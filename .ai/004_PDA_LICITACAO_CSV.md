### 🛠️ PDA: Importação de Itens e Licitantes de CSV (BLL e BRConectado) para Licitação

**Contexto:**
Precisamos implementar uma funcionalidade na feature de `Licitação` para importar os dados de itens, licitantes e propostas através de arquivos CSV exportados de dois portais de compras diferentes: **BLL** e **BRConectado**. O objetivo é preencher os dados exigidos pelo Tribunal de Contas (Audesp) automaticamente, reduzindo o trabalho manual.

**Arquitetura e Padrões:**
* Crie uma abstração/interface (ex: `CsvImportStrategy` ou `PortalCsvParser`) para padronizar a extração.
* Implemente duas classes concretas: `BllCsvParser` e `BrConectadoCsvParser`.
* Crie uma camada de *Mappers* para traduzir os status em texto dos portais para os inteiros exigidos pelo Domínio PNCP/Audesp.
* O output dos parsers deve ser uma lista de models internos da nossa aplicação (ex: `LicitacaoItemModel` contendo seus `LicitanteModel`).

**Regras de Negócio e Mapeamento - Portal BLL:**
1. **numeroItem**: Extrair da coluna `Item` (presente em `Classificacao com itens.csv` e `Relatorio de vencedores.csv`).
2. **situacaoCompraItemId**: Mapear a coluna `Status` do `Relatorio de vencedores.csv`. Exemplo: "HOMOLOGADO" -> `2`.
3. **tipoPessoaId e niPessoa**:
   * O documento vem da coluna `Documento` (`Informacoes dos participantes.csv` ou `Classificacao com itens.csv`).
   * *Regra:* Limpar a string (remover pontos/traços). Se length == 14, `tipoPessoaId` = 'PJ'. Se length == 11, 'PF'.
4. **nomeRazaoSocial**: Extrair da coluna `Participante` ou `Razão Social`.
5. **declaracaoMEouEPP**: A coluna `ME` traz "SIM" ou "NÃO".
   * *Regra:* Se "NÃO", mapear para `3`. Se "SIM", mapear temporariamente para `1` (ME) [Deixe um comentário TODO no código para a UI permitir ao usuário corrigir se for EPP (2)].
6. **Valor da Proposta**: Extrair da coluna `Lance`.
7. **resultadoHabilitacao**: Basear na `Posição` e na coluna `Classificado`.
   * `Posição` == 1 -> `1` (Classificado Vencedor).
   * `Posição` > 1 e `Classificado` == "SIM" -> `2` (Classificado).
   * `Classificado` == "NÃO" -> `4` (Desclassificado).

**Regras de Negócio e Mapeamento - Portal BRConectado:**
1. **numeroItem**: Extrair da coluna `Lote/Item` ou `Número` (ex: `vencedores.csv`, `propostas.csv`).
   * *Regra:* Fazer o parse da string "001" para inteiro `1`.
2. **situacaoCompraItemId**: Extrair da coluna `Situação`.
   * *Regra:* "ADJUDICADO" ou similar -> `2` (Homologado).
3. **niPessoa**: Extrair da coluna `CNPJ` e **limpar a máscara** (remover `.`, `/`, `-`).
4. **tipoPessoaId**: Avaliar o tamanho após limpar a máscara (geralmente será 14, resultando em 'PJ').
5. **nomeRazaoSocial**: Extrair de `Razão Social`.
6. **declaracaoMEouEPP**: A coluna `ME/EPP` (`propostas.csv`) traz "SIM" ou "NÃO". Seguir a mesma regra de conversão do BLL (NÃO = 3; SIM = 1 com TODO).
7. **Valor da Proposta**: Extrair da coluna `Valor Uni.` (atenção ao parse de valores monetários no formato brasileiro: vírgula para decimal, ponto para milhar).
8. **resultadoHabilitacao**: Traduzir a coluna `Situação` (`relatclassificacao.csv` / `propostas.csv`).
   * "ADJUDICADO" -> `1`.
   * "Classificada/Habilitada" -> `2`.
   * "DESCLASSIFICADO" -> `4`.

**Requisitos Técnicos:**
* Lide com encondings diferentes (arquivos CSV brasileiros costumam vir em latin1/ISO-8859-1 ou UTF-8 com BOM). O parser não pode quebrar a acentuação.
* Trate exceções (como arquivos mal formatados ou colunas ausentes) lançando erros amigáveis que a UI possa exibir.
* Escreva testes unitários cobrindo as funções de mapeamento (Mappers) e as regex/limpezas de string.