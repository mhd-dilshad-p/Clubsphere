import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/clay_card.dart';
import '../../../dashboard/data/providers/admin_provider.dart';
import 'club_detail_screen.dart';

class ClubsListTab extends StatelessWidget {
  const ClubsListTab({super.key});

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
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      provider.clubsList.isEmpty
                          ? const Center(child: Text('No clubs found'))
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : MediaQuery.of(context).size.width > 800 ? 3 : MediaQuery.of(context).size.width > 600 ? 2 : 1,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: provider.clubsList.length,
                              itemBuilder: (context, index) {
                                final club = provider.clubsList[index];
                                return ClayCard(
                                  borderRadius: 16,
                                  padding: EdgeInsets.zero,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ClubDetailScreen(clubData: club),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Image Section
                                      Expanded(
                                        flex: 3,
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                image: club['logo_url'] != null && club['logo_url'].toString().isNotEmpty
                                                    ? DecorationImage(
                                                        image: NetworkImage(club['logo_url']),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : null,
                                              ),
                                              child: club['logo_url'] == null || club['logo_url'].toString().isEmpty
                                                  ? const Center(child: Icon(Icons.groups_rounded, size: 36, color: AppColors.primary))
                                                  : null,
                                            ),
                                            Positioned(
                                              bottom: 12,
                                              right: 12,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surface,
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.2),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      _getDay(club['created_at']),
                                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                                    ),
                                                    Text(
                                                      _getMonth(club['created_at']),
                                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Bottom Content Section
                                      Expanded(
                                        flex: 4,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.sell_outlined, size: 14, color: AppColors.primary),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      (club['category'] ?? club['club_type'] ?? 'General').toString().toUpperCase(),
                                                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(club['verification_status']).withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      (club['verification_status'] ?? 'unknown').toUpperCase(),
                                                      style: TextStyle(
                                                        color: _getStatusColor(club['verification_status']),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 9,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                club['name'] ?? 'Unknown Club',
                                                style: AppTextStyles.title.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Expanded(
                                                child: Text(
                                                  club['description'] ?? 'No description provided for this club. Please check the details for more information.',
                                                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: AppColors.darkBg,
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Text('Read More', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: const BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.black),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }



  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'suspended':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getDay(dynamic dateStr) {
    if (dateStr == null) return '01';
    try {
      final date = DateTime.parse(dateStr.toString()).toLocal();
      return date.day.toString().padLeft(2, '0');
    } catch (_) {
      return '01';
    }
  }

  String _getMonth(dynamic dateStr) {
    if (dateStr == null) return 'Jan';
    try {
      final date = DateTime.parse(dateStr.toString()).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[date.month - 1];
    } catch (_) {
      return 'Jan';
    }
  }
}
