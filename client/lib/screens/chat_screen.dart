import 'package:flutter/material.dart';
import 'package:talkio/services/nearby_service.dart';
import 'package:talkio/services/database_helper.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final NearbyService nearbyService;

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.nearbyService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();

    // Listen for incoming messages
    widget.nearbyService.onMessageReceived = (id, msg) {
      if (id == widget.peerId) {
        _saveAndDisplayMessage(msg, false);
      }
    };

    widget.nearbyService.onDisconnected = (id) {
      if (id == widget.peerId && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Peer Disconnected")));
        Navigator.pop(context);
      }
    };
  }

  Future<void> _loadMessages() async {
    // In a real app we'd need a consistent User ID for the peer, not just the random Endpoint ID.
    // Endpoint IDs change every connection.
    // For this prototype, messages are ephemeral to the session or we'd need to exchange real identity in a handshake.
    // Let's assume we want to store them by Peer Name for now, or just Session ID.
    // Storing by Endpoint ID means they persist only for this connection session if reconnected changes ID.
    // We'll store by Peer Name (User Name) which we assume is somewhat unique for now.
    final msgs = await _dbHelper.getMessages(widget.peerName);
    setState(() {
      _messages = msgs;
    });
  }

  Future<void> _saveAndDisplayMessage(String content, bool isMe) async {
    final msg = {
      'peerId': widget
          .peerName, // Using Name as ID for persistence across sessions (imperfect but better than endpointId)
      'senderName': isMe ? 'Me' : widget.peerName,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isMe': isMe ? 1 : 0,
    };

    await _dbHelper.insertMessage(msg);

    if (mounted) {
      setState(() {
        _messages.add(msg);
      });
    }
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    final content = _controller.text;
    _controller.clear();

    widget.nearbyService.sendBytesPayload(widget.peerId, content);
    _saveAndDisplayMessage(content, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'] == 1;
                return Container(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      msg['content'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
