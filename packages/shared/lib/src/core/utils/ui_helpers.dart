import 'package:flutter/material.dart';

import '../../data/models/app_models.dart';

extension UiHelpers on BuildContext {
  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> confirm({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel, style: TextStyle(color: danger ? Theme.of(ctx).colorScheme.error : null)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

IconData iconForMessageType(MessageType type) {
  switch (type) {
    case MessageType.text:
      return Icons.chat_bubble_outline;
    case MessageType.image:
      return Icons.image_outlined;
    case MessageType.video:
      return Icons.videocam_outlined;
    case MessageType.document:
      return Icons.description_outlined;
    case MessageType.voice:
      return Icons.mic_none;
    case MessageType.location:
      return Icons.location_on_outlined;
  }
}

IconData iconForNotification(String kind) {
  switch (kind) {
    case 'message':
      return Icons.chat_outlined;
    case 'group':
      return Icons.groups_outlined;
    case 'security':
      return Icons.shield_outlined;
    case 'subscription':
      return Icons.workspace_premium_outlined;
    default:
      return Icons.notifications_none;
  }
}
