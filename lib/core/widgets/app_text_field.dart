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
/// Works inside a [Form]: it is built on [FormField], so
/// `FormState.validate()` runs [validator] and the message replaces the
/// helper row (red border + red text). [errorText] shows a server-side
/// error for this field (e.g. "wrong current password") the same way.
///
/// It is a [StatefulWidget] because UI state lives here: whether the
/// password is hidden and whether the field has focus.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.prefixIconColor,
    this.controller,
    this.isPassword = false,
    this.helperText,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.autofillHints,
    this.enabled = true,
    this.readOnly = false,
    this.validator,
    this.errorText,
  });

  final String label;
  final String hintText;

  /// SVG asset path from [AppAssets].
  final String prefixIcon;

  /// Tint for single-colour icons; `null` keeps the SVG's own colour.
  final Color? prefixIconColor;
  final TextEditingController? controller;
  final bool isPassword;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;

  /// `false` dims the field (e.g. read-only e-mail on Edit Profile).
  final bool enabled;

  /// Blocks editing without dimming — used while a form is submitting.
  final bool readOnly;

  /// Local format check, run by `FormState.validate()`.
  final FormFieldValidator<String>? validator;

  /// Error from the server for this field; wins over [validator].
  final String? errorText;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();
  TextEditingController? _ownController;
  late bool _obscured = widget.isPassword;
  bool _focused = false;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

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
    _ownController?.dispose();
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
    return FormField<String>(
      enabled: widget.enabled,
      // Always validate the controller text (it may be set in code).
      validator: (_) => widget.validator?.call(_controller.text),
      builder: (FormFieldState<String> field) {
        final String? error = widget.errorText ?? field.errorText;
        final String? helper = widget.helperText;
        final Color border = error != null
            ? AppColors.destructive
            : _focused
            ? AppColors.primary
            : AppColors.surface;
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
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.l - 1),
                    AppSvgIcon(
                      widget.prefixIcon,
                      color: widget.prefixIconColor,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          enabled: widget.enabled,
                          readOnly: widget.readOnly,
                          obscureText: _obscured,
                          obscuringCharacter: '•',
                          keyboardType: widget.keyboardType,
                          textInputAction: widget.textInputAction,
                          onSubmitted: widget.onSubmitted,
                          onChanged: (String value) {
                            field.didChange(value);
                            widget.onChanged?.call(value);
                          },
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
                    // Right padding of the field (minus the 1 pt border).
                    const SizedBox(width: AppSpacing.l - 1),
                  ],
                ),
              ),
              if (error != null)
                _HelperRow(text: error, isError: true)
              else if (helper != null)
                _HelperRow(text: helper),
            ],
          ),
        );
      },
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
  const _HelperRow({required this.text, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xs),
      child: Row(
        children: [
          AppSvgIcon(
            AppAssets.iconInfo,
            color: isError ? AppColors.destructive : null,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.footnote.copyWith(
                color: isError ? AppColors.destructive : AppColors.textHelper,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
