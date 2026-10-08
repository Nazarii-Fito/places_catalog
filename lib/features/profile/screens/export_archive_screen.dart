import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/nav_back_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_label.dart';
import '../../../data/models/place.dart';

/// "Export Places Archive" (FR2): shows the catalog as a JSON file preview
/// and copies it to the clipboard. No file system or backend is involved.
class ExportArchiveScreen extends StatelessWidget {
  const ExportArchiveScreen({super.key, required this.places});

  final List<Place> places;

  /// Plain map of one place — kept here because only the export needs it.
  static Map<String, Object?> _placeToJson(Place place) => {
    'id': place.id,
    'name': place.name,
    'category': place.category.name,
    'address': place.address,
    'visitDate': place.visitDate.toIso8601String().substring(0, 10),
    'isFavorite': place.isFavorite,
    'rating': place.review?.overallRating,
    'note': place.review?.textNote,
    'tags': place.review?.tags ?? const <String>[],
  };

  String get _json => const JsonEncoder.withIndent('  ').convert({
    'app': AppStrings.appName,
    'places': places.map(_placeToJson).toList(),
  });

  Future<void> _copy(BuildContext context, String json) async {
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) return;
    await AppConfirmDialog.show(
      context,
      title: AppStrings.copiedTitle,
      message: AppStrings.copiedMessage,
      confirmLabel: AppStrings.ok,
      cancelLabel: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String json = _json;
    final String sizeKb = (utf8.encode(json).length / 1024).toStringAsFixed(1);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavHeader(
        leading: NavBackButton(label: AppStrings.tabProfile),
      ),
      body: Builder(
        builder: (BuildContext context) {
          final EdgeInsets insets = MediaQuery.paddingOf(context);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              insets.top + AppSpacing.sm,
              AppSpacing.screen,
              insets.bottom + AppSpacing.xl,
            ),
            children: [
              const SizedBox(height: 4.5),
              Text(
                AppStrings.exportOverline.toUpperCase(),
                style: AppTextStyles.overline,
              ),
              const SizedBox(height: 1.5),
              const Text(
                AppStrings.exportTitle,
                style: AppTextStyles.largeTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.exportSubtitle,
                style: AppTextStyles.subheadline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _FileSummary(
                details:
                    '${places.length}${AppStrings.placesSuffix} · '
                    '$sizeKb${AppStrings.kilobytesSuffix}',
              ),
              const SizedBox(height: AppSpacing.l),
              const SectionLabel(AppStrings.jsonPreview),
              const SizedBox(height: AppSpacing.s),
              Container(
                height: 280,
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.mdAll,
                  boxShadow: AppShadows.group,
                ),
                child: SingleChildScrollView(
                  child: SelectableText(json, style: AppTextStyles.code),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: AppStrings.copyJson,
                onPressed: () => _copy(context, json),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FileSummary extends StatelessWidget {
  const _FileSummary({required this.details});

  final String details;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.mdAll,
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        spacing: AppSpacing.m,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const AppSvgIcon(
              AppAssets.iconDownload,
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.exportFileName,
                  style: AppTextStyles.headline,
                ),
                Text(
                  details,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
