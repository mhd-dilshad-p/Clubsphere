import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;

  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: isDesktop ? null : AppBar(
        title: const Text('ClubSphere Super Admin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.navy,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: isDesktop ? null : _buildDrawer(context),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildTopAppBar(context),
                Expanded(
                  child: Container(
                    color: AppColors.darkBg,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.navy,
      child: _buildNavigationItems(context, isDrawer: true),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.navy,
      child: _buildNavigationItems(context),
    );
  }

  Widget _buildNavigationItems(BuildContext context, {bool isDrawer = false}) {
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Image.asset('assets/logo/app_icon_backgroundremoved.png', height: 32),
              const SizedBox(width: 12),
              const Text(
                'ClubSphere',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _NavItem(
          icon: Icons.dashboard_outlined,
          label: 'Dashboard',
          isSelected: currentPath == '/dashboard',
          onTap: () {
            if (isDrawer) Navigator.pop(context);
            context.go('/dashboard');
          },
        ),
        _NavItem(
          icon: Icons.fact_check_outlined,
          label: 'Approvals',
          isSelected: currentPath.startsWith('/approvals'),
          onTap: () {
            if (isDrawer) Navigator.pop(context);
            context.go('/approvals');
          },
        ),
        _NavItem(
          icon: Icons.business_outlined,
          label: 'Clubs',
          isSelected: currentPath.startsWith('/clubs'),
          onTap: () {
            if (isDrawer) Navigator.pop(context);
            context.go('/clubs');
          },
        ),
        _NavItem(
          icon: Icons.campaign_outlined,
          label: 'Broadcast',
          isSelected: currentPath.startsWith('/broadcast'),
          onTap: () {
            if (isDrawer) Navigator.pop(context);
            context.go('/broadcast');
          },
        ),
        _NavItem(
          icon: Icons.settings_outlined,
          label: 'Settings',
          isSelected: currentPath.startsWith('/settings'),
          onTap: () {
            if (isDrawer) Navigator.pop(context);
            context.go('/settings');
          },
        ),
        const Spacer(),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.textSecondary),
          title: const Text('Logout', style: TextStyle(color: AppColors.textSecondary)),
          onTap: () async {
            await context.read<AuthRepository>().signOut();
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.darkBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Platform Owner',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
