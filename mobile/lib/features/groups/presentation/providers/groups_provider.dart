import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/groups_remote_datasource.dart';
import '../../data/models/group_model.dart';

final groupsDatasourceProvider = Provider((_) => GroupsRemoteDatasource());

final myGroupsProvider = FutureProvider<List<GroupModel>>((ref) {
  return ref.read(groupsDatasourceProvider).getMyGroups();
});

final groupDetailProvider = FutureProvider.family<GroupModel, String>((ref, groupId) {
  return ref.read(groupsDatasourceProvider).getGroup(groupId);
});

final groupMembersProvider = FutureProvider.family<List<GroupMemberModel>, String>((ref, groupId) {
  return ref.read(groupsDatasourceProvider).getMembers(groupId);
});
