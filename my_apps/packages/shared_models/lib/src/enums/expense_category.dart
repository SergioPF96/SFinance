enum ExpenseCategory {
  producto,
  servicio,
  suscripcion,
  suministroVariable,
  financiacion;

  String get displayLabel {
    switch (this) {
      case ExpenseCategory.producto:
        return 'Producto';
      case ExpenseCategory.servicio:
        return 'Servicio';
      case ExpenseCategory.suscripcion:
        return 'Suscripcion';
      case ExpenseCategory.suministroVariable:
        return 'Suministro variable';
      case ExpenseCategory.financiacion:
        return 'Financiacion';
    }
  }
}
