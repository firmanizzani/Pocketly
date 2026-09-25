import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocketly/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        if (call.method == 'read') return null;
        return null;
      },
    );
  });

  testWidgets('Pocketly app boots to splash then auth',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PocketlyApp());
    expect(find.text('Pocketly'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke Akun'), findsOneWidget);
  });
}
