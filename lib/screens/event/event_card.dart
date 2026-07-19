import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';

class EventCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onRefresh;

  const EventCard({super.key, required this.post, required this.onRefresh});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool isExpanded = false;

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

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
      return _formatDate(dateStr);
    } catch (e) {
      return '';
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final postType = widget.post['postType'] as String? ?? 'news';
    final isEvent = postType == 'event';
    final authorName = widget.post['authorUsername'] ?? 'Unknown';
    final body = widget.post['body'] ?? '';
    final createdAt = widget.post['createdAt'] as String?;
    final hasImage =
        widget.post['imageUrl'] != null &&
        (widget.post['imageUrl'] as String).isNotEmpty;

    String locationText = '';
    final loc = widget.post['location'];
    if (loc is String) {
      locationText = loc;
    } else if (loc is Map) {
      locationText = [
        loc['campus'],
        loc['floor'],
        loc['roomNo'],
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    }

    final websiteLink = widget.post['websiteLink'] as String?;
    final registrationLink = widget.post['registrationLink'] as String?;

    final hasLearnMore = (isEvent && widget.post['eventDetails'] != null) ||
        (isEvent && locationText.isNotEmpty) ||
        (websiteLink != null && websiteLink.isNotEmpty) ||
        (registrationLink != null && registrationLink.isNotEmpty);

    final typeColor = isEvent ? AuthPalette.deepTeal : AuthPalette.coral;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
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
          title: Text(
            authorName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            isEvent ? 'Event' : 'News',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: typeColor,
            ),
          ),
          trailing: createdAt != null
              ? Text(
                  _timeAgo(createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                )
              : null,
        ),

        // ── News Body (Edge-to-Edge Gradient Box) ──
        if (!isEvent && body.isNotEmpty)
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
                      : [const Color(0xFFF2F2F7), const Color(0xFFE5E5EA)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── News Links ──
        if (!isEvent && ((websiteLink != null && websiteLink.isNotEmpty) || (registrationLink != null && registrationLink.isNotEmpty)))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                if (websiteLink != null && websiteLink.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(websiteLink),
                      icon: const Icon(CupertinoIcons.link, size: 16),
                      label: const Text('Website'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (websiteLink != null && websiteLink.isNotEmpty && registrationLink != null && registrationLink.isNotEmpty)
                  const SizedBox(width: 12),
                if (registrationLink != null && registrationLink.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(registrationLink),
                      icon: const Icon(CupertinoIcons.link, size: 16),
                      label: const Text('Link'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuthPalette.coral,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),


        // ── Event Image ──
        if (isEvent && hasImage)
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(
              widget.post['imageUrl'],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                  child: const Center(child: CupertinoActivityIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                  child: Center(
                    child: Icon(CupertinoIcons.exclamationmark_triangle,
                        color: isDark ? Colors.white38 : Colors.black38),
                  ),
                );
              },
            ),
          ),

        // ── Event Body & Inline Details ──
        if (isEvent)
          GestureDetector(
            onTap: () {
              if (hasLearnMore) {
                setState(() {
                  isExpanded = !isExpanded;
                });
              }
            },
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Container(
                width: double.infinity,
                color: Colors.transparent, // Ensures the whole area is tappable
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (body.isNotEmpty) ...[
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (!isExpanded && hasLearnMore)
                      Text(
                        'Tap to view details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),

                    if (isExpanded && hasLearnMore) ...[
                      const SizedBox(height: 8),
                      // Location
                      if (locationText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.location_solid, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  locationText,
                                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Date & Time
                      if (widget.post['eventDetails'] != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.calendar, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.post['eventDetails']['isDateRange'] == true
                                      ? '${_formatDate(widget.post['eventDetails']['startDate'])} — ${_formatDate(widget.post['eventDetails']['endDate'])}'
                                      : _formatDate(widget.post['eventDetails']['startDate']),
                                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.clock, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.post['eventDetails']['isTimeRange'] == true
                                      ? '${widget.post['eventDetails']['startTime']} — ${widget.post['eventDetails']['endTime']}'
                                      : widget.post['eventDetails']['startTime'] ?? '',
                                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Links (URL Launcher Buttons)
                      if ((websiteLink != null && websiteLink.isNotEmpty) || (registrationLink != null && registrationLink.isNotEmpty))
                        Row(
                          children: [
                            if (websiteLink != null && websiteLink.isNotEmpty)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _launchUrl(websiteLink),
                                  icon: const Icon(CupertinoIcons.link, size: 16),
                                  label: const Text('Website'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                    foregroundColor: isDark ? Colors.white : Colors.black,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            if (websiteLink != null && websiteLink.isNotEmpty && registrationLink != null && registrationLink.isNotEmpty)
                              const SizedBox(width: 12),
                            if (registrationLink != null && registrationLink.isNotEmpty)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _launchUrl(registrationLink),
                                  icon: const Icon(CupertinoIcons.ticket, size: 16),
                                  label: const Text('Register'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AuthPalette.teal,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
