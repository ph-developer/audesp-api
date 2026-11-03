import '../models/condutor.dart';

/// Regras do cadastro de condutores usado em `cpfsCondutores`.
abstract final class CondutorRules {
  static String normalizarCpf(String cpf) => cpf.replaceAll(RegExp(r'\D'), '');

  /// Confere os dígitos verificadores; sequências repetidas são inválidas.
  static bool cpfValido(String cpf) {
    final digitos = normalizarCpf(cpf);
    if (digitos.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(digitos)) {
      return false;
    }
    final numeros = digitos.split('').map(int.parse).toList();
    for (final tamanho in [9, 10]) {
      var soma = 0;
      for (var i = 0; i < tamanho; i++) {
        soma += numeros[i] * (tamanho + 1 - i);
      }
      final resto = soma * 10 % 11;
      if ((resto == 10 ? 0 : resto) != numeros[tamanho]) return false;
    }
    return true;
  }

  static String formatarCpf(String cpf) {
    final d = normalizarCpf(cpf);
    if (d.length != 11) return cpf;
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.'
        '${d.substring(6, 9)}-${d.substring(9)}';
  }

  static String? validarNome(String? nome) {
    final texto = nome?.trim() ?? '';
    if (texto.isEmpty) return 'Obrigatório';
    if (texto.length > 255) return 'Máximo 255 caracteres';
    return null;
  }

  static String? validarCpf(String? cpf, Iterable<Condutor> cadastrados) {
    final digitos = normalizarCpf(cpf ?? '');
    if (digitos.isEmpty) return 'Obrigatório';
    if (!cpfValido(digitos)) return 'CPF inválido';
    if (cadastrados.any((c) => c.cpf == digitos)) return 'CPF já cadastrado';
    return null;
  }

  /// CPFs da licitação depois de escolher no cadastro.
  ///
  /// CPFs que não estão no cadastro (enviados antes dele ou excluídos dele)
  /// continuam na licitação; os do cadastro seguem a seleção. A ordem atual é
  /// mantida e os novos entram ao final, na ordem do cadastro.
  static List<String> aplicarSelecao({
    required List<String> atuais,
    required Iterable<Condutor> cadastrados,
    required Set<String> selecionados,
  }) {
    final doCadastro = cadastrados.map((c) => c.cpf).toSet();
    final resultado = atuais
        .where((cpf) => !doCadastro.contains(cpf) || selecionados.contains(cpf))
        .toList();
    for (final condutor in cadastrados) {
      if (selecionados.contains(condutor.cpf) &&
          !resultado.contains(condutor.cpf)) {
        resultado.add(condutor.cpf);
      }
    }
    return resultado;
  }
}
