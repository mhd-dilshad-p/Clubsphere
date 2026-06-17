import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import '../services/public_service.dart';
import '../../../core/widgets/web_media_embedder.dart';

const Color _navyPrimary = Color(0xFF0F172A);
const Color _blueAccent = Color(0xFF1E3A8A);
const Color _lightBg = Color(0xFFF8FAFC);
const Color _textGrey = Color(0xFF64748B);

class ClubPublicPastEventDetailsScreen extends StatefulWidget {
  final String clubId;
  final String eventId;

  const ClubPublicPastEventDetailsScreen({
    super.key,
    required this.clubId,
    required this.eventId,
  });

  @override
  State<ClubPublicPastEventDetailsScreen> createState() =>
      _ClubPublicPastEventDetailsScreenState();
}

class _ClubPublicPastEventDetailsScreenState extends State<ClubPublicPastEventDetailsScreen> {
  late Future<Map<String, dynamic>> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventFuture = PublicService.getPublicPastEvent(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _blueAccent));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final event = snapshot.data!;
          final imagesList = event['images'] as List<dynamic>? ?? [];
          
          final title = event['title']?.toString() ?? 'The Azure Gala';
          final description = event['description']?.toString() ?? 'The Azure Gala stands as the pinnacle of our social calendar, bringing together thought leaders, cultural pioneers, and sovereign members for an evening of unparalleled connection.';
          final category = 'SIGNATURE EVENT';
          final mapLink = event['map_link']?.toString();
          final venueName = event['venue_name']?.toString() ?? 'Event Location';
          final venueAddress = event['venue_address']?.toString() ?? '';
          
          DateTime? startDt;
          if (event['start_date'] != null) {
            startDt = DateTime.parse(event['start_date'].toString());
          }
          DateTime? endDt;
          if (event['end_date'] != null) {
            endDt = DateTime.parse(event['end_date'].toString());
          }
          final dateStr = startDt != null
              ? DateFormat('MMMM yyyy').format(startDt).toUpperCase()
              : 'OCTOBER 2024';

          final startTime = startDt != null ? DateFormat('h:mm a').format(startDt) : null;
          final endTime = endDt != null ? DateFormat('h:mm a').format(endDt) : null;

          final agendas = event['agendas'] as List<dynamic>? ?? [];
          final highlights = event['highlights'] as List<dynamic>? ?? [];
          final behindEvents = event['behind_events'] as List<dynamic>? ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildHeroSection(imagesList.cast<String>(), title, category, constraints.maxWidth);
                      }
                    ),
                    Positioned(
                      top: 16,
                      left: MediaQuery.of(context).size.width > 600 ? 48 : 24,
                      child: SafeArea(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.arrow_back, color: _navyPrimary, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width > 600 ? 48 : 24, 
                          vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Info Cards Row
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isLarge = constraints.maxWidth > 900;
                              if (isLarge) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 5, child: _buildAboutCard(description)),
                                    const SizedBox(width: 24),
                                    Expanded(flex: 3, child: _buildCalendarCard(dateStr, startDt, startTime, endTime)),
                                    const SizedBox(width: 24),
                                    Expanded(flex: 3, child: _buildVenueCard(mapLink, venueName, venueAddress)),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    _buildAboutCard(description),
                                    const SizedBox(height: 24),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _buildCalendarCard(dateStr, startDt, startTime, endTime, isMobile: true)),
                                        const SizedBox(width: 16),
                                        Expanded(child: _buildVenueCard(mapLink, venueName, venueAddress, isMobile: true)),
                                      ],
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 48),

                          // Event Agenda
                          if (agendas.isNotEmpty) ...[
                            _buildAgendaCard(agendas, title),
                            const SizedBox(height: 48),
                          ],

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isLarge = constraints.maxWidth > 800;
                              if (isLarge && highlights.isNotEmpty && behindEvents.isNotEmpty) {
                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _buildHighlightsSection(highlights)),
                                        const SizedBox(width: 48),
                                        Expanded(child: _buildBehindEventSection(behindEvents)),
                                      ],
                                    ),
                                    const SizedBox(height: 48),
                                  ]
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (highlights.isNotEmpty) ...[
                                    _buildHighlightsSection(highlights),
                                    const SizedBox(height: 48),
                                  ],
                                  if (behindEvents.isNotEmpty) ...[
                                    _buildBehindEventSection(behindEvents),
                                    const SizedBox(height: 48),
                                  ],
                                ],
                              );
                            }
                          ),
                          
                          // Legacy Gallery Section
                          if (imagesList.length > 1) ...[
                            _buildGallerySection(imagesList.sublist(1).cast<String>()),
                            const SizedBox(height: 80),
                          ],

                          // Footer

                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(List<String> images, String title, String category, double maxWidth) {
    bool isMobile = maxWidth < 600;
    return Container(
      width: double.infinity,
      height: isMobile ? 400 : 550,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(),
      child: Stack(
        children: [
          // Background Image Auto Slider
          Positioned.fill(
            child: _AutoSlidingHero(images: images),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    _blueAccent.withOpacity(0.5),
                    _navyPrimary.withOpacity(0.9),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          // Text Content
          Positioned(
            left: isMobile ? 24 : 48,
            bottom: isMobile ? 32 : 64,
            right: isMobile ? 24 : 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 32 : 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBase({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, color: _blueAccent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _navyPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildAboutCard(String description) {
    return _buildCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.info_outline, 'About the Event'),
          const SizedBox(height: 24),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: _textGrey,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(String dateStr, DateTime? startDt, String? startTime, String? endTime, {bool isMobile = false}) {
    final dayNumber = startDt != null ? startDt.day.toString() : '24';
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: _blueAccent, size: isMobile ? 20 : 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: _navyPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          // Calendar Grid
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['S','M','T','W','T','F','S'].map((d) => 
                    Text(d, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 12))
                  ).toList(),
                ),
                const SizedBox(height: 12),
                ..._buildCalendarRows(startDt, isMobile),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          // Time Pills
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
            decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.access_time, size: isMobile ? 14 : 16, color: _textGrey),
                const SizedBox(width: 8),
                Text('Starts', style: TextStyle(color: _textGrey, fontWeight: FontWeight.w600, fontSize: isMobile ? 12 : 14)),
                const Spacer(),
                Text(startTime ?? '19:00 PM', style: TextStyle(color: _navyPrimary, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
            decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.event_busy, size: isMobile ? 14 : 16, color: _textGrey),
                const SizedBox(width: 8),
                Text('Ends', style: TextStyle(color: _textGrey, fontWeight: FontWeight.w600, fontSize: isMobile ? 12 : 14)),
                const Spacer(),
                Text(endTime ?? '23:00 PM', style: TextStyle(color: _navyPrimary, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCalendarRows(DateTime? startDt, bool isMobile) {
    final now = DateTime.now();
    final targetMonth = startDt ?? DateTime(now.year, now.month);
    final firstDayOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
    final lastDayOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0);
    
    int startOffset = firstDayOfMonth.weekday % 7;
    int totalDays = lastDayOfMonth.day;
    
    List<Widget> rows = [];
    List<Widget> currentRow = [];
    
    for (int i = 0; i < startOffset; i++) {
      currentRow.add(_calDay('', isMobile: isMobile));
    }
    
    for (int day = 1; day <= totalDays; day++) {
      bool isHighlighted = startDt != null && startDt.day == day;
      currentRow.add(_calDay(day.toString(), isHighlighted: isHighlighted, isMobile: isMobile));
      
      if (currentRow.length == 7) {
        rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: currentRow,
        ));
        rows.add(const SizedBox(height: 12));
        currentRow = [];
      }
    }
    
    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) {
        currentRow.add(_calDay('', isMobile: isMobile));
      }
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: currentRow,
      ));
      rows.add(const SizedBox(height: 12));
    }
    
    return rows;
  }

  Widget _calDay(String day, {bool isHighlighted = false, bool isMobile = false}) {
    return Container(
      width: isMobile ? 22 : 28,
      height: isMobile ? 22 : 28,
      decoration: BoxDecoration(
        color: isHighlighted ? _blueAccent : Colors.transparent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        day,
        style: TextStyle(
          color: isHighlighted ? Colors.white : _navyPrimary,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          fontSize: isMobile ? 11 : 13,
        ),
      ),
    );
  }

  Widget _buildVenueCard(String? mapLink, String venueName, String venueAddress, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: (mapLink != null && mapLink.isNotEmpty && (mapLink.contains('<iframe') || mapLink.contains('google.com/maps/embed')))
                  ? WebMediaEmbedder(
                      url: mapLink,
                      mediaType: 'map',
                    )
                  :   Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF6F8FA),
                        ),
                        child: Transform.scale(
                          scale: 1.2,
                          child: Lottie.asset(
                            'assets/animations/map distance.json',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: _navyPrimary, size: isMobile ? 20 : 28),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  'Venue',
                  style: TextStyle(fontSize: isMobile ? 16 : 24, fontWeight: FontWeight.w600, color: _navyPrimary),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(venueName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: isMobile ? 16 : 20, color: _navyPrimary, height: 1.3)),
          if (venueAddress.isNotEmpty) ...[
            SizedBox(height: isMobile ? 4 : 6),
            Text(venueAddress, style: TextStyle(color: _textGrey, fontSize: isMobile ? 12 : 16, height: 1.4)),
          ],
          SizedBox(height: isMobile ? 16 : 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                if (mapLink != null && mapLink.isNotEmpty) {
                  final uri = Uri.tryParse(mapLink);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                }
              },
              icon: const Icon(Icons.map_outlined, size: 20),
              label: const Text('Open in Maps'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _navyPrimary,
                side: const BorderSide(color: _navyPrimary, width: 2.0),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaCard(List<dynamic> agendas, String eventTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: _navyPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_note, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Event Agenda', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: _navyPrimary)),
                  Text(eventTitle.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey, letterSpacing: 1.5)),
                ],
              ),
            )
          ]
        ),
        const SizedBox(height: 32),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: agendas.length,
          itemBuilder: (context, index) {
            return _buildAgendaTimelineItem(agendas[index] as Map<String, dynamic>, index, index == agendas.length - 1);
          },
        ),
      ],
    );
  }

  Widget _buildAgendaTimelineItem(Map<String, dynamic> ag, int index, bool isLast) {
    String timeStr = ag['time']?.toString() ?? '';
    String dateStr = ag['date']?.toString() ?? '';
    String displayTime = '';
    
    if (dateStr.isNotEmpty && timeStr.isNotEmpty) {
      displayTime = '$dateStr • $timeStr';
    } else if (dateStr.isNotEmpty) {
      displayTime = dateStr;
    } else {
      displayTime = timeStr;
    }

    final title = ag['title']?.toString() ?? '';
    final desc = ag['description']?.toString() ?? ag['desc']?.toString() ?? '';
    final dotsStr = ag['dots']?.toString() ?? '';
    
    List<Map<String, dynamic>> hosts = [];
    if (ag['hosts'] != null) {
      hosts = List<Map<String, dynamic>>.from(ag['hosts']);
    } else if ((ag['person_name']?.toString() ?? '').isNotEmpty) {
      hosts.add({
        'name': ag['person_name']?.toString(),
        'role': ag['person_role']?.toString(),
        'person_image_url': ag['person_image_url']?.toString(),
      });
    }

    String indexStr = (index + 1).toString().padLeft(2, '0');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Vertical line
        if (!isLast)
          Positioned(
            left: 23,
            top: 48,
            bottom: -32,
            child: Container(
              width: 2,
              color: _navyPrimary.withValues(alpha: 0.3),
            ),
          ),
        
        // Main Card
        Padding(
          padding: const EdgeInsets.only(left: 40, bottom: 32),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            child: hosts.length == 1 
                ? _buildSingleHostCardContent(title, displayTime, desc, dotsStr, hosts.first)
                : _buildMultiHostCardContent(title, displayTime, desc, dotsStr, hosts),
          ),
        ),

        // Circle index badge
        Positioned(
          left: 0,
          top: 24,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _navyPrimary, width: 2),
              boxShadow: [
                BoxShadow(color: _navyPrimary.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(4, 4)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(indexStr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _navyPrimary, fontStyle: FontStyle.italic)),
          ),
        ),
      ]
    );
  }

  Widget _buildSingleHostCardContent(String title, String displayTime, String desc, String dotsStr, Map<String, dynamic> host) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final hasImage = host['person_image_url'] != null && host['person_image_url'].toString().isNotEmpty;
        final isSmallImage = isMobile && dotsStr.isNotEmpty;

        Widget imageContent = Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: hasImage
            ? Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(host['person_image_url']),
                    fit: BoxFit.cover,
                  )
                ),
                child: _buildHostGradientOverlay(host, isSmall: isSmallImage),
              )
            : Container(
                color: _navyPrimary.withValues(alpha: 0.05),
                child: _buildHostGradientOverlay(host, isPlaceholder: true, isSmall: isSmallImage),
              ),
        );

        Widget textContent = Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _navyPrimary, borderRadius: BorderRadius.circular(20)),
                    child: Text(displayTime.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _navyPrimary, height: 1.2)),
                  )
                ]
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.5)),
              ],
              if (dotsStr.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, boxConstraints) {
                          final itemWidth = isMobile ? double.infinity : (boxConstraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: dotsStr.split('\n').where((s) => s.trim().isNotEmpty).map((dot) {
                              return Container(
                                width: itemWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Icon(Icons.circle, size: 8, color: _navyPrimary.withValues(alpha: 0.8)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(dot.trim(), style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 11, height: 1.4))),
                                  ]
                                )
                              );
                            }).toList()
                          );
                        }
                      )
                    ),
                    if (isMobile) ...[
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        height: 160,
                        child: imageContent,
                      ),
                    ]
                  ],
                )
              ]
            ]
          )
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              textContent,
              if (dotsStr.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                  child: SizedBox(
                    height: 260,
                    child: imageContent,
                  ),
                ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: textContent),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0, right: 16.0, left: 16.0),
              child: SizedBox(
                width: 200,
                height: 260,
                child: imageContent,
              ),
            ),
          ]
        );
      }
    );
  }

  Widget _buildHostGradientOverlay(Map<String, dynamic> host, {bool isPlaceholder = false, bool isSmall = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
          stops: const [0.5, 1.0]
        )
      ),
      alignment: Alignment.bottomLeft,
      padding: EdgeInsets.all(isSmall ? 12 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPlaceholder)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Icon(Icons.person, color: Colors.white54, size: isSmall ? 24 : 32),
            ),
          Text(host['name'] ?? '', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isSmall ? 12 : 15)),
          const SizedBox(height: 4),
          Text((host['role'] ?? '').toString().toUpperCase(), style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: isSmall ? 8 : 9, letterSpacing: 1)),
        ]
      )
    );
  }

  Widget _buildMultiHostCardContent(String title, String displayTime, String desc, String dotsStr, List<Map<String, dynamic>> hosts) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                child: Text(displayTime.toUpperCase(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _navyPrimary, height: 1.2)),
              )
            ]
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.5)),
          ],
          if (dotsStr.isNotEmpty) ...[
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, boxConstraints) {
                final isMobile = boxConstraints.maxWidth < 400;
                final itemWidth = isMobile ? double.infinity : (boxConstraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: dotsStr.split('\n').where((s) => s.trim().isNotEmpty).map((dot) {
                    return Container(
                      width: itemWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Icon(Icons.circle, size: 8, color: _navyPrimary.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(dot.trim(), style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 11, height: 1.4))),
                        ]
                      )
                    );
                  }).toList()
                );
              }
            )
          ],
          if (hosts.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text("FEATURED HOSTS", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: hosts.map((h) {
                return Container(
                  width: 130,
                  height: 180,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: (h['person_image_url'] != null && h['person_image_url'].toString().isNotEmpty)
                      ? Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(h['person_image_url']),
                              fit: BoxFit.cover,
                            )
                          ),
                          child: _buildHostGradientOverlay(h, isSmall: true),
                        )
                      : Container(
                          color: _navyPrimary.withValues(alpha: 0.05),
                          child: _buildHostGradientOverlay(h, isPlaceholder: true, isSmall: true),
                        ),
                );
              }).toList()
            )
          ]
        ]
      )
    );
  }

  Widget _buildHighlightsSection(List<dynamic> highlights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(width: 4, height: 40, color: _navyPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CURATED EXPERIENCES", style: TextStyle(color: _navyPrimary, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  const Text("Event Highlights", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
                ]
              ),
            ),
            TextButton(
              onPressed: () => context.go('/clubs/${widget.clubId}'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All', style: TextStyle(color: _navyPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: _navyPrimary, size: 16),
                ]
              )
            )
          ]
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: highlights.length,
          itemBuilder: (context, index) {
            final h = highlights[index];
            final hTitle = h['title'] ?? '';
            final hMedia = h['media'] as List<dynamic>? ?? [];
            
            String bgUrl = 'https://images.unsplash.com/photo-1511556532299-8f662fc26c06?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80';
            if (hMedia.isNotEmpty) {
              bgUrl = hMedia.first['url']?.toString() ?? bgUrl;
            }

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1), 
                    blurRadius: 10, 
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hMedia.isNotEmpty
                      ? _AutoRotatingHighlight(media: hMedia)
                      : _ImageOrVideoEmbedder(url: bgUrl, fit: BoxFit.cover),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8), Colors.black],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Text(
                      hTitle,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBehindEventSection(List<dynamic> behindEvents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 4, height: 40, color: _navyPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("THE TEAM", style: TextStyle(color: _navyPrimary, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  const Text("Behind the Event", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('The dedicated team and individuals who made this event possible.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ]
              ),
            ),
          ]
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: behindEvents.length,
          itemBuilder: (context, index) {
            final be = behindEvents[index];
            final String name = be['name'] ?? '';
            final String role = be['role'] ?? '';
            final String? imageUrl = be['image_url'];

            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300),
                    )
                  else
                    Container(color: Colors.grey.shade300, child: const Icon(Icons.person, size: 48, color: Colors.grey)),
                  
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                            Colors.black,
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  Positioned(
                    left: 20,
                    bottom: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (role.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            role.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 1
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGallerySection(List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Club Legacy Gallery',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _navyPrimary, fontFamily: 'Georgia'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/clubs/${widget.clubId}'),
              icon: const Text('More Events', style: TextStyle(color: _blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              label: const Icon(Icons.arrow_forward_rounded, color: _blueAccent, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Moments from our historical gatherings.', style: TextStyle(color: _textGrey)),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final isLarge = constraints.maxWidth > 800;
            return StaggeredGrid.count(
              crossAxisCount: isLarge ? 4 : 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: List.generate(images.length, (index) {
                final mediaUrl = images[index];
                // Pattern for bento box
                int crossAxis = 1;
                int mainAxis = 1;
                if (index % 5 == 0) {
                  crossAxis = 2; mainAxis = 2;
                } else if (index % 5 == 3) {
                  crossAxis = 2; mainAxis = 1;
                }

                return StaggeredGridTile.count(
                  crossAxisCellCount: isLarge ? crossAxis : 1,
                  mainAxisCellCount: isLarge ? mainAxis : 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _ImageOrVideoEmbedder(url: mediaUrl, fit: BoxFit.cover),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

}

class _ImageOrVideoEmbedder extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const _ImageOrVideoEmbedder({required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final isVideo = ['mp4', 'mov', 'avi', 'webm', 'mkv'].any((ext) => url.toLowerCase().endsWith(ext));
    if (isVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          WebMediaEmbedder(url: url, mediaType: 'video'),
          Container(
            color: Colors.black26,
            child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48)),
          ),
        ],
      );
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300),
    );
  }
}

class _AutoSlidingHero extends StatefulWidget {
  final List<String> images;

  const _AutoSlidingHero({required this.images});

  @override
  State<_AutoSlidingHero> createState() => _AutoSlidingHeroState();
}

class _AutoSlidingHeroState extends State<_AutoSlidingHero> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    if (widget.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        if (_currentPage < widget.images.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(color: _navyPrimary);
    }
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.images.length,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (idx) {
        _currentPage = idx;
      },
      itemBuilder: (context, index) {
        final url = widget.images[index];
        return _ImageOrVideoEmbedder(url: url, fit: BoxFit.cover);
      },
    );
  }
}

class _AutoRotatingHighlight extends StatefulWidget {
  final List<dynamic> media;
  const _AutoRotatingHighlight({required this.media});

  @override
  State<_AutoRotatingHighlight> createState() => _AutoRotatingHighlightState();
}

class _AutoRotatingHighlightState extends State<_AutoRotatingHighlight> {
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.media.length * 100);
    
    if (widget.media.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) {
      return Container();
    }
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(), // Only auto scroll
      itemBuilder: (context, index) {
        final actualIndex = index % widget.media.length;
        final mUrl = widget.media[actualIndex]['url']?.toString() ?? '';
        return _ImageOrVideoEmbedder(url: mUrl, fit: BoxFit.cover);
      },
    );
  }
}


