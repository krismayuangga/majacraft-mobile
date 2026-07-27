import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../models/dispute.dart';
import '../services/dispute_service.dart';
import '../services/upload_service.dart';
import '../services/api_service.dart';

class ComplainFormScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;

  const ComplainFormScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<ComplainFormScreen> createState() => _ComplainFormScreenState();
}

class _ComplainFormScreenState extends State<ComplainFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _disputeService = DisputeService(ApiService());
  final _uploadService = UploadService();
  final _imagePicker = ImagePicker();

  DisputeReason? _selectedReason;
  DisputeAction? _selectedAction;
  bool _isSubmitting = false;

  // Foto bukti
  final List<File> _selectedPhotos = [];
  final List<String> _uploadedUrls = [];
  bool _isUploadingPhoto = false;

  static const Map<DisputeReason, String> _reasons = {
    DisputeReason.NOT_AS_DESCRIBED: 'Tidak sesuai deskripsi',
    DisputeReason.DAMAGED: 'Rusak / cacat',
    DisputeReason.INCOMPLETE: 'Tidak lengkap',
    DisputeReason.NOT_RECEIVED: 'Tidak diterima',
    DisputeReason.WRONG_ITEM: 'Barang salah',
    DisputeReason.FAKE_PRODUCT: 'Produk palsu / tiruan',
    DisputeReason.OTHER: 'Lainnya',
  };

  static const Map<DisputeAction, String> _actions = {
    DisputeAction.REFUND_FULL: 'Refund penuh',
    DisputeAction.REFUND_PARTIAL: 'Refund sebagian',
    DisputeAction.REPLACEMENT: 'Ganti barang',
    DisputeAction.RETURN_REFUND: 'Retur barang + refund',
    DisputeAction.REPAIR: 'Perbaikan',
  };

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  // ─── Photo Picker ──────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    if (_selectedPhotos.length >= 5) {
      _showError('Maksimal 5 foto');
      return;
    }
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked == null) return;
      setState(() => _selectedPhotos.add(File(picked.path)));
    } catch (e) {
      _showError(
        'Gagal membuka ${source == ImageSource.camera ? "kamera" : "galeri"}',
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
      if (index < _uploadedUrls.length) _uploadedUrls.removeAt(index);
    });
  }

  Future<List<String>> _uploadAllPhotos(String token) async {
    if (_selectedPhotos.isEmpty) return [];
    setState(() => _isUploadingPhoto = true);
    final urls = <String>[];
    for (final file in _selectedPhotos) {
      final url = await _uploadService.uploadImage(file, 'evidence', token);
      urls.add(url);
    }
    setState(() => _isUploadingPhoto = false);
    return urls;
  }

  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFF653611),
              ),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFF653611),
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedReason == null) {
      _showError('Pilih alasan komplain');
      return;
    }
    if (_selectedAction == null) {
      _showError('Pilih solusi yang diminta');
      return;
    }

    // Konfirmasi sebelum submit
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajukan Komplain?'),
        content: const Text(
          'Setelah komplain diajukan, penjual akan menerima notifikasi dan diminta untuk merespons dalam 3×24 jam.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF653611),
            ),
            child: const Text(
              'Ya, Ajukan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final token = context.read<AuthProvider>().token!;

      // Upload foto bukti terlebih dahulu
      final evidenceUrls = await _uploadAllPhotos(token);

      final result = await _disputeService.createDispute(
        orderId: widget.orderId,
        reason: _selectedReason!,
        description: _descController.text.trim(),
        requestedAction: _selectedAction!,
        evidenceUrls: evidenceUrls,
        token: token,
      );

      if (!mounted) return;

      final disputeId = result['dispute']?['id']?.toString() ?? '';
      final disputeNumber = result['disputeNumber']?.toString() ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Komplain $disputeNumber berhasil diajukan'),
          backgroundColor: Colors.green,
        ),
      );

      // Return disputeId ke OrderDetailScreen
      Navigator.pop(context, disputeId);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1A14),
        foregroundColor: const Color(0xFFFBBF24),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajukan Komplain',
              style: TextStyle(
                color: Color(0xFFFBBF24),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              widget.orderNumber,
              style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Komplain dapat diajukan sebelum mengonfirmasi penerimaan. '
                        'Penjual akan diminta merespons dalam 3×24 jam.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Alasan
              _buildLabel('Alasan Komplain *'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DisputeReason>(
                    value: _selectedReason,
                    isExpanded: true,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Pilih alasan...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    items: _reasons.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(e.value),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedReason = v),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Deskripsi
              _buildLabel('Deskripsi *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Jelaskan masalah yang kamu alami secara detail...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF653611)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 20) {
                    return 'Deskripsi minimal 20 karakter';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Solusi diminta
              _buildLabel('Solusi yang Diminta *'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DisputeAction>(
                    value: _selectedAction,
                    isExpanded: true,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Pilih solusi...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    items: _actions.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(e.value),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedAction = v),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─── Foto Bukti ───────────────────────────────────────────────
              _buildLabel('Foto Bukti (opsional, maks 5 foto)'),
              const SizedBox(height: 4),
              Text(
                'Foto kondisi barang membantu mempercepat proses komplain',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),

              // Grid foto yang sudah dipilih + tombol tambah
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._selectedPhotos.asMap().entries.map((entry) {
                    final i = entry.key;
                    final file = entry.value;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            file,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => _removePhoto(i),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  // Tombol tambah foto (jika belum 5)
                  if (_selectedPhotos.length < 5)
                    GestureDetector(
                      onTap: _showPhotoSourceDialog,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: const Color(0xFF653611),
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tambah\nFoto',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              if (_isUploadingPhoto)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Mengunggah foto...',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _isUploadingPhoto)
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF653611),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Ajukan Komplain',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1C1A14),
      ),
    );
  }
}
