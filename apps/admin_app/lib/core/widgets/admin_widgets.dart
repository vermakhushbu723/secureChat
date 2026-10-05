import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../api/admin_api.dart';
import '../router/admin_routes.dart';
import '../utils/format.dart';

/// Standard admin page body: header (title, subtitle, actions) + content.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.showBack = false,
    this.onRefresh,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;
  final bool showBack;

  /// Shows a refresh button in the header.
  final VoidCallback? onRefresh;

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
            if (actions.isNotEmpty || onRefresh != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (onRefresh != null) IconButton.outlined(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: onRefresh),
                  ...actions,
                ],
              ),
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
    final up = !(delta?.startsWith('-') ?? false);
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
                    Flexible(
                      child: StatusChip(delta!, tone: up ? Tone.success : Tone.danger, icon: up ? Icons.trending_up : Icons.trending_down),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
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

/// Data table inside a card, scrolls horizontally on narrow screens. Server side pages.
class AdminTable extends StatelessWidget {
  const AdminTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.total,
    this.page = 1,
    this.limit = 25,
    this.onPage,
    this.emptyText = 'Nothing to show yet',
  });

  final List<String> columns;
  final List<List<Widget>> rows;
  final ValueChanged<int>? onRowTap;

  /// Total records on the server.
  final int? total;
  final int page;
  final int limit;

  /// Previous / next page (null = no paging).
  final ValueChanged<int>? onPage;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final count = total ?? rows.length;
    final from = count == 0 ? 0 : (page - 1) * limit + 1;
    final to = (page - 1) * limit + rows.length;
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
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(emptyText, textAlign: TextAlign.center, style: TextStyle(color: context.palette.textSecondary)),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                Text(
                  count == 0 ? 'No records' : 'Showing $from-$to of ${fmtNum(count)}',
                  style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
                ),
                if (onPage != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Page $page', style: TextStyle(color: context.palette.textSecondary, fontSize: 13)),
                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: page > 1 ? () => onPage!(page - 1) : null, tooltip: 'Previous'),
                      IconButton(icon: const Icon(Icons.chevron_right), onPressed: to < count ? () => onPage!(page + 1) : null, tooltip: 'Next'),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Search box (debounced) + filter chips above lists.
class AdminFilterBar extends StatefulWidget {
  const AdminFilterBar({
    super.key,
    required this.filters,
    this.hint = 'Search',
    this.selected,
    this.onChanged,
    this.onSearch,
    this.showSearch = true,
  });

  /// label -> value sent to the API (a plain list uses the label as value).
  final Map<String, String> filters;
  final String hint;
  final String? selected;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSearch;
  final bool showSearch;

  @override
  State<AdminFilterBar> createState() => _AdminFilterBarState();
}

class _AdminFilterBarState extends State<AdminFilterBar> {
  late String _selected = widget.selected ?? (widget.filters.values.isEmpty ? '' : widget.filters.values.first);
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => widget.onSearch?.call(v.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (widget.showSearch) SizedBox(width: 300, child: AppSearchField(hint: widget.hint, onChanged: _search)),
          for (final f in widget.filters.entries)
            ChoiceChip(
              label: Text(f.key),
              selected: _selected == f.value,
              showCheckmark: false,
              onSelected: (_) {
                setState(() => _selected = f.value);
                widget.onChanged?.call(f.value);
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
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
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
    if (values.isEmpty) return SizedBox(height: height, child: const Center(child: Text('No data yet')));
    final max = values.reduce((a, b) => a > b ? a : b);
    final scale = max <= 0 ? 0.0 : height / max;
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
                      message: '${labels[i]}: ${fmtNum(values[i])}$unit',
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 28),
                        height: (values[i] * scale).clamp(values[i] > 0 ? 2.0 : 0.0, height),
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

// ---------------------------------------------------------------------------
// Data loading
// ---------------------------------------------------------------------------

/// Loads data from the API and rebuilds when [reloadKey] changes.
/// Shows a spinner, an error with Retry, or [builder] with the data.
class AdminAsync<T> extends StatefulWidget {
  const AdminAsync({super.key, required this.load, required this.builder, this.reloadKey, this.loadingHeight = 220});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, VoidCallback reload) builder;
  final Object? reloadKey;
  final double loadingHeight;

  @override
  State<AdminAsync<T>> createState() => _AdminAsyncState<T>();
}

class _AdminAsyncState<T> extends State<AdminAsync<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant AdminAsync<T> old) {
    super.didUpdateWidget(old);
    if (old.reloadKey != widget.reloadKey) _fetch();
  }

  Future<void> _fetch() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.load();
      if (!mounted || seq != _seq) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _data == null) return ErrorPanel(message: '$_error', onRetry: _fetch);
    if (_data == null) return SizedBox(height: widget.loadingHeight, child: const Center(child: CircularProgressIndicator()));
    return Stack(
      children: [
        widget.builder(context, _data as T, _fetch),
        if (_loading) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
      ],
    );
  }
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          InfoBanner(icon: Icons.cloud_off_outlined, tone: Tone.danger, title: 'Could not load', message: message),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

/// Runs an admin action: spinner-free, success snack, error snack. Returns the result or null.
Future<T?> runAction<T>(BuildContext context, Future<T> Function() action, {String? success}) async {
  try {
    final result = await action();
    if (success != null && context.mounted) context.showSnack(success);
    return result;
  } on ApiException catch (e) {
    if (context.mounted) context.showSnack(e.message);
  } catch (e) {
    if (context.mounted) context.showSnack('$e');
  }
  return null;
}

/// Switch row controlled by the caller (settings that save to the server).
class SettingSwitch extends StatelessWidget {
  const SettingSwitch({super.key, required this.icon, required this.title, required this.value, required this.onChanged, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Avatar + name (+ optional second line) cell used in tables.
class NameCell extends StatelessWidget {
  const NameCell({super.key, required this.name, this.subtitle, this.online = false, this.icon});

  final String name;
  final String? subtitle;
  final bool online;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppAvatar(initials: icon == null ? initialsOf(name) : null, icon: icon, size: 32, online: online),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 11, color: context.palette.textSecondary)),
          ],
        ),
      ],
    );
  }
}

/// Converts lat / lng points to pins on the map preview (fitted to the points).
List<MapPin> pinsFor(List<({double lat, double lng, String label})> points, {String? meLabel}) {
  if (points.isEmpty) return const [];
  var minLat = points.first.lat, maxLat = points.first.lat, minLng = points.first.lng, maxLng = points.first.lng;
  for (final p in points) {
    if (p.lat < minLat) minLat = p.lat;
    if (p.lat > maxLat) maxLat = p.lat;
    if (p.lng < minLng) minLng = p.lng;
    if (p.lng > maxLng) maxLng = p.lng;
  }
  double norm(double v, double min, double max) => max - min < 1e-6 ? 0.5 : 0.12 + 0.76 * (v - min) / (max - min);
  return [
    for (final p in points)
      MapPin(dx: norm(p.lng, minLng, maxLng), dy: 1 - norm(p.lat, minLat, maxLat), label: p.label, isMe: p.label == meLabel),
  ];
}

/// Small dialog asking for a number of days (extend / premium / suspend).
Future<int?> askDays(BuildContext context, {required String title, List<int> options = const [7, 30, 90], String unit = 'days'}) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(title),
      children: [
        for (final d in options)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, d),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('$d $unit')),
          ),
      ],
    ),
  );
}

/// Dialog with one text field (reason, user ID ...).
Future<String?> askText(BuildContext context, {required String title, String? label, String? hint, String confirm = 'Save', String initial = '', int maxLines = 1}) async {
  final controller = TextEditingController(text: initial);
  final value = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label, hintText: hint),
          onSubmitted: maxLines == 1 ? (v) => Navigator.pop(ctx, v) : null,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text(confirm)),
      ],
    ),
  );
  controller.dispose();
  return value;
}
