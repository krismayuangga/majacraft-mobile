import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  bool _loadingContent = true;
  late WebViewController _webCtrl;

  @override
  void initState() {
    super.initState();
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) { if (mounted) setState(() => _loadingContent = false); },
        onNavigationRequest: (req) {
          if (!req.url.startsWith('data:') && !req.url.startsWith('about:')) {
            launchUrl(Uri.parse(req.url), mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
    _fetchAndLoad();
  }

  Future<void> _fetchAndLoad() async {
    final post = widget.post;
    String bodyContent = '<p>${post.excerpt}</p>';
    try {
      final resp = await ApiService().get('/api/ruang-budaya/${post.id}');
      final data = (resp['data'] ?? resp) as Map<String, dynamic>;
      bodyContent = data['content']?.toString() ?? bodyContent;
    } catch (_) {}

    final coverUrl = post.coverImage != null
        ? (post.coverImage!.startsWith('http') ? post.coverImage! : 'https://majacraft.id${post.coverImage}')
        : null;

    final typeLabel = {'ARTIKEL': 'Artikel', 'CERITA_KARYA': 'Cerita Karya', 'ACARA': 'Acara'}[post.type] ?? post.type;

    final authorRow = post.author != null ? '''
      <span class="meta-item">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M12 12c2.7 0 4.8-2.1 4.8-4.8S14.7 2.4 12 2.4 7.2 4.5 7.2 7.2 9.3 12 12 12zm0 2.4c-3.2 0-9.6 1.6-9.6 4.8v2.4h19.2v-2.4c0-3.2-6.4-4.8-9.6-4.8z"/></svg>
        ${post.author?.name ?? ''}
      </span>''' : '';

    final tagsHtml = post.tags.isNotEmpty
        ? '<div class="tags">${post.tags.map((t) => '<span class="tag">#$t</span>').join('')}</div>'
        : '';

    final eventHtml = post.type == 'ACARA' && post.eventDate != null ? '''
      <div class="event-box">
        <div class="event-date">📅 ${post.eventDate}</div>
        ${post.eventLocation != null ? '<div class="event-loc">📍 ${post.eventLocation}</div>' : ''}
      </div>''' : '';

    final html = '''<!DOCTYPE html>
<html><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
  * { box-sizing: border-box; }
  body { font-family: -apple-system, 'Segoe UI', sans-serif; font-size: 15px;
         line-height: 1.7; color: #1a1a1a; margin: 0; padding: 0; background: #fff; }
  .cover { width: 100%; max-height: 250px; object-fit: cover; display: block; }
  .content-wrap { padding: 18px 18px 40px; }
  .badge { display: inline-block; background: #B45309; color: #fff; font-size: 11px;
           font-weight: 700; padding: 3px 10px; border-radius: 4px; margin-bottom: 12px; }
  h1 { font-size: 21px; font-weight: 800; line-height: 1.3; margin: 0 0 12px; }
  .meta { display: flex; flex-wrap: wrap; gap: 12px; color: #888; font-size: 12px; margin-bottom: 12px; }
  .meta-item { display: flex; align-items: center; gap: 4px; }
  .tags { margin: 10px 0; }
  .tag { display: inline-block; background: #f3f3f3; color: #555; font-size: 11px;
         padding: 3px 8px; border-radius: 20px; margin: 2px 4px 2px 0; }
  .event-box { background: #fefce8; border: 1px solid #fde68a; border-radius: 8px;
               padding: 12px 14px; margin: 12px 0; font-size: 13px; }
  .event-date { font-weight: 700; color: #b45309; margin-bottom: 4px; }
  .event-loc { color: #555; }
  hr { border: none; border-top: 1px solid #e5e5e5; margin: 16px 0; }
  img { max-width: 100%; height: auto; border-radius: 8px; margin: 8px 0; display: block; }
  p { margin: 0 0 14px; }
  h2, h3, h4 { color: #111; margin: 20px 0 8px; }
  a { color: #B45309; }
  blockquote { border-left: 3px solid #B45309; margin: 14px 0; padding: 10px 14px;
               background: #fdf6ee; color: #555; font-style: italic; border-radius: 0 8px 8px 0; }
  ul, ol { padding-left: 22px; margin: 0 0 14px; }
  li { margin-bottom: 6px; }
  pre, code { background: #f5f5f5; border-radius: 4px; font-family: monospace; font-size: 13px; }
  pre { padding: 12px; overflow-x: auto; }
  code { padding: 2px 6px; }
  figure { margin: 12px 0; }
  figcaption { font-size: 12px; color: #888; text-align: center; }
</style>
</head>
<body>
${coverUrl != null ? '<img class="cover" src="$coverUrl" alt="cover">' : ''}
<div class="content-wrap">
  <span class="badge">$typeLabel</span>
  <h1>${post.title}</h1>
  <div class="meta">$authorRow
    <span class="meta-item">🕐 ${_formatDate(post.publishedAt)}</span>
    <span class="meta-item">👁 ${post.viewCount}</span>
  </div>
  $tagsHtml
  $eventHtml
  <hr>
  $bodyContent
</div>
</body></html>''';

    if (mounted) _webCtrl.loadHtmlString(html);
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1A14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFBBF24)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          post.type == 'ACARA' ? 'Acara' : post.type == 'CERITA_KARYA' ? 'Cerita Karya' : 'Artikel',
          style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Color(0xFFFBBF24)),
            tooltip: 'Buka di website',
            onPressed: () => launchUrl(
              Uri.parse('https://majacraft.id/ruang-budaya/${post.slug}'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView isi seluruh body — scroll dihandle oleh WebView sendiri
          WebViewWidget(controller: _webCtrl),
          if (_loadingContent)
            const Center(child: CircularProgressIndicator(color: Color(0xFFB45309))),
        ],
      ),
    );
  }
}