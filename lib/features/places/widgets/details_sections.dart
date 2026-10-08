import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/pressable_opacity.dart';
import '../../../core/widgets/tag_list.dart';
import '../../../core/utils/date_formatter.dart';

/// "My Notes & Impressions": read-only note with an Edit button that
/// switches the box into a text field; "Done" hands the text to [onSave].
///
/// Whether the note is being edited is local UI state of this widget.
class NotesSection extends StatefulWidget {
  const NotesSection({
    super.key,
    required this.note,
    required this.updatedAt,
    required this.onSave,
  });

  final String note;
  final DateTime? updatedAt;
  final ValueChanged<String> onSave;

  @override
  State<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<NotesSection> {
  static const double _caretMargin = 3;

  late final TextEditingController _controller = TextEditingController(
    text: widget.note,
  );
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_editing) {
      FocusScope.of(context).unfocus();
      widget.onSave(_controller.text.trim());
    } else {
      _controller.text = widget.note;
    }
    setState(() => _editing = !_editing);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? updated = widget.updatedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(AppStrings.notesTitle, style: AppTextStyles.headline),
            ),
            PressableOpacity(
              onTap: _toggle,
              child: Row(
                spacing: AppSpacing.s,
                children: [
                  if (!_editing)
                    const AppSvgIcon(
                      AppAssets.iconPencil,
                      width: 11.25,
                      height: 11.25,
                      color: AppColors.primary,
                    ),
                  Text(
                    _editing ? AppStrings.done : AppStrings.edit,
                    style: AppTextStyles.footnoteSemibold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.ml),
          // Same fill, padding and 1 pt border in both modes — only the
          // border colour changes, so the box never jumps when editing.
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowTranslucent,
            borderRadius: AppRadii.mdAll,
            border: Border.all(
              color: _editing ? AppColors.primary : AppColors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_editing)
                TextField(
                  controller: _controller,
                  autofocus: true,
                  minLines: 3,
                  maxLines: null,
                  style: AppTextStyles.noteBody,
                  decoration: const InputDecoration.collapsed(
                    hintText: AppStrings.notesHint,
                  ),
                )
              else
                // A TextField keeps room for the caret on the right
                // (cursor 2 pt + 1 pt gap); the same inset here keeps the
                // line breaks identical when switching to Edit.
                Padding(
                  padding: const EdgeInsets.only(right: _caretMargin),
                  child: Text(
                    widget.note.isEmpty ? AppStrings.noNotes : widget.note,
                    style: AppTextStyles.noteBody,
                  ),
                ),
              if (updated != null) ...[
                const SizedBox(height: 18),
                Text(
                  AppStrings.updatedPrefix + formatDateTime(updated),
                  textAlign: TextAlign.right,
                  style: AppTextStyles.tabLabel.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// "Tags & Highlights" title above the shared [TagList].
class TagsSection extends StatelessWidget {
  const TagsSection({
    super.key,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  final List<String> tags;
  final VoidCallback onAddTag;
  final ValueChanged<String> onRemoveTag;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        const Text(AppStrings.tagsTitle, style: AppTextStyles.footnoteSemibold),
        TagList(tags: tags, onAdd: onAddTag, onRemove: onRemoveTag),
      ],
    );
  }
}

/// "Location & Coordinates": static map picture with a centred pin and
/// the street label (no map SDK in Lab 3).
class LocationSection extends StatelessWidget {
  const LocationSection({
    super.key,
    required this.label,
    required this.onOpenMaps,
  });

  final String label;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                AppStrings.locationTitle,
                style: AppTextStyles.footnoteSemibold,
              ),
            ),
            PressableOpacity(
              onTap: onOpenMaps,
              child: Text(
                AppStrings.openInMaps,
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        Container(
          height: 128,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            borderRadius: AppRadii.mdAll,
            boxShadow: AppShadows.group,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(AppAssets.mapSoho, fit: BoxFit.cover),
              const ColoredBox(color: AppColors.scrim10),
              const Align(alignment: Alignment(0, -0.125), child: _MapMarker()),
              Positioned(
                left: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.glass90,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  child: Text(label, style: AppTextStyles.tabLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: AppShadows.marker,
      ),
      child: const AppSvgIcon(AppAssets.iconStore),
    );
  }
}
