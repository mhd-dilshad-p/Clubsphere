import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/theme/app_colors.dart';

class PastEventsTab extends StatefulWidget {
  final String clubId;

  const PastEventsTab({super.key, required this.clubId});

  @override
  State<PastEventsTab> createState() => _PastEventsTabState();
}

class _PastEventsTabState extends State<PastEventsTab> {
  bool _isAdding = false;
  bool _isLoading = true;
  
  // Events list from Supabase
  List<Map<String, dynamic>> _pastEvents = [];

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchPastEvents();
  }

  Future<void> _fetchPastEvents() async {
    try {
      final data = await _supabase
          .from('club_past_events')
          .select()
          .eq('club_id', widget.clubId)
          .order('created_at', ascending: false);
          
      if (mounted) {
        setState(() {
          _pastEvents = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading events: $e')));
      }
    }
  }

  // Form State
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _venueAddressController = TextEditingController();
  final _mapLinkController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  String? _editingEventId;
  List<String> _existingEventImages = [];
  List<XFile> _selectedImageFiles = [];
  List<Uint8List> _selectedImages = [];
  List<Map<String, dynamic>> _agendas = [];
  List<Map<String, dynamic>> _highlights = [];
  List<Map<String, dynamic>> _behindEvents = [];

  // Inline Agenda Form State
  bool _isAddingAgenda = false;
  int? _editingAgendaIndex;
  final _agendaTitleCtrl = TextEditingController();
  final _agendaTimeDateCtrl = TextEditingController();
  String _agendaDetailType = 'desc'; // 'dot', 'desc', 'both'
  final _agendaDescCtrl = TextEditingController();
  List<TextEditingController> _agendaDotCtrls = [TextEditingController()];
  
  // Agenda Hosts List
  List<Map<String, dynamic>> _agendaHosts = [];
  final _tempAgendaHostNameCtrl = TextEditingController();
  final _tempAgendaHostRoleCtrl = TextEditingController();
  XFile? _tempAgendaHostImageFile;
  Uint8List? _tempAgendaHostImageBytes;
  String? _tempAgendaHostImageUrl;

  // Inline Highlight Form State
  bool _isAddingHighlight = false;
  int? _editingHighlightIndex;
  final _hlTitleCtrl = TextEditingController();
  final _hlDescCtrl = TextEditingController();
  List<XFile> _hlMediaFiles = [];
  List<Uint8List> _hlMediaBytes = [];
  List<Map<String, dynamic>> _hlExistingMedia = [];
  
  // Highlight Person Fields
  final _hlPersonNameCtrl = TextEditingController();
  final _hlPersonRoleCtrl = TextEditingController();
  XFile? _hlPersonImageFile;
  Uint8List? _hlPersonImageBytes;
  String? _hlPersonImageUrl;

  // Inline Behind Event Form State
  bool _isAddingBehindEvent = false;
  int? _editingBehindEventIndex;
  final _beNameCtrl = TextEditingController();
  final _beRoleCtrl = TextEditingController();
  final _beDeptCtrl = TextEditingController();
  XFile? _beImageFile;
  Uint8List? _beImageBytes;
  String? _beImageUrl;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultipleMedia();
    if (images.isNotEmpty) {
      for (var img in images) {
        final bytes = await img.readAsBytes();
        setState(() {
          _selectedImageFiles.add(img);
          _selectedImages.add(bytes);
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now);
    final first = isStart ? DateTime(2000) : (_startDate ?? DateTime(2000));
    final last = isStart ? (_endDate ?? DateTime(2101)) : DateTime(2101);

    // Ensure initialDate is within firstDate and lastDate bounds
    DateTime validInitial = initial;
    if (validInitial.isBefore(first)) validInitial = first;
    if (validInitial.isAfter(last)) validInitial = last;

    final ThemeData modernPickerTheme = ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surfaceTint: Colors.transparent,
        onSurface: Colors.black87,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 6,
      ),
      datePickerTheme: DatePickerThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        dayStyle: const TextStyle(fontWeight: FontWeight.w600),
        yearStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      timePickerTheme: TimePickerThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dayPeriodShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: validInitial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) => Theme(data: modernPickerTheme, child: child!),
    );
    
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) => Theme(data: modernPickerTheme, child: child!),
      );
      if (time != null) {
        setState(() {
          final fullDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
          if (isStart) {
            _startDate = fullDate;
            if (_endDate != null && _startDate!.isAfter(_endDate!)) {
              _endDate = _startDate!.add(const Duration(hours: 1));
            }
          } else {
            _endDate = fullDate;
            if (_startDate != null && _endDate!.isBefore(_startDate!)) {
              _startDate = _endDate!.subtract(const Duration(hours: 1));
            }
          }
        });
      }
    }
  }

  Future<void> _selectAgendaDateTime(BuildContext context) async {
    final ThemeData modernPickerTheme = ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surfaceTint: Colors.transparent,
        onSurface: Colors.black87,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 6,
      ),
      datePickerTheme: DatePickerThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        dayStyle: const TextStyle(fontWeight: FontWeight.w600),
        yearStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      timePickerTheme: TimePickerThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dayPeriodShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: _endDate ?? DateTime(2101),
      builder: (context, child) => Theme(data: modernPickerTheme, child: child!),
    );
    
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) => Theme(data: modernPickerTheme, child: child!),
      );
      if (pickedTime != null) {
        final fullDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
        setState(() {
          _agendaTimeDateCtrl.text = DateFormat('MMM d, yyyy - h:mm a').format(fullDate);
        });
      }
    }
  }


  Future<void> _pickHighlightMedia() async {
    final picker = ImagePicker();
    final List<XFile> media = await picker.pickMultipleMedia();
    if (media.isNotEmpty) {
      for (var m in media) {
        final bytes = await m.readAsBytes();
        setState(() {
          _hlMediaFiles.add(m);
          _hlMediaBytes.add(bytes);
        });
      }
    }
  }

  Future<void> _pickTempAgendaHostImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _tempAgendaHostImageFile = image;
        _tempAgendaHostImageBytes = bytes;
      });
    }
  }

  Future<void> _pickHighlightPersonImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _hlPersonImageFile = image;
        _hlPersonImageBytes = bytes;
      });
    }
  }

  void _editAgendaItem(int index) {
    setState(() {
      final a = _agendas[index];
      _agendaTitleCtrl.text = a['title'] ?? '';
      _agendaTimeDateCtrl.text = a['time'] ?? '';
      _agendaDetailType = a['detailType'] ?? 'desc';
      _agendaDescCtrl.text = a['desc'] ?? '';
      if (a['dots'] != null && a['dots'].toString().trim().isNotEmpty) {
        _agendaDotCtrls = a['dots'].toString().split('\n').where((s) => s.trim().isNotEmpty).map((s) => TextEditingController(text: s)).toList();
      } else {
        _agendaDotCtrls = [TextEditingController()];
      }
      _agendaHosts = List<Map<String, dynamic>>.from(a['hosts'] ?? []);
      if (_agendaHosts.isEmpty && (a['person_name']?.toString().isNotEmpty ?? false)) {
        _agendaHosts.add({
          'name': a['person_name'],
          'role': a['person_role'],
          'personImageBytes': a['personImageBytes'],
          'personImageFile': a['personImageFile'],
          'person_image_url': a['person_image_url'],
        });
      }
      _isAddingAgenda = true;
      _editingAgendaIndex = index;
    });
  }

  void _editHighlightItem(int index) {
    setState(() {
      final h = _highlights[index];
      _hlTitleCtrl.text = h['title'] ?? '';
      _hlDescCtrl.text = h['desc'] ?? '';
      _hlMediaFiles = List<XFile>.from(h['mediaFiles'] ?? []);
      _hlMediaBytes = List<Uint8List>.from(h['mediaBytes'] ?? []);
      _hlExistingMedia = List<Map<String, dynamic>>.from(h['media'] ?? []);
      
      _hlPersonNameCtrl.text = h['person_name'] ?? '';
      _hlPersonRoleCtrl.text = h['person_role'] ?? '';
      _hlPersonImageBytes = h['personImageBytes'];
      _hlPersonImageFile = h['personImageFile'];
      _hlPersonImageUrl = h['person_image_url'];
      _isAddingHighlight = true;
      _editingHighlightIndex = index;
    });
  }

  void _removeHighlightMedia(int index) {
    setState(() {
      _hlMediaFiles.removeAt(index);
      _hlMediaBytes.removeAt(index);
    });
  }

  void _removeExistingHighlightMedia(int index) {
    setState(() {
      _hlExistingMedia.removeAt(index);
    });
  }

  void _saveAgenda() {
    setState(() {
      final newAgenda = {
        'title': _agendaTitleCtrl.text,
        'time': _agendaTimeDateCtrl.text,
        'detailType': _agendaDetailType,
        'desc': _agendaDescCtrl.text,
        'dots': _agendaDotCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).join('\n'),
        'hosts': List.from(_agendaHosts),
      };
      
      if (_editingAgendaIndex != null) {
        _agendas[_editingAgendaIndex!] = newAgenda;
      } else {
        _agendas.add(newAgenda);
      }
      
      _isAddingAgenda = false;
      _editingAgendaIndex = null;
      _agendaTitleCtrl.clear();
      _agendaTimeDateCtrl.clear();
      _agendaDescCtrl.clear();
      _agendaDotCtrls = [TextEditingController()];
      _agendaDetailType = 'desc';
      _agendaHosts.clear();
      _tempAgendaHostNameCtrl.clear();
      _tempAgendaHostRoleCtrl.clear();
      _tempAgendaHostImageFile = null;
      _tempAgendaHostImageBytes = null;
      _tempAgendaHostImageUrl = null;
    });
  }

  void _saveHighlight() {
    setState(() {
      final newHighlight = {
        'title': _hlTitleCtrl.text,
        'desc': _hlDescCtrl.text,
        'mediaFiles': List.from(_hlMediaFiles),
        'mediaBytes': List.from(_hlMediaBytes),
        'media': List.from(_hlExistingMedia),
        'person_name': _hlPersonNameCtrl.text,
        'person_role': _hlPersonRoleCtrl.text,
        'personImageFile': _hlPersonImageFile,
        'personImageBytes': _hlPersonImageBytes,
        'person_image_url': _hlPersonImageUrl,
      };
      
      if (_editingHighlightIndex != null) {
        _highlights[_editingHighlightIndex!] = newHighlight;
      } else {
        _highlights.add(newHighlight);
      }
      
      _isAddingHighlight = false;
      _editingHighlightIndex = null;
      _hlTitleCtrl.clear();
      _hlDescCtrl.clear();
      _hlMediaFiles.clear();
      _hlMediaBytes.clear();
      _hlExistingMedia.clear();
      _hlPersonNameCtrl.clear();
      _hlPersonRoleCtrl.clear();
      _hlPersonImageFile = null;
      _hlPersonImageBytes = null;
      _hlPersonImageUrl = null;
    });
  }

  Future<void> _pickBeImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _beImageFile = image;
        _beImageBytes = bytes;
      });
    }
  }

  void _editBehindEventItem(int index) {
    setState(() {
      final be = _behindEvents[index];
      _beNameCtrl.text = be['name'] ?? '';
      _beRoleCtrl.text = be['role'] ?? '';
      _beDeptCtrl.text = be['department'] ?? '';
      _beImageBytes = be['imageBytes'];
      _beImageFile = be['imageFile'];
      _beImageUrl = be['image_url'];
      _isAddingBehindEvent = true;
      _editingBehindEventIndex = index;
    });
  }

  void _saveBehindEvent() {
    setState(() {
      final newBe = {
        'name': _beNameCtrl.text,
        'role': _beRoleCtrl.text,
        'department': _beDeptCtrl.text,
        'imageFile': _beImageFile,
        'imageBytes': _beImageBytes,
        'image_url': _beImageUrl,
      };
      
      if (_editingBehindEventIndex != null) {
        _behindEvents[_editingBehindEventIndex!] = newBe;
      } else {
        _behindEvents.add(newBe);
      }
      
      _isAddingBehindEvent = false;
      _editingBehindEventIndex = null;
      _beNameCtrl.clear();
      _beRoleCtrl.clear();
      _beDeptCtrl.clear();
      _beImageFile = null;
      _beImageBytes = null;
      _beImageUrl = null;
    });
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading while uploading files
      });
      try {
        List<String> eventImageUrls = List.from(_existingEventImages);
        for (int i = 0; i < _selectedImageFiles.length; i++) {
          final xfile = _selectedImageFiles[i];
          final bytes = _selectedImages[i];
          final ext = xfile.name.split('.').last;
          final path = '${widget.clubId}/events/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
          
          await _supabase.storage.from(SupabaseConstants.clubsBucket).uploadBinary(path, bytes);
          final url = _supabase.storage.from(SupabaseConstants.clubsBucket).getPublicUrl(path);
          eventImageUrls.add(url);
        }

        // Process Agendas
        List<Map<String, dynamic>> finalAgendas = [];
        for (int i = 0; i < _agendas.length; i++) {
          var a = Map<String, dynamic>.from(_agendas[i]);
          if (a['hosts'] != null) {
            List<Map<String, dynamic>> hostsList = List<Map<String, dynamic>>.from(a['hosts']);
            for (int hIdx = 0; hIdx < hostsList.length; hIdx++) {
              var h = Map<String, dynamic>.from(hostsList[hIdx]);
              if (h['personImageFile'] != null && h['personImageBytes'] != null) {
                final xfile = h['personImageFile'] as XFile;
                final bytes = h['personImageBytes'] as Uint8List;
                final ext = xfile.name.split('.').last;
                final path = '${widget.clubId}/events/persons/agenda_${DateTime.now().millisecondsSinceEpoch}_${i}_$hIdx.$ext';
                await _supabase.storage.from(SupabaseConstants.clubsBucket).uploadBinary(path, bytes);
                h['person_image_url'] = _supabase.storage.from(SupabaseConstants.clubsBucket).getPublicUrl(path);
              }
              h.remove('personImageFile');
              h.remove('personImageBytes');
              hostsList[hIdx] = h;
            }
            a['hosts'] = hostsList;
          }
          a.remove('personImageFile');
          a.remove('personImageBytes');
          finalAgendas.add(a);
        }

        // Process Highlights
        List<Map<String, dynamic>> uploadedHighlights = [];
        for (int hIndex = 0; hIndex < _highlights.length; hIndex++) {
          var hl = Map<String, dynamic>.from(_highlights[hIndex]);
          
          // Legacy check for already uploaded media (from edit mode)
          List<Map<String, dynamic>> uploadedMedia = [];
          if (hl['media'] != null) {
            uploadedMedia = List<Map<String, dynamic>>.from(hl['media']);
          }

          if (hl['mediaFiles'] != null && hl['mediaBytes'] != null) {
            List<XFile> mediaFiles = List<XFile>.from(hl['mediaFiles']);
            List<Uint8List> mediaBytes = List<Uint8List>.from(hl['mediaBytes']);

            for (int i = 0; i < mediaFiles.length; i++) {
              final xfile = mediaFiles[i];
              final bytes = mediaBytes[i];
              final ext = xfile.name.split('.').last;
              final path = '${widget.clubId}/events/highlights/${DateTime.now().millisecondsSinceEpoch}_${hIndex}_$i.$ext';
              
              await _supabase.storage.from(SupabaseConstants.clubsBucket).uploadBinary(path, bytes);
              final url = _supabase.storage.from(SupabaseConstants.clubsBucket).getPublicUrl(path);
              
              final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext.toLowerCase());
              
              uploadedMedia.add({
                'url': url,
                'type': isVideo ? 'video' : 'image',
              });
            }
          }

          if (hl['personImageFile'] != null && hl['personImageBytes'] != null) {
            final xfile = hl['personImageFile'] as XFile;
            final bytes = hl['personImageBytes'] as Uint8List;
            final ext = xfile.name.split('.').last;
            final path = '${widget.clubId}/events/persons/highlight_${DateTime.now().millisecondsSinceEpoch}_$hIndex.$ext';
            await _supabase.storage.from(SupabaseConstants.clubsBucket).uploadBinary(path, bytes);
            hl['person_image_url'] = _supabase.storage.from(SupabaseConstants.clubsBucket).getPublicUrl(path);
          }
          
          uploadedHighlights.add({
            'title': hl['title'],
            'desc': hl['desc'],
            'media': uploadedMedia,
            'person_name': hl['person_name'],
            'person_role': hl['person_role'],
            'person_image_url': hl['person_image_url'],
          });
        }

        // Process Behind Events
        List<Map<String, dynamic>> uploadedBehindEvents = [];
        for (int bIndex = 0; bIndex < _behindEvents.length; bIndex++) {
          var be = Map<String, dynamic>.from(_behindEvents[bIndex]);
          if (be['imageFile'] != null && be['imageBytes'] != null) {
            final xfile = be['imageFile'] as XFile;
            final bytes = be['imageBytes'] as Uint8List;
            final ext = xfile.name.split('.').last;
            final path = '${widget.clubId}/events/behind/${DateTime.now().millisecondsSinceEpoch}_$bIndex.$ext';
            await _supabase.storage.from(SupabaseConstants.clubsBucket).uploadBinary(path, bytes);
            be['image_url'] = _supabase.storage.from(SupabaseConstants.clubsBucket).getPublicUrl(path);
          }
          
          uploadedBehindEvents.add({
            'name': be['name'],
            'role': be['role'],
            'department': be['department'],
            'image_url': be['image_url'],
          });
        }

        final eventData = {
          'club_id': widget.clubId,
          'title': _titleController.text,
          'description': _descController.text,
          'venue_name': _venueNameController.text,
          'venue_address': _venueAddressController.text,
          'map_link': _mapLinkController.text,
          'start_date': _startDate?.toIso8601String(),
          'end_date': _endDate?.toIso8601String(),
          'images': eventImageUrls,
          'agendas': finalAgendas,
          'highlights': uploadedHighlights,
          'behind_events': uploadedBehindEvents,
          'is_visible': true,
        };

        if (_editingEventId != null) {
          final response = await _supabase.from('club_past_events').update(eventData).eq('id', _editingEventId!).select().single();
          setState(() {
            final index = _pastEvents.indexWhere((e) => e['id'] == _editingEventId);
            if (index != -1) {
              _pastEvents[index] = response;
            }
          });
        } else {
          final response = await _supabase.from('club_past_events').insert(eventData).select().single();
          setState(() {
            _pastEvents.insert(0, response);
          });
        }

        setState(() {
          _isAdding = false;
          _editingEventId = null;
          // Reset form
          _titleController.clear();
          _descController.clear();
          _venueNameController.clear();
          _venueAddressController.clear();
          _mapLinkController.clear();
          _startDate = null;
          _endDate = null;
          _existingEventImages.clear();
          _selectedImages.clear();
          _selectedImageFiles.clear();
          _agendas.clear();
          _highlights.clear();
          _behindEvents.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_editingEventId != null ? 'Event updated!' : 'Past event added successfully!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving event: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _toggleVisibility(String id, bool currentVisibility) async {
    try {
      await _supabase.from('club_past_events').update({'is_visible': !currentVisibility}).eq('id', id);
      setState(() {
        final index = _pastEvents.indexWhere((e) => e['id'] == id);
        if (index != -1) {
          _pastEvents[index]['is_visible'] = !currentVisibility;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating visibility: $e')));
      }
    }
  }

  Future<void> _deleteEvent(String id) async {
    try {
      await _supabase.from('club_past_events').delete().eq('id', id);
      setState(() {
        _pastEvents.removeWhere((e) => e['id'] == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting event: $e')));
      }
    }
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 6,
          ),
        ),
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Delete Event?'),
            ],
          ),
          content: const Text('Are you sure you want to permanently delete this event showcase? This action cannot be undone.'),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteEvent(id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete Permanently'),
            ),
          ],
        ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  void _editEvent(Map<String, dynamic> e) {
    setState(() {
      _isAdding = true;
      _editingEventId = e['id'];
      _titleController.text = e['title'] ?? '';
      _descController.text = e['description'] ?? '';
      _venueNameController.text = e['venue_name'] ?? '';
      _venueAddressController.text = e['venue_address'] ?? '';
      _mapLinkController.text = e['map_link'] ?? '';
      _startDate = e['start_date'] != null ? DateTime.parse(e['start_date']) : null;
      _endDate = e['end_date'] != null ? DateTime.parse(e['end_date']) : null;
      _existingEventImages = List<String>.from(e['images'] ?? []);
      _selectedImageFiles.clear();
      _selectedImages.clear();
      
      _agendas = List<Map<String, dynamic>>.from(e['agendas'] ?? []);
      _highlights = List<Map<String, dynamic>>.from(e['highlights'] ?? []);
      _behindEvents = List<Map<String, dynamic>>.from(e['behind_events'] ?? []);
    });
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(32)}) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  Widget _buildEventList() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_pastEvents.isEmpty)
            _buildCard(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  SvgPicture.asset('assets/illusrtations_image/Empty.svg', height: 150),
                  const SizedBox(height: 24),
                  const Text('No past events added yet.', style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _isAdding = true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    icon: const Icon(Icons.add),
                    label: const Text("Create Event Showcase"),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            )
          else ...[
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isAdding = true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add),
                  label: const Text("Add Another Showcase"),
                ),
              ),
            ),
            ..._pastEvents.map((e) => _buildCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.event_available, color: AppColors.primary),
                    ),
                    title: Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                    subtitle: Text(e['start_date'] != null ? DateFormat.yMMMd().format(DateTime.parse(e['start_date'])) : 'Unknown date'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            e['is_visible'] == true ? Icons.visibility : Icons.visibility_off,
                            color: e['is_visible'] == true ? AppColors.primary : Colors.grey,
                          ),
                          onPressed: () => _toggleVisibility(e['id'], e['is_visible'] ?? true),
                          tooltip: e['is_visible'] == true ? 'Hide from Public' : 'Show on Public Profile',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                          onPressed: () => _editEvent(e),
                          tooltip: 'Edit Event',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(e['id']),
                          tooltip: 'Delete Event',
                        ),
                      ],
                    ),
                  ),
                )),
          ]
        ],
      ),
    );
  }

  Widget _buildAddForm() {
    return SingleChildScrollView(
      child: _buildCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      _isAdding = false;
                      _editingEventId = null;
                    }),
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(_editingEventId != null ? "Update Past Event" : "New Past Event", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 32),
              
              // Basic Info
              const Text("Event Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration("Event Title", Icons.title),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: _inputDecoration("About the Event", Icons.description),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _venueNameController,
                      decoration: _inputDecoration("Venue Name", Icons.place),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _venueAddressController,
                      decoration: _inputDecoration("Venue Address", Icons.location_city),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mapLinkController,
                decoration: _inputDecoration("Google Map Location Link", Icons.map),
              ),
              const SizedBox(height: 24),

              // Date & Time
              const Text("Date & Time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _startDate == null ? Colors.grey.shade200 : AppColors.primary.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.event_available, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Start Date & Time", style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(_startDate == null ? "Select Start" : DateFormat('MMM d, yyyy - h:mm a').format(_startDate!), style: TextStyle(fontWeight: FontWeight.bold, color: _startDate == null ? Colors.grey.shade400 : AppColors.textPrimary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _endDate == null ? Colors.grey.shade200 : AppColors.primary.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.event_busy, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("End Date & Time", style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(_endDate == null ? "Select End" : DateFormat('MMM d, yyyy - h:mm a').format(_endDate!), style: TextStyle(fontWeight: FontWeight.bold, color: _endDate == null ? Colors.grey.shade400 : AppColors.textPrimary)),
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
              const SizedBox(height: 32),

              // Event Images
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Event Photos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text("Upload"),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_existingEventImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingEventImages.length,
                    itemBuilder: (ctx, idx) {
                      final url = _existingEventImages[idx];
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => setState(() => _existingEventImages.removeAt(idx)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 14, color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              if (_existingEventImages.isNotEmpty) const SizedBox(height: 12),
              if (_selectedImages.isEmpty && _existingEventImages.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                  child: const Center(child: Text("No photos uploaded yet.", style: TextStyle(color: Colors.grey))),
                )
              else if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (ctx, idx) {
                      final m = _selectedImageFiles[idx];
                      final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].any((ext) => m.name.toLowerCase().endsWith(ext));
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              image: !isVideo ? DecorationImage(image: MemoryImage(_selectedImages[idx]), fit: BoxFit.cover) : null,
                            ),
                            child: isVideo ? const Icon(Icons.videocam, size: 36, color: AppColors.primary) : null,
                          ),
                          Positioned(
                            top: 4,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedImages.removeAt(idx);
                                _selectedImageFiles.removeAt(idx);
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 14, color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 32),

              // Agenda Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text("Event Agenda", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          if (_agendas.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                              child: Text('${_agendas.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _isAddingAgenda ? null : () {
                          Future.delayed(Duration.zero, () {
                            if (mounted) setState(() => _isAddingAgenda = true);
                          });
                        },
                        icon: Icon(Icons.add, size: 18, color: _isAddingAgenda ? Colors.grey : AppColors.primary),
                        label: Text("Add Agenda", style: TextStyle(color: _isAddingAgenda ? Colors.grey : AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Existing Agendas
                  if (_agendas.isNotEmpty)
                    Column(
                      children: _agendas.asMap().entries.map((entry) {
                        final index = entry.key;
                        final a = entry.value;
                        if (_editingAgendaIndex == index) return const SizedBox.shrink();
                        
                        return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.schedule, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  if ((a['time'] ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(a['time'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                  if (a['detailType'] == 'desc' || a['detailType'] == 'both') ...[
                                    const SizedBox(height: 6),
                                    Text(a['desc'] ?? '', style: const TextStyle(fontSize: 13, height: 1.4)),
                                  ],
                                  if (a['detailType'] == 'dot' || a['detailType'] == 'both') ...[
                                    const SizedBox(height: 6),
                                    ...a['dots'].toString().split('\n').where((s) => s.trim().isNotEmpty).map((d) => Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Expanded(child: Text(d, style: const TextStyle(fontSize: 13))),
                                      ]),
                                    )),
                                  ],
                                  if ((a['person_name'] ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.person, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${a['person_name']}${a['person_role'] != null && a['person_role'].toString().isNotEmpty ? ' (${a['person_role']})' : ''}",
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                  tooltip: 'Edit',
                                  onPressed: () => _editAgendaItem(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  tooltip: 'Remove',
                                  onPressed: () => setState(() => _agendas.removeAt(index)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                      }).toList(),
                    )
                  else if (!_isAddingAgenda)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text("No agenda added. (Optional)", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ),

                  // Add Agenda Form
                  if (_isAddingAgenda)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("New Agenda Item", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.primary)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _agendaTitleCtrl, decoration: _inputDecoration("Agenda Title", Icons.title)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _agendaTimeDateCtrl,
                            readOnly: true,
                            onTap: () => _selectAgendaDateTime(context),
                            decoration: _inputDecoration("Time & Date (e.g. Oct 12, 2024 - 10:00 AM)", Icons.schedule),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _agendaDetailType,
                            decoration: _inputDecoration("Details Style", Icons.style),
                            items: const [
                              DropdownMenuItem(value: 'dot', child: Text("Bullet Points")),
                              DropdownMenuItem(value: 'desc', child: Text("Description")),
                              DropdownMenuItem(value: 'both', child: Text("Both")),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _agendaDetailType = v);
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_agendaDetailType == 'desc' || _agendaDetailType == 'both')
                            TextFormField(controller: _agendaDescCtrl, maxLines: 3, decoration: _inputDecoration("Description", Icons.notes)),
                          if (_agendaDetailType == 'both') const SizedBox(height: 12),
                          if (_agendaDetailType == 'dot' || _agendaDetailType == 'both') ...[
                            const SizedBox(height: 8),
                            const Text("Agenda Points (Dots)", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                            const SizedBox(height: 8),
                            ...List.generate(_agendaDotCtrls.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.circle, size: 8, color: AppColors.primary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _agendaDotCtrls[index],
                                        decoration: _inputDecoration("Enter point details", Icons.edit).copyWith(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        ),
                                      ),
                                    ),
                                    if (_agendaDotCtrls.length > 1)
                                      GestureDetector(
                                        onTap: () {
                                          Future.delayed(Duration.zero, () {
                                            if (mounted) setState(() => _agendaDotCtrls.removeAt(index));
                                          });
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.remove_circle_outline, color: Colors.red),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            GestureDetector(
                              onTap: () {
                                Future.delayed(Duration.zero, () {
                                  if (mounted) setState(() => _agendaDotCtrls.add(TextEditingController()));
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text("Add another point", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),
                          const Text("Hosts / Featured Persons (Optional)", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                          const SizedBox(height: 8),
                          if (_agendaHosts.isNotEmpty) ...[
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _agendaHosts.length,
                              itemBuilder: (context, idx) {
                                final h = _agendaHosts[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: h['personImageBytes'] != null 
                                            ? MemoryImage(h['personImageBytes']) 
                                            : h['person_image_url'] != null ? NetworkImage(h['person_image_url']) as ImageProvider : null,
                                        child: (h['personImageBytes'] == null && h['person_image_url'] == null) ? const Icon(Icons.person) : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(h['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text(h['role'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _agendaHosts.removeAt(idx);
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Add Host", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: _pickTempAgendaHostImage,
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          shape: BoxShape.circle,
                                          image: _tempAgendaHostImageBytes != null
                                              ? DecorationImage(image: MemoryImage(_tempAgendaHostImageBytes!), fit: BoxFit.cover)
                                              : _tempAgendaHostImageUrl != null
                                                  ? DecorationImage(image: NetworkImage(_tempAgendaHostImageUrl!), fit: BoxFit.cover)
                                                  : null,
                                        ),
                                        child: _tempAgendaHostImageBytes == null && _tempAgendaHostImageUrl == null ? const Icon(Icons.add_a_photo, color: Colors.grey, size: 24) : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TextFormField(controller: _tempAgendaHostNameCtrl, decoration: _inputDecoration("Person Name", Icons.person).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
                                          const SizedBox(height: 8),
                                          TextFormField(controller: _tempAgendaHostRoleCtrl, decoration: _inputDecoration("Role (e.g. Main Guest, Host)", Icons.star).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      if (_tempAgendaHostNameCtrl.text.isNotEmpty) {
                                        setState(() {
                                          _agendaHosts.add({
                                            'name': _tempAgendaHostNameCtrl.text,
                                            'role': _tempAgendaHostRoleCtrl.text,
                                            'personImageBytes': _tempAgendaHostImageBytes,
                                            'personImageFile': _tempAgendaHostImageFile,
                                            'person_image_url': _tempAgendaHostImageUrl,
                                          });
                                          _tempAgendaHostNameCtrl.clear();
                                          _tempAgendaHostRoleCtrl.clear();
                                          _tempAgendaHostImageFile = null;
                                          _tempAgendaHostImageBytes = null;
                                          _tempAgendaHostImageUrl = null;
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text("Add to List"),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Future.delayed(Duration.zero, () {
                                    if (mounted) setState(() => _isAddingAgenda = false);
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  Future.delayed(Duration.zero, () {
                                    if (mounted) _saveAgenda();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check, size: 14, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text("Save Agenda", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),


              // Highlights Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text("Highlights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          if (_highlights.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(20)),
                              child: Text('${_highlights.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _isAddingHighlight ? null : () {
                          Future.delayed(Duration.zero, () {
                            if (mounted) setState(() => _isAddingHighlight = true);
                          });
                        },
                        icon: Icon(Icons.add, size: 18, color: _isAddingHighlight ? Colors.grey : AppColors.primary),
                        label: Text("Add Highlight", style: TextStyle(color: _isAddingHighlight ? Colors.grey : AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Existing Highlights
                  if (_highlights.isNotEmpty)
                    Column(
                      children: _highlights.asMap().entries.map((entry) {
                        final index = entry.key;
                        final h = entry.value;
                        if (_editingHighlightIndex == index) return const SizedBox.shrink();

                        return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.amber, width: 2), color: Colors.amber.withOpacity(0.08)),
                              child: const Icon(Icons.star_rounded, color: Colors.amber, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(h['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  if ((h['desc'] ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(h['desc'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                  ],
                                  const SizedBox(height: 6),
                                  Text("${((h['mediaFiles'] as List?)?.length ?? (h['media'] as List?)?.length ?? 0)} media items", style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                  if ((h['person_name'] ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.person, size: 14, color: Colors.amber),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${h['person_name']}${h['person_role'] != null && h['person_role'].toString().isNotEmpty ? ' (${h['person_role']})' : ''}",
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber.shade700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Future.delayed(Duration.zero, () {
                                      if (mounted) _editHighlightItem(index);
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Future.delayed(Duration.zero, () {
                                      if (mounted) {
                                        setState(() {
                                          _isAddingHighlight = false;
                                          _editingHighlightIndex = null;
                                        });
                                      }
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                      }).toList(),
                    )
                  else if (!_isAddingHighlight)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text("No highlights added. (Optional)", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ),

                  // Add Highlight Form
                  if (_isAddingHighlight)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("New Highlight", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.primary)),
                          const SizedBox(height: 16),
                          TextFormField(controller: _hlTitleCtrl, decoration: _inputDecoration("Highlight Name", Icons.star)),
                          const SizedBox(height: 12),
                          TextFormField(controller: _hlDescCtrl, decoration: _inputDecoration("Short Description", Icons.description)),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Highlight Media", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    ...List.generate(_hlExistingMedia.length, (index) {
                                      final m = _hlExistingMedia[index];
                                      final isVideo = m['type'] == 'video';
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 90,
                                            height: 90,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(10),
                                              image: !isVideo ? DecorationImage(image: NetworkImage(m['url']), fit: BoxFit.cover) : null,
                                            ),
                                            child: isVideo ? const Icon(Icons.videocam, size: 36, color: AppColors.primary) : null,
                                          ),
                                          Positioned(
                                            top: -8,
                                            right: -8,
                                            child: GestureDetector(
                                              onTap: () => _removeExistingHighlightMedia(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                    ...List.generate(_hlMediaBytes.length, (index) {
                                      final m = _hlMediaFiles[index];
                                      final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].any((ext) => m.name.toLowerCase().endsWith(ext));
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 90,
                                            height: 90,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(10),
                                              image: !isVideo ? DecorationImage(image: MemoryImage(_hlMediaBytes[index]), fit: BoxFit.cover) : null,
                                            ),
                                            child: isVideo ? const Icon(Icons.videocam, size: 36, color: AppColors.primary) : null,
                                          ),
                                          Positioned(
                                            top: -8,
                                            right: -8,
                                            child: GestureDetector(
                                              onTap: () => _removeHighlightMedia(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                    GestureDetector(
                                      onTap: _pickHighlightMedia,
                                      child: Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.primary.withOpacity(0.3), style: BorderStyle.solid),
                                        ),
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate, color: AppColors.primary, size: 28),
                                            SizedBox(height: 6),
                                            Text("Add Media", style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),
                          const Text("Person Spotlight (Optional)", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _pickHighlightPersonImage,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                    image: _hlPersonImageBytes != null
                                        ? DecorationImage(image: MemoryImage(_hlPersonImageBytes!), fit: BoxFit.cover)
                                        : _hlPersonImageUrl != null
                                            ? DecorationImage(image: NetworkImage(_hlPersonImageUrl!), fit: BoxFit.cover)
                                            : null,
                                  ),
                                  child: _hlPersonImageBytes == null && _hlPersonImageUrl == null ? const Icon(Icons.add_a_photo, color: Colors.grey, size: 24) : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    TextFormField(controller: _hlPersonNameCtrl, decoration: _inputDecoration("Person Name", Icons.person).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
                                    const SizedBox(height: 8),
                                    TextFormField(controller: _hlPersonRoleCtrl, decoration: _inputDecoration("Role (e.g. Main Guest, Host)", Icons.star).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Future.delayed(Duration.zero, () {
                                    if (mounted) setState(() => _isAddingHighlight = false);
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  Future.delayed(Duration.zero, () {
                                    if (mounted) _saveHighlight();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check, size: 14, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text("Save Highlight", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 32),
              
              // --- BEHIND THE EVENT SECTION ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Behind the Event",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      TextButton.icon(
                        onPressed: _isAddingBehindEvent ? null : () {
                          Future.delayed(Duration.zero, () {
                            if (mounted) setState(() => _isAddingBehindEvent = true);
                          });
                        },
                        icon: Icon(Icons.add, size: 18, color: _isAddingBehindEvent ? Colors.grey : AppColors.primary),
                        label: Text("Add Person", style: TextStyle(color: _isAddingBehindEvent ? Colors.grey : AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Existing Behind Events
                  if (_behindEvents.isNotEmpty)
                    Column(
                      children: _behindEvents.asMap().entries.map((entry) {
                        final index = entry.key;
                        final be = entry.value;
                        if (_editingBehindEventIndex == index) return const SizedBox.shrink();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: be['image_url'] != null ? NetworkImage(be['image_url']) : null,
                                child: be['image_url'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(be['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    if ((be['role'] ?? '').isNotEmpty)
                                      Text(be['role'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                    if ((be['department'] ?? '').isNotEmpty)
                                      Text(be['department'] ?? '', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                onPressed: () => _editBehindEventItem(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                onPressed: () {
                                  setState(() => _behindEvents.removeAt(index));
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    
                  if (!_isAddingBehindEvent && _behindEvents.isEmpty)
                    const Text('No persons added. (Optional)', style: TextStyle(color: Colors.grey, fontSize: 13)),

                  // Add Behind Event Form
                  if (_isAddingBehindEvent)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Person Details", style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 14)),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _pickBeImage,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                    image: _beImageBytes != null
                                        ? DecorationImage(image: MemoryImage(_beImageBytes!), fit: BoxFit.cover)
                                        : _beImageUrl != null
                                            ? DecorationImage(image: NetworkImage(_beImageUrl!), fit: BoxFit.cover)
                                            : null,
                                  ),
                                  child: _beImageBytes == null && _beImageUrl == null ? const Icon(Icons.add_a_photo, color: Colors.grey, size: 30) : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    TextFormField(controller: _beNameCtrl, decoration: _inputDecoration("Full Name", Icons.person).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
                                    const SizedBox(height: 8),
                                    TextFormField(controller: _beRoleCtrl, decoration: _inputDecoration("Role (e.g. Event Director)", Icons.work).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
                                    const SizedBox(height: 8),
                                    TextFormField(controller: _beDeptCtrl, decoration: _inputDecoration("Department/Group (Optional)", Icons.group).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Future.delayed(Duration.zero, () {
                                    if (mounted) setState(() => _isAddingBehindEvent = false);
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  Future.delayed(Duration.zero, () {
                                    if (mounted) _saveBehindEvent();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check, size: 14, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text("Save Person", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_editingEventId != null ? "Update Showcase" : "Save Showcase", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
  }

  @override
  Widget build(BuildContext context) {
    return _isAdding ? _buildAddForm() : _buildEventList();
  }
}
