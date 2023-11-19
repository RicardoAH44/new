import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' show atan2, cos, pi, pow, sin, sqrt;

void main() => runApp(const SupPage());

class SupPage extends StatefulWidget {
  const SupPage({Key? key}) : super(key: key);

  @override
  _SupPageState createState() => _SupPageState();
}

class _SupPageState extends State<SupPage> {
  late GoogleMapController mapController;
  Location location = Location();
  LatLng _currentLocation = LatLng(0.0, 0.0);
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng _nearestHospital = LatLng(0.0, 0.0);
  TextEditingController _searchController = TextEditingController();
  bool _showHospitalInfo = false;
  String _selectedHospitalName = '';
  String _selectedHospitalAddress = '';
  String _selectedHospitalPhone = '';
  String _selectedHospitalHours = '';

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

        _searchNearbyHospitals();
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

  Future<void> _searchNearbyHospitals({String? keyword}) async {
    final apiKey = 'AIzaSyDnVASaBzWWIx0ZaO5E5legQLNGrqMIztk';
    final radius = 2500;
    final type = 'hospital';

    String url;
    if (keyword != null && keyword.isNotEmpty) {
      url =
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$keyword&location=${_currentLocation.latitude},${_currentLocation.longitude}&radius=$radius&type=$type&key=$apiKey';
    } else {
      url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentLocation.latitude},${_currentLocation.longitude}&radius=$radius&type=$type&key=$apiKey';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data['results'];

      double minDistance = double.infinity;

      results.forEach((hospital) {
        final name = hospital['name'];
        final lat = hospital['geometry']['location']['lat'];
        final lng = hospital['geometry']['location']['lng'];

        final hospitalLocation = LatLng(lat, lng);
        final distance = _calculateDistance(_currentLocation, hospitalLocation);

        if (distance < minDistance) {
          minDistance = distance;
          _nearestHospital = hospitalLocation;
        }

        _markers.add(
          Marker(
            markerId: MarkerId(name),
            position: hospitalLocation,
            infoWindow: InfoWindow(
              title: name,
            ),
            onTap: () {
              _showhospitalInfo(name);
            },
          ),
        );
      });

      _getDirections(_nearestHospital);
      setState(() {});
    } else {
      throw Exception('Error al obtener hospitales cercanos');
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

  void _showhospitalInfo(String hospitalName) {
    // Implementa la lógica para mostrar la información del hospital según su nombre
    // Puedes obtener la información adicional del hospital aquí y luego mostrarla en la tarjeta
    _selectedHospitalName = hospitalName;
    _selectedHospitalAddress = 'Dirección del hospital';
    _selectedHospitalPhone = 'Teléfono del hospital';
    _selectedHospitalHours = 'Horario del hospital';
    _showHospitalInfo = true;
    setState(() {});
  }

  void _hideHospitalInfo() {
    // Implementa la lógica para ocultar la información del hospital
    _showHospitalInfo = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Mapa con Ubicación Actual y Hospitales Cercanos'),
          backgroundColor: Colors.green[700],
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                _searchNearbyHospitals(keyword: _searchController.text);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar hospitales',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
                ),
                onSubmitted: (value) {
                  _searchNearbyHospitals(keyword: value);
                },
              ),
            ),
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
            if (_showHospitalInfo)
              _buildHospitalInfoCard()
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalInfoCard() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_selectedHospitalName',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text('Dirección: $_selectedHospitalAddress'),
            SizedBox(height: 8.0),
            Text('Teléfono: $_selectedHospitalPhone'),
            SizedBox(height: 8.0),
            Text('Horario: $_selectedHospitalHours'),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _hideHospitalInfo,
              child: Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}

