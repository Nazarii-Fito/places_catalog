# Скриншоти для звіту ЛР №6

Автоматично знято в `screenshots/` (iPhone 17; підписи — `screenshots/captions.md`). Нижче те, що знімаєш ти: це потребує твоїх консолей і реальних даних.

## Консолі (завдання 3, 4, 8)

| № | Що показати | Де |
|---|---|---|
| 1 | Колекції Firestore: `users` → документ `{uid}` (поля `displayName`, `email`, `createdAt`, `seededAt`) | Firebase Console → Firestore Database → Data |
| 2 | Підколекція `places` з розгорнутим документом закладу (поля `name`, `category`, `address`, `latitude`, `longitude`, `visitDate`, `review`, `photos`, `createdAt`, `updatedAt`) | Firestore → Data → `users/{uid}/places/{id}` |
| 3 | Масив `photos` розгорнутий: `url`, `storagePath`, `sizeBytes`, `contentType`, `uploadedAt` | там само |
| 4 | Вкладка **Rules** з опублікованими правилами | Firestore → Rules |
| 5 | (за бажанням) Rules Playground: читання чужого документа → Denied | Firestore → Rules → Rules playground |
| 6 | Bucket `place-photos` (Public) і файли в `users/<uid>/<placeId>/` | Supabase → Storage → Buckets |
| 7 | Політики bucket (три політики для `anon`) | Supabase → Storage → Policies |
| 8 | SQL Editor із виконаним скриптом (за бажанням) | Supabase → SQL Editor |

## Застосунок на реальних даних

| № | Що показати | Як |
|---|---|---|
| 9 | Форма з вибраними фото (локальні прев'ю) | `flutter run --dart-define-from-file=env/supabase.json`, + → Add Photos → Choose from Library |
| 10 | Прогрес збереження «Uploading photo 1 of 2…» | Save; кадр треба зловити під час завантаження (можна ввімкнути повільну мережу в Network Link Conditioner) |
| 11 | Помилка без мережі з кнопкою Retry | авіарежим → Save із фото |
| 12 | Заклад із мережевими фото на Home і Details (після перезапуску) | після збереження |
| 13 | Place Details з реальною мапою та підписом | відкрити заклад з координатами |
| 14 | Location Picker: результати пошуку списком і картка з адресою | ввести «cafe lviv» і Enter |
| 15 | Зовнішні Карти після тапу по міні-мапі | Details → тап по мапі |

## IDE

16. Структура пакетів: розгорнути `lib/` і `test/` у Explorer (текстова версія — `structure_final.txt`).
