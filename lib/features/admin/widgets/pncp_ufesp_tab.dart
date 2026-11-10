import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/app_settings_dao.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/audesp_currency_field.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../pncp/domain/pncp_cursores.dart';
import '../../pncp/pncp_providers.dart';
import '../../processo/domain/ufesp_rules.dart';

/// Aba do admin com a consulta ao PNCP e o mínimo de UFESP.
class PncpUfespTab extends ConsumerStatefulWidget {
  const PncpUfespTab({super.key});

  @override
  ConsumerState<PncpUfespTab> createState() => _PncpUfespTabState();
}

class _PncpUfespTabState extends ConsumerState<PncpUfespTab> {
  final _cnpjCtrl = TextEditingController();
  final _intervaloCtrl = TextEditingController();
  final _sequenciaCtrl = TextEditingController();
  final _contratoSequenciaCtrl = TextEditingController();
  final _ataSequenciaCtrl = TextEditingController();
  final _ufespValorCtrl = TextEditingController();
  final _ufespQuantidadeCtrl = TextEditingController();
  final _anoAtual = DateTime.now().year;
  bool _automatica = false;

  /// Valores lidos do banco: só o que mudar é gravado.
  String _cnpjCarregado = '';
  int? _compraCarregada;
  int? _contratoCarregado;
  int? _ataCarregada;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cnpjCtrl.dispose();
    _intervaloCtrl.dispose();
    _sequenciaCtrl.dispose();
    _contratoSequenciaCtrl.dispose();
    _ataSequenciaCtrl.dispose();
    _ufespValorCtrl.dispose();
    _ufespQuantidadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final dao = ref.read(appSettingsDaoProvider);
    final config = await lerPncpConfig(dao);
    Future<int?> cursor(String Function(String, int) chave) async =>
        config.configurado
        ? int.tryParse(await dao.get(chave(config.cnpj, _anoAtual)) ?? '')
        : null;
    final compra = await cursor(SettingsKeys.pncpSequencia);
    final contrato = await cursor(SettingsKeys.pncpContratoSequencia);
    final ata = await cursor(SettingsKeys.pncpAtaCompraSequencia);
    final ufesp = UfespConfig.fromSettings(
      valor: await dao.get(SettingsKeys.ufespValor),
      quantidade: await dao.get(SettingsKeys.ufespQuantidadeMinima),
    );
    if (!mounted) return;
    setState(() {
      _cnpjCtrl.text = config.cnpj;
      _automatica = config.automatica;
      _intervaloCtrl.text = '${config.intervaloMinutos}';
      _cnpjCarregado = config.cnpj;
      _compraCarregada = compra;
      _contratoCarregado = contrato;
      _ataCarregada = ata;
      _sequenciaCtrl.text = compra?.toString() ?? '';
      _contratoSequenciaCtrl.text = contrato?.toString() ?? '';
      _ataSequenciaCtrl.text = ata?.toString() ?? '';
      _ufespValorCtrl.text = doubleToBrString(ufesp.valorUfesp);
      _ufespQuantidadeCtrl.text = '${ufesp.quantidadeMinima}';
      _loading = false;
    });
  }

  int? _inteiro(TextEditingController ctrl) =>
      parseBrCurrencyOrNull(ctrl.text)?.toInt();

  UfespConfig get _ufespDigitado => UfespConfig(
    valorUfesp:
        parseBrCurrencyOrNull(_ufespValorCtrl.text) ?? UfespConfig.valorPadrao,
    quantidadeMinima:
        _inteiro(_ufespQuantidadeCtrl) ?? UfespConfig.quantidadePadrao,
  );

  Future<void> _save() async {
    final cnpj = _cnpjCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (cnpj.isNotEmpty && cnpj.length != 14) {
      AudespSnackBar.error(context, 'O CNPJ deve ter 14 dígitos.');
      return;
    }
    final intervalo = _inteiro(_intervaloCtrl);
    if (intervalo == null || intervalo < 5) {
      AudespSnackBar.error(context, 'O intervalo mínimo é de 5 minutos.');
      return;
    }
    final compra = _inteiro(_sequenciaCtrl);
    final contrato = _inteiro(_contratoSequenciaCtrl);
    final ata = _inteiro(_ataSequenciaCtrl);
    final erroCursor = PncpCursores.validar(compra: compra, ata: ata);
    if (cnpj.isNotEmpty && erroCursor != null) {
      AudespSnackBar.error(context, erroCursor);
      return;
    }
    setState(() => _saving = true);
    try {
      final dao = ref.read(appSettingsDaoProvider);
      if (cnpj.isEmpty) {
        await dao.delete(SettingsKeys.pncpCnpj);
      } else {
        await dao.set(SettingsKeys.pncpCnpj, cnpj);
        final outroCnpj = cnpj != _cnpjCarregado;
        final alteracoes = PncpCursores.alteracoes(
          cnpj: cnpj,
          ano: _anoAtual,
          hoje: DateTime.now(),
          compra: compra,
          compraAlterada: outroCnpj || compra != _compraCarregada,
          contrato: contrato,
          contratoAlterado: outroCnpj || contrato != _contratoCarregado,
          ata: ata,
          ataAlterada: outroCnpj || ata != _ataCarregada,
        );
        for (final MapEntry(:key, :value) in alteracoes.entries) {
          if (value == null) {
            await dao.delete(key);
          } else {
            await dao.set(key, value);
          }
        }
        _cnpjCarregado = cnpj;
        _compraCarregada = compra;
        _contratoCarregado = contrato;
        _ataCarregada = ata;
      }
      await dao.set(
        SettingsKeys.pncpConsultaAutomatica,
        _automatica ? '1' : '0',
      );
      await dao.set(SettingsKeys.pncpIntervaloMinutos, '$intervalo');
      final ufesp = _ufespDigitado;
      await dao.set(SettingsKeys.ufespValor, '${ufesp.valorUfesp}');
      await dao.set(
        SettingsKeys.ufespQuantidadeMinima,
        '${ufesp.quantidadeMinima}',
      );
      ref.invalidate(pncpConfigProvider);
      ref.invalidate(ufespConfigProvider);
      if (mounted) {
        AudespSnackBar.success(context, 'Configurações salvas com sucesso.');
      }
    } catch (e) {
      if (mounted) AudespSnackBar.error(context, 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
    final ufesp = _ufespDigitado;

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
                      _titulo(Icons.travel_explore, 'Consulta ao PNCP'),
                      const Divider(height: 24),
                      AudespTextField(
                        label: 'CNPJ do órgão',
                        controller: _cnpjCtrl,
                        maxLength: 18,
                        keyboardType: TextInputType.number,
                        helperText:
                            'Compras, contratos e atas deste CNPJ no PNCP '
                            'geram as pendências.',
                      ),
                      const SizedBox(height: 16),
                      AudespNumberField(
                        label: 'Última compra consultada em $_anoAtual',
                        controller: _sequenciaCtrl,
                        decimals: false,
                        hintText:
                            'A próxima consulta começa na sequência seguinte.',
                      ),
                      const SizedBox(height: 4),
                      _ajuda(
                        'Ajuste para pular compras antigas que não serão '
                        'lançadas. Em branco, a consulta começa na sequência 1.',
                      ),
                      const SizedBox(height: 16),
                      AudespNumberField(
                        label: 'Último contrato consultado em $_anoAtual',
                        controller: _contratoSequenciaCtrl,
                        decimals: false,
                        hintText:
                            'A próxima consulta começa na sequência seguinte.',
                      ),
                      const SizedBox(height: 4),
                      _ajuda(
                        'Ajuste para pular contratos antigos que não serão '
                        'lançados. Em branco, a consulta começa no contrato 1.',
                      ),
                      const SizedBox(height: 16),
                      AudespNumberField(
                        label:
                            'Última compra verificada para atas em $_anoAtual',
                        controller: _ataSequenciaCtrl,
                        decimals: false,
                        hintText:
                            'Não pode passar da última compra consultada.',
                      ),
                      const SizedBox(height: 4),
                      _ajuda(
                        'Ajuste para pular atas de compras antigas. Ao alterar, '
                        'as atas atualizadas no PNCP passam a ser buscadas a '
                        'partir de hoje. Em branco, começa na compra 1 e busca '
                        'as atualizações desde 1º de janeiro.',
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Consulta automática'),
                        subtitle: const Text(
                          'Verifica as próximas sequências enquanto o sistema '
                          'estiver aberto.',
                        ),
                        value: _automatica,
                        onChanged: (v) => setState(() => _automatica = v),
                      ),
                      AudespNumberField(
                        label: 'Intervalo da consulta automática (minutos)',
                        controller: _intervaloCtrl,
                        decimals: false,
                        enabled: _automatica,
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
                      _titulo(Icons.price_check, 'Mínimo obrigatório (UFESP)'),
                      const Divider(height: 24),
                      AudespCurrencyField(
                        label: 'Valor da UFESP',
                        controller: _ufespValorCtrl,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      AudespNumberField(
                        label: 'Quantidade mínima de UFESP',
                        controller: _ufespQuantidadeCtrl,
                        decimals: false,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Processos com valor estimado abaixo de '
                        '${formatBRL(ufesp.limite, casasDecimais: 2)} são '
                        'marcados como envio não obrigatório.',
                        style: const TextStyle(fontWeight: FontWeight.w500),
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
