import 'package:flutter/material.dart';
import '../managers/api_manager.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 1;
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
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('找回密码'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFF5F7FA),
        foregroundColor: const Color(0xFF333333),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
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
                      '🔒',
                      style: TextStyle(fontSize: 50),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 标题
                Text(
                  _currentStep == 1 ? '找回密码' : '设置新密码',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // 引导文字
                Text(
                  _currentStep == 1 ? '请输入注册时的用户名' : '请设置您的新密码',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF909399),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),

                if (_currentStep == 1) _buildStepOne(),
                if (_currentStep == 2) _buildStepTwo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepOne() {
    return Column(
      children: [
        // 用户名输入
        Container(
          margin: const EdgeInsets.only(bottom: 24),
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
        
        // 下一步按钮
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyUsername,
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
                    '下一步',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      children: [
        // 新密码输入
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: _newPasswordController,
            decoration: InputDecoration(
              hintText: '请输入新密码',
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

        // 确认密码输入
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: TextField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              hintText: '请再次输入新密码',
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
                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: const Color(0xFF909399),
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
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
              errorText: _passwordsMatch() ? null : '两次密码不一致',
              errorStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFFF56C6C),
              ),
            ),
            obscureText: _obscureConfirmPassword,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF333333),
            ),
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
        
        // 成功信息
        if (_successMessage.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF67C23A),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF67C23A),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _successMessage,
                    style: const TextStyle(
                      color: Color(0xFF67C23A),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // 确认重置按钮
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPassword,
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
                    '确认重置',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  bool _passwordsMatch() {
    if (_confirmPasswordController.text.isEmpty) return true;
    return _newPasswordController.text == _confirmPasswordController.text;
  }

  void _verifyUsername() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '请输入用户名';
      });
      return;
    }

    try {
      final response = await ApiManager.instance.checkUsername(username);
      if (response['code'] == 200) {
        setState(() {
          _isLoading = false;
          _currentStep = 2;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '用户名不存在';
        });
      }
    } catch (e) {
      print('验证用户名失败: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '网络错误，请检查网络连接';
      });
    }
  }

  void _handleResetPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    final username = _usernameController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '请输入新密码';
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _isLoading = false;
        _errorMessage = '密码长度至少为6位';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _isLoading = false;
        _errorMessage = '两次密码不一致';
      });
      return;
    }

    try {
      final response = await ApiManager.instance.resetPassword(username, newPassword);
      if (response['code'] == 200) {
        setState(() {
          _isLoading = false;
          _successMessage = '密码重置成功，请使用新密码登录';
        });

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['msg'] ?? '密码重置失败';
        });
      }
    } catch (e) {
      print('重置密码失败: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '网络错误，请检查网络连接';
      });
    }
  }
}
