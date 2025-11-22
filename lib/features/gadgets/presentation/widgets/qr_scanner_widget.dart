import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget for scanning QR codes to provision gadget devices
class QRScannerWidget extends StatefulWidget {
  final Function(Map<String, dynamic> qrData) onQRScanned;

  const QRScannerWidget({super.key, required this.onQRScanned});

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  void _initializeScanner() {
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Parse QR code data
      final qrData = _parseQRCode(barcode.rawValue!);

      if (qrData != null) {
        // Show success feedback
        _showSuccessDialog(qrData);
      } else {
        _showErrorDialog('Invalid QR code format');
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      _showErrorDialog('Error processing QR code: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Map<String, dynamic>? _parseQRCode(String rawData) {
    try {
      // Support multiple QR code formats

      // Format 1: JSON format (most devices)
      // {"type":"smartwatch","manufacturer":"Apple","model":"Watch Series 8","serialNumber":"ABC123","macAddress":"00:00:00:00:00:00"}
      if (rawData.startsWith('{')) {
        // Try to parse as JSON
        try {
          return _parseJsonQRCode(rawData);
        } catch (e) {
          debugPrint('QRScannerWidget: Not a JSON QR code');
        }
      }

      // Format 2: URL format
      // redping://device?type=smartwatch&manufacturer=Apple&model=Watch&serial=ABC123&mac=00:00:00:00:00:00
      if (rawData.startsWith('redping://device')) {
        return _parseUrlQRCode(rawData);
      }

      // Format 3: Simple key-value format
      // TYPE:smartwatch;MFR:Apple;MODEL:Watch;SERIAL:ABC123;MAC:00:00:00:00:00:00
      if (rawData.contains(';') && rawData.contains(':')) {
        return _parseKeyValueQRCode(rawData);
      }

      return null;
    } catch (e) {
      debugPrint('QRScannerWidget: Error parsing QR code - $e');
      return null;
    }
  }

  Map<String, dynamic> _parseJsonQRCode(String jsonData) {
    // Parse JSON format (implementation would use dart:convert)
    // For now, return a sample structure
    return {
      'format': 'json',
      'rawData': jsonData,
      'type': 'smartwatch',
      'manufacturer': 'Unknown',
      'model': 'Unknown',
      'serialNumber': 'Unknown',
      'macAddress': '',
    };
  }

  Map<String, dynamic> _parseUrlQRCode(String url) {
    final uri = Uri.parse(url);
    return {
      'format': 'url',
      'rawData': url,
      'type': uri.queryParameters['type'] ?? 'other',
      'manufacturer': uri.queryParameters['manufacturer'] ?? 'Unknown',
      'model': uri.queryParameters['model'] ?? 'Unknown',
      'serialNumber': uri.queryParameters['serial'] ?? 'Unknown',
      'macAddress': uri.queryParameters['mac'] ?? '',
      'firmwareVersion': uri.queryParameters['firmware'] ?? 'Unknown',
    };
  }

  Map<String, dynamic> _parseKeyValueQRCode(String data) {
    final pairs = data.split(';');
    final result = <String, dynamic>{'format': 'keyvalue', 'rawData': data};

    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final key = parts[0].trim().toLowerCase();
        final value = parts[1].trim();

        switch (key) {
          case 'type':
            result['type'] = value;
            break;
          case 'mfr':
          case 'manufacturer':
            result['manufacturer'] = value;
            break;
          case 'model':
            result['model'] = value;
            break;
          case 'serial':
          case 'serialnumber':
            result['serialNumber'] = value;
            break;
          case 'mac':
          case 'macaddress':
            result['macAddress'] = value;
            break;
          case 'firmware':
          case 'fw':
            result['firmwareVersion'] = value;
            break;
        }
      }
    }

    return result;
  }

  void _showSuccessDialog(Map<String, dynamic> qrData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.safeGreen, size: 28),
            SizedBox(width: 12),
            Text('Device Found', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Successfully scanned device:',
              style: TextStyle(color: AppTheme.neutralGray, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Type', qrData['type'] ?? 'Unknown'),
            _buildInfoRow('Manufacturer', qrData['manufacturer'] ?? 'Unknown'),
            _buildInfoRow('Model', qrData['model'] ?? 'Unknown'),
            _buildInfoRow('Serial', qrData['serialNumber'] ?? 'Unknown'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close scanner
              widget.onQRScanned(qrData);
            },
            child: const Text('Add Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.neutralGray, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.primaryRed, size: 28),
            SizedBox(width: 12),
            Text('Scan Error', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleTorch() async {
    await _controller?.toggleTorch();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.neutralGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  color: AppTheme.primaryRed,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QR Code Scanner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Scan device QR code to add',
                        style: TextStyle(
                          color: AppTheme.neutralGray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _controller?.torchEnabled ?? false
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: _toggleTorch,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.neutralGray, height: 32),

          // Scanner view
          Expanded(
            child: _errorMessage != null
                ? _buildErrorState()
                : _buildScannerView(),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            child: const Column(
              children: [
                Icon(Icons.qr_code_2, color: AppTheme.neutralGray, size: 48),
                SizedBox(height: 12),
                Text(
                  'Point camera at device QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Make sure the code is well lit and in focus',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.neutralGray, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    if (_controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Scanning overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryRed),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          // Corner guides
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: CustomPaint(painter: _ScannerOverlayPainter()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.primaryRed,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _initializeScanner();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 40.0;
    const cornerWidth = 4.0;
    final paint = Paint()
      ..color = AppTheme.primaryRed
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke;

    // Top-left corner
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-right corner
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
