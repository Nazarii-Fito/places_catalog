import '../../core/constants/app_strings.dart';
import '../../data/models/place.dart';
import '../../data/models/place_category.dart';

/// Filter chips of the Home screen (FR9).
///
/// Each value knows its label and which places it keeps, so the chip row
/// is generated from `HomeFilter.values` and filtering is a pure function.
enum HomeFilter {
  all(AppStrings.filterAll),
  cafes(AppStrings.filterCafes),
  restaurants(AppStrings.filterRestaurants),
  museums(AppStrings.filterMuseums),
  fiveStars(AppStrings.filterFiveStars),
  bakeries(AppStrings.filterBakeries);

  const HomeFilter(this.label);

  final String label;

  bool matches(Place place) => switch (this) {
    HomeFilter.all => true,
    HomeFilter.cafes => place.category == PlaceCategory.cafe,
    HomeFilter.restaurants => place.category == PlaceCategory.restaurant,
    HomeFilter.museums => place.category == PlaceCategory.museum,
    HomeFilter.fiveStars => place.rating >= 5,
    HomeFilter.bakeries => place.category == PlaceCategory.bakery,
  };
}
