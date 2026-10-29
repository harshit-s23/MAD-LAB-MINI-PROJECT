/// Number helpers that reproduce JavaScript's rounding / printing so values
/// match the original application exactly.
class JsNumber {
  JsNumber._();

  /// `parseFloat(value.toFixed(digits))`
  static double round(double value, int digits) =>
      double.parse(value.toStringAsFixed(digits));

  /// `String(number)` for the values used by the app: integers print without a
  /// decimal point ("27" not "27.0"), others use the shortest representation.
  static String toJsString(double value) {
    if (value == value.truncateToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  /// `Math.abs(v).toFixed(2)` (`formatCarbon` in constants.js).
  static String abs2(double v) => v.abs().toStringAsFixed(2);
}
