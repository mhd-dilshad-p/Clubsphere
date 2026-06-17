import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsRepository {
  final SupabaseClient _supabase;

  AnalyticsRepository(this._supabase);

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    try {
      // Fetch all clubs
      final clubsResponse = await _supabase.from('clubs').select();
      final clubs = List<Map<String, dynamic>>.from(clubsResponse);

      final totalClubs = clubs.length;
      final pendingApprovals = clubs.where((c) => c['verification_status'] == 'pending').length;

      // Calculate Club Types for Pie Chart
      final Map<String, int> clubTypesCount = {};
      for (var club in clubs) {
        final type = club['club_type']?.toString() ?? 'Other';
        clubTypesCount[type] = (clubTypesCount[type] ?? 0) + 1;
      }

      // Calculate Growth for Line Chart (last 6 months)
      final now = DateTime.now();
      final Map<int, int> growthByMonth = {};
      
      for (var club in clubs) {
        final createdAtStr = club['created_at'];
        if (createdAtStr != null) {
          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt != null) {
            // Check if within last 6 months
            final differenceInDays = now.difference(createdAt).inDays;
            if (differenceInDays <= 180) {
              final month = createdAt.month;
              growthByMonth[month] = (growthByMonth[month] ?? 0) + 1;
            }
          }
        }
      }

      // Let's try to get total users, if it fails we just return 0
      int activeUsers = 0;
      try {
        final usersResponse = await _supabase.from('club_members').select('id').count(CountOption.exact);
        activeUsers = usersResponse.count;
      } catch (e) {
        // Table might not exist or RLS might block, fallback to 0
      }

      return {
        'totalClubs': totalClubs,
        'pendingApprovals': pendingApprovals,
        'activeUsers': activeUsers,
        'totalRevenue': '\$0', // Placeholder as we don't have a payments table yet
        'clubTypes': clubTypesCount,
        'growthByMonth': growthByMonth,
      };
    } catch (e) {
      throw Exception('Failed to load analytics data: $e');
    }
  }
}
