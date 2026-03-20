import 'package:flutter/material.dart';

enum SubjectType {
  math,
  english,
  physics,
  biology,
  worldHistory,
  chemistry,
}

enum TaskDifficulty {
  easy,
  medium,
  hard,
}

enum PetBenefitType {
  nutrition,
  happiness,
  skillPoint,
}

class SubTask {
  String name;
  bool isCompleted;
  int? stepNumber;
  String? description;

  SubTask({
    required this.name,
    this.isCompleted = false,
    this.stepNumber,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'is_completed': isCompleted ? 1 : 0,
      'step_number': stepNumber,
      'description': description,
    };
  }

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      name: map['name'] ?? '',
      isCompleted: map['is_completed'] == 1,
      stepNumber: map['step_number'],
      description: map['description'],
    );
  }
}

enum FlowState {
  low,
  medium,
  high,
  peak,
}

class StudyTaskModel {
  int? id;
  String name;
  String? description;
  SubjectType subject;
  TaskDifficulty difficulty;
  DateTime deadline;
  PetBenefitType benefitType;
  int benefitValue;
  bool isCompleted;
  DateTime? createdAt;
  DateTime? completedAt;
  int? userId;
  
  // 任务拆分相关
  List<SubTask>? subTasks;
  int? currentStep;
  int? totalSteps;
  
  // 质量评估相关
  int? qualityScore;
  int? completionTime; // 完成时间（分钟）
  double? accuracy; // 准确率
  double? efficiency; // 效率
  
  // 心流理论相关
  FlowState? flowState;
  int? focusLevel; // 专注程度 0-100
  
  // 任务匹配相关
  String? recommendedReason;
  double? abilityMatchScore; // 能力匹配分数 0-1

  StudyTaskModel({
    this.id,
    required this.name,
    this.description,
    required this.subject,
    required this.difficulty,
    required this.deadline,
    required this.benefitType,
    required this.benefitValue,
    this.isCompleted = false,
    this.createdAt,
    this.completedAt,
    this.userId,
    this.subTasks,
    this.currentStep = 1,
    this.totalSteps = 1,
    this.qualityScore,
    this.completionTime,
    this.accuracy,
    this.efficiency,
    this.flowState = FlowState.medium,
    this.focusLevel = 50,
    this.recommendedReason,
    this.abilityMatchScore,
  });

  Map<String, dynamic> toMap() {
    final now = DateTime.now();
    return {
      'id': id,
      'name': name,
      'description': description,
      'subject': subject.index,
      'difficulty': difficulty.index,
      'deadline': deadline.millisecondsSinceEpoch ~/ 1000,
      'benefit_type': benefitType.index,
      'benefit_value': benefitValue,
      'is_completed': isCompleted ?1 : 0,
      'created_at': (createdAt?.millisecondsSinceEpoch ?? now.millisecondsSinceEpoch) ~/ 1000,
      'completed_at': completedAt != null ? completedAt!.millisecondsSinceEpoch ~/ 1000 : null,
      'user_id': userId,
      'sub_tasks': subTasks?.map((st) => st.toMap()).toList(),
      'current_step': currentStep,
      'total_steps': totalSteps,
      'quality_score': qualityScore,
      'completion_time': completionTime,
      'accuracy': accuracy,
      'efficiency': efficiency,
      'flow_state': flowState?.index,
      'focus_level': focusLevel,
      'recommended_reason': recommendedReason,
      'ability_match_score': abilityMatchScore,
    };
  }

  factory StudyTaskModel.fromMap(Map<String, dynamic> map) {
    List<SubTask>? subTasks;
    if (map['sub_tasks'] is List) {
      subTasks = (map['sub_tasks'] as List).map((st) => SubTask.fromMap(st)).toList();
    }
    
    return StudyTaskModel(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'],
      subject: SubjectType.values[map['subject'] ?? 0],
      difficulty: TaskDifficulty.values[map['difficulty'] ?? 0],
      deadline: DateTime.fromMillisecondsSinceEpoch((map['deadline'] ?? 0) * 1000),
      benefitType: PetBenefitType.values[map['benefit_type'] ?? 0],
      benefitValue: map['benefit_value'] ?? 10,
      isCompleted: map['is_completed'] == 1,
      createdAt: map['created_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] * 1000) 
          : DateTime.now(),
      completedAt: map['completed_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] * 1000) 
          : null,
      userId: map['user_id'],
      subTasks: subTasks,
      currentStep: map['current_step'] ?? 1,
      totalSteps: map['total_steps'] ?? 1,
      qualityScore: map['quality_score'],
      completionTime: map['completion_time'],
      accuracy: map['accuracy'],
      efficiency: map['efficiency'],
      flowState: map['flow_state'] != null ? FlowState.values[map['flow_state']] : FlowState.medium,
      focusLevel: map['focus_level'] ?? 50,
      recommendedReason: map['recommended_reason'],
      abilityMatchScore: map['ability_match_score'],
    );
  }

  StudyTaskModel copyWith({
    int? id,
    String? name,
    String? description,
    SubjectType? subject,
    TaskDifficulty? difficulty,
    DateTime? deadline,
    PetBenefitType? benefitType,
    int? benefitValue,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    int? userId,
    List<SubTask>? subTasks,
    int? currentStep,
    int? totalSteps,
    int? qualityScore,
    int? completionTime,
    double? accuracy,
    double? efficiency,
    FlowState? flowState,
    int? focusLevel,
    String? recommendedReason,
    double? abilityMatchScore,
  }) {
    return StudyTaskModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      difficulty: difficulty ?? this.difficulty,
      deadline: deadline ?? this.deadline,
      benefitType: benefitType ?? this.benefitType,
      benefitValue: benefitValue ?? this.benefitValue,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      userId: userId ?? this.userId,
      subTasks: subTasks ?? this.subTasks,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      qualityScore: qualityScore ?? this.qualityScore,
      completionTime: completionTime ?? this.completionTime,
      accuracy: accuracy ?? this.accuracy,
      efficiency: efficiency ?? this.efficiency,
      flowState: flowState ?? this.flowState,
      focusLevel: focusLevel ?? this.focusLevel,
      recommendedReason: recommendedReason ?? this.recommendedReason,
      abilityMatchScore: abilityMatchScore ?? this.abilityMatchScore,
    );
  }
  
  // 计算任务进度
  double get progress {
    if (totalSteps == null || totalSteps == 0) return isCompleted ? 1.0 : 0.0;
    if (isCompleted) return 1.0;
    return (currentStep ?? 1) / totalSteps!;
  }
  
  // 计算子任务完成率
  double get subTaskCompletionRate {
    if (subTasks == null || subTasks!.isEmpty) return isCompleted ? 1.0 : 0.0;
    final completedSubTasks = subTasks!.where((st) => st.isCompleted).length;
    return completedSubTasks / subTasks!.length;
  }
}

extension SubjectTypeExtension on SubjectType {
  String getSubjectName() {
    switch (this) {
      case SubjectType.math:
        return '数学';
      case SubjectType.english:
        return '英语';
      case SubjectType.physics:
        return '物理';
      case SubjectType.biology:
        return '生物';
      case SubjectType.worldHistory:
        return '世界历史';
      case SubjectType.chemistry:
        return '化学';
    }
  }

  String getSubjectIcon() {
    switch (this) {
      case SubjectType.math:
        return '📐';
      case SubjectType.english:
        return '📚';
      case SubjectType.physics:
        return '⚡';
      case SubjectType.biology:
        return '🧬';
      case SubjectType.worldHistory:
        return '🌍';
      case SubjectType.chemistry:
        return '🧪';
    }
  }

  Color getSubjectColor() {
    switch (this) {
      case SubjectType.math:
        return Color(0xFF4CAF50);
      case SubjectType.english:
        return Color(0xFF2196F3);
      case SubjectType.physics:
        return Color(0xFFFF9800);
      case SubjectType.biology:
        return Color(0xFF9C27B0);
      case SubjectType.worldHistory:
        return Color(0xFF795548);
      case SubjectType.chemistry:
        return Color(0xFFE91E63);
    }
  }
}

extension TaskDifficultyExtension on TaskDifficulty {
  String getDifficultyName() {
    switch (this) {
      case TaskDifficulty.easy:
        return '简单';
      case TaskDifficulty.medium:
        return '中等';
      case TaskDifficulty.hard:
        return '困难';
    }
  }

  int getExpReward() {
    switch (this) {
      case TaskDifficulty.easy:
        return 15; // 基础任务 + 15exp
      case TaskDifficulty.medium:
        return 30; // 进阶任务 + 30exp
      case TaskDifficulty.hard:
        return 50; // 挑战任务 + 50exp
    }
  }
}