import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../data/direct_models.dart';
import '../data/direct_repository.dart';
import '../state/chat_controller.dart';
import '../state/conversations_controller.dart';
import 'dm_avatar.dart';

const quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

// Server side limits (see backend .env).
const _editWindow = Duration(minutes: 15);
const _deleteForEveryoneWindow = Duration(minutes: 60);

/// Long-press menu of a message. Runs the chosen action on [chat].
Future<void> showMessageActions(BuildContext context, ChatController chat, DmMessage m) async {
  final me = chat.me;
  final mine = m.isMine;
  final age = DateTime.now().difference(m.createdAt);
  final canEdit =
      mine && !m.deleted && const [DmType.text, DmType.image, DmType.video].contains(m.type) && age < _editWindow;
  // Private / Highly Protected: no copy, no forward.
  final canCopy = !m.deleted && m.text.isNotEmpty && m.canCopy;
  final myReaction = m.myReaction(me);

  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!m.deleted && chat.canSend)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final e in quickReactions)
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => Navigator.pop(ctx, 'react:$e'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: myReaction == e ? ctx.palette.surfaceAlt : null,
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                    IconButton.outlined(
                      tooltip: 'More reactions',
                      icon: const Icon(Icons.add),
                      onPressed: () => Navigator.pop(ctx, 'react:+'),
                    ),
                  ],
                ),
              ),
            if (!m.deleted && chat.canSend)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () => Navigator.pop(ctx, 'reply'),
              ),
            if (canCopy)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () => Navigator.pop(ctx, 'copy'),
              ),
            if (canEdit)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
            if (!m.deleted && m.canForward)
              ListTile(
                leading: const Icon(Icons.shortcut),
                title: const Text('Forward'),
                onTap: () => Navigator.pop(ctx, 'forward'),
              ),
            if (!m.deleted)
              ListTile(
                leading: Icon(m.starred ? Icons.star : Icons.star_border),
                title: Text(m.starred ? 'Unstar' : 'Star'),
                onTap: () => Navigator.pop(ctx, 'star'),
              ),
            if (mine && !m.deleted)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Info'),
                onTap: () => Navigator.pop(ctx, 'info'),
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: ctx.palette.danger),
              title: Text('Delete', style: TextStyle(color: ctx.palette.danger)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    ),
  );
  if (action == null || !context.mounted) return;

  try {
    if (action.startsWith('react:')) {
      var emoji = action.substring(6);
      if (emoji == '+') {
        final picked = await pickEmoji(context);
        if (picked == null) return;
        emoji = picked;
      }
      await chat.react(m, emoji);
      return;
    }
    switch (action) {
      case 'reply':
        chat.setReply(m);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: m.text));
        if (context.mounted) context.showSnack('Copied');
      case 'edit':
        chat.startEdit(m);
      case 'forward':
        final targets = await pickForwardTargets(context, excludeUserId: null);
        if (targets == null || targets.isEmpty) return;
        await chat.forward(m, targets);
        if (context.mounted) context.showSnack('Forwarded to ${targets.length} chat${targets.length > 1 ? 's' : ''}');
      case 'star':
        await chat.toggleStar(m);
      case 'info':
        if (context.mounted) await showMessageInfo(context, m);
      case 'delete':
        await _confirmDelete(context, chat, m, canForEveryone: mine && !m.deleted && age < _deleteForEveryoneWindow);
    }
  } on ApiException catch (e) {
    if (context.mounted) context.showSnack(e.message);
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  ChatController chat,
  DmMessage m, {
  required bool canForEveryone,
}) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete message?'),
      actions: [
        if (canForEveryone)
          TextButton(onPressed: () => Navigator.pop(ctx, 'everyone'), child: const Text('Delete for everyone')),
        TextButton(onPressed: () => Navigator.pop(ctx, 'me'), child: const Text('Delete for me')),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      ],
    ),
  );
  if (choice == null) return;
  await chat.deleteMessage(m, forEveryone: choice == 'everyone');
}

Future<String?> pickEmoji(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: EmojiPicker(
        onEmojiSelected: (_, emoji) => Navigator.pop(ctx, emoji.emoji),
        config: Config(
          height: 320,
          emojiViewConfig: EmojiViewConfig(backgroundColor: ctx.colors.surface),
          categoryViewConfig: CategoryViewConfig(
            initCategory: Category.SMILEYS,
            backgroundColor: ctx.colors.surface,
            indicatorColor: ctx.colors.primary,
          ),
          bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
        ),
      ),
    ),
  );
}

Future<void> showMessageInfo(BuildContext context, DmMessage m) async {
  final info = await DirectRepository.messageInfo(m.id);
  if (!context.mounted) return;
  String fmt(dynamic v) {
    final t = v == null ? null : DateTime.tryParse('$v')?.toLocal();
    return t == null ? '—' : '${formatDayHeader(t)}, ${formatClock(t)}';
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Message info', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ListTile(leading: const Icon(Icons.done), title: const Text('Sent'), subtitle: Text(fmt(info['sentAt']))),
          ListTile(
            leading: const Icon(Icons.done_all),
            title: const Text('Delivered'),
            subtitle: Text(fmt(info['deliveredAt'])),
          ),
          ListTile(
            leading: const Icon(Icons.done_all, color: Color(0xFF34B7F1)),
            title: const Text('Read'),
            subtitle: Text(fmt(info['readAt'])),
          ),
          if (info['editedAt'] != null)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edited'),
              subtitle: Text(fmt(info['editedAt'])),
            ),
        ],
      ),
    ),
  );
}

/// Choose up to 5 chats (people) to forward to. Returns their user ids.
Future<List<String>?> pickForwardTargets(BuildContext context, {String? excludeUserId}) {
  return Navigator.of(context).push<List<String>>(
    MaterialPageRoute(builder: (_) => _ForwardPicker(excludeUserId: excludeUserId), fullscreenDialog: true),
  );
}

class _ForwardPicker extends StatefulWidget {
  const _ForwardPicker({this.excludeUserId});

  final String? excludeUserId;

  @override
  State<_ForwardPicker> createState() => _ForwardPickerState();
}

class _ForwardPickerState extends State<_ForwardPicker> {
  final _selected = <String>{};
  String _query = '';
  List<DmUser> _searchResults = [];

  Future<void> _search(String q) async {
    setState(() => _query = q);
    if (q.trim().length < 2) return setState(() => _searchResults = []);
    try {
      final users = await DirectRepository.searchUsers(q.trim());
      if (mounted && q == _query) setState(() => _searchResults = users);
    } on ApiException {
      // keep previous results
    }
  }

  @override
  Widget build(BuildContext context) {
    final recent = ConversationsController.instance.items.map((c) => c.peer).where((u) => u.id != widget.excludeUserId);
    final q = _query.trim().toLowerCase();
    final people = <String, DmUser>{
      for (final u in recent.where((u) => q.isEmpty || u.name.toLowerCase().contains(q))) u.id: u,
      for (final u in _searchResults) u.id: u,
    }.values.toList();

    return Scaffold(
      appBar: AppBar(title: Text(_selected.isEmpty ? 'Forward to...' : '${_selected.length} selected')),
      floatingActionButton: _selected.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.pop(context, _selected.toList()),
              child: const Icon(Icons.send),
            ),
      body: ResponsiveBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: AppSearchField(hint: 'Search people', onChanged: _search, autofocus: false),
            ),
            Expanded(
              child: people.isEmpty
                  ? const EmptyState(icon: Icons.people_outline, title: 'No chats', message: 'Search a person by name')
                  : ListView(
                      children: [
                        for (final u in people)
                          CheckboxListTile(
                            value: _selected.contains(u.id),
                            onChanged: (v) {
                              if (v == true && _selected.length >= 5) {
                                context.showSnack('You can forward to up to 5 chats');
                                return;
                              }
                              setState(() => v == true ? _selected.add(u.id) : _selected.remove(u.id));
                            },
                            secondary: DmAvatar.user(u, size: 42),
                            title: Text(u.name),
                            subtitle: u.username == null ? null : Text('@${u.username}'),
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
