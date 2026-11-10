import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/api_logs_dao.dart';
import '../../../shared/widgets/audesp_checkbox.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../domain/conclusao_envio.dart';
import '../domain/retificacao.dart';
import '../domain/ultimo_envio.dart';

/// Caixa "Retificação" dos formulários. Quando o ambiente já tem envio do
/// documento, o valor é definido pelo sistema ([ModoRetificacao.valor]).
class RetificacaoCheckbox extends StatelessWidget {
  final ModoRetificacao modo;
  final bool value;
  final bool readOnly;
  final ValueChanged<bool> onChanged;

  const RetificacaoCheckbox({
    super.key,
    required this.modo,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    // No documento enviado a caixa mostra o que foi enviado.
    final imposto = readOnly ? null : modo.valor;
    final caixa = AudespCheckbox(
      label: 'Retificação',
      value: imposto ?? value,
      readOnly: readOnly || imposto != null,
      onChanged: onChanged,
    );
    if (imposto == null) return caixa;
    return Tooltip(
      message: imposto
          ? 'Documento já armazenado no AUDESP: é enviado como retificação.'
          : 'O AUDESP ainda não armazenou este documento: é enviado como '
                'original.',
      child: caixa,
    );
  }
}

String _protocolo(EnvioResumo envio) =>
    'protocolo ${envio.protocolo ?? '-'}, enviado em '
    '${DateFormat('dd/MM/yyyy').format(envio.timestamp)}';

/// Confirma a volta a rascunho de um documento armazenado. [nome] vem sem
/// artigo ("edital", "licitação").
Future<bool> confirmarRetificacao(
  BuildContext context, {
  required String nome,
  bool feminino = false,
  required ConclusaoEnvio conclusao,
}) async {
  final o = feminino ? 'A' : 'O';
  final armazenado = conclusao.envio;
  final confirmado = await showAudespDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text('Retificar $nome?'),
      content: Text(
        '$o $nome volta a rascunho para correção e é '
        '${feminino ? 'enviada' : 'enviado'} ao AUDESP como retificação. '
        'O código do documento não pode ser alterado.\n\n'
        '${armazenado == null ? 'Não há envio deste documento nos logs do sistema, por isso a '
                  'retificação não poderá ser descartada depois.' : 'A versão armazenada (${_protocolo(armazenado)}) continua '
                  'valendo até a retificação ser armazenada, e os documentos '
                  'vinculados não são bloqueados. Para desistir, use '
                  '"Descartar retificação".'}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          icon: const Icon(Icons.edit_document),
          label: const Text('Retificar'),
        ),
      ],
    ),
  );
  return confirmado == true;
}

/// Confirma a restauração da versão armazenada. [aviso] acrescenta o que
/// não é restaurado (ex.: o PDF do edital).
Future<bool> confirmarDescarteRetificacao(
  BuildContext context, {
  required String nome,
  bool feminino = false,
  required ConclusaoEnvio conclusao,
  String? aviso,
}) async {
  final armazenado = conclusao.envio;
  if (armazenado == null) return false;
  final o = feminino ? 'a' : 'o';
  final confirmado = await showAudespDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Descartar retificação?'),
      content: Text(
        [
          'As alterações são perdidas e $o $nome volta à versão armazenada '
              'no AUDESP (${_protocolo(armazenado)}).',
          if (conclusao.retificacaoRejeitada)
            'A retificação rejeitada deixa de aparecer nas pendências; o '
                'protocolo continua nos logs.',
          ?aviso,
        ].join('\n\n'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          icon: const Icon(Icons.undo),
          label: const Text('Descartar retificação'),
        ),
      ],
    ),
  );
  return confirmado == true;
}

/// Documento do envio armazenado, para restaurar ao descartar a
/// retificação. Lança [StateError] se o log não existir mais.
Future<({String documentoJson, bool retificacao})> versaoArmazenada(
  ApiLogsDao dao,
  ConclusaoEnvio conclusao,
) async {
  final armazenado = conclusao.envio;
  final log = armazenado == null ? null : await dao.findById(armazenado.id);
  if (log == null) {
    throw StateError('O envio armazenado não foi encontrado nos logs.');
  }
  return (
    documentoJson: log.request,
    retificacao: RetificacaoRules.retificacaoDe(log.request),
  );
}

/// Log do cabeçalho do documento enviado: a retificação pendente ou o envio
/// armazenado. Sem conclusão por log (não concluído ou legado), o de
/// [buscarUltimo].
Future<ApiLog?> logDoCabecalho(
  ApiLogsDao dao,
  ConclusaoEnvio? conclusao,
  Future<ApiLog?> Function() buscarUltimo,
) async {
  final envio = conclusao != null && conclusao.concluida
      ? conclusao.envioPendente
      : null;
  if (envio == null) return buscarUltimo();
  return await dao.findById(envio.id) ?? await buscarUltimo();
}

/// Botões do cabeçalho do documento enviado.
class RetificacaoHeaderActions extends StatelessWidget {
  final ConclusaoEnvio? conclusao;
  final VoidCallback onRetificar;
  final VoidCallback onDescartar;

  const RetificacaoHeaderActions({
    super.key,
    required this.conclusao,
    required this.onRetificar,
    required this.onDescartar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (RetificacaoRules.podeDescartar(conclusao, enviado: true)) ...[
          DescartarRetificacaoButton(onPressed: onDescartar),
          const SizedBox(width: 8),
        ],
        if (RetificacaoRules.podeRetificar(conclusao, enviado: true)) ...[
          TextButton.icon(
            onPressed: onRetificar,
            icon: const Icon(Icons.edit_document),
            label: const Text('Retificar'),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class DescartarRetificacaoButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const DescartarRetificacaoButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.undo),
    label: const Text('Descartar retificação'),
  );
}
