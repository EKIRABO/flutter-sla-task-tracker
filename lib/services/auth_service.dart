
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final Pbkdf2 _algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 210000,
    bits: 256,
  );

  // Generate a cryptographically secure random salt.
  Uint8List _generateSalt() {
    final random = Random.secure();

    return Uint8List.fromList(
      List<int>.generate(
        16,
        (_) => random.nextInt(256),
      ),
    );
  }

  String _toHex(List<int> bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Uint8List _fromHex(String hex) {
    if (hex.length.isOdd) {
      throw const FormatException('Invalid hex string');
    }

    return Uint8List.fromList(
      List<int>.generate(
        hex.length ~/ 2,
        (index) => int.parse(
          hex.substring(index * 2, index * 2 + 2),
          radix: 16,
        ),
      ),
    );
  }

  Future<String> _hashPassword(
    String password,
    Uint8List salt,
  ) async {
    final secretKey = await _algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    final bytes = await secretKey.extractBytes();

    return _toHex(bytes);
  }

  // Constant-time comparison to reduce timing leaks.
  bool _constantTimeEquals(
    Uint8List a,
    Uint8List b,
  ) {
    var difference = a.length ^ b.length;
    final maxLength = max(a.length, b.length);

    for (var i = 0; i < maxLength; i++) {
      final left = i < a.length ? a[i] : 0;
      final right = i < b.length ? b[i] : 0;
      difference |= left ^ right;
    }

    return difference == 0;
  }

  // REGISTER USER

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.length < 2) {
      return 'Name must be at least 2 characters.';
    }

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(cleanEmail)) {
      return 'Please enter a valid email address.';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    final existingUser = await DatabaseHelper.instance
        .findUserByEmail(cleanEmail);

    if (existingUser != null) {
      return 'An account with this email already exists.';
    }

    final salt = _generateSalt();
    final hash = await _hashPassword(password, salt);

    try {
      await DatabaseHelper.instance.createUser(
        name: cleanName,
        email: cleanEmail,
        passwordHash: hash,
        passwordSalt: _toHex(salt),
      );

      return null; // Registration successful
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        return 'An account with this email already exists.';
      }

      rethrow;
    }
  }

  // SIGN IN

  Future<Map<String, Object?>?> signIn({
    required String email,
    required String password,
  }) async {
    final user = await DatabaseHelper.instance
        .findUserByEmail(email.trim().toLowerCase());

    if (user == null) {
      return null;
    }

    final storedHash = user['password_hash'] as String;
    final storedSalt = user['password_salt'] as String;

    final computedHash = await _hashPassword(
      password,
      _fromHex(storedSalt),
    );

    final matches = _constantTimeEquals(
      _fromHex(computedHash),
      _fromHex(storedHash),
    );

    if (!matches) {
      return null;
    }

    // Never return password hashes or salts to UI screens.
    return {
      'id': user['id'],
      'name': user['name'],
      'email': user['email'],
    };
  }
}
