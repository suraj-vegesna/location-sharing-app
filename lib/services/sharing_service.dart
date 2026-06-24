import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sharing_connection.dart';
import '../models/user_profile.dart';

class SharingService {
  SharingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static String connectionIdFor(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Stream<List<SharingConnection>> watchConnections(String userId) {
    final controller = StreamController<List<SharingConnection>>.broadcast();
    QuerySnapshot<Map<String, dynamic>>? requesterDocs;
    QuerySnapshot<Map<String, dynamic>>? recipientDocs;

    void emit() {
      if (requesterDocs == null || recipientDocs == null) return;
      final docs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final doc in requesterDocs!.docs) {
        docs[doc.id] = doc;
      }
      for (final doc in recipientDocs!.docs) {
        docs[doc.id] = doc;
      }
      final connections = docs.values
          .map((doc) => SharingConnection.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(connections);
    }

    final requesterSub = _firestore
        .collection('connections')
        .where('requesterId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      requesterDocs = snapshot;
      emit();
    });

    final recipientSub = _firestore
        .collection('connections')
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      recipientDocs = snapshot;
      emit();
    });

    controller.onCancel = () {
      requesterSub.cancel();
      recipientSub.cancel();
    };

    return controller.stream;
  }

  Future<void> sendRequest({
    required String requesterId,
    required UserProfile recipient,
  }) async {
    if (requesterId == recipient.id) {
      throw StateError('You cannot send a request to yourself.');
    }

    final connectionId = connectionIdFor(requesterId, recipient.id);
    final existingDoc =
        await _firestore.collection('connections').doc(connectionId).get();

    if (existingDoc.exists) {
      final status = existingDoc.data()?['status'] as String?;
      if (status == ConnectionStatus.approved.name) {
        throw StateError('You are already sharing locations with this person.');
      }
      if (status == ConnectionStatus.pending.name) {
        final requester = existingDoc.data()?['requesterId'] as String?;
        if (requester == requesterId) {
          throw StateError('A request is already pending with this person.');
        }
        throw StateError('This person already sent you a request. Check pending requests.');
      }
    }

    await _firestore.collection('connections').doc(connectionId).set({
      'requesterId': requesterId,
      'recipientId': recipient.id,
      'status': ConnectionStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> respondToRequest({
    required String connectionId,
    required bool approve,
  }) async {
    await _firestore.collection('connections').doc(connectionId).update({
      'status': approve
          ? ConnectionStatus.approved.name
          : ConnectionStatus.rejected.name,
    });
  }

  Future<void> removeConnection(String connectionId) async {
    await _firestore.collection('connections').doc(connectionId).delete();
  }

  List<String> approvedContactIds(
    String userId,
    List<SharingConnection> connections,
  ) {
    return connections
        .where((c) => c.status == ConnectionStatus.approved)
        .map((c) => c.otherUserId(userId))
        .toList();
  }

  Future<Map<String, UserProfile>> loadProfiles(Iterable<String> userIds) async {
    final ids = userIds.toSet().toList();
    if (ids.isEmpty) return {};

    final profiles = <String, UserProfile>{};
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.skip(i).take(10).toList();
      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        profiles[doc.id] = UserProfile.fromMap(doc.id, doc.data());
      }
    }
    return profiles;
  }
}
