import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/clay_card.dart';
import '../../../dashboard/data/providers/admin_provider.dart';

class ApprovalsTab extends StatefulWidget {
  const ApprovalsTab({super.key});

  @override
  State<ApprovalsTab> createState() => _ApprovalsTabState();
}

class _ApprovalsTabState extends State<ApprovalsTab> {
  Map<String, dynamic>? _selectedClub;
  final TextEditingController _remarksController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  void _handleAction(BuildContext context, AdminProvider provider, String clubId, String status) async {
    setState(() => _isProcessing = true);
    final success = await provider.updateClubStatus(clubId, status);
    if (success && context.mounted) {
      if (_selectedClub != null && _selectedClub!['id'] == clubId) {
        setState(() {
          _selectedClub = null;
          _remarksController.clear();
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration ${status == 'active' ? 'approved' : 'declined'} successfully'),
          backgroundColor: status == 'active' ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final pendingClubs = provider.clubsList.where((c) => c['verification_status'] == 'pending').toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 800;
                    return Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sidebar
                        SizedBox(
                          width: isMobile ? double.infinity : 280,
                          height: isMobile ? 300 : null, // Limit height on mobile so it doesn't take whole screen

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registration Requests',
                            style: AppTextStyles.title.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pendingClubs.length} pending applications',
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: pendingClubs.isEmpty
                                ? const Center(child: Text('No pending requests.'))
                                : ListView.builder(
                                    itemCount: pendingClubs.length,
                                    itemBuilder: (context, index) {
                                      final club = pendingClubs[index];
                                      final isSelected = _selectedClub != null && _selectedClub!['id'] == club['id'];
                                      return _buildSidebarCard(club, isSelected);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Main Content
                    if (!isMobile) const SizedBox(width: 32),
                    if (isMobile) const SizedBox(height: 32),
                    Expanded(
                      flex: isMobile ? 0 : 1, // On mobile, we might not want Expanded if in a scroll view, but since parent is Scaffold body it's fine. Wait, if it's vertical, Expanded needs bounded height. Let's just wrap it.
                      child: _selectedClub == null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text(
                                  'Select an application to review',
                                  style: AppTextStyles.title.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                            )
                          : _buildDetailPane(provider),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSidebarCard(Map<String, dynamic> club, bool isSelected) {
    final createdAt = club['created_at'] != null ? DateTime.tryParse(club['created_at']) : null;
    final formattedDate = createdAt != null ? DateFormat('MMM d, yyyy').format(createdAt) : 'Unknown';
    final cardColor = isSelected ? AppColors.surfaceAlt : AppColors.surface;
    final textColor = Colors.white;
    final subtextColor = isSelected ? Colors.white70 : AppColors.textSecondary;

    // determine a pseudo tag based on date
    String statusTag = 'PENDING';
    Color tagColor = Colors.white24;
    Color tagTextColor = Colors.white;

    if (createdAt != null) {
      final daysPending = DateTime.now().difference(createdAt).inDays;
      if (daysPending > 7) {
        statusTag = 'URGENT';
        tagColor = const Color(0xFFC0392B);
        tagTextColor = Colors.white;
      } else if (daysPending < 2) {
        statusTag = 'NEW';
        tagColor = const Color(0xFF27AE60);
        tagTextColor = Colors.white;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedClub = club;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ClayCard(
          color: cardColor,
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      club['name'] ?? 'Unnamed',
                      style: AppTextStyles.title.copyWith(color: textColor, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tagColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusTag,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagTextColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Submitted: $formattedDate', style: AppTextStyles.body.copyWith(color: subtextColor, fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.category_outlined, size: 16, color: subtextColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (club['club_type'] ?? 'General').toString().toUpperCase(),
                      style: AppTextStyles.label.copyWith(color: subtextColor, letterSpacing: 1),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPane(AdminProvider provider) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClubInfoSection(),
              const SizedBox(height: 32),
              Text(
                'Leadership Team',
                style: AppTextStyles.title.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildLeadershipSection(),
              const SizedBox(height: 32),
              _buildDecisionSection(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClubInfoSection() {
    final coverUrl = _selectedClub!['cover_image_url']?.toString() ?? '';
    final name = _selectedClub!['name']?.toString() ?? 'Unknown Club';
    final type = _selectedClub!['club_type']?.toString().toUpperCase() ?? 'GENERAL';
    final description = _selectedClub!['description']?.toString() ?? 'No description provided.';
    final date = _selectedClub!['created_at'] != null 
        ? DateFormat('MMM d, yyyy').format(DateTime.tryParse(_selectedClub!['created_at']) ?? DateTime.now()) 
        : 'Unknown Date';

    return ClayCard(
      color: AppColors.surface,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover Image
          if (coverUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                coverUrl,
                height: 240,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: AppColors.darkBg,
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
                ),
              ),
            )
          else
            Container(
              height: 150,
              decoration: const BoxDecoration(
                color: AppColors.darkBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50)),
            ),
          
          // Basic Info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.title.copyWith(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 6),
                    Text('Applied on $date', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'About the Club',
                  style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTextStyles.body.copyWith(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadershipSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client
          .from('club_members')
          .select()
          .eq('club_id', _selectedClub!['id'])
          .neq('role', 'member')
          .order('role'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
        }
        final leaders = snapshot.data ?? [];
        if (leaders.isEmpty) {
          return ClayCard(
            color: AppColors.surface,
            padding: const EdgeInsets.all(24),
            borderRadius: 16,
            child: const Center(child: Text('No leadership assigned yet.', style: TextStyle(color: AppColors.textSecondary))),
          );
        }

        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: leaders.map((leader) => _buildLeaderCard(
            leader['full_name'] ?? 'Unknown',
            (leader['role'] ?? '').toString().toUpperCase().replaceAll('_', ' '),
            leader['avatar_url'],
          )).toList(),
        );
      },
    );
  }

  Widget _buildLeaderCard(String name, String role, String? avatarUrl) {
    return SizedBox(
      width: 180,
      child: ClayCard(
        color: AppColors.surface,
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.darkBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 2),
                image: avatarUrl != null && avatarUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.grey, size: 40)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: AppTextStyles.title.copyWith(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              role,
              style: AppTextStyles.label.copyWith(
                color: role == 'PRESIDENT' ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionSection(AdminProvider provider) {
    return ClayCard(
      color: AppColors.surface,
      borderRadius: 16,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Decision & Remarks',
            style: AppTextStyles.title.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(
            'ADMIN REMARKS (INTERNAL)',
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarksController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add notes for other administrators or feedback for the club...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: AppColors.darkBg.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _handleAction(context, provider, _selectedClub!['id'], 'active'),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text('Approve Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => _handleAction(context, provider, _selectedClub!['id'], 'rejected'),
                  icon: const Icon(Icons.cancel_outlined, color: Color(0xFFC0392B)),
                  label: const Text('Decline Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC0392B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: const Color(0xFFC0392B).withValues(alpha: 0.5), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: AppColors.surface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Status change will be emailed to the club president immediately.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
