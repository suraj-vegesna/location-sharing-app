import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sharing_connection.dart';
import '../../providers/app_state.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    try {
      await context.read<AppState>().sendConnectionRequest(email);
      _emailController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing request sent.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final userId = appState.profile!.id;

    final pendingIncoming = appState.connections
        .where(
          (c) =>
              c.status == ConnectionStatus.pending && c.recipientId == userId,
        )
        .toList();

    final pendingOutgoing = appState.connections
        .where(
          (c) =>
              c.status == ConnectionStatus.pending && c.requesterId == userId,
        )
        .toList();

    final approved = appState.approvedConnections;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Invite family or friends',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Send a request by email. They must approve before either of you can see locations.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _sendRequest,
              child: const Text('Send'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (pendingIncoming.isNotEmpty) ...[
          _SectionHeader(
            title: 'Pending approvals',
            subtitle: 'Approve to share locations with each other.',
          ),
          ...pendingIncoming.map(
            (connection) => _IncomingRequestTile(connection: connection),
          ),
          const SizedBox(height: 16),
        ],
        if (pendingOutgoing.isNotEmpty) ...[
          _SectionHeader(
            title: 'Sent requests',
            subtitle: 'Waiting for them to approve.',
          ),
          ...pendingOutgoing.map(
            (connection) => _OutgoingRequestTile(connection: connection),
          ),
          const SizedBox(height: 16),
        ],
        _SectionHeader(
          title: 'Approved contacts',
          subtitle: 'You can track each other on the map.',
        ),
        if (approved.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.people_outline),
              title: Text('No approved contacts yet'),
              subtitle: Text('Send an invite to get started.'),
            ),
          )
        else
          ...approved.map(
            (connection) => _ApprovedContactTile(connection: connection),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ],
      ),
    );
  }
}

class _IncomingRequestTile extends StatelessWidget {
  const _IncomingRequestTile({required this.connection});

  final SharingConnection connection;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          appState.contactProfiles[connection.requesterId]?.displayName ??
              connection.requesterId,
        ),
        subtitle: const Text('Wants to share locations with you'),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              tooltip: 'Reject',
              onPressed: () => context
                  .read<AppState>()
                  .respondToRequest(connection.id, false),
              icon: const Icon(Icons.close, color: Colors.red),
            ),
            IconButton(
              tooltip: 'Approve',
              onPressed: () => context
                  .read<AppState>()
                  .respondToRequest(connection.id, true),
              icon: const Icon(Icons.check, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutgoingRequestTile extends StatelessWidget {
  const _OutgoingRequestTile({required this.connection});

  final SharingConnection connection;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.schedule)),
        title: Text(
          appState.contactProfiles[connection.recipientId]?.displayName ??
              connection.recipientId,
        ),
        subtitle: const Text('Request pending approval'),
        trailing: IconButton(
          tooltip: 'Cancel',
          onPressed: () =>
              context.read<AppState>().removeConnection(connection.id),
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _ApprovedContactTile extends StatelessWidget {
  const _ApprovedContactTile({required this.connection});

  final SharingConnection connection;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final contactId = connection.otherUserId(appState.profile!.id);
    final profile = appState.contactProfiles[contactId];
    final hasLocation = appState.contactLocations.containsKey(contactId);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            (profile?.displayName ?? 'U').substring(0, 1).toUpperCase(),
          ),
        ),
        title: Text(profile?.displayName ?? 'Contact'),
        subtitle: Text(
          hasLocation ? 'Location available' : 'Location not shared yet',
        ),
        trailing: IconButton(
          tooltip: 'Remove',
          onPressed: () =>
              context.read<AppState>().removeConnection(connection.id),
          icon: const Icon(Icons.link_off),
        ),
      ),
    );
  }
}
