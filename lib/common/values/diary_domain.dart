enum DiaryDomain {
  normal('normal'),
  memoir('memoir'),
  note('note');

  final String value;

  const DiaryDomain(this.value);

  static DiaryDomain fromValue(String value) {
    return DiaryDomain.values.firstWhere(
      (domain) => domain.value == value,
      orElse: () => DiaryDomain.normal,
    );
  }
}

extension DiaryDomainTag on DiaryDomain {
  String get logicTag => 'diary_logic_$value';

  String tabTag(String? categoryId) => 'diary_tab_${value}_${categoryId ?? 'default'}';

  String get defaultTabTag => tabTag(null);
}
