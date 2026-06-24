import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/sharing_connection.dart';
import '../models/shared_location.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/sharing_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    AuthService? authService,
    LocationService? locationService,
    SharingService? sharingService,
  })  : _authService = authService ?? AuthService(),
        _locationService = locationService ?? LocationService(),
        _sharingService = sharingService ?? SharingService();

  final AuthService _authService;
  final LocationService _locationService;
  final SharingService _sharingService;

  UserProfile? _profile;
  List<SharingConnection> _connections = [];
  Map<String, UserProfile> _contactProfiles = {};
  Map<String, SharedLocation> _contactLocations = {};
  SharedLocation? _myLocation;
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<SharingConnection>>? _connectionsSubscription;
  final Map<String, StreamSubscription<SharedLocation?>> _locationSubscriptions =
      {};

  UserProfile? get profile => _profile;
  List<SharingConnection> get connections => _connections;
  Map<String, UserProfile> get contactProfiles => _contactProfiles;
  Map<String, SharedLocation> get contactLocations => _contactLocations;
  SharedLocation? get myLocation => _myLocation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _profile != null;

  List<SharingConnection> get pendingIncoming => _connections
      .where(
        (c) =>
            c.status == ConnectionStatus.pending &&
            c.recipientId == _profile?.id,
      )
      .toList();

  List<SharingConnection> get approvedConnections => _connections
      .where((c) => c.status == ConnectionStatus.approved)
      .toList();

  Future<void> initialize() async {
    _authSubscription = _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    _clearConnectionListeners();
    _connectionsSubscription?.cancel();
    _connectionsSubscription = null;

    if (user == null) {
      await _locationService.stopSharing();
      _profile = null;
      _connections = [];
      _contactProfiles = {};
      _contactLocations = {};
      _myLocation = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _profile = await _authService.getProfile(user.uid);
    _connectionsSubscription =
        _sharingService.watchConnections(user.uid).listen((connections) async {
      _connections = connections;
      await _refreshContacts();
      notifyListeners();
    });

    await _refreshMyLocation();
    if (_profile?.isSharingLocation == true) {
      await _locationService.startSharing(user.uid);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setError(null);
    _profile = await _authService.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setError(null);
    _profile = await _authService.signIn(email: email, password: password);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> toggleLocationSharing(bool enabled) async {
    final userId = _profile?.id;
    if (userId == null) return;

    await _authService.updateSharingPreference(
      userId: userId,
      isSharing: enabled,
    );
    _profile = _profile!.copyWith(isSharingLocation: enabled);

    if (enabled) {
      await _locationService.startSharing(userId);
      await _refreshMyLocation();
    } else {
      await _locationService.stopSharing();
    }
    notifyListeners();
  }

  Future<void> sendConnectionRequest(String email) async {
    final userId = _profile?.id;
    if (userId == null) return;

    final recipient = await _authService.findUserByEmail(email.toLowerCase());
    if (recipient == null) {
      throw StateError('No user found with that email.');
    }

    await _sharingService.sendRequest(
      requesterId: userId,
      recipient: recipient,
    );
  }

  Future<void> respondToRequest(String connectionId, bool approve) async {
    await _sharingService.respondToRequest(
      connectionId: connectionId,
      approve: approve,
    );
  }

  Future<void> removeConnection(String connectionId) async {
    await _sharingService.removeConnection(connectionId);
  }

  Future<void> refreshLocation() async {
    await _refreshMyLocation();
    notifyListeners();
  }

  Future<void> _refreshMyLocation() async {
    final userId = _profile?.id;
    if (userId == null) return;

    final position = await _locationService.getCurrentPosition();
    if (position == null) return;

    _myLocation = SharedLocation(
      userId: userId,
      latitude: position.latitude,
      longitude: position.longitude,
      updatedAt: DateTime.now(),
    );

    if (_profile?.isSharingLocation == true) {
      await _locationService.publishLocation(userId, position);
    }
  }

  Future<void> _refreshContacts() async {
    final userId = _profile?.id;
    if (userId == null) return;

    final allContactIds = _connections
        .map((connection) => connection.otherUserId(userId))
        .toSet();
    _contactProfiles = await _sharingService.loadProfiles(allContactIds);

    final approvedIds =
        _sharingService.approvedContactIds(userId, _connections);

    _clearConnectionListeners();
    _contactLocations = {};

    for (final contactId in approvedIds) {
      _locationSubscriptions[contactId] =
          _locationService.watchLocation(contactId).listen((location) {
        if (location != null) {
          _contactLocations[contactId] = location;
        } else {
          _contactLocations.remove(contactId);
        }
        notifyListeners();
      });
    }
  }

  void _clearConnectionListeners() {
    for (final subscription in _locationSubscriptions.values) {
      subscription.cancel();
    }
    _locationSubscriptions.clear();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _connectionsSubscription?.cancel();
    _clearConnectionListeners();
    _locationService.stopSharing();
    super.dispose();
  }
}
