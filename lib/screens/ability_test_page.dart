import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../managers/auth_manager.dart';
import '../utils/token_util.dart';

class AbilityTestPage extends StatefulWidget {
  const AbilityTestPage({Key? key}) : super(key: key);

  @override
  State<AbilityTestPage> createState() => _AbilityTestPageState();
}

class _AbilityTestPageState extends State<AbilityTestPage> {
  final _authManager = AuthManager.instance;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = false;
  bool _hasTakenTest = false;
  bool _isCheckingStatus = true;
  String _currentLevel = 'D';

  final List<Map<String, dynamic>> _questions = [
    {
      'question': '你每天能完成多少个任务？',
      'options': ['1-2个', '3-5个', '6-10个', '10个以上'],
      'scores': [1, 2, 3, 4],
    },
    {
      'question': '你完成任务的速度如何？',
      'options': ['很慢', '一般', '较快', '非常快'],
      'scores': [1, 2, 3, 4],
    },
    {
      'question': '你对任务质量的重视程度？',
      'options': ['不太重视', '一般重视', '很重视', '极度重视'],
      'scores': [1, 2, 3, 4],
    },
    {
      'question': '你连续完成任务的记录？',
      'options': ['1-3天', '4-7天', '8-14天', '15天以上'],
      'scores': [1, 2, 3, 4],
    },
    {
      'question': '你对挑战困难任务的态度？',
      'options': ['回避', '偶尔尝试', '经常尝试', '主动寻找'],
      'scores': [1, 2, 3, 4],
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkTestStatus();
  }

  Future<void> _checkTestStatus() async {
    try {
      final user = _authManager.currentUser;
      if (user != null) {
        final token = await TokenUtil.instance.getAccessToken();
        final userId = user.userId ?? user.id;

        if (token != null && userId != null) {
          final response = await http.get(
            Uri.parse('http://localhost:3000/api/evaluation/test/status?userId=$userId'),
            headers: {
              'Content-Type': 'application/json',
              'token': token,
            },
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('请求超时');
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['code'] == 200) {
              setState(() {
                _hasTakenTest = data['data']['hasTakenTest'] ?? false;
                _currentLevel = data['data']['currentLevel'] ?? 'D';
                _isCheckingStatus = false;
              });
              return;
            }
          }
        }
      }
      setState(() => _isCheckingStatus = false);
    } catch (e) {
      print('检查测试状态失败: $e');
      setState(() => _isCheckingStatus = false);
    }
  }

  String _calculateLevel(int score) {
    if (score >= 18) return 'S';
    if (score >= 14) return 'A';
    if (score >= 10) return 'B';
    if (score >= 6) return 'C';
    return 'D';
  }

  Future<void> _submitTest() async {
    setState(() => _isLoading = true);

    try {
      final user = _authManager.currentUser;
      if (user == null) {
        throw Exception('用户未登录');
      }

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) {
        throw Exception('Token或用户ID不存在');
      }

      final level = _calculateLevel(_score);

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/evaluation/test/submit'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'score': _score,
          'level': level,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('请求超时');
        },
      );

      print('提交测试响应状态码: ${response.statusCode}');
      print('提交测试响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          setState(() {
            _hasTakenTest = true;
            _currentLevel = level;
          });
          _showResultDialog(level);
        } else {
          throw Exception(data['msg'] ?? '提交测试失败');
        }
      } else {
        throw Exception('网络请求失败: ${response.statusCode}');
      }
    } catch (e) {
      print('提交测试失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交测试失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showResultDialog(String level) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('测试完成'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '你的能力等级是：$level',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('总分：$_score/20'),
            const SizedBox(height: 16),
            Text(
              _getLevelDescription(level),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _getLevelDescription(String level) {
    switch (level) {
      case 'S':
        return '你是顶尖的宠物养成专家！';
      case 'A':
        return '你非常出色，继续保持！';
      case 'B':
        return '你表现良好，还有提升空间！';
      case 'C':
        return '你还需要多加练习！';
      case 'D':
        return '加油，你可以做得更好！';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingStatus) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('能力评估'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasTakenTest) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('能力评估'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 100,
                color: Colors.amber,
              ),
              const SizedBox(height: 24),
              Text(
                '你的当前能力等级',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _currentLevel,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _getLevelDescription(_currentLevel),
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                '注意：能力测试每个用户只能参加一次',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentQuestionIndex >= _questions.length) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('能力评估'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '测试完成！',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Text(
                  '你的得分：$_score/20',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _submitTest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('提交结果', style: TextStyle(fontSize: 18)),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('能力评估 (${_currentQuestionIndex + 1}/${_questions.length})'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              minHeight: 8,
            ),
            const SizedBox(height: 32),
            Text(
              question['question'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ...List.generate(
              question['options'].length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _score += (question['scores'][index] as int);
                      _currentQuestionIndex++;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    question['options'][index],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}