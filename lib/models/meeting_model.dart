class MeetingModel {
  final String? id;
  final String? clientName;
  final String? projectName;
  final String? avatarUrl;
  final double? dealAmount;
  final String? fromAmount;
  final String? timeAgo;
  final int? messageCount;

  MeetingModel({
    this.id,
    this.clientName,
    this.projectName,
    this.avatarUrl,
    this.dealAmount,
    this.fromAmount,
    this.timeAgo,
    this.messageCount,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'],
      clientName: json['client_name'],
      projectName: json['project_name'],
      avatarUrl: json['avatar_url'],
      dealAmount: (json['deal_amount'] as num?)?.toDouble(),
      fromAmount: json['from_amount'],
      timeAgo: json['time_ago'],
      messageCount: json['message_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_name': clientName,
      'project_name': projectName,
      'avatar_url': avatarUrl,
      'deal_amount': dealAmount,
      'from_amount': fromAmount,
      'time_ago': timeAgo,
      'message_count': messageCount,
    };
  }
}
