# Скриншоти для звіту ЛР №5

Готові скриншоти лежать у `screenshots/` (Рис. 1–12, iPhone 17, режим `FAKE_AUTH`); підписи — `screenshots/captions.md`. Нижче — як їх відтворити і що автор має зробити сам.

## Команди

Усі команди — з кореня репозиторію, симулятор iPhone 17 (UDID дивись у `xcrun simctl list devices`).

```sh
flutter build ios --simulator --debug \
  --dart-define=FAKE_AUTH=signed_in \
  --dart-define=INITIAL_ROUTE=<маршрут> --dart-define=INITIAL_TAB=<0|1|2> \
  [--dart-define=DEMO_FORM=true] [--dart-define=FAKE_LOAD_DELAY_MS=600000] [--dart-define=FAKE_LOAD_FAIL=true]
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch booted ua.lpnu.pz33.placesCatalog
xcrun simctl io booted screenshot <файл>.png
```

| Рис. | Що показати | INITIAL_ROUTE | INITIAL_TAB | Додаткові define |
|---|---|---|---|---|
| 1 | Home (список на слівер-ах) | `/home` | 0 | — |
| 2 | Favorites | `/home` | 1 | — |
| 3 | Profile (статистика з каталогу) | `/home` | 2 | — |
| 4 | Place Details (олівець Edit у шапці) | `/place-details` | 0 | — |
| 5 | Add Place — порожня форма з підказками | `/add-place` | 0 | — |
| 6 | Add Place — помилки валідації після «Save Place Record» на порожній формі | `/add-place` | 0 | натиснути Save вручну |
| 7 | Add Place — заповнена демо-даними | `/add-place` | 0 | `DEMO_FORM=true` |
| 8 | Edit Place (форма з даними закладу) | `/place-details` | 0 | натиснути олівець у шапці |
| 9 | Home: завантаження | `/home` | 0 | `FAKE_LOAD_DELAY_MS=600000` |
| 10 | Home: помилка завантаження + Retry | `/home` | 0 | `FAKE_LOAD_FAIL=true` |
| 11 | Home: порожній результат пошуку | `/home` | 0 | ввести `zzz` у пошук |
| 12 | Home: меню сортування | `/home` | 0 | натиснути «Sorted by Recent» |

## Що робить автор вручну

1. **Структура пакетів з IDE (завдання 5, двічі).** Розгорнути `lib/` і `test/` у Explorer. Після завдання 1 — на коміті `5e54bbd` (`git checkout 5e54bbd`, зняти скриншот, повернутись `git checkout main`); наприкінці — на актуальному `main`. Текстові версії — `structure_after_task1.txt`, `structure_final.txt`.
2. **Збереження між запусками (реальний режим, без `FAKE_AUTH`).** Увійти справжнім акаунтом → додати заклад → повністю закрити застосунок → відкрити: заклад на місці. Зняти «до» і «після» (сценарій 2 чекліста з `README.md`).
3. **Видалення й редагування в реальному режимі** — Place Details → Delete / олівець → зміна видна на Home і Favorites (сценарії 3–4).
4. **Зміна акаунта** — Log Out → увійти іншим акаунтом → інший каталог (сценарій 7).
5. **Пошкоджений файл** (необов'язково): у симуляторі файл лежить у `Documents` застосунку (`xcrun simctl get_app_container booted ua.lpnu.pz33.placesCatalog data`), підмінити вміст `places_<uid>.json` на `{ not json`, запустити — каталог відновлюється; у Crashlytics з'явиться non-fatal «Damaged places file».
6. Запуск на Samsung S23 (Android): потрібні Android SDK, SHA-1 і повторний `flutterfire configure` (див. `docs/report_lab4/README.md` §6).
