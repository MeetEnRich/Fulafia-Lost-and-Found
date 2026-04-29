import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String matricNumber;
  final String faculty;
  final String department;
  final String phoneNumber;
  final String? profileImageUrl;
  final String role; // 'student', 'staff', 'admin'
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.matricNumber,
    required this.faculty,
    required this.department,
    required this.phoneNumber,
    this.profileImageUrl,
    this.role = 'student',
    required this.createdAt,
  });

  /// Whether this user has admin privileges.
  bool get isAdmin => role == 'admin';

  /// Whether this user is a staff member.
  bool get isStaff => role == 'staff';

  /// Create from Firestore document snapshot.
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      matricNumber: map['matricNumber'] ?? '',
      faculty: map['faculty'] ?? '',
      department: map['department'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      role: map['role'] ?? 'student',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'matricNumber': matricNumber,
      'faculty': faculty,
      'department': department,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with modified fields.
  UserModel copyWith({
    String? fullName,
    String? email,
    String? matricNumber,
    String? faculty,
    String? department,
    String? phoneNumber,
    String? profileImageUrl,
    String? role,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      matricNumber: matricNumber ?? this.matricNumber,
      faculty: faculty ?? this.faculty,
      department: department ?? this.department,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'UserModel(uid: $uid, fullName: $fullName, email: $email)';
}
