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
  final String type;
  const ProductAiGenerateRequested(
    this.productId,
    this.productName, {
    this.type = 'caption',
  });
  @override
  List<Object?> get props => [productId, productName, type];
}

class ProductAiGenerateAllRequested extends ProductEvent {
  final int productId;
  final String productName;

  const ProductAiGenerateAllRequested(this.productId, this.productName);

  @override
  List<Object?> get props => [productId, productName];
}

// ─── States ───────────────────────────────────────────────────
abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductRefreshing extends ProductState {
  final List<ProductModel> products;
  const ProductRefreshing(this.products);

  @override
  List<Object?> get props => [products];
}

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
  final String selectedType;
  final List<ProductModel> products;

  const ProductAiSuccess(
    this.aiContent,
    this.productName,
    this.selectedType,
    this.products,
  );

  @override
  List<Object?> get props => [
        aiContent,
        productName,
        selectedType,
      ];
}

class ProductAiAllSuccess extends ProductState {
  final AiAllContent aiContent;
  final String productName;
  final List<ProductModel> products;

  const ProductAiAllSuccess(this.aiContent, this.productName, this.products);

  @override
  List<Object?> get props => [aiContent, productName, products];
}

class ProductError extends ProductState {
  final String message;
  final List<ProductModel> products;
  const ProductError(this.message, [this.products = const []]);
  @override
  List<Object?> get props => [message, products];
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
    on<ProductAiGenerateAllRequested>(_onAiGenerateAll);
  }

  Future<void> _onLoad(
      ProductLoadRequested e, Emitter<ProductState> emit) async {
    if (_products.isEmpty) {
      emit(ProductLoading());
    } else {
      emit(ProductRefreshing(List<ProductModel>.from(_products)));
    }

    try {
      _products = await _repo.getProducts();
      emit(ProductLoaded(_products));
    } on ApiException catch (ex) {
      emit(ProductError(ex.message, List<ProductModel>.from(_products)));
    } catch (_) {
      emit(ProductError(
          'Gagal memuat produk', List<ProductModel>.from(_products)));
    }
  }

  Future<void> _onCreate(
      ProductCreateRequested e, Emitter<ProductState> emit) async {
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
      emit(ProductError(ex.message, List<ProductModel>.from(_products)));
    } on ApiException catch (ex) {
      emit(ProductError(ex.message, List<ProductModel>.from(_products)));
    } catch (_) {
      emit(ProductError(
          'Gagal menambahkan produk', List<ProductModel>.from(_products)));
    }
  }

  Future<void> _onDelete(
      ProductDeleteRequested e, Emitter<ProductState> emit) async {
    try {
      await _repo.deleteProduct(e.id);
      _products = await _repo.getProducts();
      emit(ProductActionSuccess('Produk dihapus', _products));
    } on ApiException catch (ex) {
      emit(ProductError(ex.message, List<ProductModel>.from(_products)));
    }
  }

  Future<void> _onAiGenerate(
      ProductAiGenerateRequested e, Emitter<ProductState> emit) async {
    if (_products.isEmpty) {
      emit(ProductLoading());
    } else {
      emit(ProductRefreshing(List<ProductModel>.from(_products)));
    }
    try {
      final ai = await _repo.generateAiContent(
        e.productId,
        type: e.type,
      );
      emit(ProductAiSuccess(
        ai,
        e.productName,
        e.type,
        _products,
      ));
    } on ValidationException catch (ex) {
      emit(ProductError(
        _mapAiError(ex.message, ex.errors),
        List<ProductModel>.from(_products),
      ));
    } on ApiException catch (ex) {
      emit(ProductError(
        _mapAiError(ex.message, null),
        List<ProductModel>.from(_products),
      ));
    } catch (_) {
      emit(ProductError(
        'Kami sedang kesulitan membuat konten. Silakan coba lagi sebentar.',
        List<ProductModel>.from(_products),
      ));
    }
  }

  Future<void> _onAiGenerateAll(
      ProductAiGenerateAllRequested e, Emitter<ProductState> emit) async {
    if (_products.isEmpty) {
      emit(ProductLoading());
    } else {
      emit(ProductRefreshing(List<ProductModel>.from(_products)));
    }
    try {
      final ai = await _repo.generateAllAiContent(e.productId);
      emit(ProductAiAllSuccess(ai, e.productName, _products));
    } on ValidationException catch (ex) {
      emit(ProductError(
        _mapAiError(ex.message, ex.errors),
        List<ProductModel>.from(_products),
      ));
    } on ApiException catch (ex) {
      emit(ProductError(
        _mapAiError(ex.message, null),
        List<ProductModel>.from(_products),
      ));
    } catch (_) {
      emit(ProductError(
        'Kami sedang kesulitan membuat semua konten. Silakan coba lagi sebentar.',
        List<ProductModel>.from(_products),
      ));
    }
  }

  String _mapAiError(String message, Map<String, dynamic>? errors) {
    final n = message.toLowerCase();

    if (errors != null) {
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

    if (n.contains('produk belum memiliki data dasar')) {
      return 'Data produk belum cukup. Lengkapi deskripsi & target market.';
    }

    if (n.contains('nama produk belum tersedia')) {
      return 'Nama produk belum terisi. Lengkapi data produk.';
    }

    if (n.contains('gagal menghubungi gemini')) {
      return 'Layanan AI sedang bermasalah. Coba lagi nanti.';
    }

    if (n.contains('timeout')) {
      return 'Koneksi ke layanan AI terlalu lama. Coba lagi ya.';
    }

    return 'Konten belum bisa dibuat saat ini. Silakan coba lagi nanti.';
  }
}
