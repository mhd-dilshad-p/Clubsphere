import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _totalClubs = 0;
  int get totalClubs => _totalClubs;

  int _pendingClubs = 0;
  int get pendingClubs => _pendingClubs;

  int _totalUsers = 0;
  int get totalUsers => _totalUsers;

  List<Map<String, dynamic>> _clubsList = [];
  List<Map<String, dynamic>> get clubsList => _clubsList;

  List<Map<String, dynamic>> _usersList = [];
  List<Map<String, dynamic>> get usersList => _usersList;

  Future<void> loadDashboardStats() async {
    _setLoading(true);
    try {
      // Get clubs
      final clubsData = await _supabase.from('clubs').select();
      _clubsList = List<Map<String, dynamic>>.from(clubsData);
      
      _totalClubs = _clubsList.length;
      _pendingClubs = _clubsList.where((c) => c['verification_status'] == 'pending').length;

      // Get users
      final usersData = await _supabase.from('club_members').select();
      _usersList = List<Map<String, dynamic>>.from(usersData);
      _totalUsers = _usersList.length;

      _error = null;
    } catch (e) {
      _error = 'Failed to load stats: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateClubStatus(String clubId, String newStatus) async {
    _setLoading(true);
    try {
      final updateData = <String, dynamic>{};
      
      if (newStatus == 'active' || newStatus == 'verified') {
        updateData['verification_status'] = 'verified';
        updateData['is_active'] = true;
        final currentClub = _clubsList.firstWhere((c) => c['id'] == clubId, orElse: () => {});
        if (currentClub['club_code'] == null) {
          final code = 'CLB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13)}';
          updateData['club_code'] = code;
        }
      } else if (newStatus == 'rejected') {
        updateData['verification_status'] = 'rejected';
        updateData['is_active'] = false;
      } else if (newStatus == 'suspended') {
        updateData['verification_status'] = 'suspended';
        updateData['is_active'] = false;
      } else {
        updateData['verification_status'] = newStatus;
      }
      
      await _supabase
          .from('clubs')
          .update(updateData)
          .eq('id', clubId);
      
      await loadDashboardStats(); // Refresh lists
      return true;
    } catch (e) {
      _error = 'Failed to update club status: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteClub(String clubId) async {
    _setLoading(true);
    try {
      await _supabase.from('club_members').delete().eq('club_id', clubId);
      await _supabase.from('clubs').delete().eq('id', clubId);
      _clubsList.removeWhere((c) => c['id'] == clubId);
      _totalClubs = _clubsList.length;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete club: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
