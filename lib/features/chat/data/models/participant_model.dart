class ParticipantModel {
  final int id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final String role;

  ParticipantModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
    this.role = 'member',
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    String role = 'member';
    if (json['pivot'] != null && json['pivot']['role'] != null) {
      role = json['pivot']['role'];
    }

    return ParticipantModel(
      id: json['id'],
      name: json['name'] ?? json['username'] ?? 'Unknown',
      avatarUrl: json['avatar'] ?? json['avatar_url'],
      isOnline: json['is_online'] ?? false,
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'is_online': isOnline,
      'role': role,
    };
  }
}
