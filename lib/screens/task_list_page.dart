import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/task_model.dart';
import '../database/task_database.dart';
import '../widgets/feedback_widget.dart';
import '../widgets/pet_upgrade_dialog.dart';
import '../managers/pet_state_manager.dart';
import '../managers/data_statistics_manager.dart';
import '../managers/auth_manager.dart';
import '../managers/pet_growth_manager.dart';
import '../utils/token_util.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({Key? key}) : super(key: key);

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  late Future<List<TaskModel>> _tasksFuture;
  final _taskDatabase = TaskDatabase.instance;
  final _petManager = PetStateManager.instance;
  final _statsManager = DataStatisticsManager.instance;
  final _authManager = AuthManager.instance;
  final _petGrowthManager = PetGrowthManager();
  StreamSubscription? _upgradeSubscription;
  List<TaskModel> _tasks = [];

  @override
  void initState() {
    super.initState();
    _refreshTasks();
    _upgradeSubscription = _petGrowthManager.upgradeStream.listen((event) {
      if (mounted) {
        showPetUpgradeDialog(
          context,
          pet: event.pet,
          oldLevel: event.oldLevel,
          newLevel: event.newLevel,
        );
      }
    });
  }

  @override
  void dispose() {
    _upgradeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshTasks() async {
    try {
      final user = _authManager.currentUser;
      if (user != null) {
        final token = await TokenUtil.instance.getAccessToken();
        final userId = user.userId ?? user.id;

        if (token != null && userId != null) {
          // 从后端获取任务列表
          final response = await http.get(
            Uri.parse('http://localhost:3000/api/task/list?userId=$userId'),
            headers: {
              'Content-Type': 'application/json',
              'token': token,
            },
          );

          print('任务列表响应: ${response.body}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['code'] == 200) {
              final taskList = data['data']['taskList'] ?? [];
              setState(() {
                _tasks = taskList.map((taskData) => TaskModel(
                  id: taskData['id'],
                  name: taskData['name'],
                  category: TaskCategory.study,
                  frequency: TaskFrequency.dailyBasic,
                  difficulty: taskData['difficulty'] ?? 1,
                  deadline: DateTime.fromMillisecondsSinceEpoch(taskData['deadline'] * 1000),
                  benefitType: _parseBenefitType(taskData['benefit_type']),
                  benefitValue: taskData['benefit_value'] ?? 10,
                  growthValue: 10,
                  happinessValue: 5,
                  duration: 30,
                  weight: 0.5,
                  description: taskData['description'] ?? '',
                  tags: [],
                  isCompleted: taskData['is_completed'] == 1,
                  createdAt: DateTime.now(),
                )).toList();
              });
              return;
            }
          }
        }
      }
    } catch (e) {
      print('加载任务失败: $e');
    }

    // 如果后端加载失败，使用本地数据
    setState(() {
      _tasksFuture = _taskDatabase.readAllTasks();
    });
  }

  PetBenefitType _parseBenefitType(String typeStr) {
    switch (typeStr) {
      case 'nutrition':
        return PetBenefitType.nutrition;
      case 'happiness':
        return PetBenefitType.happiness;
      case 'skill':
        return PetBenefitType.nutrition;
      default:
        return PetBenefitType.nutrition;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日任务'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTasks,
          ),
        ],
      ),
      body: _tasks.isEmpty
          ? const Center(child: Text('今日暂无任务'))
          : ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return _buildTaskItem(task);
              },
            ),
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: _getDifficultyIcon(task.difficulty),
        title: Text(
          task.name,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('截止时间: ${DateFormat('yyyy-MM-dd HH:mm').format(task.deadline)}'),
            Text(_getBenefitInfo(task), style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (value) async {
                if (value == true) {
                  await _completeTask(task);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _getDifficultyIcon(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return const Icon(Icons.star, color: Colors.green, size: 24);
      case TaskDifficulty.medium:
        return const Icon(Icons.star, color: Colors.yellow, size: 24);
      case TaskDifficulty.hard:
        return const Icon(Icons.star, color: Colors.red, size: 24);
    }
  }

  String _getBenefitInfo(TaskModel task) {
    String benefitTypeName;
    switch (task.benefitType) {
      case PetBenefitType.nutrition:
        benefitTypeName = '营养值';
        break;
      case PetBenefitType.happiness:
        benefitTypeName = '快乐度';
        break;
      case PetBenefitType.intimacy:
        benefitTypeName = '亲密度';
        break;
      case PetBenefitType.exp:
        benefitTypeName = '经验值';
        break;
    }
    return '奖励: $benefitTypeName +${task.benefitValue}';
  }



  String _getDifficultyName(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return '日常任务（低难度）';
      case TaskDifficulty.medium:
        return '高优先级任务（中难度）';
      case TaskDifficulty.hard:
        return '连续任务（高难度）';
    }
  }

  String _getBenefitTypeName(PetBenefitType type) {
    switch (type) {
      case PetBenefitType.nutrition:
        return '营养值';
      case PetBenefitType.happiness:
        return '快乐度';
      case PetBenefitType.intimacy:
        return '亲密度';
      case PetBenefitType.exp:
        return '经验值';
    }
  }

  Future<void> _completeTask(TaskModel task) async {
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

      // 调用后端完成任务接口
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/task/complete'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'taskId': task.id,
        }),
      );

      print('完成任务响应: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          // 更新本地任务状态
          setState(() {
            final index = _tasks.indexWhere((t) => t.id == task.id);
            if (index != -1) {
              _tasks[index] = task.copyWith(isCompleted: true);
            }
          });

          // 调用激励联动接口，获得积分和抽奖券
          final pet = await _petManager.getOrCreatePet();
          final incentiveResponse = await http.post(
            Uri.parse('http://localhost:3000/api/incentive/link'),
            headers: {
              'Content-Type': 'application/json',
              'token': token!,
            },
            body: jsonEncode({
              'userId': userId,
              'petId': pet.id,
              'taskScore': 100, // 假设任务完成得分为100
              'taskQuality': 90, // 假设任务质量为90
            }),
          );

          if (incentiveResponse.statusCode == 200) {
            final incentiveData = jsonDecode(incentiveResponse.body);
            if (incentiveData['code'] == 200) {
              print('任务完成获得积分: ${incentiveData['data']['finalIntegral']}');
              // 任务中心只产出积分和抽奖券，宠物成长只靠道具
            }
          }

          // 显示反馈
          if (mounted) {
            FeedbackWidget.showFeedback(
              context,
              task,
              efficiencyMultiplier: 1.0,
            );
          }
        } else {
          throw Exception(data['msg'] ?? '完成任务失败');
        }
      } else {
        throw Exception('网络请求失败');
      }
    } catch (e) {
      print('完成任务失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('完成任务失败: $e')),
        );
      }
    }
  }
}