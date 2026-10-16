import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class _ChatMessage {
  final String text;
  final String time;
  final bool isMe;

  const _ChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
  });
}

class HostChatScreen extends StatefulWidget {
  const HostChatScreen({super.key});

  @override
  State<HostChatScreen> createState() => _HostChatScreenState();
}

class _HostChatScreenState extends State<HostChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isHostTyping = false;
  Timer? _typingTimer;

  late final List<_ChatMessage> _messages;

  final List<String> _quickReplies = const [
    "I've arrived at Gate 2",
    'Is the cable Type 2?',
    'Need 15 mins extra',
    'Thanks for the help!',
  ];

  @override
  void initState() {
    super.initState();
    _messages = [
      const _ChatMessage(
        text: 'Hi Karan, your slot starts at 8 PM. The charger is in Tower B, parking level 2.',
        time: '7:42 PM',
        isMe: false,
      ),
      const _ChatMessage(
        text: 'Thanks Priya! Do I need a key card to access the parking?',
        time: '7:43 PM',
        isMe: true,
      ),
      const _ChatMessage(
        text: "No, just enter through the visitor gate and mention 'VoltNest slot' to the guard.",
        time: '7:44 PM',
        isMe: false,
      ),
      const _ChatMessage(
        text: 'Perfect, see you in 15.',
        time: '7:45 PM',
        isMe: true,
      ),
    ];
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? textToSend]) {
    final text = (textToSend ?? _messageController.text).trim();
    if (text.isEmpty) return;

    final timeStr = _formatCurrentTime();

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          time: timeStr,
          isMe: true,
        ),
      );
      _messageController.clear();
    });

    _scrollToBottom();
    _triggerHostReply(text);
  }

  void _triggerHostReply(String userText) {
    _typingTimer?.cancel();

    setState(() {
      _isHostTyping = true;
    });

    final lower = userText.toLowerCase();
    String reply;

    if (lower.contains('reach') ||
        lower.contains('here') ||
        lower.contains('gate') ||
        lower.contains('arrived')) {
      reply =
          'Great! I just informed the security guard at Gate 2. Slot B-4 is right next to the visitor elevator.';
    } else if (lower.contains('start') ||
        lower.contains('plug') ||
        lower.contains('cable') ||
        lower.contains('connect') ||
        lower.contains('type 2')) {
      reply =
          "The Type 2 connector gun is unlocked. Plug it into your vehicle and tap 'Start Session' on your app!";
    } else if (lower.contains('key') ||
        lower.contains('card') ||
        lower.contains('access') ||
        lower.contains('code') ||
        lower.contains('guard')) {
      reply =
          "No access card needed! The barrier is RFID-automated or the guard will open it for 'VoltShare Slot 4'.";
    } else if (lower.contains('extend') ||
        lower.contains('time') ||
        lower.contains('late') ||
        lower.contains('delay') ||
        lower.contains('extra')) {
      reply =
          'No problem at all! The slot after 9 PM is currently open today if you need extra charging time.';
    } else if (lower.contains('thank') ||
        lower.contains('perfect') ||
        lower.contains('ok') ||
        lower.contains('great')) {
      reply =
          "You're very welcome! Ping me here if the charger pauses or if you need anything else.";
    } else {
      reply =
          "Got it, Karan! I'm monitoring the charger dashboard. Let me know if you run into any issues.";
    }

    _typingTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isHostTyping = false;
        _messages.add(
          _ChatMessage(
            text: reply,
            time: _formatCurrentTime(),
            isMe: false,
          ),
        );
      });
      _scrollToBottom();
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Share with Host',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on, color: AppColors.primary),
                  ),
                  title: Text(
                    'Share Live Location',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    'Tower B Gate 2 Visitor Entry',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _sendMessage('📍 Shared location: Waiting outside Tower B Gate 2');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.primaryContainer),
                  ),
                  title: Text(
                    'Send Charger Screen Photo',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    'Show meter display or status lights',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _sendMessage('📷 Sent photo: Charger display shows Ready / Green');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bolt, color: Colors.orange),
                  ),
                  title: Text(
                    'Send Meter Reading',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    'Record starting kWh units',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _sendMessage('⚡ Initial meter reading: 4,812.4 kWh recorded');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _buildAppBar(),
      ),
      body: Column(
        children: [
          // Session info bar
          _buildSessionInfoBar(),
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isHostTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isHostTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index], index);
              },
            ),
          ),
          // Quick suggestion chips
          _buildQuickReplies(),
          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 4),
            // Avatar with initials
            Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'PS',
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                // Online indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _isHostTyping ? AppColors.primaryContainer : AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.backgroundDark,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Priya S.',
                    style: GoogleFonts.sora(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _isHostTyping ? 'typing...' : 'Online · Host',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isHostTyping ? AppColors.primaryContainer : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfoBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.6),
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderDark,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bolt,
            size: 16,
            color: AppColors.primary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Tower B Slot 4 · 8 PM–9 PM today · Type 2 (7.4 kW)',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return ActionChip(
            label: Text(
              reply,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: AppColors.surfaceVariantDark,
            side: BorderSide(color: AppColors.borderDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onPressed: () => _sendMessage(reply),
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Priya is typing',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 6),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildMessageBubble(_ChatMessage message, int index) {
    final isMe = message.isMe;

    final bubble = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : const Color(0xFF252525),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              border: isMe ? null : Border.all(color: AppColors.borderDark),
            ),
            child: Text(
              message.text,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isMe ? Colors.black : Colors.white,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message.time,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );

    if (index < 4) {
      return bubble
          .animate()
          .fadeIn(duration: 300.ms, delay: Duration(milliseconds: 100 * index))
          .slideY(begin: 0.05);
    }

    return bubble.animate().fadeIn(duration: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(color: AppColors.borderDark),
        ),
      ),
      child: Row(
        children: [
          // Attachment button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showAttachmentOptions,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Text field
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantDark,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Message Host Priya...',
                  hintStyle: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _sendMessage(),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
