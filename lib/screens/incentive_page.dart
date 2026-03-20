import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../models/incentive_model.dart';
import '../providers/app_state_provider.dart';
import '../models/pet_model.dart';
import '../models/user_model.dart';
import '../managers/auth_manager.dart';
import '../managers/pet_state_manager.dart';
import '../managers/api_manager.dart';
import '../utils/token_util.dart';

class IncentivePage extends StatefulWidget {
  const IncentivePage({Key? key}) : super(key: key);

  @override
  State<IncentivePage> createState() => _IncentivePageState();
}

class _IncentivePageState extends State<IncentivePage> {
  final _authManager = AuthManager.instance;
  final _petManager = PetStateManager.instance;
  IncentiveModel? _incentiveData;
  PetModel? _pet;
  User? _user;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadIncentiveData();
  }

  Future<void> _loadIncentiveData() async {
    setState(() => _isLoading = true);
    
    try {
      _user = _authManager.currentUser;
      if (_user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final userId = (_user!.userId ?? _user!.id).toString();
      
      // 1. 使用统一的 ApiManager 获取宠物列表
      final petListRes = await ApiManager.instance.getPetList(userId);
      if (petListRes['code'] != 200) {
        throw Exception(petListRes['msg'] ?? '获取宠物列表失败');
      }
      
      final petList = petListRes['data']['petList'] ?? [];
      if (petList.isEmpty) {
        throw Exception('没有宠物数据');
      }
      
      // 找到选中的宠物
      final selectedPetId = petListRes['data']['selectedPetId'];
      final petData = selectedPetId != null
          ? petList.firstWhere((pet) => pet['petId'] == selectedPetId, orElse: () => petList[0])
          : petList[0];
      
      _pet = PetModel.fromMap(petData);
      final petId = _pet!.id.toString();
      
      // 2. 使用统一的 ApiManager 获取激励核心数据
      final response = await ApiManager.instance.getIncentiveCore(userId, petId);

      if (response['code'] == 200) {
        setState(() {
          _incentiveData = IncentiveModel.fromJson(response['data']);
          _isLoading = false;
        });
        // 3. 同步到全局状态
        if (mounted) {
          Provider.of<AppStateProvider>(context, listen: false)
              .updateUserPoints(_incentiveData!.integral);
        }
        print('激励数据加载成功: ${_incentiveData!.integral}');
      } else {
        throw Exception(response['msg'] ?? '加载失败');
      }
    } catch (e) {
      print('加载激励数据失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载激励数据失败: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('激励中心'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在加载激励数据...'),
            ],
          ),
        ),
      );
    }

    if (_incentiveData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('激励中心'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('加载失败，请重试'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadIncentiveData,
                child: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('激励中心'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          _buildCoreDataCard(),
          _buildTabBar(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreDataCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              return _buildDataItem('当前积分', appState.userPoints.toString(), Colors.blue);
            },
          ),
          _buildDataItem('累计获取', _incentiveData!.integralGet.toString(), Colors.green),
          _buildDataItem('累计消耗', _incentiveData!.integralConsume.toString(), Colors.orange),
        ],
      ),
    );
  }

  Widget _buildDataItem(String label, String value, Color color) {
    return Column(
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
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem('积分兑换', 0),
          ),
          Expanded(
            child: _buildTabItem('成就', 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildIntegralExchange();
      case 1:
        return _buildAchievements();
      default:
        return const SizedBox.shrink();
    }
  }



  Widget _buildIntegralExchange() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPreferenceSection(),
        const SizedBox(height: 24),
        _buildCategorySection('营养类', [
          _buildExchangeItem('鲜鲜羊奶包', 'fresh_milk_pack', 50, Icons.local_drink, 0, 6),
          _buildExchangeItem('冻干三文鱼块', 'frozen_salmon', 120, Icons.food_bank, 0, 3),
        ]),
        const SizedBox(height: 16),
        _buildCategorySection('快乐类', [
          _buildExchangeItem('彩虹逗猫棒', 'rainbow_cat_stick', 50, Icons.color_lens, 1, 6),
          _buildExchangeItem('星空泡泡机', 'star_bubble_machine', 120, Icons.bubble_chart, 1, 3),
        ]),
        const SizedBox(height: 16),
        _buildCategorySection('亲密度类', [
          _buildExchangeItem('爱心曲奇', 'love_cookie', 150, Icons.favorite, 2, 2),
          _buildExchangeItem('春日樱花糕', 'spring_cherry_cake', 300, Icons.local_florist, 2, 1),
        ]),
        const SizedBox(height: 16),
        _buildCategorySection('经验类', [
          _buildExchangeItem('成长奶昔', 'growth_shake', 200, Icons.local_cafe, 3, 1),
          _buildExchangeItem('经验饼干', 'exp_cookie', 250, Icons.cookie, 3, 1),
          _buildExchangeItem('超级经验蛋糕', 'super_exp_cake', 400, Icons.cake, 3, 1),
        ]),
      ],
    );
  }

  Widget _buildCategorySection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildPreferenceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.blue[700], size: 24),
              const SizedBox(width: 8),
              Text(
                '激励偏好设置',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '设置您的激励偏好，系统将优先推荐相关任务',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPreferenceChip('营养类', 0),
              _buildPreferenceChip('快乐类', 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceChip(String label, int benefitType) {
    final isSelected = _incentiveData?.incentivePrefer['preferredBenefitType'] == benefitType;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _syncPreference(benefitType);
        }
      },
      selectedColor: Colors.blue[200],
      checkmarkColor: Colors.blue[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue[700] : Colors.black,
      ),
    );
  }

  Widget _buildExchangeItem(String name, String itemId, int cost, IconData icon, int benefitType, int dailyLimit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '消耗: $cost 积分',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '每日上限: $dailyLimit 个',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              final canExchange = appState.userPoints >= cost;
              return ElevatedButton(
                onPressed: canExchange
                    ? () => _exchangeItem(itemId, 1, cost, benefitType, dailyLimit)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canExchange
                      ? Colors.blue
                      : Colors.grey[300],
                  minimumSize: const Size(44, 44),
                ),
                child: const Text('兑换'),
              );
            },
          ),
        ],
      ),
    );
  }



  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAchievements() {
    final achievements = [
      {
        'id': 'first_task',
        'name': '初出茅庐',
        'description': '完成第一个任务',
        'icon': Icons.task,
        'unlocked': true,
      },
      {
        'id': 'daily_streak',
        'name': '每日坚持',
        'description': '连续7天完成任务',
        'icon': Icons.calendar_today,
        'unlocked': false,
      },
      {
        'id': 'pet_master',
        'name': '宠物大师',
        'description': '宠物等级达到10级',
        'icon': Icons.pets,
        'unlocked': false,
      },
      {
        'id': 'task_master',
        'name': '任务达人',
        'description': '完成100个任务',
        'icon': Icons.check_circle,
        'unlocked': false,
      },
      {
        'id': 'lucky_winner',
        'name': '幸运儿',
        'description': '抽奖获得稀有道具',
        'icon': Icons.card_giftcard,
        'unlocked': false,
      },
      {
        'id': 'social_king',
        'name': '社交王者',
        'description': '参与10次社交挑战',
        'icon': Icons.people,
        'unlocked': false,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('我的成就'),
        const SizedBox(height: 16),
        ...achievements.map((achievement) => _buildAchievementItem(achievement)).toList(),
      ],
    );
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
    final isUnlocked = achievement['unlocked'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.yellow[200] : Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              achievement['icon'] as IconData,
              size: 32,
              color: isUnlocked ? Colors.yellow[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['name'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.black : Colors.grey[500],
                  ),
                ),
                Text(
                  achievement['description'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: isUnlocked ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isUnlocked ? Icons.check_circle : Icons.lock,
            color: isUnlocked ? Colors.green : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Future<void> _exchangeItem(String itemId, int itemNum, int cost, int benefitType, int dailyLimit) async {
    try {
      final userId = (_user!.userId ?? _user!.id).toString();
      final petId = _pet!.id.toString();
      
      final response = await ApiManager.instance.exchangeItem(
        userId,
        petId,
        itemId,
        itemNum,
      );

      if (response['code'] == 200) {
        // 记录用户偏好
        _syncPreference(benefitType);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['msg']),
            backgroundColor: Colors.green,
          ),
        );
        _loadIncentiveData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['msg']),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('积分兑换失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('积分兑换失败，请重试'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _syncPreference(int benefitType) async {
    try {
      final userId = (_user!.userId ?? _user!.id).toString();
      final petId = _pet!.id.toString();
      
      final response = await ApiManager.instance.syncIncentivePreference(
        userId,
        petId,
        {'preferredBenefitType': benefitType},
      );

      if (response['code'] == 200) {
        print('偏好同步成功: ${response['data']['incentivePrefer']}');
        _loadIncentiveData();
      }
    } catch (e) {
      print('偏好同步失败: $e');
    }
  }

  Future<void> _receiveWelfare(String welfareType) async {
    try {
      final userId = (_user!.userId ?? _user!.id).toString();
      final petId = _pet!.id.toString();
      
      Map<String, dynamic> response;
      if (welfareType == 'weekly_task') {
        response = await ApiManager.instance.receiveWeeklyTaskReward(userId, petId, 10);
      } else if (welfareType == 'monthly_welfare') {
        response = await ApiManager.instance.receiveMonthlyWelfare(userId, petId, _incentiveData!.abilityLevel);
      } else {
        response = await ApiManager.instance.receiveWelfare(userId, petId, welfareType);
      }

      if (response['code'] == 200) {
        String message = response['msg'];
        if (response['data'] != null) {
          if (response['data']['reward'] != null) {
            message += '，获得${response['data']['reward']['value']}积分';
          } else if (response['data']['weeklyReward'] != null) {
            message += '，获得${response['data']['weeklyReward']}积分';
          } else if (response['data']['monthlyReward'] != null) {
            message += '，获得${response['data']['monthlyReward']}积分';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
        _loadIncentiveData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['msg']),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('领取福利失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('领取福利失败，请重试'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signIn() async {
    try {
      final userId = (_user!.userId ?? _user!.id).toString();
      final petId = _pet!.id.toString();
      
      final response = await ApiManager.instance.signIn(userId, petId);

      if (response['code'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${response['msg']}，获得${response['data']['reward']['value']}积分'),
            backgroundColor: Colors.green,
          ),
        );
        _loadIncentiveData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['msg']),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('签到失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('签到失败，请重试'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _tryUnlockAchievement(String achievementId) async {
    try {
      final userId = (_user!.userId ?? _user!.id).toString();
      final petId = _pet!.id.toString();
      
      final response = await ApiManager.instance.unlockAchievement(userId, petId, achievementId);

      if (response['code'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${response['msg']}，获得${response['data']['reward']['value']}积分'),
            backgroundColor: Colors.green,
          ),
        );
        _loadIncentiveData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['msg']),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('解锁成就失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('解锁成就失败，请重试'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
