# Приклади коду для звіту

Фрагменти скорочено: неважливі частини замінено коментарем `// ...`.

## 1. Екран авторизації — `LoginScreen` (вимога 4)

Файл: `lib/features/auth/screens/login_screen.dart`.

Бізнес-логіки немає: кнопка «Log In» і кнопки Apple / Google просто відкривають головний екран. `pushNamedAndRemoveUntil` очищає стек, тож повернутися «назад» на екран входу не можна. Спільна обгортка `AuthPage` (`lib/features/auth/widgets/auth_page.dart`) розтягує форму на весь екран і притискає `footer` донизу: на iPhone 17 екран вміщається без скролу.

```dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Home becomes the only route: "Back" must not return to Login.
  void _openHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      form: [
        const SizedBox(height: AppSpacing.m),
        const AuthHeader(
          title: AppStrings.appName,
          subtitle: TextSpan(text: AppStrings.tagline),
        ),
        const SizedBox(height: 28),
        AppTextField(
          label: AppStrings.emailLabel,
          hintText: AppStrings.emailHint,
          prefixIcon: AppAssets.iconMail,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.l),
        AppTextField(
          label: AppStrings.passwordLabel,
          hintText: AppStrings.passwordHint,
          prefixIcon: AppAssets.iconLock,
          controller: _passwordController,
          isPassword: true, // "eye" toggles obscureText via setState
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _openHome(),
        ),
        // ... "Forgot Password?" -> pushNamed(AppRoutes.forgotPassword)
        PrimaryButton(label: AppStrings.logIn, onPressed: _openHome),
        const SizedBox(height: AppSpacing.m),
        SecondaryButton(
          label: AppStrings.createAccount,
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.register),
        ),
        // ... divider "or continue with", Apple / Google buttons
      ],
      // Pinned to the bottom edge of the screen.
      footer: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: AuthLegalText(prefix: AppStrings.loginLegalPrefix),
        ),
      ],
    );
  }
}
```

## 2. Домашня сторінка — `HomeScreen` (вимога 4)

Файл: `lib/features/home/screens/home_screen.dart`. Дані беруться з hardcoded-списку `mockPlaces` (`lib/data/mock/mock_places.dart`), який зберігає й передає `MainShell`. Аналогічно дані користувача в профілі задано константами в `lib/data/mock/mock_user.dart`.

```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.places,
    required this.onToggleFavorite,
    required this.onOpenPlace,
  });

  final List<Place> places;
  final ValueChanged<Place> onToggleFavorite;
  final ValueChanged<Place> onOpenPlace;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeFilter _filter = HomeFilter.all; // selected chip (UI state)
  HomeSort _sort = HomeSort.recent;    // "Sorted by …" menu (UI state)
  String _query = '';                  // search text (UI state)
  // ...

  @override
  Widget build(BuildContext context) {
    // build() only derives data from state — no side effects.
    final List<Place> visible =
        widget.places.where(_filter.matches).where(_matchesQuery).toList()
          ..sort(_sort.compare);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavHeader(title: AppStrings.tabHome),
      body: ListView(
        children: [
          HomeTitleRow(onAdd: _openAddPlace),
          SearchField(
            controller: _searchController,
            hintText: AppStrings.searchHint,
            onChanged: (String value) => setState(() => _query = value),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(            // chips from enum values
              scrollDirection: Axis.horizontal,
              itemCount: HomeFilter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, int index) {
                final HomeFilter filter = HomeFilter.values[index];
                return CategoryChip(
                  label: filter.label,
                  selected: filter == _filter,
                  onTap: () => setState(() => _filter = filter),
                );
              },
            ),
          ),
          CatalogSummaryStrip(
            count: visible.length,
            sort: _sort,
            onSortSelected: (HomeSort sort) => setState(() => _sort = sort),
          ),
          if (visible.isEmpty)
            const EmptyState(
              title: AppStrings.emptyTitle,
              subtitle: AppStrings.emptySubtitle,
            )
          else
            Column(
              spacing: 14,
              children: visible
                  .map((Place place) => PlaceCard(   // List -> widgets
                        place: place,
                        onTap: () => widget.onOpenPlace(place),
                        onFavoriteToggle: () => widget.onToggleFavorite(place),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
```

## 3. Перевикористовуваний віджет — `PrimaryButton` (вимога 5)

Файл: `lib/core/widgets/primary_button.dart`. Використовується на Login, Register, Forgot Password, Change Password, Edit Profile, Export Archive, Add Place і Location Picker.

```dart
/// Filled blue confirm button — "Log In", "Create Account", "Save", ...
///
/// * [label] — button text (named parameter, required);
/// * [onPressed] — `null` renders the disabled state;
/// * [icon] — optional leading widget (e.g. "Confirm Location").
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = AppSizes.buttonHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Widget? leading = icon;
    return PressableOpacity(              // iOS-like fade instead of ripple
      onTap: onPressed,
      pressedOpacity: 0.85,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadii.mdAll,
            boxShadow: enabled ? AppShadows.primaryButton : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 8)],
              Text(
                label,
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 4. Перевикористовуваний віджет — `AppTextField` (вимога 5)

Файл: `lib/core/widgets/app_text_field.dart`. Це `StatefulWidget`, бо зберігає локальний UI-стан: чи прихований пароль і чи має поле фокус.

```dart
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.controller,
    this.isPassword = false,
    this.helperText,
    // ... keyboardType, textInputAction, onSubmitted, enabled
  });
  // ...
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.isPassword;
  // ... FocusNode + _focused for the blue focus border

  void _toggleObscured() => setState(() => _obscured = !_obscured);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label.toUpperCase(), style: AppTextStyles.fieldLabel),
        const SizedBox(height: 6),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.mdAll,
            boxShadow: AppShadows.subtle,
          ),
          child: Row(
            children: [
              const SizedBox(width: 15),
              AppSvgIcon(widget.prefixIcon),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  obscureText: _obscured,
                  style: AppTextStyles.input,
                  decoration: InputDecoration.collapsed(
                    hintText: widget.hintText,
                    // ... placeholder colour #C1C6D7
                  ),
                ),
              ),
              if (widget.isPassword)
                _EyeButton(obscured: _obscured, onTap: _toggleObscured),
              const SizedBox(width: 15),
            ],
          ),
        ),
        if (widget.helperText != null) _HelperRow(text: widget.helperText!),
      ],
    );
  }
}
```
