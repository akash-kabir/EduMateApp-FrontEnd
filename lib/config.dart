class Config {
  static const String BASE_URL = "https://edu-mate-app-back-end.vercel.app";

  // Auth endpoints
  static const String registerEndpoint = "$BASE_URL/api/users/register";
  static const String loginEndpoint = "$BASE_URL/api/users/login";
  static const String refreshEndpoint = "$BASE_URL/api/users/refresh";
  static const String forgotPasswordEndpoint = "$BASE_URL/api/users/forgot-password";
  static const String verifyOTPEndpoint = "$BASE_URL/api/users/verify-otp";
  static const String resetPasswordEndpoint = "$BASE_URL/api/users/reset-password";

  // Profile endpoints
  static const String profileEndpoint = "$BASE_URL/api/users/me";
  static const String checkProfileStatusEndpoint =
      "$BASE_URL/api/users/profile-status";
  static const String updateProfileEndpoint = "$BASE_URL/api/users/profile";
  static const String getProfileDataEndpoint = "$BASE_URL/api/users/profile";

  // Posts endpoints
  static const String postsEndpoint = "$BASE_URL/api/posts";
  static const String createPostEndpoint = "$BASE_URL/api/posts";

  // Admin endpoints
  static const String adminStatsEndpoint = "$BASE_URL/api/admin/stats";

  // Holiday endpoints
  static const String holidayBaseEndpoint = "$BASE_URL/api/holidays";

  // Upload endpoints
  static const String uploadSignatureEndpoint =
      "$BASE_URL/api/upload/signature";

  // Curriculum endpoints
  static const String curriculumBaseEndpoint = "$BASE_URL/api/curriculum";

  // Schedule endpoints
  static const String scheduleBaseEndpoint = "$BASE_URL/api/schedule";

  // Elective endpoints
  static const String electiveBaseEndpoint = "$BASE_URL/api/elective";
}
