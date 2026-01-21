import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../database/database_helper.dart';
import './user_ability_manager.dart';

class DataStatisticsManager {
  static final DataStatisticsManager instance = DataStatisticsManager._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final String _versionType = '优化版'; // 基础版/优化版
  final String _userId = 'user_001'; // 用户ID，实际项目中应使用真实用户标识

  DataStatisticsManager._init();

  // 计算任务完成率
  Future<double> calculateTaskCompletionRate(List<TaskModel> tasks) async {
    if (tasks.isEmpty) return 0.0;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    return completedTasks / tasks.length;
  }

  // 计算I(M;E)值
  Future<double> calculateIMEValue(TaskModel task) async {
    final userAbilityManager = UserAbilityManager.instance;
    
    // 确保用户能力模型已初始化
    await userAbilityManager.initializeAbilityModel();
    
    // 1. 计算任务完成概率（基于用户能力和任务难度）
    final abilityModel = userAbilityManager.abilityModel;
    final overallAbility = abilityModel['overall_ability'];
    final taskDifficultyFactor = task.difficulty.index / 2; // 转换为0-1范围
    
    // 任务完成概率：用户能力与任务难度的匹配度
    double completionProbability;
    if (overallAbility >= taskDifficultyFactor) {
      // 用户能力高于任务难度
      completionProbability = 0.7 + (overallAbility - taskDifficultyFactor) * 0.3;
    } else {
      // 用户能力低于任务难度
      completionProbability = 0.3 + (overallAbility / taskDifficultyFactor) * 0.4;
    }
    completionProbability = completionProbability.clamp(0.1, 1.0);
    
    // 2. 计算收益匹配度（基于任务收益和用户需求）
    final taskValue = userAbilityManager.evaluateTaskValue(task);
    final benefitMatchRate = taskValue;
    
    // 3. 计算效率系数（基于用户历史完成时间）
    final efficiencyLevel = abilityModel['efficiency_level'];
    
    // 4. 计算坚持系数（基于用户连续完成天数）
    final persistenceLevel = abilityModel['persistence_level'];
    
    // 综合计算I(M;E)值
    // 公式：I(M;E) = 完成概率 × 收益匹配度 × (效率系数 × 0.5 + 坚持系数 × 0.5)
    final imeValue = completionProbability * benefitMatchRate * 
        (efficiencyLevel * 0.5 + persistenceLevel * 0.5);
    
    return imeValue.clamp(0.0, 1.0);
  }

  // 记录统计数据
  Future<void> recordStatisticsData({
    required double taskCompletionRate,
    required int dailyUsageDuration,
    required double imeValue,
  }) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final statistics = {
      'date': today,
      'task_completion_rate': taskCompletionRate,
      'daily_usage_duration': dailyUsageDuration,
      'ime_value': imeValue,
      'user_id': _userId,
      'version_type': _versionType,
    };

    await _dbHelper.insertStatistics(statistics);
  }

  // 获取今日统计数据
  Future<Map<String, dynamic>?> getTodayStatistics() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final statistics = await _dbHelper.readStatisticsByDateRange(today, today);
    return statistics.isNotEmpty ? statistics.first : null;
  }

  // 更新今日使用时长
  Future<void> updateDailyUsageDuration(int additionalMinutes) async {
    final todayStats = await getTodayStatistics();
    final tasks = await _dbHelper.readAllTasks();
    final taskCompletionRate = await calculateTaskCompletionRate(tasks);

    if (todayStats != null) {
      // 更新已有数据
      final updatedStats = {
        'date': todayStats['date'],
        'task_completion_rate': taskCompletionRate,
        'daily_usage_duration': todayStats['daily_usage_duration'] + additionalMinutes,
        'ime_value': todayStats['ime_value'],
        'user_id': todayStats['user_id'],
        'version_type': todayStats['version_type'],
      };

      await _dbHelper.updateStatistics(updatedStats);
    } else {
      // 创建新数据
      await recordStatisticsData(
        taskCompletionRate: taskCompletionRate,
        dailyUsageDuration: additionalMinutes,
        imeValue: 0.0,
      );
    }
  }

  // 更新任务完成后的统计数据
  Future<void> updateAfterTaskCompletion(TaskModel completedTask) async {
    final tasks = await _dbHelper.readAllTasks();
    final taskCompletionRate = await calculateTaskCompletionRate(tasks);
    final imeValue = await calculateIMEValue(completedTask);

    // 更新用户能力模型
    final userAbilityManager = UserAbilityManager.instance;
    await userAbilityManager.updateAbilityModel(
      completedTask,
      isCompleted: true,
      completedAt: DateTime.now(),
      actualBenefit: completedTask.benefitValue,
    );

    final todayStats = await getTodayStatistics();
    if (todayStats != null) {
      // 更新已有数据
      final updatedStats = {
        'date': todayStats['date'],
        'task_completion_rate': taskCompletionRate,
        'daily_usage_duration': todayStats['daily_usage_duration'],
        'ime_value': imeValue, // 使用最新任务的IME值
        'user_id': todayStats['user_id'],
        'version_type': todayStats['version_type'],
      };

      await _dbHelper.updateStatistics(updatedStats);
    } else {
      // 创建新数据
      await recordStatisticsData(
        taskCompletionRate: taskCompletionRate,
        dailyUsageDuration: 0,
        imeValue: imeValue,
      );
    }
  }

  // 获取指定日期范围的统计数据
  Future<List<Map<String, dynamic>>> getStatisticsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);
    return await _dbHelper.readStatisticsByDateRange(startDateStr, endDateStr);
  }
}