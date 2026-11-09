import 'dart:convert';

/// Envio registrado em `api_logs`, só com o descritor do documento (sem o
/// JSON completo), para localizar o último envio de cada documento das
/// listagens.
class EnvioResumo {
  final int id;
  final int? statusCode;
  final String? protocolo;
  final String? statusProtocolo;
  final DateTime timestamp;
  final Map<String, dynamic> descritor;

  /// URL completa do envio; começa pela base do ambiente (Piloto/Oficial).
  final String endpoint;

  const EnvioResumo({
    required this.id,
    required this.statusCode,
    required this.protocolo,
    required this.statusProtocolo,
    required this.timestamp,
    required this.descritor,
    this.endpoint = '',
  });

  /// `row['descritor']` é o texto de `request.descritor`; nulo ou inválido
  /// vira um descritor vazio, que não corresponde a nenhum documento.
  factory EnvioResumo.fromMap(Map<String, dynamic> row) {
    Map<String, dynamic> descritor = const {};
    final texto = row['descritor'];
    if (texto is String && texto.isNotEmpty) {
      try {
        final decoded = jsonDecode(texto);
        if (decoded is Map<String, dynamic>) descritor = decoded;
      } catch (_) {}
    }
    return EnvioResumo(
      id: row['id'] as int,
      statusCode: row['status_code'] as int?,
      protocolo: row['protocolo'] as String?,
      statusProtocolo: row['status_protocolo'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (row['timestamp'] as int) * 1000,
      ),
      descritor: descritor,
      endpoint: row['endpoint'] as String? ?? '',
    );
  }

  bool get sucesso {
    final code = statusCode;
    return code != null && code >= 200 && code < 300;
  }

  SituacaoEnvio get situacao {
    if (!sucesso) return SituacaoEnvio.falha;
    final s = (statusProtocolo ?? '').toLowerCase();
    if (s.contains('rejeitado')) return SituacaoEnvio.rejeitado;
    if (s.contains('armazenado')) return SituacaoEnvio.armazenado;
    if (s.contains('substitu') || s.contains('exclu')) {
      return SituacaoEnvio.encerrado;
    }
    return SituacaoEnvio.emAndamento;
  }

  /// O AUDESP armazenou o documento. Substituído também conta: o protocolo
  /// foi armazenado antes de ser trocado pela retificação.
  bool get armazenou {
    if (!sucesso) return false;
    final s = (statusProtocolo ?? '').toLowerCase();
    return s.contains('armazenado') || s.contains('substitu');
  }

  bool doAmbiente(String baseUrl) => endpoint.startsWith('$baseUrl/');

  /// Texto da badge: o status do protocolo AUDESP ou, sem ele, o resultado
  /// da requisição.
  String get rotulo {
    if (!sucesso) return 'Falha no envio';
    final status = statusProtocolo?.trim() ?? '';
    return status.isEmpty ? 'Enviado' : status;
  }
}

enum SituacaoEnvio {
  /// A requisição não chegou ao AUDESP ou foi recusada (HTTP fora de 2xx).
  falha,

  /// Protocolo rejeitado pelo AUDESP.
  rejeitado,

  /// Protocolo armazenado: envio concluído.
  armazenado,

  /// Protocolo substituído ou excluído.
  encerrado,

  /// Pendente, recebido ou em validação.
  emAndamento,
}

/// Filtro das listagens pelo status do último envio.
enum FiltroEnvio {
  todos('Todos'),
  semEnvio('Sem envio'),
  falha('Falha'),
  rejeitado('Rejeitado'),
  emAndamento('Em análise'),
  armazenado('Armazenado'),
  encerrado('Encerrado');

  final String rotulo;
  const FiltroEnvio(this.rotulo);

  bool aceita(EnvioResumo? envio) => switch (this) {
    todos => true,
    semEnvio => envio == null,
    falha => envio?.situacao == SituacaoEnvio.falha,
    rejeitado => envio?.situacao == SituacaoEnvio.rejeitado,
    emAndamento => envio?.situacao == SituacaoEnvio.emAndamento,
    armazenado => envio?.situacao == SituacaoEnvio.armazenado,
    encerrado => envio?.situacao == SituacaoEnvio.encerrado,
  };
}

/// Trechos de `api_logs.endpoint` de cada tipo de envio.
abstract final class EnviosEndpoint {
  static const edital = 'enviar-edital';
  static const licitacao = 'enviar-licitacao';
  static const ata = 'enviar-ata';
  static const ajuste = 'enviar-ajuste';
}

/// Campos do descritor que identificam cada documento nos logs de envio.
abstract final class DescritorEnvio {
  static Map<String, Object?> edital({
    required String municipio,
    required String entidade,
    required String codigoEdital,
    required bool retificacao,
  }) => {
    'municipio': municipio,
    'entidade': entidade,
    'codigoEdital': codigoEdital,
    'retificacao': retificacao,
  };

  static Map<String, Object?> licitacao({
    required String municipio,
    required String entidade,
    required String codigoEdital,
    required bool retificacao,
  }) => edital(
    municipio: municipio,
    entidade: entidade,
    codigoEdital: codigoEdital,
    retificacao: retificacao,
  );

  static Map<String, Object?> ata({
    required String municipio,
    required String entidade,
    required String codigoEdital,
    required String codigoAta,
    required bool retificacao,
  }) => {
    'municipio': municipio,
    'entidade': entidade,
    'codigoEdital': codigoEdital,
    'codigoAta': codigoAta,
    'retificacao': retificacao,
  };

  static Map<String, Object?> ajuste({
    required String municipio,
    required String entidade,
    required String codigoEdital,
    String? codigoAta,
    required String codigoContrato,
    required bool retificacao,
  }) => {
    'municipio': municipio,
    'entidade': entidade,
    'codigoEdital': codigoEdital,
    if (codigoAta != null && codigoAta.isNotEmpty) 'codigoAta': codigoAta,
    'codigoContrato': codigoContrato,
    'retificacao': retificacao,
  };

  /// Booleanos comparam por valor; o resto pelo texto, porque o JSON pode
  /// trazer números onde o modelo guarda strings.
  static bool corresponde(
    Map<String, dynamic> descritor,
    Map<String, Object?> esperado,
  ) {
    return esperado.entries.every((entry) {
      final actual = descritor[entry.key];
      final expected = entry.value;
      if (expected is bool) return actual == expected;
      return actual?.toString() == expected?.toString();
    });
  }
}

/// Envios de um tipo de documento, agrupados por `codigoEdital` para que
/// cada card da listagem procure só entre os envios do seu edital.
class EnviosIndex {
  final Map<String, List<EnvioResumo>> _porEdital;

  EnviosIndex._(this._porEdital);

  static final vazio = EnviosIndex._(const {});

  factory EnviosIndex(Iterable<EnvioResumo> envios) {
    final ordenados = envios.toList()
      ..sort((a, b) {
        final porData = b.timestamp.compareTo(a.timestamp);
        return porData != 0 ? porData : b.id.compareTo(a.id);
      });
    final porEdital = <String, List<EnvioResumo>>{};
    for (final envio in ordenados) {
      final codigo = envio.descritor['codigoEdital']?.toString();
      if (codigo == null) continue;
      porEdital.putIfAbsent(codigo, () => []).add(envio);
    }
    return EnviosIndex._(porEdital);
  }

  /// Envio mais recente cujo descritor tem os campos de [esperado].
  EnvioResumo? ultimo(Map<String, Object?> esperado) =>
      todos(esperado).firstOrNull;

  /// Envios cujo descritor tem os campos de [esperado], do mais recente ao
  /// mais antigo.
  Iterable<EnvioResumo> todos(Map<String, Object?> esperado) {
    final candidatos =
        _porEdital[esperado['codigoEdital']?.toString()] ?? const [];
    return candidatos.where(
      (envio) => DescritorEnvio.corresponde(envio.descritor, esperado),
    );
  }
}

/// O protocolo ainda pode mudar de situação no AUDESP (pendente, recebido,
/// em validação). Situações finais não precisam ser consultadas de novo.
bool protocoloEmAndamento(String? status) {
  if (status == null) return false;
  final s = status.toLowerCase();
  return !(s.contains('rejeitado') ||
      s.contains('arquivado') ||
      s.contains('exclu') ||
      s.contains('armazenado') ||
      s.contains('substitu'));
}
