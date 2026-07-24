import 'dart:io';

import 'package:audesp_api/features/xsd_licitacao/models/xsd_licitacao_models.dart';
import 'package:audesp_api/features/xsd_licitacao/services/xsd_export_service.dart';
import 'package:audesp_api/features/xsd_licitacao/services/xsd_licitacao_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  test('NÃO1 usa descritor oficial, ordem e não cria lote fictício', () {
    final xml = XsdLicitacaoBuilder.build(
      source: _source(),
      profile: XsdLicitacaoProfile(
        situacaoData: DateTime(2026, 5, 2),
        julgamentoData: DateTime(2026, 5),
      ),
      createdAt: DateTime(2026, 7, 21),
    );
    final doc = XmlDocument.parse(xml);
    expect(
      _elementsByLocalName(doc, 'TipoDocumento').single.innerText,
      contains('MENOS-INTERNACIONAL'),
    );
    expect(
      _elementsByLocalName(doc, 'DataCriacaoXML').single.innerText,
      '2026-07-21',
    );
    expect(doc.findAllElements('Lote'), hasLength(1));
    expect(doc.findAllElements('Edital'), hasLength(1));
    expect(
      doc.descendants.whereType<XmlElement>().where(
        (element) => element.name.local.toUpperCase().startsWith('LRF'),
      ),
      isEmpty,
    );
  });

  test('NÃO3 inclui subcontratação em DadosLicitacao e fundamento único', () {
    final xml = XsdLicitacaoBuilder.build(
      source: _source(modalidade: 8, amparo: 18),
      profile: XsdLicitacaoProfile(
        finalizacaoProcessoData: DateTime(2026, 5, 2),
        fundamentoLegalCodigo: 18,
      ),
      createdAt: DateTime(2026, 7, 21),
    );
    final doc = XmlDocument.parse(xml);
    final dados = doc.findAllElements('DadosLicitacao').single;
    expect(dados.findElements('Subcontratacao').single.innerText, 'N');
    expect(doc.findAllElements('FundamentoLegal'), hasLength(1));
    expect(
      doc.findAllElements('DataFinalizacaoProcesso').single.innerText,
      '2026-05-02',
    );
  });

  test('rejeita caracteres fora de Latin-1 com o campo identificável', () {
    expect(
      () => XsdLicitacaoBuilder.ensureLatin1('Objeto 😀', field: 'Objeto'),
      throwsA(predicate((error) => error.toString().contains('Objeto'))),
    );
  });

  test('gera dados complementares de convênios e operação de crédito', () {
    final xml = XsdLicitacaoBuilder.build(
      source: _source(recursos: true),
      profile: XsdLicitacaoProfile(
        situacaoData: DateTime(2026, 5, 2),
        recursos: XsdRecursosProfile(
          declarados: true,
          valor: 1000,
          data: DateTime(2026, 3, 1),
          fontes: const [2, 5, 7],
          conveniosEstaduais: const [
            XsdConvenio(
              numero: 'EST-1',
              ano: 2026,
              valorRepasse: 400,
              valorContrapartida: 40,
            ),
          ],
          conveniosFederais: const [
            XsdConvenio(
              numero: 'FED-1',
              ano: 2025,
              valorRepasse: 300,
              valorContrapartida: 30,
            ),
          ],
          operacoesCredito: const [
            XsdOperacaoCredito(
              agenteFinanceiro: 'Banco',
              contratoNumero: 'FIN-10',
              contratoAno: 2026,
              valorRepasse: 230,
            ),
          ],
        ),
      ),
    );
    final doc = XmlDocument.parse(xml);

    final estadual = doc.findAllElements('ConvenioEstadualNum').single;
    expect(estadual.findElements('Numero').single.innerText, 'EST-1');
    expect(estadual.findElements('Ano').single.innerText, '2026');
    final federal = doc.findAllElements('ConvenioFederalNum').single;
    expect(federal.findElements('Numero').single.innerText, 'FED-1');
    expect(federal.findElements('Ano').single.innerText, '2025');
    expect(
      doc.findAllElements('ContratoFinanciamentoNum').single.innerText,
      'FIN-10',
    );
    expect(
      doc.findAllElements('RepasseContratoFinanciamentoValor').single.innerText,
      '230.00',
    );
  });

  test('exportador grava XML e Markdown sempre como par', () async {
    final temp = await Directory.systemTemp.createTemp('audesp_export_test_');
    addTearDown(() => temp.delete(recursive: true));
    final output = '${temp.path}${Platform.pathSeparator}teste.xml';
    final hashes = await const XsdExportService().writePair(
      selectedXmlPath: output,
      xml: '<?xml version="1.0" encoding="ISO-8859-1"?><x>ação</x>',
      markdown: '# ação',
    );
    expect(await File(output).exists(), isTrue);
    expect(await File(output.replaceFirst('.xml', '.md')).exists(), isTrue);
    expect(hashes.xml, hasLength(64));
    expect(hashes.markdown, hasLength(64));
  });

  test('exportador restaura o par anterior quando a auditoria falha', () async {
    final temp = await Directory.systemTemp.createTemp('audesp_rollback_test_');
    addTearDown(() => temp.delete(recursive: true));
    final xmlPath = '${temp.path}${Platform.pathSeparator}teste.xml';
    final mdPath = '${temp.path}${Platform.pathSeparator}teste.md';
    await File(xmlPath).writeAsString('xml anterior');
    await File(mdPath).writeAsString('md anterior');

    await expectLater(
      const XsdExportService().writePair(
        selectedXmlPath: xmlPath,
        xml: '<novo/>',
        markdown: '# novo',
        beforeFinalize: (_) async => throw StateError('auditoria indisponível'),
      ),
      throwsStateError,
    );
    expect(await File(xmlPath).readAsString(), 'xml anterior');
    expect(await File(mdPath).readAsString(), 'md anterior');
  });
}

Iterable<XmlElement> _elementsByLocalName(XmlDocument document, String name) =>
    document.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == name,
    );

XsdLicitacaoSource _source({
  int modalidade = 6,
  int? amparo,
  bool recursos = false,
}) => XsdLicitacaoSource(
  modalidadeId: modalidade,
  srp: false,
  carona: false,
  municipio: '0000',
  entidade: '000000',
  codigoEdital: '1234567890123410001232026',
  numeroCompra: '1',
  anoCompra: 2026,
  numeroProcesso: '1',
  objeto: 'Aquisição de material',
  criterioJulgamentoId: 1,
  amparoLegalId: amparo,
  editalData: DateTime(2026, 4),
  situacaoData: DateTime(2026, 5, 2),
  quitacaoTributosFederais: false,
  quitacaoTributosEstaduais: false,
  quitacaoTributosMunicipais: false,
  declaracaoRecursos: recursos,
  fontesRecursos: recursos ? const [2, 5, 7] : const [],
  parecerTecnicoJuridico: false,
  entregaPropostaData: DateTime(2026, 4, 20),
  aberturaData: DateTime(2026, 4, 21),
  itens: [
    {
      'numeroItem': 1,
      'descricao': 'Material',
      'quantidade': 2,
      'unidade': 'UN',
      'valorUnitarioEstimado': 100,
      'situacaoCompraItemId': 2,
      'licitantes': [
        {
          'niPessoa': '12345678901',
          'nomeRazaoSocial': 'Fornecedor',
          'resultadoHabilitacao': 1,
          'valor': 150,
          'tipoProposta': 1,
          'tipoValor': 'M',
          'declaracaoMEouEPP': 3,
        },
      ],
    },
  ],
  editalJson: const {'itensCompra': []},
  licitacaoJson: const {},
);
