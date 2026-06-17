import 'package:supabase_flutter/supabase_flutter.dart';

class AdminElectionsService {
  static final supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getElectionsForClub(String clubId) async {
    final response = await supabase
        .from('election_sessions')
        .select('*')
        .eq('club_id', clubId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> getElectionDetailsWithVoters(String sessionId) async {
    // 1. Get nominees with their details
    final nomineesResponse = await supabase
        .from('election_nominations')
        .select('id, nominee_id, club_members!election_nominations_nominee_id_fkey(full_name, role)')
        .eq('session_id', sessionId);

    // 2. Get all votes for this session WITH the voter's details
    // We join the club_members table through the voter_id foreign key
    final votesResponse = await supabase
        .from('election_votes')
        .select('nominee_id, club_members!election_votes_voter_id_fkey(full_name)')
        .eq('session_id', sessionId);

    final nominees = List<Map<String, dynamic>>.from(nomineesResponse);
    final votes = List<Map<String, dynamic>>.from(votesResponse);

    // Map nominee_id -> list of voter names
    Map<String, List<String>> votersPerNominee = {};
    Map<String, int> voteCounts = {};

    for (var n in nominees) {
      votersPerNominee[n['nominee_id']] = [];
      voteCounts[n['nominee_id']] = 0;
    }

    for (var v in votes) {
      final nId = v['nominee_id'];
      final voterName = v['club_members']?['full_name'] ?? 'Unknown Voter';
      
      if (votersPerNominee.containsKey(nId)) {
        votersPerNominee[nId]!.add(voterName);
        voteCounts[nId] = (voteCounts[nId] ?? 0) + 1;
      }
    }

    return {
      'nominees': nominees,
      'votersPerNominee': votersPerNominee,
      'voteCounts': voteCounts,
      'totalVotes': votes.length,
    };
  }
}
