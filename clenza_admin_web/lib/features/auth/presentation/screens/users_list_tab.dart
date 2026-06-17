import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/data/providers/admin_provider.dart';

class UsersListTab extends StatelessWidget {
  const UsersListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      provider.usersList.isEmpty
                          ? const Center(child: Text('No users found', style: TextStyle(color: Colors.white70)))
                          : _buildUsersList(context, provider),
                    ],
                  ),
                ),
    );
  }



  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return AppColors.success;
      case 'president':
        return AppColors.president;
      case 'secretary':
        return AppColors.secretary;
      case 'treasurer':
        return AppColors.treasurer;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildUsersList(BuildContext context, AdminProvider provider) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: -2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop) _buildTableHeader(),
          if (isDesktop) const Divider(color: Colors.white12, height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.usersList.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
            itemBuilder: (context, index) {
              final user = provider.usersList[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: isDesktop ? _buildDesktopRow(context, user, provider) : _buildMobileCard(context, user, provider),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('User Details', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 2, child: Text('Role', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 2, child: Text('Club ID', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 2, child: Text('Joined', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('Actions', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)))),
        ],
      ),
    );
  }

  Widget _buildDesktopRow(BuildContext context, Map<String, dynamic> user, AdminProvider provider) {
    final name = user['full_name']?.toString() ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final club = provider.clubsList.firstWhere((c) => c['id'] == user['club_id'], orElse: () => <String, dynamic>{});
    final clubCode = club['club_code']?.toString() ?? user['club_id']?.toString() ?? 'N/A';

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getRoleColor(user['role']).withValues(alpha: 0.15),
                child: Text(
                  initial,
                  style: TextStyle(color: _getRoleColor(user['role']), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${name.toLowerCase().replaceAll(' ', '')}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRoleColor(user['role']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getRoleColor(user['role']).withValues(alpha: 0.3)),
              ),
              child: Text(
                (user['role'] ?? 'member').toUpperCase(),
                style: TextStyle(
                  color: _getRoleColor(user['role']),
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: clubCode));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Club ID copied to clipboard!')));
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        clubCode,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.copy_rounded, color: AppColors.primary, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            user['created_at'] != null ? DateTime.parse(user['created_at']).toLocal().toString().split(' ')[0] : 'N/A',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
                onPressed: () {},
                tooltip: 'Delete',
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCard(BuildContext context, Map<String, dynamic> user, AdminProvider provider) {
    final name = user['full_name']?.toString() ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final club = provider.clubsList.firstWhere((c) => c['id'] == user['club_id'], orElse: () => <String, dynamic>{});
    final clubCode = club['club_code']?.toString() ?? user['club_id']?.toString() ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: _getRoleColor(user['role']).withValues(alpha: 0.15),
              child: Text(
                initial,
                style: TextStyle(color: _getRoleColor(user['role']), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${name.toLowerCase().replaceAll(' ', '')}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Role', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(user['role']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getRoleColor(user['role']).withValues(alpha: 0.3)),
              ),
              child: Text(
                (user['role'] ?? 'member').toUpperCase(),
                style: TextStyle(
                  color: _getRoleColor(user['role']),
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Club ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: clubCode));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Club ID copied to clipboard!')));
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        clubCode,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.copy_rounded, color: AppColors.primary, size: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Joined', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text(user['created_at'] != null ? DateTime.parse(user['created_at']).toLocal().toString().split(' ')[0] : 'N/A', style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}
