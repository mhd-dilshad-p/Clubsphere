import 'package:supabase_flutter/supabase_flutter.dart';

class PublicService {
  static Future<List<Map<String, dynamic>>> getPublicClubs() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('clubs')
        .select('id, name, category, logo_url, cover_image_url, description, founding_date, created_at, district, state, register_number, instagram_url')
        .eq('verification_status', 'verified')
        .order('created_at', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> getClubProfile(String clubId) async {
    final supabase = Supabase.instance.client;
    
    // Fetch club basic details
    final club = await supabase
        .from('clubs')
        .select()
        .eq('id', clubId)
        .eq('verification_status', 'verified')
        .single();
        
    // Fetch leadership
    final members = await supabase
        .from('club_members')
        .select('full_name, role')
        .eq('club_id', clubId)
        .eq('is_active', true)
        .inFilter('role', ['president', 'vice_president', 'secretary', 'treasurer'])
        .order('role');
        
    // Fetch upcoming public programs
    final now = DateTime.now().toIso8601String();
    final programs = await supabase
        .from('programs')
        .select('title, start_datetime, venue, category')
        .eq('club_id', clubId)
        .eq('is_published', true)
        .gte('start_datetime', now)
        .order('start_datetime')
        .limit(3);
    // Fetch gallery images
    List<dynamic> gallery = [];
    try {
      gallery = await supabase
          .from('club_gallery')
          .select('id, image_url, title, created_at, media_type')
          .eq('club_id', clubId)
          .order('created_at', ascending: false);
    } catch (e) {
      // Ignore if table doesn't exist yet
    }

    // Fetch member count
    final memberCountList = await supabase
        .from('club_members')
        .select('id')
        .eq('club_id', clubId)
        .eq('is_active', true);
    final memberCount = memberCountList.length;

    // Fetch past events
    List<dynamic> pastEvents = [];
    try {
      pastEvents = await supabase
          .from('club_past_events')
          .select()
          .eq('club_id', clubId)
          .eq('is_visible', true)
          .order('start_date', ascending: false);
    } catch (e) {
      // Ignore if table doesn't exist yet
    }

    return {
      'club': club,
      'leadership': members,
      'programs': programs,
      'gallery': gallery,
      'member_count': memberCount,
      'past_events': pastEvents,
    };
  }

  static Future<Map<String, dynamic>> getPublicProgram(String eventId) async {
    final supabase = Supabase.instance.client;
    final program = await supabase
        .from('programs')
        .select()
        .eq('id', eventId)
        .eq('is_published', true)
        .single();
    return program;
  }
  static Future<Map<String, dynamic>> getPublicPastEvent(String eventId) async {
    final supabase = Supabase.instance.client;
    final program = await supabase
        .from('club_past_events')
        .select()
        .eq('id', eventId)
        .eq('is_visible', true)
        .single();
    return program;
  }
}
