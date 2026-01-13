import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

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
                      onTap: () => _downloadFile(),
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

  void _downloadFile() async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      // Handle error
    }
  }

  void _shareFile() async {
    try {
      final List<String> messages = [
        "🎨 Just created this amazing ${type} with Hisu AI! ✨ This AI is absolutely incredible - it brings your wildest ideas to life in seconds! 🚀 Want to create something magical too? Try Hisu AI now! 💫 #HisuAI #AIArt #Creative",
        "🔥 OMG! Look what Hisu AI just made for me! 😍 This ${type} is pure perfection! Hisu is like having a creative genius in your pocket - super fast, super smart, and totally addictive! 🎯 Download Hisu AI and unleash your creativity! ⚡ #HisuAI #Innovation",
        "✨ Mind = BLOWN! 🤯 Hisu AI just turned my imagination into reality with this stunning ${type}! This app is seriously next-level - it's like magic but real! 🪄 Ready to create something extraordinary? Get Hisu AI and join the creative revolution! 🌟 #HisuAI #Future"
      ];
      
      final randomMessage = messages[DateTime.now().millisecond % messages.length];
      await Share.share('$randomMessage\n\n$url');
    } catch (e) {
      // Handle error
    }
  }
}
