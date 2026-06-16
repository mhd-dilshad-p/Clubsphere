import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardStats {
  final int totalMembers;
  final double thisMonthIncome;
  final int upcomingEvents;
  final int activeElections;

  DashboardStats({
    this.totalMembers = 0,
    this.thisMonthIncome = 0.0,
    this.upcomingEvents = 0,
    this.activeElections = 0,
  });
}

class DashboardService {
  static Future<DashboardStats> getStats(String clubId) async {
    final supabase = Supabase.instance.client;

    // Total members
    final membersRes = await supabase
        .from('club_members')
        .select()
        .eq('club_id', clubId)
        .eq('is_active', true)
        .count(CountOption.exact);
    final int membersCount = membersRes.count ?? 0;

    // This Month Income
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1).toIso8601String();
    final incomeRes = await supabase
        .from('finance_entries')
        .select('amount')
        .eq('club_id', clubId)
        .eq('type', 'income')
        .eq('status', 'approved')
        .gte('transaction_date', firstDay);

    double income = 0.0;
    for (var entry in incomeRes) {
      income += (entry['amount'] as num).toDouble();
    }

    // Upcoming events
    final eventsRes = await supabase
        .from('programs')
        .select()
        .eq('club_id', clubId)
        .gte('start_datetime', now.toIso8601String())
        .count(CountOption.exact);
    final int upcomingEvents = eventsRes.count ?? 0;

    // Active elections
    final electionsRes = await supabase
        .from('election_sessions')
        .select()
        .eq('club_id', clubId)
        .inFilter('status', ['voting_open', 'pending_president_confirm'])
        .count(CountOption.exact);
    final int activeElections = electionsRes.count ?? 0;

    return DashboardStats(
      totalMembers: membersCount,
      thisMonthIncome: income,
      upcomingEvents: upcomingEvents,
      activeElections: activeElections,
    );
  }

  static Future<List<Map<String, dynamic>>> getRecentActivity(String clubId) async {
    final supabase = Supabase.instance.client;

    // Just fetch latest finance entries for simplicity of activity feed
    final res = await supabase
        .from('finance_entries')
        .select('id, type, amount, description, created_at')
        .eq('club_id', clubId)
        .order('created_at', ascending: false)
        .limit(5);

    return List<Map<String, dynamic>>.from(res);
  }
}
