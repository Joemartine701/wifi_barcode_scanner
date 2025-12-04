import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_barcode_scanner/wifi_barcode_scanner.dart';

void main() {
  test('BarcodeHttpServer can be instantiated', () {
    final server = BarcodeHttpServer(
      onBarcodeReceived: (barcode) {},
    );
    expect(server, isNotNull);
  });

  test('ScannerConfig has correct defaults', () {
    const config = ScannerConfig();
    expect(config.port, 8080);
    expect(config.connectionTimeout, 5);
    expect(config.scanTimeout, 3);
    expect(config.requireScanConfirmation, true);
    expect(config.showDiagnostics, true);
  });

  test('ScannerConfig copyWith works correctly', () {
    const config = ScannerConfig(port: 8080);
    final modified = config.copyWith(port: 9090);
    
    expect(modified.port, 9090);
    expect(modified.connectionTimeout, 5); // unchanged
  });

  test('ScannerWidget can be instantiated', () {
    const widget = ScannerWidget();
    expect(widget, isNotNull);
    expect(widget.config.port, 8080);
  });
}