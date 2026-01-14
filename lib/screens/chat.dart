import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../components/download.dart';
import '../components/typewriter_text.dart';
import '../components/thinking_animation.dart';
import '../components/message_context_menu.dart';
import '../components/history_drawer.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  MessageType _currentMode = MessageType.text;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _drawerController;
  late Animation<Offset> _drawerSlideAnimation;
  late Animation<Offset> _chatSlideAnimation;
  bool _hasText = false;
  
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  
  String? _currentSessionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // Main chat interface
          SlideTransition(
            position: _chatSlideAnimation,
            child: Column(
              children: [
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFF000000),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Hamburger menu button
                        GestureDetector(
                          onTap: _toggleDrawer,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Icon(
                              _isDrawerOpen ? CupertinoIcons.xmark : CupertinoIcons.line_horizontal_3,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        // Title
                        Expanded(
                          child: Center(
                            child: Text(
                              'Hisu AI',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 56), // Balance the hamburger button
                      ],
                    ),
                  ),
                ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Flexible(child: ThinkingAnimation()),
                      ],
                    ),
                  );
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    ),
    
    // History Drawer
    SlideTransition(
      position: _drawerSlideAnimation,
      child: HistoryDrawer(
        onNewChat: _startNewChat,
        onLoadHistory: _loadHistorySession,
      ),
    ),
    
    // Overlay to close drawer
    if (_isDrawerOpen)
      GestureDetector(
        onTap: _toggleDrawer,
        child: Container(
          color: Colors.black.withOpacity(0.3),
        ),
      ),
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
          Flexible(
            child: MessageContextMenu(
              messageContent: message.content,
              isUser: isUser,
              onCopy: () => _copyMessage(message.content),
              onSave: () => _saveToNotes(message.content),
              onRemove: isUser ? () => _removeMessage(message) : null,
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
                    ? message.isUser 
                        ? Text(
                            message.content,
                            style: TextStyle(
                              color: isUser ? Colors.black : Colors.white,
                              fontSize: 16,
                            ),
                          )
                        : TypewriterText(
                            text: message.content,
                            style: TextStyle(
                              color: isUser ? Colors.black : Colors.white,
                              fontSize: 16,
                            ),
                            speed: const Duration(milliseconds: 30),
                          )
                  : message.type == MessageType.image
                      ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => DownloadScreen(
                                  url: message.content,
                                  type: 'image',
                                  prompt: message.prompt,
                                ),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return Hero(
                                    tag: 'image_${message.content}',
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'image_${message.content}',
                            child: Column(
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
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => DownloadScreen(
                                  url: message.content,
                                  type: 'video',
                                  prompt: message.prompt,
                                ),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return Hero(
                                    tag: 'video_${message.content}',
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, 1.0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'video_${message.content}',
                            child: Column(
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
                ),
            ),
          ),
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
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _getHintText(),
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (value) => _sendMessage(value),
                    ),
                  ),
                  GestureDetector(
                    onTap: _hasText 
                        ? () => _sendMessage(_messageController.text)
                        : _startVoiceInput,
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _isLoading
                          ? const CupertinoActivityIndicator(color: Colors.black)
                          : Icon(
                              _hasText 
                                  ? Icons.keyboard_arrow_up 
                                  : (_isListening ? Icons.stop : Icons.mic),
                              color: _isListening ? Colors.red : Colors.black,
                              size: 20,
                            ),
                    ),
                  ),
                ],
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
              _setGenerationMode(MessageType.image);
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
              _setGenerationMode(MessageType.video);
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

  void _startVoiceInput() async {
    if (!_speechEnabled) return;
    
    if (_isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      setState(() {
        _isListening = true;
      });
      
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _messageController.text = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  void _setGenerationMode(MessageType mode) {
    setState(() {
      _currentMode = mode;
    });
  }

  String _getHintText() {
    switch (_currentMode) {
      case MessageType.image:
        return 'Describe image to generate...';
      case MessageType.video:
        return 'Describe video to generate...';
      default:
        return 'Message Hisu...';
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final message = text.trim();
    final mode = _currentMode;
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        content: message,
        isUser: true,
        type: MessageType.text,
      ));
      _isLoading = true;
      _currentMode = MessageType.text; // Reset to text mode
    });

    _scrollToBottom();

    try {
      String response;
      if (mode == MessageType.image) {
        response = await ApiService.generateImage(message);
        setState(() {
          _messages.add(ChatMessage(
            content: response,
            isUser: false,
            type: MessageType.image,
            prompt: message,
          ));
        });
      } else if (mode == MessageType.video) {
        response = await ApiService.generateVideo(message);
        setState(() {
          _messages.add(ChatMessage(
            content: response,
            isUser: false,
            type: MessageType.video,
            prompt: message,
          ));
        });
      } else {
        response = await ApiService.sendMessage(message, sessionId: _currentSessionId);
        setState(() {
          _messages.add(ChatMessage(
            content: response,
            isUser: false,
            type: MessageType.text,
          ));
        });
      }
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
      
      // Save chat history
      await HistoryService.saveSessionMessages(_currentSessionId, _messages);
    }
  }



  void _loadChatHistory() async {
    try {
      final history = await ApiService.loadChatHistory();
      setState(() {
        _messages.clear();
        for (var msg in history) {
          _messages.add(ChatMessage(
            content: msg['content'] ?? '',
            isUser: msg['role'] == 'user',
            type: MessageType.text,
          ));
        }
      });
      _scrollToBottom();
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Drawer animation controller
    _drawerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _drawerSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    ));
    _chatSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.7, 0.0),
    ).animate(CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    ));
    
    _messageController.addListener(() {
      setState(() {
        _hasText = _messageController.text.trim().isNotEmpty;
      });
    });
    
    _initSpeech();
    _loadChatHistory();
    _generateSessionId();
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message copied to clipboard'),
        backgroundColor: const Color(0xFF007AFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveToNotes(String content) {
    HapticFeedback.mediumImpact();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Save to Notes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This message will be saved to your notes app.'),
            const SizedBox(height: 10),
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                content.length > 100 ? '${content.substring(0, 100)}...' : content,
                style: const TextStyle(fontSize: 14),
                softWrap: true,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              // Here you would integrate with notes app or save locally
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Message saved to notes'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeMessage(ChatMessage message) {
    HapticFeedback.heavyImpact();
    
    setState(() {
      _messages.remove(message);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message removed'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _messages.add(message);
            });
          },
        ),
      ),
    );
  }

  void _generateSessionId() {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
    
    if (_isDrawerOpen) {
      _drawerController.forward();
    } else {
      _drawerController.reverse();
    }
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _isDrawerOpen = false;
    });
    _drawerController.reverse();
    _generateSessionId();
  }

  void _loadHistorySession(String sessionId) async {
    final messages = await HistoryService.getSessionMessages(sessionId);
    setState(() {
      _messages.clear();
      _messages.addAll(messages);
      _currentSessionId = sessionId;
      _isDrawerOpen = false;
    });
    _drawerController.reverse();
    _scrollToBottom();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
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
    _fadeController.dispose();
    _drawerController.dispose();
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
