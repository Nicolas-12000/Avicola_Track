class ShedModel {
  final int id;
  final String name;
  final int farm;
  final String? farmName;
  final int capacity;
  final int? assignedWorker;
  final String? assignedWorkerName;
  final int? currentFlock;
  final int currentOccupancy;
  final bool isOccupied;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShedModel({
    required this.id,
    required this.name,
    required this.farm,
    this.farmName,
    required this.capacity,
    this.assignedWorker,
    this.assignedWorkerName,
    this.currentFlock,
    required this.currentOccupancy,
    required this.isOccupied,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShedModel.fromJson(Map<String, dynamic> json) {
    return ShedModel(
      id: json['id'] as int,
      name: json['name'] as String,
      farm: json['farm'] as int,
      farmName: json['farm_name'] as String?,
      capacity: json['capacity'] as int,
      assignedWorker: json['assigned_worker'] as int?,
      assignedWorkerName: json['assigned_worker_name'] as String?,
      currentFlock: json['current_flock'] as int?,
      currentOccupancy: json['current_occupancy'] as int? ?? 0,
      isOccupied: json['is_occupied'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'farm': farm,
      'capacity': capacity,
      'assigned_worker': assignedWorker,
      'current_flock': currentFlock,
      'current_occupancy': currentOccupancy,
      'is_occupied': isOccupied,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get occupancyPercentage {
    if (capacity == 0) return 0.0;
    return (currentOccupancy / capacity) * 100;
  }

  ShedModel copyWith({
    int? id,
    String? name,
    int? farm,
    String? farmName,
    int? capacity,
    int? assignedWorker,
    String? assignedWorkerName,
    int? currentFlock,
    int? currentOccupancy,
    bool? isOccupied,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShedModel(
      id: id ?? this.id,
      name: name ?? this.name,
      farm: farm ?? this.farm,
      farmName: farmName ?? this.farmName,
      capacity: capacity ?? this.capacity,
      assignedWorker: assignedWorker ?? this.assignedWorker,
      assignedWorkerName: assignedWorkerName ?? this.assignedWorkerName,
      currentFlock: currentFlock ?? this.currentFlock,
      currentOccupancy: currentOccupancy ?? this.currentOccupancy,
      isOccupied: isOccupied ?? this.isOccupied,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
