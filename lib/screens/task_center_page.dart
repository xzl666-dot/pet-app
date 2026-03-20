import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../managers/pet_growth_manager.dart';
import '../managers/api_manager.dart';
import '../managers/auth_manager.dart';
import '../utils/token_util.dart';
import '../providers/app_state_provider.dart';

class TaskCenterPage extends StatefulWidget {
  const TaskCenterPage({Key? key}) : super(key: key);

  @override
  State<TaskCenterPage> createState() => _TaskCenterPageState();
}

class _TaskCenterPageState extends State<TaskCenterPage> {
  final _petGrowthManager = PetGrowthManager();
  List<TaskCategory> _categories = [];
  List<Task> _dailyTasks = [];
  List<Task> _weeklyTasks = [];
  List<Task> _monthlyTasks = [];
  Map<String, dynamic>? _assessment;
  int _stateCode = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTaskData();
  }

  Future<void> _loadTaskData() async {
    print('TaskCenterPage: 开始加载任务数据');
    setState(() => _isLoading = true);
    try {
      // 并行加载：积分和任务数据独立加载，不需要等待
      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
      
      // 异步加载积分（不阻塞主流程）
      appStateProvider.loadUserPoints().then((_) {
        print('TaskCenterPage: 积分加载完成');
      }).catchError((e) {
        print('TaskCenterPage: 积分加载失败: $e');
      });

      // 同时加载推荐任务（并行执行）
      final recommendRes = await ApiManager.instance.getTaskRecommend();
      if (recommendRes['code'] == 200) {
        final data = recommendRes['data'];
        if (data != null) {
          _dailyTasks = (data['daily'] as List?)?.map((t) => Task.fromMap(t)).toList() ?? [];
          _weeklyTasks = (data['weekly'] as List?)?.map((t) => Task.fromMap(t)).toList() ?? [];
          _monthlyTasks = (data['monthly'] as List?)?.map((t) => Task.fromMap(t)).toList() ?? [];
          _assessment = data['assessment'];
          _stateCode = data['stateCode'] ?? 0;
          print('TaskCenterPage: 任务数据加载完成 - 日常:${_dailyTasks.length}, 周常:${_weeklyTasks.length}, 月度:${_monthlyTasks.length}, 状态: $_stateCode');
        }
      } else {
        print('TaskCenterPage: 任务加载失败: ${recommendRes['msg']}');
      }

      _categories = [
        TaskCategory(name: '核心学习类', icon: Icons.school, color: Colors.blue),
        TaskCategory(name: '学业进阶类', icon: Icons.book, color: Colors.green),
        TaskCategory(name: '校园生活类', icon: Icons.account_balance, color: Colors.orange),
        TaskCategory(name: '健康作息类', icon: Icons.fitness_center, color: Colors.purple),
        TaskCategory(name: '自我提升类', icon: Icons.trending_up, color: Colors.pink),
        TaskCategory(name: '社交实践类', icon: Icons.people, color: Colors.indigo),
        TaskCategory(name: '休闲放松类', icon: Icons.beach_access, color: Colors.red),
      ];

    } catch (e) {
      print('加载任务数据失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeTask(Task task) async {
    try {
      print('正在完成任务: ${task.id} - ${task.title}');
      final taskIdInt = int.tryParse(task.id);
      if (taskIdInt == null) {
        print('错误: 任务ID无效: ${task.id}');
        return;
      }
      
      final res = await ApiManager.instance.finishTask(taskIdInt, true);
      print('完成任务响应: code=${res['code']}, data=${res['data']}');
      
      if (res['code'] == 200) {
        setState(() {
          task.isCompleted = true;
        });
        
        // 获取返回的积分奖励信息
        final rewardData = res['data'] as Map<String, dynamic>?;
        final rewardIntegral = rewardData?['finalIntegral'] ?? rewardData?['reward'] ?? 0;
        final totalIntegral = rewardData?['integral'] ?? 0;
        
        print('任务奖励积分: $rewardIntegral, 总积分: $totalIntegral');
        
        // 立即更新全局积分（如果有返回值）
        if (totalIntegral > 0 && mounted) {
          Provider.of<AppStateProvider>(context, listen: false).updateUserPoints(totalIntegral);
          print('全局积分已更新为: $totalIntegral');
        }
        
        // 显示积分获得反馈
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('任务完成！获得 $rewardIntegral 积分奖励' + (totalIntegral > 0 ? '，总积分: $totalIntegral' : '')),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // 延迟刷新任务列表和积分数据
        Future.delayed(const Duration(milliseconds: 800), () async {
          if (mounted) {
            await _loadTaskData();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('任务完成失败: ${res['msg'] ?? '未知错误'}')),
        );
      }
    } catch (e) {
      print('完成任务失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('完成任务出错: $e')),
      );
    }
  }

  Future<void> _startAssessment() async {
    try {
      final res = await ApiManager.instance.startAbilityAssessment();
      if (res['code'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('能力评估已开启，有效期24小时')),
        );
        _loadTaskData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['msg'] ?? '开启失败')),
        );
      }
    } catch (e) {
      print('开启评估失败: $e');
    }
  }



  void _openCategoryTasks(TaskCategory category) {
    // 打开分类任务页面
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text(category.name),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 显示对应分类的任务
                ..._getTasksByCategory(category.name).map((task) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: task.isCompleted,
                        onChanged: (value) {
                          if (value == true) {
                            _completeTask(task);
                          }
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.title, style: const TextStyle(fontSize: 14)),
                            Text('难度: ${task.difficulty} | 奖励: ${task.points}积分', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                if (_getTasksByCategory(category.name).isEmpty)
                  const Text('该分类暂无任务'),
              ],
            ),
          ),
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

  List<Task> _getTasksByCategory(String categoryName) {
    // 合并所有任务列表
    final allTasks = [..._dailyTasks, ..._weeklyTasks, ..._monthlyTasks];
    // 过滤出对应分类的任务
    return allTasks.where((task) => task.category == categoryName).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务中心'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部信息栏
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('我的积分', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      Consumer<AppStateProvider>(
                        builder: (context, appState, child) {
                          return Text('${appState.userPoints}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pinkAccent));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 能力评估入口 ( 问题 2.8)
            _buildAssessmentCard(),
            const SizedBox(height: 20),

            // 状态标记入口 ( 问题 4)
            _buildStateSelectionCard(),
            const SizedBox(height: 20),

            // 添加自定义任务入口 ( 问题 3)
            _buildAddCustomTaskCard(),
            const SizedBox(height: 20),

            // 任务分类
            const Text('任务分类', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return GestureDetector(
                  onTap: () => _openCategoryTasks(category),
                  child: Container(
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(category.icon, color: category.color, size: 32),
                        const SizedBox(height: 8),
                        Text(category.name, style: TextStyle(color: category.color, fontSize: 12), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 日常任务
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('每日任务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('剩余3/3', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            ..._dailyTasks.map((task) => _buildTaskCard(task)).toList(),
            const SizedBox(height: 24),

            // 周常任务
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('周常任务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('剩余2/2', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            ..._weeklyTasks.map((task) => _buildTaskCard(task)).toList(),
            const SizedBox(height: 24),

            // 月度任务
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('每月任务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('剩余5/5', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            ..._monthlyTasks.map((task) => _buildTaskCard(task)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    Color difficultyColor;
    switch (task.difficulty) {
      case '简单':
        difficultyColor = Colors.green;
        break;
      case '中等':
        difficultyColor = Colors.orange;
        break;
      case '困难':
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.pink[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.task, color: Colors.pinkAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: difficultyColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(task.difficulty, style: TextStyle(color: difficultyColor, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Text(task.category, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${task.points}积分', style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: task.isCompleted ? null : () => _completeTask(task),
                style: ElevatedButton.styleFrom(
                  backgroundColor: task.isCompleted ? Colors.grey : Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
                child: Text(task.isCompleted ? '已完成' : '完成', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildAssessmentCard() {
    final bool isAssessing = _assessment != null;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isAssessing ? Colors.blue[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAssessing ? Icons.timer : Icons.assessment,
                  color: isAssessing ? Colors.blue : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  isAssessing ? '能力评估进行中' : '开启能力评估',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isAssessing
                ? "剩余任务: ${_assessment!['remainingTasks']}/${_assessment!['totalTasks']}\n截止时间: ${_assessment!['endTime']}"
                : "开启后系统将随机抽取5个任务，你有24小时时间完成它们来评估你的能力等级。",
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isAssessing ? null : _startAssessment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAssessing ? Colors.grey : Colors.orange,
                ),
                child: Text(isAssessing ? '评估中...' : '立即开启'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateSelectionCard() {
    final states = [
      {'code': 0, 'name': '正常', 'icon': Icons.sentiment_satisfied, 'color': Colors.green},
      {'code': 1, 'name': '疲惫', 'icon': Icons.sentiment_dissatisfied, 'color': Colors.blue},
      {'code': 2, 'name': '懈怠', 'icon': Icons.sentiment_neutral, 'color': Colors.orange},
      {'code': 3, 'name': '专注', 'icon': Icons.sentiment_very_satisfied, 'color': Colors.red},
    ];

    final currentStateCode = _stateCode;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('当前状态标记', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: states.map((state) {
                final isSelected = currentStateCode == state['code'];
                return GestureDetector(
                  onTap: () async {
                    try {
                      final res = await ApiManager.instance.manualState(state['code'] as int);
                      if (res['code'] == 200) {
                        _loadTaskData();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('状态已切换为: ${state['name']}')));
                      }
                    } catch (e) {
                      print('切换状态失败: $e');
                    }
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? (state['color'] as Color).withOpacity(0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? (state['color'] as Color) : Colors.grey[300]!),
                        ),
                        child: Icon(state['icon'] as IconData, color: state['color'] as Color),
                      ),
                      const SizedBox(height: 4),
                      Text(state['name'] as String, style: TextStyle(fontSize: 12, color: isSelected ? (state['color'] as Color) : Colors.grey)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCustomTaskCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green[50],
      child: ListTile(
        leading: const Icon(Icons.add_task, color: Colors.green),
        title: const Text('添加自定义任务', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('自己添加的任务将归为简单类加入循环推荐'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showAddCustomTaskDialog(),
      ),
    );
  }

  void _showAddCustomTaskDialog() {
    final _nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加自定义任务'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: '请输入任务名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                try {
                  final res = await ApiManager.instance.addCustomTask(_nameController.text);
                  if (res['code'] == 200) {
                    Navigator.pop(context);
                    _loadTaskData();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('添加成功')));
                  }
                } catch (e) {
                  print('添加任务失败: $e');
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class TaskCategory {
  final String name;
  final IconData icon;
  final Color color;

  TaskCategory({required this.name, required this.icon, required this.color});
}

class Task {
  final String id;
  final String title;
  final String category;
  final String difficulty;
  final int points;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.points,
    this.isCompleted = false,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: (map['id'] ?? '').toString(),
      title: map['name'] ?? '无标题',
      category: map['category'] ?? '其他',
      difficulty: _mapDifficulty(map['difficulty'] ?? 0),
      points: map['benefit_value'] ?? 0,
      isCompleted: map['is_completed'] == 1,
    );
  }

  static String _mapDifficulty(int d) {
    if (d <= 1) return '简单';
    if (d == 2) return '中等';
    return '困难';
  }
}
