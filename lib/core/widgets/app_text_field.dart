import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_svg_icon.dart';

/// Labelled input field from the auth/profile forms.
///
/// Layout (Figma): UPPERCASE [label] → 6 pt → white 52 pt field with a
/// [prefixIcon], optional "eye" toggle when [isPassword] is `true`, and an
/// optional [helperText] row with an info icon below.
///
/// It is a [StatefulWidget] because two pieces of UI state live here:
/// whether the password is hidden and whether the field has focus.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.controller,
    this.isPassword = false,
    this.helperText,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.enabled = true,
  });

  final String label;
  final String hintText;

  /// SVG asset path from [AppAssets].
  final String prefixIcon;
  final TextEditingController? controller;
  final bool isPassword;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();
  late bool _obscured = widget.isPassword;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  void _toggleObscured() {
    setState(() => _obscured = !_obscured);
  }

  @override
  Widget build(BuildContext context) {
    final String? helper = widget.helperText;
    return Opacity(
      opacity: widget.enabled ? 1 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              widget.label.toUpperCase(),
              style: AppTextStyles.fieldLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: AppSizes.fieldHeight,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.mdAll,
              boxShadow: AppShadows.subtle,
              border: Border.all(
                color: _focused ? AppColors.primary : AppColors.surface,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.l - 1),
                AppSvgIcon(widget.prefixIcon),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                    ),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      obscureText: _obscured,
                      obscuringCharacter: '•',
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      onSubmitted: widget.onSubmitted,
                      autofillHints: widget.autofillHints,
                      autocorrect: !widget.isPassword,
                      enableSuggestions: !widget.isPassword,
                      onTapOutside: (_) => _focusNode.unfocus(),
                      style: AppTextStyles.input,
                      decoration: InputDecoration.collapsed(
                        hintText: widget.hintText,
                        hintStyle: AppTextStyles.input.copyWith(
                          color: AppColors.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.isPassword)
                  _EyeButton(obscured: _obscured, onTap: _toggleObscured),
                // Right padding of the field (minus the 1 pt focus border).
                const SizedBox(width: AppSpacing.l - 1),
              ],
            ),
          ),
          if (helper != null) _HelperRow(text: helper),
        ],
      ),
    );
  }
}

/// 44×44 hit area around the 18×12 eye glyph (HIG minimum tap target).
class _EyeButton extends StatelessWidget {
  const _EyeButton({required this.obscured, required this.onTap});

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: obscured ? AppStrings.showPassword : AppStrings.hidePassword,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: AppSpacing.minTapTarget,
          child: Center(
            child: AppSvgIcon(
              AppAssets.iconEye,
              color: obscured ? AppColors.textTertiary : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _HelperRow extends StatelessWidget {
  const _HelperRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xs),
      child: Row(
        children: [
          const AppSvgIcon(AppAssets.iconInfo),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textHelper,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
