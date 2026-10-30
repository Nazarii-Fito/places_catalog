# Скриншоти Firebase Console, які потрібно зробити самостійно

Консоль: https://console.firebase.google.com → проєкт **PlacesCatalog** (`placescatalog-7730`).

| # | Що зняти | Шлях у консолі | Що має бути видно | Вимога методички |
|---|---|---|---|---|
| 1 | Способи входу | **Build → Authentication → Sign-in method** | Email/Password — Enabled, Google — Enabled, Apple — Enabled | п. 3 |
| 2 | Об'єднання акаунтів | **Authentication → Settings → User account linking** | «Link accounts that use the same email» | п. 3 (linking) |
| 3 | Користувачі | **Authentication → Users** | тестові акаунти; у колонці Providers в одного — і пошта, і Google (після прив'язки) | п. 4 |
| 4 | Аналітика: огляд | **Analytics → Dashboard** | користувачі, події за період | п. 1 |
| 5 | Аналітика: події | **Analytics → Events** | `login`, `sign_up`, `screen_view`, `place_opened`, `place_favorite_toggled`, `profile_updated`, `password_changed`… | п. 1 |
| 6 | Аналітика в реальному часі | **Analytics → DebugView** (з увімкненим debug-режимом, див. нижче) | потік подій із симулятора | п. 1 |
| 7 | Звіт про помилки | **Run → Crashlytics → Issues** | тестовий non-fatal «PlacesCatalog test non-fatal error» і краш «Force Test Crash» | п. 2 |
| 8 | Деталі помилки | клік на issue → вкладки Stack trace / Keys / Logs | user id (uid), breadcrumbs `Auth: signIn`, `Developer menu: …` | п. 2 |

## Як отримати дані для скриншотів

**DebugView (iOS Simulator):** Xcode → `ios/Runner.xcworkspace` → Product → Scheme → Edit Scheme → Run → Arguments → **Arguments Passed On Launch** → `-FIRDebugEnabled` → запустити з Xcode. Події з'являться в DebugView за кілька секунд. Вимкнути можна аргументом `-FIRDebugDisabled`.

**DebugView (Android, коли буде телефон):** `adb shell setprop debug.firebase.analytics.app ua.lpnu.pz33.places_catalog`, вимкнути — `adb shell setprop debug.firebase.analytics.app .none.`

**Dashboard / Events** оновлюються із затримкою до 24 годин (DebugView — одразу).

**Crashlytics:**
1. Спочатку **Crashlytics → Enable Crashlytics** у консолі.
2. Зібрати й запустити застосунок, потім зупинити `flutter run`: краш не надсилається, поки під'єднаний дебагер.
3. Відкрити застосунок з домашнього екрана симулятора: Profile → довге натискання на «PlacesCatalog · Version 1.0» → **Send Test Non-Fatal Error** → знову меню → **Force Test Crash** (застосунок закриється). Звіти (і non-fatal, і краш) надсилаються при НАСТУПНОМУ запуску застосунку, а не одразу.
4. **Відкрити застосунок ще раз з домашнього екрана (не з Xcode і не через `flutter run`)** і почекати хвилину: саме тоді звіт іде в Firebase.
5. У консолі вгорі вибрати iOS-застосунок `ua.lpnu.pz33.placesCatalog` (не Android), період «Last 7 days», без фільтрів. Перший звіт може з'явитися через 5–10 хвилин; оновлювати Crashlytics → Issues.
