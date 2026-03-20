import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../models/task_model.dart';
import 'pet_state_manager.dart';

class PetManager {
  static final PetManager instance = PetManager._init();
  final PetStateManager _petStateManager = PetStateManager.instance;

  PetManager._init();

  // 初始化宠物
  Future<void> initializePet() async {
    try {
      // 确保有宠物存在
      await _petStateManager.getOrCreatePet();
    } catch (e) {
      print('初始化宠物失败: $e');
    }
  }

  // 获取宠物
  Future<PetModel> getPet() async {
    return await _petStateManager.getOrCreatePet();
  }

  // 获取所需经验值
  int getRequiredExperience(int level) {
    // 简单的经验值计算公式：每级所需经验值 = 等级 * 100
    return level * 100;
  }

  // 更新宠物状态
  Future<PetModel> updatePetState(
    PetBenefitType benefitType,
    int value,
    {double efficiencyMultiplier = 1.0, bool isConsecutiveCompletion = false}
  ) async {
    return await _petStateManager.updatePetState(
      benefitType,
      value,
      efficiencyMultiplier: efficiencyMultiplier,
      isConsecutiveCompletion: isConsecutiveCompletion
    );
  }

  // 检查宠物是否进化
  Future<bool> checkEvolution() async {
    final pet = await getPet();
    final currentForm = pet.form;
    final newForm = _checkFormEvolution(currentForm, pet.exp);
    return newForm != currentForm;
  }

  // 检查形态进化
  PetForm _checkFormEvolution(PetForm currentForm, int exp) {
    PetForm newForm = currentForm;

    if (exp >= 1000) {
      newForm = PetForm.advanced;
    } else if (exp >= 500) {
      newForm = PetForm.adult;
    } else if (exp >= 250) {
      newForm = PetForm.adolescent;
    }

    return newForm;
  }

  // 获取宠物成长进度
  Future<double> getGrowthProgress() async {
    final pet = await getPet();
    final requiredExperience = getRequiredExperience(pet.level + 1);
    return pet.exp / (requiredExperience + pet.exp);
  }
}
