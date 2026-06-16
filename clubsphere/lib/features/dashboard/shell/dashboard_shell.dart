import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/club_session_provider.dart';

class DashboardShell extends StatefulWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard/members')) return 1;
    if (location.startsWith('/dashboard/finance')) return 2;
    if (location.startsWith('/dashboard/events')) return 3;
    if (location.startsWith('/dashboard/elections')) return 4;
    if (location.startsWith('/dashboard/approvals')) return 5;
    if (location.startsWith('/dashboard/profile')) return 6;
    return 0; // /dashboard/home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard/home');
        break;
      case 1:
        context.go('/dashboard/members');
        break;
      case 2:
        context.go('/dashboard/finance');
        break;
      case 3:
        context.go('/dashboard/events');
        break;
      case 4:
        context.go('/dashboard/elections');
        break;
      case 5:
        context.go('/dashboard/approvals');
        break;
      case 6:
        context.go('/dashboard/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<ClubSessionNotifier>();
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (sessionState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final clubName = sessionState.clubName ?? 'My Club';
    final userRole = sessionState.userRole ?? 'member';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/logo/app_icon_backgroundremoved.png', 
                height: 24, 
                width: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield, size: 24, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                clubName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.getRoleColor(userRole).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.getRoleColor(userRole).withOpacity(0.3)),
              ),
              child: Text(
                userRole.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.getRoleColor(userRole)),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            onPressed: () {
              // TODO: Notifications
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            itemBuilder: (context) => [
              if (userRole == 'founding_admin' || userRole == 'secretary')
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Edit Club Profile')]),
                ),
              const PopupMenuItem(
                value: 'minutes',
                child: Row(children: [Icon(Icons.description, size: 20), SizedBox(width: 12), Text('Meeting Minutes')]),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [Icon(Icons.logout, size: 20, color: Colors.red), SizedBox(width: 12), Text('Logout', style: TextStyle(color: Colors.red))]),
              ),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  context.read<ClubSessionNotifier>().clear();
                  context.go('/login');
                }
              } else if (value == 'profile') {
                context.push('/dashboard/profile');
              } else if (value == 'minutes') {
                context.push('/dashboard/minutes');
              }
            },
          )
        ],
      ),
      body: Row(
        children: [
          if (!isMobile)
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  )
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildSidebarItem(context, 0, Icons.dashboard_rounded, 'Dashboard'),
                  _buildSidebarItem(context, 1, Icons.people_rounded, 'Members'),
                  _buildSidebarItem(context, 2, Icons.account_balance_wallet_rounded, 'Finance'),
                  _buildSidebarItem(context, 3, Icons.event_rounded, 'Events'),
                  _buildSidebarItem(context, 4, Icons.how_to_vote_rounded, 'Elections'),
                  if (userRole == 'president')
                    _buildSidebarItem(context, 5, Icons.verified_user_rounded, 'Approvals'),
                  if (userRole == 'founding_admin' || userRole == 'secretary' || userRole == 'admin')
                    _buildSidebarItem(context, 6, Icons.person_2_rounded, 'Profile'),
                ],
              ),
            ),
          Expanded(
            child: ClipRRect(
              borderRadius: isMobile ? BorderRadius.zero : const BorderRadius.only(topLeft: Radius.circular(24)),
              child: Container(
                color: Colors.grey.shade50,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: Colors.black.withOpacity(.1),
                  )
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
                  child: GNav(
                    rippleColor: Colors.grey[300]!,
                    hoverColor: Colors.grey[100]!,
                    gap: 8,
                    activeColor: AppColors.primary,
                    iconSize: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    duration: const Duration(milliseconds: 400),
                    tabBackgroundColor: AppColors.primary.withOpacity(0.1),
                    color: Colors.grey.shade600,
                    selectedIndex: _getSelectedIndex(context),
                    onTabChange: (index) => _onItemTapped(index, context),
                    tabs: [
                      const GButton(icon: Icons.dashboard_rounded, text: 'Home'),
                      const GButton(icon: Icons.people_rounded, text: 'Members'),
                      const GButton(icon: Icons.account_balance_wallet_rounded, text: 'Finance'),
                      const GButton(icon: Icons.event_rounded, text: 'Events'),
                      const GButton(icon: Icons.how_to_vote_rounded, text: 'Elections'),
                      if (userRole == 'president')
                        const GButton(icon: Icons.verified_user_rounded, text: 'Approvals'),
                      if (userRole == 'founding_admin' || userRole == 'secretary' || userRole == 'admin')
                        const GButton(icon: Icons.settings_rounded, text: 'Settings'),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSidebarItem(BuildContext context, int index, IconData icon, String title) {
    final isSelected = _getSelectedIndex(context) == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _onItemTapped(index, context),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade600, size: 24),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
