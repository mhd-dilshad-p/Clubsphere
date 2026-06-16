import 'package:supabase_flutter/supabase_flutter.dart';

class EventsService {
  static Future<List<Map<String, dynamic>>> getEvents(String clubId) async {
    final supabase = Supabase.instance.client;
    final res = await supabase
        .from('programs')
        .select()
        .eq('club_id', clubId)
        .order('start_datetime', ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }

  static Future<bool> createEvent({
    required String clubId,
    required String title,
    required String category,
    required String description,
    required String venue,
    required DateTime start,
    required DateTime end,
    required double budget,
    required bool isPublished,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('programs').insert({
        'club_id': clubId,
        'title': title,
        'category': category,
        'description': description,
        'venue': venue,
        'start_datetime': start.toIso8601String(),
        'end_datetime': end.toIso8601String(),
        'budget_amount': budget,
        'is_published': isPublished,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
