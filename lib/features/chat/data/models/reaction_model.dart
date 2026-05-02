class ReactionModel {
  final int id;
  final int messageId;
  final int userId;
  final String userName;
  final String reaction;

  ReactionModel({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.userName,
    required this.reaction,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      id: json['id'],
      messageId: json['message_id'],
      userId: json['user_id'],
      userName: json['user']?['name'] ?? 'Unknown',
      reaction: json['reaction'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'user_id': userId,
      'user': {'name': userName},
      'reaction': reaction,
    };
  }
}
