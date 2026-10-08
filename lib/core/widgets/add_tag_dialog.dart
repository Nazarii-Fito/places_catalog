import 'package:flutter/cupertino.dart';

import '../constants/app_strings.dart';

/// iOS alert with a text field for a new hashtag.
///
/// Resolves to the tag with a leading "#" (e.g. `#Brunch`), or `null` when
/// cancelled or left empty.
Future<String?> showAddTagDialog(BuildContext context) {
  return showCupertinoDialog<String>(
    context: context,
    builder: (BuildContext context) => const _AddTagDialog(),
  );
}

class _AddTagDialog extends StatefulWidget {
  const _AddTagDialog();

  @override
  State<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String text = _controller.text.trim().replaceAll('#', '');
    Navigator.of(context).pop(text.isEmpty ? null : '#$text');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(AppStrings.newTagTitle),
      content: Column(
        children: [
          const Text(AppStrings.newTagMessage),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _controller,
            autofocus: true,
            placeholder: AppStrings.newTagHint,
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('#'),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _submit,
          child: const Text(AppStrings.add),
        ),
      ],
    );
  }
}
