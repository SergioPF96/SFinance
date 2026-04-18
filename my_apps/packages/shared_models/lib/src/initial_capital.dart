class InitialCapital {
  const InitialCapital({
    required this.id,
    required this.amountCents,
    required this.isActive,
  }) : assert(id == 1, 'InitialCapital id must always be 1');

  /// Fixed to 1 — enforces single-row constraint.
  final int id;

  /// Starting balance in cents. Always >= 0.
  final int amountCents;

  /// True until the first transaction is saved; never reverts to true.
  final bool isActive;
}
