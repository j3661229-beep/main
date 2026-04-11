import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class DocUploadScreen extends ConsumerStatefulWidget {
  const DocUploadScreen({super.key});

  @override
  ConsumerState<DocUploadScreen> createState() => _DocUploadScreenState();
}

class _DocUploadScreenState extends ConsumerState<DocUploadScreen> {
  final _picker = ImagePicker();
  File? _selectedFile;
  String _selectedDocType = 'GST';
  bool _isUploading = false;

  static const _docTypes = [
    ('GST', '📋 GST Certificate'),
    ('SHOP_LICENSE', '🏪 Shop License'),
    ('AADHAR', '🪪 Aadhar Card'),
    ('PAN', '💳 PAN Card'),
    ('OTHER', '📄 Other Document'),
  ];

  Future<void> _pickDocument() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Document', style: AppTextStyles.headingLG),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('📷', style: TextStyle(fontSize: 22)))),
              title: const Text('Take a Photo', style: AppTextStyles.headingMD),
              subtitle: const Text('Use your camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('🖼️', style: TextStyle(fontSize: 22)))),
              title: const Text('Choose from Gallery', style: AppTextStyles.headingMD),
              subtitle: const Text('Pick an existing image'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
    if (picked != null) {
      setState(() => _selectedFile = File(picked.path));
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a document first'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await ApiService.instance.uploadGovtDoc(
        file: _selectedFile!,
        docType: _selectedDocType,
      );

      if (!mounted) return;
      context.go('/auth/pending');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final role = auth.user?.role ?? 'SUPPLIER';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      role == 'DEALER' ? '🤝 Dealer Verification' : '🏪 Supplier Verification',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Main content card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Info banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.blue.shade100],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            const Text('🛡️', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 12),
                            Text(
                              'Verification Required',
                              style: AppTextStyles.headingLG.copyWith(color: Colors.blue.shade900),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'To protect farmers and ensure quality, we verify all ${role.toLowerCase()}s. Please upload one government-issued document.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.blue.shade700, fontSize: 13, height: 1.5),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      const Text('Document Type', style: AppTextStyles.labelLG),
                      const SizedBox(height: 12),

                      // Document type selector
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _docTypes.map((dt) {
                          final isSelected = _selectedDocType == dt.$1;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDocType = dt.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                dt.$2,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 28),
                      const Text('Upload Document', style: AppTextStyles.labelLG),
                      const SizedBox(height: 12),

                      // File picker
                      GestureDetector(
                        onTap: _pickDocument,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 180,
                          decoration: BoxDecoration(
                            color: _selectedFile != null ? Colors.green.shade50 : AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _selectedFile != null ? AppColors.success : AppColors.border,
                              width: _selectedFile != null ? 2 : 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _selectedFile != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(23),
                                      child: Image.file(
                                        _selectedFile!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _selectedFile = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 16, color: AppColors.error),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text('✓ Selected', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySurface,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(child: Text('📤', style: TextStyle(fontSize: 28))),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('Tap to upload document', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    const Text('JPG, PNG up to 10MB', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Upload button
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _upload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                            shadowColor: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          child: _isUploading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                                    SizedBox(width: 12),
                                    Text('Uploading...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                )
                              : const Text('Submit for Verification 🛡️', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => ref.read(authProvider.notifier).logout(),
                          child: const Text('Sign out & login later', style: TextStyle(color: AppColors.textTertiary)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
