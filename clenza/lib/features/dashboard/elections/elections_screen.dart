import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/club_session_provider.dart';
import 'elections_service.dart';
import 'nominate_sheet.dart';
import 'vote_sheet.dart';

class ElectionsScreen extends StatefulWidget {
  const ElectionsScreen({super.key});

  @override
  State<ElectionsScreen> createState() => _ElectionsScreenState();
}

class _ElectionsScreenState extends State<ElectionsScreen> with SingleTickerProviderStateMixin {
  Stream<List<Map<String, dynamic>>>? _electionsStream;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _initStream();
  }

  void _initStream() {
    final clubId = context.read<ClubSessionNotifier>().clubId;
    if (clubId != null) {
      _electionsStream = ElectionsService.getElectionsStream(clubId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<ClubSessionNotifier>().userRole;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Elections & Voting', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Active Elections'),
                  Tab(text: 'Past Results'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _electionsStream == null 
        ? const Center(child: Text('No active club session.'))
        : StreamBuilder<List<Map<String, dynamic>>>(
            stream: _electionsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final sessions = snapshot.data ?? [];
              
              final activeSessions = sessions.where((s) => s['status'] != 'completed').toList();
              final pastSessions = sessions.where((s) => s['status'] == 'completed').toList();

              List<Map<String, dynamic>> activeList;
              if (_tabController.index == 0) {
                activeList = activeSessions;
              } else {
                activeList = pastSessions;
              }

              if (activeList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset('assets/illusrtations_image/Empty.svg', height: 150),
                      const SizedBox(height: 20),
                      Text(
                        _tabController.index == 0 ? 'No active elections' : 'No past results found', 
                        style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms),
                );
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ListView.builder(
                  key: ValueKey<int>(_tabController.index),
                  padding: const EdgeInsets.all(16),
                  itemCount: activeList.length,
                  itemBuilder: (context, index) {
                    return _ElectionCard(sessionData: activeList[index], userRole: userRole)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 50 * index))
                      .slideX(begin: 0.1);
                  },
                ),
              );
            },
          ),
      floatingActionButton: userRole == 'founding_admin'
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () {
                // TODO: Create manual session
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Session', style: TextStyle(fontWeight: FontWeight.bold)),
            ).animate().scale(delay: 500.ms, duration: 400.ms)
          : null,
    );
  }
}

class _ElectionCard extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final String? userRole;

  const _ElectionCard({required this.sessionData, required this.userRole});

  @override
  State<_ElectionCard> createState() => _ElectionCardState();
}

class _ElectionCardState extends State<_ElectionCard> {
  Future<Map<String, dynamic>>? _detailsFuture;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  void _loadDetails() {
    final memberId = context.read<ClubSessionNotifier>().memberId;
    _detailsFuture = ElectionsService.getElectionDetails(widget.sessionData['id'], memberId);
  }

  @override
  void didUpdateWidget(covariant _ElectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionData['id'] != widget.sessionData['id']) {
      _loadDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = widget.sessionData['id'];
    final position = widget.sessionData['position'] ?? 'Position';
    final status = widget.sessionData['status'] as String;
    final endDateStr = widget.sessionData['voting_end_datetime'];
    final endDate = endDateStr != null ? DateTime.parse(endDateStr) : null;

    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'voting_open': 
        statusColor = Colors.green; 
        statusBgColor = Colors.green.shade50;
        statusText = 'VOTING OPEN';
        statusIcon = Icons.how_to_vote_rounded;
        break;
      case 'scheduled': 
        statusColor = Colors.blue; 
        statusBgColor = Colors.blue.shade50;
        statusText = 'NOMINATIONS OPEN';
        statusIcon = Icons.calendar_month_rounded;
        break;
      case 'pending_president_confirm': 
        statusColor = Colors.orange; 
        statusBgColor = Colors.orange.shade50;
        statusText = 'PENDING CONFIRMATION';
        statusIcon = Icons.hourglass_empty_rounded;
        break;
      case 'completed': 
      default: 
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.shade100;
        statusText = 'COMPLETED';
        statusIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.stars_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          position.toString().replaceAll('_', ' ').toUpperCase(), 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusText, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            if (endDate != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text('Voting closes: ${DateFormat.yMMMEd().add_jm().format(endDate)}', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1, color: Colors.black12),
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: _detailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                }
                final details = snapshot.data ?? {};
                final nominees = details['nominees'] as List<dynamic>? ?? [];
                final voteCounts = details['voteCounts'] as Map<String, int>? ?? {};
                final hasVoted = details['hasVoted'] as bool? ?? false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (status == 'scheduled') ...[
                      if (nominees.isNotEmpty) ...[
                        const Text('Current Nominees', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: nominees.map((n) => Chip(
                            avatar: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              child: Text((n['club_members']?['full_name'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                            ),
                            label: Text(n['club_members']?['full_name'] ?? 'Unknown', style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.grey.shade100,
                            side: BorderSide.none,
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        Text('No nominations yet.', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 16),
                      ],
                      OutlinedButton.icon(
                        onPressed: () async {
                          await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => NominateSheet(sessionId: sessionId));
                          if (mounted) setState(() { _loadDetails(); });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text('Nominate a Member', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                    if (status == 'voting_open') ...[
                      if (hasVoted)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green),
                              SizedBox(width: 8),
                              Text('You have cast your vote', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () async {
                            await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => VoteSheet(sessionId: sessionId, nominees: nominees));
                            if (mounted) setState(() { _loadDetails(); });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.how_to_vote_rounded),
                          label: const Text('Cast Your Vote', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                    if (status == 'pending_president_confirm' || status == 'completed') ...[
                      const Text('Election Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      ...nominees.map((n) {
                        final count = voteCounts[n['nominee_id']] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: const Icon(Icons.person, size: 14, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(n['club_members']?['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('$count votes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (status == 'pending_president_confirm' && widget.userRole == 'president') ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Find winner (simplistic approach: max votes)
                            String? winnerId;
                            int maxVotes = -1;
                            for (var n in nominees) {
                              final nid = n['nominee_id'];
                              final count = voteCounts[nid] ?? 0;
                              if (count > maxVotes) {
                                maxVotes = count;
                                winnerId = nid;
                              }
                            }
                            if (winnerId != null) {
                              await ElectionsService.confirmWinner(sessionId, winnerId);
                              if (mounted) setState(() { _loadDetails(); });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.verified_rounded),
                          label: const Text('Confirm Winner', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ]
                    ]
                  ],
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
