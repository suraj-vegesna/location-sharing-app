import 'package:cloud_firestore/cloud_firestore.dart';

enum ConnectionStatus { pending, approved, rejected }

class SharingConnection {
  const SharingConnection({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String requesterId;
  final String recipientId;
  final ConnectionStatus status;
  final DateTime createdAt;

  bool involves(String userId) =>
      requesterId == userId || recipientId == userId;

  String otherUserId(String currentUserId) =>
      requesterId == currentUserId ? recipientId : requesterId;

  bool isApprovedFor(String viewerId, String targetId) {
    if (status != ConnectionStatus.approved) return false;
    return (requesterId == viewerId && recipientId == targetId) ||
        (requesterId == targetId && recipientId == viewerId);
  }

  factory SharingConnection.fromMap(String id, Map<String, dynamic> data) {
    final statusRaw = data['status'] as String? ?? 'pending';
    return SharingConnection(
      id: id,
      requesterId: data['requesterId'] as String,
      recipientId: data['recipientId'] as String,
      status: ConnectionStatus.values.firstWhere(
        (s) => s.name == statusRaw,
        orElse: () => ConnectionStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'recipientId': recipientId,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
