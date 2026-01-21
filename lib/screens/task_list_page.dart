import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../database/task_database.dart';
import '../widgets/feedback_widget.dart';
import '../managers/pet_state_manager.dart';
import '../managers/data_statistics_manager.dart';

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

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = _taskDatabase.readAllTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日任务'),
        actions: [
          // 移除了手动添加任务的按钮，改为系统自动生成
        ],
      ),
      body: FutureBuilder<List<TaskModel>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('今日暂无任务，明天会自动生成新任务'));
          } else {
            final tasks = snapshot.data!;
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskItem(task);
              },
            );
          }
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
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteTask(task.id!),
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
      case PetBenefitType.skillPoint:
        benefitTypeName = '技能点';
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
      case PetBenefitType.skillPoint:
        return '技能点';
    }
  }

  Future<void> _completeTask(TaskModel task) async {
    // 更新任务状态
    final now = DateTime.now();
    await _taskDatabase.update(
      task.copyWith(
        isCompleted: true,
        completedAt: now,
      ),
    );

    // 计算效率加成
    double efficiencyMultiplier = 1.0;
    final taskDuration = now.difference(task.createdAt ?? now).inMinutes;
    
    // 根据完成时间计算效率加成
    switch (task.difficulty) {
      case TaskDifficulty.easy:
        if (taskDuration < 30) efficiencyMultiplier = 1.2; // 30分钟内完成简单任务
        break;
      case TaskDifficulty.medium:
        if (taskDuration < 60) efficiencyMultiplier = 1.3; // 1小时内完成中等任务
        break;
      case TaskDifficulty.hard:
        if (taskDuration < 120) efficiencyMultiplier = 1.5; // 2小时内完成困难任务
        break;
    }

    // 检查是否为连续完成
    bool isConsecutiveCompletion = await _checkConsecutiveCompletion();

    // 更新宠物状态
    await _petManager.updatePetState(
      task.benefitType,
      task.benefitValue,
      efficiencyMultiplier: efficiencyMultiplier,
      isConsecutiveCompletion: isConsecutiveCompletion,
    );

    // 更新统计数据，计算I(M;E)值
    await _statsManager.updateAfterTaskCompletion(task);

    // 显示反馈
    if (mounted) {
      FeedbackWidget.showFeedback(
        context,
        task,
        efficiencyMultiplier: efficiencyMultiplier,
        isConsecutive: isConsecutiveCompletion,
      );
    }

    _refreshTasks();
  }

  // 检查是否为连续完成
  Future<bool> _checkConsecutiveCompletion() async {
    final tasks = await _taskDatabase.readAllTasks();
    final completedTasks = tasks
        .where((task) => task.isCompleted && task.completedAt != null)
        .toList();
    
    if (completedTasks.length < 2) {
      return false;
    }

    // 按完成时间排序
    completedTasks.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    
    // 检查最近两个任务的完成时间是否在同一天
    final lastTask = completedTasks[0];
    final secondLastTask = completedTasks[1];
    
    final lastDate = DateTime(
      lastTask.completedAt!.year,
      lastTask.completedAt!.month,
      lastTask.completedAt!.day,
    );
    
    final secondLastDate = DateTime(
      secondLastTask.completedAt!.year,
      secondLastTask.completedAt!.month,
      secondLastTask.completedAt!.day,
    );
    
    // 检查是否为连续的日期
    final difference = lastDate.difference(secondLastDate).inDays;
    return difference == 1;
  }

  Future<void> _deleteTask(int id) async {
    await _taskDatabase.delete(id);
    _refreshTasks();
  }
}