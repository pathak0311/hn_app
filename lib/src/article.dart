class Article {
  final String text;
  final String url;
  final String by;
  final int time;
  final int score;

  const Article(this.text, this.url, this.by, this.time, this.score);

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(json['text'] ?? '[null]', json['url'] ?? '[null]',
        json['by'] ?? '[null]', json['time'] ?? '[null]', json['score'] ?? 0);
  }
}
