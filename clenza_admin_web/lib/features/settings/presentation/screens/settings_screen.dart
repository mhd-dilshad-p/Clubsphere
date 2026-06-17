import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/clay_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            Flex(
              direction: MediaQuery.of(context).size.width < 800 ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width < 800 ? double.infinity : MediaQuery.of(context).size.width * 0.55,
                  child: _buildSuperAdminManagement(),
                ),
                if (MediaQuery.of(context).size.width >= 800) const SizedBox(width: 32),
                if (MediaQuery.of(context).size.width < 800) const SizedBox(height: 32),
                Expanded(
                  flex: MediaQuery.of(context).size.width < 800 ? 0 : 1,
                  child: _buildSystemSettings(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClayCard(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform Settings',
                  style: AppTextStyles.display.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage super admins and system-wide configurations.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.settings_rounded, color: AppColors.primary, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperAdminManagement() {
    return ClayCard(
      color: AppColors.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 16),
              const Text('Super Admin Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Invite or remove platform owners who have full access to this dashboard.', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter email address...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppColors.darkBg.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text('Invite Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: Size.zero, // Override global theme's infinite width
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.success.withValues(alpha: 0.2),
                child: const Icon(Icons.person, color: AppColors.success),
              ),
              title: const Text('Platform Owner', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: const Text('owner@clenza.com', style: TextStyle(color: Colors.white70)),
              trailing: const Chip(
                label: Text('You', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.transparent,
                side: BorderSide(color: AppColors.success),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSystemSettings() {
    return ClayCard(
      color: AppColors.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.secondary, size: 24),
              ),
              const SizedBox(width: 16),
              const Text('System Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Allow New Club Registrations', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: const Text('When disabled, the registration form on the user app will be hidden.', style: TextStyle(fontSize: 12, color: Colors.white70)),
            value: true,
            onChanged: (val) {},
            activeThumbColor: AppColors.primary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: const Text('Enable to lock out non-super-admin users temporarily.', style: TextStyle(fontSize: 12, color: Colors.white70)),
            value: false,
            onChanged: (val) {},
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
