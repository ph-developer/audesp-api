# Revisao de Estilo - Widgets Compartilhados AUDESP

## Status

- Fase 1 concluida.
- Fase 2 / Prioridade 1 concluida.
- Fase 2 / Prioridade 2 concluida.
- Ultima validacao: `flutter analyze` sem issues.

---

## Widgets compartilhados

| Widget | Arquivo | Uso |
|--------|---------|-----|
| `AudespTextField` | `lib/shared/widgets/audesp_text_field.dart` | Campo de texto base |
| `AudespNumberField` | `lib/shared/widgets/audesp_number_field.dart` | Campo numerico |
| `AudespCurrencyField` | `lib/shared/widgets/audesp_currency_field.dart` | Campo monetario R$ |
| `AudespPercentField` | `lib/shared/widgets/audesp_percent_field.dart` | Campo percentual |
| `AudespQuantityField` | `lib/shared/widgets/audesp_quantity_field.dart` | Campo quantidade |
| `AudespDropdown<T>` | `lib/shared/widgets/audesp_dropdown.dart` | Dropdown por `Map` ou `List<DropdownMenuItem<T>>` |
| `AudespCheckbox` | `lib/shared/widgets/audesp_checkbox.dart` | Checkbox binario |
| `AudespTriStateCheckbox` | `lib/shared/widgets/audesp_tristate_checkbox.dart` | Checkbox tristate |
| `AudespCpfCnpjField` | `lib/shared/widgets/audesp_cpf_cnpj_field.dart` | CPF/CNPJ com mascara |
| `AudespPncpField` | `lib/shared/widgets/audesp_pncp_field.dart` | ID PNCP com mascara |
| `AudespChipInput<T>` | `lib/shared/widgets/audesp_chip_input.dart` | Entrada com chips |
| `AudespSegmentedButton<T>` | `lib/shared/widgets/audesp_segmented_button.dart` | Botao segmentado |
| `showAudespDeleteDialog()` | `lib/shared/widgets/audesp_delete_dialog.dart` | Dialog padronizado de exclusao |
| `DocumentCard` | `lib/shared/widgets/document_card.dart` | Card padrao para listas de documentos/perfis |
| `EmptyState` | `lib/shared/widgets/empty_state.dart` | Icone + mensagem para listas vazias |
| `PcnpInputFormatter` | `lib/shared/formatters/pcnp_input_formatter.dart` | Formatter PNCP |

### Widgets pre-existentes mantidos

| Widget | Arquivo |
|--------|---------|
| `AudespDatePickerField` | `lib/shared/widgets/audesp_date_picker_field.dart` |
| `AudespAsyncButton` | `lib/shared/widgets/audesp_async_button.dart` |
| `SectionCard` | `lib/shared/widgets/section_card.dart` |
| `AudespDialog` | `lib/shared/widgets/audesp_dialog.dart` |
| `HoverCellText` | `lib/shared/widgets/hover_cell_text.dart` |
| `AudespFieldRow` | `lib/shared/widgets/audesp_field_row.dart` |
| `AudespSpacing` | `lib/shared/widgets/audesp_spacing.dart` |

---

## Decisoes de design

- Props de estilo como `isDense`, `counterText`, `contentPadding` e `isExpanded` ficam fixas nos componentes quando a variacao quebraria padronizacao visual.
- `AudespDropdown` usa `isExpanded: true` e `TextOverflow.ellipsis` nos itens.
- `AudespTextField` oculta contador com `counterText: ''`, usa `isDense: true`, e expoe `onFieldSubmitted` / `textInputAction`.
- `AudespDatePickerField` usa `isDense: true`.
- `DocumentCard` mostra acoes por callback: `onDelete`, `onEdit`, `onNavigate`. Callback `null` oculta botao.
- `EmptyState` cobre estados vazios de listas principais e textos simples opcionais.

---

## Migracao concluida

### Form fields

- ~40 `TextFormField` -> `AudespTextField`
- ~35 `DropdownButtonFormField` -> `AudespDropdown`
- ~15 `CheckboxListTile` -> `AudespCheckbox`
- ~15 campos numericos -> `AudespNumberField`
- ~8 campos monetarios -> `AudespCurrencyField`
- 3 campos PNCP -> `AudespPncpField`
- 1 chip input CPF -> `AudespChipInput`
- 1 tristate checkbox -> `AudespTriStateCheckbox`
- 6 page filter dropdowns -> `AudespDropdown.items()`

### Prioridade 1

- `showAudespDeleteDialog()` aplicado em:
  - `edital_page.dart`
  - `licitacao_page.dart`
  - `ata_page.dart`
  - `ajuste_page.dart`
  - `estimativas_list_page.dart`
  - `users_page.dart`
  - `admin_page.dart`
  - `estimativa_form_page.dart`
- `DocumentCard` aplicado em:
  - `edital_page.dart`
  - `licitacao_page.dart`
  - `ata_page.dart`
  - `ajuste_page.dart`
  - `estimativas_list_page.dart`
  - `users_page.dart`
  - `admin_page.dart`
- `EmptyState` aplicado em:
  - `edital_page.dart`
  - `licitacao_page.dart`
  - `ata_page.dart`
  - `ajuste_page.dart`
  - `estimativas_list_page.dart`
  - `logs_page.dart`
  - `users_page.dart`
  - `admin_page.dart`

### Prioridade 2

- `AudespFieldRow` criado e aplicado em grupos de campos:
  - `edital_form_page.dart`
  - `licitacao_form_page.dart`
  - `ata_form_page.dart`
  - `item_compra_dialog.dart`
  - `item_licitacao_dialog.dart`
- `AudespSpacing` criado e aplicado nos mesmos pontos migrados.

---

## Mantidos sem migracao

| Widget | Arquivo | Motivo |
|--------|---------|--------|
| `TextFormField` | `login_page.dart` | Senha com `errorText` manual |
| `TextFormField` | `edital_form_page.dart` | `Autocomplete.fieldViewBuilder` exige `TextFormField` |
| `TextFormField` | `edital_form_page.dart` | Codigo comentado |
| `Checkbox` puro | Gemini dialogs + `ajuste_situacao_dialog.dart` | Layout de tabela/linha sem label integrado |
| Dialog "Alterar Tipo" | `estimativa_form_page.dart` | Mudanca destrutiva, nao exclusao |
| Empty states inline de forms/dialogs | varios | Hints contextuais especificos |

---

## Proximas prioridades

### Prioridade 3 - UX

| Item | Motivo |
|------|--------|
| `AudespAutocomplete<T>` | Padroniza autocomplete restrito a lista |
| SnackBar helpers | Reduz repeticao de sucesso/erro |
| `StatusChip` | Padroniza chips de status como "Enviado" |
