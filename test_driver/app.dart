import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('App Test', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      driver.close();
        });

    test('Verify App Title', () async {
      // Encontrar el widget que contiene el título y verificar su existencia
      final titleFinder = find.text('Flutter Auth');
      expect(await driver.getText(titleFinder), 'Flutter Auth');
    });

    // Agregar más pruebas según sea necesario
  });
}
