import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/admin_elections_service.dart';

class ClubElectionsSection extends StatefulWidget {
  final String clubId;

  const ClubElectionsSection({super.key, required this.clubId});

  @override
  State<ClubElectionsSection> createState() => _ClubElectionsSectionState();
}

class _ClubElectionsSectionState extends State<ClubElectionsSection> {
  List<Map<String, dynamic>> _elections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadElections();
  }

  Future<void> _loadElections() async {
    try {
      final elections = await AdminElectionsService.getElectionsForClub(widget.clubId);
      if (mounted) {
        setState(() {
          _elections = elections;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_elections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border.withOpacity(0.3)),
        ),
        child: Center(
          child: Text('No elections found for this club.', style: AppTextStyles.body.copyWith(color: Colors.white70)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _elections.map((election) => _AdminElectionCard(election: election)).toList(),
    );
  }
}

class _AdminElectionCard extends StatefulWidget {
  final Map<String, dynamic> election;

  const _AdminElectionCard({required this.election});

  @override
  State<_AdminElectionCard> createState() => _AdminElectionCardState();
}

class _AdminElectionCardState extends State<_AdminElectionCard> {
  bool _isLoadingDetails = false;
  Map<String, dynamic>? _details;
  bool _isExpanded = false;

  Future<void> _loadDetails() async {
    if (_details != null) return;
    
    setState(() => _isLoadingDetails = true);
    try {
      final details = await AdminElectionsService.getElectionDetailsWithVoters(widget.election['id']);
      if (mounted) {
        setState(() {
          _details = details;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.election['status'] ?? 'unknown';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            title: Text(widget.election['title'] ?? 'Election', style: AppTextStyles.title.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Status: ${status.toUpperCase()} • Total Votes: ${_details?['totalVotes'] ?? '...'}', style: TextStyle(color: Colors.white70)),
            trailing: Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white),
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
              if (_isExpanded) _loadDetails();
            },
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: _isLoadingDetails
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDetails(),
            ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    if (_details == null) return const Text('Failed to load details', style: TextStyle(color: AppColors.error));
    
    final nominees = _details!['nominees'] as List;
    final votersPerNominee = _details!['votersPerNominee'] as Map<String, List<String>>;
    final voteCounts = _details!['voteCounts'] as Map<String, int>;

    if (nominees.isEmpty) {
      return const Text('No nominees in this election.', style: TextStyle(color: Colors.white70));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: nominees.map((n) {
        final nomineeId = n['nominee_id'];
        final memberData = n['club_members'] ?? {};
        final nomineeName = memberData['full_name'] ?? 'Unknown Member';
        final nomineeRole = memberData['role'] ?? 'member';
        final votes = voteCounts[nomineeId] ?? 0;
        final voterNames = votersPerNominee[nomineeId] ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$nomineeName (${nomineeRole.toUpperCase()})',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$votes Votes', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (voterNames.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Voted By:', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: voterNames.map((name) => Chip(
                    label: Text(name, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    backgroundColor: Colors.white10,
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  )).toList(),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
