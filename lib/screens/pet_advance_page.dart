import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../managers/auth_manager.dart';
import '../utils/token_util.dart';

class PetAdvancePage extends StatefulWidget {
  const PetAdvancePage({Key? key}) : super(key: key);

  @override
  State<PetAdvancePage> createState() => _PetAdvancePageState();
}

class _PetAdvancePageState extends State<PetAdvancePage> with TickerProviderStateMixin {
  final _authManager = AuthManager.instance;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _advanceData;
  List<dynamic> _albumPets = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      await Future.wait([
        _loadAdvanceData(),
        _loadAlbum(),
      ]);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = '加载数据失败，请检查网络连接';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAdvanceData() async {
    try {
      final user = _authManager.currentUser;
      if (user == null) {
        _setDefaultAdvanceData();
        return;
      }

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) {
        _setDefaultAdvanceData();
        return;
      }

      // 获取宠物列表以获取选中的宠物ID
      final petListRes = await http.get(
        Uri.parse('http://localhost:3000/api/pet/list?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      int petId = 1;
      if (petListRes.statusCode == 200) {
        final petListData = jsonDecode(petListRes.body);
        if (petListData['code'] == 200 && petListData['data'] != null && petListData['data']['selectedPetId'] != null) {
          petId = petListData['data']['selectedPetId'];
        }
      }

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/petAdvance/advance?userId=$userId&petId=$petId'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          if (mounted) {
            setState(() {
              _advanceData = data['data'];
            });
          }
        } else {
          _setDefaultAdvanceData();
        }
      } else {
        _setDefaultAdvanceData();
      }
    } catch (e) {
      print('加载宠物进阶数据失败: $e');
      _setDefaultAdvanceData();
    }
  }

  void _setDefaultAdvanceData() {
    if (!mounted) return;
    setState(() {
      _advanceData = {
        'pet': {
          'id': 1,
          'name': '我的宠物',
          'type': 'chick',
          'form': '小鸡',
          'level': 1,
          'exp': 0,
          'expThreshold': 100,
          'nutrition': 50,
          'happiness': 50,
        },
        'advance': {
          'currentStage': '幼年期',
          'stageExp': 0,
          'stageExpMax': 100,
          'stageRecord': [],
          'evolveCondition': {'exp': 100, 'intimacy': 50, 'taskCount': 10},
        },
      };
    });
  }

  Future<void> _loadAlbum() async {
    try {
      final user = _authManager.currentUser;
      if (user == null) {
        _setDefaultAlbum();
        return;
      }

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) {
        _setDefaultAlbum();
        return;
      }

      // 获取宠物列表以获取选中的宠物ID
      final petListRes = await http.get(
        Uri.parse('http://localhost:3000/api/pet/list?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      int petId = 1;
      if (petListRes.statusCode == 200) {
        final petListData = jsonDecode(petListRes.body);
        if (petListData['code'] == 200 && petListData['data'] != null && petListData['data']['selectedPetId'] != null) {
          petId = petListData['data']['selectedPetId'];
        }
      }

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/petAdvance/album?userId=$userId&petId=$petId'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          if (mounted) {
            setState(() {
              _albumPets = data['data']['petList'] ?? [];
            });
          }
        } else {
          _setDefaultAlbum();
        }
      } else {
        _setDefaultAlbum();
      }
    } catch (e) {
      print('加载图鉴数据失败: $e');
      _setDefaultAlbum();
    }
  }

  void _setDefaultAlbum() {
    if (!mounted) return;
    setState(() {
      _albumPets = [
        {'id': 1, 'name': '小鸡', 'type': '普通', 'rarity': 'common', 'description': '可爱的小鸡，毛茸茸的非常惹人喜爱', 'isUnlocked': true},
        {'id': 2, 'name': '小狗', 'type': '普通', 'rarity': 'common', 'description': '忠诚的小狗，是人类最好的朋友', 'isUnlocked': false},
        {'id': 3, 'name': '小猫', 'type': '普通', 'rarity': 'common', 'description': '优雅的小猫，喜欢玩耍和睡觉', 'isUnlocked': false},
        {'id': 4, 'name': '小兔', 'type': '普通', 'rarity': 'common', 'description': '活泼的小兔，蹦蹦跳跳非常可爱', 'isUnlocked': false},
      ];
    });
  }

  Future<void> _evolvePet() async {
    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      // 获取宠物列表以获取选中的宠物ID
      final petListRes = await http.get(
        Uri.parse('http://localhost:3000/api/pet/list?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      int petId = 1;
      if (petListRes.statusCode == 200) {
        final petListData = jsonDecode(petListRes.body);
        if (petListData['code'] == 200 && petListData['data'] != null && petListData['data']['selectedPetId'] != null) {
          petId = petListData['data']['selectedPetId'];
        }
      }

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/petAdvance/evolve'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'petId': petId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('🎉 进化成功！'),
                content: Text(data['data']['message'] ?? '进化成功'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadAdvanceData();
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
      print('进化宠物失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('进化失败: $e')),
        );
      }
    }
  }

  Future<void> _unlockPet(int petId) async {
    try {
      final user = _authManager.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      // 获取宠物列表以获取选中的宠物ID
      final petListRes = await http.get(
        Uri.parse('http://localhost:3000/api/pet/list?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      int currentPetId = 1;
      if (petListRes.statusCode == 200) {
        final petListData = jsonDecode(petListRes.body);
        if (petListData['code'] == 200 && petListData['data'] != null && petListData['data']['selectedPetId'] != null) {
          currentPetId = petListData['data']['selectedPetId'];
        }
      }

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/petAdvance/unlockAlbum'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'petId': currentPetId,
          'petIdToUnlock': petId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['data']['message'] ?? '解锁成功'),
                backgroundColor: Colors.green,
              ),
            );
            _loadAlbum();
          }
        }
      }
    } catch (e) {
      print('解锁宠物失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解锁失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('宠物进阶'),
        actions: [
          if (!_isLoading && _hasError)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAllData,
              tooltip: '重试',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    '正在加载宠物数据...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadAllData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('重新加载'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAdvanceTab(),
                          _buildEvolutionAlbumTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: '进阶状态'),
          Tab(text: '进化图鉴'),
        ],
      ),
    );
  }

  Widget _buildAdvanceTab() {
    if (_advanceData == null || _advanceData!['pet'] == null || _advanceData!['advance'] == null) {
      return const Center(child: Text('暂无数据'));
    }

    final pet = _advanceData!['pet'];
    final advance = _advanceData!['advance'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPetInfoCard(pet),
          const SizedBox(height: 20),
          _buildStageCard(advance),
          const SizedBox(height: 20),
          _buildEvolveButton(advance),
        ],
      ),
    );
  }

  Widget _buildPetInfoCard(dynamic pet) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Center(
                    child: Text(
                      _getPetEmoji(pet['type']?.toString()),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet['name']?.toString() ?? '我的宠物',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getPetTypeName(pet['type'])} · ${_getPetFormName(pet['form'])} · Lv.${pet['level'] ?? 1}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (pet['expThreshold'] as num? ?? 100) > 0
                            ? ((pet['exp'] as num? ?? 0) / (pet['expThreshold'] as num? ?? 100)).clamp(0.0, 1.0)
                            : 0.0,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '经验: ${pet['exp'] ?? 0}/${pet['expThreshold'] ?? 100}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatBadge('营养', (pet['nutrition'] as num? ?? 0).toInt(), Colors.green),
                const SizedBox(width: 8),
                _buildStatBadge('快乐', (pet['happiness'] as num? ?? 0).toInt(), Colors.orange),
                const SizedBox(width: 8),
                _buildStatBadge('经验值', (pet['exp'] as num? ?? 0).toInt(), Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard(dynamic advance) {
    if (_advanceData == null || _advanceData!['pet'] == null) {
      return const SizedBox.shrink();
    }
    final pet = _advanceData!['pet'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '当前阶段',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    advance['currentStage']?.toString() ?? '未知阶段',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (advance['stageExpMax'] as num? ?? 100) > 0
                  ? ((advance['stageExp'] as num? ?? 0) / (advance['stageExpMax'] as num? ?? 100)).clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
            const SizedBox(height: 4),
            Text(
              '阶段经验: ${advance['stageExp'] ?? 0}/${advance['stageExpMax'] ?? 100}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '进化条件',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildEvolveCondition(
              '宠物等级',
              (pet['level'] as num? ?? 1).toInt(),
              5, // 等级要求
            ),
            _buildEvolveCondition(
              '阶段经验',
              (advance['stageExp'] as num? ?? 0).toInt(),
              (advance['evolveCondition']?['exp'] as num? ?? 100).toInt(),
            ),
            _buildEvolveCondition(
              '亲密度',
              (pet['intimacy'] as num? ?? 0).toInt(),
              (advance['evolveCondition']?['intimacy'] as num? ?? 50).toInt(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolveCondition(String label, int current, int required) {
    final isMet = current >= required;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $current/$required',
              style: TextStyle(
                color: isMet ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolveButton(dynamic advance) {
    if (_advanceData == null || _advanceData!['pet'] == null) {
      return const SizedBox.shrink();
    }
    final pet = _advanceData!['pet'];
    final levelMet = (pet['level'] as num? ?? 0) >= 5; // 等级要求
    final expMet = (advance['stageExp'] as num? ?? 0) >= (advance['evolveCondition']?['exp'] as num? ?? 100);
    final intimacyMet = (pet['intimacy'] as num? ?? 0) >= (advance['evolveCondition']?['intimacy'] as num? ?? 50);
    final canEvolve = levelMet && expMet && intimacyMet;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canEvolve ? _evolvePet : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canEvolve ? Colors.purple : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          canEvolve ? '进化' : '进化条件未满足',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  String _getPetEmoji(String? type) {
    switch (type) {
      case 'chick':
        return '🐥';
      case 'puppy':
        return '🐶';
      case 'kitten':
        return '🐱';
      case 'bunny':
        return '🐰';
      case '火':
        return '🔥';
      case '水':
        return '💧';
      case '草':
        return '🌿';
      case '电':
        return '⚡';
      case '超能':
        return '🔮';
      case '普通':
        return '⭐';
      default:
        return '🐾';
    }
  }

  String _getPetTypeName(dynamic type) {
    if (type == 'chick') return '小鸡';
    if (type == 'puppy') return '小狗';
    if (type == 'kitten') return '小猫';
    if (type == 'bunny') return '小兔';
    return type?.toString() ?? '未知';
  }

  String _getPetFormName(dynamic form) {
    if (form is int) {
      switch (form) {
        case 0: return '幼年期';
        case 1: return '青少年期';
        case 2: return '成年期';
        case 3: return '成熟期';
      }
    }
    return form?.toString() ?? '未知';
  }

  Widget _buildEvolutionAlbumTab() {
    // 进化图鉴数据，每种宠物至少4个阶段
    final evolutionData = [
      {
        'id': 1,
        'name': '小鸡',
        'type': 'chick',
        'rarity': 'common',
        'description': '可爱的小鸡，毛茸茸的非常惹人喜爱',
        'isUnlocked': true,
        'stages': [
          {'stage': 'baby', 'name': '幼年期', 'description': '绒毛未退，体型小巧'},
          {'stage': 'adolescent', 'name': '青少年期', 'description': '羽毛覆盖，冠部初现'},
          {'stage': 'adult', 'name': '成年期', 'description': '羽毛完整，冠部成熟'},
          {'stage': 'advanced', 'name': '进阶形态', 'description': '羽毛油亮，冠部突出'},
        ]
      },
      {
        'id': 2,
        'name': '小狗',
        'type': 'puppy',
        'rarity': 'common',
        'description': '忠诚的小狗，是人类最好的朋友',
        'isUnlocked': false,
        'stages': [
          {'stage': 'baby', 'name': '幼年期 (2-3个月)', 'description': '软萌依赖期，技能掌握期'},
          {'stage': 'adolescent', 'name': '青少年期 (4-12个月)', 'description': '活泼探索期'},
          {'stage': 'adult', 'name': '成年期 (1-3岁)', 'description': '成熟稳定期'},
          {'stage': 'advanced', 'name': '进阶形态 (3岁以上)', 'description': '掌握坐立、抓手等技能'},
        ]
      },
      {
        'id': 3,
        'name': '小猫',
        'type': 'kitten',
        'rarity': 'common',
        'description': '优雅的小猫，喜欢玩耍和睡觉',
        'isUnlocked': false,
        'stages': [
          {'stage': 'baby', 'name': '幼年期', 'description': '出生2-4周，依赖母猫，行动不便'},
          {'stage': 'adolescent', 'name': '青少年期', 'description': '4-8周，学习爬跳，逐渐独立'},
          {'stage': 'adult', 'name': '成年期', 'description': '8周以上，性格稳定，具备捕猎能力'},
          {'stage': 'advanced', 'name': '进阶形态', 'description': '长期饲养，与人类互动频繁，技能提升'},
        ]
      },
      {
        'id': 4,
        'name': '小兔',
        'type': 'bunny',
        'rarity': 'common',
        'description': '活泼的小兔，蹦蹦跳跳非常可爱',
        'isUnlocked': false,
        'stages': [
          {'stage': 'baby', 'name': '幼年期', 'description': '出生2周，依赖母兔'},
          {'stage': 'adolescent', 'name': '青少年期', 'description': '3-6月，活泼好动'},
          {'stage': 'adult', 'name': '成年期', 'description': '6月以上，成熟稳定，特殊品种，毛发泼变'},
          {'stage': 'advanced', 'name': '进阶形态', 'description': '特殊品种，毛毛发斩变，隐件有击互动物脑感'},
        ]
      },
    ];

    final unlockedCount = evolutionData.where((p) => (p['isUnlocked'] as bool? ?? false)).length;
    final totalCount = evolutionData.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 图鉴统计卡片
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '进化图鉴',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '已解锁: $unlockedCount/$totalCount',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        '${(unlockedCount / totalCount * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 宠物进化列表
          ...evolutionData.map((pet) {
            return Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 宠物基本信息
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pet['name']?.toString() ?? '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      pet['type']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (pet['rarity']?.toString()) == 'legendary' ? Colors.orange.withOpacity(0.1) :
                                             (pet['rarity']?.toString()) == 'rare' ? Colors.purple.withOpacity(0.1) :
                                             Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      (pet['rarity']?.toString()) == 'legendary' ? '传说' :
                                      (pet['rarity']?.toString()) == 'rare' ? '稀有' : '普通',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: (pet['rarity']?.toString()) == 'legendary' ? Colors.orange :
                                               (pet['rarity']?.toString()) == 'rare' ? Colors.purple :
                                               Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pet['description']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!(pet['isUnlocked'] as bool? ?? false))
                          ElevatedButton(
                            onPressed: () => _unlockPet(pet['id'] as int? ?? 0),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('解锁'),
                          )
                        else
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 32,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 进化阶段标题
                    const Text(
                      '进化阶段',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 进化阶段列表
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: (pet['stages'] as List? ?? []).map((stage) {
                          final stageMap = stage as Map? ?? {};
                          final hasDescription = stageMap.containsKey('description');
                          
                          // 根据宠物类型和阶段生成不同的图标和颜色
                          Map<String, dynamic> getPetInfo(String petType, String stage) {
                            switch (petType) {
                              case 'chick':
                                switch (stage) {
                                  case 'baby': return {'emoji': '🐣', 'color': Colors.yellow};
                                  case 'adolescent': return {'emoji': '🐥', 'color': Colors.orange};
                                  case 'adult': return {'emoji': '🐔', 'color': Colors.red};
                                  case 'advanced': return {'emoji': '🦚', 'color': Colors.purple};
                                  default: return {'emoji': '🐔', 'color': Colors.yellow};
                                }
                              case 'puppy':
                                switch (stage) {
                                  case 'baby': return {'emoji': '🐶', 'color': Colors.brown.shade200};
                                  case 'adolescent': return {'emoji': '🐕', 'color': Colors.brown};
                                  case 'adult': return {'emoji': '🦮', 'color': Colors.brown.shade800};
                                  case 'advanced': return {'emoji': '🐺', 'color': Colors.amber};
                                  default: return {'emoji': '🐶', 'color': Colors.brown};
                                }
                              case 'kitten':
                                switch (stage) {
                                  case 'baby': return {'emoji': '🐱', 'color': Colors.grey};
                                  case 'adolescent': return {'emoji': '🐈', 'color': Colors.blueGrey};
                                  case 'adult': return {'emoji': '🐈\u200d⬛', 'color': Colors.grey.shade800};
                                  case 'advanced': return {'emoji': '🦁', 'color': Colors.pink};
                                  default: return {'emoji': '🐱', 'color': Colors.grey};
                                }
                              case 'bunny':
                                switch (stage) {
                                  case 'baby': return {'emoji': '🐰', 'color': Colors.pink.shade200};
                                  case 'adolescent': return {'emoji': '🐇', 'color': Colors.pink};
                                  case 'adult': return {'emoji': '🐇', 'color': Colors.pink.shade800};
                                  case 'advanced': return {'emoji': '🐇', 'color': Colors.white};
                                  default: return {'emoji': '🐰', 'color': Colors.pink};
                                }
                              default:
                                return {'emoji': '🐾', 'color': Colors.grey};
                            }
                          }
                          
                          final petType = pet['type']?.toString() ?? '';
                          final stageName = stageMap['stage']?.toString() ?? '';
                          final petInfo = getPetInfo(petType, stageName);
                          final emoji = petInfo['emoji']?.toString() ?? '🐾';
                          final color = (petInfo['color'] as Color?) ?? Colors.grey;
                          
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.3),
                                        spreadRadius: 4,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        color.withOpacity(0.2),
                                        color.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(
                                        fontSize: 40,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  stageMap['name']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (hasDescription)
                                  const SizedBox(height: 4),
                                if (hasDescription)
                                  Text(
                                    stageMap['description']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
