import 'package:flutter/material.dart';
import 'package:flutter_auth/Screens/Sup.dart';
import 'package:flutter_auth/Screens/hosp.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' show atan2, cos, pi, pow, sin, sqrt;

void main() => runApp(const LibraryPage());

class LibraryPage extends StatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late GoogleMapController mapController;
  Location location = Location();
  LatLng _currentLocation = LatLng(0.0, 0.0);
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng _nearestLibrary = LatLng(0.0, 0.0);
  TextEditingController _searchController = TextEditingController();
  bool _showLibraryInfo = false;
  String _selectedLibraryName = '';
  String _selectedLibraryAddress = '';
  String _selectedLibraryPhone = '';
  String _selectedLibraryHours = '';
  List<dynamic> _allLibraries = [];

  void _showRouteOnMap(LatLng destination) async {
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

        _searchNearbyLibraries();
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

  Future<void> _searchNearbyLibraries({String? keyword}) async {
    final apiKey = 'AIzaSyDnVASaBzWWIx0ZaO5E5legQLNGrqMIztk';
    final radius = 2500;
    final type = 'library';

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

      results.forEach((library) {
        final name = library['name'];
        final lat = library['geometry']['location']['lat'];
        final lng = library['geometry']['location']['lng'];

        final libraryLocation = LatLng(lat, lng);
        final distance = _calculateDistance(_currentLocation, libraryLocation);

        if (distance < minDistance) {
          minDistance = distance;
          _nearestLibrary = libraryLocation;
        }

        _markers.add(
          Marker(
            markerId: MarkerId(name),
            position: libraryLocation,
            infoWindow: InfoWindow(
              title: name,
            ),
            onTap: () {
              _showlibraryInfo(name);
              _showRouteOnMap(libraryLocation);
            },
          ),
        );

        _allLibraries.add(library);
      });

      _getDirections(_nearestLibrary);
      setState(() {});
    } else {
      throw Exception('Error al obtener librerías cercanas');
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
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Librerias'),
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
                _searchNearbyLibraries(keyword: _searchController.text);
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
                  labelText: 'Buscar librerías',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
                ),
                onSubmitted: (value) {
                  _searchNearbyLibraries(keyword: value);
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
                _showLibraryList();
              },
              child: Text('Mostrar Librerías'),
            ),
            if (_showLibraryInfo)
              _buildLibraryInfoCard()
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
                title: Text('Supermercados'),
                onTap: () {
                  Navigator.pop(context);
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HospPage()),
                  );// Agrega la navegación o acciones adicionales según tu necesidad
                },
              ),
              ListTile(
                title: Text('Hospitales'),
                onTap: () {
                  Navigator.pop(context);
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SupPage()),
                  );// Agrega la navegación o acciones adicionales según tu necesidad
                },
              ),
              ListTile(
                title: Text('Libreria'),
                onTap: () {
                  Navigator.pop(context);
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LibraryPage()),
                  );// Agrega la navegación o acciones adicionales según tu necesidad
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLibraryList() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return _buildLibraryList();
      },
    );
  }

  Widget _buildLibraryInfoCard() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_selectedLibraryName',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text('Dirección: $_selectedLibraryAddress'),
            SizedBox(height: 8.0),
            Text('Teléfono: $_selectedLibraryPhone'),
            SizedBox(height: 8.0),
            Text('Horario: $_selectedLibraryHours'),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _hideLibraryInfo,
              child: Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryList() {
    return ListView.builder(
      itemCount: _allLibraries.length,
      itemBuilder: (context, index) {
        final library = _allLibraries[index];
        return ListTile(
          title: Text(library['name']),
          subtitle: Text(library['formatted_address'] ?? 'Dirección no disponible'),
          onTap: () {
            Navigator.pop(context);
            _showlibraryInfo(library['name']);
            _showRouteOnMap(LatLng(
              library['geometry']['location']['lat'],
              library['geometry']['location']['lng'],
            ));
          },
        );
      },
    );
  }

  void _showlibraryInfo(String libraryName) {
    final selectedLibrary =
        _allLibraries.firstWhere((library) => library['name'] == libraryName);
    _selectedLibraryName = selectedLibrary['name'];
    _selectedLibraryAddress = selectedLibrary['formatted_address'] ?? 'Dirección no disponible';
    _selectedLibraryPhone = selectedLibrary['formatted_phone_number'] ?? 'Teléfono no disponible';
    _selectedLibraryHours = selectedLibrary['opening_hours'] != null &&
            selectedLibrary['opening_hours']['weekday_text'] != null
        ? selectedLibrary['opening_hours']['weekday_text'][0]
        : 'Horario no disponible';

    _showLibraryInfo = true;
    setState(() {});
  }

  void _hideLibraryInfo() {
    _showLibraryInfo = false;
    setState(() {});
  }
}