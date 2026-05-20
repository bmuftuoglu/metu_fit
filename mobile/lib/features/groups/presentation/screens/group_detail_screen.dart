import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/groups_provider.dart';
import '../../../posts/presentation/screens/group_feed_screen.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));

    return groupAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Hata: $e'))),
      data: (group) => Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            if (group.myRole == 'captain')
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Kodu yenile',
                onPressed: () async {
                  final updated = await ref.read(groupsDatasourceProvider).regenerateInvite(group.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Yeni kod: ${updated.inviteCode}')),
                    );
                    ref.invalidate(groupDetailProvider(widget.groupId));
                  }
                },
              ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Kodu kopyala',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: group.inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kod kopyalandı: ${group.inviteCode}')),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Feed'),
              Tab(text: 'Üyeler'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            GroupFeedScreen(groupId: widget.groupId, myRole: group.myRole),
            _MembersTab(groupId: widget.groupId, myRole: group.myRole),
          ],
        ),
      ),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  final String groupId;
  final String? myRole;
  const _MembersTab({required this.groupId, this.myRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final roleLabels = {'captain': 'Kaptan', 'dietitian': 'Diyetisyen', 'member': 'Üye'};

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (members) => ListView.builder(
        itemCount: members.length,
        itemBuilder: (_, i) {
          final m = members[i];
          return ListTile(
            leading: CircleAvatar(child: Text(m.fullName[0].toUpperCase())),
            title: Text(m.fullName),
            subtitle: Text(roleLabels[m.role] ?? m.role),
            trailing: myRole == 'captain'
                ? PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'remove') {
                        await ref.read(groupsDatasourceProvider).removeMember(groupId, m.userId);
                        ref.invalidate(groupMembersProvider(groupId));
                      } else {
                        await ref.read(groupsDatasourceProvider).updateMemberRole(groupId, m.userId, action);
                        ref.invalidate(groupMembersProvider(groupId));
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'captain', child: Text('Kaptan Yap')),
                      const PopupMenuItem(value: 'dietitian', child: Text('Diyetisyen Yap')),
                      const PopupMenuItem(value: 'member', child: Text('Üye Yap')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'remove', child: Text('Çıkar', style: TextStyle(color: Colors.red))),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }
}
