import 'package:flutter/material.dart';
import 'package:wifi_barcode_scanner/wifi_barcode_scanner.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Barcode Scanner Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Barcode Scanner Demo'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose Device Mode',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReceiverPage()),
                );
              },
              icon: const Icon(Icons.tablet_mac, size: 40),
              label: const Text(
                'Receiver (Tablet/POS)',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScannerPage()),
                );
              },
              icon: const Icon(Icons.qr_code_scanner, size: 40),
              label: const Text(
                'Scanner (Phone)',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReceiverPage extends StatefulWidget {
  const ReceiverPage({super.key});

  @override
  State<ReceiverPage> createState() => _ReceiverPageState();
}

class _ReceiverPageState extends State<ReceiverPage> {
  BarcodeHttpServer? _server;
  String? _serverIP;
  final List<String> _barcodes = [];

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    _server = BarcodeHttpServer(
      onBarcodeReceived: (barcode) {
        setState(() {
          _barcodes.insert(0, barcode);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Received: $barcode'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );

    _serverIP = await _server!.start();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Receiver'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          if (_serverIP != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade100,
              child: Column(
                children: [
                  const Icon(Icons.wifi, size: 48, color: Colors.green),
                  const SizedBox(height: 8),
                  const Text(
                    'Server Running',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    'IP: $_serverIP:8080',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter this IP in scanner app',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Recent Scans',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _barcodes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Waiting for scans...',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _barcodes.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          _barcodes[index],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text('Scan #${_barcodes.length - index}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _server?.stop();
    super.dispose();
  }
}

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScannerWidget(
      config: ScannerConfig(
        defaultIpAddress: '192.168.43.1',
        requireScanConfirmation: true,
        showDiagnostics: true,
      ),
    );
  }
}