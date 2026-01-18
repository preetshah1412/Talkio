import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkio/models/user.dart';
import 'package:talkio/models/chat.dart';
import 'package:talkio/models/message.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost of the host machine.
  // Use http://localhost:5000 for iOS simulator or web.
  // For physical device, use your machine's local IP address.
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final user = User.fromJson(jsonResponse);
      await _saveToken(user.token);
      return user;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<User> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'pic':
            'https://icon-library.com/images/anonymous-avatar-icon/anonymous-avatar-icon-25.jpg', // Default
      }),
    );

    if (response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      final user = User.fromJson(jsonResponse);
      await _saveToken(user.token);
      return user;
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<List<Chat>> fetchChats(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Chat> chats = body
          .map((dynamic item) => Chat.fromJson(item))
          .toList();
      return chats;
    } else {
      throw Exception('Failed to load chats');
    }
  }

  Future<List<User>> searchUsers(String query, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user?search=$query'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<User> users = body
          .map((dynamic item) => User.fromJson(item))
          .toList();
      return users;
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<Chat> accessChat(String userId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"userId": userId}),
    );

    if (response.statusCode == 200) {
      return Chat.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to access chat');
    }
  }

  Future<List<Message>> fetchMessages(String chatId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/message/$chatId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Message.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  Future<Message> sendMessage(
    String content,
    String chatId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/message'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"content": content, "chatId": chatId}),
    );

    if (response.statusCode == 200) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send message');
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
