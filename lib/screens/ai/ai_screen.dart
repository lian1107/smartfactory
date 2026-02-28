import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/config/theme.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _projectSummary;
  String? _productionSummary;
  bool _projectLoading = false;
  bool _productionLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _analyzeProjects() async {
    setState(() => _projectLoading = true);
    try {
      final client = Supabase.instance.client;
      final projects = await client
          .from('projects')
          .select('id, name, status, deadline, description')
          .limit(20);

      final tasks = await client
          .from('tasks')
          .select('id, status, project_id')
          .limit(100);

      final taskList = tasks as List;
      final result = await client.functions.invoke(
        'ai-analyze',
        body: {
          'type': 'project',
          'data': {
            'projects': projects,
            'task_summary': {
              'total': taskList.length,
              'done':
                  taskList.where((t) => t['status'] == 'done').length,
              'overdue':
                  taskList.where((t) => t['status'] == 'overdue').length,
            },
          },
        },
      );
      final summary =
          result.data['summary'] as String? ?? '暂无分析结果';
      setState(() => _projectSummary = summary);
    } catch (e) {
      setState(
          () => _projectSummary = 'AI 分析暂时不可用，请检查网络或联系管理员。');
    } finally {
      setState(() => _projectLoading = false);
    }
  }

  Future<void> _analyzeProduction() async {
    setState(() => _productionLoading = true);
    try {
      final client = Supabase.instance.client;
      final reports = await client
          .from('daily_reports')
          .select('date, shift, total_output, defect_count')
          .order('date', ascending: false)
          .limit(30);

      final quality = await client
          .from('quality_records')
          .select('inspection_date, result, defect_count')
          .order('inspection_date', ascending: false)
          .limit(30);

      final result = await client.functions.invoke(
        'ai-analyze',
        body: {
          'type': 'production',
          'data': {
            'recent_reports': reports,
            'recent_quality': quality,
          },
        },
      );
      final summary =
          result.data['summary'] as String? ?? '暂无分析结果';
      setState(() => _productionSummary = summary);
    } catch (e) {
      setState(
          () => _productionSummary = 'AI 分析暂时不可用，请检查网络或联系管理员。');
    } finally {
      setState(() => _productionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 分析'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '项目分析'),
            Tab(text: '生产分析'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AnalysisTab(
            title: '项目分析',
            description: '分析项目完成率、逾期任务和风险项目，生成 AI 洞察报告。',
            summary: _projectSummary,
            loading: _projectLoading,
            onAnalyze: _analyzeProjects,
            emptyIcon: Icons.folder_outlined,
          ),
          _AnalysisTab(
            title: '生产分析',
            description: '分析近期产量趋势、不良率和高频故障，生成 AI 洞察报告。',
            summary: _productionSummary,
            loading: _productionLoading,
            onAnalyze: _analyzeProduction,
            emptyIcon: Icons.factory_outlined,
          ),
        ],
      ),
    );
  }
}

class _AnalysisTab extends StatelessWidget {
  final String title;
  final String description;
  final String? summary;
  final bool loading;
  final VoidCallback onAnalyze;
  final IconData emptyIcon;

  const _AnalysisTab({
    required this.title,
    required this.description,
    required this.summary,
    required this.loading,
    required this.onAnalyze,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : onAnalyze,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow, size: 18),
                    label: Text(loading ? '分析中...' : '生成分析'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (summary != null) ...[
          const SizedBox(height: 16),
          Card(
            color: AppColors.primaryLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'AI 洞察',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    summary!,
                    style: const TextStyle(
                      height: 1.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (summary == null && !loading) ...[
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(emptyIcon, size: 64, color: AppColors.textDisabled),
                const SizedBox(height: 12),
                const Text(
                  '点击「生成分析」查看 AI 洞察',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
