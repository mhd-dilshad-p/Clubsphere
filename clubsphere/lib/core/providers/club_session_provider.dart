import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClubSessionState {
  final bool isLoading;
  final String? clubId;
  final String? clubName;
  final String? userRole;
  final String? memberId;
  final String? memberName;
  final String? verificationStatus;

  ClubSessionState({
    this.isLoading = true,
    this.clubId,
    this.clubName,
    this.userRole,
    this.memberId,
    this.memberName,
    this.verificationStatus,
  });

  ClubSessionState copyWith({
    bool? isLoading,
    String? clubId,
    String? clubName,
    String? userRole,
    String? memberId,
    String? memberName,
    String? verificationStatus,
  }) {
    return ClubSessionState(
      isLoading: isLoading ?? this.isLoading,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      userRole: userRole ?? this.userRole,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }
}

class ClubSessionNotifier extends ChangeNotifier {
  ClubSessionState _state = ClubSessionState();
  ClubSessionState get state => _state;
  
  String? get clubId => _state.clubId;
  String? get clubName => _state.clubName;
  String? get userRole => _state.userRole;
  String? get memberId => _state.memberId;
  String? get memberName => _state.memberName;
  String? get verificationStatus => _state.verificationStatus;
  bool get isLoading => _state.isLoading;
  
  User? _currentUser;
  
  void update(User? user) {
    if (_currentUser?.id == user?.id) return;
    _currentUser = user;
    _init();
  }

  Future<void> _init() async {
    if (_currentUser == null) {
      _state = ClubSessionState(isLoading: false);
      notifyListeners();
      return;
    }
    
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      
      final member = await supabase
          .from('club_members')
          .select('*, clubs(*)')
          .eq('user_id', _currentUser!.id)
          .eq('is_active', true)
          .maybeSingle();

      if (member != null) {
        final club = member['clubs'];
        _state = _state.copyWith(
          isLoading: false,
          clubId: club['id'],
          clubName: club['name'],
          verificationStatus: club['verification_status'],
          userRole: member['role'],
          memberId: member['id'],
          memberName: member['full_name'],
        );
      } else {
        _state = _state.copyWith(isLoading: false);
      }
    } catch (e) {
      _state = _state.copyWith(isLoading: false);
    }
    notifyListeners();
  }

  void clear() {
    _state = ClubSessionState(isLoading: false);
    notifyListeners();
  }
}
