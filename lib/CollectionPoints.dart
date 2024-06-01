import 'dart:async';
import 'dart:developer';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Future<void> getAgentsCollection() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;

    if (user!= null) {
      final agentId = user.uid;
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final CollectionReference agentsRef = _firestore.collection('tournees');

      final QuerySnapshot querySnapshot = await agentsRef.where('agentId', isEqualTo: agentId).get();

      if (querySnapshot.docs.isNotEmpty) {
        print('Agents collection matching with current logged in agent:');
        querySnapshot.docs.forEach((document) {
          print(document.data());
          final data = document.data() as Map<String, dynamic>;
          if(data != null) {
            final pointsDeCollect = data['pointsDeCollect'] as List<dynamic>;

            pointsDeCollect.forEach((point) {
              final lat = point['lat'] as double;
              final lng = point['lng'] as double;
              final markerIdVal = Random().nextInt(10000)
                  .toString(); // generate random id
              _markers.add(
                Marker(
                  markerId: MarkerId(markerIdVal),
                  position: LatLng(lat, lng),
                  icon: BitmapDescriptor.defaultMarker,
                ),
              );
            });

            final firstPoint = pointsDeCollect[0];
            if(firstPoint != null) {
              _kGooglePlex = CameraPosition(
                target: LatLng(firstPoint['lat'] as double, firstPoint['lng'] as double),
                zoom: 19,
              );
            }
          }
        });
      } else {
        print('No agents collection matching with current logged in agent');
      }
    } else {
      print('No user is signed in');
    }
  }

  bool _isTracking = false;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(35.81271783644581, 10.0772944703472),
    zoom: 10,
  );

  Set<Marker> _markers = {};
  List<LatLng> _polylinePoints = [];

  loc.Location _locationTracker = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;
  Timer? _locationUpdateTimer;

  void _onMarkerTapped(MarkerId markerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Marker Clicked'),
          content: Text('You clicked on marker $markerId'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _locationSubscription =
        _locationTracker.onLocationChanged.listen((loc.LocationData location) {
      if (location != null) {
        _polylinePoints.add(LatLng(location.latitude!, location.longitude!));
        setState(() {});
      }
    });

    _locationUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {});
  }

  @override
  Widget build(BuildContext context) {
    getAgentsCollection();
    return Scaffold(
      appBar: AppBar(
        title: Text('Collection Points'),
        actions: _isTracking
            ? [
                IconButton(
                  icon: Icon(Icons.stop),
                  onPressed: _stopLocationUpdates,
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.play_arrow),
                  onPressed: _getUserLocation,
                ),
              ],
      ),
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: _kGooglePlex,
        markers: _markers.map((marker) {
          return Marker(
            markerId: marker.markerId,
            position: marker.position,
            icon: marker.icon,
            onTap: () => _onMarkerTapped(marker.markerId),
          );
        }).toSet(),
        polylines: {
          Polyline(
            polylineId: PolylineId('line'),
            points: _polylinePoints,
            color: Colors.blue,
            width: 3,
          ),
        },
        zoomControlsEnabled: false,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _goToTheFirstLocation,
            child: Icon(Icons.directions),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _zoomIn,
            child: Icon(Icons.add),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _zoomOut,
            child: Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  Future<void> _getUserLocation() async {
    final GoogleMapController controller = await _controller.future;
    final loc.LocationData? location = await _locationTracker.getLocation();
    if (location != null) {
      _polylinePoints.add(LatLng(location.latitude!, location.longitude!));
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('currentLocation'),
            position: LatLng(location.latitude!, location.longitude!),
            icon: BitmapDescriptor.defaultMarker,
          ),
        );
      });
      await controller.animateCamera(
        CameraUpdate.newLatLng(LatLng(location.latitude!, location.longitude!)),
      );

      _locationUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        _getUserLocation();
      });
    }

    setState(() {
      _isTracking = true;
    });
  }

  Future<void> _goToTheFirstLocation() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newLatLng(_kGooglePlex.target));
  }

  void _zoomIn() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomOut());
  }

  void _stopLocationUpdates() {
    _locationSubscription?.cancel();
    setState(() {
      _markers
          .removeWhere((marker) => marker.markerId.value == 'currentLocation');
    });
    _locationUpdateTimer?.cancel();

    setState(() {
      _isTracking = false;
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
}
