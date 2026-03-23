import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

enum GaspButtonVariant { primary, secondary, outline, text ,}

class GaspButton extends StatelessWidget {
  const GaspButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GaspButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.height = AppSizes.buttonHeight,
    this.width,
    this.buttonColor,
    this.textColor,
    this.borderRadius = AppSizes.radiusLg,
  });

  final String label;
  final VoidCallback? onPressed;
  final GaspButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double height;
  final double? width;
  final Color? buttonColor;
  final Color? textColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    final bool disabled = isDisabled || isLoading;
    final Color finalButtonColor = buttonColor ?? (disabled ? AppColors.border : AppColors.primary);
    final Color finalTextColor = textColor ?? Colors.white;

    switch (variant) {
      case GaspButtonVariant.primary:
        return ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: finalButtonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildChild(finalTextColor),
        );

      case GaspButtonVariant.secondary:
        return ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor ?? AppColors.primarySurface,
            foregroundColor: finalTextColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildChild(finalTextColor),
        );

      case GaspButtonVariant.outline:
        return OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: finalButtonColor,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildChild(finalTextColor),
        );

      case GaspButtonVariant.text:
        return TextButton(
          onPressed: disabled ? null : onPressed,
          child: _buildChild(finalTextColor),
        );
    }
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: color),
          const SizedBox(width: AppSizes.sm),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
      ),
    );
  }
}
