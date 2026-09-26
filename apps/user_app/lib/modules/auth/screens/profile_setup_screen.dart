import '../../../core/core.dart';

/// After the first OTP login: Personal (name only) or Business (business name,
/// business address, bio), then the two privacy switches.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, this.from});

  final String? from;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String _type = 'personal';
  final _name = TextEditingController();
  final _businessName = TextEditingController();
  final _address = TextEditingController();
  final _bio = TextEditingController();
  bool _groupLocation = true;
  bool _searchable = true;
  bool _saving = false;

  bool get _business => _type == 'business';

  @override
  void dispose() {
    _name.dispose();
    _businessName.dispose();
    _address.dispose();
    _bio.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_business) {
      if (_businessName.text.trim().isEmpty) return 'Enter your business name';
      if (_address.text.trim().length < 3) return 'Enter your business address';
    } else if (_name.text.trim().isEmpty) {
      return 'Enter your name';
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) return context.showSnack(error);
    setState(() => _saving = true);
    final auth = AuthService.instance;
    try {
      await auth.completeProfile(
        _business
            ? {'accountType': 'business', 'businessName': _businessName.text.trim(), 'businessAddress': _address.text.trim(), 'bio': _bio.text.trim()}
            : {'accountType': 'personal', 'name': _name.text.trim()},
      );
      await auth.updateProfile({'privacy': {'searchable': _searchable}});
      await auth.setGroupLocation(_groupLocation);
      if (!mounted) return;
      context.go(widget.from ?? AppRoutes.home);
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile info'), automaticallyImplyLeading: false),
        body: FormPage(
          items: [
            Text('Tell us who you are', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('You can change this later in Profile.', style: TextStyle(color: p.textSecondary)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _TypeCard(icon: Icons.person_outline, label: 'Personal', selected: !_business, onTap: () => setState(() => _type = 'personal'))),
                const SizedBox(width: 12),
                Expanded(child: _TypeCard(icon: Icons.storefront_outlined, label: 'Business', selected: _business, onTap: () => setState(() => _type = 'business'))),
              ],
            ),
            const SizedBox(height: 24),
            if (_business) ...[
              AppTextField(key: const ValueKey('bname'), controller: _businessName, label: 'Business name', hint: 'e.g. Verma Traders', prefixIcon: Icons.storefront_outlined, maxLength: 60),
              const SizedBox(height: 8),
              AppTextField(controller: _address, label: 'Business address', hint: 'Shop / street, area, city', prefixIcon: Icons.location_on_outlined, maxLines: 2, maxLength: 200),
              const SizedBox(height: 8),
              AppTextField(controller: _bio, label: 'Bio', hint: 'What does your business do?', prefixIcon: Icons.info_outline, maxLines: 3, maxLength: 140),
            ] else
              AppTextField(key: const ValueKey('pname'), controller: _name, label: 'Your name', hint: 'Full name', prefixIcon: Icons.person_outline, maxLength: 60),
            const SizedBox(height: 16),
            Text('Settings', style: TextStyle(color: p.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.share_location_outlined),
              title: const Text('Group user location'),
              subtitle: const Text('Share your location with groups that use location'),
              value: _groupLocation,
              onChanged: (v) => setState(() => _groupLocation = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.person_search_outlined),
              title: const Text('Anyone can find me'),
              subtitle: const Text('Let people search you by user ID or name'),
              value: _searchable,
              onChanged: (v) => setState(() => _searchable = v),
            ),
          ],
          bottom: PrimaryButton(label: 'Next', loading: _saving, onPressed: _saving ? null : _save),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: selected ? p.activeBg : p.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, size: 30, color: selected ? AppColors.primary : p.textSecondary),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? context.colors.onSurface : p.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
