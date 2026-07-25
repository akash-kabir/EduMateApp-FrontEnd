import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/friend_model.dart';
class FriendsStorageService {
  static const String _key = 'friends_list';

  /// Get the list of saved friends
  static Future<List<FriendModel>> getFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final String? friendsJson = prefs.getString(_key);
    if (friendsJson == null || friendsJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(friendsJson);
      return decoded.map((e) => FriendModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a friend to the list (max 10)
  static Future<bool> addFriend(FriendModel friend) async {
    final friends = await getFriends();
    
    // Check limit
    if (friends.length >= 10) return false;
    
    // Check duplicate rollNo
    if (friends.any((f) => f.rollNo.toUpperCase() == friend.rollNo.toUpperCase())) {
      return false; // Already exists
    }

    friends.add(friend);
    await _saveFriends(friends);
    return true;
  }

  /// Remove a friend by rollNo
  static Future<void> removeFriend(String rollNo) async {
    final friends = await getFriends();
    friends.removeWhere((f) => f.rollNo.toUpperCase() == rollNo.toUpperCase());
    await _saveFriends(friends);
  }

  /// Internal save method
  static Future<void> _saveFriends(List<FriendModel> friends) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(friends.map((f) => f.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
