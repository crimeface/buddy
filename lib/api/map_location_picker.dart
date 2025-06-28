import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  const MapLocationPicker({Key? key, this.initialLocation}) : super(key: key);

  @override
  _MapLocationPickerState createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  LatLng? _pickedLocation;
  LatLng? _mapCenter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Set a default location immediately for faster loading
    setState(() {
      _mapCenter = widget.initialLocation ?? LatLng(19.0760, 72.8777); // Default: Mumbai
    });

    // If we have an initial location, no need to get current position
    if (widget.initialLocation != null) {
      return;
    }

    // Try to get current location in background
    _getCurrentLocationInBackground();
  }

  Future<void> _getCurrentLocationInBackground() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return; // Keep the default location
      }

      // Use a timeout to prevent hanging
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      
      if (mounted) {
        setState(() {
          _mapCenter = LatLng(pos.latitude, pos.longitude);
        });
      }
    } catch (e) {
      // Keep the default location if there's an error
      print('Error getting current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mapCenter == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Pick Location')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: Text('Pick Location')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _mapCenter!,
          zoom: 14,
        ),
        onTap: (latLng) {
          setState(() {
            _pickedLocation = latLng;
          });
        },
        markers: _pickedLocation == null
            ? {}
            : {
                Marker(
                  markerId: MarkerId('picked'),
                  position: _pickedLocation!,
                ),
              },
      ),
      floatingActionButton: _pickedLocation == null
          ? null
          : FloatingActionButton(
              child: Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop(_pickedLocation);
              },
            ),
    );
  }
}