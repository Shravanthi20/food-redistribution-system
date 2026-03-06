import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_redistribution_app/main.dart';

void main() {
  setUpAll(() async {
    const MethodChannel pathChannel =
        MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (MethodCall methodCall) async {
      return '.';
    });
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodRedistributionApp());
    await tester.pumpAndSettle();
    expect(find.byType(FoodRedistributionApp), findsOneWidget);
  });
}
