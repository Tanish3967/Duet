import 'package:flutter/foundation.dart';

class AuthResult {
  const AuthResult({required this.authenticated, this.isSuperAdmin = false});

  final bool authenticated;
  final bool isSuperAdmin;
}

abstract interface class AuthService {
  AuthResult authenticate(String email, String password);
}

/// Debug-only adapter for the local prototype. Replace with a server-backed
/// implementation before enabling production authentication.
class LocalDebugAuthService implements AuthService {
  static const adminEmail = 'admin@duet.local';
  static const adminPassword = 'DuetAdmin123!';

  @override
  AuthResult authenticate(String email, String password) {
    if (!kDebugMode) return const AuthResult(authenticated: false);
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail == adminEmail && password == adminPassword) {
      return const AuthResult(authenticated: true, isSuperAdmin: true);
    }
    if (normalizedEmail.isNotEmpty && password.isNotEmpty) {
      return const AuthResult(authenticated: true);
    }
    return const AuthResult(authenticated: false);
  }
}
