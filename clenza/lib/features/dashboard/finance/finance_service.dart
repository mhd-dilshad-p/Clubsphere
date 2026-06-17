import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceService {
  static Future<List<Map<String, dynamic>>> getFinanceEntries(String clubId, String role) async {
    final supabase = Supabase.instance.client;
    
    var query = supabase
        .from('finance_entries')
        .select('*, club_members!finance_entries_submitted_by_fkey(full_name)')
        .eq('club_id', clubId);

    // If normal member, only show approved and visible entries
    if (role == 'member') {
      query = query.eq('status', 'approved').eq('is_visible_to_members', true);
    }

    final res = await query.order('transaction_date', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<bool> addEntry({
    required String clubId,
    required String userId,
    required String userRole,
    required String type,
    required String category,
    required double amount,
    required String description,
    required DateTime transactionDate,
    required bool isVisibleToMembers,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Logic: amounts >= 5000 require approval unless added by founding_admin
      String status = 'approved';
      if (amount >= 5000 && userRole != 'founding_admin') {
        status = 'pending_approval';
      }

      await supabase.from('finance_entries').insert({
        'club_id': clubId,
        'submitted_by': userId,
        'type': type,
        'category': category,
        'amount': amount,
        'description': description,
        'transaction_date': transactionDate.toIso8601String(),
        'status': status,
        'is_visible_to_members': isVisibleToMembers,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> updateStatus(String id, String status) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('finance_entries').update({'status': status}).eq('id', id);
    } catch (e) {
      // Handle error if needed
    }
  }
}
