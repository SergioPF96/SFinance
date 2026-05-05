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
        return 'Suscripción';
      case ExpenseCategory.suministroVariable:
        return 'Suministro variable';
      case ExpenseCategory.financiacion:
        return 'Financiación';
    }
  }
}
