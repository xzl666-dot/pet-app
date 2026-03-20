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
  int intimacy;
  int level;
  int exp;
  int expThreshold;
  DateTime createdAt;
  DateTime lastUpdated;

  PetModel({
    this.id,
    required this.name,
    this.type = PetType.chick,
    this.form = PetForm.baby,
    this.nutrition = 50,
    this.happiness = 50,
    this.intimacy = 0,
    this.level = 1,
    this.exp = 0,
    this.expThreshold = 100,
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
      'intimacy': intimacy,
      'level': level,
      'exp': exp,
      'exp_threshold': expThreshold,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_updated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory PetModel.fromMap(Map<String, dynamic> map) {
    return PetModel(
      id: map['petId'] ?? map['id'],
      name: map['petName'] ?? map['name'],
      type: map.containsKey('petType') 
          ? _parsePetType(map['petType']) 
          : (map.containsKey('type') ? PetType.values[map['type']] : PetType.chick),
      form: map.containsKey('form') ? PetForm.values[map['form']] : PetForm.baby,
      nutrition: map['nutrition'] ?? 50,
      happiness: map['happiness'] ?? 50,
      intimacy: map['intimacy'] ?? 0,
      level: map['level'] ?? 1,
      exp: map['exp'] ?? 0,
      expThreshold: map['expThreshold'] ?? map['exp_threshold'] ?? 100,
      createdAt: map['createTime'] != null 
          ? DateTime.parse(map['createTime']) 
          : (map.containsKey('created_at') ? DateTime.fromMillisecondsSinceEpoch(map['created_at']) : DateTime.now()),
      lastUpdated: DateTime.now(),
    );
  }

  static PetType _parsePetType(String typeStr) {
    switch (typeStr?.toLowerCase()) {
      case 'chick':
        return PetType.chick;
      case 'puppy':
        return PetType.puppy;
      case 'kitten':
        return PetType.kitten;
      case 'bunny':
        return PetType.bunny;
      default:
        return PetType.chick;
    }
  }

  PetModel copyWith({
    int? id,
    String? name,
    PetType? type,
    PetForm? form,
    int? nutrition,
    int? happiness,
    int? intimacy,
    int? level,
    int? exp,
    int? expThreshold,
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
      intimacy: intimacy ?? this.intimacy,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      expThreshold: expThreshold ?? this.expThreshold,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'Pet{id: $id, name: $name, type: $type, form: $form, nutrition: $nutrition, happiness: $happiness, intimacy: $intimacy, level: $level, exp: $exp}';
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
        return '成熟期';
    }
  }

  static PetForm getFormByLevel(int level) {
    if (level >= 91) return PetForm.advanced;
    if (level >= 61) return PetForm.adult;
    if (level >= 31) return PetForm.adolescent;
    return PetForm.baby;
  }

  String getLevelRange() {
    switch (this) {
      case PetForm.baby:
        return '1-30级';
      case PetForm.adolescent:
        return '31-60级';
      case PetForm.adult:
        return '61-90级';
      case PetForm.advanced:
        return '91-100级';
    }
  }

  String getUnlockCondition() {
    switch (this) {
      case PetForm.baby:
        return '初始阶段';
      case PetForm.adolescent:
        return '31级且营养≥65、快乐≥65、亲密度≥150';
      case PetForm.adult:
        return '61级且营养≥80、快乐≥80、亲密度≥400';
      case PetForm.advanced:
        return '91级且营养≥95、快乐≥95、亲密度≥800';
    }
  }
}