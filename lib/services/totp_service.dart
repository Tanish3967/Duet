import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Small RFC 6238-compatible TOTP implementation used for buddy invites.
class TotpService {
  static const step = Duration(seconds: 30);
  static const digits = 6;
  static String createSecret() {
    final random = _secureRandom();
    final bytes = List<int>.generate(20, (_) => random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  }

  static String createInviteCode() {
    final random = _secureRandom();
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List<String>.generate(6, (_) => alphabet[random.nextInt(alphabet.length)]).join();
  }

  static Random _secureRandom() {
    // Invite codes and TOTP secrets are authentication material. Falling back
    // to Random() would make them predictable, so fail closed instead.
    return Random.secure();
  }

  static String generate(String secret, {DateTime? now}) {
    final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final counter = timestamp ~/ step.inSeconds;
    final key = _decodeHex(secret);
    final message = Uint8List(8);
    var remaining = counter;
    for (var index = message.length - 1; index >= 0; index--) {
      message[index] = remaining & 0xff;
      remaining = remaining ~/ 256;
    }
    final digest = Hmac(sha1, key).convert(message).bytes;
    final offset = digest.last & 0x0f;
    final binary = ((digest[offset] & 0x7f) << 24) |
        ((digest[offset + 1] & 0xff) << 16) |
        ((digest[offset + 2] & 0xff) << 8) |
        (digest[offset + 3] & 0xff);
    return (binary % 1000000).toString().padLeft(digits, '0');
  }

  static bool verify(String secret, String code, {DateTime? now}) {
    final normalized = code.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\d{6}$').hasMatch(normalized)) return false;
    final current = now ?? DateTime.now();
    for (final drift in [-1, 0, 1]) {
      final candidate = current.add(Duration(seconds: drift * step.inSeconds));
      if (_constantTimeEquals(generate(secret, now: candidate), normalized)) return true;
    }
    return false;
  }

  static List<int> _decodeHex(String value) {
    if (!RegExp(r'^[0-9A-Fa-f]{40}$').hasMatch(value)) {
      throw const FormatException('Invalid TOTP secret');
    }
    return List<int>.generate(20, (index) => int.parse(value.substring(index * 2, index * 2 + 2), radix: 16));
  }

  static bool _constantTimeEquals(String left, String right) {
    final a = utf8.encode(left);
    final b = utf8.encode(right);
    var result = a.length ^ b.length;
    for (var i = 0; i < min(a.length, b.length); i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}