import os

files_to_create = {
    'lib/features/public/home/public_home_screen.dart': 'PublicHomeScreen',
    'lib/features/public/club_profile/club_public_profile_screen.dart': 'ClubPublicProfileScreen',
    'lib/features/auth/login/club_login_screen.dart': 'ClubLoginScreen',
    'lib/features/auth/register/club_register_screen.dart': 'ClubRegisterScreen',
    'lib/features/auth/register/registration_success_screen.dart': 'RegistrationSuccessScreen',
    'lib/features/dashboard/shell/dashboard_shell.dart': 'DashboardShell',
    'lib/features/dashboard/home/dashboard_home_screen.dart': 'DashboardHomeScreen',
    'lib/features/dashboard/members/members_screen.dart': 'MembersScreen',
    'lib/features/dashboard/finance/finance_screen.dart': 'FinanceScreen',
    'lib/features/dashboard/events/events_screen.dart': 'EventsScreen',
    'lib/features/dashboard/elections/elections_screen.dart': 'ElectionsScreen',
    'lib/features/dashboard/minutes/minutes_screen.dart': 'MeetingMinutesScreen',
    'lib/features/dashboard/profile/club_profile_edit_screen.dart': 'ClubProfileEditScreen',
    'lib/features/auth/login/pending_verification_screen.dart': 'PendingVerificationScreen',
}

template = """import 'package:flutter/material.dart';

class {CLASS_NAME} extends StatelessWidget {
  const {CLASS_NAME}({{super.key}});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{CLASS_NAME}')),
      body: const Center(child: Text('{CLASS_NAME} - placeholder')),
    );
  }
}
"""

shell_template = """import 'package:flutter/material.dart';

class {CLASS_NAME} extends StatelessWidget {
  final Widget child;
  const {CLASS_NAME}({{super.key, required this.child}});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Members'),
        ],
      ),
    );
  }
}
"""

profile_template = """import 'package:flutter/material.dart';

class {CLASS_NAME} extends StatelessWidget {
  final String id;
  const {CLASS_NAME}({{super.key, required this.id}});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{CLASS_NAME}')),
      body: Center(child: Text('{CLASS_NAME} for $id - placeholder')),
    );
  }
}
"""

for path, class_name in files_to_create.items():
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        if class_name == 'DashboardShell':
            f.write(shell_template.replace('{CLASS_NAME}', class_name))
        elif class_name == 'ClubPublicProfileScreen':
            f.write(profile_template.replace('{CLASS_NAME}', class_name))
        else:
            f.write(template.replace('{CLASS_NAME}', class_name))

print("Created placeholder files.")
