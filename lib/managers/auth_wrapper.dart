import 'package:flutter/material.dart';
import '../managers/auth_manager.dart';
import '../screens/login_page.dart';
import '../screens/pet_selection_page.dart';
import '../managers/pet_state_manager.dart';

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
    setState(() {
      _isChecking = true;
    });

    // 检查认证状态
    if (!_authManager.isLoggedIn) {
      // 如果未登录，导航到登录页面
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // 如果要求必须有宠物，检查是否有宠物
    if (widget.requirePet) {
      final pets = await _petManager.getAllPets();
      _hasPet = pets.isNotEmpty;

      if (!_hasPet) {
        // 如果没有宠物，导航到宠物选择页面
        Navigator.pushReplacementNamed(context, '/pet_selection');
        return;
      }
    }

    setState(() {
      _isChecking = false;
    });
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
