import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthService {
  static const _tokenKey = 'auth_jwt_token';
  static const _userKey = 'auth_user_json';

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  String? _cachedToken;
  UserModel? _cachedUser;

  /// Check if the user has a saved valid token.
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Get the stored JWT token.
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  /// Get the stored user.
  Future<UserModel?> getUser() async {
    if (_cachedUser != null) return _cachedUser;
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    _cachedUser =
        UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    return _cachedUser;
  }

  /// Sign in with Google and authenticate with the backend.
  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw Exception('Failed to get Google ID token.');
    }

    // Send the ID token to the backend
    final baseUrl = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
        : ApiConstants.baseUrl;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'id_token': idToken}),
    );

    if (response.statusCode != 200) {
      throw Exception('Authentication failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    // Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_userKey, jsonEncode(userJson));
    _cachedToken = accessToken;
    _cachedUser = user;

    return user;
  }

  /// Sign out — clear local state and Google session.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _cachedToken = null;
    _cachedUser = null;
  }
}
