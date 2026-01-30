import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamropadhai/features/auth/presentation/pages/login_screen.dart';

void main() {
  testWidgets("Should have a title LOGIN", (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    Finder title = find.text('LOGIN');
    expect(title, findsOneWidget);
  });

  testWidgets("Should have username and password fields", (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets("Should have Log in button", (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets("Should accept input in username field", (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'myusername');
    await tester.pumpAndSettle();

    expect(find.text('myusername'), findsOneWidget);
  });

  testWidgets("Should toggle password visibility", (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    final passwordField = tester.widget<TextField>(find.byType(TextField).last);
    expect(passwordField.obscureText, true);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pumpAndSettle();

    final updatedPasswordField = tester.widget<TextField>(
      find.byType(TextField).last,
    );
    expect(updatedPasswordField.obscureText, false);
  });
}
