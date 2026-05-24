// lib/features/product/data/models/product_model.dart

int _parseInt(dynamic value) {
  final stringValue = value?.toString();
  if (stringValue == null || stringValue.isEmpty) return 0;
  return int.tryParse(stringValue) ?? 0;
}

double _parseDouble(dynamic value) {
  final stringValue = value?.toString();
  if (stringValue == null || stringValue.isEmpty) return 0.0;
  return double.tryParse(stringValue) ?? 0.0;
}

class AiContent {
  final int id;
  final String type;
  final String content;
  final String? generatedAt;

  const AiContent({
    required this.id,
    required this.type,
    required this.content,
    this.generatedAt,
  });

  factory AiContent.fromJson(Map<String, dynamic> j) => AiContent(
        id: _parseInt(j['id']),
        type: j['type']?.toString() ?? '',
        content: j['content']?.toString() ?? '',
        generatedAt: j['generated_at']?.toString(),
      );
}

class ProductModel {
  final int id;
  final String productName, priceFormatted;
  final double price;
  final int stock;
  final String? imageUrl, description, targetMarket;
  final bool isActive;
  final AiContent? aiContent;

  const ProductModel({
    required this.id,
    required this.productName,
    required this.price,
    required this.priceFormatted,
    required this.stock,
    this.imageUrl,
    this.description,
    this.targetMarket,
    required this.isActive,
    this.aiContent,
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
        id: _parseInt(j['id']),
        productName: j['product_name']?.toString() ?? '',
        price: _parseDouble(j['price']),
        priceFormatted: j['price_formatted']?.toString() ?? '',
        stock: _parseInt(j['stock']),
        imageUrl: j['image_url']?.toString(),
        description: j['description']?.toString(),
        targetMarket: j['target_market']?.toString(),
        isActive: j['is_active'] == null
            ? true
            : j['is_active'] == 1 || j['is_active'] == true,
        aiContent: j['ai_content'] != null
            ? AiContent.fromJson(j['ai_content'])
            : null,
      );
}
