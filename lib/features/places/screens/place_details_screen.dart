import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/nav_back_button.dart';
import '../../../core/widgets/pressable_opacity.dart';
import '../../../data/models/place.dart';
import '../../../data/models/place_category.dart';
import '../../../data/models/review.dart';
import '../place_details_args.dart';
import '../widgets/details_hero.dart';
import '../widgets/details_sections.dart';
import '../widgets/rating_summary_card.dart';

/// Place details (FR5, FR7): photo, ratings, notes, tags, map and delete.
///
/// Data arrives through route arguments ([PlaceDetailsArgs]); favourite and
/// delete actions are reported back to `MainShell` via callbacks.
class PlaceDetailsScreen extends StatefulWidget {
  const PlaceDetailsScreen({super.key, required this.args});

  final PlaceDetailsArgs args;

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  late Place _place = widget.args.place;

  void _toggleFavorite() {
    widget.args.onToggleFavorite(_place);
    setState(() => _place = _place.copyWith(isFavorite: !_place.isFavorite));
  }

  Future<void> _confirmDelete() async {
    final NavigatorState navigator = Navigator.of(context);
    final bool confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteDialogTitle,
      message: AppStrings.deleteDialogMessage,
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed) return;
    widget.args.onDelete(_place);
    navigator.pop();
  }

  // Editing notes/tags and opening Apple Maps are outside Lab 3 (no
  // business logic); the controls are shown as designed but inert.
  void _notImplemented() {}

  @override
  Widget build(BuildContext context) {
    final Review? review = _place.review;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavHeader(
        leading: NavBackButton(),
        title: AppStrings.placeDetails,
      ),
      body: Builder(
        builder: (BuildContext context) {
          final EdgeInsets insets = MediaQuery.paddingOf(context);
          return ListView(
            padding: EdgeInsets.only(top: insets.top),
            children: [
              DetailsHero(
                image: _place.heroImage,
                photosCount: _place.photosCount,
                isFavorite: _place.isFavorite,
                onBack: () => Navigator.of(context).maybePop(),
                onToggleFavorite: _toggleFavorite,
              ),
              // The sheet overlaps the photo by 24 pt, like in Figma.
              Transform.translate(
                offset: const Offset(0, -24),
                child: _DetailsSheet(
                  bottomInset: insets.bottom,
                  children: [
                    _TitleBlock(place: _place),
                    if (review != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      RatingSummaryCard(review: review),
                      const SizedBox(height: AppSpacing.xl),
                      NotesSection(
                        note: review.textNote,
                        updatedAt: review.updatedAt,
                        onEdit: _notImplemented,
                      ),
                      const SizedBox(height: AppSpacing.l),
                      TagsSection(tags: review.tags, onAddTag: _notImplemented),
                    ],
                    const SizedBox(height: 28),
                    LocationSection(
                      label: _shortAddress(_place.address),
                      onOpenMaps: _notImplemented,
                    ),
                    const SizedBox(height: 28),
                    _DeleteButton(onPressed: _confirmDelete),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// "424 Broome St, SoHo, Manhattan" → "424 Broome St, SoHo".
  static String _shortAddress(String address) =>
      address.split(', ').take(2).join(', ');
}

class _DetailsSheet extends StatelessWidget {
  const _DetailsSheet({required this.children, required this.bottomInset});

  final List<Widget> children;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + bottomInset - 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppShadows.sheet,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: SizedBox(
              width: 40,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.handle,
                  borderRadius: AppRadii.pillAll,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          ...children,
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.place});

  final Place place;

  static const Map<PlaceCategory, String> _categoryIcons = {
    PlaceCategory.cafe: AppAssets.iconCup,
    PlaceCategory.bakery: AppAssets.iconCup,
    PlaceCategory.museum: AppAssets.iconMuseum,
  };

  @override
  Widget build(BuildContext context) {
    final String area = place.address.split(', ').skip(1).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(place.name, style: AppTextStyles.placeTitle),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            _InfoChip(
              icon: AppSvgIcon(
                _categoryIcons[place.category] ?? AppAssets.iconForkKnife,
                height: 11.25,
              ),
              text: AppStrings.categorySingular[place.category] ?? '',
            ),
            _InfoChip(icon: const AppSvgIcon(AppAssets.iconPin), text: area),
          ],
        ),
        const SizedBox(height: AppSpacing.ml),
        Row(
          spacing: AppSpacing.sm,
          children: [
            const AppSvgIcon(AppAssets.iconCalendarCheck),
            Text(
              AppStrings.visitedOnPrefix + formatLongDate(place.visitDate),
              style: AppTextStyles.footnoteMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          icon,
          Text(
            text,
            style: AppTextStyles.footnoteMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: PressableOpacity(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: 13,
          ),
          decoration: const BoxDecoration(
            color: AppColors.destructiveContainer,
            borderRadius: AppRadii.lgAll,
            boxShadow: AppShadows.group,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              const AppSvgIcon(AppAssets.iconTrash),
              Text(
                AppStrings.deletePlace,
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
