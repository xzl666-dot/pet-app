import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../managers/auth_manager.dart';
import '../managers/pet_state_manager.dart';
import '../managers/api_manager.dart';
import '../utils/token_util.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _authManager = AuthManager.instance;
  final _petManager = PetStateManager.instance;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('登录'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFF5F7FA),
        foregroundColor: const Color(0xFF333333),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                
                // 应用图标
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🐶',
                      style: TextStyle(fontSize: 50),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 标题
                const Text(
                  '欢迎回来',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // 引导文字
                const Text(
                  '登录您的账号以继续',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF909399),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),

                // 用户名输入
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: '请输入用户名',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFC0C4CC),
                      ),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF909399),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),

                // 密码输入
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: '请输入密码',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFC0C4CC),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF909399),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: const Color(0xFF909399),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                
                // 七天免登录
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF1677FF),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '七天免登录',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF606266),
                        ),
                      ),
                    ],
                  ),
                ),
              
                // 错误信息
                if (_errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF56C6C),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFF56C6C),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Color(0xFFF56C6C),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              
                // 登录按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1677FF),
                      disabledBackgroundColor: const Color(0xFFC0C4CC),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '登录',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),

              // 辅助操作区
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 注册引导
                  Row(
                    children: [
                      const Text(
                        '还没有账号？',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF909399),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '去注册',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1677FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // 密码找回
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '忘记密码？',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1677FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '请输入用户名和密码';
      });
      return;
    }

    try {
      // 调用后端API登录（优化版）
      final response = await ApiManager.instance.login(username, password, '1', 'Web Browser');
      if (response['code'] == 200) {
        // 登录成功，保存用户信息
        final data = response['data'];
        await _authManager.saveUserInfo(data);

        // 保存token到TokenUtil
        await TokenUtil.instance.saveTokens(
          data['accessToken'].toString(),
          data['accessExpire'].toString(),
          data['refreshToken'].toString(),
          data['refreshExpire'].toString(),
          data,
        );

        // 调试：打印后端返回的数据
        print('后端返回的数据: $data');
        print('userId: ${data['userId']}');

        // 调用后端接口检查用户是否有宠物
        final token = await TokenUtil.instance.getAccessToken();
        final userId = data['userId'];
        
        if (token != null && userId != null) {
          print('准备查询宠物列表，userId: $userId');
          final petListResponse = await http.get(
            Uri.parse('http://localhost:3000/api/pet/list?userId=$userId'),
            headers: {
              'Content-Type': 'application/json',
              'token': token,
            },
          );

          print('宠物列表响应状态码: ${petListResponse.statusCode}');
          print('宠物列表响应内容: ${petListResponse.body}');

          if (petListResponse.statusCode == 200) {
            final petListData = jsonDecode(petListResponse.body);
            if (petListData['code'] == 200) {
              final total = petListData['data']['total'] ?? 0;
              print('宠物数量: $total');
              if (total > 0) {
                // 如果有宠物，跳转到主页
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
                return;
              }
            }
          }
        } else {
          print('token或userId为空，token: $token, userId: $userId');
        }

        // 如果没有宠物，跳转到宠物选择页面
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/pet_selection');
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['msg'] ?? '登录失败，请重试';
        });
      }
    } catch (e) {
      print('登录失败: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '网络错误，请检查网络连接';
      });
    }
  }
}
