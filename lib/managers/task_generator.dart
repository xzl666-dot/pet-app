import 'dart:math';
import '../models/task_model.dart';
import './user_ability_manager.dart';

class TaskGenerator {
  static final TaskGenerator instance = TaskGenerator._init();
  final Random _random = Random();

  TaskGenerator._init();

  // 任务模板库
  final Map<TaskDifficulty, List<Map<String, dynamic>>> _taskTemplates = {
    TaskDifficulty.easy: [
      {'name': '完成10分钟学习', 'baseBenefit': 5},
      {'name': '整理桌面', 'baseBenefit': 3},
      {'name': '喝一杯水', 'baseBenefit': 2},
      {'name': '做5个俯卧撑', 'baseBenefit': 4},
      {'name': '写一篇日记', 'baseBenefit': 6},
      {'name': '阅读20页书籍', 'baseBenefit': 5},
      {'name': '给朋友发一条问候消息', 'baseBenefit': 3},
      {'name': '冥想5分钟', 'baseBenefit': 4},
      {'name': '听一首喜欢的歌曲', 'baseBenefit': 2},
      {'name': '记录今日待办事项', 'baseBenefit': 3},
    ],
    TaskDifficulty.medium: [
      {'name': '完成30分钟学习', 'baseBenefit': 12},
      {'name': '完成一项工作任务', 'baseBenefit': 15},
      {'name': '运动30分钟', 'baseBenefit': 10},
      {'name': '学习一个新技能', 'baseBenefit': 18},
      {'name': '写一篇文章', 'baseBenefit': 14},
      {'name': '打扫房间', 'baseBenefit': 11},
      {'name': '准备一顿健康的餐食', 'baseBenefit': 13},
      {'name': '阅读1小时书籍', 'baseBenefit': 12},
      {'name': '学习一门外语30分钟', 'baseBenefit': 16},
      {'name': '完成一个编程练习', 'baseBenefit': 15},
    ],
    TaskDifficulty.hard: [
      {'name': '完成2小时专注学习', 'baseBenefit': 25},
      {'name': '完成一个重要项目', 'baseBenefit': 30},
      {'name': '运动1小时', 'baseBenefit': 22},
      {'name': '学习新技能3小时', 'baseBenefit': 35},
      {'name': '写一篇高质量文章', 'baseBenefit': 28},
      {'name': '完成一次深度整理', 'baseBenefit': 26},
      {'name': '阅读一本新书的一半', 'baseBenefit': 24},
      {'name': '学习一门外语2小时', 'baseBenefit': 29},
      {'name': '完成一个复杂的编程项目', 'baseBenefit': 32},
      {'name': '参加一个研讨会或课程', 'baseBenefit': 30},
    ],
  };

  // 随机选择任务模板
  Map<String, dynamic> _selectRandomTemplate(TaskDifficulty difficulty) {
    final templates = _taskTemplates[difficulty]!;
    final index = _random.nextInt(templates.length);
    return templates[index];
  }

  // 根据难度生成合理的奖励值
  int _generateBenefitValue(TaskDifficulty difficulty) {
    final template = _selectRandomTemplate(difficulty);
    final baseBenefit = template['baseBenefit'] as int;
    
    // 根据难度添加随机浮动值
    int randomBonus;
    switch (difficulty) {
      case TaskDifficulty.easy:
        randomBonus = _random.nextInt(3); // 0-2
        break;
      case TaskDifficulty.medium:
        randomBonus = _random.nextInt(5) + 2; // 2-6
        break;
      case TaskDifficulty.hard:
        randomBonus = _random.nextInt(8) + 5; // 5-12
        break;
    }
    
    return baseBenefit + randomBonus;
  }

  // 随机选择奖励类型
  PetBenefitType _selectRandomBenefitType() {
    final types = PetBenefitType.values;
    return types[_random.nextInt(types.length)];
  }

  // 生成单个任务
  TaskModel generateTask(TaskDifficulty difficulty, {DateTime? deadline}) {
    final template = _selectRandomTemplate(difficulty);
    final taskName = template['name'] as String;
    
    // 如果没有指定截止时间，根据难度设置合理的截止时间
    final taskDeadline = deadline ?? DateTime.now().add(
      Duration(
        hours: difficulty == TaskDifficulty.easy ? 6 : 
               difficulty == TaskDifficulty.medium ? 12 : 24,
      ),
    );

    return TaskModel(
      name: taskName,
      difficulty: difficulty,
      deadline: taskDeadline,
      benefitType: _selectRandomBenefitType(),
      benefitValue: _generateBenefitValue(difficulty),
      isCompleted: false,
      createdAt: DateTime.now(),
    );
  }

  // 生成每日任务列表
  Future<List<TaskModel>> generateDailyTasks() async {
    final tasks = <TaskModel>[];
    final today = DateTime.now();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);

    // 获取用户能力评估
    final userAbilityManager = UserAbilityManager.instance;
    await userAbilityManager.initializeAbilityModel();
    final abilityModel = userAbilityManager.abilityModel;
    final overallAbility = abilityModel['overall_ability'] ?? 0.5;

    // 根据用户能力动态调整任务难度和数量
    Map<TaskDifficulty, int> taskCounts;
    if (overallAbility < 0.33) {
      // 初级用户：更多简单任务
      taskCounts = {
        TaskDifficulty.easy: 4,
        TaskDifficulty.medium: 1,
        TaskDifficulty.hard: 0,
      };
    } else if (overallAbility < 0.66) {
      // 中级用户：平衡的任务难度
      taskCounts = {
        TaskDifficulty.easy: 2,
        TaskDifficulty.medium: 3,
        TaskDifficulty.hard: 1,
      };
    } else {
      // 高级用户：更多困难任务
      taskCounts = {
        TaskDifficulty.easy: 1,
        TaskDifficulty.medium: 2,
        TaskDifficulty.hard: 3,
      };
    }

    // 生成任务
    taskCounts.forEach((difficulty, count) {
      for (int i = 0; i < count; i++) {
        tasks.add(generateTask(difficulty, deadline: tomorrow));
      }
    });

    // 打乱任务顺序
    tasks.shuffle(_random);
    return tasks;
  }

  // 检查是否需要生成新任务
  Future<bool> shouldGenerateNewTasks(List<TaskModel> existingTasks) async {
    // 如果没有任务，需要生成
    if (existingTasks.isEmpty) {
      return true;
    }

    // 获取今天的日期
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = DateTime(today.year, today.month, today.day + 1);

    // 检查是否有今天生成的任务
    final todayTasks = existingTasks.where((task) {
      final createdAt = task.createdAt ?? DateTime.now();
      return createdAt.isAfter(todayStart) && createdAt.isBefore(todayEnd);
    }).toList();

    // 如果今天的任务不足6个，需要生成
    return todayTasks.length < 6;
  }
}
