import '../../core/constants/app_strings.dart';
import '../../data/models/place.dart';

/// Sort orders of the Home list ("Sorted by …" menu).
///
/// Like [HomeFilter], every value carries its label and its comparator,
/// so the menu items are generated from `HomeSort.values`.
enum HomeSort {
  recent(AppStrings.sortRecent),
  oldest(AppStrings.sortOldest),
  rating(AppStrings.sortRating),
  name(AppStrings.sortName);

  const HomeSort(this.label);

  final String label;

  int compare(Place a, Place b) => switch (this) {
    HomeSort.recent => b.visitDate.compareTo(a.visitDate),
    HomeSort.oldest => a.visitDate.compareTo(b.visitDate),
    HomeSort.rating => b.rating.compareTo(a.rating),
    HomeSort.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  };
}
