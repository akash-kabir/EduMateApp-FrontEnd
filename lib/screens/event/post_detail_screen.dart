import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';
import '../../models/poi_model.dart';
import '../../services/poi_service.dart';
import '../../services/map_navigation_store.dart';

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

  Future<void> _handleLocate(
    BuildContext context,
    String locationText,
    String? poiId,
    String? poiName,
    double? poiLat,
    double? poiLng,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(CupertinoIcons.compass, color: Color(0xFFFF9B7A)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'View Location',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Would you like to view $locationText on the campus map?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9B7A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('View Location'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show Loading Transition Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 14),
              const SizedBox(height: 16),
              Text(
                'Opening Campus Map...',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Resolve POI with rich backend data (description, image, address)
    PoiModel targetPoi = PoiModel(
      id: poiId ?? 'custom_loc',
      name: poiName ?? locationText,
      lat: poiLat ?? 20.2961,
      lng: poiLng ?? 85.8245,
      address: locationText,
    );

    try {
      final pois = await PoiService.getPOIs();
      final match = pois.firstWhere(
        (p) => (poiId != null && p.id == poiId) ||
               (poiName != null && p.name.trim().toLowerCase() == poiName.trim().toLowerCase()) ||
               p.name.trim().toLowerCase().contains(locationText.trim().toLowerCase()) ||
               locationText.trim().toLowerCase().contains(p.name.trim().toLowerCase()),
        orElse: () => targetPoi,
      );
      targetPoi = match;
    } catch (_) {}

    // Trigger tab switch and POI navigation
    MapNavigationStore.instance.navigateToPoi(targetPoi);

    // Wait a brief moment to let loading overlay mask tab switch, then pop dialog and post detail screen
    await Future.delayed(const Duration(milliseconds: 600));
    if (context.mounted) {
      // Pop loading dialog
      Navigator.of(context).pop();
    }
    if (context.mounted) {
      // Pop PostDetailScreen
      Navigator.of(context).pop();
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
    final endDateStr = eventDetails?['endDate'] as String?;
    final startTimeStr = eventDetails?['startTime'] as String?;
    final endTimeStr = eventDetails?['endTime'] as String?;
    final isDateRange = eventDetails?['isDateRange'] == true;
    final isTimeRange = eventDetails?['isTimeRange'] == true;

    String dateDisplay = '';
    if (startDateStr != null) {
      dateDisplay = _formatDate(startDateStr);
      if (isDateRange && endDateStr != null && endDateStr.isNotEmpty) {
        dateDisplay += ' - ${_formatDate(endDateStr)}';
      }
    }

    String timeDisplay = '';
    if (startTimeStr != null) {
      timeDisplay = startTimeStr;
      if (isTimeRange && endTimeStr != null && endTimeStr.isNotEmpty) {
        timeDisplay += ' - $endTimeStr';
      }
    }

    String locationText = '';
    String? poiId;
    String? poiName;
    double? poiLat;
    double? poiLng;

    final loc = post['location'];
    if (loc is String) {
      locationText = loc;
    } else if (loc is Map) {
      locationText = [
        loc['campus'],
        loc['floor'],
        loc['roomNo'],
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
      
      poiId = loc['poiId'] as String?;
      poiName = loc['poiName'] as String?;
      if (loc['poiLat'] != null) poiLat = (loc['poiLat'] as num).toDouble();
      if (loc['poiLng'] != null) poiLng = (loc['poiLng'] as num).toDouble();
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
            expandedHeight: 400,
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
                        alignment: Alignment.topCenter,
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
                        if (isEvent && (locationText.isNotEmpty || dateDisplay.isNotEmpty || timeDisplay.isNotEmpty)) ...[
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          if (dateDisplay.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(CupertinoIcons.calendar, color: typeColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    dateDisplay,
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
                          
                          if (timeDisplay.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(CupertinoIcons.time, color: typeColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    timeDisplay,
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
                            // Locate Button (Only if Navigation Target is Active)
                            if (poiId != null || (poiLat != null && poiLng != null) || (poiName != null && poiName.isNotEmpty)) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _handleLocate(context, locationText, poiId, poiName, poiLat, poiLng),
                                  icon: const Icon(CupertinoIcons.compass_fill, size: 18),
                                  label: const Text('Locate on Map', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: typeColor,
                                    side: BorderSide(color: typeColor.withValues(alpha: 0.5)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
