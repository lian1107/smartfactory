# Sprint 2 车间端设计文档

> **日期**: 2026-02-28
> **Sprint**: Sprint 2 — 车间端报表数字化
> **方案**: B（UI 先行 + 数据库并行）

---

## 一、范围

替代车间现有手写报表，实现 4 个车间端屏幕的数字化录入。

**包含**：
- 生产报工（产线组长）
- 品质检验（QC）
- 维修记录（维修技术员）
- 来料检验（QC）
- 对应数据库表结构（Supabase 迁移）
- 数据模型 + Repository + Provider 层

**不包含**（留 Sprint 3）：
- 管理端生产视图（production/ 目录）
- 离线同步（Drift）
- 图片上传（Storage）
- 推送通知

---

## 二、班次与时段规则

| 班次 | 时间 | 小时时段 |
|------|------|---------|
| 早班 | 08:00–12:00 | 8-9, 9-10, 10-11, 11-12（4段）|
| 中班 | 13:00–17:00 | 13-14, 14-15, 15-16, 16-17（4段）|
| 晚班 | 18:00–21:00 | 18-19, 19-20, 20-21（3段）|

每个时段录入：**计划产量 + 实际产量 + 不良总数 + 停线原因/备注**

---

## 三、数据库设计

### 3.1 daily_reports（生产日报主表）
```sql
id uuid PK
date date NOT NULL
shift text NOT NULL  -- 'early' | 'mid' | 'late'
product_id uuid REFERENCES products(id)
production_line text
created_by uuid REFERENCES profiles(id)
status text DEFAULT 'submitted'  -- 'draft' | 'submitted'
created_at timestamptz DEFAULT now()
updated_at timestamptz DEFAULT now()
```

### 3.2 report_time_slots（小时时段明细）
```sql
id uuid PK
report_id uuid REFERENCES daily_reports(id) ON DELETE CASCADE
slot_start int NOT NULL  -- 小时数，如 8 表示 8:00
slot_end int NOT NULL    -- 如 9 表示 9:00
planned_qty int NOT NULL DEFAULT 0
actual_qty int NOT NULL DEFAULT 0
defect_qty int NOT NULL DEFAULT 0
downtime_reason text     -- 停线原因/异常备注
created_at timestamptz DEFAULT now()
```

### 3.3 quality_records（品质检验）
```sql
id uuid PK
date date NOT NULL
inspection_type text NOT NULL  -- 'full' | 'sample'
product_id uuid REFERENCES products(id)
total_qty int NOT NULL
defect_qty int NOT NULL DEFAULT 0
notes text
created_by uuid REFERENCES profiles(id)
created_at timestamptz DEFAULT now()
```

### 3.4 repair_records（维修记录）
```sql
id uuid PK
date date NOT NULL
product_id uuid REFERENCES products(id)
fault_type text NOT NULL  -- 预设类型
repair_action text NOT NULL
duration_minutes int
created_by uuid REFERENCES profiles(id)
created_at timestamptz DEFAULT now()
```

### 3.5 incoming_inspections（来料检验）
```sql
id uuid PK
date date NOT NULL
material_name text NOT NULL
supplier text
total_qty int NOT NULL
defect_qty int NOT NULL DEFAULT 0
defect_description text
result text NOT NULL  -- 'pass' | 'conditional' | 'fail'
created_by uuid REFERENCES profiles(id)
created_at timestamptz DEFAULT now()
```

### 3.6 RLS 策略
- leader/qc/technician 可写入各自对应的表
- admin/leader 可读取所有记录
- 普通成员只能读取自己创建的记录

---

## 四、屏幕 UI 设计

### 4.1 生产报工（DailyReportScreen）

```
┌────────────────────────────────┐
│  生产报工          2026-02-28  │
├────────────────────────────────┤
│  产品：[下拉选择产品]           │
│  班次：[早班] [中班] [晚班]     │
├────────────────────────────────┤
│  ┌──────────────────────────┐  │
│  │ 8:00 - 9:00              │  │
│  │ 计划 [___]  实际 [___]   │  │
│  │ 不良 [___]               │  │
│  │ 备注 [停线/异常说明...]   │  │
│  └──────────────────────────┘  │
│  ┌──────────────────────────┐  │
│  │ 9:00 - 10:00             │  │
│  │ ...                      │  │
│  └──────────────────────────┘  │
│  （按班次显示 3-4 个时段卡片）   │
├────────────────────────────────┤
│  [        提交报工        ]    │
└────────────────────────────────┘
```

- 数字输入用大字号（48sp），方便车间手机操作
- 班次切换时时段列表自动更新
- 备注为可选项，其余字段必填

### 4.2 品质检验（QualityCheckScreen）

```
┌────────────────────────────────┐
│  品质检验          2026-02-28  │
├────────────────────────────────┤
│  产品：[下拉选择]              │
│  检验类型：[全检] [抽检]       │
├────────────────────────────────┤
│  检验总数   [    大数字    ]   │
│  不良总数   [    大数字    ]   │
│  不良描述   [多行文字输入  ]   │
├────────────────────────────────┤
│  [        提交检验        ]    │
└────────────────────────────────┘
```

### 4.3 维修记录（RepairLogScreen）

```
┌────────────────────────────────┐
│  维修记录          2026-02-28  │
├────────────────────────────────┤
│  产品：[下拉选择]              │
│  故障类型（预设按钮，可多选）:  │
│  [电气故障] [机械故障] [外观]   │
│  [软件故障] [其他]             │
├────────────────────────────────┤
│  维修措施 [多行文字输入]        │
│  维修时长 [___] 分钟           │
├────────────────────────────────┤
│  [        提交记录        ]    │
└────────────────────────────────┘
```

### 4.4 来料检验（IncomingInspectionScreen）

```
┌────────────────────────────────┐
│  来料检验          2026-02-28  │
├────────────────────────────────┤
│  物料名称 [文字输入]           │
│  供应商   [文字输入]           │
├────────────────────────────────┤
│  来料数量 [大数字]             │
│  不良数量 [大数字]             │
│  不良描述 [多行文字]           │
├────────────────────────────────┤
│  检验结论：                    │
│  [合格] [条件接收] [不合格]    │
│  拍照 [占位，Sprint 3 实现]    │
├────────────────────────────────┤
│  [        提交检验        ]    │
└────────────────────────────────┘
```

---

## 五、代码层结构

### 新增文件清单

**数据库迁移** (`supabase/migrations/`)：
- `010_daily_reports.sql`
- `011_quality_records.sql`
- `012_repair_records.sql`
- `013_incoming_inspections.sql`
- `014_rls_updates.sql`

**数据模型** (`lib/models/`)：
- `daily_report.dart` + `daily_report.g.dart`
- `report_time_slot.dart` + `report_time_slot.g.dart`
- `quality_record.dart` + `quality_record.g.dart`
- `repair_record.dart` + `repair_record.g.dart`
- `incoming_inspection.dart` + `incoming_inspection.g.dart`

**Repository** (`lib/repositories/`)：
- `report_repository.dart`
- `quality_repository.dart`
- `inspection_repository.dart`

**Providers** (`lib/providers/`)：
- `report_providers.dart`

**Widgets** (`lib/widgets/production/`)：
- `number_input_pad.dart` — 大数字输入
- `time_slot_card.dart` — 时段卡片
- `shift_selector.dart` — 班次选择器

**屏幕** (`lib/screens/workshop/`)：
- `daily_report_screen.dart` — 替换占位符
- `quality_check_screen.dart` — 替换占位符
- `repair_log_screen.dart` — 替换占位符
- `incoming_inspection_screen.dart` — 替换占位符

---

## 六、实现顺序

```
阶段 1（并行）：
  A. 数据库迁移 010-014
  B. 车间屏幕 UI（静态假数据）

阶段 2：
  数据模型 + .g.dart 手写
  Repository 层（Supabase CRUD）
  Providers（AsyncNotifier）

阶段 3：
  屏幕接入真实数据（替换假数据）
  表单验证 + 错误处理
  提交成功反馈

阶段 4（可选，Sprint 3）：
  管理端生产视图
  历史记录查询
  离线支持
```

---

## 七、预设数据

### 故障类型（repair_records.fault_type）
- 电气故障、机械故障、外观损伤、软件/固件、物料问题、操作失误、其他

### 检验类型
- full（全检）、sample（抽检）

### 来料检验结论
- pass（合格）、conditional（条件接收）、fail（不合格）
