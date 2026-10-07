import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/nav_back_button.dart';
import '../../../core/widgets/pressable_opacity.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/place_category.dart';
import '../widgets/form_group.dart';
import '../widgets/photo_picker_panel.dart';
import '../widgets/star_rating_input.dart';
import '../widgets/tag_editor.dart';
import 'add_place_pickers.dart';

/// New place record (FR4, FR8). Pure UI state: photos, fields, ratings,
/// notes and tags change with `setState`; "Save" just closes the screen.
class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  static const int _maxPhotos = 5;
  static const List<String> _demoPhotos = [
    AppAssets.photoCoffee,
    AppAssets.photoPasta,
    AppAssets.photoStorefront,
  ];

  final TextEditingController _nameController = TextEditingController(
    text: AppStrings.placeNameHint,
  );
  final TextEditingController _notesController = TextEditingController(
    text: AppStrings.defaultNote,
  );
  final TextEditingController _tagController = TextEditingController();

  List<String> _photos = List.of(_demoPhotos);
  PlaceCategory _category = PlaceCategory.cafe;
  String _location = AppStrings.defaultLocation;
  DateTime _visitDate = DateTime(2026, 9, 24);
  final Map<String, int> _ratings = {
    AppStrings.ratingFood: 5,
    AppStrings.ratingService: 4,
    AppStrings.ratingAtmosphere: 5,
  };
  List<String> _tags = [
    '#Espresso',
    '#Pastries',
    '#QuietWork',
    '#NaturalLight',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  double get _averageRating =>
      _ratings.values.reduce((int a, int b) => a + b) / _ratings.length;

  void _addPhoto() => setState(() {
    _photos = [..._photos, _demoPhotos[_photos.length % _demoPhotos.length]];
  });

  void _removePhoto(int index) => setState(() {
    _photos = [..._photos]..removeAt(index);
  });

  Future<void> _pickCategory() async {
    final PlaceCategory? picked = await showCategoryPicker(context, _category);
    if (picked != null) setState(() => _category = picked);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showVisitDatePicker(context, _visitDate);
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _pickLocation() async {
    final Object? result = await Navigator.of(context)
        .pushNamed(AppRoutes.locationPicker);
    if (result is String) setState(() => _location = result);
  }

  void _addTag(String raw) {
    final String text = raw.trim().replaceAll('#', '');
    if (text.isEmpty) return;
    setState(() => _tags = [..._tags, '#$text']);
    _tagController.clear();
  }

  void _removeTag(String tag) =>
      setState(() => _tags = _tags.where((String t) => t != tag).toList());

  @override
  Widget build(BuildContext context) {
    final Map<String, String> ratingIcons = {
      AppStrings.ratingFood: AppAssets.iconRatingFood,
      AppStrings.ratingService: AppAssets.iconRatingService,
      AppStrings.ratingAtmosphere: AppAssets.iconRatingAtmosphere,
    };
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavHeader(
        leading: NavBackButton(),
        title: AppStrings.addPlaceTitle,
      ),
      body: Builder(
        builder: (BuildContext context) {
          final EdgeInsets insets = MediaQuery.paddingOf(context);
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              insets.top + 7,
              AppSpacing.screen,
              insets.bottom + AppSpacing.xxl,
            ),
            children: [
              PhotoPickerPanel(
                photos: _photos,
                maxPhotos: _maxPhotos,
                onAdd: _addPhoto,
                onRemove: _removePhoto,
              ),
              const SizedBox(height: AppSpacing.l),
              FormSection(
                title: AppStrings.venueInfo,
                child: FormGroup(
                  rows: [
                    FormRow(
                      label: const _RowLabel(AppStrings.placeName),
                      trailing: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.body,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: const InputDecoration.collapsed(
                          hintText: AppStrings.placeName,
                        ),
                      ),
                    ),
                    FormRow(
                      label: const _RowLabel(AppStrings.category),
                      trailing: _ValueButton(
                        text: AppStrings.categorySingular[_category] ?? '',
                        icon: AppAssets.iconChevronUpDown,
                        onTap: _pickCategory,
                      ),
                    ),
                    FormRow(
                      label: const _RowLabel(AppStrings.location),
                      trailing: _ValueButton(
                        text: _location,
                        icon: AppAssets.iconMapPinned,
                        onTap: _pickLocation,
                      ),
                    ),
                    FormRow(
                      label: const _RowLabel(AppStrings.dateOfVisit),
                      trailing: _DatePill(date: _visitDate, onTap: _pickDate),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              FormSection(
                title: AppStrings.experienceRatings,
                trailing: Text(
                  _averageRating.toStringAsFixed(1) + AppStrings.avgSuffix,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.cafeAccent,
                  ),
                ),
                child: FormGroup(
                  rows: _ratings.entries
                      .map(
                        (MapEntry<String, int> e) => FormRow(
                          fixedTrailing: true,
                          label: Row(
                            spacing: AppSpacing.sm,
                            children: [
                              AppSvgIcon(ratingIcons[e.key]!),
                              Flexible(child: _RowLabel(e.key)),
                            ],
                          ),
                          trailing: StarRatingInput(
                            value: e.value,
                            onChanged: (int v) =>
                                setState(() => _ratings[e.key] = v),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              FormSection(
                title: AppStrings.personalNotes,
                trailing: const _SectionNote(AppStrings.privateToYou),
                child: _NotesCard(
                  controller: _notesController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              FormSection(
                title: AppStrings.tags,
                trailing: _SectionNote(
                  '${_tags.length}${AppStrings.tagsSuffix}',
                ),
                child: TagEditor(
                  tags: _tags,
                  controller: _tagController,
                  onAdd: _addTag,
                  onRemove: _removeTag,
                ),
              ),
              const SizedBox(height: AppSpacing.l + AppSpacing.sm),
              PrimaryButton(
                label: AppStrings.savePlaceRecord,
                height: 48,
                // No storage in Lab 3 — saving simply closes the form.
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.body,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

class _SectionNote extends StatelessWidget {
  const _SectionNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.tabLabel.copyWith(color: AppColors.textTertiary),
  );
}

/// Grey value + small icon on the right of a row (Category, Location).
class _ValueButton extends StatelessWidget {
  const _ValueButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableOpacity(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.s,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subheadline.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          AppSvgIcon(icon),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableOpacity(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.smAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.s,
          children: [
            const AppSvgIcon(AppAssets.iconCalendar),
            Text(formatMediumDate(date), style: AppTextStyles.footnoteMedium),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.mdAll,
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: 4,
            maxLines: null,
            style: AppTextStyles.noteInput,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: const InputDecoration.collapsed(hintText: ''),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${controller.text.length}${AppStrings.charsSuffix}',
            textAlign: TextAlign.right,
            style: AppTextStyles.tabLabel.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
