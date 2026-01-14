import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../handlers/permissions_handler.dart';
import '../handlers/notification_handler.dart';
import 'dart:io';

class DownloadScreen extends StatelessWidget {
  final String url;
  final String type; // 'image' or 'video'
  final String prompt;

  const DownloadScreen({
    super.key,
    required this.url,
    required this.type,
    required this.prompt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          type == 'video' ? 'Video Preview' : 'Image Preview',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Hero(
                tag: '${type}_$url',
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: type == 'video'
                        ? Container(
                            width: double.infinity,
                            height: 300,
                            color: Colors.grey[900],
                            child: const Icon(
                              Icons.play_circle_fill,
                              size: 80,
                              color: Colors.white,
                            ),
                          )
                        : Image.network(
                            url,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 300,
                                color: Colors.grey[900],
                                child: const Center(
                                  child: CupertinoActivityIndicator(color: Colors.white),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (prompt.isNotEmpty) ...[
                  Text(
                    prompt,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.download,
                      label: 'Download',
                      onTap: () => _downloadFile(context),
                    ),
                    _buildActionButton(
                      icon: Icons.share,
                      label: 'Share',
                      onTap: () => _shareFile(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadFile(BuildContext context) async {
    try {
      // Request storage permission
      bool hasStoragePermission = await PermissionsHandler.requestStoragePermission();
      if (!hasStoragePermission) {
        await PermissionsHandler.showPermissionDialog(
          context, 
          'Storage permission is required to download files.'
        );
        return;
      }

      // Request notification permission
      bool hasNotificationPermission = await PermissionsHandler.requestNotificationPermission();
      if (!hasNotificationPermission) {
        await PermissionsHandler.showPermissionDialog(
          context, 
          'Notification permission is required to show download progress.'
        );
        return;
      }

      final notificationId = DateTime.now().millisecond;
      
      // Get download directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        // Create filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = type == 'image' ? 'jpg' : 'mp4';
        final fileName = '${type}_$timestamp.$extension';
        final filePath = '${directory.path}/$fileName';

        // Start download with progress
        final request = http.Request('GET', Uri.parse(url));
        final response = await request.send();
        
        if (response.statusCode == 200) {
          final contentLength = response.contentLength ?? 0;
          final file = File(filePath);
          final sink = file.openWrite();
          
          int downloaded = 0;
          
          await response.stream.listen((chunk) async {
            sink.add(chunk);
            downloaded += chunk.length;
            
            if (contentLength > 0) {
              final progress = (downloaded / contentLength * 100).round();
              final speed = (downloaded / 1024).round(); // KB
              
              await NotificationHandler.showProgressNotification(
                id: notificationId,
                title: 'Downloading ${type}...',
                body: '$progress% • ${speed}KB downloaded',
                progress: downloaded,
                maxProgress: contentLength,
              );
            }
          }).asFuture();
          
          await sink.close();
          
          // Show completion notification
          await NotificationHandler.showCompletedNotification(
            id: notificationId,
            fileName: fileName,
            type: type,
          );
          
          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${type.toUpperCase()} downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download failed!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareFile() async {
    try {
      final List<String> messages = [
        "Just created this incredible ${type} with Hisu AI! 🎨 This AI assistant is absolutely amazing - it transforms ideas into reality in seconds. Want to experience the magic of AI creativity? Try Hisu AI today! #HisuAI #AICreativity",
        "Look what Hisu AI just made for me! 😍 This ${type} is exactly what I imagined. Hisu is like having a creative genius at your fingertips - fast, intelligent, and incredibly intuitive. Ready to unleash your creativity? Get Hisu AI now! #HisuAI #Innovation", 
        "Mind blown by what Hisu AI can do! ✨ This stunning ${type} was created in just moments. The app is seriously next-level - it's like having superpowers for creativity. Ready to create something extraordinary? Download Hisu AI! #HisuAI #CreativeAI"
      ];
      
      final randomMessage = messages[DateTime.now().millisecond % messages.length];
      await Share.share('$randomMessage\n\n$url');
    } catch (e) {
      // Handle error
    }
  }
}
