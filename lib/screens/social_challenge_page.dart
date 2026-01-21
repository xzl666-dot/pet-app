import 'package:flutter/material.dart';
import '../managers/social_challenge_manager.dart';
import '../models/task_model.dart';
import '../database/task_database.dart';

class SocialChallengePage extends StatefulWidget {
  const SocialChallengePage({Key? key}) : super(key: key);

  @override
  State<SocialChallengePage> createState() => _SocialChallengePageState();
}

class _SocialChallengePageState extends State<SocialChallengePage> {
  final SocialChallengeManager _challengeManager = SocialChallengeManager.instance;
  final TaskDatabase _taskDatabase = TaskDatabase.instance;
  
  bool _isMatching = false;
  Map<String, dynamic>? _matchedOpponent;
  List<TaskModel>? _challengeTasks;
  bool _challengeStarted = false;
  List<Map<String, dynamic>> _challengeHistory = [];
  Map<String, dynamic> _challengeStats = {};

  @override
  void initState() {
    super.initState();
    _loadChallengeHistory();
    _loadChallengeStatistics();
  }

  Future<void> _loadChallengeHistory() async {
    setState(() {
      _challengeHistory = _challengeManager.getChallengeHistory();
    });
  }

  Future<void> _loadChallengeStatistics() async {
    setState(() {
      _challengeStats = _challengeManager.getChallengeStatistics();
    });
  }

  Future<void> _matchOpponent() async {
    setState(() {
      _isMatching = true;
      _matchedOpponent = null;
      _challengeTasks = null;
      _challengeStarted = false;
    });

    try {
      // 匹配对手
      final opponent = await _challengeManager.matchOpponent();
      if (opponent != null) {
        setState(() {
          _matchedOpponent = opponent;
        });

        // 生成挑战任务
        final tasks = await _challengeManager.generateChallengeTasks(opponent);
        setState(() {
          _challengeTasks = tasks;
        });
      }
    } catch (e) {
      print('匹配对手失败: $e');
    } finally {
      setState(() {
        _isMatching = false;
      });
    }
  }

  Future<void> _startChallenge() async {
    if (_challengeTasks == null) return;

    setState(() {
      _challengeStarted = true;
    });

    // 保存挑战任务到数据库
    for (final task in _challengeTasks!) {
      await _taskDatabase.create(task);
    }

    // 显示成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('挑战开始！任务已添加到任务列表')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('社交挑战'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 挑战统计
            _buildChallengeStatsCard(),
            
            const SizedBox(height: 24),
            
            // 开始挑战
            _buildStartChallengeSection(),
            
            const SizedBox(height: 24),
            
            // 挑战历史
            _buildChallengeHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeStatsCard() {
    final totalChallenges = _challengeStats['total_challenges'] ?? 0;
    final wonChallenges = _challengeStats['won_challenges'] ?? 0;
    final winRate = _challengeStats['win_rate'] ?? 0.0;
    final taskCompletionRate = _challengeStats['task_completion_rate'] ?? 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '挑战统计',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('总挑战次数', '$totalChallenges'),
                _buildStatItem('获胜次数', '$wonChallenges'),
                _buildStatItem('胜率', '${(winRate * 100).toInt()}%'),
                _buildStatItem('任务完成率', '${(taskCompletionRate * 100).toInt()}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStartChallengeSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '开始挑战',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            if (_isMatching)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在匹配对手...'),
                ],
              )
            else if (_matchedOpponent != null && _challengeTasks != null && !_challengeStarted)
              _buildOpponentInfoCard()
            else if (_challengeStarted)
              const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 64),
                  SizedBox(height: 16),
                  Text('挑战已开始！'),
                  SizedBox(height: 8),
                  Text('请在任务列表中查看和完成挑战任务'),
                ],
              )
            else
              ElevatedButton(
                onPressed: _matchOpponent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('匹配对手'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpponentInfoCard() {
    if (_matchedOpponent == null || _challengeTasks == null) return Container();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '匹配到对手',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    _matchedOpponent!['name'],
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 16),
                  Chip(
                    label: Text('等级 ${_matchedOpponent!['level']}'),
                    backgroundColor: Colors.blue,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // 挑战任务预览
        Container(
          alignment: Alignment.centerLeft,
          child: const Text(
            '挑战任务：',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        
        for (int i = 0; i < _challengeTasks!.length; i++)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(_challengeTasks![i].name),
                  ),
                  Chip(
                    label: Text('+${_challengeTasks![i].benefitValue}'),
                    backgroundColor: Colors.green[100],
                    labelStyle: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
        
        const SizedBox(height: 20),
        
        ElevatedButton(
          onPressed: _startChallenge,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            textStyle: const TextStyle(fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('开始挑战'),
        ),
      ],
    );
  }

  Widget _buildChallengeHistorySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '挑战历史',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (_challengeHistory.isEmpty)
              const Center(
                child: Text('暂无挑战历史'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _challengeHistory.length,
                itemBuilder: (context, index) {
                  final challenge = _challengeHistory[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '对手：${challenge['opponent_name']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Chip(
                                label: Text(challenge['is_winner'] ? '获胜' : '失败'),
                                backgroundColor: challenge['is_winner'] ? Colors.green[100] : Colors.red[100],
                                labelStyle: TextStyle(
                                  color: challenge['is_winner'] ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '完成任务：${challenge['completed_tasks']}/${challenge['total_tasks']}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Text(
                            '挑战时间：${challenge['challenge_date'].toString().substring(0, 16)}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
