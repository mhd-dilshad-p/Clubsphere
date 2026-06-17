import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../services/public_service.dart';
import '../../../core/widgets/web_media_embedder.dart';

const Color _navyPrimary = Color(0xFF0F172A);
const Color _blueAccent = Color(0xFF1E3A8A);
const Color _lightBg = Color(0xFFF8FAFC);

class ClubPublicGalleryScreen extends StatefulWidget {
  final String id;
  const ClubPublicGalleryScreen({super.key, required this.id});

  @override
  State<ClubPublicGalleryScreen> createState() => _ClubPublicGalleryScreenState();
}

class _ClubPublicGalleryScreenState extends State<ClubPublicGalleryScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  String _selectedFilter = 'All Moments';

  @override
  void initState() {
    super.initState();
    _profileFuture = PublicService.getClubProfile(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final club = data['club'];
          final List<dynamic> gallery = data['gallery'] ?? [];
          final List<dynamic> pastEvents = data['past_events'] ?? [];
          
          final name = club['name']?.toString() ?? 'Sovereign Social';
          
          // Generate a fallback gallery if empty to showcase the design
          final List<dynamic> displayGallery = gallery.isNotEmpty ? gallery : _generateMockGallery();

          return CustomScrollView(
            slivers: [
              _buildTopNav(name),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('The Sovereign Archive', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: _navyPrimary)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 600,
                            child: Text(
                              'A curated visual chronicle of the moments that define our community. From global summits to intimate lounge sessions, rediscover the prestige.',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 48),
                          _buildFilters(displayGallery.length),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.keyboard_arrow_down, color: _navyPrimary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Load Older Memories', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
              _buildFooter(name),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopNav(String name) {
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
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _navyPrimary, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(name, style: const TextStyle(color: _navyPrimary, fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavLink('About Us', false, onTap: () => context.pop()),
                  _buildNavLink('Events', false, onTap: () => context.pop()),
                  _buildNavLink('Gallery', true),
                ],
              ),
            ),
          ),
        ],
      ),
      iconTheme: const IconThemeData(color: _navyPrimary),
    );
  }

  Widget _buildNavLink(String text, bool active, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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

  Widget _buildFilters(int totalCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.filter_list, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text('Filter by:', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(width: 24),
            _buildFilterPill('All Years'),
            const SizedBox(width: 12),
            _buildFilterPill('All Moments'),
            const SizedBox(width: 12),
            _buildFilterPill('Galas'),
            const SizedBox(width: 12),
            _buildFilterPill('Tech Summits'),
            const SizedBox(width: 12),
            _buildFilterPill('Private Lounges'),
          ],
        ),
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

  Widget _buildBentoGrid(List<dynamic> gallery) {
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
            return _buildGalleryItem(context, url);
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
      return _buildBentoGrid(_generateMockGallery());
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
                _buildBentoGrid(gallery),
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
                _buildBentoGrid(images.map((url) => {'image_url': url.toString()}).toList()),
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
                        _buildBentoGrid(hlMedia.map((m) => {'image_url': m['url']?.toString() ?? ''}).toList()),
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

  Widget _buildGalleryItem(BuildContext context, String url) {
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

  Widget _buildFooter(String name) {
    return SliverToBoxAdapter(
      child: Container(
        color: _lightBg,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: _navyPrimary, fontSize: 18)),
            Row(
              children: [
                TextButton(onPressed: () {}, child: Text('Privacy Policy', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
                TextButton(onPressed: () {}, child: Text('Terms of Service', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
                TextButton(onPressed: () {}, child: Text('Membership Inquiry', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
              ],
            ),
            Text('© ${DateTime.now().year} $name. All rights reserved.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
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
}
