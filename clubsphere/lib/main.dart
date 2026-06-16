import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'core/constants/supabase_constants.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/auth_session_provider.dart';
import 'core/providers/club_session_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    publishableKey: SupabaseConstants.anonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthSessionNotifier()),
        ChangeNotifierProxyProvider<AuthSessionNotifier, ClubSessionNotifier>(
          create: (_) => ClubSessionNotifier(),
          update: (_, auth, clubSession) => clubSession!..update(auth.currentUser),
        ),
        Provider<AppRouter>(
          create: (context) => AppRouter(
            context.read<AuthSessionNotifier>(),
            context.read<ClubSessionNotifier>(),
          ),
        ),
      ],
      child: const ClubSphereApp(),
    ),
  );
}

class ClubSphereApp extends StatelessWidget {
  const ClubSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.read<AppRouter>().router;

    return MaterialApp.router(
      title: AppStrings.appName,
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
