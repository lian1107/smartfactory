import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/models/quality_record.dart';

class QualityRepository {
  final SupabaseClient _client;

  QualityRepository(this._client);

  Future<QualityRecord> createQualityRecord({
    required DateTime date,
    required String inspectionType,
    required String? productId,
    required int totalQty,
    required int defectQty,
    required String? notes,
    required String createdBy,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final data = await _client
        .from('quality_records')
        .insert({
          'date': dateStr,
          'inspection_type': inspectionType,
          if (productId != null) 'product_id': productId,
          'total_qty': totalQty,
          'defect_qty': defectQty,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'created_by': createdBy,
        })
        .select()
        .single();

    return QualityRecord.fromJson(data);
  }

  Future<List<QualityRecord>> fetchRecentRecords({int limit = 30}) async {
    final data = await _client
        .from('quality_records')
        .select()
        .order('date', ascending: false)
        .limit(limit);

    return data.map<QualityRecord>((e) => QualityRecord.fromJson(e)).toList();
  }
}
