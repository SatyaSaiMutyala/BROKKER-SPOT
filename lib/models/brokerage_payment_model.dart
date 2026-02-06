class DealModel {
  final String? id;
  final String? projectName;
  final String? propertyType;
  final String? referenceId;
  final String? status;
  final String? imageUrl;
  final String? brokerAvatarUrl;
  final double? totalAmount;

  DealModel({
    this.id,
    this.projectName,
    this.propertyType,
    this.referenceId,
    this.status,
    this.imageUrl,
    this.brokerAvatarUrl,
    this.totalAmount,
  });

  factory DealModel.fromJson(Map<String, dynamic> json) {
    return DealModel(
      id: json['id'],
      projectName: json['project_name'],
      propertyType: json['property_type'],
      referenceId: json['reference_id'],
      status: json['status'],
      imageUrl: json['image_url'],
      brokerAvatarUrl: json['broker_avatar_url'],
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_name': projectName,
      'property_type': propertyType,
      'reference_id': referenceId,
      'status': status,
      'image_url': imageUrl,
      'broker_avatar_url': brokerAvatarUrl,
      'total_amount': totalAmount,
    };
  }
}

class BrokerPaymentModel {
  final String? id;
  final String? brokerName;
  final String? projectName;
  final String? avatarUrl;
  final double? amount;
  final String? dealId;

  BrokerPaymentModel({
    this.id,
    this.brokerName,
    this.projectName,
    this.avatarUrl,
    this.amount,
    this.dealId,
  });

  factory BrokerPaymentModel.fromJson(Map<String, dynamic> json) {
    return BrokerPaymentModel(
      id: json['id'],
      brokerName: json['broker_name'],
      projectName: json['project_name'],
      avatarUrl: json['avatar_url'],
      amount: (json['amount'] as num?)?.toDouble(),
      dealId: json['deal_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'broker_name': brokerName,
      'project_name': projectName,
      'avatar_url': avatarUrl,
      'amount': amount,
      'deal_id': dealId,
    };
  }
}
