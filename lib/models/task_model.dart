enum TaskDifficulty {
  easy,
  medium,
  hard
}

enum PetBenefitType {
  nutrition,
  happiness,
  skillPoint
}

class TaskModel {
  int? id;
  String name;
  TaskDifficulty difficulty;
  DateTime deadline;
  PetBenefitType benefitType;
  int benefitValue;
  bool isCompleted;
  DateTime? createdAt;
  DateTime? completedAt;

  TaskModel({
    this.id,
    required this.name,
    required this.difficulty,
    required this.deadline,
    required this.benefitType,
    required this.benefitValue,
    this.isCompleted = false,
    this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'difficulty': difficulty.index,
      'deadline': deadline.millisecondsSinceEpoch,
      'benefit_type': benefitType.index,
      'benefit_value': benefitValue,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      name: map['name'],
      difficulty: TaskDifficulty.values[map['difficulty']],
      deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline']),
      benefitType: PetBenefitType.values[map['benefit_type']],
      benefitValue: map['benefit_value'],
      isCompleted: map['is_completed'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      completedAt: map['completed_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['completed_at']) : null,
    );
  }

  @override
  String toString() {
    return 'Task{id: $id, name: $name, difficulty: $difficulty, deadline: $deadline, benefitType: $benefitType, benefitValue: $benefitValue, isCompleted: $isCompleted}';
  }

  TaskModel copyWith({
    int? id,
    String? name,
    TaskDifficulty? difficulty,
    DateTime? deadline,
    PetBenefitType? benefitType,
    int? benefitValue,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      name: name ?? this.name,
      difficulty: difficulty ?? this.difficulty,
      deadline: deadline ?? this.deadline,
      benefitType: benefitType ?? this.benefitType,
      benefitValue: benefitValue ?? this.benefitValue,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}