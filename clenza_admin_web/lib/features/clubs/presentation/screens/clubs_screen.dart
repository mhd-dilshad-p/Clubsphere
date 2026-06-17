import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/components/admin_layout.dart';
import '../../../../core/components/status_badge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../approvals/data/repositories/club_repository.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  late Future<List<Map<String, dynamic>>> _clubsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  void _loadClubs() {
    setState(() {
      _clubsFuture = context.read<ClubRepository>().getAllClubs();
    });
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
              'Master Directory',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search clubs by name...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const Spacer(flex: 3),
                ElevatedButton.icon(
                  onPressed: _loadClubs,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _clubsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading clubs: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
                  }

                  final allClubs = snapshot.data ?? [];
                  final filteredClubs = allClubs.where((club) {
                    final name = (club['name'] ?? '').toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();

                  if (filteredClubs.isEmpty) {
                    return const Center(
                      child: Text('No clubs found.', style: TextStyle(color: AppColors.textSecondary)),
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
                          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          columns: const [
                            DataColumn(label: Text('Club ID')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Created Date')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filteredClubs.map((club) {
                            final createdAt = club['created_at'] != null 
                              ? DateTime.tryParse(club['created_at']) 
                              : null;
                              
                            final formattedDate = createdAt != null 
                              ? DateFormat('MMM d, yyyy').format(createdAt) 
                              : 'Unknown';

                            return DataRow(
                              cells: [
                                DataCell(Text((club['id'] ?? '').toString().substring(0, 8))),
                                DataCell(Text(club['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Text(club['club_type'] ?? 'General')),
                                DataCell(Text(formattedDate)),
                                DataCell(StatusBadge(status: club['status'] ?? 'unknown')),
                                DataCell(
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'suspend') {
                                        await context.read<ClubRepository>().suspendClub(club['id']);
                                        _loadClubs();
                                      } else if (value == 'approve' && club['status'] != 'approved') {
                                        await context.read<ClubRepository>().approveClub(club['id']);
                                        _loadClubs();
                                      }
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        if (club['status'] != 'approved')
                                          const PopupMenuItem(value: 'approve', child: Text('Approve')),
                                        if (club['status'] != 'suspended')
                                          const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
                                      ];
                                    },
                                    icon: const Icon(Icons.more_vert),
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
