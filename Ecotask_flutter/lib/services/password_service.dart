import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Local password hashing, replacing `bcryptjs` of the Node backend.
///
/// PBKDF2-HMAC-SHA256 with a random 16-byte salt. The stored format is
/// `pbkdf2_sha256$<iterations>$<salt b64>$<hash b64>`; the iteration count is
/// stored with the hash so it can be raised later without breaking old
/// accounts.
class PasswordService {
  PasswordService(
      {this.iterations = defaultIterations, this.useIsolate = true});

  /// Cost chosen to take a few hundred ms on a mid-range phone in release mode.
  static const int defaultIterations = 50000;
  static const String _scheme = 'pbkdf2_sha256';
  static const int _saltLength = 16;

  final int iterations;

  /// Hash on a background isolate so the UI thread never blocks.
  final bool useIsolate;

  Future<String> hash(String password) async {
    final rng = Random.secure();
    final salt = Uint8List.fromList(
        List<int>.generate(_saltLength, (_) => rng.nextInt(256)));
    final key = await _derive(password, salt, iterations);
    return '$_scheme\$$iterations\$${base64Encode(salt)}\$${base64Encode(key)}';
  }

  Future<bool> verify(String password, String stored) async {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != _scheme) return false;
    final iters = int.tryParse(parts[1]);
    if (iters == null || iters <= 0) return false;
    try {
      final salt = base64Decode(parts[2]);
      final expected = base64Decode(parts[3]);
      final actual = await _derive(password, salt, iters);
      return _constantTimeEquals(actual, expected);
    } on FormatException {
      return false;
    }
  }

  Future<Uint8List> _derive(String password, Uint8List salt, int iters) {
    final pw = Uint8List.fromList(utf8.encode(password));
    if (!useIsolate) return Future.value(pbkdf2(pw, salt, iters));
    return Isolate.run(() => pbkdf2(pw, salt, iters));
  }

  /// PBKDF2 (RFC 8018) with HMAC-SHA256 and a 32-byte derived key.
  static Uint8List pbkdf2(Uint8List password, Uint8List salt, int iterations) {
    final hmac = Hmac(sha256, password);
    final block = Uint8List(salt.length + 4)
      ..setAll(0, salt)
      ..[salt.length + 3] = 1; // big-endian block index 1
    var u = Uint8List.fromList(hmac.convert(block).bytes);
    final t = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    return t;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
