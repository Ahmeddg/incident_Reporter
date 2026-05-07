import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:incident_reporter/core/models/app_notification.dart';
import 'package:incident_reporter/ui/controllers/emergency_controller.dart';

class NotificationsScreen extends GetView<EmergencyController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: <Widget>[
          TextButton(
            onPressed: controller.markAllNotificationsRead,
            child: const Text('Mark read'),
          ),
        ],
      ),
      body: Obx(
        () {
          final List<AppNotification> items = controller.notifications;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F3F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF16697A),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final AppNotification item = items[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.isRead
                        ? const Color(0xFFE1E7EC)
                        : const Color(0xFFFFD9A8),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: item.isRead
                            ? const Color(0xFFF1F4F6)
                            : const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.isRead
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                        color:
                            item.isRead ? Colors.grey : const Color(0xFFB35C00),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: item.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w900,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Color(0xFF637381),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.message,
                            style: const TextStyle(color: Color(0xFF46545C)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
