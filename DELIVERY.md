# Передача приложения — GonzoRevol Block Tap

По инструкции «Инструкция для разработчиков-2.md».

## Текст для отправки заказчику

Скопируйте блок ниже в чат / почту:

```
GonzoRevol Block Tap
com.gonzorevol.blocktap
v 1.0

дизайн
https://www.figma.com/design/gRe2wyq0qbTugt8txAAxLp/GonzoRevol-Block-Tap?node-id=0-1

Product ID              Price   Pack name       Coins    Free Spins   Bonus
gonzotokrevo_1500       $2.99   Starter Pack    1,500    3            +10% on every win for 3 days
gonzotokrevo_4500       $5.99   Premium Pack    4,500    6            +15% on every win for 7 days
gonzotokrevo_10000      $9.99   VIP Pack        10,000   10           +25% on every win for 7 days + Priority Withdrawal

AppMetrica:
com.gonzorevol.blocktap
8d12d2cc-5f4e-43dc-8909-7e2ad95ad293

Реклама start.io:
206450178

Terms of Use:
https://telegra.ph/Terms-of-Use-07-02-8

Privacy Policy:
https://telegra.ph/Privacy-Policy-07-02-132

Версия: v 1.0
Что сделано: первый релиз — дизайн по Figma, игровая логика, магазин, колесо, вывод, rewarded-реклама, AppMetrica.
```

## Файлы для передачи

| Файл | Описание |
|---|---|
| `release/com.gonzorevol.blocktap.apk` | Тестовая установка |
| `release/com.gonzorevol.blocktap.aab` | Загрузка в Google Play |
| `release/com.gonzorevol.blocktap.jks` | Keystore подписи |
| `release/com.gonzorevol.blocktap.zip` | Архив исходников проекта |
| Ссылка на **открытый GitLab** | Исходный код |

> Все файлы именуются по package name: `com.gonzorevol.blocktap.*`

## Keystore (подпись release)

| Параметр | Значение |
|---|---|
| Файл | `android/com.gonzorevol.blocktap.jks` |
| Alias | `gonzorevol` |
| Store password | `GonzoRevol2026!` |
| Key password | `GonzoRevol2026!` |

> Передайте `.jks` и пароли заказчику **отдельным защищённым каналом**.  
> `android/key.properties` в git не коммитится (см. `android/.gitignore`).

## Локальная сборка delivery-пакета

```bash
chmod +x scripts/build_release.sh
./scripts/build_release.sh
```

После выполнения в папке `release/` будут все 4 файла для отправки.

## GitLab CI (release APK/AAB на сервере)

1. Залейте проект в **открытый** GitLab-репозиторий.
2. В **Settings → CI/CD → Variables** добавьте:
   - `KEYSTORE_BASE64` — `base64 -i android/com.gonzorevol.blocktap.jks | pbcopy`
   - `KEYSTORE_PASSWORD` = `GonzoRevol2026!`
   - `KEY_PASSWORD` = `GonzoRevol2026!`
   - `KEY_ALIAS` = `gonzorevol`
3. Запустите pipeline (manual или push в main / tag).
4. Скачайте артефакты `com.gonzorevol.blocktap.apk` и `.aab`.

## Чеклист перед отправкой

- [ ] Собраны `release/com.gonzorevol.blocktap.apk` и `.aab` в **release** mode с billing permission
- [ ] Keystore `com.gonzorevol.blocktap.jks` передан отдельно
- [ ] Zip исходников `com.gonzorevol.blocktap.zip` приложен
- [ ] Ссылка на **открытый** GitLab репозиторий отправлена
- [ ] Текст с названием, пакетом, версией, Figma, ключами и продуктами отправлен
- [ ] **Google Play Protect** на тестовом телефоне **выключен**
- [ ] Terms / Privacy — актуальные Telegraph-ссылки в приложении

## Ссылки из инструкции

- [Реклама start.io](https://docs.google.com/document/d/139pVhZLwxNGIcBQlBgd5bYklKJqUvBZ0QlxFvEyw5uE/edit?hl=ru&tab=t.imtlnrwv3cff)
- [AppMetrica](https://docs.google.com/document/d/1MHVFAz8A74Ar-x9vlY1DN-m5TAZIYabqyAjhtkOJevQ/edit?hl=ru&tab=t.0#heading=h.whcge5qqrs1s)
- [Шаблон Terms / Privacy](https://docs.google.com/document/d/1pcaT0QReg9XQNX-QEj49P6KCyw44xb3KR9aJMXhbVB8/edit?usp=sharing)
