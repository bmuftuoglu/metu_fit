class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String inviteCode;
  final String createdBy;
  final int memberCount;
  final String? myRole;
  final String createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.inviteCode,
    required this.createdBy,
    required this.memberCount,
    this.myRole,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        inviteCode: json['invite_code'] as String,
        createdBy: json['created_by'] as String,
        memberCount: json['member_count'] as int? ?? 0,
        myRole: json['my_role'] as String?,
        createdAt: json['created_at'] as String,
      );
}

class GroupMemberModel {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String role;
  final String joinedAt;

  const GroupMemberModel({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) => GroupMemberModel(
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String,
        joinedAt: json['joined_at'] as String,
      );
}
