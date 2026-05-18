class BarbershopFormValidator {
  static String? validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa el nombre de la barbería';
    if (text.length < 3) return 'Nombre demasiado corto';
    return null;
  }

  static String? validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa el teléfono';
    if (text.length < 8) return 'Teléfono inválido';
    return null;
  }

  static String? validateAddress(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa la dirección';
    return null;
  }
}
