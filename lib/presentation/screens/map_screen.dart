import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  LatLng _currentPos = const LatLng(0, 0);

  bool _screenShouldLoad = false;

  final List<LatLng> _allLocationTraveled = [];

  late GoogleMapController googleMapController;

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  Future<void> _takePermission() async {
    LocationPermission locationPermissionStatus =
        await Geolocator.checkPermission();
    if (locationPermissionStatus == LocationPermission.denied) {
      await Geolocator.requestPermission();
      locationPermissionStatus = await Geolocator.checkPermission();
      if (locationPermissionStatus == LocationPermission.denied) {
        _takePermission();
      }
    } else if (locationPermissionStatus == LocationPermission.deniedForever) {
      await Geolocator.openLocationSettings();
      locationPermissionStatus = await Geolocator.checkPermission();
      if (locationPermissionStatus != LocationPermission.always &&
          locationPermissionStatus != LocationPermission.whileInUse) {
        _takePermission();
      }
    }
  }

  Future<void> _getUpdatedLocation() async {
    await _takePermission();
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      ),
    ).listen((position) async {
      _currentPos = LatLng(position.latitude, position.longitude);

      _allLocationTraveled.insert(0, _currentPos);

      await googleMapController.moveCamera(CameraUpdate.newLatLng(_currentPos));

      setState(() {});
    });
  }

  Future<void> _getCurrentPosition() async {
    _screenShouldLoad = false;
    setState(() {});

    await _takePermission();

    final curPos = await Geolocator.getCurrentPosition();

    _currentPos = LatLng(curPos.latitude, curPos.longitude);

    _allLocationTraveled.insert(0, _currentPos);

    _screenShouldLoad = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Visibility(
          visible: _screenShouldLoad && _currentPos != const LatLng(0, 0),
          replacement: const Center(
            child: CircularProgressIndicator(),
          ),
          child: GoogleMap(
            onMapCreated: (controller) {
              googleMapController = controller;
              _getUpdatedLocation();
            },
            initialCameraPosition:
                CameraPosition(target: _currentPos, zoom: 16),
            markers: {
              Marker(
                markerId: const MarkerId("currentPosition"),
                position: _currentPos,
                infoWindow: InfoWindow(
                    title: "My current location",
                    snippet:
                        "latitude ${_currentPos.latitude} and longitude ${_currentPos.longitude}"),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId("currentPosition"),
                color: Colors.blue,
                width: 5,
                points: _allLocationTraveled,
              )
            },
          ),
        ),
      ),
    );
  }
}

