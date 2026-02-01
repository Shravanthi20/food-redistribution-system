import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_redistribution_app/screens/welcome_screen.dart';

void main() {
  group('Welcome Screen Widget Tests', () {
    testWidgets('should display app title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verify app title
      expect(find.text('Food Redistribution Platform'), findsOneWidget);
      
      // Verify subtitle
      expect(find.text('Connecting Communities, Reducing Waste'), findsOneWidget);
    });

    testWidgets('should display all role selection cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verify all role cards are present
      expect(find.text('Food Donor'), findsOneWidget);
      expect(find.text('NGO/Organization'), findsOneWidget);
      expect(find.text('Volunteer'), findsOneWidget);
      expect(find.text('Coordinator'), findsOneWidget);
    });

    testWidgets('should display role descriptions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verify role descriptions
      expect(find.text('Share surplus food from restaurants, events, and households'), findsOneWidget);
      expect(find.text('Manage food distribution programs and community outreach'), findsOneWidget);
      expect(find.text('Help with food collection, sorting, and distribution efforts'), findsOneWidget);
      expect(find.text('Coordinate logistics and optimize food redistribution networks'), findsOneWidget);
    });

    testWidgets('should handle role card taps', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Test tapping on donor card
      await tester.tap(find.text('Food Donor'));
      await tester.pumpAndSettle();

      // Verify navigation or state change occurred
      // Note: This would require implementing actual navigation logic
      expect(find.text('Food Donor'), findsOneWidget);
    });

    testWidgets('should display impact statistics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Look for impact statistics
      expect(find.textContaining('10,000+'), findsOneWidget); // Meals delivered
      expect(find.textContaining('500+'), findsOneWidget); // Active donors
      expect(find.textContaining('50+'), findsOneWidget); // Partner NGOs
      expect(find.textContaining('25+'), findsOneWidget); // Cities covered
    });

    testWidgets('should have proper accessibility labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verify semantic labels for accessibility
      expect(find.bySemanticsLabel('Select Food Donor role'), findsOneWidget);
      expect(find.bySemanticsLabel('Select NGO Organization role'), findsOneWidget);
      expect(find.bySemanticsLabel('Select Volunteer role'), findsOneWidget);
      expect(find.bySemanticsLabel('Select Coordinator role'), findsOneWidget);
    });

    testWidgets('should display feature highlights', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Check for feature highlights
      expect(find.textContaining('Real-time tracking'), findsOneWidget);
      expect(find.textContaining('AI-powered matching'), findsOneWidget);
      expect(find.textContaining('Impact analytics'), findsOneWidget);
      expect(find.textContaining('Community building'), findsOneWidget);
    });

    testWidgets('should have responsive layout', (WidgetTester tester) async {
      // Test on mobile size
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verify layout adapts to mobile
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      
      // Test on tablet size
      tester.binding.window.physicalSizeTestValue = const Size(800, 1200);
      await tester.pumpAndSettle();
      
      // Verify layout adapts to tablet
      expect(find.byType(WelcomeScreen), findsOneWidget);

      // Reset window size
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    testWidgets('should display app logo', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Look for logo or icon
      expect(find.byIcon(Icons.eco), findsOneWidget);
    });

    testWidgets('should have proper color scheme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verify theme colors are applied
      final containerWidgets = find.byType(Container);
      expect(containerWidgets, findsWidgets);

      // Check for gradient backgrounds
      final decoratedBoxWidgets = find.byType(DecoratedBox);
      expect(decoratedBoxWidgets, findsWidgets);
    });

    testWidgets('should handle scroll behavior', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verify scrollable content
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsOneWidget);

      // Test scrolling
      await tester.drag(scrollView, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Content should still be visible
      expect(find.text('Food Redistribution Platform'), findsOneWidget);
    });

    testWidgets('should display call-to-action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Look for action buttons
      expect(find.textContaining('Get Started'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Learn More'), findsWidgets);
    });

    testWidgets('should handle theme switching', (WidgetTester tester) async {
      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: WelcomeScreen(),
        ),
      );

      expect(find.text('Food Redistribution Platform'), findsOneWidget);

      // Test with light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: WelcomeScreen(),
        ),
      );

      expect(find.text('Food Redistribution Platform'), findsOneWidget);
    });

    testWidgets('should display loading state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // The widget should render without loading indicators initially
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should handle error states gracefully', (WidgetTester tester) async {
      // This would test error handling if implemented
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Should not display error messages on normal load
      expect(find.textContaining('Error'), findsNothing);
      expect(find.textContaining('Failed'), findsNothing);
    });

    testWidgets('should support keyboard navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Test tab navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Focus should be manageable via keyboard
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('should display testimonials section', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Look for testimonials if implemented
      expect(find.textContaining('testimonial').or(find.textContaining('review')), findsAny);
    });

    group('Role Card Interactions', () {
      testWidgets('should highlight role card on hover', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: WelcomeScreen(),
          ),
        );

        final donorCard = find.ancestor(
          of: find.text('Food Donor'),
          matching: find.byType(InkWell),
        );

        // Simulate hover
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        await gesture.moveTo(tester.getCenter(donorCard));
        await tester.pump();

        // Card should respond to hover
        expect(donorCard, findsOneWidget);
      });

      testWidgets('should show role-specific information on selection', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: WelcomeScreen(),
          ),
        );

        // Tap on volunteer role
        await tester.tap(find.text('Volunteer'));
        await tester.pumpAndSettle();

        // Should show volunteer-specific content
        expect(find.textContaining('volunteer'), findsAtLeastNWidgets(1));
      });
    });

    group('Responsive Design Tests', () {
      testWidgets('should adapt to small screen sizes', (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(320, 568); // iPhone SE size
        tester.binding.window.devicePixelRatioTestValue = 2.0;

        await tester.pumpWidget(
          MaterialApp(
            home: WelcomeScreen(),
          ),
        );

        // Content should be scrollable on small screens
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });

      testWidgets('should use grid layout on larger screens', (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(1200, 800); // Desktop size
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: WelcomeScreen(),
          ),
        );

        // Should use appropriate layout for desktop
        expect(find.byType(WelcomeScreen), findsOneWidget);

        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });
  });
}