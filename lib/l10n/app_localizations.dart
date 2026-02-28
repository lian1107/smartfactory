import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('zh')];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'智能工厂'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get email;

  /// No description provided for @password.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get password;

  /// No description provided for @loginButton.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get loginButton;

  /// No description provided for @loginFailed.
  ///
  /// In zh, this message translates to:
  /// **'登录失败，请检查邮箱和密码'**
  String get loginFailed;

  /// No description provided for @dashboard.
  ///
  /// In zh, this message translates to:
  /// **'仪表盘'**
  String get dashboard;

  /// No description provided for @workspace.
  ///
  /// In zh, this message translates to:
  /// **'我的工作台'**
  String get workspace;

  /// No description provided for @products.
  ///
  /// In zh, this message translates to:
  /// **'产品管理'**
  String get products;

  /// No description provided for @projects.
  ///
  /// In zh, this message translates to:
  /// **'项目管理'**
  String get projects;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @newProduct.
  ///
  /// In zh, this message translates to:
  /// **'新建产品'**
  String get newProduct;

  /// No description provided for @newProject.
  ///
  /// In zh, this message translates to:
  /// **'新建项目'**
  String get newProject;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @confirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'此操作不可恢复，确认删除吗？'**
  String get confirmDeleteMessage;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get loading;

  /// No description provided for @empty.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get empty;

  /// No description provided for @error.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @search.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In zh, this message translates to:
  /// **'筛选'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get all;

  /// No description provided for @active.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get active;

  /// No description provided for @completed.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get cancelled;

  /// No description provided for @onHold.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get onHold;

  /// No description provided for @overdue.
  ///
  /// In zh, this message translates to:
  /// **'已逾期'**
  String get overdue;

  /// No description provided for @today.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In zh, this message translates to:
  /// **'本周'**
  String get thisWeek;

  /// No description provided for @upcoming.
  ///
  /// In zh, this message translates to:
  /// **'后续'**
  String get upcoming;

  /// No description provided for @noTasks.
  ///
  /// In zh, this message translates to:
  /// **'暂无任务'**
  String get noTasks;

  /// No description provided for @taskTitle.
  ///
  /// In zh, this message translates to:
  /// **'任务标题'**
  String get taskTitle;

  /// No description provided for @taskDescription.
  ///
  /// In zh, this message translates to:
  /// **'任务描述'**
  String get taskDescription;

  /// No description provided for @assignee.
  ///
  /// In zh, this message translates to:
  /// **'负责人'**
  String get assignee;

  /// No description provided for @dueDate.
  ///
  /// In zh, this message translates to:
  /// **'截止日期'**
  String get dueDate;

  /// No description provided for @priority.
  ///
  /// In zh, this message translates to:
  /// **'优先级'**
  String get priority;

  /// No description provided for @status.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get status;

  /// No description provided for @projectName.
  ///
  /// In zh, this message translates to:
  /// **'项目名称'**
  String get projectName;

  /// No description provided for @productName.
  ///
  /// In zh, this message translates to:
  /// **'产品名称'**
  String get productName;

  /// No description provided for @productCode.
  ///
  /// In zh, this message translates to:
  /// **'产品编号'**
  String get productCode;

  /// No description provided for @template.
  ///
  /// In zh, this message translates to:
  /// **'模板'**
  String get template;

  /// No description provided for @selectTemplate.
  ///
  /// In zh, this message translates to:
  /// **'选择模板'**
  String get selectTemplate;

  /// No description provided for @health.
  ///
  /// In zh, this message translates to:
  /// **'健康度'**
  String get health;

  /// No description provided for @kanban.
  ///
  /// In zh, this message translates to:
  /// **'看板'**
  String get kanban;

  /// No description provided for @myTasks.
  ///
  /// In zh, this message translates to:
  /// **'我的任务'**
  String get myTasks;

  /// No description provided for @teamTasks.
  ///
  /// In zh, this message translates to:
  /// **'团队任务'**
  String get teamTasks;

  /// No description provided for @addTask.
  ///
  /// In zh, this message translates to:
  /// **'添加任务'**
  String get addTask;

  /// No description provided for @addComment.
  ///
  /// In zh, this message translates to:
  /// **'添加评论'**
  String get addComment;

  /// No description provided for @comments.
  ///
  /// In zh, this message translates to:
  /// **'评论'**
  String get comments;

  /// No description provided for @documents.
  ///
  /// In zh, this message translates to:
  /// **'文档'**
  String get documents;

  /// No description provided for @associatedProjects.
  ///
  /// In zh, this message translates to:
  /// **'关联项目'**
  String get associatedProjects;

  /// No description provided for @role.
  ///
  /// In zh, this message translates to:
  /// **'角色'**
  String get role;

  /// No description provided for @department.
  ///
  /// In zh, this message translates to:
  /// **'部门'**
  String get department;

  /// No description provided for @userManagement.
  ///
  /// In zh, this message translates to:
  /// **'用户管理'**
  String get userManagement;

  /// No description provided for @adminOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅管理员可访问'**
  String get adminOnly;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
