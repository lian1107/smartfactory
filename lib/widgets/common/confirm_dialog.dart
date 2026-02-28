import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = '确认',
    this.cancelLabel = '取消',
    this.isDestructive = false,
  });

  /// Show confirm dialog and return true if confirmed
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = '确认',
    String cancelLabel = '取消',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
