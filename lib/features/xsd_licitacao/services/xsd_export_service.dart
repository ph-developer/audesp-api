// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

class XsdExportHashes {
  final String xml;
  final String markdown;
  const XsdExportHashes(this.xml, this.markdown);
}

class XsdExportService {
  const XsdExportService();

  Future<XsdExportHashes> writePair({
    required String selectedXmlPath,
    required String xml,
    required String markdown,
    Future<void> Function(XsdExportHashes hashes)? beforeFinalize,
  }) async {
    final xmlPath = selectedXmlPath.toLowerCase().endsWith('.xml')
        ? selectedXmlPath
        : '$selectedXmlPath.xml';
    final markdownPath = path.setExtension(xmlPath, '.md');
    final nonce = DateTime.now().microsecondsSinceEpoch;
    final xmlTemp = File('$xmlPath.$nonce.tmp');
    final mdTemp = File('$markdownPath.$nonce.tmp');
    final xmlTarget = File(xmlPath);
    final mdTarget = File(markdownPath);
    final xmlBackup = File('$xmlPath.$nonce.bak');
    final mdBackup = File('$markdownPath.$nonce.bak');
    var xmlBackedUp = false;
    var mdBackedUp = false;
    var xmlCommitted = false;
    var mdCommitted = false;
    try {
      final xmlBytes = _latin1(xml);
      final markdownBytes = utf8.encode(markdown);
      await xmlTemp.writeAsBytes(xmlBytes, flush: true);
      await mdTemp.writeAsBytes(markdownBytes, flush: true);
      if (await xmlTarget.exists()) {
        await xmlTarget.rename(xmlBackup.path);
        xmlBackedUp = true;
      }
      if (await mdTarget.exists()) {
        await mdTarget.rename(mdBackup.path);
        mdBackedUp = true;
      }
      await xmlTemp.rename(xmlTarget.path);
      xmlCommitted = true;
      await mdTemp.rename(mdTarget.path);
      mdCommitted = true;
      final hashes = XsdExportHashes(
        sha256.convert(xmlBytes).toString(),
        sha256.convert(markdownBytes).toString(),
      );
      if (beforeFinalize != null) await beforeFinalize(hashes);
      if (xmlBackedUp) {
        try {
          await xmlBackup.delete();
        } catch (_) {}
      }
      if (mdBackedUp) {
        try {
          await mdBackup.delete();
        } catch (_) {}
      }
      return hashes;
    } catch (_) {
      if (xmlCommitted && await xmlTarget.exists()) await xmlTarget.delete();
      if (mdCommitted && await mdTarget.exists()) await mdTarget.delete();
      if (xmlBackedUp && await xmlBackup.exists())
        await xmlBackup.rename(xmlTarget.path);
      if (mdBackedUp && await mdBackup.exists())
        await mdBackup.rename(mdTarget.path);
      rethrow;
    } finally {
      if (await xmlTemp.exists()) await xmlTemp.delete();
      if (await mdTemp.exists()) await mdTemp.delete();
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
