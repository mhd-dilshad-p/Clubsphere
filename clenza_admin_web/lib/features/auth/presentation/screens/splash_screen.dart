import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveAnimation;
  late Animation<double> _fadeAnimation;
  
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _moveAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.6, curve: Curves.easeInOutCubic),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.forward().then((_) {
          _navigateNext();
        });
      }
    });
  }

  void _navigateNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), 
      body: AnimatedBuilder(
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
                    opacity: 0.2,
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
                    opacity: 0.2,
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
                    opacity: 0.2,
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
                    opacity: 0.2,
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
                    opacity: 0.15,
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
                    opacity: 0.15,
                    child: Lottie.asset('assets/animations/sport and arts/arts.json', width: 150),
                  ),
                ),
              ),

              // Main Logo Animation
              child!,
            ],
          );
        },
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(_moveAnimation.value * -15, 0),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Image.asset('assets/images/splashscreen/text_lubsph.png', height: 48), 
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(_moveAnimation.value * 125, 0),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Image.asset('assets/images/splashscreen/text_re.png', height: 48), 
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(_moveAnimation.value * -120, 0),
                    child: Image.asset('assets/images/splashscreen/logo_c.png', height: 64), 
                  ),
                  Transform.translate(
                    offset: Offset(_moveAnimation.value * 75, 0),
                    child: Image.asset('assets/images/splashscreen/logo_globe.png', height: 40), 
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
