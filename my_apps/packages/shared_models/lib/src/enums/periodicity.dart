enum Periodicity {
  mensual,
  anual;

  String get displayLabel {
    switch (this) {
      case Periodicity.mensual:
        return 'Mensual';
      case Periodicity.anual:
        return 'Anual';
    }
  }
}
