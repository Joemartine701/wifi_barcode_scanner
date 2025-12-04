# Complete WiFi Barcode Scanner Package Setup Script
Write-Host "========================================" -ForegroundColor Green
Write-Host "WiFi Barcode Scanner Package Setup" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Create directories
Write-Host "Creating directory structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "lib\src\models" | Out-Null
New-Item -ItemType Directory -Force -Path "example\lib" | Out-Null
New-Item -ItemType Directory -Force -Path "test" | Out-Null
Write-Host "✓ Directories created" -ForegroundColor Cyan

# File 1: Main export file
Write-Host "Creating lib\wifi_barcode_scanner.dart..." -ForegroundColor Yellow
$mainExport = @'
/// WiFi Barcode Scanner
/// 
/// A Flutter package for wireless barcode scanning between devices over WiFi.
/// Perfect for POS systems, inventory management, and warehouse operations.
library wifi_barcode_scanner;

export 'src/barcode_server.dart';
export 'src/scanner_widget.dart';
export 'src/models/scanner_config.dart';
'@
Set-Content -Path "lib\wifi_barcode_scanner.dart" -Value $mainExport -Encoding UTF8
Write-Host "✓ Created lib\wifi_barcode_scanner.dart" -ForegroundColor Cyan

# File 2: Scanner Config
Write-Host "Creating lib\src\models\scanner_config.dart..." -ForegroundColor Yellow
$scannerConfig = @'
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
'@
Set-Content -Path "lib\src\models\scanner_config.dart" -Value $scannerConfig -Encoding UTF8
Write-Host "✓ Created lib\src\models\scanner_config.dart" -ForegroundColor Cyan

# File 3: Barcode Server (with documentation)
Write-Host "Creating lib\src\barcode_server.dart..." -ForegroundColor Yellow
$barcodeServer = @'
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// HTTP server that receives barcodes from scanner devices over WiFi.
/// 
/// Creates an HTTP server on port 8080 that listens for barcode scans
/// from remote devices on the same network.
/// 
/// Example:
/// ```dart
/// final server = BarcodeHttpServer(
///   onBarcodeReceived: (barcode) {
///     print('Received barcode: $barcode');
///   },
/// );
/// 
/// String? ip = await server.start();
/// print('Server running at: http://$ip:8080');
/// 
/// server.stop();
/// ```
class BarcodeHttpServer {
  HttpServer? _server;
  final Function(String) onBarcodeReceived;
  
  BarcodeHttpServer({required this.onBarcodeReceived});
  
  Future<String?> start() async {
    var handler = const Pipeline().addHandler((Request request) async {
      var headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      };
      
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      
      if (request.url.path == 'scan') {
        String? barcode = request.url.queryParameters['code'];
        if (barcode != null && barcode.isNotEmpty) {
          onBarcodeReceived(barcode);
          return Response.ok('Barcode received: $barcode', headers: headers);
        }
        return Response.badRequest(body: 'No barcode provided', headers: headers);
      }
      
      return Response.ok(
        'Barcode Server is running!\nUse: /scan?code=YOUR_BARCODE',
        headers: headers
      );
    });
    
    try {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
      
      List<String> ipAddresses = await _getAllLocalIPs();
      
      print('📱 Barcode server started on:');
      for (var ip in ipAddresses) {
        print('   http://$ip:8080');
      }
      
      String? bestIP = ipAddresses.firstWhere(
        (ip) => !ip.startsWith('172.') && !ip.startsWith('127.'),
        orElse: () => ipAddresses.isNotEmpty ? ipAddresses.first : 'unknown'
      );
      
      return bestIP;
    } catch (e) {
      print('❌ Failed to start barcode server: $e');
      return null;
    }
  }
  
  Future<List<String>> _getAllLocalIPs() async {
    List<String> ips = [];
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        print('🔍 Network interface: ${interface.name}');
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            print('   IP: ${addr.address}');
            ips.add(addr.address);
          }
        }
      }
    } catch (e) {
      print('❌ Error getting IPs: $e');
    }
    return ips;
  }
  
  void stop() {
    _server?.close(force: true);
    _server = null;
    print('📱 Barcode server stopped');
  }
}
'@
Set-Content -Path "lib\src\barcode_server.dart" -Value $barcodeServer -Encoding UTF8
Write-Host "✓ Created lib\src\barcode_server.dart" -ForegroundColor Cyan

# File 4: Scanner Widget (complete with config support)
Write-Host "Creating lib\src\scanner_widget.dart..." -ForegroundColor Yellow
$scannerWidget = @'
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'models/scanner_config.dart';

/// A complete barcode scanner widget with camera and WiFi transmission.
class ScannerWidget extends StatefulWidget {
  final ScannerConfig config;

  const ScannerWidget({
    super.key,
    this.config = const ScannerConfig(),
  });

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget> {
  late final TextEditingController _ipController;
  bool _isConnected = false;
  String _diagnosticMessage = '';
  bool _isScanningEnabled = true;
  String? _lastScannedCode;
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(
      text: widget.config.defaultIpAddress ?? '192.168.1.100',
    );
    _loadSavedIP();
    _checkNetworkInfo();
  }

  Future<void> _checkNetworkInfo() async {
    if (!widget.config.showDiagnostics) return;

    try {
      final interfaces = await NetworkInterface.list();
      String myIP = 'Unknown';

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            myIP = addr.address;
            break;
          }
        }
        if (myIP != 'Unknown') break;
      }

      setState(() {
        _diagnosticMessage = 'Scanner Phone IP: $myIP';
      });
    } catch (e) {
      setState(() {
        _diagnosticMessage = 'Could not determine IP';
      });
    }
  }

  Future<void> _loadSavedIP() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIP = prefs.getString('wifi_barcode_scanner_ip');
    if (savedIP != null) {
      _ipController.text = savedIP;
    }
  }

  Future<void> _saveIP() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wifi_barcode_scanner_ip', _ipController.text);
  }

  Future<void> _testConnection() async {
    setState(() {
      _diagnosticMessage = 'Testing connection...';
    });

    try {
      final url = 'http://${_ipController.text}:${widget.config.port}';
      debugPrint("🔍 Trying to connect to: $url");

      final response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: widget.config.connectionTimeout),
      );

      debugPrint("📡 Response status: ${response.statusCode}");
      debugPrint("📡 Response body: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          _isConnected = true;
          _diagnosticMessage = '✅ Connected successfully!';
        });
        _saveIP();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Connected to receiver!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on SocketException catch (e) {
      debugPrint("❌ Socket error: $e");
      setState(() {
        _isConnected = false;
        _diagnosticMessage = '❌ Cannot reach receiver.\n\n'
            'Possible issues:\n'
            '• Devices not on same WiFi\n'
            '• Router blocking device communication\n'
            '• Wrong IP address\n\n'
            'Try using mobile hotspot instead!';
      });

      if (mounted) {
        _showNetworkHelp();
      }
    } catch (e) {
      debugPrint("❌ Connection error: $e");
      setState(() {
        _isConnected = false;
        _diagnosticMessage = '❌ Connection failed: $e';
      });
    }
  }

  void _showNetworkHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Failed'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cannot connect to receiver. Try these solutions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                '1. Mobile Hotspot (Easiest)',
                '• Enable hotspot on receiver device\n'
                '• Connect scanner phone to hotspot\n'
                '• The receiver IP will be: 192.168.43.1',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                '2. Same WiFi Network',
                '• Ensure both devices on same WiFi\n'
                '• Not one on WiFi and one on mobile data',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                '3. Disable Router Isolation',
                '• Access router settings\n'
                '• Disable "AP Isolation" or "Client Isolation"',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _ipController.text = '192.168.43.1';
              });
              _testConnection();
            },
            child: const Text('Try Hotspot IP'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _sendBarcode(String code) async {
    if (!_isScanningEnabled) return;

    setState(() {
      _isScanningEnabled = false;
      _lastScannedCode = code;
    });

    try {
      final url = 'http://${_ipController.text}:${widget.config.port}/scan?code=$code';
      debugPrint("📤 Sending barcode to: $url");

      final response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: widget.config.scanTimeout),
      );

      debugPrint("📥 Response: ${response.statusCode} - ${response.body}");

      if (mounted) {
        if (widget.config.requireScanConfirmation) {
          _showScanConfirmation(code, true);
        } else {
          setState(() {
            _isScanningEnabled = true;
            _lastScannedCode = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Sent: $code'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Send error: $e");
      setState(() => _isConnected = false);
      if (mounted) {
        _showScanConfirmation(code, false, error: e.toString());
      }
    }
  }

  void _showScanConfirmation(String code, bool success, {String? error}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(success ? 'Scan Successful' : 'Scan Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Barcode: $code',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (!success && error != null) ...[
              const SizedBox(height: 12),
              Text(
                'Error: $error',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!success)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendBarcode(code);
              },
              child: const Text('Retry'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isScanningEnabled = true;
                _lastScannedCode = null;
              });
            },
            child: const Text('Scan Next'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        backgroundColor: Colors.blue,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Icon(
                _isConnected ? Icons.wifi : Icons.wifi_off,
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ipController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Receiver IP Address',
                            border: const OutlineInputBorder(),
                            hintText: '192.168.1.100',
                            prefixIcon: Icon(
                              _isConnected ? Icons.check_circle : Icons.error,
                              color: _isConnected ? Colors.green : Colors.grey,
                            ),
                          ),
                          onChanged: (_) => setState(() => _isConnected = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _testConnection,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                        ),
                        child: const Text('Test'),
                      ),
                    ],
                  ),
                  if (_diagnosticMessage.isNotEmpty && widget.config.showDiagnostics) ...[
                    const SizedBox(height: 12),
                    Text(
                      _diagnosticMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isConnected ? Colors.green : Colors.orange[800],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!_isConnected)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Not Connected',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Test connection before scanning',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _showNetworkHelp,
                    child: const Text('Help'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    if (!_isScanningEnabled) return;

                    final barcode = capture.barcodes.first.rawValue;
                    if (barcode != null && _isConnected) {
                      if (barcode != _lastScannedCode) {
                        _sendBarcode(barcode);
                      }
                    } else if (barcode != null && !_isConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ Not connected! Test connection first.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ),
                if (!_isScanningEnabled)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.pause_circle_filled,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Scanning Paused',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Last scanned: $_lastScannedCode',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _scannerController.dispose();
    super.dispose();
  }
}
'@
Set-Content -Path "lib\src\scanner_widget.dart" -Value $scannerWidget -Encoding UTF8
Write-Host "✓ Created lib\src\scanner_widget.dart" -ForegroundColor Cyan

# Continue in next part...
Write-Host ""
Write-Host "Part 1 of 2 complete. Run setup_part2.ps1 next..." -ForegroundColor Yellow