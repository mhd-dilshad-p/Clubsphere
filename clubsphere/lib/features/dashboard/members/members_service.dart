import 'package:supabase_flutter/supabase_flutter.dart';

class MembersService {
  static Future<List<Map<String, dynamic>>> getMembers(String clubId) async {
    final supabase = Supabase.instance.client;
    final res = await supabase
        .from('club_members')
        .select()
        .eq('club_id', clubId)
        .order('role')
        .order('full_name');

    return List<Map<String, dynamic>>.from(res);
  }

  static Future<bool> addMember({
    required String clubId,
    required String fullName,
    required String email,
    required String phone,
    required String role,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Generate member number
      final res = await supabase
          .from('club_members')
          .select()
          .eq('club_id', clubId)
          .count(CountOption.exact);
      
      final int count = res.count ?? 0;
      
      final String memberNumber = 'MBR-${(count + 1).toString().padLeft(4, '0')}';

      await supabase.from('club_members').insert({
        'club_id': clubId,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'member_number': memberNumber,
        'is_active': true,
      });

      // Increment total_members in clubs table
      await supabase.from('clubs').update({
        'total_members': count + 1,
      }).eq('id', clubId);

      return true;
    } catch (e) {
      print('Failed to add member: $e');
      return false;
    }
  }

  static Future<bool> removeMember(String memberId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('club_members').delete().eq('id', memberId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
