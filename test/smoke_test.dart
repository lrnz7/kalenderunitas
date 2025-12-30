import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kalender_unitas/services/data_loader.dart';
import 'package:kalender_unitas/models/event_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Start with a clean mocked SharedPreferences
    SharedPreferences.setMockInitialValues({});
  });

  test('DataLoader smoke: load assets, add, update, delete event', () async {
    // 1. Load events (should fall back to assets)
    final initial = await DataLoader.loadEvents();
    expect(initial, isNotNull);
    expect(initial.length, greaterThan(0),
        reason: 'Should load events from assets/local');

    // 2. Add a new event
    final newEvent = EventModel(
      id: 'temp',
      title: 'Smoke Test Event',
      startDate: '2025-12-24',
      category: 'Test',
      division: 'Umum',
      description: 'Created by smoke test',
    );

    final docId = await DataLoader.addEvent(newEvent, createdBy: 'smoke_test');
    expect(docId, isNotNull);
    expect(docId, isNot(''));

    // 3. Verify it's present in local storage
    final afterAdd = await DataLoader.loadEvents();
    final found = afterAdd.firstWhere((e) => e.title == 'Smoke Test Event',
        orElse: () => EventModel(id: '', title: '', startDate: ''));
    expect(found.id, isNotEmpty,
        reason: 'Added event should be present in local events');

    final addedId = found.id;

    // 4. Update the event
    final updated = found.copyWith(title: 'Smoke Test Event Updated');
    await DataLoader.updateEvent(addedId, updated);

    final afterUpdate = await DataLoader.loadEvents();
    final updatedFound = afterUpdate.firstWhere((e) => e.id == addedId,
        orElse: () => EventModel(id: '', title: '', startDate: ''));
    expect(updatedFound.title, 'Smoke Test Event Updated');

    // 5. Delete the event
    await DataLoader.deleteEvent(addedId);
    final afterDelete = await DataLoader.loadEvents();
    final stillThere = afterDelete.any((e) => e.id == addedId);
    expect(stillThere, isFalse, reason: 'Event should be removed after delete');
  });
}
