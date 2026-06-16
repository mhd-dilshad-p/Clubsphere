import 'package:clubsphere/core/widgets/web_media_embedder.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/public_service.dart';

const Color _navyPrimary = Color(0xFF0F172A);
const Color _blueAccent = Color(0xFF1E3A8A);
const Color _lightBg = Color(0xFFF8FAFC);

class ClubPublicProfileScreen extends StatefulWidget {
  final String id;
  final String? initialTab;
  const ClubPublicProfileScreen({super.key, required this.id, this.initialTab});

  @override
  State<ClubPublicProfileScreen> createState() =>
      _ClubPublicProfileScreenState();
}

class _ClubPublicProfileScreenState extends State<ClubPublicProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  late String _activeTab;
  String _selectedFilter = 'All Years';

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab ?? 'About Us';
    _profileFuture = PublicService.getClubProfile(widget.id);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _navyPrimary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final club = data['club'];
          final programs = data['programs'] as List<dynamic>? ?? [];
          final pastEvents = data['past_events'] as List<dynamic>? ?? [];
          final gallery = data['gallery'] as List<dynamic>? ?? [];
          final leadership = data['leadership'] as List<dynamic>? ?? [];

          final logoUrl = club['logo_url']?.toString() ?? '';
          final name = (club['name']?.toString().isNotEmpty == true)
              ? club['name'].toString()
              : 'Sovereign Social';
          final description = (club['description']?.toString().isNotEmpty == true)
              ? club['description'].toString()
              : 'The intersection of professional excellence and exclusive leisure. A private community for the modern sovereign individual.';
          
          final locationQuery = '${club['address_line1'] ?? ''}, ${club['city'] ?? ''}, ${club['district'] ?? ''}'.trim();
          final foundedDate = club['founding_date'] != null ? DateTime.tryParse(club['founding_date'].toString()) : null;
          final coverUrl = club['cover_image_url']?.toString() ?? '';

          return CustomScrollView(
            slivers: [
              _buildTopNav(name, logoUrl),
              
              if (_activeTab == 'About Us') ...[
              SliverToBoxAdapter(
                child: SizedBox(
                  width: double.infinity,
                  height: 700,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (gallery.isNotEmpty)
                        _AutoRotatingGallery(images: gallery.map((e) => (e is Map ? e['image_url']?.toString() ?? '' : e.toString())).where((url) => url.isNotEmpty).toList())
                      else if (coverUrl.isNotEmpty)
                        Image.network(coverUrl, fit: BoxFit.cover)
                      else
                        Container(color: _navyPrimary),
                        
                      Container(color: Colors.black.withValues(alpha: 0.6)),
                      
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 64, right: 64, bottom: 48),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                    height: 1.2,
                                    shadows: [
                                      Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)],
                                ),
                                child: ClipOval(
                                  child: logoUrl.isNotEmpty
                                      ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.business, size: 60, color: Colors.grey))
                                      : const Icon(Icons.business, size: 80, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 64),
                          
                          // Bento Grid Layout
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final bool isLarge = constraints.maxWidth > 900;
                              return StaggeredGrid.count(
                                crossAxisCount: 4,
                                mainAxisSpacing: 24,
                                crossAxisSpacing: 24,
                                children: [
                                  // About the Club
                                  StaggeredGridTile.fit(
                                    crossAxisCellCount: isLarge ? 2 : 4,
                                    child: _buildBentoAboutCard(description),
                                  ),
                                  // Map Card
                                  StaggeredGridTile.fit(
                                    crossAxisCellCount: isLarge ? 2 : 4,
                                    child: _buildMapCard(locationQuery.isNotEmpty ? locationQuery : '42 Sovereign Pass, London, UK'),
                                  ),
                                  // Vision
                                  StaggeredGridTile.fit(
                                    crossAxisCellCount: isLarge ? 1 : 2,
                                    child: _buildInfoCard(Icons.visibility, 'Our Vision', club['vision']?.toString().isNotEmpty == true ? club['vision'].toString() : 'To become the global gold standard for hybrid social-professional environments.'),
                                  ),
                                  // Mission
                                  StaggeredGridTile.fit(
                                    crossAxisCellCount: isLarge ? 1 : 2,
                                    child: _buildInfoCard(Icons.flag, 'Our Mission', club['mission']?.toString().isNotEmpty == true ? club['mission'].toString() : 'To curate exceptional experiences and facilitate deep networks.'),
                                  ),
                                  // Founded Date
                                  StaggeredGridTile.fit(
                                    crossAxisCellCount: isLarge ? 2 : 4,
                                    child: _buildCalendarCard(foundedDate),
                                  ),
                                ],
                              );
                            }
                          ),
                        const SizedBox(height: 80),

                        // Upcoming Events
                        if (programs.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Upcoming & Recent', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _navyPrimary)),
                                  const SizedBox(height: 4),
                                  Text('A glimpse into our exclusive programming', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                                ],
                              ),
                              TextButton(
                                onPressed: () => setState(() => _activeTab = 'Events'),
                                child: const Row(
                                  children: [
                                    Text('View All Events', style: TextStyle(color: _blueAccent, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 16, color: _blueAccent),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final bool isLarge = constraints.maxWidth > 900;
                              return StaggeredGrid.count(
                                crossAxisCount: isLarge ? 4 : 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                children: List.generate(programs.length, (index) {
                                  final p = programs[index];
                                  final cover = p['cover_image_url']?.toString() ?? 'https://images.unsplash.com/photo-1519671482749-fd09871171dd?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80';
                                  
                                  int crossAxisCellCount = 1;
                                  int mainAxisCellCount = 1;
                                  if (index % 5 == 0) {
                                    crossAxisCellCount = isLarge ? 2 : 2;
                                    mainAxisCellCount = 2;
                                  } else if (index % 5 == 3) {
                                    crossAxisCellCount = isLarge ? 2 : 1;
                                    mainAxisCellCount = 1;
                                  }

                                  return StaggeredGridTile.count(
                                    crossAxisCellCount: crossAxisCellCount,
                                    mainAxisCellCount: mainAxisCellCount,
                                    child: GestureDetector(
                                      onTap: () => context.push('/clubs/${widget.id}/events/${p['id']}'),
                                      child: _buildEventCard(
                                        p['title'] ?? 'Event Title',
                                        p['start_datetime'] != null ? DateFormat('MMM d').format(DateTime.parse(p['start_datetime'].toString())) : 'TBA',
                                        p['venue'] ?? 'Venue TBA',
                                        cover,
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ],
                        if (leadership.isNotEmpty) ...[
                          const SizedBox(height: 80),
                          _buildLeadershipSection(leadership),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
              
                  ),
                ),
              ),
            ),

            // The Sovereign Lifestyle Gallery Section
            SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  color: _lightBg,
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('The Gallery', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _navyPrimary)),
                                    const SizedBox(height: 16),
                                    Text('Explore the spaces and moments that define our unique community experience.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() => _activeTab = 'Gallery'),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('View Full Gallery', style: TextStyle(color: _blueAccent, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 16, color: _blueAccent),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),
                          
                          // Bento Box Gallery
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final bool isLarge = constraints.maxWidth > 900;
                              return StaggeredGrid.count(
                                crossAxisCount: isLarge ? 4 : 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                children: [
                                  StaggeredGridTile.count(
                                    crossAxisCellCount: 2,
                                    mainAxisCellCount: 2,
                                    child: _buildGalleryImage(context, gallery.isNotEmpty ? (gallery[0]['image_url']?.toString() ?? 'https://images.unsplash.com/photo-1497366216548-37526070297c?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80') : 'https://images.unsplash.com/photo-1497366216548-37526070297c?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'),
                                  ),
                                  StaggeredGridTile.count(
                                    crossAxisCellCount: 1,
                                    mainAxisCellCount: 1,
                                    child: _buildGalleryImage(context, gallery.length > 1 ? (gallery[1]['image_url']?.toString() ?? 'https://images.unsplash.com/photo-1556761175-5973dc0f32d7?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80') : 'https://images.unsplash.com/photo-1556761175-5973dc0f32d7?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'),
                                  ),
                                  StaggeredGridTile.count(
                                    crossAxisCellCount: 1,
                                    mainAxisCellCount: 1,
                                    child: _buildGalleryImage(context, gallery.length > 2 ? (gallery[2]['image_url']?.toString() ?? 'https://images.unsplash.com/photo-1542314831-c6a4d14eff50?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80') : 'https://images.unsplash.com/photo-1542314831-c6a4d14eff50?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'),
                                  ),
                                  StaggeredGridTile.count(
                                    crossAxisCellCount: 1,
                                    mainAxisCellCount: 1,
                                    child: _buildGalleryImage(context, gallery.length > 3 ? (gallery[3]['image_url']?.toString() ?? 'https://images.unsplash.com/photo-1536987333706-fc9adfb10d91?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80') : 'https://images.unsplash.com/photo-1536987333706-fc9adfb10d91?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'),
                                  ),
                                  StaggeredGridTile.count(
                                    crossAxisCellCount: 1,
                                    mainAxisCellCount: 1,
                                    child: _buildGalleryImage(context, gallery.length > 4 ? (gallery[4]['image_url']?.toString() ?? 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80') : 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'),
                                  ),
                                ],
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              ] else if (_activeTab == 'Events') ...[
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Events', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: _navyPrimary)),
                            const SizedBox(height: 16),
                            Text('Discover our exclusive programming and experiences.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                            const SizedBox(height: 48),
                            if (programs.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 80),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/illusrtations_image/Empty.svg',
                                      height: 200,
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No upcoming events right now.',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              )
                            else
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final bool isLarge = constraints.maxWidth > 900;
                                  return StaggeredGrid.count(
                                    crossAxisCount: isLarge ? 4 : 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    children: List.generate(programs.length, (index) {
                                      final p = programs[index];
                                      final cover = p['cover_image_url']?.toString() ?? 'https://images.unsplash.com/photo-1519671482749-fd09871171dd?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80';
                                      int crossAxisCellCount = 1;
                                      int mainAxisCellCount = 1;
                                      if (index % 5 == 0) {
                                        crossAxisCellCount = isLarge ? 2 : 2;
                                        mainAxisCellCount = 2;
                                      } else if (index % 5 == 3) {
                                        crossAxisCellCount = isLarge ? 2 : 1;
                                        mainAxisCellCount = 1;
                                      }
                                      return StaggeredGridTile.count(
                                        crossAxisCellCount: crossAxisCellCount,
                                        mainAxisCellCount: mainAxisCellCount,
                                        child: GestureDetector(
                                          onTap: () => context.push('/clubs/${widget.id}/events/${p['id']}'),
                                          child: _buildEventCard(
                                            p['title'] ?? 'Event Title',
                                            p['start_datetime'] != null ? DateFormat('MMM d').format(DateTime.parse(p['start_datetime'].toString())) : 'TBA',
                                            p['venue'] ?? 'Venue TBA',
                                            cover,
                                          ),
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                            const SizedBox(height: 80),
                            const Text('Past Events Showcase', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _navyPrimary)),
                            const SizedBox(height: 16),
                            Text('A look back at our most memorable gatherings.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                            const SizedBox(height: 48),
                            
                            if (pastEvents.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 80),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/illusrtations_image/Empty.svg',
                                      height: 150,
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No past events showcased yet.',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              )
                            else
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final bool isLarge = constraints.maxWidth > 900;
                                  return StaggeredGrid.count(
                                    crossAxisCount: isLarge ? 4 : 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    children: List.generate(pastEvents.length, (index) {
                                      final pe = pastEvents[index];
                                      final imagesList = pe['images'] as List<dynamic>? ?? [];
                                      final cover = imagesList.isNotEmpty 
                                          ? imagesList.first.toString() 
                                          : 'https://images.unsplash.com/photo-1511556532299-8f662fc26c06?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80';
                                      
                                      return StaggeredGridTile.count(
                                        crossAxisCellCount: isLarge ? 2 : 2,
                                        mainAxisCellCount: 1,
                                        child: GestureDetector(
                                          onTap: () => context.push('/clubs/${widget.id}/past-events/${pe['id']}'),
                                          child: _buildEventCard(
                                            pe['title'] ?? 'Past Event',
                                            pe['start_date'] != null ? DateFormat.yMMMd().format(DateTime.parse(pe['start_date'].toString())) : 'Unknown Date',
                                            'Past Event Showcase',
                                            cover,
                                            isPast: true,
                                            gallery: imagesList.map((e) => e.toString()).toList(),
                                          ),
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ] else if (_activeTab == 'Gallery') ...[
              // Hero header for gallery
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('The Sovereign Archive', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: _navyPrimary)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 600,
                            child: Text(
                              'A curated visual chronicle of the moments that define our community. From global summits to intimate lounge sessions, rediscover the prestige.',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 48),
                          _buildFilters(gallery.isNotEmpty ? gallery.length : _generateMockGallery().length),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Grid
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: _buildEventsGallery(pastEvents, gallery),
                    ),
                  ),
                ),
              ),
              // Load more
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Load More Archives', style: TextStyle(color: _navyPrimary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              ],
              
            
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopNav(String name, String logoUrl) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white.withValues(alpha: 0.7),
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 80,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _navyPrimary, size: 18),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
      ),
      title: Row(
        children: [
          // Name
          Expanded(
            child: Text(name, style: const TextStyle(color: _navyPrimary, fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 16),
          // Logo & Links
          if (logoUrl.isNotEmpty) ...[
            CircleAvatar(backgroundImage: NetworkImage(logoUrl), radius: 16),
            const SizedBox(width: 12),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavLink('About Us', _activeTab == 'About Us', onTap: () => setState(() => _activeTab = 'About Us')),
                  _buildNavLink('Events', _activeTab == 'Events', onTap: () => setState(() => _activeTab = 'Events')),
                  _buildNavLink('Gallery', _activeTab == 'Gallery', onTap: () => setState(() => _activeTab = 'Gallery')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String text, bool active, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? _blueAccent : Colors.grey.shade700,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String text) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _lightBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _blueAccent, size: 28),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _navyPrimary)),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(DateTime? date) {
    final displayDate = date ?? DateTime.now();
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('FOUNDED IN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _blueAccent, letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    Text(displayDate.year.toString(), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _navyPrimary, height: 1)),
                    const SizedBox(height: 16),
                    Text('A new era of social excellence began in the heart of the city.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 6,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(
                          color: _blueAccent,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                        ),
                        child: Text(DateFormat('MMMM').format(displayDate).toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['S','M','T','W','T','F','S'].map((d) => Text(d, style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold))).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(14, (i) {
                            final isHighlight = i == 8; 
                            return Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isHighlight ? _blueAccent.withValues(alpha: 0.1) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text('${i + 1}', style: TextStyle(fontSize: 10, color: isHighlight ? _blueAccent : Colors.grey.shade400, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          // Member Portal Bubble Button
          InkWell(
            onTap: () => context.push('/login'),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_blueAccent, _navyPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _blueAccent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Member Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(String location) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: IgnorePointer(
                ignoring: false,
                child: WebMediaEmbedder(
                  url: location,
                  mediaType: 'map',
                ),
              ),
            ),
          ),
          Positioned(
            top: 24,
            left: 24,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Flagship Location', style: TextStyle(fontWeight: FontWeight.bold, color: _blueAccent)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(location, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
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

  Widget _buildBentoAboutCard(String description) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: _lightBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About the Club', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _navyPrimary)),
          const SizedBox(height: 24),
          Text(
            description,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.8),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(String title, String dateStr, String venue, String coverUrl, {bool isPast = false, List<String>? gallery}) {
    return Stack(
      children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: (gallery != null && gallery.isNotEmpty)
                  ? _AutoRotatingGallery(images: gallery)
                  : coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade300,
                            child: const Center(child: Icon(Icons.event, color: Colors.grey)),
                          ),
                        )
                      : Container(color: Colors.grey.shade300),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, _navyPrimary.withValues(alpha: 0.9)],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(isPast ? 'Showcase' : 'Upcoming', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _navyPrimary)),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('$dateStr • $venue', style: TextStyle(fontSize: 13, color: Colors.grey.shade300)),
          ],
        ),
      ),
      ),
      ],
    );
  }

  Widget _buildGalleryImage(BuildContext context, String url) {
    if (url.isEmpty) return Container(color: Colors.grey.shade200);
    final isVideo = url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov');
    
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: isVideo
          ? IgnorePointer(
              ignoring: true,
              child: WebMediaEmbedder(url: url, mediaType: 'video'),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
    );

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: isVideo
                      ? AspectRatio(
                          aspectRatio: 16 / 9,
                          child: WebMediaEmbedder(url: url, mediaType: 'video'),
                        )
                      : Image.network(
                          url,
                          fit: BoxFit.contain,
                        ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: content,
    );
  }

  Widget _buildFilters(int totalCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
       
        Text('Showing $totalCount archives', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }

  Widget _buildFilterPill(String title) {
    final isActive = _selectedFilter == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _navyPrimary : Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBentoGalleryGrid(List<dynamic> gallery) {
    if (gallery.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLarge = constraints.maxWidth > 900;
        final int crossAxisCount = isLarge ? 4 : 2;

        return MasonryGridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: gallery.length,
          itemBuilder: (context, index) {
            final item = gallery[index];
            final url = item['image_url']?.toString() ?? '';
            return _buildBentoGalleryItem(context, url);
          },
        );
      }
    );
  }

  Widget _buildModernHeading(String text, {bool isMain = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMain ? 24.0 : 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 5,
            height: isMain ? 36 : 24,
            decoration: BoxDecoration(
              color: _blueAccent,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: _blueAccent.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isMain ? 36 : 24,
                fontWeight: FontWeight.w900,
                letterSpacing: isMain ? -1.0 : -0.5,
                color: _navyPrimary,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsGallery(List<dynamic> pastEvents, List<dynamic> gallery) {
    final eventsWithMedia = pastEvents.where((e) {
      final images = e['images'] as List<dynamic>? ?? [];
      final highlights = e['highlights'] as List<dynamic>? ?? [];
      return images.isNotEmpty || highlights.any((hl) => (hl['media'] as List<dynamic>? ?? []).isNotEmpty);
    }).toList();

    if (eventsWithMedia.isEmpty && gallery.isEmpty) {
      return _buildBentoGalleryGrid(_generateMockGallery());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (gallery.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 64.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModernHeading('Club Gallery', isMain: true),
                const SizedBox(height: 16),
                _buildBentoGalleryGrid(gallery),
              ],
            ),
          ),
        ],
        ...eventsWithMedia.map((event) {
        final title = event['title']?.toString() ?? 'Event';
        final images = event['images'] as List<dynamic>? ?? [];
        final highlights = event['highlights'] as List<dynamic>? ?? [];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 64.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHeading(title, isMain: true),
              const SizedBox(height: 16),
              if (images.isNotEmpty) ...[
                _buildModernHeading('Images and Videos', isMain: false),
                const SizedBox(height: 8),
                _buildBentoGalleryGrid(images.map((url) => {'image_url': url.toString()}).toList()),
                const SizedBox(height: 48),
              ],
              if (highlights.isNotEmpty) ...[
                _buildModernHeading('Highlights', isMain: false),
                const SizedBox(height: 8),
                ...highlights.map((hl) {
                  final hlTitle = hl['title']?.toString() ?? 'Highlight';
                  final hlMedia = hl['media'] as List<dynamic>? ?? [];
                  if (hlMedia.isEmpty) return const SizedBox.shrink();
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModernHeading(hlTitle, isMain: false),
                        const SizedBox(height: 8),
                        _buildBentoGalleryGrid(hlMedia.map((m) => {'image_url': m['url']?.toString() ?? ''}).toList()),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
          );
      }),
      ],
    );
  }

  Widget _buildBentoGalleryItem(BuildContext context, String url) {
    if (url.isEmpty) return Container(color: Colors.grey.shade200);
    final isVideo = url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov');
    
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: isVideo
          ? AspectRatio(
              aspectRatio: 16 / 9,
              child: IgnorePointer(
                ignoring: true,
                child: WebMediaEmbedder(url: url, mediaType: 'video'),
              ),
            )
          : Image.network(
              url,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
    );

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: isVideo
                      ? AspectRatio(
                          aspectRatio: 16 / 9,
                          child: WebMediaEmbedder(url: url, mediaType: 'video'),
                        )
                      : Image.network(
                          url,
                          fit: BoxFit.contain,
                        ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: content,
    );
  }

  List<dynamic> _generateMockGallery() {
    return [
      {'image_url': 'https://images.unsplash.com/photo-1519671482749-fd09871171dd?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'},
      {'image_url': 'https://images.unsplash.com/photo-1556761175-5973dc0f32d7?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'},
      {'image_url': 'https://images.unsplash.com/photo-1542314831-c6a4d14eff50?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'},
      {'image_url': 'https://images.unsplash.com/photo-1536987333706-fc9adfb10d91?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'},
      {'image_url': 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'},
      {'image_url': 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'},
    ];
  }

  Widget _buildLeadershipSection(List<dynamic> leadership) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Club Leadership', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _navyPrimary)),
        const SizedBox(height: 4),
        Text('The dedicated individuals guiding our community', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isLarge = constraints.maxWidth > 900;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isLarge ? 4 : (constraints.maxWidth > 500 ? 3 : 2),
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: leadership.length,
              itemBuilder: (context, index) {
                final member = leadership[index];
                final role = member['role']?.toString() ?? 'Member';
                final name = member['full_name']?.toString() ?? 'Unknown';
                final displayRole = role.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
                
                return Container(
                  decoration: BoxDecoration(
                    color: _lightBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: _navyPrimary.withValues(alpha: 0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _navyPrimary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navyPrimary),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _blueAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          displayRole,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _blueAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _AutoRotatingGallery extends StatefulWidget {
  final List<String> images;
  const _AutoRotatingGallery({required this.images});

  @override
  State<_AutoRotatingGallery> createState() => _AutoRotatingGalleryState();
}

class _AutoRotatingGalleryState extends State<_AutoRotatingGallery> {
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.images.length * 100);
    
    if (widget.images.length > 1) {
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
    if (widget.images.isEmpty) {
      return Container();
    }
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(), // Only auto scroll
      itemBuilder: (context, index) {
        final actualIndex = index % widget.images.length;
        final mUrl = widget.images[actualIndex];
        final isVideo = mUrl.toLowerCase().endsWith('.mp4') || mUrl.toLowerCase().endsWith('.mov');
        
        if (isVideo) {
          return IgnorePointer(
            ignoring: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                WebMediaEmbedder(url: mUrl, mediaType: 'video'),
                Container(
                  color: Colors.black26,
                  child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48)),
                ),
              ],
            ),
          );
        }
        return Image.network(
          mUrl,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300),
        );
      },
    );
  }
}

