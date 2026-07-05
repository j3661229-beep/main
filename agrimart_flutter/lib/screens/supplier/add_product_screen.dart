import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});
  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _priceCtrl  = TextEditingController();
  final _stockCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();

  String? _category;
  String? _unit;
  final List<File> _images = [];
  bool _isSubmitting = false;
  String? _error;

  final _units = ['kg', 'litre', 'packet', 'quintal', 'piece', 'bag'];

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose();
    _stockCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked.map((x) => File(x.path)).take(5 - _images.length));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'category': _category,
        'price': double.parse(_priceCtrl.text),
        'unit': _unit,
        'stockQuantity': int.parse(_stockCtrl.text),
        'description': _descCtrl.text.trim(),
      };
      if (_images.isNotEmpty) {
        await ApiService.instance.createProductWithImages(data, _images.map((f) => f.path).toList());
      } else {
        await ApiService.instance.createProduct(data);
      }
      HapticFeedback.mediumImpact();
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Product listed successfully! 🎉', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      setState(() { _isSubmitting = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Add Product', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w700)),
        leading: GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Image upload ─────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product Photos', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: Row(
                        children: [
                          // Add button
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 86, height: 86,
                              decoration: BoxDecoration(
                                color: AppColors.supplierTint,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.supplierAccent.withValues(alpha: 0.4), style: BorderStyle.solid, width: 1.5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.supplierAccent, size: 28),
                                  const SizedBox(height: 4),
                                  Text('Add', style: GoogleFonts.inter(fontSize: 11, color: AppColors.supplierAccent, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Preview images
                          Expanded(
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _images.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (_, i) => Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(_images[i], width: 86, height: 86, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 4, right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _images.removeAt(i)),
                                      child: Container(
                                        width: 22, height: 22,
                                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Up to 5 photos. First photo is thumbnail.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.placeholder)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Form fields ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Product Name *'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(hintText: 'e.g. Premium Onion Seeds 500g', prefixIcon: Icon(Icons.edit_outlined, color: AppColors.supplierAccent, size: 20)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter product name' : null,
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel('Category *'),
                    DropdownButtonFormField<String>(
                      value: _category,
                      hint: Text('Select category', style: GoogleFonts.inter(color: AppColors.placeholder)),
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined, color: AppColors.supplierAccent, size: 20)),
                      items: AppConstants.categories.map((c) => DropdownMenuItem(value: c['key'], child: Text(c['label']!, style: GoogleFonts.inter(fontSize: 14)))).toList(),
                      onChanged: (v) => setState(() => _category = v),
                      validator: (v) => v == null ? 'Select a category' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _FieldLabel('Price *'),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          decoration: const InputDecoration(hintText: '0.00', prefixText: '₹ '),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter price';
                            if (double.tryParse(v) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _FieldLabel('Unit *'),
                        DropdownButtonFormField<String>(
                          value: _unit,
                          hint: Text('Unit', style: GoogleFonts.inter(color: AppColors.placeholder, fontSize: 13)),
                          items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: GoogleFonts.inter(fontSize: 14)))).toList(),
                          onChanged: (v) => setState(() => _unit = v),
                          validator: (v) => v == null ? 'Select unit' : null,
                        ),
                      ])),
                    ]),
                    const SizedBox(height: 16),

                    _FieldLabel('Stock Quantity *'),
                    TextFormField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(hintText: '100', prefixIcon: Icon(Icons.warehouse_outlined, color: AppColors.supplierAccent, size: 20), suffixText: 'units'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter stock quantity';
                        if (int.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _FieldLabel('Description'),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Describe quality, origin, usage...', alignLabelWithHint: true),
                    ),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger))),
                  ]),
                ),
              ],

              const SizedBox(height: 24),
              AppButton(
                label: 'List Product',
                onTap: _submit,
                isLoading: _isSubmitting,
                color: AppColors.supplierAccent,
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
  );
}

