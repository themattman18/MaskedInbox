import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:masked_inbox/main.dart';

void main() {
  testWidgets('shows first-run API key setup', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const MaskedInboxApp());
    await tester.pump();

    expect(find.text('Masked Inbox'), findsOneWidget);
    expect(find.text('Connect Firefox Relay'), findsOneWidget);
    expect(find.text('Save key'), findsOneWidget);
  });
}
