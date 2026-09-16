import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../../../router/app_router.dart';
import '../../../shared/widgets/pin_keypad.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  String _pin = '';
  String _errorMessage = '';
  int _attempts = 0;

  void _onKeyTap(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _errorMessage = '';
      });
      if (_pin.length == 4) {
        _validatePin();
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = '';
      });
    }
  }

  Future<void> _validatePin() async {
    final valid = await ref.read(authProvider.notifier).validatePin(_pin);
    if (valid) {
      if (mounted) context.go(AppRoutes.dashboard);
    } else {
      setState(() {
        _attempts++;
        _pin = '';
        _errorMessage = _attempts >= 3
            ? 'Too many attempts. Try again.'
            : 'Incorrect PIN. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 64),

              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 32),

              Text('Welcome back', style: AppTextStyles.headingLarge),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN to continue',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 48),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length
                          ? AppColors.pinFilled
                          : AppColors.pinEmpty,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),

              const Spacer(),

              PinKeypad(onKeyTap: _onKeyTap, onDelete: _onDelete),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
