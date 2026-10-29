/// A user-presentable error. The [message] is always safe to show in the UI.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Message shown for unexpected failures (never expose raw exceptions).
const String kGenericErrorMessage = 'Something went wrong. Please try again.';
