/// Configuration options for the WiFi barcode scanner.
class ScannerConfig {
  /// Server port (default: 8080)
  final int port;
  
  /// Connection timeout in seconds (default: 5)
  final int connectionTimeout;
  
  /// Scan timeout in seconds (default: 3)
  final int scanTimeout;
  
  /// Default IP address to pre-fill in the scanner
  final String? defaultIpAddress;
  
  /// Require manual confirmation after each scan (default: true)
  final bool requireScanConfirmation;
  
  /// Show diagnostic messages and network info (default: true)
  final bool showDiagnostics;

  const ScannerConfig({
    this.port = 8080,
    this.connectionTimeout = 5,
    this.scanTimeout = 3,
    this.defaultIpAddress,
    this.requireScanConfirmation = true,
    this.showDiagnostics = true,
  });

  ScannerConfig copyWith({
    int? port,
    int? connectionTimeout,
    int? scanTimeout,
    String? defaultIpAddress,
    bool? requireScanConfirmation,
    bool? showDiagnostics,
  }) {
    return ScannerConfig(
      port: port ?? this.port,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      scanTimeout: scanTimeout ?? this.scanTimeout,
      defaultIpAddress: defaultIpAddress ?? this.defaultIpAddress,
      requireScanConfirmation: requireScanConfirmation ?? this.requireScanConfirmation,
      showDiagnostics: showDiagnostics ?? this.showDiagnostics,
    );
  }
}