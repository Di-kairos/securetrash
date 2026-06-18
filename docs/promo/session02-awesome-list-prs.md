# Awesome-list PR kit — securetrash

> ⚠️ **НЕ слать сейчас.** Репо на момент подготовки: **0 звёзд, создан 2026-06-17**.
> `agarrharr/awesome-cli-apps` жёстко требует **>20 звёзд**, остальные неформально ждут
> traction. PR на day-1/0★ = авто-реджект + риск пометки как self-promo спам.
>
> **Когда слать:** после раскрутки (#2 посты), когда репо набрал звёзды (для cli-apps —
> строго >20). И **после** того как поднят GitHub Pages (#6) → выставить `homepage` репо
> (`gh repo edit Di-kairos/securetrash --homepage <url>`), чтобы ссылка в PR вела на лендинг.
>
> Все PR'ы — внешние репозитории, постит **Mr. Di сам** (fork → branch → PR), не Claude.

---

## 1. agarrharr/awesome-cli-apps  ✅ хороший фит

- **Гейт:** репо должно иметь **>20 звёзд** (правило из `contributing.md`). Не раньше.
- **Файл/секция:** `readme.md` → `### Deleting, Copying, and Renaming`
- **Формат:** `- [name](url) - Description.` (с заглавной, точка в конце)
- **Готовая строка** (вставить в конец секции):

```
- [securetrash](https://github.com/Di-kairos/securetrash) - Honest secure deletion with an encrypted crypto-shred vault instead of fake SSD overwrite.
```

---

## 2. jaywcjlove/awesome-mac  ✅ хороший фит

- **Файл/секция:** `README.md` → `## Encryption` (сейчас там Cryptomator, Deadbolt)
- **Формат:** с бейджами; вставить по алфавиту (после Deadbolt):

```
* [securetrash](https://github.com/Di-kairos/securetrash) - Honest secure-delete CLI: FileVault + AES-256 crypto-shred vault, no SSD overwrite snake oil. [![Open-Source Software][OSS Icon]](https://github.com/Di-kairos/securetrash) ![Freeware][Freeware Icon]
```

- Бейдж-лейблы `OSS Icon` / `Freeware Icon` уже определены в этом README — менять не нужно.
- Список крупный и модерируется строго: лучше слать с ненулевыми звёздами.

---

## 3. pluja/awesome-privacy  ✅ средний фит

- **Файл/секция:** `README.md` → `## Encryption` (рядом Veracrypt, Picocrypt, Cryptomator)
- **Формат:** `- [name](url) - Description`
- **Готовая строка:**

```
- [securetrash](https://github.com/Di-kairos/securetrash) - Honest secure file deletion for macOS: AES-256 crypto-shred vaults instead of unreliable SSD overwriting.
```

- Репо использует обычный README (без structured-data) → PR правит README напрямую.
- Фокус списка — privacy-сервисы; CLI-утилита проходит, но без явного star-гейта;
  слать после минимальной traction.

---

## 4. sbilly/awesome-security  ⛔ ПРОПУСТИТЬ

- В списке нет категории под secure-delete / data-sanitization / anti-forensics.
  Разделы: Network (scan/IDS/honeypot/sniffer/VPN/firewall…), Endpoint (AV, CDR, auth,
  mobile, **Forensics**), Web, Exploits, Datastores и т.п.
- Единственный близкий — `Endpoint > Forensics`, но это *forensics*, противоположное по
  смыслу (securetrash — анти-форензика). Натягивать = реджект.
- **Рекомендация:** не слать. Если очень хочется security-список — искать нишевый
  `awesome-anti-forensics` / `awesome-privacy-tools`, а не общий awesome-security.

---

## Чеклист перед отправкой (для Mr. Di)

1. [ ] Репо набрал звёзды (cli-apps: строго **>20**).
2. [ ] Поднят GitHub Pages (#6) и выставлен `homepage` репо.
3. [ ] Прочитать актуальный CONTRIBUTING каждого списка (правила меняются).
4. [ ] Один PR = один список, осмысленный заголовок (`Add securetrash`), без массовой рассылки.
5. [ ] Описание совпадает по стилю с соседними строками секции.
