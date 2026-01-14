import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import '../handlers/permissions_handler.dart';
import '../handlers/notification_handler.dart';
import 'dart:io';

class DownloadScreen extends StatefulWidget {
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
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    if (widget.type == 'video') {
      _initializeVideo();
    }
  }

  void _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      print('Video initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _checkPermissions() async {
    // Check storage permission
    bool hasStoragePermission = await PermissionsHandler.requestStoragePermission();
    if (!hasStoragePermission) {
      _showPermissionDialog('Storage permission is required to download files.');
      return;
    }

    // Check notification permission
    bool hasNotificationPermission = await PermissionsHandler.requestNotificationPermission();
    if (!hasNotificationPermission) {
      _showPermissionDialog('Notification permission is required to show download progress.');
    }
  }

  void _showPermissionDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
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
          widget.type == 'video' ? 'Video Preview' : 'Image Preview',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Hero(
                tag: '${widget.type}_${widget.url}',
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
                    child: widget.type == 'video'
                        ? _buildVideoPlayer()
                        : Image.network(
                            widget.url,
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
                if (widget.prompt.isNotEmpty) ...[
                  Text(
                    widget.prompt,
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

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        width: double.infinity,
        height: 300,
        color: Colors.grey[900],
        child: const Center(
          child: CupertinoActivityIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        width: double.infinity,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            // Play/Pause overlay
            if (!_isPlaying)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            // Video controls
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(_videoController!.value.position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Expanded(
                      child: Slider(
                        value: _videoController!.value.position.inSeconds.toDouble(),
                        max: _videoController!.value.duration.inSeconds.toDouble(),
                        onChanged: (value) {
                          _videoController!.seekTo(Duration(seconds: value.toInt()));
                        },
                        activeColor: Colors.white,
                        inactiveColor: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    Text(
                      _formatDuration(_videoController!.value.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
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
      Directory directory;
      if (Platform.isAndroid) {
        // Use DCIM/hisu/ folder for better user access
        directory = Directory('/storage/emulated/0/DCIM/hisu');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Create filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = widget.type == 'image' ? 'jpg' : 'mp4';
      final fileName = '${widget.type}_$timestamp.$extension';
      final filePath = '${directory.path}/$fileName';

        // Start download with progress
        final request = http.Request('GET', Uri.parse(widget.url));
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
                title: 'Downloading ${widget.type}...',
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
            type: widget.type,
          );
          
          // Show success snackbar with location
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.type.toUpperCase()} downloaded successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Open Gallery',
                textColor: Colors.white,
                onPressed: () => _openGallery(),
              ),
            ),
          );
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

  void _openGallery() async {
    try {
      if (Platform.isAndroid) {
        // Open gallery app
        final uri = Uri.parse('content://media/external/images/media');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          // Fallback to file manager
          final uri2 = Uri.parse('content://com.android.externalstorage.documents/document/primary%3ADCIM%2Fhisu');
          if (await canLaunchUrl(uri2)) {
            await launchUrl(uri2);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open gallery'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _shareFile() async {
    try {
      final List<String> messages = [
        "Just created this incredible ${widget.type} with Hisu AI! 🎨 This AI assistant is absolutely amazing - it transforms ideas into reality in seconds. Want to experience the magic of AI creativity? Try Hisu AI today! #HisuAI #AICreativity",
        "Look what Hisu AI just made for me! 😍 This ${widget.type} is exactly what I imagined. Hisu is like having a creative genius at your fingertips - fast, intelligent, and incredibly intuitive. Ready to unleash your creativity? Get Hisu AI now! #HisuAI #Innovation", 
        "Mind blown by what Hisu AI can do! ✨ This stunning ${widget.type} was created in just moments. The app is seriously next-level - it's like having superpowers for creativity. Ready to create something extraordinary? Download Hisu AI! #HisuAI #CreativeAI"
      ];
      
      final randomMessage = messages[DateTime.now().millisecond % messages.length];
      await Share.share('$randomMessage\n\n${widget.url}');
    } catch (e) {
      // Handle error
    }
  }
}
