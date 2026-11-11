import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';

enum TipoPrazo { edital, licitacao, ata, ajuste }

enum SituacaoPrazo { emDia, proximo, venceHoje, vencido }

/// Calendário dos dias úteis: sábados, domingos, feriados nacionais, 09/07
/// (SP), Sexta-feira Santa e as datas cadastradas pelo admin.
class DiasUteis {
  /// Datas `dd/MM` (todo ano) ou `dd/MM/aaaa`.
  final List<String> feriadosExtras;
  final bool carnaval;
  final bool corpusChristi;

  final Set<(int, int)> _anuais;
  final Set<DateTime> _datas;
  final Map<int, Set<DateTime>> _moveis = {};

  DiasUteis({
    this.feriadosExtras = const [],
    this.carnaval = false,
    this.corpusChristi = false,
  }) : _anuais = {
         for (final f in feriadosExtras)
           if (lerFeriado(f) case (final dia, final mes, null)) (mes, dia),
       },
       _datas = {
         for (final f in feriadosExtras)
           if (lerFeriado(f) case (final dia, final mes, final int ano))
             DateTime(ano, mes, dia),
       };

  static const _fixos = {
    (1, 1),
    (4, 21),
    (5, 1),
    (7, 9),
    (9, 7),
    (10, 12),
    (11, 2),
    (11, 15),
    (11, 20),
    (12, 25),
  };

  /// `(dia, mês, ano?)` de `dd/MM` ou `dd/MM/aaaa`; null se inválida.
  static (int, int, int?)? lerFeriado(String texto) {
    final m = RegExp(
      r'^(\d{1,2})/(\d{1,2})(?:/(\d{4}))?$',
    ).firstMatch(texto.trim());
    if (m == null) return null;
    final dia = int.parse(m[1]!);
    final mes = int.parse(m[2]!);
    final ano = m[3] == null ? null : int.parse(m[3]!);
    final data = DateTime(ano ?? 2024, mes, dia); // 2024 aceita 29/02.
    if (data.month != mes || data.day != dia) return null;
    return (dia, mes, ano);
  }

  /// Domingo de Páscoa (algoritmo de Meeus/Jones/Butcher).
  static DateTime pascoa(int ano) {
    final a = ano % 19;
    final b = ano ~/ 100;
    final c = ano % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final mes = (h + l - 7 * m + 114) ~/ 31;
    final dia = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(ano, mes, dia);
  }

  Set<DateTime> _moveisDe(int ano) => _moveis.putIfAbsent(ano, () {
    final p = pascoa(ano);
    DateTime dias(int n) => DateTime(p.year, p.month, p.day + n);
    return {
      dias(-2),
      if (carnaval) ...[dias(-48), dias(-47)],
      if (corpusChristi) dias(60),
    };
  });

  bool util(DateTime data) {
    final d = DateTime(data.year, data.month, data.day);
    if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
      return false;
    }
    final mesDia = (d.month, d.day);
    return !_fixos.contains(mesDia) &&
        !_anuais.contains(mesDia) &&
        !_datas.contains(d) &&
        !_moveisDe(d.year).contains(d);
  }

  /// [dias] dias úteis depois de [base], sem contar o próprio dia.
  DateTime somar(DateTime base, int dias) {
    var d = DateTime(base.year, base.month, base.day);
    var contados = 0;
    while (contados < dias) {
      d = DateTime(d.year, d.month, d.day + 1);
      if (util(d)) contados++;
    }
    return d;
  }

  /// Dias úteis depois de [de] até [ate], inclusive.
  int entre(DateTime de, DateTime ate) {
    var d = DateTime(de.year, de.month, de.day);
    final fim = DateTime(ate.year, ate.month, ate.day);
    var total = 0;
    while (d.isBefore(fim)) {
      d = DateTime(d.year, d.month, d.day + 1);
      if (util(d)) total++;
    }
    return total;
  }
}

/// Prazos de envio ao AUDESP configurados pelo admin (`app_settings`).
class PrazoEnvioConfig {
  static final cortePadrao = DateTime(2026, 11, 1);
  static final prazoTransicaoPadrao = DateTime(2027, 2, 1);
  static const diasPadrao = {
    TipoPrazo.edital: 5,
    TipoPrazo.licitacao: 10,
    TipoPrazo.ata: 15,
    TipoPrazo.ajuste: 22,
  };
  static const diasAlertaPadrao = 2;

  /// Editais publicados antes do corte têm o prazo fixo da transição.
  final DateTime corte;
  final DateTime prazoTransicao;
  final Map<TipoPrazo, int> dias;

  /// A partir de quantos dias úteis restantes o prazo fica em destaque.
  final int diasAlerta;
  final DiasUteis calendario;

  PrazoEnvioConfig({
    DateTime? corte,
    DateTime? prazoTransicao,
    this.dias = diasPadrao,
    this.diasAlerta = diasAlertaPadrao,
    DiasUteis? calendario,
  }) : corte = corte ?? cortePadrao,
       prazoTransicao = prazoTransicao ?? prazoTransicaoPadrao,
       calendario = calendario ?? DiasUteis();

  static const chaveCorte = 'prazo_corte';
  static const chaveTransicao = 'prazo_transicao';
  static const chaveDiasAlerta = 'prazo_dias_alerta';
  static const chaveFeriados = 'prazo_feriados';
  static const chaveCarnaval = 'prazo_carnaval';
  static const chaveCorpusChristi = 'prazo_corpus_christi';
  static String chaveDias(TipoPrazo tipo) => 'prazo_dias_${tipo.name}';

  static List<String> get chaves => [
    chaveCorte,
    chaveTransicao,
    chaveDiasAlerta,
    chaveFeriados,
    chaveCarnaval,
    chaveCorpusChristi,
    for (final tipo in TipoPrazo.values) chaveDias(tipo),
  ];

  static final _iso = DateFormat('yyyy-MM-dd');

  factory PrazoEnvioConfig.fromSettings(Map<String, String?> s) {
    DateTime? data(String chave) => switch (DateTime.tryParse(s[chave] ?? '')) {
      final DateTime d => DateTime(d.year, d.month, d.day),
      null => null,
    };
    int? inteiro(String chave) => int.tryParse(s[chave] ?? '');
    return PrazoEnvioConfig(
      corte: data(chaveCorte),
      prazoTransicao: data(chaveTransicao),
      dias: {
        for (final tipo in TipoPrazo.values)
          tipo: switch (inteiro(chaveDias(tipo))) {
            final int n when n > 0 => n,
            _ => diasPadrao[tipo]!,
          },
      },
      diasAlerta: switch (inteiro(chaveDiasAlerta)) {
        final int n when n >= 0 => n,
        _ => diasAlertaPadrao,
      },
      calendario: DiasUteis(
        feriadosExtras: [
          for (final f in (s[chaveFeriados] ?? '').split(';'))
            if (DiasUteis.lerFeriado(f) != null) f.trim(),
        ],
        carnaval: s[chaveCarnaval] == '1',
        corpusChristi: s[chaveCorpusChristi] == '1',
      ),
    );
  }

  Map<String, String> toSettings() => {
    chaveCorte: _iso.format(corte),
    chaveTransicao: _iso.format(prazoTransicao),
    chaveDiasAlerta: '$diasAlerta',
    chaveFeriados: calendario.feriadosExtras.join(';'),
    chaveCarnaval: calendario.carnaval ? '1' : '0',
    chaveCorpusChristi: calendario.corpusChristi ? '1' : '0',
    for (final tipo in TipoPrazo.values) chaveDias(tipo): '${dias[tipo]}',
  };

  /// [publicacaoEdital] define o regime (antes ou depois do corte). Sem ela,
  /// ata e ajuste usam a própria data. Edital conta da publicação; ata e
  /// ajuste, da assinatura ou, sem ela, da publicação. Licitação não tem data
  /// de referência e fica sem prazo.
  PrazoEnvio? calcular(
    TipoPrazo tipo, {
    DateTime? publicacaoEdital,
    DateTime? assinatura,
    DateTime? publicacao,
  }) {
    final base = switch (tipo) {
      TipoPrazo.edital => publicacaoEdital,
      TipoPrazo.licitacao => null,
      TipoPrazo.ata || TipoPrazo.ajuste => assinatura ?? publicacao,
    };
    final regime = publicacaoEdital ?? base;
    if (regime == null) return null;
    final fmt = DateFormat('dd/MM/yyyy');
    if (_dia(regime).isBefore(corte)) {
      return PrazoEnvio(
        limite: prazoTransicao,
        explicacao:
            'Edital publicado antes de ${fmt.format(corte)}: '
            'prazo até ${fmt.format(prazoTransicao)}.',
        transicao: true,
        calendario: calendario,
        diasAlerta: diasAlerta,
      );
    }
    if (base == null) return null;
    final n = dias[tipo]!;
    final origem = switch (tipo) {
      TipoPrazo.edital => 'da publicação no PNCP',
      _ when assinatura != null => 'da assinatura',
      _ => 'da publicação no PNCP',
    };
    return PrazoEnvio(
      limite: calendario.somar(base, n),
      explicacao: '$n dias úteis $origem (${fmt.format(base)}).',
      calendario: calendario,
      diasAlerta: diasAlerta,
    );
  }

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);
}

class PrazoEnvio {
  final DateTime limite;
  final String explicacao;
  final bool transicao;
  final DiasUteis calendario;
  final int diasAlerta;

  PrazoEnvio({
    required DateTime limite,
    required this.explicacao,
    this.transicao = false,
    required this.calendario,
    required this.diasAlerta,
  }) : limite = DateTime(limite.year, limite.month, limite.day);

  /// Dias úteis depois de [hoje] até o limite (0 se vence hoje ou já venceu).
  int diasRestantes(DateTime hoje) => calendario.entre(hoje, limite);

  SituacaoPrazo situacao(DateTime hoje) {
    final dia = DateTime(hoje.year, hoje.month, hoje.day);
    if (dia.isAfter(limite)) return SituacaoPrazo.vencido;
    if (dia == limite) return SituacaoPrazo.venceHoje;
    return diasRestantes(dia) <= diasAlerta
        ? SituacaoPrazo.proximo
        : SituacaoPrazo.emDia;
  }
}

/// Prazos dos itens das pendências, a partir das leituras do PNCP. Documentos
/// locais casam pelo código PNCP (só dígitos), como nas pendências.
class PrazosEnvio {
  final PrazoEnvioConfig config;
  final Map<String, DateTime> _publicacoes;
  final Map<String, PncpAta> _atas;
  final Map<String, PncpContrato> _contratos;

  PrazosEnvio({
    required this.config,
    Iterable<PncpCompra> compras = const [],
    Iterable<PncpAta> atas = const [],
    Iterable<PncpContrato> contratos = const [],
  }) : _publicacoes = {
         for (final c in compras)
           if (c.dataPublicacao != null)
             _digitos(c.numeroControle): c.dataPublicacao!,
       },
       _atas = {for (final a in atas) _digitos(a.numeroControle): a},
       _contratos = {for (final c in contratos) _digitos(c.numeroControle): c};

  PrazoEnvio? compra(PncpCompra compra) => compra.dispensada
      ? null
      : config.calcular(
          TipoPrazo.edital,
          publicacaoEdital: compra.dataPublicacao,
        );

  PrazoEnvio? ataPncp(PncpAta ata) => ata.dispensada || ata.cancelada
      ? null
      : config.calcular(
          TipoPrazo.ata,
          publicacaoEdital: _publicacoes[_digitos(ata.numeroControleCompra)],
          assinatura: ata.dataAssinatura,
          publicacao: ata.dataPublicacao,
        );

  PrazoEnvio? contratoPncp(PncpContrato contrato) => contrato.dispensado
      ? null
      : config.calcular(
          TipoPrazo.ajuste,
          publicacaoEdital:
              _publicacoes[_digitos(contrato.numeroControleCompra ?? '')],
          assinatura: contrato.dataAssinatura,
          publicacao: contrato.dataPublicacao,
        );

  PrazoEnvio? edital(Edital edital) {
    for (final codigo in [edital.codigoEdital, edital.idContratacaoPNCP]) {
      final digitos = _digitos(codigo);
      if (digitos.isEmpty) continue;
      final publicacao = _publicacoes[digitos];
      if (publicacao != null) {
        return config.calcular(TipoPrazo.edital, publicacaoEdital: publicacao);
      }
    }
    return null;
  }

  PrazoEnvio? ata(Ata ata) => switch (_atas[_digitos(ata.codigoAta)]) {
    final PncpAta pncp => ataPncp(pncp),
    null => null,
  };

  PrazoEnvio? ajuste(Ajuste ajuste) =>
      switch (_contratos[_digitos(ajuste.codigoContrato)]) {
        final PncpContrato pncp => contratoPncp(pncp),
        null => null,
      };

  /// Ordem estável pelo limite; sem prazo vai para o fim.
  static List<T> ordenar<T>(Iterable<T> itens, PrazoEnvio? Function(T) prazo) {
    final indexados = [
      for (final (i, item) in itens.indexed) (i, item, prazo(item)?.limite),
    ];
    indexados.sort((a, b) {
      final (ia, _, la) = a;
      final (ib, _, lb) = b;
      if (la != null && lb != null && la != lb) return la.compareTo(lb);
      if ((la == null) != (lb == null)) return la == null ? 1 : -1;
      return ia.compareTo(ib);
    });
    return [for (final (_, item, _) in indexados) item];
  }

  static String _digitos(String? texto) =>
      (texto ?? '').replaceAll(RegExp(r'\D'), '');
}
