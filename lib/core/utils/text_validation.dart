String? validarTamanhoMaximo(String? value, int maxLength) {
  if (value != null && value.trim().length > maxLength) {
    return 'Máximo $maxLength caracteres';
  }
  return null;
}
