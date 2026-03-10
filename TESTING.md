# 🧪 Testing Framework Configuration

## Test Structure

```
test/
├── unit/                     # Unit tests for business logic
│   ├── app_user_test.dart   # User model tests
│   ├── app_utils_test.dart  # Utility function tests
│   └── ...
├── widget/                   # Widget tests for UI components
│   ├── welcome_screen_test.dart
│   └── ...
├── integration/             # End-to-end integration tests
│   ├── app_flow_test.dart
│   └── ...
└── test_config.dart        # Test configuration and helpers
```

## Test Categories

### 1. Unit Tests
- **Purpose**: Test individual functions, classes, and business logic
- **Speed**: Very fast (milliseconds)
- **Scope**: Isolated components without UI
- **Examples**: Model validation, utility functions, calculations

### 2. Widget Tests
- **Purpose**: Test UI components and their interactions
- **Speed**: Fast (seconds)
- **Scope**: Individual widgets or widget trees
- **Examples**: Button taps, form validation, layout behavior

### 3. Integration Tests
- **Purpose**: Test complete user flows and app behavior
- **Speed**: Slower (minutes)
- **Scope**: Full app functionality
- **Examples**: User registration, navigation flows, data persistence

## Running Tests

### All Tests
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Specific Test Types
```bash
# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# Integration tests
flutter test test/integration/
```

### Test Coverage
```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Test Configuration

### Dependencies
```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
  fake_async: ^1.3.1
  test: ^1.24.6
```

### Mock Generation
```bash
# Generate mocks
flutter packages pub run build_runner build
```

## Testing Guidelines

### 1. Test Naming
- **Unit Tests**: `test('should [expected behavior] when [condition]')`
- **Widget Tests**: `testWidgets('should [UI behavior] when [user action]')`
- **Integration Tests**: `testWidgets('should complete [user flow]')`

### 2. Test Structure
```dart
group('Feature Name Tests', () {
  late TestObject testObject;
  
  setUp(() {
    // Setup before each test
    testObject = TestObject();
  });
  
  tearDown(() {
    // Cleanup after each test
    testObject.dispose();
  });
  
  test('should behave correctly', () {
    // Arrange
    final input = 'test input';
    
    // Act
    final result = testObject.process(input);
    
    // Assert
    expect(result, equals('expected output'));
  });
});
```

### 3. Assertions
```dart
// Equality
expect(actual, equals(expected));
expect(actual, isA<String>());

// Numbers
expect(value, greaterThan(0));
expect(value, lessThan(100));
expect(value, closeTo(3.14, 0.01));

// Collections
expect(list, hasLength(3));
expect(list, contains('item'));
expect(map, containsPair('key', 'value'));

// Widgets
expect(find.text('Hello'), findsOneWidget);
expect(find.byType(Button), findsNWidgets(2));
```

## Mock Configuration

### Creating Mocks
```dart
// test/mocks/mock_services.dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:food_redistribution_app/services/user_service.dart';

@GenerateMocks([UserService, AuthService, DatabaseService])
import 'mock_services.mocks.dart';

// Usage in tests
final mockUserService = MockUserService();
when(mockUserService.getCurrentUser())
    .thenAnswer((_) async => testUser);
```

### Test Utilities
```dart
// test/test_helpers.dart
class TestHelpers {
  static AppUser createTestUser({
    String id = 'test-user-id',
    String email = 'test@example.com',
    UserRole role = UserRole.donor,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: 'Test User',
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }
  
  static Widget wrapWithMaterialApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }
}
```

## Test Data

### Fixtures
```dart
// test/fixtures/test_data.dart
class TestData {
  static final testUsers = [
    AppUser(id: '1', email: 'donor@test.com', role: UserRole.donor, ...),
    AppUser(id: '2', email: 'ngo@test.com', role: UserRole.ngo, ...),
    AppUser(id: '3', email: 'volunteer@test.com', role: UserRole.volunteer, ...),
  ];
  
  static final testLocations = [
    Location(latitude: 37.7749, longitude: -122.4194, address: 'San Francisco'),
    Location(latitude: 40.7128, longitude: -74.0060, address: 'New York'),
  ];
  
  static final testDonations = [
    FoodDonation(
      id: 'donation-1',
      donorId: 'donor-1',
      title: 'Fresh Vegetables',
      items: [
        FoodItem(name: 'Carrots', quantity: 5, unit: 'kg'),
      ],
      // ... other properties
    ),
  ];
}
```

## Widget Testing Patterns

### Testing User Interactions
```dart
testWidgets('should handle button tap', (WidgetTester tester) async {
  var tapped = false;
  
  await tester.pumpWidget(
    MaterialApp(
      home: ElevatedButton(
        onPressed: () => tapped = true,
        child: Text('Tap me'),
      ),
    ),
  );
  
  await tester.tap(find.text('Tap me'));
  await tester.pump();
  
  expect(tapped, isTrue);
});
```

### Testing Form Validation
```dart
testWidgets('should validate email input', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextFormField(
          key: Key('email-field'),
          validator: (value) => AppUtils.isValidEmail(value) ? null : 'Invalid email',
        ),
      ),
    ),
  );
  
  // Enter invalid email
  await tester.enterText(find.byKey(Key('email-field')), 'invalid-email');
  await tester.pump();
  
  // Trigger validation
  final formState = tester.state<FormState>(find.byType(Form));
  formState.validate();
  await tester.pump();
  
  expect(find.text('Invalid email'), findsOneWidget);
});
```

### Testing Navigation
```dart
testWidgets('should navigate to next screen', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/details': (context) => DetailsScreen(),
      },
    ),
  );
  
  await tester.tap(find.text('Go to Details'));
  await tester.pumpAndSettle();
  
  expect(find.byType(DetailsScreen), findsOneWidget);
});
```

## Integration Testing Setup

### Test Configuration
```dart
// test/integration/test_config.dart
import 'package:flutter/services.dart';
import 'package:integration_test/integration_test.dart';

class IntegrationTestConfig {
  static void setupTests() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock platform channels
    TestDefaultBinaryMessengerBinding.instance?.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('firebase_core'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  }
  
  static Future<void> cleanupAfterTest() async {
    // Cleanup logic
  }
}
```

### Golden Tests (Visual Regression)
```dart
testWidgets('welcome screen golden test', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(home: WelcomeScreen()));
  await expectLater(
    find.byType(WelcomeScreen),
    matchesGoldenFile('welcome_screen.png'),
  );
});
```

## Performance Testing

### Memory Leaks
```dart
testWidgets('should not leak memory', (WidgetTester tester) async {
  for (int i = 0; i < 100; i++) {
    await tester.pumpWidget(MaterialApp(home: MyWidget()));
    await tester.pumpWidget(Container());
  }
  
  // Check for memory leaks using appropriate tools
});
```

### Animation Performance
```dart
testWidgets('animations should be smooth', (WidgetTester tester) async {
  await tester.pumpWidget(MyAnimatedWidget());
  
  // Measure frame rendering times
  final binding = tester.binding;
  binding.addTimingsCallback((List<FrameTiming> timings) {
    for (final timing in timings) {
      expect(timing.totalSpan.inMilliseconds, lessThan(16)); // 60 FPS
    }
  });
  
  await tester.pump();
});
```

## CI/CD Integration

### GitHub Actions
```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - run: flutter test test/integration/
```

### Test Reports
```bash
# Generate test reports
flutter test --reporter=json > test_results.json
flutter test --coverage
```

## Best Practices

### 1. Test Isolation
- Each test should be independent
- Use setUp/tearDown for clean state
- Mock external dependencies

### 2. Test Coverage
- Aim for >80% code coverage
- Focus on critical business logic
- Test edge cases and error scenarios

### 3. Test Maintainability
- Keep tests simple and readable
- Use descriptive test names
- Avoid testing implementation details

### 4. Test Speed
- Unit tests should run in milliseconds
- Widget tests in seconds
- Integration tests in minutes

### 5. Error Testing
```dart
test('should handle network errors', () async {
  when(mockApiService.getData()).thenThrow(NetworkException('Connection failed'));
  
  final result = await dataService.fetchData();
  
  expect(result.isError, isTrue);
  expect(result.error, isA<NetworkException>());
});
```

## Debugging Tests

### Test Debugging
```dart
testWidgets('debug widget test', (WidgetTester tester) async {
  await tester.pumpWidget(MyWidget());
  
  // Print widget tree
  debugDumpApp();
  
  // Print render tree
  debugDumpRenderTree();
  
  // Take screenshot
  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('debug_screenshot.png'),
  );
});
```

### Common Issues
1. **Pump and Settle**: Always use `pumpAndSettle()` after async operations
2. **Finders**: Use specific finders to avoid ambiguous matches
3. **Test Isolation**: Ensure tests don't affect each other
4. **Mock Setup**: Properly configure mocks before use

This testing framework ensures comprehensive coverage and maintainable test suites for the Food Redistribution Platform.