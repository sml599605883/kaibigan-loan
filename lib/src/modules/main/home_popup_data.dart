import '../../core/json/json.dart';

enum HomePopupType {
  none,
  appUpgrade,
  membershipUpgrade,
  marketing,
  unsupported,
}

class HomePopupData {
  const HomePopupData({
    required this.type,
    this.latestVersion = '',
    this.content = '',
    this.imageUrl = '',
    this.targetUrl = '',
  });

  final HomePopupType type;
  final String latestVersion;
  final String content;
  final String imageUrl;
  final String targetUrl;

  bool get shouldShow => switch (type) {
    HomePopupType.appUpgrade => true,
    HomePopupType.marketing => imageUrl.trim().isNotEmpty,
    _ => false,
  };

  String get displayVersion {
    final normalized = latestVersion.trim();
    if (normalized.isEmpty) {
      return '';
    }
    return normalized.toUpperCase().startsWith('V')
        ? normalized
        : 'V$normalized';
  }

  factory HomePopupData.fromJson(Json json) {
    final dialog = json['misaligned'];
    final dialogContent = dialog['lowliness'].stringValue.trim();
    return HomePopupData(
      type: _typeFrom(json['commensurate'].intValue),
      latestVersion: dialog['misapprehension'].stringValue.trim(),
      content: dialogContent.isNotEmpty
          ? dialogContent
          : dialog['mourningly'].stringValue.trim(),
      imageUrl: dialog['tanists'].stringValue.trim(),
      targetUrl: dialog['bloomeries'].stringValue.trim(),
    );
  }

  static HomePopupType _typeFrom(int rawType) => switch (rawType) {
    0 => HomePopupType.none,
    1 => HomePopupType.appUpgrade,
    2 => HomePopupType.membershipUpgrade,
    3 => HomePopupType.marketing,
    _ => HomePopupType.unsupported,
  };
}
