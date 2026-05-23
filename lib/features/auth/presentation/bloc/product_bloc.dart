// lib/features/product/presentation/bloc/product_bloc.dart

import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../../core/network/api_client.dart';

// ─── Events ───────────────────────────────────────────────────
abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class ProductLoadRequested extends ProductEvent {}

class ProductCreateRequested extends ProductEvent {
  final String productName, description, targetMarket;
  final double price;
  final int stock;
  final File? image;
  const ProductCreateRequested({
    required this.productName,
    required this.price,
    required this.stock,
    this.description = '',
    this.targetMarket = '',
    this.image,
  });
}

class ProductDeleteRequested extends ProductEvent {
  final int id;
  const ProductDeleteRequested(this.id);
}

class ProductAiGenerateRequested extends ProductEvent {
  final int productId;
  final String productName;
  const ProductAiGenerateRequested(this.productId, this.productName);
}

// ─── States ───────────────────────────────────────────────────
abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  const ProductLoaded(this.products);
  @override
  List<Object?> get props => [products];
}

class ProductActionSuccess extends ProductState {
  final String message;
  final List<ProductModel> products;
  const ProductActionSuccess(this.message, this.products);
  @override
  List<Object?> get props => [message, products];
}

class ProductAiSuccess extends ProductState {
  final AiContent aiContent;
  final String productName;
  final List<ProductModel> products;
  const ProductAiSuccess(this.aiContent, this.productName, this.products);
  @override
  List<Object?> get props => [aiContent, productName];
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repo;
  List<ProductModel> _products = [];

  ProductBloc(this._repo) : super(ProductInitial()) {
    on<ProductLoadRequested>(_onLoad);
    on<ProductCreateRequested>(_onCreate);
    on<ProductDeleteRequested>(_onDelete);
    on<ProductAiGenerateRequested>(_onAiGenerate);
  }

  Future<void> _onLoad(
    ProductLoadRequested e,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      _products = await _repo.getProducts();
      emit(ProductLoaded(_products));
    } on ApiException catch (ex) {
      emit(ProductError(ex.message));
    } catch (_) {
      emit(const ProductError('Gagal memuat produk'));
    }
  }

  Future<void> _onCreate(
    ProductCreateRequested e,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      await _repo.createProduct(
        productName: e.productName,
        price: e.price,
        stock: e.stock,
        description: e.description,
        targetMarket: e.targetMarket,
        image: e.image,
      );
      _products = await _repo.getProducts();
      emit(ProductActionSuccess('Produk berhasil ditambahkan! ✅', _products));
    } on ValidationException catch (ex) {
      emit(ProductError(ex.message));
    } on ApiException catch (ex) {
      emit(ProductError(ex.message));
    } catch (_) {
      emit(const ProductError('Gagal menambahkan produk'));
    }
  }

  Future<void> _onDelete(
    ProductDeleteRequested e,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _repo.deleteProduct(e.id);
      _products = await _repo.getProducts();
      emit(ProductActionSuccess('Produk dihapus', _products));
    } on ApiException catch (ex) {
      emit(ProductError(ex.message));
    }
  }

  Future<void> _onAiGenerate(
    ProductAiGenerateRequested e,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      final ai = await _repo.generateAiContent(e.productId);
      emit(ProductAiSuccess(ai, e.productName, _products));
    } on ValidationException catch (ex) {
      final errorMsg = _mapAiError(ex.message, ex.errors);
      emit(ProductError(errorMsg));
    } on ApiException catch (ex) {
      final errorMsg = _mapAiError(ex.message, null);
      emit(ProductError(errorMsg));
    } catch (_) {
      emit(
        const ProductError(
          'Kami sedang kesulitan membuat konten. Silakan coba lagi sebentar.',
        ),
      );
    }
  }

  String _mapAiError(String message, Map<String, dynamic>? errors) {
    final normalized = message.toLowerCase();

    if (errors != null && errors.isNotEmpty) {
      if (errors.containsKey('product_id')) {
        return 'Produk tidak ditemukan. Silakan pilih produk lain.';
      }
      if (errors.containsKey('type')) {
        return 'Jenis konten belum tersedia. Coba pilih fitur lain.';
      }
      if (errors.containsKey('ai')) {
        return 'AI sedang sibuk. Silakan coba beberapa saat lagi.';
      }
    }

    if (normalized.contains('produk belum memiliki data dasar')) {
      return 'Data produk belum cukup untuk dibuatkan konten AI. Lengkapi deskripsi, target market, dan informasi utama produk.';
    }

    if (normalized.contains('nama produk belum tersedia')) {
      return 'Nama produk belum terisi. Lengkapi data produk terlebih dahulu.';
    }

    if (normalized.contains('gagal menghubungi gemini')) {
      return 'Layanan AI sedang bermasalah. Silakan coba lagi nanti.';
    }

    if (normalized.contains('timeout')) {
      return 'Koneksi ke layanan AI terlalu lama. Coba lagi ya.';
    }

    return 'Konten belum bisa dibuat saat ini. Silakan coba lagi nanti.';
  }
}
