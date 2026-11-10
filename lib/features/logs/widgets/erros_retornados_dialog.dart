import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../shared/widgets/status_chip.dart';

/// Erros (`erros`) do retorno da consulta de um protocolo AUDESP.
List<Map<String, dynamic>> errosRetornados(String? retornoStatus) {
  if (retornoStatus == null || retornoStatus.isEmpty) return const [];
  try {
    final json = jsonDecode(retornoStatus);
    final erros = json is Map<String, dynamic> ? json['erros'] : null;
    if (erros is! List) return const [];
    return [
      for (final erro in erros)
        if (erro is Map<String, dynamic>) erro,
    ];
  } catch (_) {
    return const [];
  }
}

/// Lista os erros retornados pelo AUDESP para um protocolo.
Future<void> showErrosRetornadosDialog(
  BuildContext context,
  List<Map<String, dynamic>> erros,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Erros Retornados'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: erros.length,
          itemBuilder: (itemCtx, i) {
            final erro = erros[i];
            return ListTile(
              title: Text(erro['mensagem']?.toString() ?? 'Erro'),
              subtitle: Text(
                'Campo: ${erro['campo']} | Código: ${erro['codigoErro']}',
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
}

/// Situação do último protocolo no topo dos formulários. Rejeitado fica em
/// vermelho e, quando há erros retornados, abre a lista ao clicar.
class ProtocoloStatusChip extends StatelessWidget {
  final String? status;
  final String? retornoStatus;

  const ProtocoloStatusChip({super.key, this.status, this.retornoStatus});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rejeitado = status?.toLowerCase().contains('rejeitado') ?? false;
    final chip = StatusChip(
      label: status?.isNotEmpty == true ? status! : 'Enviado',
      color: rejeitado ? scheme.error : null,
      backgroundColor: rejeitado ? scheme.errorContainer : null,
      borderColor: rejeitado ? scheme.error.withAlpha(80) : null,
    );
    final erros = errosRetornados(retornoStatus);
    if (erros.isEmpty) return chip;
    return Tooltip(
      message: 'Ver erros retornados',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => showErrosRetornadosDialog(context, erros),
          child: chip,
        ),
      ),
    );
  }
}
