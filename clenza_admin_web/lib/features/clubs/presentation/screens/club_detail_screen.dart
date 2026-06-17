import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../dashboard/data/providers/admin_provider.dart';
import '../widgets/club_elections_section.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'dart:ui' as ui;

class ClubDetailScreen extends StatefulWidget {
  final Map<String, dynamic> clubData;

  const ClubDetailScreen({super.key, required this.clubData});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  late final String mapId;
  late String currentStatus;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.clubData['verification_status'] ?? 'pending';
    mapId = 'map-iframe-${widget.clubData['id']}';
    
    // Register the Google Maps iframe view
    ui_web.platformViewRegistry.registerViewFactory(
      mapId,
      (int viewId) => html.IFrameElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..src = 'https://maps.google.com/maps?q=${Uri.encodeComponent([
            widget.clubData['address_line1'],
            widget.clubData['area'],
            widget.clubData['city'],
            widget.clubData['state']
          ].where((e) => e != null && e.toString().isNotEmpty).join(','))}&t=&z=13&ie=UTF8&iwloc=&output=embed',
    );
  }

  void _updateStatus(String newStatus) async {
    setState(() => isProcessing = true);
    final provider = context.read<AdminProvider>();
    final success = await provider.updateClubStatus(widget.clubData['id'], newStatus);
    
    if (success && mounted) {
      setState(() {
        currentStatus = newStatus;
        isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${newStatus.toUpperCase()}')),
      );
    } else {
      setState(() => isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _deleteClub() async {
    setState(() => isProcessing = true);
    final provider = context.read<AdminProvider>();
    final success = await provider.deleteClub(widget.clubData['id']);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Club permanently deleted')),
      );
      Navigator.pop(context); // Go back to clubs list
    } else {
      setState(() => isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete club'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return AppColors.success;
      case 'suspended': return AppColors.warning;
      case 'rejected':
      case 'deleted': return AppColors.error;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Edge-to-Edge Hero Header
                _buildHeroHeader(context),
                
                // 2. Main Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 7, child: _buildMainContent()),
                                const SizedBox(width: 64),
                                Expanded(flex: 3, child: _buildRightSidebar()),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildMainContent(),
                                const SizedBox(height: 48),
                                _buildRightSidebar(),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final logoUrl = widget.clubData['logo_url']?.toString();
    final coverUrl = widget.clubData['cover_image_url']?.toString();
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;

    return SizedBox(
      height: 250,
      width: double.infinity,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: hasCover
                ? Image.network(coverUrl, fit: BoxFit.cover)
                : (hasLogo 
                    ? Image.network(logoUrl, fit: BoxFit.cover) 
                    : Container(color: AppColors.primary.withValues(alpha: 0.2))),
          ),
          // Gradient and Blur Overlay
          Positioned.fill(
            child: hasCover
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.darkBg.withValues(alpha: 0.8),
                          AppColors.darkBg,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                  )
                : BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black54,
                            AppColors.darkBg.withValues(alpha: 0.8),
                            AppColors.darkBg,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
          ),
          // Prominent Logo and Title
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar Logo
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(color: Colors.white38, width: 3),
                        image: hasLogo ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover) : null,
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10)),
                        ],
                      ),
                      child: !hasLogo ? const Icon(Icons.groups, size: 40, color: Colors.white54) : null,
                    ),
                    const SizedBox(width: 24),
                    // Title and Tags
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildGlassBadge((widget.clubData['category'] ?? widget.clubData['club_type'] ?? 'General').toString().toUpperCase(), Icons.category),
                              _buildGlassBadge('Status: ${currentStatus.toUpperCase()}', Icons.info_outline, color: _getStatusColor(currentStatus)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.clubData['name'] ?? 'Unnamed Club',
                            style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Administrative Overview',
                            style: AppTextStyles.title.copyWith(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBadge(String text, IconData icon, {Color color = Colors.white}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description Block - Massive and clear
        Text('About the Club', style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Text(
            widget.clubData['description'] ?? 'No description provided for this club. Please update the club profile to add an overview of their mission and activities.',
            style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.9), height: 1.8, fontSize: 16),
          ),
        ),
        const SizedBox(height: 32),

        // Overview / Stats
        Text('Overview', style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildOverviewGrid(),
        const SizedBox(height: 24),
        _buildFullGlassCalendarMonth(widget.clubData['founding_date']?.toString()),
        
        const SizedBox(height: 32),
        
        // Location
        Text('Headquarters Location', style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildLocationMap(),
      ],
    );
  }

  Widget _buildOverviewGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          children: [
            _buildOverviewCard(Icons.category, 'Category', (widget.clubData['category'] ?? widget.clubData['club_type'] ?? 'General').toString().toUpperCase()),
            _buildOverviewCard(Icons.groups, 'Total Members', '${widget.clubData['total_members'] ?? '0'}'),
          ],
        );
      }
    );
  }

  Widget _buildOverviewCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontSize: 13, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(value, style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullGlassCalendarMonth(String? dateStr) {
    DateTime date;
    try {
      date = dateStr != null ? DateTime.parse(dateStr).toLocal() : DateTime(2014, 5, 12);
    } catch (e) {
      date = DateTime(2014, 5, 12);
    }

    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(date.year, date.month);
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    // Sunday-first calendar
    final startOffset = startingWeekday == 7 ? 0 : startingWeekday;
    
    final List<Widget> dayWidgets = [];
    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    
    for (var w in weekdays) {
      dayWidgets.add(
        Center(child: Text(w, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11))),
      );
    }
    
    // Previous month trailing dates
    final prevMonth = DateTime(date.year, date.month - 1, 1);
    final daysInPrevMonth = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);
    for (int i = 0; i < startOffset; i++) {
      final prevDay = daysInPrevMonth - startOffset + i + 1;
      dayWidgets.add(
        Center(
          child: Text(
            prevDay.toString(),
            style: const TextStyle(color: Colors.white24, fontSize: 14),
          ),
        ),
      );
    }
    
    // Current month dates
    for (int i = 1; i <= daysInMonth; i++) {
      final isSelected = i == date.day;
      dayWidgets.add(
        Center(
          child: isSelected 
              ? Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.white38, blurRadius: 8, spreadRadius: 0)],
                  ),
                  child: Center(
                    child: Text(
                      i.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : Text(
                  i.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
        ),
      );
    }

    // Next month trailing dates
    final totalCells = startOffset + daysInMonth;
    final slotsToFill = (7 - (totalCells % 7)) % 7;
    for (int i = 1; i <= slotsToFill; i++) {
      dayWidgets.add(
        Center(
          child: Text(
            i.toString(),
            style: const TextStyle(color: Colors.white24, fontSize: 14),
          ),
        ),
      );
    }

    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: -2),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(34),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.calendar_today, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Established Date', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontSize: 13, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text('${months[date.month - 1]} ${date.day}, ${date.year}', style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: -5),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header: <  Month Year  >
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.chevron_left, color: Colors.white70, size: 24),
                            Text(
                              '${months[date.month - 1]} ${date.year}',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white70, size: 24),
                          ],
                        ),
                        const SizedBox(height: 24),
                        GridView.count(
                          crossAxisCount: 7,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.0,
                          children: dayWidgets,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: HtmlElementView(viewType: mapId),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registered Address', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      [
                        widget.clubData['address_line1'],
                        widget.clubData['address_line2'],
                        widget.clubData['area'],
                        widget.clubData['city'],
                        widget.clubData['state'],
                      ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', '),
                      style: AppTextStyles.body.copyWith(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.clubData['club_code'] != null) ...[
          _buildLottieBubbleButton(
            label: 'Copy Club ID: ${widget.clubData['club_code']}',
            lottieAsset: 'assets/animations/club_ID.json',
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.clubData['club_code'].toString()));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Club ID copied to clipboard!')));
            },
            circleColor: Colors.blueAccent,
          ),
          const SizedBox(height: 48),
        ],
        // Administrative Actions
        Text('Actions', style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildSidebarActionsCard(),
        
        const SizedBox(height: 48),
        
        // Leadership
        Text('Club Members', style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildSidebarLeadershipCard(),
        
        const SizedBox(height: 48),
        
        // Elections
        Text('Elections & Voting', style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ClubElectionsSection(clubId: widget.clubData['id'].toString()),
      ],
    );
  }

  Widget _buildSidebarActionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (currentStatus == 'pending' || currentStatus == 'suspended' || currentStatus == 'rejected') ...[
            _buildGlassButton('Approve Club', Icons.check_circle, AppColors.success, () => _updateStatus('active')),
            const SizedBox(height: 16),
          ],
          if (currentStatus == 'active' || currentStatus == 'verified') ...[
            _buildGlassButton('Suspend Club', Icons.pause_circle_outline, AppColors.warning, () => _updateStatus('suspended')),
            const SizedBox(height: 16),
            _buildGlassButton('Request Info', Icons.info_outline, Colors.white, () {}, outlined: true),
            const SizedBox(height: 16),
          ],
          if (currentStatus != 'rejected') ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text('OR', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2))),
            ),
            _buildGlassButton('Reject / Remove', Icons.cancel_outlined, AppColors.error, () => _updateStatus('rejected'), outlined: true),
          ],
          if (currentStatus == 'rejected') ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text('OR', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2))),
            ),
            _buildGlassButton('Delete Permanently', Icons.delete_forever, AppColors.error, () => _deleteClub()),
          ],
        ],
      ),
    );
  }

  Widget _buildGlassButton(String label, IconData icon, Color color, VoidCallback onPressed, {bool outlined = false}) {
    return isProcessing
        ? const Center(child: CircularProgressIndicator())
        : ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: outlined ? Colors.transparent : color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: color.withValues(alpha: outlined ? 0.3 : 0.5), width: outlined ? 1 : 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildSidebarLeadershipCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client
            .from('club_members')
            .select()
            .eq('club_id', widget.clubData['id'])
            .order('role')
            .limit(10),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final leaders = snapshot.data ?? [];
          if (leaders.isEmpty) return const Text('No leadership assigned.', style: TextStyle(color: AppColors.textSecondary));
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...leaders.map((leader) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.darkBg,
                      backgroundImage: leader['avatar_url'] != null ? NetworkImage(leader['avatar_url']) : null,
                      child: leader['avatar_url'] == null ? const Icon(Icons.person, color: Colors.white54, size: 28) : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(leader['full_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text((leader['role'] ?? '').toString().toUpperCase(), style: TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildLottieBubbleButton(
                      label: 'Message Leadership',
                      lottieAsset: 'assets/animations/message.json',
                      onTap: () {},
                      circleColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  Widget _buildLottieBubbleButton({
    required String label,
    required String lottieAsset,
    required VoidCallback onTap,
    required Color circleColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: -2),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: circleColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: Lottie.asset(
                  lottieAsset,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
