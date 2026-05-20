import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await context.push(RouteNames.editProfile);
              ref.invalidate(profileProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (user) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 36, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.fullName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ProfileRow('Boy', user.heightCm != null ? '${user.heightCm!.round()} cm' : '-'),
                    const Divider(height: 16),
                    _ProfileRow('Kilo', user.weightKg != null ? '${user.weightKg!.toStringAsFixed(1)} kg' : '-'),
                    const Divider(height: 16),
                    _ProfileRow('Yaş', user.age != null ? '${user.age} yaş' : '-'),
                    const Divider(height: 16),
                    _ProfileRow('Kalori Hedefi', user.goalCalories != null ? '${user.goalCalories} kcal' : '-'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
