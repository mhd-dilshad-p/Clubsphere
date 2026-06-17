import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/club_session_provider.dart';
import '../members/members_service.dart';
import 'elections_service.dart';

class NominateSheet extends StatefulWidget {
  final String sessionId;
  const NominateSheet({super.key, required this.sessionId});

  @override
  State<NominateSheet> createState() => _NominateSheetState();
}

class _NominateSheetState extends State<NominateSheet> {
  String? _selectedMemberId;
  bool _isLoading = false;
  Future<List<Map<String, dynamic>>>? _membersFuture;

  @override
  void initState() {
    super.initState();
    final clubId = context.read<ClubSessionNotifier>().clubId;
    if (clubId != null) {
      _membersFuture = MembersService.getMembers(clubId);
    } else {
      _membersFuture = Future.value([]);
    }
  }

  void _submit() async {
    if (_selectedMemberId == null) return;
    setState(() => _isLoading = true);

    final memberId = context.read<ClubSessionNotifier>().memberId;
    if (memberId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final success = await ElectionsService.nominate(widget.sessionId, memberId, _selectedMemberId!);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to nominate'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return SizedBox(height: 200, child: Center(child: Text('Error: ${snapshot.error}')));
          }
          final members = snapshot.data ?? [];
          final activeMembers = members.where((m) => m['is_active'] == true).toList();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nominate a Member', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Member'),
                items: activeMembers.map((m) {
                  return DropdownMenuItem<String>(
                    value: m['id'],
                    child: Text('${m['full_name']} (${m['role']})'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedMemberId = v),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading || _selectedMemberId == null ? null : _submit,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Nomination'),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
