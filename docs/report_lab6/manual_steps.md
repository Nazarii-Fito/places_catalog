# Що треба зробити вручну (ЛР №6)

Код, тести й матеріали готові. Нижче — те, чого я зробити не міг: потрібні твої акаунти й консолі. Виконуй по порядку.

## 1. Firebase Console → Cloud Firestore → створити базу

1. Відкрий https://console.firebase.google.com/project/placescatalog-7730/firestore
2. **Build → Firestore Database → Create database**.
3. **Edition:** Standard. **Database ID:** `(default)`.
4. **Location:** обери регіон, **змінити його потім не можна**. Для користувача зі Львова зручні `europe-central2` (Варшава) або мультирегіон `eur3`.
5. **Secure rules:** обери **Start in production mode** (усе закрито), правила ми одразу замінимо на свої.
6. **Create**.

## 2. Опублікувати правила (`firestore.rules`)

**Варіант А (CLI, рекомендовано).** У корені репозиторію:

```sh
firebase deploy --only firestore:rules --project placescatalog-7730
```

Очікуваний результат: `✔ cloud.firestore: released rules firestore.rules to cloud.firestore`.

**Варіант Б (консоль).** **Firestore Database → вкладка Rules** → встав вміст файла `firestore.rules` (або `docs/report_lab6/firestore.rules`) → **Publish**.

> Правила вже перевірено на компіляцію (`firebase deploy --only firestore:rules --dry-run` → «rules file firestore.rules compiled successfully»), але **реальний деплой не виконано**: бази ще не було.

## 3. Supabase

Дивись `supabase_setup.md`: реєстрація, проєкт, SQL (bucket + політики), де взяти URL і ключ. Потім:

```sh
cp env/supabase.example.json env/supabase.json
# відкрий env/supabase.json і встав свої SUPABASE_URL та SUPABASE_ANON_KEY
```

Без цього файла застосунок працює, але додавання фото дасть повідомлення «Cloud storage is not configured.»

## 4. Запуск

> **Ключі Supabase підхоплюються автоматично.** Якщо є файл `env/supabase.json`, він вбудовується в локальну збірку (каталог `env/` оголошено в `pubspec.yaml`), тож хмарні фото працюють при **будь-якому** локальному запуску: з IDE, з Xcode, через `flutter run` і з іконки на симуляторі/телефоні. Прапорець `--dart-define-from-file` більше не обов'язковий (але має пріоритет). Після створення чи зміни `env/supabase.json` зроби повну перезбірку (не hot reload). У debug-консолі при старті видно рядок `Cloud storage: configured` або `NOT configured`.

- **VS Code:** Run and Debug → «PlacesCatalog (Firestore + Supabase)» (бере `env/supabase.json`).
- **Термінал:**
  ```sh
  flutter run --dart-define-from-file=env/supabase.json
  ```
- Без хмари (каталог у JSON-файлі, як у ЛР №5): `--dart-define=PLACES_BACKEND=local`.
- Без мережі взагалі (скриншоти): `--dart-define=FAKE_AUTH=signed_in` (+ `DEMO_FORM=true`).

Увійди справжнім акаунтом (e-mail/Google/Apple): Firestore і Storage потребують автентифікації.

## 5. Сценарії перевірки

1. **Засів.** Перший вхід нового акаунта: у Firestore з'являються `users/{uid}` (із `seededAt`) і 5 закладів у `users/{uid}/places`. Видали всі заклади в застосунку й перезапусти: демо-дані **не** повертаються.
2. **Створення з фото.** «+» → назва, локація на мапі, 2 фото з галереї → Save. Під час збереження кнопка крутиться й видно «Uploading photo 1 of 2…». Після успіху: у Firestore документ має масив `photos` з `url`/`storagePath`/`sizeBytes`/`contentType`/`uploadedAt`; у Supabase **Storage → place-photos → users/<uid>/<placeId>/** лежать 2 файли.
3. **Редагування фото.** Відкрий заклад → олівець → додай одне фото, зніми одне хрестиком → Save. Нове з'явилось у Storage, знятого там більше немає, незмінені не перезавантажувались.
4. **Видалення.** Delete Place → заклад зникає, файли в Storage теж.
5. **Ізоляція.** Вийди й увійди другим акаунтом: бачиш лише його каталог (перший акаунт — не бачиш; перевір і Rules → Playground).
6. **Після перезапуску й на іншому пристрої** під тим самим акаунтом фото та каталог на місці.
7. **Авіарежим:**
   - список читається з кешу;
   - створення/редагування **без** нових фото ставиться в чергу (форма закривається; після повернення мережі запис з'являється в консолі);
   - створення **з** фото дає «No connection…» з кнопкою **Retry**, дані форми не втрачаються;
   - вибір локації без мережі: мапа без тайлів, у картці координати, `Confirm` усе одно працює.
8. **Заклади на мапі й «моя геолокація»:** у виборі локації на мапі з'являються круглі маркери закладів (кав'ярні, ресторани, бари…) від zoom 15; тап по маркеру вибирає заклад (картка показує його назву й адресу), а у формі підставляється назва (якщо поле порожнє) й категорія. Пошук за назвою («copernicus», «starbucks») знаходить заклади поряд із центром мапи. Кнопка зі стрілкою під пошуком центрує мапу на тобі (при першому натисканні iOS питає дозвіл на геолокацію). **На симуляторі:** Features → Location → Custom Location… (або `xcrun simctl location booted set 49.8419,24.0315`). Заклади беруться з публічних серверів Overpass, які іноді «at capacity»: тоді маркери просто не з'являться; рух мапи повторить запит.
9. **Аватар з пристрою:** Profile → олівець → «Upload from Device» → бібліотека або камера → Save. У Supabase з'являється `users/<uid>/avatar/<uuid>.jpg`, у Firebase Auth оновлюється `photoURL`, у Firestore — `users/{uid}.photoUrl`. Заміна фото видаляє попередній файл із Storage (лише наш), пресет DiceBear не чіпається.
10. **Мапа:** вибір локації (пошук за адресою, перетягування мапи, пін піднімається, адреса оновлюється через ~0,7 с після зупинки); на Details міні-мапа, тап по ній і «Open in Apple Maps» відкривають зовнішні Карти.

## 6. iPhone-симулятор і Samsung Galaxy S23

- **Симулятор iOS.** Галерея порожня: перетягни фото з Finder на вікно симулятора (потрапляють у Photos). Камера на симуляторі недоступна: це очікувано, застосунок покаже «The camera is not available on this device.»
- **Samsung S23 (Android).** Потрібні Android SDK та SHA-1: `cd android && ./gradlew signingReport` → додай SHA-1 у Firebase Project settings → Android app → перезавантаж `google-services.json` (`flutterfire configure`). Камера й галерея працюють на реальному пристрої; дозволи додатково не потрібні (системний Photo Picker, камера через intent).
- **Якщо тайли мапи не вантажаться:** перевір інтернет; тайли йдуть з `tile.openstreetmap.org` (https). У режимі `FAKE_AUTH` і в тестах тайлів немає навмисно, мапа — сірий фон.

## 7. Скриншоти для звіту

Список — `screenshots_todo.md`.

## Що я свідомо НЕ робив

- Не створював базу Firestore і не розгортав rules: твій вибір (ти створюєш у консолі).
- Не створював проєкт Supabase й не використовував ваші ключі.
- Не пушив у GitHub: усе лише в локальних комітах (`git log --oneline`). Запушити: `git push origin main`.
