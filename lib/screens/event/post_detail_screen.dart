import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';

class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final postType = post['postType'] as String? ?? 'news';
    final isEvent = postType == 'event';
    final authorName = post['authorUsername'] ?? 'Unknown';
    final title = post['title'] ?? '';
    final body = post['body'] ?? '';
    final createdAt = post['createdAt'] as String?;
    
    final imageUrl = post['imageUrl'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    final eventDetails = post['eventDetails'] as Map<String, dynamic>?;
    final startDateStr = eventDetails?['startDate'] as String?;
    final startTimeStr = eventDetails?['startTime'] as String?;

    String locationText = '';
    final loc = post['location'];
    if (loc is String) {
      locationText = loc;
    } else if (loc is Map) {
      locationText = [
        loc['campus'],
        loc['floor'],
        loc['roomNo'],
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    }

    final websiteLink = post['websiteLink'] as String?;
    final registrationLink = post['registrationLink'] as String?;
    final postId = post['_id'] ?? post['id'] ?? UniqueKey().toString();

    final typeColor = isEvent ? AuthPalette.deepTeal : AuthPalette.coral;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── Hero Image App Bar ──
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: 'image_$postId',
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isDark),
                      )
                    : _buildPlaceholder(isDark),
              ),
            ),
          ),

          // ── Post Content ──
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                        child: Text(
                          authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authorName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEvent ? 'Event' : 'News',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Detail Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty) ...[
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Body Text
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Event Specific Details
                        if (isEvent && (locationText.isNotEmpty || startDateStr != null || startTimeStr != null)) ...[
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          if (startDateStr != null) ...[
                            Row(
                              children: [
                                Icon(CupertinoIcons.calendar, color: typeColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _formatDate(startDateStr),
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          
                          if (startTimeStr != null) ...[
                            Row(
                              children: [
                                Icon(CupertinoIcons.time, color: typeColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    startTimeStr,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (locationText.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(CupertinoIcons.location_solid, color: typeColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    locationText,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ],
                    ),
                  ),

                  // Action Links
                  if ((websiteLink != null && websiteLink.isNotEmpty) || 
                      (registrationLink != null && registrationLink.isNotEmpty)) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (websiteLink != null && websiteLink.isNotEmpty)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _launchUrl(context, websiteLink),
                              icon: const Icon(CupertinoIcons.globe, size: 18),
                              label: const Text('Website'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                                foregroundColor: isDark ? Colors.white : Colors.black,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        if (websiteLink != null && websiteLink.isNotEmpty && 
                            registrationLink != null && registrationLink.isNotEmpty)
                          const SizedBox(width: 12),
                        if (registrationLink != null && registrationLink.isNotEmpty)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _launchUrl(context, registrationLink),
                              icon: const Icon(CupertinoIcons.ticket, size: 18),
                              label: const Text('Register'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: typeColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Bottom Padding for scrolling
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          size: 64,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }
}
