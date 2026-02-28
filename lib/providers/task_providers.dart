import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfactory/models/task.dart';
import 'package:smartfactory/models/task_comment.dart';
import 'package:smartfactory/repositories/task_repository.dart';
import 'package:smartfactory/providers/auth_provider.dart';

// ─── Task repository ─────────────────────────────────────────
final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(supabaseClientProvider)),
);

// ─── Tasks by project ────────────────────────────────────────
class _ProjectTasksNotifier
    extends FamilyAsyncNotifier<List<Task>, String> {
  @override
  Future<List<Task>> build(String arg) =>
      ref.watch(taskRepositoryProvider).fetchTasksByProject(arg);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(taskRepositoryProvider).fetchTasksByProject(arg),
    );
  }

  Future<Task> createTask({
    required String phaseId,
    required String title,
    String? description,
    String? assigneeId,
    String priority = 'medium',
    DateTime? dueDate,
  }) async {
    final tasks = state.valueOrNull ?? [];
    final phaseTasks = tasks.where((t) => t.phaseId == phaseId).toList();

    final task = await ref.read(taskRepositoryProvider).createTask({
      'project_id': arg,
      'phase_id': phaseId,
      'title': title,
      if (description != null) 'description': description,
      if (assigneeId != null) 'assignee_id': assigneeId,
      'priority': priority,
      if (dueDate != null)
        'due_date': dueDate.toIso8601String().substring(0, 10),
      'order_index': phaseTasks.length,
    });
    ref.invalidateSelf();
    return task;
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    await ref.read(taskRepositoryProvider).updateTask(taskId, updates);
    ref.invalidateSelf();
  }

  Future<void> moveTask({
    required String taskId,
    required String newPhaseId,
    required int newOrderIndex,
  }) async {
    await ref.read(taskRepositoryProvider).moveTask(
          taskId: taskId,
          newPhaseId: newPhaseId,
          newOrderIndex: newOrderIndex,
        );
    ref.invalidateSelf();
  }

  Future<void> deleteTask(String taskId) async {
    await ref.read(taskRepositoryProvider).deleteTask(taskId);
    ref.invalidateSelf();
  }

  void optimisticMove({
    required String taskId,
    required String newPhaseId,
    required int newOrderIndex,
  }) {
    final tasks = state.valueOrNull;
    if (tasks == null) return;

    final updated = tasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(phaseId: newPhaseId, orderIndex: newOrderIndex);
      }
      return t;
    }).toList();

    state = AsyncData(updated);

    ref
        .read(taskRepositoryProvider)
        .moveTask(
          taskId: taskId,
          newPhaseId: newPhaseId,
          newOrderIndex: newOrderIndex,
        )
        .catchError((_) => ref.invalidateSelf());
  }
}

final projectTasksProvider =
    AsyncNotifierProvider.family<_ProjectTasksNotifier, List<Task>, String>(
  _ProjectTasksNotifier.new,
);

// ─── My tasks ────────────────────────────────────────────────
class _MyTasksNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    final user = ref.watch(supabaseClientProvider).auth.currentUser;
    if (user == null) return [];
    return ref.watch(taskRepositoryProvider).fetchMyTasks(user.id);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    await ref.read(taskRepositoryProvider).updateTask(taskId, updates);
    ref.invalidateSelf();
  }
}

final myTasksProvider =
    AsyncNotifierProvider<_MyTasksNotifier, List<Task>>(
  _MyTasksNotifier.new,
);

// ─── Task comments ───────────────────────────────────────────
class _TaskCommentsNotifier
    extends FamilyAsyncNotifier<List<TaskComment>, String> {
  @override
  Future<List<TaskComment>> build(String arg) =>
      ref.watch(taskRepositoryProvider).fetchComments(arg);

  Future<void> addComment(String content) async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) return;

    await ref.read(taskRepositoryProvider).addComment(
          taskId: arg,
          authorId: user.id,
          content: content,
        );
    ref.invalidateSelf();
  }

  Future<void> deleteComment(String commentId) async {
    await ref.read(taskRepositoryProvider).deleteComment(commentId);
    ref.invalidateSelf();
  }
}

final taskCommentsProvider =
    AsyncNotifierProvider.family<_TaskCommentsNotifier, List<TaskComment>, String>(
  _TaskCommentsNotifier.new,
);
