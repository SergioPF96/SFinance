enum IncomeCategory {
  salario,
  venta,
  servicio;

  String get displayLabel {
    switch (this) {
      case IncomeCategory.salario:
        return 'Salario';
      case IncomeCategory.venta:
        return 'Venta';
      case IncomeCategory.servicio:
        return 'Servicio';
    }
  }
}
