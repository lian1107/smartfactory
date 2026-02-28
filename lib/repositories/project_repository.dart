import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/models/project.dart';
import 'package:smartfactory/models/project_phase.dart';
import 'package:smartfactory/models/project_template.dart';
import 'package:smartfactory/models/phase_template.dart';

class ProjectRepository {
  final SupabaseClient _client;

  ProjectRepository(this._client);

  Future<List<Project>> fetchProjects({
    String? status,
    String? search,
    String? ownerId,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client.from('projects').select();

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (ownerId != null) query = query.eq('owner_id', ownerId);
    if (search != null && search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return data.map<Project>((e) => Project.fromJson(e)).toList();
  }

  Future<Project?> fetchProject(String id) async {
    final data = await _client
        .from('projects')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Project.fromJson(data);
  }

  Future<Project> createProject(Map<String, dynamic> payload) async {
    final data = await _client
        .from('projects')
        .insert(payload)
        .select()
        .single();

    return Project.fromJson(data);
  }

  Future<Project> updateProject(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = await _client
        .from('projects')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Project.fromJson(data);
  }

  Future<void> deleteProject(String id) async {
    await _client.from('projects').delete().eq('id', id);
  }

  // ─── Project Phases ─────────────────────────────────────────

  Future<List<ProjectPhase>> fetchPhases(String projectId) async {
    final data = await _client
        .from('project_phases')
        .select()
        .eq('project_id', projectId)
        .order('order_index');

    return data.map<ProjectPhase>((e) => ProjectPhase.fromJson(e)).toList();
  }

  Future<ProjectPhase> createPhase(Map<String, dynamic> payload) async {
    final data = await _client
        .from('project_phases')
        .insert(payload)
        .select()
        .single();

    return ProjectPhase.fromJson(data);
  }

  Future<ProjectPhase> updatePhase(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = await _client
        .from('project_phases')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return ProjectPhase.fromJson(data);
  }

  /// Create phases from a template's phase_ids list
  Future<List<ProjectPhase>> createPhasesFromTemplate(
    String projectId,
    ProjectTemplate template,
    List<PhaseTemplate> allPhaseTemplates,
  ) async {
    final phaseMap = {for (final p in allPhaseTemplates) p.id: p};
    final payloads = <Map<String, dynamic>>[];

    for (var i = 0; i < template.phaseIds.length; i++) {
      final phaseId = template.phaseIds[i];
      final pt = phaseMap[phaseId];
      if (pt == null) continue;
      payloads.add({
        'project_id': projectId,
        'template_id': phaseId,
        'name': pt.name,
        'description': pt.description,
        'order_index': i,
        'color': pt.color,
      });
    }

    if (payloads.isEmpty) return [];

    final data = await _client
        .from('project_phases')
        .insert(payloads)
        .select();

    return data.map<ProjectPhase>((e) => ProjectPhase.fromJson(e)).toList();
  }

  // ─── Templates ─────────────────────────────────────────────

  Future<List<ProjectTemplate>> fetchProjectTemplates() async {
    final data = await _client
        .from('project_templates')
        .select()
        .order('is_default', ascending: false);

    return data.map<ProjectTemplate>((e) => ProjectTemplate.fromJson(e)).toList();
  }

  Future<List<PhaseTemplate>> fetchPhaseTemplates() async {
    final data = await _client
        .from('phase_templates')
        .select()
        .order('default_order');

    return data.map<PhaseTemplate>((e) => PhaseTemplate.fromJson(e)).toList();
  }
}
