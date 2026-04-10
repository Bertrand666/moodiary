import 'package:isar/isar.dart';
import 'package:moodiary/common/values/diary_domain.dart';

part 'category.g.dart';

@collection
class Category {
  @Id()
  late String id;

  late String categoryName;

  @Index()
  String domain = DiaryDomain.normal.value;

  String? parentId;

  @Index()
  String get level => parentId ?? 'root';

  Category();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryName': categoryName,
      'domain': domain,
      'parentId': parentId,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category()
      ..id = json['id'] as String
      ..categoryName = json['categoryName'] as String
      ..domain = (json['domain'] as String?) ?? DiaryDomain.normal.value
      ..parentId = json['parentId'] as String?;
  }
}
