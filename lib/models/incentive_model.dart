import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/pet_model.dart';
import '../models/task_model.dart';
import '../utils/token_util.dart';

class IncentiveModel {
  final int userId;
  final int petId;
  final String abilityLevel;
  final int integral;
  final int integralGet;
  final int integralConsume;
  final int integralExpire;
  final int lotteryTickets;
  final List<String> chestUnlock;
  final int chestOpenNum;
  final List<String> achievementUnlock;
  final int signInDays;
  final List<Map<String, dynamic>> welfareGet;
  final Map<String, dynamic> incentivePrefer;
  final double baseRate;
  final bool canInteract;

  IncentiveModel({
    required this.userId,
    required this.petId,
    required this.abilityLevel,
    required this.integral,
    required this.integralGet,
    required this.integralConsume,
    required this.integralExpire,
    required this.lotteryTickets,
    required this.chestUnlock,
    required this.chestOpenNum,
    required this.achievementUnlock,
    required this.signInDays,
    required this.welfareGet,
    required this.incentivePrefer,
    required this.baseRate,
    required this.canInteract,
  });

  factory IncentiveModel.fromJson(Map<String, dynamic> json) {
    return IncentiveModel(
      userId: _parseInt(json['userId']) ?? 0,
      petId: _parseInt(json['petId']) ?? 0,
      abilityLevel: json['abilityLevel'] ?? 'D',
      integral: _parseInt(json['integral']) ?? 0,
      integralGet: _parseInt(json['integralGet']) ?? 0,
      integralConsume: _parseInt(json['integralConsume']) ?? 0,
      integralExpire: _parseInt(json['integralExpire']) ?? 0,
      lotteryTickets: _parseInt(json['lotteryTickets']) ?? 0,
      chestUnlock: List<String>.from(json['chestUnlock'] ?? []),
      chestOpenNum: _parseInt(json['chestOpenNum']) ?? 0,
      achievementUnlock: List<String>.from(json['achievementUnlock'] ?? []),
      signInDays: _parseInt(json['signInDays']) ?? 0,
      welfareGet: List<Map<String, dynamic>>.from(json['welfareGet'] ?? []),
      incentivePrefer: Map<String, dynamic>.from(json['incentivePrefer'] ?? {}),
      baseRate: (json['baseRate'] ?? 1.0).toDouble(),
      canInteract: json['canInteract'] ?? true,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
