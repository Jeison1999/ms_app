/// Normalización de textos libres (ciudad, etc.) para evitar duplicados
/// por mayúsculas/minúsculas o espacios ("soledad" vs "Soledad").
class PersonTextNormalize {
  PersonTextNormalize._();

  static String collapseSpaces(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// "soledad" / "SOLEDAD" / "  la  soledad " → "Soledad" / "La Soledad"
  static String titleCase(String value) {
    final trimmed = collapseSpaces(value);
    if (trimmed.isEmpty) return trimmed;
    return trimmed.split(' ').map((word) {
      if (word.isEmpty) return word;
      final lower = word.toLowerCase();
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }).join(' ');
  }

  /// Deduplica ignorando mayúsculas; opcionalmente unifica el texto mostrado.
  static List<String> uniqueIgnoreCase(
    Iterable<dynamic> values, {
    String Function(String raw)? canonicalize,
  }) {
    final seen = <String, String>{};
    for (final raw in values) {
      final trimmed = collapseSpaces(raw.toString());
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      final display =
          canonicalize != null ? canonicalize(trimmed) : trimmed;
      final existing = seen[key];
      if (existing == null) {
        seen[key] = display;
        continue;
      }
      if (canonicalize == null &&
          existing == existing.toLowerCase() &&
          display != display.toLowerCase()) {
        seen[key] = display;
      }
    }
    final list = seen.values.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// Alinea un valor al item canónico de la lista (mismo texto sin importar casing).
  static String? matchInList(String? value, List<String> options) {
    if (value == null) return null;
    final key = collapseSpaces(value).toLowerCase();
    if (key.isEmpty) return null;
    for (final option in options) {
      if (option.toLowerCase() == key) return option;
    }
    return value;
  }
}
