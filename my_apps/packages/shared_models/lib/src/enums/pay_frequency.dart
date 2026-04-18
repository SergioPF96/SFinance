enum PayFrequency {
  docepagas,
  catorcepagas;

  String get displayLabel {
    switch (this) {
      case PayFrequency.docepagas:
        return '12 pagas';
      case PayFrequency.catorcepagas:
        return '14 pagas';
    }
  }
}
