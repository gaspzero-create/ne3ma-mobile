import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class GaspTextField extends StatefulWidget {
  const GaspTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.borderColor,
    this.borderRadius,
    this.textColor,
    this.backgroundColor,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool enabled;
  final bool autofocus;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final Color? textColor;
  final Color? backgroundColor;

  @override
  State<GaspTextField> createState() => _GaspTextFieldState();
}

class _GaspTextFieldState extends State<GaspTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ──────────────────────────────────
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: AppSizes.xs + 2),

        // ── Input ──────────────────────────────────
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword ? _obscureText : false,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: widget.textColor ?? AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            filled: widget.backgroundColor != null,
            fillColor: widget.backgroundColor,
            hintText: widget.hint,
            hintStyle: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: AppSizes.iconMd,
                    color: AppColors.textSecondary,
                  )
                : null,
            suffixIcon: widget.isPassword
                ? GestureDetector(
                    onTap: () => setState(() => _obscureText = !_obscureText),
                    child: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: AppSizes.iconMd,
                      color: AppColors.textSecondary,
                    ),
                  )
                : widget.suffixIcon,
            // ── Border ──────────────────────────────
            border: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: widget.borderColor ?? AppColors.border,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: widget.borderColor ?? AppColors.border,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2.0,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(
                color: widget.borderColor ?? AppColors.border,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
          ),
        ),
      ],
    );
  }
}
