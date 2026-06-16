import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/providers/club_session_provider.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/widgets/animated_states.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/past_events_tab.dart';

class ClubProfileEditScreen extends StatefulWidget {
  const ClubProfileEditScreen({super.key});

  @override
  State<ClubProfileEditScreen> createState() => _ClubProfileEditScreenState();
}

class _ClubProfileEditScreenState extends State<ClubProfileEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _instagramController;
  late TextEditingController _missionController;
  late TextEditingController _visionController;
  late TabController _tabController;

  bool _showMap = true;
  bool _showMembers = true;

  String? _currentLogoUrl;
  String? _currentCoverUrl;

  Uint8List? _newLogoBytes;
  String? _newLogoFileName;

  Uint8List? _newCoverBytes;
  String? _newCoverFileName;

  List<Map<String, dynamic>> _galleryImages = [];
  bool _isUploadingGallery = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _instagramController = TextEditingController();
    _missionController = TextEditingController();
    _visionController = TextEditingController();
    _loadClubProfile();
  }

  Future<void> _loadClubProfile() async {
    final session = context.read<ClubSessionNotifier>();
    if (session.clubId == null) return;

    try {
      final club = await Supabase.instance.client
          .from('clubs')
          .select()
          .eq('id', session.clubId!)
          .single();

      List<Map<String, dynamic>> gallery = [];
      try {
        final g = await Supabase.instance.client
            .from('club_gallery')
            .select('id, image_url, title, media_type')
            .eq('club_id', session.clubId!)
            .order('created_at', ascending: false);
        gallery = List<Map<String, dynamic>>.from(g);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _nameController.text = club['name'] ?? '';
          _descController.text = club['description'] ?? '';
          _instagramController.text = club['instagram_url'] ?? '';
          _missionController.text = club['mission'] ?? '';
          _visionController.text = club['vision'] ?? '';
          _currentLogoUrl = club['logo_url'];
          _currentCoverUrl = club['cover_image_url'];
          _showMap = club['show_map'] ?? true;
          _showMembers = club['show_members'] ?? true;
          _galleryImages = gallery;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomToast.showError(context, 'Failed to load profile');
      }
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      setState(() {
        if (isLogo) {
          _newLogoBytes = bytes;
          _newLogoFileName = xfile.name;
        } else {
          _newCoverBytes = bytes;
          _newCoverFileName = xfile.name;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final session = context.read<ClubSessionNotifier>();
    if (session.clubId == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      String? updatedLogoUrl = _currentLogoUrl;
      String? updatedCoverUrl = _currentCoverUrl;

      if (_newLogoBytes != null && _newLogoFileName != null) {
        final ext = _newLogoFileName!.split('.').last;
        final path =
            '${user.id}/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage
            .from(SupabaseConstants.clubsBucket)
            .uploadBinary(path, _newLogoBytes!);
        updatedLogoUrl = supabase.storage
            .from(SupabaseConstants.clubsBucket)
            .getPublicUrl(path);
      }

      if (_newCoverBytes != null && _newCoverFileName != null) {
        final ext = _newCoverFileName!.split('.').last;
        final path =
            '${user.id}/cover_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage
            .from(SupabaseConstants.clubsBucket)
            .uploadBinary(path, _newCoverBytes!);
        updatedCoverUrl = supabase.storage
            .from(SupabaseConstants.clubsBucket)
            .getPublicUrl(path);
      }

      await supabase
          .from('clubs')
          .update({
            'description': _descController.text,
            'mission': _missionController.text,
            'vision': _visionController.text,
            'logo_url': updatedLogoUrl,
            'cover_image_url': updatedCoverUrl,
            'instagram_url': _instagramController.text,
            'show_map': _showMap,
            'show_members': _showMembers,
          })
          .eq('id', session.clubId!);

      if (mounted) {
        CustomToast.showSuccess(context, 'Profile updated successfully');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Failed to update profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showAddMediaDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add to Gallery",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.image_rounded, color: AppColors.primary),
                ),
                title: const Text(
                  "Upload Photo",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text("Add a photo from your device"),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadGalleryImage();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.videocam_rounded, color: AppColors.primary),
                ),
                title: const Text(
                  "Upload Video",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text("Add a video from your device (Max 50MB)"),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadGalleryVideo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadGalleryVideo() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video == null) return;
      if (!mounted) return;

      setState(() => _isUploadingGallery = true);
      final supabase = Supabase.instance.client;
      final session = context.read<ClubSessionNotifier>();
      final bytes = await video.readAsBytes();
      final ext = video.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = '${session.clubId}/gallery/$fileName';
      await supabase.storage
          .from(SupabaseConstants.clubsBucket)
          .uploadBinary(filePath, bytes);
      final publicUrl = supabase.storage
          .from(SupabaseConstants.clubsBucket)
          .getPublicUrl(filePath);

      final insertData = {
        'club_id': session.clubId!,
        'image_url': publicUrl,
        'title': video.name,
        'media_type': 'video',
        'uploaded_by': supabase.auth.currentUser!.id,
      };

      final response = await supabase
          .from('club_gallery')
          .insert(insertData)
          .select()
          .single();

      if (mounted) {
        setState(() {
          _galleryImages.insert(0, response);
          _isUploadingGallery = false;
        });
        CustomToast.showSuccess(context, 'Video uploaded to gallery!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingGallery = false);
        CustomToast.showError(context, 'Failed to upload video: $e');
      }
    }
  }

  Future<void> _uploadGalleryImage() async {
    final session = context.read<ClubSessionNotifier>();
    if (session.clubId == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final xfiles = await picker.pickMultiImage();
    if (xfiles.isEmpty) return;

    setState(() => _isUploadingGallery = true);
    final supabase = Supabase.instance.client;

    try {
      for (var file in xfiles) {
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last;
        final path =
            '${user.id}/gallery_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage
            .from(SupabaseConstants.clubsBucket)
            .uploadBinary(path, bytes);
        final url = supabase.storage
            .from(SupabaseConstants.clubsBucket)
            .getPublicUrl(path);

        await supabase.from('club_gallery').insert({
          'club_id': session.clubId!,
          'image_url': url,
          'title': 'Gallery Image',
          'uploaded_by': user.id,
        });
      }
      if (mounted) {
        CustomToast.showSuccess(context, 'Gallery uploaded successfully');
      }
      await _loadClubProfile();
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Failed to upload gallery: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingGallery = false);
      }
    }
  }

  Future<void> _deleteGalleryImage(String id) async {
    setState(() => _isUploadingGallery = true);
    try {
      await Supabase.instance.client.from('club_gallery').delete().eq('id', id);
      if (mounted) CustomToast.showSuccess(context, 'Media deleted');
      await _loadClubProfile();
    } catch (e) {
      if (mounted) CustomToast.showError(context, 'Failed to delete media: $e');
    } finally {
      if (mounted) setState(() => _isUploadingGallery = false);
    }
  }

  Future<void> _confirmDeleteMedia(Map<String, dynamic> item) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Media",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        content: Text(
          "Are you sure you want to delete '${item['title'] ?? 'this item'}'? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteGalleryImage(item['id']);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _instagramController.dispose();
    _missionController.dispose();
    _visionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Club Profile',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: _isSaving ? null : _saveProfile,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: _isSaving
                      ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
                      : LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: _isSaving ? Colors.transparent : AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSaving)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    else
                      const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3)),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            height: 50,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent, // Removes the default bottom line
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorPadding: const EdgeInsets.all(4),
              labelPadding: const EdgeInsets.symmetric(horizontal: 20),
              tabs: const [
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.info_outline_rounded, size: 18), SizedBox(width: 8), Text('Basic Info')])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.brush_rounded, size: 18), SizedBox(width: 8), Text('Branding')])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.collections_rounded, size: 18), SizedBox(width: 8), Text('Gallery')])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.event_available_rounded, size: 18), SizedBox(width: 8), Text('Events Archive')])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.visibility_rounded, size: 18), SizedBox(width: 8), Text('Visibility')])),
              ],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildBrandingTab(),
            _buildGalleryTab(),
            PastEventsTab(clubId: context.read<ClubSessionNotifier>().clubId ?? ''),
            _buildVisibilityTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(32),
  }) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        margin: const EdgeInsets.all(24),
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Club Identity",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Update your club's primary details.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Club Name', Icons.account_balance),
              readOnly: true,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _descController,
              decoration: _inputDecoration(
                'Heritage Description',
                Icons.description,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _missionController,
              decoration: _inputDecoration(
                'Our Mission',
                Icons.flag,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _visionController,
              decoration: _inputDecoration(
                'Our Vision',
                Icons.remove_red_eye,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _instagramController,
              decoration: _inputDecoration(
                'Instagram Profile URL',
                Icons.camera_alt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandingTab() {
    return SingleChildScrollView(
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Premium Branding",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enhance your visual identity with high-quality media.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 48),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _pickImage(true),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 3),
                            image: _newLogoBytes != null
                                ? DecorationImage(
                                    image: MemoryImage(_newLogoBytes!),
                                    fit: BoxFit.cover,
                                  )
                                : (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(_currentLogoUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null),
                          ),
                          child:
                              (_newLogoBytes == null && (_currentLogoUrl == null || _currentLogoUrl!.isEmpty))
                              ? const Icon(
                                  Icons.shield,
                                  size: 50,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Club Crest / Logo",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Recommended: 512x512 PNG",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _pickImage(false),
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          constraints: const BoxConstraints(maxWidth: 400),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.primary, width: 2),
                            image: _newCoverBytes != null
                                ? DecorationImage(
                                    image: MemoryImage(_newCoverBytes!),
                                    fit: BoxFit.cover,
                                  )
                                : (_currentCoverUrl != null && _currentCoverUrl!.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            _currentCoverUrl!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null),
                          ),
                          child:
                              (_newCoverBytes == null &&
                                  (_currentCoverUrl == null || _currentCoverUrl!.isEmpty))
                              ? const Icon(
                                  Icons.image,
                                  size: 50,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Hero Cover Photo",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Recommended: 1920x1080 high-res image",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryTab() {
    return SingleChildScrollView(
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Social Reels",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Manage the gallery shown on your public profile.",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isUploadingGallery ? null : _showAddMediaDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: _isUploadingGallery
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add, size: 18),
                  label: const Text("Add Media"),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_galleryImages.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    SvgPicture.asset('assets/illusrtations_image/Empty.svg', height: 150),
                    const SizedBox(height: 20),
                    const Text('Your gallery is empty.', style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 48),
                  ],
                ).animate().fadeIn(duration: 500.ms),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: _galleryImages.length,
                itemBuilder: (context, index) {
                  final item = _galleryImages[index];
                  final type = item['media_type'];
                  final isVideo = type == 'video';
                  final isInstagram = type == 'instagram';
                  final isYouTube = type == 'youtube';
                  final isFacebook = type == 'facebook';
                  final isImage = type == null || type == 'image' || type == '';

                  IconData mediaIcon = Icons.image;
                  if (isVideo) mediaIcon = Icons.videocam;
                  if (isInstagram) mediaIcon = Icons.camera_alt;
                  if (isYouTube) mediaIcon = Icons.play_arrow;
                  if (isFacebook) mediaIcon = Icons.facebook;

                  return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: isImage && item['image_url']?.toString().isNotEmpty == true
                              ? DecorationImage(
                                  image: NetworkImage(item['image_url']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: Colors.grey.shade100,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (!isImage)
                              Center(
                                child: Icon(
                                  mediaIcon,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.8),
                                    ],
                                    stops: const [0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => _confirmDeleteMedia(item),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Row(
                                children: [
                                  Icon(
                                    mediaIcon,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item['title'] ?? 'Media',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ), // Stack
                      )
                      .animate()
                      .fadeIn(delay: (50 * index).ms)
                      .scale(begin: const Offset(0.9, 0.9));
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityTab() {
    return SingleChildScrollView(
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Visibility Settings",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Control what the public sees.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            _buildSwitchTile(
              title: "Regional Anchor Map",
              subtitle: "Show the location map on your public profile.",
              value: _showMap,
              onChanged: (val) => setState(() => _showMap = val),
              icon: Icons.map_outlined,
            ),
            const Divider(height: 32),
            _buildSwitchTile(
              title: "Leadership Roster",
              subtitle: "Display the founding members and leaders publicly.",
              value: _showMembers,
              onChanged: (val) => setState(() => _showMembers = val),
              icon: Icons.people_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
