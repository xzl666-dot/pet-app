import 'dart:math';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../database/database_helper.dart';

class UserAbilityManager {
  static final UserAbilityManager instance = UserAbilityManager._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final String _userId = 'user_001'; // 用户ID，实际项目中应使用真实用户标识

  // 用户能力模型数据
  Map<String, dynamic> _abilityModel = {
    'completion_ability': 0.5, // 完成能力（0-1）
    'effect_quality': 0.5,     // 效果好坏（0-1）
    'efficiency_level': 0.5,   // 效率高低（0-1）
    'persistence_level': 0.5,  // 坚持程度（0-1）
    'overall_ability': 0.5,    // 综合能力（0-1）
    'last_updated': DateTime.now().toString(),
  };

  // 历史任务数据
  List<Map<String, dynamic>> _taskHistory = [];

  UserAbilityManager._init();

  // 获取用户能力模型
  Map<String, dynamic> get abilityModel => _abilityModel;

  // 初始化用户能力模型
  Future<void> initializeAbilityModel() async {
    // 加载历史任务数据
    await _loadTaskHistory();
    // 计算初始能力评估
    await _calculateAbilityModel();
  }

  // 加载历史任务数据
  Future<void> _loadTaskHistory() async {
    final tasks = await _dbHelper.readAllTasks();
    _taskHistory = tasks.map((task) {
      return {
        'task_id': task.id,
        'difficulty': task.difficulty.index,
        'is_completed': task.isCompleted,
        'benefit_type': task.benefitType.index,
        'benefit_value': task.benefitValue,
        'deadline': task.deadline,
        'completed_at': task.completedAt,
        'created_at': task.createdAt,
      };
    }).toList();
  }

  // 计算用户能力模型
  Future<void> _calculateAbilityModel() async {
    if (_taskHistory.isEmpty) {
      // 如果没有历史数据，使用默认值
      return;
    }

    // 1. 计算完成能力（任务成功率）
    final completedTasks = _taskHistory.where((task) => task['is_completed']).length;
    final completionAbility = completedTasks / _taskHistory.length;

    // 2. 计算效果好坏（实际与预期收益差距）
    // 这里简化处理，假设完成任务的效果都符合预期
    final effectQuality = completionAbility;

    // 3. 计算效率高低（完成时间与平均水平对比）
    double efficiencyLevel = 0.5;
    final completedTasksWithTime = _taskHistory.where((task) {
      return task['is_completed'] && task['completed_at'] != null;
    }).toList();

    if (completedTasksWithTime.isNotEmpty) {
      // 计算平均完成时间
      final avgCompletionTime = completedTasksWithTime.map((task) {
        final created = task['created_at'] as DateTime;
        final completed = task['completed_at'] as DateTime;
        return completed.difference(created).inMinutes;
      }).reduce((a, b) => a + b) / completedTasksWithTime.length;

      // 假设平均完成时间在30分钟为效率1.0，超过60分钟为0.5，低于15分钟为1.0
      if (avgCompletionTime <= 15) {
        efficiencyLevel = 1.0;
      } else if (avgCompletionTime <= 30) {
        efficiencyLevel = 1.0 - (avgCompletionTime - 15) / 15 * 0.5;
      } else if (avgCompletionTime <= 60) {
        efficiencyLevel = 0.5 - (avgCompletionTime - 30) / 30 * 0.3;
      } else {
        efficiencyLevel = 0.2;
      }
    }

    // 4. 计算坚持程度（连续完成天数）
    double persistenceLevel = 0.5;
    final completedDates = _taskHistory
        .where((task) => task['is_completed'] && task['completed_at'] != null)
        .map((task) {
          final completed = task['completed_at'] as DateTime;
          return DateFormat('yyyy-MM-dd').format(completed);
        })
        .toSet()
        .toList()
        ..sort();

    if (completedDates.length > 1) {
      int consecutiveDays = 1;
      int maxConsecutiveDays = 1;

      for (int i = 1; i < completedDates.length; i++) {
        final prevDate = DateTime.parse(completedDates[i-1]);
        final currDate = DateTime.parse(completedDates[i]);
        final difference = currDate.difference(prevDate).inDays;

        if (difference == 1) {
          consecutiveDays++;
          maxConsecutiveDays = max(maxConsecutiveDays, consecutiveDays);
        } else {
          consecutiveDays = 1;
        }
      }

      // 坚持程度计算（连续完成天数最多30天为满值）
      persistenceLevel = min(maxConsecutiveDays / 30, 1.0);
    }

    // 5. 计算综合能力
    final overallAbility = (
      completionAbility * 0.3 +
      effectQuality * 0.25 +
      efficiencyLevel * 0.25 +
      persistenceLevel * 0.2
    );

    // 更新能力模型
    _abilityModel = {
      'completion_ability': completionAbility,
      'effect_quality': effectQuality,
      'efficiency_level': efficiencyLevel,
      'persistence_level': persistenceLevel,
      'overall_ability': overallAbility,
      'last_updated': DateTime.now().toString(),
    };
  }

  // 评估任务价值（基于用户能力）
  double evaluateTaskValue(TaskModel task) {
    // 任务难度系数（0-1）
    final difficultyFactor = task.difficulty.index / 2;

    // 任务收益系数（0-1）
    final benefitFactor = task.benefitValue / 50; // 假设最大收益为50

    // 任务时间系数（0-1）
    final timeFactor = 1.0 - min((task.deadline.difference(DateTime.now()).inHours / 24).abs(), 1.0);

    // 用户能力匹配度（0-1）
    final abilityMatch = 1.0 - ( (_abilityModel['overall_ability'] - difficultyFactor) ).abs();

    // 综合任务价值（0-1）
    final taskValue = (
      difficultyFactor * 0.2 +
      benefitFactor * 0.3 +
      timeFactor * 0.2 +
      abilityMatch * 0.3
    );

    return taskValue;
  }

  // 推荐任务难度
  TaskDifficulty recommendTaskDifficulty() {
    final overallAbility = _abilityModel['overall_ability'];

    if (overallAbility < 0.33) {
      return TaskDifficulty.easy;
    } else if (overallAbility < 0.66) {
      return TaskDifficulty.medium;
    } else {
      return TaskDifficulty.hard;
    }
  }

  // 更新用户能力模型（基于新完成的任务）
  Future<void> updateAbilityModel(TaskModel completedTask, {
    required bool isCompleted,
    required DateTime? completedAt,
    required int actualBenefit,
  }) async {
    // 添加新任务到历史记录
    final taskData = {
      'task_id': completedTask.id,
      'difficulty': completedTask.difficulty.index,
      'is_completed': isCompleted,
      'benefit_type': completedTask.benefitType.index,
      'expected_benefit': completedTask.benefitValue,
      'actual_benefit': actualBenefit,
      'deadline': completedTask.deadline,
      'completed_at': completedAt,
      'created_at': completedTask.createdAt,
      'completion_time': completedAt != null 
          ? completedAt.difference(completedTask.createdAt ?? DateTime.now()).inMinutes 
          : null,
    };

    _taskHistory.add(taskData);

    // 重新计算能力模型
    await _calculateAbilityModel();
  }

  // 获取能力评级
  String getAbilityRating() {
    final overallAbility = _abilityModel['overall_ability'];

    if (overallAbility >= 0.8) {
      return '优秀';
    } else if (overallAbility >= 0.6) {
      return '良好';
    } else if (overallAbility >= 0.4) {
      return '中等';
    } else if (overallAbility >= 0.2) {
      return '初级';
    } else {
      return '新手';
    }
  }

  // 获取能力提升建议
  List<String> getAbilityImprovementSuggestions() {
    final suggestions = <String>[];

    if (_abilityModel['completion_ability'] < 0.6) {
      suggestions.add('建议从简单任务开始，逐步提高完成率');
    }

    if (_abilityModel['efficiency_level'] < 0.6) {
      suggestions.add('建议合理规划时间，提高任务完成效率');
    }

    if (_abilityModel['persistence_level'] < 0.6) {
      suggestions.add('建议坚持每日完成任务，培养良好习惯');
    }

    if (suggestions.isEmpty) {
      suggestions.add('继续保持良好的表现！');
    }

    return suggestions;
  }

  // 获取任务历史记录
  List<Map<String, dynamic>> getTaskHistory() {
    return _taskHistory;
  }
}
