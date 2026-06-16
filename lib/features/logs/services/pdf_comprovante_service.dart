import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/database/models/api_log.dart';

class PdfComprovanteService {
  static final _timeFmt = DateFormat('dd/MM/yyyy HH:mm:ss');

  static String _prettyJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '(vazio)';
    try {
      final obj = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return raw;
    }
  }

  static String _obfuscateEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 1) return '*@$domain';
    return '${name.substring(0, 3.clamp(1, name.length))}***@$domain';
  }

  static Future<void> gerarComprovante(BuildContext context, WidgetRef ref, ApiLog log) async {
    String userDisplay = log.userId?.toString() ?? 'N/A';
    if (log.userId != null) {
      final user = await ref.read(usersDaoProvider).findById(log.userId!);
      if (user != null) {
        userDisplay = _obfuscateEmail(user.email);
      }
    }
    final pdf = pw.Document();

    final label = _labelFor(log.endpoint);
    final dataHora = _timeFmt.format(log.timestamp.toLocal());

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
                    'Comprovante de Situação de Protocolo',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'AUDESP API',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Resumo
            pw.Text(
              'Resumo dos Dados',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Divider(),
            _buildRow('Módulo:', label),
            _buildRow('Endpoint:', log.endpoint),
            _buildRow('Data/Hora:', dataHora),
            _buildRow('Usuário:', userDisplay),
            _buildRow('Status Code HTTP:', log.statusCode?.toString() ?? '—'),
            _buildRow('Protocolo:', log.protocolo ?? 'N/A'),
            _buildRow('Situação Atual:', log.statusProtocolo ?? 'N/A'),
            pw.SizedBox(height: 30),

            // Histórico / Detalhes (F4)
            if (log.retornoStatus != null) ...[
              pw.Text(
                'Detalhes da Situação (Consulta F4)',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              ..._prettyJson(log.retornoStatus).split('\n').map(
                    (line) => pw.Text(
                      line,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
              pw.SizedBox(height: 20),
            ],

            // Request Body
            pw.Text(
              'Payload Enviado (Request)',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Divider(),
            ..._prettyJson(log.request).split('\n').map(
                  (line) => pw.Text(
                    line,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
            pw.SizedBox(height: 20),

            // Response Original
            if (log.response != null) ...[
              pw.Text(
                'Resposta Original (Response)',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              ..._prettyJson(log.response).split('\n').map(
                    (line) => pw.Text(
                      line,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
            ],
          ];
        },
      ),
    );

    // Save File
    final outputFile = await FilePicker.saveFile(
      dialogTitle: 'Salvar Comprovante PDF',
      fileName: 'comprovante_${log.protocolo ?? "log"}.pdf',
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

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  static const _kEndpointLabels = <String, String>{
    '/login': 'Login',
    'enviar-edital': 'Edital',
    'enviar-licitacao': 'Licitação',
    'enviar-ata': 'Ata',
    'enviar-ajuste': 'Ajuste',
    'enviar-empenho-contrato': 'Empenho de Contrato',
    'enviar-termo-contrato': 'Termo de Contrato',
  };

  static String _labelFor(String endpoint) {
    for (final entry in _kEndpointLabels.entries) {
      if (endpoint.contains(entry.key)) return entry.value;
    }
    return endpoint;
  }
}
