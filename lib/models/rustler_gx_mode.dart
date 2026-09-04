enum RustlerGxCapability {
  localBluetooth,
  hubClient,
  hubServer,
  dashboard,
  gps,
  media,
  remoteAccess,
}

extension RustlerGxCapabilityExtension on RustlerGxCapability {
  String get label {
    switch (this) {
      case RustlerGxCapability.localBluetooth:
        return 'Local Bluetooth';

      case RustlerGxCapability.hubClient:
        return 'Connect to Hub';

      case RustlerGxCapability.hubServer:
        return 'Act as Hub';

      case RustlerGxCapability.dashboard:
        return 'Dashboard';

      case RustlerGxCapability.gps:
        return 'GPS';

      case RustlerGxCapability.media:
        return 'Media';

      case RustlerGxCapability.remoteAccess:
        return 'Remote Access';
    }
  }

  String get description {
    switch (this) {
      case RustlerGxCapability.localBluetooth:
        return 'Scan and connect to nearby Bluetooth devices.';

      case RustlerGxCapability.hubClient:
        return 'Receive data from a RigOS Hub.';

      case RustlerGxCapability.hubServer:
        return 'Provide device data to other RigOS clients.';

      case RustlerGxCapability.dashboard:
        return 'Show the local RigOS dashboard.';

      case RustlerGxCapability.gps:
        return 'Use this device GPS and location hardware.';

      case RustlerGxCapability.media:
        return 'Enable media and head-unit features.';

      case RustlerGxCapability.remoteAccess:
        return 'Allow optional internet-based remote monitoring.';
    }
  }
}
