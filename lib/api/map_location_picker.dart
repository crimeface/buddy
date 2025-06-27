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
    if (widget.initialLocation != null) {
      setState(() {
        _mapCenter = widget.initialLocation;
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        setState(() {
          _mapCenter = LatLng(19.0760, 72.8777); // fallback: Mumbai
          _isLoading = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _mapCenter = LatLng(pos.latitude, pos.longitude);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _mapCenter = LatLng(19.0760, 72.8777); // fallback: Mumbai
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _mapCenter == null) {
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