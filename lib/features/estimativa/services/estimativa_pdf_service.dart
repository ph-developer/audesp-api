import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../shared/widgets/audesp_cpf_cnpj_field.dart';
import '../models/estimativa_model.dart';
import '../models/estimativa_item_model.dart';
import '../models/estimativa_fornecedor_model.dart';

class EstimativaPdfService {
  static final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  static Future<void> gerarPdfEstimativa(
    BuildContext context,
    EstimativaModel estimativa,
  ) async {
    final pdf = pw.Document();

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
              estimativa.calculoGlobal == 'min'
                  ? 'Menor Preço'
                  : estimativa.calculoGlobal == 'avg'
                  ? 'Média'
                  : 'Mediana',
            ),
            _buildInfoRow(
              'Registro de Preços:',
              estimativa.registroPrecos ? 'Sim' : 'Não',
            ),
            _buildInfoRow(
              'Garantia Exigida:',
              estimativa.temGarantia ? estimativa.periodoGarantia : 'Não',
            ),
            _buildInfoRow(
              estimativa.registroPrecos
                  ? 'Prazo de Vigência da ARP:'
                  : 'Prazo de Vigência do Contrato:',
              estimativa.registroPrecos
                  ? '${estimativa.prazoVigencia}, a partir de sua assinatura, podendo ser prorrogado por igual período, desde que comprovada a vantagem econômica dos preços registrados.'
                  : estimativa.temGarantia
                  ? '${estimativa.prazoVigencia}, a partir de sua assinatura, podendo ser prorrogado pelo prazo legal a critério da Administração, sendo que seus efeitos prorrogar-se-ão até o término da garantia dos equipamentos.'
                  : '${estimativa.prazoVigencia}, a partir de sua assinatura, podendo ser prorrogado pelo prazo legal a critério da Administração.',
            ),
            if (estimativa.formaPagamento.isNotEmpty)
              _buildInfoRow('Forma de Pagamento:', estimativa.formaPagamento),
            _buildInfoRow(
              'Exclusividade ME/EPP:',
              _getExclusividadeLabel(estimativa),
            ),
            if (estimativa.fontesRecurso.isNotEmpty)
              _buildInfoRow(
                'Fontes de Recurso/Aplicação:',
                estimativa.fontesRecurso.join('; '),
              ),

            pw.SizedBox(height: 20),

            // Itens ou Lotes
            if (estimativa.tipoEstimativa == 'lote')
              ..._buildLotes(estimativa)
            else
              ..._buildItens(
                estimativa.itens,
                estimativa.fornecedores,
                estimativa.calculoGlobal,
                exclusividadeGlobal: estimativa.exclusividadeMeEpp,
              ),

            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'VALOR TOTAL ESTIMADO: ${_fmt.format(estimativa.valorTotalGlobal)}',
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
    final outputFile = await FilePicker.saveFile(
      dialogTitle: 'Salvar PDF Estimativa',
      fileName: 'estimativa_${estimativa.numero}_${estimativa.ano}.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputFile == null) return; // User canceled

    try {
      final file = File(outputFile);
      await file.writeAsBytes(await pdf.save());

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
            content: Text('Erro ao salvar ou abrir o PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static String _getCalculoLabel(String calc) {
    if (calc == 'min') return 'Menor Preço';
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

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 170,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildLotes(EstimativaModel estimativa) {
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
                'Lote ${lote.numero} - ${lote.descricao}',
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
                isInsideLote: true,
                exclusividadeGlobal: estimativa.exclusividadeMeEpp,
              ),
              pw.SizedBox(height: 10),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Subtotal do Lote: ${_fmt.format(lote.getValorTotal(estimativa.calculoGlobal))}',
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
    String globalCalculo, {
    bool isInsideLote = false,
    String exclusividadeGlobal = 'nenhuma',
  }) {
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
                      'Item ${item.numero} - ${item.descricao}',
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
                'Regra Ref.: ${_getCalculoLabel(calculoUsado)}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 8),

              // Tabela de Orçamentos
              pw.TableHelper.fromTextArray(
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                headers: ['Razão Social', 'CNPJ', 'Data', 'Valor Unitário'],
                columnWidths: {
                  0: pw.FixedColumnWidth(150.0),
                  1: pw.FixedColumnWidth(60.0),
                  2: pw.FixedColumnWidth(40.0),
                  3: pw.FixedColumnWidth(50.0),
                },
                cellAlignments: {
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                },
                data: item.orcamentos.map((o) {
                  final fornecedor = fornecedores
                      .where((f) => f.id == o.fornecedorId)
                      .firstOrNull;
                  return [
                    fornecedor?.razaoSocial ?? '-',
                    AudespCpfCnpjField.formatDocument(fornecedor?.cnpj ?? ''),
                    fornecedor?.data ?? '-',
                    _fmt.format(o.valorUnitario),
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 8),

              // Totais do Item
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Valor de Referência Unitário: ${_fmt.format(item.getValorReferenciaUnitario(globalCalculo))}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      if (isMensal)
                        pw.Text(
                          'Valor Estimado Mensal: ${_fmt.format(item.getValorMensal(globalCalculo))}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      pw.Text(
                        'Valor Estimado Total: ${_fmt.format(item.getValorTotal(globalCalculo))}',
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
