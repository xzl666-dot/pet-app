import 'package:sqflite/sqflite.dart';
import '../models/pet_model.dart';
import '../models/task_model.dart';
import '../database/database_helper.dart';

class PetStateManager {
  static final PetStateManager instance = PetStateManager._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  PetStateManager._init();

  // 检查是否有宠物
  Future<bool> hasPet() async {
    final pets = await getAllPets();
    return pets.isNotEmpty;
  }

  // 获取所有宠物
  Future<List<PetModel>> getAllPets() async {
    return await _dbHelper.readAllPets();
  }

  // 创建或获取宠物
  Future<PetModel> getOrCreatePet({String name = '我的宠物'}) async {
    final pets = await _dbHelper.readAllPets();
    if (pets.isNotEmpty) {
      return pets.first;
    } else {
      // 当没有宠物时，会在UI层引导用户到宠物选择页面
      final pet = PetModel(name: name);
      await _dbHelper.createPet(pet);
      return pet;
    }
  }

  // 带指定种类创建宠物
  Future<void> _createPetWithType(PetModel pet) async {
    await _dbHelper.createPet(pet);
  }

  // 更新宠物状态
  Future<PetModel> updatePetState(
    PetBenefitType benefitType,
    int value,
    {double efficiencyMultiplier = 1.0, bool isConsecutiveCompletion = false}
  ) async {
    final pet = await getOrCreatePet();
    int nutrition = pet.nutrition;
    int happiness = pet.happiness;
    int skillPoint = pet.skillPoint;

    // 计算最终奖励值（考虑效率加成和连续完成奖励）
    int finalValue = value;
    
    // 效率加成：高效完成任务获得额外奖励
    if (efficiencyMultiplier > 1.0) {
      finalValue = (value * efficiencyMultiplier).toInt();
    }
    
    // 连续完成奖励：连续完成任务获得额外技能点
    if (isConsecutiveCompletion) {
      skillPoint = _clampValue(skillPoint + 2, 0, 100); // 额外2点技能点
    }

    // 根据收益类型更新对应属性
    switch (benefitType) {
      case PetBenefitType.nutrition:
        nutrition = _clampValue(nutrition + finalValue, 0, 100);
        break;
      case PetBenefitType.happiness:
        happiness = _clampValue(happiness + finalValue, 0, 100);
        break;
      case PetBenefitType.skillPoint:
        skillPoint = _clampValue(skillPoint + finalValue, 0, 100);
        break;
    }

    // 检查是否需要进化形态
    PetForm newForm = _checkFormEvolution(pet.form, skillPoint);
    bool hasEvolved = newForm != pet.form;

    // 创建更新后的宠物实例
    final updatedPet = pet.copyWith(
      nutrition: nutrition,
      happiness: happiness,
      skillPoint: skillPoint,
      form: newForm,
      lastUpdated: DateTime.now(),
    );

    // 保存到数据库
    await _dbHelper.updatePet(updatedPet);
    
    // 如果宠物进化了，返回进化后的宠物
    return updatedPet;
  }

  // 手动更新宠物属性
  Future<PetModel> updatePetAttributes({
    int? nutrition,
    int? happiness,
    int? skillPoint,
  }) async {
    final pet = await getOrCreatePet();

    int newNutrition = nutrition ?? pet.nutrition;
    int newHappiness = happiness ?? pet.happiness;
    int newSkillPoint = skillPoint ?? pet.skillPoint;

    // 检查是否需要进化形态
    PetForm newForm = _checkFormEvolution(pet.form, newSkillPoint);

    // 创建更新后的宠物实例
    final updatedPet = pet.copyWith(
      nutrition: _clampValue(newNutrition, 0, 100),
      happiness: _clampValue(newHappiness, 0, 100),
      skillPoint: _clampValue(newSkillPoint, 0, 100),
      form: newForm,
      lastUpdated: DateTime.now(),
    );

    // 保存到数据库
    await _dbHelper.updatePet(updatedPet);
    return updatedPet;
  }

  // 更改宠物名称
  Future<PetModel> renamePet(String newName) async {
    final pet = await getOrCreatePet();
    final updatedPet = pet.copyWith(
      name: newName,
      lastUpdated: DateTime.now(),
    );
    await _dbHelper.updatePet(updatedPet);
    return updatedPet;
  }

  // 检查形态进化
  PetForm _checkFormEvolution(PetForm currentForm, int skillPoint) {
    PetForm newForm = currentForm;

    if (skillPoint >= PetForm.advanced.getSkillPointThreshold()) {
      newForm = PetForm.advanced;
    } else if (skillPoint >= PetForm.adult.getSkillPointThreshold()) {
      newForm = PetForm.adult;
    } else if (skillPoint >= PetForm.adolescent.getSkillPointThreshold()) {
      newForm = PetForm.adolescent;
    }

    return newForm;
  }

  // 限制数值在0-100之间
  int _clampValue(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  // 获取宠物的当前状态
  Future<PetModel> getCurrentPetState() async {
    return await getOrCreatePet();
  }



  // 创建指定种类的宠物
  Future<PetModel> createPetWithType({String name = '我的宠物', required PetType type}) async {
    final pet = PetModel(name: name, type: type);
    await _dbHelper.createPet(pet);
    return pet;
  }
}