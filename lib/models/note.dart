class Note {
  String text;
  String audioPath;
  String? photo;
  String? location;
  int mood;

  Note({
    required this.text,
    required this.audioPath,
    this.photo,
    this.location,
    required this.mood,
  });
}