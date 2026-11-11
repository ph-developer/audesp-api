import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/audesp_chip_input.dart';
import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../pendencias/domain/prazo_envio.dart';
import '../../pendencias/pendencias_providers.dart';

/// Aba do admin com os prazos de envio ao AUDESP mostrados nas pendências.
class PrazosEnvioTab extends ConsumerStatefulWidget {
  const PrazosEnvioTab({super.key});

  @override
  ConsumerState<PrazosEnvioTab> createState() => _PrazosEnvioTabState();
}

class _PrazosEnvioTabState extends ConsumerState<PrazosEnvioTab> {
  final _diasCtrl = {
    for (final tipo in TipoPrazo.values) tipo: TextEditingController(),
  };
  final _alertaCtrl = TextEditingController();
  DateTime? _corte;
  DateTime? _transicao;
  bool _carnaval = false;
  bool _corpusChristi = false;
  List<String> _feriados = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final ctrl in _diasCtrl.values) {
      ctrl.dispose();
    }
    _alertaCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final config = await ref.read(prazoEnvioConfigProvider.future);
    if (!mounted) return;
    setState(() {
      _corte = config.corte;
      _transicao = config.prazoTransicao;
      for (final MapEntry(:key, :value) in _diasCtrl.entries) {
        value.text = '${config.dias[key]}';
      }
      _alertaCtrl.text = '${config.diasAlerta}';
      _carnaval = config.calendario.carnaval;
      _corpusChristi = config.calendario.corpusChristi;
      _feriados = [...config.calendario.feriadosExtras];
      _loading = false;
    });
  }

  Future<void> _save() async {
    final dias = <TipoPrazo, int>{};
    for (final MapEntry(:key, :value) in _diasCtrl.entries) {
      final n = int.tryParse(value.text);
      if (n == null || n <= 0) {
        AudespSnackBar.error(
          context,
          'Informe os dias úteis de ${_rotulo(key).toLowerCase()} '
          '(maior que zero).',
        );
        return;
      }
      dias[key] = n;
    }
    final alerta = int.tryParse(_alertaCtrl.text);
    if (alerta == null) {
      AudespSnackBar.error(context, 'Informe os dias úteis do destaque.');
      return;
    }
    if (_corte == null || _transicao == null) {
      AudespSnackBar.error(context, 'Informe as datas da regra de transição.');
      return;
    }
    final config = PrazoEnvioConfig(
      corte: _corte,
      prazoTransicao: _transicao,
      dias: dias,
      diasAlerta: alerta,
      calendario: DiasUteis(
        feriadosExtras: _feriados,
        carnaval: _carnaval,
        corpusChristi: _corpusChristi,
      ),
    );
    setState(() => _saving = true);
    try {
      final dao = ref.read(appSettingsDaoProvider);
      for (final MapEntry(:key, :value) in config.toSettings().entries) {
        await dao.set(key, value);
      }
      ref.invalidate(prazoEnvioConfigProvider);
      if (mounted) {
        AudespSnackBar.success(context, 'Prazos salvos com sucesso.');
      }
    } catch (e) {
      if (mounted) AudespSnackBar.error(context, 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _rotulo(TipoPrazo tipo) => switch (tipo) {
    TipoPrazo.edital => 'Edital',
    TipoPrazo.licitacao => 'Licitação',
    TipoPrazo.ata => 'Ata de registro de preços',
    TipoPrazo.ajuste => 'Ajuste',
  };

  static String _contagem(TipoPrazo tipo) => switch (tipo) {
    TipoPrazo.edital => 'Contados da publicação no PNCP.',
    TipoPrazo.licitacao =>
      'Ainda sem alerta: o sistema não tem a data de referência.',
    TipoPrazo.ata || TipoPrazo.ajuste =>
      'Contados da assinatura ou, sem ela, da publicação no PNCP.',
  };

  /// `dd/MM` ou `dd/MM/aaaa`, com zeros à esquerda.
  static String _normalizar(String texto) {
    final (dia, mes, ano) = DiasUteis.lerFeriado(texto)!;
    final dm =
        '${dia.toString().padLeft(2, '0')}/${mes.toString().padLeft(2, '0')}';
    return ano == null ? dm : '$dm/$ano';
  }

  Widget _ajuda(String texto) =>
      Text(texto, style: Theme.of(context).textTheme.bodySmall);

  Widget _titulo(IconData icon, String texto) => Row(
    children: [
      Icon(icon),
      const SizedBox(width: 12),
      Text(texto, style: Theme.of(context).textTheme.titleMedium),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final fmt = DateFormat('dd/MM/yyyy');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _titulo(Icons.event_available, 'Prazos de envio'),
                      const Divider(height: 24),
                      _ajuda(
                        'Os prazos aparecem nas pendências de Edital, Ata e '
                        'Ajuste apenas como alerta; não bloqueiam envios.',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AudespDatePickerField(
                              label: 'Editais publicados antes de',
                              value: _corte,
                              onChanged: (d) => setState(() => _corte = d),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AudespDatePickerField(
                              label: 'têm prazo até',
                              value: _transicao,
                              onChanged: (d) => setState(() => _transicao = d),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _ajuda(
                        'Vale para o edital e para as atas e ajustes dele. '
                        'A partir de ${_corte == null ? 'essa data' : fmt.format(_corte!)}, '
                        'valem os dias úteis abaixo.',
                      ),
                      for (final tipo in TipoPrazo.values) ...[
                        const SizedBox(height: 16),
                        AudespNumberField(
                          label: '${_rotulo(tipo)} (dias úteis)',
                          controller: _diasCtrl[tipo],
                          decimals: false,
                        ),
                        const SizedBox(height: 4),
                        _ajuda(_contagem(tipo)),
                      ],
                      const SizedBox(height: 16),
                      AudespNumberField(
                        label: 'Destacar quando faltarem até (dias úteis)',
                        controller: _alertaCtrl,
                        decimals: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _titulo(Icons.calendar_month_outlined, 'Dias não úteis'),
                      const Divider(height: 24),
                      _ajuda(
                        'Sábados, domingos, feriados nacionais, Sexta-feira '
                        'Santa e 9 de julho já são considerados.',
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Carnaval (segunda e terça)'),
                        value: _carnaval,
                        onChanged: (v) => setState(() => _carnaval = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Corpus Christi'),
                        value: _corpusChristi,
                        onChanged: (v) => setState(() => _corpusChristi = v),
                      ),
                      const SizedBox(height: 8),
                      AudespChipInput<String>(
                        label: 'Outros feriados e pontos facultativos',
                        hintText: 'dd/mm (todo ano) ou dd/mm/aaaa',
                        chips: _feriados,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                        ],
                        validateInput: (v) =>
                            DiasUteis.lerFeriado(v ?? '') == null
                            ? 'Data inválida. Use dd/mm ou dd/mm/aaaa.'
                            : _feriados.contains(_normalizar(v!))
                            ? 'Data já cadastrada.'
                            : null,
                        onAdd: (v) =>
                            setState(() => _feriados.add(_normalizar(v))),
                        onRemove: (v) => setState(() => _feriados.remove(v)),
                        formatChip: (v) => v,
                      ),
                      const SizedBox(height: 4),
                      _ajuda(
                        'Inclua os feriados municipais, recessos e pontos '
                        'facultativos em que não há expediente.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
