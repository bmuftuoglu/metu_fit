import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/posts_provider.dart';

class CreateActivityPostScreen extends ConsumerStatefulWidget {
  final String groupId;
  const CreateActivityPostScreen({super.key, required this.groupId});

  @override
  ConsumerState<CreateActivityPostScreen> createState() => _CreateActivityPostScreenState();
}

class _CreateActivityPostScreenState extends ConsumerState<CreateActivityPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _durationCtrl.dispose();
    _calCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(postsDatasourceProvider).createActivityPost(
            groupId: widget.groupId,
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            durationSeconds: int.parse(_durationCtrl.text) * 60,
            caloriesBurned: double.parse(_calCtrl.text),
          );
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktivite Paylaş')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Süre *', suffixText: 'dakika'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Süre gerekli';
                if (int.tryParse(v) == null) return 'Geçerli sayı girin';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _calCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Yakılan Kalori *', suffixText: 'kcal'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Kalori gerekli';
                if (double.tryParse(v) == null) return 'Geçerli sayı girin';
                return null;
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Paylaş'),
            ),
          ],
        ),
      ),
    );
  }
}
