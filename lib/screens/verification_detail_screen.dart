import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../config/api_config.dart';

class _BlockchainInfo {
  final String? tokenId, txHash, mintedAt;
  final String network;
  _BlockchainInfo({this.tokenId, this.txHash, this.mintedAt, this.network = 'BSC (BNB Smart Chain)'});
  factory _BlockchainInfo.fromJson(Map<String, dynamic> j) => _BlockchainInfo(
    tokenId: j['tokenId']?.toString(), txHash: j['txHash']?.toString(),
    mintedAt: j['mintedAt']?.toString(), network: j['network']?.toString() ?? 'BSC (BNB Smart Chain)',
  );
}

class _TimelineEvent {
  final String type, title;
  final String? from, to, txHash, createdAt;
  _TimelineEvent({required this.type, required this.title, this.from, this.to, this.txHash, this.createdAt});
  factory _TimelineEvent.fromJson(Map<String, dynamic> j) => _TimelineEvent(
    type: j['type']?.toString() ?? '', title: j['title']?.toString() ?? '',
    from: j['from']?.toString(), to: j['to']?.toString(),
    txHash: j['txHash']?.toString(), createdAt: j['createdAt']?.toString(),
  );
}

class _CertData {
  final String id, productName;
  final String? material, dimensions, weight, origin, artisan, studio, owner, issuedAt;
  final bool studioVerified, isValid;
  final _BlockchainInfo? blockchain;
  final List<_TimelineEvent> timeline;
  _CertData({required this.id, required this.productName, this.material, this.dimensions,
    this.weight, this.origin, this.artisan, this.studio, this.studioVerified = false,
    this.owner, this.issuedAt, this.blockchain, this.timeline = const [], this.isValid = true});
  factory _CertData.fromJson(Map<String, dynamic> j, bool valid) {
    final b = j['blockchain'] as Map<String, dynamic>?;
    final tl = (j['timeline'] as List? ?? []).map((e) => _TimelineEvent.fromJson(e as Map<String, dynamic>)).toList();
    return _CertData(
      id: j['id']?.toString() ?? '', productName: j['productName']?.toString() ?? '',
      material: j['material']?.toString(), dimensions: j['dimensions']?.toString(),
      weight: j['weight']?.toString(), origin: j['origin']?.toString(),
      artisan: j['artisan']?.toString(), studio: j['studio']?.toString(),
      studioVerified: j['studioVerified'] == true, owner: j['owner']?.toString(),
      issuedAt: j['issuedAt']?.toString(), blockchain: b != null ? _BlockchainInfo.fromJson(b) : null,
      timeline: tl, isValid: valid,
    );
  }
  String get thumbnailUrl => '${ApiConfig.baseUrl}/uploads/certificates/thumbs/$id.jpg';
  String get pngUrl => '${ApiConfig.baseUrl}/uploads/certificates/$id.png';
}

class VerificationDetailScreen extends StatefulWidget {
  final Product product;
  const VerificationDetailScreen({super.key, required this.product});
  @override
  State<VerificationDetailScreen> createState() => _VerificationDetailScreenState();
}

class _VerificationDetailScreenState extends State<VerificationDetailScreen> {
  _CertData? _cert;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCertificate();
  }

  Future<void> _fetchCertificate() async {
    final certId = widget.product.certificateId;
    if (certId == null) {
      setState(() { _error = 'ID sertifikat tidak ditemukan'; _loading = false; });
      return;
    }
    try {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/certificate/$certId'),
        headers: {'Accept': 'application/json'},
      );
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode == 200 && body['certificate'] != null) {
        setState(() {
          _cert = _CertData.fromJson(body['certificate'] as Map<String, dynamic>, body['isValid'] == true);
          _loading = false;
        });
      } else {
        setState(() { _error = body['error']?.toString() ?? 'Sertifikat tidak ditemukan'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Gagal memuat sertifikat'; _loading = false; });
    }
  }

  Future<void> _downloadPng(BuildContext context) async {
    final cert = _cert;
    if (cert == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Download Sertifikat PNG'),
        content: const Text('File PNG beresolusi tinggi ~4MB. Lanjutkan download?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF653611)),
            child: const Text('Download', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Row(children: [
        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
        SizedBox(width: 16), Text('Mengunduh...'),
      ]),
      backgroundColor: Color(0xFF653611), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 10),
    ));
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) await Gal.requestAccess(toAlbum: true);
      final resp = await http.get(Uri.parse(cert.pngUrl));
      if (resp.statusCode == 200) {
        await Gal.putImageBytes(resp.bodyBytes, name: 'sertifikat_${cert.id}', album: 'MajaCraft');
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Color(0xFFD4AF69)), SizedBox(width: 12),
              Expanded(child: Text('Tersimpan di Galeri → Album MajaCraft')),
            ]),
            backgroundColor: Color(0xFF653611), behavior: SnackBarBehavior.floating,
          ));
        }
      } else throw Exception('${resp.statusCode}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal download: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final certId = widget.product.certificateId ?? '';
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF653611), elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Sertifikat Phygital', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              final url = 'https://majacraft.id/verifikasi/$certId';
              Share.share('Sertifikat Phygital: ${widget.product.name}\nVerifikasi keaslian karya ini di:\n$url', subject: 'Sertifikat Phygital - ${widget.product.name}');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF653611)))
          : _error != null ? _buildError() : _buildContent(),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () { setState(() { _loading = true; _error = null; }); _fetchCertificate(); },
          icon: const Icon(Icons.refresh), label: const Text('Coba Lagi'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF653611), foregroundColor: Colors.white),
        ),
      ]),
    ),
  );

  Widget _buildContent() {
    final cert = _cert!;
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: const Color(0xFF653611), padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.verified, color: Colors.white, size: 16)),
            const SizedBox(width: 8),
            Text(cert.isValid ? 'Sertifikat Terverifikasi ✓' : 'Sertifikat Tidak Valid', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
        ),
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(cert.thumbnailUrl, fit: BoxFit.contain,
              loadingBuilder: (ctx, child, prog) => prog == null ? child : Container(height: 200, alignment: Alignment.center, child: const CircularProgressIndicator(color: Color(0xFF653611))),
              errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey.shade100, alignment: Alignment.center, child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey.shade400)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7A4822), Color(0xFF653611)]), borderRadius: BorderRadius.circular(12)),
            child: ElevatedButton.icon(
              onPressed: () => _downloadPng(context),
              icon: const Icon(Icons.download, size: 20), label: const Text('Download Sertifikat PNG', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse('https://majacraft.id/verifikasi/${cert.id}'), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_browser, size: 18), label: const Text('Lihat di Website (Download PDF)'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF653611), side: const BorderSide(color: Color(0xFF653611)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
        const SizedBox(height: 20),
        _card(Icons.workspace_premium, 'Detail Karya', Column(children: [
          _row('NAMA KARYA', cert.productName),
          _row('MATERIAL', cert.material ?? '-'),
          _row('DIMENSI', cert.dimensions ?? '-'),
          _row('BERAT', cert.weight != null ? '${cert.weight} gram' : '-'),
          _row('ASAL DAERAH', cert.origin ?? '-'),
          _row('SENIMAN', cert.artisan ?? '-'),
          _row('STUDIO', '${cert.studio ?? '-'}${cert.studioVerified ? '  ✓ Terverifikasi' : ''}'),
          if (cert.owner != null) _row('PEMILIK', cert.owner!),
          _row('TANGGAL TERBIT', cert.issuedAt != null ? _fmtDate(cert.issuedAt!) : '-'),
          _row('ID SERTIFIKAT', cert.id, highlight: true),
        ])),
        const SizedBox(height: 16),
        if (cert.blockchain?.tokenId != null) ...[
          _card(Icons.link, 'Info Blockchain', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _row('NETWORK', cert.blockchain!.network),
            _row('TOKEN ID', '#${cert.blockchain!.tokenId}'),
            if (cert.blockchain!.mintedAt != null) _row('MINTING', _fmtDate(cert.blockchain!.mintedAt!)),
            if (cert.blockchain!.txHash != null) ...[
              _row('TX HASH', '${cert.blockchain!.txHash!.substring(0, 14)}...', mono: true),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://bscscan.com/nft/0xcEa918A6f1472F913bD41a2E50aA59CE55553258/${cert.blockchain!.tokenId}'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 15), label: const Text('BSCScan Token', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF653611), side: const BorderSide(color: Color(0xFF653611)), padding: const EdgeInsets.symmetric(vertical: 10)),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://bscscan.com/tx/${cert.blockchain!.txHash}'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.receipt_long, size: 15), label: const Text('Lihat TX', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF653611), side: const BorderSide(color: Color(0xFF653611)), padding: const EdgeInsets.symmetric(vertical: 10)),
                )),
              ]),
            ],
          ])),
          const SizedBox(height: 16),
        ],
        if (cert.timeline.isNotEmpty) ...[
          _card(Icons.history, 'Riwayat Kepemilikan', Column(
            children: cert.timeline.asMap().entries.map((e) => _timelineItem(e.value, e.key == cert.timeline.length - 1)).toList(),
          )),
          const SizedBox(height: 16),
        ],
        _card(Icons.security, 'Dibangun di Atas Blockchain', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _infoPoint(Icons.security, 'Tidak Dapat Dipalsukan', 'Data tersimpan di ribuan node blockchain — tidak ada satu pihak yang dapat mengubah atau menghapusnya.'),
          const SizedBox(height: 12),
          _infoPoint(Icons.visibility, 'Transparan & Terbuka', 'Siapapun dapat memverifikasi keaslian sertifikat ini kapan pun, tanpa perlu akun.'),
          const SizedBox(height: 12),
          _infoPoint(Icons.all_inclusive, 'Permanen Selamanya', 'Selama blockchain BSC beroperasi, catatan ini akan tetap ada tanpa batas waktu.'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse('https://bscscan.com/address/0xcEa918A6f1472F913bD41a2E50aA59CE55553258'), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new, size: 16), label: const Text('Lihat Smart Contract di BSCScan'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF653611), side: const BorderSide(color: Color(0xFF653611))),
          ),
        ])),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _card(IconData icon, String title, Widget child) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: const Color(0xFF653611), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 18)),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 16),
      child,
    ]),
  );

  Widget _row(String label, String value, {bool highlight = false, bool mono = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, letterSpacing: 0.5))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: highlight ? FontWeight.bold : FontWeight.w500, color: highlight ? const Color(0xFF653611) : Colors.black87, fontFamily: mono ? 'monospace' : null))),
    ]),
  );

  Widget _timelineItem(_TimelineEvent ev, bool isLast) {
    final isTransfer = ev.type == 'OWNERSHIP_TRANSFERRED';
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 32, height: 32,
          decoration: BoxDecoration(color: isTransfer ? Colors.blue.shade50 : const Color(0xFFFFF8E7), shape: BoxShape.circle, border: Border.all(color: isTransfer ? Colors.blue.shade300 : const Color(0xFF653611), width: 1.5)),
          child: Icon(isTransfer ? Icons.swap_horiz : Icons.verified, size: 16, color: isTransfer ? Colors.blue.shade600 : const Color(0xFF653611)),
        ),
        if (!isLast) Container(width: 2, height: 32, color: Colors.grey.shade200),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ev.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        if (ev.from != null || ev.to != null) ...[
          const SizedBox(height: 4),
          Text([if (ev.from != null) 'Dari: ${ev.from}', if (ev.to != null) 'Ke: ${ev.to}'].join(' → '), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
        if (ev.createdAt != null) ...[const SizedBox(height: 2), Text(_fmtDate(ev.createdAt!), style: TextStyle(fontSize: 11, color: Colors.grey.shade400))],
        if (ev.txHash != null)
          GestureDetector(onTap: () => launchUrl(Uri.parse('https://bscscan.com/tx/${ev.txHash}'), mode: LaunchMode.externalApplication), child: Text('Lihat TX ↗', style: TextStyle(fontSize: 11, color: Colors.blue.shade600))),
      ]))),
    ]);
  }

  Widget _infoPoint(IconData icon, String title, String desc) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 18, color: const Color(0xFF653611)),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
    ])),
  ]);

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return iso; }
  }
}