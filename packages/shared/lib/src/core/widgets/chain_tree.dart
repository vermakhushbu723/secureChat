import 'package:flutter/material.dart';

import '../../data/models/app_models.dart';
import '../theme/app_palette.dart';
import 'app_avatar.dart';
import 'status_chip.dart';

/// Recursive view of a forward chain. Users see names only;
/// [showIds] is used by admins to show internal message IDs.
class ChainTree extends StatelessWidget {
  const ChainTree({super.key, required this.node, this.depth = 0, this.showIds = false, this.deletedFrom});

  final ForwardNode node;
  final int depth;
  final bool showIds;

  /// Message ID from which the chain is (being) deleted - that node and its descendants.
  final String? deletedFrom;

  bool _isDeleted(bool parentDeleted) => parentDeleted || node.deleted || node.messageId == deletedFrom;

  @override
  Widget build(BuildContext context) => _build(context, false);

  Widget _build(BuildContext context, bool parentDeleted) {
    final deleted = _isDeleted(parentDeleted);
    final color = deleted ? context.palette.danger : context.colors.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 20.0, bottom: 8),
          child: Row(
            children: [
              if (depth > 0) ...[
                Icon(Icons.subdirectory_arrow_right, size: 18, color: context.palette.textSecondary),
                const SizedBox(width: 4),
              ],
              AppAvatar(icon: depth == 0 ? Icons.edit_outlined : Icons.shortcut, size: 32, inverted: depth == 0),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showIds ? '${node.messageId}  ${node.from}' : node.from,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color,
                        decoration: deleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      '${depth == 0 ? 'Original in' : 'To'} ${node.to}  |  ${node.recipients} users  |  ${node.time}'
                      '${showIds && node.parentId != null ? '  |  parent ${node.parentId}' : ''}',
                      style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusChip(deleted ? 'Deleted' : 'Active'),
            ],
          ),
        ),
        for (final c in node.children)
          ChainTree(node: c, depth: depth + 1, showIds: showIds, deletedFrom: deleted ? c.messageId : deletedFrom),
      ],
    );
  }
}
