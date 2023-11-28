import 'package:flutter/material.dart';


import '../../../constants.dart';

class WelcomeImage extends StatelessWidget {
  const WelcomeImage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
       Text(
  "¿ONTAA?",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontFamily: '', // Reemplaza 'NuevaFuente' con el nombre de la fuente que deseas usar
    fontSize: 40.0, // Reemplaza 20.0 con el tamaño de fuente que deseas
  ),
),

        SizedBox(height: defaultPadding * 2),
        Row(
          children: [
            Spacer(),
            Expanded(
              flex: 8,
              child: Image.asset(
                "assets/images/wa.jpg", // Asegúrate de proporcionar la ruta correcta
                // También puedes ajustar la altura y el ancho de la imagen según tus necesidades
                height: 350,
                width: 350,
              ),
            ),
            Spacer(),
          ],
        ),
        SizedBox(height: defaultPadding * 2),
      ],
    );
  }
}
