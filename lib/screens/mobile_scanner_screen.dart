import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MobileScannerScreen extends StatefulWidget {
  const MobileScannerScreen({super.key});

  @override
  State<MobileScannerScreen> createState() => _MobileScannerScreenState();
}

class _MobileScannerScreenState extends State<MobileScannerScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled || !mounted) return;
    for (final barcode in capture.barcodes) {
      final v = barcode.rawValue ?? barcode.displayValue;
      if (v != null && v.isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop<String>(v);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(),
            ),
          ),
          Center(
            child: SizedBox(
              width: 260,
              height: 160,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _scannerCornerL(),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _RotatedCorner(turns: 0.25),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _RotatedCorner(turns: 0.75),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _RotatedCorner(turns: 0.5),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Scan Barcode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Point at a barcode to scan',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 260,
      height: 160,
    );
    canvas.drawPath(
      Path.combine(
        ui.PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
          ),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
      Paint()
        ..color = const Color(0xFF00C48C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget _scannerCornerL() {
  return Container(
    width: 20,
    height: 20,
    decoration: const BoxDecoration(
      border: Border(
        top: BorderSide(color: Color(0xFF00C48C), width: 3),
        left: BorderSide(color: Color(0xFF00C48C), width: 3),
      ),
    ),
  );
}

class _RotatedCorner extends StatelessWidget {
  const _RotatedCorner({required this.turns});

  final double turns;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: turns * 2 * math.pi,
      child: _scannerCornerL(),
    );
  }
}
