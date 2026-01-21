import 'dart:math';
import '../models/task_model.dart';
import '../managers/user_ability_manager.dart';

class SocialChallengeManager {
  static final SocialChallengeManager instance = SocialChallengeManager._init();
  final Random _random = Random();
  
  // 模拟的用户数据（实际项目中应从服务器获取）
  final List<Map<String, dynamic>> _mockUsers = [
    {'id': 'user_001', 'name': '小明', 'level': 10, 'overall_ability': 0.65},
    {'id': 'user_002', 'name': '小红', 'level': 8, 'overall_ability': 0.55},
    {'id': 'user_003', 'name': '小李', 'level': 12, 'overall_ability': 0.75},
    {'id': 'user_004', 'name': '小王', 'level': 6, 'overall_ability': 0.45},
    {'id': 'user_005', 'name': '小张', 'level': 15, 'overall_ability': 0.85},
  ];
  
  // 挑战历史
  final List<Map<String, dynamic>> _challengeHistory = [];

  SocialChallengeManager._init();

  // 智能匹配对手
  Future<Map<String, dynamic>?> matchOpponent() async {
    final userAbilityManager = UserAbilityManager.instance;
    await userAbilityManager.initializeAbilityModel();
    final currentUserAbility = userAbilityManager.abilityModel['overall_ability'] ?? 0.5;
    
    // 过滤出能力相近的用户（±0.15范围内）
    final suitableOpponents = _mockUsers.where((user) {
      double diff = (user['overall_ability'] as double) - currentUserAbility;
      return diff.abs() <= 0.15;
    }).toList();
    
    if (suitableOpponents.isEmpty) {
      // 如果没有合适的对手，返回能力最接近的用户
      _mockUsers.sort((a, b) {
        double aDiff = (a['overall_ability'] as double) - currentUserAbility;
        double bDiff = (b['overall_ability'] as double) - currentUserAbility;
        return aDiff.abs().compareTo(bDiff.abs());
      });
      return _mockUsers.first;
    }
    
    // 从合适的对手中随机选择一个
    return suitableOpponents[_random.nextInt(suitableOpponents.length)];
  }

  // 生成挑战任务
  Future<List<TaskModel>> generateChallengeTasks(Map<String, dynamic> opponent) async {
    final userAbilityManager = UserAbilityManager.instance;
    await userAbilityManager.initializeAbilityModel();
    final currentUserAbility = userAbilityManager.abilityModel['overall_ability'] ?? 0.5;
    final opponentAbility = opponent['overall_ability'] as double;
    
    // 根据双方能力水平确定任务难度
    final averageAbility = (currentUserAbility + opponentAbility) / 2;
    
    TaskDifficulty difficulty;
    if (averageAbility < 0.33) {
      difficulty = TaskDifficulty.easy;
    } else if (averageAbility < 0.66) {
      difficulty = TaskDifficulty.medium;
    } else {
      difficulty = TaskDifficulty.hard;
    }
    
    // 生成3个挑战任务
    final tasks = <TaskModel>[];
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    // 挑战任务模板
    final challengeTemplates = [
      '完成30分钟专注学习',
      '运动45分钟',
      '阅读50页书籍',
      '写一篇500字以上的文章',
      '学习一个新技能',
    ];
    
    for (int i = 0; i < 3; i++) {
      final template = challengeTemplates[_random.nextInt(challengeTemplates.length)];
      final task = TaskModel(
        name: '挑战：$template',
        difficulty: difficulty,
        deadline: tomorrow,
        benefitType: PetBenefitType.values[_random.nextInt(PetBenefitType.values.length)],
        benefitValue: _generateBenefitValue(difficulty),
        isCompleted: false,
        createdAt: now,
      );
      tasks.add(task);
    }
    
    return tasks;
  }

  // 生成奖励值
  int _generateBenefitValue(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return _random.nextInt(5) + 5; // 5-10
      case TaskDifficulty.medium:
        return _random.nextInt(8) + 12; // 12-19
      case TaskDifficulty.hard:
        return _random.nextInt(10) + 20; // 20-29
    }
  }

  // 记录挑战结果
  void recordChallengeResult({
    required String opponentId,
    required String opponentName,
    required List<TaskModel> tasks,
    required int completedTasks,
    required bool isWinner,
  }) {
    final challengeResult = {
      'challenge_id': 'challenge_${DateTime.now().millisecondsSinceEpoch}',
      'opponent_id': opponentId,
      'opponent_name': opponentName,
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'completed_tasks': completedTasks,
      'total_tasks': tasks.length,
      'is_winner': isWinner,
      'challenge_date': DateTime.now().toString(),
    };
    
    _challengeHistory.add(challengeResult);
  }

  // 获取挑战历史
  List<Map<String, dynamic>> getChallengeHistory() {
    return _challengeHistory;
  }

  // 获取挑战统计
  Map<String, dynamic> getChallengeStatistics() {
    final totalChallenges = _challengeHistory.length;
    final wonChallenges = _challengeHistory.where((result) => result['is_winner']).length;
    final winRate = totalChallenges > 0 ? wonChallenges / totalChallenges : 0.0;
    
    int totalTasks = 0;
    int completedTasks = 0;
    
    for (final result in _challengeHistory) {
      totalTasks += result['total_tasks'] as int;
      completedTasks += result['completed_tasks'] as int;
    }
    
    final taskCompletionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    
    return {
      'total_challenges': totalChallenges,
      'won_challenges': wonChallenges,
      'win_rate': winRate,
      'total_tasks': totalTasks,
      'completed_tasks': completedTasks,
      'task_completion_rate': taskCompletionRate,
    };
  }
}
