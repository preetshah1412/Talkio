import 'package:talkio/models/user.dart';
import 'package:talkio/models/chat.dart';

class Message {
  final String id;
  final String content;
  final User sender;
  // final Chat chat; // Avoid circular dependency issues if not strictly needed or handle carefully

  Message({required this.id, required this.content, required this.sender});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'],
      content: json['content'],
      sender: User.fromJson(json['sender']),
    );
  }
}
