class Favorite {
  final int id; // autoincrement
  final int userId;
  final int medicineId;
  final DateTime createdAt;
  const Favorite({
    required this.id,
    required this.userId,
    required this.medicineId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'medicine_id': medicineId,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Favorite.fromMap(Map<String, dynamic> map) => Favorite(
    id: map['id'] as int,
    userId: map['user_id'] as int,
    medicineId: map['medicine_id'] as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    ),
  );
}
