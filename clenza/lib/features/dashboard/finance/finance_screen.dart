import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/club_session_provider.dart';
import 'finance_service.dart';
import 'add_finance_sheet.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _financeFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadEntries();
  }

  void _loadEntries() {
    final session = context.read<ClubSessionNotifier>();
    if (session.clubId != null) {
      _financeFuture = FinanceService.getFinanceEntries(session.clubId!, session.userRole ?? 'member');
    } else {
      _financeFuture = Future.value([]);
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

    final canAddFinance = role == 'treasurer' || role == 'founding_admin';
    final canApprove = role == 'president' || role == 'founding_admin';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Finance & Accounts', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Tab(text: 'Income'),
                  Tab(text: 'Expenditure'),
                  Tab(text: 'Pending'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _financeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final entries = snapshot.data ?? [];
          final income = entries.where((e) => e['type'] == 'income' && e['status'] == 'approved').toList();
          final expenditure = entries.where((e) => e['type'] == 'expenditure' && e['status'] == 'approved').toList();
          final pending = entries.where((e) => e['status'] == 'pending_approval').toList();

          double totalIncome = income.fold(0, (sum, e) => sum + (e['amount'] as num).toDouble());
          double totalExp = expenditure.fold(0, (sum, e) => sum + (e['amount'] as num).toDouble());
          double balance = totalIncome - totalExp;

          return RefreshIndicator(
            onRefresh: () async => setState(() => _loadEntries()),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  if (role != 'member')
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryItem(title: 'Income', amount: totalIncome, color: Colors.greenAccent),
                          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                          _SummaryItem(title: 'Expenditure', amount: totalExp, color: Colors.redAccent),
                          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                          _SummaryItem(title: 'Balance', amount: balance, color: Colors.white),
                        ],
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOutQuart),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Builder(
                      key: ValueKey<int>(_tabController.index),
                      builder: (context) {
                        List<Map<String, dynamic>> activeList;
                        if (_tabController.index == 0) {
                          activeList = income;
                        } else if (_tabController.index == 1) {
                          activeList = expenditure;
                        } else {
                          activeList = pending;
                        }
                        
                        return _FinanceList(
                          entries: activeList,
                          isPending: _tabController.index == 2,
                          canApprove: canApprove,
                          onStatusUpdated: () => setState(() => _loadEntries()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: canAddFinance
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
                  builder: (context) => const AddFinanceSheet(),
                );
                if (result == true) {
                  setState(() {
                    _loadEntries();
                  });
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Entry', style: TextStyle(fontWeight: FontWeight.bold)),
            ).animate().scale(delay: 500.ms, duration: 400.ms)
          : null,
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _SummaryItem({required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(
          '₹${NumberFormat('#,##,###').format(amount)}', 
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }
}

class _FinanceList extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final bool isPending;
  final bool canApprove;
  final VoidCallback? onStatusUpdated;

  const _FinanceList({
    required this.entries,
    this.isPending = false,
    this.canApprove = false,
    this.onStatusUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/illusrtations_image/Empty.svg', height: 150),
              const SizedBox(height: 20),
              Text(
                isPending ? 'No pending entries' : 'No entries found', 
                style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)
              ),
            ],
          ).animate().fadeIn(duration: 500.ms),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isIncome = entry['type'] == 'income';
        final dateStr = entry['transaction_date'] != null
            ? DateFormat.yMMMd().format(DateTime.parse(entry['transaction_date']))
            : '';
        final createdBy = entry['club_members']?['full_name'] ?? 'Unknown';

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
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isIncome ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry['category'] ?? 'Category',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isIncome ? '+' : '-'}₹${NumberFormat('#,##,###').format(entry['amount'])}',
                      style: TextStyle(
                          color: isIncome ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(entry['description'] ?? '', style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('$dateStr • By $createdBy', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Pending', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                if (isPending && canApprove) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(height: 1, color: Colors.black12),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await FinanceService.updateStatus(entry['id'], 'rejected');
                          onStatusUpdated?.call();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await FinanceService.updateStatus(entry['id'], 'approved');
                          onStatusUpdated?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
      },
    );
  }
}
