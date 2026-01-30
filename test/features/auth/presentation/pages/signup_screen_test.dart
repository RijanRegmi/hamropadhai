import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamropadhai/features/auth/presentation/pages/signup_screen.dart';

void main() {
  testWidgets("Should have a title SIGNUP", (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignupScreen())),
    );

    Finder title = find.text('SIGNUP');
    expect(title, findsOneWidget);
  });

  testWidgets("Should have all input fields", (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignupScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
  });

  testWidgets("Should have Sign up button", (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignupScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign up'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets("Should have gender radio buttons", (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignupScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.byType(RadioListTile<String>), findsNWidgets(2));
  });

  testWidgets("Should accept input in name field", (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignupScreen())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'John Doe');
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
  });
}
