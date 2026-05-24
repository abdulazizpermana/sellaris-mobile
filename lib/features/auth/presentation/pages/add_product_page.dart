// lib/features/product/presentation/pages/add_product_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../bloc/product_bloc.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});
  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  File? _image;
  bool _isPickingImage = false;

  void _disposeControllers() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (!mounted) return;
      if (picked != null) {
        setState(() => _image = File(picked.path));
      }
    } on PlatformException catch (error) {
      if (error.code != 'already_active') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memilih gambar: ${error.message ?? 'Terjadi kesalahan'}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      _isPickingImage = false;
    }
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    context.read<ProductBloc>().add(
      ProductCreateRequested(
        productName: _nameCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.replaceAll('.', '')),
        stock: int.parse(_stockCtrl.text),
        description: _descCtrl.text.trim(),
        targetMarket: _targetCtrl.text.trim(),
        image: _image,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tambah Produk')),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (ctx, state) {
          if (state is ProductActionSuccess) {
            Navigator.pop(ctx, true);
          } else if (state is ProductError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        builder: (ctx, state) {
          final isLoading = state is ProductLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Foto Produk ──────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                          image: _image != null
                              ? DecorationImage(
                                  image: FileImage(_image!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _image == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: AppColors.primary,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tambah Foto',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.primary),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Form Fields ──────────────────────────
                  SField(
                    controller: _nameCtrl,
                    label: 'Nama Produk',
                    hint: 'Contoh: Keripik Pisang Coklat',
                    prefixIcon: Icons.shopping_bag_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Nama produk wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: SField(
                          controller: _priceCtrl,
                          label: 'Harga (Rp)',
                          hint: '15000',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.attach_money_rounded,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Harga wajib diisi';
                            }
                            if (double.tryParse(v.replaceAll('.', '')) ==
                                null) {
                              return 'Harga tidak valid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SField(
                          controller: _stockCtrl,
                          label: 'Stok',
                          hint: '50',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.inventory_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Stok wajib diisi';
                            }
                            if (int.tryParse(v) == null) return 'Angka saja';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SField(
                    controller: _targetCtrl,
                    label: 'Target Market',
                    hint: 'Contoh: Anak muda, Ibu rumah tangga',
                    prefixIcon: Icons.people_outline_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),

                  SField(
                    controller: _descCtrl,
                    label: 'Deskripsi Produk',
                    hint: 'Ceritakan keunggulan produkmu...',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 12),

                  // AI hint
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Setelah produk disimpan, kamu bisa generate caption Instagram & konten promosi dengan AI! ✨',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  LoadingButton(
                    isLoading: isLoading,
                    label: 'Simpan Produk',
                    onPressed: _submit,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
