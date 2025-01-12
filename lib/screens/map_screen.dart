import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gaster/screens/table_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:gaster/services/csv_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? _currentPosition;
  final MapController _mapController = MapController();
  List<CSVObject> _locations = [];
  bool _isLoading = true;
  String _error = '';

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return 'Address not found';
  }

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      setState(() => _isLoading = true);

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Load CSV data
      _locations = await readCSV();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'View as Table',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TableScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _currentPosition == null
                ? null
                : () {
                    _mapController.move(
                      LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude),
                      15.0,
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeMap,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TableScreen()),
          );
        },
        label: const Text('View Table'),
        icon: const Icon(Icons.table_chart),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeMap,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(0, 0),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: [
            if (_currentPosition != null)
              Marker(
                point: LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude),
                width: 80,
                height: 80,
                child: GestureDetector(
                  onTap: () async {
                    String address = await getAddressFromLatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude);
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Current Location'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Coordinates: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}'),
                              const SizedBox(height: 8),
                              Text('Address: $address'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ),
            ..._locations.map((location) {
              final lat = double.tryParse(location.Latitude);
              final lng = double.tryParse(location.Longitude);
              if (lat == null || lng == null) return null;

              return Marker(
                point: LatLng(lat, lng),
                width: 80,
                height: 80,
                child: GestureDetector(
                  onTap: () async {
                    String address = await getAddressFromLatLng(lat, lng);
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(location.Name),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('District: ${location.District}'),
                              Text(
                                  'Coordinates: ${location.Latitude}, ${location.Longitude}'),
                              const SizedBox(height: 8),
                              Text('Address: $address'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
              );
            }).whereType<Marker>(),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
