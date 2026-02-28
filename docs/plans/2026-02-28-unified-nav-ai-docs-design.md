# 统一导航 + AI 分析 + 文档模块 — 设计文档

**日期：** 2026-02-28
**状态：** 已确认

---

## 一、背景与目标

当前应用按角色分成两套 UI（WorkshopShell 车间端 / AppScaffold 管理端），导致：
- Admin 看不到车间模块
- 车间人员看不到项目/产品

目标：**统一一套界面**，所有角色看相同导航，权限只区分可编辑/只读。同时新增 AI 分析和文档两个模块。

---

## 二、导航结构（所有角色相同）

```
仪表盘          /                       Icons.dashboard_rounded
工作台          /workspace              Icons.work_rounded
项目            /projects               Icons.folder_rounded
生产 ▶          (可展开分组)            Icons.factory_rounded
  ├ 生产报表    /workshop/daily-report
  ├ 品质检验    /workshop/quality
  ├ 来料检验    /workshop/incoming
  └ 维修记录    /workshop/repair
AI 分析         /ai                     Icons.auto_awesome_rounded
文档            /docs                   Icons.description_rounded
产品            /products               Icons.inventory_2_rounded
设置            /settings               Icons.settings_rounded
```

「生产」是可折叠分组：
- 点击展开/收起子项
- 当前路由匹配子项时自动展开并高亮
- 子项缩进显示，图标较小

---

## 三、架构变更

### 3.1 删除 WorkshopShell

`lib/widgets/workshop/workshop_shell.dart` 退役删除。

### 3.2 路由变更（`lib/config/router.dart`）

- 删除 `_isWorkshopRole` 和角色重定向逻辑
- 删除 `ShellRoute(WorkshopShell)` 块
- 将所有 `/workshop/*` 路由移入 `ShellRoute(AppScaffold)` 下
- 新增路由：`/ai`、`/docs`、`/docs/new`、`/docs/:id`
- 登录后所有角色统一跳转 `/`

### 3.3 AppScaffold 导航变更（`lib/widgets/common/app_scaffold.dart`）

新增 `_NavGroup` 数据结构支持可展开分组：

```dart
class _NavGroup {
  final String label;
  final IconData icon;
  final List<_NavItem> children;
}
```

导航列表改为混合类型（`_NavItem` 平铺 + `_NavGroup` 可展开），展开状态用 `AnimatedContainer` 动画。

删除 `_workshopOfficeNavItems` 和 `_navItemsFor(role)` 逻辑，所有角色使用同一份导航。

---

## 四、车间表单改浅色主题

**涉及文件：**
- `lib/screens/workshop/daily_report_screen.dart`
- `lib/screens/workshop/quality_check_screen.dart`
- `lib/screens/workshop/repair_log_screen.dart`
- `lib/screens/workshop/incoming_inspection_screen.dart`

**变更规则：**

| 旧值（深色）         | 新值（浅色）              |
|---------------------|--------------------------|
| `Color(0xFF0F172A)` | `Colors.transparent` / 页面背景 |
| `Color(0xFF1E293B)` | `Colors.white` / `AppColors.surface` |
| `Color(0xFF334155)` | `AppColors.border`        |
| `Color(0xFF94A3B8)` | `AppColors.textSecondary` |
| `Colors.white` (文字)| `AppColors.textPrimary`   |
| `Colors.white70`    | `AppColors.textSecondary` |

输入框改用标准 `InputDecoration`（无需手动指定 fillColor/border）。

---

## 五、AI 分析模块

### 5.1 顶级页面 `/ai`

两个 Tab：
- **项目分析**：项目完成率趋势、逾期任务统计、风险项目列表 + AI 自然语言总结
- **生产分析**：产量趋势折线图、不良率趋势、高频故障类型 + AI 自然语言总结

### 5.2 嵌入各模块

- **项目详情页**（`/projects/:id`）：新增「AI 分析」区块，点击「生成分析」按钮后展示当前项目进度风险
- **生产模块**各表单页顶部：「AI 洞察」卡片（折叠默认），显示最近记录的趋势摘要

### 5.3 技术实现

```
Flutter → Supabase Edge Function → Claude API (claude-haiku-4-5)
```

- API Key 存在 Supabase Secrets，不暴露客户端
- Edge Function 接收 `{ type, data }` 请求，返回 `{ summary: String }`
- Flutter 侧用 `SupabaseClient.functions.invoke('ai-analyze', body: {...})`
- 模型：日常分析用 `claude-haiku-4-5`（快+省成本），复杂洞察用 `claude-sonnet-4-6`

---

## 六、文档模块

### 6.1 数据库表 `documents`

```sql
id          uuid PK
title       text NOT NULL
description text
type        text NOT NULL  -- 'feishu' | 'file' | 'note'
url         text           -- feishu 链接
file_path   text           -- Supabase Storage 路径
content     text           -- 在线笔记 markdown 内容
category    text           -- '作业指导书' | '质量标准' | '设备手册' | '其他'
tags        text[]
created_by  uuid REFERENCES profiles(id)
created_at  timestamptz DEFAULT now()
updated_at  timestamptz DEFAULT now()
```

### 6.2 页面结构

- `/docs` — 文档列表（按分类过滤 + 搜索）
- `/docs/new` — 新建文档（选类型 → 填写对应字段）
- `/docs/:id` — 文档详情/查看

### 6.3 三种文档类型 UI

**飞书链接卡片：**
```
📄 Q1 品质检验标准 v2.0
   质量标准 · 飞书文档
   最后更新：张三 · 3天前
   [ 在飞书中打开 ↗ ]
```
点击「在飞书中打开」→ `url_launcher` 在新 Tab 打开飞书 URL

**上传文件：** Supabase Storage，支持 PDF/图片，点击下载/新 Tab 预览

**在线笔记：** 简单 `TextField` 多行，支持 markdown 渲染（`flutter_markdown` 包）

---

## 七、权限控制

| 角色 | 项目/产品 创建/编辑/删除 | 文档 创建/编辑 | 车间表单提交 | 用户角色管理 |
|------|------------------------|----------------|-------------|-------------|
| admin | ✅ | ✅ | ✅ | ✅ |
| leader | 只读 | 只读 | ✅ | ❌ |
| qc | 只读 | 只读 | ✅ | ❌ |
| technician | 只读 | 只读 | ✅ | ❌ |

实现：全局 `canEdit(String? role) => role == 'admin'`，在各屏幕的新建/编辑按钮处判断。

---

## 八、角色标签修正

设置页 `_UserTile` 下拉框标签：

| 旧 | 新 |
|----|-----|
| 项目负责人 | 产线组长 |
| 质检员 | 品质员 |
| 技术员 | 维修技术员 |

---

## 九、范围外（留后续 Sprint）

- 离线同步（Drift）
- 图片上传（Supabase Storage）— 文档模块文件上传除外
- 推送通知
- 不良代码库
- 维修历史记录查询
- 生产数据汇总看板（管理端查看生产报表的图表页）
