/// Available time ranges for the Entradas filter and Análisis charts.
///
/// Pure Dart — no Flutter dependencies. Shared between providers and widgets.
enum TimeRange {
  ultimos7Dias,
  ultimoMes,
  ultimos3Meses,
  ultimoAnio,
  desdeOrigen;

  String get label {
    switch (this) {
      case TimeRange.ultimos7Dias:
        return 'Últimos 7 días';
      case TimeRange.ultimoMes:
        return 'Último mes';
      case TimeRange.ultimos3Meses:
        return 'Últimos 3 meses';
      case TimeRange.ultimoAnio:
        return 'Último año';
      case TimeRange.desdeOrigen:
        return 'Desde origen';
    }
  }

  /// Returns a [start, end] datetime pair for this range.
  ({DateTime start, DateTime end}) toDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: 1));

    switch (this) {
      case TimeRange.ultimos7Dias:
        return (start: today.subtract(const Duration(days: 6)), end: end);
      case TimeRange.ultimoMes:
        return (
          start: DateTime(now.year, now.month - 1, now.day),
          end: end,
        );
      case TimeRange.ultimos3Meses:
        return (
          start: DateTime(now.year, now.month - 3, now.day),
          end: end,
        );
      case TimeRange.ultimoAnio:
        return (
          start: DateTime(now.year - 1, now.month, now.day),
          end: end,
        );
      case TimeRange.desdeOrigen:
        return (
          start: DateTime(2000, 1, 1),
          end: end,
        );
    }
  }
}
