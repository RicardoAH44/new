import 'package:flutter/material.dart';
import 'package:flutter_auth/Screens/Sup.dart';
import 'package:flutter_auth/Screens/bank.dart';
import 'package:flutter_auth/Screens/library.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' show atan2, cos, pi, pow, sin, sqrt;

void main() => runApp(const HospPage());

class HospPage extends StatefulWidget {
  const HospPage({Key? key}) : super(key: key);

  @override
  _SupermarketPageState createState() => _SupermarketPageState();
}

class _SupermarketPageState extends State<HospPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late GoogleMapController mapController;
  Location location = Location();
  LatLng _currentLocation = LatLng(0.0, 0.0);
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng _nearestSupermarket = LatLng(0.0, 0.0);

  @override
  void initState() {
    super.initState();
    _centerMapOnUserLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _centerMapOnUserLocation() async {
    try {
      var userLocation = await location.getLocation();
      setState(() {
        _currentLocation = LatLng(userLocation.latitude!, userLocation.longitude!);

        _markers.add(
          Marker(
            markerId: MarkerId('user_location'),
            position: _currentLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: 'Tu ubicación actual',
            ),
          ),
        );

        _searchNearbySupermarkets();
      });

      mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(userLocation.latitude!, userLocation.longitude!),
        ),
      );
    } catch (e) {
      print("Error al obtener la ubicación: $e");
    }
  }

  Future<void> _searchNearbySupermarkets() async {
    final apiKey = 'AIzaSyDnVASaBzWWIx0ZaO5E5legQLNGrqMIztk';
    final radius = 2500;
    final type = 'supermarket';

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentLocation.latitude},${_currentLocation.longitude}&radius=$radius&type=$type&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data['results'];

      double minDistance = double.infinity;

      results.forEach((supermarket) {
        final name = supermarket['name'];
        final lat = supermarket['geometry']['location']['lat'];
        final lng = supermarket['geometry']['location']['lng'];

        final supermarketLocation = LatLng(lat, lng);
        final distance = _calculateDistance(_currentLocation, supermarketLocation);

        if (distance < minDistance) {
          minDistance = distance;
          _nearestSupermarket = supermarketLocation;
        }

        _markers.add(
          Marker(
            markerId: MarkerId(name),
            position: supermarketLocation,
            infoWindow: InfoWindow(
              title: name,
            ),
          ),
        );
      });

      _getDirections(_nearestSupermarket);
      setState(() {});
    } else {
      throw Exception('Error al obtener supermercados cercanos');
    }
  }

  double _calculateDistance(LatLng from, LatLng to) {
    const double earthRadius = 6371.0; // Radio de la Tierra en kilómetros
    final double lat1 = from.latitude * (pi / 180);
    final double lon1 = from.longitude * (pi / 180);
    final double lat2 = to.latitude * (pi / 180);
    final double lon2 = to.longitude * (pi / 180);

    final double dlon = lon2 - lon1;
    final double dlat = lat2 - lat1;

    final double a = pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distancia en kilómetros
  }

  Future<void> _getDirections(LatLng destination) async {
    final apiKey = 'AIzaSyDnVASaBzWWIx0ZaO5E5legQLNGrqMIztk';
    final directionsApi = 'https://maps.googleapis.com/maps/api/directions/json?';

    final origin = _currentLocation;

    _polylines.clear();

    final url = '$directionsApi'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> routes = data['routes'];
      if (routes.isNotEmpty) {
        final points = PolylinePoints().decodePolyline(routes[0]['overview_polyline']['points']);
        List<LatLng> polylineCoordinates = [];
        for (PointLatLng point in points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        final String polylineId = 'polyline_id_${destination.latitude}${destination.longitude}';
        final Polyline polyline = Polyline(
          polylineId: PolylineId(polylineId),
          color: Colors.blue,
          points: polylineCoordinates,
          width: 5,
        );
        _polylines.add(polyline);

        setState(() {});
      }
    } else {
      throw Exception('Error al obtener direcciones');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey, // Agrega esta línea
        appBar: AppBar(
          title: const Text('Supermercado'),
          backgroundColor: const Color.fromARGB(255, 56, 139, 142),
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState!.openDrawer();
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation,
                  zoom: 15.0,
                ),
                markers: _markers,
                polylines: _polylines,
              ),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.green[700],
                ),
                child: Text('Menú'),
              ),
               ListTile(
                title: Text('Hospitales'),
                onTap: () {
                  Navigator.pop(context); // Cierra el drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SupPage()),
                  );
                },
              ),
              ListTile(
                title: Text('Bancos'),
                onTap: () {
                  // Acciones al hacer clic en la opción 2
                  Navigator.pop(context); // Cierra el drawer
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => bankPage()),
                  );
                },
              ),
                ListTile(
                title: Text('Libreria'),
                onTap: () {
                  // Acciones al hacer clic en la opción 2
                  Navigator.pop(context); // Cierra el drawer
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LibraryPage()),
                  );
                },
              ),
              // Agrega más opciones según tus necesidades
            ],
          ),
        ),
      ),
    );
  }
}
