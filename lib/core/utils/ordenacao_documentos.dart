/// Critérios de ordenação das listagens de Edital, Licitação, Ata e Ajuste.
enum OrdenarPor {
  data('Data'),
  codigo('Código'),
  licitacao('Licitação');

  final String rotulo;
  const OrdenarPor(this.rotulo);
}

/// Valores de um documento usados na ordenação.
class ChaveOrdenacao {
  /// Data de alteração mostrada no card.
  final DateTime data;

  /// Código do título do card (PNCP ou código local do "Sem PNCP").
  final String codigo;

  /// Modalidade, número e ano da licitação do edital; vazios quando o
  /// documento não tem edital no sistema (ex.: ajuste de adesão).
  final String modalidade;
  final String numero;
  final int ano;

  const ChaveOrdenacao({
    required this.data,
    required this.codigo,
    this.modalidade = '',
    this.numero = '',
    this.ano = 0,
  });
}

/// Ordena [itens] por [por]. [decrescente] vale para a data, o código e o
/// ano/número; a modalidade fica sempre em ordem alfabética, e documentos
/// sem licitação vão para o fim. Empates caem na data mais recente.
List<T> ordenarDocumentos<T>(
  Iterable<T> itens, {
  required OrdenarPor por,
  required bool decrescente,
  required ChaveOrdenacao Function(T item) chave,
}) {
  final comChave = [for (final item in itens) (item, chave(item))];
  int sentido(int c) => decrescente ? -c : c;

  comChave.sort((x, y) {
    final a = x.$2;
    final b = y.$2;
    final c = switch (por) {
      OrdenarPor.data => sentido(a.data.compareTo(b.data)),
      OrdenarPor.codigo => sentido(compararCodigos(a.codigo, b.codigo)),
      OrdenarPor.licitacao => _compararLicitacao(a, b, sentido),
    };
    return c != 0 ? c : b.data.compareTo(a.data);
  });
  return [for (final (item, _) in comChave) item];
}

int _compararLicitacao(
  ChaveOrdenacao a,
  ChaveOrdenacao b,
  int Function(int) sentido,
) {
  final semA = a.modalidade.isEmpty;
  final semB = b.modalidade.isEmpty;
  if (semA != semB) return semA ? 1 : -1;
  final porModalidade = a.modalidade.toLowerCase().compareTo(
    b.modalidade.toLowerCase(),
  );
  if (porModalidade != 0) return porModalidade;
  final porAno = sentido(a.ano.compareTo(b.ano));
  if (porAno != 0) return porAno;
  return sentido(compararNatural(a.numero, b.numero));
}

/// Códigos PNCP (com ou sem máscara) comparam por ano, sequencial da
/// contratação, sequencial da ata e CNPJ, de modo que fiquem em ordem de
/// emissão; códigos locais vêm depois, em ordem natural.
int compararCodigos(String a, String b) {
  final ka = _chavePncp(a);
  final kb = _chavePncp(b);
  if (ka != null && kb != null) return ka.compareTo(kb);
  if (ka != null) return -1;
  if (kb != null) return 1;
  return compararNatural(a, b);
}

/// `CNPJ(14) + 1 + sequencial(6) + ano(4)` e, nas atas, `+ sequencial(6)`.
String? _chavePncp(String codigo) {
  final d = codigo.replaceAll(RegExp(r'\D'), '');
  if (d.length != 25 && d.length != 31) return null;
  final ano = d.substring(21, 25);
  final sequencial = d.substring(15, 21);
  final sequencialAta = d.length == 31 ? d.substring(25) : '000000';
  final cnpj = d.substring(0, 14);
  return '$ano$sequencial$sequencialAta$cnpj';
}

final _trechos = RegExp(r'\d+|\D+');

/// Compara textos tratando sequências de dígitos como números
/// ("2" < "10", "007" == "7") e o resto sem diferenciar maiúsculas.
int compararNatural(String a, String b) {
  final ta = _trechos.allMatches(a.trim()).map((m) => m[0]!).toList();
  final tb = _trechos.allMatches(b.trim()).map((m) => m[0]!).toList();
  for (var i = 0; i < ta.length && i < tb.length; i++) {
    final x = ta[i];
    final y = tb[i];
    final numX = _ehDigito(x);
    final numY = _ehDigito(y);
    final int c;
    if (numX && numY) {
      final nx = x.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      final ny = y.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      c = nx.length != ny.length
          ? nx.length.compareTo(ny.length)
          : nx.compareTo(ny);
    } else if (numX != numY) {
      c = numX ? -1 : 1;
    } else {
      c = x.toLowerCase().compareTo(y.toLowerCase());
    }
    if (c != 0) return c;
  }
  return ta.length.compareTo(tb.length);
}

bool _ehDigito(String trecho) {
  final c = trecho.codeUnitAt(0);
  return c >= 0x30 && c <= 0x39;
}
