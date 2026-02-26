enum DiaryTemplate {
  memoir('memoir');

  final String value;

  const DiaryTemplate(this.value);
}

abstract class DiaryTemplateConst {
  static const memoirTag = '回忆录';
  static const legacyMemoirTag = '童年回忆录';

  static bool hasMemoirTag(Iterable<String> tags) {
    return tags.contains(memoirTag) || tags.contains(legacyMemoirTag);
  }
}
