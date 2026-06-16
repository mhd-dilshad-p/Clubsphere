import 'package:supabase_flutter/supabase_flutter.dart';

class MinutesService {
  static Future<List<Map<String, dynamic>>> getMinutes(String clubId, String role) async {
    final supabase = Supabase.instance.client;

    var query = supabase
        .from('meeting_minutes')
        .select()
        .eq('club_id', clubId);

    if (role == 'member') {
      query = query.eq('is_published', true);
    }

    final res = await query.order('meeting_date', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<bool> addMinutes({
    required String clubId,
    required String userId,
    required String title,
    required DateTime meetingDate,
    required String content,
    required bool isPublished,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase.from('meeting_minutes').insert({
        'club_id': clubId,
        'created_by': userId,
        'title': title,
        'meeting_date': meetingDate.toIso8601String(),
        'content': content,
        'is_published': isPublished,
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
