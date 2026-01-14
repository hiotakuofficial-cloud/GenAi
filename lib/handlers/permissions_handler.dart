import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

class PermissionsHandler {
  static Future<bool> requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.request();
    if (status.isDenied) {
      status = await Permission.manageExternalStorage.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    var status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<void> showPermissionDialog(BuildContext context, String message) async {
    if (Platform.isIOS) {
      return showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Permission Required'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              isDefaultAction: true,
              child: const Text('Settings'),
            ),
          ],
        ),
      );
    } else {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        ),
      );
    }
  }
}
