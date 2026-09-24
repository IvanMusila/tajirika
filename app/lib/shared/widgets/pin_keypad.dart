import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class PinKeypad extends StatelessWidget {
  final Function(String) onKeyTap;
  final VoidCallback onDelete;

  const PinKeypad({
    super.key,
    required this.onKeyTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map(
          (digit) => _KeypadButton(
            label: digit,
            onTap: () => onKeyTap(digit),
          ),
        ),
        const SizedBox(),
        _KeypadButton(label: '0', onTap: () => onKeyTap('0')),
        _KeypadButton(
          icon: Icons.backspace_outlined,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const KeypadButton({
    super.key,
    this.label,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _KeypadButton(label: label, icon: icon, onTap: onTap);
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeypadButton({
    this.label,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      splashColor: AppColors.primaryLight,
      child: Center(
        child: icon != null
            ? Icon(icon, color: AppColors.textPrimary, size: 22)
            : Text(
                label!,
                style: AppTextStyles.headingLarge,
              ),
      ),
    );
  }
}