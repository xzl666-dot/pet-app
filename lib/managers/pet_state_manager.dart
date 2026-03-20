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
    int intimacy = pet.intimacy;
    int exp = pet.exp;

    // 计算最终奖励值
    int finalValue = value;

    // 根据收益类型更新对应属性
    switch (benefitType) {
      case PetBenefitType.nutrition:
        nutrition = _clampValue(nutrition + finalValue, 0, 100);
        break;
      case PetBenefitType.happiness:
        happiness = _clampValue(happiness + finalValue, 0, 100);
        break;
      case PetBenefitType.intimacy:
        intimacy = _clampValue(intimacy + finalValue, 0, 800);
        break;
      case PetBenefitType.exp:
        // 经验只来自成长奶昔
        if (pet.level < 10) {
          exp += finalValue;
        }
        break;
    }

    // 检查是否需要进化形态
    PetForm newForm = _checkFormEvolution(pet.form, pet.level);
    bool hasEvolved = newForm != pet.form;

    // 创建更新后的宠物实例
    final updatedPet = pet.copyWith(
      nutrition: nutrition,
      happiness: happiness,
      intimacy: intimacy,
      exp: exp,
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
    int? exp,
  }) async {
    final pet = await getOrCreatePet();

    int newNutrition = nutrition ?? pet.nutrition;
    int newHappiness = happiness ?? pet.happiness;
    int newExp = exp ?? pet.exp;

    // 检查是否需要进化形态
    PetForm newForm = _checkFormEvolution(pet.form, newExp);

    // 创建更新后的宠物实例
    final updatedPet = pet.copyWith(
      nutrition: _clampValue(newNutrition, 0, 100),
      happiness: _clampValue(newHappiness, 0, 100),
      exp: newExp,
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
  PetForm _checkFormEvolution(PetForm currentForm, int level) {
    PetForm newForm = currentForm;

    if (level >= 10) {
      newForm = PetForm.advanced;
    } else if (level >= 7) {
      newForm = PetForm.adult;
    } else if (level >= 4) {
      newForm = PetForm.adolescent;
    } else {
      newForm = PetForm.baby;
    }

    return newForm;
  }

  // 限制数值在指定范围内
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