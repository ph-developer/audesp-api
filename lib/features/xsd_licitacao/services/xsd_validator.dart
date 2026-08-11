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
    // Validação MSXML desativada temporariamente conforme solicitação.
    return const XsdValidationResult.valid();
  }

  // ignore: unused_element
  Future<void> _materialize(Directory root) async {
    for (final asset in _assetFiles) {
      final target = File(path.joinAll([root.path, ...asset.split('/')]));
      if (await target.exists()) continue;
      await target.parent.create(recursive: true);
      final data = await (assets ?? rootBundle).load(asset);
      await target.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
  }

  // ignore: unused_element
  XsdValidationResult _validateMsxml(
    String xmlPath,
    String schemaPath,
    String namespace,
  ) {
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
      if (validation == null ||
          validation.ref.vt != VT_DISPATCH ||
          validation.ref.pdispVal.ptr == nullptr) {
        if (validation != null) {
          VariantClear(validation);
          free(validation);
        }
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
    } catch (error) {
      return XsdValidationResult.invalid('Falha no MSXML 6: $error');
    } finally {
      if (document != null) {
        try {
          document.dispose();
        } catch (_) {}
      }
      if (cache != null) {
        try {
          cache.dispose();
        } catch (_) {}
      }
    }
  }

  XsdValidationResult _parseError(Dispatcher document) {
    try {
      final value = document.get('parseError');
      try {
        if (value.ref.vt != VT_DISPATCH || value.ref.pdispVal.ptr == nullptr) {
          return const XsdValidationResult.invalid(
            'Falha ao carregar o XML no MSXML.',
          );
        }
        return _readError(Dispatcher(value.ref.pdispVal));
      } finally {
        VariantClear(value);
        free(value);
      }
    } catch (e) {
      return XsdValidationResult.invalid('Falha ao analisar erro do MSXML: $e');
    }
  }

  XsdValidationResult _readError(Dispatcher error) {
    final reason = _getString(error, 'reason').trim();
    final line = _getInt(error, 'line');
    final column = _getInt(error, 'linepos');
    return XsdValidationResult.invalid(
      reason.isEmpty ? 'Erro de validação XSD desativado/não especificável.' : reason,
      line: line,
      column: column,
    );
  }

  int _getInt(Dispatcher object, String name) {
    try {
      final value = object.get(name);
      try {
        if (value.ref.vt == VT_I4) return value.ref.lVal;
        if (value.ref.vt == VT_I2) return value.ref.iVal;
        if (value.ref.vt == VT_UI4) return value.ref.ulVal;
        return 0;
      } finally {
        VariantClear(value);
        free(value);
      }
    } catch (_) {
      return 0;
    }
  }

  String _getString(Dispatcher object, String name) {
    try {
      final value = object.get(name);
      try {
        if (value.ref.vt == VT_BSTR && value.ref.bstrVal != nullptr) {
          return value.ref.bstrVal.toDartString();
        }
        return '';
      } finally {
        VariantClear(value);
        free(value);
      }
    } catch (_) {
      return '';
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
    final nativeUtf16 = value.toNativeUtf16();
    result.ref
      ..vt = VT_BSTR
      ..bstrVal = SysAllocString(nativeUtf16);
    free(nativeUtf16);
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

  // ignore: unused_element
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
