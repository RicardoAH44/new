import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../constants.dart';
import '../../home.dart'; // Asegúrate de importar la página home.dart

class LoginForm extends StatefulWidget {
  final FirebaseAuth auth;

  const LoginForm({
    Key? key,
    required this.auth, // Agregado el parámetro 'auth' en el constructor
  }) : super(key: key);

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
      // Puedes mostrar un mensaje de error al usuario si lo deseas.
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
                return 'Por favor ingresa tu email';
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
          const SizedBox(height: defaultPadding),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _signInWithEmailAndPassword(context); // Pasa el contexto a la función
              }
            },
            child: Text("Iniciar sesion".toUpperCase()),
          ),
          const SizedBox(height: defaultPadding),
          // Otras partes de tu formulario
        ],
      ),
    );
  }
}
