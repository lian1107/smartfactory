import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/models/repair_record.dart';
import 'package:smartfactory/models/incoming_inspection.dart';

class InspectionRepository {
  final SupabaseClient _client;

  InspectionRepository(this._client);

  Future<RepairRecord> createRepairRecord({
    required DateTime date,
    required String? productId,
    required List<String> faultTypes,
    required String repairAction,
    required int? durationMinutes,
    required String createdBy,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final data = await _client
        .from('repair_records')
        .insert({
          'date': dateStr,
          if (productId != null) 'product_id': productId,
          'fault_types': faultTypes,
          'repair_action': repairAction,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
          'created_by': createdBy,
        })
        .select()
        .single();

    return RepairRecord.fromJson(data);
  }

  Future<IncomingInspection> createIncomingInspection({
    required DateTime date,
    required String materialName,
    required String? supplier,
    required int totalQty,
    required int defectQty,
    required String? defectDescription,
    required String result,
    required String createdBy,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final data = await _client
        .from('incoming_inspections')
        .insert({
          'date': dateStr,
          'material_name': materialName,
          if (supplier != null && supplier.isNotEmpty) 'supplier': supplier,
          'total_qty': totalQty,
          'defect_qty': defectQty,
          if (defectDescription != null && defectDescription.isNotEmpty)
            'defect_description': defectDescription,
          'result': result,
          'created_by': createdBy,
        })
        .select()
        .single();

    return IncomingInspection.fromJson(data);
  }

  Future<List<IncomingInspection>> fetchRecentInspections(
      {int limit = 30}) async {
    final data = await _client
        .from('incoming_inspections')
        .select()
        .order('date', ascending: false)
        .limit(limit);

    return data
        .map<IncomingInspection>((e) => IncomingInspection.fromJson(e))
        .toList();
  }
}
