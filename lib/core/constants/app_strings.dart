import '../../data/models/place_category.dart';

/// Short alias so the label maps above read naturally.
typedef PlaceCategoryKey = PlaceCategory;

/// Every user-facing string of the app in one place (NFR7).
///
/// When uk/en localisation is added, this class is replaced by generated
/// `AppLocalizations` without touching widget layout code.
abstract final class AppStrings {
  // App
  static const String appName = 'PlacesCatalog';
  // Auth subtitles keep the line breaks from Figma (explicit '\n').
  static const String tagline = 'Your personal culinary & culture\ndiary';

  // Shared auth
  static const String emailLabel = 'Email Address';
  static const String emailHint = 'name@icloud.com';
  static const String passwordLabel = 'Password';
  static const String passwordHint = '••••••••';
  static const String passwordHelper =
      'Must be at least 8 characters with a number';
  static const String showPassword = 'Show password';
  static const String hidePassword = 'Hide password';
  static const String orContinueWith = 'or continue with';
  static const String apple = 'Apple';
  static const String google = 'Google';
  static const String termsOfService = 'Terms of Service';
  static const String privacyPolicy = 'Privacy Policy';
  static const String and = ' and ';
  static const String period = '.';

  // Login
  static const String forgotPassword = 'Forgot Password?';
  static const String logIn = 'Log In';
  static const String createAccount = 'Create Account';
  static const String loginLegalPrefix = 'By continuing, you agree to our ';

  // Register
  static const String registerSubtitle =
      'Start your personal culinary & culture\njournal';
  static const String fullNameLabel = 'Full Name';
  static const String fullNameHint = 'Nazarii Fito';
  static const String registerLegalPrefix = 'By signing up, you agree to our ';
  static const String alreadyHaveAccount = 'Already have an account? ';

  // Forgot password
  static const String resetPasswordTitle = 'Reset Password';
  static const String resetPasswordSubtitle =
      "Enter your email and we'll send you\na link to reset your password.";
  static const String resetEmailHelper =
      "We'll send a secure link to this address";
  static const String sendResetLink = 'Send Reset Link';
  static const String rememberPassword = 'Remember your password? ';
  static const String checkEmailTitle = 'Check your email';
  static const String checkEmailSubtitle = 'We sent a password reset link to';
  static const String backToLogIn = 'Back to Log In';
  static const String didntGetEmail = "Didn't get the email? ";
  static const String resend = 'Resend';

  // Tabs
  static const String tabHome = 'Home';
  static const String tabFavorites = 'Favorites';
  static const String tabProfile = 'Profile';

  // Home
  static const String homeOverline = 'Catalog & Journal';
  static const String myPlaces = 'My Places';
  static const String addPlace = 'Add new place';
  static const String searchHint = 'Search by name or cuisine...';
  static const String filterAll = 'All';
  static const String filterCafes = 'Cafes';
  static const String filterRestaurants = 'Restaurants';
  static const String filterMuseums = 'Museums';
  static const String filterFiveStars = '★ 5 Stars';
  static const String filterBakeries = 'Bakeries';
  static const String recordedSpots = ' recorded spots';
  static const String sortedByPrefix = 'Sorted by ';
  static const String sortRecent = 'Recent';
  static const String sortOldest = 'Oldest';
  static const String sortRating = 'Rating';
  static const String sortName = 'Name';
  static const String visitedPrefix = 'Visited ';
  static const String toggleFavorite = 'Toggle favorite';
  static const String emptyTitle = 'No places found';
  static const String emptySubtitle = 'Try another name or filter.';

  // Favorites
  static const String favoritesHeader = 'Saved Favorites';
  static const String favoritesTitle = 'Favorites';
  static const String searchFavoritesHint = 'Search favorites...';
  static const String noFavoritesTitle = 'No favorites yet';
  static const String noFavoritesSubtitle =
      'Tap the heart on a place to keep it here.';

  /// Plural chip labels per category ("Cafes (2)").
  static const Map<PlaceCategoryKey, String> categoryPlural = {
    PlaceCategoryKey.cafe: 'Cafes',
    PlaceCategoryKey.restaurant: 'Restaurants',
    PlaceCategoryKey.bar: 'Bars',
    PlaceCategoryKey.museum: 'Museums',
    PlaceCategoryKey.fastFood: 'Fast Food',
    PlaceCategoryKey.hotel: 'Hotels',
    PlaceCategoryKey.bakery: 'Bakeries',
    PlaceCategoryKey.pub: 'Pubs',
  };

  /// Singular labels per category ("Cafe").
  static const Map<PlaceCategoryKey, String> categorySingular = {
    PlaceCategoryKey.cafe: 'Cafe',
    PlaceCategoryKey.restaurant: 'Restaurant',
    PlaceCategoryKey.bar: 'Bar',
    PlaceCategoryKey.museum: 'Museum',
    PlaceCategoryKey.fastFood: 'Fast Food',
    PlaceCategoryKey.hotel: 'Hotel',
    PlaceCategoryKey.bakery: 'Bakery',
    PlaceCategoryKey.pub: 'Pub',
  };

  // Place details
  static const String placeDetails = 'Place Details';
  static const String photosSuffix = ' Photos';
  static const String visitedOnPrefix = 'Visited on ';
  static const String yourPersonalRating = 'Your personal rating';
  static const String criterionFood = 'Food & Pastry';
  static const String criterionService = 'Service & Hospitality';
  static const String criterionAtmosphere = 'Atmosphere & Vibe';
  static const String outOfFive = ' / 5';
  static const String notRated = 'Not rated';
  static const String notesTitle = 'My Notes & Impressions';
  static const String edit = 'Edit';
  static const String noNotes = 'No notes yet.';
  static const String updatedPrefix = 'Updated ';
  static const String tagsTitle = 'Tags & Highlights';
  static const String addTag = 'Add Tag';
  static const String newTagTitle = 'New Tag';
  static const String newTagMessage = 'Short keyword, e.g. Brunch';
  static const String newTagHint = 'Tag';
  static const String add = 'Add';
  static const String notesHint = 'Write your impressions...';
  static const String locationTitle = 'Location & Coordinates';
  static const String openInMaps = 'Open in Apple Maps';
  static const String deletePlace = 'Delete Place';
  static const String deleteDialogTitle = 'Delete Place?';
  static const String deleteDialogMessage =
      'Are you sure you want to permanently delete this place and all its '
      'photos?';
  static const String delete = 'Delete';
  static const String back = 'Back';

  // Add place
  static const String addPlaceTitle = 'Add Place';
  static const String addPhotos = 'Add Photos';
  static const String addPhotosHint = 'Upload up to 5 photos from library';
  static const String photosLeftSuffix = ' left';
  static const String removePhoto = 'Remove photo';
  static const String venueInfo = 'Venue Info';
  static const String placeName = 'Place Name';
  static const String placeNameHint = 'Lumina Osteria';
  static const String category = 'Category';
  static const String location = 'Location';
  static const String defaultLocation = 'Manhattan, Bandery, 5';
  static const String dateOfVisit = 'Date of Visit';
  static const String experienceRatings = 'Experience Ratings';
  static const String avgSuffix = ' avg';
  static const String ratingFood = 'Food';
  static const String ratingService = 'Service';
  static const String ratingAtmosphere = 'Atmosphere';
  static const String personalNotes = 'Personal Notes';
  static const String privateToYou = 'Private to you';
  static const String charsSuffix = ' chars';
  static const String defaultNote =
      'The Meyer lemon mascarpone tart is unforgettable. Corner window seat '
      'with sun flare around 10am is prime for reading and quiet journaling.';
  static const String tags = 'Tags';
  static const String tagsSuffix = ' tags';
  static const String addTagHint = 'Add tag...';
  static const String savePlaceRecord = 'Save Place Record';
  static const String done = 'Done';

  // Location picker
  static const String defaultMapQuery = 'Manhattan, Bandery';
  static const String pickedPlaceTitle = 'Manhattan, Ukraine';
  static const String pickedPlaceAddress = 'Bandery, 05, Manhattan, NY, 79090';
  static const String pickedCoordinates = '40.7587° N, 73.9787° W';
  static const String confirmLocation = 'Confirm Location';

  // Profile
  static const String editProfilePhoto = 'Edit profile';
  static const String archivedCatalog = 'Archived Catalog';
  static const String totalVisitedPlaces = 'Total Visited Places';
  static const String statCafes = 'Cafes';
  static const String statDining = 'Dining';
  static const String statMuseums = 'Museums';
  static const String statFavorites = 'Favorites';
  static const String accountSettings = 'Account Settings';
  static const String changePassword = 'Change Password';
  static const String dataAndPrivacy = 'Data & Privacy';
  static const String exportArchive = 'Export Places Archive';
  static const String logOut = 'Log Out';
  // Edit profile
  static const String editProfile = 'Edit Profile';
  static const String accountOverline = 'Account';
  static const String editProfileSubtitle =
      'Update how your name and email appear in PlacesCatalog.';
  static const String changePhoto = 'Change Photo';
  static const String removeProfilePhoto = 'Remove Photo';
  static const String useDefaultPhoto = 'Use Default Photo';
  static const String saveChanges = 'Save Changes';
  static const String profileUpdatedTitle = 'Profile Updated';
  static const String profileUpdatedMessage = 'Your changes have been saved.';

  // Export archive (FR2)
  static const String exportTitle = 'Export Archive';
  static const String exportOverline = 'Data & Privacy';
  static const String exportSubtitle =
      'All your places, ratings, notes and tags in one JSON file.';
  static const String exportFileName = 'places_archive.json';
  static const String placesSuffix = ' places';
  static const String kilobytesSuffix = ' KB';
  static const String jsonPreview = 'Preview';
  static const String copyJson = 'Copy JSON';
  static const String copiedTitle = 'Archive Copied';
  static const String copiedMessage =
      'The JSON archive is in the clipboard — paste it into Notes or Files.';

  static const String logOutDialogTitle = 'Log Out?';
  static const String logOutDialogMessage =
      'You will need to sign in again to see your places.';
  static const String cancel = 'Cancel';

  // Change password
  static const String accountSecurity = 'Account Security';
  static const String changePasswordSubtitle =
      'Your new password must be different from the one you currently use.';
  static const String currentPasswordLabel = 'Current Password';
  static const String newPasswordLabel = 'New Password';
  static const String confirmPasswordLabel = 'Confirm New Password';
  static const String forgotCurrentPassword = 'Forgot current password?';
  static const String updatePassword = 'Update Password';
  static const String passwordUpdatedTitle = 'Password Updated';
  static const String passwordUpdatedMessage =
      'Your password has been changed successfully.';
  static const String ok = 'OK';

  // Dates
  static const String am = 'AM';
  static const String pm = 'PM';
  static const List<String> monthsLong = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const List<String> monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}
