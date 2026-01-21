import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/task_model.dart';

class NotificationManager {
  static final NotificationManager instance = NotificationManager._init();
  
  // 提醒设置
  Map<String, dynamic> _notificationSettings = {
    'enabled': true,
    'platform_preferences': {
      'android': 'notification',
      'ios': 'notification',
      'web': 'alert',
      'default': 'alert',
    },
    'reminder_times': {
      'morning': '09:00',
      'afternoon': '14:00',
      'evening': '19:00',
    },
    'task_reminder_enabled': true,
    'task_reminder_before_minutes': 30,
  };

  NotificationManager._init();

  // 初始化通知系统
  Future<void> initialize() async {
    // 这里可以添加平台特定的初始化代码
    // 例如，在Android上请求通知权限
    print('通知系统初始化完成');
  }

  // 获取当前平台
  String getCurrentPlatform() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isLinux) {
      return 'linux';
    } else {
      return 'unknown';
    }
  }

  // 获取平台推荐的提醒方式
  String getRecommendedNotificationMethod() {
    final platform = getCurrentPlatform();
    return _notificationSettings['platform_preferences'][platform] ??
        _notificationSettings['platform_preferences']['default'];
  }

  // 发送任务提醒
  Future<void> sendTaskReminder(TaskModel task) async {
    if (!_notificationSettings['enabled'] || !_notificationSettings['task_reminder_enabled']) {
      return;
    }

    final method = getRecommendedNotificationMethod();
    
    switch (method) {
      case 'notification':
        await _sendSystemNotification(task);
        break;
      case 'alert':
        await _sendAlertNotification(task);
        break;
      case 'email':
        await _sendEmailNotification(task);
        break;
      default:
        await _sendAlertNotification(task);
        break;
    }
  }

  // 发送系统通知（适用于移动平台）
  Future<void> _sendSystemNotification(TaskModel task) async {
    // 这里应该集成实际的通知插件
    // 例如 flutter_local_notifications
    print('发送系统通知: ${task.name}');
    
    // 模拟通知发送
    print('【任务提醒】${task.name}');
    print('截止时间: ${task.deadline.toString()}');
    print('奖励: ${_getBenefitTypeName(task.benefitType)} +${task.benefitValue}');
  }

  // 发送弹窗提醒（适用于Web和桌面平台）
  Future<void> _sendAlertNotification(TaskModel task) async {
    // 在实际应用中，这里应该使用全局导航键显示弹窗
    print('发送弹窗提醒: ${task.name}');
    
    // 模拟弹窗内容
    print('📌 任务提醒');
    print('任务: ${task.name}');
    print('难度: ${_getTaskDifficultyName(task.difficulty)}');
    print('截止时间: ${task.deadline.toString().substring(0, 16)}');
    print('奖励: ${_getBenefitTypeName(task.benefitType)} +${task.benefitValue}');
  }

  // 发送邮件通知（可选功能）
  Future<void> _sendEmailNotification(TaskModel task) async {
    print('发送邮件通知: ${task.name}');
    // 实际应用中，这里应该集成邮件发送服务
  }

  // 发送每日提醒
  Future<void> sendDailyReminder() async {
    if (!_notificationSettings['enabled']) {
      return;
    }

    final method = getRecommendedNotificationMethod();
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    // 检查是否在提醒时间
    if (_notificationSettings['reminder_times'].containsValue(currentTime)) {
      switch (method) {
        case 'notification':
          print('发送每日系统提醒');
          break;
        case 'alert':
          print('发送每日弹窗提醒');
          break;
        default:
          print('发送每日提醒');
          break;
      }
    }
  }

  // 智能调整提醒方式
  Future<void> adjustNotificationMethod() async {
    final platform = getCurrentPlatform();
    
    // 这里可以根据用户行为数据智能调整提醒方式
    // 例如，如果用户经常忽略弹窗提醒，可以切换到其他方式
    print('智能调整提醒方式为: ${getRecommendedNotificationMethod()}');
  }

  // 设置提醒偏好
  void setNotificationPreference(String platform, String method) {
    _notificationSettings['platform_preferences'][platform] = method;
    print('已设置$platform平台的提醒方式为: $method');
  }

  // 启用/禁用提醒
  void setNotificationsEnabled(bool enabled) {
    _notificationSettings['enabled'] = enabled;
    print('提醒已${enabled ? '启用' : '禁用'}');
  }

  // 设置任务提醒时间
  void setTaskReminderTime(int minutesBefore) {
    _notificationSettings['task_reminder_before_minutes'] = minutesBefore;
    print('任务提醒时间已设置为: 任务截止前$minutesBefore分钟');
  }

  // 获取提醒设置
  Map<String, dynamic> getNotificationSettings() {
    return _notificationSettings;
  }

  // 辅助方法：获取任务难度名称
  String _getTaskDifficultyName(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return '简单';
      case TaskDifficulty.medium:
        return '中等';
      case TaskDifficulty.hard:
        return '困难';
    }
  }

  // 辅助方法：获取收益类型名称
  String _getBenefitTypeName(PetBenefitType benefitType) {
    switch (benefitType) {
      case PetBenefitType.nutrition:
        return '营养值';
      case PetBenefitType.happiness:
        return '快乐度';
      case PetBenefitType.skillPoint:
        return '技能点';
    }
  }
}
