import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../managers/auth_manager.dart';
import '../utils/token_util.dart';

class AbilityEvaluationPage extends StatefulWidget {
  const AbilityEvaluationPage({super.key});

  @override
  State<AbilityEvaluationPage> createState() => _AbilityEvaluationPageState();
}

class _AbilityEvaluationPageState extends State<AbilityEvaluationPage> {
  final authManager = AuthManager.instance;
  bool _isLoading = true;
  bool _isEvaluating = false;
  Map<String, dynamic>? _evaluationData;
  bool _hasNewUserEvaluation = true;
  int _completedTasksToday = 0;

  @override
  void initState() {
    super.initState();
    _loadEvaluationData();
  }

  Future<void> _loadEvaluationData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = authManager.currentUser;
      if (user == null) {
        throw Exception('用户未登录');
      }

      final userId = user.userId ?? user.id;
      if (userId == null) {
        throw Exception('用户ID不存在');
      }

      final token = await TokenUtil.instance.getAccessToken();

      print('=== 加载评估数据 ===');
      print('UserId: $userId');

      // 查询评估等级
      final levelResponse = await http.get(
        Uri.parse('http://localhost:3000/api/evaluation/level/query?userId=$userId&petId=1'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'token': token,
        },
      );

      print('评估等级响应: ${levelResponse.body}');

      if (levelResponse.statusCode == 200) {
        final levelData = jsonDecode(levelResponse.body);
        if (levelData['code'] == 200) {
          setState(() {
            _evaluationData = levelData['data'];
            _hasNewUserEvaluation = _checkNewUserEvaluation();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('加载评估数据失败: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _checkNewUserEvaluation() {
    if (_evaluationData == null) return true;
    
    final levelHistory = _evaluationData!['levelHistory'] as List?;
    if (levelHistory == null || levelHistory.isEmpty) return true;
    
    final lastEvaluation = levelHistory.first;
    final lastEvaluationDate = DateTime.parse(lastEvaluation['date']);
    final daysSinceLastEvaluation = DateTime.now().difference(lastEvaluationDate).inDays;
    
    return daysSinceLastEvaluation > 30;
  }

  Future<void> _startNewUserEvaluation() async {
    setState(() {
      _isEvaluating = true;
    });

    try {
      final user = authManager.currentUser;
      print('=== 开始新用户评估 ===');
      print('AuthManager.currentUser: $user');
      
      if (user == null) {
        throw Exception('用户未登录');
      }

      final userId = user.userId ?? user.id;
      print('UserId: $userId');
      
      if (userId == null) {
        throw Exception('用户ID不存在');
      }

      final token = await TokenUtil.instance.getAccessToken();
      print('Token: $token');

      if (token == null) {
        throw Exception('Token不存在，请重新登录');
      }

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/evaluation/newUser/evaluate'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'petId': 1,
        }),
      );

      print('评估响应状态码: ${response.statusCode}');
      print('评估响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          if (mounted) {
            _showEvaluationResultDialog(data['data']);
          }
        } else {
          throw Exception(data['msg'] ?? '评估失败');
        }
      } else {
        throw Exception('网络请求失败');
      }
    } catch (e) {
      print('评估失败: $e');
      setState(() {
        _isEvaluating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('评估失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEvaluationResultDialog(Map<String, dynamic> result) {
    final level = result['newLevel'];
    final score = result['totalScore'];
    final expReward = result['expReward'];
    final skipLevels = result['skipLevels'];
    final levelBenefits = result['levelBenefits'];

    final levelColors = {
      'S': Colors.purple,
      'A': Colors.blue,
      'B': Colors.green,
      'C': Colors.orange,
      'D': Colors.grey,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('评估结果'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: levelColors[level],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    level,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '评估得分: $score',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildResultItem('经验奖励', '+$expReward 经验', Icons.star, Colors.orange),
              const SizedBox(height: 8),
              _buildResultItem('跳过等级', '跳过$skipLevels级养成', Icons.trending_up, Colors.green),
              const SizedBox(height: 16),
              const Text(
                '等级权益',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                levelBenefits['description'] ?? '基础权限',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isEvaluating = false;
              });
              _loadEvaluationData();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('能力评估'),
        backgroundColor: Colors.blue[600],
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (_hasNewUserEvaluation) _buildNewUserEvaluationSection(),
                  _buildCurrentLevelSection(),
                  _buildEvaluationRulesSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildNewUserEvaluationSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, size: 32, color: Colors.blue[600]),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '新用户能力评估',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '完成能力评估，根据评估得分获得经验奖励和等级跳过！',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildLevelRewardCard('S', '90分以上', '500经验', '跳过5级', Colors.purple),
          const SizedBox(height: 12),
          _buildLevelRewardCard('A', '80-89分', '400经验', '跳过4级', Colors.blue),
          const SizedBox(height: 12),
          _buildLevelRewardCard('B', '70-79分', '300经验', '跳过3级', Colors.green),
          const SizedBox(height: 12),
          _buildLevelRewardCard('C', '60-69分', '100经验', '跳过2级', Colors.orange),
          const SizedBox(height: 12),
          _buildLevelRewardCard('D', '60分以下', '0经验', '不跳过', Colors.grey),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isEvaluating ? null : _startNewUserEvaluation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isEvaluating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('评估中...'),
                      ],
                    )
                  : const Text('开始评估'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRewardCard(String level, String scoreRange, String exp, String skip, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                level,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scoreRange,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  exp,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  skip,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLevelSection() {
    if (_evaluationData == null) return const SizedBox.shrink();

    final currentLevel = _evaluationData!['currentLevel'];
    final currentScore = _evaluationData!['currentScore'];
    final levelBenefits = _evaluationData!['levelBenefits'];

    final levelColors = {
      'S': Colors.purple,
      'A': Colors.blue,
      'B': Colors.green,
      'C': Colors.orange,
      'D': Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: levelColors[currentLevel],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '当前评估等级',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            currentLevel,
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当前得分: $currentScore',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            levelBenefits['description'] ?? '基础权限',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationRulesSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, size: 24, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                '评估规则',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRuleItem('新用户评估', '创建账号后可进行一次能力评估，获得初始经验和等级跳过'),
          const SizedBox(height: 8),
          _buildRuleItem('每日自动评估', '每天完成任务后，系统自动评估并更新等级'),
          const SizedBox(height: 8),
          _buildRuleItem('评估得分', '根据任务完成情况计算，得分越高奖励越多'),
          const SizedBox(height: 8),
          _buildRuleItem('等级跳过', '高评估得分可以跳过一部分初期的养成过程'),
          const SizedBox(height: 8),
          _buildRuleItem('等级有效期', '评估等级有效期为30天，过期后需要重新评估'),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.blue[600],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
