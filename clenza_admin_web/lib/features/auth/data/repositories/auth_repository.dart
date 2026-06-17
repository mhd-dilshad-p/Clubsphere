import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // Get current user stream
  Stream<User?> get authStateChanges => _supabase.auth.onAuthStateChange.map((event) => event.session?.user);

  // Check if current user is a super admin
  Future<bool> isSuperAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('super_admins')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Sign in
  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Verify super admin role immediately
        final isAdmin = await isSuperAdmin();
        if (!isAdmin) {
          await signOut(); // Sign them back out if not authorized
          throw Exception('Unauthorized access. Super Admin only.');
        }
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
