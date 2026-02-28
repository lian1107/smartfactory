# SmartFactory - Sprint 1

智能工厂管理系统 Web + Android 应用

## 快速启动

### 1. 前置条件

- Flutter SDK ≥ 3.3.0（需手动安装并加入 PATH）
- Supabase 项目（已有实例）
- Android Studio / VS Code + Flutter 插件

### 2. 初始化 Flutter 项目（首次运行）

```bash
cd D:\AI编程\seuwu
# 创建 Flutter 项目骨架（生成 android/ios/web 平台文件）
flutter create smartfactory --org com.sewu --platforms android,ios,web
# 注意：此命令会覆盖部分文件，运行后需将 lib/ 目录的代码复制回来
```

> **推荐方式**：先在其他目录运行 `flutter create`，然后将 `android/`、`ios/`、`web/`、`pubspec.lock` 复制到本项目目录。

### 3. 配置 Supabase

编辑 `.env` 文件（已在 .gitignore 中排除）：

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### 4. 执行数据库迁移

在 Supabase Dashboard → SQL Editor 中，按顺序执行：

```
supabase/migrations/001_profiles_and_auth.sql
supabase/migrations/002_phase_templates.sql
supabase/migrations/003_project_templates.sql
supabase/migrations/004_products.sql
supabase/migrations/005_projects_and_phases.sql
supabase/migrations/006_tasks.sql
supabase/migrations/007_activity_logs.sql
supabase/migrations/008_defect_codes.sql
supabase/migrations/009_rls_policies.sql
supabase/migrations/seed.sql        ← 预置数据
```

### 5. 安装依赖

```bash
cd smartfactory
flutter pub get
```

### 6. 运行开发版

```bash
# Web
flutter run -d chrome

# Android 模拟器
flutter run -d emulator-5554

# 列出可用设备
flutter devices
```

### 7. 构建发布版

```bash
# Web
flutter build web --release

# Android APK
flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk
```

## 项目结构

```
smartfactory/
├── lib/
│   ├── main.dart               # 入口
│   ├── app.dart                # MaterialApp + GoRouter
│   ├── config/
│   │   ├── router.dart         # 路由表 + 登录守卫
│   │   ├── theme.dart          # Material 3 主题
│   │   ├── constants.dart      # 全局常量
│   │   └── supabase_config.dart
│   ├── models/                 # 数据模型 + JSON 序列化
│   ├── repositories/           # Supabase CRUD 封装
│   ├── providers/              # Riverpod 状态管理
│   ├── screens/                # 功能页面
│   │   ├── auth/               # 登录
│   │   ├── dashboard/          # 仪表盘
│   │   ├── workspace/          # 我的工作台
│   │   ├── products/           # 产品管理
│   │   ├── projects/           # 项目管理（看板）
│   │   └── settings/           # 设置
│   ├── widgets/
│   │   ├── common/             # 通用组件
│   │   ├── project/            # 看板相关组件
│   │   └── dashboard/          # 仪表盘组件
│   └── utils/                  # 工具函数
├── supabase/migrations/        # SQL 迁移文件
├── .env                        # Supabase 密钥（不提交 Git）
└── pubspec.yaml
```

## 路由

| 路径 | 页面 | 权限 |
|------|------|------|
| `/login` | 登录 | 公开 |
| `/` | 仪表盘 | 已登录 |
| `/workspace` | 我的工作台 | 已登录 |
| `/products` | 产品列表 | 已登录 |
| `/products/new` | 新建产品 | admin/leader |
| `/products/:id` | 产品详情 | 已登录 |
| `/projects` | 项目列表 | 已登录 |
| `/projects/new` | 新建项目 | admin/leader |
| `/projects/:id` | 项目看板 | 已登录 |
| `/settings` | 设置 | 已登录 |

## 用户角色

| 角色 | 权限 |
|------|------|
| `admin` | 所有操作，用户管理 |
| `leader` | 创建/管理项目和产品 |
| `qc` | 查看，任务状态更新 |
| `technician` | 查看，更新自己的任务 |
