import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSessionNotifier extends ChangeNotifier {
  final SupabaseClient supabaseClient = Supabase.instance.client;
  StreamSubscription<AuthState>? _authStateSubscription;

  User? _currentUser;
  User? get currentUser => _currentUser;
  User? get user => _currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AuthSessionNotifier() {
    _init();
  }

  void _init() {
    _currentUser = supabaseClient.auth.currentUser;
    _isLoading = false;
    notifyListeners();

    _authStateSubscription = supabaseClient.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
