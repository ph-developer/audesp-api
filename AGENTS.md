# audesp_api

Flutter Windows desktop app for sending data to AUDESP (TCE-SP).

## Prerequisites

- **MySQL 8.0** — `docker compose up -d` provides it (user `audesp`/`audesp`, DB `audesp`)
- **`assets/.env`** — must exist with `ADMIN_PASSWORD` and `DEFAULT_USER_PASSWORD`
- **`config.ini`** (root, tracked in git) — read at runtime for DB connection alongside the executable or CWD

## Commands

```bash
flutter run                        # launch on Windows
flutter test                       # all tests
flutter test test/path/to/file.dart # single test file
flutter analyze                    # lint (uses flutter_lints)
```

`dart run build_runner build --delete-conflicting-outputs` is available but **not currently needed** — models are hand-written with `fromMap`/`toMap`, not freezed.

## Architecture

- **State:** Riverpod (`flutter_riverpod`) — one provider file per feature, DAOs via `Provider`, services via `Provider`
- **Router:** `go_router` with `ShellRoute` + `NavigationRail`. Shell wraps Edital/Licitação/Ata/Ajuste/Logs. Login, Profile, Admin are outside the shell.
- **Pattern per feature:** `providers.dart`, `services/`, `pages/`, `widgets/`, optional `domain/` (domain logic) and `csv/` (import parsers)
- **Auth:** local DB users (SHA-256 + pepper) + virtual admin (id=`-1`, pw from `.env`). AUDESP API token stored in memory only via `AuthService`.
- **Env switching:** Piloto (`https://audesp-piloto.tce.sp.gov.br`) / Oficial (`https://audesp.tce.sp.gov.br`), persisted in `app_settings` table

## Database

- Schema **auto-creates** on first `DatabaseService.initialize()` with versioning via `__schema` table (current: v2)
- Tables: `users`, `editais`, `licitacoes`, `atas`, `ajustes`, `app_settings`, `api_logs`
- Timestamps are **Unix epoch seconds** stored as `BIGINT`
- `documento_json` stored as `LONGTEXT` (raw JSON string)
- `app_settings` is a key-value store (`SettingsKeys` constants in `app_settings_dao.dart`)
- Unique index on `users.email(255)`

## Notable Conventions

- **Admin user:** hardcoded id = `-1` (sentinel), email = `'admin'`, password from `assets/.env`
- **Password hashing:** SHA-256 with email + pepper (`'audesp_api_sys_2026'`), done in `PasswordHasher`
- **Document status:** `'draft'` (editing) vs `'sent'` (submitted to AUDESP)
- **Gemini default model:** hardcoded as `'gemini-3.1-flash-lite'` in `GeminiService`; API key configured via Admin UI → stored in `app_settings`
- **AUDESP API auth:** email:password → POST `/login` → returns `access_token`, attached as `Authorization: Bearer <token>` by Dio interceptor (`ApiService`)
- **CSV parsers** support UTF-8 (with/without BOM) and Latin-1; use `CsvUtils` (`lib/core/utils/csv_utils.dart`)

## Testing

- Only **CSV parser tests** exist (4 files under `test/features/`)
- Use `flutter_test` with inline byte fixtures (`utf8.encode`, `latin1.encode`)
- `CsvParseException` from `csv_utils.dart` is expected in error cases

## Gotchas

- `config.ini` contains real DB credentials and **is tracked in git** — do not commit changes to it unless intentional
- `freezed` / `json_serializable` are declared in `pubspec.yaml` but **no generated files exist** — all models use manual `fromMap`/`toMap`
- On first run the DB schema auto-creates (`__schema` table), but the admin user is **not auto-created** — it's a virtual in-memory user
- `flutter_secure_storage` uses DPAPI on Windows with `useBackwardCompatibility: false`
