class UserModel {
  String? uid;
  String? username;
  String? email;
  bool isAdmin;
  bool isApproved;
  bool isActive;

  UserModel({
    this.uid,
    this.username,
    this.email,
    this.isAdmin = false,
    this.isApproved = true,
    this.isActive = true,
  });

  // Conversion depuis/vers Map pour Firebase
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      username: map['username'],
      email: map['email'],
      isAdmin: map['isAdmin'] ?? false,
      isApproved: map['isApproved'] ?? true,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'isAdmin': isAdmin,
      'isApproved': isApproved,
      'isActive': isActive,
    };
  }
}
