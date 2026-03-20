import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/pet_model.dart';
import '../managers/pet_state_manager.dart';
import '../managers/pet_growth_manager.dart';
import '../widgets/pet_interaction_widget.dart';
import '../screens/learning_center_page.dart';
import '../screens/npc_challenge_page.dart';
import '../screens/user_center_page.dart';
import '../managers/data_statistics_manager.dart';
import '../utils/data_export_util.dart';
import '../managers/auth_manager.dart';
import '../utils/token_util.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _petManager = PetStateManager.instance;
  final _statsManager = DataStatisticsManager.instance;
  final _petGrowthManager = PetGrowthManager();
  final _exportUtil = DataExportUtil.instance;
  PetModel? _pet;
  bool _isPetAnimating = false;
  int _interactionCount = 0;
  DateTime _lastInteractionDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPet();
    _startUsageTimer();
  }

  // 加载宠物数据
  Future<void> _loadPet() async {
    try {
      final authManager = AuthManager.instance;
      final user = authManager.currentUser;

      print('=== 加载宠物数据 ===');
      print('用户信息: $user');

      if (user != null) {
        final token = await TokenUtil.instance.getAccessToken();
        final userId = user.userId ?? user.id;

        print('Token: $token');
        print('UserId: $userId');

        if (token != null && userId != null) {
          // 从后端加载宠物列表
          final response = await http.get(
            Uri.parse('http://localhost:3000/api/pet/list?userId=$userId'),
            headers: {
              'Content-Type': 'application/json',
              'token': token,
            },
          );

          print('宠物列表响应状态码: ${response.statusCode}');
          print('宠物列表响应内容: ${response.body}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            print('data type: ${data.runtimeType}');
            print('data: $data');
            print('data[code] type: ${data['code']?.runtimeType}');
            print('data[code] value: ${data['code']}');
            if (data['code'] == 200) {
              final petList = data['data']['petList'] ?? [];
              final total = data['data']['total'] ?? 0;

              print('宠物数量: $total');
              print('petList length: ${petList.length}');

              if (total > 0) {
                // 有宠物，优先使用选中的宠物
                final selectedPetId = data['data']['selectedPetId'];
                final petData = selectedPetId != null
                    ? petList.firstWhere((pet) => pet['petId'] == selectedPetId, orElse: () => petList[0])
                    : petList[0];
                print('宠物数据: $petData');
                print('petName: ${petData['petName']}');
                print('petType: ${petData['petType']}');
                print('createTime: ${petData['createTime']}');
                
                final pet = PetModel(
                  id: petData['petId'],
                  name: petData['petName'] ?? '我的宠物',
                  type: _parsePetType(petData['petType']),
                  form: PetForm.baby, // 新宠物默认为幼年期
                  nutrition: petData['nutrition'] ?? 100,
                  happiness: petData['happiness'] ?? 100,
                  intimacy: petData['intimacy'] ?? 0,
                  exp: petData['exp'] ?? 0,
                  level: petData['level'] ?? 1,
                  expThreshold: petData['expThreshold'] ?? 100,
                  createdAt: petData['createTime'] != null 
                      ? DateTime.tryParse(petData['createTime']) ?? DateTime.now()
                      : DateTime.now(),
                  lastUpdated: DateTime.now(),
                );

                print('即将设置宠物对象: $pet');
                print('宠物名称: ${pet.name}');
                print('宠物类型: ${pet.type}');

                // 检查是否需要升级
                await _checkAndHandleLevelUp(pet);
                
                // 检查是否需要进化
                await _checkAndHandleEvolution(pet);

                setState(() {
                  _pet = pet;
                });

                print('宠物对象已设置，_pet = $_pet');
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      print('加载宠物数据失败: $e');
    }
  }

  PetType _parsePetType(String? typeStr) {
    if (typeStr == null) return PetType.chick;
    
    switch (typeStr) {
      case 'chick':
        return PetType.chick;
      case 'puppy':
        return PetType.puppy;
      case 'kitten':
        return PetType.kitten;
      case 'bunny':
        return PetType.bunny;
      default:
        return PetType.chick;
    }
  }

  // 开始使用时长计时器
  void _startUsageTimer() {
    // 每1分钟更新一次使用时长
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _statsManager.updateDailyUsageDuration(1);
    });
  }

  DateTime? _lastInteractionTime;
  
  // 处理宠物点击事件
  Future<void> _handlePetTap() async {
    setState(() {
      _isPetAnimating = true;
    });
    
    // 检查是否是新的一天
    final today = DateTime.now();
    if (today.day != _lastInteractionDate.day || 
        today.month != _lastInteractionDate.month || 
        today.year != _lastInteractionDate.year) {
      _interactionCount = 0;
      _lastInteractionDate = today;
    }
    
    // 检查互动间隔
    if (_lastInteractionTime != null) {
      final timeDiff = today.difference(_lastInteractionTime!);
      if (timeDiff.inMinutes < 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('互动间隔需≥1分钟'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        // 1秒后停止动画
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _isPetAnimating = false;
            });
          }
        });
        return;
      }
    }
    
    // 增加经验值（每日限3次）
    if (_interactionCount < 3) {
      await _petGrowthManager.updatePetExp(5);
      _interactionCount++;
    }
    
    // 增加亲密度（每次+3，无每日上限）
    await _updatePetIntimacy(3);
    _lastInteractionTime = today;
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('互动成功！获得3亲密度${_interactionCount < 3 ? '，获得5经验值，今日剩余次数：${3 - _interactionCount}' : ''}'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    // 1秒后停止动画
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isPetAnimating = false;
        });
      }
    });
  }
  
  // 更新宠物亲密度
  Future<void> _updatePetIntimacy(int intimacyGain) async {
    try {
      final user = AuthManager.instance.currentUser;
      if (user == null) return;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/pet/updateStatus'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'petId': _pet?.id ?? 1,
          'intimacy': (_pet?.intimacy ?? 0) + intimacyGain,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          // 更新本地宠物数据
          if (_pet != null) {
            setState(() {
              _pet = _pet!.copyWith(
                intimacy: (_pet!.intimacy ?? 0) + intimacyGain,
              );
            });
          }
        }
      }
    } catch (e) {
      print('更新亲密度失败: $e');
    }
  }

  // 导出数据
  Future<void> _exportData() async {
    try {
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      final statistics = await _statsManager.getStatisticsByDateRange(lastWeek, now);
      
      if (statistics.isNotEmpty) {
        final filePath = await _exportUtil.exportToCSV(statistics, 'app_statistics_');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('数据导出成功：$filePath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有可导出的数据')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据导出失败：$e')),
      );
    }
  }

  // 检查并处理升级
  Future<void> _checkAndHandleLevelUp(PetModel pet) async {
    if (pet.exp >= pet.expThreshold) {
      // 经验满了，需要升级
      try {
        final user = AuthManager.instance.currentUser;
        if (user == null) return;

        final token = await TokenUtil.instance.getAccessToken();
        final userId = user.userId ?? user.id;

        if (token != null && userId != null) {
          final response = await http.post(
            Uri.parse('http://localhost:3000/api/pet/levelUp'),
            headers: {
              'Content-Type': 'application/json',
              'token': token,
            },
            body: jsonEncode({
              'userId': userId,
              'petId': pet.id,
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['code'] == 200) {
              // 升级成功，显示提示
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('恭喜！宠物升级到 ${pet.level + 1} 级'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        print('升级失败: $e');
      }
    }
  }

  // 检查并处理进化
  Future<void> _checkAndHandleEvolution(PetModel pet) async {
    // 进化等级条件：20级（幼体→成体）、40级（成体→高阶）、70级（高阶→终极）
    int? evolveLevel;
    String? evolveStage;

    switch (pet.form) {
      case PetForm.baby:
        if (pet.level >= 20) {
          evolveLevel = 20;
          evolveStage = '成体';
        }
        break;
      case PetForm.adolescent:
        if (pet.level >= 40) {
          evolveLevel = 40;
          evolveStage = '高阶';
        }
        break;
      case PetForm.adult:
        if (pet.level >= 70) {
          evolveLevel = 70;
          evolveStage = '终极';
        }
        break;
      case PetForm.advanced:
        // 终极形态，无需再进化
        break;
    }

    if (evolveLevel != null && evolveStage != null) {
      // 达到进化条件，提示用户
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('进化提示'),
            content: Text('宠物已达到 $evolveLevel 级，可以进化为 $evolveStage 形态了！'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // 导航到宠物进阶页面
                  Navigator.pushNamed(context, '/pet_advance');
                },
                child: const Text('去进化'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('稍后'),
              ),
            ],
          ),
        );
      }
    }
  }

  // 获取宠物状态
  String _getPetStatus() {
    if (_pet == null) return '未知';
    
    if (_pet!.nutrition <= 0) {
      return '萎靡';
    } else if (_pet!.nutrition < 30) {
      return '饥饿';
    } else if (_pet!.nutrition < 80) {
      return '正常';
    } else {
      return '良好';
    }
  }

  // 退出登录
  Future<void> _logout() async {
    try {
      await AuthManager.instance.logout();
      // 导航回登录页面，替换当前导航栈，避免用户返回
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('退出登录失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('宠物养成'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 宠物交互区域
            if (_pet != null)
              Column(
                children: [
                  PetInteractionWidget(
                    pet: _pet!,
                    isAnimating: _isPetAnimating,
                    onTap: _handlePetTap,
                  ),
                  const SizedBox(height: 20),
                  // 宠物属性面板
                  _buildPetStatsCard(),
                ],
              ),
            const SizedBox(height: 40),
            // 宠物养成功能 - 响应式布局
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  // 宠物喂养
                  _buildFeatureCard(
                    context,
                    icon: Icons.restaurant,
                    title: '宠物喂养',
                    description: '喂养宠物，增加营养值',
                    onTap: () async {
                      // 导航到物品页面使用营养丹
                      final result = await Navigator.pushNamed(context, '/items');
                      if (result == true) {
                        _loadPet(); // 刷新宠物数据
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // 宠物状态
                  _buildFeatureCard(
                    context,
                    icon: Icons.stacked_line_chart,
                    title: '宠物状态',
                    description: '查看宠物详细属性和成长记录',
                    onTap: () {
                      // 导航到宠物进阶页面
                      Navigator.pushNamed(context, '/pet_advance');
                    },
                  ),

                  // 管理员模式入口，只有管理员可以看到
                  if (AuthManager.instance.isAdmin)
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildFeatureCard(
                          context,
                          icon: Icons.admin_panel_settings,
                          title: '管理员模式',
                          description: '查看和管理所有用户账号',
                          onTap: () {
                            Navigator.pushNamed(context, '/admin');
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 构建宠物属性面板
  Widget _buildPetStatsCard() {
    if (_pet == null) return Container();
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '宠物属性',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('等级', '${_pet!.level}/100'),
                _buildStatItem('经验', '${_pet!.exp}/${_pet!.expThreshold}'),
                _buildStatItem('形态', _pet!.form.getFormName()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('营养值', '${_pet!.nutrition}%'),
                _buildStatItem('快乐值', '${_pet!.happiness}%'),
                _buildStatItem('亲密度', '${_pet!.intimacy}'),
              ],
            ),
            const SizedBox(height: 16),
            _buildAttributeWarnings(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('经验值', '${_pet!.exp}'),
                _buildStatItem('互动次数', '$_interactionCount/3'),
                _buildStatItem('状态', _getPetStatus()),
              ],
            ),
            const SizedBox(height: 16),
            // 经验条
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('经验进度'),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _pet!.exp / _pet!.expThreshold,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建属性警告
  Widget _buildAttributeWarnings() {
    final warnings = <Widget>[];

    if (_pet!.nutrition < 60) {
      warnings.add(
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '营养值过低（${_pet!.nutrition}%），无法参与挑战',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pet!.happiness < 60) {
      warnings.add(
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '快乐值过低（${_pet!.happiness}%），无法互动，亲密度停止增长',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: warnings,
    );
  }

  // 构建属性项
  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // 构建功能卡片
  Widget _buildFeatureCard(
    BuildContext context,
    {required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(28.0),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 36,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.displayLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          softWrap: true,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: Theme.of(context).primaryColor.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

