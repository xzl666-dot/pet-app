import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../database/database_helper.dart';

class AuthManager {
  static final AuthManager instance = AuthManager._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static User? _currentUser;

  AuthManager._init();

  // 获取当前登录用户
  User? get currentUser => _currentUser;

  // 检查是否已登录
  bool get isLoggedIn => _currentUser != null;

  // 检查当前用户是否为管理员
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // 生成密码哈希
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 检查是否存在管理员账号
  Future<bool> _hasAdminUser() async {
    try {
      // 对于Web平台，直接检查内存中的用户列表
      if (kIsWeb) {
        final allUsers = await _dbHelper.getAllUsers();
        return allUsers.any((user) => user.isAdmin);
      }
      
      // 对于原生平台，查询数据库
      final db = await _dbHelper.database;
      final result = await db.query(
        'users',
        where: 'is_admin = ?',
        whereArgs: [1],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking admin user: $e');
      return false;
    }
  }

  // 注册新用户
  Future<bool> register(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      return false;
    }

    // 检查用户名是否已存在
    final existingUser = await _getUserByUsername(username);
    if (existingUser != null) {
      return false;
    }

    // 检查是否要创建管理员账号
    bool isAdmin = false;
    if (username == 'admin') {
      // 检查是否已经存在管理员账号
      final hasAdmin = await _hasAdminUser();
      if (!hasAdmin) {
        isAdmin = true;
      } else {
        // 已经存在管理员账号，不允许再次创建
        return false;
      }
    }

    // 创建新用户
    final passwordHash = _hashPassword(password);
    final newUser = User(
      username: username,
      passwordHash: passwordHash,
      isAdmin: isAdmin,
    );

    // 保存到数据库
    await _dbHelper.createUser(newUser);
    return true;
  }

  // 用户登录
  Future<bool> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      return false;
    }

    // 获取用户
    final user = await _getUserByUsername(username);
    if (user == null) {
      return false;
    }

    // 验证密码
    final passwordHash = _hashPassword(password);
    if (user.passwordHash != passwordHash) {
      return false;
    }

    // 更新用户在线状态为true
    final updatedUser = user.copyWith(isOnline: true);
    await _dbHelper.updateUser(updatedUser);

    // 登录成功，保存当前用户
    _currentUser = updatedUser;
    return true;
  }

  // 用户登出
  Future<void> logout() async {
    if (_currentUser != null) {
      // 更新用户在线状态为false
      final updatedUser = _currentUser!.copyWith(isOnline: false);
      await _dbHelper.updateUser(updatedUser);
    }
    _currentUser = null;
  }

  // 根据用户名获取用户
  Future<User?> _getUserByUsername(String username) async {
    return await _dbHelper.getUserByUsername(username);
  }

  // 根据ID获取用户
  Future<User?> getUserById(int id) async {
    return await _dbHelper.getUserById(id);
  }
}
