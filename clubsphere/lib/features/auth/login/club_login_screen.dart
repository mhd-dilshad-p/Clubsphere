import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/animated_states.dart';
import 'login_provider.dart';
import 'package:provider/provider.dart';

class ClubLoginScreen extends StatelessWidget {
  const ClubLoginScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginNotifier(),
      child: const _ClubLoginView(),
    );
  }
}

class _ClubLoginView extends StatefulWidget {
  const _ClubLoginView();

  @override
  State<_ClubLoginView> createState() => _ClubLoginViewState();
}

class _ClubLoginViewState extends State<_ClubLoginView> with SingleTickerProviderStateMixin {
  final _clubCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isPressed = false;
  
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _clubCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final clubCode = _clubCodeController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (clubCode.isEmpty || email.isEmpty || password.isEmpty) return;

    final notifier = context.read<LoginNotifier>();
    await notifier.login(clubCode, email, password);
    if (notifier.hasError && mounted) {
      CustomToast.showError(context, notifier.error ?? 'Invalid credentials. Please try again.');
    } else if (!notifier.hasError && mounted) {
      CustomToast.showSuccess(context, 'Login Successful!');
      context.go('/dashboard/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loginState = context.watch<LoginNotifier>();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Animated Background Gradient
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [Color(0xFFE3F2FD), Color(0xFFF0F4FF), Color(0xFFE1F5FE)],
                    stops: [
                      0.0,
                      0.5 + 0.5 * math.sin(_bgController.value * 2 * math.pi),
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Floating Blurred Circles
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -100 + 50 * math.sin(_bgController.value * 2 * math.pi),
                    left: -100 + 50 * math.cos(_bgController.value * 2 * math.pi),
                    child: _buildBlurredCircle(AppColors.primary, 300),
                  ),
                  Positioned(
                    bottom: -150 + 80 * math.cos(_bgController.value * 2 * math.pi),
                    right: -50 + 60 * math.sin(_bgController.value * 2 * math.pi),
                    child: _buildBlurredCircle(AppColors.accent, 400),
                  ),
                  Positioned(
                    top: 200 + 30 * math.sin(_bgController.value * 2 * math.pi),
                    right: -150,
                    child: _buildBlurredCircle(AppColors.accent2, 250),
                  ),
                ],
              );
            },
          ),
          
          // Subtle Grid Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(painter: GridPainter()),
            ),
          ),
          
          // Main Login Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: math.min(400, screenWidth - 32),
                decoration: AppDecorations.glossy3D.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Welcome Illustration
                          SvgPicture.asset(
                            'assets/illusrtations_image/welcome.svg',
                            height: 140,
                            fit: BoxFit.contain,
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 2.seconds),
                          
                          // Logo Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/logo/app_icon_backgroundremoved.png', height: 40),
                              const SizedBox(width: 12),
                              Text(
                                AppStrings.appName,
                                style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),
                          
                          const SizedBox(height: 24),
                          
                          // Title
                          const Text("Welcome Back 👋", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          const Text("Login to manage your club", style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                          
                          const SizedBox(height: 32),
                          
                          // Club Code Field
                          TextField(
                            controller: _clubCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Club Code / Register No.',
                              prefixIcon: Icon(Icons.badge, color: AppColors.primaryLight),
                            ),
                            keyboardType: TextInputType.text,
                          ).animate().fadeIn(delay: 200.ms),
                          
                          const SizedBox(height: 16),
                          
                          // Email Field
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email, color: AppColors.primaryLight),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ).animate().fadeIn(delay: 250.ms),
                          
                          const SizedBox(height: 16),
                          
                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock, color: AppColors.primaryLight),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                          
                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                              child: const Text('Forgot Password?', style: TextStyle(fontSize: 13)),
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                          
                          const SizedBox(height: 16),
                          
                          // Login Button
                          GestureDetector(
                            onTapDown: (_) => setState(() => _isPressed = true),
                            onTapUp: (_) {
                              setState(() => _isPressed = false);
                              if (!loginState.isLoading) _login();
                            },
                            onTapCancel: () => setState(() => _isPressed = false),
                            child: AnimatedScale(
                              scale: _isPressed ? 0.97 : 1.0,
                              duration: const Duration(milliseconds: 100),
                              child: Container(
                                width: double.infinity,
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: AppColors.gradient1,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))
                                  ],
                                ),
                                child: Center(
                                  child: loginState.isLoading
                                      ? Lottie.asset('assets/animations/Sandy Loading Animation.json', height: 40)
                                      : const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                          
                          const SizedBox(height: 24),
                          
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Colors.black12)),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("or", style: TextStyle(color: Colors.grey, fontSize: 12))),
                              Expanded(child: Divider(color: Colors.black12)),
                            ],
                          ).animate().fadeIn(delay: 500.ms),
                          
                          const SizedBox(height: 24),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("New club? ", style: TextStyle(color: AppColors.textSecondary)),
                              TextButton(
                                onPressed: () => context.push('/register'),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                child: const Text("Register Here →", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ).animate().fadeIn(delay: 600.ms),
                          
                          const SizedBox(height: 32),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMiniFeature("🔒 Secure"),
                              _buildMiniFeature("✓ Verified"),
                              _buildMiniFeature("🇮🇳 Made in India"),
                            ],
                          ).animate().fadeIn(delay: 700.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 800.ms).fadeIn(duration: 800.ms).slideY(begin: 0.3, curve: Curves.easeOutBack),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildMiniFeature(String text) {
    return Text(text, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500));
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;
    
    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
