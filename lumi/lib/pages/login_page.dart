import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入邮箱/用户名和密码')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      context.go('/');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录失败，请检查用户名和密码')),
      );
    }
  }

  Future<void> _handleAppleLogin() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.loginWithApple(
        authorizationCode: credential.authorizationCode,
        userID: credential.userIdentifier ?? '',
        email: credential.email,
        fullName: credential.givenName != null && credential.familyName != null
            ? '${credential.givenName} ${credential.familyName}'
            : null,
        idToken: credential.identityToken ?? '',
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        context.go('/');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('苹果登录失败')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(AppConfig.backgroundDark),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 背景渐变圆圈
              Positioned(
                top: -100,
                left: MediaQuery.of(context).size.width / 2 - 250,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(AppConfig.primaryColor).withOpacity(0.2),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(AppConfig.primaryColor).withOpacity(0.1),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              // 内容
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      // Logo 和标题
                      Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(AppConfig.primaryColor),
                                  Color(0xFFD946EF),
                                  Color(0xFFA21CAF),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(AppConfig.primaryColor)
                                      .withOpacity(0.6),
                                  blurRadius: 40,
                                  spreadRadius: -10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Symbols.smart_toy,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Welcome to Lumi',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connect with your favorite AI characters and step into the future.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      // 输入框
                      Column(
                        children: [
                          // 邮箱/用户名输入框
                          _buildTextField(
                            controller: _emailController,
                            hintText: 'Email or Username',
                            icon: Symbols.mail,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          // 密码输入框
                          _buildPasswordField(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 忘记密码
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: 实现忘记密码功能
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(AppConfig.primaryColor),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 登录按钮
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(AppConfig.primaryColor),
                            foregroundColor: const Color(0xFF221022),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            elevation: 0,
                            shadowColor: const Color(AppConfig.primaryColor)
                                .withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF221022),
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.015,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 分隔线
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0xFF4A2B4A),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0xFF4A2B4A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // 苹果登录按钮
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _handleAppleLogin,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF221022),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Apple Logo SVG
                              CustomPaint(
                                size: const Size(20, 20),
                                painter: AppleLogoPainter(),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Sign in with Apple',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.015,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // 注册链接
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // TODO: 实现注册功能
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(AppConfig.primaryColor),
                                decoration: TextDecoration.underline,
                                decorationThickness: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(AppConfig.surfaceDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(AppConfig.surfaceDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Symbols.lock,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Symbols.visibility : Symbols.visibility_off,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// Apple Logo 绘制器
class AppleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF221022)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1)
      ..cubicTo(
        size.width * 0.4, size.height * 0.05,
        size.width * 0.25, size.height * 0.1,
        size.width * 0.2, size.height * 0.25,
      )
      ..cubicTo(
        size.width * 0.15, size.height * 0.4,
        size.width * 0.2, size.height * 0.55,
        size.width * 0.3, size.height * 0.6,
      )
      ..cubicTo(
        size.width * 0.35, size.height * 0.65,
        size.width * 0.4, size.height * 0.7,
        size.width * 0.5, size.height * 0.75,
      )
      ..cubicTo(
        size.width * 0.6, size.height * 0.7,
        size.width * 0.65, size.height * 0.65,
        size.width * 0.7, size.height * 0.6,
      )
      ..cubicTo(
        size.width * 0.8, size.height * 0.55,
        size.width * 0.85, size.height * 0.4,
        size.width * 0.8, size.height * 0.25,
      )
      ..cubicTo(
        size.width * 0.75, size.height * 0.1,
        size.width * 0.6, size.height * 0.05,
        size.width * 0.5, size.height * 0.1,
      )
      ..close();

    canvas.drawPath(path, paint);

    // 绘制叶子
    final leafPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1)
      ..cubicTo(
        size.width * 0.55, size.height * 0.05,
        size.width * 0.6, size.height * 0.08,
        size.width * 0.65, size.height * 0.15,
      )
      ..cubicTo(
        size.width * 0.6, size.height * 0.2,
        size.width * 0.55, size.height * 0.18,
        size.width * 0.5, size.height * 0.1,
      )
      ..close();

    canvas.drawPath(leafPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
