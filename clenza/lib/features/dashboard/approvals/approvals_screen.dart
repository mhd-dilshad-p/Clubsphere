import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/club_session_provider.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingEvents = [];
  List<Map<String, dynamic>> _pendingMembers = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingApprovals();
  }

  Future<void> _fetchPendingApprovals() async {
    final clubId = context.read<ClubSessionNotifier>().clubId;
    if (clubId == null) return;

    try {
      final events = await supabase
          .from('programs')
          .select('*')
          .eq('club_id', clubId)
          .eq('approval_status', 'pending');

      final members = await supabase
          .from('club_members')
          .select('*')
          .eq('club_id', clubId)
          .eq('approval_status', 'pending');

      if (mounted) {
        setState(() {
          _pendingEvents = List<Map<String, dynamic>>.from(events);
          _pendingMembers = List<Map<String, dynamic>>.from(members);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load pending approvals.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _updateStatus(String table, String id, String status) async {
    try {
      await supabase.from(table).update({'approval_status': status}).eq('id', id);
      _fetchPendingApprovals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('President Approvals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text('Review and approve actions submitted by the Secretary.', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                const SizedBox(height: 32),
                
                Text('Pending Events (${_pendingEvents.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                if (_pendingEvents.isEmpty)
                  _buildEmptyState('No pending events')
                else
                  ..._pendingEvents.map((e) => _buildApprovalCard(
                    title: e['title'] ?? 'Unnamed Event',
                    subtitle: 'Date: ${e['date'] ?? 'TBD'}',
                    onApprove: () => _updateStatus('programs', e['id'].toString(), 'approved'),
                    onReject: () => _updateStatus('programs', e['id'].toString(), 'rejected_pending_vote'),
                  )),
                
                const SizedBox(height: 32),
                
                Text('Pending Members (${_pendingMembers.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                if (_pendingMembers.isEmpty)
                  _buildEmptyState('No pending members')
                else
                  ..._pendingMembers.map((m) => _buildApprovalCard(
                    title: m['full_name'] ?? 'Unnamed Member',
                    subtitle: 'Email: ${m['email']} • Phone: ${m['phone']}',
                    onApprove: () => _updateStatus('club_members', m['id'].toString(), 'approved'),
                    onReject: () => _updateStatus('club_members', m['id'].toString(), 'rejected_pending_vote'),
                  )),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(child: Text(message, style: TextStyle(color: Colors.grey.shade500))),
    );
  }

  Widget _buildApprovalCard({
    required String title,
    required String subtitle,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject & Vote'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
