# Скриншоти для звіту ЛР №5 (чернетка після Фази 1)

Повний список буде доповнено у Фазі 5 (loading / error / empty). Усі команди виконуються з кореня репозиторію; симулятор — iPhone 17.

Спільна команда (змінюються лише `INITIAL_ROUTE` і `INITIAL_TAB`):

```sh
flutter build ios --simulator --debug \
  --dart-define=FAKE_AUTH=signed_in --dart-define=DEMO_FORM=true \
  --dart-define=INITIAL_ROUTE=<маршрут> --dart-define=INITIAL_TAB=<0|1|2>
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch booted ua.lpnu.pz33.placesCatalog
xcrun simctl io booted screenshot <файл>.png
```

| № | Що показати | INITIAL_ROUTE | INITIAL_TAB |
|---|---|---|---|
| 1 | Вкладка Home (список на slivers) | `/home` | 0 |
| 2 | Вкладка Favorites | `/home` | 1 |
| 3 | Вкладка Profile | `/home` | 2 |
| 4 | Place Details (з олівцем Edit у шапці) | `/place-details` | 0 |
| 5 | Add Place (порожня форма без `DEMO_FORM`; з демо-даними — з ним) | `/add-place` | 0 |
| 6 | Edit Place (форма з даними закладу) — відкрити олівцем на Details | вручну | — |
| 7 | Помилки валідації форми (натиснути Save на порожній формі) — вручну | `/add-place` (без `DEMO_FORM`) | — |
| 8 | Структура пакетів з IDE: розгорнути `lib/` і `test/` (завдання 5 методички); текстова версія — `structure_after_task1.txt` | — | — |
