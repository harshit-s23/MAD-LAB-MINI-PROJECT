import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A persisted login session (replaces the JWT kept in localStorage).
class Session {
  const Session(
      {required this.userId, required this.token, required this.expiresAt});

  final String userId;

  /// Random opaque token kept in secure storage.
  final String token;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !expiresAt.isAfter(now);
}

abstract class SessionStore {
  Future<Session?> read();
  Future<void> save(Session session);
  Future<void> clear();
}

String generateSessionToken() {
  final rng = Random.secure();
  final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Production store.
///  * SharedPreferences: non-sensitive data (user id, expiry) — the analogue of
///    the `ecotask_user` entry in localStorage.
///  * flutter_secure_storage: the session token — the analogue of the JWT in
///    `ecotask_token`.
class SecureSessionStore implements SessionStore {
  SecureSessionStore(this._prefs, [FlutterSecureStorage? secure])
      : _secure = secure ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  static const String _kUserId = 'ecotask_user_id';
  static const String _kExpires = 'ecotask_session_expires';
  static const String _kToken = 'ecotask_token';
  static const String _kTokenFallback = 'ecotask_token_fallback';

  @override
  Future<Session?> read() async {
    final userId = _prefs.getString(_kUserId);
    final expires = _prefs.getString(_kExpires);
    if (userId == null || expires == null) return null;
    final expiresAt = DateTime.tryParse(expires);
    if (expiresAt == null) return null;
    String? token;
    try {
      token = await _secure.read(key: _kToken);
    } catch (_) {
      token = null;
    }
    // Fallback used only when secure storage is unavailable on this device.
    token ??= _prefs.getString(_kTokenFallback);
    if (token == null || token.isEmpty) return null;
    return Session(userId: userId, token: token, expiresAt: expiresAt);
  }

  @override
  Future<void> save(Session session) async {
    try {
      await _secure.write(key: _kToken, value: session.token);
      await _prefs.remove(_kTokenFallback);
    } catch (_) {
      // Secure storage unavailable (some desktop setups): keep the session
      // working by storing the opaque token in preferences instead.
      await _prefs.setString(_kTokenFallback, session.token);
    }
    await _prefs.setString(_kUserId, session.userId);
    await _prefs.setString(
        _kExpires, session.expiresAt.toUtc().toIso8601String());
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_kUserId);
    await _prefs.remove(_kExpires);
    await _prefs.remove(_kTokenFallback);
    try {
      await _secure.delete(key: _kToken);
    } catch (_) {
      // Nothing else to do; the prefs half is already gone.
    }
  }
}

/// In-memory store for tests.
class MemorySessionStore implements SessionStore {
  Session? _session;

  @override
  Future<Session?> read() async => _session;

  @override
  Future<void> save(Session session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
