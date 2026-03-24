import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/widgets/main_scaffold.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../booking/domain/providers/booking_providers.dart';
import '../../data/chat_repository.dart';
import '../../domain/providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const ChatScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  StreamSubscription? _chatSub;

  @override
  void initState() {
    super.initState();
    _listenForMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatSub?.cancel();
    super.dispose();
  }

  void _listenForMessages() {
    final ws = ref.read(wsClientProvider);
    _chatSub = ws.on('chat_message').listen((data) {
      final eventData = data['data'] ?? data;
      final currentUserId = ref.read(authStateProvider).user?.id ?? '';
      if (eventData['booking_id'] == widget.bookingId) {
        // Don't add our own messages from WS echo — we already add them locally on send
        if (eventData['sender_id'] == currentUserId) return;
        final msg = ChatMessage.fromJson(eventData);
        // Deduplicate by id
        if (_messages.any((m) => m.id == msg.id && msg.id.isNotEmpty)) return;
        setState(() {
          _messages.add(msg);
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = ref.read(authStateProvider).user?.id ?? '';

    // Add message locally for instant display
    setState(() {
      _messages.add(ChatMessage(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        bookingId: widget.bookingId,
        senderId: currentUserId,
        senderRole: ref.read(authStateProvider).user?.role ?? '',
        message: text,
        createdAt: DateTime.now(),
      ));
    });
    _scrollToBottom();

    // Send via WebSocket for real-time delivery to other party
    final ws = ref.read(wsClientProvider);
    ws.sendChatMessage(widget.bookingId, text);

    // Also send via HTTP for persistence
    ref.read(chatRepositoryProvider).sendMessage(widget.bookingId, text);

    _messageController.clear();
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentUserId = ref.watch(authStateProvider).user?.id ?? '';
    final isTechnician =
        ref.watch(authStateProvider).user?.role == 'technician';
    final messagesAsync = ref.watch(chatMessagesProvider(widget.bookingId));
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));

    // Extract phone number and arrival code from booking
    String? otherPartyPhone;
    String? otherPartyName;
    String? arrivalCode;
    bookingAsync.whenData((booking) {
      if (isTechnician) {
        otherPartyPhone = booking.customerPhone;
        otherPartyName = booking.customerName;
      } else {
        otherPartyPhone = booking.technicianPhone;
        otherPartyName = booking.technicianName;
        arrivalCode = booking.arrivalCode;
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.chat, style: const TextStyle(fontSize: 16)),
            if (otherPartyName != null)
              Text(otherPartyName!,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          // Call button
          if (otherPartyPhone != null && otherPartyPhone!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.phone_rounded,
                    color: AppTheme.successColor),
                onPressed: () => _callPhone(otherPartyPhone!),
                tooltip: 'Call',
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Arrival code banner (customer only)
          if (!isTechnician && arrivalCode != null && arrivalCode!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.08),
                  AppTheme.accentColor.withValues(alpha: 0.08),
                ]),
                border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Arrival Code',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          arrivalCode!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.info_outline,
                      size: 16, color: Colors.grey),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (serverMessages) {
                // Merge server messages with real-time messages
                final allMessages = [
                  ...serverMessages,
                  ..._messages.where((m) =>
                      !serverMessages.any((sm) => sm.id == m.id)),
                ];

                if (allMessages.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.chat_bubble_outline,
                    title: 'No messages yet',
                    subtitle: 'Start the conversation!',
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final msg = allMessages[index];
                    final isMe = msg.senderId == currentUserId;

                    return _MessageBubble(
                      message: msg.message,
                      isMe: isMe,
                      timestamp: msg.createdAt,
                      senderRole: msg.senderRole,
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorDisplayWidget(message: e.toString()),
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
                  child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: l10n.typeMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                  ],
                ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final String senderRole;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.senderRole,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width *
                Responsive.value<double>(context, mobile: 0.75, tablet: 0.55)),
        decoration: BoxDecoration(
          color: isMe
              ? AppTheme.primaryColor
              : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 11,
                color: isMe ? Colors.white70 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
