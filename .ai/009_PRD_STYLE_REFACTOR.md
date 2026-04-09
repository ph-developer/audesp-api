### 🕵️‍♀️ Análise de Inconsistências de Design / UI

**1. Tamanhos dos Diálogos (Os famosos *Magic Numbers*)**
Cada diálogo tem um `SizedBox(width: XXX)` completamente arbitrário cravado no código:
* `UserFormDialog`: 380px
* `ItemCompraDialog`: 560px
* `PublicacaoDialog`: 460px
* `EditalImportCsvDialog`: 700px
* `GeminiReviewDialog`: 720px
* `ItemLicitacaoDialog`: 680px
* `LicitanteDialog`: 480px
* `PortalImportDialog`: 520px
* `AjusteMeEppDialog`: 620px
Isso quebra totalmente a responsividade. Se o usuário abrir em uma tela menor, vai dar *overflow*.

**2. Paddings das Páginas de Formulário**
Nas páginas base, você não se decidiu sobre os respiros:
* `AjusteFormPage` e `AtaFormPage`: usam `padding: const EdgeInsets.all(24)`.
* `EditalFormPage` e `LicitacaoFormPage`: usam `padding: const EdgeInsets.all(16)`.

**3. O Caos dos DatePickers**
A forma de pegar datas está espalhada e com regras diferentes em cada arquivo:
* Em `AjusteFormPage`: `firstDate: DateTime(1970)`, `lastDate: DateTime(2099)`. Construído num widget privado `_DatePickerRow`.
* Em `AtaFormPage`: `firstDate: DateTime(1950)`, `lastDate: DateTime(2100)`. Construído num widget privado `_DateField`.
* Em `EditalFormPage` e `LicitacaoFormPage`: Usa um simples `TextFormField` com `onTap`, e os limites são `2000` a `2099`.
* Essa variação de limites e de implementação cria uma experiência bem inconsistente.

**4. Indicadores de Carregamento nos Botões (Loading States)**
Quando algo está salvando, você troca o ícone ou texto do botão por um `CircularProgressIndicator`, o que é bom! Mas o tamanho dele varia:
* `UserFormDialog`: `14x14`, `strokeWidth: 2`.
* `AudespAuthDialog`: `16x16`, `strokeWidth: 2`.
* `EditalFormPage` (AppBar): `20x20`, `strokeWidth: 2`.
* Novamente, falta padronização.

**5. Textos de Ação (Labels)**
A linguagem dos botões de confirmação muda dependendo da tela, mesmo para ações iguais: "Salvar", "Criar", "Confirmar", "Adicionar", "Adicionar Item", "Aplicar".

---

### 📝 PRD: Padronização e Refatoração de UI/UX (Formulários e Diálogos)

**Objetivo:**
Unificar a experiência visual do usuário (UX/UI) e reduzir a duplicação de código de interface, centralizando componentes base e tornando o layout responsivo e coeso.

#### 1. Escopo das Mudanças
Criar uma pasta `lib/shared/components/` para hospedar nossos widgets genéricos que substituirão as implementações isoladas de cada módulo.

#### 2. Requisitos Funcionais e de Interface

* **REQ-01: Sistema de Diálogos Responsivos (AudespDialog)**
  * **Problema:** Larguras fixas quebrando em telas menores.
  * **Solução:** Criar um widget base `AudespDialog` ou um helper `showAudespDialog` que aceite parâmetros de tamanho semânticos (ex: `DialogSize.small` = max 400px, `DialogSize.medium` = max 600px, `DialogSize.large` = max 800px).
  * **Regra:** Substituir todos os `SizedBox(width: XXX)` por `ConstrainedBox(constraints: BoxConstraints(maxWidth: ...))`.

* **REQ-02: Componente Universal de Datas (AudespDatePickerField)**
  * **Problema:** Três widgets diferentes fazendo a mesma coisa com limites de data diferentes.
  * **Solução:** Criar um único widget `AudespDatePickerField`.
  * **Regra:** * Formato padrão: `dd/MM/yyyy`.
    * Limites globais definidos no app (ex: `1950` a `2100`).
    * Já embutir validação de data nula ou mal formatada.

* **REQ-03: Botões de Ação Padronizados (AudespAsyncButton)**
  * **Problema:** Tamanhos de *spinners* variados e código repetitivo para setar estado de `_saving`.
  * **Solução:** Criar um botão (wrapper do `FilledButton`) que aceite uma função assíncrona no `onPressed`. Ele próprio deve gerenciar seu estado de `loading` e renderizar um `CircularProgressIndicator` de tamanho único (ex: `16x16`).

* **REQ-04: Padronização de Layouts de Página**
  * Ajustar todas as páginas (`Ajuste`, `Ata`, `Edital`, `Licitacao`) para utilizarem o mesmo `EdgeInsets.all(24)` (ou 16, a gente escolhe um e abraça).
  * Padronizar o texto dos botões: 
    * Fluxo de Adição: "Adicionar [Item]"
    * Fluxo de Edição: "Salvar [Item]"
    * Ações de Envio: "Confirmar" ou "Enviar"

#### 3. Plano de Ataque (Passo a Passo)
1. **Fase 1:** Criar o `AudespDatePickerField` e o `AudespAsyncButton` em `shared/widgets/`.
2. **Fase 2:** Refatorar todos os `Dialogs` removendo os `SizedBox` de largura fixa e aplicando o novo sistema de constraints.
3. **Fase 3:** Passar o pente fino nas Pages (Edital, Licitacao, Ata, Ajuste) e uniformizar os paddings e os textos dos botões.
4. **Fase 4:** Teste de responsividade redimensionando a janela para garantir que nenhum diálogo vaza da tela.
