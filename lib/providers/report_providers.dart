import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfactory/models/daily_report.dart';
import 'package:smartfactory/models/quality_record.dart';
import 'package:smartfactory/models/repair_record.dart';
import 'package:smartfactory/models/incoming_inspection.dart';
import 'package:smartfactory/repositories/report_repository.dart';
import 'package:smartfactory/repositories/quality_repository.dart';
import 'package:smartfactory/repositories/inspection_repository.dart';
import 'package:smartfactory/providers/auth_provider.dart';

// ─── Repositories ─────────────────────────────────────────────
final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(supabaseClientProvider)),
);

final qualityRepositoryProvider = Provider<QualityRepository>(
  (ref) => QualityRepository(ref.watch(supabaseClientProvider)),
);

final inspectionRepositoryProvider = Provider<InspectionRepository>(
  (ref) => InspectionRepository(ref.watch(supabaseClientProvider)),
);

// ─── Daily Reports ────────────────────────────────────────────
class _DailyReportsNotifier extends AsyncNotifier<List<DailyReport>> {
  @override
  Future<List<DailyReport>> build() =>
      ref.watch(reportRepositoryProvider).fetchRecentReports();

  Future<void> submit({
    required DateTime date,
    required String shift,
    required String? productId,
    required List<Map<String, dynamic>> slots,
  }) async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) throw Exception('未登录');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(reportRepositoryProvider).createDailyReport(
            date: date,
            shift: shift,
            productId: productId,
            createdBy: user.id,
            slots: slots,
          );
      return ref.read(reportRepositoryProvider).fetchRecentReports();
    });
  }
}

final dailyReportsProvider =
    AsyncNotifierProvider<_DailyReportsNotifier, List<DailyReport>>(
  _DailyReportsNotifier.new,
);

// ─── Quality Records ──────────────────────────────────────────
class _QualityRecordsNotifier extends AsyncNotifier<List<QualityRecord>> {
  @override
  Future<List<QualityRecord>> build() =>
      ref.watch(qualityRepositoryProvider).fetchRecentRecords();

  Future<void> submit({
    required DateTime date,
    required String inspectionType,
    required String? productId,
    required int totalQty,
    required int defectQty,
    required String? notes,
  }) async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) throw Exception('未登录');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(qualityRepositoryProvider).createQualityRecord(
            date: date,
            inspectionType: inspectionType,
            productId: productId,
            totalQty: totalQty,
            defectQty: defectQty,
            notes: notes,
            createdBy: user.id,
          );
      return ref.read(qualityRepositoryProvider).fetchRecentRecords();
    });
  }
}

final qualityRecordsProvider =
    AsyncNotifierProvider<_QualityRecordsNotifier, List<QualityRecord>>(
  _QualityRecordsNotifier.new,
);

// ─── Repair Records ───────────────────────────────────────────
class _RepairRecordsNotifier extends AsyncNotifier<List<RepairRecord>> {
  @override
  Future<List<RepairRecord>> build() async => [];

  Future<void> submit({
    required DateTime date,
    required String? productId,
    required List<String> faultTypes,
    required String repairAction,
    required int? durationMinutes,
  }) async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) throw Exception('未登录');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inspectionRepositoryProvider).createRepairRecord(
            date: date,
            productId: productId,
            faultTypes: faultTypes,
            repairAction: repairAction,
            durationMinutes: durationMinutes,
            createdBy: user.id,
          );
      return <RepairRecord>[];
    });
  }
}

final repairRecordsProvider =
    AsyncNotifierProvider<_RepairRecordsNotifier, List<RepairRecord>>(
  _RepairRecordsNotifier.new,
);

// ─── Incoming Inspections ─────────────────────────────────────
class _IncomingInspectionsNotifier
    extends AsyncNotifier<List<IncomingInspection>> {
  @override
  Future<List<IncomingInspection>> build() =>
      ref.watch(inspectionRepositoryProvider).fetchRecentInspections();

  Future<void> submit({
    required DateTime date,
    required String materialName,
    required String? supplier,
    required int totalQty,
    required int defectQty,
    required String? defectDescription,
    required String result,
  }) async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) throw Exception('未登录');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(inspectionRepositoryProvider)
          .createIncomingInspection(
            date: date,
            materialName: materialName,
            supplier: supplier,
            totalQty: totalQty,
            defectQty: defectQty,
            defectDescription: defectDescription,
            result: result,
            createdBy: user.id,
          );
      return ref.read(inspectionRepositoryProvider).fetchRecentInspections();
    });
  }
}

final incomingInspectionsProvider = AsyncNotifierProvider<
    _IncomingInspectionsNotifier, List<IncomingInspection>>(
  _IncomingInspectionsNotifier.new,
);
