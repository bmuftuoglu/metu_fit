import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../providers/groups_provider.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gruplar')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join',
            onPressed: () async {
              await context.push(RouteNames.joinGroup);
              ref.invalidate(myGroupsProvider);
            },
            child: const Icon(Icons.login),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () async {
              await context.push(RouteNames.createGroup);
              ref.invalidate(myGroupsProvider);
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz grubun yok', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Yeni bir grup oluştur veya davet koduyla katıl',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myGroupsProvider),
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (_, i) {
                final g = groups[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(g.name[0].toUpperCase()),
                  ),
                  title: Text(g.name),
                  subtitle: Text('${g.memberCount} üye • ${g.myRole ?? 'member'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/main/groups/${g.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
