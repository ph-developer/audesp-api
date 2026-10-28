# audesp_api

Flutter Windows desktop app for sending data to AUDESP (TCE-SP).

## Prerequisites

- **MySQL 8.0** — `docker compose up -d` provides it (user `audesp`/`audesp`, DB `audesp`)
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
- **Router:** `go_router` with `ShellRoute` + custom rail (`shell/widgets/app_navigation_rail.dart`); modules, their order and access rules are defined once in `core/navigation/app_modules.dart`. Shell wraps Processos/Estimativa/Edital/Licitação/Ata/Ajuste/Logs. `/processos` is the home for sending profiles; Estimativa-only users start at `/estimativa`. Login, Profile, Admin are outside the shell.
- **Pattern per feature:** `providers.dart`, `services/`, `pages/`, `widgets/`, optional `domain/` (domain logic) and `csv/` (import parsers)
- **Auth:** local DB users (SHA-256 + pepper). Admin user is seeded on first DB initialization. `AuthService` keeps the AUDESP token in memory with user, environment and expiration; reuse requires a 60-second validity margin (unknown expiration: until 401). Logout, environment changes and HTTP 401 clear it. Sending still requires confirmation, with a password only when no valid token exists.
- **Processes:** `processo/domain/processo_rules.dart` defines dependencies and profile pending actions; `processo_etapas.dart` computes stages, blocking reasons and permitted actions. `processosProvider` groups the editais, licitações, atas and ajustes by edital, plus a column-only summary of the source Estimativa (`EstimativasDao.listResumo`).
- **Env switching:** Piloto (`https://audesp-piloto.tce.sp.gov.br`) / Oficial (`https://audesp.tce.sp.gov.br`), persisted in `app_settings` table
- **Reports:** Uses the `pdf` package for generating exportable PDF reports (e.g., system logs).

## Database

- Schema **auto-creates** on first `DatabaseService.initialize()` with versioning via `__schema` table (current: v13); migrations are the `if (version < N)` blocks in `database_service.dart`
- Tables: `users`, `editais`, `licitacoes`, `atas`, `ajustes`, `app_settings`, `api_logs`, `estimativas`, `assinaturas_predefinidas`, `xsd_comissao`, `xsd_licitacao_logs`, `xsd_licitacao_profiles`
- Timestamps are **Unix epoch seconds** stored as `BIGINT`
- `documento_json` stored as `LONGTEXT` (raw JSON string)
- `app_settings` is a key-value store (`SettingsKeys` constants in `app_settings_dao.dart`)
- Unique index on `users.email(255)`
- `estimativas.status` stores the local state; nullable `editais.estimativa_id` has no FK (deleted source estimates are handled as absent).

## Notable Conventions

- **Admin user:** seeded in `users` table automatically during DB initialization.
- **Logs:** accessible only with a sending permission (Edital/Licitação/Ata/Ajuste). API logs in `api_logs` are read-only in the UI; deletion is restricted for auditing. Logs can be exported to PDF.
- **Password hashing:** SHA-256 with email + pepper (`'audesp_api_sys_2026'`), done in `PasswordHasher`
- **Document status:** `'draft'` (editing) vs `'sent'` (submitted to AUDESP). Status can also be consulted via the AUDESP Protocol Status Consultation feature.
- **Estimativa:** `'rascunho'` (editable) vs `'finalizada'` (read-only; PDF/HTML remain available). Only finalized estimates can be imported into an Edital. Reopening warns about linked editais without changing their imported items. Migration v13 finalizes existing estimates.
- **Gemini default model:** hardcoded as `'gemini-3.1-flash-lite'` in `GeminiService`; API key configured via Admin UI → stored in `app_settings`
- **AUDESP API auth:** email:password → POST `/login` → returns `access_token`, attached as `Authorization: Bearer <token>` by Dio interceptor (`ApiService`)
- **CSV parsers** support UTF-8 (with/without BOM) and Latin-1; use `CsvUtils` (`lib/core/utils/csv_utils.dart`)
- **Edital "Sem PNCP"** (`Edital.semPncp`): the edital uses a local `codigoEdital` instead of the PNCP id. Contracts (Ajuste) and Atas derived from it are not on PNCP either, so their forms switch `codigoContrato` / `codigoAta` to free local codes (max 25 / 31 chars) instead of the masked PNCP field. Use `text.trim()` (not `PcnpInputFormatter.stripMask`) for local codes.
- **SRP:** following the prefeitura's practice, an SRP edital generates only Ata, and a non-SRP edital generates only Ajuste. Although TCE-SP allows Ajuste from Ata, the system does not offer that flow. The Ata form only lists sent SRP editais; the Ajuste form only lists sent non-SRP editais. Adesão/participação follows its separate flow.
- **Dependencies:** Ata requires a sent SRP edital and sent Licitação; Ajuste requires a sent non-SRP edital and sent Licitação, except adesão/participação. Legacy ajustes linked to an Ata or SRP edital remain visible and editable, preserving their stored ata_id; only sending is blocked.
- **Ajuste de adesão/participação:** `ajustes.edital_id` is nullable (v12). With `adesaoParticipacao = true` the local edital link is optional and `codigoEdital`/`codigoAta` are typed PNCP ids of the managing entity; `Ajuste.editalId` is `int?`, so code reading it must handle null.
- **Licitante `niPessoa`:** normalize with `normalizarNiPessoa` (`licitacao/domain/licitacao_pessoa.dart`) — digits only for PJ/PF, kept as typed for PE (foreign ids contain letters).

## AUDESP documentation

- Official docs live in `docs/tcesp/`: one folder per document with JSON schema + example (`edital-20261015/`, `licitacao-20261015/`, `ajuste-20261015/`, `ata-20261015/`, `empenho-20261015/`), the HTTP contract `audesp.yaml`, and the rules/domains spreadsheet `Novo Modelo da Fase IV_2026_v04_externo.xlsx` (sheet "Alterações" is the changelog).
- **The JSON schema is what the server validates.** When the spreadsheet lists domain codes the schema enum lacks (e.g. amparos 174–189, fonte de recurso 19/99), follow the schema and leave a comment in the domain file.
- Domain constants are in each feature's `domain/*_domain.dart`; conditional rules (e.g. Ajuste fontes, despesas, vigência) in `domain/*_rules.dart` with unit tests.
- `docs/compatibilidade-audesp-20261015.md` is the compatibility review of the 15/10/2026 update, with the status of each finding.
- The Empenho module is not used by the app for now.

## Testing

- Tests under `test/` mirror `lib/` (domain rules, CSV parsers/mappers, services, models, some shared widgets).
- CSV tests use `flutter_test` with inline byte fixtures (`utf8.encode`, `latin1.encode`); `CsvParseException` from `csv_utils.dart` is expected in error cases.
- Prefer extracting business rules into pure functions in `domain/` and testing them there; widget tests are only used for shared widgets and import dialogs.

## Gotchas

- `config.ini` contains real DB credentials and **is tracked in git** — do not commit changes to it unless intentional
- `freezed` / `json_serializable` are declared in `pubspec.yaml` but **no generated files exist** — all models use manual `fromMap`/`toMap`
- On first run the DB schema auto-creates (`__schema` table) and the default admin user is seeded automatically.
- `flutter_secure_storage` uses DPAPI on Windows with `useBackwardCompatibility: false`
