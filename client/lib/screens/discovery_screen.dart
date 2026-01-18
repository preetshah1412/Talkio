import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkio/services/nearby_service.dart';
import 'package:talkio/screens/chat_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final NearbyService _nearbyService = NearbyService();
  String _nickname = '';
  // List of discovered peers: endpointId -> endpointName
  final Map<String, String> _discoveredPeers = {};
  bool _isAdvertising = false;
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nickname = prefs.getString('nickname') ?? 'Unknown';
    });

    await _nearbyService.checkPermissions();

    // Setup callbacks
    _nearbyService.onEndpointFound = (id, name) {
      setState(() {
        _discoveredPeers[id] = name;
      });
    };

    _nearbyService.onEndpointLost = (id) {
      setState(() {
        _discoveredPeers.remove(id);
      });
    };

    _nearbyService.onConnectionInitiated = (id, name) {
      // Show dialog to accept connection
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Connection Request from $name"),
          content: const Text("Do you want to accept?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reject (Not implemented in service yet strictly, but can just ignore or add reject)
              },
              child: const Text("Reject"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _nearbyService.acceptConnection(id);
                if (mounted) {
                  // Navigate to chat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        peerId: id,
                        peerName: name,
                        nearbyService: _nearbyService,
                      ),
                    ),
                  );
                }
              },
              child: const Text("Accept"),
            ),
          ],
        ),
      );
    };

    _nearbyService.onConnectionResult = (id) {
      print("Connected to $id");
      // If we initiated, we might want to navigate here if we haven't already
      // But usually the one who taps "Connect" will wait for acceptance.
      // The navigation logic is simpler if we navigate on acceptance or let the user tap again.
      // For now, let's navigate if we are in Discovery screen.
      if (mounted && _discoveredPeers.containsKey(id)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              peerId: id,
              peerName: _discoveredPeers[id]!,
              nearbyService: _nearbyService,
            ),
          ),
        );
      }
    };
  }

  void _toggleAdvertising() async {
    setState(() {
      _isAdvertising = !_isAdvertising;
    });
    if (_isAdvertising) {
      await _nearbyService.startAdvertising(_nickname);
    } else {
      await _nearbyService.stopAdvertising();
    }
  }

  void _toggleDiscovery() async {
    setState(() {
      _isDiscovering = !_isDiscovering;
      _discoveredPeers.clear();
    });
    if (_isDiscovering) {
      await _nearbyService.startDiscovery(_nickname);
    } else {
      await _nearbyService.stopDiscovery();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Talkio: $_nickname'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('nickname');
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text("Be Discoverable (Advertise)"),
            subtitle: const Text("Allow others to find you"),
            value: _isAdvertising,
            onChanged: (val) => _toggleAdvertising(),
          ),
          SwitchListTile(
            title: const Text("Search for Users (Discover)"),
            subtitle: const Text("Find others nearby"),
            value: _isDiscovering,
            onChanged: (val) => _toggleDiscovery(),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Discovered Users:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _discoveredPeers.length,
              itemBuilder: (context, index) {
                String id = _discoveredPeers.keys.elementAt(index);
                String name = _discoveredPeers[id]!;
                return ListTile(
                  title: Text(name),
                  subtitle: const Text("Tap to connect"),
                  trailing: const Icon(Icons.bluetooth_searching),
                  onTap: () {
                    _nearbyService.requestConnection(id, name);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
