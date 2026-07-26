class Address {
  final String id;
  final String label;
  final String name;
  final String phone;
  final String address;
  final String city;
  final String province;
  final String? district;    // Added
  final String? village;     // Added
  final String zip;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Address({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.province,
    this.district,           // Added
    this.village,            // Added
    required this.zip,
    required this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      label: json['label'] ?? 'Rumah',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
      district: json['district'],     // Added
      village: json['village'],       // Added
      zip: json['zip'] ?? '',
      isDefault: json['isDefault'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'province': province,
      'district': district,      // Added
      'village': village,        // Added
      'zip': zip,
      'isDefault': isDefault,
    };
  }

  Address copyWith({
    String? id,
    String? label,
    String? name,
    String? phone,
    String? address,
    String? city,
    String? province,
    String? zip,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      province: province ?? this.province,
      zip: zip ?? this.zip,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullAddress {
    final parts = [
      address,
      city,
      province,
      zip,
    ].where((part) => part.isNotEmpty);
    return parts.join(', ');
  }
}
