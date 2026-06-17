import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/club_session_provider.dart';
import 'dashboard_service.dart';

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  late Future<DashboardStats> _statsFuture;
  late Future<List<Map<String, dynamic>>> _activityFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final clubId = context.read<ClubSessionNotifier>().clubId;
    if (clubId != null) {
      _statsFuture = DashboardService.getStats(clubId);
      _activityFuture = DashboardService.getRecentActivity(clubId);
    } else {
      _statsFuture = Future.value(DashboardStats());
      _activityFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ClubSessionNotifier>();
    final theme = Theme.of(context);

    if (session.isLoading) {
      return Center(
        child: Lottie.asset('assets/animations/Sandy Loading Animation.json', height: 100),
      );
    }

    final name = session.memberName?.split(' ').first ?? 'Member';
    final role = session.userRole ?? 'member';

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadData();
        });
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Section with Lottie
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,\n$name 👋',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Here is what\'s happening in your club today.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (MediaQuery.of(context).size.width > 400)
                    SvgPicture.asset(
                      'assets/illusrtations_image/welcome.svg',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOutQuart),

            const SizedBox(height: 32),

            // Stats Grid
            FutureBuilder<DashboardStats>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
                }
                final stats = snapshot.data ?? DashboardStats();
                return LayoutBuilder(builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 800 ? 4 : constraints.maxWidth > 400 ? 2 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: constraints.maxWidth > 800 ? 1.5 : 1.2,
                    children: [
                      _StatCard(title: 'Total Members', value: stats.totalMembers.toString(), icon: Icons.people_alt_rounded, color: Colors.blue),
                      if (role == 'treasurer' || role == 'president' || role == 'founding_admin')
                        _StatCard(title: 'This Month', value: '₹${stats.thisMonthIncome.toInt()}', icon: Icons.account_balance_wallet_rounded, color: Colors.green),
                      _StatCard(title: 'Upcoming Events', value: stats.upcomingEvents.toString(), icon: Icons.event_available_rounded, color: Colors.orange),
                      _StatCard(title: 'Active Elections', value: stats.activeElections.toString(), icon: Icons.how_to_vote_rounded, color: Colors.purple),
                    ].animate(interval: 100.ms).fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
                  );
                });
              },
            ),

            const SizedBox(height: 32),
            
            // Quick Actions Section
            Text('Quick Actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))
                .animate().fadeIn(delay: 400.ms).slideX(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (role == 'founding_admin' || role == 'secretary')
                  _QuickActionButton(label: 'Add Member', icon: Icons.person_add_rounded, color: Colors.blue, onTap: () => context.push('/dashboard/members')),
                if (role == 'treasurer' || role == 'founding_admin')
                  _QuickActionButton(label: 'Add Finance', icon: Icons.add_shopping_cart_rounded, color: Colors.green, onTap: () => context.push('/dashboard/finance')),
                if (role == 'president' || role == 'founding_admin')
                  _QuickActionButton(label: 'New Election', icon: Icons.how_to_vote_rounded, color: Colors.purple, onTap: () => context.push('/dashboard/elections')),
                _QuickActionButton(label: 'View Events', icon: Icons.event_rounded, color: Colors.orange, onTap: () => context.push('/dashboard/events')),
              ].animate(interval: 50.ms).fadeIn(delay: 500.ms).slideY(begin: 0.2),
            ),

            const SizedBox(height: 32),

            // Recent Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Activity', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {}, // Maybe navigate to a full log
                  child: const Text('View All'),
                )
              ],
            ).animate().fadeIn(delay: 600.ms).slideX(),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _activityFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final activities = snapshot.data ?? [];
                if (activities.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/illusrtations_image/Empty.svg', height: 120),
                        const SizedBox(height: 16),
                        const Text('No recent activity yet', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 700.ms);
                }
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activities.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                      itemBuilder: (context, index) {
                        final item = activities[index];
                        final isIncome = item['type'] == 'income';
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isIncome ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),
                          title: Text(item['description'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Just now', style: TextStyle(fontSize: 12)), // Format actual date if available
                          trailing: Text(
                            '${isIncome ? '+' : '-'}₹${item['amount']}',
                            style: TextStyle(
                              color: isIncome ? Colors.green : Colors.red, 
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1);
              },
            )
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value, 
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                title, 
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
