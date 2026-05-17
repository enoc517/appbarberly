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

  static String? validateLat(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Requerido';
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Inválido';
    if (parsed < -90 || parsed > 90) return 'Inválido';
    return null;
  }

  static String? validateLng(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Requerido';
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Inválido';
    if (parsed < -180 || parsed > 180) return 'Inválido';
    return null;
  }
}
