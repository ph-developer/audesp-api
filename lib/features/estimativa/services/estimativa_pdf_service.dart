import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/pdf_text_sanitizer.dart';
import '../../../shared/widgets/audesp_cpf_cnpj_field.dart';
import '../models/estimativa_model.dart';
import '../models/estimativa_item_model.dart';
import '../models/estimativa_fornecedor_model.dart';
import '../models/estimativa_orcamento_model.dart';

class EstimativaPdfService {
  static Future<void> gerarPdfEstimativa(
    BuildContext context,
    EstimativaModel estimativa,
  ) async {
    final fmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: estimativa.casasDecimais,
    );
    final pdf = pw.Document();
    final obsBancoPrecos = _getObservacaoBancoPrecos(estimativa);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Estimativa nº ${estimativa.numero}/${estimativa.ano}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            _buildInfoRow('Objeto:', estimativa.objeto),
            _buildInfoRow(
              'Tipo de Estimativa:',
              estimativa.tipoEstimativa == 'lote' ? 'Por Lote' : 'Por Item',
            ),
            _buildInfoRow(
              'Tipo de Cálculo:',
              _getCalculoLabel(
                estimativa.calculoGlobal,
                isLote: estimativa.tipoEstimativa == 'lote',
              ),
            ),
            _buildInfoRow(
              'Registro de Preços:',
              estimativa.registroPrecos ? 'Sim' : 'Não',
            ),
            if (estimativa.prazoVigencia.isNotEmpty)
              _buildInfoRow(
                estimativa.registroPrecos
                    ? 'Prazo de Vigência da ARP:'
                    : 'Prazo de Vigência do Contrato:',
                estimativa.registroPrecos
                    ? '${estimativa.prazoVigencia}, a partir de sua assinatura, podendo ser prorrogado por igual período, desde que comprovada a vantagem econômica dos preços registrados.'
                    : estimativa.temGarantia
                    ? '${estimativa.prazoVigencia}, a partir de sua assinatura, podendo ser prorrogado pelo prazo legal a critério da Administração, sendo que seus efeitos prorrogar-se-ão até o término do prazo de garantia.'
                    : '${estimativa.prazoVigencia}, a partir de sua assinatura, podendo ser prorrogado pelo prazo legal a critério da Administração.',
              ),
            if (estimativa.formaPagamento.isNotEmpty)
              _buildInfoRow('Forma de Pagamento:', estimativa.formaPagamento),
            if (estimativa.exclusividadeMeEpp != 'nao_aplica')
              _buildInfoRow(
                'Exclusividade ME/EPP:',
                _getExclusividadeLabel(estimativa),
              ),
            if (estimativa.fontesRecurso.isEmpty)
              _buildInfoRow('Fontes de Recurso/Aplicação:', 'A definir')
            else
              _buildInfoRow(
                'Fontes de Recurso/Aplicação:',
                estimativa.fontesRecurso
                    .map((e) {
                      var text = '${e['fonteRecurso']}/${e['aplicacao']}';
                      if ((e['descricao'] as String).isNotEmpty) {
                        text += ' (${e['descricao']})';
                      }
                      if ((e['reserva'] as String).isNotEmpty) {
                        text += ' - Reserva ${e['reserva']}';
                      }
                      if ((e['ficha'] as String).isNotEmpty) {
                        text += ' - Ficha ${e['ficha']}';
                      }
                      return text;
                    })
                    .join('; '),
              ),

            if (obsBancoPrecos != null) ...[
              pw.SizedBox(height: 6),
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  text: 'OBSERVAÇÃO: '.toPdfSafe(),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9.5,
                  ),
                  children: [
                    pw.TextSpan(
                      text: obsBancoPrecos.toPdfSafe(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.normal,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            pw.SizedBox(height: 20),

            // Itens ou Lotes
            if (estimativa.tipoEstimativa == 'lote')
              ..._buildLotes(estimativa, fmt)
            else
              ..._buildItens(
                estimativa.itens,
                estimativa.fornecedores,
                estimativa.calculoGlobal,
                fmt,
                exclusividadeGlobal: estimativa.exclusividadeMeEpp,
                casasDecimais: estimativa.casasDecimais,
              ),

            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'VALOR TOTAL ESTIMADO: ${fmt.format(estimativa.valorTotalGlobal)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Save File
    final pdfBytes = await pdf.save();
    final savedUri = await FilePicker.saveFile(
      dialogTitle: 'Salvar PDF Estimativa',
      fileName: 'estimativa_${estimativa.numero}_${estimativa.ano}.pdf',
      bytes: pdfBytes,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (savedUri == null) return; // User canceled

    final outputFile = savedUri.toFilePath();

    try {
      // Open file natively
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '""', outputFile]);
      } else if (Platform.isMacOS) {
        Process.run('open', [outputFile]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [outputFile]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir o PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static String _getCalculoLabel(String calc, {bool isLote = false}) {
    if (calc == 'min') return isLote ? 'Menor Preço (Unitário)' : 'Menor Preço';
    if (calc == 'min_global') return 'Menor Preço (Global)';
    if (calc == 'avg') return 'Média';
    if (calc == 'median') return 'Mediana';
    return calc;
  }

  static String _getExclusividadeLabel(EstimativaModel estimativa) {
    if (estimativa.exclusividadeMeEpp == 'exclusiva') {
      return 'Exclusiva para ME/EPP (conforme Art. 48, I, da LFC nº 123/2006)';
    }
    if (estimativa.exclusividadeMeEpp == 'reservada') {
      final tipoStr = estimativa.tipoEstimativa == 'lote' ? 'lotes' : 'itens';
      String base =
          'Com $tipoStr reservados para ME/EPP (conforme Art. 48, III, da LFC nº 123/2006)';
      final exclusivos = <int>[];

      if (estimativa.tipoEstimativa == 'lote') {
        exclusivos.addAll(
          estimativa.lotes.where((l) => l.exclusivoMeEpp).map((l) => l.numero),
        );
        if (exclusivos.isNotEmpty) {
          base += ' - Lotes: ${exclusivos.join(', ')}';
        }
      } else {
        exclusivos.addAll(
          estimativa.itens.where((i) => i.exclusivoMeEpp).map((i) => i.numero),
        );
        if (exclusivos.isNotEmpty) {
          base += ' - Itens: ${exclusivos.join(', ')}';
        }
      }
      return base;
    }
    return 'Não exclusiva para ME/EPP';
  }

  static String? _getObservacaoBancoPrecos(EstimativaModel estimativa) {
    final bancosDePrecos = estimativa.fornecedores
        .where((f) => f.bancoDePrecos && f.razaoSocial.trim().isNotEmpty)
        .toList();

    if (bancosDePrecos.isEmpty) return null;

    final nomes = bancosDePrecos.map((f) => f.razaoSocial.trim()).toList();
    final String nomesStr;
    if (nomes.length == 1) {
      nomesStr = nomes.first;
    } else if (nomes.length == 2) {
      nomesStr = '${nomes[0]} e ${nomes[1]}';
    } else {
      nomesStr =
          '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';
    }

    if (nomes.length == 1) {
      return 'A razão social $nomesStr, corresponde a plataforma de Banco de Preços, utilizada como ferramenta de pesquisa de preços praticados em contratações públicas. O valor indicado não representa cotação comercial apresentada pela referida empresa, mas valor resultante da pesquisa realizada na plataforma, apurado a partir de múltiplos registros de contratações públicas de órgãos e entidades da Administração Pública.';
    } else {
      return 'As razões sociais $nomesStr, correspondem a plataformas de Banco de Preços, utilizadas como ferramentas de pesquisa de preços praticados em contratações públicas. Os valores indicados não representam cotações comerciais apresentadas pelas referidas empresas, mas valores resultantes da pesquisa realizada nas plataformas, apurados a partir de múltiplos registros de contratações públicas de órgãos e entidades da Administração Pública.';
    }
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 170,
            child: pw.Text(
              label.toPdfSafe(),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.toPdfSafe(),
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildLotes(
    EstimativaModel estimativa,
    NumberFormat fmt,
  ) {
    final widgets = <pw.Widget>[];
    for (final lote in estimativa.lotes) {
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Lote ${lote.numero} - ${lote.descricao}'.toPdfSafe(),
                textAlign: pw.TextAlign.justify,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (estimativa.exclusividadeMeEpp == 'exclusiva' ||
                  (lote.exclusivoMeEpp &&
                      estimativa.exclusividadeMeEpp == 'reservada')) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  estimativa.exclusividadeMeEpp == 'exclusiva'
                      ? '(Exclusivo ME/EPP)'
                      : '(Reservado ME/EPP)',
                  style: pw.TextStyle(color: PdfColors.green700, fontSize: 10),
                ),
              ],
              pw.SizedBox(height: 10),
              ..._buildItens(
                lote.itens,
                estimativa.fornecedores,
                estimativa.calculoGlobal,
                fmt,
                isInsideLote: true,
                fornecedorVencedorId: estimativa.calculoGlobal == 'min_global'
                    ? lote.getFornecedorMenorPrecoGlobalId(
                        desclassificadosIds:
                            estimativa.fornecedoresDesclassificadosIds,
                      )
                    : null,
                exclusividadeGlobal: estimativa.exclusividadeMeEpp,
                casasDecimais: estimativa.casasDecimais,
              ),
              pw.SizedBox(height: 10),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Subtotal do Lote: ${fmt.format(lote.getValorTotal(estimativa.calculoGlobal, casasDecimais: estimativa.casasDecimais, desclassificadosIds: estimativa.fornecedoresDesclassificadosIds))}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  static List<pw.Widget> _buildItens(
    List<EstimativaItem> itens,
    List<EstimativaFornecedor> fornecedores,
    String globalCalculo,
    NumberFormat fmt, {
    bool isInsideLote = false,
    String? fornecedorVencedorId,
    String exclusividadeGlobal = 'nenhuma',
    int casasDecimais = 2,
  }) {
    final desclassificadosIds = fornecedores
        .where((f) => f.desclassificado)
        .map((f) => f.id)
        .toList();
    final widgets = <pw.Widget>[];

    for (final item in itens) {
      final isMensal = item.tipoFornecimento == 'mensal';
      final calculoUsado = globalCalculo;

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: isInsideLote
              ? pw.EdgeInsets.zero
              : const pw.EdgeInsets.all(8),
          decoration: isInsideLote
              ? null
              : pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'Item ${item.numero} - ${item.descricao}'.toPdfSafe(),
                      textAlign: pw.TextAlign.justify,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  if (!isInsideLote &&
                      (exclusividadeGlobal == 'exclusiva' ||
                          (item.exclusivoMeEpp &&
                              exclusividadeGlobal == 'reservada')))
                    pw.Text(
                      exclusividadeGlobal == 'exclusiva'
                          ? '(Exclusivo ME/EPP)'
                          : '(Reservado ME/EPP)',
                      style: pw.TextStyle(
                        color: PdfColors.green700,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Quantidade: ${item.quantidade} ${item.unidade} | '
                '${isMensal ? "Fornecimento: Mensal (${item.quantidadeMeses} meses)" : "Fornecimento: Único"} | '
                'Regra Ref.: ${_getCalculoLabel(calculoUsado, isLote: isInsideLote)}'.toPdfSafe(),
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 8),

              // Tabela de Orçamentos
              () {
                String? vencedorFornecedorId;
                double? minVal;
                double? maxVal;

                if (isInsideLote && globalCalculo == 'min_global') {
                  vencedorFornecedorId = fornecedorVencedorId;
                } else if (globalCalculo == 'min') {
                  final validOrcamentos = item.orcamentos
                      .where(
                        (e) =>
                            !desclassificadosIds.contains(e.fornecedorId) &&
                            e.valorUnitario > 0,
                      )
                      .toList();
                  if (validOrcamentos.isNotEmpty) {
                    minVal = validOrcamentos
                        .map((e) => e.valorUnitario)
                        .reduce((a, b) => a < b ? a : b);
                  }
                } else if (globalCalculo == 'desc') {
                  final validOrcamentos = item.orcamentos
                      .where(
                        (e) =>
                            !desclassificadosIds.contains(e.fornecedorId) &&
                            e.valorUnitario > 0,
                      )
                      .toList();
                  if (validOrcamentos.isNotEmpty) {
                    maxVal = validOrcamentos
                        .map((e) => e.valorUnitario)
                        .reduce((a, b) => a > b ? a : b);
                  }
                }

                final orcamentosOrdenados =
                    List<EstimativaOrcamento>.from(item.orcamentos)
                      ..sort(
                        (a, b) => a.valorUnitario.compareTo(b.valorUnitario),
                      );

                return pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FixedColumnWidth(95.0),
                    2: pw.FixedColumnWidth(60.0),
                    3: pw.FixedColumnWidth(75.0),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blueGrey800,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Razão Social',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'CPF/CNPJ',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Data',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Valor Unitário',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...orcamentosOrdenados.map((o) {
                      final fornecedor = fornecedores
                          .where((f) => f.id == o.fornecedorId)
                          .firstOrNull;

                      final isDesclassificado =
                          fornecedor?.desclassificado == true ||
                          desclassificadosIds.contains(o.fornecedorId);

                      final bool isVencedor;
                      if (isDesclassificado) {
                        isVencedor = false;
                      } else if (vencedorFornecedorId != null) {
                        isVencedor = o.fornecedorId == vencedorFornecedorId;
                      } else if (minVal != null) {
                        isVencedor = o.valorUnitario == minVal;
                      } else if (maxVal != null) {
                        isVencedor = o.valorUnitario == maxVal;
                      } else {
                        isVencedor = false;
                      }

                      final razaoSocial =
                          (fornecedor?.razaoSocial ?? '-').toPdfSafe();
                      pw.Widget razaoSocialWidget;
                      if (isDesclassificado) {
                        razaoSocialWidget = pw.RichText(
                          text: pw.TextSpan(
                            text: razaoSocial,
                            style: const pw.TextStyle(fontSize: 9),
                            children: [
                              pw.TextSpan(
                                text: ' (DESCLASSIFICADO)',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.red800,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        razaoSocialWidget = pw.Text(
                          razaoSocial,
                          style: const pw.TextStyle(fontSize: 9),
                        );
                      }

                      return pw.TableRow(
                        decoration: isVencedor
                            ? const pw.BoxDecoration(
                                color: PdfColor.fromInt(0xFFE8F5E9),
                              )
                            : null,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: razaoSocialWidget,
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              AudespCpfCnpjField.formatDocument(
                                fornecedor?.cnpj ?? '',
                              ),
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              (fornecedor?.data ?? '-').toPdfSafe(),
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              fmt.format(o.valorUnitario),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                );
              }(),

              pw.SizedBox(height: 8),

              // Totais do Item
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Valor de Referência Unitário: ${fmt.format(item.getValorReferenciaUnitario(globalCalculo, casasDecimais: casasDecimais, desclassificadosIds: desclassificadosIds, fornecedorVencedorId: fornecedorVencedorId))}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      if (isMensal)
                        pw.Text(
                          'Valor Estimado Mensal: ${fmt.format(item.getValorMensal(globalCalculo, casasDecimais: casasDecimais, desclassificadosIds: desclassificadosIds, fornecedorVencedorId: fornecedorVencedorId))}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      pw.Text(
                        'Valor Estimado Total: ${fmt.format(item.getValorTotal(globalCalculo, casasDecimais: casasDecimais, desclassificadosIds: desclassificadosIds, fornecedorVencedorId: fornecedorVencedorId))}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }
}
