import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/models/product.dart';
import 'package:smartfactory/models/document_link.dart';

class ProductRepository {
  final SupabaseClient _client;

  ProductRepository(this._client);

  Future<List<Product>> fetchProducts({
    String? search,
    String? category,
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client.from('products').select();

    if (isActive != null) query = query.eq('is_active', isActive);
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,code.ilike.%$search%');
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return data.map<Product>((e) => Product.fromJson(e)).toList();
  }

  Future<Product?> fetchProduct(String id) async {
    final data = await _client
        .from('products')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Product.fromJson(data);
  }

  Future<Product> createProduct(Map<String, dynamic> payload) async {
    final data = await _client
        .from('products')
        .insert(payload)
        .select()
        .single();

    return Product.fromJson(data);
  }

  Future<Product> updateProduct(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = await _client
        .from('products')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Product.fromJson(data);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  Future<List<DocumentLink>> fetchDocuments(String productId) async {
    final data = await _client
        .from('document_links')
        .select()
        .eq('entity_type', 'product')
        .eq('entity_id', productId)
        .order('created_at', ascending: false);

    return data.map<DocumentLink>((e) => DocumentLink.fromJson(e)).toList();
  }

  Future<List<String>> fetchCategories() async {
    final data = await _client
        .from('products')
        .select('category')
        .not('category', 'is', null)
        .order('category');

    return data
        .map<String>((e) => e['category'] as String)
        .toSet()
        .toList();
  }
}
