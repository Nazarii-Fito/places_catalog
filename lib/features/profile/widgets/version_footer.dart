import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../../app/app_scope.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_confirm_dialog.dart';

/// "PlacesCatalog · Version 1.0" at the bottom of Profile.
///
/// A long press opens a hidden developer menu to test Crashlytics. It is
/// only wired up in debug/profile builds (`kReleaseMode` → no gesture), so
/// a test crash can never reach real users.
class VersionFooter extends StatelessWidget {
  const VersionFooter({super.key});

  Future<void> _openDeveloperMenu(BuildContext context) async {
    final AppScope scope = AppScope.of(context);
    final _DevAction? action = await showCupertinoModalPopup<_DevAction>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text(AppStrings.developerTools),
        message: const Text(AppStrings.developerToolsMessage),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(_DevAction.nonFatal),
            child: const Text(AppStrings.sendTestError),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(_DevAction.crash),
            child: const Text(AppStrings.forceTestCrash),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
      ),
    );
    switch (action) {
      case _DevAction.nonFatal:
        await scope.crashReporter.sendTestNonFatal();
        if (!context.mounted) return;
        await AppConfirmDialog.show(
          context,
          title: AppStrings.testErrorSentTitle,
          message: AppStrings.testErrorSentMessage,
          confirmLabel: AppStrings.ok,
          cancelLabel: null,
        );
      case _DevAction.crash:
        await scope.crashReporter.log('Developer menu: forced test crash');
        scope.crashReporter.forceTestCrash();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: kReleaseMode ? null : () => _openDeveloperMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        child: Text(
          AppStrings.appVersion,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
        ),
      ),
    );
  }
}

enum _DevAction { nonFatal, crash }
