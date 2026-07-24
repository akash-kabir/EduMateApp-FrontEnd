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
