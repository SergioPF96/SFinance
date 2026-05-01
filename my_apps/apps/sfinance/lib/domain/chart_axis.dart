import 'dart:math' as math;

/// Returns a "nice" interval for chart Y axis given a [range] of values.
///
/// Divides the range into approximately 4 readable intervals using
/// multiples of 1, 2, or 5 × a power of 10.
double niceInterval(double range) {
  if (range <= 0) return 1.0;
  final rough = range / 4;
  final mag = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  final norm = rough / mag;
  final nice = norm < 1.5
      ? 1.0
      : norm < 3
          ? 2.0
          : norm < 7
              ? 5.0
              : 10.0;
  return nice * mag;
}

/// Formats a value in cents as an abbreviated axis label.
///
/// Pass [intervalCents] (the axis tick spacing in cents) to get the right
/// decimal precision — e.g. a 1000-cent step in "k" range needs 2 decimals
/// so "€1,41k" and "€1,42k" are visually distinct.
///
/// Examples: 0 → "€0", 4200 → "€42", 120000 → "€1,2k", 100000000 → "€1,0M"
String formatAxisLabel(double cents, {double? intervalCents}) {
  final euros = cents.abs() / 100;
  final String sign = cents < 0 ? '-' : '';
  if (euros >= 1000000) {
    final prec = _precisionForScale(intervalCents, 100 * 1000000);
    return '$sign€${_compactPrec(euros / 1000000, prec)}M';
  }
  if (euros >= 1000) {
    final prec = _precisionForScale(intervalCents, 100 * 1000);
    return '$sign€${_compactPrec(euros / 1000, prec)}k';
  }
  return '$sign€${euros.round()}';
}

/// How many decimal places to show given the axis step size in the scaled unit.
int _precisionForScale(double? intervalCents, double scaleCents) {
  if (intervalCents == null) return 1;
  final step = intervalCents / scaleCents;
  if (step >= 1) return 0;
  if (step >= 0.1) return 1;
  return 2;
}

String _compactPrec(double value, int decimals) {
  if (decimals == 0) return value.round().toString();
  final s = value.toStringAsFixed(decimals);
  final trimmed = s.replaceAll(RegExp(r'0+$'), '');
  // If all decimals trimmed away (e.g. "25."), drop the dot too.
  final result =
      trimmed.endsWith('.') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  return result.replaceAll('.', ',');
}
