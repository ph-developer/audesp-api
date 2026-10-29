import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/app_settings_dao.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/audesp_currency_field.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_text_field.dart';
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
  final _ufespValorCtrl = TextEditingController();
  final _ufespQuantidadeCtrl = TextEditingController();
  final _anoAtual = DateTime.now().year;
  bool _automatica = false;
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
    _ufespValorCtrl.dispose();
    _ufespQuantidadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final dao = ref.read(appSettingsDaoProvider);
    final config = await lerPncpConfig(dao);
    final sequencia = config.configurado
        ? await dao.get(SettingsKeys.pncpSequencia(config.cnpj, _anoAtual))
        : null;
    final ufesp = UfespConfig.fromSettings(
      valor: await dao.get(SettingsKeys.ufespValor),
      quantidade: await dao.get(SettingsKeys.ufespQuantidadeMinima),
    );
    if (!mounted) return;
    setState(() {
      _cnpjCtrl.text = config.cnpj;
      _automatica = config.automatica;
      _intervaloCtrl.text = '${config.intervaloMinutos}';
      _sequenciaCtrl.text = sequencia ?? '';
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
    setState(() => _saving = true);
    try {
      final dao = ref.read(appSettingsDaoProvider);
      if (cnpj.isEmpty) {
        await dao.delete(SettingsKeys.pncpCnpj);
      } else {
        await dao.set(SettingsKeys.pncpCnpj, cnpj);
        final sequencia = _inteiro(_sequenciaCtrl);
        final chave = SettingsKeys.pncpSequencia(cnpj, _anoAtual);
        if (sequencia == null) {
          await dao.delete(chave);
        } else {
          await dao.set(chave, '$sequencia');
        }
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
                            'Compras publicadas no PNCP com este CNPJ e sem '
                            'edital no sistema aparecem nas pendências.',
                      ),
                      const SizedBox(height: 16),
                      AudespNumberField(
                        label: 'Última sequência consultada em $_anoAtual',
                        controller: _sequenciaCtrl,
                        decimals: false,
                        hintText:
                            'A próxima consulta começa na sequência seguinte.',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ajuste para pular compras antigas que não serão '
                        'lançadas. Em branco, a consulta começa na sequência 1.',
                        style: Theme.of(context).textTheme.bodySmall,
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
