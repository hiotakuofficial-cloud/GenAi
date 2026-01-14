import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

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
          trailingIcon: CupertinoIcons.doc_on_clipboard_fill,
          child: const Text('Copy'),
        ),
        CupertinoContextMenuAction(
          onPressed: () {
            Navigator.pop(context);
            HapticFeedback.lightImpact();
            if (onSave != null) onSave!();
          },
          trailingIcon: CupertinoIcons.bookmark_fill,
          child: const Text('Save'),
        ),
        CupertinoContextMenuAction(
          onPressed: () {
            Navigator.pop(context);
            HapticFeedback.lightImpact();
            _shareMessage(context);
          },
          trailingIcon: CupertinoIcons.share,
          child: const Text('Share'),
        ),
        if (isUser)
          CupertinoContextMenuAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
              _showRemoveConfirmation(context);
            },
            trailingIcon: CupertinoIcons.delete_solid,
            child: const Text('Remove'),
          ),
      ],
      child: child,
    );
  }

  void _shareMessage(BuildContext context) {
    HapticFeedback.lightImpact();
  }

  void _showRemoveConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: CupertinoAlertDialog(
            title: const Text(
              'Remove Message',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'This message will be permanently removed from your chat history.',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                  height: 1.4,
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  HapticFeedback.heavyImpact();
                  if (onRemove != null) onRemove!();
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
