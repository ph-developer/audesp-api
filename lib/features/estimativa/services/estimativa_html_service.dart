import 'package:intl/intl.dart';

import '../../../shared/widgets/audesp_cpf_cnpj_field.dart';
import '../models/estimativa_model.dart';
import '../models/estimativa_item_model.dart';
import '../models/estimativa_fornecedor_model.dart';
import '../models/estimativa_orcamento_model.dart';
import '../models/assinatura_model.dart';

class EstimativaHtmlService {
  static String gerarHtmlEstimativa(
    EstimativaModel estimativa, {
    List<AssinaturaModel> assinaturas = const [],
  }) {
    final fmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: estimativa.casasDecimais,
    );

    final sb = StringBuffer();
    sb.writeln(
      '<html style="font-family: Arial, sans-serif; font-size: 12pt;"><body style="font-family: Arial, sans-serif; font-size: 12pt;">',
    );

    // Header
    sb.writeln(
      '<h2 style="text-align: center;">Estimativa nº ${estimativa.numero}/${estimativa.ano}</h2>',
    );

    // Info Rows
    void addInfo(String label, String value, {bool justify = false}) {
      final style = justify ? ' style="text-align: justify;"' : '';
      sb.writeln('<p$style><strong>$label</strong> $value</p>');
    }

    addInfo('Objeto:', estimativa.objeto, justify: true);
    addInfo(
      'Tipo de Estimativa:',
      estimativa.tipoEstimativa == 'lote' ? 'Por Lote' : 'Por Item',
    );
    addInfo(
      'Tipo de Cálculo:',
      _getCalculoLabel(
        estimativa.calculoGlobal,
        isLote: estimativa.tipoEstimativa == 'lote',
      ),
    );
    addInfo('Registro de Preços:', estimativa.registroPrecos ? 'Sim' : 'Não');

    if (estimativa.prazoVigencia.isNotEmpty) {
      addInfo(
        estimativa.registroPrecos
            ? 'Prazo de Vigência da ARP:'
            : 'Prazo de Vigência do Contrato:',
        estimativa.registroPrecos
            ? '${estimativa.prazoVigencia}, a partir de sua assinatura, podendo ser prorrogado por igual período, desde que comprovada a vantagem econômica dos preços registrados.'
            : estimativa.temGarantia
            ? '${estimativa.prazoVigencia}, a partir de sua assinatura, podendo ser prorrogado pelo prazo legal a critério da Administração, sendo que seus efeitos prorrogar-se-ão até o término do prazo de garantia.'
            : '${estimativa.prazoVigencia}, a partir de sua assinatura, podendo ser prorrogado pelo prazo legal a critério da Administração.',
        justify: true,
      );
    }

    if (estimativa.formaPagamento.isNotEmpty) {
      addInfo('Forma de Pagamento:', estimativa.formaPagamento, justify: true);
    }

    if (estimativa.exclusividadeMeEpp != 'nao_aplica') {
      addInfo(
        'Exclusividade ME/EPP:',
        _getExclusividadeLabel(estimativa),
        justify: true,
      );
    }

    if (estimativa.fontesRecurso.isEmpty) {
      addInfo('Fontes de Recurso/Aplicação:', 'A definir');
    } else {
      addInfo(
        'Fontes de Recurso/Aplicação:',
        estimativa.fontesRecurso
            .map((e) {
              var text = '${e['fonteRecurso']}/${e['aplicacao']}';
              if ((e['descricao'] as String).isNotEmpty) {
                text += ' (${e['descricao']})';
              }
              if ((e['reserva'] as String).isNotEmpty) {
                text += ' - Reserva ${e['reserva']}';
              }
              if ((e['ficha'] as String).isNotEmpty) {
                text += ' - Ficha ${e['ficha']}';
              }
              return text;
            })
            .join('; '),
        justify: true,
      );
    }

    final obsBancoPrecos = _getObservacaoBancoPrecos(estimativa);
    if (obsBancoPrecos != null) {
      sb.writeln(
        '<p style="text-align: justify; margin-top:8px;">'
        '<strong>OBSERVAÇÃO:</strong> $obsBancoPrecos'
        '</p>',
      );
    }

    sb.writeln('<hr/>');

    if (estimativa.tipoEstimativa == 'lote') {
      final desclassificados = estimativa.fornecedoresDesclassificadosIds;
      for (final lote in estimativa.lotes) {
        sb.writeln(
          '<div style="border:1px solid #ccc; padding:10px; margin-bottom:10px;">',
        );
        sb.writeln(
          '<h3 style="text-align: justify;">Lote ${lote.numero} - ${lote.descricao}</h3>',
        );
        if (estimativa.exclusividadeMeEpp == 'exclusiva' ||
            (lote.exclusivoMeEpp &&
                estimativa.exclusividadeMeEpp == 'reservada')) {
          sb.writeln(
            '<p style="color:green;">${estimativa.exclusividadeMeEpp == 'exclusiva' ? '(Exclusivo ME/EPP)' : '(Reservado ME/EPP)'}</p>',
          );
        }

        final fVencedorId = estimativa.calculoGlobal == 'min_global'
            ? lote.getFornecedorMenorPrecoGlobalId(
                desclassificadosIds: desclassificados,
              )
            : null;

        sb.write(
          _buildItensHtml(
            lote.itens,
            estimativa.fornecedores,
            estimativa.calculoGlobal,
            fmt,
            isInsideLote: true,
            fornecedorVencedorId: fVencedorId,
            exclusividadeGlobal: estimativa.exclusividadeMeEpp,
            casasDecimais: estimativa.casasDecimais,
          ),
        );
        sb.writeln(
          '<p style="text-align:right; font-weight:bold;">Subtotal do Lote: ${fmt.format(lote.getValorTotal(estimativa.calculoGlobal, casasDecimais: estimativa.casasDecimais, desclassificadosIds: desclassificados))}</p>',
        );
        sb.writeln('</div>');
      }
    } else {
      sb.write(
        _buildItensHtml(
          estimativa.itens,
          estimativa.fornecedores,
          estimativa.calculoGlobal,
          fmt,
          exclusividadeGlobal: estimativa.exclusividadeMeEpp,
          casasDecimais: estimativa.casasDecimais,
        ),
      );
    }

    sb.writeln('<hr/>');
    sb.writeln(
      '<h3 style="text-align:right;">VALOR TOTAL ESTIMADO: ${fmt.format(estimativa.valorTotalGlobal)}</h3>',
    );

    if (assinaturas.isNotEmpty) {
      sb.writeln('<br/><br/>');
      for (int i = 0; i < assinaturas.length; i++) {
        final ass = assinaturas[i];
        sb.writeln('<div style="text-align: center;">');
        sb.writeln('<b>${ass.nome}</b><br/>${ass.cargo}');
        if (i < assinaturas.length - 1) {
          sb.writeln('</div><br/>');
        } else {
          sb.writeln('</div>');
        }
      }
    }

    sb.writeln('</body></html>');
    return sb.toString();
  }

  static String _buildItensHtml(
    List<EstimativaItem> itens,
    List<EstimativaFornecedor> fornecedores,
    String globalCalculo,
    NumberFormat fmt, {
    bool isInsideLote = false,
    String? fornecedorVencedorId,
    String exclusividadeGlobal = 'nenhuma',
    int casasDecimais = 2,
  }) {
    final desclassificadosIds = fornecedores
        .where((f) => f.desclassificado)
        .map((f) => f.id)
        .toList();
    final sb = StringBuffer();
    for (final item in itens) {
      final isMensal = item.tipoFornecimento == 'mensal';
      sb.writeln(
        '<div ${isInsideLote ? '' : 'style="border:1px solid #ccc; padding:8px; margin-bottom:8px;"'}>',
      );

      sb.writeln(
        '<h4 style="text-align: justify;">Item ${item.numero} - ${item.descricao}',
      );
      if (!isInsideLote &&
          (exclusividadeGlobal == 'exclusiva' ||
              (item.exclusivoMeEpp && exclusividadeGlobal == 'reservada'))) {
        sb.write(
          ' <span style="color:green; font-size:12pt;">${exclusividadeGlobal == 'exclusiva' ? '(Exclusivo ME/EPP)' : '(Reservado ME/EPP)'}</span>',
        );
      }
      sb.writeln('</h4>');

      sb.writeln(
        '<p style="font-size:12pt; color:#555;">Quantidade: ${item.quantidade} ${item.unidade} | ${isMensal ? "Fornecimento: Mensal (${item.quantidadeMeses} meses)" : "Fornecimento: Único"} | Regra Ref.: ${_getCalculoLabel(globalCalculo, isLote: isInsideLote)}</p>',
      );

      String? vencedorFornecedorId;
      double? minVal;
      double? maxVal;

      if (isInsideLote && globalCalculo == 'min_global') {
        vencedorFornecedorId = fornecedorVencedorId;
      } else if (globalCalculo == 'min') {
        final validOrcamentos = item.orcamentos
            .where(
              (e) =>
                  !desclassificadosIds.contains(e.fornecedorId) &&
                  e.valorUnitario > 0,
            )
            .toList();
        if (validOrcamentos.isNotEmpty) {
          minVal = validOrcamentos
              .map((e) => e.valorUnitario)
              .reduce((a, b) => a < b ? a : b);
        }
      } else if (globalCalculo == 'desc') {
        final validOrcamentos = item.orcamentos
            .where(
              (e) =>
                  !desclassificadosIds.contains(e.fornecedorId) &&
                  e.valorUnitario > 0,
            )
            .toList();
        if (validOrcamentos.isNotEmpty) {
          maxVal = validOrcamentos
              .map((e) => e.valorUnitario)
              .reduce((a, b) => a > b ? a : b);
        }
      }

      sb.writeln(
        '<table border="1" bordercolor="#ccc" cellpadding="4" cellspacing="0" style="width:100%; border-collapse:collapse; font-size:12pt; border: 1px solid #ccc;">',
      );
      sb.writeln(
        '<tr><th style="border: 1px solid #ccc;">Razão Social</th><th style="border: 1px solid #ccc; width: 1%; white-space: nowrap;">CPF/CNPJ</th><th style="border: 1px solid #ccc; width: 1%; white-space: nowrap;">Data</th><th style="border: 1px solid #ccc; width: 1%; white-space: nowrap;">Valor Unitário</th></tr>',
      );
      final orcamentosOrdenados = List<EstimativaOrcamento>.from(item.orcamentos)
        ..sort((a, b) => a.valorUnitario.compareTo(b.valorUnitario));
      for (final o in orcamentosOrdenados) {
        final f = fornecedores.where((f) => f.id == o.fornecedorId).firstOrNull;
        final isDesclassificado =
            f?.desclassificado == true ||
            desclassificadosIds.contains(o.fornecedorId);

        final bool isVencedor;
        if (isDesclassificado) {
          isVencedor = false;
        } else if (vencedorFornecedorId != null) {
          isVencedor = o.fornecedorId == vencedorFornecedorId;
        } else if (minVal != null) {
          isVencedor = o.valorUnitario == minVal;
        } else if (maxVal != null) {
          isVencedor = o.valorUnitario == maxVal;
        } else {
          isVencedor = false;
        }

        final razaoSocial = f?.razaoSocial ?? '-';
        final nomeComSufixo = isDesclassificado
            ? '$razaoSocial <span style="color: darkred;">(DESCLASSIFICADO)</span>'
            : razaoSocial;
        final trStyle = isVencedor ? ' style="background-color: #e8f5e9;"' : '';
        sb.writeln('<tr$trStyle>');
        sb.writeln('<td style="border: 1px solid #ccc;">$nomeComSufixo</td>');
        sb.writeln(
          '<td align="center" style="white-space: nowrap; border: 1px solid #ccc;">${AudespCpfCnpjField.formatDocument(f?.cnpj ?? '')}</td>',
        );
        sb.writeln(
          '<td align="center" style="white-space: nowrap; border: 1px solid #ccc;">${f?.data ?? '-'}</td>',
        );
        sb.writeln(
          '<td align="right" style="white-space: nowrap; border: 1px solid #ccc;">${fmt.format(o.valorUnitario)}</td>',
        );
        sb.writeln('</tr>');
      }
      sb.writeln('</table>');

      sb.writeln('<div style="text-align:right; margin-top:8px;">');
      sb.writeln(
        '<p style="margin:2px; font-size:12pt;">Valor de Referência Unitário: ${fmt.format(item.getValorReferenciaUnitario(globalCalculo, casasDecimais: casasDecimais, desclassificadosIds: desclassificadosIds, fornecedorVencedorId: fornecedorVencedorId))}</p>',
      );
      if (isMensal) {
        sb.writeln(
          '<p style="margin:2px; font-size:12pt;">Valor Estimado Mensal: ${fmt.format(item.getValorMensal(globalCalculo, casasDecimais: casasDecimais, desclassificadosIds: desclassificadosIds, fornecedorVencedorId: fornecedorVencedorId))}</p>',
        );
      }
      sb.writeln(
        '<p style="margin:2px; font-weight:bold; font-size:12pt;">Valor Estimado Total: ${fmt.format(item.getValorTotal(globalCalculo, casasDecimais: casasDecimais, desclassificadosIds: desclassificadosIds, fornecedorVencedorId: fornecedorVencedorId))}</p>',
      );
      sb.writeln('</div>');
      sb.writeln('</div>');
    }
    return sb.toString();
  }

  static String _getCalculoLabel(String calc, {bool isLote = false}) {
    if (calc == 'min') return isLote ? 'Menor Preço (Unitário)' : 'Menor Preço';
    if (calc == 'min_global') return 'Menor Preço (Global)';
    if (calc == 'avg') return 'Média';
    if (calc == 'median') return 'Mediana';
    return calc;
  }

  static String _getExclusividadeLabel(EstimativaModel estimativa) {
    if (estimativa.exclusividadeMeEpp == 'exclusiva') {
      return 'Exclusiva para ME/EPP (conforme Art. 48, I, da LFC nº 123/2006)';
    }
    if (estimativa.exclusividadeMeEpp == 'reservada') {
      final tipoStr = estimativa.tipoEstimativa == 'lote' ? 'lotes' : 'itens';
      String base =
          'Com $tipoStr reservados para ME/EPP (conforme Art. 48, III, da LFC nº 123/2006)';
      final exclusivos = <int>[];

      if (estimativa.tipoEstimativa == 'lote') {
        exclusivos.addAll(
          estimativa.lotes.where((l) => l.exclusivoMeEpp).map((l) => l.numero),
        );
        if (exclusivos.isNotEmpty) base += ' - Lotes: ${exclusivos.join(', ')}';
      } else {
        exclusivos.addAll(
          estimativa.itens.where((i) => i.exclusivoMeEpp).map((i) => i.numero),
        );
        if (exclusivos.isNotEmpty) base += ' - Itens: ${exclusivos.join(', ')}';
      }
      return base;
    }
    return 'Não exclusiva para ME/EPP';
  }

  static String? _getObservacaoBancoPrecos(EstimativaModel estimativa) {
    final bancosDePrecos = estimativa.fornecedores
        .where((f) => f.bancoDePrecos && f.razaoSocial.trim().isNotEmpty)
        .toList();

    if (bancosDePrecos.isEmpty) return null;

    final nomes = bancosDePrecos.map((f) => f.razaoSocial.trim()).toList();
    final String nomesStr;
    if (nomes.length == 1) {
      nomesStr = nomes.first;
    } else if (nomes.length == 2) {
      nomesStr = '${nomes[0]} e ${nomes[1]}';
    } else {
      nomesStr =
          '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';
    }

    if (nomes.length == 1) {
      return 'A razão social $nomesStr, corresponde a plataforma de Banco de Preços, utilizada como ferramenta de pesquisa de preços praticados em contratações públicas. O valor indicado não representa cotação comercial apresentada pela referida empresa, mas valor resultante da pesquisa realizada na plataforma, apurado a partir de múltiplos registros de contratações públicas de órgãos e entidades da Administração Pública.';
    } else {
      return 'As razões sociais $nomesStr, correspondem a plataformas de Banco de Preços, utilizadas como ferramentas de pesquisa de preços praticados em contratações públicas. Os valores indicados não representam cotações comerciais apresentadas pelas referidas empresas, mas valores resultantes da pesquisa realizada nas plataformas, apurados a partir de múltiplos registros de contratações públicas de órgãos e entidades da Administração Pública.';
    }
  }
}
