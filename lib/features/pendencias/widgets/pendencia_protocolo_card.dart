import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/environments.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/document_card.dart';
import '../../auth/auth_providers.dart';
import '../../auth/widgets/audesp_auth_dialog.dart';
import '../../logs/domain/conclusao_envio.dart';
import '../../logs/envios_providers.dart';
import '../../logs/services/consulta_service.dart';
import '../../logs/widgets/ultimo_envio_chip.dart';

class PendenciaProtocoloCard extends ConsumerStatefulWidget {
  final String titulo;
  final String descricao;
  final String nome;
  final bool feminino;
  final String rota;
  final ConclusaoEnvio conclusao;
  final List<Widget> indicadores;

  const PendenciaProtocoloCard({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.nome,
    this.feminino = false,
    required this.rota,
    required this.conclusao,
    this.indicadores = const [],
  });

  @override
  ConsumerState<PendenciaProtocoloCard> createState() =>
      _PendenciaProtocoloCardState();
}

class _PendenciaProtocoloCardState
    extends ConsumerState<PendenciaProtocoloCard> {
  bool _ocupado = false;
  bool _atualizando = false;

  Future<void> _atualizar() async {
    final envio = widget.conclusao.envio;
    final user = ref.read(localSessionProvider);
    if (envio?.protocolo == null || user == null) return;
    final baseUrl = ref.read(environmentProvider).baseUrl;
    final consulta = ref.read(consultaServiceProvider);
    final dao = ref.read(apiLogsDaoProvider);
    final auth = ref.read(authServiceProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    String? novoStatus;

    Future<void> consultar() async {
      if (mounted) setState(() => _atualizando = true);
      try {
        final retorno = await consulta.consultarStatus(envio!.protocolo!);
        final json = jsonDecode(retorno);
        final status = json['status']?.toString() ?? 'Desconhecido';
        await dao.updateProtocoloInfo(envio.id, status, retorno);
        novoStatus = status;
        // O rail também precisa atualizar se o cartão já tiver sido fechado.
        container.invalidate(enviosProvider);
      } finally {
        if (mounted) setState(() => _atualizando = false);
      }
    }

    setState(() => _ocupado = true);
    try {
      if (auth.tokenValido(userId: user.id, baseUrl: baseUrl) != null) {
        await consultar();
      } else {
        await showAudespAuthDialog(
          context,
          ref,
          actionLabel: 'Autenticar e Atualizar',
          onConfirm: (_) => consultar(),
        );
      }
      if (mounted && novoStatus != null) {
        AudespSnackBar.success(
          context,
          'Situação atualizada para: $novoStatus',
        );
      }
    } catch (e) {
      if (mounted) AudespSnackBar.error(context, 'Erro ao atualizar: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final envio = widget.conclusao.envio;
    final colors = Theme.of(context).colorScheme;
    return DocumentCard(
      icon: Icons.pending_actions,
      iconBackgroundColor: colors.surfaceContainerHighest,
      iconColor: colors.onSurfaceVariant,
      title: widget.titulo,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.descricao.isNotEmpty) Text(widget.descricao),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (envio != null) UltimoEnvioChip(envio),
              ...widget.indicadores,
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.conclusao.motivo(widget.nome, feminino: widget.feminino)!,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => context.go(widget.rota),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir'),
              ),
              TextButton.icon(
                onPressed: _ocupado || (envio?.protocolo ?? '').isEmpty
                    ? null
                    : _atualizar,
                icon: _atualizando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: const Text('Atualizar situação'),
              ),
            ],
          ),
        ],
      ),
      onTap: () => context.go(widget.rota),
    );
  }
}
