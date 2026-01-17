class FarmModel {
  final int id;
  final String name;
  final String location;
  final int? farmManagerId;
  final String? farmManagerName;
  final int totalCapacity;
  final int activeSheds;
  final int? shedsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FarmModel({
    required this.id,
    required this.name,
    required this.location,
    this.farmManagerId,
    this.farmManagerName,
    required this.totalCapacity,
    required this.activeSheds,
    this.shedsCount,
    required this.createdAt,
    this.updatedAt,
  });

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    return FarmModel(
      id: json['id'] as int,
      name: json['name'] as String,
      location: json['location'] as String? ?? '',
      farmManagerId: json['farm_manager'] as int?,
      farmManagerName: json['farm_manager_name'] as String?,
      totalCapacity: json['total_capacity'] as int? ?? 0,
      activeSheds: json['active_sheds'] as int? ?? 0,
      shedsCount: json['sheds_count'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'farm_manager': farmManagerId,
      'total_capacity': totalCapacity,
      'active_sheds': activeSheds,
    };
  }
}
