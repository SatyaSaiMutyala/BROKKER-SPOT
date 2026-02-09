class ProjectDealModel {
  final String? id;
  final String? propertyName;
  final String? location;
  final String? imageUrl;
  final double? price;
  final String? currency;
  final String? brokerName;
  final String? brokerAvatarUrl;
  final double? brokerRating;
  final int? bedrooms;
  final int? sqft;
  final String? uid;
  final String? date;
  final String? status;
  final List<TrackingStepModel>? steps;

  ProjectDealModel({
    this.id,
    this.propertyName,
    this.location,
    this.imageUrl,
    this.price,
    this.currency,
    this.brokerName,
    this.brokerAvatarUrl,
    this.brokerRating,
    this.bedrooms,
    this.sqft,
    this.uid,
    this.date,
    this.status,
    this.steps,
  });

  factory ProjectDealModel.fromJson(Map<String, dynamic> json) {
    return ProjectDealModel(
      id: json['id'],
      propertyName: json['property_name'],
      location: json['location'],
      imageUrl: json['image_url'],
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'],
      brokerName: json['broker_name'],
      brokerAvatarUrl: json['broker_avatar_url'],
      brokerRating: (json['broker_rating'] as num?)?.toDouble(),
      bedrooms: json['bedrooms'],
      sqft: json['sqft'],
      uid: json['uid'],
      date: json['date'],
      status: json['status'],
      steps: (json['steps'] as List?)
          ?.map((e) => TrackingStepModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_name': propertyName,
      'location': location,
      'image_url': imageUrl,
      'price': price,
      'currency': currency,
      'broker_name': brokerName,
      'broker_avatar_url': brokerAvatarUrl,
      'broker_rating': brokerRating,
      'bedrooms': bedrooms,
      'sqft': sqft,
      'uid': uid,
      'date': date,
      'status': status,
      'steps': steps?.map((e) => e.toJson()).toList(),
    };
  }
}

enum StepType { submitted, bookingLink, paymentProof, eSignature, spaDocument, downPayment, paymentPlan }

enum StepStatus { pending, completed, verified, signed, booked, notSignedYet, notStarted }

class TrackingStepModel {
  final String? title;
  final String? subtitle;
  final String? date;
  final StepType? type;
  StepStatus status;
  final String? actionLabel;

  TrackingStepModel({
    this.title,
    this.subtitle,
    this.date,
    this.type,
    this.status = StepStatus.pending,
    this.actionLabel,
  });

  factory TrackingStepModel.fromJson(Map<String, dynamic> json) {
    return TrackingStepModel(
      title: json['title'],
      subtitle: json['subtitle'],
      date: json['date'],
      type: json['type'] != null
          ? StepType.values[json['type']]
          : null,
      status: json['status'] != null
          ? StepStatus.values[json['status']]
          : StepStatus.pending,
      actionLabel: json['action_label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'date': date,
      'type': type?.index,
      'status': status.index,
      'action_label': actionLabel,
    };
  }

  String get statusLabel {
    switch (status) {
      case StepStatus.completed:
        return 'Summited';
      case StepStatus.verified:
        return 'Verified';
      case StepStatus.signed:
        return 'Signed';
      case StepStatus.booked:
        return 'Booked';
      case StepStatus.notSignedYet:
        return 'Not Signed Yet';
      case StepStatus.notStarted:
        return 'Not Started yet';
      case StepStatus.pending:
        return 'Pending';
    }
  }
}
