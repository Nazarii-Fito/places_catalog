import 'package:flutter/cupertino.dart';

import '../constants/app_strings.dart';

/// Centered iOS alert used for confirmations ("Log Out?", "Delete Place?")
/// and simple notices ("Password Updated").
///
/// HIG: destructive actions are confirmed with an alert, never a snackbar;
/// the destructive button is red ([isDestructive]).
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel,
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;

  /// `null` → a single-button notice without "Cancel".
  final String? cancelLabel;
  final bool isDestructive;

  /// Shows the dialog; resolves to `true` when the user confirms.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String? cancelLabel = AppStrings.cancel,
    bool isDestructive = false,
  }) async {
    final bool? result = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final String? cancel = cancelLabel;
    return CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        if (cancel != null)
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancel),
          ),
        CupertinoDialogAction(
          isDefaultAction: !isDestructive,
          isDestructiveAction: isDestructive,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
