import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/public/home/public_home_screen.dart';
import '../../features/public/club_profile/club_public_profile_screen.dart';
import '../../features/public/club_profile/club_public_gallery_screen.dart';
import '../../features/auth/login/club_login_screen.dart';
import '../../features/auth/login/pending_verification_screen.dart';
import '../../features/auth/register/club_register_screen.dart';
import '../../features/auth/register/registration_success_screen.dart';
import '../../features/auth/register/setup_password_screen.dart';
import '../../features/public/club_profile/club_public_event_details_screen.dart';
import '../../features/public/club_profile/club_public_past_event_details_screen.dart';

import '../../features/dashboard/shell/dashboard_shell.dart';
import '../../features/dashboard/home/dashboard_home_screen.dart';
import '../../features/dashboard/members/members_screen.dart';
import '../../features/dashboard/finance/finance_screen.dart';
import '../../features/dashboard/events/events_screen.dart';
import '../../features/dashboard/elections/elections_screen.dart';
import '../../features/dashboard/minutes/minutes_screen.dart';
import '../../features/dashboard/profile/club_profile_edit_screen.dart';
import '../../features/dashboard/approvals/approvals_screen.dart';

import '../providers/auth_session_provider.dart';
import '../providers/club_session_provider.dart';

class AppRouter {
  final AuthSessionNotifier authSession;
  final ClubSessionNotifier clubSession;
  late final GoRouter router;

  AppRouter(this.authSession, this.clubSession) {
    router = GoRouter(
      initialLocation: '/',
      refreshListenable: Listenable.merge([authSession, clubSession]),
      redirect: (context, state) {
        final path = state.uri.path;
        final isGoingToDashboard = path.startsWith('/dashboard');
        final isGoingToLogin = path == '/login';
        
        final isAuth = authSession.currentUser != null;
        final isClubVerified = clubSession.state.verificationStatus == 'verified';
        final isLoading = clubSession.state.isLoading;
        
        if (isGoingToDashboard) {
          if (!isAuth) {
            return '/login';
          }
          if (!isLoading && !isClubVerified) {
            return '/pending';
          }
        } else if (isGoingToLogin) {
          if (isAuth && !isLoading) {
            if (isClubVerified) {
              return '/dashboard/home';
            } else {
              return '/pending';
            }
          }
        }
        
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PublicHomeScreen(),
        ),
        GoRoute(
          path: '/clubs',
          builder: (context, state) => const PublicHomeScreen(), // Placeholder or list
        ),
        GoRoute(
          path: '/clubs/:id',
          builder: (context, state) => ClubPublicProfileScreen(
            id: state.pathParameters['id']!,
            initialTab: state.uri.queryParameters['tab'],
          ),
        ),
        GoRoute(
          path: '/clubs/:id/gallery',
          builder: (context, state) => ClubPublicGalleryScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/clubs/:id/events/:eventId',
          builder: (context, state) => ClubPublicEventDetailsScreen(
            clubId: state.pathParameters['id']!,
            eventId: state.pathParameters['eventId']!,
          ),
        ),
        GoRoute(
          path: '/clubs/:id/past-events/:eventId',
          builder: (context, state) => ClubPublicPastEventDetailsScreen(
            clubId: state.pathParameters['id']!,
            eventId: state.pathParameters['eventId']!,
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const ClubLoginScreen(),
        ),
        GoRoute(
          path: '/pending',
          builder: (context, state) => const PendingVerificationScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const ClubRegisterScreen(),
        ),
        GoRoute(
          path: '/register/success',
          builder: (context, state) => const RegistrationSuccessScreen(),
        ),
        GoRoute(
          path: '/setup-password',
          builder: (context, state) => const SetupPasswordScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => DashboardShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard/home',
              builder: (context, state) => const DashboardHomeScreen(),
            ),
            GoRoute(
              path: '/dashboard/members',
              builder: (context, state) => const MembersScreen(),
            ),
            GoRoute(
              path: '/dashboard/finance',
              builder: (context, state) => const FinanceScreen(),
            ),
            GoRoute(
              path: '/dashboard/events',
              builder: (context, state) => const EventsScreen(),
            ),
            GoRoute(
              path: '/dashboard/elections',
              builder: (context, state) => const ElectionsScreen(),
            ),
            GoRoute(
              path: '/dashboard/minutes',
              builder: (context, state) => const MeetingMinutesScreen(),
            ),
            GoRoute(
              path: '/dashboard/profile',
              builder: (context, state) => const ClubProfileEditScreen(),
            ),
            GoRoute(
              path: '/dashboard/approvals',
              builder: (context, state) => const ApprovalsScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
