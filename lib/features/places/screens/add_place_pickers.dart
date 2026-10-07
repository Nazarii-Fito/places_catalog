import 'package:flutter/cupertino.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/place_category.dart';

/// iOS action sheet listing every [PlaceCategory]; resolves to the choice
/// or `null` when cancelled.
Future<PlaceCategory?> showCategoryPicker(
  BuildContext context,
  PlaceCategory current,
) {
  return showCupertinoModalPopup<PlaceCategory>(
    context: context,
    builder: (BuildContext context) => CupertinoActionSheet(
      title: const Text(AppStrings.category),
      actions: PlaceCategory.values
          .map(
            (PlaceCategory c) => CupertinoActionSheetAction(
              isDefaultAction: c == current,
              onPressed: () => Navigator.of(context).pop(c),
              child: Text(AppStrings.categorySingular[c] ?? c.name),
            ),
          )
          .toList(),
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(AppStrings.cancel),
      ),
    ),
  );
}

/// Bottom wheel date picker with a "Done" button.
Future<DateTime?> showVisitDatePicker(BuildContext context, DateTime initial) {
  DateTime selected = initial;
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (BuildContext context) => Container(
      height: 300,
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                onPressed: () => Navigator.of(context).pop(selected),
                child: const Text(AppStrings.done),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                maximumYear: 2100,
                onDateTimeChanged: (DateTime value) => selected = value,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
