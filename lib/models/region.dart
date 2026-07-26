class Province {
  final String id;
  final String name;

  Province({required this.id, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(id: json['id'].toString(), name: json['name'] ?? '');
  }
}

class Regency {
  final String id;
  final String provinceId;
  final String name;

  Regency({required this.id, required this.provinceId, required this.name});

  factory Regency.fromJson(Map<String, dynamic> json) {
    return Regency(
      id: json['id'].toString(),
      provinceId: json['province_id']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}

class District {
  final String id;
  final String regencyId;
  final String name;

  District({required this.id, required this.regencyId, required this.name});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'].toString(),
      regencyId: json['regency_id']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}

class Village {
  final String id;
  final String districtId;
  final String name;

  Village({required this.id, required this.districtId, required this.name});

  factory Village.fromJson(Map<String, dynamic> json) {
    return Village(
      id: json['id'].toString(),
      districtId: json['district_id']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}
