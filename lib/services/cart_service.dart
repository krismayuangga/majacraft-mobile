import '../models/cart.dart';
import 'api_service.dart';

// ─── Shipping Models ──────────────────────────────────────────────────────────

class ShippingOption {
  final String
  courier; // kode kurir: "anteraja", "jne", "jnt" (untuk API order)
  final String courierName; // nama tampilan: "AnterAja", "JNE"
  final String service; // kode layanan: "ECO", "REG" (untuk API order)
  final String description; // nama layanan: "Anteraja Economy"
  final int cost; // biaya rupiah
  final String etd; // estimasi hari: "2-4"

  ShippingOption({
    required this.courier,
    required this.courierName,
    required this.service,
    required this.description,
    required this.cost,
    required this.etd,
  });

  factory ShippingOption.fromJson(Map<String, dynamic> json) {
    // API mengembalikan: courier_code, courier_name, service_code, service_name, price, etd
    // Fallback ke: courier, service, description, cost (format lama)
    String rawEtd = (json['etd'] ?? '-').toString();
    // Bersihkan " Hari" jika sudah ada di nilai ETD
    rawEtd = rawEtd.replaceAll(RegExp(r'\s*[Hh][Aa][Rr][Ii].*$'), '').trim();
    if (rawEtd.isEmpty) rawEtd = '-';

    return ShippingOption(
      courier:
          json['courier_code']?.toString() ?? json['courier']?.toString() ?? '',
      courierName:
          json['courier_name']?.toString() ?? json['courier']?.toString() ?? '',
      service:
          json['service_code']?.toString() ?? json['service']?.toString() ?? '',
      description:
          json['service_name']?.toString() ??
          json['description']?.toString() ??
          '',
      cost: _parseInt(json['price'] ?? json['cost']),
      etd: rawEtd,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  /// Display: "AnterAja ECO"
  String get displayName => '$courierName $service';

  /// Display: "2-4 hari kerja"
  String get etdText => etd == '-' ? '-' : '$etd hari kerja';
}

class ShippingData {
  final String originCity;
  final String destinationCity;
  final int weight;
  final double weightKg;
  final bool isHeavyItem;
  final String? heavyItemNote;
  final List<ShippingOption> couriers;

  ShippingData({
    required this.originCity,
    required this.destinationCity,
    required this.weight,
    this.weightKg = 0,
    this.isHeavyItem = false,
    this.heavyItemNote,
    required this.couriers,
  });

  factory ShippingData.fromJson(Map<String, dynamic> json) {
    final origin = json['origin'] ?? {};
    final destination = json['destination'] ?? {};
    final List<dynamic> couriersJson = json['couriers'] ?? [];

    final allOptions = couriersJson
        .map((c) => ShippingOption.fromJson(c as Map<String, dynamic>))
        .toList();

    // Debug log
    print('[ShippingData] Total opsi dari API: ${allOptions.length}');
    for (final o in allOptions) {
      print('  → ${o.courier} ${o.service} | cost=${o.cost} | etd=${o.etd}');
    }

    // Filter: hapus yang nama kurir kosong atau cost = 0
    final validOptions = allOptions
        .where((o) => o.courier.isNotEmpty && o.cost > 0)
        .toList();

    // Jika semua cost=0 (sandbox/no data), tampilkan semua agar tidak kosong
    final workingOptions = validOptions.isNotEmpty ? validOptions : allOptions;

    // Sort by cost ascending (termurah di atas)
    workingOptions.sort((a, b) => a.cost.compareTo(b.cost));

    // Batasi max 3 per kurir (ambil yang paling murah)
    final Map<String, int> courierCount = {};
    final filtered = <ShippingOption>[];
    for (final opt in workingOptions) {
      final key = opt.courier.toLowerCase();
      courierCount[key] = (courierCount[key] ?? 0) + 1;
      if (courierCount[key]! <= 3) {
        filtered.add(opt);
      }
    }

    return ShippingData(
      originCity: origin['city']?.toString() ?? '',
      destinationCity: destination['city']?.toString() ?? '',
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      weightKg:
          (json['weightKg'] as num?)?.toDouble() ??
          ((json['weight'] as num?)?.toDouble() ?? 0) / 1000,
      isHeavyItem: json['isHeavyItem'] == true,
      heavyItemNote: json['heavyItemNote']?.toString(),
      couriers: filtered,
    );
  }
}

// ─── CartService ──────────────────────────────────────────────────────────────

class CartService {
  final ApiService _api;

  CartService(this._api);

  /// GET /api/cart — Ambil isi keranjang
  Future<Cart> getCart({required String token}) async {
    print('[CartService] getCart');
    final response = await _api.get('/api/cart', token: token);

    if (response['success'] == true && response['data'] != null) {
      return Cart.fromJson(response['data'] as Map<String, dynamic>);
    }

    // Empty cart response
    return Cart(items: [], itemCount: 0);
  }

  /// POST /api/cart — Tambah item ke keranjang
  Future<void> addToCart({
    required String productId,
    required int qty,
    required String token,
  }) async {
    print('[CartService] addToCart: $productId qty=$qty');
    final response = await _api.post(
      '/api/cart',
      body: {'productId': productId, 'qty': qty},
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(
        response['error'] ??
            response['message'] ??
            'Gagal menambahkan ke keranjang',
      );
    }
  }

  /// PATCH /api/cart — Update qty item
  Future<void> updateCartItem({
    required String cartItemId,
    required int qty,
    required String token,
  }) async {
    print('[CartService] updateCartItem: $cartItemId qty=$qty');
    final response = await _api.patch(
      '/api/cart',
      body: {'cartItemId': cartItemId, 'qty': qty},
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(
        response['error'] ?? response['message'] ?? 'Gagal mengubah jumlah',
      );
    }
  }

  /// DELETE /api/cart — Hapus item dari keranjang
  Future<void> removeCartItem({
    required String cartItemId,
    required String token,
  }) async {
    print('[CartService] removeCartItem: $cartItemId');
    final response = await _api.delete(
      '/api/cart',
      body: {'cartItemId': cartItemId},
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(
        response['error'] ?? response['message'] ?? 'Gagal menghapus item',
      );
    }
  }

  /// POST /api/shipping/cost — Hitung ongkir berdasarkan alamat
  Future<ShippingData> calculateShipping({
    required String addressId,
    required String token,
  }) async {
    print('[CartService] calculateShipping: addressId=$addressId');
    final response = await _api.post(
      '/api/shipping/cost',
      body: {'addressId': addressId},
      token: token,
    );

    print('[CartService] shipping raw response: $response');

    if (response['success'] == true && response['data'] != null) {
      return ShippingData.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw Exception(
      response['error'] ?? response['message'] ?? 'Gagal menghitung ongkir',
    );
  }
}
