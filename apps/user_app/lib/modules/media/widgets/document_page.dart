import '../../../core/core.dart';

/// A mock document page made of placeholder text lines.
class DocumentPage extends StatelessWidget {
  const DocumentPage({super.key, required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    final line = context.palette.divider;
    return AspectRatio(
      aspectRatio: 1 / 1.414,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 16, width: 180, color: const Color(0xFF111B21)),
            const SizedBox(height: 18),
            for (var i = 0; i < 14; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                height: 8,
                width: i % 5 == 4 ? 140 : double.infinity,
                color: line,
              ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Text('Page $page', style: const TextStyle(color: Colors.black54, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
