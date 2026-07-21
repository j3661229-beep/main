import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

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
    final r = context.r;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.all(r.rs(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload Document', style: AppTextStyles.headingLG),
            SizedBox(height: r.rh(20)),
            ListTile(
              leading: Container(
                  width: r.rs(44), height: 44,
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(r.rs(12))),
                  child: Center(child: Text('📷', style: TextStyle(fontSize: r.sp(22))))),
              title: Text('Take a Photo', style: AppTextStyles.headingMD),
              subtitle: const Text('Use your camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                  width: r.rs(44), height: 44,
                  decoration: BoxDecoration(color: Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(r.rs(12))),
                  child: Center(child: Text('🖼️', style: TextStyle(fontSize: r.sp(22))))),
              title: Text('Choose from Gallery', style: AppTextStyles.headingMD),
              subtitle: const Text('Pick an existing image'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            SizedBox(height: r.rh(16)),
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
    final r = context.r;
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
                padding: EdgeInsets.all(r.rs(20)),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    ),
                    SizedBox(width: r.rs(12)),
                    Text(
                      role == 'DEALER' ? '🤝 Dealer Verification' : '🏪 Supplier Verification',
                      style: TextStyle(fontSize: r.sp(18), fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Main content card
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(r.rs(16)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(r.rs(32)),
                  ),
                  child: ListView(
                    padding: EdgeInsets.all(r.rs(24)),
                    children: [
                      // Info banner
                      Container(
                        padding: EdgeInsets.all(r.rs(20)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.blue.shade100],
                          ),
                          borderRadius: BorderRadius.circular(r.rs(20)),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Text('🛡️', style: TextStyle(fontSize: r.sp(40))),
                            SizedBox(height: r.rh(12)),
                            Text(
                              'Verification Required',
                              style: AppTextStyles.headingLG.copyWith(color: Colors.blue.shade900),
                            ),
                            SizedBox(height: r.rh(8)),
                            Text(
                              'To protect farmers and ensure quality, we verify all ${role.toLowerCase()}s. Please upload one government-issued document.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.blue.shade700, fontSize: r.sp(13), height: 1.5),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: r.rh(28)),
                      Text('Document Type', style: AppTextStyles.labelLG),
                      SizedBox(height: r.rh(12)),

                      // Document type selector
                      Wrap(
                        spacing: r.rs(8),
                        runSpacing: r.rs(8),
                        children: _docTypes.map((dt) {
                          final isSelected = _selectedDocType == dt.$1;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDocType = dt.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(horizontal: r.rs(14), vertical: r.rh(8)),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(r.rs(20)),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                dt.$2,
                                style: TextStyle(
                                  fontSize: r.sp(12),
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: r.rh(28)),
                      Text('Upload Document', style: AppTextStyles.labelLG),
                      SizedBox(height: r.rh(12)),

                      // File picker
                      GestureDetector(
                        onTap: _pickDocument,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: r.rh(180),
                          decoration: BoxDecoration(
                            color: _selectedFile != null ? Colors.green.shade50 : AppColors.surface,
                            borderRadius: BorderRadius.circular(r.rs(24)),
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
                                      borderRadius: BorderRadius.circular(r.rs(23)),
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
                                          padding: EdgeInsets.all(r.rs(4)),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.close, size: r.sp(16), color: AppColors.error),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      left: 8,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rh(4)),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(r.rs(12)),
                                        ),
                                        child: Text('✓ Selected', style: TextStyle(color: Colors.white, fontSize: r.sp(11), fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: r.rs(56),
                                      height: r.rh(56),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySurface,
                                        borderRadius: BorderRadius.circular(r.rs(16)),
                                      ),
                                      child: Center(child: Text('📤', style: TextStyle(fontSize: r.sp(28)))),
                                    ),
                                    SizedBox(height: r.rh(12)),
                                    Text('Tap to upload document', style: TextStyle(fontWeight: FontWeight.w700, fontSize: r.sp(14))),
                                    SizedBox(height: r.rh(4)),
                                    Text('JPG, PNG up to 10MB', style: TextStyle(fontSize: r.sp(12), color: AppColors.textTertiary)),
                                  ],
                                ),
                        ),
                      ),

                      SizedBox(height: r.rh(32)),

                      // Upload button
                      SizedBox(
                        width: double.infinity,
                        height: r.rh(58),
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _upload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.rs(20))),
                            elevation: 8,
                            shadowColor: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          child: _isUploading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(width: r.rs(20), height: r.rh(20), child: CircularProgressIndicator(color: Colors.white, strokeWidth: r.rs(2.5))),
                                    SizedBox(width: r.rs(12)),
                                    Text('Uploading...', style: TextStyle(fontSize: r.sp(16), fontWeight: FontWeight.bold)),
                                  ],
                                )
                              : Text('Submit for Verification 🛡️', style: TextStyle(fontSize: r.sp(17), fontWeight: FontWeight.bold)),
                        ),
                      ),

                      SizedBox(height: r.rh(16)),
                      Center(
                        child: TextButton(
                          onPressed: () => ref.read(authProvider.notifier).logout(),
                          child: Text('Sign out & login later', style: TextStyle(color: AppColors.textTertiary)),
                        ),
                      ),
                      SizedBox(height: r.rh(16)),
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

