import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String fullName;
  final String email;
  final String role;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;

  const ProfileCard({
    super.key,
    required this.fullName,
    required this.email,
    this.role = 'student',
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
  });

  Map<String, dynamic> _getRoleStyle() {
    switch (role.toLowerCase()) {
      case 'student':
        return {'color': const Color(0xFF34C759), 'label': 'Student'};
      case 'society_head':
        return {'color': const Color(0xFFAF52DE), 'label': 'Creator'};

      default:
        return {'color': const Color(0xFF34C759), 'label': 'Student'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleStyle = _getRoleStyle();
    final roleColor = roleStyle['color'] as Color;
    final roleLabel = roleStyle['label'] as String;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: backgroundColor,
                child: Icon(CupertinoIcons.person, color: iconColor, size: 36),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Email
                    Text(
                      email,
                      style: TextStyle(color: textColor, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Divider(color: textColor.withOpacity(0.3), thickness: 1),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: roleColor, width: 1),
            ),
            child: Text(
              roleLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: roleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
