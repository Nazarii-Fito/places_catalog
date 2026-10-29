import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/auth_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/nav_back_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/app_user.dart';
import '../widgets/avatar_picker.dart';

/// Edit profile: display name and photo, saved with
/// `AuthRepository.updateProfile` (Firebase `updateDisplayName` /
/// `updatePhotoURL`). The photo is a preset HTTPS avatar or a custom link
/// with a live preview; e-mail is read-only.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final AppUser _user = AppScope.of(context).auth.currentUser!;
  late final TextEditingController _nameController = TextEditingController(
    text: _user.displayName ?? '',
  );
  late final TextEditingController _emailController = TextEditingController(
    text: _user.email ?? '',
  );
  final TextEditingController _linkController = TextEditingController();

  late String? _preset = AppAssets.presetAvatarUrls.contains(_user.photoUrl)
      ? _user.photoUrl
      : null;
  bool _useCustomLink = false;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  /// The photo that would be saved now (null = keep the current one).
  String? get _photoUrl =>
      _useCustomLink ? _linkController.text.trim() : _preset;

  bool get _customLinkLooksValid =>
      Validators.httpsUrl(_linkController.text) == null;

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final AppScope scope = AppScope.of(context);
    final NavigatorState navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final String? photo = _photoUrl;
      await scope.auth.updateProfile(
        displayName: _nameController.text.trim(),
        photoUrl: photo == _user.photoUrl ? null : photo,
      );
      await scope.analytics.logProfileUpdated(
        photoSource: _useCustomLink
            ? 'custom'
            : _preset != null
            ? 'preset'
            : 'unchanged',
      );
      if (!mounted) return;
      await AppConfirmDialog.show(
        context,
        title: AppStrings.profileUpdatedTitle,
        message: AppStrings.profileUpdatedMessage,
        confirmLabel: AppStrings.ok,
        cancelLabel: null,
      );
      navigator.pop();
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? error = _error;
    final String? previewUrl = _useCustomLink
        ? (_customLinkLooksValid ? _linkController.text.trim() : null)
        : _preset ?? _user.photoUrl;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavHeader(
        leading: NavBackButton(label: AppStrings.tabProfile),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Builder(
          builder: (BuildContext context) {
            final EdgeInsets insets = MediaQuery.paddingOf(context);
            return Form(
              key: _formKey,
              autovalidateMode: _autovalidate,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  insets.top + AppSpacing.sm,
                  AppSpacing.screen,
                  insets.bottom + AppSpacing.xl,
                ),
                children: [
                  const SizedBox(height: 4.5),
                  Text(
                    AppStrings.accountOverline.toUpperCase(),
                    style: AppTextStyles.overline,
                  ),
                  const SizedBox(height: 1.5),
                  const Text(
                    AppStrings.editProfile,
                    style: AppTextStyles.largeTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.editProfileSubtitle,
                    style: AppTextStyles.subheadline.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: _useCustomLink && previewUrl != null
                        ? CustomPhotoPreview(url: previewUrl)
                        : UserAvatar(
                            imageUrl: previewUrl,
                            initials: _user.initials,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  const SectionLabel(AppStrings.choosePhoto),
                  const SizedBox(height: AppSpacing.m),
                  AvatarPicker(
                    urls: AppAssets.presetAvatarUrls,
                    selected: _useCustomLink ? null : _preset,
                    onSelected: (String url) => setState(() {
                      _preset = url;
                      _useCustomLink = false;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          AppStrings.useCustomLink,
                          style: AppTextStyles.body,
                        ),
                      ),
                      CupertinoSwitch(
                        value: _useCustomLink,
                        activeTrackColor: AppColors.primary,
                        onChanged: _saving
                            ? null
                            : (bool on) => setState(() => _useCustomLink = on),
                      ),
                    ],
                  ),
                  if (_useCustomLink) ...[
                    const SizedBox(height: AppSpacing.m),
                    AppTextField(
                      label: AppStrings.photoLinkLabel,
                      hintText: AppStrings.photoLinkHint,
                      prefixIcon: AppAssets.iconPhoto,
                      prefixIconColor: AppColors.textTertiary,
                      controller: _linkController,
                      readOnly: _saving,
                      validator: Validators.httpsUrl,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      // Rebuild so the preview follows the typed link.
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: AppStrings.fullNameLabel,
                    hintText: AppStrings.fullNameHint,
                    prefixIcon: AppAssets.iconPerson,
                    controller: _nameController,
                    readOnly: _saving,
                    validator: Validators.fullName,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.name],
                  ),
                  const SizedBox(height: AppSpacing.l),
                  AppTextField(
                    label: AppStrings.emailLabel,
                    hintText: AppStrings.emailHint,
                    prefixIcon: AppAssets.iconMail,
                    controller: _emailController,
                    enabled: false,
                    helperText: AppStrings.emailReadOnly,
                  ),
                  const SizedBox(height: AppSpacing.l + AppSpacing.sm),
                  if (error != null) ...[
                    ErrorBanner(message: error),
                    const SizedBox(height: AppSpacing.m),
                  ],
                  PrimaryButton(
                    label: AppStrings.saveChanges,
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
