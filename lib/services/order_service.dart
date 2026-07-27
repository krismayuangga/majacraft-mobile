import '../models/order.dart';
import 'api_service.dart';

// ─── Payment Model ────────────────────────────────────────────────────────────

class PaymentData {
  final String url;
  final String sessionId;
  final String orderId;

  PaymentData({
    required this.url,
    required this.sessionId,
    required this.orderId,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      url: json['url']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
    );
  }
}

// ─── Tracking Models ──────────────────────────────────────────────────────────

class TrackingEvent {
  final DateTime datetime;
  final String description;
  final String? city;

  TrackingEvent({required this.datetime, required this.description, this.city});

  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      datetime:
          DateTime.tryParse(json['datetime']?.toString() ?? '') ??
          DateTime.now(),
      description: json['description']?.toString() ?? '',
      city: json['city']?.toString(),
    );
  }
}

class TrackingData {
  final String source;
  final String courierName;
  final String courierService;
  final String trackingNumber;
  final String status;
  final bool delivered;
  final DateTime? lastUpdate;
  final List<TrackingEvent> events;

  TrackingData({
    required this.source,
    required this.courierName,
    required this.courierService,
    required this.trackingNumber,
    required this.status,
    required this.delivered,
    this.lastUpdate,
    required this.events,
  });

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    final eventsJson = json['events'] as List? ?? [];
    return TrackingData(
      source: json['source']?.toString() ?? 'live',
      courierName: json['courierName']?.toString() ?? '',
      courierService: json['courierService']?.toString() ?? '',
      trackingNumber: json['trackingNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      delivered: json['delivered'] == true,
      lastUpdate: DateTime.tryParse(json['lastUpdate']?.toString() ?? ''),
      events: eventsJson.map((e) => TrackingEvent.fromJson(e)).toList(),
    );
  }
}

// ─── OrderService ─────────────────────────────────────────────────────────────

class OrderService {
  final ApiService _api;

  OrderService(this._api);

  /// POST /api/orders — Buat pesanan baru
  Future<Order> createOrder({
    required String addressId,
    required String courierName,
    required String courierService,
    required int shippingCost,
    required List<Map<String, dynamic>> items, // [{ productId, qty }]
    String paymentMethod = 'ipaymu',
    String? note,
    required String token,
  }) async {
    print(
      '[OrderService] createOrder: ${items.length} items, courier=$courierName $courierService',
    );

    final body = <String, dynamic>{
      'addressId': addressId,
      'courierName': courierName,
      'courierService': courierService,
      'shippingCost': shippingCost,
      'paymentMethod': paymentMethod,
      'items': items,
    };
    if (note != null && note.isNotEmpty) body['note'] = note;

    final response = await _api.post('/api/orders', body: body, token: token);

    if (response['success'] == true && response['data'] != null) {
      return Order.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw Exception(
      response['error'] ?? response['message'] ?? 'Gagal membuat pesanan',
    );
  }

  /// GET /api/orders — List pesanan, opsional filter status
  Future<List<Order>> getOrders({String? status, required String token}) async {
    String endpoint = '/api/orders';
    if (status != null) endpoint += '?status=$status';

    print('[OrderService] getOrders: $endpoint');
    final response = await _api.get(endpoint, token: token);

    if (response['success'] == true) {
      final data = response['data'];
      List<dynamic> list;

      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] is List) {
        list = data['items'] as List;
      } else {
        list = [];
      }

      return list
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// GET /api/orders/[id] — Detail pesanan
  Future<Order> getOrderDetail(String orderId, {required String token}) async {
    print('[OrderService] getOrderDetail: $orderId');
    final response = await _api.get('/api/orders/$orderId', token: token);

    if (response['success'] == true && response['data'] != null) {
      return Order.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw Exception(
      response['error'] ?? response['message'] ?? 'Pesanan tidak ditemukan',
    );
  }

  /// POST /api/payment/create — Buat URL pembayaran iPaymu
  Future<PaymentData> createPayment(
    String orderId, {
    required String token,
  }) async {
    print('[OrderService] createPayment: orderId=$orderId');
    final response = await _api.post(
      '/api/payment/create',
      body: {'orderId': orderId},
      token: token,
    );

    if (response['success'] == true && response['data'] != null) {
      return PaymentData.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw Exception(
      response['error'] ?? response['message'] ?? 'Gagal membuat pembayaran',
    );
  }

  /// GET /api/payment/check/[orderId] — Cek status pembayaran
  Future<String> checkPaymentStatus(
    String orderId, {
    required String token,
  }) async {
    print('[OrderService] checkPaymentStatus: $orderId');
    final response = await _api.get(
      '/api/payment/check/$orderId',
      token: token,
    );

    if (response['success'] == true && response['data'] != null) {
      return response['data']['status']?.toString() ?? 'PENDING_PAYMENT';
    }

    return 'PENDING_PAYMENT';
  }

  /// POST /api/orders/[id]/confirm — Konfirmasi barang diterima
  Future<void> confirmOrder(String orderId, {required String token}) async {
    print('[OrderService] confirmOrder: $orderId');
    final response = await _api.post(
      '/api/orders/$orderId/confirm',
      body: {},
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(
        response['error'] ?? response['message'] ?? 'Gagal konfirmasi pesanan',
      );
    }
  }

  /// POST /api/orders/[id]/cancel — Batalkan pesanan
  Future<void> cancelOrder(String orderId, {required String token}) async {
    print('[OrderService] cancelOrder: $orderId');
    final response = await _api.post(
      '/api/orders/$orderId/cancel',
      body: {},
      token: token,
    );

    if (response['success'] != true) {
      throw Exception(
        response['error'] ?? response['message'] ?? 'Gagal membatalkan pesanan',
      );
    }
  }

  /// GET /api/orders/[id]/tracking — Info tracking pengiriman
  Future<TrackingData> getTracking(
    String orderId, {
    required String token,
  }) async {
    print('[OrderService] getTracking: $orderId');
    final response = await _api.get(
      '/api/orders/$orderId/tracking',
      token: token,
    );

    if (response['success'] == true && response['data'] != null) {
      return TrackingData.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw Exception(
      response['error'] ??
          response['message'] ??
          'Info tracking tidak tersedia',
    );
  }
}
