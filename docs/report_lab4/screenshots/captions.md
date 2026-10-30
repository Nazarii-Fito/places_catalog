# Підписи до скриншотів (ЛР №4)

Усі кадри зроблено на iOS Simulator (iPhone 17) у режимі `FAKE_AUTH`: екрани працюють на тестовій заміні `AuthRepository`, щоб стабільно відтворити стани (помилка сервера, довге завантаження, `requires-recent-login`). Реальні відповіді Firebase показано окремо скриншотами консолі зі списку `console_screens_todo.md`.

| Файл | Підпис |
|---|---|
| 01_login.png | Рис. 1. Екран входу: email, пароль, «Forgot Password?», вхід через Apple та Google. |
| 02_register_validation.png | Рис. 2. Реєстрація: після спроби відправити порожню форму під кожним полем з'являються помилки валідації (`Form` + `GlobalKey`), запит не надсилається. |
| 03_login_error.png | Рис. 3. Помилка входу від Firebase (`invalid-credential`) показана зрозумілим банером над кнопкою, без сирого коду помилки. |
| 04_login_loading.png | Рис. 4. Стан завантаження: кнопка показує індикатор, поля лише для читання, повторне натискання не надсилає другий запит. |
| 05_forgot_sent.png | Рис. 5. Відновлення пароля: нейтральне повідомлення «Check your email» (у проєкті ввімкнено email enumeration protection). |
| 06_apple_sheet.png | Рис. 6. Системне вікно «Sign in with Apple» після натискання кнопки Apple (знімається вручну на симуляторі/пристрої). |
| 07_home_signed_in.png | Рис. 7. Відновлення сеансу: залогінений користувач одразу потрапляє на головний екран (`AuthGate` + `authStateChanges()`). |
| 08_profile.png | Рис. 8. Профіль: ім'я та email беруться з Firebase-користувача (`userChanges()`). |
| 09_profile_connected.png | Рис. 9. «Connected Accounts»: Email & Password — Linked, Google — можна під'єднати («Link»). |
| 10_profile_linked.png | Рис. 10. Після прив'язки Google обидва способи входу позначені Linked — один акаунт, два провайдери. |
| 11_change_validation.png | Рис. 11. Зміна пароля: нове має відрізнятися від поточного, підтвердження має збігатися. |
| 12_change_wrong_current.png | Рис. 12. Хибний поточний пароль під час повторної автентифікації показано помилкою біля поля. |
| 13_change_recent_login.png | Рис. 13. Помилка `requires-recent-login`: діалог пропонує увійти знову. |
| 14_edit_preset.png | Рис. 14. Редагування профілю: вибір готового аватара (8 пресетів), у шапці видно попередній перегляд. |
| 15_edit_custom_url.png | Рис. 15. Власне фото за HTTPS-посиланням з попереднім переглядом. |
| 16_edit_custom_url_bad.png | Рис. 16. Посилання без https відхиляється валідатором. |
| 17_edit_custom_url_broken.png | Рис. 17. Посилання на недоступне зображення: прев'ю показує «Couldn't load this image.» замість краху. |
| 18_dev_menu.png | Рис. 18. Меню розробника (довге натискання на «PlacesCatalog · Version 1.0», лише в debug/profile): тестова non-fatal помилка і тестовий краш для Crashlytics. |

## Скриншоти зі справжнім Firebase (папка `live/`)

Знято на iOS Simulator (iPhone 17) у збірці без fake-режиму: запити йдуть у проєкт `placescatalog-7730`, користувач — тестовий акаунт `lab4.tester@example.com` (домен `example.com` зарезервований, листи нікому не надсилаються). Їх можна використати замість або разом із fake-кадрами, коли в звіті потрібне підтвердження реальної роботи.

| Файл | Підпис |
|---|---|
| live/L01_real_wrong_login.png | Рис. 19. Реальна відповідь Firebase на вхід із неіснуючим акаунтом: зрозуміле повідомлення «Incorrect email or password» без сирого коду помилки. |
| live/L02_real_register_home.png | Рис. 20. Після реєстрації через Firebase Auth користувач одразу потрапляє на головний екран (`AuthGate`). |
| live/L03_real_session_restored_profile.png | Рис. 21. Відновлення сеансу після перезапуску застосунку: профіль показує ім'я та email з Firebase, «Email & Password — Linked». |
| live/L04_real_change_wrong_current.png | Рис. 22. Зміна пароля: хибний поточний пароль (повторна автентифікація) відхилено, помилка біля поля. |
| live/L05_real_forgot_sent.png | Рис. 23. Реальне надсилання листа для скидання пароля: нейтральний екран «Check your email». |
| live/L06_real_edit_profile_saved.png | Рис. 24. Edit Profile: вибрано готовий аватар, збереження в Firebase (`updatePhotoURL`) підтверджено діалогом «Profile Updated». |
| live/L07_real_profile_new_avatar.png | Рис. 25. Профіль після збереження: аватар узято з посилання, що збережене в акаунті Firebase. |

Примітка. Реальні кадри входу через Google та Apple, Crashlytics і консолі Firebase автор робить вручну (див. `console_screens_todo.md`).
