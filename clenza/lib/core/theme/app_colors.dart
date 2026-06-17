import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1565C0); // deep royal blue
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color accent = Color(0xFFFF6F00); // amber
  static const Color accent2 = Color(0xFF00C853); // green
  static const Color background = Color(0xFFF0F4FF); // soft blue-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  static const LinearGradient gradient1 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
  );

  static const LinearGradient gradient2 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6F00), Color(0xFFFFD54F)],
  );

  // Role chip colors
  static const Color roleFoundingAdmin = Colors.deepPurple;
  static const Color rolePresident = Color(0xFF1565C0); 
  static const Color roleVicePresident = Colors.teal;
  static const Color roleSecretary = Colors.blue;
  static const Color roleTreasurer = Colors.orange;
  static const Color roleMember = Colors.grey;

  static Color getRoleColor(String role) {
    switch (role) {
      case 'founding_admin':
        return roleFoundingAdmin;
      case 'president':
        return rolePresident;
      case 'vice_president':
        return roleVicePresident;
      case 'secretary':
        return roleSecretary;
      case 'treasurer':
        return roleTreasurer;
      default:
        return roleMember;
    }
  }
}
