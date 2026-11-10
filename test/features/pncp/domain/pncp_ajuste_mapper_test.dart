import 'dart:convert';
import 'dart:io';

import 'package:audesp_api/features/pncp/domain/pncp_ajuste_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pncp_fixtures.dart';

void main() {
  test('mapeia o cabeçalho com referências locais e dados existentes', () {
    final doc = PncpAjusteMapper.documento(
      contratoPncpJson(),
      adesaoParticipacao: false,
      codigoEdital: 'LOCAL-352/2025',
    );
    expect(doc['descritor'], {
      'codigoContrato': '4639500000013920000022026',
      'codigoEdital': 'LOCAL-352/2025',
      'adesaoParticipacao': false,
      'retificacao': false,
    });
    expect(doc['anoContrato'], 2026);
    expect(doc['numeroContratoEmpenho'], '3');
    expect(doc['processo'], '329');
    expect(doc['tipoContratoId'], 8);
    expect(doc['categoriaProcessoId'], 8);
    expect(doc['tipoPessoaFornecedor'], 'PJ');
    expect(doc['niFornecedor'], '24195949000152');
    expect(doc['nomeRazaoSocialFornecedor'], 'Fornecedor de teste LTDA');
    expect(doc['objetoContrato'], 'Prestação de serviços de manutenção');
    expect(doc['dataAssinatura'], '2026-03-09');
    expect(doc['datavigenciaInicio'], '2026-03-09');
    expect(doc.containsKey('dataVigenciaInicio'), isFalse);
    expect(doc['dataVigenciaFim'], '2027-03-09');
    expect(doc['valorInicial'], 16200);
    expect(doc['valorGlobal'], 16200);
    expect(doc['valorParcela'], 16200);
    expect(doc['valorAcumulado'], 16200);
    expect(doc['numeroParcelas'], 1);
    expect(doc['itens'], isEmpty);
    expect(doc.containsKey('tipoObjetoContrato'), isFalse);
    expect(doc.containsKey('fonteRecursosContratacao'), isFalse);
    expect(doc.containsKey('despesas'), isFalse);
  });

  test('adesão usa a compra PNCP mesmo havendo edital local', () {
    final doc = PncpAjusteMapper.documento(
      {
        ...contratoPncpJson(),
        'numeroControlePncpCompra': '49576416000141-1-000352/2026',
      },
      adesaoParticipacao: true,
      codigoEdital: 'edital-local',
    );
    expect(doc['descritor']['adesaoParticipacao'], isTrue);
    expect(doc['descritor']['codigoEdital'], '4957641600014110003522026');
    expect(doc['descritor'].containsKey('gerenciadoraJurisdicionada'), isFalse);
    expect(doc['descritor'].containsKey('codigoAta'), isFalse);
  });

  test('PF e PJ só têm dígitos; estrangeiro preserva letras', () {
    for (final (tipo, ni, esperado) in [
      ('PF', '123.456.789-09', '12345678909'),
      ('PE', ' AB-123/XY ', 'AB-123/XY'),
    ]) {
      final doc = PncpAjusteMapper.documento({
        ...contratoPncpJson(),
        'tipoPessoa': tipo,
        'niFornecedor': ni,
      }, adesaoParticipacao: false);
      expect(doc['niFornecedor'], esperado);
      expect(doc['tipoPessoaFornecedor'], tipo);
    }
  });

  test('não fabrica valores, parcelas, datas ou códigos de domínio', () {
    final doc = PncpAjusteMapper.documento({
      'tipoContrato': {'id': 6},
      'categoriaProcesso': {'id': 99},
      'tipoPessoa': 'XX',
      'dataAssinatura': 'não informada',
      'numeroParcelas': 0,
    }, adesaoParticipacao: false);
    expect(doc.keys.toSet(), {'descritor', 'itens'});
  });

  test('todos os códigos importados pertencem ao enum do schema vigente', () {
    final schema = jsonDecode(
      File('docs/tcesp/ajuste-20261015/ajuste_schema.json').readAsStringSync(),
    );
    for (var codigo = 1; codigo <= 15; codigo++) {
      final doc = PncpAjusteMapper.documento({
        'tipoContrato': {'id': codigo},
        'categoriaProcesso': {'id': codigo},
      }, adesaoParticipacao: false);
      for (final campo in ['tipoContratoId', 'categoriaProcessoId']) {
        if (doc.containsKey(campo)) {
          expect(schema['properties'][campo]['enum'], contains(doc[campo]));
        }
      }
    }
  });
}
