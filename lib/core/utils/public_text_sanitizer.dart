class PublicTextSanitizer {
  static const _fallbackDescription =
      'Aún no hay una descripción completa para este lugar.';

  static String? cleanOptional(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty || _looksInternal(text)) {
      return null;
    }
    return text;
  }

  static String cleanDescription(String? value) {
    return cleanOptional(value) ?? _fallbackDescription;
  }

  static bool _looksInternal(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('usar solo para') ||
        normalized.contains('cuando el usuario lo pida explícitamente') ||
        normalized.contains('cuando el usuario lo pida explicitamente') ||
        normalized.contains('check-in, check-out o descanso') ||
        normalized.contains('prompt') && normalized.contains('backend') ||
        normalized.contains('instrucción interna') ||
        normalized.contains('instruccion interna');
  }
}
