import '../mappers/br_conectado_mapper.dart';
import '../mappers/csv_mappers.dart';
import '../models/licitacao_item_csv_model.dart';
import '_csv_utils.dart';
import 'portal_csv_parser.dart';

/// Parser para os arquivos CSV exportados pelo portal **BRConectado**.
///
/// Arquivos necessários (informar via [CsvFileKeys]):
/// - [CsvFileKeys.brRelatClassificacao] → `relatclassificacao.csv`
/// - [CsvFileKeys.brPropostas]          → `propostas.csv` (para coluna ME/EPP)
///
/// ### Colunas esperadas
///
/// **relatclassificacao.csv** (separador `;`)
/// ```
/// Lote/Item;Classificação;Razão Social;Valor Uni.;Valor Total;Situação;CNPJ;...
/// ```
///
/// **propostas.csv** (separador `;`)
/// ```
/// Lote/Item;Razão Social;CNPJ;Valor Uni.;Valor Total;Situação;Valor Total Estimado;ME/EPP
/// ```
///
/// Os arquivos costumam ser exportados em **Latin-1/ISO-8859-1**; a decodificação
/// é tratada automaticamente por [CsvUtils.decodeBytes].
class BrConectadoCsvParser implements PortalCsvParser {
  const BrConectadoCsvParser();

  @override
  List<LicitacaoItemCsvModel> parse(Map<String, List<int>> csvFiles) {
    final relatBytes = csvFiles[CsvFileKeys.brRelatClassificacao];
    final propostasBytes = csvFiles[CsvFileKeys.brPropostas];

    if (relatBytes == null) {
      throw const CsvParseException(
        'Arquivo "relatclassificacao.csv" não fornecido '
        '(chave: "${CsvFileKeys.brRelatClassificacao}").',
      );
    }
    if (propostasBytes == null) {
      throw const CsvParseException(
        'Arquivo "propostas.csv" não fornecido '
        '(chave: "${CsvFileKeys.brPropostas}").',
      );
    }

    final meEppMap = _buildMeEppMap(propostasBytes);
    return _parseRelatClassificacao(relatBytes, meEppMap);
  }

  // ---------------------------------------------------------------------------
  // Passo 1 — Constrói mapa (itemNum, cleanCnpj) → declaracaoMEouEPP a partir
  //           de propostas.csv.
  // ---------------------------------------------------------------------------

  Map<_ItemCnpjKey, int> _buildMeEppMap(List<int> bytes) {
    final rows = CsvUtils.parseCsv(
      CsvUtils.decodeBytes(bytes),
      delimiter: ';',
    );
    if (rows.isEmpty) {
      throw const CsvParseException('"propostas.csv" está vazio.');
    }

    final header = CsvUtils.buildHeaderIndex(rows.first);
    final result = <_ItemCnpjKey, int>{};

    for (final row in rows.skip(1)) {
      if (row.length <= 1) continue;
      try {
        final itemStr = CsvUtils.getField(row, header, 'lote/item');

        if (itemStr.trim().isEmpty) continue; // Ignora linhas sem número de item

        final cnpjStr = CsvUtils.getField(row, header, 'cnpj');
        final meStr = CsvUtils.getField(row, header, 'me/epp');

        final itemNum = BrConectadoMapper.parseNumeroItem(itemStr);
        final cleanCnpj = CsvMappers.cleanNiPessoa(cnpjStr);
        final key = _ItemCnpjKey(itemNum, cleanCnpj);

        result.putIfAbsent(key, () => CsvMappers.declaracaoMEouEPP(meStr));
      } catch (e) {
        throw CsvParseException('Erro ao ler linha de "propostas.csv": $e');
      }
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Passo 2 — Parseia relatclassificacao.csv, agrega licitantes por item e
  //           determina situacaoCompraItemId.
  // ---------------------------------------------------------------------------

  List<LicitacaoItemCsvModel> _parseRelatClassificacao(
    List<int> bytes,
    Map<_ItemCnpjKey, int> meEppMap,
  ) {
    final rows = CsvUtils.parseCsv(
      CsvUtils.decodeBytes(bytes),
      delimiter: ';',
    );
    if (rows.isEmpty) {
      throw const CsvParseException('"relatclassificacao.csv" está vazio.');
    }

    final header = CsvUtils.buildHeaderIndex(rows.first);
    // Mapa: numeroItem → (situacaoCompraItemId, lista de licitantes)
    final itensMapa = <int, _ItemAccumulator>{};

    for (final row in rows.skip(1)) {
      if (row.length <= 1) continue;
      try {
        final itemStr = CsvUtils.getField(row, header, 'lote/item');

        if (itemStr.trim().isEmpty) continue; // Ignora linhas sem número de item

        final razaoSocial = CsvUtils.getField(row, header, 'razão social');
        final cnpjStr = CsvUtils.getField(row, header, 'cnpj');
        final valorStr = CsvUtils.getField(row, header, 'valor uni.');
        final situacaoStr = CsvUtils.getField(row, header, 'situação');

        final itemNum = BrConectadoMapper.parseNumeroItem(itemStr);
        final cleanCnpj = CsvMappers.cleanNiPessoa(cnpjStr);
        final meEpp = meEppMap[_ItemCnpjKey(itemNum, cleanCnpj)] ?? 3;

        final licitante = LicitanteCsvModel(
          niPessoa: cleanCnpj,
          tipoPessoaId: CsvMappers.tipoPessoaFromCleanNi(cleanCnpj),
          nomeRazaoSocial: razaoSocial,
          declaracaoMEouEPP: meEpp,
          valorProposta: CsvMappers.parseBrCurrency(valorStr),
          resultadoHabilitacao:
              BrConectadoMapper.resultadoHabilitacao(situacaoStr),
        );

        final acc = itensMapa.putIfAbsent(
          itemNum,
          () => _ItemAccumulator(situacaoCompraItemId: 1),
        );
        acc.licitantes.add(licitante);

        // Herda o status mais "avançado" do item (e.g., ADJUDICADO prevalece).
        final novoStatus =
            BrConectadoMapper.situacaoCompraItemId(situacaoStr);
        if (novoStatus > acc.situacaoCompraItemId) {
          acc.situacaoCompraItemId = novoStatus;
        }
      } catch (e) {
        throw CsvParseException(
          'Erro ao ler linha de "relatclassificacao.csv": $e',
        );
      }
    }

    return itensMapa.entries
        .map((e) => LicitacaoItemCsvModel(
              numeroItem: e.key,
              situacaoCompraItemId: e.value.situacaoCompraItemId,
              licitantes: e.value.licitantes,
            ))
        .toList()
      ..sort((a, b) => a.numeroItem.compareTo(b.numeroItem));
  }
}

// ---------------------------------------------------------------------------
// Helpers internos
// ---------------------------------------------------------------------------

/// Chave composta para lookup no mapa de propostas.
class _ItemCnpjKey {
  final int itemNum;
  final String cleanCnpj;

  const _ItemCnpjKey(this.itemNum, this.cleanCnpj);

  @override
  bool operator ==(Object other) =>
      other is _ItemCnpjKey &&
      other.itemNum == itemNum &&
      other.cleanCnpj == cleanCnpj;

  @override
  int get hashCode => Object.hash(itemNum, cleanCnpj);
}

class _ItemAccumulator {
  int situacaoCompraItemId;
  final List<LicitanteCsvModel> licitantes = [];

  _ItemAccumulator({required this.situacaoCompraItemId});
}
