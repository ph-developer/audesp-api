# audesp_api — AGENTS.md

## Stack

- Flutter desktop app (**Windows only**), Dart SDK `^3.11.4`
- Riverpod (state), GoRouter (routing), Drift (ORM, dual SQLite/Postgres)
- `flutter_lints` with `avoid_print: false`; generated files excluded from analysis

## Entrypoint & routing

- `lib/main.dart` → `AppEnv.load()` then `ProviderScope(child: App())`
- `lib/app.dart`: `MaterialApp.router` with `GoRouter`, locale hardcoded to `pt_BR`
- ShellRoute wraps 5 feature modules: `/edital`, `/licitacao`, `/ata`, `/ajuste`, `/logs`
- Auth guard: unauthenticated → `/login`; `user.id == -1` → admin; non-admin → blocked from `/admin`

## Module structure (feature-first)

```
lib/
  core/          database/, services/, constants/, theme/, utils/
  features/      admin/, ajuste/, ata/, auth/, edital/, licitacao/, logs/, shell/
  shared/        widgets/
```

Each feature typically: `pages/`, `services/`, `widgets/`, plus optional `csv/`, `domain/`.

## Database & codegen

- Drift schema: `lib/core/database/tables.dart` → `app_database.dart` → generated `app_database.g.dart`
- Dual driver: reads `config.ini` (`[Database] Driver=sqlite|postgres`) at app directory (release = exe dir, debug = CWD)
- Default SQLite path: `C:\audesp\dados\audesp_db.sqlite` (configurable in `config.ini`)
- DAOs in `lib/core/database/daos/` — one per table, injected via Riverpod
- After editing tables, regenerated data, or freezed models: `dart run build_runner build --delete-conflicting-outputs`

## Environment & secrets

- `assets/.env`: loaded by `AppEnv.load()` before `runApp`
  - `ADMIN_PASSWORD` (default: `admin@1234`), `DEFAULT_USER_PASSWORD` (default: `Mudar@1234`)
- `config.ini`: DB configuration (example at repo root, runtime version next to executable)
- `flutter_secure_storage` (DPAPI on Windows) holds AUDESP bearer token — **not** user passwords
- User passwords: SHA-256 hash stored in `Users.passwordHash` column

## AUDESP API

- Two environments: `Piloto` (`https://audesp-piloto.tce.sp.gov.br`) and `Oficial` (`https://audesp.tce.sp.gov.br`)
- API spec: `docs/audesp.yaml` (OpenAPI 3.0)
- Dio HTTP client with Bearer token interceptor via `AuthService`
- `ApiLogs` table records every API call

## Testing

- 4 test files, all CSV parser tests: `test/features/edital/csv/`, `test/features/licitacao/csv/`
- **No widget/integration tests**
- Run: `flutter test`
- Run single file: `flutter test test/features/edital/csv/edital_csv_parser_test.dart`
- Brazilian number format parser tested with `closeTo(..., 0.001)` matchers

## Key domain quirks

- `lib/features/edital/domain/edital_domain.dart` — large AUDESP schema enums (modalidades, amparos legais, etc.)
- CSV parsers detect encoding (UTF-8, UTF-8 BOM, Latin-1), ignore `#` comment lines, normalize `unidadeMedida` to uppercase, parse PT-BR number format (`1.200,50`)
- Edital CSV: `ValorUnitarioMenor` maps to `valorUnitarioEstimado`; `ValorEstimadoMedia` (Licitação col) is ignored
- `EditalCsvParseException` thrown on missing columns, invalid values, empty input
