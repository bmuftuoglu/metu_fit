import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/group_model.dart';

class GroupsRemoteDatasource {
  final Dio _dio = DioClient.instance;

  Future<List<GroupModel>> getMyGroups() async {
    final response = await _dio.get(ApiEndpoints.groups);
    return (response.data as List).map((e) => GroupModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GroupModel> createGroup({required String name, String? description}) async {
    final response = await _dio.post(ApiEndpoints.groups, data: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return GroupModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GroupModel> joinGroup(String inviteCode) async {
    final response = await _dio.post(ApiEndpoints.joinGroup, data: {'invite_code': inviteCode});
    return GroupModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GroupModel> getGroup(String groupId) async {
    final response = await _dio.get(ApiEndpoints.group(groupId));
    return GroupModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<GroupMemberModel>> getMembers(String groupId) async {
    final response = await _dio.get(ApiEndpoints.groupMembers(groupId));
    return (response.data as List).map((e) => GroupMemberModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GroupModel> regenerateInvite(String groupId) async {
    final response = await _dio.post(ApiEndpoints.regenerateInvite(groupId));
    return GroupModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateMemberRole(String groupId, String userId, String role) async {
    await _dio.patch(ApiEndpoints.groupMember(groupId, userId), data: {'role': role});
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _dio.delete(ApiEndpoints.groupMember(groupId, userId));
  }

  Future<void> leaveGroup(String groupId) async {
    await _dio.delete('${ApiEndpoints.group(groupId)}/members/me');
  }

  Future<void> deleteGroup(String groupId) async {
    await _dio.delete(ApiEndpoints.group(groupId));
  }
}
