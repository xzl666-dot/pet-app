import 'dart:math';
import '../managers/user_ability_manager.dart';
import '../managers/data_statistics_manager.dart';

class AIMentalStateManager {
  static final AIMentalStateManager instance = AIMentalStateManager._init();
  final Random _random = Random();
  
  // 心理状态常量
  static const String ENERGETIC = 'energetic'; // 精力充沛
  static const String NORMAL = 'normal'; // 正常
  static const String TIRED = 'tired'; // 疲惫
  static const String STRESSED = 'stressed'; // 压力大
  static const String ANXIOUS = 'anxious'; // 焦虑
  
  // 当前心理状态
  String _currentState = NORMAL;
  
  // 状态历史记录
  final List<Map<String, dynamic>> _stateHistory = [];

  AIMentalStateManager._init();

  // 分析用户心理状态
  Future<String> analyzeMentalState() async {
    final userAbilityManager = UserAbilityManager.instance;
    final dataStatisticsManager = DataStatisticsManager.instance;
    
    await userAbilityManager.initializeAbilityModel();
    
    // 1. 获取用户能力数据
    final abilityModel = userAbilityManager.abilityModel;
    final overallAbility = abilityModel['overall_ability'] ?? 0.5;
    final persistenceLevel = abilityModel['persistence_level'] ?? 0.5;
    
    // 2. 获取任务完成数据
    final taskHistory = userAbilityManager.getTaskHistory();
    final recentTasks = taskHistory.length >= 5 
        ? taskHistory.sublist(taskHistory.length - 5)
        : taskHistory;
    
    // 3. 计算近期完成率
    final recentCompletedTasks = recentTasks.where((task) => task['is_completed']).length;
    final recentCompletionRate = recentTasks.isNotEmpty ? recentCompletedTasks / recentTasks.length : 0.0;
    
    // 4. 计算任务完成时间趋势
    int totalTaskTime = 0;
    int completedTaskCount = 0;
    
    for (final task in recentTasks) {
      if (task['is_completed'] && task.containsKey('completion_time') && task.containsKey('created_at')) {
        try {
          final createdAt = DateTime.parse(task['created_at']);
          final completionTime = DateTime.parse(task['completion_time']);
          final taskDuration = completionTime.difference(createdAt).inMinutes;
          totalTaskTime += taskDuration;
          completedTaskCount++;
        } catch (e) {
          // 解析时间失败，跳过
        }
      }
    }
    
    final averageTaskTime = completedTaskCount > 0 ? totalTaskTime / completedTaskCount : 0.0;
    
    // 5. 综合分析心理状态
    String state;
    
    if (recentCompletionRate > 0.8 && persistenceLevel > 0.7) {
      state = ENERGETIC;
    } else if (recentCompletionRate < 0.4) {
      if (averageTaskTime > 60) {
        state = TIRED;
      } else {
        state = STRESSED;
      }
    } else if (recentCompletionRate < 0.2) {
      state = ANXIOUS;
    } else {
      state = NORMAL;
    }
    
    // 更新当前状态
    _currentState = state;
    
    // 记录状态历史
    _stateHistory.add({
      'state': state.toString(),
      'timestamp': DateTime.now().toString(),
      'completion_rate': recentCompletionRate,
      'average_task_time': averageTaskTime,
      'persistence_level': persistenceLevel,
    });
    
    // 限制历史记录数量
    if (_stateHistory.length > 50) {
      _stateHistory.removeRange(0, _stateHistory.length - 50);
    }
    
    return state;
  }

  // 获取心理状态建议
  String getStateAdvice(String state) {
    switch (state) {
      case ENERGETIC:
        return '你当前状态非常好！可以尝试挑战一些更有难度的任务，充分发挥你的潜力。';
      case NORMAL:
        return '你当前状态正常，继续保持良好的工作节奏，合理安排任务。';
      case TIRED:
        return '你看起来有些疲惫，建议适当休息，避免过度劳累。可以先完成一些简单的任务，恢复精力。';
      case STRESSED:
        return '你当前压力较大，建议暂时减少任务量，优先完成重要的任务，给自己一些放松的时间。';
      case ANXIOUS:
        return '你似乎有些焦虑，建议先暂停任务，进行一些放松活动，如深呼吸、散步等，调整心态后再继续。';
      default:
        return '你当前状态正常，继续保持良好的工作节奏，合理安排任务。';
    }
  }

  // 获取任务调整建议
  Map<String, dynamic> getTaskAdjustmentAdvice(String state) {
    switch (state) {
      case ENERGETIC:
        return {
          'difficulty_adjustment': 1, // 增加难度
          'task_count_adjustment': 1, // 增加任务数量
          'advice': '可以增加任务难度和数量，挑战自我',
        };
      case NORMAL:
        return {
          'difficulty_adjustment': 0, // 保持不变
          'task_count_adjustment': 0, // 保持不变
          'advice': '保持当前任务难度和数量',
        };
      case TIRED:
        return {
          'difficulty_adjustment': -1, // 降低难度
          'task_count_adjustment': -1, // 减少任务数量
          'advice': '建议减少任务难度和数量，优先恢复精力',
        };
      case STRESSED:
        return {
          'difficulty_adjustment': -1, // 降低难度
          'task_count_adjustment': -1, // 减少任务数量
          'advice': '建议减少任务量，降低任务难度，减轻压力',
        };
      case ANXIOUS:
        return {
          'difficulty_adjustment': -2, // 大幅降低难度
          'task_count_adjustment': -2, // 大幅减少任务数量
          'advice': '建议暂时只保留少量简单任务，优先调整心态',
        };
      default:
        return {
          'difficulty_adjustment': 0, // 保持不变
          'task_count_adjustment': 0, // 保持不变
          'advice': '保持当前任务难度和数量',
        };
    }
  }

  // 获取放松建议
  List<String> getRelaxationSuggestions() {
    final suggestions = [
      '深呼吸练习：慢慢吸气4秒，屏住呼吸4秒，慢慢呼气6秒，重复5次',
      '短暂休息：站起来伸展身体，走动5分钟',
      '眼部放松：闭眼休息1分钟，或远眺窗外景色',
      '听音乐：播放一些轻松的音乐，放松心情',
      '喝杯水：保持身体水分，有助于提高注意力',
      '冥想：花2分钟时间专注于呼吸，清空思绪',
      '简单运动：做几个伸展动作，活动关节',
      '短暂聊天：与朋友或同事简短交流，转移注意力',
    ];
    
    // 随机返回3个建议
    final shuffledSuggestions = [...suggestions]..shuffle(_random);
    return shuffledSuggestions.take(3).toList();
  }

  // 获取当前心理状态
  String getCurrentState() {
    return _currentState;
  }

  // 获取状态历史
  List<Map<String, dynamic>> getStateHistory() {
    return _stateHistory;
  }

  // 获取状态统计
  Map<String, dynamic> getStateStatistics() {
    final totalStates = _stateHistory.length;
    if (totalStates == 0) {
      return {
        'total_records': 0,
        'state_distribution': {},
        'most_common_state': 'normal',
      };
    }
    
    // 计算状态分布
    final stateCounts = <String, int>{};
    for (final record in _stateHistory) {
      final state = record['state'] as String;
      stateCounts[state] = (stateCounts[state] ?? 0) + 1;
    }
    
    // 找出最常见的状态
    String mostCommonState = 'normal';
    int maxCount = 0;
    stateCounts.forEach((state, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonState = state;
      }
    });
    
    return {
      'total_records': totalStates,
      'state_distribution': stateCounts,
      'most_common_state': mostCommonState,
    };
  }
}
