import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/clay_card.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../dashboard/presentation/screens/admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepository = context.read<AuthRepository>();
      final success = await authRepository.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('Exception:') 
            ? e.toString().split('Exception: ').last
            : e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.darkBg, AppColors.navy],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final floatValue = _floatController.value;
            return Stack(
              children: [
                // Background Animations
                Positioned(
                  top: 40,
                  left: 40,
                  child: Transform.translate(
                    offset: Offset(5 * floatValue, 10 * floatValue),
                    child: Opacity(
                      opacity: 0.8,
                      child: Lottie.asset('assets/animations/sport and arts/Olympics Animation.json', width: 200),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 40,
                  child: Transform.translate(
                    offset: Offset(-10 * floatValue, 15 * (1 - floatValue)),
                    child: Opacity(
                      opacity: 0.8,
                      child: Lottie.asset('assets/animations/sport and arts/criket.json', width: 200),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 40,
                  child: Transform.translate(
                    offset: Offset(8 * floatValue, -12 * floatValue),
                    child: Opacity(
                      opacity: 0.8,
                      child: Lottie.asset('assets/animations/sport and arts/Archery Man Animation.json', width: 200),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  right: 40,
                  child: Transform.translate(
                    offset: Offset(-15 * floatValue, 8 * floatValue),
                    child: Opacity(
                      opacity: 0.8,
                      child: Lottie.asset('assets/animations/sport and arts/kick on the ball Animation.json', width: 200),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height / 2 - 100,
                  left: 10,
                  child: Transform.translate(
                    offset: Offset(10 * floatValue, 10 * (1 - floatValue)),
                    child: Opacity(
                      opacity: 0.6,
                      child: Lottie.asset('assets/animations/sport and arts/boxer lottie Animation.json', width: 150),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height / 2 - 100,
                  right: 10,
                  child: Transform.translate(
                    offset: Offset(-10 * floatValue, -15 * floatValue),
                    child: Opacity(
                      opacity: 0.6,
                      child: Lottie.asset('assets/animations/sport and arts/arts.json', width: 150),
                    ),
                  ),
                ),

                // Main Login Card
                child!,
              ],
            );
          },
          child: Center(
            child: ClayCard(
                width: 400,
                color: AppColors.surface,
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/logo/app_icon_backgroundremoved.png',
                      height: 80,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Clenza',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Super Admin Portal',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: AppColors.darkBg.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: AppColors.darkBg.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _floatController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
