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
  static const String sortedByRecent = 'Sorted by Recent';
  static const String visitedPrefix = 'Visited ';
  static const String toggleFavorite = 'Toggle favorite';
  static const String emptyTitle = 'No places found';
  static const String emptySubtitle = 'Try another name or filter.';

  // Favorites
  static const String favoritesHeader = 'Saved Favorites';
  static const String favoritesTitle = 'Favorites';

  // Profile
  static const String editProfilePhoto = 'Edit profile photo';
  static const String archivedCatalog = 'Archived Catalog';
  static const String totalVisitedPlaces = 'Total Visited Places';
  static const String statCafes = 'Cafes';
  static const String statDining = 'Dining';
  static const String statMuseums = 'Museums';
  static const String statFavorites = 'Favorites';
  static const String accountSettings = 'Account Settings';
  static const String changePassword = 'Change Password';
  static const String appSettings = 'App Settings';
  static const String icloudSync = 'iCloud Sync & Backup';
  static const String active = 'Active';
  static const String dataAndPrivacy = 'Data & Privacy';
  static const String exportArchive = 'Export Places Archive';
  static const String logOut = 'Log Out';
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
