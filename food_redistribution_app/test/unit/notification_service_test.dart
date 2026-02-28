import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_redistribution_app/services/notification_service.dart';
import 'package:food_redistribution_app/config/firebase_schema.dart';

// generate mocks by running `flutter pub run build_runner build` if desired

class MockFirestore extends Mock implements FirebaseFirestore {}
class MockCollection extends Mock implements CollectionReference<Map<String, dynamic>> {}

void main() {
  late MockFirestore mockFirestore;
  late MockCollection mockCollection;
  late NotificationService service;

  setUp(() {
    mockFirestore = MockFirestore();
    mockCollection = MockCollection();
    when(mockFirestore.collection(Collections.notifications))
        .thenReturn(mockCollection);
    service = NotificationService(firestore: mockFirestore);
  });

  test('sendNotification should add a document in notifications collection', () async {
    when(mockCollection.add(any)).thenAnswer((_) async => MockDocumentReference());

    await service.sendNotification(
      userId: 'user123',
      title: 'Test',
      message: 'Hello',
      type: 'test',
      data: {'foo': 'bar'},
    );

    verify(mockCollection.add(argThat(
      allOf(
        containsPair('userId', 'user123'),
        containsPair('title', 'Test'),
        containsPair('message', 'Hello'),
        containsPair('type', 'test'),
        contains('data'),
        contains('createdAt'),
      ),
    ))).called(1);
  });
}

// A minimal fake DocumentReference so Mockito doesn't complain about null return.
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
