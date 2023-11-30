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

void main() => runApp(const BankPage());

class BankPage extends StatefulWidget {
  const BankPage({Key? key}) : super(key: key);

  @override
  _BankPageState createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late GoogleMapController mapController;
  Location location = Location();
  LatLng _currentLocation = LatLng(0.0, 0.0);
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng _nearestBank = LatLng(0.0, 0.0);
  TextEditingController _searchController = TextEditingController();
  bool _showBankInfo = false;
  String _selectedBankName = '';
  String _selectedBankAddress = '';
  String _selectedBankHours = '';

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

  Future<void> _searchNearbyBanks({String? keyword}) async {
    final apiKey = 'AIzaSyDnVASaBzWWIx0ZaO5E5legQLNGrqMIztk';
    final radius = 10000;
    final type = 'bank';

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
            onTap: () {
              _showbankInfo(name);
              _showRouteOnMap(bankLocation);
            },
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

  Future<void> _showRouteOnMap(LatLng destination) async {
    try {
      await _getDirections(destination);
      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsFromLatLngList([_currentLocation, destination]), 100),
      );
    } catch (e) {
      print("Error al mostrar la ruta en el mapa: $e");
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double minLat = list[0].latitude;
    double maxLat = list[0].latitude;
    double minLng = list[0].longitude;
    double maxLng = list[0].longitude;

    for (LatLng latLng in list) {
      if (latLng.latitude < minLat) minLat = latLng.latitude;
      if (latLng.latitude > maxLat) maxLat = latLng.latitude;
      if (latLng.longitude < minLng) minLng = latLng.longitude;
      if (latLng.longitude > maxLng) maxLng = latLng.longitude;
    }

    return LatLngBounds(northeast: LatLng(maxLat, maxLng), southwest: LatLng(minLat, minLng));
  }

  void _showbankInfo(String bankName) {
    // Implementa la lógica para mostrar la información del banco
    // ignore: unused_local_variable
    final selectedBank = _markers.firstWhere((marker) => marker.markerId.value == bankName);
    _selectedBankName = bankName;
    _selectedBankAddress = 'Dirección del banco';
    _selectedBankHours = 'Horario del banco';

    _showBankInfo = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Bancos'),
          backgroundColor: const Color.fromARGB(255, 56, 79, 142),
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState!.openDrawer();
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                _searchNearbyBanks(keyword: _searchController.text);
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
                  labelText: 'Buscar bancos',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
                ),
                onSubmitted: (value) {
                  _searchNearbyBanks(keyword: value);
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
            ElevatedButton(
              onPressed: () {
                _showBankList();
              },
              child: Text('Mostrar Bancos'),
            ),
            if (_showBankInfo)
              _buildBankInfoCard()
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
                  Navigator.pop(context);
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HospPage()),
                  );// Implementa la lógica para navegar a la página de supermercados
                },
              ),
              ListTile(
                title: Text('Hospitales'),
                onTap: () {
                  Navigator.pop(context);
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SupPage()),
                  );// Implementa la lógica para navegar a la página de hospitales
                },
              ),
              ListTile(
                title: Text('Libreria'),
                onTap: () {
                  Navigator.pop(context);
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LibraryPage()),
                  );// Implementa la lógica para navegar a la página de librerías
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBankList() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return _buildBankList();
      },
    );
  }

  Widget _buildBankInfoCard() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_selectedBankName',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text('Dirección: $_selectedBankAddress'),
            SizedBox(height: 8.0),
            Text('Horario: $_selectedBankHours'),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                _hideBankInfo();
              },
              child: Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankList() {
    // Implementa la lógica para construir la lista de bancos
    return ListView.builder(
      itemCount: _markers.length,
      itemBuilder: (context, index) {
        final bank = _markers.elementAt(index);
        return ListTile(
          title: Text(bank.markerId.value),
          onTap: () {
            Navigator.pop(context); // Cerrar el modal
            _showbankInfo(bank.markerId.value);
            _showRouteOnMap(bank.position);
          },
        );
      },
    );
  }

  void _hideBankInfo() {
    _showBankInfo = false;
    setState(() {});
  }
}
