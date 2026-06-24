import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/shared_location.dart';

class LocationService {
  LocationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  StreamSubscription<Position>? _positionSubscription;

  Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<void> publishLocation(String userId, Position position) async {
    await _firestore.collection('locations').doc(userId).set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> startSharing(String userId) async {
    await stopSharing();
    final hasPermission = await ensurePermission();
    if (!hasPermission) return;

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen((position) async {
      await publishLocation(userId, position);
    });
  }

  Future<void> stopSharing() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Stream<SharedLocation?> watchLocation(String userId) {
    return _firestore.collection('locations').doc(userId).snapshots().map(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return null;
        return SharedLocation.fromMap(snapshot.id, snapshot.data()!);
      },
    );
  }
}
