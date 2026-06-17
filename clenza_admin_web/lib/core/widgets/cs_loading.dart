import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CsLoading extends StatelessWidget {
  const CsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 100,
        height: 100,
        child: Lottie.asset('assets/animations/Sandy Loading Animation.json'),
      ),
    );
  }
}
