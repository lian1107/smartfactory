# Sprint 2 车间端报表 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 实现 4 个车间端屏幕（生产报工、品质检验、维修记录、来料检验），替代手写纸质报表，数据写入 Supabase。

**Architecture:** 并行推进数据库迁移与 UI；先完成数据层（模型→Repository→Provider），再接入屏幕。每个屏幕用 `ConsumerStatefulWidget` 管理表单状态，通过 Provider 提交数据。

**Tech Stack:** Flutter 3.x, Riverpod 2.x (手写 AsyncNotifier, 无 @riverpod 注解), Supabase Flutter 2.x, go_router, json_annotation (手写 .g.dart)

---

## 背景与约定

### 项目位置
`F:/编程/seuwu/smartfactory/`

### 关键约定（务必遵守）
1. **模型 .g.dart 手写**，不运行 build_runner（已有 .g.dart 文件均为手写）
2. **Provider 无 `@riverpod` 注解**，用直接的 `AsyncNotifier`/`Notifier` + `AsyncNotifierProvider`
3. **导入路径**用 `package:smartfactory/...`（不用相对路径）
4. **深色背景** `Color(0xFF0F172A)` 用于车间屏幕（参考 workshop_home_screen.dart）
5. **大字号输入**（fontSize 32+）方便车间手机操作
6. **参考文件**：
   - 模型：`lib/models/task.dart` + `lib/models/task.g.dart`
   - Repository：`lib/repositories/task_repository.dart`
   - Provider：`lib/providers/task_providers.dart`
   - 车间屏幕风格：`lib/screens/workshop/workshop_home_screen.dart`

### 班次时段规则
```
早班 08:00-12:00 → slots: [8,9], [9,10], [10,11], [11,12]
中班 13:00-17:00 → slots: [13,14], [14,15], [15,16], [16,17]
晚班 18:00-21:00 → slots: [18,19], [19,20], [20,21]
```

### 验证命令
```bash
cd F:/编程/seuwu/smartfactory
flutter analyze
```
每个 Task 完成后运行，无 error 即通过。

---

## Task 1: 数据库迁移 — daily_reports + report_time_slots

**Files:**
- Create: `supabase/migrations/010_daily_reports.sql`

**Step 1: 创建迁移文件**

```sql
-- supabase/migrations/010_daily_reports.sql

-- 生产日报主表
CREATE TABLE IF NOT EXISTS daily_reports (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date          date NOT NULL,
  shift         text NOT NULL CHECK (shift IN ('early', 'mid', 'late')),
  product_id    uuid REFERENCES products(id) ON DELETE SET NULL,
  production_line text,
  created_by    uuid REFERENCES profiles(id) ON DELETE SET NULL,
  status        text NOT NULL DEFAULT 'submitted'
                  CHECK (status IN ('draft', 'submitted')),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- 小时时段明细表
CREATE TABLE IF NOT EXISTS report_time_slots (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id     uuid NOT NULL REFERENCES daily_reports(id) ON DELETE CASCADE,
  slot_start    int NOT NULL,  -- 小时数，如 8 = 08:00
  slot_end      int NOT NULL,  -- 如 9 = 09:00
  planned_qty   int NOT NULL DEFAULT 0,
  actual_qty    int NOT NULL DEFAULT 0,
  defect_qty    int NOT NULL DEFAULT 0,
  downtime_reason text,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- updated_at 触发器（复用已有函数）
CREATE TRIGGER update_daily_reports_updated_at
  BEFORE UPDATE ON daily_reports
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 索引
CREATE INDEX idx_daily_reports_date ON daily_reports(date DESC);
CREATE INDEX idx_daily_reports_created_by ON daily_reports(created_by);
CREATE INDEX idx_report_time_slots_report_id ON report_time_slots(report_id);

-- RLS
ALTER TABLE daily_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_time_slots ENABLE ROW LEVEL SECURITY;

-- daily_reports RLS
CREATE POLICY "leader_and_above_read_reports"
  ON daily_reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'leader')
    )
    OR created_by = auth.uid()
  );

CREATE POLICY "workshop_insert_reports"
  ON daily_reports FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'leader', 'technician', 'qc')
    )
  );

CREATE POLICY "own_update_reports"
  ON daily_reports FOR UPDATE
  USING (created_by = auth.uid());

-- report_time_slots RLS（跟随 daily_reports 权限）
CREATE POLICY "read_slots_via_report"
  ON report_time_slots FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM daily_reports dr
      WHERE dr.id = report_id
      AND (
        dr.created_by = auth.uid()
        OR EXISTS (
          SELECT 1 FROM profiles p
          WHERE p.id = auth.uid()
          AND p.role IN ('admin', 'leader')
        )
      )
    )
  );

CREATE POLICY "insert_slots_via_report"
  ON report_time_slots FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM daily_reports dr
      WHERE dr.id = report_id
      AND dr.created_by = auth.uid()
    )
  );
```

**Step 2: 在 Supabase SQL Editor 中执行**

登录 Supabase → SQL Editor → 粘贴并运行。
确认 Tables 中出现 `daily_reports` 和 `report_time_slots`。

---

## Task 2: 数据库迁移 — quality_records, repair_records, incoming_inspections

**Files:**
- Create: `supabase/migrations/011_quality_records.sql`
- Create: `supabase/migrations/012_repair_records.sql`
- Create: `supabase/migrations/013_incoming_inspections.sql`

**Step 1: 创建 011_quality_records.sql**

```sql
-- supabase/migrations/011_quality_records.sql

CREATE TABLE IF NOT EXISTS quality_records (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date             date NOT NULL,
  inspection_type  text NOT NULL CHECK (inspection_type IN ('full', 'sample')),
  product_id       uuid REFERENCES products(id) ON DELETE SET NULL,
  total_qty        int NOT NULL CHECK (total_qty > 0),
  defect_qty       int NOT NULL DEFAULT 0 CHECK (defect_qty >= 0),
  notes            text,
  created_by       uuid REFERENCES profiles(id) ON DELETE SET NULL,
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_quality_records_date ON quality_records(date DESC);

ALTER TABLE quality_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "read_quality_records"
  ON quality_records FOR SELECT
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'leader')
    )
  );

CREATE POLICY "insert_quality_records"
  ON quality_records FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'leader', 'qc')
    )
  );
```

**Step 2: 创建 012_repair_records.sql**

```sql
-- supabase/migrations/012_repair_records.sql

CREATE TABLE IF NOT EXISTS repair_records (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date              date NOT NULL,
  product_id        uuid REFERENCES products(id) ON DELETE SET NULL,
  fault_types       text[] NOT NULL DEFAULT '{}',
  repair_action     text NOT NULL,
  duration_minutes  int,
  created_by        uuid REFERENCES profiles(id) ON DELETE SET NULL,
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_repair_records_date ON repair_records(date DESC);

ALTER TABLE repair_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "read_repair_records"
  ON repair_records FOR SELECT
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'leader')
    )
  );

CREATE POLICY "insert_repair_records"
  ON repair_records FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid()
      AND role IN ('admin', 'leader', 'technician')
    )
  );
```

**Step 3: 创建 013_incoming_inspections.sql**

```sql
-- supabase/migrations/013_incoming_inspections.sql

CREATE TABLE IF NOT EXISTS incoming_inspections (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date                 date NOT NULL,
  material_name        text NOT NULL,
  supplier             text,
  total_qty            int NOT NULL CHECK (total_qty > 0),
  defect_qty           int NOT NULL DEFAULT 0 CHECK (defect_qty >= 0),
  defect_description   text,
  result               text NOT NULL CHECK (result IN ('pass', 'conditional', 'fail')),
  created_by           uuid REFERENCES profiles(id) ON DELETE SET NULL,
  created_at           timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_incoming_inspections_date ON incoming_inspections(date DESC);

ALTER TABLE incoming_inspections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "read_incoming_inspections"
  ON incoming_inspections FOR SELECT
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'leader')
    )
  );

CREATE POLICY "insert_incoming_inspections"
  ON incoming_inspections FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid()
      AND role IN ('admin', 'leader', 'qc')
    )
  );
```

**Step 4: 在 Supabase SQL Editor 中按顺序执行 3 个文件**

确认 Tables 中出现 `quality_records`、`repair_records`、`incoming_inspections`。

---

## Task 3: 数据模型 — DailyReport + ReportTimeSlot

**Files:**
- Create: `lib/models/daily_report.dart`
- Create: `lib/models/daily_report.g.dart`
- Create: `lib/models/report_time_slot.dart`
- Create: `lib/models/report_time_slot.g.dart`

**Step 1: 创建 daily_report.dart**

```dart
// lib/models/daily_report.dart
import 'package:json_annotation/json_annotation.dart';

part 'daily_report.g.dart';

@JsonSerializable()
class DailyReport {
  final String id;
  final DateTime date;
  final String shift; // 'early' | 'mid' | 'late'
  @JsonKey(name: 'product_id')
  final String? productId;
  @JsonKey(name: 'production_line')
  final String? productionLine;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  final String status; // 'draft' | 'submitted'
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const DailyReport({
    required this.id,
    required this.date,
    required this.shift,
    this.productId,
    this.productionLine,
    this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) =>
      _$DailyReportFromJson(json);
  Map<String, dynamic> toJson() => _$DailyReportToJson(this);

  DailyReport copyWith({
    String? id,
    DateTime? date,
    String? shift,
    String? productId,
    String? productionLine,
    String? createdBy,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DailyReport(
        id: id ?? this.id,
        date: date ?? this.date,
        shift: shift ?? this.shift,
        productId: productId ?? this.productId,
        productionLine: productionLine ?? this.productionLine,
        createdBy: createdBy ?? this.createdBy,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
```

**Step 2: 创建 daily_report.g.dart**

```dart
// lib/models/daily_report.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_report.dart';

DailyReport _$DailyReportFromJson(Map<String, dynamic> json) => DailyReport(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      shift: json['shift'] as String,
      productId: json['product_id'] as String?,
      productionLine: json['production_line'] as String?,
      createdBy: json['created_by'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$DailyReportToJson(DailyReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'shift': instance.shift,
      'product_id': instance.productId,
      'production_line': instance.productionLine,
      'created_by': instance.createdBy,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
```

**Step 3: 创建 report_time_slot.dart**

```dart
// lib/models/report_time_slot.dart
import 'package:json_annotation/json_annotation.dart';

part 'report_time_slot.g.dart';

@JsonSerializable()
class ReportTimeSlot {
  final String id;
  @JsonKey(name: 'report_id')
  final String reportId;
  @JsonKey(name: 'slot_start')
  final int slotStart; // 小时数，如 8 = 08:00
  @JsonKey(name: 'slot_end')
  final int slotEnd;   // 如 9 = 09:00
  @JsonKey(name: 'planned_qty')
  final int plannedQty;
  @JsonKey(name: 'actual_qty')
  final int actualQty;
  @JsonKey(name: 'defect_qty')
  final int defectQty;
  @JsonKey(name: 'downtime_reason')
  final String? downtimeReason;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const ReportTimeSlot({
    required this.id,
    required this.reportId,
    required this.slotStart,
    required this.slotEnd,
    required this.plannedQty,
    required this.actualQty,
    required this.defectQty,
    this.downtimeReason,
    required this.createdAt,
  });

  factory ReportTimeSlot.fromJson(Map<String, dynamic> json) =>
      _$ReportTimeSlotFromJson(json);
  Map<String, dynamic> toJson() => _$ReportTimeSlotToJson(this);
}
```

**Step 4: 创建 report_time_slot.g.dart**

```dart
// lib/models/report_time_slot.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_time_slot.dart';

ReportTimeSlot _$ReportTimeSlotFromJson(Map<String, dynamic> json) =>
    ReportTimeSlot(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      slotStart: (json['slot_start'] as num).toInt(),
      slotEnd: (json['slot_end'] as num).toInt(),
      plannedQty: (json['planned_qty'] as num).toInt(),
      actualQty: (json['actual_qty'] as num).toInt(),
      defectQty: (json['defect_qty'] as num).toInt(),
      downtimeReason: json['downtime_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ReportTimeSlotToJson(ReportTimeSlot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'report_id': instance.reportId,
      'slot_start': instance.slotStart,
      'slot_end': instance.slotEnd,
      'planned_qty': instance.plannedQty,
      'actual_qty': instance.actualQty,
      'defect_qty': instance.defectQty,
      'downtime_reason': instance.downtimeReason,
      'created_at': instance.createdAt.toIso8601String(),
    };
```

**Step 5: 运行分析**
```bash
cd F:/编程/seuwu/smartfactory && flutter analyze lib/models/daily_report.dart lib/models/report_time_slot.dart
```
期望：无 error。

---

## Task 4: 数据模型 — QualityRecord, RepairRecord, IncomingInspection

**Files:**
- Create: `lib/models/quality_record.dart`
- Create: `lib/models/quality_record.g.dart`
- Create: `lib/models/repair_record.dart`
- Create: `lib/models/repair_record.g.dart`
- Create: `lib/models/incoming_inspection.dart`
- Create: `lib/models/incoming_inspection.g.dart`

**Step 1: 创建 quality_record.dart**

```dart
// lib/models/quality_record.dart
import 'package:json_annotation/json_annotation.dart';

part 'quality_record.g.dart';

@JsonSerializable()
class QualityRecord {
  final String id;
  final DateTime date;
  @JsonKey(name: 'inspection_type')
  final String inspectionType; // 'full' | 'sample'
  @JsonKey(name: 'product_id')
  final String? productId;
  @JsonKey(name: 'total_qty')
  final int totalQty;
  @JsonKey(name: 'defect_qty')
  final int defectQty;
  final String? notes;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const QualityRecord({
    required this.id,
    required this.date,
    required this.inspectionType,
    this.productId,
    required this.totalQty,
    required this.defectQty,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  factory QualityRecord.fromJson(Map<String, dynamic> json) =>
      _$QualityRecordFromJson(json);
  Map<String, dynamic> toJson() => _$QualityRecordToJson(this);
}
```

**Step 2: 创建 quality_record.g.dart**

```dart
// lib/models/quality_record.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quality_record.dart';

QualityRecord _$QualityRecordFromJson(Map<String, dynamic> json) =>
    QualityRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      inspectionType: json['inspection_type'] as String,
      productId: json['product_id'] as String?,
      totalQty: (json['total_qty'] as num).toInt(),
      defectQty: (json['defect_qty'] as num).toInt(),
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$QualityRecordToJson(QualityRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'inspection_type': instance.inspectionType,
      'product_id': instance.productId,
      'total_qty': instance.totalQty,
      'defect_qty': instance.defectQty,
      'notes': instance.notes,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
    };
```

**Step 3: 创建 repair_record.dart**

```dart
// lib/models/repair_record.dart
import 'package:json_annotation/json_annotation.dart';

part 'repair_record.g.dart';

@JsonSerializable()
class RepairRecord {
  final String id;
  final DateTime date;
  @JsonKey(name: 'product_id')
  final String? productId;
  @JsonKey(name: 'fault_types')
  final List<String> faultTypes;
  @JsonKey(name: 'repair_action')
  final String repairAction;
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const RepairRecord({
    required this.id,
    required this.date,
    this.productId,
    required this.faultTypes,
    required this.repairAction,
    this.durationMinutes,
    this.createdBy,
    required this.createdAt,
  });

  factory RepairRecord.fromJson(Map<String, dynamic> json) =>
      _$RepairRecordFromJson(json);
  Map<String, dynamic> toJson() => _$RepairRecordToJson(this);
}
```

**Step 4: 创建 repair_record.g.dart**

```dart
// lib/models/repair_record.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repair_record.dart';

RepairRecord _$RepairRecordFromJson(Map<String, dynamic> json) => RepairRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      productId: json['product_id'] as String?,
      faultTypes: (json['fault_types'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      repairAction: json['repair_action'] as String,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$RepairRecordToJson(RepairRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'product_id': instance.productId,
      'fault_types': instance.faultTypes,
      'repair_action': instance.repairAction,
      'duration_minutes': instance.durationMinutes,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
    };
```

**Step 5: 创建 incoming_inspection.dart**

```dart
// lib/models/incoming_inspection.dart
import 'package:json_annotation/json_annotation.dart';

part 'incoming_inspection.g.dart';

@JsonSerializable()
class IncomingInspection {
  final String id;
  final DateTime date;
  @JsonKey(name: 'material_name')
  final String materialName;
  final String? supplier;
  @JsonKey(name: 'total_qty')
  final int totalQty;
  @JsonKey(name: 'defect_qty')
  final int defectQty;
  @JsonKey(name: 'defect_description')
  final String? defectDescription;
  final String result; // 'pass' | 'conditional' | 'fail'
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const IncomingInspection({
    required this.id,
    required this.date,
    required this.materialName,
    this.supplier,
    required this.totalQty,
    required this.defectQty,
    this.defectDescription,
    required this.result,
    this.createdBy,
    required this.createdAt,
  });

  factory IncomingInspection.fromJson(Map<String, dynamic> json) =>
      _$IncomingInspectionFromJson(json);
  Map<String, dynamic> toJson() => _$IncomingInspectionToJson(this);
}
```

**Step 6: 创建 incoming_inspection.g.dart**

```dart
// lib/models/incoming_inspection.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incoming_inspection.dart';

IncomingInspection _$IncomingInspectionFromJson(Map<String, dynamic> json) =>
    IncomingInspection(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      materialName: json['material_name'] as String,
      supplier: json['supplier'] as String?,
      totalQty: (json['total_qty'] as num).toInt(),
      defectQty: (json['defect_qty'] as num).toInt(),
      defectDescription: json['defect_description'] as String?,
      result: json['result'] as String,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$IncomingInspectionToJson(
        IncomingInspection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'material_name': instance.materialName,
      'supplier': instance.supplier,
      'total_qty': instance.totalQty,
      'defect_qty': instance.defectQty,
      'defect_description': instance.defectDescription,
      'result': instance.result,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
    };
```

**Step 7: 运行分析**
```bash
flutter analyze lib/models/quality_record.dart lib/models/repair_record.dart lib/models/incoming_inspection.dart
```

---

## Task 5: Repository 层

**Files:**
- Create: `lib/repositories/report_repository.dart`
- Create: `lib/repositories/quality_repository.dart`
- Create: `lib/repositories/inspection_repository.dart`

**Step 1: 创建 report_repository.dart**

```dart
// lib/repositories/report_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/models/daily_report.dart';
import 'package:smartfactory/models/report_time_slot.dart';

class ReportRepository {
  final SupabaseClient _client;

  ReportRepository(this._client);

  /// 创建日报（主表 + 所有时段明细，事务方式）
  Future<DailyReport> createDailyReport({
    required DateTime date,
    required String shift,
    required String? productId,
    required String createdBy,
    required List<Map<String, dynamic>> slots,
  }) async {
    // 插入主表
    final reportData = await _client
        .from('daily_reports')
        .insert({
          'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'shift': shift,
          if (productId != null) 'product_id': productId,
          'created_by': createdBy,
          'status': 'submitted',
        })
        .select()
        .single();

    final report = DailyReport.fromJson(reportData);

    // 插入时段明细
    final slotPayloads = slots
        .map((s) => {...s, 'report_id': report.id})
        .toList();

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
```

**Step 2: 创建 quality_repository.dart**

```dart
// lib/repositories/quality_repository.dart
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
    final data = await _client
        .from('quality_records')
        .insert({
          'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
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
```

**Step 3: 创建 inspection_repository.dart**

```dart
// lib/repositories/inspection_repository.dart
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
    final data = await _client
        .from('repair_records')
        .insert({
          'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
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
    final data = await _client
        .from('incoming_inspections')
        .insert({
          'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
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
```

**Step 4: 运行分析**
```bash
flutter analyze lib/repositories/
```

---

## Task 6: Providers

**Files:**
- Create: `lib/providers/report_providers.dart`

**Step 1: 创建 report_providers.dart**

```dart
// lib/providers/report_providers.dart
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
      return [];
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
```

**Step 2: 运行分析**
```bash
flutter analyze lib/providers/report_providers.dart
```

---

## Task 7: 生产 Widgets（公共组件）

**Files:**
- Create: `lib/widgets/production/shift_selector.dart`
- Create: `lib/widgets/production/time_slot_card.dart`
- Create: `lib/widgets/production/big_number_field.dart`

**Step 1: 创建 lib/widgets/production/ 目录（创建第一个文件时自动建立）**

**Step 2: 创建 shift_selector.dart**

```dart
// lib/widgets/production/shift_selector.dart
import 'package:flutter/material.dart';
import 'package:smartfactory/config/theme.dart';

enum Shift { early, mid, late }

extension ShiftExt on Shift {
  String get label {
    switch (this) {
      case Shift.early: return '早班';
      case Shift.mid:   return '中班';
      case Shift.late:  return '晚班';
    }
  }

  String get value {
    switch (this) {
      case Shift.early: return 'early';
      case Shift.mid:   return 'mid';
      case Shift.late:  return 'late';
    }
  }

  String get timeRange {
    switch (this) {
      case Shift.early: return '08:00-12:00';
      case Shift.mid:   return '13:00-17:00';
      case Shift.late:  return '18:00-21:00';
    }
  }

  /// 返回该班次的时段列表，每项为 [start, end] 小时数
  List<List<int>> get slots {
    switch (this) {
      case Shift.early: return [[8,9],[9,10],[10,11],[11,12]];
      case Shift.mid:   return [[13,14],[14,15],[15,16],[16,17]];
      case Shift.late:  return [[18,19],[19,20],[20,21]];
    }
  }
}

class ShiftSelector extends StatelessWidget {
  final Shift selected;
  final ValueChanged<Shift> onChanged;

  const ShiftSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Shift.values.map((shift) {
        final isSelected = shift == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(shift),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFF334155),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      shift.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shift.timeRange,
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

**Step 3: 创建 big_number_field.dart**

```dart
// lib/widgets/production/big_number_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 大字号数字输入框，适合车间手机操作
class BigNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool isRequired;

  const BigNumberField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint ?? '0',
            hintStyle: const TextStyle(
              color: Colors.white24,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
          ),
          validator: isRequired
              ? (v) => (v == null || v.isEmpty) ? '请填写$label' : null
              : null,
        ),
      ],
    );
  }
}
```

**Step 4: 创建 time_slot_card.dart**

```dart
// lib/widgets/production/time_slot_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimeSlotFormData {
  final int slotStart;
  final int slotEnd;
  final TextEditingController plannedCtrl;
  final TextEditingController actualCtrl;
  final TextEditingController defectCtrl;
  final TextEditingController noteCtrl;

  TimeSlotFormData({
    required this.slotStart,
    required this.slotEnd,
  })  : plannedCtrl = TextEditingController(),
        actualCtrl = TextEditingController(),
        defectCtrl = TextEditingController(text: '0'),
        noteCtrl = TextEditingController();

  void dispose() {
    plannedCtrl.dispose();
    actualCtrl.dispose();
    defectCtrl.dispose();
    noteCtrl.dispose();
  }

  Map<String, dynamic> toPayload() => {
        'slot_start': slotStart,
        'slot_end': slotEnd,
        'planned_qty': int.tryParse(plannedCtrl.text) ?? 0,
        'actual_qty': int.tryParse(actualCtrl.text) ?? 0,
        'defect_qty': int.tryParse(defectCtrl.text) ?? 0,
        if (noteCtrl.text.isNotEmpty) 'downtime_reason': noteCtrl.text,
      };
}

class TimeSlotCard extends StatelessWidget {
  final TimeSlotFormData data;

  const TimeSlotCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final label =
        '${data.slotStart.toString().padLeft(2, '0')}:00 - ${data.slotEnd.toString().padLeft(2, '0')}:00';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SlotNumberField(
                  label: '计划',
                  controller: data.plannedCtrl,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SlotNumberField(
                  label: '实际',
                  controller: data.actualCtrl,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SlotNumberField(
                  label: '不良',
                  controller: data.defectCtrl,
                  defaultValue: '0',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: data.noteCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 1,
            decoration: InputDecoration(
              hintText: '停线原因 / 异常备注（可选）',
              hintStyle:
                  const TextStyle(color: Colors.white38, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? defaultValue;

  const _SlotNumberField({
    required this.label,
    required this.controller,
    this.defaultValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: defaultValue ?? '-',
            hintStyle: const TextStyle(
              color: Colors.white24,
              fontSize: 22,
            ),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: Color(0xFF3B82F6), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            isDense: true,
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? '必填' : null,
        ),
      ],
    );
  }
}
```

**Step 5: 运行分析**
```bash
flutter analyze lib/widgets/production/
```

---

## Task 8: DailyReportScreen 实现

**Files:**
- Modify: `lib/screens/workshop/daily_report_screen.dart`

**Step 1: 替换 daily_report_screen.dart**

```dart
// lib/screens/workshop/daily_report_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/models/product.dart';
import 'package:smartfactory/providers/project_providers.dart';
import 'package:smartfactory/providers/report_providers.dart';
import 'package:smartfactory/widgets/production/shift_selector.dart';
import 'package:smartfactory/widgets/production/time_slot_card.dart';

class DailyReportScreen extends ConsumerStatefulWidget {
  const DailyReportScreen({super.key});

  @override
  ConsumerState<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends ConsumerState<DailyReportScreen> {
  final _formKey = GlobalKey<FormState>();
  Shift _shift = Shift.early;
  String? _selectedProductId;
  List<TimeSlotFormData> _slots = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _rebuildSlots(Shift.early);
  }

  void _rebuildSlots(Shift shift) {
    // 释放旧 controllers
    for (final s in _slots) {
      s.dispose();
    }
    _slots = shift.slots
        .map((pair) =>
            TimeSlotFormData(slotStart: pair[0], slotEnd: pair[1]))
        .toList();
  }

  @override
  void dispose() {
    for (final s in _slots) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    try {
      await ref.read(dailyReportsProvider.notifier).submit(
            date: DateTime.now(),
            shift: _shift.value,
            productId: _selectedProductId,
            slots: _slots.map((s) => s.toPayload()).toList(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('报工提交成功'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败：$e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text('生产报工'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 日期显示
            Text(
              _formatDate(DateTime.now()),
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // 班次选择
            const Text('选择班次',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            ShiftSelector(
              selected: _shift,
              onChanged: (s) {
                setState(() {
                  _shift = s;
                  _rebuildSlots(s);
                });
              },
            ),
            const SizedBox(height: 20),

            // 产品选择
            const Text('选择产品（可选）',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            productsAsync.when(
              loading: () => const SizedBox(
                height: 48,
                child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF3B82F6), strokeWidth: 2),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (products) => _ProductDropdown(
                products: products,
                value: _selectedProductId,
                onChanged: (id) =>
                    setState(() => _selectedProductId = id),
              ),
            ),
            const SizedBox(height: 24),

            // 时段卡片
            const Text('各时段产量',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ..._slots.map((s) => TimeSlotCard(data: s)),
            const SizedBox(height: 24),

            // 提交按钮
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        '提交报工',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}年${d.month}月${d.day}日  周${['', '一', '二', '三', '四', '五', '六', '日'][d.weekday]}';
}

class _ProductDropdown extends StatelessWidget {
  final List<Product> products;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _ProductDropdown({
    required this.products,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: '不选则不关联产品',
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('-- 不关联产品 --',
              style: TextStyle(color: Colors.white54)),
        ),
        ...products.map((p) => DropdownMenuItem<String>(
              value: p.id,
              child: Text(p.name),
            )),
      ],
      onChanged: onChanged,
    );
  }
}
```

**Step 2: 运行分析**
```bash
flutter analyze lib/screens/workshop/daily_report_screen.dart
```

---

## Task 9: QualityCheckScreen 实现

**Files:**
- Modify: `lib/screens/workshop/quality_check_screen.dart`

**Step 1: 替换 quality_check_screen.dart**

```dart
// lib/screens/workshop/quality_check_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/models/product.dart';
import 'package:smartfactory/providers/project_providers.dart';
import 'package:smartfactory/providers/report_providers.dart';
import 'package:smartfactory/widgets/production/big_number_field.dart';

class QualityCheckScreen extends ConsumerStatefulWidget {
  const QualityCheckScreen({super.key});

  @override
  ConsumerState<QualityCheckScreen> createState() =>
      _QualityCheckScreenState();
}

class _QualityCheckScreenState extends ConsumerState<QualityCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  String _inspectionType = 'full'; // 'full' | 'sample'
  String? _selectedProductId;
  final _totalCtrl = TextEditingController();
  final _defectCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _totalCtrl.dispose();
    _defectCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final total = int.tryParse(_totalCtrl.text) ?? 0;
    final defect = int.tryParse(_defectCtrl.text) ?? 0;

    if (defect > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('不良数量不能大于检验总数'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(qualityRecordsProvider.notifier).submit(
            date: DateTime.now(),
            inspectionType: _inspectionType,
            productId: _selectedProductId,
            totalQty: total,
            defectQty: defect,
            notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('检验记录提交成功'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败：$e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text('品质检验'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 检验类型
            const Text('检验类型',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeButton(
                  label: '全检',
                  selected: _inspectionType == 'full',
                  onTap: () => setState(() => _inspectionType = 'full'),
                ),
                const SizedBox(width: 12),
                _TypeButton(
                  label: '抽检',
                  selected: _inspectionType == 'sample',
                  onTap: () => setState(() => _inspectionType = 'sample'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 产品选择
            const Text('产品（可选）',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            productsAsync.maybeWhen(
              data: (products) => _ProductDropdown(
                products: products,
                value: _selectedProductId,
                onChanged: (id) =>
                    setState(() => _selectedProductId = id),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // 数量
            BigNumberField(label: '检验总数', controller: _totalCtrl),
            const SizedBox(height: 16),
            BigNumberField(
              label: '不良总数',
              controller: _defectCtrl,
              isRequired: false,
            ),
            const SizedBox(height: 16),

            // 备注
            const Text('不良描述（可选）',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '描述不良现象...',
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFF3B82F6), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        '提交检验',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF3B82F6)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF334155),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductDropdown extends StatelessWidget {
  final List<Product> products;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _ProductDropdown({
    required this.products,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: '不选则不关联产品',
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('-- 不关联产品 --',
              style: TextStyle(color: Colors.white54)),
        ),
        ...products.map((p) => DropdownMenuItem<String>(
              value: p.id,
              child: Text(p.name),
            )),
      ],
      onChanged: onChanged,
    );
  }
}
```

**Step 2: 运行分析**
```bash
flutter analyze lib/screens/workshop/quality_check_screen.dart
```

---

## Task 10: RepairLogScreen 实现

**Files:**
- Modify: `lib/screens/workshop/repair_log_screen.dart`

**Step 1: 替换 repair_log_screen.dart**

```dart
// lib/screens/workshop/repair_log_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/models/product.dart';
import 'package:smartfactory/providers/project_providers.dart';
import 'package:smartfactory/providers/report_providers.dart';

const _kFaultTypes = [
  '电气故障',
  '机械故障',
  '外观损伤',
  '软件/固件',
  '物料问题',
  '操作失误',
  '其他',
];

class RepairLogScreen extends ConsumerStatefulWidget {
  const RepairLogScreen({super.key});

  @override
  ConsumerState<RepairLogScreen> createState() => _RepairLogScreenState();
}

class _RepairLogScreenState extends ConsumerState<RepairLogScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProductId;
  final Set<String> _selectedFaultTypes = {};
  final _actionCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _actionCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedFaultTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少选择一种故障类型'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(repairRecordsProvider.notifier).submit(
            date: DateTime.now(),
            productId: _selectedProductId,
            faultTypes: _selectedFaultTypes.toList(),
            repairAction: _actionCtrl.text,
            durationMinutes: int.tryParse(_durationCtrl.text),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('维修记录提交成功'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败：$e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text('维修记录'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 产品
            const Text('产品（可选）',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            productsAsync.maybeWhen(
              data: (products) => DropdownButtonFormField<String>(
                value: _selectedProductId,
                dropdownColor: const Color(0xFF1E293B),
                style:
                    const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '选择产品',
                  hintStyle:
                      const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF334155)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('-- 不关联产品 --',
                        style: TextStyle(color: Colors.white54)),
                  ),
                  ...products.map((p) => DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.name),
                      )),
                ],
                onChanged: (id) =>
                    setState(() => _selectedProductId = id),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // 故障类型
            const Text('故障类型（可多选）',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kFaultTypes.map((type) {
                final selected = _selectedFaultTypes.contains(type);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedFaultTypes.remove(type);
                    } else {
                      _selectedFaultTypes.add(type);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF334155),
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color:
                            selected ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 维修措施
            const Text('维修措施 *',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _actionCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请填写维修措施' : null,
              decoration: InputDecoration(
                hintText: '描述维修过程和处理措施...',
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFF3B82F6), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 维修时长
            const Text('维修时长（分钟，可选）',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(
                    color: Colors.white24, fontSize: 24),
                suffixText: '分钟',
                suffixStyle:
                    const TextStyle(color: Colors.white54, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFF3B82F6), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 12),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        '提交记录',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: 运行分析**
```bash
flutter analyze lib/screens/workshop/repair_log_screen.dart
```

---

## Task 11: IncomingInspectionScreen 实现

**Files:**
- Modify: `lib/screens/workshop/incoming_inspection_screen.dart`

**Step 1: 替换 incoming_inspection_screen.dart**

```dart
// lib/screens/workshop/incoming_inspection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/providers/report_providers.dart';
import 'package:smartfactory/widgets/production/big_number_field.dart';

class IncomingInspectionScreen extends ConsumerStatefulWidget {
  const IncomingInspectionScreen({super.key});

  @override
  ConsumerState<IncomingInspectionScreen> createState() =>
      _IncomingInspectionScreenState();
}

class _IncomingInspectionScreenState
    extends ConsumerState<IncomingInspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _materialCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _defectCtrl = TextEditingController(text: '0');
  final _descCtrl = TextEditingController();
  String _result = 'pass'; // 'pass' | 'conditional' | 'fail'
  bool _submitting = false;

  @override
  void dispose() {
    _materialCtrl.dispose();
    _supplierCtrl.dispose();
    _totalCtrl.dispose();
    _defectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final total = int.tryParse(_totalCtrl.text) ?? 0;
    final defect = int.tryParse(_defectCtrl.text) ?? 0;

    if (defect > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('不良数量不能大于来料总数'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(incomingInspectionsProvider.notifier).submit(
            date: DateTime.now(),
            materialName: _materialCtrl.text.trim(),
            supplier: _supplierCtrl.text.trim().isEmpty
                ? null
                : _supplierCtrl.text.trim(),
            totalQty: total,
            defectQty: defect,
            defectDescription: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            result: _result,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('来料检验提交成功'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败：$e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text('来料检验'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 物料名称
            const Text('物料名称 *',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _materialCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请填写物料名称' : null,
              decoration: _inputDecoration('如：电机、电池、外壳...'),
            ),
            const SizedBox(height: 16),

            // 供应商
            const Text('供应商（可选）',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _supplierCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: _inputDecoration('供应商名称'),
            ),
            const SizedBox(height: 20),

            // 数量
            BigNumberField(label: '来料总数', controller: _totalCtrl),
            const SizedBox(height: 16),
            BigNumberField(
              label: '不良总数',
              controller: _defectCtrl,
              isRequired: false,
            ),
            const SizedBox(height: 16),

            // 不良描述
            const Text('不良描述（可选）',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 3,
              decoration: _inputDecoration('描述不良现象，如：外观划伤、尺寸偏差...'),
            ),
            const SizedBox(height: 20),

            // 检验结论
            const Text('检验结论',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _ResultButton(
                  label: '合格',
                  value: 'pass',
                  selected: _result == 'pass',
                  color: const Color(0xFF10B981),
                  onTap: () => setState(() => _result = 'pass'),
                ),
                const SizedBox(width: 8),
                _ResultButton(
                  label: '条件接收',
                  value: 'conditional',
                  selected: _result == 'conditional',
                  color: const Color(0xFFF59E0B),
                  onTap: () => setState(() => _result = 'conditional'),
                ),
                const SizedBox(width: 8),
                _ResultButton(
                  label: '不合格',
                  value: 'fail',
                  selected: _result == 'fail',
                  color: const Color(0xFFEF4444),
                  onTap: () => setState(() => _result = 'fail'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 拍照占位
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF334155),
                    style: BorderStyle.solid),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      color: Colors.white38, size: 20),
                  SizedBox(width: 8),
                  Text('拍照留证（Sprint 3 实现）',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        '提交检验',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

class _ResultButton extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ResultButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : const Color(0xFF334155),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
```

**Step 2: 全量分析**
```bash
flutter analyze
```
期望：0 errors，warnings 可忽略。

---

## Task 12: 最终验证

**Step 1: 全量分析**
```bash
cd F:/编程/seuwu/smartfactory
flutter analyze
```

**Step 2: 确认路由（检查 router.dart 是否已有 workshop 子路由）**

打开 `lib/config/router.dart`，确认以下路由存在且指向正确 Screen：
```
/workshop/daily-report    → DailyReportScreen
/workshop/quality-check   → QualityCheckScreen
/workshop/repair-log      → RepairLogScreen
/workshop/incoming        → IncomingInspectionScreen
```

如果路由指向旧的占位符 class，需要更新 import 或确认 class 名不变（class 名未变，无需改 router）。

**Step 3: 在 Supabase 运行所有迁移文件（010-013）**

按顺序在 SQL Editor 中执行，确认 5 张新表创建成功。

**Step 4: 启动应用**
```bash
flutter run -d chrome
```
登录后进入车间端，测试 4 个屏幕的提交流程。

---

## 新增文件清单

| 文件 | 类型 |
|------|------|
| `supabase/migrations/010_daily_reports.sql` | 新建 |
| `supabase/migrations/011_quality_records.sql` | 新建 |
| `supabase/migrations/012_repair_records.sql` | 新建 |
| `supabase/migrations/013_incoming_inspections.sql` | 新建 |
| `lib/models/daily_report.dart` | 新建 |
| `lib/models/daily_report.g.dart` | 新建 |
| `lib/models/report_time_slot.dart` | 新建 |
| `lib/models/report_time_slot.g.dart` | 新建 |
| `lib/models/quality_record.dart` | 新建 |
| `lib/models/quality_record.g.dart` | 新建 |
| `lib/models/repair_record.dart` | 新建 |
| `lib/models/repair_record.g.dart` | 新建 |
| `lib/models/incoming_inspection.dart` | 新建 |
| `lib/models/incoming_inspection.g.dart` | 新建 |
| `lib/repositories/report_repository.dart` | 新建 |
| `lib/repositories/quality_repository.dart` | 新建 |
| `lib/repositories/inspection_repository.dart` | 新建 |
| `lib/providers/report_providers.dart` | 新建 |
| `lib/widgets/production/shift_selector.dart` | 新建 |
| `lib/widgets/production/time_slot_card.dart` | 新建 |
| `lib/widgets/production/big_number_field.dart` | 新建 |
| `lib/screens/workshop/daily_report_screen.dart` | 替换占位符 |
| `lib/screens/workshop/quality_check_screen.dart` | 替换占位符 |
| `lib/screens/workshop/repair_log_screen.dart` | 替换占位符 |
| `lib/screens/workshop/incoming_inspection_screen.dart` | 替换占位符 |
