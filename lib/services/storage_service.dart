import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = 'gh_token';
  static const _usersKey = 'gh_users';
  static const _jenkinsUserKey = 'jenkins_user';
  static const _jenkinsTokenKey = 'jenkins_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<List<String>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }

  static Future<void> setUsers(List<String> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  static Future<String?> getJenkinsUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_jenkinsUserKey);
  }

  static Future<void> setJenkinsUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_jenkinsUserKey, username);
  }

  static Future<String?> getJenkinsToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_jenkinsTokenKey);
  }

  static Future<void> setJenkinsToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_jenkinsTokenKey, token);
  }
}
