import 'package:duet/services/auth_service.dart';
import 'package:duet/services/invite_service.dart';
import 'package:duet/services/totp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug auth adapter distinguishes admin and regular prototype users', () {
    final service = LocalDebugAuthService();

    expect(service.authenticate(LocalDebugAuthService.adminEmail, LocalDebugAuthService.adminPassword).isSuperAdmin, isTrue);
    expect(service.authenticate('person@example.com', 'password').authenticated, isTrue);
    expect(service.authenticate('', '').authenticated, isFalse);
  });

  test('local invite adapter validates the generated code and current OTP', () {
    final service = LocalDebugInviteService();
    final invite = service.create();
    final otp = TotpService.generate(invite.secret);

    expect(service.validate(invite.code, otp, invite), isTrue);
    expect(service.validate('INVALID', otp, invite), isFalse);
    expect(service.validate(invite.code, '000000', invite), isFalse);
  });
}
