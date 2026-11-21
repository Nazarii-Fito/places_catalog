# Матеріали для звіту ЛР №6 — «Синхронізація даних із хмарним сховищем. Робота з файлами та медіа»

Вхід для того, хто оформлює звіт. Усе нижче перевірено за станом репозиторію на останній коміт. Код, ідентифікатори й UI-тексти — англійською, документи — українською. Покрокові дії автора — `manual_steps.md`.

## 1. Що зроблено

- **Cloud Firestore** замість локального файла: колекції `users` та `users/{uid}/places`, правила доступу, `FirestorePlacesRepository`, живий потік змін, офлайн-кеш, одноразовий засів демо-каталогу.
- **Файли в Supabase Storage:** справжній вибір фото (камера/галерея, стиснення, валідація), завантаження в bucket `place-photos`, публічні URL і метадані у Firestore.
- **Окремі `CreatePlaceBloc` і `UpdatePlaceBloc`** (Creating → Error / Success) із відкатом завантажених файлів.
- **Справжня мапа** (`flutter_map` + OpenStreetMap) у виборі локації та на Details; **REST через `dio`** — пошук адрес і reverse geocoding (Nominatim); відкриття зовнішніх Карт (`url_launcher`).
- **Стан перевірки:** `flutter analyze` — 0 зауважень; `flutter test` — 297 тестів зелені; iOS-збірка проходить (перевірено `flutter build ios --simulator`). Реальний обмін із Firestore і Supabase **не перевірено** (див. розділ 9).

## 2. Версії та нові залежності

| Пакет | Версія | Навіщо |
|---|---|---|
| cloud_firestore | ^6.10.2 | база даних (лінійка, сумісна з `firebase_core ^4.15.2`) |
| supabase_flutter | ^2.18.3 | лише `SupabaseClient.storage` |
| image_picker | ^1.2.4 | камера й галерея |
| cached_network_image | ^4.0.7 | показ мережевих фото |
| flutter_map / latlong2 | ^8.3.2 / ^0.10.1 | мапа OpenStreetMap |
| dio | ^5.11.1 | REST (Nominatim) |
| url_launcher | ^6.3.3 | відкриття зовнішніх Карт |
| uuid | ^4.6.0 | унікальні імена файлів |
| geolocator | ^14.1.2 | кнопка «My location» (за вимогою автора) |

`fake_cloud_firestore` **не додано**: усі його версії тягнуть `fake_firebase_security_rules` з `equatable ^2`, а проєкт на `equatable ^3`. Тестованість забезпечено власним тонким шаром `PlacesDocumentStore` з in-memory реалізацією (`decisions.md`, фаза A).

## 3. Пункт методички → де в коді

| Завдання | Де в проєкті | Матеріал |
|---|---|---|
| 1. Таблиця статусів FR | розділ 4 цього файла | — |
| 2. Невиконані вимоги | розділ 5 | — |
| 3. Колекції Firestore і поля | розділ 6; `lib/data/firestore/place_mapper.dart` | скриншоти консолі |
| 4. Rules | `firestore.rules` (копія в цій папці); розділ 7 | скриншот вкладки Rules |
| 5. `cloud_firestore`, репозиторії, моделі | `firestore_places_repository.dart`, `firestore_places_document_store.dart`, `place_mapper.dart`, `place.dart`, `place_photo.dart` | `code_examples.md` §1–2 |
| 6. Списки з оновлених репозиторіїв | `PlacesBloc` (`watchPlaces`) | §3 |
| 7. Create / Update під керуванням BLoC | `create_place_bloc.dart`, `update_place_bloc.dart`, `photo_upload_session.dart`, `place_form_screen.dart` | §4 |
| 8. Файлове сховище (Supabase) | `media_repository.dart`, `supabase_media_repository.dart`, `supabase_config.dart`, `supabase_setup.md` | §5 |
| 9. REST через `dio` | `nominatim_geocoding_repository.dart`, `geocoding_result.dart`, `location_picker_cubit.dart` | §6 |
| Доробка 4.1: власні фото | `photo_picker_service.dart`, `add_place_pickers.dart`, `place_image_view.dart` | §7 |
| Доробка 4.2: мапа | `location_picker_screen.dart`, `details_sections.dart`, `osm_tile_layer.dart`, `map_launcher.dart` | §8 |
| Контрольне питання 29 (Storage + Firestore) | `PhotoUploadSession` + `PlaceMapper._photoToMap` | §4–5 |

## 4. Таблиця статусів FR (завдання 1)

Специфікація — `Фітьо_Лаб2_КПП.docx` (у `docs/input/`, локально). Нумерація FR із документа.

| FR | Вимога | Статус |
|---|---|---|
| FR1 | Реєстрація, вхід (email/Apple/Google), відновлення пароля | Виконано в ЛР №4 |
| FR2 | Профіль: статистика з розбивкою, зміна пароля, експорт JSON, зміна аватарки | Виконано в ЛР №3–6: статистика — реальна з каталогу (ЛР №5); аватарка — пресет, посилання (ЛР №4) і **власне фото з камери/галереї** (ЛР №6, зберігається в Supabase, URL — у `photoURL` та `users/{uid}`); профіль синхронізується в `users/{uid}` |
| FR3 | Головний екран: список карток із назвою, категорією, оцінкою, мініатюрою | Верстка ЛР №3, стан ЛР №5, дані з Firestore — **ЛР №6** |
| FR4 | Створення закладу (назва, категорія, дата, локація з адресою й GPS, оцінки, нотатка, теги, до 5 фото) | Виконано в **ЛР №3–6** (локація на мапі й фото — ЛР №6) |
| FR5 | Перегляд деталей (оцінки, нотатка, фото, мапа) | Виконано в ЛР №3 і **ЛР №6** (мапа, мережеві фото). Показ фото — головне з лічильником (як описує FR8); перегортання галереї — не виконано |
| FR6 | Редагування запису | Виконано в **ЛР №5–6** (повна форма та нотатки/теги на Details; оновлюється `updatedAt`) |
| FR7 | Видалення з підтвердженням (і всіх фото) | ЛР №3, ЛР №5; **ЛР №6**: разом із файлами у Storage |
| FR8 | Фото: вибір до 5 зображень, головне фото з лічильником | Виконано в **ЛР №6** |
| FR9 | Пошук і фільтрація за категоріями | Виконано в ЛР №3–5 |
| FR10 | Вкладка «Вибране» з власним пошуком | Частково: вкладка та власний пошук — ЛР №3–5; сортування й цитата нотатки на картці — **не виконано** (їх немає в макеті) |
| FR11 | Мапи: вибір локації (пошук, кнопка поточної геолокації, пін, адреса, GPS), мапа на Details, «Open in Apple Maps» | Виконано в **ЛР №6**: пошук закладів і адрес, заклади-маркери навколо, кнопка «My location». Відхилення: OpenStreetMap замість Apple Maps |

Нефункціональні вимоги (довідково): NFR1 (Safe Area, Tab Bar) — ЛР №3; NFR2 — iOS ≥ 15.0 (вимога Firebase SDK; у специфікації 14.0); NFR3 — ліниві слівери, час завантаження не вимірювався; **NFR4 (стиснення фото) — ЛР №6** (`imageQuality 80`, ≤ 1600 px, ≤ 5 МБ); **NFR5 (кеш і синхронізація) — ЛР №6** (Firestore persistence; створення з фото без мережі неможливе); NFR6 — HTTPS усюди, паролі хешує Firebase Auth; NFR7 (українська мова) — **не виконано**.

## 5. Невиконані вимоги й обґрунтування (завдання 2)

1. **Push-сповіщення / Cloud Functions** — дозволений виняток методички; у специфікації їх і немає.
2. **NFR7, локалізація (укр. + англ.).** Інтерфейс лише англійською; вимога не входить до завдань ЛР №3–6, потрібна окрема робота (`flutter_localizations`, ARB-файли).
3. **FR9, фільтри за тегами, рейтингом і датою** (згадані в загальному описі функцій, але не в самому FR9). Є категорії й пошук; решта не входила в макет.
4. **FR10, сортування й цитата нотатки на картці Favorites** — немає в макеті Favorites.
5. **FR5, перегортання галереї фото.** Details показує головне фото й лічильник (так описано в FR8); повноекранна галерея не реалізована.
6. **Android-збірка** не перевірялась (немає Android SDK); конфіги й дозволи підготовлені.

## 6. Схема Firestore (завдання 3)

```
users/{uid}                       профіль-дзеркало (1 документ на користувача)
└── places/{placeId}              заклад (підколекція)
```

**`users/{uid}`**

| Поле | Тип | Опис |
|---|---|---|
| `displayName` | string \| null | ім'я з Firebase Auth |
| `email` | string \| null | e-mail |
| `photoUrl` | string \| null | фото профілю |
| `createdAt` | timestamp | час першого входу (пишеться один раз) |
| `lastLoginAt` | timestamp | останній вхід / оновлення профілю |
| `seededAt` | timestamp | коли засіяно демо-каталог; не дає йому «воскреснути» |

**`users/{uid}/places/{placeId}`**

| Поле | Тип | Опис |
|---|---|---|
| `name` | string (2–50) | назва |
| `category` | string | `cafe, restaurant, bar, museum, fastFood, hotel, bakery, pub` |
| `subtitle` | string | підпис під назвою (напр. «Museum & Art») |
| `address` | string | текстова адреса |
| `latitude`, `longitude` | number \| null | GPS-координати (null для старих записів) |
| `visitDate` | timestamp | дата візиту; за нею впорядкований список |
| `isFavorite` | bool | чи є в «Вибраному» |
| `cover` | map | мініатюра картки (той самий формат, що елемент `photos`) |
| `review` | map \| null | вкладений відгук: `overallRating, foodRating, serviceRating, atmosphereRating, textNote, tags[], updatedAt` |
| `photos` | array of map (≤ 5) | `kind` (`asset`/`remote`), `url`, `storagePath`, `sizeBytes`, `contentType`, `uploadedAt` |
| `createdAt` | timestamp | час створення (серверний) |
| `updatedAt` | timestamp | час останньої зміни (серверний) |

**Чому `review` вкладений, а `photos` — масив, а не підколекції.** Відгук 1:1 із закладом і завжди читається разом із ним; масив із ≤ 5 елементів вміщується в один документ, тож список і Details отримують усе одним читанням (дешевше за кілька запитів), а ліміти малі. Об'єкти ЛР №2 `User`, `Place`, `Review`, `PlacePhoto` відображені так: `User` → `users/{uid}`, `Place` → документ закладу, `Review` і `PlacePhoto` → вкладені в нього.

**Файли в Supabase:** `place-photos/users/<uid>/<placeId>/<uuid>.<ext>`; у Firestore лише метадані та публічний URL.

## 7. Правила доступу (завдання 4)

Файл `firestore.rules`: лише автентифікований **власник** читає й пише `users/{uid}/**` (`request.auth.uid == uid`); запис закладу валідується (обов'язкові поля, `name` 2–50 символів, `category` зі списку, типи координат, `photos.size() <= 5`); решта закрита.

**Відступ від прикладу методички.** Методичка наводить правила «публікацію створює автор, дивляться всі». PlacesCatalog — **особистий щоденник**, тож дані приватні: «дивитись усі» тут було б витоком особистих нотаток і геолокації. Рішення зафіксовано в `decisions.md`.

## 8. Архітектура

```
Екран ── подія ──▶ Bloc ──▶ Repository (interface) ──▶ Firestore / Supabase / файл / пам'ять
   ▲                 │
   └───── стан ◀─────┘     PlacesBloc підписаний на watchPlaces → список оновлюється сам
```

- **Збереження закладу:** `PlaceFormScreen` → `CreatePlaceBloc` / `UpdatePlaceBloc` → `PhotoUploadSession` (фото в Storage по одному, відкат при помилці) → `PlacesRepository.savePlace` (документ у Firestore). Список оновлює потік `watchPlaces`.
- **Фото різного походження** — `PlacePhoto` (`asset` / `local` / `remote`), один віджет показу `PlaceImageView`.
- **Офлайн-запис:** `Future` запису Firestore завершується лише після підтвердження сервера, тому `savePlace` чекає 4 с і трактує таймаут як «збережено локально» (SDK доставить запис сам).
- **Мапа:** `LocationPickerCubit` (пошук за сабмітом, debounce, відкидання застарілих відповідей, «моя геолокація») + `NominatimGeocodingRepository` (адреси) + `OverpassVenuesRepository` (заклади навколо й за назвою) + `GeolocatorLocationService`.
- **DI:** `MultiRepositoryProvider` у `main.dart` (`PlacesRepository`, `MediaRepository`, `GeocodingRepository`, `MapLauncher`, `PhotoPickerService`, `UserProfileRepository`, …); `UserScope` створює по користувачу `PlacesBloc`, `CreatePlaceBloc`, `UpdatePlaceBloc`, `CatalogViewCubit`, `ProfileBloc`.

## 9. Режими запуску

| Режим | Команда |
|---|---|
| Повний (Firestore + Supabase) | `flutter run --dart-define-from-file=env/supabase.json` |
| Без ключів Supabase | `flutter run` — фото дадуть «Cloud storage is not configured.» |
| Каталог у JSON-файлі (ЛР №5) | `--dart-define=PLACES_BACKEND=local` |
| Скриншоти без мережі | `--dart-define=FAKE_AUTH=signed_in` (+ `DEMO_FORM=true`, `FAKE_LOAD_DELAY_MS`, `FAKE_LOAD_FAIL`) |

## 10. Що перевірено, а що ні

**Автоматично (297 тестів, без мережі):** серіалізація моделі туди-назад (всі три види фото, null-координати), репозиторій на in-memory сховищі (засів один раз, порядок, пагінація, типізовані помилки, таймаут запису, пошкоджений документ), `CreatePlaceBloc`/`UpdatePlaceBloc` (успіх, відкат, помилки Storage і БД, повторне натискання, нове/видалене/незмінене фото), `PlacesBloc` на потоці, `LocationPickerCubit` (пошук, reverse, debounce, застаріла відповідь, помилка мережі), Nominatim на підміненому HTTP-адаптері `dio`, вибір фото (ліміт 5, скасування, заборонений доступ, немає камери), екрани мапи, відсутність overflow.

**Не перевірено (потрібні твої консолі та ключі):**
- реальний обмін із Firestore і Supabase (запис, правила, `permission-denied`);
- реальні тайли OpenStreetMap у збірці (скриншоти зі звичайної збірки — `screenshots/`);
- справжня галерея й камера на пристрої; Android-збірка;
- поведінка без мережі на реальному пристрої.

Чекліст ручної перевірки — `manual_steps.md`, розділ 5.

## 11. Файли в цій папці

| Файл | Призначення |
|---|---|
| `README.md` | цей огляд (таблиця FR, схема, rules, архітектура) |
| `code_examples.md` | код для звіту (згенеровано з актуальних джерел) |
| `firestore.rules` | копія правил |
| `supabase_setup.md` | SQL і кроки налаштування Supabase, чесні обмеження безпеки |
| `manual_steps.md` | що виконати вручну |
| `screenshots_todo.md` | які скриншоти знімаєш ти |
| `screenshots/`, `screenshots/captions.md` | скриншоти екранів і підписи |
| `structure_final.txt` | дерево `lib/` і `test/` |
