import 'package:flutter/material.dart';
import 'overview_tab.dart';
import '../../../clubs/presentation/screens/clubs_list_tab.dart';
import '../../../approvals/presentation/screens/approvals_tab.dart';
import '../../../auth/presentation/screens/users_list_tab.dart';
import '../../../broadcast/presentation/screens/broadcast_tab.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../../core/theme/app_colors.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _tabs => const [
    OverviewTab(),
    ClubsListTab(),
    ApprovalsTab(),
    UsersListTab(),
    BroadcastTab(),
    SettingsScreen(),
  ];

  final List<String> _tabTitles = [
    'Home',
    'Clubs',
    'Approvals',
    'People',
    'Broadcast',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: AppColors.surface,
                  elevation: 0,
                  title: const Text('ClubSphere Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  iconTheme: const IconThemeData(color: Colors.white),
                )
              : PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.blur_circular, color: AppColors.primary, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'ClubSphere',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E), // Dark bubble background
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(_tabTitles.length, (index) {
                                  final isSelected = _selectedIndex == index;
                                  return InkWell(
                                    onTap: () => setState(() => _selectedIndex = index),
                                    borderRadius: BorderRadius.circular(40),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(40),
                                        boxShadow: isSelected ? [
                                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
                                        ] : null,
                                      ),
                                      child: Text(
                                        _tabTitles[index],
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : AppColors.textSecondary,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_none, color: AppColors.textSecondary),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 16),
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
          drawer: isMobile
              ? Drawer(
                  backgroundColor: AppColors.darkBg,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const DrawerHeader(
                        decoration: BoxDecoration(color: AppColors.surface),
                        child: Text('ClubSphere Admin', style: TextStyle(color: Colors.white, fontSize: 20)),
                      ),
                      ...List.generate(_tabTitles.length, (index) {
                        return ListTile(
                          title: Text(
                            _tabTitles[index],
                            style: TextStyle(color: _selectedIndex == index ? AppColors.primary : Colors.white),
                          ),
                          onTap: () {
                            setState(() => _selectedIndex = index);
                            Navigator.pop(context);
                          },
                        );
                      }),
                    ],
                  ),
                )
              : null,
          body: Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedIndex),
                child: _tabs[_selectedIndex],
              ),
            ),
          ),
        );
      },
    );
  }
}
