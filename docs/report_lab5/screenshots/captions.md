# Підписи до скриншотів ЛР №5

Усі кадри — iPhone 17, режим `FAKE_AUTH=signed_in` (каталог у пам'яті, демо-дані).

- **Рис. 1.** Вкладка Home: каталог на `CustomScrollView` (заголовок, пошук і чипи — `SliverToBoxAdapter`, картки — `SliverList.separated`).
- **Рис. 2.** Вкладка Favorites: ті самі дані, відфільтровані за `isFavorite`; лічильники категорій у чипах.
- **Рис. 3.** Вкладка Profile: статистика (Total Visited, Cafes, Dining, Museums, Favorites) обчислюється з каталогу в `PlacesBloc`.
- **Рис. 4.** Place Details; олівець у шапці — вхід до редагування закладу.
- **Рис. 5.** Add Place: порожня форма, у полях підказки (`hint`), оцінки за замовчуванням 3 зірки.
- **Рис. 6.** Add Place: після спроби зберегти порожню форму — помилки валідації `Form` («This field is required.», «Choose a location.»).
- **Рис. 7.** Add Place, заповнена демо-даними з Figma (параметр `DEMO_FORM=true`, лише для скриншотів).
- **Рис. 8.** Edit Place: та сама форма з даними вибраного закладу, заголовок «Edit Place».
- **Рис. 9.** Home: стан завантаження (`PlacesStatus.loading`, `CupertinoActivityIndicator`).
- **Рис. 10.** Home: помилка завантаження (`PlacesStatus.failure`) з кнопкою Retry.
- **Рис. 11.** Home: порожній результат пошуку (`EmptyState`); пошуковий запит зберігається лише в пам'яті.
- **Рис. 12.** Home: меню сортування; вибраний варіант зберігається в `SharedPreferences` і відновлюється при запуску.
