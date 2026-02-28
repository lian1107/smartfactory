import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/models/daily_report.dart';
import 'package:smartfactory/models/report_time_slot.dart';

class ReportRepository {
  final SupabaseClient _client;

  ReportRepository(this._client);

  /// 创建日报（主表 + 所有时段明细）
  Future<DailyReport> createDailyReport({
    required DateTime date,
    required String shift,
    required String? productId,
    required String createdBy,
    required List<Map<String, dynamic>> slots,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // 插入主表
    final reportData = await _client
        .from('daily_reports')
        .insert({
          'date': dateStr,
          'shift': shift,
          if (productId != null) 'product_id': productId,
          'created_by': createdBy,
          'status': 'submitted',
        })
        .select()
        .single();

    final report = DailyReport.fromJson(reportData);

    // 插入时段明细
    final slotPayloads =
        slots.map((s) => {...s, 'report_id': report.id}).toList();
    await _client.from('report_time_slots').insert(slotPayloads);

    return report;
  }

  Future<List<DailyReport>> fetchRecentReports({int limit = 30}) async {
    final data = await _client
        .from('daily_reports')
        .select()
        .order('date', ascending: false)
        .limit(limit);

    return data.map<DailyReport>((e) => DailyReport.fromJson(e)).toList();
  }

  Future<List<ReportTimeSlot>> fetchSlotsByReport(String reportId) async {
    final data = await _client
        .from('report_time_slots')
        .select()
        .eq('report_id', reportId)
        .order('slot_start');

    return data
        .map<ReportTimeSlot>((e) => ReportTimeSlot.fromJson(e))
        .toList();
  }
}
