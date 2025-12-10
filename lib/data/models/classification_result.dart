class ClassificationResult {
  final String categoryId;
  final bool isNewCategory;
  final String? newCategoryName;
  final String? newDescription;

  const ClassificationResult({
    required this.categoryId,
    required this.isNewCategory,
    this.newCategoryName,
    this.newDescription,
  });

  // 从JSON创建实例
  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      categoryId: json['categoryId'] as String,
      isNewCategory: json['isNewCategory'] as bool? ?? false,
      newCategoryName: json['newCategoryName'] as String?,
      newDescription: json['newDescription'] as String?,
    );
  }

  // 从AI响应JSON创建实例
  factory ClassificationResult.fromAiResponse(Map<String, dynamic> json) {
    final categoryId = json['categoryId'] as String;
    final isNew = categoryId == 'new';

    final newCategory = json['newCategory'] as Map<String, dynamic>?;

    return ClassificationResult(
      categoryId: categoryId,
      isNewCategory: isNew,
      newCategoryName: newCategory?['name'] as String?,
      newDescription: newCategory?['description'] as String?,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'isNewCategory': isNewCategory,
      'newCategoryName': newCategoryName,
      'newDescription': newDescription,
    };
  }

  // 创建副本
  ClassificationResult copyWith({
    String? categoryId,
    bool? isNewCategory,
    String? newCategoryName,
    String? newDescription,
  }) {
    return ClassificationResult(
      categoryId: categoryId ?? this.categoryId,
      isNewCategory: isNewCategory ?? this.isNewCategory,
      newCategoryName: newCategoryName ?? this.newCategoryName,
      newDescription: newDescription ?? this.newDescription,
    );
  }

  // 获取显示名称
  String get displayName {
    if (isNewCategory && newCategoryName != null) {
      return newCategoryName!;
    }

    // 映射已知分类ID到显示名称
    switch (categoryId) {
      case 'work':
        return '工作';
      case 'study':
        return '学习';
      case 'life':
        return '生活';
      default:
        return categoryId;
    }
  }

  // 获取分类ID（如果是新分类，返回新分类名称）
  String get effectiveCategoryId {
    if (isNewCategory && newCategoryName != null) {
      return newCategoryName!;
    }
    return categoryId;
  }

  // 获取分类描述
  String get effectiveDescription {
    if (isNewCategory && newDescription != null) {
      return newDescription!;
    }

    return '';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassificationResult &&
        other.categoryId == categoryId &&
        other.isNewCategory == isNewCategory &&
        other.newCategoryName == newCategoryName &&
        other.newDescription == newDescription;
  }

  @override
  int get hashCode {
    return categoryId.hashCode ^
        isNewCategory.hashCode ^
        newCategoryName.hashCode ^
        newDescription.hashCode;
  }

  @override
  String toString() {
    return 'ClassificationResult{categoryId: $categoryId, isNewCategory: $isNewCategory, newCategoryName: $newCategoryName}';
  }
}