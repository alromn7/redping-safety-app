/// Transport types for multi-channel message delivery
enum TransportType {
  internet, // HTTPS/WebSocket/Firestore
  bluetooth, // BLE Mesh
  wifiDirect, // WiFi Direct P2P
  satellite, // Satellite IoT (future)
  localStore, // Store & forward
}

/// Transport hint for message routing preference
enum TransportHint {
  auto, // Let system decide
  preferInternet,
  preferMesh,
  forceOffline,
}

/// Transport availability status
class TransportStatus {
  final bool internet;
  final bool bluetooth;
  final bool wifiDirect;
  final bool satellite;
  final bool hasOutboxMessages;
  final TransportType? activeTransport;

  const TransportStatus({
    this.internet = false,
    this.bluetooth = false,
    this.wifiDirect = false,
    this.satellite = false,
    this.hasOutboxMessages = false,
    this.activeTransport,
  });

  bool get hasAnyTransport => internet || bluetooth || wifiDirect || satellite;

  bool get isOnlineCapable => internet || satellite;

  TransportStatus copyWith({
    bool? internet,
    bool? bluetooth,
    bool? wifiDirect,
    bool? satellite,
    bool? hasOutboxMessages,
    TransportType? activeTransport,
  }) {
    return TransportStatus(
      internet: internet ?? this.internet,
      bluetooth: bluetooth ?? this.bluetooth,
      wifiDirect: wifiDirect ?? this.wifiDirect,
      satellite: satellite ?? this.satellite,
      hasOutboxMessages: hasOutboxMessages ?? this.hasOutboxMessages,
      activeTransport: activeTransport ?? this.activeTransport,
    );
  }
}

extension TransportTypeExtension on TransportType {
  String get displayName {
    switch (this) {
      case TransportType.internet:
        return 'Internet';
      case TransportType.bluetooth:
        return 'Bluetooth Mesh';
      case TransportType.wifiDirect:
        return 'WiFi Direct';
      case TransportType.satellite:
        return 'Satellite';
      case TransportType.localStore:
        return 'Offline Queue';
    }
  }

  String get icon {
    switch (this) {
      case TransportType.internet:
        return '🌐';
      case TransportType.bluetooth:
        return '📡';
      case TransportType.wifiDirect:
        return '📶';
      case TransportType.satellite:
        return '🛰️';
      case TransportType.localStore:
        return '💾';
    }
  }
}
