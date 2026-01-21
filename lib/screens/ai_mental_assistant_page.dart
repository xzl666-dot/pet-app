import 'package:flutter/material.dart';
import '../managers/ai_mental_state_manager.dart';

class AIMentalAssistantPage extends StatefulWidget {
  const AIMentalAssistantPage({Key? key}) : super(key: key);

  @override
  State<AIMentalAssistantPage> createState() => _AIMentalAssistantPageState();
}

class _AIMentalAssistantPageState extends State<AIMentalAssistantPage> {
  final AIMentalStateManager _aiManager = AIMentalStateManager.instance;
  
  bool _isAnalyzing = false;
  String? _currentState;
  String _stateAdvice = '';
  Map<String, dynamic>? _taskAdjustmentAdvice;
  List<String> _relaxationSuggestions = [];
  Map<String, dynamic> _stateStatistics = {};

  @override
  void initState() {
    super.initState();
    _analyzeMentalState();
  }

  Future<void> _analyzeMentalState() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // 分析心理状态
      await _aiManager.analyzeMentalState();
      
      // 获取当前状态
      final currentState = _aiManager.getCurrentState().toString();
      
      // 获取相关建议
      final advice = _aiManager.getStateAdvice(_aiManager.getCurrentState());
      final taskAdvice = _aiManager.getTaskAdjustmentAdvice(_aiManager.getCurrentState());
      final relaxationSuggestions = _aiManager.getRelaxationSuggestions();
      final statistics = _aiManager.getStateStatistics();

      setState(() {
        _currentState = currentState;
        _stateAdvice = advice;
        _taskAdjustmentAdvice = taskAdvice;
        _relaxationSuggestions = relaxationSuggestions;
        _stateStatistics = statistics;
      });
    } catch (e) {
      print('分析心理状态失败: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  String _getStateName(dynamic state) {
    switch (state) {
      case 'MentalState.energetic':
        return '精力充沛';
      case 'MentalState.normal':
        return '状态正常';
      case 'MentalState.tired':
        return '有些疲惫';
      case 'MentalState.stressed':
        return '压力较大';
      case 'MentalState.anxious':
        return '有些焦虑';
      default:
        return '状态正常';
    }
  }

  Color _getStateColor(dynamic state) {
    switch (state) {
      case 'MentalState.energetic':
        return Colors.green;
      case 'MentalState.normal':
        return Colors.blue;
      case 'MentalState.tired':
        return Colors.orange;
      case 'MentalState.stressed':
        return Colors.red;
      case 'MentalState.anxious':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  IconData _getStateIcon(dynamic state) {
    switch (state) {
      case 'MentalState.energetic':
        return Icons.bolt;
      case 'MentalState.normal':
        return Icons.sentiment_satisfied;
      case 'MentalState.tired':
        return Icons.sentiment_neutral;
      case 'MentalState.stressed':
        return Icons.sentiment_dissatisfied;
      case 'MentalState.anxious':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_satisfied;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI心理助手'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分析按钮
            Center(
              child: ElevatedButton(
                onPressed: _analyzeMentalState,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isAnalyzing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('分析当前状态'),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 当前状态
            if (_currentState != null)
              _buildCurrentStateCard(),
            
            const SizedBox(height: 24),
            
            // 任务调整建议
            if (_taskAdjustmentAdvice != null)
              _buildTaskAdviceCard(),
            
            const SizedBox(height: 24),
            
            // 放松建议
            if (_relaxationSuggestions.isNotEmpty)
              _buildRelaxationCard(),
            
            const SizedBox(height: 24),
            
            // 状态统计
            if (_stateStatistics.isNotEmpty)
              _buildStatisticsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStateCard() {
    if (_currentState == null) return Container();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStateIcon(_currentState!),
                  color: _getStateColor(_currentState!),
                  size: 64,
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前心理状态',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    Text(
                      _getStateName(_currentState!),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getStateColor(_currentState!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _stateAdvice,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskAdviceCard() {
    if (_taskAdjustmentAdvice == null) return Container();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '任务调整建议',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _taskAdjustmentAdvice!['advice'],
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('难度调整', style: TextStyle(color: Colors.grey[600])),
                    Text(
                      _getDifficultyAdjustmentText(_taskAdjustmentAdvice!['difficulty_adjustment'] as int),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('数量调整', style: TextStyle(color: Colors.grey[600])),
                    Text(
                      _getTaskCountAdjustmentText(_taskAdjustmentAdvice!['task_count_adjustment'] as int),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDifficultyAdjustmentText(int adjustment) {
    switch (adjustment) {
      case 2:
        return '大幅增加';
      case 1:
        return '增加';
      case 0:
        return '保持不变';
      case -1:
        return '降低';
      case -2:
        return '大幅降低';
      default:
        return '保持不变';
    }
  }

  String _getTaskCountAdjustmentText(int adjustment) {
    switch (adjustment) {
      case 2:
        return '大幅增加';
      case 1:
        return '增加';
      case 0:
        return '保持不变';
      case -1:
        return '减少';
      case -2:
        return '大幅减少';
      default:
        return '保持不变';
    }
  }

  Widget _buildRelaxationCard() {
    if (_relaxationSuggestions.isEmpty) return Container();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '放松建议',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._relaxationSuggestions.asMap().entries.map((entry) {
              final index = entry.key;
              final suggestion = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: const TextStyle(fontSize: 14),
                        ),
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

  Widget _buildStatisticsCard() {
    if (_stateStatistics.isEmpty) return Container();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '状态统计',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('总记录数', style: TextStyle(color: Colors.grey[600])),
                    Text(
                      '${_stateStatistics['total_records']}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('最常见状态', style: TextStyle(color: Colors.grey[600])),
                    Text(
                      _getStateNameFromKey(_stateStatistics['most_common_state'] as String),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_stateStatistics['state_distribution'] != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('状态分布', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(_stateStatistics['state_distribution'] as Map<String, dynamic>).entries.map((entry) {
                      final stateKey = entry.key;
                      final count = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_getStateNameFromKey(stateKey)),
                            Text('$count次'),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getStateNameFromKey(String stateKey) {
    final stateMap = {
      'MentalState.energetic': '精力充沛',
      'MentalState.normal': '状态正常',
      'MentalState.tired': '有些疲惫',
      'MentalState.stressed': '压力较大',
      'MentalState.anxious': '有些焦虑',
    };
    return stateMap[stateKey] ?? stateKey;
  }
}
