import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/estimativa_item_model.dart';
import '../models/estimativa_lote_model.dart';

class EstimativaMatrizDialog extends StatelessWidget {
  final String tipoEstimativa;
  final List<EstimativaLote> lotes;
  final List<EstimativaItem> itens;

  const EstimativaMatrizDialog({
    super.key,
    required this.tipoEstimativa,
    required this.lotes,
    required this.itens,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, String> empresasMap = {};

    // Extrai todas as empresas
    if (tipoEstimativa == 'lote') {
      for (final lote in lotes) {
        for (final item in lote.itens) {
          for (final orc in item.orcamentos) {
            if (orc.razaoSocial.trim().isNotEmpty) {
              empresasMap[orc.razaoSocial.trim().toUpperCase()] =
                  'CNPJ: ${orc.cnpj}\nData: ${orc.data}';
            }
          }
        }
      }
    } else {
      for (final item in itens) {
        for (final orc in item.orcamentos) {
          if (orc.razaoSocial.trim().isNotEmpty) {
            empresasMap[orc.razaoSocial.trim().toUpperCase()] =
                'CNPJ: ${orc.cnpj}\nData: ${orc.data}';
          }
        }
      }
    }

    final empresasList = empresasMap.keys.toList()..sort();

    String truncateWord(String text, int max) {
      if (text.length <= max) return text;
      final sub = text.substring(0, max);

      final parts = sub.split(' ');
      if (parts.length > 1) {
        // Como cortamos no limite, a última string do split costuma ser uma palavra pela metade.
        // Se ela não terminar num espaço, nós a removemos para não exibir pedaços de palavras.
        if (!sub.endsWith(' ')) {
          parts.removeLast();
        }

        // Remove também se a última palavra inteira tiver 1 ou 2 letras (ex: 'de', 'e', 'a')
        while (parts.isNotEmpty && parts.last.length <= 2) {
          parts.removeLast();
        }

        if (parts.isNotEmpty) {
          return parts.join(' ');
        }
      }
      return '$sub...';
    }

    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return AlertDialog(
      title: const Text('Matriz de Valores'),
      content: SizedBox(
        width: double.maxFinite,
        child: empresasList.isEmpty
            ? const Center(
                child: Text(
                  'Nenhum orçamento cadastrado para exibir na matriz.',
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    border: TableBorder.all(
                      color: Theme.of(context).dividerColor,
                    ),
                    horizontalMargin: 12,
                    headingRowHeight: 72,
                    columnSpacing: 24,
                    headingRowColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    columns: [
                      if (tipoEstimativa == 'lote')
                        const DataColumn(
                          label: Center(
                            child: Text(
                              'Lote',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      const DataColumn(
                        label: Center(
                          child: Text(
                            'Item',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const DataColumn(
                        label: Center(
                          child: Text(
                            'Descritivo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      ...empresasList.map(
                        (e) => DataColumn(
                          label: Tooltip(
                            message: '$e\n${empresasMap[e]}',
                            child: Container(
                              width: 85,
                              alignment: Alignment.center,
                              child: Text(
                                truncateWord(e, 20),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Container(
                          width: 85,
                          alignment: Alignment.center,
                          child: Text(
                            'Menor',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Container(
                          width: 85,
                          alignment: Alignment.center,
                          child: Text(
                            'Média',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Container(
                          width: 85,
                          alignment: Alignment.center,
                          child: Text(
                            'Mediana',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                    rows: _buildRows(empresasList, fmt),
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  List<DataRow> _buildRows(List<String> empresas, NumberFormat fmt) {
    final rows = <DataRow>[];

    if (tipoEstimativa == 'lote') {
      for (final lote in lotes) {
        for (final item in lote.itens) {
          rows.add(
            _buildDataRow(
              'L${lote.numero}',
              '${item.numero}',
              item.descricao.toUpperCase(),
              item,
              empresas,
              fmt,
            ),
          );
        }
      }
    } else {
      for (final item in itens) {
        rows.add(
          _buildDataRow(
            '',
            '${item.numero}',
            item.descricao.toUpperCase(),
            item,
            empresas,
            fmt,
          ),
        );
      }
    }

    return rows;
  }

  DataRow _buildDataRow(
    String loteStr,
    String itemStr,
    String descritivo,
    EstimativaItem item,
    List<String> empresas,
    NumberFormat fmt,
  ) {
    final descTruncated = descritivo.length > 50
        ? '${descritivo.substring(0, 50)}...'
        : descritivo;

    return DataRow(
      cells: [
        if (tipoEstimativa == 'lote') DataCell(Center(child: Text(loteStr))),
        DataCell(Center(child: Text(itemStr))),
        DataCell(
          Tooltip(
            message: descritivo,
            child: SizedBox(
              width: 250,
              child: Text(
                descTruncated,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.justify,
              ),
            ),
          ),
        ),
        ...empresas.map((empresa) {
          // Busca orçamento para esta empresa
          final orc = item.orcamentos
              .where((o) => o.razaoSocial.trim().toUpperCase() == empresa)
              .firstOrNull;
          if (orc != null) {
            return DataCell(
              Container(
                width: 85,
                alignment: Alignment.center,
                child: Text(fmt.format(orc.valorUnitario)),
              ),
            );
          } else {
            return DataCell(
              Container(
                width: 85,
                alignment: Alignment.center,
                child: const Text('-', style: TextStyle(color: Colors.grey)),
              ),
            );
          }
        }),
        DataCell(
          Container(
            width: 85,
            alignment: Alignment.center,
            child: Text(
              fmt.format(item.getValorReferenciaUnitario('min')),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        DataCell(
          Container(
            width: 85,
            alignment: Alignment.center,
            child: Text(
              fmt.format(item.getValorReferenciaUnitario('avg')),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        DataCell(
          Container(
            width: 85,
            alignment: Alignment.center,
            child: Text(
              fmt.format(item.getValorReferenciaUnitario('median')),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
