import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_text_link.dart';
import '../../../core/widgets/nav_back_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/user.dart';

/// Edit profile: name, e-mail and photo (opened by the pencil badge).
///
/// Receives the current [User] through route arguments and returns the
/// edited copy with `Navigator.pop(user)` — nothing is stored on a server.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final User user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.user.fullName,
  );
  late final TextEditingController _emailController = TextEditingController(
    text: widget.user.email,
  );
  late User _draft = widget.user;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final bool hasPhoto = _draft.avatarAsset != null;
    final bool? remove = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text(AppStrings.changePhoto),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: hasPhoto,
            onPressed: () => Navigator.of(context).pop(hasPhoto),
            child: Text(
              hasPhoto
                  ? AppStrings.removeProfilePhoto
                  : AppStrings.useDefaultPhoto,
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
      ),
    );
    if (remove == null) return;
    setState(() {
      _draft = remove
          ? _draft.copyWith(removeAvatar: true)
          : _draft.copyWith(avatarAsset: AppAssets.avatarNazariiFito);
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    // Empty fields keep the previous value — no validation in Lab 3.
    final User updated = _draft.copyWith(
      fullName: name.isEmpty ? null : name,
      email: email.isEmpty ? null : email,
    );
    final NavigatorState navigator = Navigator.of(context);
    await AppConfirmDialog.show(
      context,
      title: AppStrings.profileUpdatedTitle,
      message: AppStrings.profileUpdatedMessage,
      confirmLabel: AppStrings.ok,
      cancelLabel: null,
    );
    navigator.pop(updated);
  }

  @override
  Widget build(BuildContext context) {
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
            return ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  child: UserAvatar(
                    imageAsset: _draft.avatarAsset,
                    initials: _draft.initials,
                  ),
                ),
                Center(
                  child: AppTextLink(
                    label: AppStrings.changePhoto,
                    onTap: _changePhoto,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                AppTextField(
                  label: AppStrings.fullNameLabel,
                  hintText: AppStrings.fullNameHint,
                  prefixIcon: AppAssets.iconPerson,
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: AppSpacing.l),
                AppTextField(
                  label: AppStrings.emailLabel,
                  hintText: AppStrings.emailHint,
                  prefixIcon: AppAssets.iconMail,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: AppSpacing.l + AppSpacing.sm),
                PrimaryButton(label: AppStrings.saveChanges, onPressed: _save),
              ],
            );
          },
        ),
      ),
    );
  }
}
