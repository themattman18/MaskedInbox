import 'package:flutter_test/flutter_test.dart';
import 'package:masked_inbox/main.dart';

void main() {
  test('parses random Relay mask data', () {
    final mask = EmailMask.fromJson(
      {
        'id': 42,
        'full_address': 'quiet-sun@relay.firefox.com',
        'created_at': '2026-08-08T12:00:00Z',
        'mask_type': 'random',
      },
      MaskKind.custom,
    );

    expect(mask.id, 42);
    expect(mask.fullAddress, 'quiet-sun@relay.firefox.com');
    expect(mask.kind, MaskKind.random);
  });

  test('parses premium profile capability data', () {
    final profile = RelayProfile.fromJson({
      'has_premium': true,
      'total_masks': 12,
      'subdomain': 'masked',
    });

    expect(profile.hasPremium, isTrue);
    expect(profile.totalMasks, 12);
    expect(profile.subdomain, 'masked');
  });
}
