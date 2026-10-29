import '../core/app_date.dart';
import '../core/app_exception.dart';
import '../core/constants.dart';
import '../core/validators.dart';
import '../models/app_user.dart';
import '../repositories/user_repository.dart';
import 'password_service.dart';
import 'session_store.dart';

/// Local replacement for `authController.js` + JWT middleware.
///
/// Messages are the original API messages:
///  * "All fields are required", "Password must be at least 6 characters",
///    "Email already registered"
///  * "Email and password required", "Invalid credentials"
class AuthService {
  AuthService({
    required UserRepository users,
    required PasswordService passwords,
    required SessionStore sessions,
  })  : _users = users,
        _passwords = passwords,
        _sessions = sessions;

  final UserRepository _users;
  final PasswordService _passwords;
  final SessionStore _sessions;

  /// E-mails are compared trimmed and lower-cased (documented deviation: the
  /// original compared them verbatim, which made "Demo@x.com" a different
  /// account on a phone keyboard that auto-capitalises).
  static String normalizeEmail(String email) => email.trim().toLowerCase();

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      throw const AppException('All fields are required');
    }
    if (password.length < Validators.minPasswordLength) {
      throw const AppException('Password must be at least 6 characters');
    }
    final nameError = Validators.name(name);
    if (nameError != null) throw AppException(nameError);
    final emailError = Validators.email(email);
    if (emailError != null) throw AppException(emailError);

    final normalized = normalizeEmail(email);
    if (await _users.emailExists(normalized)) {
      throw const AppException('Email already registered');
    }

    final hash = await _passwords.hash(password);
    final user = await _users.create(
        name: name.trim(), email: normalized, passwordHash: hash);
    await _startSession(user);
    return user;
  }

  Future<AppUser> login(
      {required String email, required String password}) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AppException('Email and password required');
    }
    final creds = await _users.findCredentialsByEmail(normalizeEmail(email));
    if (creds == null) throw const AppException('Invalid credentials');
    final ok = await _passwords.verify(password, creds.passwordHash);
    if (!ok) throw const AppException('Invalid credentials');
    await _startSession(creds.user);
    return creds.user;
  }

  /// Restores a persisted session, or returns null when there is none, it has
  /// expired (7 days, like the JWT) or its user no longer exists.
  Future<AppUser?> restoreSession() async {
    final session = await _sessions.read();
    if (session == null) return null;
    if (session.isExpired(AppDate.now())) {
      await _sessions.clear();
      return null;
    }
    final user = await _users.findById(session.userId);
    if (user == null) {
      await _sessions.clear();
      return null;
    }
    return user;
  }

  Future<AppUser?> currentUser(String userId) => _users.findById(userId);

  Future<void> logout() => _sessions.clear();

  Future<void> _startSession(AppUser user) => _sessions.save(Session(
        userId: user.id,
        token: generateSessionToken(),
        expiresAt: AppDate.now().add(AppConstants.sessionLifetime),
      ));
}
