class MeshMessage {
  final String id;
  final String sender;
  final String content;
  final int timestamp;
  final int hops;

  MeshMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.hops = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'content': content,
      'timestamp': timestamp,
      'hops': hops,
    };
  }

  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      id: json['id'],
      sender: json['sender'],
      content: json['content'],
      timestamp: json['timestamp'],
      hops: json['hops'] ?? 0,
    );
  }
}
