/// Category filter for the Entradas view.
///
/// Each value except [all] maps directly to the raw category string
/// stored in the database (matching the enum name via [matches]).
enum CategoryFilter {
  all,
  producto,
  servicio,
  suscripcion,
  suministroVariable,
  financiacion,
  salario,
  venta;

  String get label {
    switch (this) {
      case CategoryFilter.all:
        return 'Todas';
      case CategoryFilter.producto:
        return 'Producto';
      case CategoryFilter.servicio:
        return 'Servicio';
      case CategoryFilter.suscripcion:
        return 'Suscripción';
      case CategoryFilter.suministroVariable:
        return 'Suministro variable';
      case CategoryFilter.financiacion:
        return 'Financiación';
      case CategoryFilter.salario:
        return 'Salario';
      case CategoryFilter.venta:
        return 'Venta';
    }
  }

  /// Returns true if [rawCategory] (as stored in the DB) matches this filter.
  bool matches(String rawCategory) {
    if (this == CategoryFilter.all) return true;
    return rawCategory == name;
  }
}
