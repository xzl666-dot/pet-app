import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/pet_model.dart';
import '../models/task_model.dart';
import '../managers/pet_state_manager.dart';
import '../managers/task_generator.dart';
import '../database/task_database.dart';
import '../widgets/pet_interaction_widget.dart';
import '../screens/task_list_page.dart';
import '../screens/pet_selection_page.dart';
import '../managers/data_statistics_manager.dart';
import '../utils/data_export_util.dart';
import '../managers/auth_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _petManager = PetStateManager.instance;
  final _statsManager = DataStatisticsManager.instance;
  final _exportUtil = DataExportUtil.instance;
  final _taskDatabase = TaskDatabase.instance;
  final _taskGenerator = TaskGenerator.instance;
  PetModel? _pet;
  bool _isPetAnimating = false;
  bool _tasksGenerated = false;

  @override
  void initState() {
    super.initState();
    _loadPet();
    _generateDailyTasksIfNeeded();
    _startUsageTimer();
  }

  // 加载宠物数据
  Future<void> _loadPet() async {
    final hasPet = await _petManager.hasPet();
    if (hasPet) {
      final pet = await _petManager.getOrCreatePet();
      setState(() {
        _pet = pet;
      });
    } else {
      // 没有宠物，导航到宠物选择页面
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PetSelectionPage()),
      );
      if (result == true) {
        // 宠物创建成功，重新加载宠物数据
        _loadPet();
      }
    }
  }

  // 生成每日任务（如果需要）
  Future<void> _generateDailyTasksIfNeeded() async {
    if (_tasksGenerated) {
      return; // 今天已经生成过任务
    }

    try {
      // 获取现有的任务
      final existingTasks = await _taskDatabase.readAllTasks();
      
      // 检查是否需要生成新任务
      final shouldGenerate = await _taskGenerator.shouldGenerateNewTasks(existingTasks);
      
      if (shouldGenerate) {
        // 生成新的每日任务
        final newTasks = await _taskGenerator.generateDailyTasks();
        
        // 保存新任务到数据库
        for (final task in newTasks) {
          await _taskDatabase.create(task);
        }
        
        setState(() {
          _tasksGenerated = true;
        });
      }
    } catch (e) {
      // 任务生成失败，不影响应用运行
      debugPrint('生成每日任务失败: $e');
    }
  }

  // 开始使用时长计时器
  void _startUsageTimer() {
    // 每1分钟更新一次使用时长
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _statsManager.updateDailyUsageDuration(1);
    });
  }

  // 处理宠物点击事件
  void _handlePetTap() {
    setState(() {
      _isPetAnimating = true;
    });
    // 1秒后停止动画
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isPetAnimating = false;
        });
      }
    });
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
        title: const Text('宠物养成任务管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportData,
            tooltip: '导出数据',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '退出登录',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // 宠物交互区域
                if (_pet != null)
                  PetInteractionWidget(
                    pet: _pet!,
                    isAnimating: _isPetAnimating,
                    onTap: _handlePetTap,
                  ),
                const SizedBox(height: 40),
                // 功能入口
                _buildFeatureCard(
                  context,
                  icon: Icons.checklist,
                  title: '任务管理',
                  description: '查看和管理您的任务',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TaskListPage()),
                    ).then((_) {
                      // 返回时重新加载宠物数据，因为任务完成可能影响宠物状态
                      _loadPet();
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildFeatureCard(
                  context,
                  icon: Icons.bar_chart,
                  title: '数据统计',
                  description: '查看您的使用统计和I(M;E)值',
                  onTap: () async {
                    final todayStats = await _statsManager.getTodayStatistics();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('今日统计'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('日期：${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
                            if (todayStats != null)
                              ...[
                                Text('任务完成率：${(todayStats['task_completion_rate'] * 100).toStringAsFixed(1)}%'),
                                Text('今日使用时长：${todayStats['daily_usage_duration']} 分钟'),
                                Text('I(M;E)值：${todayStats['ime_value'].toStringAsFixed(2)}'),
                                Text('版本类型：${todayStats['version_type']}'),
                              ]
                            else
                              const Text('今日暂无统计数据'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('关闭'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildFeatureCard(
                  context,
                  icon: Icons.info_outline,
                  title: '背景信息',
                  description: '查看项目的理论、行业和用户调研信息',
                  onTap: () {
                    Navigator.pushNamed(context, '/background');
                  },
                ),
                const SizedBox(height: 20),
                _buildFeatureCard(
            context,
            icon: Icons.assessment,
            title: '能力评估',
            description: '查看您的能力水平评估和任务难度推荐',
            onTap: () {
              Navigator.pushNamed(context, '/ability');
            },
          ),
          _buildFeatureCard(
            context,
            icon: Icons.people,
            title: '社交挑战',
            description: '智能匹配对手，参与任务挑战',
            onTap: () {
              Navigator.pushNamed(context, '/social');
            },
          ),
          _buildFeatureCard(
            context,
            icon: Icons.psychology,
            title: 'AI心理助手',
            description: '感知您的心理状态，提供个性化建议',
            onTap: () {
              Navigator.pushNamed(context, '/ai_assistant');
            },
          ),
          _buildFeatureCard(
            context,
            icon: Icons.notifications,
            title: '通知设置',
            description: '个性化通知提醒，智能调整提醒方式',
            onTap: () {
              Navigator.pushNamed(context, '/notification_settings');
            },
          ),
          // 管理员模式入口，只有管理员可以看到
          if (AuthManager.instance.isAdmin)
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
          ),
        ),
      ),
    );
  }

  // 构建功能卡片
  Widget _buildFeatureCard(
    BuildContext context,
    {required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}

