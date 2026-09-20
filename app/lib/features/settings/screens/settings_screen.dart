import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/storage_service.dart';
import '../../../router/app_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _smsSync = true;
  bool _notifications = true;

  Future<void> _clearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Clear all data?', style: AppTextStyles.headingSmall),
        content: Text(
          'This will delete all your transactions, categories and settings. This cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Clear data',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearAll();
      if (context.mounted) context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              Text('Settings', style: AppTextStyles.headingLarge),
              const SizedBox(height: 4),
              Text('Manage your Tajirika preferences',
                  style: AppTextStyles.bodyMedium),

              const SizedBox(height: 28),

              // Profile section
              _SettingsSection(
                title: 'Account',
                children: [
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    iconColor: AppColors.primary,
                    label: 'Change PIN',
                    onTap: () => context.go(AppRoutes.pinSetup),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Data section
              _SettingsSection(
                title: 'Data & Sync',
                children: [
                  _SettingsToggleTile(
                    icon: Icons.sms_outlined,
                    iconColor: const Color(0xFF64B5F6),
                    label: 'SMS sync',
                    subtitle: 'Read M-Pesa messages automatically',
                    value: _smsSync,
                    onChanged: (v) => setState(() => _smsSync = v),
                  ),
                  Divider(height: 1, color: AppColors.background, indent: 56),
                  _SettingsTile(
                    icon: Icons.sync_rounded,
                    iconColor: const Color(0xFF8BC4A0),
                    label: 'Sync now',
                    subtitle: 'Last synced: Today 9:14 AM',
                    onTap: () {},
                  ),
                  Divider(height: 1, color: AppColors.background, indent: 56),
                  _SettingsToggleTile(
                    icon: Icons.notifications_none_rounded,
                    iconColor: const Color(0xFFFFB74D),
                    label: 'Notifications',
                    subtitle: 'Spending alerts and weekly reports',
                    value: _notifications,
                    onChanged: (v) => setState(() => _notifications = v),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Merchant labels
              _SettingsSection(
                title: 'Merchants',
                children: [
                  _SettingsTile(
                    icon: Icons.storefront_outlined,
                    iconColor: const Color(0xFFBA68C8),
                    label: 'Merchant labels',
                    subtitle: 'View and edit your saved merchants',
                    onTap: () {},
                    showChevron: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // About section
              _SettingsSection(
                title: 'About',
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.textSecondary,
                    label: 'How the AI works',
                    onTap: () => _showHowItWorks(context),
                    showChevron: true,
                  ),
                  Divider(height: 1, color: AppColors.background, indent: 56),
                  _SettingsTile(
                    icon: Icons.tag_rounded,
                    iconColor: AppColors.textSecondary,
                    label: 'Version',
                    subtitle: 'Tajirika v1.0.0',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Danger zone
              _SettingsSection(
                title: 'Danger zone',
                children: [
                  _SettingsTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.error,
                    label: 'Clear all data',
                    labelColor: AppColors.error,
                    subtitle: 'Permanently delete everything',
                    onTap: () => _clearData(context),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Footer
              Center(
                child: Text(
                  'Made with care in Nairobi 🇰🇪',
                  style: AppTextStyles.labelSmall,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How Tajirika AI works',
                style: AppTextStyles.headingSmall),
            const SizedBox(height: 16),
            _HowItWorksItem(
              icon: Icons.phone_android_outlined,
              title: 'Reads on your phone',
              body:
                  'Your M-Pesa messages are read and parsed directly on your device. Nothing leaves your phone unprocessed.',
            ),
            const SizedBox(height: 12),
            _HowItWorksItem(
              icon: Icons.category_outlined,
              title: 'AI categorization',
              body:
                  'A machine learning model trained on Kenyan spending patterns assigns categories to each transaction.',
            ),
            const SizedBox(height: 12),
            _HowItWorksItem(
              icon: Icons.trending_up_rounded,
              title: 'Forecasting',
              body:
                  'Prophet, a time-series forecasting model, projects your future spend and calculates how long your money lasts.',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _HowItWorksItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text(body, style: AppTextStyles.bodyMedium.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Reusable Settings Widgets
// ─────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: AppTextStyles.labelSmall),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor,
    this.subtitle,
    required this.onTap,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontSize: 14,
                      color: labelColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style:
                          AppTextStyles.labelSmall.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      AppTextStyles.headingSmall.copyWith(fontSize: 14),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.labelSmall.copyWith(fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}