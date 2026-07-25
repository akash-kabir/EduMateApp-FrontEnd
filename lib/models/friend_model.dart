class FriendModel {
  final String rollNo;
  final String nameTag;
  final String semester;
  final String section;
  final List<String> electives;

  FriendModel({
    required this.rollNo,
    required this.nameTag,
    required this.semester,
    required this.section,
    this.electives = const [],
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedElectives = [];
    if (json['electives'] is List) {
      parsedElectives = List<String>.from((json['electives'] as List).map((e) => e.toString()));
    }

    return FriendModel(
      rollNo: json['rollNo'] ?? '',
      nameTag: json['nameTag'] ?? '',
      semester: json['semester'] ?? '',
      section: json['section'] ?? '',
      electives: parsedElectives,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rollNo': rollNo,
      'nameTag': nameTag,
      'semester': semester,
      'section': section,
      'electives': electives,
    };
  }
}
