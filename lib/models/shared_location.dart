import 'package:cloud_firestore/cloud_firestore.dart';

class SharedLocation {
  const SharedLocation({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  final String userId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  factory SharedLocation.fromMap(String userId, Map<String, dynamic> data) {
    final timestamp = data['updatedAt'];
    return SharedLocation(
      userId: userId,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      updatedAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
