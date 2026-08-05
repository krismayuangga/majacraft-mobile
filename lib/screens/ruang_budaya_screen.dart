import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/ruang_budaya.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import 'ruang_budaya_detail_screen.dart';

class RuangBudayaScreen extends StatefulWidget {
  const RuangBudayaScreen({super.key});

  @override
  State<RuangBudayaScreen> createState() => _RuangBudayaScreenState();
}

class _RuangBudayaScreenState extends State<RuangBudayaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RuangBudayaPost> _posts = [];
  bool _isLoading = true;
  String? _currentType; // null = Semua, ARTIKEL, CERITA_KARYA, ACARA

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      switch (index) {
        case 0:
          _currentType = null; // Semua
          break;
        case 1:
          _currentType = 'ARTIKEL';
          break;
        case 2:
          _currentType = 'CERITA_KARYA';
          break;
        case 3:
          _currentType = 'ACARA';
          break;
      }
    });
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();

      // Build endpoint with query params
      String endpoint = '/api/ruang-budaya';
      if (_currentType != null) {
        endpoint += '?type=$_currentType';
      }

      final response = await apiService.get(endpoint);

      if (response['success'] == true) {
        final data = response['data'];
        final postsList = data['posts'] as List<dynamic>? ?? [];

        setState(() {
          _posts = postsList
              .map(
                (item) =>
                    RuangBudayaPost.fromJson(item as Map<String, dynamic>),
              )
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('[RuangBudaya] Error loading posts: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1A14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFBBF24)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ruang Budaya',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF78350F).withOpacity(0.4),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFBBF24),
              unselectedLabelColor: const Color(0xFFB45309),
              indicatorColor: const Color(0xFFFBBF24),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'Semua'),
                Tab(text: 'Artikel'),
                Tab(text: 'Cerita Karya'),
                Tab(text: 'Acara'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
              ),
            )
          : _posts.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadPosts,
              color: const Color(0xFFFBBF24),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  return _buildPostCard(_posts[index]);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: const Color(0xFF78350F).withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada konten',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Konten akan segera hadir',
            style: TextStyle(
              color: const Color(0xFFFEE686).withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(RuangBudayaPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF2A2620),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF78350F).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RuangBudayaDetailScreen(post: post),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            if (post.coverImage != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  post.coverImage!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: const Color(0xFF1C1A14),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Color(0xFF78350F),
                        size: 48,
                      ),
                    );
                  },
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A3206).withOpacity(0.5),
                      border: Border.all(
                        color: const Color(0xFFE17200).withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      post.typeDisplay,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFD230),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Excerpt
                  Text(
                    post.excerpt,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFFEE686).withOpacity(0.7),
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Event Info (if event)
                  if (post.isEvent) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: const Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          post.formattedEventDate ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFBBF24),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (post.eventLocation != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: const Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              post.eventLocation!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFBBF24),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Meta info
                  Row(
                    children: [
                      // Author
                      if (post.author != null) ...[
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.author!.name,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      // Time ago
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeago.format(post.publishedAt, locale: 'id'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB45309),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // View count
                      const Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.viewCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB45309),
                        ),
                      ),

                      // RSVP count (for events)
                      if (post.isEvent && post.eventMaxRsvp != null) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.people_outline,
                          size: 14,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.rsvpCount}/${post.eventMaxRsvp}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Tags
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: post.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF78350F).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFFEE686),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
