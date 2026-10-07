import 'package:flutter/cupertino.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_svg_icon.dart';

/// Grey iOS search bar with a magnifier and a clear button.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  void _clear() {
    controller.clear();
    onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.searchHeight,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppRadii.mdAll,
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.ml),
          const AppSvgIcon(AppAssets.iconSearch),
          const SizedBox(width: 11),
          Expanded(
            child: CupertinoTextField.borderless(
              controller: controller,
              onChanged: onChanged,
              padding: EdgeInsets.zero,
              placeholder: hintText,
              placeholderStyle: AppTextStyles.search.copyWith(
                color: AppColors.textTertiary,
              ),
              style: AppTextStyles.search,
              cursorColor: AppColors.primary,
              textInputAction: TextInputAction.search,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          // Rebuilds only the clear button when the text changes.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox(width: 36)
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _clear,
                    child: const SizedBox(
                      width: AppSpacing.minTapTarget,
                      height: AppSizes.searchHeight,
                      child: Icon(
                        CupertinoIcons.clear_circled_solid,
                        size: 17,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
