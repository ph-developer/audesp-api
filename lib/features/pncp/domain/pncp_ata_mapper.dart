import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';

/// Somente as correspondências do schema ata-20261015, já normalizadas.
abstract final class PncpAtaMapper {
  static Map<String, dynamic> documento(PncpAta ata, {required Edital edital}) {
    final documento = <String, dynamic>{
      'descritor': {
        'codigoAta': ata.numeroControle,
        'codigoEdital': edital.codigoEdital.trim(),
        'anoCompra': ata.anoCompra,
        'retificacao': false,
      },
      'numeroItem': <int>[],
      if (ata.numeroAta.isNotEmpty && ata.numeroAta.length <= 30)
        'numeroAtaRegistroPreco': ata.numeroAta,
      if (ata.anoAta != null && ata.anoAta! >= 1950 && ata.anoAta! <= 2100)
        'anoAta': ata.anoAta,
    };
    for (final (campo, data) in [
      ('dataAssinatura', ata.dataAssinatura),
      ('dataVigenciaInicio', ata.vigenciaInicio),
      ('dataVigenciaFim', ata.vigenciaFim),
    ]) {
      if (data != null) {
        documento[campo] = DateFormat('yyyy-MM-dd').format(data);
      }
    }
    // Os itens da ata não constam nestes endpoints: o usuário deve selecioná-los
    // entre os itens da licitação. Não deduzimos itens pelo objeto da compra.
    // Objeto, publicação, cancelamento e adesão não têm campos neste schema.
    // Município e entidade continuam vindo da configuração do formulário.
    // Dados ausentes ou fora dos limites do schema ficam para preenchimento.
    return documento;
  }
}
