import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';

class VerificationDetailScreen extends StatelessWidget {
  final Product product;

  const VerificationDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF653611),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sertifikat Phygital',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fitur share segera hadir'),
                  backgroundColor: Color(0xFF653611),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Badge
            Container(
              decoration: BoxDecoration(color: Color(0xFF653611)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Sertifikat Terverifikasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Certificate Image
            if (product.certificateImageUrl != null)
              Container(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      product.certificateImageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 400,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Gambar sertifikat tidak tersedia',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            // Download Button
            if (product.certificateImageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7A4822), Color(0xFF653611)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadCertificate(context),
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text(
                      'Download Sertifikat PNG',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),

            // Detail Karya Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF653611),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Detail Karya',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('NAMA KARYA', product.name),
                  _buildDetailRow('MATERIAL', product.material ?? '-'),
                  _buildDetailRow('DIMENSI', product.dimensions ?? '-'),
                  _buildDetailRow('BERAT', '${product.weight ?? 0} gram'),
                  _buildDetailRow('ASAL DAERAH', product.origin ?? '-'),
                  _buildDetailRow('SENIMAN', product.artistName ?? '-'),
                  _buildDetailRow('STUDIO', product.sellerName),
                  _buildDetailRow(
                    'TANGGAL TERBIT',
                    _formatDate(DateTime.now()),
                  ),
                  _buildDetailRow(
                    'ID SERTIFIKAT',
                    product.certificateId ?? '-',
                    isHighlight: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Dibangun di Atas Blockchain Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.link, color: Color(0xFF653611), size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        'Dibangun di Atas Blockchain',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.6,
                      ),
                      children: [
                        TextSpan(
                          text:
                              'Sertifikat Phygital MajaCraft menggunakan teknologi ',
                        ),
                        TextSpan(
                          text: 'NFT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextSpan(text: ' di jaringan '),
                        TextSpan(
                          text: 'BSC (BNB Smart Chain)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextSpan(
                          text:
                              '. Setiap sertifikat direkam sebagai token unik yang tidak dapat digandakan.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoPoint(
                    Icons.security,
                    'Tidak Dapat Dipalsukan',
                    'Data tersimpan di ribuan node blockchain — tidak ada satu pihak yang dapat mengubah atau menghapusnya.',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoPoint(
                    Icons.visibility,
                    'Transparan & Terbuka',
                    'Siapapun dapat memverifikasi keaslian sertifikat ini kapan pun dan di mana pun, tanpa perlu akun.',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoPoint(
                    Icons.all_inclusive,
                    'Permanen Selamanya',
                    'Selama blockchain BSC beroperasi, catatan sertifikat ini akan tetap ada tanpa batas waktu.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Penting Untuk Dipahami Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFFFFDF0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE5C77D), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Color(0xFFD4AF69),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Penting Untuk Dipahami',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFFFD54F), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bukan Instrumen Investasi',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sertifikat Phygital MajaCraft bukan produk investasi atau instrumen keuangan. Nilainya tidak dijamin dan tidak dimaksudkan untuk diperjualbelikan sebagai aset digital.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoPoint(
                    Icons.description,
                    'Dokumen Identitas Digital',
                    'Berfungsi sebagai bukti pendaftaran dan identitas karya fisik — bukan jaminan kondisi fisik produk.',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoPoint(
                    Icons.lock,
                    'Non-Transferable (Soulbound)',
                    'Melekat pada karya dan tidak dapat dipindahtangankan secara independen dari karya fisiknya.',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoPoint(
                    Icons.privacy_tip,
                    'Privasi Pemilik Terlindungi',
                    'Data pembeli tidak dipublikasikan penuh. Hanya nama depan dan inisial yang ditampilkan.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Kembali Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text(
                  'Kembali ke Produk',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF653611),
                  side: BorderSide(color: Color(0xFF653611), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadCertificate(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(width: 16),
              Text('Mengunduh sertifikat...'),
            ],
          ),
          backgroundColor: Color(0xFF653611),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // Download implementation
      final response = await http.get(Uri.parse(product.certificateImageUrl!));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/certificate_${product.certificateId}.png';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFFD4AF69)),
                  SizedBox(width: 12),
                  Expanded(child: Text('Sertifikat berhasil diunduh!')),
                ],
              ),
              backgroundColor: Color(0xFF653611),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 12),
                Expanded(child: Text('Gagal mengunduh sertifikat')),
              ],
            ),
            backgroundColor: Color(0xFF653611),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isHighlight ? Color(0xFF653611) : Colors.black87,
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Color(0xFF653611), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
