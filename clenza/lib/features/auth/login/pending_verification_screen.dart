import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';

class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Pending'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Supabase.instance.client.auth.signOut();
            },
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_empty, size: 64, color: AppColors.accent),
              const SizedBox(height: 24),
              Text('Registration Submitted!', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text(
                'Your club registration is currently pending verification by a Super Admin.\n\nThis process usually takes 24-48 hours. You will be able to access your dashboard once approved.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () {
                  Supabase.instance.client.auth.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
