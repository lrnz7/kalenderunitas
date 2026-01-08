import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/screens/calendar_page.dart';

void main() {
  testWidgets('TopBar title is visually centered across widths',
      (WidgetTester tester) async {
    for (final size in [Size(320, 800), Size(600, 800), Size(1200, 800)]) {
      await tester.pumpWidget(MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          home: CalendarPage(
            isAdmin: true,
            disableRealtimeIndicator: true,
            testEvents: [],
            testHolidays: [],
          ),
        ),
      ));

      await tester.pumpAndSettle();

      final title = find.byKey(const Key('topbar_title'));
      expect(title, findsOneWidget);

      final titleTL = tester.getTopLeft(title);
      final titleSize = tester.getSize(title);
      final titleCenterX = titleTL.dx + titleSize.width / 2.0;

      final appBar = find.byType(AppBar);
      final appBarSize = tester.getSize(appBar);
      final appBarCenterX = appBarSize.width / 2.0;

      expect((titleCenterX - appBarCenterX).abs() < 8.0, isTrue,
          reason:
              'TopBar title is not centered for width ${size.width}; diff: ${(titleCenterX - appBarCenterX).abs()}');
    }
  });

  testWidgets('TopBar left and right zones anchored, user info max width',
      (WidgetTester tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(1200, 800)),
      child: MaterialApp(
        home: CalendarPage(
          isAdmin: true,
          disableRealtimeIndicator: true,
          testEvents: [],
          testHolidays: [],
        ),
      ),
    ));

    await tester.pumpAndSettle();

    final user = find.byKey(const Key('topbar_user_info'));
    final title = find.byKey(const Key('topbar_title'));
    final logout = find.byKey(const Key('topbar_logout'));

    expect(user, findsOneWidget);
    expect(title, findsOneWidget);
    expect(logout, findsOneWidget);

    final userTL = tester.getTopLeft(user).dx;
    final titleTL = tester.getTopLeft(title);
    final titleSize = tester.getSize(title);
    final titleCenterX = titleTL.dx + titleSize.width / 2.0;
    final logoutTL = tester.getTopLeft(logout).dx;

    // user info should be left of title
    expect(userTL < titleCenterX, isTrue,
        reason: 'User info is not to the left of title');

    // logout should be to the right of title center
    expect(logoutTL > titleCenterX, isTrue,
        reason: 'Logout button is not to the right of title center');

    // ensure user info width does not exceed 220 (maxWidth)
    final userSize = tester.getSize(user);
    expect(userSize.width <= 220, isTrue,
        reason: 'User info exceeds max width and may overlap center');
  });
}
