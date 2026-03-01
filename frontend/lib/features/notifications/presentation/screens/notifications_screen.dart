import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifications = state.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('No hay notificaciones recientes'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(n.title),
                  subtitle: Text(n.body),
                  trailing: Text(
                    '${n.createdAt.toLocal()}'.split('.').first,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  onTap: () {
                    if (n.alarmId != null) {
                      context.push('/alarms');
                    }
                  },
                );
              },
              separatorBuilder: (_, __) => const Divider(),
              itemCount: notifications.length,
            ),
    );
  }
}
