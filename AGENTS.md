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
- **Router:** `go_router` com `ShellRoute` + rail (`shell/widgets/app_navigation_rail.dart`); módulos, ordem e permissões ficam em `core/navigation/app_modules.dart`. A casca envolve Estimativa/Edital/Licitação/Ata/Ajuste/Logs. `homeLocationFor(user)` é síncrono: primeiro módulo de envio acessível, depois Estimativa, Logs ou Perfil. Após login e na abertura com sessão, `home_navigation.dart` escolhe o primeiro módulo de envio com pendência (Edital → Licitação → Ata → Ajuste), com limite de 2 segundos e fallback em caso de erro. O resultado é ignorado se a sessão mudar ou o usuário navegar durante a consulta; mudanças de ambiente recalculam as pendências pelo provider. Login, Perfil e Admin ficam fora da casca.
- **Pattern per feature:** `providers.dart`, `services/`, `pages/`, `widgets/`, optional `domain/` (domain logic) and `csv/` (import parsers)
- **Auth:** local DB users (SHA-256 + pepper). Admin user is seeded on first DB initialization. `AuthService` keeps the AUDESP token in memory with user, environment and expiration; reuse requires a 60-second validity margin (unknown expiration: until 401). Logout, environment changes and HTTP 401 clear it. Sending still requires confirmation, with a password only when no valid token exists.
- **Vínculos e dependências:** `processo/domain/processo_rules.dart` mantém as regras dos formulários. `documentosProcessoProvider` carrega os quatro tipos de documentos, inclusive ajustes sem edital; invalidar após criar, alterar, excluir ou retornar a rascunho. `enviosProcessoProvider` expõe `EnviosProcesso` com os quatro índices de `enviosProvider` e o ambiente ativo. `processosProvider` agrupa esses dados por edital e acrescenta o resumo da Estimativa (`EstimativasDao.listResumo`). Invalidar `enviosProvider` recalcula as conclusões e as pendências. A tela Processos e a cadeia visual de etapas foram removidas.
- **Pendências por módulo:** `pendencias/domain/pendencias_modulos.dart` contém funções puras usadas por `pendenciasModulosProvider` nas abas Pendências (selecionadas inicialmente) e por `pendenciasContagemProvider` nos badges do rail e na tela inicial. Edital reúne compras do PNCP sem edital e protocolos em análise/rejeitados/excluídos; Licitação reúne esses protocolos e editais concluídos sem nenhuma licitação. Ata só cobra protocolos. Ajuste reúne protocolos e contratos do PNCP ainda sem ajuste local; apenas os contratos liberados contam no badge e na tela inicial, e os bloqueados aparecem abaixo deles na aba. Ajustes de adesão sem edital também são avaliados. Rascunhos sem envio aceito não são pendências de protocolo. A busca não altera os badges; compras e contratos dispensados só aparecem com "Mostrar dispensadas"/"Mostrar dispensados" e não contam. Atualização manual consulta direto com token válido do usuário/ambiente ou usa `showAudespAuthDialog`, salva em `ApiLogsDao.updateProtocoloInfo` e invalida `enviosProvider`.
- **Env switching:** Piloto (`https://audesp-piloto.tce.sp.gov.br`) / Oficial (`https://audesp.tce.sp.gov.br`), persisted in `app_settings` table
- **Reports:** Uses the `pdf` package for generating exportable PDF reports (e.g., system logs).

## Database

- Schema **auto-creates** on first `DatabaseService.initialize()` with versioning via `__schema` table (current: v17); migrations are the `if (version < N)` blocks in `database_service.dart`
- Tables: `users`, `editais`, `licitacoes`, `atas`, `ajustes`, `app_settings`, `api_logs`, `estimativas`, `assinaturas_predefinidas`, `xsd_comissao`, `xsd_licitacao_logs`, `xsd_licitacao_profiles`, `pncp_compras`, `condutores`, `pncp_contratos`
- **Access:** DAOs use `DatabaseService.execute` (no parameters, or client-side named parameters) and `DatabaseService.executePrepared` (server-side binding; always deallocates). Never prepare a statement elsewhere: open statements only die with the connection, `max_prepared_stmt_count` is global to the MySQL instance, and a leak here takes down the other systems on that server.
- **Pool:** `DbPool` (`db_pool.dart`) replaces the driver's `MySQLConnectionPool`, which exceeds `maxConnections` in bursts, freezes the isolate when no connection is idle (`pool.dart` `Future.doWhile`) and loses the connection when a `withConnection` callback throws. `DbPool.use` holds a connection exclusively, so a callback must not call `DatabaseService` again.
- Timestamps are **Unix epoch seconds** stored as `BIGINT`
- `documento_json` stored as `LONGTEXT` (raw JSON string)
- `app_settings` is a key-value store (`SettingsKeys` constants in `app_settings_dao.dart`)
- Unique index on `users.email(255)`
- `estimativas.status` stores the local state; nullable `editais.estimativa_id` has no FK (deleted source estimates are handled as absent).

## Notable Conventions

- **Admin user:** seeded in `users` table automatically during DB initialization.
- **Logs:** accessible only with a sending permission (Edital/Licitação/Ata/Ajuste). API logs in `api_logs` are read-only in the UI; deletion is restricted for auditing. Logs can be exported to PDF.
- **Último envio:** `api_logs` has no document id; a send is matched to its document by the `descritor` fields (`DescritorEnvio` in `logs/domain/ultimo_envio.dart`, also used by the forms' `findLatest*SendLog`). The list pages load `ApiLogsDao.listEnvios`, which extracts only the descritor in MySQL (`JSON_EXTRACT`), and show `UltimoEnvioChip` on each card, drafts included (failed attempts, rejected protocols).
- **Password hashing:** SHA-256 with email + pepper (`'audesp_api_sys_2026'`), done in `PasswordHasher`
- **Document status:** `'draft'` (editing) vs `'sent'` (submitted to AUDESP). Status can also be consulted via the AUDESP Protocol Status Consultation feature.
- **Estimativa:** `'rascunho'` (editable) vs `'finalizada'` (read-only; PDF/HTML remain available). Only finalized estimates can be imported into an Edital. Reopening warns about linked editais without changing their imported items. Migration v13 finalizes existing estimates.
- **Gemini default model:** hardcoded as `'gemini-3.1-flash-lite'` in `GeminiService`; API key configured via Admin UI → stored in `app_settings`
- **AUDESP API auth:** email:password → POST `/login` → returns `access_token`, attached as `Authorization: Bearer <token>` by Dio interceptor (`ApiService`)
- **CSV parsers** support UTF-8 (with/without BOM) and Latin-1; use `CsvUtils` (`lib/core/utils/csv_utils.dart`)
- **Edital "Sem PNCP"** (`Edital.semPncp`): the edital uses a local `codigoEdital` instead of the PNCP id. Contracts (Ajuste) and Atas derived from it are not on PNCP either, so their forms switch `codigoContrato` / `codigoAta` to free local codes (max 25 / 31 chars) instead of the masked PNCP field. Use `text.trim()` (not `PcnpInputFormatter.stripMask`) for local codes.
- **SRP:** following the prefeitura's practice, an SRP edital generates only Ata, and a non-SRP edital generates only Ajuste. Although TCE-SP allows Ajuste from Ata, the system does not offer that flow. The Ata form only lists sent SRP editais; the Ajuste form only lists sent non-SRP editais. Adesão/participação follows its separate flow.
- **Fase concluída = protocolo armazenado:** a phase only unlocks the next one when a send of the document (original or retificação, matched by the descritor without `retificacao`) is **Armazenado** (or Substituído) in the active environment — `ConclusaoEnvio` in `logs/domain/conclusao_envio.dart`; `status = 'sent'` alone is not enough. A Piloto protocol never concludes in Oficial. Legacy: `'sent'` with no accepted send log counts as concluded. A later retificação em análise/rejeitada does not undo it. Blocking reasons show the protocol situation.
- **Protocolos em andamento:** `protocolosMonitorProvider` (shell, users with Logs access) consults up to 20 non-final protocols of the active environment every 2 minutes, only while `AuthService.tokenValido` holds (it never asks for the password), and invalidates `enviosProvider` when one changes.
- **Dependencies:** Licitação can only be sent with the edital concluded; Ata requires a concluded SRP edital and concluded Licitação; Ajuste requires a concluded non-SRP edital and concluded Licitação, except adesão/participação. Legacy ajustes linked to an Ata or SRP edital remain visible and editable, preserving their stored ata_id; only sending is blocked.
- **Ajuste de adesão/participação:** `ajustes.edital_id` is nullable (v12). With `adesaoParticipacao = true` the local edital link is optional and `codigoEdital`/`codigoAta` are typed PNCP ids of the managing entity; `Ajuste.editalId` is `int?`, so code reading it must handle null.
- **PNCP:** `features/pncp/` consulta a API pública (`/v1/orgaos/{cnpj}/compras/{ano}/{sequencial}`, 404 = sem compra) para o CNPJ de Admin → PNCP / UFESP. `PncpVarredura` parte da última sequência encontrada (settings `pncp_sequencia_<cnpj>_<ano>`), para após 3 respostas 404 consecutivas ou 50 requisições e só consulta o ano anterior se já consultado. 410 é ignorado sem contar como ausência; 429 aguarda `Retry-After` (≤ 60 s, padrão 10 s) e tenta uma vez; outros erros preservam o progresso e aparecem no botão "Consultar PNCP" da listagem de Edital. O botão só aparece com PNCP configurado e permissão de criar edital; mostra execução, erro e última consulta. Compras em `pncp_compras` sem edital correspondente (`codigoEdital` ou publicação PNCP, só dígitos) aparecem em Edital → Pendências para quem cria edital. Podem ser dispensadas com motivo opcional e restauradas via "Mostrar dispensadas". "Iniciar edital" abre `/edital/new?pncpCompraId=` com o cabeçalho de `PncpEditalMapper`, sem importar itens. `pncpMonitorProvider` continua na casca, verifica a cada minuto e só consulta quando `pncp_ultima_consulta_em` ultrapassa o intervalo configurado, compartilhado entre máquinas.
- **Contratos PNCP** (v17): na mesma rodada de `PncpConsultaNotifier`, depois das compras, consulta `/api/pncp/v1/orgaos/{cnpj}/contratos/{ano}/{sequencial}` (não `/api/consulta`). `PncpVarredura.executarContratos` compartilha o algoritmo das compras, com limite próprio de 50 consultas e cursor `pncp_contrato_sequencia_<cnpj>_<ano>`; usa a mesma `pncp_ultima_consulta_em`. Falhas preservam tudo já salvo e a mensagem de sucesso informa compras e contratos novos. `ConsultarPncpButton` também aparece no Ajuste com a respectiva permissão. `PncpContratosDao.upsert` preserva a dispensa. `PncpContratosPendencias.classificar` casa códigos com dígitos: qualquer ajuste local, inclusive rascunho, retira o contrato das pendências; referência a ata, edital SRP ou oculto nunca aparece, nem nas dispensas. Adesão (`frutoAdesao` ou compra de outro CNPJ) é liberada sem dependência local; nos demais casos usa `ProcessoRules.motivoBloqueioAjuste`. Sem compra PNCP, bloqueia mesmo na adesão, pois falta a referência do edital. Todos os demais contratos podem ser dispensados/restaurados na aba do Ajuste. `/ajuste/new?pncpContratoId=` revalida a pendência e aplica `PncpAjusteMapper` à resposta salva, sem consultar novamente a rede: referências, número/ano, processo, fornecedor, objeto, datas e valores presentes; tipo e categoria apenas nos enums do schema AUDESP. Não deduz itens, fontes, despesas, tipo de objeto nem dados da gerenciadora.
- **Edital oculto** (v15: `editais.oculto_em`, `oculto_por`, `motivo_ocultacao`): identifica processos enviados por outro sistema; nada é excluído. Não gera pendências em nenhum módulo, inclusive para documentos vinculados, e bloqueia nova licitação/ata/ajuste (`ProcessoRules.motivoEditalOculto`, também na adesão). Fica fora de `EditaisDao.watchByStatus` e do seletor de Licitação, salvo vínculo existente. `documentosProcessoProvider` e `processosProvider` o preservam para corresponder às compras do PNCP e verificar dependências, mas ele não aparece nas pendências. **Ocultar/restaurar é feito só no banco** (preencher/limpar `oculto_em`); não há ação nem lista de ocultos na UI.
- **Documentação AUDESP monitorada:** `features/documentacao/` verifica a página de JSON Schemas/xlsx do TCE e a API (`audesp.yaml`, carregado pela casca do Swagger em `/api`) uma vez por período (0h–12h / 12h–0h, `periodoVerificacao`), compartilhado entre as máquinas via `app_settings` (`documentacao_*`). Compara hashes SHA-256 do texto do `<article>` (menu/rodapé mudam sozinhos), de cada anexo e do yaml. A primeira leitura vira referência; diferença mostra um ícone vermelho no rail para todos ("informe o TI") e só o admin "Marcar como verificada" (referência = última leitura). Falhas são silenciosas e liberam o período, com nova tentativa após 15 min.
- **UFESP:** `UfespConfig` (`processo/domain/ufesp_rules.dart`, settings `ufesp_valor` / `ufesp_quantidade_minima`, padrão 2.500 × R$ 38,42). `UfespIndicador` fica em `shared/widgets/ufesp_indicador.dart` e mostra "Envio não obrigatório" em compras do PNCP e editais abaixo do limite, na listagem e nas pendências (inclusive criar licitação). O indicador é informativo e não altera pendências nem badges. `Edital.valorTotalEstimado` soma `itensCompra[].valorTotal`.
- **Condutores** (v16, `condutores`: nome + CPF único): cadastro reutilizável para `cpfsCondutores` da Licitação, escolhido em `licitacao/widgets/condutores_dialog.dart` (como as assinaturas da exportação SEI). A licitação continua guardando só os CPFs; CPFs fora do cadastro (anteriores a ele ou excluídos dele) permanecem na licitação (`CondutorRules.aplicarSelecao`).
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
- Database tests run the real driver against `test/support/fake_mysql_server.dart`, a local socket server that counts statements and connections; no MySQL is needed.
- Prefer extracting business rules into pure functions in `domain/` and testing them there; widget tests are only used for shared widgets and import dialogs.

## Gotchas

- `config.ini` contains real DB credentials and **is tracked in git** — do not commit changes to it unless intentional
- `freezed` / `json_serializable` are declared in `pubspec.yaml` but **no generated files exist** — all models use manual `fromMap`/`toMap`
- On first run the DB schema auto-creates (`__schema` table) and the default admin user is seeded automatically.
- `flutter_secure_storage` uses DPAPI on Windows with `useBackwardCompatibility: false`
