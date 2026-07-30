import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/theme/app_colors.dart';

void main() {
  test('camera permission secondary action uses the muted gray token', () {
    expect(AppColors.cameraPermissionLaterText.toARGB32(), 0xFFB8B8B8);

    const pagePaths = <String>[
      'lib/src/modules/certification/certification_upload_page.dart',
      'lib/src/modules/certification/certification_face_page.dart',
      'lib/src/modules/certification/certification_bind_card_page.dart',
    ];

    for (final path in pagePaths) {
      final source = File(path).readAsStringSync();
      expect(source, contains("'Maybe Later'"), reason: path);
      expect(
        source,
        contains(
          'style: TextStyle(color: AppColors.cameraPermissionLaterText)',
        ),
        reason: path,
      );
    }
  });
}
