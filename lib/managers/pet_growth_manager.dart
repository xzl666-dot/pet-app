import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/pet_model.dart';
import '../managers/auth_manager.dart';
import '../utils/token_util.dart';

class PetGrowthManager {
  static final PetGrowthManager _instance = PetGrowthManager._internal();
  factory PetGrowthManager() => _instance;
  PetGrowthManager._internal();

  final _authManager = AuthManager.instance;
  final _upgradeController = StreamController<PetUpgradeEvent>.broadcast();
  
  Stream<PetUpgradeEvent> get upgradeStream => _upgradeController.stream;

  void dispose() {
    _upgradeController.close();
  }

  Future<PetModel?> updatePetExp(int expGain) async {
    try {
      final user = _authManager.currentUser;
      if (user == null) return null;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return null;

      final pet = await getCurrentPet();
      if (pet == null) return null;

      final newExp = pet.exp + expGain;
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/pet/updateStatus'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'userId': userId,
          'petId': 1,
          'exp': newExp,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final petData = data['data'];
          final isUpgrade = petData['isUpgrade'] ?? false;
          
          final updatedPet = PetModel(
            id: pet.id,
            name: pet.name,
            type: pet.type,
            form: pet.form,
            nutrition: petData['status']['nutrition'] ?? pet.nutrition,
            happiness: petData['status']['happiness'] ?? pet.happiness,
            intimacy: petData['status']['intimacy'] ?? pet.intimacy,
            level: petData['level'] ?? pet.level,
            exp: petData['exp'] ?? pet.exp,
            expThreshold: petData['expThreshold'] ?? pet.expThreshold,
            createdAt: pet.createdAt,
            lastUpdated: DateTime.now(),
          );

          if (isUpgrade) {
            _upgradeController.add(PetUpgradeEvent(
              pet: updatedPet,
              oldLevel: pet.level,
              newLevel: updatedPet.level,
            ));
          }

          return updatedPet;
        }
      }
    } catch (e) {
      print('更新宠物经验失败: $e');
    }
    return null;
  }

  Future<PetModel?> getCurrentPet() async {
    try {
      final user = _authManager.currentUser;
      if (user == null) return null;

      final token = await TokenUtil.instance.getAccessToken();
      final userId = user.userId ?? user.id;

      if (token == null || userId == null) return null;

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/pet/status?userId=$userId&petId=1'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final petData = data['data'];
          return PetModel(
            id: petData['petId'],
            name: petData['petName'],
            type: _parsePetType(petData['petType'] ?? 'common'),
            form: _getFormByLevel(petData['level']),
            nutrition: petData['nutrition'],
            happiness: petData['happiness'],
            intimacy: petData['intimacy'],
            level: petData['level'],
            exp: petData['exp'],
            expThreshold: petData['expThreshold'],
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          );
        }
      }
    } catch (e) {
      print('获取当前宠物失败: $e');
    }
    return null;
  }

  PetType _parsePetType(String typeStr) {
    switch (typeStr) {
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

  PetForm _getFormByLevel(int level) {
    if (level >= 91) return PetForm.advanced;
    if (level >= 61) return PetForm.adult;
    if (level >= 31) return PetForm.adolescent;
    return PetForm.baby;
  }

  int getExpReward(int level) {
    return 15;
  }

  int getExpThreshold(int level) {
    if (level >= 100) return 0;
    
    final baseExp = 100;
    final levelMultiplier = level;
    final difficultyMultiplier = 1.0 + (level - 1) * 0.1;
    
    return ((baseExp + levelMultiplier * 50) * difficultyMultiplier).round();
  }
}

class PetUpgradeEvent {
  final PetModel pet;
  final int oldLevel;
  final int newLevel;

  PetUpgradeEvent({
    required this.pet,
    required this.oldLevel,
    required this.newLevel,
  });
}