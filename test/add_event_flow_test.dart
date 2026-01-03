import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/features/calendar/calendar_page.dart';
import 'package:kalender_unitas/services/data_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kalender_unitas/models/event_model.dart';

void main() {
  testWidgets('Tambah Event opens EditEventPage (injection)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CalendarPage(
        isAdmin: true,
        disableRealtimeIndicator: true,
        testEvents: [],
        testHolidays: [],
      ),
    ));

    // Ensure button is present
    expect(find.text('Tambah Event'), findsOneWidget);

    // Tap the add event button with an injected handler
    EventModel? captured;
    await tester.pumpWidget(MaterialApp(
      home: CalendarPage(
        isAdmin: true,
        disableRealtimeIndicator: true,
        testEvents: [],
        testHolidays: [],
        onCreateEvent: (e) async {
          captured = e;
        },
      ),
    ));

    await tester.tap(find.text('Tambah Event'));
    await tester.pumpAndSettle();

    // Should be on EditEventPage (AppBar title)
    expect(find.widgetWithText(AppBar, 'Edit Event'), findsOneWidget);

    // Fill in title
    await tester.enterText(find.byType(TextFormField).first, 'My Test Event');
    await tester.pump();
    expect(find.text('My Test Event'), findsOneWidget);

    // Select required dropdowns (Kategori, Divisi)
    // Tap first DropdownButtonFormField (Kategori)
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akademik').last);
    await tester.pumpAndSettle();

    // Tap second DropdownButtonFormField (Divisi)
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BPH').last);
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.byTooltip('Simpan Perubahan'));

    // Wait for handler
    await tester.pumpAndSettle();

    // The injected onCreateEvent should have been called with the new event
    expect(captured, isNotNull);
    expect(captured!.title, 'My Test Event');
  });

  testWidgets('Saving via default path refreshes calendar UI',
      (WidgetTester tester) async {
    // Prepare in-memory SharedPreferences
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(
      home: CalendarPage(
        isAdmin: true,
        disableRealtimeIndicator: true,
      ),
    ));

    // Wait for initial async loader to finish (events/holidays)
    await tester.pumpAndSettle();

    // Tap add event
    await tester.tap(find.text('Tambah Event'));
    await tester.pumpAndSettle();

    // Fill in title
    await tester.enterText(find.byType(TextFormField).first, 'Refreshed Event');
    await tester.pump();
    expect(find.text('Refreshed Event'), findsOneWidget);

    // Select required dropdowns
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akademik').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BPH').last);
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.byTooltip('Simpan Perubahan'));

    // Wait for persistence and reload
    await tester.pumpAndSettle();

    // Verify persistence via SharedPreferences (contains the new title)
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(DataLoader.eventsStorageKey);
    expect(saved, isNotNull);
    expect(saved!.contains('Refreshed Event'), isTrue);

    // Verify events load includes the new event (painter renders markers, not titles)
    final events = await DataLoader.loadEvents();
    expect(events.any((e) => e.title.contains('Refreshed')), isTrue);
  });
}
