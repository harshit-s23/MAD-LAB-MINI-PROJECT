import 'dart:math' as math;

/// "Nice" axis bounds (like Recharts' automatic domain, which always includes 0).
class AxisScale {
  const AxisScale(this.min, this.max, this.interval);

  final double min;
  final double max;
  final double interval;
}

AxisScale niceScale(double minValue, double maxValue, {int ticks = 4}) {
  var lo = math.min(0.0, minValue);
  var hi = math.max(0.0, maxValue);
  if (hi - lo < 1e-9) hi = lo + 1;
  final raw = (hi - lo) / ticks;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final norm = raw / mag;
  final step = (norm <= 1
          ? 1
          : norm <= 2
              ? 2
              : norm <= 2.5
                  ? 2.5
                  : norm <= 5
                      ? 5
                      : 10) *
      mag;
  lo = (lo / step).floorToDouble() * step;
  hi = (hi / step).ceilToDouble() * step;
  return AxisScale(lo == 0 ? 0 : lo, hi, step);
}
