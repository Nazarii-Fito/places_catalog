# Налаштування Supabase Storage (завдання 8, варіант 8.b методички)

Supabase використовується **лише як файлове сховище** для фото закладів. Автентифікація лишається в Firebase, база даних — Cloud Firestore. Файли лежать у Supabase, а в Firestore (у документі закладу) зберігаються метадані й публічні URL (відповідь на контрольне питання 29).

## Кроки

1. Зареєструватися на https://supabase.com і натиснути **New project**: назва `placescatalog`, регіон найближчий до тебе (наприклад, Frankfurt), пароль до БД — довільний (у застосунку не потрібен).
2. Зачекати кінця створення проєкту (1–2 хв).
3. Відкрити **SQL Editor → New query**, вставити SQL нижче й натиснути **Run**.
4. Знайти ключі: **Project Settings → API** (на нових проєктах: **Project Settings → API Keys**). Потрібні:
   - **Project URL** (`https://xxxx.supabase.co`);
   - **публічний ключ**: «Publishable key» (`sb_publishable_…`) або, на старих проєктах, «anon public».
5. Покласти їх у файл `env/supabase.json` (за прикладом `env/supabase.example.json`). Файл у `.gitignore`, у репозиторій не потрапляє.
6. Запустити застосунок: ключі з `env/supabase.json` вбудовуються в локальну збірку автоматично (можна й явно: `--dart-define-from-file=env/supabase.json`, у VS Code — конфігурація «PlacesCatalog (Firestore + Supabase)»). Після зміни файла потрібна повна перезбірка, не hot reload.

## SQL: bucket і політики

```sql
-- 1) Публічний bucket для фото закладів: до 5 МБ, лише jpeg/png/webp.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'place-photos',
  'place-photos',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 2) Політики на storage.objects для ролі anon (ключ застосунку).
--    Читання публічного bucket за URL працює й без політики select,
--    але вона потрібна для list/remove у деяких сценаріях.
create policy "place-photos: anon can read"
  on storage.objects for select to anon
  using (bucket_id = 'place-photos');

create policy "place-photos: anon can upload"
  on storage.objects for insert to anon
  with check (bucket_id = 'place-photos');

create policy "place-photos: anon can delete"
  on storage.objects for delete to anon
  using (bucket_id = 'place-photos');
```

Перевірка: **Storage → place-photos → Policies** має показати три політики; у **Storage → Buckets** bucket позначений як *Public*.

## Структура об'єктів

`users/<uid>/<placeId>/<uuid>.<ext>` — наприклад, `users/Zk3…/8fQ…/6c1b….jpg`. Файл ніколи не лежить у корені bucket; унікальне ім'я не дає двом завантаженням перезаписати одне одного.

## Чесно про безпеку (відповідь на питання викладача)

Методичка допускає публічний bucket без автентифікації «для навчальних цілей», так і зроблено. Політики відкриті для ролі `anon`, тому **будь-хто, хто має ключ застосунку, технічно може завантажити чи видалити файл у цьому bucket** (ключ міститься в збірці). Захист лише на рівні bucket: розмір ≤ 5 МБ, лише зображення, а шлях містить `uid`. Для продакшену потрібно одне з:

- інтеграція Supabase з Firebase JWT (Third-party auth) і Row-Level Security за `auth.uid()` у політиках (`(storage.foldername(name))[2] = auth.uid()::text`);
- або перехід на Firebase Storage з Security Rules (`request.auth.uid == uid`).

Приватність метаданих гарантують правила Firestore (див. `firestore.rules`): лише власник читає документ закладу, а отже й знає URL його фото. Самі URL публічні й важко вгадувані (UUID), але не секретні.
