import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_auth/Screens/home.dart';

import '../../../components/already_have_an_account_acheck.dart';
import '../../../constants.dart';


class LoginForm extends StatefulWidget {
  const LoginForm({Key? key, required FirebaseAuth auth}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  Future<void> _signInWithEmailAndPassword(BuildContext context) async {
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Si llega aquí, el inicio de sesión fue exitoso
      // Navega a la página de inicio
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return HomeScreen(); // Reemplaza "HomeScreen" con el nombre de tu página de inicio
          },
        ),
      );
    } catch (e) {
      // Maneja los errores de inicio de sesión aquí
      print('Error de inicio de sesión: $e');

      // Muestra mensajes de error específicos
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          print('No se encontró ningún usuario con este correo electrónico.');
          // Muestra una notificación en la aplicación usando Fluttertoast
          Fluttertoast.showToast(
            msg: 'No se encontró ningún usuario con este correo electrónico.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        } else if (e.code == 'wrong-password') {
          print('Contraseña incorrecta. Verifica tu contraseña e intenta de nuevo.');
          // Muestra una notificación en la aplicación usando Fluttertoast
          Fluttertoast.showToast(
            msg: 'Contraseña incorrecta. Verifica tu contraseña e intenta de nuevo.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
        // Otros códigos de error pueden ser manejados de manera similar.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            cursorColor: kPrimaryColor,
            decoration: InputDecoration(
              hintText: "Tu correo",
              prefixIcon: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Icon(Icons.person),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu correo';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            child: TextFormField(
              controller: _passwordController,
              textInputAction: TextInputAction.done,
              obscureText: true,
              cursorColor: kPrimaryColor,
              decoration: InputDecoration(
                hintText: "Tu contraseña",
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Icon(Icons.lock),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu contraseña';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: defaultPadding / 2),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _signInWithEmailAndPassword(context);
              }
            },
            child: Text("Iniciar Sesión".toUpperCase()),
          ),
          const SizedBox(height: defaultPadding),
          AlreadyHaveAnAccountCheck(
            login: true,
            press: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
