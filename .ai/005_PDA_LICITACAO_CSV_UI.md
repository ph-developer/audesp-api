### 🛠️ PDA: Integração da Importação de CSV na UI de Licitação

**Contexto:**
Os parsers de CSV (BLL e BRConectado) já estão prontos e testados em `lib/features/licitacao/csv/`. Agora precisamos conectar isso na interface de usuário (UI) da criação/edição de Licitação, permitindo que o usuário faça o upload dos arquivos e popule a lista de itens e licitantes automaticamente.

**1. Criação do Widget `PortalImportDialog`:**
Crie um dialog moderno (`AlertDialog` ou custom dialog) em `lib/features/licitacao/widgets/portal_import_dialog.dart`.
* **Estado Interno:** Deve controlar qual portal está selecionado (`enum PortalType { bll, brConectado }`) e armazenar as referências/bytes dos arquivos selecionados pelo usuário.
* **UI Dinâmica:** * Um seletor (SegmentedButton ou Radio) para escolher o Portal.
  * Botões de "Selecionar Arquivo" que mudam de texto dependendo do portal.
    * Para **BLL**, mostre botões para selecionar: 1) Classificação com itens e 2) Relatório de vencedores.
    * Para **BRConectado**, mostre botões para: 1) Relatório de Classificação e 2) Propostas.
  * Utilize o package `file_picker` (ou a abstração equivalente já existente no projeto) para ler os arquivos como bytes (`List<int>`).
* **Ação de Importar:** Um botão "Importar" que executa o parser correspondente (`BllCsvParser` ou `BrConectadoCsvParser`) passando o mapa de bytes com as chaves definidas em `CsvFileKeys`.

**2. Integração com o Estado da Licitação (Riverpod):**
* No controller/provider que gerencia o formulário de Licitação (provavelmente em `licitacao_providers.dart` ou no notifier do form), crie um método `importarItensDoCsv(List<LicitacaoItemCsvModel> itensParsed)`.
* Este método deve mapear o `LicitacaoItemCsvModel` e seus `LicitanteCsvModel` para as entidades reais do formulário (ex: convertendo os inteiros de domínio, populando os campos e adicionando à lista de itens do form).
* *Regra de Merge:* Se já houver itens no formulário, anexe os novos ou substitua (pergunte ao usuário via um modal rápido se deseja limpar os itens atuais, ou apenas limpe antes de injetar se for o padrão).

**3. Atualização da UI do Formulário (`licitacao_form_page.dart` ou similar):**
* Adicione um botão "Importar do Portal 📥" na seção de Itens.
* Ao clicar, abre o `PortalImportDialog`.
* Ao concluir a importação com sucesso, feche o dialog e exiba um `SnackBar` de sucesso.
* **Importante:** O SnackBar deve conter a mensagem de aviso: *"Itens importados com sucesso! Verifique os enquadramentos de ME/EPP dos licitantes, pois os portais não os diferenciam."*

**4. Tratamento de Erros:**
* Envolva a chamada do `parser.parse()` em um bloco `try/catch`. 
* Se capturar um `CsvParseException` ou qualquer outro erro, mostre a mensagem de erro na própria UI do Dialog (ex: texto em vermelho) para o usuário saber que enviou o arquivo errado ou faltando.

**Notas Adicionais para o Dev:**
* Mantenha o design alinhado com o `AppTheme`.
* Evite travar a main thread se a conversão do CSV for pesada (use `compute` ou `Isolate.run` se achar necessário, embora os CSVs costumem ser pequenos).