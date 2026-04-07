## Pipeline de Desenvolvimento — AUDESP API

### Fase 0 — Fundação do Projeto

**0.1 Dependências (pubspec.yaml)**

Adicionar ao `pubspec.yaml` todos os pacotes necessários e rodar `flutter pub get`.

| Pacote | Finalidade |
|--------|-----------|
| `drift` + `drift_flutter` | ORM SQLite (desktop-first) |
| `dio` | HTTP client com interceptors |
| `file_picker` | Seleção de PDF |
| `flutter_riverpod` | Gerenciamento de estado |
| `go_router` | Roteamento declarativo |
| `flutter_secure_storage` | Armazenamento seguro de senhas locais |
| `intl` | Formatação de datas |
| `freezed` + `json_serializable` | Modelos imutáveis + serialização |
| `build_runner` | Code generation |

- [x] Editar `pubspec.yaml` com todos os pacotes listados (dependencies + dev_dependencies)
- [x] Executar `flutter pub get`
- [x] Verificar ausência de conflitos de versão

---

**0.2 Estrutura de pastas**

Criar a hierarquia de diretórios e arquivos vazios (stubs) para toda a aplicação.

```
lib/
├── main.dart
├── app.dart                  # MaterialApp + GoRouter + ProviderScope
├── core/
│   ├── database/
│   │   ├── app_database.dart  # Drift DB + tabelas
│   │   └── daos/              # DAO por módulo
│   ├── services/
│   │   ├── api_service.dart   # Dio + auth interceptor
│   │   ├── auth_service.dart  # Login AUDESP + token
│   │   └── log_service.dart   # api_logs
│   ├── theme/
│   └── constants/
│       └── environments.dart  # piloto / oficial
├── features/
│   ├── auth/                  # Login + gestão de usuários locais
│   ├── shell/                 # NavigationRail shell
│   ├── edital/                # Módulo 1
│   ├── licitacao/             # Módulo 2
│   ├── ata/                   # Módulo 3
│   ├── ajuste/                # Módulo 4 + sub-telas
│   │   ├── empenho/
│   │   └── termo_contrato/
│   └── logs/                  # Histórico de chamadas API
└── shared/
    └── widgets/               # Form fields reutilizáveis
```

- [x] Criar todos os diretórios acima
- [x] Criar `app.dart` com stub mínimo (`MaterialApp` + ProviderScope placeholder)
- [x] Atualizar `main.dart` para chamar `runApp(ProviderScope(child: App()))`

---

**0.3 Configuração de ambientes**

Definir as constantes de URL para os dois ambientes da API AUDESP.

- [x] Criar `lib/core/constants/environments.dart` com enum `Environment { piloto, oficial }` e URLs base
- [x] Criar mecanismo de toggle (SharedPreferences ou variável global em Riverpod) para alternar ambientes em runtime

---

**0.4 Tema e estilos globais**

- [x] Criar `lib/core/theme/app_theme.dart` com `ThemeData` base (cores, fontes, espaçamentos padrão)
- [x] Referenciar o tema em `app.dart`

---

**0.5 Code generation (build_runner)**

- [x] Confirmar que `analysis_options.yaml` está configurado corretamente para `freezed` / `json_serializable`
- [x] Executar `flutter pub run build_runner build --delete-conflicting-outputs` (mesmo sem arquivos geráveis ainda, para validar o setup)

---

**0.6 Validação da fundação**

- [x] `flutter analyze` sem erros críticos
- [x] `flutter run -d windows` mostrando tela em branco sem crashes
- [x] Estrutura de pastas revisada e consistente com o pipeline

---

### Fase 1 — Banco de Dados (SQLite / Drift)

**Tabelas:**

| Tabela | Descrição |
|--------|-----------|
| `users` | Usuários locais: nome, email AUDESP, senha (hash), municipio, entidade |
| `editais` | Dados do edital (campos descritores + JSON do documento), `status` (draft/sent), `pdf_path` |
| `licitacoes` | Vinculado a `edital_id`, JSON + campos descritores |
| `atas` | Vinculado a `edital_id`, JSON + campos descritores |
| `ajustes` | Vinculado a `edital_id` + `ata_id` |
| `empenhos` | Vinculado a `ajuste_id` |
| `termos_contrato` | Vinculado a `ajuste_id` |
| `api_logs` | `endpoint`, `request`, `response`, `status_code`, `user_id`, `timestamp` |

---

### Fase 2 — Autenticação

- Tela de **login local** (selecionar usuário + senha local)
- CRUD de usuários locais (email AUDESP, senha AUDESP armazenada com `flutter_secure_storage`)
- Ao enviar qualquer módulo: autenticar no AUDESP → obter Bearer token → exibir diálogo de confirmação com nome do usuário logado → enviar

---

### Fase 3 — Shell & Navegação

- `NavigationRail` lateral com 5 itens: Edital · Licitação · Ata · Ajuste · Logs
- Seletor de ambiente (piloto/oficial) acessível nas configurações

---

### Fase 4 — Módulo 1: Edital

- Listagem de editais (draft / enviado)
- Formulário completo baseado em edital_schema.json: campos descritores + lista de publicações + lista de itens
- Seletor de PDF (`file_picker`)
- Ao selecionar o PDF deve havar uma opção que será implementada posteriormente: chama a api do gemini para ler o edital e trazer alguns dados para preenchimento automático do formulário
- Deve ser possível a importação da lista de itens de um arquivo csv (formato a definir posteriormente)
- Salvar rascunho no SQLite
- Envio: `multipart/form-data` com `documentoJSON` + `arquivoPDF` → POST `/recepcao-fase-4/f4/enviar-edital`
- Gravar retorno em `api_logs`

---

### Fase 5 — Módulo 2: Licitação

- Vinculado a um Edital existente
- Formulário baseado em licitacao-schema-v4.json: BID, fontes de recurso, itens com licitantes
- Campos condicionais conforme regras de obrigatoriedade
- Envio: `multipart/form-data` (JSON) → POST `/recepcao-fase-4/f4/enviar-licitacao`

---

### Fase 6 — Módulo 3: Ata

- Vinculado a Edital (com `srp = true`)
- Formulário baseado em ata_schema.json

---

### Fase 7 — Módulo 4: Ajuste + sub-módulos

- Ajuste vinculado a Edital + Ata
- Formulário baseado em ajuste-schema-v2.json
- Sub-telas: **Empenho de Contrato** e **Termo de Contrato** (acessíveis a partir de um Ajuste salvo)

---

### Fase 8 — Tela de Logs

- Listagem de todas as chamadas à API com filtros por módulo/data/status
- Exibição do JSON de request e response

---

### Decisões de Implementação

| Decisão | Escolha |
|---------|---------|
| Ambiente | Configurável: piloto (dev) / oficial (prod) |
| Token AUDESP | Em memória por sessão (não persiste) |
| Senhas locais | `flutter_secure_storage` (DPAPI no Windows) |
| Dados de formulário | Draft em SQLite como JSON + campos-chave estruturados |
| Campos condicionais | Lógica de validação local espelhando regras do schema |
| Retificação | Campo `retificacao` controlado por estado do registro |