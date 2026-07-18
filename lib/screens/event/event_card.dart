import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class EventCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onRefresh;

  const EventCard({super.key, required this.post, required this.onRefresh});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
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
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
      return _formatDate(dateStr);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final postType = widget.post['postType'] as String? ?? 'news';
    final isEvent = postType == 'event';
    final authorName = widget.post['authorUsername'] ?? 'Unknown';
    final heading = widget.post['heading'] ?? '';
    final body = widget.post['body'] ?? '';
    final createdAt = widget.post['createdAt'] as String?;
    final hasImage =
        widget.post['imageUrl'] != null &&
        (widget.post['imageUrl'] as String).isNotEmpty;

    // Determine if there's expandable content
    final locationText = widget.post['location'] != null
        ? [
            widget.post['location']['campus'],
            widget.post['location']['floor'],
            widget.post['location']['roomNo'],
          ].where((e) => e != null && e.toString().isNotEmpty).join(', ')
        : '';
    final hasEventDetails = isEvent && widget.post['eventDetails'] != null;
    final hasExpandableContent =
        (hasImage && body.isNotEmpty) ||
        locationText.isNotEmpty ||
        hasEventDetails;

    final typeColor = isEvent ? AuthPalette.teal : AuthPalette.coral;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Instagram-style header: avatar + author + type badge + time ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                // Author avatar with gradient ring
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isEvent
                          ? [AuthPalette.teal, AuthPalette.deepTeal]
                          : [AuthPalette.blush, AuthPalette.coral],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: typeColor.withOpacity(0.15),
                      child: Text(
                        authorName.isNotEmpty
                            ? authorName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Author name + type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Icon(
                            isEvent ? CupertinoIcons.calendar : CupertinoIcons.news,
                            size: 12,
                            color: typeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isEvent ? 'Event' : 'News',
                            style: TextStyle(
                              fontFamily: 'Salena',
                              fontSize: 12,
                              color: typeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Time ago
                if (createdAt != null)
                  Text(
                    _timeAgo(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
          ),

          // ── Post image (if any) ──
          if (hasImage)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleExpanded,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    widget.post['imageUrl'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.04),
                        child: const Center(child: CupertinoActivityIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.04),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.photo,
                            size: 40,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // ── Content banner with gradient ──
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isEvent
                        ? [
                            AuthPalette.teal.withOpacity(isDark ? 0.4 : 0.15),
                            AuthPalette.deepTeal.withOpacity(isDark ? 0.5 : 0.2),
                          ]
                        : [
                            AuthPalette.blush.withOpacity(isDark ? 0.3 : 0.1),
                            AuthPalette.coral.withOpacity(isDark ? 0.4 : 0.15),
                          ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      heading,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    if (hasEventDetails) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(CupertinoIcons.calendar, size: 14, color: isDark ? AuthPalette.teal : AuthPalette.deepTeal),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.post['eventDetails']['isDateRange'] == true
                                  ? '${_formatDate(widget.post['eventDetails']['startDate'])} — ${_formatDate(widget.post['eventDetails']['endDate'])}'
                                  : _formatDate(widget.post['eventDetails']['startDate']),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AuthPalette.teal : AuthPalette.deepTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(CupertinoIcons.clock, size: 14, color: isDark ? AuthPalette.teal : AuthPalette.deepTeal),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.post['eventDetails']['isTimeRange'] == true
                                  ? '${widget.post['eventDetails']['startTime']} — ${widget.post['eventDetails']['endTime']}'
                                  : widget.post['eventDetails']['startTime'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AuthPalette.teal : AuthPalette.deepTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Show body below heading when there's no image
                    if (!hasImage && body.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        body,
                        maxLines: isExpanded ? null : 2,
                        overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Action row (only if there's expandable content) ──
          if (hasExpandableContent)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  // Expand / collapse
                  GestureDetector(
                    onTap: _toggleExpanded,
                    child: Row(
                      children: [
                        Icon(
                          isExpanded
                              ? CupertinoIcons.chevron_up
                              : CupertinoIcons.chevron_down,
                          size: 18,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isExpanded ? 'Less' : 'More',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

          // ── Expanded details ──
          if (hasExpandableContent)
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Body text only in collapse when image is present
                    if (hasImage && body.isNotEmpty) ...[
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? Colors.white : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (isEvent) ...[
                      const SizedBox(height: 8),
                      if (locationText.isNotEmpty)
                        _buildInfoChip(
                          icon: CupertinoIcons.location_solid,
                          text: locationText,
                          isDark: isDark,
                        ),
                      if (widget.post['eventDetails'] != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoChip(
                          icon: CupertinoIcons.calendar,
                          text:
                              widget.post['eventDetails']['isDateRange'] == true
                              ? '${_formatDate(widget.post['eventDetails']['startDate'])} — ${_formatDate(widget.post['eventDetails']['endDate'])}'
                              : _formatDate(
                                  widget.post['eventDetails']['startDate'],
                                ),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoChip(
                          icon: CupertinoIcons.clock,
                          text:
                              widget.post['eventDetails']['isTimeRange'] == true
                              ? '${widget.post['eventDetails']['startTime']} — ${widget.post['eventDetails']['endTime']}'
                              : widget.post['eventDetails']['startTime'] ?? '',
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AuthPalette.coral),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
