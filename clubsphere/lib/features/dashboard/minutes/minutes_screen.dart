import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/club_session_provider.dart';
import 'minutes_service.dart';
import 'add_minutes_sheet.dart';

class MeetingMinutesScreen extends StatefulWidget {
  const MeetingMinutesScreen({super.key});

  @override
  State<MeetingMinutesScreen> createState() => _MeetingMinutesScreenState();
}

class _MeetingMinutesScreenState extends State<MeetingMinutesScreen> {
  late Future<List<Map<String, dynamic>>> _minutesFuture;

  @override
  void initState() {
    super.initState();
    _loadMinutes();
  }

  void _loadMinutes() {
    final session = context.read<ClubSessionNotifier>();
    if (session.clubId != null) {
      _minutesFuture = MinutesService.getMinutes(session.clubId!, session.userRole ?? 'member');
    } else {
      _minutesFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<ClubSessionNotifier>().userRole;
    final canAdd = userRole == 'founding_admin' || userRole == 'secretary';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Meeting Minutes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _minutesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final minutes = snapshot.data ?? [];
          if (minutes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/illusrtations_image/Empty.svg', height: 150),
                  const SizedBox(height: 20),
                  const Text('No meeting minutes found', style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ).animate().fadeIn(duration: 500.ms),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _loadMinutes()),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: minutes.length,
              itemBuilder: (context, index) {
                final m = minutes[index];
                final dateStr = m['meeting_date'] != null ? DateFormat.yMMMEd().format(DateTime.parse(m['meeting_date'])) : '';
                final isPublished = m['is_published'] == true;

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
                    padding: const EdgeInsets.all(20),
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
                                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(m['title'] ?? 'Meeting', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPublished ? Colors.green.shade50 : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(isPublished ? Icons.public : Icons.visibility_off, size: 12, color: isPublished ? Colors.green : Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(isPublished ? 'PUBLISHED' : 'DRAFT', style: TextStyle(fontSize: 10, color: isPublished ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(dateStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1, color: Colors.black12),
                        ),
                        Text(
                          m['content'] ?? '', 
                          maxLines: 3, 
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                                        child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(m['title'] ?? 'Meeting', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                                    ],
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Date: $dateStr', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 12.0),
                                          child: Divider(),
                                        ),
                                        Text(m['content'] ?? '', style: const TextStyle(height: 1.5)),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context), 
                                      child: const Text('Close', style: TextStyle(color: Colors.grey))
                                    )
                                  ],
                                ).animate().scale(duration: 200.ms, curve: Curves.easeOutQuart),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text('Read Full Minutes', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1);
              },
            ),
          );
        },
      ),
      floatingActionButton: canAdd
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
                  builder: (context) => const AddMinutesSheet()
                );
                if (result == true) {
                  setState(() {
                    _loadMinutes();
                  });
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Minutes', style: TextStyle(fontWeight: FontWeight.bold)),
            ).animate().scale(delay: 500.ms, duration: 400.ms)
          : null,
    );
  }
}
