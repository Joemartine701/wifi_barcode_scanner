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