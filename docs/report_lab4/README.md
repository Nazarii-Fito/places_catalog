# Матеріали для звіту ЛР №4 — «Реалізація автентифікації та інтеграція з Firebase»

Цей файл — вхід для того, хто пише звіт (зокрема Claude desktop). Усе нижче перевірено за станом репозиторію на останній коміт. Мова звіту — українська; код, ідентифікатори й UI-тексти в застосунку — англійською.

## 1. Про проєкт і роботу

- **Застосунок:** PlacesCatalog (Flutter, iOS-first, дизайн за Apple HIG): особистий каталог закладів і місць. У ЛР №3 зверстано всі екрани на mock-даних; у ЛР №4 додано справжню автентифікацію та Firebase.
- **Firebase-проєкт:** `placescatalog-7730`. Застосунки: iOS `ua.lpnu.pz33.placesCatalog`, Android `ua.lpnu.pz33.places_catalog`.
- **Що підключено:** Firebase Analytics, Crashlytics, Authentication (email/пароль, Google, Apple), `AuthRepository`, валідація через `Form`. **Чого немає і так задумано:** Firestore, Storage, push-сповіщення та реальна статистика лишаються заглушками (mock-дані).
- **Стан перевірки:** `flutter analyze` — 0 зауважень, `flutter test` — 91 тест зелений. Перевірку зі справжнім Firebase виконано на iOS Simulator (iPhone 17).

## 2. Версії та залежності

| Пакет | Версія |
|---|---|
| firebase_core | ^4.15.2 |
| firebase_auth | ^6.7.1 |
| firebase_analytics | ^12.6.1 |
| firebase_crashlytics | ^5.4.1 |
| google_sign_in | ^7.2.0 |
| sign_in_with_apple | ^8.2.0 |
| crypto | ^3.0.8 (SHA-256 для nonce Apple) |

Нативний Firebase iOS SDK — 12.19.3 (через Swift Package Manager); iOS ≥ 15.0; Android minSdk 24. Flutter 3.47.4 / Dart 3.13.3.

**Чому не найновіші мажорні версії Firebase-плагінів (5.x/7.x/13.x/6.x).** Вони вимагають Firebase iOS SDK 13, який несумісний із `GoogleSignIn-iOS 9` (різні діапазони залежності `gtm-session-fetcher`), тож збірка під iOS не вирішувалася. Попередня лінійка плагінів має той самий Dart API. Деталі — у `docs/decisions.md`.

## 3. Відповідність вимогам методички → що показати у звіті

| Вимога | Де в проєкті | Матеріал |
|---|---|---|
| 1. Analytics | `lib/data/services/analytics_service.dart`, `main.dart`, `FirebaseAnalyticsObserver` + `logScreenView` для вкладок | `code_examples.md` §7, скриншот консолі №4–6 (`console_screens_todo.md`) |
| 2. Crashlytics + тестова помилка | `crash_reporter.dart`, обробники в `main.dart`, меню розробника (довге натискання на «PlacesCatalog · Version 1.0» у Profile, лише debug/profile) | `code_examples.md` §7–8, скриншот Рис. 18, скриншоти консолі №7–8 |
| 3. Auth: email/пароль + об'єднання способів входу | `firebase_auth_repository.dart`, `social_sign_in.dart`, `connected_accounts_group.dart` | `code_examples.md` §1, §4; скриншот консолі «Sign-in method» (№1–2); Рис. 9–10 |
| 4a. Реєстрація, вхід, відновлення пароля | `login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart` | Рис. 1–5, 19–23 |
| 4b. Профіль, зміна пароля | `profile_screen.dart`, `change_password_screen.dart`, `edit_profile_screen.dart` | `code_examples.md` §2, §5; Рис. 8–17, 21–25 |
| Фото профілю (HTTPS-пресети + власне посилання з прев'ю) | `avatar_picker.dart`, `app_assets.dart` (8 пресетів DiceBear) | Рис. 14–17, 24–25 |
| Стани: помилки, завантаження, блокування повторного запиту, вихід, відновлення сеансу, `requires-recent-login` | `PrimaryButton(isLoading)`, `ErrorBanner`, `AuthGate`, діалог повторного входу | Рис. 3–4, 7, 12–13, 21 |
| `AuthRepository` + приклад виклику з відображенням даних | `auth_repository.dart`, `firebase_auth_repository.dart` | `code_examples.md` §1–2 |
| 5. Валідація через `Form` + `GlobalKey` | `validators.dart`, екрани auth/profile | `code_examples.md` §3; Рис. 2, 11, 16 |
| 6. Повний `main.dart` | `lib/main.dart` | `code_examples.md` §8 |
| 7. Структура проєкту | — | `structure.txt` |
| Контрольні питання | — | `defense_notes.md` |

## 4. Архітектура (коротко для розділу звіту)

- Уся робота з Firebase Auth, Google Sign-In і Sign in with Apple — **лише в `FirebaseAuthRepository`**. Екрани в `lib/features/` та віджети в `lib/core/` не імпортують жодного з цих пакетів (перевірено `grep`). Це дає змогу підставити `FakeAuthRepository` у тести та в режим скриншотів.
- Залежності (`AuthRepository`, `AnalyticsService`, `CrashReporter`) передає екранам `AppScope` (`InheritedWidget`); бібліотек керування станом немає.
- `AuthGate` у корені слухає `authStateChanges()`: заставка → Login → `MainShell`. Завдяки цьому сеанс відновлюється після перезапуску, а вихід повертає на Login без ручної навігації.
- Помилки SDK перетворюються на `AuthFailure` (тип + людське повідомлення з `AppStrings`); сирі коди користувач не бачить, невідомі коди йдуть у Crashlytics як non-fatal.
- Форми: `Form` + `GlobalKey<FormState>` (ключ — поле `State`, не в `build()`), поле `AppTextField` на `FormField<String>`, автоперевірка вмикається після першої спроби відправки. Помилки Firebase (сервер) відображаються окремо від локальної валідації: банер над кнопкою або помилка біля поля.
- Crashlytics: `FlutterError.onError = recordFlutterFatalError`, `PlatformDispatcher.instance.onError` → `recordError(fatal: true)`, `setUserIdentifier(uid)`, breadcrumbs через `log()`.
- Analytics: стандартні `logSignUp`, `logLogin`, `setUserId`, `logScreenView`; власні події `password_reset_requested`, `password_changed`, `profile_updated`, `place_favorite_toggled`, `place_opened`, `account_linked`.

## 5. Відхилення від брифу і важливі рішення (розкрити у звіті чесно)

- `signInWithGoogle()` і `signInWithApple()` повертають `Future<bool>`, а не `void`: `false` означає, що користувач закрив вікно входу (це не помилка).
- `fetchSignInMethodsForEmail` у сучасному `firebase_auth` видалено з міркувань безпеки; об'єднання акаунтів спирається на `FirebaseAuthException.email` і `.credential`. У проєкті ввімкнено захист від перебору email, тому лист скидання пароля показує нейтральний текст.
- Apple спочатку була заглушкою-діалогом; після вимоги методички підключено справжній потік (див. `docs/decisions.md`).
- Меню тестових помилок Crashlytics доступне лише в debug/profile; у release довге натискання нічого не робить.
- Версії Firebase-плагінів — див. розділ 2.
- Повний журнал рішень — `docs/decisions.md` (розділ «ЛР №4 — Firebase»).

## 6. Що перевірено на справжньому Firebase, а що ні

**Перевірено (iOS Simulator, проєкт `placescatalog-7730`):** реєстрація; вхід із хибними даними (коректне повідомлення); відновлення сеансу після перезапуску; профіль із даними Firebase; зміна пароля (хибний поточний — помилка біля поля; правильний — успіх); лист скидання пароля (екран «Check your email»); збереження аватара через `updatePhotoURL`; запуск Firebase, Analytics, Crashlytics без падінь.

**Не перевірено автором коду (зробити вручну і додати у звіт, якщо потрібно):**
- вхід через **Apple** від кнопки до акаунта в Authentication → Users (потрібен Apple ID на симуляторі);
- вхід і прив'язка **Google** з реальним акаунтом Google;
- **Crashlytics:** тестова non-fatal помилка і тестовий краш (запускати не з дебагера, після краша відкрити застосунок ще раз);
- **Android:** згенеровано конфігурацію, але збірку не робили (немає Android SDK); потрібні SHA-1 і повторний `flutterfire configure`.

**Обмеження Apple:** на реальному iPhone вхід через Apple потребує платного Apple Developer Program і capability «Sign in with Apple» у Xcode; на симуляторі працює без нього. На Android цей спосіб не підтримується (повідомлення «not available»).

## 7. Скриншоти

- `screenshots/01…18` — зроблені в **fake-режимі** (`--dart-define=FAKE_AUTH=…`): так стабільно відтворюються помилки сервера, довге завантаження і `requires-recent-login`. Підписи («Рис. 1–18») — у `screenshots/captions.md`. Рис. 6 (системне вікно Apple) файлу ще не має: його знімає автор вручну.
- `screenshots/live/L01…L07` — **зі справжнім Firebase** (Рис. 19–25).
- Скриншоти консолі Firebase робить автор за `console_screens_todo.md`. Попередження: у Crashlytics можуть бути сторонні записи від налагодження («Bad state: Not found on screen…»); для звіту обирати issue з текстом тестової помилки «PlacesCatalog test non-fatal error» і краш «Force Test Crash».
- Тестовий акаунт `lab4.tester@example.com` (домен `example.com` зарезервований) створено лише для перевірки; його можна видалити в Authentication → Users.

## 8. Рекомендована структура звіту

1. Мета й завдання. 2. Підготовка Firebase (проєкт, `flutterfire configure`, `firebase_options.dart`, ініціалізація; версії пакетів). 3. Analytics (події, трекінг екранів, скриншоти консолі). 4. Crashlytics (обробники, тестова помилка, скриншоти). 5. Authentication (способи входу, об'єднання акаунтів, скриншот Sign-in method). 6. Архітектура: `AuthRepository`, `AuthFailure`, `AuthGate` (код з `code_examples.md`). 7. Валідація форм (код реєстрації). 8. Профіль: зміна пароля, `requires-recent-login`, фото профілю. 9. Тестування (91 тест, fake-режим). 10. Структура проєкту (`structure.txt`). 11. Повний `main.dart`. 12. Висновки. 13. Відповіді на контрольні питання (`defense_notes.md`).

## 9. Файли в цій папці

| Файл | Призначення |
|---|---|
| `README.md` | цей огляд |
| `code_examples.md` | код для звіту (згенеровано з актуальних джерел): репозиторій, `AuthFailure`, приклади виклику, форма реєстрації, соціальний вхід, зміна пароля, `AuthGate`, сервіси, `main.dart` |
| `structure.txt` | дерево `lib/` після змін + що додалося + конфігурація платформ і тести |
| `screenshots/`, `screenshots/captions.md` | скриншоти та підписи «Рис. N» |
| `console_screens_todo.md` | які скриншоти консолі Firebase зробити вручну і як отримати дані |
| `defense_notes.md` | відповіді на контрольні питання (25 тем із брифу, згруповано за темами; нумерованого списку з 32 питань у репозиторії немає) |
