/// Local app user (mirrors users/{uid} in Firestore).
class AppUser {
  final String uid;
  final String name;
  final String email;

  const AppUser({required this.uid, required this.name, required this.email});
}
