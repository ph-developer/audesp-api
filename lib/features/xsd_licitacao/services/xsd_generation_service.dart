import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../core/database/daos/xsd_licitacao_logs_dao.dart';
import '../../../core/database/daos/xsd_licitacao_profiles_dao.dart';
import '../models/xsd_licitacao_models.dart';
import 'xsd_domain_rules.dart';
import 'xsd_export_service.dart';
import 'xsd_licitacao_builder.dart';
import 'xsd_source_normalizer.dart';
import 'xsd_validator.dart';

class XsdGenerationService {
  final XsdValidator validator;
  final XsdExportService exporter;
  final XsdLicitacaoProfilesDao profiles;
  final XsdLicitacaoLogsDao logs;

  const XsdGenerationService({
    required this.validator,
    required this.exporter,
    required this.profiles,
    required this.logs,
  });

  Future<XsdBuildResult> generateAndSave({
    required int licitacaoId,
    required XsdLicitacaoSource source,
    required XsdLicitacaoProfile profile,
    required String outputPath,
  }) async {
    final variant = XsdDomainRules.selectVariant(source);
    final effectiveProfile = const XsdSourceNormalizer().mergeProfile(
      source: source,
      persisted: profile,
    );
    final xml = XsdLicitacaoBuilder.build(
      source: source,
      profile: effectiveProfile,
    );
    final markdown = XsdMarkdownBuilder.build(
      xml,
      title: 'Licitação ${source.numeroCompra}/${source.anoCompra}',
    );
    final validation = await validator.validate(xml, variant);
    final baseName = _baseName(source, variant);
    final result = XsdBuildResult(
      xml: xml,
      markdown: markdown,
      variant: variant,
      baseName: baseName,
      validation: validation,
    );
    if (!validation.isValid) throw FormatException(validation.displayMessage);
    await exporter.writePair(
      selectedXmlPath: outputPath,
      xml: xml,
      markdown: markdown,
      beforeFinalize: (hashes) async {
        await profiles.upsert(licitacaoId, effectiveProfile);
        await logs.insertLog(
          XsdLicitacaoLogEntry(
            licitacaoId: licitacaoId,
            variant: variant.name,
            revision: XsdLicitacaoProfile.revision,
            baseName: baseName,
            xmlSha256: hashes.xml,
            markdownSha256: hashes.markdown,
            editalSourceSha256: _hashJson(source.editalJson),
            licitacaoSourceSha256: _hashJson(source.licitacaoJson),
            profileSnapshot: effectiveProfile.encode(),
          ),
        );
      },
    );
    return result;
  }

  String _baseName(XsdLicitacaoSource source, XsdLicitacaoVariant variant) {
    final number = source.numeroCompra.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    return 'licitacao_${variant.name}_${number}_${source.anoCompra}'
        .toLowerCase();
  }

  String _hashJson(Map<String, dynamic> value) =>
      sha256.convert(utf8.encode(jsonEncode(value))).toString();
}
