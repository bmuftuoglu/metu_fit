import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_codeCtrl.text.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Davet kodu en az 8 karakter olmalı')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(groupsDatasourceProvider).joinGroup(_codeCtrl.text.trim().toUpperCase());
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gruba Katıl')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.group_add, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            TextFormField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Davet Kodu',
                hintText: 'XXXXXXXX',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Katıl'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
