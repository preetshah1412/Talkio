import 'package:flutter/material.dart';
import 'package:talkio/services/nearby_service.dart';
import 'package:talkio/services/database_helper.dart';
import 'package:talkio/models/mesh_message.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

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
  final Set<String> _processedMessageIds =
      {}; // Deduplication cache (In-memory for now)

  @override
  void initState() {
    super.initState();
    _loadMessages();

    // Listen for incoming messages
    widget.nearbyService.onMessageReceived = (id, msgStr) async {
      try {
        // Attempt to parse as MeshMessage (JSON)
        final Map<String, dynamic> data = jsonDecode(msgStr);
        final meshMsg = MeshMessage.fromJson(data);
        _handleIncomingMeshMessage(meshMsg);
      } catch (e) {
        // Fallback for legacy plain text messages
        // We can treat them as direct messages
        print("Received non-JSON message: $msgStr ($e)");
      }
    };

    widget.nearbyService.onDisconnected = (id) {
      // Only pop if it's the direct peer we are talking to, but in Mesh, we might talk via relays.
      // For this simple UI, we assume direct connection is primary target.
      if (id == widget.peerId && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Direct Peer Disconnected - Mesh may still work"),
          ),
        );
        // Don't pop automatically in Mesh mode, as we might route via others.
      }
    };
  }

  void _handleIncomingMeshMessage(MeshMessage msg) {
    // 1. Deduplication Check
    if (_processedMessageIds.contains(msg.id)) {
      return; // Already processed/relayed
    }
    _processedMessageIds.add(msg.id);

    // 2. Display Message
    _saveAndDisplayMessage(msg, false);

    // 3. Relay (Flood)
    // Broadcast to everyone else (except me, which is implied by receive).
    // Update hops count logic could go here.
    final relayedMsg = MeshMessage(
      id: msg.id,
      sender: msg.sender,
      content: msg.content,
      timestamp: msg.timestamp,
      hops: msg.hops + 1,
    );

    widget.nearbyService.broadcastPayload(jsonEncode(relayedMsg.toJson()));
  }

  Future<void> _loadMessages() async {
    // For mesh, loading by peerName is tricky because sender varies.
    // We should load all messages where relevant.
    // For this prototype, just load messages associated with this "Chat Room" context if we had one.
    // Since we don't have rooms, let's load everything or just specifically for this peer if sender matches.
    // Simplification: Load messages where sender is the peerName or Me.
    final msgs = await _dbHelper.getMessages(widget.peerName);
    setState(() {
      _messages = msgs;
    });
  }

  Future<void> _saveAndDisplayMessage(MeshMessage msg, bool isMe) async {
    // Store in DB
    final row = {
      'peerId': isMe
          ? widget.peerName
          : msg.sender, // Who it's associated with in UI
      'senderName': msg.sender,
      'content': msg.content,
      'timestamp': msg.timestamp,
      'isMe': isMe ? 1 : 0,
    };

    await _dbHelper.insertMessage(row);

    if (mounted) {
      setState(() {
        // Naive list update: check if it's relevant to current view
        // If we are looking at "Alice", and "Bob" sends a message via mesh, should it show here?
        // Ideally we need a "Global Chat" or specific rooms.
        // For now: Just show it if logic matches or simply append.
        _messages.add(row);
      });
    }
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    final content = _controller.text;
    _controller.clear();

    final myNickname = widget.nearbyService.userName ?? 'Me';

    final newMsg = MeshMessage(
      id: const Uuid().v4(),
      sender: myNickname,
      content: content,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    // Cache own ID
    _processedMessageIds.add(newMsg.id);

    // Broadcast to Mesh (Flooding)
    widget.nearbyService.broadcastPayload(jsonEncode(newMsg.toJson()));

    _saveAndDisplayMessage(newMsg, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat: ${widget.peerName} (Mesh)")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'] == 1;
                final sender = msg['senderName'];
                return Container(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Text(
                          sender,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      Container(
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
                    ],
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
