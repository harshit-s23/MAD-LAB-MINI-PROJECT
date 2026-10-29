/// Date helpers.
///
/// All dates in the database are `yyyy-MM-dd` strings (Sequelize DATEONLY in
/// the original app) so they compare correctly as plain text in SQL.
///
/// NOTE (documented deviation): the original web app derived "today" from
/// `new Date().toISOString()`, i.e. the UTC calendar date. On a phone that
/// would roll the day over at 05:30 for users in India, so the mobile app uses
/// the device's *local* calendar date instead. To restore the original
/// behaviour, make [AppDate.dayOf] use `d.toUtc()`.
class AppDate {
  AppDate._();

  /// Overridable clock so tests can control "now".
  static DateTime Function() now = DateTime.now;

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// `yyyy-MM-dd` for the calendar day of [d].
  static String dayOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  static String today() => dayOf(now());

  /// Calendar-day subtraction (immune to DST shifts).
  static DateTime minusDays(DateTime from, int days) =>
      DateTime(from.year, from.month, from.day - days);

  /// `yyyy-MM-dd` for [days] before [from] (defaults to now).
  static String daysAgo(int days, {DateTime? from}) =>
      dayOf(minusDays(from ?? now(), days));

  static final RegExp _pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Strictly parses a `yyyy-MM-dd` string. Returns null when invalid
  /// (including impossible dates such as 2025-02-30).
  static DateTime? tryParse(String? value) {
    if (value == null || !_pattern.hasMatch(value)) return null;
    final y = int.parse(value.substring(0, 4));
    final m = int.parse(value.substring(5, 7));
    final d = int.parse(value.substring(8, 10));
    final parsed = DateTime(y, m, d);
    if (parsed.year != y || parsed.month != m || parsed.day != d) return null;
    return parsed;
  }

  static bool isValid(String? value) => tryParse(value) != null;
}
