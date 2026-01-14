import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class MessageContextMenu extends StatelessWidget {
  final Widget child;
  final String messageContent;
  final bool isUser;
  final VoidCallback? onRemove;
  final VoidCallback? onSave;
  final VoidCallback? onCopy;

  const MessageContextMenu({
    super.key,
    required this.child,
    required this.messageContent,
    required this.isUser,
    this.onRemove,
    this.onSave,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoContextMenu(
      enableHapticFeedback: true,
      actions: [
        CupertinoContextMenuAction(
          onPressed: () {
            Navigator.pop(context);
            HapticFeedback.lightImpact();
            if (onCopy != null) onCopy!();
          },
          trailingIcon: CupertinoIcons.doc_on_clipboard,
          child: const Text('Copy'),
        ),
        CupertinoContextMenuAction(
          onPressed: () {
            Navigator.pop(context);
            HapticFeedback.lightImpact();
            if (onSave != null) onSave!();
          },
          trailingIcon: CupertinoIcons.book,
          child: const Text('Save to Notes'),
        ),
        if (isUser)
          CupertinoContextMenuAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
              _showRemoveConfirmation(context);
            },
            trailingIcon: CupertinoIcons.delete,
            child: const Text('Remove'),
          ),
      ],
      child: child,
    );
  }

  void _showRemoveConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove Message'),
        content: const Text('Are you sure you want to remove this message?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.heavyImpact();
              if (onRemove != null) onRemove!();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
