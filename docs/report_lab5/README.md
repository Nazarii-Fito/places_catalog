# Матеріали для звіту ЛР №5 — «Робота з локальними даними та керування станом»

Вхід для того, хто оформлює звіт (титул, тема, мета, постановка, результати, висновки пишуться окремо). Усе нижче перевірено за станом репозиторію на останній коміт. Код, ідентифікатори й UI-тексти — англійською, звіт — українською.

## 1. Що зроблено

- **Керування станом — BLoC (`flutter_bloc`) + Cubit.** Стан із `setState` і колбеків перенесено в блоки: каталог, сесія, вхід, реєстрація, профіль, зміна й відновлення пароля, вигляд списку.
- **Локальне сховище.** Каталог закладів — JSON-файл `places_<uid>.json` (`path_provider`), налаштування списку — `SharedPreferences`. Дані зберігаються між запусками й ізольовані по користувачу.
- **Повний CRUD закладів.** Створення, перегляд, редагування (нове: олівець на Place Details), видалення, обране.
- **Екрани й списки.** Home і Favorites — на слівер-ах/ледачих списках; форма закладу — `Form` + `GlobalKey`.
- **Стан перевірки:** `flutter analyze` — 0 зауважень; `flutter test` — 166 тестів зелені (BLoC, сховище, flow-сценарії, відсутність overflow на iPhone SE / 17 Pro Max з Dynamic Type ×1.2).

## 2. Версії та залежності

Нові: `flutter_bloc ^9.1.1`, `equatable ^3.0.0`, `shared_preferences ^2.5.6`, `path_provider ^2.1.6`; dev: `bloc_test ^10.0.0`. Усе інше без змін (Firebase-пакети з ЛР №4). Бібліотек Provider/Riverpod/get_it/Hive/Drift немає, кодогенерації (`freezed`, `json_serializable`) немає — серіалізація написана вручну.

## 3. Вимоги методички → де в коді

| Вимога | Де в проєкті | Матеріал |
|---|---|---|
| Завдання 1: вкладки Home/Favorites/Profile | `features/home`, `features/favorites`, `features/profile`, `features/shell` | Рис. 1–3 |
| Завдання 1: перегляд, створення, редагування об'єкта | `place_details_screen.dart`, `place_form_screen.dart` (режими create / edit) | Рис. 4–8 |
| Завдання 2.1: екран зі списком | `home_screen.dart` — `CustomScrollView`, `SliverToBoxAdapter`, `SliverList.separated`; Favorites — те саме | `code_examples.md` §2.1 |
| Завдання 2.2: екран перегляду / редагування | `place_details_screen.dart`, `place_form_screen.dart` | `code_examples.md` §2.2 |
| Завдання 3.1: реєстрація й логін | `LoginBloc`, `RegisterBloc`, `AuthBloc` (`features/auth/bloc`, `features/session/bloc`) | `code_examples.md` §3.3–3.4, §3.7 |
| Завдання 3.2: завантаження й редагування профілю | `ProfileBloc`, `ChangePasswordCubit` (`features/profile/bloc`) | §3.5–3.6 |
| Завдання 3.3: завантаження списків | `PlacesBloc` (`PlacesLoadRequested`, стани loading / loaded / failure) | §3.1; Рис. 9–10 |
| Завдання 3.4: створення, редагування, видалення | `PlacesBloc` (`PlaceCreated`, `PlaceUpdated`, `PlaceDeleted`, `PlaceFavoriteToggled`) | §3.1 |
| Використання в віджетах | `MultiRepositoryProvider`, `BlocProvider`, `BlocBuilder`, `BlocListener`, `BlocSelector`, `context.read/watch/select` | §3.8 |
| Завдання 4: локальне сховище | `LocalPlacesRepository` (файл), `SharedPrefsSettingsRepository`; виклик — `PlacesBloc._change`, `CatalogViewCubit` | `code_examples.md` §4 |
| Завдання 5: структура пакетів | після завдання 1 і наприкінці | `structure_after_task1.txt`, `structure_final.txt` |
| Контрольні питання | — | `defense_notes.md` (33 питання) |

## 4. Архітектура (для розділу звіту)

- **Шари:** `UI (screens)` → `Bloc/Cubit` → `Repository (interface)` → `реалізація` (Firebase / файл / SharedPreferences / пам'ять). Екрани не імпортують `firebase_auth`, `dart:io` чи `shared_preferences` (перевірено `grep` по `lib/features/*/screens` і `widgets`).
- **DI:** `MultiRepositoryProvider` у `main.dart` (`AuthRepository`, `PlacesRepository`, `SettingsRepository`, `AnalyticsService`, `CrashReporter`), `BlocProvider<AuthBloc>` над застосунком, читання через `context.read<T>()`.
- **Per-user блоки:** `UserScope` (`lib/app/user_scope.dart`) створює `PlacesBloc`, `CatalogViewCubit`, `ProfileBloc` з `ValueKey(uid)`. Він стоїть у `MaterialApp.builder` (над `Navigator`), бо pushed-екрани не є нащадками роута `AuthGate`. **Це відхилення від брифу** (у брифі — гілка «авторизований» в `AuthGate`).
- **`AuthGate`** — `BlocBuilder<AuthBloc>`; побічні ефекти (user id в Analytics/Crashlytics, `popUntil`) — у `BlocListener`.
- **Ephemeral state лишається в `StatefulWidget`:** поточна вкладка, поля й контролери форм, перемикач «custom link», пошуковий рядок. **App state — у блоках:** каталог, профіль, сесія, фільтр і сортування.
- **Блокування повторного запиту:** у `LoginLoading` / `RegisterLoading` / `submitting` події ігноруються перевіркою стану (без `bloc_concurrency`).

## 5. Локальне сховище — вибір і обмеження

| Дані | Сховище | Чому |
|---|---|---|
| Фільтр і сортування Home | `SharedPreferences` (`<uid>.catalog.filter`, `<uid>.catalog.sort`) | кілька простих пар ключ–значення |
| Каталог закладів | JSON-файл у `getApplicationDocumentsDirectory()`, атомарний запис (`.tmp` + `rename`), черга записів | структурований список, що росте; SharedPreferences для цього не призначений |
| Пошуковий запит | не зберігається | ephemeral |
| Токени, ключі | не потрібні, `flutter_secure_storage` не додано | сесію тримає Firebase Auth |

Поведінка файлу: перший запуск без файла — сид із демо-закладів (`mockPlaces`); пошкоджений JSON — non-fatal у Crashlytics, відновлення сиду. **Чесно про обмеження:** фото — демо-ассети (завантаження файлів — ЛР №6); синхронізації між пристроями немає (дані лише на пристрої).

## 6. Режими запуску для скриншотів і перевірки

`--dart-define=FAKE_AUTH=signed_in` — фейковий вхід, каталог у пам'яті (без диска); додатково `DEMO_FORM=true` (форма з демо-даними Figma), `FAKE_LOAD_DELAY_MS=<мс>` (тривалість завантаження, за замовчуванням 400), `FAKE_LOAD_FAIL=true` (завантаження завершується помилкою). Без цих параметрів застосунок працює зі справжніми Firebase і файлом. Команди — у `screenshots_todo.md`.

## 7. Що перевірено, а що зробити вручну

**Перевірено автоматично й на симуляторі (iPhone 17):** тести (див. вище); запуск реальної збірки з Firebase — відновлення сеансу й завантаження каталогу з файлу; скриншоти станів у режимі `FAKE_AUTH` (`screenshots/`).

**Чекліст для ручної перевірки (на симуляторі й на Samsung S23):**
1. Холодний старт (FAKE_AUTH): список з'являється після короткого loading.
2. Додати заклад → з'являється на Home; перезапуск застосунку → лишається (реальний режим, без `FAKE_AUTH`).
3. Редагувати заклад (назва, категорія, оцінки, нотатки, теги) → зміни на Home, Favorites, Details.
4. Видалити заклад (підтвердження) → зникає всюди, після перезапуску не повертається.
5. Сердечко на Home ↔ Favorites синхронізується, після перезапуску зберігається.
6. Змінити сортування / фільтр → перезапуск → значення збереглися; пошук не зберігається.
7. Вийти й увійти під іншим акаунтом → каталог і налаштування іншого користувача, без «протікання».
8. Login/Register: невірні дані, повторне натискання під час loading ігнорується, успіх, відновлення сеансу.
9. Edit Profile / Change Password: успіх, помилки, `requires-recent-login`.
10. Пошкоджений `places_<uid>.json` (підмінити вміст на `{ not json`) → застосунок не падає, сид відновлюється, помилка в Crashlytics як non-fatal.
11. Dynamic Type великий / маленький екран — без overflow.

**Не перевірено автором коду:** сценарії 2, 4–7, 9–10 на справжньому Firebase і на фізичному пристрої; Android-збірку (немає Android SDK); вхід через Google/Apple. Скриншот структури пакетів з IDE (завдання 5) робить автор: текстові версії — `structure_*.txt`.

## 8. Файли в цій папці

| Файл | Призначення |
|---|---|
| `README.md` | цей огляд |
| `code_examples.md` | фрагменти коду для звіту (згенеровано з актуальних джерел) |
| `structure_after_task1.txt`, `structure_final.txt` | структура пакетів після завдання 1 і наприкінці |
| `screenshots/`, `screenshots/captions.md` | скриншоти та підписи «Рис. N» |
| `screenshots_todo.md` | команди й список скриншотів, які знімає автор |
| `defense_notes.md` | відповіді на 33 контрольні питання + «підступні» питання |
| `../report/llm_usage.md` | розділ про використання LLM (додано розділ ЛР №5) |

## 9. Відхилення від брифу (розкрити у звіті)

- `UserScope` над `Navigator` замість гілки в `AuthGate` (причина — у розділі 4).
- Налаштування — класичний `SharedPreferences` (`getInstance`), а не `SharedPreferencesAsync`: його підтримує `setMockInitialValues` з методички.
- Кнопки Google/Apple на екрані реєстрації надсилають події в `LoginBloc` (окремо від `RegisterBloc`).
- Оцінки нового закладу стартують із 3 зірок: `Review` вимагає оцінку ≥ 1.
- `GridView` у дизайні немає (вертикальні картки), тому його не використано; пояснення — питання 32 у `defense_notes.md`.
- Повний журнал рішень — `docs/decisions.md` (розділи «ЛР №5»).
