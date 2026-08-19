// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';

import 'package:crypto/crypto.dart';

class XsdExportService {
  const XsdExportService();

  Future<String> writeXml({
    required String selectedXmlPath,
    required String xml,
    Future<void> Function(String xmlSha256)? beforeFinalize,
  }) async {
    final xmlPath = selectedXmlPath.toLowerCase().endsWith('.xml')
        ? selectedXmlPath
        : '$selectedXmlPath.xml';
    final nonce = DateTime.now().microsecondsSinceEpoch;
    final xmlTemp = File('$xmlPath.$nonce.tmp');
    final xmlTarget = File(xmlPath);
    final xmlBackup = File('$xmlPath.$nonce.bak');
    var xmlBackedUp = false;
    var xmlCommitted = false;
    try {
      final xmlBytes = _latin1(xml);
      await xmlTemp.writeAsBytes(xmlBytes, flush: true);
      if (await xmlTarget.exists()) {
        await xmlTarget.rename(xmlBackup.path);
        xmlBackedUp = true;
      }
      await xmlTemp.rename(xmlTarget.path);
      xmlCommitted = true;
      final xmlSha256 = sha256.convert(xmlBytes).toString();
      if (beforeFinalize != null) await beforeFinalize(xmlSha256);
      if (xmlBackedUp) {
        try {
          await xmlBackup.delete();
        } catch (_) {}
      }
      return xmlSha256;
    } catch (_) {
      if (xmlCommitted && await xmlTarget.exists()) await xmlTarget.delete();
      if (xmlBackedUp && await xmlBackup.exists())
        await xmlBackup.rename(xmlTarget.path);
      rethrow;
    } finally {
      if (await xmlTemp.exists()) await xmlTemp.delete();
    }
  }

  List<int> _latin1(String value) {
    final bytes = <int>[];
    for (final rune in value.runes) {
      if (rune > 255) {
        throw FormatException(
          'XML contém caractere fora de ISO-8859-1: ${String.fromCharCode(rune)}',
        );
      }
      bytes.add(rune);
    }
    return bytes;
  }
}
