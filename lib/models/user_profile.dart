class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.isSharingLocation = false,
  });

  final String id;
  final String email;
  final String displayName;
  final bool isSharingLocation;

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'User',
      isSharingLocation: data['isSharingLocation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'isSharingLocation': isSharingLocation,
    };
  }

  UserProfile copyWith({
    String? displayName,
    bool? isSharingLocation,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      isSharingLocation: isSharingLocation ?? this.isSharingLocation,
    );
  }
}
