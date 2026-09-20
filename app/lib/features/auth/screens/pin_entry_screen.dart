import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/pin_keypad.dart';
import '../providers/auth_provider.dart';
import '../../../router/app_router.dart';

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
      if (_pin.length == 4) _validatePin();
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
              const SizedBox(height: 56),

              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),

              const SizedBox(height: 32),

              Text('Welcome back', style: AppTextStyles.headingLarge),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN to continue',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 52),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: filled ? 20 : 16,
                    height: filled ? 20 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          filled ? AppColors.pinFilled : AppColors.pinEmpty,
                      boxShadow: filled
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                              )
                            ]
                          : null,
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

              PinKeypad(
                onKeyTap: _onKeyTap,
                onDelete: _onDelete,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}