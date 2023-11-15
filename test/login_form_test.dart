import 'package:flutter/material.dart';
import 'package:flutter_auth/Screens/home.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_auth/Screens/Login/components/login_form.dart';

void main() {
  // Inicializa Firebase antes de ejecutar las pruebas
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
  });

  testWidgets('Login exitoso', (WidgetTester tester) async {
    final FirebaseAuth auth = FirebaseAuth.instance;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LoginForm(auth: auth)),
      ),
    );

    await tester.enterText(find.byKey(ValueKey('emailField')), 'test@example.com');
    await tester.enterText(find.byKey(ValueKey('passwordField')), 'password');

    await tester.tap(find.byKey(ValueKey('loginButton')));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}