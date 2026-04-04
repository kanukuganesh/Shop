import 'address.dart';

class User {
  final String username;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? profilePictureUrl;
  final String? password;
  final String passwordHint;
  final String usernameHint;
  final bool isAdmin;
  final DateTime? memberSince;
  final List<Address> addresses;

  const User({
    required this.username,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.profilePictureUrl,
    this.password,
    required this.passwordHint,
    required this.usernameHint,
    required this.isAdmin,
    this.memberSince,
    this.addresses = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      profilePictureUrl: json['profilePictureUrl'],
      password: json['password'],
      passwordHint: json['passwordHint'] ?? '',
      usernameHint: json['usernameHint'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      memberSince: json['memberSince'] != null ? DateTime.parse(json['memberSince']) : null,
      addresses: json['addresses'] != null
          ? List<Address>.from(json['addresses'].map((x) => Address.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'password': password,
      'passwordHint': passwordHint,
      'usernameHint': usernameHint,
      'isAdmin': isAdmin,
      'memberSince': memberSince?.toIso8601String(),
      'addresses': addresses.map((x) => x.toJson()).toList(),
    };
  }
}
