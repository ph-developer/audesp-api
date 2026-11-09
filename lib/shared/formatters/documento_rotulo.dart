import '../../core/database/app_database.dart';
import 'pcnp_input_formatter.dart';

String tituloEdital(Edital edital) => [
  edital.semPncp
      ? edital.codigoEdital
      : PcnpInputFormatter.applyMask(edital.idContratacaoPNCP),
  if (edital.modalidadeLabel.isNotEmpty &&
      edital.numeroCompra.isNotEmpty &&
      edital.anoCompra != 0)
    '${edital.modalidadeLabel} ${edital.numeroCompra}/${edital.anoCompra}',
].where((p) => p.isNotEmpty).join(' - ');

String tituloLicitacao(Licitacao licitacao, Edital? edital) => edital != null
    ? tituloEdital(edital)
    : PcnpInputFormatter.applyMask(licitacao.codigoEdital);

String tituloAta(Ata ata) => [
  PcnpInputFormatter.applyMask(ata.codigoAta),
  if (ata.numeroAtaRegistroPreco.isNotEmpty && ata.anoAta != 0)
    'Ata ${ata.numeroAtaRegistroPreco}/${ata.anoAta}',
].join(' - ');

String tituloAjuste(Ajuste ajuste) => [
  PcnpInputFormatter.applyMask(ajuste.codigoContrato),
  if (ajuste.numeroContratoEmpenho.isNotEmpty && ajuste.anoContrato != 0)
    'Ajuste ${ajuste.numeroContratoEmpenho}/${ajuste.anoContrato}',
].join(' - ');
