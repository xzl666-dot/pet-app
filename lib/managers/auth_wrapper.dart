import 'package:flutter/material.dart';
import '../screens/login_page.dart';
import '../screens/pet_selection_page.dart';
import '../managers/pet_state_manager.dart';
import '../managers/auth_manager.dart';
import '../utils/token_util.dart';

/// 认证包装器组件，用于管理认证状态和导航
class AuthWrapper extends StatefulWidget {
  final Widget child;
  final bool requirePet; // 是否要求必须有宠物

  const AuthWrapper({
    Key? key,
    required this.child,
    this.requirePet = false,
  }) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authManager = AuthManager.instance;
  final _petManager = PetStateManager.instance;
  bool _isChecking = true;
  bool _hasPet = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndPet();
  }

  Future<void> _checkAuthAndPet() async {
    if (!mounted) return;
    
    setState(() {
      _isChecking = true;
    });

    try {
      // 检查认证状态（使用TokenUtil检查是否有有效的token）
      final isLogin = await TokenUtil.instance.isLogin();
      if (!isLogin) {
        // 如果未登录，导航到登录页面
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
        return;
      }

      // 如果已登录但内存中没有用户信息，尝试从本地存储恢复
      if (!_authManager.isLoggedIn) {
        final userInfo = await TokenUtil.instance.getUserInfo();
        if (userInfo != null) {
          await _authManager.saveUserInfo(userInfo);
        } else {
          // 如果无法恢复用户信息，视为未登录
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    } catch (e) {
      print('AuthWrapper error: $e');
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.child;
  }
}
