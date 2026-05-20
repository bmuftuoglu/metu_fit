import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/posts_provider.dart';

class CreateMealPostScreen extends ConsumerStatefulWidget {
  final String groupId;
  const CreateMealPostScreen({super.key, required this.groupId});

  @override
  ConsumerState<CreateMealPostScreen> createState() => _CreateMealPostScreenState();
}

class _CreateMealPostScreenState extends ConsumerState<CreateMealPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _calCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(postsDatasourceProvider).createMealPost(
            groupId: widget.groupId,
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            calories: double.parse(_calCtrl.text),
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
      appBar: AppBar(title: const Text('Öğün Paylaş')),
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
              controller: _calCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kalori *', suffixText: 'kcal'),
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
