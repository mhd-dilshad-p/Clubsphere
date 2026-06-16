import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
// Provider import removed

class RegistrationSuccessScreen extends StatelessWidget {
  const RegistrationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFF0F4FF)],
          ),
        ),
        child: Stack(
          children: [
            // Floating Confetti / Background Elements could go here
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: AppDecorations.glossy3D.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            (Lottie.asset(
                              'assets/animations/user restration Done.json',
                              height: 180,
                              repeat: false,
                            ) as Widget).animate().scale(curve: Curves.easeOutBack, duration: 800.ms),
                            
                            const SizedBox(height: 24),
                            
                            Text(
                              'Registration Submitted!',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                            
                            const SizedBox(height: 16),
                            
                            const Text(
                              'Your Club Register Number is:',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                            ).animate().fadeIn(delay: 500.ms),
                            
                            const SizedBox(height: 12),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: AppColors.gradient1,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'PENDING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ).animate().fadeIn(delay: 600.ms).scale(curve: Curves.easeOutBack),
                            
                            const SizedBox(height: 32),
                            
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: AppColors.accent),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Super admin will verify within 24-48 hours.\nYou will receive an email once approved.',
                                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
                            
                            const SizedBox(height: 32),
                            
                            ElevatedButton(
                              onPressed: () => context.go('/login'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 54),
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                                elevation: 0,
                              ),
                              child: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ).animate().fadeIn(delay: 800.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
