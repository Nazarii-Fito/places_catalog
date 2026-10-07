/// Paths to every bundled asset (exported from the Figma file).
abstract final class AppAssets {
  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';

  // Images
  static const String appIcon = '$_images/app_icon.jpg';
  static const String avatarNazariiFito = '$_images/avatar_nazarii_fito.jpg';
  static const String placeDailyGrind = '$_images/place_daily_grind.jpg';
  static const String placeOsteriaDelSole =
      '$_images/place_osteria_del_sole.jpg';
  static const String placeMomaModernCafe =
      '$_images/place_moma_modern_cafe.jpg';
  static const String placeKurobutaRamen = '$_images/place_kurobuta_ramen.jpg';

  // Icons — forms & navigation
  static const String iconMail = '$_icons/mail.svg';
  static const String iconLock = '$_icons/lock.svg';
  static const String iconEye = '$_icons/eye.svg';
  static const String iconPerson = '$_icons/person.svg';
  static const String iconInfo = '$_icons/info.svg';
  static const String iconChevronLeft = '$_icons/chevron_left.svg';
  static const String iconChevronRight = '$_icons/chevron_right.svg';
  static const String iconApple = '$_icons/apple.svg';
  static const String iconGoogle = '$_icons/google.svg';

  // Icons — home
  static const String iconPlus = '$_icons/plus.svg';
  static const String iconSearch = '$_icons/search.svg';
  static const String iconBookmark = '$_icons/bookmark.svg';
  static const String iconSort = '$_icons/sort.svg';
  static const String iconStar = '$_icons/star.svg';
  static const String iconStarHalf = '$_icons/star_half.svg';
  static const String iconHeartFilled = '$_icons/heart_filled.svg';
  static const String iconHeartOutline = '$_icons/heart_outline.svg';

  // Icons — tab bar (single-colour, tinted at runtime)
  static const String iconTabHome = '$_icons/tab_home.svg';
  static const String iconTabFavorites = '$_icons/heart_outline.svg';
  static const String iconTabProfile = '$_icons/tab_profile.svg';

  // Icons — profile
  static const String iconPencil = '$_icons/pencil.svg';
  static const String iconBookmarkStat = '$_icons/bookmark_stat.svg';
  static const String iconCup = '$_icons/cup.svg';
  static const String iconForkKnife = '$_icons/fork_knife.svg';
  static const String iconMuseum = '$_icons/museum.svg';
  static const String iconHeartStat = '$_icons/heart_stat.svg';
  static const String iconDownload = '$_icons/download.svg';
  static const String iconLogout = '$_icons/logout.svg';
}
