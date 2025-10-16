class Course {
  final int id;
  final String title;
  final String imageUrl;
  final String descriptionImage;
  final String descriptionImage2;

  Course({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.descriptionImage,
    required this.descriptionImage2,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'] ?? "",
      descriptionImage: json['description_image'] ?? "",
      descriptionImage2: json['description_image2'] ?? "",
    );
  }
}
