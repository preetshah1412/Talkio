import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talkio/models/chat.dart';
import 'package:talkio/models/user.dart';
import 'package:talkio/providers/user_provider.dart';
import 'package:talkio/services/api_service.dart';
import 'package:talkio/services/socket_service.dart';
import 'package:talkio/screens/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  late SocketService _socketService;
  List<Chat> _chats = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _socketService = SocketService();
    _fetchChats();
    // Initialize socket
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      _socketService.connect(user.id);
    }
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  Future<void> _fetchChats() async {
    setState(() => _isLoading = true);
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      try {
        final chats = await _apiService.fetchChats(user.token);
        setState(() => _chats = chats);
      } catch (e) {
        // Handle error
        print(e);
      }
    }
    setState(() => _isLoading = false);
  }

  void _showSearch() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      showSearch(
        context: context,
        delegate: UserSearchDelegate(_apiService, user.token),
      );
    }
  }

  String _getChatName(Chat chat, User currentUser) {
    if (chat.isGroupChat) return chat.chatName;
    // For one-on-one, find the other user
    final otherUser = chat.users.firstWhere(
      (u) => u.id != currentUser.id,
      orElse: () =>
          User(id: '', username: 'Unknown', email: '', pic: '', token: ''),
    );
    return otherUser.username;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Talkio'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _showSearch),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchChats,
              child: ListView.builder(
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  return ListTile(
                    leading: CircleAvatar(
                      // Simple logic for avatar, can be improved
                      child: Text(
                        _getChatName(
                          chat,
                          currentUser!,
                        ).substring(0, 1).toUpperCase(),
                      ),
                    ),
                    title: Text(_getChatName(chat, currentUser)),
                    subtitle: chat.latestMessage != null
                        ? Text(
                            "${chat.latestMessage!.sender.username}: ${chat.latestMessage!.content}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const Text("No messages yet"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chat: chat,
                            socketService: _socketService,
                          ),
                        ),
                      ).then((_) => _fetchChats());
                    },
                  );
                },
              ),
            ),
    );
  }
}

class UserSearchDelegate extends SearchDelegate<User?> {
  final ApiService apiService;
  final String token;

  UserSearchDelegate(this.apiService, this.token);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
      future: _search(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        final users = snapshot.data as List<User>;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.username),
              subtitle: Text(user.email),
              onTap: () async {
                close(context, user); // Return selected user
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => Container();

  Future<List<User>> _search() async {
    if (query.isEmpty) return [];
    try {
      return await apiService.searchUsers(query, token);
    } catch (e) {
      print(e); // For debugging
      return [];
    }
  }
}
