// Simple UserDetails model
class UserDetails {
  final String uid;
  final String email;

  UserDetails({
    required this.uid,
    required this.email,
  });

  // Optional: Convert from Firebase Auth User object
  factory UserDetails.fromFirebaseUser(dynamic user) {
    return UserDetails(
      uid: user.uid,
      email: user.email ?? '',
    );
  }

  // Optional: Convert to Map (if storing in Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
    };
  }

  // Optional: Create from Map (if fetching from Firestore)
  factory UserDetails.fromMap(Map<String, dynamic> map) {
    return UserDetails(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
    );
  }
}
