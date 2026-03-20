import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/main_navigation_page.dart';
import '../utils/token_util.dart';
import '../managers/auth_manager.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  // 检查登录状态并跳转
  Future<void> _checkLoginAndNavigate() async {
    // 等待1秒展示启动页
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;

    try {
      // 检查是否已登录
      final isLogin = await TokenUtil.instance.isLogin();
      
      if (isLogin) {
        // 如果已登录，尝试恢复用户信息
        final userInfo = await TokenUtil.instance.getUserInfo();
        if (userInfo != null) {
          await AuthManager.instance.saveUserInfo(userInfo);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          // 如果有token但没用户信息，尝试重新登录
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      } else {
        // 未登录，跳转到登录页
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print('SplashPage error: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 应用图标
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.pets,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            // 应用名称
            const Text(
              '宠物养成任务管理',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            // 加载动画
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
