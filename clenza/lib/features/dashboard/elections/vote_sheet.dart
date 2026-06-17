import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/club_session_provider.dart';
import 'elections_service.dart';

class VoteSheet extends StatefulWidget {
  final String sessionId;
  final List<dynamic> nominees;
  const VoteSheet({super.key, required this.sessionId, required this.nominees});

  @override
  State<VoteSheet> createState() => _VoteSheetState();
}

class _VoteSheetState extends State<VoteSheet> {
  String? _selectedNomineeId;
  bool _isLoading = false;

  void _submit() async {
    if (_selectedNomineeId == null) return;
    
    setState(() => _isLoading = true);

    final memberId = context.read<ClubSessionNotifier>().memberId;
    if (memberId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final success = await ElectionsService.castVote(widget.sessionId, memberId, _selectedNomineeId!);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to cast vote'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Cast Your Vote', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          if (widget.nominees.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No nominations available.'),
            )
          else
            ...widget.nominees.map((n) {
              final nomineeId = n['nominee_id'];
              final name = n['club_members']?['full_name'] ?? 'Unknown';
              return RadioListTile<String>(
                title: Text(name),
                value: nomineeId,
                // ignore: deprecated_member_use
                groupValue: _selectedNomineeId,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _selectedNomineeId = v),
              );
            }),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading || _selectedNomineeId == null ? null : _submit,
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Vote'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
