import 'app_date.dart';
import 'constants.dart';

/// Validation rules migrated from the original app:
///  * User model: name 2–50 chars, valid e-mail, unique e-mail
///  * authController: all fields required, password >= 6 chars
///  * Task model: title 1–200 chars, category enum, date required
///  * TaskModal: quantity min 0.01, required
///
/// Each validator returns an error message or `null` when valid, so they plug
/// straight into `TextFormField.validator`.
class Validators {
  Validators._();

  static const int minPasswordLength = 6;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxTitleLength = 200;
  static const double minQuantity = 0.01;

  static final RegExp _email = RegExp(
      r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$");

  static String? required(String? v, [String label = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? name(String? v) {
    final r = required(v, 'Full name');
    if (r != null) return r;
    final len = v!.trim().length;
    if (len < minNameLength || len > maxNameLength) {
      return 'Name must be between $minNameLength and $maxNameLength characters';
    }
    return null;
  }

  static String? email(String? v) {
    final r = required(v, 'Email');
    if (r != null) return r;
    if (!_email.hasMatch(v!.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? loginPassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    return null;
  }

  static String? newPassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }
    return null;
  }

  static String? taskTitle(String? v) {
    final r = required(v, 'Activity title');
    if (r != null) return r;
    if (v!.trim().length > maxTitleLength) {
      return 'Title must be $maxTitleLength characters or fewer';
    }
    return null;
  }

  static String? quantity(String? v) {
    if (v == null || v.trim().isEmpty) return 'Quantity is required';
    final n = double.tryParse(v.trim());
    if (n == null || n.isNaN || n.isInfinite) return 'Enter a valid number';
    if (n < minQuantity) return 'Quantity must be at least $minQuantity';
    return null;
  }

  static String? category(String? v) {
    if (v == null || !AppConstants.categoryValues.contains(v)) {
      return 'Choose a valid category';
    }
    return null;
  }

  static String? date(String? v) {
    if (v == null || v.isEmpty) return 'Date is required';
    if (!AppDate.isValid(v)) return 'Enter a valid date';
    return null;
  }
}
