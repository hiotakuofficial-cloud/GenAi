import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: const Text(
          'Hisu AI',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: CupertinoColors.systemBlue,
              child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? Colors.white
                    : const Color(0xFF111111),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.type == MessageType.text
                  ? Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.black : Colors.white,
                        fontSize: 16,
                      ),
                    )
                  : message.type == MessageType.image
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                message.content,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    color: CupertinoColors.systemGrey6,
                                    child: const Center(
                                      child: CupertinoActivityIndicator(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (message.prompt.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                message.prompt,
                                style: TextStyle(
                                  color: isUser ? Colors.white70 : CupertinoColors.secondaryLabel,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 200,
                              height: 150,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.play_circle_fill,
                                size: 50,
                                color: CupertinoColors.systemBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Video: ${message.prompt}',
                              style: TextStyle(
                                color: isUser ? Colors.white70 : CupertinoColors.secondaryLabel,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: CupertinoColors.systemGrey,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Color(0xFF000000),
          ],
          stops: [0.0, 0.7],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showGenerationOptions,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Message Hisu...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? const CupertinoActivityIndicator(color: Colors.black)
                  : const Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.black,
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGenerationOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Generate Content'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showPromptDialog(MessageType.image);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, color: CupertinoColors.systemBlue),
                SizedBox(width: 8),
                Text('Gen Image'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showPromptDialog(MessageType.video);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam, color: CupertinoColors.systemBlue),
                SizedBox(width: 8),
                Text('Gen Video'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showPromptDialog(MessageType type) {
    final TextEditingController promptController = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Generate ${type == MessageType.image ? 'Image' : 'Video'}'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: promptController,
            placeholder: 'Enter your prompt...',
            maxLines: 3,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              if (promptController.text.isNotEmpty) {
                _generateContent(type, promptController.text);
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(
        content: text,
        isUser: true,
        type: MessageType.text,
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await ApiService.sendMessage(text);
      setState(() {
        _messages.add(ChatMessage(
          content: response,
          isUser: false,
          type: MessageType.text,
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          content: 'Sorry, something went wrong. Please try again.',
          isUser: false,
          type: MessageType.text,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _generateContent(MessageType type, String prompt) async {
    setState(() {
      _messages.add(ChatMessage(
        content: prompt,
        isUser: true,
        type: MessageType.text,
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      String content;
      if (type == MessageType.image) {
        content = await ApiService.generateImage(prompt);
      } else {
        content = await ApiService.generateVideo(prompt);
      }

      setState(() {
        _messages.add(ChatMessage(
          content: content,
          isUser: false,
          type: type,
          prompt: prompt,
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          content: 'Failed to generate ${type == MessageType.image ? 'image' : 'video'}. Please try again.',
          isUser: false,
          type: MessageType.text,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final MessageType type;
  final String prompt;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.type,
    this.prompt = '',
  });
}

enum MessageType { text, image, video }
