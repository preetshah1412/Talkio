# Talkio 📶  
**Stay Connected. Anywhere. Anytime. No Internet Required.**

![Talkio Banner](https://via.placeholder.com/1200x300?text=Talkio+Offline+P2P+Messaging)

Talkio is a next-generation **Offline Peer-to-Peer (P2P) Messaging Application** built with Flutter. It enables seamless communication between devices using **Bluetooth and Wi-Fi Direct**, completely bypassing the need for cellular data, Wi-Fi routers, or the internet. 

Perfect for hiking, festivals, disasters, or anywhere connectivity is scarce.

---

## 🚀 Features

-   **📡 100% Offline**: Zero dependency on ISPs or servers.
-   **🔗 P2P Mesh Technology**: Powered by Google Nearby Connections API (Star/Cluster strategy).
-   **⚡ High-Speed Transfer**: Uses Wi-Fi Direct for high-bandwidth payloads (text, and future file support).
-   **🔒 Private & Local**: Messages are stored locally on your device (SQLite). Your data never leaves your proximity.
-   **📍 Proximity Discovery**: Automatically discover users within ~100 meters.

## 🛠️ Tech Stack

-   **Frontend**: Flutter (Dart)
-   **Networking**: `nearby_connections` (Android/iOS P2P API wrapper)
-   **Database**: `sqflite` (Local SQL storage)
-   **State Management**: `provider` (Legacy refactor) / `setState` (Current lightweight approach)

---

## 📱 Getting Started

### Prerequisites
*   **Hardware**: At least 2 Physical Android Devices (Emulators *do not* support Bluetooth/Wi-Fi P2P).
*   **OS**: Android 8.0+ recommended.

### Installation

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/yourusername/talkio.git
    cd talkio/client
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run on Device**
    Connect your Android phone via USB and run:
    ```bash
    flutter run
    ```

---

## 📖 User Guide

1.  **Set Identity**: Launch the app and enter a unique **Nickname**.
2.  **Discover**: 
    *   **Device A**: Toggle "Advertise" (Be Discoverable).
    *   **Device B**: Toggle "Discover" (Search for Users).
3.  **Connect**: Device B will see Device A in the list. Tap to connect.
4.  **Chat**: Accept the connection on both screens and start messaging!

---

## ⚠️ Important Notes

*   **Range**: The effective range is approximately **100 meters (300 ft)** line-of-sight. Walls and interference can reduce this.
*   **iOS Support**: Currently optimized for Android. iOS support requires additional plist configuration for Nearby Connections.

## 🤝 Contributing

Contributions are welcome! We are looking to implement:
- [ ] Multi-hop Mesh Networking (A -> B -> C) for longer range.
- [ ] Image/File Sharing.
- [ ] End-to-End Encryption.

---

*Built with ❤️ by the Talkio Team*
