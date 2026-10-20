class BanglaNumberConverter {
  static const Map<String, String> _englishToBanglaDigits = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
    '.': '.',
  };

  static const Map<String, String> _banglaToEnglishDigits = {
    '০': '0',
    '১': '1',
    '২': '2',
    '৩': '3',
    '৪': '4',
    '৫': '5',
    '৬': '6',
    '৭': '7',
    '৮': '8',
    '৯': '9',
  };

  /// Converts any integer, double, or numeric string to Bangla digits.
  static String toBangla(dynamic value) {
    if (value == null) return '০';
    final String str = value.toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      if (_englishToBanglaDigits.containsKey(char)) {
        buffer.write(_englishToBanglaDigits[char]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// Converts Bangla numeric string to English numeric string for calculations.
  static String toEnglish(String banglaStr) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < banglaStr.length; i++) {
      final char = banglaStr[i];
      if (_banglaToEnglishDigits.containsKey(char)) {
        buffer.write(_banglaToEnglishDigits[char]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// Formats currency with Taka symbol in Bengali (e.g. ৳ ২,৫০০)
  static String formatCurrency(num amount) {
    // Format with 2 decimal places if has fractional value
    final formatted = amount % 1 == 0
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
    return '৳ ${toBangla(formatted)}';
  }

  /// Formats weight in Kg or Mon
  static String formatWeight(num amountInKg) {
    if (amountInKg >= 40) {
      final double mon = amountInKg / 40.0;
      final String formattedMon = mon % 1 == 0
          ? mon.toInt().toString()
          : mon.toStringAsFixed(1);
      return '${toBangla(formattedMon)} মণ (${toBangla(amountInKg.toStringAsFixed(0))} কেজি)';
    }
    final String formattedKg = amountInKg % 1 == 0
        ? amountInKg.toInt().toString()
        : amountInKg.toStringAsFixed(1);
    return '${toBangla(formattedKg)} কেজি';
  }
}
