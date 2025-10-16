class SearchItem {
  final int id;
  final String title;

  SearchItem({required this.id, required this.title});

  factory SearchItem.fromJson(Map<String, dynamic> json) {
    return SearchItem(
      id: json['id'],
      title: json['title'],
    );
  }

  @override
  String toString() => title;
}
