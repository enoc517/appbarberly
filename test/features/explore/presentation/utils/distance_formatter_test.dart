import 'package:barberly/features/explore/presentation/utils/distance_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDistanceKm', () {
    test('returns an empty label when distance is unavailable', () {
      expect(formatDistanceKm(null), '');
    });

    test('formats nearby distances in meters', () {
      expect(formatDistanceKm(0.35), '350 m');
    });

    test('formats kilometer distances with one decimal', () {
      expect(formatDistanceKm(4.5), '4.5 km');
    });
  });
}
