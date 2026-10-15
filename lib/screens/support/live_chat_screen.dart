import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class SupportMessage {
  final String text;
  final DateTime timestamp;
  final bool isFromUser;
  final String status;

  const SupportMessage({
    required this.text,
    required this.timestamp,
    required this.isFromUser,
    required this.status,
  });
}

class _ChatQAPair {
  final List<String> triggers;
  final List<List<String>> keywordCombinations;
  final String answer;

  const _ChatQAPair({
    required this.triggers,
    required this.keywordCombinations,
    required this.answer,
  });
}

class LiveChatScreen extends StatefulWidget {
  final String? initialTopic;
  const LiveChatScreen({super.key, this.initialTopic});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<SupportMessage> _messages = [];

  static const String _fallbackAnswer =
      'I couldn\'t find a direct answer to that query. You can explore role-specific FAQs in Help & Support, submit a ticket via "Report an Issue", or email our support desk at support@voltshare.app (Operating hours: Mon–Sun, 8:00 AM – 10:00 PM IST).';

  static const List<_ChatQAPair> _qaPairs = [
    // 1. How VoltShare works
    _ChatQAPair(
      triggers: [
        'how voltshare works',
        'how does voltshare work',
        'what is voltshare',
        'about voltshare',
        'explain voltshare',
        'how it works',
      ],
      keywordCombinations: [
        ['how', 'voltshare', 'work'],
        ['what', 'voltshare'],
        ['about', 'voltshare'],
        ['how', 'platform', 'work'],
      ],
      answer:
          'VoltShare is a community EV charging network connecting EV drivers with residential societies and private charger hosts. Drivers discover, reserve, and pay for charging sessions, while hosts monetize their private charging stations.',
    ),

    // 2. Driver registration and login
    _ChatQAPair(
      triggers: [
        'driver registration',
        'how to register',
        'how to login',
        'login issue',
        'otp verification',
        'phone number login',
        'sign in',
        'sign up',
      ],
      keywordCombinations: [
        ['driver', 'register'],
        ['driver', 'login'],
        ['how', 'login'],
        ['how', 'register'],
        ['otp'],
        ['phone', 'login'],
        ['sign', 'in'],
        ['sign', 'up'],
      ],
      answer:
          'Drivers can log in or register by entering any valid 10-digit Indian mobile number on the login screen. You can then enter any 4-digit demo verification OTP (0000–9999) to authenticate instantly.',
    ),

    // 3. Finding nearby EV chargers
    _ChatQAPair(
      triggers: [
        'find nearby chargers',
        'find chargers',
        'locate charger',
        'nearest charging station',
        'search station',
        'view map',
        'find station',
      ],
      keywordCombinations: [
        ['find', 'charger'],
        ['nearby', 'charger'],
        ['locate', 'charger'],
        ['nearest', 'charger'],
        ['map', 'station'],
        ['search', 'station'],
        ['filter', 'charger'],
      ],
      answer:
          'You can discover chargers on the home Charger Map screen. Filter stations by connector type (Type 2 AC or CCS2 DC Fast), view real-time bay availability and per-kWh rates, and tap any station pin for directions.',
    ),

    // 4. Booking or reserving a charger
    _ChatQAPair(
      triggers: [
        'book a charger',
        'reserve a charger',
        'how to book',
        'schedule slot',
        'reserve slot',
        'booking a slot',
      ],
      keywordCombinations: [
        ['book', 'charger'],
        ['reserve', 'charger'],
        ['how', 'book'],
        ['schedule', 'slot'],
        ['book', 'slot'],
        ['reserve', 'slot'],
      ],
      answer:
          'To book a charger, select a station on the map or list, choose your preferred charging time slot, review the estimated charging rate, and tap "Book Slot". You can track confirmed reservations in Booking History.',
    ),

    // 5. Charging session status and completion
    _ChatQAPair(
      triggers: [
        'charging session status',
        'how to start charging',
        'stop charging',
        'session completion',
        'live telemetry',
        'charging status',
        'start session',
        'stop session',
      ],
      keywordCombinations: [
        ['start', 'charging'],
        ['stop', 'charging'],
        ['start', 'session'],
        ['stop', 'session'],
        ['session', 'status'],
        ['charging', 'telemetry'],
        ['session', 'completion'],
      ],
      answer:
          'Once at the station, connect the cable to your vehicle and tap "Start Session" in the app. The active session screen monitors live power delivery (kW), energy supplied (kWh), battery percentage, and elapsed duration. Tap "Stop Session" when charging is done.',
    ),

    // 6. Payments and transaction history
    _ChatQAPair(
      triggers: [
        'payments and transactions',
        'payment methods',
        'transaction history',
        'how to pay',
        'upi payment',
        'billing history',
      ],
      keywordCombinations: [
        ['payment', 'method'],
        ['transaction', 'history'],
        ['how', 'pay'],
        ['upi'],
        ['pay', 'session'],
        ['billing', 'history'],
      ],
      answer:
          'VoltShare supports in-app checkout via UPI, debit/credit cards, and net banking. You can review all completed payments and transaction history under Profile > Booking History.',
    ),

    // 7. Pricing and charging costs
    _ChatQAPair(
      triggers: [
        'pricing and charging costs',
        'charging rate',
        'cost per kwh',
        'how much does charging cost',
        'idle fees',
        'tariff',
      ],
      keywordCombinations: [
        ['pricing'],
        ['charging', 'cost'],
        ['cost', 'kwh'],
        ['rate', 'kwh'],
        ['price', 'kwh'],
        ['idle', 'fee'],
        ['tariff'],
      ],
      answer:
          'Charging costs are based on the host\'s published base tariff per kWh multiplied by the energy consumed. A 15-minute grace period is provided after 100% full charge; idle parking fees may apply thereafter to free the bay.',
    ),

    // 8. Charger Host registration and listing chargers
    _ChatQAPair(
      triggers: [
        'host registration',
        'how to become a host',
        'list my charger',
        'add charger',
        'register as host',
        'list charger',
      ],
      keywordCombinations: [
        ['become', 'host'],
        ['list', 'charger'],
        ['add', 'charger'],
        ['host', 'registration'],
        ['register', 'charger'],
        ['host', 'signup'],
      ],
      answer:
          'To list your charger, switch to the Charger Host role and open Host Dashboard > "Add Charger". Enter your charger model, connector type (Type 2 AC / CCS2 DC), power rating (kW), and set your base tariff per kWh.',
    ),

    // 9. Managing charger availability
    _ChatQAPair(
      triggers: [
        'manage charger availability',
        'turn charger offline',
        'charger operating hours',
        'set schedule',
        'charger availability',
      ],
      keywordCombinations: [
        ['charger', 'availability'],
        ['charger', 'offline'],
        ['charger', 'online'],
        ['operating', 'hours'],
        ['manage', 'charger'],
      ],
      answer:
          'Charger Hosts can manage availability under Host Dashboard > My Chargers. You can toggle charger status between Online and Offline at any time, and configure active days and booking hours.',
    ),

    // 10. Host earnings and payments
    _ChatQAPair(
      triggers: [
        'host earnings',
        'host payout',
        'how hosts get paid',
        'host payment',
        'platform fee',
        'host revenue',
      ],
      keywordCombinations: [
        ['host', 'earning'],
        ['host', 'payout'],
        ['host', 'payment'],
        ['host', 'revenue'],
        ['platform', 'fee'],
      ],
      answer:
          'Host revenue accumulates from completed charging sessions. VoltShare disburses net payouts after deducting a 10% platform fee for payment handling and connectivity. Track earnings under Host Dashboard > Host Earnings.',
    ),

    // 11. Cancellations and booking issues
    _ChatQAPair(
      triggers: [
        'cancel booking',
        'cancellation policy',
        'cancel slot',
        'bay occupied',
        'bay blocked',
        'booking issue',
      ],
      keywordCombinations: [
        ['cancel', 'booking'],
        ['cancel', 'reservation'],
        ['cancel', 'slot'],
        ['cancellation'],
        ['bay', 'blocked'],
        ['bay', 'occupied'],
      ],
      answer:
          'You can cancel an upcoming reservation from Booking Details prior to the scheduled start time with no cancellation penalty. If a reserved bay is occupied upon arrival, message the host via Host Chat or submit a ticket in Help & Support.',
    ),

    // 12. Reporting an issue
    _ChatQAPair(
      triggers: [
        'report an issue',
        'report issue',
        'raise a ticket',
        'file a complaint',
        'technical problem',
        'submit ticket',
      ],
      keywordCombinations: [
        ['report', 'issue'],
        ['raise', 'ticket'],
        ['file', 'complaint'],
        ['technical', 'issue'],
        ['hardware', 'issue'],
        ['submit', 'ticket'],
      ],
      answer:
          'To report an issue, navigate to Profile > Help & Support > "Report an Issue". Select your issue category (hardware, billing, or blocked bay), enter a description, and tap "Submit Report" for prompt review.',
    ),

    // 13. Downloading invoices
    _ChatQAPair(
      triggers: [
        'download invoice',
        'get invoice',
        'download receipt',
        'tax invoice',
        'billing receipt',
        'view invoice',
      ],
      keywordCombinations: [
        ['download', 'invoice'],
        ['get', 'invoice'],
        ['download', 'receipt'],
        ['tax', 'invoice'],
        ['invoice'],
        ['receipt'],
      ],
      answer:
          'Itemized receipts and invoices are generated for every completed session. Go to Profile > Booking History, open any completed session to view Booking Details, and tap "Download Invoice" to save your statement.',
    ),

    // 14. Account logout and basic troubleshooting
    _ChatQAPair(
      triggers: [
        'account logout',
        'how to logout',
        'sign out',
        'troubleshooting',
        'cable stuck',
        'session not starting',
        'app troubleshooting',
      ],
      keywordCombinations: [
        ['logout'],
        ['log', 'out'],
        ['sign', 'out'],
        ['cable', 'stuck'],
        ['connector', 'stuck'],
        ['troubleshoot'],
        ['not', 'working'],
      ],
      answer:
          'To log out, go to Profile > Settings and tap "Logout", or switch roles from the top menu. If a charging session fails to start, verify your vehicle is in Park, unseat and re-latch the charging connector firmly, and tap "Start Session".',
    ),

    // 15. Society Admin overview
    _ChatQAPair(
      triggers: [
        'society admin',
        'community chargers',
        'transformer load',
        'residential charging',
      ],
      keywordCombinations: [
        ['society', 'admin'],
        ['transformer', 'load'],
        ['community', 'charger'],
      ],
      answer:
          'The Society Admin Dashboard provides visibility into community chargers installed across apartment wings, aggregate power consumption, transformer headroom, and resident vs visitor charging sessions.',
    ),

    // 16. Support operating hours and direct contact
    _ChatQAPair(
      triggers: [
        'contact support',
        'support email',
        'operating hours',
        'customer care',
        'contact desk',
      ],
      keywordCombinations: [
        ['contact', 'support'],
        ['support', 'email'],
        ['operating', 'hours'],
        ['customer', 'care'],
        ['human', 'agent'],
      ],
      answer:
          'VoltShare support operates Monday through Sunday, 8:00 AM – 10:00 PM IST. You can email support@voltshare.app for driver queries, hosts@voltshare.app for charger hosts, or society@voltshare.app for residential admins.',
    ),
  ];

  static String _matchAnswer(String rawQuery) {
    final clean = rawQuery
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (clean.isEmpty) return _fallbackAnswer;

    _ChatQAPair? bestMatch;
    int bestScore = 0;

    for (final pair in _qaPairs) {
      int score = 0;

      // 1. Check direct trigger substring matches
      for (final trigger in pair.triggers) {
        if (clean == trigger) {
          score += 100;
        } else if (clean.contains(trigger)) {
          score += 60;
        } else if (trigger.contains(clean) && clean.length >= 4) {
          score += 30;
        }
      }

      // 2. Check keyword combination matches
      for (final combo in pair.keywordCombinations) {
        final allPresent = combo.every((word) => clean.contains(word));
        if (allPresent) {
          score += 20 * combo.length;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = pair;
      }
    }

    if (bestMatch != null && bestScore >= 20) {
      return bestMatch.answer;
    }

    return _fallbackAnswer;
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      final role = AuthProvider().userRole;
      if (role == UserRole.admin) {
        context.go('/admin-dashboard');
      } else if (role == UserRole.host) {
        context.go('/host/dashboard');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialTopic != null && widget.initialTopic!.trim().isNotEmpty) {
      final topic = widget.initialTopic!.trim();
      _messages.add(
        SupportMessage(
          text: 'Inquiry regarding: $topic',
          timestamp: DateTime.now(),
          isFromUser: true,
          status: 'Sent',
        ),
      );
      _messages.add(
        SupportMessage(
          text: _matchAnswer(topic),
          timestamp: DateTime.now().add(const Duration(milliseconds: 50)),
          isFromUser: false,
          status: 'VoltShare Assistant',
        ),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final userMessage = SupportMessage(
      text: text,
      timestamp: DateTime.now(),
      isFromUser: true,
      status: 'Sent',
    );

    final answer = _matchAnswer(text);
    final botMessage = SupportMessage(
      text: answer,
      timestamp: DateTime.now().add(const Duration(milliseconds: 50)),
      isFromUser: false,
      status: 'VoltShare Assistant',
    );

    setState(() {
      _messages.add(userMessage);
      _messages.add(botMessage);
      _textController.clear();
    });

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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final role = AuthProvider().userRole;
    final roleLabel = role == UserRole.admin
        ? 'Society Admin Support'
        : (role == UserRole.host ? 'Charger Host Support' : 'Driver Support');

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: _handleBack,
        ),
        title: Column(
          children: [
            Text(
              'Live Support Chat',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            Text(
              roleLabel,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Honest support notice banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Live support queue connected. Leave a message and our team will respond during operating hours (8 AM - 10 PM IST).',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            // Chat messages list
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.chat_bubble_outline,
                                  color: AppColors.primary, size: 30),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'How can we assist you today?',
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Type your question below regarding sessions, chargers, or billing.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return Align(
                          alignment: msg.isFromUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.78,
                            ),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: msg.isFromUser
                                  ? cs.primary
                                  : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(msg.isFromUser ? 16 : 4),
                                bottomRight: Radius.circular(msg.isFromUser ? 4 : 16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.text,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    color: msg.isFromUser ? cs.onPrimary : cs.onSurface,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      DateFormat('hh:mm a').format(msg.timestamp),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10,
                                        color: (msg.isFromUser ? cs.onPrimary : cs.onSurface)
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${msg.status}',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9,
                                        color: (msg.isFromUser ? cs.onPrimary : cs.onSurface)
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Message Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(color: cs.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _textController,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type your support message...',
                          hintStyle: GoogleFonts.manrope(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
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
}
