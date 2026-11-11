import 'package:flutter/material.dart';

/// Indicador compacto dos cartões: só o ícone, com [titulo] e [detalhe] na
/// tooltip.
class IndicadorIcone extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String? detalhe;

  const IndicadorIcone({
    super.key,
    required this.icone,
    required this.cor,
    required this.titulo,
    this.detalhe,
  });

  String get mensagem => detalhe == null ? titulo : '$titulo\n$detalhe';

  @override
  Widget build(BuildContext context) => Tooltip(
    message: mensagem,
    child: Semantics(
      label: mensagem,
      child: Container(
        width: 28,
        height: 28,
        decoration: ShapeDecoration(
          color: cor.withAlpha(20),
          shape: CircleBorder(side: BorderSide(color: cor.withAlpha(100))),
        ),
        child: Icon(icone, size: 16, color: cor),
      ),
    ),
  );
}
