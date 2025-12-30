import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:kalender_unitas/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin login navigates to main and shows ADMIN badge',
      (WidgetTester tester) async {
    // Start the app
    app.main();

    // Wait for the app to settle and Firebase initialization to complete
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Ensure we're on the Login page by checking for the password field
    final passwordField = find.byKey(const Key('admin_password_field'));
    expect(passwordField, findsOneWidget);

    // Enter admin password and tap login
    await tester.enterText(passwordField, 'unitas2025');
    await tester.pumpAndSettle();

    final loginButton = find.byKey(const Key('admin_login_button'));
    expect(loginButton, findsOneWidget);

    await tester.tap(loginButton);
    // Wait for navigation and animations
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify we navigated to MainPage by checking for the 'ADMIN' badge
    expect(find.text('ADMIN'), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
