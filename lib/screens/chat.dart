import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/chat_message.dart';
import '../components/download.dart';
import '../components/typewriter_text.dart';
import '../components/thinking_animation.dart';
import '../components/message_context_menu.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../components/generation_animation.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _hasText = false;
  
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Column(
        children: [
          Container(
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF000000),
            ),
            child: SafeArea(
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
          ),
          Expanded(
            child: _messages.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
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
                              height: 1.5,
                            ),
                            speed: const Duration(milliseconds: 300),
                          )
                  : GenerationAnimation(
                      type: message.type == MessageType.image ? 'image' : 'video',
                      url: message.content.isNotEmpty ? message.content : null,
                      prompt: message.prompt,
                      onTap: () {
                        if (message.content.isNotEmpty) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => DownloadScreen(
                                url: message.content,
                                type: message.type == MessageType.image ? 'image' : 'video',
                                prompt: message.prompt,
                              ),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return Hero(
                                  tag: '${message.type == MessageType.image ? 'image' : 'video'}_${message.content}',
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      },
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
            onTap: _showMoreOptions,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'What can I help you with?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildQuickAction(
                  icon: CupertinoIcons.photo,
                  title: 'Create Image',
                  onTap: () => _setQuickPrompt('Create a image of: ', MessageType.image),
                ),
                _buildQuickAction(
                  icon: CupertinoIcons.videocam,
                  title: 'Create Video',
                  onTap: () => _setQuickPrompt('Create a video of: ', MessageType.video),
                ),
                _buildQuickAction(
                  icon: CupertinoIcons.lightbulb,
                  title: 'Get Advice',
                  onTap: () => _setQuickPrompt('Give me advice about: ', MessageType.text),
                ),
                _buildQuickAction(
                  icon: CupertinoIcons.ellipsis,
                  title: 'More...',
                  onTap: _showMoreOptions,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setQuickPrompt(String prompt, MessageType mode) {
    setState(() {
      _messageController.text = prompt;
      _currentMode = mode;
      _hasText = true;
    });
    // Focus on input field
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _showMoreOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('More Options'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _setQuickPrompt('Summarize this text: ', MessageType.text);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.doc_text, color: CupertinoColors.systemBlue),
                SizedBox(width: 8),
                Text('Summarize'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _setQuickPrompt('Generate a story about: ', MessageType.text);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.book, color: CupertinoColors.systemBlue),
                SizedBox(width: 8),
                Text('Story Gen'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _setQuickPrompt('Write professionally about: ', MessageType.text);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.briefcase, color: CupertinoColors.systemBlue),
                SizedBox(width: 8),
                Text('Pro Write'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _setQuickPrompt('Explain simply: ', MessageType.text);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.info_circle, color: CupertinoColors.systemBlue),
                SizedBox(width: 8),
                Text('Explain'),
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
    // Check permission when mic button is clicked
    var permissionStatus = await Permission.microphone.status;
    
    if (permissionStatus.isDenied) {
      // Request permission
      var result = await Permission.microphone.request();
      
      if (result.isDenied) {
        // Show iOS style dialog to go to settings
        _showMicPermissionDialog();
        return;
      }
    } else if (permissionStatus.isPermanentlyDenied) {
      // Show settings dialog
      _showMicPermissionDialog();
      return;
    }
    
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
            _hasText = result.recognizedWords.isNotEmpty;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  void _showMicPermissionDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Enable Mic Permission'),
        content: const Text('Microphone access is required for voice input. Please enable it in Settings.'),
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
            isDefaultAction: true,
            child: const Text('Settings'),
          ),
        ],
      ),
    );
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
        response = await ApiService.sendMessage(message);
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
    }
  }



  void _loadChatHistory() async {
    // This method is not needed for new session-based history
    // History is now managed by HistoryService and loaded on demand
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _messageController.addListener(() {
      setState(() {
        _hasText = _messageController.text.trim().isNotEmpty;
      });
    });
    
    _initSpeech();
    _loadChatHistory();
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



  void _initSpeech() async {
    // Don't request permission at startup, just initialize
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}




