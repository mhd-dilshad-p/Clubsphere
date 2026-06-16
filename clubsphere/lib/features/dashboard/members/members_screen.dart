import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/club_session_provider.dart';
import 'members_service.dart';
import 'add_member_sheet.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late Future<List<Map<String, dynamic>>> _membersFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMembers() {
    final clubId = context.read<ClubSessionNotifier>().clubId;
    if (clubId != null) {
      _membersFuture = MembersService.getMembers(clubId);
    } else {
      _membersFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ClubSessionNotifier>();
    final canAddMember = session.userRole == 'founding_admin' || session.userRole == 'secretary';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Club Members', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'All Members'),
                  Tab(text: 'Committee'),
                  Tab(text: 'Regular'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final members = snapshot.data ?? [];
          var filtered = members.where((m) {
            final nameMatch = (m['full_name'] ?? '').toLowerCase().contains(_searchQuery);
            final roleMatch = (m['role'] ?? '').toLowerCase().contains(_searchQuery);
            return nameMatch || roleMatch;
          }).toList();

          if (_tabController.index == 1) {
            filtered = filtered.where((m) => m['role'] != 'member').toList();
          } else if (_tabController.index == 2) {
            filtered = filtered.where((m) => m['role'] == 'member').toList();
          }

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/illusrtations_image/Empty.svg', height: 150),
                  const SizedBox(height: 20),
                  const Text('No members found', style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ).animate().fadeIn(duration: 500.ms),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _loadMembers()),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final member = filtered[index];
                final role = member['role'] as String;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.getRoleColor(role).withOpacity(0.15),
                      child: Text(
                        (member['full_name'] ?? '?')[0].toUpperCase(),
                        style: TextStyle(color: AppColors.getRoleColor(role), fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    title: Text(member['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'ID: ${member['member_number'] ?? 'N/A'}\n${member['phone'] ?? member['email']}',
                        style: TextStyle(color: Colors.grey.shade600, height: 1.3),
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.getRoleColor(role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.getRoleColor(role).withOpacity(0.3)),
                      ),
                      child: Text(
                        role.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.getRoleColor(role)),
                      ),
                    ),
                    onTap: () {
                      _showMemberDetails(context, member, canAddMember);
                    },
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
              },
            ),
          );
        },
      ),
      floatingActionButton: canAddMember
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () async {
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AddMemberSheet(),
                );
                if (result == true) {
                  setState(() {
                    _loadMembers();
                  });
                }
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Member', style: TextStyle(fontWeight: FontWeight.bold)),
            ).animate().scale(delay: 500.ms, duration: 400.ms)
          : null,
    );
  }

  void _showMemberDetails(BuildContext context, Map<String, dynamic> member, bool isAdmin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.getRoleColor(member['role']).withOpacity(0.15),
              child: Icon(Icons.person, color: AppColors.getRoleColor(member['role'])),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(member['full_name'] ?? 'Member Details', style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.badge_outlined, 'Role', (member['role'] as String).replaceAll('_', ' ').toUpperCase()),
            _buildDetailRow(Icons.email_outlined, 'Email', member['email'] ?? 'N/A'),
            _buildDetailRow(Icons.phone_outlined, 'Phone', member['phone'] ?? 'N/A'),
            _buildDetailRow(Icons.info_outline_rounded, 'Status', member['is_active'] == true ? 'Active' : 'Inactive'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          if (isAdmin)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Remove Member?'),
                    content: const Text('Are you sure you want to remove this member? This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      TextButton(
                        style: TextButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1)),
                        onPressed: () => Navigator.pop(c, true), 
                        child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                      ),
                    ],
                  )
                );
                
                if (confirm == true) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  final success = await MembersService.removeMember(member['id']);
                  if (!context.mounted) return;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Member removed successfully.'), backgroundColor: Colors.green),
                    );
                    setState(() {
                      _loadMembers();
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to remove member. Check permissions.'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Remove Member', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ).animate().scale(duration: 200.ms, curve: Curves.easeOutQuart),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
