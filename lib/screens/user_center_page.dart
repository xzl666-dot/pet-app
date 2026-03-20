import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../managers/auth_manager.dart';
import '../managers/pet_growth_manager.dart';
import '../managers/user_ability_manager.dart';
import '../managers/social_challenge_manager.dart';
import '../managers/api_manager.dart';
import '../models/pet_model.dart';
import '../providers/app_state_provider.dart';

class UserCenterPage extends StatefulWidget {
  const UserCenterPage({Key? key}) : super(key: key);

  @override
  State<UserCenterPage> createState() => _UserCenterPageState();
}

class _UserCenterPageState extends State<UserCenterPage> {
  final PetGrowthManager _petManager = PetGrowthManager();
  final UserAbilityManager _abilityManager = UserAbilityManager.instance;
  final SocialChallengeManager _socialManager = SocialChallengeManager.instance;
  
  PetModel? _pet;
  Map<String, dynamic> _userStats = {};
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _todoItems = [];
  bool _isLoading = true;
  bool _hasCheckedInToday = false;

  @override
  void initState() {
    super.initState();
    _loadUserCenterData();
  }

  Future<void> _loadUserCenterData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authManager = Provider.of<AuthManager>(context, listen: false);
      final userId = authManager.currentUser?.userId.toString();
      
      if (userId == null) return;

      // 1. 加载看板数据 (包含宠物和统计)
      final dashboardRes = await ApiManager.instance.getUserDashboard(userId);
      if (dashboardRes['code'] == 200) {
        final data = dashboardRes['data'];
        
        // 映射宠物数据
        if (data['pet'] != null) {
          final petData = data['pet'];
          _pet = PetModel(
            id: petData['id'] ?? 1,
            name: petData['name'] ?? '未命名',
            type: _mapPetType(petData['type']),
            form: _mapPetForm(petData['form']),
            nutrition: petData['nutrition'] ?? 0,
            happiness: petData['happiness'] ?? 0,
            level: petData['level'] ?? 1,
            exp: petData['exp'] ?? 0,
            expThreshold: petData['expThreshold'] ?? 100,
          );
        }

        // 映射统计数据
        final stats = data['statistics'];
        _userStats = {
          'totalTasks': stats['tasks']['total'],
          'completedTasks': stats['tasks']['completed'],
          'studyDays': stats['tasks']['todayTotal'] > 0 ? 1 : 0, // 简化处理
          'consecutiveDays': 0, // 将在打卡接口获取
          'totalChallenges': stats['challenges']['total'],
          'wonChallenges': stats['challenges']['wins'],
          'abilityLevel': data['evaluation']?['currentLevel'] ?? 'D',
          'petGrowthValue': _pet?.exp ?? 0,
        };
      }

      // 2. 加载打卡数据
      final checkInRes = await ApiManager.instance.getCheckInData();
      if (checkInRes['code'] == 200) {
        _hasCheckedInToday = checkInRes['data']['hasCheckedInToday'];
        final checkIns = checkInRes['data']['checkIns'] as List;
        if (checkIns.isNotEmpty) {
          _userStats['consecutiveDays'] = checkIns[0]['continuousDays'];
        }
      }

      // 3. 加载成就数据
      final achievementRes = await ApiManager.instance.getAchievements();
      if (achievementRes['code'] == 200) {
        final list = achievementRes['data'] as List;
        _achievements = list.map((a) => {
          'id': a['id'],
          'title': a['achievementName'],
          'description': '达成条件: ${a['targetValue']}',
          'isUnlocked': a['status'] >= 1,
          'status': a['status'], // 0=未达成, 1=已达成, 2=已领取
          'progress': a['progress'],
          'target': a['targetValue'],
          'icon': _getAchievementIcon(a['achievementKey']),
        }).toList();
      }

      // 4. 加载待办事项 (保持模拟或从任务列表获取)
      _todoItems = await _loadTodoItems();

    } catch (e) {
      print('加载个人中心数据失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  PetType _mapPetType(dynamic type) {
    if (type is int) return PetType.values[type % PetType.values.length];
    return PetType.chick;
  }

  PetForm _mapPetForm(dynamic form) {
    if (form is int) return PetForm.values[form % PetForm.values.length];
    return PetForm.baby;
  }

  IconData _getAchievementIcon(String key) {
    if (key.contains('task')) return Icons.assignment_turned_in;
    if (key.contains('checkin')) return Icons.calendar_today;
    if (key.contains('pet')) return Icons.pets;
    return Icons.star;
  }

  Future<List<Map<String, dynamic>>> _loadTodoItems() async {
    return [
      {
        'id': 'todo_1',
        'title': '完成今日学习任务',
        'description': '保持连续打卡，获得更多积分',
        'priority': 'high',
        'module': '学习任务',
      },
    ];
  }

  Future<void> _handleCheckIn() async {
    if (_hasCheckedInToday) return;
    
    try {
      final res = await ApiManager.instance.checkIn();
      if (res['code'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打卡成功！获得 ${res['data']['rewardPoints']} 积分')),
        );
        _loadUserCenterData(); // 重新加载数据
        // 刷新全局积分
        if (mounted) {
          Provider.of<AppStateProvider>(context, listen: false).loadUserPoints();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['msg'] ?? '打卡失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络错误，请稍后再试')),
      );
    }
  }

  Future<void> _handleClaimReward(int achievementId) async {
    try {
      final res = await ApiManager.instance.claimAchievementReward(achievementId);
      if (res['code'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('领取成功！获得 ${res['data']['rewardPoints']} 积分')),
        );
        _loadUserCenterData();
        // 刷新全局积分
        if (mounted) {
          Provider.of<AppStateProvider>(context, listen: false).loadUserPoints();
        }
      }
    } catch (e) {
      print('领取奖励失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authManager = Provider.of<AuthManager>(context);
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // 用户信息卡片
                _buildUserInfoCard(authManager),
                const SizedBox(height: 24),

                // 核心数据卡片
                _buildCoreDataCards(),
                const SizedBox(height: 24),

                // 宠物养成系统
                _buildPetCard(),
                const SizedBox(height: 24),

                // 学习进度与打卡系统
                _buildStudyProgressCard(),
                const SizedBox(height: 24),

                // 成就系统
                _buildAchievementsCard(),
                const SizedBox(height: 24),

                // 待办事项
                _buildTodoItemsCard(),
                const SizedBox(height: 24),

                // 功能选项
                _buildFunctionMenu(),
                const SizedBox(height: 24),

                // 其他选项
                _buildOtherMenu(authManager),
              ],
            ),
    );
  }

  Widget _buildUserInfoCard(AuthManager authManager) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authManager.currentUser?.nickname ?? '用户',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authManager.currentUser?.username ?? '未登录',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text('等级 ${_userStats['abilityLevel'] ?? 1}'),
                        backgroundColor: Colors.blue[100],
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('学习${_userStats['studyDays'] ?? 0}天'),
                        backgroundColor: Colors.green[100],
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreDataCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '核心数据',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildDataCard(
              title: '宠物成长值',
              value: '${_userStats['petGrowthValue'] ?? 0}',
              icon: Icons.pets,
              color: Colors.pink,
            ),
            _buildDataCard(
              title: '完成任务数',
              value: '${_userStats['completedTasks'] ?? 0}/${_userStats['totalTasks'] ?? 0}',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _buildDataCard(
              title: '挑战胜率',
              value: '${(_userStats['totalChallenges'] ?? 0) > 0 ? ((_userStats['wonChallenges'] ?? 0) * 100 ~/ (_userStats['totalChallenges'] ?? 1)) : 0}%',
              icon: Icons.emoji_events,
              color: Colors.yellow,
            ),
            _buildDataCard(
              title: '连续打卡',
              value: '${_userStats['consecutiveDays'] ?? 0}天',
              icon: Icons.calendar_today,
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '宠物养成',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/pet_advance');
                  },
                  child: const Text('详情'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_pet != null)
              Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.yellow[100],
                        ),
                        child: const Icon(Icons.pets, size: 40, color: Colors.yellow),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pet!.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('等级: ${_pet!.level}'),
                            Text('形态: ${_pet!.form.getFormName()}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 宠物属性
                  Row(
                    children: [
                      Expanded(
                        child: _buildPetAttributeBar('营养', _pet!.nutrition),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPetAttributeBar('快乐', _pet!.happiness),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 宠物经验
                  _buildPetExpBar(),
                ],
              )
            else
              const Text('暂无宠物数据'),
          ],
        ),
      ),
    );
  }

  Widget _buildPetAttributeBar(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$value%'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildPetExpBar() {
    if (_pet == null) return Container();
    final expPercentage = _pet!.exp / _pet!.expThreshold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('经验'),
            Text('${_pet!.exp}/${_pet!.expThreshold}'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: expPercentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildStudyProgressCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '学习进度',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/learning_center');
                  },
                  child: const Text('详情'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 学习统计
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStudyStat('总学习天数', '${_userStats['studyDays'] ?? 0}天'),
                _buildStudyStat('连续打卡', '${_userStats['consecutiveDays'] ?? 0}天'),
                _buildStudyStat('完成任务', '${_userStats['completedTasks'] ?? 0}个'),
              ],
            ),
            const SizedBox(height: 16),
            // 今日打卡
            _buildCheckInButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCheckInButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _hasCheckedInToday ? null : _handleCheckIn,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
          textStyle: const TextStyle(fontSize: 18),
          backgroundColor: _hasCheckedInToday ? Colors.grey : null,
        ),
        child: Text(_hasCheckedInToday ? '今日已打卡' : '今日打卡'),
      ),
    );
  }

  Widget _buildAchievementsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '我的成就',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('${_achievements.where((a) => a['isUnlocked'] == true).length}/${_achievements.length}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: _achievements.take(3).map((achievement) => _buildAchievementItem(achievement)).toList(),
            ),
            if (_achievements.length > 3)
              TextButton(
                onPressed: () {
                  // 显示全部成就
                },
                child: const Text('查看全部成就'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: achievement['isUnlocked'] == true ? Colors.yellow[100] : Colors.grey[200],
            ),
            child: Icon(
              achievement['icon'],
              size: 24,
              color: achievement['isUnlocked'] == true ? Colors.yellow : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: achievement['isUnlocked'] == true ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  achievement['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (achievement['isUnlocked'] != true && achievement.containsKey('progress'))
                  LinearProgressIndicator(
                    value: achievement['progress'] / achievement['target'],
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
              ],
            ),
          ),
          if (achievement['status'] == 1)
            ElevatedButton(
              onPressed: () => _handleClaimReward(achievement['id']),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(60, 30),
              ),
              child: const Text('领取', style: TextStyle(fontSize: 12)),
            )
          else if (achievement['status'] == 2)
            const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildTodoItemsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '待办事项',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_todoItems.isNotEmpty)
                  Chip(
                    label: Text('${_todoItems.length}个'),
                    backgroundColor: Colors.red[100],
                    labelStyle: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_todoItems.isNotEmpty)
              Column(
                children: _todoItems.map((todo) => _buildTodoItem(todo)).toList(),
              )
            else
              const Text('暂无待办事项', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoItem(Map<String, dynamic> todo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    todo['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Chip(
                    label: Text(todo['module']),
                    backgroundColor: Colors.grey[100],
                    labelStyle: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(todo['description'], style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    // 处理待办事项
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('处理成功！')),
                    );
                  },
                  child: const Text('立即处理'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '功能中心',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),

        // 挑战中心
        _buildMenuItem(
          icon: Icons.emoji_events,
          title: '挑战中心',
          onTap: () {
            Navigator.pushNamed(context, '/social');
          },
        ),




        // 物品管理
        _buildMenuItem(
          icon: Icons.inventory_2,
          title: '我的物品',
          onTap: () {
            Navigator.pushNamed(context, '/items');
          },
        ),

        // 通知设置
        _buildMenuItem(
          icon: Icons.notifications,
          title: '通知设置',
          onTap: () {
            Navigator.pushNamed(context, '/notification_settings');
          },
        ),
      ],
    );
  }

  Widget _buildOtherMenu(AuthManager authManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '其他',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),

        // 关于我们
        _buildMenuItem(
          icon: Icons.info,
          title: '关于我们',
          onTap: () {
            // 显示关于我们对话框
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('关于我们'),
                content: const Text('宠物养成APP v1.0.0\n\n帮助用户通过完成学习任务和挑战，养成虚拟宠物，提升自我能力。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('确定'),
                  ),
                ],
              ),
            );
          },
        ),

        // 退出登录
        _buildMenuItem(
          icon: Icons.logout,
          title: '退出登录',
          onTap: () {
            // 显示退出登录确认对话框
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('退出登录'),
                content: const Text('确定要退出登录吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await authManager.logout();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
            );
          },
          isLogout: true,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : Theme.of(context).primaryColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red : Colors.black,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

