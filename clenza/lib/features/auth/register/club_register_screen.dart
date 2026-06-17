import 'dart:ui';
import 'package:clenza/core/widgets/animated_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/indian_states_districts.dart';
import 'register_provider.dart';
import 'package:provider/provider.dart';

class ClubRegisterScreen extends StatelessWidget {
  const ClubRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterNotifier(),
      child: const _ClubRegisterView(),
    );
  }
}

class _ClubRegisterView extends StatefulWidget {
  const _ClubRegisterView();

  @override
  State<_ClubRegisterView> createState() => _ClubRegisterViewState();
}

class _ClubRegisterViewState extends State<_ClubRegisterView> {
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  final List<String> _stepTitles = [
    "Club Details",
    "Location",
    "Contact & Logo",
    "Founding Admin"
  ];

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<RegisterNotifier>();
    final state = notifier.state;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Register Club', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: Stack(
        children: [
          // Background Animation
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Lottie.asset(
                'assets/animations/sport and arts/arts.json', 
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Glassmorphism Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
          
          SafeArea(
            child: state.isLoading
                ? _buildLoadingState()
                : Column(
                    children: [
                      _buildProgressBar(state.currentStep),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                              child: FadeTransition(opacity: animation, child: child),
                            );
                          },
                          child: SingleChildScrollView(
                            key: ValueKey<int>(state.currentStep),
                            padding: const EdgeInsets.all(24.0),
                            child: _buildCurrentStepForm(state, notifier),
                          ),
                        ),
                      ),
                      _buildBottomNavigation(state, notifier),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/sending_loading.json', width: 200),
          const SizedBox(height: 24),
          const Text("Processing Registration...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2.seconds),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int currentStep) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Step ${currentStep + 1} of ${_stepTitles.length + 1}",
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            currentStep < _stepTitles.length ? _stepTitles[currentStep] : "Review",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(_stepTitles.length + 1, (index) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  height: 6,
                  decoration: BoxDecoration(
                    color: index <= currentStep ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ).animate(target: index <= currentStep ? 1 : 0).tint(color: AppColors.primary),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepForm(RegisterState state, RegisterNotifier notifier) {
    switch (state.currentStep) {
      case 0: return _buildStep1(state, notifier);
      case 1: return _buildStep2(state, notifier);
      case 2: return _buildStep3(state, notifier);
      case 3: return _buildStep4(state, notifier);
      case 4: return _buildReviewStep(state);
      default: return const SizedBox.shrink();
    }
  }

  // === STEP 1: Club Details (Category Cards & Animated Calendar) ===
  Widget _buildStep1(RegisterState state, RegisterNotifier notifier) {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: 'Club Name *',
            initialValue: state.clubName,
            icon: Icons.business,
            onChanged: (v) => notifier.updateField(clubName: v),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ).animate().fadeIn().slideY(begin: 0.2),
          
          const SizedBox(height: 24),
          const Text("Category *", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildCategoryCards(state, notifier).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
          
          const SizedBox(height: 24),
          _buildTextField(
            label: 'Description',
            initialValue: state.description,
            icon: Icons.description,
            maxLines: 3,
            onChanged: (v) => notifier.updateField(description: v),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

          const SizedBox(height: 24),
          const Text("Founding Date *", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildAnimatedCalendar(state, notifier).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
          
          const SizedBox(height: 24),
          const Text("Leadership Model *", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildLeadershipCards(state, notifier).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          
          const SizedBox(height: 24),
          Text(
            state.termDurationMonths < 12 
              ? 'Term Duration: ${state.termDurationMonths.toInt()} months'
              : 'Term Duration: ${(state.termDurationMonths / 12).toStringAsFixed(1)} years', 
            style: const TextStyle(fontWeight: FontWeight.bold)
          ),
          Slider(
            value: state.termDurationMonths,
            min: 1, max: 60, divisions: 59,
            activeColor: AppColors.primary,
            label: '${state.termDurationMonths.toInt()} mo',
            onChanged: (v) => notifier.updateField(termDurationMonths: v),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildCategoryCards(RegisterState state, RegisterNotifier notifier) {
    final categories = ['other', 'arts', 'sports', 'cultural', 'social_welfare'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.map((cat) {
        final isSelected = state.category == cat;
        return GestureDetector(
          onTap: () => notifier.updateField(category: cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (isSelected)
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))
                else
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
              ],
              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(cat), 
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  cat == 'other' ? 'GENERAL' : (cat == 'social_welfare' ? 'WELFARE' : cat.toUpperCase()),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'arts': return Icons.palette;
      case 'sports': return Icons.sports_soccer;
      case 'cultural': return Icons.theater_comedy;
      case 'social_welfare': return Icons.volunteer_activism;
      default: return Icons.category;
    }
  }

  Widget _buildLeadershipCards(RegisterState state, RegisterNotifier notifier) {
    final models = [
      {'id': 'fixed', 'title': 'Fixed Term', 'icon': Icons.lock_clock},
      {'id': 'rotating', 'title': 'Rotating', 'icon': Icons.autorenew},
    ];
    return Row(
      children: models.map((model) {
        final isSelected = state.leadershipModel == model['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => notifier.updateField(leadershipModel: model['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))
                  else
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
                ],
                border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    model['icon'] as IconData, 
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    model['title'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnimatedCalendar(RegisterState state, RegisterNotifier notifier) {
    return GestureDetector(
      onTap: () async {
        final date = await showGeneralDialog<DateTime>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Calendar',
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, anim1, anim2) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppColors.primary),
                      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CalendarDatePicker(
                        initialDate: state.foundingDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        onDateChanged: (d) => Navigator.pop(context, d),
                      ),
                    ),
                  ),
                ).animate().scale(curve: Curves.easeOutBack).fadeIn(),
              ),
            );
          },
        );
        if (date != null) notifier.updateField(foundingDate: date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.gradient1,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Date", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    state.foundingDate != null ? DateFormat.yMMMMd().format(state.foundingDate!) : 'Tap to pick date',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Icon(Icons.touch_app, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  // === STEP 2: Location (Geolocator, State/District Dropdowns, Pinput) ===
  Widget _buildStep2(RegisterState state, RegisterNotifier notifier) {
    List<String> availableDistricts = IndianStatesDistricts.stateDistrictMap[state.state] ?? [];
    if (availableDistricts.isEmpty) {
      availableDistricts = [state.district.isNotEmpty ? state.district : 'Other'];
    }
    
    String currentDistrict = state.district;
    if (!availableDistricts.contains(currentDistrict)) {
      currentDistrict = availableDistricts.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.updateField(district: currentDistrict);
      });
    }

    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ElevatedButton.icon(
              onPressed: () => notifier.fetchCurrentLocation(),
              icon: const Icon(Icons.my_location),
              label: const Text("Use Current Location (Auto-fill)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 4,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ).animate().shimmer(duration: 2.seconds, delay: 1.seconds),
          ),
          const SizedBox(height: 24),
          
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(state.errorMessage!, style: const TextStyle(color: Colors.red)),
            ),

          _buildTextField(
            label: 'Address Line 1 *',
            initialValue: state.addressLine1,
            icon: Icons.location_on,
            onChanged: (v) => notifier.updateField(addressLine1: v),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ).animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 16),
          
          _buildTextField(
            label: 'Address Line 2',
            initialValue: state.addressLine2,
            icon: Icons.add_location,
            onChanged: (v) => notifier.updateField(addressLine2: v),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),

          _buildTextField(
            label: 'City *',
            initialValue: state.city,
            icon: Icons.location_city,
            onChanged: (v) => notifier.updateField(city: v),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: state.state,
                  isExpanded: true,
                  decoration: _inputDecoration("State *", Icons.map),
                  items: IndianStatesDistricts.stateDistrictMap.keys.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      notifier.updateField(state: v);
                    }
                  },
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: currentDistrict,
                  isExpanded: true,
                  decoration: _inputDecoration("District *", Icons.terrain),
                  items: availableDistricts.map((d) {
                    return DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (v) => notifier.updateField(district: v),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text("Pin Code *", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Center(
            child: Pinput(
              length: 6,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              defaultPinTheme: PinTheme(
                width: 48,
                height: 56,
                textStyle: const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w600),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 52,
                height: 60,
                textStyle: const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w600),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))
                  ]
                ),
              ),
              onChanged: (v) => notifier.updateField(pinCode: v),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  // === STEP 3: Contact & Logo ===
  Widget _buildStep3(RegisterState state, RegisterNotifier notifier) {
    return Form(
      key: _formKeys[2],
      child: Column(
        children: [
          _buildTextField(
            label: 'Club Email (Optional)',
            initialValue: state.clubEmail,
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            onChanged: (v) => notifier.updateField(clubEmail: v),
            validator: (v) {
              if (v != null && v.isNotEmpty && !v.endsWith('@gmail.com')) {
                return 'Must be a valid @gmail.com address';
              }
              return null;
            },
          ).animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Club Phone (Optional)',
            initialValue: state.clubPhone,
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            onChanged: (v) => notifier.updateField(clubPhone: v),
            validator: (v) {
              if (v != null && v.isNotEmpty && v.length != 10) {
                return 'Phone number must be exactly 10 digits';
              }
              return null;
            },
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
          const SizedBox(height: 32),
          
          Text("Club Media", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Upload
              Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final xfile = await picker.pickImage(source: ImageSource.gallery);
                      if (xfile != null) {
                        final bytes = await xfile.readAsBytes();
                        notifier.updateField(logoBytes: bytes, logoFileName: xfile.name);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 8))
                        ],
                        image: state.logoBytes != null 
                          ? DecorationImage(image: MemoryImage(state.logoBytes!), fit: BoxFit.cover) 
                          : null,
                      ),
                      child: state.logoBytes == null 
                        ? const Icon(Icons.shield, size: 40, color: AppColors.primary)
                        : null,
                    ),
                  ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 8),
                  const Text("Logo", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              
              const SizedBox(width: 32),
              
              // Cover Image Upload
              Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final xfile = await picker.pickImage(source: ImageSource.gallery);
                      if (xfile != null) {
                        final bytes = await xfile.readAsBytes();
                        notifier.updateField(coverImageBytes: bytes, coverImageFileName: xfile.name);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 160,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary, width: 2),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 8))
                        ],
                        image: state.coverImageBytes != null 
                          ? DecorationImage(image: MemoryImage(state.coverImageBytes!), fit: BoxFit.cover) 
                          : null,
                      ),
                      child: state.coverImageBytes == null 
                        ? const Icon(Icons.image, size: 40, color: AppColors.primary)
                        : null,
                    ),
                  ).animate().scale(delay: 300.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 8),
                  const Text("Cover Photo", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === STEP 4: Founding Admin ===
  Widget _buildStep4(RegisterState state, RegisterNotifier notifier) {
    return Form(
      key: _formKeys[3],
      child: Column(
        children: [
          _buildTextField(
            label: 'Full Name *',
            initialValue: state.adminName,
            icon: Icons.person,
            onChanged: (v) => notifier.updateField(adminName: v),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ).animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Personal Email * (Login ID)',
            initialValue: state.adminEmail,
            icon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            onChanged: (v) => notifier.updateField(adminEmail: v),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!v.endsWith('@gmail.com')) return 'Must be a valid @gmail.com address';
              return null;
            },
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Password * (min 8 chars)',
            initialValue: state.adminPassword,
            icon: Icons.lock,
            obscureText: true,
            textCapitalization: TextCapitalization.none,
            onChanged: (v) => notifier.updateField(adminPassword: v),
            validator: (v) => (v == null || v.length < 8) ? 'Min 8 chars required' : null,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Phone *',
            initialValue: state.adminPhone,
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            onChanged: (v) => notifier.updateField(adminPhone: v),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length != 10) return 'Phone number must be exactly 10 digits';
              return null;
            },
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  // === STEP 5: Review Step ===
  Widget _buildReviewStep(RegisterState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.verified, size: 64, color: Colors.green).animate().scale(curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        const Text("Review Your Information", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        
        _buildReviewCard("Club Details", Icons.business, [
          "Name: ${state.clubName}",
          "Category: ${state.category.toUpperCase()}",
          "Model: ${state.leadershipModel} (${state.termDurationMonths.toInt()} months)",
        ]).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
        
        const SizedBox(height: 16),
        _buildReviewCard("Location", Icons.location_on, [
          "${state.addressLine1}, ${state.city}",
          "${state.district}, ${state.state} - ${state.pinCode}",
        ]).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
        
        const SizedBox(height: 16),
        _buildReviewCard("Admin Info", Icons.person, [
          "Name: ${state.adminName}",
          "Email: ${state.adminEmail}",
        ]).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),

        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Text(state.errorMessage!, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
      ],
    );
  }

  Widget _buildReviewCard(String title, IconData icon, List<String> details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...details.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(d, style: TextStyle(color: Colors.grey.shade700)),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === Helper Widgets ===
  Widget _buildTextField({
    required String label,
    required String initialValue,
    required IconData icon,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.words,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      decoration: _inputDecoration(label, icon),
      validator: validator,
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  // === Bottom Navigation ===
  Widget _buildBottomNavigation(RegisterState state, RegisterNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (state.currentStep > 0)
              OutlinedButton(
                onPressed: () => notifier.setStep(state.currentStep - 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.arrow_back),
              ),
            if (state.currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradient1,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    if (state.currentStep < 4) {
                      if (_formKeys[state.currentStep].currentState!.validate()) {
                        notifier.setStep(state.currentStep + 1);
                      }
                    } else {
                      final clubCode = await notifier.submitRegistration();
                      if (clubCode != null && mounted) {
                        CustomToast.showSuccess(context, 'Registration submitted! Your Club Code is: $clubCode. Please save it. Waiting for admin approval.');
                        context.go('/dashboard/home');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    state.currentStep == 4 ? 'Submit Application' : 'Next Step',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
