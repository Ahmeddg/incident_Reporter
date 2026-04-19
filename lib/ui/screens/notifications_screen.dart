import 'package:flutter/material.dart';
import 'package:incident_reporter/core/models/app_notification.dart';
import 'package:incident_reporter/core/services/mock_emergency_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MockEmergencyService service = MockEmergencyService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: <Widget>[
          TextButton(
            onPressed: service.markAllNotificationsRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<AppNotification>>(
        valueListenable: service.notifications,
        builder: (BuildContext context, List<AppNotification> items, _) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No notifications yet.'),
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final AppNotification item = items[index];
              return ListTile(
                leading: Icon(
                  item.isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: item.isRead ? Colors.grey : const Color(0xFFB35C00),
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                subtitle: Text(item.message),
                trailing: Text(
                  '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
