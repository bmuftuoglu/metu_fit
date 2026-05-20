import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  void _initFromProfile() {
    if (_initialized) return;
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null) return;
    _nameCtrl.text = profile.fullName;
    _heightCtrl.text = profile.heightCm?.toString() ?? '';
    _weightCtrl.text = profile.weightKg?.toString() ?? '';
    _ageCtrl.text = profile.age?.toString() ?? '';
    _goalCtrl.text = profile.goalCalories?.toString() ?? '';
    _initialized = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(profileDatasourceProvider).updateProfile(
            fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
            heightCm: double.tryParse(_heightCtrl.text),
            weightKg: double.tryParse(_weightCtrl.text),
            age: int.tryParse(_ageCtrl.text),
            goalCalories: int.tryParse(_goalCtrl.text),
          );
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    _initFromProfile();
    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Boy', suffixText: 'cm'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Kilo', suffixText: 'kg'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Yaş'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _goalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Kalori Hedefi', suffixText: 'kcal'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
