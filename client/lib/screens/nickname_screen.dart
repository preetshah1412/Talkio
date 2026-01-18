import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final _nicknameController = TextEditingController();

  Future<void> _saveNickname() async {
    if (_nicknameController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nickname', _nicknameController.text);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/discovery');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('nickname');
    if (name != null && name.isNotEmpty && mounted) {
      Navigator.pushReplacementNamed(context, '/discovery');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Talkio Offline')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Enter a nickname to be visible to others nearby"),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(labelText: 'Nickname'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveNickname,
              child: const Text('Start Messaging'),
            ),
          ],
        ),
      ),
    );
  }
}
