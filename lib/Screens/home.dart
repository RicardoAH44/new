import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
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
        title: Text('Widgets Section'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: ListView.builder(
          itemCount: featureWidgets.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 15), // Espacio entre tarjetas
              child: featureWidgets[index],
            );
          },
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
