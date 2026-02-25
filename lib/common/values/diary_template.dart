enum DiaryTemplate {
  childhoodMemoir('childhoodMemoir');

  final String value;

  const DiaryTemplate(this.value);
}

abstract class DiaryTemplateConst {
  static const childhoodMemoirTag = '童年回忆录';
}
