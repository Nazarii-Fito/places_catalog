import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/add_tag_dialog.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/nav_back_button.dart';
import '../../../core/widgets/pressable_opacity.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/tag_list.dart';
import '../../../app/dev_launch_options.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_text_link.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../data/models/geocoding_result.dart';
import '../../../data/models/place.dart';
import '../../../data/services/photo_picker_service.dart';
import '../../../data/models/place_category.dart';
import '../../../data/models/place_photo.dart';
import '../../../data/models/review.dart';
import '../widgets/form_group.dart';
import '../widgets/photo_picker_panel.dart';
import '../widgets/star_rating_input.dart';
import '../bloc/create_place_bloc.dart';
import '../bloc/update_place_bloc.dart';
import 'add_place_pickers.dart';

/// Create (`initial == null`) or edit (`initial != null`) a place — FR4, FR8.
///
/// One screen for both modes keeps the layout identical and removes the
/// duplicated form. UI state (text controllers, picked photos, ratings) is
/// *ephemeral* and stays in this `State`; the finished [Place] is returned
/// to the caller through `Navigator.pop`, so the form never needs to know
/// where or how the catalog is stored.
///
/// Validation is a [Form] + [GlobalKey]: name (2–50 chars) and location are
/// required. Errors appear only after the first "Save" tap, then follow
/// every change.
class PlaceFormScreen extends StatefulWidget {
  const PlaceFormScreen({super.key, this.initial});

  /// The place being edited, or `null` to create a new one.
  final Place? initial;

  @override
  State<PlaceFormScreen> createState() => _PlaceFormScreenState();
}

class _PlaceFormScreenState extends State<PlaceFormScreen> {
  static const int _maxPhotos = PhotoRules.maxPhotosPerPlace;
  static const List<String> _demoPhotos = [
    AppAssets.photoCoffee,
    AppAssets.photoPasta,
    AppAssets.photoStorefront,
  ];

  /// Filled in for new places in screenshot mode only (`DEMO_FORM`).
  static const bool _demo = DevLaunchOptions.demoForm;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late List<PlacePhoto> _photos;
  late PlaceCategory _category;
  late String _location;
  double? _latitude;
  double? _longitude;
  late DateTime _visitDate;
  late final Map<String, int> _ratings;
  late List<String> _tags;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    // A result from an earlier visit must not greet the user.
    if (widget.initial == null) {
      context.read<CreatePlaceBloc>().add(const CreatePlaceReset());
    } else {
      context.read<UpdatePlaceBloc>().add(const UpdatePlaceReset());
    }
    final Place? place = widget.initial;
    final Review? review = place?.review;
    _nameController = TextEditingController(
      text: place?.name ?? (_demo ? AppStrings.placeNameHint : ''),
    );
    _notesController = TextEditingController(
      text: review?.textNote ?? (_demo ? AppStrings.defaultNote : ''),
    );
    _photos = place != null
        ? List.of(place.photos)
        : (_demo
              ? [for (final String a in _demoPhotos) PlacePhoto.asset(a)]
              : <PlacePhoto>[]);
    _category = place?.category ?? PlaceCategory.cafe;
    _location = place?.address ?? (_demo ? AppStrings.defaultLocation : '');
    _latitude = place?.latitude;
    _longitude = place?.longitude;
    _visitDate =
        place?.visitDate ?? (_demo ? DateTime(2026, 9, 24) : DateTime.now());
    // A review needs a rating of at least 1, so every criterion starts at a
    // neutral 3 stars (the user can change it) instead of "unrated".
    _ratings = {
      AppStrings.ratingFood: _stars(review?.foodRating, _demo ? 5 : 3),
      AppStrings.ratingService: _stars(review?.serviceRating, _demo ? 4 : 3),
      AppStrings.ratingAtmosphere: _stars(
        review?.atmosphereRating,
        _demo ? 5 : 3,
      ),
    };
    _tags = review != null
        ? List.of(review.tags)
        : (_demo
              ? ['#Espresso', '#Pastries', '#QuietWork', '#NaturalLight']
              : <String>[]);
  }

  static int _stars(double? stored, int fallback) =>
      stored == null ? fallback : stored.round().clamp(1, 5);

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _averageRating =>
      _ratings.values.reduce((int a, int b) => a + b) / _ratings.length;

  /// Opens the source sheet, then adds what the user picked. Cancelling
  /// does nothing; a denied permission or a bad file shows a plain message.
  Future<void> _addPhoto() async {
    final int free = _maxPhotos - _photos.length;
    if (free < 1) return;
    final PhotoSource? source = await showPhotoSourceSheet(context);
    if (source == null || !mounted) return;
    final PhotoPickerService picker = context.read<PhotoPickerService>();
    try {
      final List<PlacePhoto> picked = switch (source) {
        PhotoSource.library => await picker.pickFromLibrary(limit: free),
        PhotoSource.camera => [?await picker.takePhoto()],
      };
      if (!mounted || picked.isEmpty) return;
      // The preview is the local file itself: shown at once, no network.
      setState(
        () => _photos = [..._photos, ...picked].take(_maxPhotos).toList(),
      );
    } on PhotoPickFailure catch (failure) {
      if (!mounted) return;
      await AppConfirmDialog.show(
        context,
        title: AppStrings.photoErrorTitle,
        message: failure.message,
        confirmLabel: AppStrings.ok,
        cancelLabel: null,
      );
    }
  }

  void _removePhoto(int index) => setState(() {
    _photos = [..._photos]..removeAt(index);
  });

  /// Builds the result from the form. For an edit the identity (id,
  /// favourite flag, coordinates) is kept; for a new place they are created.
  Place _buildPlace() {
    final Place? old = widget.initial;
    final List<PlacePhoto> photos = _photos;
    final double food = _ratings[AppStrings.ratingFood]!.toDouble();
    final double service = _ratings[AppStrings.ratingService]!.toDouble();
    final double atmosphere = _ratings[AppStrings.ratingAtmosphere]!.toDouble();
    final Review review = Review(
      overallRating: _averageRating,
      foodRating: food,
      serviceRating: service,
      atmosphereRating: atmosphere,
      textNote: _notesController.text.trim(),
      tags: _tags,
      updatedAt: DateTime.now(),
    );
    final bool sameCategory = old != null && old.category == _category;
    return Place(
      // A new place gets its real id from `CreatePlaceBloc` (photos are
      // stored under it), so the draft carries an empty one.
      id: old?.id ?? '',
      name: _nameController.text.trim(),
      category: _category,
      subtitle: sameCategory
          ? old.subtitle
          : (AppStrings.categorySingular[_category] ?? _category.name),
      address: _location,
      visitDate: _visitDate,
      // The bloc swaps in the uploaded copy of the first photo. Without
      // photos: keep a bundled cover, never one whose file was deleted.
      coverImage: photos.isNotEmpty
          ? photos.first
          : (old != null && !old.coverImage.isRemote
                ? old.coverImage
                : const PlacePhoto.asset(AppAssets.photoStorefront)),
      createdAt: old?.createdAt,
      review: review,
      isFavorite: old?.isFavorite ?? false,
      latitude: _latitude,
      longitude: _longitude,
      photos: photos,
    );
  }

  void _revalidate() {
    if (_submitted) _formKey.currentState?.validate();
  }

  void _save() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    final Place draft = _buildPlace();
    // The blocs ignore a second tap while a save is running. Closing the
    // form is the success listener's job.
    final Place? original = widget.initial;
    if (original == null) {
      context.read<CreatePlaceBloc>().add(CreatePlaceSubmitted(draft));
    } else {
      context.read<UpdatePlaceBloc>().add(
        UpdatePlaceSubmitted(original: original, draft: draft),
      );
    }
  }

  /// What the save buttons area shows, from the bloc of the current mode.
  _SaveView _saveView(BuildContext context) {
    if (_isEditing) {
      return switch (context.watch<UpdatePlaceBloc>().state) {
        PlaceUpdatingState(
          origin: UpdateOrigin.form,
          :final uploaded,
          :final total,
        ) =>
          _SaveView.busy(uploaded, total),
        PlaceUpdateErrorState(
          origin: UpdateOrigin.form,
          :final message,
          :final retryable,
        ) =>
          _SaveView.error(message, retryable),
        _ => const _SaveView.idle(),
      };
    }
    return switch (context.watch<CreatePlaceBloc>().state) {
      PlaceCreatingState(:final uploaded, :final total) => _SaveView.busy(
        uploaded,
        total,
      ),
      PlaceCreateErrorState(:final message, :final retryable) =>
        _SaveView.error(message, retryable),
      _ => const _SaveView.idle(),
    };
  }

  Future<void> _pickCategory() async {
    final PlaceCategory? picked = await showCategoryPicker(context, _category);
    if (picked != null) setState(() => _category = picked);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showVisitDatePicker(context, _visitDate);
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _pickLocation() async {
    final Object? result = await Navigator.of(context).pushNamed(
      AppRoutes.locationPicker,
      arguments: _location.isEmpty && _latitude == null
          ? null
          : LocationPickerArgs(
              address: _location,
              latitude: _latitude,
              longitude: _longitude,
            ),
    );
    if (result is PickedLocation) {
      setState(() {
        _location = result.address;
        _latitude = result.latitude;
        _longitude = result.longitude;
        // A venue chosen on the map tells us what and where it is: fill the
        // name only if the user has not typed one, and set the category.
        final String? venueName = result.name;
        if (venueName != null && _nameController.text.trim().isEmpty) {
          _nameController.text = venueName;
        }
        final PlaceCategory? venueCategory = result.category;
        if (venueCategory != null) _category = venueCategory;
      });
      _revalidate();
    }
  }

  Future<void> _addTag() async {
    final String? tag = await showAddTagDialog(context);
    if (tag == null || _tags.contains(tag)) return;
    setState(() => _tags = [..._tags, tag]);
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
    final _SaveView save = _saveView(context);
    // While saving, the form cannot be left or edited by accident: touches
    // are ignored and the back swipe is blocked until the bloc finishes.
    return PopScope(
      canPop: !save.busy,
      child: IgnorePointer(
        ignoring: save.busy,
        child: MultiBlocListener(
          listeners: [
            BlocListener<CreatePlaceBloc, CreatePlaceState>(
              listenWhen: (_, CreatePlaceState now) =>
                  now is PlaceCreateSuccessState,
              listener: (BuildContext context, _) =>
                  Navigator.of(context).pop(),
            ),
            BlocListener<UpdatePlaceBloc, UpdatePlaceState>(
              listenWhen: (_, UpdatePlaceState now) =>
                  now is PlaceUpdateSuccessState &&
                  now.origin == UpdateOrigin.form,
              listener: (BuildContext context, _) =>
                  Navigator.of(context).pop(),
            ),
          ],
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppNavHeader(
              leading: const NavBackButton(),
              title: _isEditing
                  ? AppStrings.editPlaceTitle
                  : AppStrings.addPlaceTitle,
            ),
            body: Builder(
              builder: (BuildContext context) {
                final EdgeInsets insets = MediaQuery.paddingOf(context);
                return Form(
                  key: _formKey,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.always
                      : AutovalidateMode.disabled,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
                                onChanged: (_) => _revalidate(),
                                textAlign: TextAlign.right,
                                style: AppTextStyles.body,
                                onTapOutside: (_) =>
                                    FocusScope.of(context).unfocus(),
                                decoration: InputDecoration.collapsed(
                                  hintText: AppStrings.placeNameHint,
                                  // A hint must look like a hint, not like a value.
                                  hintStyle: AppTextStyles.body.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                            FormRow(
                              label: const _RowLabel(AppStrings.category),
                              trailing: _ValueButton(
                                text:
                                    AppStrings.categorySingular[_category] ??
                                    '',
                                icon: AppAssets.iconChevronUpDown,
                                onTap: _pickCategory,
                              ),
                            ),
                            FormRow(
                              label: const _RowLabel(AppStrings.location),
                              trailing: _ValueButton(
                                text: _location.isEmpty
                                    ? AppStrings.locationHint
                                    : _location,
                                isPlaceholder: _location.isEmpty,
                                icon: AppAssets.iconMapPinned,
                                onTap: _pickLocation,
                              ),
                            ),
                            FormRow(
                              label: const _RowLabel(AppStrings.dateOfVisit),
                              trailing: _DatePill(
                                date: _visitDate,
                                onTap: _pickDate,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _FieldError(
                        validator: (_) =>
                            Validators.placeName(_nameController.text),
                      ),
                      _FieldError(
                        validator: (_) => Validators.location(_location),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      FormSection(
                        title: AppStrings.experienceRatings,
                        trailing: Text(
                          _averageRating.toStringAsFixed(1) +
                              AppStrings.avgSuffix,
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
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadii.mdAll,
                            boxShadow: AppShadows.subtle,
                          ),
                          child: TagList(
                            tags: _tags,
                            onAdd: _addTag,
                            onRemove: _removeTag,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l + AppSpacing.sm),
                      if (save.error != null) ...[
                        ErrorBanner(message: save.error!),
                        if (save.retryable)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.s),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: AppTextLink(
                                label: AppStrings.retry,
                                onTap: _save,
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.m),
                      ],
                      PrimaryButton(
                        label: _isEditing
                            ? AppStrings.saveChanges
                            : AppStrings.savePlaceRecord,
                        height: 48,
                        isLoading: save.busy,
                        onPressed: _save,
                      ),
                      if (save.busy && save.total > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(
                            AppStrings.uploadingPhoto(
                              (save.uploaded + 1).clamp(1, save.total),
                              save.total,
                            ),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.footnote.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The state of the Save area: idle, saving (with upload progress) or failed.
class _SaveView {
  const _SaveView.idle()
    : busy = false,
      uploaded = 0,
      total = 0,
      error = null,
      retryable = false;
  const _SaveView.busy(this.uploaded, this.total)
    : busy = true,
      error = null,
      retryable = false;
  const _SaveView.error(this.error, this.retryable)
    : busy = false,
      uploaded = 0,
      total = 0;

  final bool busy;
  final int uploaded;
  final int total;
  final String? error;
  final bool retryable;
}

/// Red message under the venue group; empty (zero height) while valid.
///
/// The rows of the group are custom controls, not text fields, so their
/// errors are shown by a dedicated [FormField] that takes part in
/// `FormState.validate()` like any other field.
class _FieldError extends StatelessWidget {
  const _FieldError({required this.validator});

  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator,
      builder: (FormFieldState<String> field) {
        final String? message = field.errorText;
        if (message == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            top: AppSpacing.s,
          ),
          child: Text(
            message,
            style: AppTextStyles.caption.copyWith(color: AppColors.destructive),
          ),
        );
      },
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
    this.isPlaceholder = false,
  });

  final String text;
  final String icon;

  /// Greys the text further when it is a hint, not a chosen value.
  final bool isPlaceholder;
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
                color: isPlaceholder
                    ? AppColors.textTertiary
                    : AppColors.textSecondary,
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
            decoration: const InputDecoration.collapsed(
              hintText: AppStrings.notesHint,
            ),
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
