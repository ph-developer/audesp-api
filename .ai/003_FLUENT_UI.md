# 003 — Migração para fluent_ui

**Data:** 2026-04-08  
**Objetivo:** Substituir o tema Material 3 pelo pacote `fluent_ui`, adotando a linguagem visual Fluent Design (Windows 11-native) em toda a aplicação.

---

## Contexto

A aplicação é um **app Flutter Desktop para Windows** que envia dados ao sistema AUDESP do TCE-SP. Atualmente usa `MaterialApp.router` com `ThemeData` (Material 3). A migração para `fluent_ui` tornará a aplicação visualmente nativa no Windows, com navegação, formulários e diálogos no estilo Fluent Design.

---

## Tabela de Mapeamento Material → Fluent UI

| Material Widget | Fluent UI Equivalente | Observações |
|---|---|---|
| `MaterialApp.router` | `FluentApp.router` | Raiz do app |
| `ThemeData` | `FluentThemeData` | Paleta, tipografia, etc. |
| `Scaffold` | `ScaffoldPage` | Para páginas com header |
| `Scaffold` (sem AppBar) | `NavigationView` body direto | Shell layout |
| `AppBar` | `PageHeader` (dentro de `ScaffoldPage`) | Título da página |
| `NavigationRail` | `NavigationView` + `NavigationPane` | Shell lateral |
| `ElevatedButton` | `FilledButton` | Ação primária |
| `TextButton` | `Button` | Ação secundária |
| `OutlinedButton` | `OutlinedButton` _(fluent_ui)_ | Ação terciária |
| `TextField` / `TextFormField` | `TextBox` | Mantém validação de `Form` |
| `DropdownButtonFormField` | `ComboBox` | Seleção de opções |
| `Checkbox` | `Checkbox` _(fluent_ui)_ | — |
| `RadioListTile` | `RadioButton` | — |
| `Switch` | `ToggleSwitch` | — |
| `Card` | `Card` _(fluent_ui)_ | — |
| `AlertDialog` / `showDialog` | `ContentDialog` / `showDialog` _(fluent_ui)_ | API diferente |
| `SnackBar` / `ScaffoldMessenger` | `displayInfoBar` + `InfoBar` | Notificações inline |
| `DefaultTabController + TabBar + TabBarView` | `TabView` | Mais poderoso |
| `CircularProgressIndicator` | `ProgressRing` | — |
| `LinearProgressIndicator` | `ProgressBar` | — |
| `ListTile` | `ListTile` _(fluent_ui)_ | API similar |
| `PopupMenuButton` | `Flyout` + `FlyoutController` ou `DropDownButton` | Menu contextual |
| `IconButton` | `IconButton` _(fluent_ui)_ | — |
| `FloatingActionButton` | `FilledButton` ou `CommandBar` button | Sem FAB nativo |
| `Chip` | `InfoBadge` ou widget customizado | Para "Retificação", env chip |
| `showDatePicker` (dialog) | `DatePicker` _(widget inline)_ | API totalmente diferente |
| `showTimePicker` (dialog) | `TimePicker` _(widget inline)_ | API totalmente diferente |
| `CircleAvatar` | `PersonPicture` | Avatar do usuário |
| `ExpansionTile` | `Expander` | — |
| `Divider` | `Divider` _(fluent_ui)_ | — |
| `Tooltip` | `Tooltip` _(fluent_ui)_ | — |
| `Form` + `GlobalKey<FormState>` | Manter igual | Funciona com fluent_ui |

> **Nota sobre Icons:** `fluent_ui` exporta `FluentIcons` mas também é compatível com `Icons` do Material. Migrar ícones para `FluentIcons` é opcional/cosmético — fazer após a migração funcional.

---

## Arquivos a Serem Alterados

### Grupo A — Configuração e Raiz

| Arquivo | Mudança |
|---|---|
| `pubspec.yaml` | Adicionar `fluent_ui: ^4.x.x` |
| `lib/main.dart` | Remover import material se necessário |
| `lib/app.dart` | `MaterialApp.router` → `FluentApp.router`; importar fluent_ui |
| `lib/core/theme/app_theme.dart` | Reescrever com `FluentThemeData` |

### Grupo B — Shell / Navegação

| Arquivo | Mudança |
|---|---|
| `lib/features/shell/shell_page.dart` | `Scaffold + NavigationRail` → `NavigationView + NavigationPane` |
| `lib/features/shell/widgets/environment_dialog.dart` | `RadioListTile` → `RadioButton`; `showDialog` → fluent `showDialog` |

### Grupo C — Auth

| Arquivo | Mudança |
|---|---|
| `lib/features/auth/pages/login_page.dart` | `Scaffold`, `TextField`, `ElevatedButton`, `Card` → equivalentes fluent |
| `lib/features/auth/pages/profile_page.dart` | Idem |
| `lib/features/auth/pages/users_page.dart` | `ListView`, `Card`, `FAB`, dialogs → fluent |
| `lib/features/auth/widgets/user_form_dialog.dart` | `AlertDialog`, `TextField` → `ContentDialog`, `TextBox` |
| `lib/features/auth/widgets/audesp_auth_dialog.dart` | Idem |

### Grupo D — Admin

| Arquivo | Mudança |
|---|---|
| `lib/features/admin/pages/admin_page.dart` | `TabController + TabBar + TabBarView` → `TabView` |

### Grupo E — Edital

| Arquivo | Mudança |
|---|---|
| `lib/features/edital/pages/edital_page.dart` | Tabs, cards, chips → fluent |
| `lib/features/edital/pages/edital_form_page.dart` | Formulário grande: `TextBox`, `ComboBox`, `DatePicker`, `TimePicker` |
| `lib/features/edital/widgets/publicacao_dialog.dart` | `ContentDialog`, `TextBox`, `DatePicker` |
| `lib/features/edital/widgets/item_compra_dialog.dart` | Idem |

### Grupo F — Licitação

| Arquivo | Mudança |
|---|---|
| `lib/features/licitacao/pages/licitacao_page.dart` | Tabs, cards → fluent |
| `lib/features/licitacao/pages/licitacao_form_page.dart` | Formulário: `TextBox`, `ComboBox`, `Checkbox`, `ToggleSwitch` |
| `lib/features/licitacao/widgets/licitante_dialog.dart` | `ContentDialog` |
| `lib/features/licitacao/widgets/item_licitacao_dialog.dart` | `ContentDialog` |

### Grupo G — Ata

| Arquivo | Mudança |
|---|---|
| `lib/features/ata/pages/ata_page.dart` | Tabs, cards → fluent |
| `lib/features/ata/pages/ata_form_page.dart` | Formulário → fluent |

### Grupo H — Ajuste

| Arquivo | Mudança |
|---|---|
| `lib/features/ajuste/pages/ajuste_page.dart` | Tabs, cards → fluent |
| `lib/features/ajuste/pages/ajuste_form_page.dart` | Formulário → fluent |

### Grupo I — Logs

| Arquivo | Mudança |
|---|---|
| `lib/features/logs/pages/logs_page.dart` | Filtros, lista, diálogo de detalhe → fluent |

---

## Etapas do Plano de Execução

### Etapa 1 — Setup do Pacote
**Prompt:** _"Execute a Etapa 1"_

- [ ] Adicionar `fluent_ui` ao `pubspec.yaml`
- [ ] Rodar `flutter pub get`
- [ ] Verificar compatibilidade de versão com outros pacotes (`go_router`, `flutter_riverpod`)
- [ ] Criar regra no `analysis_options.yaml` para preferir imports de `fluent_ui` ao invés de `material`

**Resultado esperado:** Projeto compila com `fluent_ui` instalado.

---

### Etapa 2 — Core: Tema, App e Rota
**Prompt:** _"Execute a Etapa 2"_

- [ ] Reescrever `app_theme.dart` com `FluentThemeData`
  - Paleta: azul TCE-SP `0xFF1565C0` como `accentColor`
  - Tipografia PT-BR adequada
  - Light theme
- [ ] Alterar `app.dart`: `MaterialApp.router` → `FluentApp.router`
- [ ] Garantir que `go_router` continua funcionando com `FluentApp.router`
  - O `routerConfig:` ou `routerDelegate:` + `routeInformationParser:` precisa ser compatível
- [ ] Ajustar importações: remover `package:flutter/material.dart` do `app.dart` e `app_theme.dart`, usar `package:fluent_ui/fluent_ui.dart`

**Resultado esperado:** App inicializa com tema Fluent. Rota para `/login` funciona.

---

### Etapa 3 — Shell / Navegação Principal
**Prompt:** _"Execute a Etapa 3"_

- [ ] Reescrever `shell_page.dart`
  - `NavigationView` com `NavigationPane` lateral (equivalente ao `NavigationRail`)
  - 5 itens: Edital, Licitação, Ata, Ajuste, Logs
  - FooterItems: Environment chip + user avatar
  - Sincronizar índice com `go_router` (o `NavigationPane.selected` deve refletir a rota)
- [ ] Reescrever `environment_dialog.dart` com `ContentDialog` + `RadioButton`
- [ ] Avatar de usuário: `PersonPicture` ou `DropDownButton` com Flyout para o menu de logout

**Resultado esperado:** Shell navega corretamente entre as 5 seções.

---

### Etapa 4 — Auth: Login e Perfil
**Prompt:** _"Execute a Etapa 4"_

- [ ] `login_page.dart`: `ScaffoldPage`, `TextBox`, `FilledButton`, `PasswordBox` (para senha)
- [ ] `profile_page.dart`: cards com `Card` fluent, `TextBox`, `FilledButton`
- [ ] `users_page.dart`: `ListView`, `ListTile`, botões de ação
- [ ] `user_form_dialog.dart`: `ContentDialog`, `TextBox`
- [ ] `audesp_auth_dialog.dart`: `ContentDialog`, `PasswordBox`

**Resultado esperado:** Fluxo de login e gerenciamento de usuários funcional.

---

### Etapa 5 — Admin
**Prompt:** _"Execute a Etapa 5"_

- [ ] `admin_page.dart`: Substituir `DefaultTabController + TabBar + TabBarView` por `TabView`
  - Tab "Usuários": lista de usuários com `UserFormDialog`
  - Tab "Ambiente": `RadioButton` para Piloto/Oficial
  - Tab "Registros": visão geral de registros

**Resultado esperado:** Página admin funcional com `TabView`.

---

### Etapa 6 — Módulo Edital ✅
**Prompt:** _"Execute a Etapa 6"_

- [x] `edital_page.dart`: `ScaffoldPage + TabView` (Rascunhos/Enviados), `Card`, Container p/ Retificação
- [x] `edital_form_page.dart`:
  - `TextBox` para campos de texto, `ComboBox` para dropdowns
  - `DatePicker` + `TimePicker` inline (substituíram `showDatePicker`/`showTimePicker`)
  - `ToggleSwitch` para booleans (substituiu `SwitchListTile`)
  - `AutoSuggestBox` para Amparo Legal (substituiu `Autocomplete`)
  - `FilledButton`/`Button` sem `.icon` (Row com Icon)
  - `ProgressRing` para loading; `displayInfoBar` para feedback
  - Validação manual `_validateForm()` (sem `GlobalKey<FormState>`)
- [x] `publicacao_dialog.dart`: `ContentDialog` + `DatePicker` inline
- [x] `item_compra_dialog.dart`: `ContentDialog` + Fluent widgets

**Resultado:** Módulo Edital migrado. `flutter analyze` — apenas 2 info pré-existentes.

---

### Etapa 7 — Módulo Licitação ✅
**Prompt:** _"Execute a Etapa 7"_

- [x] `licitacao_page.dart`: idem Etapa 6
- [x] `licitacao_form_page.dart`: `TextBox`, `ComboBox`, `Checkbox`, `ToggleSwitch` para tristate
- [x] `licitante_dialog.dart`: `ContentDialog`
- [x] `item_licitacao_dialog.dart`: `ContentDialog`

**Resultado esperado:** Módulo Licitação totalmente funcional.

---

### Etapa 8 — Módulos Ata e Ajuste ✅
**Prompt:** _"Execute a Etapa 8"_

- [x] `ata_page.dart` + `ata_form_page.dart`
- [x] `ajuste_page.dart` + `ajuste_form_page.dart`

**Resultado esperado:** Módulos Ata e Ajuste funcionais.

---

### Etapa 9 — Logs ✅
**Prompt:** _"Execute a Etapa 9"_

- [x] `logs_page.dart`: filtros com `ComboBox` e `DatePicker`, lista com `ListView`, `_LogDetailDialog` → `ContentDialog`
- [x] Botão "Limpar todos" com confirmação via `ContentDialog`

**Resultado esperado:** Página de logs funcional.

---

### Etapa 10 — Refinamentos e Widgets Compartilhados ✅
**Prompt:** _"Execute a Etapa 10"_

- [x] Criar shared widgets em `lib/shared/widgets/`:
  - `section_header.dart` — `SectionHeader` (extraído de `_SectionHeader` duplicado em ata_form e ajuste_form)
  - `app_info_bar.dart` — `showAppInfoBar()` wrapper para `displayInfoBar` com tipos (success, warning, error, info)
  - `app_confirm_dialog.dart` — `AppConfirmDialog` + `showAppConfirmDialog()` reutilizável
  - `status_badge.dart` — `StatusBadge` com enum `AppStatus` (rascunho / enviado / retificação)
  - `app_card.dart` — `AppCard` padronizado com padding e borderRadius
  - `widgets.dart` — barrel export de todos os shared widgets
- [x] Substituir `_SectionHeader` por `SectionHeader` em:
  - `ata_form_page.dart` (4 usos → shared widget)
  - `ajuste_form_page.dart` (10 usos → shared widget)
- [x] Substituir badge de Retificação inline por `StatusBadge` em:
  - `ata_page.dart`
  - `ajuste_page.dart`
- [x] Migrar `FluentIcons` nos lugares mais visíveis:
  - Shell: `document`, `task_list`, `history`, `shield`, `account_management`, `people`
  - ata_page: `task_list`, `task_add`, `accept`, `edit`, `caret_right`
  - ajuste_page: `task_list`, `accept`, `edit`, `caret_right`
  - Removeu import `show Icons` de `ata_page.dart` e `ajuste_page.dart`
- [x] Espaçamentos e alinhamentos: padrão consistente de `padding: EdgeInsets.all(16)` no `AppCard`

**Resultado:** Código coeso, sem duplicação, visual polido. `flutter analyze → No issues found!`

---

## Pontos de Atenção Críticos

### 1. go_router + FluentApp
`FluentApp.router` aceita `routerConfig:` da mesma forma que `MaterialApp.router`. O `go_router` é totalmente compatível. Apenas trocar o widget raiz é suficiente.

### 2. Conflito de imports Material vs Fluent
`fluent_ui` importa internamente vários widgets do Material mas **redefine** alguns (ex: `Card`, `Checkbox`, `Dialog`, `ListTile`). Para evitar conflitos:
```dart
// CORRETO — usar apenas fluent_ui no arquivo
import 'package:fluent_ui/fluent_ui.dart';

// ERRADO — causar ambiguidade
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart';
```
Se um widget Material for necessário em um arquivo fluent, usar hide:
```dart
import 'package:flutter/material.dart' show Colors;
```

### 3. Form + TextBox
`TextBox` do fluent_ui **não** possui `validator` nativo (é um `TextEditingController`-based). Para manter validação:
- Manter o `Form` + `GlobalKey<FormState>`
- Usar o parâmetro `validator` do wrapper `FormField<String>` customizado, ou
- Usar a abordagem de `autovalidate` com controle manual

**Solução recomendada:** Criar um `AppTextFormBox` que une `TextBox` com `FormField` para validação.

### 4. DatePicker / TimePicker — API diferente
No Material, `showDatePicker` abre um dialog. No fluent_ui, `DatePicker` é um **widget inline**.  
Isso afeta o layout dos formulários — os campos de data precisam ser redimensionados para acomodar o widget dropdown inline.

### 5. NavigationView e go_router
O `NavigationView` atualiza seu `selected` index internamente. Para sincronizar com o roteador:
- Usar `onChanged` do `NavigationPane` para chamar `context.go(route)`
- Usar o `selectedIndex` calculado a partir da rota atual (via `GoRouter.of(context).location` ou `GoRouterState`)

### 6. ScaffoldPage vs layout customizado
- Para páginas simples (login, admin): usar `ScaffoldPage` com `header: PageHeader(title: ...)`
- Para páginas de formulário complexas: usar `ScaffoldPage` com `content: ...` e scroll manual
- Para a shell: o body do `NavigationView` serve como container principal

### 7. InfoBar vs SnackBar
`displayInfoBar` é uma função global do fluent_ui que exige o `BuildContext` de um widget dentro de um `FluentApp`. O replacement é:
```dart
// Antes:
ScaffoldMessenger.of(context).showSnackBar(SnackBar(...));

// Depois:
displayInfoBar(context, builder: (ctx, close) {
  return InfoBar(title: Text('...'), severity: InfoBarSeverity.success);
});
```

---

## Versão do Pacote

Verificar a versão mais recente em [pub.dev/packages/fluent_ui](https://pub.dev/packages/fluent_ui) antes de adicionar ao `pubspec.yaml`.

Compatibilidade mínima recomendada: `fluent_ui: ^4.9.0` (suporte Flutter 3.x, Windows 11 design tokens).

> **Versão instalada:** `fluent_ui: ^4.15.1` (resolvida em 2026-04-08 via `flutter pub add`).

---

## Ordem de Execução Sugerida

```
Etapa 1 → Setup
Etapa 2 → Tema + App + Router
Etapa 3 → Shell (testar navegação)
Etapa 4 → Auth (testar login)
Etapa 5 → Admin
Etapa 6 → Edital (maior esforço)
Etapa 7 → Licitação
Etapa 8 → Ata + Ajuste
Etapa 9 → Logs
Etapa 10 → Refinamentos
```

Cada etapa deve ser compilável e testável individualmente. Ao final de cada prompt, confirmar que `flutter run -d windows` sobe sem erros antes de avançar.

---

## Status de Progresso

| Etapa | Status |
|---|---|
| 1 — Setup do pacote | ✅ Concluído |
| 2 — Tema, App e Rota | ✅ Concluído |
| 3 — Shell / Navegação | ✅ Concluído |
| 4 — Auth | ✅ Concluído |
| 5 — Admin | ✅ Concluído |
| 6 — Módulo Edital | ✅ Concluído |
| 7 — Módulo Licitação | ✅ Concluído |
| 8 — Módulos Ata e Ajuste | ✅ Concluído |
| 9 — Logs | ✅ Concluído |
| 10 — Refinamentos | ✅ Concluído |
