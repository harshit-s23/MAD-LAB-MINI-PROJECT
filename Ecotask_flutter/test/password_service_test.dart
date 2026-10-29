import 'package:ecotask/repositories/seed_repository.dart';
import 'package:ecotask/services/password_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fast = PasswordService(iterations: 1000, useIsolate: false);

  test('hash is salted and verifies', () async {
    final a = await fast.hash('hunter22');
    final b = await fast.hash('hunter22');
    expect(a, isNot(equals(b)));
    expect(a.startsWith(r'pbkdf2_sha256$1000$'), isTrue);
    expect(await fast.verify('hunter22', a), isTrue);
    expect(await fast.verify('hunter22', b), isTrue);
  });

  test('wrong password and malformed hashes are rejected', () async {
    final a = await fast.hash('hunter22');
    expect(await fast.verify('hunter23', a), isFalse);
    expect(await fast.verify('x', 'garbage'), isFalse);
    expect(await fast.verify('x', r'pbkdf2_sha256$abc$AAAA$BBBB'), isFalse);
    expect(await fast.verify('x', r'bcrypt$10$AAAA$BBBB'), isFalse);
  });

  test('stored iteration count is honoured', () async {
    final slow = PasswordService(iterations: 2000, useIsolate: false);
    final h = await slow.hash('pw');
    expect(await fast.verify('pw', h), isTrue);
  });

  test('precomputed demo hash verifies the demo password only', () async {
    expect(await fast.verify('demo123', kDemoPasswordHash), isTrue);
    expect(await fast.verify('demo124', kDemoPasswordHash), isFalse);
  });
}
