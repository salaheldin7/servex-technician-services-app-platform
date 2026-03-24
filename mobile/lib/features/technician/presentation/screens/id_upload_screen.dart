import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/verification_providers.dart';
import 'id_scan_camera_screen.dart';

class IdUploadScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const IdUploadScreen({super.key, required this.onComplete});

  @override
  ConsumerState<IdUploadScreen> createState() => _IdUploadScreenState();
}

class _IdUploadScreenState extends ConsumerState<IdUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _files = [];

  Future<void> _pickFromCamera() async {
    if (_files.length >= 2) {
      _showMaxFilesError();
      return;
    }

    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;
    final side = _files.isEmpty
        ? (isArabic ? 'مسح الوجه الأمامي' : 'Scan Front Side')
        : (isArabic ? 'مسح الوجه الخلفي' : 'Scan Back Side');

    final XFile? photo = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(
        builder: (_) => IdScanCameraScreen(title: side),
      ),
    );

    if (photo != null && mounted) {
      setState(() => _files.add(photo));
    }
  }

  Future<void> _pickFromGallery() async {
    if (_files.length >= 2) {
      _showMaxFilesError();
      return;
    }

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );

    if (photo != null) {
      setState(() => _files.add(photo));
    }
  }

  void _showMaxFilesError() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.isArabic
              ? 'الحد الأقصى 2 صورة (وجه + خلف البطاقة)'
              : 'Maximum 2 images (front + back of ID)',
        ),
      ),
    );
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_files.isEmpty) return;

    final success =
        await ref.read(verificationFlowProvider.notifier).uploadDocuments(_files);

    if (success && mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final flowState = ref.watch(verificationFlowProvider);
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تحميل بطاقة الهوية' : 'Upload ID Card'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppTheme.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'حمّل صورتين (وجه أمامي + خلفي) بصيغة PNG/JPEG'
                          : 'Upload 2 photos (front + back) as PNG/JPEG',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Uploaded files
            if (_files.isNotEmpty) ...[
              Text(
                isArabic
                    ? 'الصور المرفوعة (${_files.length}/2)'
                    : 'Uploaded Photos (${_files.length}/2)',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...List.generate(_files.length, (i) {
                final file = _files[i];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          file.path,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 64, color: Colors.grey),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeFile(i),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            i == 0
                                ? (isArabic ? 'الوجه الأمامي' : 'Front')
                                : (isArabic ? 'الوجه الخلفي' : 'Back'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Two action buttons: Scan Now & Choose from Gallery
            if (_files.length < 2) ...[
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.camera_alt_rounded,
                      label: isArabic ? 'مسح الآن' : 'Scan Now',
                      onTap: _pickFromCamera,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.photo_library_rounded,
                      label: isArabic ? 'اختر من المعرض' : 'Gallery',
                      onTap: _pickFromGallery,
                    ),
                  ),
                ],
              ),
            ],

            // When we have 1 image, show hint for back side
            if (_files.length == 1) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'تم التقاط الوجه الأمامي. اضغط "مسح الآن" لالتقاط الوجه الخلفي.'
                            : 'Front side captured. Tap "Scan Now" to capture the back side.',
                        style: TextStyle(color: Colors.orange[800], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit button
            if (_files.isNotEmpty)
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
                          isArabic ? 'إرسال والمتابعة' : 'Submit & Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

            if (flowState.error != null) ...[
              const SizedBox(height: 16),
              Text(
                flowState.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
