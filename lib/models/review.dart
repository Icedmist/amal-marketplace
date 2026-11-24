class ProductReview {
  const ProductReview({
    required this.id,
    required this.productId,
    required this.rating,
    this.comment,
    this.authorName,
    this.photoUrl,
    this.isVerified = false,
    this.createdAt,
  });

  final String id;
  final String productId;
  final double rating;
  final String? comment;
  final String? authorName;
  final String? photoUrl;
  final bool isVerified;
  final DateTime? createdAt;

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'] as String,
      productId: (json['product_id'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: json['comment'] as String?,
      authorName: json['author_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      isVerified: json['is_verified'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
