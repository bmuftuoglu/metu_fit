import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/food_provider.dart';

class AddCustomFoodScreen extends ConsumerStatefulWidget {
  final String date;
  const AddCustomFoodScreen({super.key, required this.date});

  @override
  ConsumerState<AddCustomFoodScreen> createState() => _AddCustomFoodScreenState();
}

class _AddCustomFoodScreenState extends ConsumerState<AddCustomFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(foodDatasourceProvider).createCustomFoodItem(
            name: _nameCtrl.text.trim(),
            brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
            caloriesPer100g: double.parse(_calCtrl.text),
            proteinG: double.tryParse(_proteinCtrl.text),
            carbsG: double.tryParse(_carbsCtrl.text),
            fatG: double.tryParse(_fatCtrl.text),
          );
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Yiyecek Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Ad *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brandCtrl,
              decoration: const InputDecoration(labelText: 'Marka (opsiyonel)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _calCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kalori (100g başına) *', suffixText: 'kcal'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Kalori gerekli';
                if (double.tryParse(v) == null) return 'Geçerli sayı girin';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _proteinCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Protein', suffixText: 'g'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _carbsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Karbonhidrat', suffixText: 'g'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _fatCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Yağ', suffixText: 'g'),
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
