class AttendanceRecord {
  final int? id;
  final String subject;
  final int totalClasses;
  final int presentClasses;
  final String semesterId;
  final DateTime lastSyncedAt;
  final String? facultyName;

  AttendanceRecord({
    this.id,
    required this.subject,
    required this.totalClasses,
    required this.presentClasses,
    required this.semesterId,
    required this.lastSyncedAt,
    this.facultyName,
  });

  double get percentage => totalClasses == 0 ? 0.0 : (presentClasses / totalClasses) * 100;

  double simulateAttendNext() {
    return ((presentClasses + 1) / (totalClasses + 1)) * 100;
  }

  double simulateSkipNext() {
    return (presentClasses / (totalClasses + 1)) * 100;
  }

  int classesNeededToReach(double threshold) {
    if (percentage >= threshold) return 0;
    if (threshold >= 100) return 999;
    final num = (threshold * totalClasses) - (100 * presentClasses);
    final den = 100 - threshold;
    final needed = (num / den).ceil();
    return needed < 0 ? 0 : needed;
  }

  int classesAllowedToSkip(double threshold) {
    if (percentage < threshold || threshold <= 0) return 0;
    final maxTotal = (100 * presentClasses) / threshold;
    final allowed = (maxTotal - totalClasses).floor();
    return allowed < 0 ? 0 : allowed;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'totalClasses': totalClasses,
      'presentClasses': presentClasses,
      'semesterId': semesterId,
      'lastSyncedAt': lastSyncedAt.toIso8601String(),
      'facultyName': facultyName,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      subject: map['subject'],
      totalClasses: map['totalClasses'],
      presentClasses: map['presentClasses'],
      semesterId: map['semesterId'],
      lastSyncedAt: DateTime.parse(map['lastSyncedAt']),
      facultyName: map['facultyName'],
    );
  }
}

class SemesterOption {
  final String id;
  final String title;

  SemesterOption({required this.id, required this.title});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemesterOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
