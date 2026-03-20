import 'dart:math';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../database/database_helper.dart';

class LevelMatchTask {
  String id;
  String name;
  TaskDifficulty difficulty;
  String description;
  int points;
  bool isCompleted;
  DateTime? completedAt;
  
  // 能力维度权重
  Map<String, double> abilityWeights;

  LevelMatchTask({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.description,
    required this.points,
    this.isCompleted = false,
    this.completedAt,
    required this.abilityWeights,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'difficulty': difficulty.index,
      'description': description,
      'points': points,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toString(),
      'ability_weights': abilityWeights,
    };
  }

  factory LevelMatchTask.fromMap(Map<String, dynamic> map) {
    return LevelMatchTask(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      difficulty: TaskDifficulty.values[map['difficulty'] ?? 0],
      description: map['description'] ?? '',
      points: map['points'] ?? 0,
      isCompleted: map['is_completed'] ?? false,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']) : null,
      abilityWeights: Map<String, double>.from(map['ability_weights'] ?? {}),
    );
  }
}

class AbilityAssessmentReport {
  DateTime generatedAt;
  Map<String, dynamic> currentAbility;
  Map<String, dynamic>? previousAbility;
  List<String> improvementAreas;
  List<String> achievementAreas;
  String levelChange;
  List<String> personalizedSuggestions;

  AbilityAssessmentReport({
    required this.generatedAt,
    required this.currentAbility,
    this.previousAbility,
    required this.improvementAreas,
    required this.achievementAreas,
    required this.levelChange,
    required this.personalizedSuggestions,
  });

  Map<String, dynamic> toMap() {
    return {
      'generated_at': generatedAt.toString(),
      'current_ability': currentAbility,
      'previous_ability': previousAbility,
      'improvement_areas': improvementAreas,
      'achievement_areas': achievementAreas,
      'level_change': levelChange,
      'personalized_suggestions': personalizedSuggestions,
    };
  }

  factory AbilityAssessmentReport.fromMap(Map<String, dynamic> map) {
    return AbilityAssessmentReport(
      generatedAt: DateTime.parse(map['generated_at'] ?? DateTime.now().toString()),
      currentAbility: Map<String, dynamic>.from(map['current_ability'] ?? {}),
      previousAbility: map['previous_ability'] != null ? Map<String, dynamic>.from(map['previous_ability']) : null,
      improvementAreas: List<String>.from(map['improvement_areas'] ?? []),
      achievementAreas: List<String>.from(map['achievement_areas'] ?? []),
      levelChange: map['level_change'] ?? '',
      personalizedSuggestions: List<String>.from(map['personalized_suggestions'] ?? []),
    );
  }
}

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
    'level': 1,                // 用户等级
    'experience': 0,           // 用户经验值
  };

  // 历史任务数据
  List<Map<String, dynamic>> _taskHistory = [];
  
  // 主动定级赛任务
  List<LevelMatchTask> _levelMatchTasks = [];
  
  // 能力评估报告历史
  List<AbilityAssessmentReport> _assessmentReports = [];
  
  // 上次被动评估时间
  DateTime? _lastPassiveAssessment;

  UserAbilityManager._init();

  // 获取用户能力模型
  Map<String, dynamic> get abilityModel => _abilityModel;
  
  // 获取等级
  int get userLevel => _abilityModel['level'] ?? 1;
  
  // 获取经验值
  int get userExperience => _abilityModel['experience'] ?? 0;

  // 初始化用户能力模型
  Future<void> initializeAbilityModel() async {
    // 加载历史任务数据
    await _loadTaskHistory();
    // 计算初始能力评估
    await _calculateAbilityModel();
    // 初始化定级赛任务
    _initializeLevelMatchTasks();
    // 检查是否需要被动评估
    await _checkPassiveAssessment();
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

    // 计算等级和经验值
    final level = (overallAbility * 10).ceil();
    final experience = (overallAbility * 1000).toInt();

    // 更新能力模型
    _abilityModel = {
      'completion_ability': completionAbility,
      'effect_quality': effectQuality,
      'efficiency_level': efficiencyLevel,
      'persistence_level': persistenceLevel,
      'overall_ability': overallAbility,
      'level': max(1, min(10, level)),
      'experience': experience,
      'last_updated': DateTime.now().toString(),
    };
  }

  // 初始化定级赛任务
  void _initializeLevelMatchTasks() {
    _levelMatchTasks = [
      LevelMatchTask(
        id: 'task_001',
        name: '快速完成简单任务',
        difficulty: TaskDifficulty.easy,
        description: '在10分钟内完成3个简单任务',
        points: 100,
        abilityWeights: {
          'completion_ability': 0.4,
          'efficiency_level': 0.6,
        },
      ),
      LevelMatchTask(
        id: 'task_002',
        name: '高质量完成中等任务',
        difficulty: TaskDifficulty.medium,
        description: '高质量完成2个中等难度任务',
        points: 150,
        abilityWeights: {
          'effect_quality': 0.6,
          'completion_ability': 0.4,
        },
      ),
      LevelMatchTask(
        id: 'task_003',
        name: '连续完成任务',
        difficulty: TaskDifficulty.easy,
        description: '连续5天每天完成至少1个任务',
        points: 200,
        abilityWeights: {
          'persistence_level': 1.0,
        },
      ),
      LevelMatchTask(
        id: 'task_004',
        name: '挑战困难任务',
        difficulty: TaskDifficulty.hard,
        description: '完成1个困难难度任务',
        points: 250,
        abilityWeights: {
          'completion_ability': 0.3,
          'effect_quality': 0.3,
          'persistence_level': 0.4,
        },
      ),
      LevelMatchTask(
        id: 'task_005',
        name: '高效完成任务',
        difficulty: TaskDifficulty.medium,
        description: '在预期时间的80%内完成任务',
        points: 180,
        abilityWeights: {
          'efficiency_level': 0.8,
          'effect_quality': 0.2,
        },
      ),
      LevelMatchTask(
        id: 'task_006',
        name: '多任务并行处理',
        difficulty: TaskDifficulty.medium,
        description: '同时处理2个任务并都高质量完成',
        points: 220,
        abilityWeights: {
          'completion_ability': 0.3,
          'efficiency_level': 0.4,
          'effect_quality': 0.3,
        },
      ),
      LevelMatchTask(
        id: 'task_007',
        name: '突破自我',
        difficulty: TaskDifficulty.hard,
        description: '完成比自己当前能力高一级的任务',
        points: 300,
        abilityWeights: {
          'persistence_level': 0.5,
          'effect_quality': 0.5,
        },
      ),
      LevelMatchTask(
        id: 'task_008',
        name: '稳定输出',
        difficulty: TaskDifficulty.easy,
        description: '连续7天每天完成任务，保持稳定质量',
        points: 260,
        abilityWeights: {
          'persistence_level': 0.6,
          'effect_quality': 0.4,
        },
      ),
      LevelMatchTask(
        id: 'task_009',
        name: '精准完成',
        difficulty: TaskDifficulty.medium,
        description: '以90%以上的准确率完成任务',
        points: 190,
        abilityWeights: {
          'effect_quality': 0.8,
          'completion_ability': 0.2,
        },
      ),
      LevelMatchTask(
        id: 'task_010',
        name: '全面发展',
        difficulty: TaskDifficulty.hard,
        description: '完成涵盖所有能力维度的任务组合',
        points: 350,
        abilityWeights: {
          'completion_ability': 0.25,
          'effect_quality': 0.25,
          'efficiency_level': 0.25,
          'persistence_level': 0.25,
        },
      ),
    ];
  }

  // 获取定级赛任务
  List<LevelMatchTask> getLevelMatchTasks() {
    return _levelMatchTasks;
  }

  // 完成定级赛任务
  Future<void> completeLevelMatchTask(String taskId, int score) async {
    final taskIndex = _levelMatchTasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _levelMatchTasks[taskIndex] = LevelMatchTask(
        id: _levelMatchTasks[taskIndex].id,
        name: _levelMatchTasks[taskIndex].name,
        difficulty: _levelMatchTasks[taskIndex].difficulty,
        description: _levelMatchTasks[taskIndex].description,
        points: _levelMatchTasks[taskIndex].points,
        isCompleted: true,
        completedAt: DateTime.now(),
        abilityWeights: _levelMatchTasks[taskIndex].abilityWeights,
      );
      
      // 根据任务权重更新能力模型
      await _updateAbilityFromLevelMatch(taskId, score);
    }
  }

  // 根据定级赛任务更新能力
  Future<void> _updateAbilityFromLevelMatch(String taskId, int score) async {
    final task = _levelMatchTasks.firstWhere((t) => t.id == taskId);
    final scoreRatio = score / task.points;
    
    // 根据任务权重更新各能力维度
    task.abilityWeights.forEach((ability, weight) {
      if (_abilityModel.containsKey(ability)) {
        final currentValue = _abilityModel[ability] as double;
        final newValue = min(1.0, currentValue + (scoreRatio * weight * 0.1));
        _abilityModel[ability] = newValue;
      }
    });
    
    // 重新计算综合能力
    await _calculateAbilityModel();
    
    // 生成主动评估报告
    await _generateActiveAssessmentReport();
  }

  // 检查是否需要被动评估
  Future<void> _checkPassiveAssessment() async {
    final now = DateTime.now();
    if (_lastPassiveAssessment == null || 
        now.difference(_lastPassiveAssessment!).inDays >= 7) {
      await _generatePassiveAssessmentReport();
      _lastPassiveAssessment = now;
    }
  }

  // 生成主动评估报告
  Future<AbilityAssessmentReport> _generateActiveAssessmentReport() async {
    final report = AbilityAssessmentReport(
      generatedAt: DateTime.now(),
      currentAbility: _abilityModel,
      previousAbility: _assessmentReports.isNotEmpty ? _assessmentReports.last.currentAbility : null,
      improvementAreas: _identifyImprovementAreas(),
      achievementAreas: _identifyAchievementAreas(),
      levelChange: _calculateLevelChange(),
      personalizedSuggestions: _generatePersonalizedSuggestions(),
    );
    
    _assessmentReports.add(report);
    return report;
  }

  // 生成被动评估报告
  Future<AbilityAssessmentReport> _generatePassiveAssessmentReport() async {
    final report = AbilityAssessmentReport(
      generatedAt: DateTime.now(),
      currentAbility: _abilityModel,
      previousAbility: _assessmentReports.isNotEmpty ? _assessmentReports.last.currentAbility : null,
      improvementAreas: _identifyImprovementAreas(),
      achievementAreas: _identifyAchievementAreas(),
      levelChange: _calculateLevelChange(),
      personalizedSuggestions: _generatePersonalizedSuggestions(),
    );
    
    _assessmentReports.add(report);
    return report;
  }

  // 获取最新评估报告
  AbilityAssessmentReport? getLatestAssessmentReport() {
    return _assessmentReports.isNotEmpty ? _assessmentReports.last : null;
  }

  // 识别改进领域
  List<String> _identifyImprovementAreas() {
    final areas = <String>[];
    
    if (_abilityModel['completion_ability'] < 0.6) {
      areas.add('任务完成能力');
    }
    if (_abilityModel['effect_quality'] < 0.6) {
      areas.add('任务完成质量');
    }
    if (_abilityModel['efficiency_level'] < 0.6) {
      areas.add('任务完成效率');
    }
    if (_abilityModel['persistence_level'] < 0.6) {
      areas.add('任务坚持程度');
    }
    
    return areas;
  }

  // 识别成就领域
  List<String> _identifyAchievementAreas() {
    final areas = <String>[];
    
    if (_abilityModel['completion_ability'] >= 0.8) {
      areas.add('任务完成能力');
    }
    if (_abilityModel['effect_quality'] >= 0.8) {
      areas.add('任务完成质量');
    }
    if (_abilityModel['efficiency_level'] >= 0.8) {
      areas.add('任务完成效率');
    }
    if (_abilityModel['persistence_level'] >= 0.8) {
      areas.add('任务坚持程度');
    }
    
    return areas;
  }

  // 计算等级变化
  String _calculateLevelChange() {
    if (_assessmentReports.isEmpty) {
      return '首次评估';
    }
    
    final previousLevel = _assessmentReports.last.currentAbility['level'] ?? 1;
    final currentLevel = _abilityModel['level'] ?? 1;
    
    if (currentLevel > previousLevel) {
      return '等级提升';
    } else if (currentLevel < previousLevel) {
      return '等级下降';
    } else {
      return '等级稳定';
    }
  }

  // 生成个性化建议
  List<String> _generatePersonalizedSuggestions() {
    final suggestions = <String>[];
    
    // 根据各能力维度生成建议
    if (_abilityModel['completion_ability'] < 0.6) {
      suggestions.add('建议从简单任务开始，逐步提高完成率');
    }
    if (_abilityModel['effect_quality'] < 0.6) {
      suggestions.add('建议注重任务质量，追求高质量完成');
    }
    if (_abilityModel['efficiency_level'] < 0.6) {
      suggestions.add('建议合理规划时间，提高任务完成效率');
    }
    if (_abilityModel['persistence_level'] < 0.6) {
      suggestions.add('建议坚持每日完成任务，培养良好习惯');
    }
    
    // 根据等级生成建议
    final level = _abilityModel['level'] ?? 1;
    if (level < 5) {
      suggestions.add('建议多完成简单和中等难度的任务，积累经验');
    } else if (level >= 5 && level < 8) {
      suggestions.add('建议尝试挑战困难任务，突破自我');
    } else {
      suggestions.add('建议保持高水平表现，追求卓越');
    }
    
    return suggestions;
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
    
    // 检查是否需要被动评估
    await _checkPassiveAssessment();
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
  
  // 获取能力评估报告历史
  List<AbilityAssessmentReport> getAssessmentReports() {
    return _assessmentReports;
  }
}
