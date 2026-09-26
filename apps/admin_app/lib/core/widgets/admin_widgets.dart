import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../router/admin_routes.dart';

/// Standard admin page body: header (title, subtitle, actions) + content.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.showBack = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showBack) ...[
                  IconButton.outlined(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.canPop() ? context.pop() : context.go(AdminRoutes.dashboard),
                  ),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      if (subtitle != null) Text(subtitle!, style: TextStyle(color: context.palette.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.icon, required this.label, required this.value, this.delta, this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final String? delta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final up = delta?.startsWith('+') ?? true;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppAvatar(icon: icon, size: 40),
                  const Spacer(),
                  if (delta != null)
                    StatusChip(
                      delta!,
                      tone: up ? Tone.success : Tone.danger,
                      icon: up ? Icons.trending_up : Icons.trending_down,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: context.palette.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive grid of fixed-min-width cards.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.children, this.minItemWidth = 220, this.spacing = 12});

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final count = (c.maxWidth / minItemWidth).floor().clamp(1, 6);
        final width = (c.maxWidth - spacing * (count - 1)) / count;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final w in children) SizedBox(width: width, child: w)],
        );
      },
    );
  }
}

/// Data table inside a card, scrolls horizontally on narrow screens.
class AdminTable extends StatelessWidget {
  const AdminTable({super.key, required this.columns, required this.rows, this.onRowTap, this.total});

  final List<String> columns;
  final List<List<Widget>> rows;
  final ValueChanged<int>? onRowTap;

  /// Total records on the server. Lists are paginated server side
  /// (cursor based) so the panel stays fast with millions of rows.
  final int? total;

  @override
  Widget build(BuildContext context) {
    final table = LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: c.maxWidth),
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStatePropertyAll(context.palette.surfaceAlt),
            headingTextStyle: TextStyle(fontWeight: FontWeight.w700, color: context.colors.onSurface),
            columns: [for (final col in columns) DataColumn(label: Text(col))],
            rows: [
              for (var i = 0; i < rows.length; i++)
                DataRow(
                  onSelectChanged: onRowTap == null ? null : (_) => onRowTap!(i),
                  cells: [for (final cell in rows[i]) DataCell(cell)],
                ),
            ],
          ),
        ),
      ),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          table,
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                Text(
                  'Showing 1-${rows.length} of ${_format(total ?? rows.length)}',
                  style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('25 / page', style: TextStyle(color: context.palette.textSecondary, fontSize: 13)),
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: null, tooltip: 'Previous'),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: (total ?? 0) > rows.length ? () {} : null,
                      tooltip: 'Next',
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

  static String _format(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}

/// Search + filter chips row above lists.
class AdminFilterBar extends StatefulWidget {
  const AdminFilterBar({super.key, required this.filters, this.hint = 'Search', this.onChanged});

  final List<String> filters;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  State<AdminFilterBar> createState() => _AdminFilterBarState();
}

class _AdminFilterBarState extends State<AdminFilterBar> {
  late String _selected = widget.filters.first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: 300, child: AppSearchField(hint: widget.hint)),
          for (final f in widget.filters)
            ChoiceChip(
              label: Text(f),
              selected: _selected == f,
              showCheckmark: false,
              onSelected: (_) {
                setState(() => _selected = f);
                widget.onChanged?.call(f);
              },
            ),
        ],
      ),
    );
  }
}

/// Card with a title row and arbitrary content.
class PanelCard extends StatelessWidget {
  const PanelCard({super.key, required this.title, required this.child, this.action, this.onAction, this.padding});

  final String title;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
              ],
            ),
          ),
          Padding(padding: padding ?? const EdgeInsets.fromLTRB(0, 0, 0, 8), child: child),
        ],
      ),
    );
  }
}

/// Single-series bar chart (one hue, thin rounded bars, hover tooltip per bar).
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.values, required this.labels, this.height = 180, this.unit = ''});

  final List<double> values;
  final List<String> labels;
  final double height;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final max = values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: height + 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: '${labels[i]}: ${values[i].round()}$unit',
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 28),
                        height: height * values[i] / max,
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: TextStyle(fontSize: 11, color: context.palette.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
