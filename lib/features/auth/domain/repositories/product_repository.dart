// lib/features/product/domain/repositories/product_repository.dart

import 'dart:io';
import '../../data/models/product_model.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel> getProduct(int id);
  Future<ProductModel> createProduct({
    required String productName,
    required double price,
    required int stock,
    String? description,
    String? targetMarket,
    File? image,
  });
  Future<ProductModel> updateProduct(int id, Map<String, dynamic> data);
  Future<void> deleteProduct(int id);
  Future<AiContent> generateAiContent(int productId);
}
