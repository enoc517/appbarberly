import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Info.plist declares camera and photo library profile image usage', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(plist, contains('<key>NSCameraUsageDescription</key>'));
    expect(plist, contains('foto de perfil'));
    expect(plist, contains('<key>NSPhotoLibraryUsageDescription</key>'));
    expect(plist, contains('galería'));
  });
}
