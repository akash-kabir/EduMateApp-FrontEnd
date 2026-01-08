class Config {
  static const String BASE_URL = "https://edu-mate-app-back-end.vercel.app";

  static const String registerEndpoint = "$BASE_URL/api/users/register";
  static const String loginEndpoint = "$BASE_URL/api/users/login";
  static const String profileEndpoint = "$BASE_URL/api/users/me";

  static const String postsEndpoint = "$BASE_URL/api/posts";
  static const String createPostEndpoint = "$BASE_URL/api/posts";
}
