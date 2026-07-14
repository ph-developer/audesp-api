import 'package:audesp_api/features/licitacao/services/open_cnpj_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifica microempresa como ME', () {
    expect(
      OpenCnpjService.classificarDeclaracaoMeEpp(
        porteEmpresa: 'Micro Empresa',
      ),
      1,
    );
  });

  test('classifica empresa de pequeno porte como EPP', () {
    expect(
      OpenCnpjService.classificarDeclaracaoMeEpp(
        porteEmpresa: 'Empresa de Pequeno Porte (EPP)',
      ),
      2,
    );
  });

  test('classifica optante MEI como ME', () {
    expect(
      OpenCnpjService.classificarDeclaracaoMeEpp(
        porteEmpresa: 'Demais',
        opcaoMei: 'S',
      ),
      1,
    );
  });

  test('classifica demais portes como não ME/EPP', () {
    expect(
      OpenCnpjService.classificarDeclaracaoMeEpp(
        porteEmpresa: 'Demais',
        opcaoMei: 'N',
      ),
      3,
    );
  });
}
