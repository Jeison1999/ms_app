class PersonValidators {
  static final RegExp _lettersOnly = RegExp(
    r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ'’\-\s]+$",
  );
  static final RegExp _digitsOnly = RegExp(r'^\d+$');
  static final RegExp _alphanumeric = RegExp(r'^[A-Za-z0-9]+$');
  static final RegExp _email = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  /// CC / TI / RC (o sin tipo): solo dígitos 5–20.
  static bool isDigitDocumentType(String? type) {
    if (type == null || type.isEmpty) return true;
    return const {'CC', 'TI', 'RC'}.contains(type.toUpperCase());
  }

  static String sanitizePhone(String input) {
    return input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  static String? name(String? value, {required String label}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$label es obligatorio';
    if (!_lettersOnly.hasMatch(v)) {
      return '$label solo puede contener letras';
    }
    return null;
  }

  static String? documentNumber(String? value, String? documentType) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // opcional

    if (isDigitDocumentType(documentType)) {
      if (!_digitsOnly.hasMatch(v)) {
        return 'La cédula solo puede contener dígitos';
      }
      if (v.length < 5 || v.length > 20) {
        return 'La cédula debe tener entre 5 y 20 dígitos';
      }
      return null;
    }

    if (!_alphanumeric.hasMatch(v)) {
      return 'Documento inválido (solo letras y números)';
    }
    if (v.length < 3 || v.length > 30) {
      return 'Documento debe tener entre 3 y 30 caracteres';
    }
    return null;
  }

  static String? phone(String? value) {
    final v = sanitizePhone(value ?? '');
    if (v.isEmpty) return null;
    if (!_digitsOnly.hasMatch(v)) {
      return 'El teléfono solo puede contener dígitos';
    }
    if (v.length < 7 || v.length > 15) {
      return 'Teléfono inválido';
    }
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!_email.hasMatch(v)) return 'Email inválido';
    return null;
  }

  static String? birthDate(DateTime? date) {
    if (date == null) return null;
    final today = DateTime.now();
    final onlyDate = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (onlyDate.isAfter(todayOnly)) {
      return 'La fecha de nacimiento no puede ser futura';
    }
    return null;
  }
}
