import 'package:flutter_test/flutter_test.dart';
import 'package:duet/services/totp_service.dart';

void main() {
  final now = DateTime.utc(2026, 8, 8, 12, 0, 15);
  const secret = '0123456789ABCDEF0123456789ABCDEF01234567';

  test('generates a six digit deterministic TOTP', () {
    final code = TotpService.generate(secret, now: now);
    expect(code, matches(RegExp(r'^\d{6}$')));
    expect(TotpService.generate(secret, now: now), code);
  });

  test('accepts the current time step and small clock drift', () {
    final code = TotpService.generate(secret, now: now);
    expect(TotpService.verify(secret, code, now: now), isTrue);
    expect(TotpService.verify(secret, code, now: now.add(const Duration(seconds: 30))), isTrue);
    expect(TotpService.verify(secret, code, now: now.add(const Duration(minutes: 2))), isFalse);
    expect(TotpService.verify(secret, '12345', now: now), isFalse);
  });
}
