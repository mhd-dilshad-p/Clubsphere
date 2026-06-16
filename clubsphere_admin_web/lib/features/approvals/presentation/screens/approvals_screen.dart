import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/components/admin_layout.dart';
import '../../../../core/components/status_badge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/club_repository.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  late Future<List<Map<String, dynamic>>> _pendingClubsFuture;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  void _loadClubs() {
    setState(() {
      _pendingClubsFuture = context.read<ClubRepository>().getPendingClubs();
    });
  }

  void _showReviewModal(Map<String, dynamic> club) {
    showDialog(
      context: context,
      builder: (context) => _ReviewModal(
        club: club,
        onProcessed: () {
          Navigator.pop(context);
          _loadClubs(); // Reload the list after approval/rejection
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pending Approvals',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _pendingClubsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading clubs: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    );
                  }

                  final clubs = snapshot.data ?? [];

                  if (clubs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No pending approvals at the moment.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                          columns: const [
                            DataColumn(label: Text('Date Applied')),
                            DataColumn(label: Text('Club Name')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: clubs.map((club) {
                            final createdAt = club['created_at'] != null 
                              ? DateTime.tryParse(club['created_at']) 
                              : null;
                              
                            final formattedDate = createdAt != null 
                              ? DateFormat('MMM d, yyyy').format(createdAt) 
                              : 'Unknown';

                            return DataRow(
                              cells: [
                                DataCell(Text(formattedDate)),
                                DataCell(
                                  Text(
                                    club['name'] ?? 'Unnamed Club',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                DataCell(Text(club['club_type'] ?? 'General')),
                                DataCell(StatusBadge(status: club['verification_status'] ?? 'pending')),
                                DataCell(
                                  ElevatedButton(
                                    onPressed: () => _showReviewModal(club),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.navy,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Review'),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewModal extends StatefulWidget {
  final Map<String, dynamic> club;
  final VoidCallback onProcessed;

  const _ReviewModal({required this.club, required this.onProcessed});

  @override
  State<_ReviewModal> createState() => _ReviewModalState();
}

class _ReviewModalState extends State<_ReviewModal> {
  bool _isProcessing = false;
  final _reasonController = TextEditingController();

  Future<void> _approve() async {
    setState(() => _isProcessing = true);
    try {
      await context.read<ClubRepository>().approveClub(widget.club['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club approved successfully!'), backgroundColor: AppColors.success),
        );
        widget.onProcessed();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rejection reason.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await context.read<ClubRepository>().rejectClub(widget.club['id'], _reasonController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club rejected.'), backgroundColor: AppColors.warning),
        );
        widget.onProcessed();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Review Registration',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow('Club Name', widget.club['name'] ?? 'N/A'),
            _buildDetailRow('Club Type', widget.club['club_type'] ?? 'N/A'),
            _buildDetailRow('Admin Email', widget.club['admin_email'] ?? 'N/A'),
            _buildDetailRow('Phone Number', widget.club['phone_number'] ?? 'N/A'),
            _buildDetailRow('Address', widget.club['address'] ?? 'N/A'),
            _buildDetailRow('Description', widget.club['description'] ?? 'N/A', isLong: true),
            
            const SizedBox(height: 24),
            const Text(
              'Rejection Reason (if rejecting)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason for rejection...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isProcessing ? null : _reject,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Reject Application'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _approve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Approve Club'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: isLong ? null : 1,
              overflow: isLong ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
