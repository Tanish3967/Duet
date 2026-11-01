import 'package:flutter/foundation.dart';

import 'totp_service.dart';

class InviteData {
  const InviteData({required this.code, required this.secret});

  final String code;
  final String secret;
}

abstract interface class InviteService {
  InviteData create();
  bool validate(String code, String otp, InviteData invite);
}

/// Local-only adapter. A production implementation must validate invites on a
/// server and consume them atomically.
class LocalDebugInviteService implements InviteService {
  static final _codePattern = RegExp(r'^[A-Z0-9]{6}$');

  @override
  InviteData create() {
    if (!kDebugMode) return const InviteData(code: '', secret: '');
    return InviteData(code: TotpService.createInviteCode(), secret: TotpService.createSecret());
  }

  @override
  bool validate(String code, String otp, InviteData invite) {
    if (!kDebugMode || invite.code.isEmpty || invite.secret.isEmpty) return false;
    final normalized = code.trim().toUpperCase();
    return _codePattern.hasMatch(normalized) && normalized == invite.code && TotpService.verify(invite.secret, otp);
  }
}
