import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/models/document.dart';

class DocumentRepository {
  final SupabaseClient _client;

  DocumentRepository(this._client);

  Future<List<Document>> fetchDocuments({
    String? category,
    String? search,
  }) async {
    var query = _client.from('documents').select();

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }

    final data = await query.order('created_at', ascending: false);
    return data.map<Document>((e) => Document.fromJson(e)).toList();
  }

  Future<Document?> fetchDocument(String id) async {
    final data = await _client
        .from('documents')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Document.fromJson(data);
  }

  Future<Document> createDocument(Map<String, dynamic> payload) async {
    final data = await _client
        .from('documents')
        .insert(payload)
        .select()
        .single();
    return Document.fromJson(data);
  }

  Future<Document> updateDocument(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = await _client
        .from('documents')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return Document.fromJson(data);
  }

  Future<void> deleteDocument(String id) async {
    await _client.from('documents').delete().eq('id', id);
  }
}
