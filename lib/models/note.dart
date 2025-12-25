class Note {
  int? id; // db primary key
  String text;
  String audioPath;
  String? photo;
  String? location;
  double? latitude;
  double? longitude;
  int mood; // store enum index or scaled value
  DateTime createdAt;

  Note({
    this.id,
    required this.text,
    required this.audioPath,
    this.photo,
    this.location,
    this.latitude,
    this.longitude,
    required this.mood,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'audio_path': audioPath,
    'photo': photo,
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'mood': mood,
    'created_at': createdAt.toIso8601String(),
  };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
    id: map['id'] as int?,
    text: map['text'] as String? ?? '',
    audioPath: map['audio_path'] as String? ?? '',
    photo: map['photo'] as String?,
    location: map['location'] as String?,
    latitude: (map['latitude'] as num?)?.toDouble(),
    longitude: (map['longitude'] as num?)?.toDouble(),
    mood: map['mood'] as int? ?? 0,
    createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
  );
}
