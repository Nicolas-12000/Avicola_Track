import '../../core/utils/json_parsers.dart';

class BiosecurityChecklistModel {
  final int id;
  final int farmId;
  final int? shedId; // null si aplica a toda la granja
  final String
  checklistType; // daily, weekly, monthly, pre_flock, post_flock, emergency
  final DateTime performedDate;
  final int performedBy; // user_id
  final String status; // completed, incomplete, failed
  final List<BiosecurityCheckItem> items;
  final double complianceScore; // 0-100
  final String? notes;
  final List<String>? photoUrls;
  final String? correctiveActions;
  final DateTime? correctiveActionsDeadline;
  final DateTime createdAt;

  const BiosecurityChecklistModel({
    required this.id,
    required this.farmId,
    this.shedId,
    required this.checklistType,
    required this.performedDate,
    required this.performedBy,
    required this.status,
    required this.items,
    required this.complianceScore,
    this.notes,
    this.photoUrls,
    this.correctiveActions,
    this.correctiveActionsDeadline,
    required this.createdAt,
  });

  factory BiosecurityChecklistModel.fromJson(Map<String, dynamic> json) {
    return BiosecurityChecklistModel(
      id: json['id'] as int,
      farmId: json['farm_id'] as int,
      shedId: json['shed_id'] as int?,
      checklistType: json['checklist_type'] as String,
      performedDate: DateTime.parse(json['performed_date'] as String),
      performedBy: json['performed_by'] as int,
      status: json['status'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => BiosecurityCheckItem.fromJson(e as Map<String, dynamic>))
          .toList(),
        complianceScore: JsonParsers.toDouble(json['compliance_score']),
      notes: json['notes'] as String?,
      photoUrls: (json['photo_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      correctiveActions: json['corrective_actions'] as String?,
      correctiveActionsDeadline: json['corrective_actions_deadline'] != null
          ? DateTime.parse(json['corrective_actions_deadline'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_id': farmId,
      'shed_id': shedId,
      'checklist_type': checklistType,
      'performed_date': performedDate.toIso8601String(),
      'performed_by': performedBy,
      'status': status,
      'items': items.map((e) => e.toJson()).toList(),
      'compliance_score': complianceScore,
      'notes': notes,
      'photo_urls': photoUrls,
      'corrective_actions': correctiveActions,
      'corrective_actions_deadline': correctiveActionsDeadline
          ?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  BiosecurityChecklistModel copyWith({
    int? id,
    int? farmId,
    int? shedId,
    String? checklistType,
    DateTime? performedDate,
    int? performedBy,
    String? status,
    List<BiosecurityCheckItem>? items,
    double? complianceScore,
    String? notes,
    List<String>? photoUrls,
    String? correctiveActions,
    DateTime? correctiveActionsDeadline,
    DateTime? createdAt,
  }) {
    return BiosecurityChecklistModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      shedId: shedId ?? this.shedId,
      checklistType: checklistType ?? this.checklistType,
      performedDate: performedDate ?? this.performedDate,
      performedBy: performedBy ?? this.performedBy,
      status: status ?? this.status,
      items: items ?? this.items,
      complianceScore: complianceScore ?? this.complianceScore,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      correctiveActions: correctiveActions ?? this.correctiveActions,
      correctiveActionsDeadline:
          correctiveActionsDeadline ?? this.correctiveActionsDeadline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters
  bool get isCompleted => status == 'completed';
  bool get hasFailed => status == 'failed';
  bool get needsCorrectiveActions =>
      correctiveActions != null && correctiveActions!.isNotEmpty;
  bool get isCorrectiveActionsOverdue {
    if (correctiveActionsDeadline == null) return false;
    return DateTime.now().isAfter(correctiveActionsDeadline!);
  }

  int get completedItems => items.where((item) => item.isCompliant).length;
  int get failedItems =>
      items.where((item) => !item.isCompliant && !item.isNotApplicable).length;
  bool get hasGoodCompliance => complianceScore >= 80;
  bool get hasPoorCompliance => complianceScore < 60;

}

class BiosecurityCheckItem {
  final String
  category; // access_control, sanitation, equipment, personnel, waste_management, feed_water
  final String description;
  final bool isCompliant;
  final bool isNotApplicable;
  final String? notes;
  final String? photoUrl;

  const BiosecurityCheckItem({
    required this.category,
    required this.description,
    required this.isCompliant,
    required this.isNotApplicable,
    this.notes,
    this.photoUrl,
  });

  factory BiosecurityCheckItem.fromJson(Map<String, dynamic> json) {
    return BiosecurityCheckItem(
      category: json['category'] as String,
      description: json['description'] as String,
      isCompliant: json['is_compliant'] as bool,
      isNotApplicable: json['is_not_applicable'] as bool? ?? false,
      notes: json['notes'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'description': description,
      'is_compliant': isCompliant,
      'is_not_applicable': isNotApplicable,
      'notes': notes,
      'photo_url': photoUrl,
    };
  }

  BiosecurityCheckItem copyWith({
    String? category,
    String? description,
    bool? isCompliant,
    bool? isNotApplicable,
    String? notes,
    String? photoUrl,
  }) {
    return BiosecurityCheckItem(
      category: category ?? this.category,
      description: description ?? this.description,
      isCompliant: isCompliant ?? this.isCompliant,
      isNotApplicable: isNotApplicable ?? this.isNotApplicable,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
