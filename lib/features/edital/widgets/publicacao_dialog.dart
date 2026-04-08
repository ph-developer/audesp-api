import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';

import '../domain/edital_domain.dart';

/// Diálogo para adicionar ou editar uma Publicação do Edital.
///
/// Retorna um `Map<String,dynamic>` com os campos preenchidos,
/// ou null se o usuário cancelou.
Future<Map<String, dynamic>?> showPublicacaoDialog(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _PublicacaoDialog(initial: initial),
  );
}

class _PublicacaoDialog extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _PublicacaoDialog({this.initial});

  @override
  State<_PublicacaoDialog> createState() => _PublicacaoDialogState();
}

class _PublicacaoDialogState extends State<_PublicacaoDialog> {
  DateTime? _dataPublicacao;
  final _pncpCtrl = TextEditingController();
  final _outrosCtrl = TextEditingController();

  int? _veiculo;

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    if (ini != null) {
      final raw = ini['dataPublicacao'] as String? ?? '';
      if (raw.isNotEmpty) {
        try {
          _dataPublicacao = DateFormat('yyyy-MM-dd').parse(raw);
        } catch (_) {}
      }
      _veiculo = ini['veiculoPublicacao'] as int?;
      _pncpCtrl.text = ini['idContratacaoPNCP'] as String? ?? '';
      _outrosCtrl.text = ini['veiculoPublicacaoNome'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _pncpCtrl.dispose();
    _outrosCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_dataPublicacao == null) {
      displayInfoBar(context,
          builder: (ctx, close) => const InfoBar(
              title: Text('Data de Publicação é obrigatória.'),
              severity: InfoBarSeverity.error));
      return;
    }
    if (_veiculo == null) {
      displayInfoBar(context,
          builder: (ctx, close) => const InfoBar(
              title: Text('Veículo de Publicação é obrigatório.'),
              severity: InfoBarSeverity.error));
      return;
    }
    if (_veiculo == 5) {
      final pncp = _pncpCtrl.text.trim();
      if (pncp.isEmpty) {
        displayInfoBar(context,
            builder: (ctx, close) => const InfoBar(
                title: Text('ID Contratação PNCP é obrigatório.'),
                severity: InfoBarSeverity.error));
        return;
      }
      if (!RegExp(r'^[0-9]{25}$').hasMatch(pncp)) {
        displayInfoBar(context,
            builder: (ctx, close) => const InfoBar(
                title: Text(
                    'ID PNCP deve ter exatamente 25 dígitos numéricos.'),
                severity: InfoBarSeverity.error));
        return;
      }
    }
    if (_veiculo == 10 && _outrosCtrl.text.trim().isEmpty) {
      displayInfoBar(context,
          builder: (ctx, close) => const InfoBar(
              title: Text('Nome do Veículo é obrigatório.'),
              severity: InfoBarSeverity.error));
      return;
    }
    final apiDate = DateFormat('yyyy-MM-dd').format(_dataPublicacao!);
    final result = <String, dynamic>{
      'dataPublicacao': apiDate,
      'veiculoPublicacao': _veiculo,
    };
    if (_veiculo == 5) {
      result['idContratacaoPNCP'] = _pncpCtrl.text.trim();
    }
    if (_veiculo == 10) {
      result['veiculoPublicacaoNome'] = _outrosCtrl.text.trim();
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(widget.initial == null
          ? 'Adicionar Publicação'
          : 'Editar Publicação'),
      constraints: const BoxConstraints(maxWidth: 500),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoLabel(
              label: 'Data de Publicação *',
              child: DatePicker(
                selected: _dataPublicacao,
                onChanged: (v) => setState(() => _dataPublicacao = v),
              ),
            ),
            const SizedBox(height: 12),
            InfoLabel(
              label: 'Veículo de Publicação *',
              child: ComboBox<int>(
                value: _veiculo,
                placeholder: const Text('Selecione...'),
                isExpanded: true,
                items: kVeiculosPublicacao.entries
                    .map((e) =>
                        ComboBoxItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _veiculo = v),
              ),
            ),
            if (_veiculo == 5) ...[
              const SizedBox(height: 12),
              InfoLabel(
                label: 'ID Contratação PNCP *',
                child: TextBox(
                  controller: _pncpCtrl,
                  placeholder: '25 dígitos numéricos',
                  maxLength: 25,
                ),
              ),
            ],
            if (_veiculo == 10) ...[
              const SizedBox(height: 12),
              InfoLabel(
                label: 'Nome do Veículo *',
                child: TextBox(
                  controller: _outrosCtrl,
                  maxLength: 100,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
