import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/public_service.dart';

const Color _navyPrimary = Color(0xFF0F172A);
const Color _blueAccent = Color(0xFF1E3A8A);
const Color _lightBg = Color(0xFFF8FAFC);
const Color _textGrey = Color(0xFF64748B);

class ClubPublicEventDetailsScreen extends StatefulWidget {
  final String clubId;
  final String eventId;

  const ClubPublicEventDetailsScreen({
    super.key,
    required this.clubId,
    required this.eventId,
  });

  @override
  State<ClubPublicEventDetailsScreen> createState() =>
      _ClubPublicEventDetailsScreenState();
}

class _ClubPublicEventDetailsScreenState
    extends State<ClubPublicEventDetailsScreen> {
  late Future<Map<String, dynamic>> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventFuture = PublicService.getPublicProgram(widget.eventId);
  }

  Future<void> _openGoogleMaps(String query) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final event = snapshot.data!;
          final coverUrl = event['cover_image_url']?.toString() ?? '';
          final title = event['title']?.toString() ?? 'Event Title';
          final description = event['description']?.toString() ??
              'Join us for an exclusive gathering bringing together thought leaders and pioneers. Experience a curated evening of unparalleled connection.';
          final category = event['category']?.toString().toUpperCase() ?? 'SIGNATURE EVENT';
          final venueName = event['venue_name']?.toString() ?? event['venue']?.toString() ?? 'The Glass Pavilion, NYC';
          final venueAddress = event['venue_address']?.toString() ?? '';

          DateTime? startDt;
          if (event['start_datetime'] != null) {
            startDt = DateTime.parse(event['start_datetime'].toString());
          }
          DateTime? endDt;
          if (event['end_datetime'] != null) {
            endDt = DateTime.parse(event['end_datetime'].toString());
          }

          final dateStr = startDt != null
              ? DateFormat('MMMM d, yyyy').format(startDt)
              : 'Date TBA';
          final timeStr = startDt != null
              ? '${DateFormat('HH:mm').format(startDt)}${endDt != null ? ' - ${DateFormat('HH:mm').format(endDt)}' : ''}'
              : 'Time TBA';

          return CustomScrollView(
            slivers: [
              _buildHeroSection(coverUrl, title, category, dateStr, venueName, timeStr),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _buildLeftColumn(description),
                          ),
                          const SizedBox(width: 48),
                          Expanded(
                            flex: 4,
                            child: _buildRightColumn(venueName, venueAddress),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Legacy Section
              SliverToBoxAdapter(
                child: _buildLegacySection(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(String coverUrl, String title, String category,
      String dateStr, String venue, String timeStr) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 500,
        child: Stack(
          children: [
            Positioned.fill(
              child: coverUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: _navyPrimary),
                    )
                  : Container(color: _navyPrimary),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      _navyPrimary.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 600 ? 24 : 48, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sovereign Social',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width < 600 ? 24 : 48, 
                      vertical: MediaQuery.of(context).size.width < 600 ? 24 : 48
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _blueAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width < 600 ? 28 : 48,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 24,
                          runSpacing: 12,
                          children: [
                            _IconText(Icons.calendar_today, dateStr),
                            _IconText(Icons.location_on, venue),
                            _IconText(Icons.access_time, timeStr),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About the Event',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _navyPrimary),
              ),
              const SizedBox(height: 24),
              Text(
                description,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.6),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DRESS CODE', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                        const SizedBox(height: 8),
                        const Text('Black Tie & Azure Accents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navyPrimary)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RSVP STATUS', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('Confirmed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navyPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Event Agenda',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _navyPrimary),
              ),
              const SizedBox(height: 32),
              _buildAgendaItem('19:00', 'Champagne Reception', 'Networking and artisanal appetizers in the South Terrace.'),
              _buildAgendaItem('20:30', 'Gala Dinner & Keynote', 'A four-course culinary journey with insights from our founding members.'),
              _buildAgendaItem('22:00', 'Digital Art Reveal & Cocktails', 'The unveiling of Sovereign Canvas with curated nightcaps.', isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn(String venueName, String venueAddress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
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
                  child: Container(
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
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: _navyPrimary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Venue',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _navyPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(venueName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: _navyPrimary, height: 1.3)),
              if (venueAddress.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(venueAddress, style: const TextStyle(color: _textGrey, fontSize: 16, height: 1.4)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openGoogleMaps('$venueName, $venueAddress'),
                  icon: const Icon(Icons.directions, size: 20),
                  label: const Text('Get Directions'),
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
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HOSTED BY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                  const SizedBox(height: 4),
                  const Text('Elena Vance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navyPrimary)),
                  Text('Event Director', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _navyPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Modify RSVP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _navyPrimary,
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Invite a Guest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaItem(String time, String title, String desc, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 60,
            child: Text(time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          ),
          Column(
            children: [
              Container(width: 12, height: 12, decoration: const BoxDecoration(color: _blueAccent, shape: BoxShape.circle)),
              if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navyPrimary)),
                  const SizedBox(height: 8),
                  Text(desc, style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacySection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 48),
      color: _lightBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gala Legacy', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _navyPrimary)),
                  const SizedBox(height: 8),
                  Text('Reflecting on our previous annual gatherings.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Row(
                  children: [
                    Text('View Full Archive', style: TextStyle(color: _blueAccent, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16, color: _blueAccent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 260,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildLegacyCard('2023 EDITION', 'The Gilded Symposium', 'https://images.unsplash.com/photo-1519671482749-fd09871171dd?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'),
                const SizedBox(width: 24),
                _buildLegacyCard('2022 EDITION', 'Veridian Night Rooftop', 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'),
                const SizedBox(width: 24),
                _buildLegacyCard('2021 EDITION', 'Prism of Sovereignty', 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyCard(String year, String title, String imageUrl) {
    return SizedBox(
      width: 340,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl.isNotEmpty ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ) : Container(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 16),
          Text(year, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navyPrimary)),
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconText(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}
