import 'package:ecotask/core/app_date.dart';
import 'package:ecotask/core/app_exception.dart';
import 'package:ecotask/services/auth_service.dart';
import 'package:ecotask/services/password_service.dart';
import 'package:ecotask/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_env.dart';

void main() {
  late TestEnv env;
  late MemorySessionStore sessions;
  late AuthService auth;

  setUp(() async {
    env = await TestEnv.create();
    sessions = MemorySessionStore();
    auth = AuthService(
        users: env.users,
        passwords: PasswordService(iterations: 1000, useIsolate: false),
        sessions: sessions);
  });
  tearDown(() => env.dispose());

  Matcher failsWith(String message) =>
      throwsA(isA<AppException>().having((e) => e.message, 'message', message));

  group('register', () {
    test('creates the user, hashes the password and starts a 7-day session',
        () async {
      final u = await auth.register(
          name: ' Jane Doe ', email: ' Jane@Example.com ', password: 'secret1');
      expect(u.name, 'Jane Doe');
      expect(u.email, 'jane@example.com');
      final creds =
          (await env.users.findCredentialsByEmail('jane@example.com'))!;
      expect(creds.passwordHash.contains('secret1'), isFalse);
      expect(creds.passwordHash.startsWith('pbkdf2_sha256'), isTrue);
      final s = (await sessions.read())!;
      expect(s.userId, u.id);
      expect(s.expiresAt.difference(AppDate.now()), const Duration(days: 7));
      expect(s.token.length, 64);
    });

    test('rejects missing fields, short password, bad name/email', () async {
      expect(
          () => auth.register(name: '', email: 'a@b.co', password: 'secret1'),
          failsWith('All fields are required'));
      expect(
          () => auth.register(name: 'Jane', email: 'a@b.co', password: '12345'),
          failsWith('Password must be at least 6 characters'));
      expect(
          () => auth.register(name: 'J', email: 'a@b.co', password: 'secret1'),
          throwsA(isA<AppException>()));
      expect(
          () => auth.register(
              name: 'Jane', email: 'not-an-email', password: 'secret1'),
          throwsA(isA<AppException>()));
    });

    test('duplicate e-mail (case-insensitive) is rejected', () async {
      await auth.register(
          name: 'Jane', email: 'jane@example.com', password: 'secret1');
      expect(
          () => auth.register(
              name: 'Other', email: 'JANE@example.com', password: 'secret2'),
          failsWith('Email already registered'));
    });
  });

  group('login', () {
    setUp(() => auth.register(
        name: 'Jane', email: 'jane@example.com', password: 'secret1'));

    test('succeeds with the right credentials', () async {
      await sessions.clear();
      final u =
          await auth.login(email: 'Jane@Example.com', password: 'secret1');
      expect(u.email, 'jane@example.com');
      expect(await sessions.read(), isNotNull);
    });

    test('wrong password and unknown e-mail give the same message', () async {
      expect(() => auth.login(email: 'jane@example.com', password: 'wrong'),
          failsWith('Invalid credentials'));
      expect(() => auth.login(email: 'ghost@example.com', password: 'secret1'),
          failsWith('Invalid credentials'));
    });

    test('empty fields', () async {
      expect(() => auth.login(email: '', password: 'x'),
          failsWith('Email and password required'));
      expect(() => auth.login(email: 'a@b.co', password: ''),
          failsWith('Email and password required'));
    });

    test('the seeded demo account can sign in with demo123', () async {
      await env.seed.ensureDemoUser();
      final u =
          await auth.login(email: 'demo@ecotask.com', password: 'demo123');
      expect(u.name, 'Alex Green');
    });
  });

  group('session', () {
    test('restoreSession returns the logged-in user', () async {
      final u = await auth.register(
          name: 'Jane', email: 'jane@example.com', password: 'secret1');
      expect((await auth.restoreSession())!.id, u.id);
    });

    test('no session -> null', () async {
      expect(await auth.restoreSession(), isNull);
    });

    test('expired session is cleared', () async {
      final u = await auth.register(
          name: 'Jane', email: 'jane@example.com', password: 'secret1');
      AppDate.now = () => kNow.add(const Duration(days: 8));
      expect(await auth.restoreSession(), isNull);
      expect(await sessions.read(), isNull);
      expect(u.id.isNotEmpty, isTrue);
    });

    test('session of a deleted user is cleared', () async {
      final u = await auth.register(
          name: 'Jane', email: 'jane@example.com', password: 'secret1');
      await (await env.helper.database)
          .delete('users', where: 'id = ?', whereArgs: [u.id]);
      expect(await auth.restoreSession(), isNull);
      expect(await sessions.read(), isNull);
    });

    test('logout clears the session', () async {
      await auth.register(
          name: 'Jane', email: 'jane@example.com', password: 'secret1');
      await auth.logout();
      expect(await auth.restoreSession(), isNull);
    });
  });
}
