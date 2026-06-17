import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/components/stat_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/analytics_repository.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  late Future<Map<String, dynamic>> _dashboardMetrics;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  void _loadMetrics() {
    _dashboardMetrics = context.read<AnalyticsRepository>().getDashboardMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardMetrics,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.warning, size: 60),
                const SizedBox(height: 16),
                Text('Failed to load dashboard: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loadMetrics();
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final totalClubs = data['totalClubs'] ?? 0;
        final pendingApprovals = data['pendingApprovals'] ?? 0;
        final activeUsers = data['activeUsers'] ?? 0;
        final totalRevenue = data['totalRevenue'] ?? '\$0';
        
        final Map<int, int> growthByMonth = data['growthByMonth'] ?? {};
        final Map<String, int> clubTypes = data['clubTypes'] ?? {};

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1000;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1000;
            
            const double gap = 16.0;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Welcome back to Clenza Admin. Here is your summary.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Top Stat Cards
                  if (isDesktop)
                    Row(
                      children: [
                        Expanded(child: StatCard(title: 'Total Clubs', value: totalClubs.toString(), icon: Icons.business, color: AppColors.primary)),
                        const SizedBox(width: gap),
                        Expanded(child: StatCard(title: 'Pending Approvals', value: pendingApprovals.toString(), icon: Icons.hourglass_top, color: AppColors.warning)),
                        const SizedBox(width: gap),
                        Expanded(child: StatCard(title: 'Active Users', value: activeUsers.toString(), icon: Icons.people, color: AppColors.success)),
                        const SizedBox(width: gap),
                        Expanded(child: StatCard(title: 'Total Revenue', value: totalRevenue.toString(), icon: Icons.attach_money, color: AppColors.accent)),
                      ],
                    )
                  else if (isTablet)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: StatCard(title: 'Total Clubs', value: totalClubs.toString(), icon: Icons.business, color: AppColors.primary)),
                            const SizedBox(width: gap),
                            Expanded(child: StatCard(title: 'Pending Approvals', value: pendingApprovals.toString(), icon: Icons.hourglass_top, color: AppColors.warning)),
                          ],
                        ),
                        const SizedBox(height: gap),
                        Row(
                          children: [
                            Expanded(child: StatCard(title: 'Active Users', value: activeUsers.toString(), icon: Icons.people, color: AppColors.success)),
                            const SizedBox(width: gap),
                            Expanded(child: StatCard(title: 'Total Revenue', value: totalRevenue.toString(), icon: Icons.attach_money, color: AppColors.accent)),
                          ],
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        StatCard(title: 'Total Clubs', value: totalClubs.toString(), icon: Icons.business, color: AppColors.primary),
                        const SizedBox(height: gap),
                        StatCard(title: 'Pending Approvals', value: pendingApprovals.toString(), icon: Icons.hourglass_top, color: AppColors.warning),
                        const SizedBox(height: gap),
                        StatCard(title: 'Active Users', value: activeUsers.toString(), icon: Icons.people, color: AppColors.success),
                        const SizedBox(height: gap),
                        StatCard(title: 'Total Revenue', value: totalRevenue.toString(), icon: Icons.attach_money, color: AppColors.accent),
                      ],
                    ),
                    
                  const SizedBox(height: gap),
                  
                  // Bottom Charts
                  if (isDesktop || isTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildGrowthChart(growthByMonth),
                        ),
                        const SizedBox(width: gap),
                        Expanded(
                          flex: 3,
                          child: _buildPieChart(clubTypes),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildGrowthChart(growthByMonth),
                        const SizedBox(height: gap),
                        _buildPieChart(clubTypes),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGrowthChart(Map<int, int> growthByMonth) {
    final List<FlSpot> spots = [];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    
    int cumulative = 0;
    for (int i = 5; i >= 0; i--) {
      int monthToCheck = now.month - i;
      if (monthToCheck <= 0) monthToCheck += 12;
      
      final countForMonth = growthByMonth[monthToCheck] ?? 0;
      cumulative += countForMonth;
      
      spots.add(FlSpot((5 - i).toDouble(), cumulative.toDouble()));
    }

    if (spots.isEmpty || cumulative == 0) {
      for (int i = 0; i <= 5; i++) {
        spots.add(FlSpot(i.toDouble(), 0));
      }
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Club Growth (Last 6 Months)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text('${value.toInt()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11));
                      },
                      reservedSize: 30,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int currentMonth = now.month;
                        int labelMonth = currentMonth - (5 - value.toInt());
                        if (labelMonth <= 0) labelMonth += 12;

                        if (value.toInt() >= 0 && value.toInt() <= 5) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(months[labelMonth - 1], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: spots.map((spot) {
                  return BarChartGroupData(
                    x: spot.x.toInt(),
                    barRods: [
                      BarChartRodData(
                        toY: spot.y,
                        color: AppColors.primary,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> clubTypes) {
    List<PieChartSectionData> sections = [];
    final colors = [
      AppColors.primary,
      AppColors.warning,
      AppColors.accent,
      AppColors.success,
      AppColors.textSecondary,
    ];

    if (clubTypes.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 100,
          title: 'No Data',
          color: AppColors.border,
          radius: 40,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      int colorIndex = 0;
      clubTypes.forEach((type, count) {
        sections.add(
          PieChartSectionData(
            value: count.toDouble(),
            title: '$type\n($count)',
            color: colors[colorIndex % colors.length],
            radius: 50,
            titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
        colorIndex++;
      });
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clubs by Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                startDegreeOffset: 180,
                sectionsSpace: 4,
                centerSpaceRadius: 80,
                sections: sections,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
