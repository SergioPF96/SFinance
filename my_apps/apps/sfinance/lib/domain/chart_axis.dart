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
/// Examples: 0 → "€0", 4200 → "€42", 120000 → "€1,2k", 100000000 → "€1,0M"
String formatAxisLabel(double cents) {
  final euros = cents.abs() / 100;
  String sign = cents < 0 ? '-' : '';
  if (euros >= 1000000) {
    return '$sign€${_compact(euros / 1000000)}M';
  }
  if (euros >= 1000) {
    return '$sign€${_compact(euros / 1000)}k';
  }
  return '$sign€${euros.round()}';
}

String _compact(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
