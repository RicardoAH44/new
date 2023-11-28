import 'package:flutter/material.dart';
import 'package:flutter_auth/Screens/Sup.dart';

import 'package:flutter_auth/Screens/hosp.dart';
import 'package:flutter_auth/Screens/library.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' show atan2, cos, pi, pow, sin, sqrt;

void main() => runApp(const bankPage());

class bankPage extends StatefulWidget {
  const bankPage({Key? key}) : super(key: key);

  @override
  _SupPageState createState() => _SupPageState();
}

class _SupPageState extends State<bankPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late GoogleMapController mapController;
  Location location = Location();
  LatLng _currentLocation = LatLng(0.0, 0.0);
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng _nearestBank = LatLng(0.0, 0.0);

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

        _searchNearbyBanks();
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

  Future<void> _searchNearbyBanks() async {
    final apiKey = 'AIzaSyDnVASaBzWWIx0ZaO5E5legQLNGrqMIztk';
    final radius = 10000;
    final type = 'bank';

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentLocation.latitude},${_currentLocation.longitude}&radius=$radius&type=$type&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data['results'];

      double minDistance = double.infinity;

      results.forEach((bank) {
        final name = bank['name'];
        final lat = bank['geometry']['location']['lat'];
        final lng = bank['geometry']['location']['lng'];

        final bankLocation = LatLng(lat, lng);
        final distance = _calculateDistance(_currentLocation, bankLocation);

        if (distance < minDistance) {
          minDistance = distance;
          _nearestBank = bankLocation;
        }

        _markers.add(
          Marker(
            markerId: MarkerId(name),
            position: bankLocation,
            infoWindow: InfoWindow(
              title: name,
            ),
          ),
        );
      });

      _getDirections(_nearestBank);
      setState(() {});
    } else {
      throw Exception('Error al obtener bancos cercanos');
    }
  }

  double _calculateDistance(LatLng from, LatLng to) {
    const double earthRadius = 6371.0;
    final double lat1 = from.latitude * (pi / 180);
    final double lon1 = from.longitude * (pi / 180);
    final double lat2 = to.latitude * (pi / 180);
    final double lon2 = to.longitude * (pi / 180);

    final double dlon = lon2 - lon1;
    final double dlat = lat2 - lat1;

    final double a = pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
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
          title: const Text('Bancos'),
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
                title: Text('Supermercado'),
                onTap: () {
                  Navigator.pop(context); // Cierra el drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HospPage()),
                  );
                },
              ),
              ListTile(
                title: Text('Hospitales'),
                onTap: () {
                  // Acciones al hacer clic en la opción 2
                  Navigator.pop(context); // Cierra el drawer
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SupPage()),
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
