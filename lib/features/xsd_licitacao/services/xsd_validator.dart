// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:win32/win32.dart';

import '../models/xsd_licitacao_models.dart';

class XsdValidator {
  final AssetBundle? assets;
  const XsdValidator({this.assets});

  static const _assetFiles = <String>[
    'docs/tcesp/xsd/licitacao1/AUDESP4_LIC_REG_NAO1_2026_A.XSD',
    'docs/tcesp/xsd/licitacao3/AUDESP4_LIC_REG_NAO3_2026_A.XSD',
    'docs/tcesp/xsd/tagcomum/AUDESP4_COMUM_2026_A.XSD',
    'docs/tcesp/xsd/generico/AUDESP_TIPOSGENERICOS_2026_A.XSD',
  ];

  Future<XsdValidationResult> validate(
    String xml,
    XsdLicitacaoVariant variant,
  ) async {
    if (!Platform.isWindows) {
      return const XsdValidationResult.invalid(
        'A validação MSXML 6 está disponível somente no Windows.',
      );
    }
    final root = Directory(
      path.join(
        Directory.systemTemp.path,
        'audesp_xsd',
        XsdLicitacaoProfile.revision,
      ),
    );
    await _materialize(root);
    final xmlFile = File(path.join(root.path, 'validation-input.xml'));
    await xmlFile.writeAsBytes(_latin1Bytes(xml), flush: true);
    final schema = path.join(
      root.path,
      'docs',
      'tcesp',
      'xsd',
      variant == XsdLicitacaoVariant.nao1 ? 'licitacao1' : 'licitacao3',
      variant == XsdLicitacaoVariant.nao1
          ? 'AUDESP4_LIC_REG_NAO1_2026_A.XSD'
          : 'AUDESP4_LIC_REG_NAO3_2026_A.XSD',
    );
    return _validateMsxml(
      xmlFile.path,
      schema,
      variant == XsdLicitacaoVariant.nao1
          ? 'http://www.tce.sp.gov.br/audesp/xml/licitacao1'
          : 'http://www.tce.sp.gov.br/audesp/xml/licitacao3',
    );
  }

  Future<void> _materialize(Directory root) async {
    for (final asset in _assetFiles) {
      final target = File(path.joinAll([root.path, ...asset.split('/')]));
      if (await target.exists()) continue;
      await target.parent.create(recursive: true);
      final data = await (assets ?? rootBundle).load(asset);
      await target.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
  }

  XsdValidationResult _validateMsxml(
    String xmlPath,
    String schemaPath,
    String namespace,
  ) {
    final hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    final mustUninitialize = hr == S_OK || hr == S_FALSE;
    Dispatcher? cache;
    Dispatcher? document;
    try {
      cache = Dispatcher.fromProgID('Msxml2.XMLSchemaCache.6.0');
      document = Dispatcher.fromProgID('Msxml2.DOMDocument.6.0');
      _invoke(cache, 'add', [_bstr(namespace), _bstr(schemaPath)]);
      _setBool(document, 'async', false);
      _setBool(document, 'validateOnParse', true);
      _setBool(document, 'resolveExternals', true);
      final cacheVariant = calloc<VARIANT>();
      VariantInit(cacheVariant);
      cacheVariant.ref
        ..vt = VT_DISPATCH
        ..pdispVal = cache.dispatch;
      document.set('schemas', cacheVariant);
      free(cacheVariant);

      final loaded = _invoke(document, 'load', [_bstr(xmlPath)], result: true);
      final ok = loaded != null && loaded.ref.boolVal;
      if (loaded != null) {
        VariantClear(loaded);
        free(loaded);
      }
      if (!ok) return _parseError(document);

      final validation = _invoke(document, 'validate', const [], result: true);
      if (validation == null || validation.ref.vt != VT_DISPATCH) {
        return const XsdValidationResult.invalid(
          'MSXML não retornou o resultado da validação.',
        );
      }
      final error = Dispatcher(validation.ref.pdispVal);
      final code = _getInt(error, 'errorCode');
      final result = code == 0
          ? const XsdValidationResult.valid()
          : _readError(error);
      VariantClear(validation);
      free(validation);
      return result;
    } on WindowsException catch (error) {
      return XsdValidationResult.invalid('Falha no MSXML 6: ${error.message}');
    } finally {
      if (document != null) {
        document.dispatch.release();
        document.dispose();
      }
      if (cache != null) {
        cache.dispatch.release();
        cache.dispose();
      }
      if (mustUninitialize) CoUninitialize();
    }
  }

  XsdValidationResult _parseError(Dispatcher document) {
    final value = document.get('parseError');
    try {
      if (value.ref.vt != VT_DISPATCH) {
        return const XsdValidationResult.invalid(
          'Falha ao carregar o XML no MSXML.',
        );
      }
      return _readError(Dispatcher(value.ref.pdispVal));
    } finally {
      VariantClear(value);
      free(value);
    }
  }

  XsdValidationResult _readError(Dispatcher error) =>
      XsdValidationResult.invalid(
        _getString(error, 'reason').trim(),
        line: _getInt(error, 'line'),
        column: _getInt(error, 'linepos'),
      );

  int _getInt(Dispatcher object, String name) {
    final value = object.get(name);
    try {
      return value.ref.lVal;
    } finally {
      VariantClear(value);
      free(value);
    }
  }

  String _getString(Dispatcher object, String name) {
    final value = object.get(name);
    try {
      return value.ref.bstrVal == nullptr
          ? ''
          : value.ref.bstrVal.toDartString();
    } finally {
      VariantClear(value);
      free(value);
    }
  }

  void _setBool(Dispatcher object, String name, bool state) {
    final value = calloc<VARIANT>();
    VariantInit(value);
    value.ref
      ..vt = VT_BOOL
      ..boolVal = state;
    try {
      object.set(name, value);
    } finally {
      VariantClear(value);
      free(value);
    }
  }

  Pointer<VARIANT> _bstr(String value) {
    final result = calloc<VARIANT>();
    VariantInit(result);
    result.ref
      ..vt = VT_BSTR
      ..bstrVal = SysAllocString(value.toNativeUtf16());
    return result;
  }

  Pointer<VARIANT>? _invoke(
    Dispatcher object,
    String method,
    List<Pointer<VARIANT>> arguments, {
    bool result = false,
  }) {
    final params = calloc<DISPPARAMS>();
    final contiguous = arguments.isEmpty
        ? nullptr
        : calloc<VARIANT>(arguments.length);
    for (var i = 0; i < arguments.length; i++) {
      (contiguous + i).ref = arguments[arguments.length - i - 1].ref;
      free(arguments[arguments.length - i - 1]);
    }
    params.ref
      ..cArgs = arguments.length
      ..rgvarg = contiguous;
    final output = result ? calloc<VARIANT>() : null;
    if (output != null) VariantInit(output);
    try {
      object.invoke(method, params, output);
      return output;
    } finally {
      for (var i = 0; i < arguments.length; i++) {
        VariantClear(contiguous + i);
      }
      if (contiguous != nullptr) free(contiguous);
      free(params);
    }
  }

  List<int> _latin1Bytes(String value) {
    final result = <int>[];
    for (final rune in value.runes) {
      if (rune > 255)
        throw FormatException(
          'Caractere fora de ISO-8859-1: ${String.fromCharCode(rune)}',
        );
      result.add(rune);
    }
    return result;
  }
}
