class Address {
  final String id;
  final String type; // e.g., 'Home', 'Work', 'Other'
  final String street;
  final String city;
  final String pinCode;
  final String? landmark;
  final bool isDefault;

  const Address({
    required this.id,
    required this.type,
    required this.street,
    required this.city,
    required this.pinCode,
    this.landmark,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      type: json['type'] ?? 'Other',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      pinCode: json['pinCode'] ?? '',
      landmark: json['landmark'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'street': street,
      'city': city,
      'pinCode': pinCode,
      'landmark': landmark,
      'isDefault': isDefault,
    };
  }

  Address copyWith({
    String? id,
    String? type,
    String? street,
    String? city,
    String? pinCode,
    String? landmark,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      type: type ?? this.type,
      street: street ?? this.street,
      city: city ?? this.city,
      pinCode: pinCode ?? this.pinCode,
      landmark: landmark ?? this.landmark,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return '$street, $city, $pinCode${landmark != null ? ' (Landmark: $landmark)' : ''}';
  }
}
