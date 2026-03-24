import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

/// Full-screen camera for scanning ID cards (front / back).
/// Returns an [XFile] via Navigator.pop when the user captures a photo.
class IdScanCameraScreen extends StatefulWidget {
  /// Label shown at the top, e.g. "Scan Front Side"
  final String title;

  const IdScanCameraScreen({super.key, required this.title});

  @override
  State<IdScanCameraScreen> createState() => _IdScanCameraScreenState();
}

class _IdScanCameraScreenState extends State<IdScanCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isCameraReady = false;
  bool _isCapturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No cameras found');
        return;
      }

      // Default to back camera for ID scanning
      _currentCameraIndex = 0;
      for (int i = 0; i < _cameras.length; i++) {
        if (_cameras[i].lensDirection == CameraLensDirection.back) {
          _currentCameraIndex = i;
          break;
        }
      }

      await _startCamera(_cameras[_currentCameraIndex]);
    } catch (e) {
      if (mounted) setState(() => _error = 'Camera error: $e');
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final prev = _controller;
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    // Dispose previous after creating new to avoid flicker
    await prev?.dispose();

    try {
      await _controller!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Camera error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() => _isCameraReady = false);
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _startCamera(_cameras[_currentCameraIndex]);
  }

  Future<void> _capture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final file = await _controller!.takePicture();
      if (mounted) Navigator.of(context).pop(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview
            if (_isCameraReady && _controller != null)
              Center(child: CameraPreview(_controller!))
            else if (_error != null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(_error!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initCamera,
                      child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  ],
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Semi-transparent overlay with card-shaped cutout
            if (_isCameraReady)
              CustomPaint(
                painter: _IdCardGuidePainter(),
                child: const SizedBox.expand(),
              ),

            // Top bar: back button + title + switch camera
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Switch camera button
                    if (_cameras.length >= 2)
                      IconButton(
                        icon: const Icon(Icons.cameraswitch_rounded,
                            color: Colors.white, size: 28),
                        onPressed: _switchCamera,
                        tooltip:
                            isArabic ? 'تبديل الكاميرا' : 'Switch Camera',
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // Hint text
            if (_isCameraReady)
              Positioned(
                bottom: 120,
                left: 24,
                right: 24,
                child: Text(
                  isArabic
                      ? 'ضع بطاقة الهوية داخل الإطار والتقط الصورة'
                      : 'Position ID card within the frame and capture',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(blurRadius: 6, color: Colors.black54),
                    ],
                  ),
                ),
              ),

            // Bottom: capture button
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _isCameraReady ? _capture : null,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _isCapturing
                          ? Colors.grey
                          : AppTheme.primaryColor.withValues(alpha: 0.8),
                    ),
                    child: _isCapturing
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(Icons.camera_alt,
                            color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a semi-transparent overlay with a card-shaped cutout in the centre.
class _IdCardGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cardWidth = size.width * 0.85;
    final cardHeight = cardWidth / 1.586; // standard ID card aspect ratio
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: cardWidth,
      height: cardHeight,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    // Dark overlay
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final cutoutPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(cutoutPath, overlayPaint);

    // Card border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, borderPaint);

    // Corner accents
    const cLen = 24.0;
    final accentPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top + cLen),
        Offset(rect.left, rect.top), accentPaint);
    canvas.drawLine(Offset(rect.left, rect.top),
        Offset(rect.left + cLen, rect.top), accentPaint);
    // Top-right
    canvas.drawLine(Offset(rect.right - cLen, rect.top),
        Offset(rect.right, rect.top), accentPaint);
    canvas.drawLine(Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + cLen), accentPaint);
    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom - cLen),
        Offset(rect.left, rect.bottom), accentPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom),
        Offset(rect.left + cLen, rect.bottom), accentPaint);
    // Bottom-right
    canvas.drawLine(Offset(rect.right - cLen, rect.bottom),
        Offset(rect.right, rect.bottom), accentPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - cLen), accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
