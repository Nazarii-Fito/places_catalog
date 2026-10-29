# Шпаргалка до захисту ЛР №4 (Firebase)

> Методички ЛР №4 з точним нумерованим списком контрольних питань у репозиторії немає (`docs/input/` містить лише матеріали ЛР №3). Тому відповіді згруповано за темами контрольних питань із брифу. Після отримання методички їх легко переставити під її нумерацію.

## Залежності та платформна взаємодія

**1. Семантичне версіонування і `^`.** Версія `MAJOR.MINOR.PATCH`: MAJOR — несумісні зміни API, MINOR — нові можливості без поломок, PATCH — виправлення. `^6.7.1` означає `>=6.7.1 <7.0.0`, тобто дозволені оновлення в межах мажорної версії. У `pubspec.yaml`: `firebase_auth: ^6.7.1`, `google_sign_in: ^7.2.0`. Приклад, чому мажорна версія важлива: `firebase_auth` 7.0 перейшов на Firebase iOS SDK 13, несумісний із GoogleSignIn-iOS 9 (конфлікт `gtm-session-fetcher`), тому в проєкті лишено 6.x (див. `docs/decisions.md`). Інший приклад: `google_sign_in` 7.0 змінив API (замість `GoogleSignIn().signIn()` тепер `GoogleSignIn.instance.initialize()` + `authenticate()`, див. `FirebaseAuthRepository._googleCredential`).

**2. `pub get` vs `pub upgrade`.** `flutter pub get` встановлює версії, зафіксовані в `pubspec.lock`, а якщо їх немає — підбирає найновіші, що задовольняють обмеження. `pub upgrade` ігнорує lock-файл і оновлює до найновіших сумісних з `^`-обмеженнями версій, а потім переписує `pubspec.lock`. Lock-файл комітимо, щоб у всіх була та сама збірка.

**3. Path- і git-залежності.** Замість версії з pub.dev можна вказати `path: ../my_package` (локальний пакет, наприклад у монорепозиторії) або `git: url: …, ref: …` (форк чи невипущена версія). У проєкті всі залежності беруться з pub.dev. Path і git зручні для розробки, але не мають semver-гарантій.

**4. MethodChannel.** Це асинхронний канал між Dart і нативним кодом (Swift/Kotlin): Dart викликає `invokeMethod('name', args)`, платформа відповідає результатом. Плагіни FlutterFire побудовані саме так. Наприклад, `FirebaseAuth.signInWithEmailAndPassword` через platform interface та канал викликає нативний Firebase iOS SDK. Наш код канали напряму не використовує: це зроблено всередині плагінів.

**5. `PlatformException` vs `MissingPluginException`.** `PlatformException` — нативна сторона виконала метод і повернула помилку (код + повідомлення). У Firebase вона перетворюється на `FirebaseAuthException`, яку ми мапимо в `AuthFailure`. `MissingPluginException` — для каналу немає нативної реалізації (плагін не зареєстровано: забули перезібрати після `pub add`, гаряче перезавантаження після додавання плагіна, непідтримувана платформа або виклик у unit-тесті). Тому в тестах використовуємо `FakeAuthRepository` і no-op сервіси без каналів (`test/helpers/test_harness.dart`).

**6. `firebase_core`, `firebase_options.dart`, `Firebase.initializeApp()`.** `firebase_core` — базовий пакет, який підключає застосунок до Firebase-проєкту. `flutterfire configure` реєструє застосунки й генерує `lib/firebase_options.dart` з ключами для кожної платформи (а також `GoogleService-Info.plist` і `google-services.json`). У `main.dart` спочатку `WidgetsFlutterBinding.ensureInitialized()`, потім `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`, і лише після цього можна використовувати Auth, Analytics чи Crashlytics.

## Analytics

**7. Автоматичні та власні події.** Автоматичні SDK збирає сам: `first_open`, `session_start`, `screen_view` (на iOS для нативних контролерів), `app_update` тощо. Власні логуємо в коді через `logEvent` або рекомендовані методи: `logLogin`, `logSignUp` — див. `lib/data/services/analytics_service.dart`. Власні події проєкту: `password_reset_requested`, `password_changed`, `profile_updated {photo_source}`, `place_favorite_toggled {place_id, is_favorite}`, `place_opened {place_id, category}`, `account_linked {provider}`.

**8. `logEvent` і параметри.** `logEvent(name:, parameters:)`: назва до 40 символів (літери, цифри, `_`), значення параметрів — лише `String` або `num`. Тому `is_favorite` передаємо як 0/1 (`FirebaseAnalyticsService.logPlaceFavoriteToggled`). Події викликаються там, де відбулась дія: після успішного `signIn` у `LoginScreen._submit` — `logLogin('password')`; у `MainShell._toggleFavorite` — `logPlaceFavoriteToggled`.

**9. Трекінг екранів.** `FirebaseAnalyticsObserver` у `MaterialApp.navigatorObservers` (`lib/app/app.dart`) логує `screen_view` при `push`/`pop` іменованих маршрутів. Для цього `AppRoutes.onGenerateRoute` передає `settings` з назвою в `CupertinoPageRoute`. Вкладки Home / Favorites / Profile живуть в `IndexedStack` без маршрутів, тож для них `MainShell._selectTab` викликає `logScreenView` вручну. Перевірка — Analytics → DebugView з аргументом запуску `-FIRDebugEnabled`.

## Crashlytics

**10. Fatal vs non-fatal.** Fatal — збій, що завершив застосунок (нативний краш або необроблена помилка, позначена як fatal). Non-fatal — оброблена помилка, про яку ми повідомили, але застосунок працює далі. У проєкті невідомий код помилки Firebase Auth реєструється як non-fatal (`FirebaseAuthRepository._guard` → `recordError(..., reason: ...)`). Developer-меню має обидва варіанти: «Send Test Non-Fatal Error» і «Force Test Crash» (`lib/features/profile/widgets/version_footer.dart`).

**11. `recordError(fatal: true)` не завершує застосунок.** Прапорець лише позначає звіт як fatal у консолі: процес не вбивається. Наприклад, `PlatformDispatcher.instance.onError` у `main.dart` записує помилку з `fatal: true` і повертає `true` («оброблено»), тож застосунок продовжує працювати. Справжній краш для тесту робить `FirebaseCrashlytics.instance.crash()` (`FirebaseCrashReporter.forceTestCrash`).

**12. `log()` vs `recordError()`.** `log(message)` нічого не надсилає окремо. Це breadcrumb, що з'явиться у вкладці Logs наступного звіту: контекст «що відбувалось перед помилкою». `recordError` створює сам звіт. У проєкті `_guard` пише `log('Auth: signIn')` перед кожною дією, а `sendTestNonFatal` — `log` і потім `recordError`. У логи не потрапляють паролі, токени й email; ідентифікатор користувача — лише uid (`setUserIdentifier`).

**13. `FlutterError.onError` і `PlatformDispatcher.instance.onError`.** Перший ловить помилки всередині фреймворку Flutter (build, layout, paint, обробники жестів): `FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError`. Другий ловить асинхронні помилки поза фреймворком (необроблені `Future`, колбеки платформи): обробник викликає `recordError(error, stack, fatal: true)` і повертає `true`. Разом вони покривають усі необроблені помилки Dart (`lib/main.dart`).

## Автентифікація

**14. Способи автентифікації.**
- Email/пароль — `signUp` / `signIn`.
- Федеративні провайдери (OAuth): Google — `signInWithGoogle`; Apple, Facebook, GitHub.
- Телефон з SMS-кодом, анонімний вхід, email-посилання без пароля, власні (custom) токени з бекенду.

У проєкті ввімкнено Email/Password і Google. Apple показано як платформоспецифічну опцію: кнопка відкриває діалог, бо потрібен платний Apple Developer Program (`lib/features/auth/widgets/social_sign_in.dart`).

**15. Токени.**
- **ID token** (JWT, ~1 год) підтверджує особу користувача для бекенду й правил безпеки.
- **Refresh token** — довготривалий, на пристрої. SDK сам обмінює його на нові ID-токени, тому сеанс переживає перезапуск застосунку («відновлення сеансу» в `AuthGate`).
- **Provider token** — токен зовнішнього провайдера: Google `idToken` з `account.authentication.idToken` перетворюється на Firebase-credential через `GoogleAuthProvider.credential(idToken:)`.
- **Custom token** видає ваш сервер (Admin SDK) для власної системи входу; клієнт викликає `signInWithCustomToken`. У проєкті не використовується.

**16. Linking (об'єднання способів входу).** Один Firebase-акаунт (один uid) може мати кілька провайдерів у `providerData`.
- **Під час входу:** якщо Google повертає `account-exists-with-different-credential`, ми запам'ятовуємо credential, просимо пароль, входимо email/паролем і викликаємо `linkWithCredential(googleCredential)` (`FirebaseAuthRepository.completeGoogleLink`, діалог у `social_sign_in.dart`).
- **У профілі:** Connected Accounts → «Link» → `linkGoogle()` (`ConnectedAccountsGroup`).

`fetchSignInMethodsForEmail` у сучасних версіях `firebase_auth` видалено (з міркувань безпеки — запобігання переліку email), тому email беремо з самої помилки.

**17. Дані профілю.** `User` містить `uid`, `email`, `displayName`, `photoURL`, `emailVerified`, `providerData` (провайдери), `metadata` (дати створення та входу). Ми перетворюємо їх на власну модель `AppUser` (`lib/data/models/app_user.dart`), щоб екрани не залежали від SDK. Відображення — `ProfileScreen` через `StreamBuilder` на `userChanges()`. Статистика відвідувань лишається mock, бо зберігатиметься у Firestore в наступних лабах.

**18. `currentUser`, `updateDisplayName`, `updatePhotoURL`.** `currentUser` — синхронний знімок поточного користувача (`null`, якщо не увійшов): `AuthRepository.currentUser`, `initialData` у Profile, стартові значення в `EditProfileScreen`. `updateDisplayName(fullName)` викликається після `createUserWithEmailAndPassword` у `signUp` і в Edit Profile. `updatePhotoURL(url)` зберігає вибраний пресет або власне HTTPS-посилання. Після змін робимо `reload()`, і `userChanges()` видає оновлені дані.

**19. Зміна vs відновлення пароля.**
- **Зміна** — користувач увійшов і знає поточний пароль: `reauthenticateWithCredential(EmailAuthProvider.credential(...))`, потім `updatePassword(new)` (`changePassword`, екран Change Password).
- **Відновлення** — користувач не може увійти: `sendPasswordResetEmail(email)`, Firebase надсилає лист із посиланням (`ForgotPasswordScreen`).

Текст успіху нейтральний («If an account exists…»), бо email enumeration protection не розкриває, чи існує акаунт.

**20. `requires-recent-login`.** Чутливі операції (зміна пароля чи email, видалення акаунта) вимагають недавнього входу. Якщо сесія давня, Firebase кидає `requires-recent-login`. У нас Change Password спершу робить reauth з поточним паролем, тож зазвичай помилки немає. Якщо вона все ж приходить, `AuthFailureType.requiresRecentLogin` показує діалог «Log In Again» з пропозицією вийти й увійти знову (`ChangePasswordScreen._askToSignInAgain`).

## Форми та валідація

**21. `Form` і `GlobalKey<FormState>` (і чому не в `build()`).** `Form` об'єднує поля, а `GlobalKey<FormState>` дає доступ до стану форми: `validate()`, `save()`, `reset()`. Ключ створюється один раз як поле `State` (`final GlobalKey<FormState> _formKey = GlobalKey<FormState>();` у `_RegisterScreenState`). Якщо створювати його в `build()`, кожна перебудова дасть новий ключ: Flutter вважатиме форму новою, втратить стан полів і помилок, а `currentState` вказуватиме не на ту форму.

**22. `validator` і `validate()`.** У кожного поля `validator: (value) => …` повертає `null` (усе гаразд) або текст помилки. `_formKey.currentState!.validate()` запускає всі валідатори, показує помилки і повертає `true`, тільки якщо помилок немає. Лише тоді викликається `AuthRepository` (`RegisterScreen._submit`). `AppTextField` побудовано на `FormField<String>` (`lib/core/widgets/app_text_field.dart`), тому вигляд поля з ЛР №3 зберігся. `autovalidateMode: onUserInteraction` вмикається після першої спроби відправки.

**23. Локальна валідація vs помилки Firebase.** Локально (`lib/core/validation/validators.dart`, чисті функції + unit-тести) перевіряємо формат: обов'язковість, вигляд email, довжину й цифру в паролі, збіг підтвердження, `https://` у посиланні. Тільки сервер знає, чи існує email, чи правильний пароль, чи не заблоковано акаунт. Це приходить як `FirebaseAuthException` → `AuthFailure.message` і показується в `ErrorBanner` або під конкретним полем (`errorText`, наприклад неправильний Current Password). Локальна перевірка економить запити і дає миттєвий відгук, але не замінює серверну.

## Архітектура та async-стан

**24. Навіщо `AuthRepository`.**
- **Ізоляція SDK:** весь код Firebase в одному класі `FirebaseAuthRepository`; жоден файл у `lib/features` не імпортує `firebase_auth` (перевірка: `grep -r firebase_auth lib/features` порожній).
- **Тестованість:** у тестах і скриншот-режимі підставляється `FakeAuthRepository` через `AppScope` (`test/auth_flow_test.dart`).
- **Єдина обробка помилок:** будь-яка помилка → `AuthFailure` з людським текстом, невідомі коди йдуть у Crashlytics.
- **Заміна бекенду:** можна підставити інший бекенд, не чіпаючи екрани.

**25. Відображення асинхронного стану.**
- **Стрими** — `StreamBuilder` на `authStateChanges()` в `AuthGate`: `ConnectionState.waiting` → splash, `null` → Login, користувач → `MainShell`. Profile так само слухає `userChanges()`.
- **Разові дії** (`Future`) — поле стану `_submitting`: `PrimaryButton(isLoading: true)` показує `CupertinoActivityIndicator`, повторні натискання ігноруються, поля `readOnly`. Помилка — `setState(() => _error = failure.message)` → `ErrorBanner`. Успіх — діалог або навігація.
- **Перевірка `mounted`** після кожного `await`: екран міг закритися, поки чекали відповіді.
