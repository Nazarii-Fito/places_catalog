# Рішення щодо реалізації (ЛР №3)

Дрібні розбіжності й неоднозначності дизайну та рішення, ухвалені під час верстки.

## Узгоджено з автором

| #   | Питання                                                                                                                         | Рішення                                                                                                                                                                                             |
| --- | ------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Profile у Figma не має групи ACCOUNT SETTINGS, пілюлі «Apple ID», футера «Version»; Home — футера iCloud, бейджів на мініатюрах | Верстаємо як у Figma. Додаємо лише групу ACCOUNT SETTINGS з пунктом Change Password у стилі DATA & PRIVACY, бо він потрібен для вимоги 3.2 (App Settings та iCloud Sync прибрано 08.10, див. нижче) |
| 2   | Немає дизайну Forgot Password і Change Password                                                                                 | Домальовано у Figma з наявних шарів: фрейми `26:14`, `27:14`, `27:63`                                                                                                                               |
| 3   | Login і Registration по-різному стилізують ті самі елементи                                                                     | Уніфіковано за Login (див. нижче)                                                                                                                                                                   |

## Уніфікація стилів (за Login)

| Елемент                     | Login (взято)                        | Registration (відхилення)            |
| --------------------------- | ------------------------------------ | ------------------------------------ |
| Лейбл поля                  | 11/16, tracking 0.6                  | 11/13, tracking 0.55                 |
| Горизонтальний padding поля | 16 + іконка + 12                     | 14 + іконка з margin                 |
| Колір плейсхолдера          | `#C1C6D7`                            | `#717786` @ 70 %                     |
| Legal-текст                 | 12/19.5 `#717786`, посилання Regular | 13/21.13 `#414755`, посилання Medium |

## Інше

- **Змінна Figma `Main-Text #0C0E13`** у фреймах не застосована (текст скрізь `#1A1B1F`), тому береться `#1A1B1F`. `#0C0E13` лишився тільки всередині SVG логотипа Apple.
- **Іконки табів:** у Figma активна й неактивна іконки мають однакову форму і різняться лише кольором. Тому для кожного табу один SVG, а колір задається через `ColorFilter`. Іконка табу Favorites — той самий `heart_outline.svg`.
- **Іконка `person`** експортувалась разом із вбудованим відступом 12 px (вузол `Margin`): viewBox обрізано до 13.33 × 13.33.
- **Зображення** з Figma мають роздільність @2x (мініатюри 168 px для слота 84 pt). Файли — JPEG, тому розширення `.jpg`.
- **«N recorded spots»** рахується з довжини mock-списку (у Figma — «24», у застосунку — фактична кількість).
- **Зірки рейтингу:** у дизайні 4.9 → 5 повних зірок, а 4.8 і 4.7 → 4 повні + половинка. Правило: дробова частина ≥ 0.85 → повна зірка, ≥ 0.25 → половинка.
- **Стартовий екран для скриншотів:** `--dart-define=INITIAL_ROUTE=/home --dart-define=INITIAL_TAB=2`, див. `lib/app/dev_launch_options.dart`. Без них застосунок стартує з Login. (Змінні оточення `SIMCTL_CHILD_*` не підійшли: на iOS `Platform.environment` у Dart їх не бачить.)
- **Шрифт:** Inter 4.1 (static TTF, OFL), ваги 400/500/600/700. Перевірено вимірюванням через `TextPainter` проти ширин текстових вузлів Figma: Inter 4.1 збігається до 0.02 px (helper 269.91 проти 269.92, «PlacesCatalog» 228.03 проти 228.03), Inter 3.19 відхиляється до 1.2 px.
- **Кнопка «ока»** у полі пароля: як на Login, 44 × 44 + 16 pt праворуч (центр гліфа ≈38 pt від краю поля). На Registration вона стоїть ближче до краю.
- **Чипси фільтрів:** візуально 32 pt, а зона натискання — уся висота ряду (40 pt), бо ряд у Figma має висоту 40. Це на 4 pt менше за мінімум HIG у 44 pt: свідомий компроміс, щоб не зсувати макет.
- **Переноси в підзаголовках auth-екранів** взято з Figma (явні `\n` у `AppStrings`): автоматичний перенос за шириною 260 давав інші рядки.
- **Register:** блок «or continue with» компактніший, ніж на Login (як у Figma: лінія на 24 pt нижче кнопки, соц-кнопки на 24.75 pt нижче лінії). Через уніфіковані лейбли (line-height 16 замість 13) форма нижча за Figma на ~7 pt (виміряно по пікселях).
- **Legal-текст на Login/Register** на iPhone 17e опиняється нижче згину екрана, бо у фреймах Figma немає статус-бару (+47 pt). Контент скролиться, overflow немає (див. `test/layout_test.dart`).
- **Методика звірки:** скриншот симулятора (iPhone 17e, @3x → 1x) обрізано на safe area 47 pt і поставлено поруч з рендером фрейму Figma (`docs/compare/`). Позиції елементів міряно по пікселях: Login, Forgot, Home, Profile і Change Password збігаються з Figma в межах ±0.5 pt.

## Етап 2

- **Стан каталогу піднято в `MainShell`** (lifting state up): Home і Favorites отримують `List<Place>` параметром і повідомляють про зміни колбеками. Тому Favorites завжди показує фактично обрані на Home заклади: Daily Grind, MOMA, Atelier. У Figma Favorites там Osteria, хоча на Home у неї порожнє сердечко, тож дизайн тут суперечить сам собі.
- **Atelier Pastel Cafe** з фрейму Favorites додано в mock-дані з датою 02.11.2022, щоб не змінювати порядок карток Home («Sorted by Recent»).
- **Favorites:** пошук і чипси уніфіковано за Home (40 pt, текст 13), тоді як у Figma Favorites 36 pt і 15. Картка Favorites — варіант `PlaceCard.favorites`, точно за Figma (відступ 12, мініатюра 88, одна зірка).
- **Place Details:** у Figma дві кнопки «назад» (у шапці й на фото); кругла кнопка на фото прибрана 08.10, лишилась лише кнопка в шапці. Рейтинг береться з даних (5.0, як на Home), а не 4.9 з фрейму.
- **Place Details отримує дані через `RouteSettings.arguments`** (`PlaceDetailsArgs`). Location Picker повертає адресу через `Navigator.pop(result)` і відкривається як `fullscreenDialog` (знизу, з «Cancel»).
- **Location Picker:** нижня картка стоїть над home indicator (Safe Area), а в Figma — за 16 pt від краю фрейму. Кнопка Confirm уніфікована з `PrimaryButton` (радіус 12 замість 16).
- **HIG:** зірки на Add Place (32 pt) і хрестики видалення фото й тегів менші за 44 pt — так у дизайні.
- **Мапи** — статичні зображення з Figma (`map_soho.png`, `map_manhattan.jpg`) низької роздільності (512 px), тож на @3x вони трохи розмиті.

## Правки після рев'ю (08.10.2026)

- **Profile:**
  - пункти App Settings та iCloud Sync & Backup прибрано (у вимогах FR2 їх немає); iCloud більше ніде не згадується, крім прикладу адреси `name@icloud.com` у полях email;
  - олівець біля аватара відкриває новий екран **Edit Profile** (ім'я, email, фото: «Remove Photo» / «Use Default Photo»). Результат повертається через `Navigator.pop(user)`, і `ProfileScreen` (тепер `StatefulWidget`) показує оновлені дані. Без фото аватар показує ініціали (`UserAvatar`);
  - **Export Places Archive** (FR2) відкриває екран із JSON-архівом поточного каталогу (`dart:convert`), розміром файлу й кнопкою «Copy JSON» (буфер обміну). Справжнього файлу й бекенду немає.
  - Екранів Edit Profile і Export у Figma немає, тож вони зверстані в тій самій візуальній мові, що й Change Password.
- **Favorites:** кнопку **Edit** прибрано. В iOS вона вмикає режим масового видалення, але сердечко на кожній картці вже прибирає заклад з обраного, тож режим лише дублював би цю дію.
- **Place Details:**
  - «Edit» біля нотаток перемикає блок у текстове поле, а «Done» зберігає текст і оновлює час «Updated»;
  - «+ Add Tag» відкриває `CupertinoAlertDialog` із полем вводу;
  - зміни повертаються в `MainShell` через колбек `onUpdate`, тож зберігаються після виходу з екрана;
  - «Open in Apple Maps» лишається неактивним: для нього потрібен плагін `url_launcher`.
- **Home:** «Sorted by …» — випадне меню (`MenuAnchor`) з варіантами Recent / Oldest / Rating / Name; сортування описане `enum HomeSort` з компаратором, як фільтри в `HomeFilter`.
- **Login і Register без скролу на iPhone 17** (402 × 874 pt, корисна висота ≈778 pt):
  - відступи стиснуто відносно Figma: Login приблизно на 95 pt, Register приблизно на 90 pt (поля 10 замість 16, блок «or continue with» 14/14, логотип–заголовок 16);
  - legal-текст і «Already have an account?» притиснуто до низу екрана через `AuthPage`;
  - на менших екранах, з текстом 120 % або з відкритою клавіатурою сторінка скролиться, а не переповнюється;
  - перевірено тестами: `maxScrollExtent == 0` на iPhone 17 для обох екранів.
- **Застарілі порівняння:** склейки в `docs/compare/` для Login, Register, Favorites і Place Details зроблено до цих правок. Актуальні скриншоти — у `docs/report/screenshots/` (iPhone 17).

## Правки 08.10.2026 (друга ітерація)

- **Нотатки на Place Details не «стрибають» при Edit.** Блок має той самий фон, відступи та рамку 1 pt в обох режимах (змінюється лише колір рамки), рядок «Updated» не зникає. Текст у режимі перегляду має праворуч 3 pt (як `TextField` резервує під курсор), тож переноси рядків однакові. Перевірено тестом: розмір блоку до й після Edit збігається.
- **Letter-spacing у полях вводу.** `TextField` змішує стиль із `bodyLarge` теми Material 3, де letter-spacing 0.5, тож текст у полях був ширшим за Figma. Тепер усі стилі `AppTextStyles` мають явний `letterSpacing` (0, якщо у Figma його немає).
- **Єдиний компонент тегів `TagList`** (`lib/core/widgets/tag_list.dart`) на Add Place і Place Details: чипси з «×» для видалення та кнопка «+ Add Tag», що відкриває той самий `showAddTagDialog` (`lib/core/widgets/add_tag_dialog.dart`). Поле «Add tag...» з Figma Add Place замінено цією кнопкою, щоб взаємодія була однаковою.

## ЛР №4 — Firebase (29.10.2026)

### Налаштування
- **Firebase-проєкт:** `placescatalog-7730`. Застосунки iOS (`ua.lpnu.pz33.placesCatalog`) і Android (`ua.lpnu.pz33.places_catalog`) зареєстровано через `flutterfire configure --platforms=ios,android`.
- **Конфіги в git:** `firebase_options.dart`, `GoogleService-Info.plist`, `google-services.json` комітимо. Це не секрети: доступ обмежують правила й обмеження API-ключа.
- **Пакети:** `firebase_core ^4.15.2`, `firebase_auth ^6.7.1`, `firebase_analytics ^12.6.1`, `firebase_crashlytics ^5.4.1`, `google_sign_in ^7.2.0` (Firebase iOS SDK 12.19.3 через Swift Package Manager, iOS ≥ 15.0, Android minSdk 24).
- **Чому не найновіші мажорні версії Firebase-плагінів.** Спершу стояли `firebase_core ^5.1.0` / `firebase_auth ^7.0.1` / `firebase_analytics ^13.0.1` / `firebase_crashlytics ^6.0.1` (Firebase iOS SDK 13). Збірка під iOS не проходить: SDK 13 вимагає `gtm-session-fetcher` 4.0.0..<6.0.0, а найновіший `google_sign_in_ios` 6.3.8 тягне GoogleSignIn-iOS 9.x, якому потрібен `gtm-session-fetcher` 3.3.0..<4.0.0 (Swift Package Manager не може узгодити залежності). Попередня лінійка плагінів (опублікована 23.10.2026) використовує SDK 12.19.3 з діапазоном `gtm-session-fetcher` 3.4.1..<6.0.0, тож сумісна з GoogleSignIn 9. За CHANGELOG єдина breaking-зміна мажорних версій — оновлення нативного SDK; Dart API, яким користується застосунок, той самий. Повернутися на нові версії можна, коли `google_sign_in_ios` перейде на GoogleSignIn-iOS 10.
- **iOS:** у `Info.plist` додано `GIDClientID` (= `CLIENT_ID`) і URL scheme `REVERSED_CLIENT_ID` з `GoogleService-Info.plist`, як вимагає `google_sign_in_ios` 7.x. Build phase `FlutterFire: upload-crashlytics-symbols` для dSYM додав FlutterFire.
- **Інструменти:** для `flutterfire configure` встановлено Ruby-гем `xcodeproj` (Homebrew Ruby). Android toolchain на машині не встановлений, тож Android-конфіг згенеровано, але збірку не перевірено.

### Архітектура
- **`AuthRepository`** (`lib/data/repositories/`) — єдина точка роботи з Firebase Auth. `firebase_auth` і `google_sign_in` імпортує лише `firebase_auth_repository.dart`; у `lib/features` і `lib/core` SDK немає. `FakeAuthRepository` використовують тести і скриншот-режим (`--dart-define=FAKE_AUTH=signed_in|signed_out`).
- **`AuthFailure`** (`lib/core/errors/`): enum типів + `fromCode(FirebaseAuthException.code)` → текст з `AppStrings`. Невідомий код → загальне повідомлення + `recordError(fatal: false)` у Crashlytics.
- **`AppScope`** (`InheritedWidget`) передає `AuthRepository`, `AnalyticsService` і `CrashReporter` без state-management бібліотек.
- **`AuthGate`** — корінь (`/`): `StreamBuilder` на `authStateChanges()` показує splash, Login або `MainShell`. Побічні ефекти (`popUntil(isFirst)`, userId в Analytics і Crashlytics) — в окремій підписці, не в `build()`. Login і Register більше не навігують на Home вручну.
- **`signInWithGoogle()` повертає `Future<bool>`** (`false` — користувач закрив вікно Google) замість `Future<void>` з брифу: так UI знає, чи логувати `login`.
- **Linking:** `fetchSignInMethodsForEmail` у сучасних версіях `firebase_auth` видалено (з міркувань безпеки — запобігання переліку email). На `account-exists-with-different-credential` беремо `e.email` і `e.credential`, просимо пароль, `signIn`, потім `linkWithCredential` (`completeGoogleLink`). У Profile група Connected Accounts дає «Link» для Google. Примітка: для адрес Gmail Google — довірений провайдер, і Firebase може не повертати account-exists, а автоматично об'єднати акаунти, якщо в налаштуваннях консолі ввімкнено «Link accounts that use the same email».

### UI-стани та форми
- **`AppTextField` побудовано на `FormField<String>`:** `validator`, `errorText` (помилка сервера для поля, наприклад неправильний поточний пароль), `readOnly` (блокування під час відправки без «вицвітання»). Помилка — червона рамка й червоний текст замість helper.
- **`PrimaryButton(isLoading)`:** `CupertinoActivityIndicator` замість тексту; повторні натискання ігноруються, поля в `readOnly`, тож другий запит відправити неможливо.
- **`ErrorBanner`** — для помилок сервера над кнопкою. Діалоги — для `requires-recent-login`, помилки прив'язки.
- **`GlobalKey<FormState>`** — поле `State`. `autovalidateMode: onUserInteraction` вмикається після першої спроби відправки.
- **Login** перевіряє пароль лише на заповненість; політика (≥ 8 символів і цифра) — для нових паролів (Register, Change Password).
- **Forgot Password:** нейтральний текст «If an account exists…», бо в проєкті ввімкнено email enumeration protection.
- **Change Password:** спершу reauth з Current Password, потім `updatePassword`. Неправильний поточний пароль показується під полем; на `requires-recent-login` — діалог «Log In Again» з виходом. Для Google-only акаунта рядок пояснює, що пароля немає.
- **Edit Profile:**
  - 8 пресет-аватарів DiceBear (`notionists`, стабільні HTTPS-посилання, перевірено 200 OK) або власне посилання (`https://`, прев'ю з `loadingBuilder` / `errorBuilder`);
  - email лише для читання;
  - старий варіант «Remove Photo / Use Default Photo» з ЛР №3 прибрано: фото тепер — це Firebase `photoURL`.
- **Profile:** ім'я, email, фото й провайдери — з `userChanges()`; статистика лишається mock (`mockUser.stats`).
- **Apple (змінено за вимогою методички):** спершу була заглушка-діалог. Після підтвердження підключено пакет `sign_in_with_apple ^8.2.0` (+ `crypto` для SHA-256). Нативний потік у `FirebaseAuthRepository.signInWithApple()`: випадковий nonce, Apple отримує його SHA-256, Firebase — сирий (`OAuthProvider('apple.com').credential`); ім'я Apple віддає лише при першому вході, тому зберігається тоді через `updateDisplayName`. Скасування — не помилка (`false`). Додано `ios/Runner/Runner.entitlements` (`com.apple.developer.applesignin`) і `CODE_SIGN_ENTITLEMENTS` у Xcode. Обмеження: на реальному пристрої capability «Sign in with Apple» потребує платного Apple Developer Program і Team у Xcode; на Simulator потрібен Apple ID, увійдений у Settings симулятора. Android не підтримується (потрібен веб-потік із Services ID) — там `appleUnavailable`.

### Analytics і Crashlytics
- **`FirebaseAnalyticsObserver`** у `navigatorObservers` логує `screen_view` для іменованих маршрутів. Вкладки в `IndexedStack` логуються вручну (`logScreenView` у `MainShell._selectTab`).
- **Події:** `sign_up`, `login` (method: password / google), `password_reset_requested`, `password_changed`, `profile_updated {photo_source}`, `place_favorite_toggled {place_id, is_favorite: 0/1}` (булеві значення в параметрах не дозволені), `place_opened {place_id, category}`, `account_linked {provider}`.
- **Crashlytics:** `FlutterError.onError = recordFlutterFatalError`, `PlatformDispatcher.instance.onError` → `recordError(fatal: true)`. `setUserIdentifier(uid)` — без email. Breadcrumbs `log('Auth: …')` без паролів і токенів.
- **Тестові помилки:** довге натискання на футер «PlacesCatalog · Version 1.0» у Profile відкриває Developer Tools з «Send Test Non-Fatal Error» і «Force Test Crash». Меню працює лише не в release (`kReleaseMode`).

## ЛР №5 — локальні дані та керування станом (Фаза 1)

- **Список на слівер-ах.** Home і Favorites переведено з `ListView(children: …)` на `CustomScrollView`: заголовок, пошук і чипи — `SliverToBoxAdapter`, картки — `SliverList.separated` (створюються ліниво, ключ `ValueKey(place.id)`). Відступи та вигляд ті самі. `GridView` у дизайні немає (вертикальні картки), тож його не використано.
- **Одна форма для створення й редагування.** `AddPlaceScreen` → `PlaceFormScreen(initial: Place?)`. Вона повертає готовий `Place` через `Navigator.pop`, а не пише в сховище сама: форма не знає, де зберігається каталог.
- **Edit Place** у Figma немає. Точка входу — олівець у `AppNavHeader` на Place Details (`AppRoutes.editPlace`), форма в стилі Add Place; заголовок «Edit Place», кнопка «Save Changes».
- **Валідація:** `Form` + `GlobalKey<FormState>`; назва 2–50 символів, локація обов'язкова. Рядки групи — кастомні контроли, тому їхні помилки показує `_FieldError` (`FormField`) під групою. Помилки з'являються після першої спроби зберегти.
- **Порожня форма.** Демо-текст з Figma лишається лише з `--dart-define=DEMO_FORM=true` (скриншоти). Оцінки Food/Service/Atmosphere стартують із 3 зірок: `Review` вимагає оцінку ≥ 1.
- **Новий `id`** — `DateTime.now().microsecondsSinceEpoch` (без зовнішніх пакетів). `subtitle` береться з назви категорії. Обкладинка — перше фото або `photoStorefront`.
- **Тимчасово (до Фази 3):** створення й редагування повертаються в `MainShell` через колбеки; `PlacesBloc` їх замінить.

## ЛР №5 — Фаза 2: дані й сховище

- **Пакети:** `flutter_bloc ^9.1.1`, `equatable ^3.0.0`, `shared_preferences ^2.5.6`, `path_provider ^2.1.6`; dev: `bloc_test ^10.0.0`.
- **Серіалізація вручну** (`toJson` / `fromJson` у `Place`, `Review`, `PlacePhoto`), без генерації коду. Категорія зберігається за `name` (перестановка enum не псує дані), дати — ISO-8601. Екран Export Archive використовує той самий `Place.toJson`.
- **`PlacesRepository`** (interface): `loadPlaces(uid)`, `savePlace(uid, place)` (вставка або заміна), `deletePlace(uid, id)`. `uid` — параметр, бо репозиторій створюється до входу. Реалізації: `LocalPlacesRepository` (файл) і `InMemoryPlacesRepository` (тести, `FAKE_AUTH`, з `delay`/`failLoad` для станів loading/error).
- **`LocalPlacesRepository`:** файл `places_<uid>.json`; перший запуск — сид із `mockPlaces`; запис через тимчасовий файл + `rename` (атомарно), записи ставляться в чергу; пошкоджений JSON → `recordError` (non-fatal) і відновлення сиду. Каталог приймається через конструктор.
- **Чому файл, а не SharedPreferences:** каталог — зростаючий список вкладених об'єктів; SharedPreferences призначений для кількох малих пар ключ–значення. База даних (Hive/Drift) надмірна й заборонена брифом.
- **`SettingsRepository`:** фільтр і сортування Home як імена enum (`<uid>.catalog.filter|sort`); дані шару не залежать від `HomeFilter`/`HomeSort`. Пошуковий запит не зберігається (ephemeral). Використано класичний `SharedPreferences` (`getInstance`), бо його підтримує `setMockInitialValues` з методички.
- **Secure storage не додано:** токени тримає Firebase сам, секретів застосунок не зберігає.
- Обмеження: фото — демо-ассети (файли — ЛР №6); синхронізації між пристроями немає.

## ЛР №5 — Фаза 3: BLoC для каталогу

- **`PlacesBloc`** (`features/places/bloc/`, події й стани — `part`-файли): `PlacesLoadRequested`, `PlaceCreated`, `PlaceUpdated`, `PlaceDeleted`, `PlaceFavoriteToggled`, `PlaceOpened`. Стан `PlacesState(status, places, errorMessage)` — `Equatable`, список щоразу новий. Зміна спершу зберігається через `PlacesRepository`, і лише потім `emit` (екран не показує те, чого немає на диску). Помилка збереження лишає список і ставить `errorMessage` (одноразовий `AlertDialog` у `MainShell` через `BlocListener`); помилка завантаження — `failure` + кнопка Retry. Аналітика (`place_favorite_toggled`, `place_opened`) перенесена з віджетів у блок; подія `PlaceOpened` не змінює дані.
- **`CatalogViewCubit`** (`features/home/bloc/`): `query` (лише в пам'яті), `filter`, `sort` (зберігаються через `SettingsRepository`, відновлюються при створенні). Видимий список — чиста функція `visiblePlaces(places, view)`. Cubit, а не Bloc: три прості сеттери без потреби в подіях.
- **`AppScope` видалено.** Залежності (`AuthRepository`, `PlacesRepository`, `SettingsRepository`, `AnalyticsService`, `CrashReporter`) надає `MultiRepositoryProvider` у `main.dart`, екрани читають `context.read<T>()`. `test_harness` зберіг `withScope(child, {auth})` і `testApp(home)`.
- **Відхилення від брифу: `UserScope` у `MaterialApp.builder`, а не в `AuthGate`.** Роути Details/форми, які додає `Navigator.push`, не є нащадками роута `AuthGate`, тож блоки, створені в `AuthGate`, були б для них недоступні. `UserScope` стоїть над `Navigator`, слухає `authStateChanges()` і створює `PlacesBloc` та `CatalogViewCubit` з `key: ValueKey(uid)`: при зміні акаунта обидва скидаються. Фаза 4 замінить `StreamBuilder` усередині на `BlocBuilder<AuthBloc>`.
- **Екрани:** `MainShell` більше не володіє списком (лишився індекс вкладки — ephemeral state). `HomeScreen`/`FavoritesScreen` без параметрів-колбеків; Favorites — те саме джерело істини, відфільтроване за `isFavorite`. `PlaceDetailsScreen` читає заклад через `BlocSelector` за `id`; `PlaceDetailsArgs` має лише `placeId`. Статистика Profile тепер обчислюється з каталогу (раніше — mock).
- **Стани Home:** `loading` (`CupertinoActivityIndicator`), `failure` (`ErrorState` з Retry), порожній результат — `EmptyState`. У режимі `FAKE_AUTH` репозиторій у пам'яті має затримку 400 мс, щоб loading було видно.

## ЛР №5 — Фаза 4: BLoC для auth і профілю

- **`AuthBloc`** (`features/session/bloc/`): стани `AuthInitial` (splash) / `Authenticated(user)` / `Unauthenticated`; підписується на `authStateChanges()` через `emit.forEach` (без ручної `StreamSubscription`). Початковий стан береться з `currentUser`, якщо SDK вже відновив сеанс. Живе весь час роботи застосунку (`BlocProvider` у `main.dart`). `AuthGate` — `BlocBuilder` + два `BlocListener`: ідентифікатор користувача для Analytics/Crashlytics і `popUntil` після входу/виходу з накладеного екрана (не для першого стану). Невдалий Log Out лишає `Authenticated` з `logoutError`, який Profile показує один раз.
- **`LoginBloc`:** події `LoginSubmitted`, `LoginGoogleRequested`, `LoginAppleRequested`, `LoginGoogleLinkConfirmed/Cancelled`; стани `Initial / Loading / Success / Failure(message) / LinkRequired(email)`. У `LoginLoading` нові події ігноруються (перевірка стану, без `bloc_concurrency`). Діалог пароля для об'єднання акаунтів — побічний ефект у `BlocListener` (`LoginLinkListener`).
- **`RegisterBloc`:** лише e-mail/пароль. Кнопки Google/Apple на екрані реєстрації надсилають події в `LoginBloc`, тому `RegisterScreen` створює обидва блоки; «зайнято» = будь-який із них у `Loading`.
- **`ForgotPasswordCubit`** і **`ChangePasswordCubit`** — Cubit: один метод, простий стан. `ChangePasswordState` зберігає `failureType`, за яким екран вирішує, куди вивести помилку: під полем (неправильний поточний пароль), діалог «Log In Again» (`requires-recent-login`, виходить через `AuthBloc`) або банер.
- **`ProfileBloc`** (по користувачу, у `UserScope`): `ProfileStarted` (підписка на `userChanges()`), `ProfileUpdated`, `ProfileGoogleLinkRequested`, `ProfileErrorDismissed`. Статуси `loading / idle / saving / linking / saveFailure / linkFailure` — помилки збереження й прив'язки розділені, щоб одна не з'являлась на екрані іншої. Перехід `saving → idle` — сигнал «збережено» для Edit Profile.
- **Екрани** лишились із тим самим UX; `_submitting`/`_error` у `setState` замінені станами блоків. У `lib/features/**/screens` немає `firebase_auth`, диска чи прямих викликів `auth.…`.
- **`FakeAuthRepository`:** потік `authStateChanges()` переписано з `async*` на `StreamController.onListen`. У генератора зміна відразу після `listen` могла загубитися; помітили на тестах `ProfileBloc`.

## ЛР №6 — Firestore, файли, мапа

### Фаза A: схема, модель, репозиторій Firestore, rules
- **Специфікація ЛР №2** знайдена в `docs/input/Фітьо_Лаб2_КПП.docx`. Нумерація FR у ній: FR6 — редагування, FR7 — видалення, FR8 — фото, FR11 — мапи. Частина доккоментарів у коді (ЛР №3) містить застарілі номери (напр., «FR4, FR8» на формі); таблиця статусів у `docs/report_lab6/` спирається на документ.
- **Пакети:** `cloud_firestore ^6.10.2` (лінійка, сумісна з `firebase_core ^4.15.2`), `supabase_flutter`, `image_picker`, `cached_network_image`, `flutter_map`, `latlong2`, `dio`, `url_launcher`, `uuid`. `fake_cloud_firestore` **не додано**: усі його версії тягнуть `fake_firebase_security_rules`, який вимагає `equatable ^2`, а проєкт на `equatable ^3`, тож `pub` не знаходить рішення.
- **Тестованість без fake Firestore.** SDK ізольовано в одному класі `FirestorePlacesDocumentStore` (`lib/data/firestore/`), який лише переносить `Map` туди й назад (і перетворює `DateTime` ↔ `Timestamp`). Логіка репозиторію (засів, порядок, мапінг помилок, таймаут запису) тестується на `InMemoryPlacesDocumentStore`.
- **`PlacePhoto` — три походження** (`PhotoKind`: `asset`, `local`, `remote`). Лише `remote` має метадані хмари (`storagePath`, `contentType`, `uploadedAt`). Локальне фото ніколи не потрапляє у Firestore (мапер кидає `StateError`). `Place.coverImage` став `PlacePhoto`; додано `createdAt`. Старі файли ЛР №5 (поля `imageAsset`, рядковий `coverImage`) читаються.
- **Один віджет показу фото** — `PlaceImageView` (`asset` → `Image.asset`, `local` → `Image.file`, `remote` → `CachedNetworkImage` з placeholder і error-віджетом).
- **Схема:** `users/{uid}` (профіль-дзеркало, `seededAt`) і `users/{uid}/places/{placeId}`. `review` вкладений в документ закладу (1:1, завжди читається разом), `photos` — масив ≤ 5 (одне читання на заклад, малі ліміти; підколекції дали б зайві запити). Порядок — `orderBy('visitDate', desc)`; другорядний ключ (`createdAt`, `id`) застосовується в коді, щоб не вимагати складеного індексу.
- **Засів один раз** — транзакція `seedOnce`: якщо `users/{uid}.seededAt` уже є, нічого не пишемо. Інакше після видалення всіх закладів демо-каталог «воскресав» би. Без мережі транзакція неможлива: тоді читається кеш, а засів повторюється пізніше.
- **Офлайн-запис.** `Future` запису Firestore завершується лише після підтвердження сервера. `savePlace`/`deletePlace` чекають `writeTimeout` (4 с); таймаут трактується як «збережено локально, синхронізується», бо SDK сам доставить запис. Помилка, що прийде пізніше (наприклад, rules), іде в Crashlytics.
- **Помилки:** `FirebaseException` → `PlacesFailure` (`permissionDenied`, `offline`, `invalidInput`, `unknown`); пошкоджений документ пропускається й логується, а не ламає список.
- **Пагінація:** `loadPage(perPage, cursor)` на всіх бекендах; екран використовує `watchPlaces` (фільтр і пошук локальні, тому потрібен весь каталог).
- **Rules** (`firestore.rules`): лише власник читає й пише `users/{uid}/**`; валідація місця (назва 2–50, категорія зі списку, `photos.size() <= 5`, типи координат). Каталог — **особистий щоденник**, тому на відміну від прикладу методички («публікації бачать усі») дані приватні. Файл компілюється (`firebase deploy --only firestore:rules --dry-run`); реальний деплой — після створення бази в консолі.
- **`watchPlaces` без `async*`:** підписка скасовується миттєво (`reloadingStream` на `StreamController`); у генератора `cancel()` чекає наступної події й міг «зависати» разом із `Bloc.close()`.

### Фаза B: `PlacesBloc` на живому потоці, профіль-дзеркало, вибір бекенда
- **`PlacesBloc` підписується на `watchPlaces`** (`PlacesLoadRequested` підписує або перепідписує після Retry). Блок не «вважає» запис успішним: показує те, що репозиторій повідомив через потік, тому зміна з іншого пристрою з'являється так само, як власна. `PlaceDeleted` і обране лише пишуть у репозиторій; новий список приходить із потоку. `PlaceCreated`/`PlaceUpdated` лишено тимчасово тонкими обгортками (лише `savePlace`); у фазі D їх замінюють `CreatePlaceBloc` і `UpdatePlaceBloc`.
- **`UserProfileRepository`** (`users/{uid}`): `displayName`, `email`, `photoUrl`, `lastLoginAt`; `createdAt` пишеться лише вперше. Викликається в `AuthGate` при вході й у `ProfileBloc` після збереження профілю; ніколи не кидає (best-effort, помилка йде в Crashlytics).
- **Вибір бекенда:** за замовчуванням Firestore; `--dart-define=PLACES_BACKEND=local` — JSON-файл із ЛР №5 (тести й код збережено); у режимі `FAKE_AUTH` — пам'ять. Persistence Firestore вмикається явно в `main.dart`.
- **iOS-збірка** з усіма новими пакетами (`cloud_firestore`, `supabase_flutter`, `image_picker`, `flutter_map`, …) проходить без конфліктів Swift Package Manager.

### Фаза C: вибір фото, `PlaceImageView`, `MediaRepository` (Supabase Storage)
- **Вибір фото** — `PhotoPickerService` (інтерфейс) і `ImagePickerPhotoService` на `image_picker`; у тестах `FakePhotoPickerService`. Натискання «Add Photos» / «N left» відкриває `CupertinoActionSheet` (Take Photo / Choose from Library / Cancel). Галерея: `pickMultiImage(limit: вільні слоти)`, камера: `pickImage(source: camera)`; стиснення прямо в пікері (`imageQuality 80`, `max 1600 px`) — це вимога NFR4. `requestFullMetadata: false`: системний пікер iOS не потребує дозволу, а повний набір метаданих змусив би iOS питати доступ до бібліотеки марно.
- **Валідація** (`PhotoRules`): лише `jpg/jpeg/png/webp`, ≤ 5 МБ після стиснення; ті самі обмеження в bucket. Скасування — не помилка (порожній результат). Окремі зрозумілі тексти для: заборонений доступ до фото, заборонена камера, немає камери (симулятор), завеликий файл, непідтримуваний тип, помилка читання.
- **Прев'ю миттєве:** обране фото — `PhotoKind.local`, показується з файла без мережі.
- **`MediaRepository`:** `uploadPlacePhoto(uid, placeId, local)` → `PlacePhoto.remote` (публічний URL + `storagePath`, `sizeBytes`, `contentType`, `uploadedAt`), `deletePhoto`, `deleteAll`. Відхилення від промпту: замість `File` приймає `PlacePhoto.local` (там уже шлях, розмір і MIME), а замість окремого `UploadedPhoto` повертає `PlacePhoto` (тип `remote`); параметра `onProgress` немає — `storage_client 2.8.1` не дає покадрового прогресу, тож UI показуватиме «Uploading 2 of 4».
- **Supabase без `Supabase.initialize`:** створюється лише `SupabaseClient(url, key)` і використовується `storage`. Так немає глобального стану, збереження сесії та обробки deep-link, яких ми не використовуємо (Supabase Auth не застосовується).
- **Шлях об'єкта** `users/<uid>/<placeId>/<uuid>.<ext>`: унікальне ім'я (файли не перезаписують один одного), каталог за користувачем і закладом, а не корінь bucket. `contentType` задається явно в `FileOptions`.
- **Конфіг** через `--dart-define` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`); ключів у репозиторії немає, `env/*.json` (крім `supabase.example.json`) у `.gitignore`, `.vscode/launch.json` читає `env/supabase.json`. Без ключів діє `NotConfiguredMediaRepository`: завантаження дає «Cloud storage is not configured», решта застосунку працює.
- **Android:** для `image_picker` у маніфесті нічого додавати не треба (системний Photo Picker, камера через intent). Додано `INTERNET` у основний маніфест: Flutter додає його лише в debug/profile, а release без нього не мав би доступу до Firestore, сховища, тайлів і Nominatim. iOS: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`.
