// lib/features/product/data/repositories/product_repository_impl.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../data/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ApiClient _api;
  ProductRepositoryImpl(this._api);

  @override
  Future<List<ProductModel>> getProducts() async {
    final res = await _api.get('${AppConstants.products}?per_page=1000');
    final list = res.data['data'] as List;
    return list.map((j) => ProductModel.fromJson(j)).toList();
  }

  @override
  Future<ProductModel> getProduct(int id) async {
    final res = await _api.get('${AppConstants.products}/$id');
    return ProductModel.fromJson(res.data['data']);
  }

  @override
  Future<ProductModel> createProduct({
    required String productName,
    required double price,
    required int stock,
    String? description,
    String? targetMarket,
    File? image,
  }) async {
    final fields = <String, String>{
      'product_name': productName,
      'price': price.toString(),
      'stock': stock.toString(),
      'description': description ?? '',
      'target_market': targetMarket ?? '',
    };
    final res = await _api.postMultipart(
      AppConstants.products,
      fields: fields,
      imageFile: image,
    );
    return ProductModel.fromJson(res.data['data']);
  }

  @override
  Future<ProductModel> updateProduct(int id, Map<String, dynamic> data) async {
    final image = data['image'];
    final fields = <String, String>{
      'product_name': data['product_name']?.toString() ?? '',
      'price': data['price']?.toString() ?? '0',
      'stock': data['stock']?.toString() ?? '0',
      'description': data['description']?.toString() ?? '',
      'target_market': data['target_market']?.toString() ?? '',
    };

    final res = image is File
        ? await _api.putMultipart(
            '${AppConstants.products}/$id',
            fields: fields,
            imageFile: image,
          )
        : await _api.put('${AppConstants.products}/$id', body: fields);

    return ProductModel.fromJson(res.data['data']);
  }

  @override
  Future<void> deleteProduct(int id) async {
    await _api.delete('${AppConstants.products}/$id');
  }

  @override
  Future<AiContent> generateAiContent(
    int productId, {
    String type = 'caption',
  }) async {
    final res = await _api.post(
      AppConstants.aiGenerate,
      body: {
        'product_id': productId,
        'type': type,
      },
    );
    return AiContent.fromJson(res.data['data']);
  }

  @override
  Future<AiAllContent> generateAllAiContent(int productId) async {
    final token = await SecureStorage().getToken();

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.aiGenerateAll}'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'product_id': productId}),
    );

    final responseBody = utf8.decode(response.bodyBytes);
    print('=== [HTTP STATUS CODE]: ${response.statusCode}');
    print('=== [HTTP RESPONSE BODY]: $responseBody');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));

      if (responseData is Map<String, dynamic>) {
        throw ApiException(
          responseData['message']?.toString() ?? 'Terjadi kesalahan',
          errors: responseData['errors'] as Map<String, dynamic>?,
        );
      }

      throw const ApiException('Terjadi kesalahan');
    }

    final responseData = jsonDecode(responseBody);
    return AiAllContent.fromJson(responseData['data']);
  }

  @override
  Future<AiContentHistory> getAiHistory(int productId) async {
    final res = await _api.get('${AppConstants.aiHistory}/$productId');
    return AiContentHistory.fromJson(res.data);
  }
}
