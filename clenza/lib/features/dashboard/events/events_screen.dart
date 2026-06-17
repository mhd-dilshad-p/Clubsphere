import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/club_session_provider.dart';
import 'events_service.dart';
import 'create_event_sheet.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadEvents();
  }

  void _loadEvents() {
    final clubId = context.read<ClubSessionNotifier>().clubId;
    if (clubId != null) {
      _eventsFuture = EventsService.getEvents(clubId);
    } else {
      _eventsFuture = Future.value([]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ClubSessionNotifier>();
    final role = session.userRole ?? 'member';
    final canCreate = role == 'secretary' || role == 'founding_admin' || role == 'president';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Programs & Events', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Past'),
                  Tab(text: 'All'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final programs = snapshot.data ?? [];
          final now = DateTime.now();
          final upcoming = programs.where((p) {
            final start = DateTime.parse(p['start_datetime']);
            return start.isAfter(now);
          }).toList();

          final past = programs.where((p) {
            final start = DateTime.parse(p['start_datetime']);
            return start.isBefore(now);
          }).toList();

          // sort past events descending
          past.sort((a, b) => DateTime.parse(b['start_datetime']).compareTo(DateTime.parse(a['start_datetime'])));
          upcoming.sort((a, b) => DateTime.parse(a['start_datetime']).compareTo(DateTime.parse(b['start_datetime'])));

          List<Map<String, dynamic>> activeList;
          if (_tabController.index == 0) {
            activeList = upcoming;
          } else if (_tabController.index == 1) {
            activeList = past;
          } else {
            activeList = programs;
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _loadEvents()),
            color: AppColors.primary,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _EventList(
                key: ValueKey<int>(_tabController.index),
                events: activeList,
                isPast: _tabController.index == 1,
              ),
            ),
          );
        },
      ),
      floatingActionButton: canCreate
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
                  builder: (context) => const CreateEventSheet(),
                );
                if (result == true) {
                  setState(() {
                    _loadEvents();
                  });
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Program', style: TextStyle(fontWeight: FontWeight.bold)),
            ).animate().scale(delay: 500.ms, duration: 400.ms)
          : null,
    );
  }
}

class _EventList extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final bool isPast;

  const _EventList({super.key, required this.events, this.isPast = false});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/illusrtations_image/Empty.svg', height: 150),
            const SizedBox(height: 20),
            const Text('No programs found', style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
          ],
        ).animate().fadeIn(duration: 500.ms),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final prog = events[index];
        final startDt = DateTime.parse(prog['start_datetime']);
        final endDt = DateTime.parse(prog['end_datetime']);
        final isMultiDay = startDt.day != endDt.day || startDt.month != endDt.month;
        
        final dateStr = isMultiDay 
            ? '${DateFormat.MMMEd().format(startDt)} - ${DateFormat.MMMEd().format(endDt)}'
            : DateFormat.yMMMEd().format(startDt);
            
        final timeStr = '${DateFormat.jm().format(startDt)} - ${DateFormat.jm().format(endDt)}';
        final isPublished = prog['is_published'] == true;

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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        prog['title'] ?? 'Program',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        prog['category']?.toString().toUpperCase() ?? 'EVENT',
                        style: const TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(dateStr, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.access_time_rounded, size: 14, color: Colors.orange),
                    ),
                    const SizedBox(width: 8),
                    Text(timeStr, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.location_on_rounded, size: 14, color: Colors.green),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(prog['venue'] ?? 'TBD', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500))),
                  ],
                ),
                if (prog['description'] != null && prog['description'].isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(height: 1, color: Colors.black12),
                  ),
                  Text(
                    prog['description'], 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.4)
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isPublished)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.visibility_off, size: 14, color: Colors.orange),
                            SizedBox(width: 4),
                            Text('Internal', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.public, size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Public', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    OutlinedButton(
                      onPressed: () {
                        // TODO: View details, RSVP, attendance etc
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1);
      },
    );
  }
}
