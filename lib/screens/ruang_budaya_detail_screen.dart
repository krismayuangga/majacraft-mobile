import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../models/ruang_budaya.dart';
import '../services/api_service.dart';

class RuangBudayaDetailScreen extends StatefulWidget {
  final RuangBudayaPost post;
  const RuangBudayaDetailScreen({super.key, required this.post});

  @override
  State<RuangBudayaDetailScreen> createState() => _RuangBudayaDetailScreenState();
}

class _RuangBudayaDetailScreenState extends State<RuangBudayaDetailScreen> {
  String? _htmlContent;
  bool _loadingContent = true;
  late WebViewController _webCtrl;

  @override
  void initState() {
    super.initState();
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (req) {
          // Buka link eksternal di browser
          if (!req.url.startsWith('data:') && !req.url.startsWith('about:')) {
            launchUrl(Uri.parse(req.url), mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final resp = await ApiService().get('/api/ruang-budaya/${widget.post.id}');
      final data = (resp['data'] ?? resp) as Map<String, dynamic>;
      final content = data['content']?.toString() ?? '';
      if (mounted) {
        setState(() {
          _htmlContent = content;
          _loadingContent = false;
        });
        _loadHtml(content);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingContent = false);
    }
  }

  void _loadHtml(String content) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
<style>
  body { font-family: -apple-system, sans-serif; font-size: 15px; line-height: 1.7;
         color: #1a1a1a; margin: 0; padding: 16px; }
  img { max-width: 100%; height: auto; border-radius: 8px; margin: 8px 0; }
  p { margin: 0 0 12px; }
  h1,h2,h3 { color: #333; margin: 16px 0 8px; }
  a { color: #B45309; }
  blockquote { border-left: 3px solid #B45309; margin: 12px 0; padding: 8px 16px;
               background: #fafaf5; color: #555; font-style: italic; }
  ul, ol { padding-left: 20px; }
  li { margin-bottom: 6px; }
</style>
</head>
<body>$content</body>
</html>''';
    _webCtrl.loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: post.coverImage != null ? 250 : 0,
            pinned: true,
            backgroundColor: const Color(0xFF1C1A14),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFFBBF24)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_browser, color: Color(0xFFFBBF24)),
                onPressed: () => launchUrl(
                  Uri.parse('https://majacraft.id/ruang-budaya/${post.slug}'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
            flexibleSpace: post.coverImage != null
                ? FlexibleSpaceBar(
                    background: Image.network(
                      post.coverImage!.startsWith('http')
                          ? post.coverImage!
                          : 'https://majacraft.id${post.coverImage}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFF1C1A14)),
                    ),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB45309),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _typeLabel(post.type),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(post.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3)),
                  const SizedBox(height: 12),
                  // Author + date + views
                  Row(children: [
                    if (post.author != null) ...[
                      Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(post.author!.name, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(width: 12),
                    ],
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(timeago.format(post.publishedAt, locale: 'id'), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(width: 12),
                    Icon(Icons.visibility_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${post.viewCount}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ]),
                  // Event info
                  if (post.type == 'ACARA' && post.eventDate != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.event, size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Text(post.eventDate!, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.amber.shade700)),
                        ]),
                        if (post.eventLocation != null) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Expanded(child: Text(post.eventLocation!, style: TextStyle(color: Colors.grey.shade700))),
                          ]),
                        ],
                      ]),
                    ),
                  ],
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(spacing: 6, children: post.tags.map((tag) => Chip(
                      label: Text('#$tag', style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey.shade100,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList()),
                  ],
                  const Divider(height: 32),
                  // HTML Content
                  if (_loadingContent)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: Color(0xFFB45309)),
                    ))
                  else
                    SizedBox(
                      height: 600,
                      child: WebViewWidget(controller: _webCtrl),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'ARTIKEL': return 'Artikel';
      case 'CERITA_KARYA': return 'Cerita Karya';
      case 'ACARA': return 'Acara';
      default: return type;
    }
  }
}