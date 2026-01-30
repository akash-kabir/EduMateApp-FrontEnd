class Config {
  static const String BASE_URL = "https://edu-mate-app-back-end.vercel.app";

  // Auth endpoints
  static const String registerEndpoint = "$BASE_URL/api/users/register";
  static const String loginEndpoint = "$BASE_URL/api/users/login";

  // Profile endpoints
  static const String profileEndpoint = "$BASE_URL/api/users/me";
  static const String checkProfileStatusEndpoint =
      "$BASE_URL/api/users/profile-status";
  static const String updateProfileEndpoint = "$BASE_URL/api/users/profile";
  static const String getProfileDataEndpoint = "$BASE_URL/api/users/profile";

  // Posts endpoints
  static const String postsEndpoint = "$BASE_URL/api/posts";
  static const String createPostEndpoint = "$BASE_URL/api/posts";

  // Curriculum endpoints
  static const String curriculumUploadEndpoint =
      "$BASE_URL/api/curriculum/upload";
  static const String curriculumByBranchEndpoint =
      "$BASE_URL/api/curriculum/branch";
  static const String allCurriculumsEndpoint = "$BASE_URL/api/curriculum";

  // Schedule endpoints
  static const String scheduleUploadEndpoint = "$BASE_URL/api/schedule/upload";
  static const String scheduleByClassEndpoint = "$BASE_URL/api/schedule/class";
  static const String allSchedulesEndpoint = "$BASE_URL/api/schedule";
}
