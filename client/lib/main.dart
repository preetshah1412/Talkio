import 'package:flutter/material.dart';
import 'package:talkio/screens/nickname_screen.dart';
import 'package:talkio/screens/discovery_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talkio Offline',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const NicknameScreen(),
        '/discovery': (context) => const DiscoveryScreen(),
      },
    );
  }
}
