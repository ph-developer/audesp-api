import 'package:audesp_api/features/documentacao/domain/documentacao_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pagina = DocumentacaoFontes.paginaTce;

  group('periodoVerificacao', () {
    test('separa manhã (0h-12h) e tarde (12h-0h) no horário local', () {
      expect(periodoVerificacao(DateTime(2026, 11, 3)), '2026-11-03-manha');
      expect(
        periodoVerificacao(DateTime(2026, 11, 3, 11, 59)),
        '2026-11-03-manha',
      );
      expect(periodoVerificacao(DateTime(2026, 11, 3, 12)), '2026-11-03-tarde');
      expect(
        periodoVerificacao(DateTime(2026, 11, 3, 23, 59)),
        '2026-11-03-tarde',
      );
    });
  });

  group('extrairPaginaTce', () {
    const html = '''
<html><head><title>x</title></head><body>
<nav><a href="/sites/default/files/menu.pdf">Menu</a> Visitas: 123</nav>
<article class="node">
  <script>var token = "abc";</script>
  <p>JSON Schemas&nbsp;relativos a <b>licitações</b>.</p>
  <a href="https://www.tce.sp.gov.br/sites/default/files/audesp-documentacao/edital-20261015.zip">edital</a>
  <a href="/sites/default/files/audesp-documentacao/Novo%20Modelo.xlsx">xlsx</a>
  <a href="/sites/default/files/audesp-documentacao/Novo%20Modelo.xlsx">de novo</a>
  <a href="https://portal.tce.sp.gov.br">Portal</a>
</article>
<footer>Atualizado em 03/11/2026 09:00</footer>
</body></html>''';

    test('usa só o artigo: ignora menu, rodapé e scripts', () {
      final extraida = extrairPaginaTce(html, pagina: pagina);
      expect(
        extraida.texto,
        'JSON Schemas relativos a licitações . edital xlsx de novo Portal',
      );
    });

    test('lista os anexos sem repetição, resolvendo endereços relativos', () {
      final extraida = extrairPaginaTce(html, pagina: pagina);
      expect(extraida.anexos.map(nomeAnexo), [
        'edital-20261015.zip',
        'Novo Modelo.xlsx',
      ]);
      expect(
        extraida.anexos.last.toString(),
        'https://www.tce.sp.gov.br/sites/default/files/audesp-documentacao/Novo%20Modelo.xlsx',
      );
    });

    test('falha quando a página não tem a seção da documentação', () {
      expect(
        () => extrairPaginaTce('<html>manutenção</html>', pagina: pagina),
        throwsFormatException,
      );
    });
  });

  group('compararDocumentacao', () {
    const referencia = DocumentacaoSnapshot(
      textoPagina: 't1',
      anexos: {'a.zip': 'h1', 'b.zip': 'h2'},
      especificacaoApi: 'y1',
    );

    test('sem diferença não gera alteração', () {
      final igual = DocumentacaoSnapshot.fromJson(referencia.toJson());
      expect(compararDocumentacao(referencia, igual), isEmpty);
    });

    test('descreve texto, anexos novos, alterados, removidos e a API', () {
      const atual = DocumentacaoSnapshot(
        textoPagina: 't2',
        anexos: {'a.zip': 'h1-novo', 'c.zip': 'h3'},
        especificacaoApi: 'y2',
      );
      expect(compararDocumentacao(referencia, atual), [
        'Texto da página de documentação do TCE alterado',
        'Anexo alterado: a.zip',
        'Novo anexo: c.zip',
        'Anexo removido: b.zip',
        'Especificação da API (audesp.yaml) alterada',
      ]);
    });
  });

  test('lerSnapshot trata valor ausente ou corrompido como ausente', () {
    expect(lerSnapshot(null), isNull);
    expect(lerSnapshot('{x'), isNull);
    expect(lerSnapshot('{}'), isNull);
  });
}
