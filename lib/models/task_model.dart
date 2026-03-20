// 任务类型枚举
enum TaskCategory {
  study,            // 学习类
  campus,           // 校园类
  life,             // 生活类
  interest,         // 兴趣类
  social,           // 社交类
  career,           // 职业规划类
  growth,           // 成长进阶类
  other             // 其他
}

// 任务频率枚举
enum TaskFrequency {
  dailyBasic,   // 每日基础
  weeklyAdvance, // 每周进阶
  flexibleOptional // 弹性选做
}

// 任务难度枚举
enum TaskDifficulty {
  easy,
  medium,
  hard
}

// 宠物收益类型枚举
enum PetBenefitType {
  nutrition,
  happiness,
  intimacy,
  exp
}

class TaskModel {
  int? id;
  String name;
  TaskCategory category;
  TaskFrequency frequency;
  TaskDifficulty difficulty;
  DateTime deadline;
  PetBenefitType benefitType;
  int benefitValue;
  int growthValue; // 成长值
  int happinessValue; // 幸福度
  int duration; // 任务时长（分钟）
  double weight; // 任务权重
  String description; // 任务描述
  List<String> tags; // 任务标签
  bool isCompleted;
  DateTime? createdAt;
  DateTime? completedAt;

  TaskModel({
    this.id,
    required this.name,
    required this.category,
    required this.frequency,
    required this.difficulty,
    required this.deadline,
    required this.benefitType,
    required this.benefitValue,
    required this.growthValue,
    required this.happinessValue,
    required this.duration,
    required this.weight,
    required this.description,
    required this.tags,
    this.isCompleted = false,
    this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.index,
      'frequency': frequency.index,
      'difficulty': difficulty.index,
      'deadline': deadline.millisecondsSinceEpoch,
      'benefit_type': benefitType.index,
      'benefit_value': benefitValue,
      'growth_value': growthValue,
      'happiness_value': happinessValue,
      'duration': duration,
      'weight': weight,
      'description': description,
      'tags': tags.join(','),
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      name: map['name'],
      category: TaskCategory.values[map['category']],
      frequency: TaskFrequency.values[map['frequency']],
      difficulty: TaskDifficulty.values[map['difficulty']],
      deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline']),
      benefitType: PetBenefitType.values[map['benefit_type']],
      benefitValue: map['benefit_value'],
      growthValue: map['growth_value'],
      happinessValue: map['happiness_value'],
      duration: map['duration'],
      weight: map['weight'],
      description: map['description'],
      tags: (map['tags'] as String).split(','),
      isCompleted: map['is_completed'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      completedAt: map['completed_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['completed_at']) : null,
    );
  }

  @override
  String toString() {
    return 'Task{id: $id, name: $name, category: $category, frequency: $frequency, difficulty: $difficulty, duration: $duration, benefitValue: $benefitValue, isCompleted: $isCompleted}';
  }

  TaskModel copyWith({
    int? id,
    String? name,
    TaskCategory? category,
    TaskFrequency? frequency,
    TaskDifficulty? difficulty,
    DateTime? deadline,
    PetBenefitType? benefitType,
    int? benefitValue,
    int? growthValue,
    int? happinessValue,
    int? duration,
    double? weight,
    String? description,
    List<String>? tags,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      difficulty: difficulty ?? this.difficulty,
      deadline: deadline ?? this.deadline,
      benefitType: benefitType ?? this.benefitType,
      benefitValue: benefitValue ?? this.benefitValue,
      growthValue: growthValue ?? this.growthValue,
      happinessValue: happinessValue ?? this.happinessValue,
      duration: duration ?? this.duration,
      weight: weight ?? this.weight,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}