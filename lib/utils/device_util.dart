import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

class DeviceUtil {
  static final DeviceUtil instance = DeviceUtil._init();
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  DeviceUtil._init();

  // 获取设备ID
  Future<String> getDeviceId() async {
    try {
      if (kIsWeb) {
        // Web平台使用UUID
        return Uuid().v4();
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return iosInfo.identifierForVendor ?? Uuid().v4();
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        return windowsInfo.deviceId;
      } else if (Platform.isMacOS) {
        final macosInfo = await _deviceInfoPlugin.macOsInfo;
        return macosInfo.systemGUID ?? Uuid().v4();
      } else if (Platform.isLinux) {
        // Linux平台使用UUID
        return Uuid().v4();
      } else {
        // 其他平台使用UUID
        return Uuid().v4();
      }
    } catch (e) {
      print('获取设备ID失败: $e');
      // 失败时返回UUID
      return Uuid().v4();
    }
  }

  // 获取设备名称
  Future<String> getDeviceName() async {
    try {
      if (kIsWeb) {
        return 'Web Browser';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return 'iPhone ${iosInfo.model}';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        return windowsInfo.computerName;
      } else if (Platform.isMacOS) {
        final macosInfo = await _deviceInfoPlugin.macOsInfo;
        return 'MacBook ${macosInfo.computerName}';
      } else if (Platform.isLinux) {
        return 'Linux Device';
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      print('获取设备名称失败: $e');
      return 'Unknown Device';
    }
  }
}
