import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';

/// Dialog reusable untuk upgrade BUYER → SELLER.
/// Dipanggil dari halaman Akun (tombol "Jadi Seniman") maupun dari tab Studio.
class UpgradeToSellerDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const UpgradeToSellerDialog({super.key, required this.onSuccess});

  @override
  State<UpgradeToSellerDialog> createState() => _UpgradeToSellerDialogState();
}

class _UpgradeToSellerDialogState extends State<UpgradeToSellerDialog> {
  final _storeNameController = TextEditingController();
  String? _selectedProvince;
  bool _isLoading = false;
  String? _errorMessage;

  static const _provinces = [
    'DKI Jakarta',
    'Jawa Barat',
    'Jawa Tengah',
    'Jawa Timur',
    'DI Yogyakarta',
    'Banten',
    'Bali',
    'Sumatera Utara',
    'Sumatera Barat',
    'Sumatera Selatan',
    'Kalimantan Timur',
    'Sulawesi Selatan',
    'NTB',
    'NTT',
    'Aceh',
    'Lainnya',
  ];

  @override
  void dispose() {
    _storeNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final storeName = _storeNameController.text.trim();
    if (storeName.length < 3) {
      setState(() => _errorMessage = 'Nama toko minimal 3 karakter');
      return;
    }
    if (_selectedProvince == null) {
      setState(() => _errorMessage = 'Pilih provinsi asal');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/upgrade-seller'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'storeName': storeName,
          'province': _selectedProvince,
        }),
      );

      if (!mounted) return;

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      // Ambil pesan error dari berbagai kemungkinan key
      String? errorMsg =
          data['error'] as String? ??
          data['message'] as String? ??
          (data['data'] is Map ? (data['data'] as Map)['error'] : null);

      if (response.statusCode == 200 || data['success'] == true) {
        // Berhasil → refresh user data dan tutup dialog
        await context.read<AuthProvider>().refreshUserData();
        if (!mounted) return;
        Navigator.pop(context);
        widget.onSuccess();
      } else {
        setState(
          () => _errorMessage =
              errorMsg ?? 'Gagal upgrade akun (${response.statusCode})',
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upgrade ke Seniman',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Isi data studio Anda untuk mulai berjualan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama Toko
            const Text(
              'NAMA TOKO / STUDIO *',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _storeNameController,
              decoration: InputDecoration(
                hintText: 'cth: Kerajinan Batu Jogja',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Provinsi
            const Text(
              'PROVINSI ASAL *',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedProvince,
              hint: const Text('Pilih provinsi...'),
              isExpanded: true,
              items: _provinces
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedProvince = v),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),

            // Error
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[700], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB45309),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Upgrade Sekarang',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}

/// Helper — panggil dari mana saja
void showUpgradeToSellerDialog(
  BuildContext context, {
  required VoidCallback onSuccess,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => UpgradeToSellerDialog(onSuccess: onSuccess),
  );
}
