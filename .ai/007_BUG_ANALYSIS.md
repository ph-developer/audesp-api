# Relatório de Bugs e Pontos de Atenção - Integração AUDESP

## 📄 Módulo 1: Edital (Fase 4)

### 1. Validação Ausente nas Datas de Proposta
* **Onde:** `edital_form_page.dart`
* **Erro:** Os campos `dataAberturaProposta` e `dataEncerramentoProposta` são visualmente indicados como obrigatórios no frontend, mas falta o `validator` no `TextFormField`.
* **Regra do Schema:** São campos obrigatórios quando `tipoInstrumentoConvocatorioId` for `1` (Edital) ou `2` (Aviso de Contratação Direta).
* **Solução:** Adicionar a condição de obrigatoriedade no `validator` desses campos atrelada ao valor de `_tipoInstrumento`.

### 2. Precisão de 4 Casas Decimais nos Itens
* **Onde:** `item_compra_dialog.dart` (submit/geração do JSON)
* **Erro:** O frontend pega o `double` direto do input. Valores com dízimas ou que não respeitem exatamente o formato exigido podem gerar rejeição por formatação inválida.
* **Regra do Schema:** `quantidade`, `valorUnitarioEstimado` e `valorTotal` exigem precisão exata de 4 dígitos decimais (Ex: 100.0000).
* **Solução:** No método `_confirm` ou antes do envio do JSON, formatar os valores aplicando `.toStringAsFixed(4)` e convertendo de volta para número, ou tratar a string no backend.

### 3. Sincronia de IDs do Amparo Legal
* **Onde:** `_AmparoLegalField` em `edital_form_page.dart`
* **Ponto de Atenção:** O schema possui uma lista exaustiva e bem esburacada de códigos de Amparo Legal (1 ao 1020). 
* **Solução:** Certificar-se de que a constante `kAmparosLegaisValidos` utilizada no validador do frontend possui todos os códigos listados no array `enum` do `edital_schema.json`.

### 4. Bloqueio de Retificação do SRP (Regra de Negócio)
* **Onde:** Formatação geral do campo `srp` (`edital_form_page.dart`)
* **Regra da Planilha:** Não é permitido retificar a flag `srp` se já existir uma Licitação cadastrada vinculada a este edital.
* **Solução:** Travar o campo de edição no frontend caso a entidade `Edital` sendo carregada já possua dependentes (Licitações) no banco.

---

## ⚖️ Módulo 2: Licitação (Fase 5)

### 1. Submit Permitindo "Fontes de Recurso" Vazia
* **Onde:** Método `_enviar` em `licitacao_form_page.dart`
* **Erro:** O formulário permite o envio mesmo se o array `_fontesRecurso` estiver vazio.
* **Regra do Schema:** O campo `fonteRecursosContratacao` tem a propriedade `"minItems": 1`.
* **Solução:** Adicionar checagem `if (_fontesRecurso.isEmpty)` no método de envio bloqueando e alertando o usuário.

### 2. Submit Permitindo "Condutores" Vazio
* **Onde:** Método `_enviar` em `licitacao_form_page.dart`
* **Erro:** Se o switch `_contratacaoConduzida` for `true`, o sistema não exige que a lista `_cpfsCondutores` seja populada.
* **Regra do Schema:** Exige array de objetos de CPF caso a contratação seja conduzida.
* **Solução:** Adicionar checagem `if (_contratacaoConduzida && _cpfsCondutores.isEmpty)` bloqueando o envio.

### 3. Submit Permitindo "Índices Econômicos" Vazio
* **Onde:** Método `_enviar` em `licitacao_form_page.dart`
* **Erro:** Semelhante aos itens anteriores, marcar `_exigenciaIndicesEconomicos` como `1` não obriga visualmente a lista a ter itens.
* **Solução:** Adicionar validação cruzada no submit para exigir tamanho > 0 no array `_indicesEconomicos` caso exigência seja verdadeira.

### 4. Validação Condicional Ausente: Orçamento de Itens
* **Onde:** `item_licitacao_dialog.dart`
* **Erro:** O validador de `_valorCtrl` e `_dataOrcamentoCtrl` valida apenas o formato da string/double, mas não a obrigatoriedade.
* **Regra da Planilha:** `valor` e `dataOrcamento` são OBRIGATÓRIOS se o campo `tipoOrcamento` for diferente de `0` (Não).
* **Solução:** Atualizar o validator dos dois campos para checar `if (_tipoOrcamento != 0 && (v == null || v.isEmpty)) return 'Obrigatório';`.

### 5. Validação Condicional Ausente: Valor do Vencedor
* **Onde:** `licitante_dialog.dart`
* **Erro:** É possível adicionar um licitante com resultado `Vencedor` sem preencher o campo de valor da proposta.
* **Regra da Planilha:** O campo `valor` é obrigatório se o resultado da habilitação for Classificado Vencedor (`1`) ou Classificado (`2`).
* **Solução:** No validator do campo de valor, incluir verificação: `if ((_resultadoHabilitacao == 1 || _resultadoHabilitacao == 2) && (v == null || v.isEmpty)) return 'Obrigatório para classificados';`.

# Relatório de Bugs e Inconsistências - Integração AUDESP (Módulo 3: Ata)

## 🚨 Inconsistências Críticas (AUDESP Documentação)

### 1. O Paradoxo do Tamanho do `codigoAta`
* **Onde:** Validação de caracteres do Código da Ata.
* **O Erro:** A documentação em markdown (Regras de Negócio) afirma categoricamente que o campo `codigoAta` deve ter **31 caracteres** (sendo 25 da contratação no PNCP + 6 da ata). Porém, o `ata_schema.json` limita o campo com `"maxLength": 30`.
* **Impacto:** Se o PNCP realmente gerar uma string de 31 caracteres, o payload vai falhar na validação do schema do próprio AUDESP antes mesmo de processar. 
* **Solução recomendada:** Travar o limite no frontend em 30 caracteres temporariamente para respeitar o Schema JSON (que é o gatekeeper da API), e levantar um chamado urgente com o suporte do AUDESP perguntando qual é a regra definitiva.

### 2. O `codigoEdital` Esquizofrênico
* **Onde:** Validação de caracteres do Código do Edital vinculado.
* **O Erro:** Na tabela de regras da Ata, o limite informado para `codigoEdital` é de **25 caracteres**. No entanto, o schema da Ata define esse mesmo campo com `"maxLength": 30`.
* **Impacto:** Menor risco de quebra na API, mas risco alto de inconsistência de dados.
* **Solução recomendada:** Como no Módulo 1 (Edital) o limite já está cravado em 25, mantenha o `maxLength: 25` no `TextFormField` do `ata_form_page.dart` para garantir integridade referencial. Ignorar a folga do schema.

### 3. Validação de Duplicidade no Array de Itens
* **Onde:** Inserção de itens na lista `numeroItem`.
* **O Erro:** O schema exige apenas que o array tenha pelo menos um item (`"minItems": 1`), mas a regra de negócio (Markdown) impõe: **"Não permitir duplicidade de item"**.
* **Solução recomendada:** Certifique-se de que a lógica no formulário de Ata impede que o usuário adicione o mesmo número de item duas vezes. Faça a validação na hora do "submit" local do item ou utilize um `Set` em Dart para armazenar os itens antes de converter para lista no JSON final.

### 4. Limites de Ano de Compra e Ata
* **Onde:** Campos `anoCompra` e `anoAta`.
* **O Erro:** Diferente do Edital (onde você validou entre 1970 e 2099), o schema da Ata é bem específico: os anos devem respeitar `"minimum": 1950` e `"maximum": 2100`. A tabela diz que ambos são obrigatórios.
* **Solução recomendada:** Ajustar os `validators` dos campos de ano no frontend para retornar erro caso o valor fuja do range 1950-2100.

# Relatório de Bugs e Inconsistências - Integração AUDESP (Módulo 4: Ajuste)

## 🚨 Inconsistências Críticas (AUDESP Documentação vs Schema)

### 1. O Paradoxo da Vigência (Datas vs Meses)
* **Onde:** Campos `dataVigenciaInicio`, `dataVigenciaFim` e `vigenciaMeses`.
* **O Erro:** A tabela de regras (Markdown) diz que `dataVigenciaInicio` é obrigatório APENAS se `vigenciaMeses` não for preenchido. **PORÉM**, no `ajuste-schema-v2.json`, os campos `dataVigenciaInicio` e `dataVigenciaFim` estão cravados na raiz do array `"required"` do JSON!
* **Impacto:** Se o usuário preencher apenas `vigenciaMeses` (como a regra de negócio permite) e você não enviar as datas, a API vai retornar erro 400 por quebra de schema.
* **Solução Recomendada:** Até o suporte do AUDESP esclarecer essa cagada, obrigue o preenchimento de `dataVigenciaInicio` e `dataVigenciaFim` no frontend (`ajuste_form_page.dart`) para todos os casos, garantindo que o JSON passe no validador.

---

## 🛠️ Pontos de Atenção para o Frontend (`ajuste_form_page.dart`)

### 2. Formatação Exata de 4 Casas Decimais (Validação Estrita)
* **Onde:** Campos `valorInicial`, `valorParcela`, `valorGlobal` e `valorAcumulado`.
* **A Regra:** O schema JSON é brutal aqui. Ele usa a propriedade `"multipleOf": 0.0001` para esses campos. Isso significa que se o Dart enviar um double tipo `100.0` ou `100.12345`, a API vai rejeitar.
* **Solução Recomendada:** No método `_submit` ou na geração do payload, capture esses valores numéricos e force a formatação antes de serializar: `double.parse(valor.toStringAsFixed(4))`.

### 3. Validação de Arrays Obrigatórios (Prevenção de Envio Vazio)
* **Onde:** Validação de formulário antes do envio.
* **A Regra:** O schema exige que `fonteRecursosContratacao` e `itens` estejam no payload. A tabela complementa dizendo "Obrigatório ao menos um".
* **Solução Recomendada:** Assim como vimos no módulo de Licitação, adicione no método `_enviar()` verificações diretas:
  ```dart
  if (_fontesRecurso.isEmpty) {
    _showError('Selecione pelo menos uma Fonte de Recurso.');
    return;
  }
  if (_itens.isEmpty) {
    _showError('Adicione pelo menos um item.');
    return;
  }
  ```

### 4. Condicional Complexa do Campo `despesas`
* **Onde:** Regra de exibição e obrigatoriedade da Classificação Econômica da Despesa.
* **A Regra:** O markdown diz que `despesas` é obrigatório SE `tipoContratoId` = 7 (Empenho) **OU** se `receita` = false (Despesa) E o órgão for de tipos específicos (Prefeitura, Câmara, Autarquia, etc). Além disso, se for Empenho, deve informar apenas UMA despesa.
* **Solução Recomendada:** Criar um validador customizado robusto no botão de submit. Avalie o `_tipoContratoId` e o boolean `_receita`. Se a condição for atendida e a lista de despesas estiver vazia, bloqueie o envio. Se for empenho (7) e tiver mais de uma despesa na lista, bloqueie também.

### 5. Cascateamento do Licitante Estrangeiro (NiFornecedor)
* **Onde:** Campos de fornecedor (Principal e Subcontratado).
* **A Regra:** A validação do `niFornecedor` e `niFornecedorSubContratado` depende do tipo de pessoa (`PJ`, `PF` ou `PE`). Não há validação de formato de documento se for Pessoa Estrangeira (`PE`).
* **Solução Recomendada:** Certifique-se de que os `TextFormFields` de identificação de fornecedor desabilitem máscaras de CPF/CNPJ e validações de tamanho exato caso a opção `PE` esteja selecionada no dropdown.

# Referências
- docs\tabelas_organizadas.md
- docs\ajuste-schema-v2_0_0\ajuste-schema-v2.json
- docs\edital-v4-20260203\edital_schema.json
- docs\licitacao-v4\licitacao-schema-v4.json
- docs\ata_v1_0\ata_schema.json
- lib\features\edital
- lib\features\licitacao
- lib\features\ajuste
- lib\features\ata