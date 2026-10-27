# Compatibilidade com a documentação AUDESP de 15/10/2026

Data da análise: 27/10/2026.

## Resultado

A aplicação está **parcialmente compatível**. Os quatro construtores conseguem produzir JSONs estruturalmente válidos, mas há fluxos documentados que a interface bloqueia, valores que o envio altera e regras condicionais que não são verificadas. Não é possível considerar os quatro módulos integralmente adequados à documentação atual.

| Ordem | Módulo | Situação |
| --- | --- | --- |
| 1 | Edital | Novas modalidades e amparos presentes no schema já estão implementados. Faltam validações de publicidade, PDF e combinações de campos. Critérios distintos dos itens são sobrescritos no envio. |
| 2 | Licitação | Há perda de caracteres em identificadores estrangeiros, exigência indevida de fonte de recurso e limite de nome desatualizado. Também faltam verificações condicionais dos itens. |
| 3 | Ajuste | O filtro de editais impede o vínculo correto de ajustes com SRP. Vigência apenas em meses e códigos locais de contrato são bloqueados. |
| 4 | Ata | O identificador PNCP de 31 dígitos já funciona. Códigos locais são bloqueados e a referência dos itens à licitação não é conferida. |

**P1** indica perda de dados ou bloqueio de um fluxo documentado. **P2** indica restrição de preenchimento ou ausência de validação que permite tentar um envio incompatível. As divergências entre documentos oficiais estão separadas dos defeitos confirmados da aplicação.

## Situação das correções

Atualizado em 27/10/2026. Cada achado abaixo traz também uma linha **Situação**.

| Achado | Situação | Commit |
| --- | --- | --- |
| E1 — PDF e limite de tamanho | ✅ Corrigido | `c2d8536` |
| E2 — publicação declarada sem publicações | ✅ Corrigido | `118d2a1` |
| E3 — instrumento × modalidade, datas e categoria | ✅ Corrigido (modalidades 12 e 15 sem checagem de instrumento) | `c2d8536` |
| E4 — critério dos itens sobrescrito | ➖ Não se aplica: a entidade usa um único critério por edital | — |
| L1 — identificador PE perde letras | ✅ Corrigido | `77ce34b` |
| L2 — fonte de recurso sem declaração / código 99 | ✅ Corrigido | `77ce34b` |
| L3 — nome do licitante limitado a 50 | ✅ Corrigido | `118d2a1` |
| L4 — garantia e índice "Outro" | ✅ Corrigido | `118d2a1` |
| L5 — validação conjunta de itens e licitantes | ✅ Corrigido | `c2d8536` |
| L6 — datas e valor dos itens | ✅ Corrigido | `c2d8536` |
| L7 — rótulo de condução da contratação | ✅ Corrigido (rótulo segue o schema) | `118d2a1` |
| A1 — editais SRP excluídos do ajuste | ✅ Corrigido | `c7f9d92` |
| A2 — vigência apenas em meses | ✅ Corrigido | `77ce34b` |
| A3 — código de contrato local | ✅ Corrigido (código livre quando o edital é "Sem PNCP") | `c7f9d92` |
| A4 — adesão depende de edital local | ✅ Corrigido (vínculo local opcional na adesão; migração v12 torna `ajustes.edital_id` anulável) | `c2d8536`, `fe7820f` |
| A5 — categoria × objeto do contrato | ✅ Corrigido | `c2d8536` |
| A6 — limites de campos do contrato | ✅ Corrigido | `118d2a1` |
| T1 — código local de ata | ✅ Corrigido (código livre quando o edital é "Sem PNCP") | `c7f9d92` |
| T2 — itens da ata × licitação | ✅ Corrigido (também no Ajuste; sem licitação local, apenas avisa) | `c2d8536` |
| T3 — número da ata acima de 30 | ✅ Corrigido | `118d2a1` |
| Amparo 161 (divergência) | ✅ Removido do app, seguindo o schema | `77ce34b` |
| Fonte 99 (divergência) | ✅ Removida do app, seguindo o schema | `77ce34b` |
| Demais divergências da planilha | ⏳ Aguardando a TCE: o app segue o schema | — |

## Escopo e método

- Schemas e exemplos em `docs/tcesp/edital-20261015`, `licitacao-20261015`, `ajuste-20261015` e `ata-20261015`.
- Planilha `docs/tcesp/Novo Modelo da Fase IV_2026_v04_externo.xlsx`, incluindo regras e domínios relacionados aos quatro módulos.
- Contrato HTTP em `docs/tcesp/audesp.yaml`.
- Formulários, montagem do JSON, importações e serviços de envio correspondentes.
- Comparação dos schemas novos com os documentos anteriores ainda disponíveis no `HEAD` do Git.

O módulo **Empenho de Contrato ficou fora da análise**. Nenhuma alteração foi feita no código da aplicação, nos documentos oficiais ou em `config.ini`. Não houve envio ao AUDESP nem acesso ao banco de produção.

Para conferir a serialização, foram executados em uma sonda Dart os quatro métodos `_buildJson` extraídos dos fontes atuais, com entradas de tela substituídas por valores de teste. No edital foram incluídos o preenchimento do critério nos itens e a limpeza realizada pelo serviço antes do envio. As saídas foram verificadas por `jsonschema` 4.26.0, com validação de formatos de data. Essa verificação não equivale a executar a interface completa nem a obter aceitação do servidor.

## Mudanças efetivas nos schemas

| Módulo | Diferença em relação ao documento anterior do repositório | Aplicação |
| --- | --- | --- |
| Edital | `additionalProperties: false` na raiz; modalidades 15–19; amparos 166–173. | As modalidades e esses amparos já existem. O campo interno `criterioJulgamentoId` é retirado da raiz por `EditalService`, portanto não provoca rejeição por propriedade adicional no envio atual. |
| Licitação | `nomeRazaoSocial` do licitante passa de 50 para 100 caracteres. | O diálogo continua limitado a 50. |
| Ajuste | `descritor.codigoAta` passa de 30 para 31 caracteres; `processo` entra em `required`; fontes e datas de vigência saem de `required` na raiz. | 31 dígitos e processo obrigatório já são contemplados. As fontes possuem regra condicional por órgão/receita. As datas continuam obrigatórias em todas as situações. |
| Ata | `descritor.codigoAta` passa de 30 para 31 caracteres. | Campo, máscara e serialização já contemplam 31 dígitos. |

Os demais achados abaixo incluem incompatibilidades que já existiam antes da atualização. Não devem ser atribuídos automaticamente à mudança de 15/10.

## 1. Edital

### E1 — P2: PDF pode ser omitido em qualquer modalidade

**Situação:** ✅ Corrigido em `c2d8536`.

A planilha permite JSON sem PDF somente na modalidade 9, inexigibilidade, com erro indicativo. No formulário não existe bloqueio para PDF ausente nas demais modalidades. O serviço simplesmente deixa de incluir `arquivoPDF` quando `pdfPath` é nulo. Também não há conferência local do limite de 30 MB descrito no YAML.

**Impacto:** um pregão, por exemplo, pode chegar à tentativa de envio sem o anexo exigido. A ausência de validação não significa que o servidor aceitará o documento.

**Referências:** planilha `Edital!C3:D3`; `docs/tcesp/audesp.yaml:117`; `lib/features/edital/pages/edital_form_page.dart:336`; `lib/features/edital/services/edital_service.dart:65`.

**Adequação:** exigir o PDF conforme a modalidade e conferir o tamanho antes de transmitir.

### E2 — P2: publicação declarada sem nenhuma publicação informada

**Situação:** ✅ Corrigido em `118d2a1`.

Com `houvePublicacao = true` e lista vazia, o construtor omite `publicacoes`. A interface mostra o texto “Adicione ao menos uma publicação”, mas essa mensagem não integra a validação do formulário e `_enviar` não bloqueia o caso.

**Impacto:** JSON passa no schema, mas contraria a obrigatoriedade condicional da planilha. A sonda reproduziu essa saída.

**Referências:** planilha `Edital!C10:F12`; `lib/features/edital/pages/edital_form_page.dart:219`, `:336` e `:1012`.

**Adequação:** bloquear o envio quando a publicação estiver declarada e a lista estiver vazia.

### E3 — P2: combinações de instrumento, modalidade e categoria não são conferidas

**Situação:** ✅ Corrigido em `c2d8536`. Modalidades 12 (Credenciamento) e 15 (Chamada pública) ficam sem checagem de instrumento, pois o instrumento 4 foi removido do app.

Os seletores de instrumento e modalidade são independentes e validam apenas a presença de uma seleção. Assim, é possível escolher instrumento 3 com modalidade 6, combinação que não consta na relação oficial. O diálogo do item também oferece material/serviço e categoria sem considerar a modalidade: a planilha exige material e categoria 1 ou 2 para leilão, e categoria 3 nas demais modalidades.

**Referências:** planilha `Intrumento Convocatório!A3:C6` e `Edital!C32:I42`; `lib/features/edital/pages/edital_form_page.dart:1110`; `lib/features/edital/widgets/item_compra_dialog.dart:151` e `:249`.

**Adequação:** validar essas relações. A tabela oficial de instrumentos também precisa ser esclarecida para as modalidades novas, conforme as divergências documentais ao final.

### E4 — P2: critério de julgamento de cada item é sobrescrito

**Situação:** ➖ Não se aplica: a entidade utiliza um único critério de julgamento por edital, então aplicar o critério geral a todos os itens é o comportamento esperado.

Antes de transmitir, `_enviar` grava `_criterioJulgamentoId` em todos os itens, mesmo naqueles que já têm um critério próprio importado. O contrato documenta o critério no item.

**Reprodução:** item 1 com critério 1 e item 2 com critério 2, mantendo o critério geral em 1, resultam em dois itens enviados com critério 1. A sonda confirmou a alteração. O JSON continua válido, portanto o schema não detecta a perda da informação original.

**Referências:** planilha `Edital!C41:I41`; schema do edital, `properties.itensCompra.items.properties.criterioJulgamentoId`; `lib/features/edital/pages/edital_form_page.dart:367`.

**Adequação:** preservar o valor informado por item e aplicar eventual padrão apenas a itens sem valor.

## 2. Licitação

### L1 — P1: identificação de pessoa estrangeira perde letras

**Situação:** ✅ Corrigido em `77ce34b`.

O diálogo e o construtor final removem todos os caracteres não numéricos de `niPessoa`, inclusive quando `tipoPessoaId = PE`. A documentação permite identificação estrangeira textual e o próprio exemplo oficial utiliza letras.

**Reprodução:** o identificador oficial `01234FG567890123` vira `01234567890123`. Um identificador `ABC-XYZ` vira uma string vazia, que também falha no mínimo de três caracteres do schema. Ambos os comportamentos foram reproduzidos.

**Referências:** planilha `Licitação!D45:I47`; exemplo `docs/tcesp/licitacao-20261015/licitacao-exemplo.json`; `lib/features/licitacao/widgets/licitante_dialog.dart:69`; `lib/features/licitacao/pages/licitacao_form_page.dart:282`.

**Adequação:** preservar identificadores de PE e normalizar documentos nacionais de acordo com o tipo informado.

### L2 — P1: fonte de recurso é exigida sem declaração de recursos

**Situação:** ✅ Corrigido em `77ce34b`. O código 99 foi removido do app, seguindo o schema.

`_enviar` exige uma fonte em qualquer situação. A planilha v04 exige pelo menos uma somente quando `declaracaoRecursosContratacao = true`. O histórico registra essa alteração em 19/08/2026.

**Reprodução:** com declaração falsa e nenhuma fonte, o construtor gera JSON aceito pelo schema, mas o formulário impede o envio. Escolher o código 99 para contornar o bloqueio introduz outra divergência: o código aparece na planilha e na aplicação, mas está ausente do enum do schema.

**Referências:** planilha `Alterações!A7:C7`, `Licitação!D29:G30` e `Fonte de Recurso!A21:C21`; `lib/features/licitacao/pages/licitacao_form_page.dart:435`; `lib/features/licitacao/domain/licitacao_domain.dart`, constante `kFonteRecurso`.

**Adequação:** condicionar a exigência à declaração. Tratar a divergência do código 99 sem presumir que o servidor aceita o enum da planilha.

### L3 — P2: nome do licitante continua limitado a 50 caracteres

**Situação:** ✅ Corrigido em `118d2a1`.

O schema novo permite 100 caracteres, mas o diálogo mantém `maxLength: 50`. A limitação é relevante sobretudo para pessoas estrangeiras, cujo nome é obrigatório. Uma razão social de 75 caracteres passou na validação do schema na sonda, mas excede o limite do campo manual.

**Referências:** schema da licitação, `properties.itens.items.properties.licitantes.items.properties.nomeRazaoSocial.maxLength`; `lib/features/licitacao/widgets/licitante_dialog.dart:131`.

**Adequação:** atualizar o campo para 100 caracteres.

### L4 — P2: garantia e índice “Outro” podem ficar incompletos

**Situação:** ✅ Corrigido em `118d2a1`.

O percentual de garantia aceita vazio mesmo quando `exigenciaGarantiaLicitantes = 1`; nesse caso o construtor omite `percentualValor`. A planilha o exige nessa condição. Para índice econômico tipo 8, o diálogo aceita salvar sem nome: o código apenas deixa de incluir `nomeIndice` quando ele tem menos de três caracteres.

**Referências:** planilha `Licitação!D20:G21` e `Licitação!D34:G36`; `lib/features/licitacao/pages/licitacao_form_page.dart:1436` e `:711`.

**Adequação:** tornar ambos os preenchimentos obrigatórios nas respectivas condições, com validação também sobre o documento final.

### L5 — P2: validação final dos itens não cobre as regras da planilha

**Situação:** ✅ Corrigido em `c2d8536`.

O envio verifica se existe algum item, mas não confere o conjunto inteiro contra o edital. Não bloqueia números duplicados, itens ausentes do edital ou a falta de itens que já constavam nele. O resumo pode exibir alertas, mas não constitui uma condição de envio.

Também faltam verificações finais sobre licitantes duplicados por `(tipoPessoaId, niPessoa)`, presença de licitantes nas modalidades/situações exigidas e quantidade de vencedores, considerando as exceções de cota reservada e SRP. O diálogo permite lista vazia de licitantes sem conhecer modalidade ou SRP.

**Referências:** planilha `Licitação!D37:J50`; `lib/features/licitacao/pages/licitacao_form_page.dart:429`, `:451` e `:950`; `lib/features/licitacao/widgets/item_licitacao_dialog.dart:120`.

**Adequação:** validar os itens e licitantes em conjunto antes do envio, inclusive os provenientes de importação.

### L6 — P2: datas dos itens não seguem todas as condições documentadas

**Situação:** ✅ Corrigido em `c2d8536`.

`dataSituacaoItem` é validada apenas como não nula e utiliza o seletor geral de 1950 a 2100. A planilha limita a data entre hoje menos 30 anos e a data da prestação. Além disso, o diálogo exige `dataOrcamento` conforme `tipoOrcamento != 0`, enquanto a planilha exige a data sempre que `valor` estiver preenchido. Com tipo 0, ainda é possível preencher valor e deixar a data vazia.

**Referências:** planilha `Licitação!D39:I42`; `lib/features/licitacao/widgets/item_licitacao_dialog.dart:194` e `:224`; `lib/shared/widgets/audesp_date_picker_field.dart:59`.

**Adequação:** aplicar os limites de data e vincular a exigência da data do orçamento ao valor efetivamente enviado.

### L7 — P2: rótulo de condução da contratação altera o significado do campo

**Situação:** ✅ Corrigido em `118d2a1`. O rótulo segue a descrição do schema.

O campo aparece como “Contratação Conduzida por Órgão Externo”. A planilha pergunta se houve condução por agente de contratação ou comissão, sem restringir a um órgão externo. O usuário pode deixar falso em uma contratação conduzida por agente da própria entidade e, consequentemente, não informar os CPFs correspondentes.

**Referências:** planilha `Licitação!D31:I32`; `lib/features/licitacao/pages/licitacao_form_page.dart:1520`.

**Adequação:** ajustar o rótulo ao significado oficial do campo.

## 3. Ajuste

### A1 — P1: editais SRP são excluídos do vínculo do ajuste

**Situação:** ✅ Corrigido em `c7f9d92`. O seletor de atas também passou a listar apenas as atas do edital escolhido.

A inicialização mantém apenas editais enviados com `!e.isSrp`. A seleção prévia repete a restrição. A documentação prevê expressamente ajustes vinculados a SRP e exige `codigoAta` nesses casos.

**Impacto:** um edital SRP corretamente cadastrado não pode ser selecionado para formar seu ajuste. Paralelamente, o seletor de atas lista todas as atas enviadas, sem restringi-las ao edital escolhido, permitindo montar vínculos inconsistentes.

**Referências:** planilha `Ajuste!C12:I16`; `lib/features/ajuste/pages/ajuste_form_page.dart:173`, `:198` e `:1148`.

**Adequação:** permitir o vínculo SRP, exigir a ata quando aplicável e filtrar as atas pela origem correta.

### A2 — P1: vigência apenas em meses é bloqueada

**Situação:** ✅ Corrigido em `77ce34b`.

O formulário e `_enviar` exigem início e fim da vigência em qualquer situação. A planilha permite, para os tipos de contrato nela especificados, informar `vigenciaMeses` quando ainda não há data inicial. O schema novo retirou as duas datas da lista de campos obrigatórios.

**Reprodução:** tipo 1 com vigência de 12 meses e sem datas é bloqueado pela interface. Há uma segunda adequação necessária no construtor: ele escreve `""` nas datas ausentes. Na sonda, esses campos causaram dois erros de formato; omitindo-os, o documento com `vigenciaMeses` passou no schema.

**Referências:** planilha `Ajuste!C39:I41`; schema do ajuste, `required`; `lib/features/ajuste/pages/ajuste_form_page.dart:375`, `:556`, `:1730` e `:1741`.

**Adequação:** implementar a alternativa entre datas e meses e omitir datas não informadas, conforme as condições documentadas.

### A3 — P1: código de contrato local é recusado

**Situação:** ✅ Corrigido em `c7f9d92`. Quando o edital é "Sem PNCP", o contrato aceita código local (até 25 caracteres); com edital no PNCP, mantém-se o ID PNCP.

A planilha pede o número de controle PNCP quando a entidade efetuou a publicação por esse portal. O schema aceita uma string com até 25 caracteres e o exemplo oficial utiliza `202304567`. A aplicação exige sempre 25 dígitos com marcador 2 na posição 15, inclusive para salvar rascunho.

**Reprodução:** `AjusteRules.validarCodigoContrato('202304567')` retorna “ID do Contrato PNCP incompleto (25 dígitos)”, embora o exemplo passe no schema.

**Referências:** planilha `Ajuste!C14:H14`; exemplo do ajuste; `lib/features/ajuste/domain/ajuste_rules.dart:50`; `lib/features/ajuste/pages/ajuste_form_page.dart:445` e `:1201`.

**Adequação:** aceitar código local quando aplicável e usar a validação PNCP somente para identificadores PNCP.

### A4 — P2: adesão a contratação externa depende indevidamente de edital local

**Situação:** ✅ Corrigido em `c2d8536` e `fe7820f`. Na adesão, os IDs PNCP de contratação e ata são digitados e o vínculo com um edital local é opcional; a migração v12 tornou `ajustes.edital_id` anulável.

Mesmo marcando adesão/participação e gerenciadora não jurisdicionada, o formulário exige selecionar um edital local enviado. O código do edital é preenchido a partir dessa seleção e não há entrada independente para o identificador da contratação externa. A planilha prevê esse caso com consulta ao PNCP, sem exigir que a própria entidade tenha prestado o edital gerenciado por outra entidade.

**Referências:** planilha `Ajuste!C7:I16`; `lib/features/ajuste/pages/ajuste_form_page.dart:170`, `:437`, `:521` e `:1128`.

**Adequação:** separar a escolha de origem local do preenchimento da contratação gerenciada externamente.

### A5 — P2: categoria e objeto do contrato são independentes

**Situação:** ✅ Corrigido em `c2d8536`.

Os dois seletores oferecem todos os códigos e validam somente a presença da seleção. A planilha exige a correspondência da tabela de objetos. Por exemplo, categoria 2, Compras, com objeto 28, Serviços de saúde, é admitida pela interface, apesar de o objeto 28 corresponder à categoria 10.

**Referências:** planilha `Ajuste!C42:H42` e aba `Tipo objeto do Contrato`; `lib/features/ajuste/pages/ajuste_form_page.dart:1443` e `:1627`.

**Adequação:** filtrar ou validar os objetos permitidos para cada categoria.

### A6 — P2: limites de campos do contrato não são aplicados

**Situação:** ✅ Corrigido em `118d2a1`. `codigoUnidade` não está ativo no formulário.

Campos como processo e número do contrato não possuem o limite de 50 caracteres previsto no schema. Nome do fornecedor e objeto também não aplicam, na tela, os respectivos limites de 100 e 5120 caracteres. O serviço não realiza uma validação do documento final contra o schema.

**Reprodução:** processo com 51 caracteres é serializado pelo construtor e falha em `maxLength` na validação do schema. A validação do formulário verifica somente se o processo está vazio.

**Referências:** schema do ajuste, propriedades `processo`, `numeroContratoEmpenho`, `nomeRazaoSocialFornecedor` e `objetoContrato`; `lib/features/ajuste/pages/ajuste_form_page.dart:1400`, `:1432`, `:1571` e `:1636`.

**Adequação:** aplicar os limites oficiais e conferir o documento completo antes de transmitir.

## 4. Ata

### T1 — P1: código local de ata é bloqueado

**Situação:** ✅ Corrigido em `c7f9d92`. Quando o edital é "Sem PNCP", a ata aceita código local (até 31 caracteres).

O schema permite uma string de até 31 caracteres e o exemplo oficial usa `123456-45SDF`. A planilha exige o identificador PNCP quando a publicação foi realizada nesse portal. A interface sempre usa campo numérico PNCP e exige pelo menos 31 dígitos.

**Reprodução:** o código local do exemplo permanece íntegro no construtor e passa no schema, mas não pode ser informado e enviado pelo campo atual. O caso PNCP com 31 dígitos também passou na sonda; a ampliação de tamanho já está atendida.

**Referências:** planilha `Ata!B11:H11`; exemplo e schema da ata; `lib/features/ata/pages/ata_form_page.dart:667` e `:676`; `lib/shared/widgets/audesp_pncp_field.dart:64`.

**Adequação:** permitir código local para as situações documentadas, mantendo a máscara e a validação específicas para PNCP.

### T2 — P2: itens da ata não são confrontados com a licitação

**Situação:** ✅ Corrigido em `c2d8536`. A mesma conferência vale para os itens do Ajuste; sem licitação local, o app apenas avisa.

A seleção de edital corretamente restringe os resultados a SRP enviado. Entretanto, a inclusão de itens verifica somente se o número é positivo e não está duplicado. Não consulta se ele consta na licitação correspondente, conforme exige a planilha, nem condiciona o fluxo à existência dessa licitação.

**Referências:** planilha `Ata!B9:H10`; `lib/features/ata/pages/ata_form_page.dart:94`, `:316` e `:525`.

**Adequação:** conferir os itens contra a licitação da origem selecionada, utilizando os dados locais disponíveis e a situação efetiva da prestação.

### T3 — P2: número da ata pode ultrapassar o tamanho do schema

**Situação:** ✅ Corrigido em `118d2a1`.

O schema limita `numeroAtaRegistroPreco` a 30 caracteres. O campo manual valida apenas preenchimento, sem limite de comprimento. Uma entrada de 31 caracteres foi serializada e reprovada pelo schema na sonda.

**Referências:** schema da ata, `properties.numeroAtaRegistroPreco.maxLength`; `lib/features/ata/pages/ata_form_page.dart:710`.

**Adequação:** aplicar o limite de 30 caracteres.

## Divergências dentro da documentação oficial

Estas questões impedem declarar uma única lista de domínios como plenamente consistente. Não é adequado adicionar todos os códigos da planilha ao aplicativo e presumir que serão aceitos pelo schema publicado.

| Questão | Planilha v04 | Schema / aplicação | Consequência |
| --- | --- | --- | --- |
| Amparos novos | `Amparo Legal!A176:C191` inclui 174–189. O histórico registra inclusão de códigos em 02/10/2026. | Ausentes do enum do schema de edital e das listas da aplicação. | O código 174, por exemplo, é documentado na planilha e rejeitado pelo schema. |
| Amparo 161 | Presente em `Amparo Legal!A163:C163`. | Presente na aplicação, ausente do enum do schema. | O aplicativo pode produzir uma seleção que não passa no schema publicado. |
| Fonte 99 | Presente em `Fonte de Recurso!A21:C21`, para ausência de declaração. | Presente na licitação da aplicação, ausente do enum do schema da licitação. | Reprovação de schema reproduzida. |
| Fonte 19 | Presente em `Fonte de Recurso!A12:C12`. | Ausente dos enums dos schemas de licitação e ajuste e das listas correspondentes da aplicação. | Outro domínio da planilha sem correspondência no contrato JSON. |
| Instrumento 4 | A tabela mantém o código em `Intrumento Convocatório!A6:C6`, mas o histórico registra sua exclusão em `Alterações!A33:C33`. | O schema de edital aceita 4; o código da aplicação o comenta como removido. | Há conflito até entre a tabela e o histórico da planilha. |
| Relação instrumento/modalidade | A tabela de instrumentos não relaciona explicitamente as modalidades 15–19. | O schema e a aplicação aceitam essas modalidades. | A regra de compatibilidade para os códigos novos precisa de esclarecimento. |

Também há diferença entre a regra específica de PDF da planilha, que admite exceção para inexigibilidade, e o YAML, que declara `arquivoPDF` obrigatório de forma geral.

## Transporte e funcionalidades adicionais

Os quatro serviços utilizam os endpoints previstos no YAML, `POST` com `multipart/form-data` e campo `documentoJSON`. A autenticação utiliza `x-authorization` no login e `Authorization: Bearer` nas demais requisições. O edital usa o nome de campo `arquivoPDF`. Não foi identificada mudança de caminho ou nome desses campos nos arquivos fornecidos.

A planilha também descreve documentos de Resultado de Itens, Atualização da Ata e Atualização do Contrato, além de outros documentos relacionados a contratos e obras. Os serviços atuais dos quatro módulos não implementam esses envios. Atualizar o status de um protocolo na aplicação não executa essas atualizações de conteúdo. Isso é uma lacuna de cobertura funcional, distinta da compatibilidade dos quatro cadastros iniciais. O YAML fornecido não documenta os endpoints desses documentos adicionais.

## Verificações realizadas

| Verificação | Resultado |
| --- | --- |
| `flutter test --no-pub --reporter expanded` | **212 testes passaram.** |
| `flutter analyze --no-pub` | **Nenhum problema encontrado.** |
| Quatro exemplos oficiais contra seus schemas | Todos passaram, com verificação de formatos. |
| Sonda dos construtores e preparação do envio | **15 cenários executados**, confirmando os resultados descritos acima. |
| JSON do edital após a limpeza do serviço | Sem `criterioJulgamentoId` na raiz, compatível com `additionalProperties: false`. |
| Identificador PNCP de ata com 31 dígitos | Aceito pelo schema na saída do construtor. |
| Vigência em meses | Aceita pelo schema ao omitir datas; o construtor atual produz datas vazias e a interface bloqueia o fluxo. |

Os testes existentes e a análise estática não cobrem todas as regras de negócio desses contratos. A validação do schema também não detecta, por exemplo, um critério de julgamento alterado para outro código válido, a correspondência entre documentos ou as condições que aparecem somente na planilha.

## Sequência recomendada de adequação

1. **Edital:** validar PDF/publicações e relações de campos, preservando os critérios dos itens. Resolver os domínios contraditórios antes de ampliar as listas.
2. **Licitação:** preservar identificações estrangeiras, corrigir a exigência de fontes, ampliar nomes para 100 e validar itens/campos condicionais no documento final.
3. **Ajuste:** corrigir os vínculos SRP/ata e a origem externa, permitir a alternativa de vigência em meses e códigos locais, validar categoria/objeto e limites.
4. **Ata:** permitir códigos locais e conferir a origem dos itens e o limite do número da ata.

Após as correções, acrescentar verificações dos JSONs efetivamente transmitidos contra os schemas e casos de negócio baseados na planilha. A confirmação de aceitação pelo servidor requer testes no ambiente Piloto com documentos e vínculos válidos.
