import '../models/dispute.dart';
import 'api_service.dart';

class DisputeService {
  final ApiService _apiService;

  DisputeService(this._apiService);

  /// GET /api/disputes/[id] - Detail dispute + semua pesan
  Future<Dispute> getDispute(String disputeId, {String? token}) async {
    try {
      print('[DisputeService] Getting dispute: $disputeId');

      final response = await _apiService.get(
        '/api/disputes/$disputeId',
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        return Dispute.fromJson(response['data'] as Map<String, dynamic>);
      }

      throw Exception(response['error'] ?? 'Failed to get dispute');
    } catch (e) {
      print('[DisputeService] Error getting dispute: $e');
      rethrow;
    }
  }

  /// POST /api/disputes - Buat komplain baru
  Future<Map<String, dynamic>> createDispute({
    required String orderId,
    required DisputeReason reason,
    required String description,
    required DisputeAction requestedAction,
    List<String> evidenceUrls = const [],
    String? token,
  }) async {
    try {
      print('[DisputeService] Creating dispute for order: $orderId');

      final body = {
        'orderId': orderId,
        'reason': reason.value,
        'description': description,
        'requestedAction': requestedAction.value,
        'evidenceUrls': evidenceUrls,
      };

      final response = await _apiService.post(
        '/api/disputes',
        body: body,
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        // Kembalikan raw data — ComplainFormScreen hanya butuh id & disputeNumber
        // Tidak parse ke Dispute object karena response POST tidak include buyer/seller
        return {
          'disputeNumber':
              data['disputeNumber']?.toString() ??
              data['dispute']?['disputeNumber']?.toString() ??
              '',
          'dispute': {
            'id':
                data['dispute']?['id']?.toString() ??
                data['id']?.toString() ??
                '',
          },
        };
      }

      throw Exception(response['error'] ?? 'Failed to create dispute');
    } catch (e) {
      print('[DisputeService] Error creating dispute: $e');
      rethrow;
    }
  }

  /// POST /api/disputes/[id]/messages - Kirim pesan di chat room
  Future<DisputeMessage> sendDisputeMessage(
    String disputeId,
    String message, {
    String? token,
  }) async {
    try {
      print('[DisputeService] Sending message to dispute: $disputeId');

      final response = await _apiService.post(
        '/api/disputes/$disputeId/messages',
        body: {'message': message},
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        return DisputeMessage.fromJson(
          response['data'] as Map<String, dynamic>,
        );
      }

      // Some APIs might return message directly
      if (response['id'] != null && response['message'] != null) {
        return DisputeMessage.fromJson(response);
      }

      throw Exception(response['error'] ?? 'Failed to send message');
    } catch (e) {
      print('[DisputeService] Error sending message: $e');
      rethrow;
    }
  }

  /// POST /api/disputes/[id]/escalate - Eskalasi ke admin
  Future<void> escalateDispute(
    String disputeId,
    String reason, {
    String? token,
  }) async {
    try {
      print('[DisputeService] Escalating dispute: $disputeId');

      final response = await _apiService.post(
        '/api/disputes/$disputeId/escalate',
        body: {'reason': reason},
        token: token,
      );

      if (response['success'] == true) {
        return;
      }

      throw Exception(response['error'] ?? 'Failed to escalate dispute');
    } catch (e) {
      print('[DisputeService] Error escalating dispute: $e');
      rethrow;
    }
  }

  /// POST /api/disputes/[id]/cancel - Batalkan komplain
  Future<void> cancelDispute(
    String disputeId,
    String reason, {
    String? token,
  }) async {
    try {
      print('[DisputeService] Cancelling dispute: $disputeId');

      final response = await _apiService.post(
        '/api/disputes/$disputeId/cancel',
        body: {'reason': reason},
        token: token,
      );

      if (response['success'] == true) {
        return;
      }

      throw Exception(response['error'] ?? 'Failed to cancel dispute');
    } catch (e) {
      print('[DisputeService] Error cancelling dispute: $e');
      rethrow;
    }
  }

  /// PATCH /api/disputes/[id] - Submit resi retur (BUYER)
  Future<void> submitReturnTracking({
    required String disputeId,
    required String courier,
    required String trackingNumber,
    required String shippingPayer,
    String? token,
  }) async {
    try {
      print('[DisputeService] Submitting return tracking for: $disputeId');

      final body = {
        'action': 'submit_return_tracking',
        'courier': courier,
        'trackingNumber': trackingNumber,
        'shippingPayer': shippingPayer,
      };

      final response = await _apiService.patch(
        '/api/disputes/$disputeId',
        body: body,
        token: token,
      );

      if (response['success'] == true) {
        return;
      }

      throw Exception(response['error'] ?? 'Failed to submit return tracking');
    } catch (e) {
      print('[DisputeService] Error submitting return tracking: $e');
      rethrow;
    }
  }

  /// PATCH /api/disputes/[id] - Konfirmasi barang diterima (SELLER/ADMIN)
  Future<void> confirmReturnReceived(String disputeId, {String? token}) async {
    try {
      print('[DisputeService] Confirming return received for: $disputeId');

      final body = {'action': 'confirm_return_received'};

      final response = await _apiService.patch(
        '/api/disputes/$disputeId',
        body: body,
        token: token,
      );

      if (response['success'] == true) {
        return;
      }

      throw Exception(response['error'] ?? 'Failed to confirm return received');
    } catch (e) {
      print('[DisputeService] Error confirming return: $e');
      rethrow;
    }
  }

  /// GET /api/seller/disputes - Daftar komplain (sisi seller)
  Future<List<Dispute>> getSellerDisputes({String? token}) async {
    try {
      print('[DisputeService] Getting seller disputes');

      final response = await _apiService.get(
        '/api/seller/disputes',
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final List<dynamic> disputes = data['disputes'] ?? [];
        return disputes
            .map((json) => Dispute.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception(response['error'] ?? 'Failed to get seller disputes');
    } catch (e) {
      print('[DisputeService] Error getting seller disputes: $e');
      rethrow;
    }
  }

  /// POST /api/seller/disputes/[id]/respond - Seller respons komplain
  Future<void> respondToDispute({
    required String disputeId,
    required String response,
    required bool agreed,
    String? token,
  }) async {
    try {
      print('[DisputeService] Responding to dispute: $disputeId');

      final body = {'response': response, 'agreed': agreed};

      final apiResponse = await _apiService.post(
        '/api/seller/disputes/$disputeId/respond',
        body: body,
        token: token,
      );

      if (apiResponse['success'] == true) {
        return;
      }

      throw Exception(apiResponse['error'] ?? 'Failed to respond to dispute');
    } catch (e) {
      print('[DisputeService] Error responding to dispute: $e');
      rethrow;
    }
  }
}
