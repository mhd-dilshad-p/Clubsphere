import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/permission_guard.dart';

class CsBadge extends StatelessWidget {
  final String text;
  final ClubRole? role;
  final Color? color;

  const CsBadge({
    super.key,
    required this.text,
    this.role,
    this.color,
  });

  Color _getRoleColor() {
    if (color != null) return color!;
    switch (role) {
      case ClubRole.president:
        return AppColors.president;
      case ClubRole.secretary:
        return AppColors.secretary;
      case ClubRole.treasurer:
        return AppColors.treasurer;
      case ClubRole.foundingAdmin:
        return AppColors.navy;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getRoleColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: bgColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
