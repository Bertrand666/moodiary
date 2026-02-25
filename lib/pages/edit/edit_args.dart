import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/common/values/diary_template.dart';
import 'package:moodiary/common/values/diary_type.dart';

class EditCreateArgs {
  final DiaryDomain domain;
  final DiaryType type;
  final String? categoryId;
  final DiaryTemplate? template;

  const EditCreateArgs({
    required this.domain,
    required this.type,
    this.categoryId,
    this.template,
  });
}
