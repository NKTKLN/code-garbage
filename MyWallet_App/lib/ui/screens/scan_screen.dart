import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../../domain/models/enums.dart';

class ScanResult {
  final String value;
  final CodeType codeType;
  const ScanResult({required this.value, required this.codeType});
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;

  bool _popped = false;
  bool _hasPermission = true;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _controller?.pauseCamera();
    }
    _controller?.resumeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cutOut = (size.width < 360) ? 240.0 : 290.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: QRView(
                key: _qrKey,
                onQRViewCreated: _onQRViewCreated,
                onPermissionSet: (ctrl, p) {
                  setState(() => _hasPermission = p);
                  if (!p) _showNoPermissionDialog();
                },
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.white,
                  borderRadius: 18,
                  borderLength: 34,
                  borderWidth: 6,
                  cutOutSize: cutOut,
                  overlayColor: Colors.black.withOpacity(0.60),
                ),
              ),
            ),

            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _RoundIconButton(
                    icon: Icons.cameraswitch,
                    onTap: () async => _controller?.flipCamera(),
                  ),
                  const SizedBox(width: 10),
                  _RoundIconButton(
                    icon: Icons.flash_on,
                    onTap: () async => _controller?.toggleFlash(),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _hasPermission ? 1 : 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Text(
                    'Наведи на QR/штрихкод — сканирование автоматически',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;

    controller.scannedDataStream.listen((barcode) {
      if (_popped) return;

      final value = barcode.code;
      if (value == null || value.trim().isEmpty) return;

      _popped = true;

      Navigator.pop(
        context,
        ScanResult(
          value: value.trim(),
          codeType: _mapFormat(barcode.format),
        ),
      );
    });
  }

  CodeType _mapFormat(BarcodeFormat f) {
    switch (f) {
      case BarcodeFormat.qrcode:
        return CodeType.qr;
      case BarcodeFormat.code128:
        return CodeType.code128;
      case BarcodeFormat.ean13:
        return CodeType.ean13;
      case BarcodeFormat.pdf417:
        return CodeType.pdf417;
      default:
        return CodeType.qr;
    }
  }

  Future<void> _showNoPermissionDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Нет доступа к камере'),
        content: const Text('Разреши доступ к камере в настройках приложения и открой сканер снова.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
