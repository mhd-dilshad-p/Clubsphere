import 'package:supabase_flutter/supabase_flutter.dart';

class ClubRepository {
  final SupabaseClient _supabase;

  ClubRepository(this._supabase);

  // Fetch all pending clubs
  Future<List<Map<String, dynamic>>> getPendingClubs() async {
    try {
      final response = await _supabase
          .from('clubs')
          .select()
          .eq('verification_status', 'pending')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load pending clubs: $e');
    }
  }

  // Fetch all clubs (for master directory)
  Future<List<Map<String, dynamic>>> getAllClubs() async {
    try {
      final response = await _supabase
          .from('clubs')
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load clubs: $e');
    }
  }

  // Approve a club
  Future<void> approveClub(String clubId) async {
    try {
      final code = 'CLB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13)}';
      await _supabase
          .from('clubs')
          .update({
            'verification_status': 'verified',
            'is_active': true,
            'club_code': code,
          })
          .eq('id', clubId);
    } catch (e) {
      throw Exception('Failed to approve club: $e');
    }
  }

  // Reject a club
  Future<void> rejectClub(String clubId, String reason) async {
    try {
      await _supabase
          .from('clubs')
          .update({
            'verification_status': 'rejected',
            'rejection_reason': reason,
          })
          .eq('id', clubId);
    } catch (e) {
      throw Exception('Failed to reject club: $e');
    }
  }

  // Suspend a club
  Future<void> suspendClub(String clubId) async {
    try {
      await _supabase
          .from('clubs')
          .update({'verification_status': 'suspended'})
          .eq('id', clubId);
    } catch (e) {
      throw Exception('Failed to suspend club: $e');
    }
  }
}
