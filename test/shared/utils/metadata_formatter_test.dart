import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/shared/utils/metadata_formatter.dart';

void main() {
  group('MetadataFormatter', () {
    test('formatea duraciones en mm:ss', () {
      expect(MetadataFormatter.formatDurationMs(0), '00:00');
      expect(MetadataFormatter.formatDurationMs(45000), '00:45');
      expect(MetadataFormatter.formatDurationMs(215000), '03:35');
    });

    test('formatea duraciones largas con horas', () {
      expect(MetadataFormatter.formatDurationMs(3665000), '1:01:05');
    });

    test('formatea tamaños de archivo en KB y MB', () {
      expect(MetadataFormatter.formatFileSize(null), '');
      expect(MetadataFormatter.formatFileSize(0), '');
      expect(MetadataFormatter.formatFileSize(512000), '500.0 KB');
      expect(MetadataFormatter.formatFileSize(5242880), '5.0 MB');
    });

    test('formatea números de pista con padding de dos dígitos', () {
      expect(MetadataFormatter.formatTrackNumber(null), '');
      expect(MetadataFormatter.formatTrackNumber(0), '');
      expect(MetadataFormatter.formatTrackNumber(4), '04');
      expect(MetadataFormatter.formatTrackNumber(12), '12');
    });
  });
}
