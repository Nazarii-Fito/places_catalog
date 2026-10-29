import 'package:flutter/cupertino.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// 4 × 2 grid of preset avatars (fixed HTTPS links). The selected one has a
/// blue ring. No file upload — that comes with Firebase Storage later.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.urls,
    required this.selected,
    required this.onSelected,
  });

  final List<String> urls;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.m,
      alignment: WrapAlignment.center,
      children: [
        for (final (int i, String url) in urls.indexed)
          Semantics(
            button: true,
            selected: url == selected,
            label: '${AppStrings.presetAvatar} ${i + 1}',
            child: GestureDetector(
              onTap: () => onSelected(url),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 2,
                    color: url == selected
                        ? AppColors.primary
                        : AppColors.transparent,
                  ),
                ),
                child: ClipOval(
                  child: ColoredBox(
                    color: AppColors.surfaceContainerHigh,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, Widget child, ImageChunkEvent? p) =>
                          p == null
                          ? child
                          : const Center(child: CupertinoActivityIndicator()),
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Preview of a custom image link: spinner while loading, a clear message
/// when the link is broken or not an image.
class CustomPhotoPreview extends StatelessWidget {
  const CustomPhotoPreview({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: AppRadii.mdAll,
      ),
      child: Image.network(
        url,
        key: ValueKey<String>(url),
        fit: BoxFit.cover,
        loadingBuilder: (_, Widget child, ImageChunkEvent? progress) =>
            progress == null
            ? child
            : const Center(child: CupertinoActivityIndicator()),
        errorBuilder: (_, _, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Center(
            child: Text(
              AppStrings.imageLoadFailed,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.destructive,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
