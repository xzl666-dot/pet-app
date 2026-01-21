enum PetForm {
  baby,
  adolescent,
  adult,
  advanced
}

enum PetType {
  chick,
  puppy,
  kitten,
  bunny
}

class PetModel {
  int? id;
  String name;
  PetType type;
  PetForm form;
  int nutrition;
  int happiness;
  int skillPoint;
  DateTime createdAt;
  DateTime lastUpdated;

  PetModel({
    this.id,
    required this.name,
    this.type = PetType.chick,
    this.form = PetForm.baby,
    this.nutrition = 50,
    this.happiness = 50,
    this.skillPoint = 0,
    DateTime? createdAt,
    DateTime? lastUpdated,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'form': form.index,
      'nutrition': nutrition,
      'happiness': happiness,
      'skill_point': skillPoint,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_updated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory PetModel.fromMap(Map<String, dynamic> map) {
    return PetModel(
      id: map['id'],
      name: map['name'],
      type: map.containsKey('type') ? PetType.values[map['type']] : PetType.chick,
      form: PetForm.values[map['form']],
      nutrition: map['nutrition'],
      happiness: map['happiness'],
      skillPoint: map['skill_point'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['last_updated']),
    );
  }

  PetModel copyWith({
    int? id,
    String? name,
    PetType? type,
    PetForm? form,
    int? nutrition,
    int? happiness,
    int? skillPoint,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return PetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      form: form ?? this.form,
      nutrition: nutrition ?? this.nutrition,
      happiness: happiness ?? this.happiness,
      skillPoint: skillPoint ?? this.skillPoint,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'Pet{id: $id, name: $name, type: $type, form: $form, nutrition: $nutrition, happiness: $happiness, skillPoint: $skillPoint}';
  }
}

extension PetTypeExtension on PetType {
  String getTypeName() {
    switch (this) {
      case PetType.chick:
        return '小鸡';
      case PetType.puppy:
        return '小狗';
      case PetType.kitten:
        return '小猫';
      case PetType.bunny:
        return '小兔';
    }
  }
}

extension PetFormExtension on PetForm {
  String getFormName() {
    switch (this) {
      case PetForm.baby:
        return '幼年期';
      case PetForm.adolescent:
        return '青少年期';
      case PetForm.adult:
        return '成年期';
      case PetForm.advanced:
        return '进阶形态';
    }
  }

  int getSkillPointThreshold() {
    switch (this) {
      case PetForm.baby:
        return 10;
      case PetForm.adolescent:
        return 25;
      case PetForm.adult:
        return 50;
      case PetForm.advanced:
        return 100;
    }
  }
}