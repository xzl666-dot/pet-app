import 'package:flutter/material.dart';
import '../managers/social_challenge_manager.dart';
import '../models/task_model.dart';
import '../database/database_helper.dart';
import 'task_list_page.dart';
import 'friend_list_page.dart';
import 'add_friend_page.dart';

class SocialChallengePage extends StatefulWidget {
  const SocialChallengePage({Key? key}) : super(key: key);

  @override
  State<SocialChallengePage> createState() => _SocialChallengePageState();
}

class _SocialChallengePageState extends State<SocialChallengePage> {
  final SocialChallengeManager _challengeManager = SocialChallengeManager.instance;
  
  Map<String, dynamic> _challengeStats = {};
  List<Map<String, dynamic>> _recentChallenges = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChallengeData();
  }

  Future<void> _loadChallengeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _challengeManager.getChallengeStatistics();
      setState(() {
        _challengeStats = stats;
      });

      final records = await _challengeManager.getChallengeRecords(1, 3);
      setState(() {
        _recentChallenges = records['list'] ?? [];
      });
    } catch (e) {
      print('加载挑战数据失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('社交挑战'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddFriendPage()),
              );
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: '好友'),
                Tab(text: '排行榜'),
                Tab(text: '竞赛'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const FriendListPage(),
                  const LeaderboardPage(),
                  const CompetitionPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 发起挑战页
class ChallengeCreatePage extends StatefulWidget {
  final String? opponentId;
  final String? opponentNickname;
  const ChallengeCreatePage({Key? key, this.opponentId, this.opponentNickname}) : super(key: key);

  @override
  State<ChallengeCreatePage> createState() => _ChallengeCreatePageState();
}

class _ChallengeCreatePageState extends State<ChallengeCreatePage> {
  final SocialChallengeManager _challengeManager = SocialChallengeManager.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _challengeNameController = TextEditingController();
  
  List<TaskModel> _tasks = [];
  TaskModel? _selectedTask;
  bool _isLoading = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await _dbHelper.readAllTasks();
      setState(() {
        _tasks = tasks;
      });
    } catch (e) {
      print('加载任务失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createChallenge() async {
    if (_selectedTask == null || _challengeNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择任务并输入挑战名称')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      if (widget.opponentId != null) {
        final result = await _challengeManager.createFriendChallenge(
          _selectedTask!.id.toString(),
          _challengeNameController.text,
          widget.opponentId!,
          widget.opponentNickname ?? '未知',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('挑战创建成功！')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChallengeIngPage(
              challengeId: result['challengeId'],
              opponent: {
                'opponentId': widget.opponentId,
                'opponentNickname': widget.opponentNickname,
                'opponentLevel': result['opponentLevel'],
              },
            ),
          ),
        );
      } else {
        final result = await _challengeManager.createChallenge(
          _selectedTask!.id.toString(),
          _challengeNameController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('挑战创建成功！')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChallengeMatchPage(challengeId: result['challengeId']),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建挑战失败: $e')),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发起挑战'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择挑战任务',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_tasks.isEmpty)
              const Center(child: Text('暂无任务'))
            else
              Column(
                children: _tasks.map((task) {
                  return RadioListTile<TaskModel>(
                    title: Text(task.name),
                    subtitle: Text('难度：${task.difficulty.name}，奖励：${task.benefitValue}'),
                    value: task,
                    groupValue: _selectedTask,
                    onChanged: (value) {
                      setState(() {
                        _selectedTask = value;
                        if (value != null) {
                          _challengeNameController.text = '挑战：${value.name}';
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _challengeNameController,
              decoration: const InputDecoration(
                labelText: '挑战名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createChallenge,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
                ),
                child: _isCreating
                    ? const CircularProgressIndicator()
                    : const Text('创建挑战'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 挑战匹配页
class ChallengeMatchPage extends StatefulWidget {
  final String challengeId;
  const ChallengeMatchPage({Key? key, required this.challengeId}) : super(key: key);

  @override
  State<ChallengeMatchPage> createState() => _ChallengeMatchPageState();
}

class _ChallengeMatchPageState extends State<ChallengeMatchPage> {
  final SocialChallengeManager _challengeManager = SocialChallengeManager.instance;
  bool _isMatching = true;
  int _countdown = 10;
  bool _matchSuccess = false;
  Map<String, dynamic>? _matchedOpponent;

  @override
  void initState() {
    super.initState();
    _startMatching();
    _startCountdown();
  }

  Future<void> _startMatching() async {
    try {
      final opponent = await _challengeManager.matchOpponent(widget.challengeId);
      if (opponent != null) {
        setState(() {
          _matchSuccess = true;
          _matchedOpponent = opponent;
        });

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChallengeIngPage(
                challengeId: widget.challengeId,
                opponent: opponent,
              ),
            ),
          );
        });
      } else {
        setState(() {
          _isMatching = false;
        });
      }
    } catch (e) {
      print('匹配失败: $e');
      setState(() {
        _isMatching = false;
      });
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_countdown > 0 && !_matchSuccess) {
        setState(() {
          _countdown--;
        });
        _startCountdown();
      } else if (!_matchSuccess) {
        setState(() {
          _isMatching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('匹配对手'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isMatching && !_matchSuccess)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  const Text('正在匹配对手...', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  Text('剩余时间：$_countdown秒', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              )
            else if (_matchSuccess && _matchedOpponent != null)
              Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text('匹配成功！', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  Text('对手：${_matchedOpponent!['opponentNickname']}', style: const TextStyle(fontSize: 16)),
                ],
              )
            else
              Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text('暂无匹配对手', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isMatching = true;
                        _countdown = 10;
                      });
                      _startMatching();
                      _startCountdown();
                    },
                    child: const Text('重新匹配'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// 挑战进行中页
class ChallengeIngPage extends StatefulWidget {
  final String challengeId;
  final Map<String, dynamic> opponent;
  const ChallengeIngPage({Key? key, required this.challengeId, required this.opponent}) : super(key: key);

  @override
  State<ChallengeIngPage> createState() => _ChallengeIngPageState();
}

class _ChallengeIngPageState extends State<ChallengeIngPage> {
  final SocialChallengeManager _challengeManager = SocialChallengeManager.instance;
  bool _isCompleted = false;
  bool _isSyncing = false;
  int _opponentStatus = 0; 

  Future<void> _completeChallenge() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await _challengeManager.syncChallengeData(
        widget.challengeId,
        1, 
        25, 
        95, 
      );

      setState(() {
        _isCompleted = true;
        _opponentStatus = result['opponentFinishStatus'] ?? 0;
      });

      if (_opponentStatus == 1) {
        _settleChallenge();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已完成，等待对手提交...')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('同步失败: $e')),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _giveUpChallenge() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await _challengeManager.syncChallengeData(
        widget.challengeId,
        2, 
        null,
        null,
      );

      setState(() {
        _isCompleted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已放弃挑战')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _settleChallenge() async {
    try {
      final result = await _challengeManager.settleChallenge(widget.challengeId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChallengeSettlePage(settleResult: result),
        ),
      );
    } catch (e) {
      print('结算失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('挑战进行中'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 40, color: Colors.blue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.opponent['opponentNickname'] ?? '未知',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text('等级：${widget.opponent['opponentLevel'] ?? 0}'),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(_opponentStatus == 0 ? '未提交' : _opponentStatus == 1 ? '已完成' : '已放弃'),
                      backgroundColor: _opponentStatus == 0 ? Colors.grey[200] : _opponentStatus == 1 ? Colors.green[100] : Colors.red[100],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_isCompleted)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _isSyncing ? null : _completeChallenge,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isSyncing
                        ? const CircularProgressIndicator()
                        : const Text('完成任务'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _isSyncing ? null : _giveUpChallenge,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('放弃挑战'),
                  ),
                ],
              )
            else
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 64),
                    SizedBox(height: 16),
                    Text('任务已提交', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 挑战结算页
class ChallengeSettlePage extends StatelessWidget {
  final Map<String, dynamic> settleResult;
  const ChallengeSettlePage({Key? key, required this.settleResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('挑战结算'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              settleResult['settleResult'] ?? '未知',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}

// 排行榜页面
class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final SocialChallengeManager _socialManager = SocialChallengeManager.instance;
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  String _selectedType = 'pet_growth';

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final leaderboard = await _socialManager.getLeaderboard(_selectedType, 20);
      setState(() {
        _leaderboard = leaderboard;
      });
    } catch (e) {
      print('获取排行榜失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() => _selectedType = 'pet_growth');
                    _loadLeaderboard();
                  },
                  child: const Text('宠物成长'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _selectedType = 'level');
                    _loadLeaderboard();
                  },
                  child: const Text('用户等级'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _leaderboard.length,
                    itemBuilder: (context, index) {
                      final item = _leaderboard[index];
                      return ListTile(
                        leading: Text('${item['rank']}'),
                        title: Text(item['nickname']),
                        trailing: Text('${item['value']}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// 竞赛页面
class CompetitionPage extends StatefulWidget {
  const CompetitionPage({Key? key}) : super(key: key);

  @override
  State<CompetitionPage> createState() => _CompetitionPageState();
}

class _CompetitionPageState extends State<CompetitionPage> {
  final SocialChallengeManager _socialManager = SocialChallengeManager.instance;
  List<Competition> _competitions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  Future<void> _loadCompetitions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final competitions = await _socialManager.getActiveCompetitions();
      setState(() {
        _competitions = competitions;
      });
    } catch (e) {
      print('获取竞赛列表失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _competitions.length,
              itemBuilder: (context, index) {
                final comp = _competitions[index];
                return ListTile(
                  title: Text('与 ${comp.opponentNickname} 的竞赛'),
                  subtitle: Text('结束时间: ${comp.endTime}'),
                );
              },
            ),
    );
  }
}

// 挑战大厅页
class ChallengeHallPage extends StatelessWidget {
  const ChallengeHallPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('挑战大厅')),
      body: const Center(child: Text('挑战大厅功能开发中')),
    );
  }
}

// 挑战记录页
class ChallengeRecordPage extends StatelessWidget {
  const ChallengeRecordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('挑战记录')),
      body: const Center(child: Text('挑战记录功能开发中')),
    );
  }
}

// 陌生人列表页面
class StrangerListPage extends StatelessWidget {
  const StrangerListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('随机匹配')),
      body: const Center(child: Text('随机匹配功能开发中')),
    );
  }
}
