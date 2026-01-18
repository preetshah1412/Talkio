import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:talkio/services/api_service.dart'; // For baseUrl logic

class SocketService {
  late IO.Socket socket;

  void connect(String userId) {
    // baseUrl is http://10.0.2.2:5000/api -> needed http://10.0.2.2:5000
    String socketUrl = 'http://10.0.2.2:5000';

    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print('Connected to Socket Server');
      socket.emit('setup', {'_id': userId});
    });

    socket.on('connected', (_) {
      print('User setup complete');
    });
  }

  void joinChat(String chatId) {
    socket.emit('join chat', chatId);
  }

  void sendMessage(Map<String, dynamic> messageData) {
    socket.emit('new message', messageData);
  }

  void onMessageReceived(Function(dynamic) callback) {
    socket.on('message received', callback);
  }

  void disconnect() {
    socket.disconnect();
  }
}
