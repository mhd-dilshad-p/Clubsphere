import 'package:supabase_flutter/supabase_flutter.dart';

class ElectionsService {
  static Stream<List<Map<String, dynamic>>> getElectionsStream(String clubId) {
    return Supabase.instance.client
        .from('election_sessions')
        .stream(primaryKey: ['id'])
        .eq('club_id', clubId)
        .order('created_at');
  }

  static Future<Map<String, dynamic>> getElectionDetails(String sessionId, String? memberId) async {
    final supabase = Supabase.instance.client;

    final nominees = await supabase
        .from('election_nominations')
        .select('id, nominee_id, club_members!election_nominations_nominee_id_fkey(full_name, role)')
        .eq('session_id', sessionId);

    final votes = await supabase
        .from('election_votes')
        .select('nominee_id');

    bool hasVoted = false;
    if (memberId != null) {
      final voteCheck = await supabase
          .from('election_votes')
          .select('id')
          .eq('session_id', sessionId)
          .eq('voter_id', memberId)
          .maybeSingle();
      hasVoted = voteCheck != null;
    }

    final Map<String, int> voteCounts = {};
    for (var v in votes) {
      final nid = v['nominee_id'] as String;
      voteCounts[nid] = (voteCounts[nid] ?? 0) + 1;
    }

    return {
      'nominees': nominees,
      'voteCounts': voteCounts,
      'hasVoted': hasVoted,
    };
  }

  static Future<bool> castVote(String sessionId, String voterId, String nomineeId) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase.from('election_votes').insert({
        'session_id': sessionId,
        'voter_id': voterId,
        'nominee_id': nomineeId,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> nominate(String sessionId, String nominatorId, String nomineeId) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase.from('election_nominations').insert({
        'session_id': sessionId,
        'nominator_id': nominatorId,
        'nominee_id': nomineeId,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> confirmWinner(String sessionId, String winnerId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('election_sessions').update({'status': 'completed'}).eq('id', sessionId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
