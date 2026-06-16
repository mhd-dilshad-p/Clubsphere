import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'core/constants/supabase_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/data/providers/admin_provider.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/dashboard/data/repositories/analytics_repository.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConstants.url,
    publishableKey: SupabaseConstants.anonKey,
  );

  runApp(const ClubSphereAdminApp());
}

class ClubSphereAdminApp extends StatelessWidget {
  const ClubSphereAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository(Supabase.instance.client)),
        Provider<AnalyticsRepository>(create: (_) => AnalyticsRepository(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => AdminProvider()..loadDashboardStats()),
      ],
      child: MaterialApp(
        title: 'ClubSphere Admin',
        theme: darkTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
