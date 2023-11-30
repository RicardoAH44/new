import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_auth/Screens/Login/login_screen.dart';
import 'package:flutter_auth/Screens/Sup.dart';
import 'package:flutter_auth/Screens/hosp.dart';
import 'package:flutter_auth/Screens/library.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_auth/Screens/home.dart';


class HomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Widget> featureWidgets = [
    FeatureCard(
      title: 'Hospitales',
      imagePath: 'assets/images/Hospital.jpg',
      routeName: 'Sup',
    ),
    FeatureCard(
      title: 'Supermercados',
      imagePath: 'assets/images/super.jpg',
      routeName: 'hosp',
    ),
    FeatureCard(
      title: 'Bancos',
      imagePath: 'assets/images/bank.jpg',
      routeName: 'bank',
    ),
    FeatureCard(
      title: 'Libreria',
      imagePath: 'assets/images/libb.jpg',
      routeName: 'Library',
    ),
    // Agrega más tarjetas de características aquí
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('¿ONTAA?'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: ListView.builder(
          itemCount: featureWidgets.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: featureWidgets[index],
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 56, 79, 142),
              ),
              child: Text(''),
            ),
            ListTile(
              title: Text('Supermercado'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HospPage()),
                );
              },
            ),
            ListTile(
              title: Text('Hospitales'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SupPage()),
                );
              },
            ),
            ListTile(
              title: Text('Libreria'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LibraryPage()),
                );
              },
            ),
            // Nuevo ListTile para cerrar sesión
            ListTile(
              title: Text('Cerrar Sesión'),
              onTap: () async {
                // Cerrar sesión utilizando Firebase
                await _auth.signOut();
                // Navegar a la pantalla de inicio de sesión
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return LoginScreen(); // Reemplaza "LoginScreen" con el nombre de tu pantalla de inicio de sesión
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final String routeName;

  FeatureCard({
    required this.title,
    required this.imagePath,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
      child: Container(
        width: double.infinity,
        height: 275,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 3,
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: 225,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Text(title, style: TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }
}
