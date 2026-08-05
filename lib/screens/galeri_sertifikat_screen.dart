import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../screens/verification_detail_screen.dart';
import '../models/product.dart';

class GaleriSertifikatScreen extends StatefulWidget {
  const GaleriSertifikatScreen({super.key});

  @override
  State<GaleriSertifikatScreen> createState() => _GaleriSertifikatScreenState();
}

class _GaleriSertifikatScreenState extends State<GaleriSertifikatScreen> {
  final _searchCtrl = TextEditingController();
  List<_CertItem> _certs = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _certs = [];
        _loading = true;
        _hasMore = true;
      });
    }
    try {
      var ep = '/api/certificate?page=$_page&limit=12';
      if (_search.isNotEmpty) ep += '&search=${Uri.encodeComponent(_search)}';
      final resp = await ApiService().get(ep);
      final data = (resp['data'] ?? resp) as Map<String, dynamic>;
      final list = (data['certificates'] as List? ?? [])
          .map((e) => _CertItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = data['pagination'] as Map<String, dynamic>?;
      final total = pagination?['total'] as int? ?? list.length;
      setState(() {
        if (refresh)
          _certs = list;
        else
          _certs.addAll(list);
        _hasMore = _certs.length < total;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _page++;
    });
    await _load();
  }

  void _openDetail(String certId) {
    final minimalProduct = Product(
      id: certId,
      name: '',
      slug: certId,
      price: 0,
      image: '',
      images: const [],
      category: '',
      sellerId: '',
      sellerName: '',
      sellerSlug: '',
      sellerLocation: '',
      sellerRating: 0,
      sold: 0,
      rating: 0,
      reviews: 0,
      stock: 0,
      hasNFT: true,
      certificateId: certId,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerificationDetailScreen(product: minimalProduct),
      ),
    );
  }

  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QRScannerScreen(
          onResult: (certId) {
            Navigator.pop(context);
            _openDetail(certId);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF653611),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Galeri Sertifikat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            tooltip: 'Scan QR Sertifikat',
            onPressed: _openQRScanner,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama karya, seniman, ID sertifikat...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFFB45309),
                  size: 20,
                ),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                          _load(refresh: true);
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFB45309)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onSubmitted: (v) {
                setState(() => _search = v.trim());
                _load(refresh: true);
              },
            ),
          ),
          // Grid
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF653611)),
                  )
                : _certs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.workspace_premium_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada sertifikat',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    addAutomaticKeepAlives: false,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 280,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: _certs.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _certs.length) {
                        if (!_loadingMore) _loadMore();
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: Color(0xFF653611),
                            ),
                          ),
                        );
                      }
                      return _CertCard(
                        cert: _certs[i],
                        onTap: () => _openDetail(_certs[i].id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Certificate card --------------------------------------------------------

class _CertCard extends StatelessWidget {
  final _CertItem cert;
  final VoidCallback onTap;
  const _CertCard({required this.cert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final thumbUrl =
        'https://majacraft.id/uploads/certificates/thumbs/${cert.id}.jpg';
    final shortId = cert.id.length > 18
        ? '${cert.id.substring(0, 12)}...'
        : cert.id;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: CachedNetworkImage(
                      imageUrl: thumbUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 300,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade100),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF1C1A14),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Color(0xFFB45309),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                if (cert.nftTokenId != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1A14).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'NFT #${cert.nftTokenId}',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (cert.storeVerified)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 9, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'Terverifikasi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cert.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cert.sellerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shortId,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- QR Scanner ------------------------------------------------------------

class _QRScannerScreen extends StatefulWidget {
  final void Function(String certId) onResult;
  const _QRScannerScreen({required this.onResult});

  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  bool _detected = false;
  final _regex = RegExp(r'MAJA-\d{4}-[A-Z0-9]{12}');

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue ?? '';
      final match = _regex.firstMatch(raw);
      if (match != null) {
        _detected = true;
        widget.onResult(match.group(0)!);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan QR Sertifikat',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          // Target frame overlay
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFB45309), width: 2.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white54,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  'Arahkan kamera ke QR code pada sertifikat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Data model -------------------------------------------------------------

class _CertItem {
  final String id, productName, sellerName;
  final String? nftTokenId;
  final bool storeVerified;

  _CertItem({
    required this.id,
    required this.productName,
    required this.sellerName,
    this.nftTokenId,
    this.storeVerified = false,
  });

  factory _CertItem.fromJson(Map<String, dynamic> j) => _CertItem(
    id: j['id']?.toString() ?? '',
    productName: j['productName']?.toString() ?? '',
    sellerName: '${j['sellerName'] ?? ''} � ${j['sellerStore'] ?? ''}',
    nftTokenId: j['nftTokenId']?.toString(),
    storeVerified:
        (j['product'] as Map<String, dynamic>?)?['store']?['isVerified'] ==
        true,
  );
}
