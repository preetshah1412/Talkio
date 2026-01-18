import 'dart:typed_data';
import 'dart:convert';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyService {
  final Strategy strategy =
      Strategy.P2P_CLUSTER; // Can use P2P_STAR or P2P_POINT_TO_POINT
  String? userName;

  // Map to store connected endpoints: endpointId -> endpointName
  Map<String, String> connectedEndpoints = {};

  // Callbacks
  Function(String endpointId, String endpointName)? onConnectionInitiated;
  Function(String endpointId)? onConnectionResult;
  Function(String endpointId)? onDisconnected;
  Function(String endpointId, String message)? onMessageReceived;
  Function(String endpointId, String endpointName)? onEndpointFound;
  Function(String endpointId)? onEndpointLost;

  Future<bool> checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.storage, // For files if needed
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> startAdvertising(String userNickName) async {
    userName = userNickName;
    try {
      bool a = await Nearby().startAdvertising(
        userNickName,
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          if (onConnectionInitiated != null) {
            onConnectionInitiated!(id, info.endpointName);
          }
        },
        onConnectionResult: (String id, Status status) {
          if (status == Status.CONNECTED) {
            // success
            if (onConnectionResult != null) onConnectionResult!(id);
          } else {
            // failure
            print("Connection failed: $status");
          }
        },
        onDisconnected: (String id) {
          connectedEndpoints.remove(id);
          if (onDisconnected != null) onDisconnected!(id);
        },
      );
      print("ADVERTISING: $a");
    } catch (exception) {
      print(exception);
    }
  }

  Future<void> startDiscovery(String userNickName) async {
    userName = userNickName;
    try {
      bool a = await Nearby().startDiscovery(
        userNickName,
        strategy,
        onEndpointFound: (String id, String name, String serviceId) {
          if (onEndpointFound != null) onEndpointFound!(id, name);
        },
        onEndpointLost: (String id) {
          if (onEndpointLost != null) onEndpointLost!(id);
        },
      );
      print("DISCOVERY: $a");
    } catch (e) {
      print(e);
    }
  }

  Future<void> stopAdvertising() async {
    await Nearby().stopAdvertising();
  }

  Future<void> stopDiscovery() async {
    await Nearby().stopDiscovery();
  }

  Future<void> requestConnection(String endpointId, String name) async {
    try {
      await Nearby().requestConnection(
        userName!,
        endpointId,
        onConnectionInitiated: (id, info) {
          if (onConnectionInitiated != null) {
            onConnectionInitiated!(id, info.endpointName);
          }
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            if (onConnectionResult != null) onConnectionResult!(id);
          }
        },
        onDisconnected: (id) {
          connectedEndpoints.remove(id);
          if (onDisconnected != null) onDisconnected!(id);
        },
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> acceptConnection(String endpointId) async {
    await Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (endId, payload) {
        if (payload.type == PayloadType.BYTES) {
          String str = String.fromCharCodes(payload.bytes!);
          if (onMessageReceived != null) onMessageReceived!(endId, str);
        }
      },
      onPayloadTransferUpdate: (endId, payloadTransferUpdate) {
        // Handle progress
      },
    );
  }

  Future<void> sendBytesPayload(String endpointId, String msg) async {
    var payload = Payload.forBytes(Uint8List.fromList(msg.codeUnits));
    await Nearby().sendPayload(payload, endpointId);
  }
}
