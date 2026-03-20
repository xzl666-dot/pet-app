import 'package:flutter/material.dart';
import '../managers/user_segmentation_manager.dart';

class UserSegmentationPage extends StatefulWidget {
  const UserSegmentationPage({Key? key}) : super(key: key);

  @override
  State<UserSegmentationPage> createState() => _UserSegmentationPageState();
}

class _UserSegmentationPageState extends State<UserSegmentationPage> {
  final UserSegmentationManager _segmentManager = UserSegmentationManager.instance;
  
  bool _isLoading = true;
  String _currentSegment = '';
  Map<String, dynamic>? _currentSegmentInfo;
  List<Map<String, dynamic>> _availableBenefits = [];
  Map<String, dynamic> _segmentProgress = {};
  List<Map<String, dynamic>> _segmentHistory = [];
  
  @override
  void initState() {
    super.initState();
    _loadSegmentData();
  }
  
  Future<void> _loadSegmentData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 评估用户分层
      await _segmentManager.evaluateUserSegment();
      
      // 获取当前分层
      final currentSegment = _segmentManager.getCurrentSegment();
      final currentSegmentInfo = _segmentManager.getCurrentSegmentInfo();
      
      // 获取可用权益
      final availableBenefits = _segmentManager.getAllAvailableBenefits();
      
      // 获取分层进度
      final segmentProgress = _segmentManager.getSegmentProgress();
      
      // 获取分层历史
      final segmentHistory = _segmentManager.getSegmentHistory();
      
      setState(() {
        _currentSegment = currentSegment;
        _currentSegmentInfo = currentSegmentInfo;
        _availableBenefits = availableBenefits;
        _segmentProgress = segmentProgress;
        _segmentHistory = segmentHistory;
      });
    } catch (e) {
      print('加载分层数据失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 构建当前分层卡片
  Widget _buildCurrentSegmentCard() {
    if (_currentSegmentInfo == null) {
      return Container();
    }
    
    final color = Color(int.parse(_currentSegmentInfo!['color'].substring(1, 7), radix: 16) + 0xFF000000);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '当前用户等级',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Chip(
                  label: Text(
                    _currentSegmentInfo!['name'],
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: color,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getSegmentIcon(_currentSegment),
                    style: TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '恭喜你达到${_currentSegmentInfo!['name']}等级！',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _getSegmentDescription(_currentSegment),
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建分层进度卡片
  Widget _buildSegmentProgressCard() {
    if (_segmentProgress.isEmpty) {
      return Container();
    }
    
    final nextSegment = _segmentProgress['next_segment'];
    final progress = _segmentProgress['progress'] as double;
    final requirements = _segmentProgress['requirements'] as Map<String, dynamic>;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '等级晋升进度',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (nextSegment != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '当前等级: ${_currentSegmentInfo!['name']}',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '下一等级: ${_segmentManager.getSegmentInfo(nextSegment)?['name'] ?? ''}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '晋升要求:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (requirements.isNotEmpty) ...[
                _buildRequirementItem('任务完成率', '${requirements['min_task_completion_rate']! * 100}%'),
                _buildRequirementItem('活跃天数', '${requirements['min_active_days']}天'),
                _buildRequirementItem('宠物等级', '${requirements['min_pet_level']}级'),
                _buildRequirementItem('好友数量', '${requirements['min_friends']}人'),
              ] else ...[
                Center(
                  child: Text(
                    '你已达到最高等级！',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  // 构建权益卡片
  Widget _buildBenefitsCard() {
    if (_availableBenefits.isEmpty) {
      return Container();
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '可用权益',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._availableBenefits.map((benefit) {
              final isActive = benefit['is_active'] ?? true;
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green[100] : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isActive ? Icons.check_circle : Icons.cancel,
                            color: isActive ? Colors.green : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              benefit['name'],
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              benefit['description'],
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isActive,
                        onChanged: (value) {
                          // 动态调整权益状态
                          _segmentManager.adjustSegmentBenefits(
                            _currentSegment,
                            benefit['id'],
                            value,
                          );
                          setState(() {
                            benefit['is_active'] = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  // 构建分层历史卡片
  Widget _buildSegmentHistoryCard() {
    if (_segmentHistory.isEmpty) {
      return Container();
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '等级变更历史',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._segmentHistory.map((history) {
              final segmentInfo = _segmentManager.getSegmentInfo(history['segment']);
              final color = segmentInfo != null 
                  ? Color(int.parse(segmentInfo['color'].substring(1, 7), radix: 16) + 0xFF000000)
                  : Colors.grey;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getSegmentIcon(history['segment']),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            segmentInfo?['name'] ?? history['segment'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            history['timestamp'],
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        history['reason'],
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: color.withOpacity(0.1),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  // 构建要求项
  Widget _buildRequirementItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  // 获取分层图标
  String _getSegmentIcon(String segment) {
    switch (segment) {
      case 'newbie':
        return '🌱';
      case 'active':
        return '🔥';
      case 'core':
        return '⭐';
      case 'elite':
        return '💎';
      case 'legend':
        return '👑';
      default:
        return '📱';
    }
  }
  
  // 获取分层描述
  String _getSegmentDescription(String segment) {
    switch (segment) {
      case 'newbie':
        return '开始你的学习之旅，探索宠物养成的乐趣';
      case 'active':
        return '保持活跃，享受学习和社交的双重乐趣';
      case 'core':
        return '成为核心用户，解锁更多高级功能和权益';
      case 'elite':
        return '晋升为精英，享受专属特权和挑战';
      case 'legend':
        return '达到传奇级别，成为游戏中的传奇人物';
      default:
        return '继续努力，提升你的等级';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户分层'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 当前分层
                  _buildCurrentSegmentCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 分层进度
                  _buildSegmentProgressCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 可用权益
                  _buildBenefitsCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 分层历史
                  _buildSegmentHistoryCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 刷新按钮
                  Center(
                    child: ElevatedButton(
                      onPressed: _loadSegmentData,
                      child: const Text('刷新数据'),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
