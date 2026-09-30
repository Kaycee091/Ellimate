import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../features/auth/domain/auth_providers.dart';
import '../../../shared/models/chat_message.dart';
import '../../../shared/widgets/ellimate_avatar.dart';
import '../../../shared/widgets/ellimate_states.dart';

final chatMessagesProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatMessage>>>((ref) {
  return ChatNotifier(ref);
});

class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  ChatNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;
  RealtimeChannel? _channel;
  String? _apartmentId;

  Future<void> _init() async {
    try {
      final apartment = await _ref.read(currentApartmentProvider.future);
      if (apartment == null) {
        state = const AsyncValue.data([]);
        return;
      }
      _apartmentId = apartment.id;
      await _loadMessages();
      _subscribeToMessages();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> _loadMessages() async {
    if (_apartmentId == null) return;
    try {
      final msgs = await _ref.read(chatRepositoryProvider).fetchMessages(
        apartmentId: _apartmentId!,
      );
      // Enrich with profile data
      final members = await _ref.read(apartmentRepositoryProvider).fetchMembers(_apartmentId!);
      final profileMap = {for (final m in members) m.userId: m.profile};

      final enriched = msgs.map((msg) {
        final profile = profileMap[msg.userId];
        return msg.copyWith(
          senderName: profile?.name ?? msg.senderName,
          senderAvatarUrl: profile?.avatarUrl ?? msg.senderAvatarUrl,
        );
      }).toList();

      if (mounted) state = AsyncValue.data(enriched);
    } catch (e) {
      if (mounted) state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void _subscribeToMessages() {
    if (_apartmentId == null) return;

    _channel = _ref.read(chatRepositoryProvider).subscribeToMessages(
      apartmentId: _apartmentId!,
      onMessage: (msg) async {
        // Enrich incoming message
        final members = await _ref.read(apartmentRepositoryProvider).fetchMembers(_apartmentId!);
        final profile = members
            .where((m) => m.userId == msg.userId)
            .map((m) => m.profile)
            .firstOrNull;

        final enriched = msg.copyWith(
          senderName: profile?.name,
          senderAvatarUrl: profile?.avatarUrl,
        );

        if (mounted) {
          final current = state.value ?? [];
          state = AsyncValue.data([...current, enriched]);
        }
      },
    );
  }

  Future<void> sendMessage(String message, String userId) async {
    if (_apartmentId == null) return;
    await _ref.read(chatRepositoryProvider).sendMessage(
      apartmentId: _apartmentId!,
      userId: userId,
      message: message,
    );
  }

  Future<void> refresh() => _loadMessages();

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ref.read(chatMessagesProvider.notifier).sendMessage(text, user.id);
      _scrollToBottom();
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
        _messageController.text = text;
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final apartment = ref.watch(currentApartmentProvider);

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apartment Chat', style: AppTypography.sectionHeading),
            apartment.when(
              data: (apt) => Text(apt?.name ?? '', style: AppTypography.caption),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(chatMessagesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const ElliMateLoading(),
              error: (e, _) => ElliMateErrorState(
                message: 'Unable to load messages.',
                onRetry: () => ref.read(chatMessagesProvider.notifier).refresh(),
              ),
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                if (messages.isEmpty) {
                  return const ElliMateEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No messages yet',
                    subtitle: 'Start the conversation!',
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.userId == currentUser?.id;
                    final prevMsg = i > 0 ? messages[i - 1] : null;
                    final showAvatar = prevMsg?.userId != msg.userId;

                    return _ChatBubble(
                      message: msg,
                      isMe: isMe,
                      showSenderInfo: showAvatar,
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            color: AppColors.white,
            padding: EdgeInsets.fromLTRB(
              16, 8, 16, 8 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.creamBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTypography.body,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: AppTypography.body.copyWith(
                          color: AppColors.secondaryText.withValues(alpha: 0.6),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _messageController,
                  builder: (context, _) {
                    final hasText = _messageController.text.trim().isNotEmpty;
                    return GestureDetector(
                      onTap: hasText && !_isSending ? _sendMessage : null,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: hasText ? AppColors.primaryCoral : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                        child: _isSending
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded,
                                color: AppColors.white, size: 20),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.showSenderInfo,
  });

  final ChatMessage message;
  final bool isMe;
  final bool showSenderInfo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (showSenderInfo)
              ElliMateAvatar(
                imageUrl: message.senderAvatarUrl,
                name: message.senderName ?? '?',
                radius: 16,
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && showSenderInfo) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      message.senderName ?? 'Unknown',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primaryCoral : AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNavy.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message.message,
                        style: AppTypography.body.copyWith(
                          color: isMe ? AppColors.white : AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateTimeUtils.formatChatTime(message.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: isMe
                              ? AppColors.white.withValues(alpha: 0.7)
                              : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
