import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../../core/constants/supabase_constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class RegisterState {
  final int currentStep;
  final bool isLoading;
  final String? errorMessage;
  final String? registerNumber;

  // Step 1: Club Details
  final String clubName;
  final String category;
  final String description;
  final DateTime? foundingDate;
  final String leadershipModel; // fixed/rotating
  final double termDurationMonths;

  // Step 2: Location
  final String addressLine1;
  final String addressLine2;
  final String area;
  final String city;
  final String district;
  final String state;
  final String pinCode;
  
  // Step 3: Contact & Logo
  final String clubEmail;
  final String clubPhone;
  final Uint8List? logoBytes;
  final String? logoFileName;
  final Uint8List? coverImageBytes;
  final String? coverImageFileName;
  
  // Step 4: Admin User Details
  final String adminName;
  final String adminEmail;
  final String adminPhone;
  final String adminPassword;

  RegisterState({
    this.currentStep = 0,
    this.isLoading = false,
    this.errorMessage,
    this.registerNumber,
    this.clubName = '',
    this.category = 'other',
    this.description = '',
    this.foundingDate,
    this.leadershipModel = 'rotating',
    this.termDurationMonths = 12.0,
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.area = '',
    this.city = '',
    this.district = 'Thiruvananthapuram',
    this.state = 'Kerala',
    this.pinCode = '',
    this.clubEmail = '',
    this.clubPhone = '',
    this.logoBytes,
    this.logoFileName,
    this.coverImageBytes,
    this.coverImageFileName,
    this.adminName = '',
    this.adminEmail = '',
    this.adminPhone = '',
    this.adminPassword = '',
  });

  RegisterState copyWith({
    int? currentStep,
    bool? isLoading,
    String? errorMessage,
    String? registerNumber,
    String? clubName,
    String? category,
    String? description,
    DateTime? foundingDate,
    String? leadershipModel,
    double? termDurationMonths,
    String? addressLine1,
    String? addressLine2,
    String? area,
    String? city,
    String? district,
    String? state,
    String? pinCode,
    String? clubEmail,
    String? clubPhone,
    Uint8List? logoBytes,
    String? logoFileName,
    Uint8List? coverImageBytes,
    String? coverImageFileName,
    String? adminName,
    String? adminEmail,
    String? adminPhone,
    String? adminPassword,
  }) {
    return RegisterState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      registerNumber: registerNumber ?? this.registerNumber,
      clubName: clubName ?? this.clubName,
      category: category ?? this.category,
      description: description ?? this.description,
      foundingDate: foundingDate ?? this.foundingDate,
      leadershipModel: leadershipModel ?? this.leadershipModel,
      termDurationMonths: termDurationMonths ?? this.termDurationMonths,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      area: area ?? this.area,
      city: city ?? this.city,
      district: district ?? this.district,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      clubEmail: clubEmail ?? this.clubEmail,
      clubPhone: clubPhone ?? this.clubPhone,
      logoBytes: logoBytes ?? this.logoBytes,
      logoFileName: logoFileName ?? this.logoFileName,
      coverImageBytes: coverImageBytes ?? this.coverImageBytes,
      coverImageFileName: coverImageFileName ?? this.coverImageFileName,
      adminName: adminName ?? this.adminName,
      adminEmail: adminEmail ?? this.adminEmail,
      adminPhone: adminPhone ?? this.adminPhone,
      adminPassword: adminPassword ?? this.adminPassword,
    );
  }
}

class RegisterNotifier extends ChangeNotifier {
  RegisterState _state = RegisterState();
  RegisterState get state => _state;

  void setStep(int step) {
    _state = _state.copyWith(currentStep: step);
    notifyListeners();
  }

  void updateField({
    String? clubName, String? category, String? description, DateTime? foundingDate,
    String? leadershipModel, double? termDurationMonths,
    String? addressLine1, String? addressLine2, String? area,
    String? city, String? district, String? state, String? pinCode,
    String? clubEmail, String? clubPhone, Uint8List? logoBytes, String? logoFileName,
    Uint8List? coverImageBytes, String? coverImageFileName,
    String? adminName, String? adminEmail, String? adminPhone, String? adminPassword,
  }) {
    _state = _state.copyWith(
      clubName: clubName, category: category, description: description, foundingDate: foundingDate,
      leadershipModel: leadershipModel, termDurationMonths: termDurationMonths,
      addressLine1: addressLine1, addressLine2: addressLine2, area: area,
      city: city, district: district, state: state, pinCode: pinCode,
      clubEmail: clubEmail, clubPhone: clubPhone, logoBytes: logoBytes, logoFileName: logoFileName,
      coverImageBytes: coverImageBytes, coverImageFileName: coverImageFileName,
      adminName: adminName, adminEmail: adminEmail, adminPhone: adminPhone, adminPassword: adminPassword,
      errorMessage: null, // Clear error on new input
    );
    notifyListeners();
  }

  Future<void> fetchCurrentLocation() async {
    try {
      _state = _state.copyWith(isLoading: true);
      notifyListeners();
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      } 

      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Match state name roughly to what is in our predefined map (e.g., remove " State" or ensure correct capitalization)
        String foundState = place.administrativeArea ?? 'Kerala';
        if (foundState.contains('Kerala')) foundState = 'Kerala';
        
        _state = _state.copyWith(
          addressLine1: place.street ?? _state.addressLine1,
          city: place.locality ?? _state.city,
          district: place.subAdministrativeArea ?? _state.district,
          state: foundState,
          pinCode: place.postalCode ?? _state.pinCode,
          isLoading: false,
          errorMessage: null,
        );
      } else {
        _state = _state.copyWith(isLoading: false, errorMessage: 'No address found for location.');
      }
    } catch (e) {
      _state = _state.copyWith(isLoading: false, errorMessage: e.toString());
    }
    notifyListeners();
  }

  Future<String?> submitRegistration() async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Create or get auth user
      String? userId;
      try {
        final authResponse = await supabase.auth.signUp(
          email: _state.adminEmail,
          password: _state.adminPassword,
          data: {'full_name': _state.adminName},
        );
        userId = authResponse.user?.id;
      } on AuthException catch (e) {
        if (e.statusCode == '422' || e.message.contains('User already registered') || e.code == 'user_already_exists') {
          // If the user already exists, try to sign them in to continue registration
          final signInResp = await supabase.auth.signInWithPassword(
            email: _state.adminEmail,
            password: _state.adminPassword,
          );
          userId = signInResp.user?.id;
        } else {
          rethrow;
        }
      }
      
      if (userId == null) throw Exception('Failed to create or authenticate admin user.');

      // 2. Upload Logo if present
      String? logoUrl;
      if (_state.logoBytes != null && _state.logoFileName != null) {
        final ext = _state.logoFileName!.split('.').last;
        final path = '$userId/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage.from(SupabaseConstants.clubsBucket).uploadBinary(path, _state.logoBytes!);
        logoUrl = supabase.storage.from(SupabaseConstants.clubsBucket).getPublicUrl(path);
      }
      
      // 2.5 Upload Cover Image if present
      String? coverImageUrl;
      if (_state.coverImageBytes != null && _state.coverImageFileName != null) {
        final ext = _state.coverImageFileName!.split('.').last;
        final path = '$userId/cover_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage.from(SupabaseConstants.clubsBucket).uploadBinary(path, _state.coverImageBytes!);
        coverImageUrl = supabase.storage.from(SupabaseConstants.clubsBucket).getPublicUrl(path);
      }

      final clubId = const Uuid().v4();
      final clubCode = 'CLB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13)}';

      // 3. Insert into clubs
      final clubData = {
        'id': clubId,
        'club_code': clubCode,
        'name': _state.clubName,
        'category': _state.category,
        'description': _state.description,
        'email': _state.clubEmail,
        'phone': _state.clubPhone,
        'address_line1': _state.addressLine1,
        'address_line2': _state.addressLine2,
        'area': _state.area,
        'city': _state.city,
        'district': _state.district,
        'state': _state.state,
        'pin_code': _state.pinCode,
        'logo_url': logoUrl,
        'cover_image_url': coverImageUrl,
        'verification_status': 'pending',
        'leadership_model': _state.leadershipModel,
        'term_duration_months': _state.termDurationMonths.toInt(),
        'enabled_roles': ['president', 'vice_president', 'secretary', 'treasurer', 'member'],
      };

      await supabase.from('clubs').insert(clubData);

      // 4. Insert into club_members
      await supabase.from('club_members').insert({
        'club_id': clubId,
        'user_id': userId,
        'role': 'founding_admin',
        'full_name': _state.adminName,
        'email': _state.adminEmail,
        'phone': _state.adminPhone,
        'is_active': true,
      });

      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return clubCode;
    } catch (e) {
      _state = _state.copyWith(isLoading: false, errorMessage: e.toString());
      notifyListeners();
      return null;
    }
  }
}
