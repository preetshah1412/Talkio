import 'package:talkio/models/user.dart';
import 'package:talkio/models/message.dart';

class Chat {
  final String id;
  final String chatName;
  final bool isGroupChat;
  final List<User> users;
  final Message? latestMessage;
  final User? groupAdmin;

  Chat({
    required this.id,
    required this.chatName,
    required this.isGroupChat,
    required this.users,
    this.latestMessage,
    this.groupAdmin,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['_id'],
      chatName: json['chatName'] ?? "Chat",
      isGroupChat: json['isGroupChat'] ?? false,
      users: (json['users'] as List).map((i) => User.fromJson(i)).toList(),
      latestMessage: json['latestMessage'] != null
          ? Message.fromJson(json['latestMessage'])
          : null,
      groupAdmin: json['groupAdmin'] != null
          ? User.fromJson(json['groupAdmin'])
          : null,
    );
  }
}
