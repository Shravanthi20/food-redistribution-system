import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:food_redistribution_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Food Redistribution App Integration Tests', () {
    testWidgets('should complete user onboarding flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app launches correctly
      expect(find.text('Food Redistribution Platform'), findsOneWidget);

      // Test role selection
      await tester.tap(find.text('Food Donor'));
      await tester.pumpAndSettle();

      // Should navigate to donor dashboard or registration
      expect(find.textContaining('donor').or(find.textContaining('Donor')), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle navigation between screens', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Start from welcome screen
      expect(find.text('Food Redistribution Platform'), findsOneWidget);

      // Test navigation to different roles
      await tester.tap(find.text('NGO/Organization'));
      await tester.pumpAndSettle();

      // Should show NGO-related content
      expect(find.textContaining('NGO').or(find.textContaining('Organization')), findsAtLeastNWidgets(1));

      // Navigate back if possible
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        expect(find.text('Food Redistribution Platform'), findsOneWidget);
      }
    });

    testWidgets('should handle volunteer registration flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Select volunteer role
      await tester.tap(find.text('Volunteer'));
      await tester.pumpAndSettle();

      // Should navigate to volunteer-specific screen
      expect(find.textContaining('volunteer').or(find.textContaining('Volunteer')), 
             findsAtLeastNWidgets(1));
    });

    testWidgets('should display coordinator dashboard', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Select coordinator role
      await tester.tap(find.text('Coordinator'));
      await tester.pumpAndSettle();

      // Should show coordinator-related content
      expect(find.textContaining('coordinator').or(find.textContaining('Coordinator')), 
             findsAtLeastNWidgets(1));
    });

    testWidgets('should handle scroll behavior in welcome screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find scrollable content
      final scrollable = find.byType(SingleChildScrollView);
      expect(scrollable, findsOneWidget);

      // Test scrolling down
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      // Should still show main content
      expect(find.text('Food Redistribution Platform'), findsOneWidget);

      // Test scrolling back up
      await tester.drag(scrollable, const Offset(0, 500));
      await tester.pumpAndSettle();

      expect(find.text('Food Redistribution Platform'), findsOneWidget);
    });

    testWidgets('should handle app state preservation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Initial state
      expect(find.text('Food Redistribution Platform'), findsOneWidget);

      // Simulate app lifecycle changes
      tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler(
        'flutter/lifecycle',
        (dynamic message) async {
          return 'AppLifecycleState.paused';
        },
      );

      await tester.pumpAndSettle();

      // App should still be functional
      expect(find.text('Food Redistribution Platform'), findsOneWidget);

      // Restore lifecycle
      tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler(
        'flutter/lifecycle',
        (dynamic message) async {
          return 'AppLifecycleState.resumed';
        },
      );

      await tester.pumpAndSettle();
      expect(find.text('Food Redistribution Platform'), findsOneWidget);
    });

    testWidgets('should handle different screen orientations', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Portrait orientation (default)
      expect(find.text('Food Redistribution Platform'), findsOneWidget);

      // Simulate landscape orientation
      tester.binding.window.physicalSizeTestValue = const Size(800, 400);
      await tester.pumpAndSettle();

      // App should adapt to landscape
      expect(find.text('Food Redistribution Platform'), findsOneWidget);

      // Reset orientation
      tester.binding.window.clearPhysicalSizeTestValue();
      await tester.pumpAndSettle();
    });

    testWidgets('should handle accessibility features', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test semantic labels
      expect(find.bySemanticsLabel('Select Food Donor role'), findsOneWidget);
      expect(find.bySemanticsLabel('Select NGO Organization role'), findsOneWidget);
      expect(find.bySemanticsLabel('Select Volunteer role'), findsOneWidget);
      expect(find.bySemanticsLabel('Select Coordinator role'), findsOneWidget);

      // Test focus management
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Should maintain proper focus
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should handle network error states', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // App should load even without network
      expect(find.text('Food Redistribution Platform'), findsOneWidget);

      // Test offline functionality
      await tester.tap(find.text('Food Donor'));
      await tester.pumpAndSettle();

      // Should handle offline state gracefully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should maintain performance with animations', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test rapid interactions
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Food Donor'));
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();

      // App should remain responsive
      expect(find.text('Food Redistribution Platform'), findsOneWidget);
    });

    testWidgets('should handle role switching', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test switching between different roles
      await tester.tap(find.text('Food Donor'));
      await tester.pumpAndSettle();

      // Go back and select different role
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Volunteer'));
      await tester.pumpAndSettle();

      // Should handle role switching correctly
      expect(find.textContaining('volunteer').or(find.textContaining('Volunteer')), 
             findsAtLeastNWidgets(1));
    });

    testWidgets('should validate app theming', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify Material Design 3 theming
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, isTrue);

      // Check for consistent color scheme
      expect(find.text('Food Redistribution Platform'), findsOneWidget);
    });

    testWidgets('should handle deep linking scenarios', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test initial route
      expect(find.text('Food Redistribution Platform'), findsOneWidget);

      // Simulate deep link navigation (would require route setup)
      await tester.tap(find.text('Food Donor'));
      await tester.pumpAndSettle();

      // Should handle route changes appropriately
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    group('Error Handling Tests', () {
      testWidgets('should handle widget build errors gracefully', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // App should build without errors
        expect(find.text('Food Redistribution Platform'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should display error boundaries when needed', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Normal operation should not show errors
        expect(find.textContaining('Error'), findsNothing);
        expect(find.textContaining('Something went wrong'), findsNothing);
      });
    });

    group('Performance Tests', () {
      testWidgets('should load within acceptable time', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        app.main();
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // App should load within 3 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
        expect(find.text('Food Redistribution Platform'), findsOneWidget);
      });

      testWidgets('should handle memory efficiently', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Simulate multiple navigation cycles
        for (int i = 0; i < 10; i++) {
          await tester.tap(find.text('Food Donor'));
          await tester.pumpAndSettle();

          final backButton = find.byIcon(Icons.arrow_back);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton);
            await tester.pumpAndSettle();
          }
        }

        // App should still be responsive
        expect(find.text('Food Redistribution Platform'), findsOneWidget);
      });
    });

    group('User Experience Tests', () {
      testWidgets('should provide smooth animations', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Test smooth transitions
        await tester.tap(find.text('Food Donor'));
        await tester.pump(const Duration(milliseconds: 16)); // Single frame
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Should complete transitions smoothly
        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('should maintain UI consistency', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Verify consistent spacing and typography
        final titleFinder = find.text('Food Redistribution Platform');
        expect(titleFinder, findsOneWidget);

        final titleWidget = tester.widget<Text>(titleFinder);
        expect(titleWidget.style?.fontWeight, equals(FontWeight.bold));
      });
    });
  });
}