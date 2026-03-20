import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../managers/auth_manager.dart';
import '../managers/pet_growth_manager.dart';
import '../utils/token_util.dart';

class NPCChallengePage extends StatefulWidget {
  const NPCChallengePage({Key? key}) : super(key: key);

  @override
  State<NPCChallengePage> createState() => _NPCChallengePageState();
}

class _NPCChallengePageState extends State<NPCChallengePage> {
  final _authManager = AuthManager.instance;
  bool _isLoading = true;
  List<dynamic> _npcList = [];
  int _selectedDifficulty = -1;

  @override
  void initState() {
    super.initState();
    _loadNPCList();
    _initNPCData();
  }

  Future<void> _initNPCData() async {
    try {
      final token = await TokenUtil.instance.getAccessToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/npcChallenge/init'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );
    } catch (e) {
      print('初始化NPC数据失败: $e');
    }
  }

  Future<void> _loadNPCList() async {
    setState(() => _isLoading = true);

    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      String url = 'http://localhost:3000/api/npcChallenge/list';
      if (_selectedDifficulty != -1) {
        url += '?difficulty=$_selectedDifficulty';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          setState(() {
            _npcList = data['data']['npcList'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('加载NPC列表失败: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startChallenge(dynamic npc) async {
    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      // 检查宠物营养值
      final petResponse = await http.get(
        Uri.parse('http://localhost:3000/api/pet/status?userId=$userId&petId=1'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      if (petResponse.statusCode == 200) {
        final petData = jsonDecode(petResponse.body);
        if (petData['code'] == 200) {
          final nutrition = petData['data']['nutrition'] ?? 0;
          if (nutrition < 5) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('宠物营养不足，无法挑战'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }
      }

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/npcChallenge/challenge'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'npcId': npc['id'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NPCBattlePage(
                  challengeId: data['data']['challengeId'],
                  npc: data['data']['npc'],
                  user: data['data']['user'],
                  pet: data['data']['pet'],
                ),
              ),
            ).then((result) {
              if (result != null && result['completed']) {
                _loadNPCList();
              }
            });
          }
        }
      }
    } catch (e) {
      print('开始挑战失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('开始挑战失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NPC挑战'),
      ),
      body: Column(
        children: [
          _buildDifficultyFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _npcList.isEmpty
                    ? const Center(child: Text('暂无NPC'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _npcList.length,
                        itemBuilder: (context, index) {
                          return _buildNPCCard(_npcList[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          final difficulties = ['全部', '简单', '中等', '困难'];
          final isSelected = (index == 0 && _selectedDifficulty == -1) ||
              (index > 0 && _selectedDifficulty == index);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(difficulties[index]),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedDifficulty = index == 0 ? -1 : index;
                });
                _loadNPCList();
              },
              selectedColor: Colors.blue.withOpacity(0.2),
              checkmarkColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNPCCard(dynamic npc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      npc['avatar'],
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            npc['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(npc['difficulty'])
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getDifficultyName(npc['difficulty']),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getDifficultyColor(npc['difficulty']),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lv.${npc['level']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (npc['description'] != null)
              Text(
                npc['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem('🎯', '挑战', '${npc['challengeCount']}次'),
                const SizedBox(width: 16),
                _buildInfoItem('🏆', '胜利', '${npc['winCount']}次'),
                const SizedBox(width: 16),
                _buildInfoItem('⭐', '经验', '+${npc['rewardExp']}'),
                const SizedBox(width: 16),
                _buildInfoItem('💎', '积分', '+${npc['rewardPoints']}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPetInfo('🐱', npc['petType'] ?? '未知', npc['petLevel']),
                const SizedBox(width: 16),
                _buildPetInfo('🌟', npc['petForm'] ?? '未知', npc['petLevel']),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startChallenge(npc),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('开始挑战'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPetInfo(String icon, String label, int level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$label Lv.$level',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getDifficultyName(int difficulty) {
    switch (difficulty) {
      case 1:
        return '简单';
      case 2:
        return '中等';
      case 3:
        return '困难';
      default:
        return '未知';
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class NPCBattlePage extends StatefulWidget {
  final String challengeId;
  final Map<String, dynamic> npc;
  final Map<String, dynamic> user;
  final Map<String, dynamic> pet;

  const NPCBattlePage({
    Key? key,
    required this.challengeId,
    required this.npc,
    required this.user,
    required this.pet,
  }) : super(key: key);

  @override
  State<NPCBattlePage> createState() => _NPCBattlePageState();
}

class _NPCBattlePageState extends State<NPCBattlePage> {
  int _userScore = 0;
  int _npcScore = 0;
  bool _isBattling = false;
  final _petGrowthManager = PetGrowthManager();

  Future<void> _completeBattle(bool isWin) async {
    setState(() => _isBattling = true);

    try {
      final authManager = AuthManager.instance;
      final user = authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/npcChallenge/complete'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'challengeId': widget.challengeId,
          'isWin': isWin,
          'userScore': _userScore,
          'npcScore': _npcScore,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          // 根据胜负情况获得经验值
          final expGain = isWin ? 20 : 5;
          await _petGrowthManager.updatePetExp(expGain);
          
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text(isWin ? '🎉 挑战胜利！' : '😢 挑战失败'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isWin) ...[
                      Text('经验值: +$expGain'),
                      Text('积分: +${data['data']['rewardPoints']}'),
                      if (data['data']['newPetLevel'] > widget.pet['level'])
                        Text('宠物升级到 Lv.${data['data']['newPetLevel']}'),
                    ] else ...[
                      Text('经验值: +$expGain'),
                      Text('积分: -2'),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context, {'completed': true});
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      print('完成挑战失败: $e');
      setState(() => _isBattling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NPC对战'),
      ),
      body: _isBattling
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildBattleHeader(),
                  const SizedBox(height: 20),
                  _buildScoreBoard(),
                  const SizedBox(height: 20),
                  _buildBattleControls(),
                  const Spacer(),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildBattleHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildPlayerCard(
          widget.user['nickname'],
          widget.user['avatar'],
          widget.pet['name'],
          widget.pet['level'],
          Colors.blue,
        ),
        const Text(
          'VS',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        _buildPlayerCard(
          widget.npc['name'],
          widget.npc['avatar'],
          widget.npc['petType'] ?? '未知',
          widget.npc['petLevel'],
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildPlayerCard(
    String name,
    String avatar,
    String petName,
    int level,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(avatar, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$petName Lv.$level',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('你的得分', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                '$_userScore',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const Text(
            '-',
            style: TextStyle(fontSize: 32, color: Colors.grey),
          ),
          Column(
            children: [
              const Text('NPC得分', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                '$_npcScore',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBattleControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildScoreButton('你的得分 +1', Colors.blue, () {
              setState(() => _userScore++);
            }),
            _buildScoreButton('NPC得分 +1', Colors.red, () {
              setState(() => _npcScore++);
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildScoreButton('你的得分 +5', Colors.blue, () {
              setState(() => _userScore += 5);
            }),
            _buildScoreButton('NPC得分 +5', Colors.red, () {
              setState(() => _npcScore += 5);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(140, 48),
      ),
      child: Text(label),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _completeBattle(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('认输', style: TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _completeBattle(_userScore >= _npcScore),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('完成挑战', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}