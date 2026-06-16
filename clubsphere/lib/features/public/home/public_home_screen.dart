import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

import '../services/public_service.dart';

class PublicHomeScreen extends StatefulWidget {
  const PublicHomeScreen({super.key});

  @override
  State<PublicHomeScreen> createState() => _PublicHomeScreenState();
}

class _PublicHomeScreenState extends State<PublicHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  String _selectedCategory = 'All';
  Timer? _bgTimer;
  int _currentBgIndex = 0;
  late Future<List<Map<String, dynamic>>> _clubsFuture;

  final List<String> _bgAnimations = [
    'assets/animations/sport and arts/boxer lottie Animation.json',
    'assets/animations/sport and arts/criket.json',
    'assets/animations/sport and arts/kick on the ball Animation.json',
    'assets/animations/sport and arts/Olympics Animation.json',
    'assets/animations/sport and arts/Archery Man Animation.json',
  ];

  final Map<String, String> _categories = {
    'All': 'assets/animations/checking_all.json',
    'Arts': 'assets/animations/sport and arts/arts.json',
    'Sports': 'assets/animations/sport and arts/kick on the ball Animation.json',
    'Cultural': 'assets/animations/sport and arts/Olympics Animation.json',
    'Social Welfare': 'assets/animations/leader_funny_animation.json',
    'Educational': 'assets/animations/checking_all.json',
    'Others': 'assets/animations/sport and arts/Archery Man Animation.json',
  };

  @override
  void initState() {
    super.initState();
    _clubsFuture = PublicService.getPublicClubs();
    _bgTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentBgIndex = (_currentBgIndex + 1) % _bgAnimations.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(theme),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeroSection(size, theme),
            const SizedBox(height: 60),
            _buildStatsBanner(theme),
            const SizedBox(height: 80),
            _buildHowItWorks(theme, size),
            const SizedBox(height: 80),
            _buildCategoriesAndClubs(theme, size),
            const SizedBox(height: 80),
            _buildWelcomeBanner(theme, size),
            const SizedBox(height: 80),
            _buildVerificationProcess(theme),
            const SizedBox(height: 80),
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.white.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Image.asset(
                    'assets/logo/clubspherefullnamelogo-BackgroundRemover.png', 
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  if (MediaQuery.of(context).size.width > 600)
                    TextButton(
                      onPressed: () => context.push('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('Login'),
                    ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient1,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => context.push('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(140, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      child: const Text('Register Club', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ),
                  ).animate().scale(curve: Curves.easeOutBack),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(Size size, ThemeData theme) {
    final bool isDesktop = size.width > 800;

    return Container(
      constraints: BoxConstraints(minHeight: size.height),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F4FF), Color(0xFFE1F5FE), Color(0xFFF3E5F5)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sport and Arts Animations in Background - cycled to prevent CanvasKit OOM
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 1500),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child: Lottie.asset(
                  _bgAnimations[_currentBgIndex],
                  key: ValueKey(_currentBgIndex),
                  width: size.width * (isDesktop ? 0.6 : 0.9),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Radial gradient overlay to ensure text readability in the center
          // while leaving the edges clear for the animations to shine through.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.7,
                  colors: [
                    Colors.white.withValues(alpha: 0.8),
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Foreground Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: size.height * 0.15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradient2,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Text(
                        "🏆 India's #1 Club Platform",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.5),
                    
                    const SizedBox(height: 32),
                    
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent, Colors.deepPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        "Find & Manage\nClubs Near You",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          height: 1.1,
                          fontSize: size.width < 600 ? 44 : 72,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      "Arts • Sports • Cultural • Welfare\nAll in one place 🇮🇳",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                        fontSize: size.width < 600 ? 16 : 20,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                    
                    const SizedBox(height: 48),
                    
                    // Huge Premium Search Bar
                    Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      height: 70,
                      decoration: AppDecorations.glossy3D.copyWith(
                        borderRadius: BorderRadius.circular(35),
                        color: Colors.white.withValues(alpha: 0.9),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 15))
                        ],
                      ),
                      child: Center(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                          style: const TextStyle(fontSize: 18),
                          decoration: InputDecoration(
                            hintText: size.width < 400 ? 'Search clubs...' : 'Search clubs, district...',
                            hintStyle: TextStyle(fontSize: size.width < 600 ? 16 : 18, color: Colors.grey.shade400),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 8),
                              child: Icon(Icons.search, color: AppColors.primary, size: size.width < 600 ? 24 : 28),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(size.width < 600 ? 80 : 120, 54),
                                  padding: EdgeInsets.symmetric(horizontal: size.width < 600 ? 12 : 24),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                                  elevation: 0,
                                ),
                                child: Text('Explore', style: TextStyle(fontSize: size.width < 600 ? 14 : 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).scale(curve: Curves.easeOutBack),
                    
                    const SizedBox(height: 32),
                    
                    if (!isDesktop) ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => context.push('/register'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.8),
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                          minimumSize: const Size(200, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                        ),
                        child: const Text('Register Your Club', style: TextStyle(fontWeight: FontWeight.bold)),
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildStatsBanner(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatCard('500+', 'Clubs', 'assets/illusrtations_image/arts_club.svg'),
          _buildStatCard('10,000+', 'Members', 'assets/illusrtations_image/members.svg'),
          _buildStatCard('14', 'Districts', 'assets/animations/indian flag.json'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String count, String label, String assetPath) {
    return Hover3DCard(
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        padding: const EdgeInsets.all(24),
        decoration: AppDecorations.glossy3D.copyWith(
          border: const Border(top: BorderSide(color: AppColors.primary, width: 4)),
        ),
        child: Column(
          children: [
            assetPath.endsWith('.json')
                ? Lottie.asset(assetPath, width: 70, height: 70)
                : SvgPicture.asset(assetPath, width: 70, height: 70),
            const SizedBox(height: 16),
            Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary)),
            Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildHowItWorks(ThemeData theme, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text("How ClubSphere Works", style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text("3 simple steps to connect", style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 40),
          if (size.width < 800)
            Column(
              children: [
                _buildStepCard("01", "Register Your Club", "Submit your club details. Get verified in 24 hours.", "assets/illusrtations_image/registration.svg", 0),
                const SizedBox(height: 16),
                _buildStepCard("02", "Connect Members", "Add members, assign roles, manage everything online.", "assets/illusrtations_image/connect members.svg", 1),
                const SizedBox(height: 16),
                _buildStepCard("03", "Lead & Manage", "Track finance, run elections, organize events.", "assets/illusrtations_image/leadership.svg", 2),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildStepCard("01", "Register Your Club", "Submit your club details. Get verified in 24 hours.", "assets/illusrtations_image/registration.svg", 0)),
                const SizedBox(width: 16),
                Expanded(child: _buildStepCard("02", "Connect Members", "Add members, assign roles, manage everything online.", "assets/illusrtations_image/connect members.svg", 1)),
                const SizedBox(width: 16),
                Expanded(child: _buildStepCard("03", "Lead & Manage", "Track finance, run elections, organize events.", "assets/illusrtations_image/leadership.svg", 2)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStepCard(String number, String title, String desc, String imageAsset, int index) {
    return Hover3DCard(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppDecorations.glossy3D.copyWith(
          border: const Border(left: BorderSide(color: AppColors.primary, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.gradient1),
                  child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ),
                SvgPicture.asset(imageAsset, width: 80, height: 80),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 150).ms).slideY(begin: 0.2);
  }

  Widget _buildCategoriesAndClubs(ThemeData theme, Size size) {
    return Column(
      children: [
        Text("Every Club, One Platform", style: theme.textTheme.headlineSmall),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _categories.entries.map((e) {
              final isSelected = _selectedCategory == e.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.gradient1 : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      if (isSelected) BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                    border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (e.key != 'All')
                        Lottie.asset(e.value, width: 24, height: 24)
                      else 
                        const Icon(Icons.apps, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(e.key, style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _clubsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Lottie.asset('assets/animations/Sandy Loading Animation.json', width: 100);
              }
              if (snapshot.hasError) {
                return Text('Error loading clubs: ${snapshot.error}');
              }
              
              final clubs = snapshot.data ?? [];
              final filtered = clubs.where((c) {
                final matchSearch = (c['name'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
                                    (c['district'] ?? '').toString().toLowerCase().contains(_searchQuery);
                final matchCat = _selectedCategory == 'All' || c['category'] == _selectedCategory.toLowerCase();
                return matchSearch && matchCat;
              }).toList();

              if (filtered.isEmpty) {
                return Column(
                  children: [
                    Lottie.asset('assets/animations/connecting.json', width: 200),
                    const Text("No clubs found. Be the first!", style: TextStyle(color: AppColors.textSecondary)),
                  ],
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  mainAxisExtent: 460,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final club = filtered[index];
                  return _buildVerticalClubCard(club, context, index);
                },
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildVerticalClubCard(Map<String, dynamic> club, BuildContext context, int index) {
    return Hover3DCard(
      child: GestureDetector(
        onTap: () => context.push('/clubs/${club['id']}'),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 10),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Section (Image + Clipper)
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipPath(
                        clipper: ClubCutoutClipper(),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              image: club['cover_image_url'] != null && club['cover_image_url'].toString().isNotEmpty
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(club['cover_image_url']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: club['cover_image_url'] == null || club['cover_image_url'].toString().isEmpty
                                ? const Center(
                                    child: Icon(Icons.business, size: 64, color: Colors.grey),
                                  )
                                : null,
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.black, width: 1.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Lottie.asset(
                                    'assets/animations/hash_animation.json',
                                    width: 16,
                                    height: 16,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    club['category']?.toString().toUpperCase() ?? 'GENERAL',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      ),
                      // No verified badge needed, clubs shown here are already verified
                    ],
                  ),
                ),
              ),
              
              // Bottom Section
              Expanded(
                flex: 5,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 46, left: 16, right: 16, bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  (club['name'] ?? 'Unknown').toString().toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF333333),
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Removed category badge from here
                          const SizedBox(height: 12),
                          if (club['description'] != null && club['description'].toString().isNotEmpty)
                            Text(
                              club['description'],
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Established", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                  Text(
                                    club['founding_date'] != null 
                                      ? DateFormat.yMMM().format(DateTime.parse(club['founding_date'])) 
                                      : club['created_at'] != null 
                                          ? DateFormat.yMMM().format(DateTime.parse(club['created_at']))
                                          : 'Unknown',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () => context.push('/clubs/${club['id']}'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                  minimumSize: const Size(80, 32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text("See More", style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -46,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                          backgroundImage: club['logo_url'] != null && club['logo_url'].toString().isNotEmpty ? CachedNetworkImageProvider(club['logo_url']) : null,
                          child: club['logo_url'] == null || club['logo_url'].toString().isEmpty
                              ? Text(
                                  (club['name'] ?? 'C')[0].toUpperCase(),
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1),
    );
  }

  // (Keeping existing bottom widgets...)
  Widget _buildWelcomeBanner(ThemeData theme, Size size) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppColors.gradient1,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 32,
        children: [
          SvgPicture.asset(
            'assets/illusrtations_image/welcome.svg',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
          Column(
            crossAxisAlignment: size.width < 600 ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              const Text("Welcome to ClubSphere 🎉", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text("The modern platform built for Indian clubs.\nTransparent. Democratic. Digital.", style: TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(200, 48),
                ),
                child: const Text("Register Free →"),
              ),
            ],
          )
        ],
      ),
    ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack);
  }

  Widget _buildVerificationProcess(ThemeData theme) {
    return Column(
      children: [
        Text("How We Verify Clubs", style: theme.textTheme.headlineSmall),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _buildTimelineStep("assets/animations/admin_approve_animation.json", "Submit Application", "Register with official details"),
              _buildTimelineStep("assets/animations/checking_all.json", "Admin Reviews", "Our team verifies credentials"),
              _buildTimelineStep("assets/animations/verification_done.json", "Get Verified Badge ✓", "Build trust with members"),
              _buildTimelineStep("assets/animations/connecting.json", "Go Live on ClubSphere", "Start managing online"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(String lottie, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: AppDecorations.glassmorphism,
            child: Lottie.asset(lottie, width: 50, height: 50, repeat: false),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(desc, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          )
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.2);
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: AppDecorations.glassmorphism.copyWith(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Image.asset('assets/logo/app_logo.png', width: 120),
          const SizedBox(height: 16),
          const Text("Connecting clubs across India 🇮🇳", style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 24,
            children: [
              TextButton(onPressed: () {}, child: const Text("About")),
              TextButton(onPressed: () {}, child: const Text("Contact")),
              TextButton(onPressed: () {}, child: const Text("Privacy Policy")),
              TextButton(onPressed: () => context.push('/register'), child: const Text("Register Club")),
            ],
          ),
          const SizedBox(height: 32),
          const Text("© 2026 ClubSphere. All rights reserved.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class Hover3DCard extends StatefulWidget {
  final Widget child;
  const Hover3DCard({super.key, required this.child});

  @override
  State<Hover3DCard> createState() => _Hover3DCardState();
}

class _Hover3DCardState extends State<Hover3DCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _isHovered ? -10 : 0, 0),
          child: widget.child,
        ),
      ),
    );
  }
}

class ClubCutoutClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    
    // Create the inverted cutout for the avatar in the center
    final centerX = size.width / 2;
    // Avatar radius is 40 (36 inner + 4 padding), we make the cutout slightly bigger
    const cutoutRadius = 42.0;
    
    path.lineTo(centerX - cutoutRadius, size.height);
    // Draw an arc curving inwards (upwards) using arcToPoint for stability on web
    path.arcToPoint(
      Offset(centerX + cutoutRadius, size.height),
      radius: const Radius.circular(cutoutRadius),
      clockwise: true,
    );
    
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

