import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/shared_location.dart';
import '../../providers/app_state.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  static const _defaultCenter = LatLng(37.7749, -122.4194);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final myLocation = appState.myLocation;
    final markers = _buildMarkers(appState);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: myLocation != null
                ? LatLng(myLocation.latitude, myLocation.longitude)
                : _defaultCenter,
            zoom: 14,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: markers,
          onMapCreated: (controller) => _mapController = controller,
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        appState.profile?.isSharingLocation == true
                            ? Icons.location_on
                            : Icons.location_off,
                        color: appState.profile?.isSharingLocation == true
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appState.profile?.isSharingLocation == true
                              ? 'Your location is being shared with approved contacts.'
                              : 'Turn on sharing to let approved contacts track you.',
                        ),
                      ),
                    ],
                  ),
                  if (appState.approvedConnections.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      'Tracking ${appState.approvedConnections.length} contact(s)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...appState.approvedConnections.map((connection) {
                      final contactId =
                          connection.otherUserId(appState.profile!.id);
                      final profile = appState.contactProfiles[contactId];
                      final location = appState.contactLocations[contactId];
                      return _ContactRow(
                        name: profile?.displayName ?? 'Contact',
                        location: location,
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 200,
          child: FloatingActionButton.small(
            heroTag: 'recenter',
            onPressed: () => _recenter(appState),
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  Set<Marker> _buildMarkers(AppState appState) {
    final markers = <Marker>{};

    for (final entry in appState.contactLocations.entries) {
      final profile = appState.contactProfiles[entry.key];
      final location = entry.value;
      markers.add(
        Marker(
          markerId: MarkerId(entry.key),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(
            title: profile?.displayName ?? 'Contact',
            snippet: _formatUpdatedAt(location.updatedAt),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    return markers;
  }

  Future<void> _recenter(AppState appState) async {
    await appState.refreshLocation();
    final location = appState.myLocation;
    if (location == null || _mapController == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        15,
      ),
    );
  }

  String _formatUpdatedAt(DateTime updatedAt) {
    return 'Updated ${DateFormat.jm().format(updatedAt)}';
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.name,
    required this.location,
  });

  final String name;
  final SharedLocation? location;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.person_pin_circle, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(name)),
          Text(
            location == null
                ? 'No location'
                : DateFormat.jm().format(location!.updatedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
