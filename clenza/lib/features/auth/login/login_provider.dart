import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginNotifier extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;
  bool get hasError => _error != null;

  Future<void> login(String clubCode, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Fetch the club by club_code or register_number
      final clubData = await supabase
          .from('clubs')
          .select('id, verification_status')
          .or('club_code.eq.$clubCode,register_number.eq.$clubCode')
          .maybeSingle();

      if (clubData == null) {
        throw const AuthException('Invalid Club Code. Please check and try again.');
      }

      if (clubData['verification_status'] != 'verified') {
        throw const AuthException('Your club is pending verification. Please wait for approval.');
      }

      // 2. Sign in using the provided email and password
      final authResponse = await supabase.auth.signInWithPassword(email: email, password: password);
      final userId = authResponse.user?.id;
      
      if (userId == null) {
        throw const AuthException('Invalid email or password.');
      }

      // 3. Verify that the authenticated user belongs to this club
      final memberData = await supabase
          .from('club_members')
          .select('id, is_active')
          .eq('club_id', clubData['id'])
          .eq('user_id', userId)
          .maybeSingle();

      if (memberData == null) {
        await supabase.auth.signOut();
        throw const AuthException('You are not a member of this club.');
      }
      
      if (memberData['is_active'] != true) {
        await supabase.auth.signOut();
        throw const AuthException('Your account is inactive in this club.');
      }

    } catch (e) {
      if (e is AuthException) {
        _error = e.message;
      } else {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
