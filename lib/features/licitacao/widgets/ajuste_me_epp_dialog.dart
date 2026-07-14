import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/audesp_cpf_cnpj_field.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_segmented_button.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../services/open_cnpj_service.dart';

/// Abre o diálogo de ajuste em lote do enquadramento ME/EPP.
///
/// Recebe [licitantesUnicos]: mapa de [niPessoa] → dados do licitante
/// (obrigatoriamente com as chaves `niPessoa`, `nomeRazaoSocial` e
/// `declaracaoMEouEPP`).
///
/// Retorna as alterações de enquadramento e razão social, ou null se
/// cancelado.
Future<AjusteMeEppDialogResult?> showAjusteMeEppDialog(
  BuildContext context,
  Map<String, Map<String, dynamic>> licitantesUnicos,
) {
  return showAudespDialog<AjusteMeEppDialogResult>(
    context: context,
    size: DialogSize.large,
    builder: (_) => _AjusteMeEppDialog(licitantesUnicos: licitantesUnicos),
  );
}

class _AjusteMeEppDialog extends ConsumerStatefulWidget {
  final Map<String, Map<String, dynamic>> licitantesUnicos;
  const _AjusteMeEppDialog({required this.licitantesUnicos});

  @override
  ConsumerState<_AjusteMeEppDialog> createState() =>
      _AjusteMeEppDialogState();
}

class AjusteMeEppDialogResult {
  final Map<String, int> declaracoesMeEpp;
  final Map<String, String> razoesSociaisAlteradas;

  const AjusteMeEppDialogResult({
    required this.declaracoesMeEpp,
    required this.razoesSociaisAlteradas,
  });
}

class _AjusteMeEppDialogState extends ConsumerState<_AjusteMeEppDialog> {
  late final Map<String, int> _status;
  late final Map<String, String> _razoesSociaisOriginais;
  late final Map<String, String> _razoesSociais;
  final Map<String, String> _razoesSociaisSugeridas = {};
  final Set<String> _consultasComFalha = {};
  bool _consultando = false;
  int _consultasConcluidas = 0;
  int _totalConsultas = 0;

  @override
  void initState() {
    super.initState();
    _status = {
      for (final entry in widget.licitantesUnicos.entries)
        entry.key: (entry.value['declaracaoMEouEPP'] as num? ?? 3).toInt(),
    };
    _razoesSociaisOriginais = {
      for (final entry in widget.licitantesUnicos.entries)
        entry.key: entry.value['nomeRazaoSocial'] as String? ?? '',
    };
    _razoesSociais = Map<String, String>.from(_razoesSociaisOriginais);
  }

  void _submit() {
    final razoesSociaisAlteradas = <String, String>{};
    for (final entry in _razoesSociais.entries) {
      if (entry.value != _razoesSociaisOriginais[entry.key]) {
        razoesSociaisAlteradas[entry.key] = entry.value;
      }
    }
    Navigator.of(context).pop(
      AjusteMeEppDialogResult(
        declaracoesMeEpp: Map<String, int>.from(_status),
        razoesSociaisAlteradas: razoesSociaisAlteradas,
      ),
    );
  }

  void _aceitarRazaoSocial(String ni) {
    final razaoSocial = _razoesSociaisSugeridas[ni];
    if (razaoSocial == null) return;
    setState(() {
      _razoesSociais[ni] = razaoSocial;
      _razoesSociaisSugeridas.remove(ni);
    });
  }

  Future<void> _copiarCnpj(String cnpj) async {
    final cnpjFormatado = AudespCpfCnpjField.formatDocument(cnpj);
    await Clipboard.setData(ClipboardData(text: cnpjFormatado));
    if (mounted) {
      AudespSnackBar.success(context, 'CNPJ copiado: $cnpjFormatado');
    }
  }

  Future<void> _consultarOpenCnpj() async {
    final empresasCandidatas = widget.licitantesUnicos.entries.where(
      (entry) => entry.value['tipoPessoaId'] == 'PJ',
    );
    final empresas = empresasCandidatas.where((entry) {
      final cnpj = entry.key.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      return RegExp(r'^[A-Za-z0-9]{12}\d{2}$').hasMatch(cnpj);
    }).toList();
    final cnpjsInvalidos = empresasCandidatas.where((entry) {
      final cnpj = entry.key.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      return !RegExp(r'^[A-Za-z0-9]{12}\d{2}$').hasMatch(cnpj);
    }).map((entry) => entry.key);

    setState(() {
      _consultasComFalha
        ..clear()
        ..addAll(cnpjsInvalidos);
    });

    if (empresas.isEmpty) {
      AudespSnackBar.error(context, 'Nenhum CNPJ válido para consultar.');
      return;
    }

    setState(() {
      _consultando = true;
      _consultasConcluidas = 0;
      _totalConsultas = empresas.length;
    });

    final service = ref.read(openCnpjServiceProvider);
    var atualizados = 0;
    var falhas = 0;

    for (final empresa in empresas) {
      try {
        final consulta = await service.consultarEmpresa(empresa.key);
        if (!mounted) return;
        setState(() {
          _status[empresa.key] = consulta.declaracaoMeEpp;
          _consultasComFalha.remove(empresa.key);
          final razaoAtual = _razoesSociais[empresa.key] ?? '';
          if (consulta.razaoSocial.isNotEmpty &&
              !_mesmaRazaoSocial(consulta.razaoSocial, razaoAtual)) {
            _razoesSociaisSugeridas[empresa.key] = consulta.razaoSocial;
          } else {
            _razoesSociaisSugeridas.remove(empresa.key);
          }
          _consultasConcluidas++;
        });
        atualizados++;
      } catch (_) {
        falhas++;
        if (!mounted) return;
        setState(() {
          _consultasComFalha.add(empresa.key);
          _consultasConcluidas++;
        });
      }
    }

    if (!mounted) return;
    setState(() => _consultando = false);
    final mensagem = '$atualizados empresa(s) atualizada(s) pela OpenCNPJ.';
    if (falhas == 0) {
      AudespSnackBar.success(context, mensagem);
    } else {
      AudespSnackBar.error(
        context,
        '$mensagem Não foi possível consultar $falhas empresa(s).',
      );
    }
  }

  bool _mesmaRazaoSocial(String primeira, String segunda) {
    String normalizar(String valor) =>
        valor.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    return normalizar(primeira) == normalizar(segunda);
  }

  @override
  Widget build(BuildContext context) {
    final licitantes = widget.licitantesUnicos.entries.toList();
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Ajustar ME/EPP')),
          OutlinedButton.icon(
            onPressed: _consultando ? null : _consultarOpenCnpj,
            icon: _consultando
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_sync_outlined, size: 18),
            label: Text(
              _consultando
                  ? 'Consultando $_consultasConcluidas/$_totalConsultas'
                  : 'Consultar OpenCNPJ',
            ),
          ),
        ],
      ),
      content: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Corrija o enquadramento de cada licitante. '
              'A alteração será aplicada em todos os itens onde ele aparecer.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: licitantes.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final entry = licitantes[i];
                  final ni = entry.key;
                  final nome = _razoesSociais[ni] ?? '';
                  final razaoSocialSugerida = _razoesSociaisSugeridas[ni];
                  final consultaComFalha = _consultasComFalha.contains(ni);
                  final cnpjFormatado = AudespCpfCnpjField.formatDocument(ni);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (nome.isNotEmpty || consultaComFalha)
                                Row(
                                  children: [
                                    if (nome.isNotEmpty)
                                      Flexible(
                                        child: Text(
                                          nome,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    if (consultaComFalha) ...[
                                      if (nome.isNotEmpty)
                                        const SizedBox(width: 6),
                                      const Tooltip(
                                        message:
                                            'Não foi possível consultar esta empresa',
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.red,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              if (razaoSocialSugerida != null)
                                Tooltip(
                                  message: 'Clique para usar esta razão social',
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(4),
                                      onTap: () => _aceitarRazaoSocial(ni),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        child: Text(
                                          razaoSocialSugerida,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Tooltip(
                                message: 'Clique para copiar o CNPJ',
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(4),
                                    onTap: () => _copiarCnpj(ni),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            cnpjFormatado,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.copy_outlined,
                                            size: 13,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        AudespSegmentedButton<int>(
                          segments: const {1: 'ME', 2: 'EPP', 3: 'NÃO'},
                          selected: {_status[ni] ?? 3},
                          onSelectionChanged: (s) =>
                              setState(() => _status[ni] = s.first),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _consultando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _consultando ? null : _submit,
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
