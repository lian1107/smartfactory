import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/providers/auth_provider.dart';
import 'package:smartfactory/providers/task_providers.dart';

/// Subscribe to task changes for a specific project
final taskRealtimeSubscriptionProvider =
    StreamProvider.family.autoDispose<void, String>((ref, projectId) {
  final client = ref.watch(supabaseClientProvider);

  final channel = client.channel('tasks:$projectId');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'tasks',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'project_id',
      value: projectId,
    ),
    callback: (payload) {
      ref.invalidate(projectTasksProvider(projectId));
    },
  );

  channel.subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
  });

  return const Stream.empty();
});

/// Subscribe to task changes for the current user
final myTaskRealtimeSubscriptionProvider =
    StreamProvider.autoDispose<void>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return const Stream.empty();

  final channel = client.channel('my_tasks:${user.id}');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'tasks',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'assignee_id',
      value: user.id,
    ),
    callback: (payload) {
      ref.invalidate(myTasksProvider);
    },
  );

  channel.subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
  });

  return const Stream.empty();
});
