import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/models/document.dart';
import 'package:smartfactory/repositories/document_repository.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(Supabase.instance.client);
});

typedef _DocListParams = ({String? category, String? search});

final documentsProvider =
    FutureProvider.family<List<Document>, _DocListParams>(
  (ref, params) async {
    final repo = ref.watch(documentRepositoryProvider);
    return repo.fetchDocuments(
      category: params.category,
      search: params.search,
    );
  },
);

final documentDetailProvider =
    FutureProvider.family<Document?, String>((ref, id) async {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.fetchDocument(id);
});
