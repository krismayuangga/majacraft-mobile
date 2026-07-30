import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/order.dart';

class ReviewFormScreen extends StatefulWidget {
  final String orderId;
  final OrderItem item;
  final VoidCallback onSuccess;

  const ReviewFormScreen({
    super.key,
    required this.orderId,
    required this.item,
    required this.onSuccess,
  });

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  final List<File> _images = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maksimal 5 foto')));
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (picked != null) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  Future<String?> _uploadImage(File file, String token) async {
    try {
      final api = ApiService();
      final url = await api.uploadFile(
        '/api/upload',
        file,
        fieldName: 'file',
        token: token,
        extraFields: {'folder': 'reviews'},
      );
      return url;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih rating bintang terlebih dahulu')),
      );
      return;
    }
    final comment = _commentController.text.trim();
    if (comment.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ulasan minimal 20 karakter')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token!;

      // Upload foto jika ada
      final List<String> imageUrls = [];
      for (final img in _images) {
        final url = await _uploadImage(img, token);
        if (url != null) imageUrls.add(url);
      }

      // Submit review
      final api = ApiService();
      final resp = await api.post(
        '/api/reviews',
        token: token,
        body: {
          'orderId': widget.orderId,
          'productId': widget.item.productId,
          'rating': _rating,
          'comment': comment,
          'imageUrls': imageUrls,
        },
      );

      if (resp['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ulasan berhasil dikirim! Terima kasih.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(resp['error'] ?? 'Gagal mengirim ulasan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Beri Ulasan',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.item.productImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.item.productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rating stars
            const Text(
              'Rating Produk',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      star <= _rating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: star <= _rating
                          ? Colors.amber
                          : Colors.grey.shade400,
                    ),
                  ),
                );
              }),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 8),
              Text(
                [
                  '',
                  'Sangat Buruk',
                  'Buruk',
                  'Cukup',
                  'Bagus',
                  'Sangat Bagus',
                ][_rating],
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Comment
            const Text(
              'Ulasan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText:
                    'Bagikan pengalaman Anda dengan produk ini... (min. 20 karakter)',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF653611),
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_commentController.text.trim().isNotEmpty &&
                _commentController.text.trim().length < 20)
              Text(
                'Masih butuh ${20 - _commentController.text.trim().length} karakter lagi',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),

            const SizedBox(height: 20),

            // Photo upload (optional)
            const Text(
              'Foto Bukti (Opsional)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._images.map(
                  (img) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          img,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.remove(img)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_images.length < 5)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            color: Colors.grey.shade400,
                            size: 28,
                          ),
                          Text(
                            'Tambah',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF653611),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Kirim Ulasan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
