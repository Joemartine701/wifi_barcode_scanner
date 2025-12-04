# WiFi Barcode Scanner

[![pub package](https://img.shields.io/pub/v/wifi_barcode_scanner.svg)](https://pub.dev/packages/wifi_barcode_scanner)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Flutter package for wireless barcode scanning between devices over WiFi. Turn any phone into a barcode scanner for your POS, inventory, or warehouse application.

## ✨ Features

- 📱 Turn any phone into a wireless barcode scanner
- 🌐 Works over WiFi or mobile hotspot
- 🔌 No cables or Bluetooth required
- ⚡ Real-time barcode transmission
- 🔍 Built-in connection diagnostics
- ✅ Scan confirmation dialogs
- 🛠️ Easy integration

## 📦 Installation

Add to your `pubspec.yaml`:
```yaml
dependencies:
  wifi_barcode_scanner: ^1.0.0
```

Then run:
```bash
flutter pub get
```

## 🚀 Quick Start

### Receiver Device (Tablet/POS)
```dart
import 'package:wifi_barcode_scanner/wifi_barcode_scanner.dart';

final server = BarcodeHttpServer(
  onBarcodeReceived: (barcode) {
    print('Received: $barcode');
    // Process barcode in your app
  },
);

String? ip = await server.start();
print('Server IP: $ip:8080');
```

### Scanner Device (Phone)
```dart
import 'package:wifi_barcode_scanner/wifi_barcode_scanner.dart';

Scaffold(
  body: ScannerWidget(
    config: ScannerConfig(
      defaultIpAddress: '192.168.43.1', // or your receiver's IP
    ),
  ),
)
```