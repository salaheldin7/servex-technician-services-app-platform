import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/verification_providers.dart';
import 'face_verification_screen.dart';
import 'id_upload_screen.dart';
import 'service_selector_screen.dart';
import 'location_selector_screen.dart';

class VerificationFlowScreen extends ConsumerStatefulWidget {
  const VerificationFlowScreen({super.key});

  @override
  ConsumerState<VerificationFlowScreen> createState() =>
      _VerificationFlowScreenState();
}

class _VerificationFlowScreenState
    extends ConsumerState<VerificationFlowScreen> {
  int _currentStep = 0;

  final List<Map<String, String>> _stepInfo = [
    {'en': 'Face Verification', 'ar': 'التحقق من الوجه', 'icon': '📸'},
    {'en': 'ID Document', 'ar': 'بطاقة الهوية', 'icon': '🪪'},
    {'en': 'Your Services', 'ar': 'خدماتك', 'icon': '🔧'},
    {'en': 'Service Areas', 'ar': 'مناطق الخدمة', 'icon': '📍'},
  ];

  bool _showSuccessScreen = false;

  @override
  void initState() {
    super.initState();
    _checkExistingStatus();
  }

  Future<void> _checkExistingStatus() async {
    final statusResult =
        await ref.read(verificationRepositoryProvider).getVerificationStatus();
    if (statusResult.isSuccess && mounted) {
      final status = statusResult.data!;
      if (status.faceVerified && status.docsUploaded) {
        setState(() => _currentStep = 2);
      } else if (status.faceVerified) {
        setState(() => _currentStep = 1);
      }
    }
  }

  void _onStepComplete() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      // All steps complete — show success screen
      setState(() => _showSuccessScreen = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;

    if (_showSuccessScreen) {
      return _buildSuccessScreen(isArabic);
    }

    return Scaffold(
      body: Column(
        children: [
          // Step indicator header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        Expanded(
                          child: Text(
                            isArabic
                                ? 'إعداد الحساب'
                                : 'Account Setup',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance close button
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Step indicators
                    Row(
                      children: List.generate(4, (i) {
                        final isDone = i < _currentStep;
                        final isCurrent = i == _currentStep;
                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDone
                                        ? AppTheme.successColor
                                        : isCurrent
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.2),
                                  ),
                                  child: Center(
                                    child: isDone
                                        ? const Icon(Icons.check,
                                            color: Colors.white, size: 20)
                                        : Text(
                                            _stepInfo[i]['icon']!,
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isArabic
                                      ? _stepInfo[i]['ar']!
                                      : _stepInfo[i]['en']!,
                                  style: TextStyle(
                                    color: isCurrent || isDone
                                        ? Colors.white
                                        : Colors.white
                                            .withValues(alpha: 0.5),
                                    fontSize: 10,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Current step content
          Expanded(
            child: _buildCurrentStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(bool isArabic) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.successColor,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  isArabic ? 'تم إرسال الطلب!' : 'Application Sent!',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isArabic
                      ? 'تم إرسال طلبك للمراجعة. ستصلك إشعار عند الموافقة أو الرفض.'
                      : 'Your application has been submitted for review. You will receive a notification once approved or rejected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isArabic ? 'تم' : 'Done',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return FaceVerificationScreen(onComplete: _onStepComplete);
      case 1:
        return IdUploadScreen(onComplete: _onStepComplete);
      case 2:
        return ServiceSelectorScreen(onComplete: _onStepComplete);
      case 3:
        return LocationSelectorScreen(onComplete: _onStepComplete);
      default:
        return const SizedBox.shrink();
    }
  }
}
