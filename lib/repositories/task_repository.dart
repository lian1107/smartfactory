import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/models/task.dart';
import 'package:smartfactory/models/task_comment.dart';

class TaskRepository {
  final SupabaseClient _client;

  TaskRepository(this._client);

  Future<List<Task>> fetchTasksByProject(String projectId) async {
    final data = await _client
        .from('tasks')
        .select()
        .eq('project_id', projectId)
        .order('order_index');

    return data.map<Task>((e) => Task.fromJson(e)).toList();
  }

  Future<List<Task>> fetchTasksByPhase(String phaseId) async {
    final data = await _client
        .from('tasks')
        .select()
        .eq('phase_id', phaseId)
        .order('order_index');

    return data.map<Task>((e) => Task.fromJson(e)).toList();
  }

  Future<List<Task>> fetchMyTasks(String userId) async {
    final data = await _client
        .from('tasks')
        .select()
        .eq('assignee_id', userId)
        .neq('status', 'done')
        .order('due_date', ascending: true, nullsFirst: false);

    return data.map<Task>((e) => Task.fromJson(e)).toList();
  }

  Future<Task?> fetchTask(String id) async {
    final data = await _client
        .from('tasks')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Task.fromJson(data);
  }

  Future<Task> createTask(Map<String, dynamic> payload) async {
    final data = await _client
        .from('tasks')
        .insert(payload)
        .select()
        .single();

    return Task.fromJson(data);
  }

  Future<Task> updateTask(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = await _client
        .from('tasks')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Task.fromJson(data);
  }

  Future<Task> moveTask({
    required String taskId,
    required String newPhaseId,
    required int newOrderIndex,
  }) async {
    return updateTask(taskId, {
      'phase_id': newPhaseId,
      'order_index': newOrderIndex,
    });
  }

  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }

  /// Reorder tasks within a phase by updating order_index in batch
  Future<void> reorderTasks(
    List<({String id, int orderIndex})> updates,
  ) async {
    for (final update in updates) {
      await _client
          .from('tasks')
          .update({'order_index': update.orderIndex})
          .eq('id', update.id);
    }
  }

  // ─── Comments ───────────────────────────────────────────────

  Future<List<TaskComment>> fetchComments(String taskId) async {
    final data = await _client
        .from('task_comments')
        .select()
        .eq('task_id', taskId)
        .order('created_at');

    return data.map<TaskComment>((e) => TaskComment.fromJson(e)).toList();
  }

  Future<TaskComment> addComment({
    required String taskId,
    required String authorId,
    required String content,
  }) async {
    final data = await _client
        .from('task_comments')
        .insert({
          'task_id': taskId,
          'author_id': authorId,
          'content': content,
        })
        .select()
        .single();

    return TaskComment.fromJson(data);
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('task_comments').delete().eq('id', commentId);
  }
}
