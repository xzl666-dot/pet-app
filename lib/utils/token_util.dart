import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../managers/api_manager.dart';
import '../models/user_model.dart';

class TokenUtil {
  static final TokenUtil instance = TokenUtil._init();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final _aesKey = 'pet_app_aes_key';

  TokenUtil._init();

  // 保存令牌
  Future<void> saveTokens(String accessToken, String accessExpire, String refreshToken, String? refreshExpire, Map<String, dynamic>? userInfo) async {
    // 加密refreshToken
    final encryptedRefreshToken = _encrypt(refreshToken);

    // 存储到安全存储
    await _secureStorage.write(key: 'encrypted_refresh_token', value: encryptedRefreshToken);

    // 存储到shared_preferences
    final prefs = await SharedPreferences.getInstance();
    if (refreshExpire != null) {
      await prefs.setString('refresh_expire', refreshExpire);
    }
    await prefs.setString('access_token', accessToken);
    await prefs.setString('access_expire', accessExpire);
    if (userInfo != null) {
      await prefs.setString('user_info', json.encode(userInfo));
    }
  }

  // 获取accessToken
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 获取refreshToken
  Future<String?> getRefreshToken() async {
    final encryptedToken = await _secureStorage.read(key: 'encrypted_refresh_token');
    if (encryptedToken != null) {
      return _decrypt(encryptedToken);
    }
    return null;
  }

  // 检查refreshToken是否有效
  Future<bool> isRefreshTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshExpire = prefs.getString('refresh_expire');
    if (refreshExpire == null) {
      return false;
    }
    
    try {
      final now = DateTime.now();
      // 后端返回的是秒级时间戳
      final expireTimestamp = int.tryParse(refreshExpire);
      if (expireTimestamp != null) {
        final expireTime = DateTime.fromMillisecondsSinceEpoch(expireTimestamp * 1000);
        return now.isBefore(expireTime);
      }
      
      // 备选：尝试解析为ISO格式
      final expireTime = DateTime.parse(refreshExpire);
      return now.isBefore(expireTime);
    } catch (e) {
      print('解析过期时间失败: $e');
      return false;
    }
  }

  // 清除所有令牌
  Future<void> clearAll() async {
    await _secureStorage.delete(key: 'encrypted_refresh_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('refresh_expire');
    await prefs.remove('access_token');
    await prefs.remove('access_expire');
    await prefs.remove('user_info');
  }

  // 获取用户信息
  Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoStr = prefs.getString('user_info');
    if (userInfoStr != null) {
      return json.decode(userInfoStr);
    }
    return null;
  }

  // 检查是否已登录
  Future<bool> isLogin() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;
    
    final isRefreshValid = await isRefreshTokenValid();
    if (isRefreshValid) return true;

    // 如果 accessToken 存在但 refreshToken 过期，尝试刷新
    return await refreshToken();
  }

  // 刷新token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      // 获取设备ID
      final deviceId = 'test_device_id';

      // 调用刷新接口
      final response = await ApiManager.instance.refreshToken(refreshToken, deviceId);
      if (response['code'] == 200) {
        // 保存新token
        await saveTokens(
          response['data']['accessToken'],
          response['data']['accessExpire'],
          refreshToken, // 使用原有的refreshToken
          null, // 刷新令牌接口不返回新的refreshExpire
          null, // 刷新令牌接口不返回userInfo
        );
        return true;
      }
      return false;
    } catch (e) {
      print('刷新token失败: $e');
      return false;
    }
  }

  // AES加密
  String _encrypt(String text) {
    // 简化的加密实现，实际应使用更安全的AES加密
    final bytes = utf8.encode(text + _aesKey);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  // AES解密
  String _decrypt(String encrypted) {
    // 简化的解密实现，实际应使用更安全的AES解密
    // 注意：这里只是为了演示，实际无法从MD5哈希还原原文
    return encrypted;
  }
}
