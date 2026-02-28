import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final postType = widget.post['postType'] as String? ?? 'news';
    final isEvent = postType == 'event';

    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isEvent
                              ? CupertinoColors.systemPurple.withValues(
                                  alpha: 0.2,
                                )
                              : CupertinoColors.systemBlue.withValues(
                                  alpha: 0.2,
                                ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isEvent ? 'EVENT' : 'NEWS',
                          style: TextStyle(
                            color: isEvent
                                ? CupertinoColors.systemPurple
                                : CupertinoColors.systemBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '@${widget.post['authorUsername'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        isExpanded
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        color: CupertinoColors.systemGrey,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.post['heading'] ?? '',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: isDark ? Colors.white12 : Colors.black12),
                    const SizedBox(height: 12),
                    Text(
                      widget.post['body'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? Colors.white12 : Colors.black12),
                    if (isEvent) ...[
                      const SizedBox(height: 16),
                      if (widget.post['location'] != null) ...[
                        _buildDetailRow(
                          icon: CupertinoIcons.location_solid,
                          label: 'Location',
                          value:
                              [
                                    widget.post['location']['campus'],
                                    widget.post['location']['floor'],
                                    widget.post['location']['roomNo'],
                                  ]
                                  .where(
                                    (e) => e != null && e.toString().isNotEmpty,
                                  )
                                  .join(', '),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (widget.post['eventDetails'] != null) ...[
                        _buildDetailRow(
                          icon: CupertinoIcons.calendar,
                          label: 'Date',
                          value:
                              widget.post['eventDetails']['isDateRange'] == true
                              ? '${_formatDate(widget.post['eventDetails']['startDate'])} - ${_formatDate(widget.post['eventDetails']['endDate'])}'
                              : _formatDate(
                                  widget.post['eventDetails']['startDate'],
                                ),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: CupertinoIcons.clock,
                          label: 'Time',
                          value:
                              widget.post['eventDetails']['isTimeRange'] == true
                              ? '${widget.post['eventDetails']['startTime']} - ${widget.post['eventDetails']['endTime']}'
                              : widget.post['eventDetails']['startTime'] ?? '',
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: CupertinoColors.activeBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
