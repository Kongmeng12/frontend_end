class DateUtil {
  /// Converts any ISO-ish date string → dd/MM/yyyy display format.
  /// Input can be yyyy-MM-dd or full ISO datetime like 2025-06-15T10:30:00.
  static String fmt(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final s = raw.length >= 10 ? raw.substring(0, 10) : raw;
    final p = s.split('-');
    if (p.length != 3) return s;
    return '${p[2]}/${p[1]}/${p[0]}';
  }
}
