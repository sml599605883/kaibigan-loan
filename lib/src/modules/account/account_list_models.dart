import '../../core/json/json.dart';

class AccountListItem {
  const AccountListItem({
    required this.bindId,
    required this.typeName,
    required this.typeIconUrl,
    required this.providerName,
    required this.displayValue,
    this.isUnderMaintenance = false,
    required this.isMain,
  });

  factory AccountListItem.fromJson(
    Json json, {
    required String typeName,
    required String typeIconUrl,
  }) {
    return AccountListItem(
      bindId: json['smokehouse'].stringValue.trim(),
      typeName: typeName.trim(),
      typeIconUrl: typeIconUrl.trim(),
      providerName: json['postaccident'].stringValue.trim(),
      displayValue: json['flamen'].stringValue.trim(),
      isUnderMaintenance: json['bondmen'].intOrNull == 0,
      isMain: json['uptime'].boolValue,
    );
  }

  final String bindId;
  final String typeName;
  final String typeIconUrl;
  final String providerName;
  final String displayValue;
  final bool isUnderMaintenance;
  final bool isMain;

  @override
  bool operator ==(Object other) {
    return other is AccountListItem &&
        bindId == other.bindId &&
        typeName == other.typeName &&
        typeIconUrl == other.typeIconUrl &&
        providerName == other.providerName &&
        displayValue == other.displayValue &&
        isUnderMaintenance == other.isUnderMaintenance &&
        isMain == other.isMain;
  }

  @override
  int get hashCode => Object.hash(
    bindId,
    typeName,
    typeIconUrl,
    providerName,
    displayValue,
    isUnderMaintenance,
    isMain,
  );
}

class AccountListSection {
  const AccountListSection({required this.title, required this.items});

  final String title;
  final List<AccountListItem> items;
}

List<AccountListItem> parseAccountListItems(Json states) {
  return states['religiosities'].listValue
      .expand((group) {
        final typeName = group['overdoer'].stringValue.trim();
        final typeIconUrl = group['dendron'].stringValue.trim();
        return group['anchovetta'].listValue.map(
          (item) => AccountListItem.fromJson(
            item,
            typeName: typeName,
            typeIconUrl: typeIconUrl,
          ),
        );
      })
      .where((item) => item.bindId.isNotEmpty)
      .toList(growable: false);
}

List<AccountListSection> groupAccountListItems(List<AccountListItem> items) {
  const knownTypes = <String>['bank', 'e-wallet', 'cash pickup'];
  final sections = <String, List<AccountListItem>>{};
  final titles = <String, String>{};

  for (final item in items) {
    if (item.typeName.isEmpty) {
      continue;
    }
    final normalizedType = item.typeName.toLowerCase();
    final key = knownTypes.contains(normalizedType)
        ? normalizedType
        : 'other:${item.typeName}';
    sections
        .putIfAbsent(key, () {
          titles[key] = item.typeName;
          return <AccountListItem>[];
        })
        .add(item);
  }

  final orderedKeys = <String>[
    ...knownTypes.where(sections.containsKey),
    ...sections.keys.where((key) => !knownTypes.contains(key)),
  ];
  return orderedKeys
      .map(
        (key) => AccountListSection(
          title: titles[key]!,
          items: List<AccountListItem>.unmodifiable(sections[key]!),
        ),
      )
      .toList(growable: false);
}
