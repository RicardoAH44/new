import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_auth/responsive.dart';

import '../../components/background.dart';
import 'components/login_form.dart';
import 'components/login_screen_top_image.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Crea una instancia de FirebaseAuth, asegúrate de tener las importaciones necesarias
    final FirebaseAuth _auth = FirebaseAuth.instance;

    return Background(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: MobileLoginScreen(auth: _auth),
          desktop: Row(
            children: [
              Expanded(
                child: LoginScreenTopImage(),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 450,
                      child: LoginForm(auth: _auth), // Pasa la instancia de FirebaseAuth
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MobileLoginScreen extends StatelessWidget {
  final FirebaseAuth auth;

  const MobileLoginScreen({
    Key? key,
    required this.auth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const LoginScreenTopImage(),
        Row(
          children: [
            Spacer(),
            Expanded(
              flex: 8,
              child: LoginForm(auth: auth), // Pasa la instancia de FirebaseAuth
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}
