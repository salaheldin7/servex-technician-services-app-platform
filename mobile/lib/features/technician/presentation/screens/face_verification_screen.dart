import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/verification_providers.dart';

class FaceVerificationScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const FaceVerificationScreen({super.key, required this.onComplete});

  @override
  ConsumerState<FaceVerificationScreen> createState() =>
      _FaceVerificationScreenState();
}

class _FaceVerificationScreenState
    extends ConsumerState<FaceVerificationScreen> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isCapturing = false;
  String? _cameraError;

  XFile? _frontImage;
  XFile? _rightImage;
  XFile? _leftImage;
  int _currentStep = 0; // 0=front, 1=right, 2=left

  final List<Map<String, dynamic>> _steps = [
    {
      'key': 'front',
      'icon': Icons.face,
      'en': 'Look straight at the camera',
      'ar': 'انظر مباشرة إلى الكاميرا',
    },
    {
      'key': 'right',
      'icon': Icons.turn_right,
      'en': 'Turn your face to the right',
      'ar': 'أدر وجهك إلى اليمين',
    },
    {
      'key': 'left',
      'icon': Icons.turn_left,
      'en': 'Turn your face to the left',
      'ar': 'أدر وجهك إلى اليسار',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No cameras found');
        return;
      }

      // Prefer front camera
      CameraDescription camera = cameras.first;
      for (final cam in cameras) {
        if (cam.lensDirection == CameraLensDirection.front) {
          camera = cam;
          break;
        }
      }

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Camera error: $e');
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await _cameraController!.takePicture();

      setState(() {
        switch (_currentStep) {
          case 0:
            _frontImage = photo;
            break;
          case 1:
            _rightImage = photo;
            break;
          case 2:
            _leftImage = photo;
            break;
        }

        if (_currentStep < 2) {
          _currentStep++;
        }
        _isCapturing = false;
      });
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_frontImage == null || _rightImage == null || _leftImage == null) return;

    final success = await ref
        .read(verificationFlowProvider.notifier)
        .uploadFace(_frontImage!, _rightImage!, _leftImage!);

    if (success && mounted) {
      widget.onComplete();
    }
  }

  void _retakeStep(int step) {
    setState(() {
      switch (step) {
        case 0:
          _frontImage = null;
          break;
        case 1:
          _rightImage = null;
          break;
        case 2:
          _leftImage = null;
          break;
      }
      _currentStep = step;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final flowState = ref.watch(verificationFlowProvider);
    final isArabic = l10n.isArabic;
    final allCaptured =
        _frontImage != null && _rightImage != null && _leftImage != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'التحقق من الوجه' : 'Face Verification'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: List.generate(3, (i) {
                final isDone = _getImageForStep(i) != null;
                final isCurrent = i == _currentStep;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppTheme.successColor
                          : isCurrent
                              ? AppTheme.primaryColor
                              : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Step instruction
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                Text(
                  isArabic
                      ? _steps[_currentStep]['ar'] as String
                      : _steps[_currentStep]['en'] as String,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'الخطوة ${_currentStep + 1} من 3'
                      : 'Step ${_currentStep + 1} of 3',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),

          // Camera preview or captured images
          Expanded(
            child: allCaptured
                ? _buildAllCapturedView(isArabic)
                : _buildCameraView(isArabic),
          ),

          // Bottom actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                // Photo thumbnails
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final file = _getImageForStep(i);
                    final stepInfo = _steps[i];
                    return GestureDetector(
                      onTap: () {
                        if (file != null) {
                          _retakeStep(i);
                        } else {
                          setState(() => _currentStep = i);
                        }
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: i == _currentStep && !allCaptured
                                ? AppTheme.primaryColor
                                : file != null
                                    ? AppTheme.successColor
                                    : Colors.grey[300]!,
                            width: i == _currentStep && !allCaptured ? 2.5 : 1.5,
                          ),
                        ),
                        child: file != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(file.path,
                                        fit: BoxFit.cover,
                                        width: 64,
                                        height: 64,
                                        errorBuilder: (_, __, ___) => const Icon(
                                            Icons.image, size: 32, color: Colors.grey)),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.successColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check,
                                          size: 10, color: Colors.white),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(stepInfo['icon'] as IconData,
                                      size: 22, color: Colors.grey[400]),
                                  const SizedBox(height: 2),
                                  Text(
                                    stepInfo['key'] as String,
                                    style: TextStyle(
                                        fontSize: 9, color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Capture or Submit
                if (!allCaptured)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: (_isCameraReady && !_isCapturing)
                          ? _capturePhoto
                          : null,
                      icon: _isCapturing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_rounded, size: 28),
                      label: Text(
                        isArabic ? 'التقاط صورة' : 'Capture Photo',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                if (allCaptured) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: flowState.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: flowState.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isArabic
                                  ? 'إرسال والمتابعة'
                                  : 'Submit & Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],

                if (flowState.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    flowState.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView(bool isArabic) {
    if (_cameraError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _cameraError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _cameraError = null);
                  _initializeCamera();
                },
                child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraReady || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Live camera preview
            CameraPreview(_cameraController!),

            // Face guide overlay
            CustomPaint(
              painter: _FaceGuidePainter(step: _currentStep),
            ),

            // Direction indicator overlay
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _steps[_currentStep]['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isArabic
                            ? _steps[_currentStep]['ar'] as String
                            : _steps[_currentStep]['en'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllCapturedView(bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 48, color: AppTheme.successColor),
            const SizedBox(height: 10),
            Text(
              isArabic
                  ? 'تم التقاط جميع الصور بنجاح!'
                  : 'All photos captured successfully!',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isArabic
                  ? 'اضغط على الصورة المصغرة لإعادة التقاطها أو أرسل للمتابعة'
                  : 'Tap a thumbnail to retake or submit to continue',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  XFile? _getImageForStep(int step) {
    switch (step) {
      case 0:
        return _frontImage;
      case 1:
        return _rightImage;
      case 2:
        return _leftImage;
      default:
        return null;
    }
  }
}

/// Draws an oval face guide on the camera preview
class _FaceGuidePainter extends CustomPainter {
  final int step;

  _FaceGuidePainter({required this.step});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    // Face-shaped oval: compact size to fit comfortably on screen
    final ovalRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.28,
      height: size.width * 0.40,
    );

    // Draw semi-transparent overlay outside the oval
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );

    // Draw oval border
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Draw directional arrow for right/left steps
    if (step == 1) {
      // Right arrow
      _drawArrow(canvas, center, size.width * 0.38, isRight: true);
    } else if (step == 2) {
      // Left arrow
      _drawArrow(canvas, center, size.width * 0.38, isRight: false);
    }
  }

  void _drawArrow(Canvas canvas, Offset center, double radius,
      {required bool isRight}) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final xDir = isRight ? 1.0 : -1.0;
    final start = Offset(center.dx + xDir * (radius - 20), center.dy);
    final end = Offset(center.dx + xDir * (radius + 15), center.dy);

    canvas.drawLine(start, end, paint);

    // Arrow head
    canvas.drawLine(
      end,
      Offset(end.dx - xDir * 10, end.dy - 10),
      paint,
    );
    canvas.drawLine(
      end,
      Offset(end.dx - xDir * 10, end.dy + 10),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FaceGuidePainter oldDelegate) =>
      oldDelegate.step != step;
}
