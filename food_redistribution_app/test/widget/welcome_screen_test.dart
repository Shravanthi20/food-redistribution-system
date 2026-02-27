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
      expect(find.text('Food Redistribution'), findsOneWidget);
      
      // Verify subtitle
      expect(find.text('Reducing waste, feeding communities'), findsOneWidget);
      
      expect(find.text('Choose your role'), findsOneWidget);
    });

    testWidgets('should display all role selection cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verify all role cards are present
      expect(find.text('Food Donor'), findsOneWidget);
      expect(find.text('NGO Partner'), findsOneWidget);
      
      // Scroll to reveal the Volunteer card
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      
      expect(find.text('Volunteer'), findsOneWidget);
    });

    testWidgets('should display role descriptions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verify role descriptions
      expect(find.text('Share surplus food with those in need'), findsOneWidget);
      expect(find.text('Connect with donors to help communities'), findsOneWidget);
      
      // Scroll down
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      
      expect(find.text('Help with food collection and delivery'), findsOneWidget);
    });

    testWidgets('should display app logo', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Look for logo or icon
      expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);
    });

    testWidgets('should display call-to-action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Scroll down
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      // Look for action buttons
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}