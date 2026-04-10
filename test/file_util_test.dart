import 'package:flutter_test/flutter_test.dart';
import 'package:moodiary/utils/file_util.dart';

void main() {
  group('FileUtil.videoNameToThumbnailName', () {
    test('generates correct thumbnail name with valid UUID format video name', () {
      const videoName = 'video-550e8400-e29b-41d4-a716-446655440000.mp4';
      final thumbnailName = FileUtil.videoNameToThumbnailName(videoName);
      expect(thumbnailName, 'thumbnail-550e8400-e29b-41d4-a716-446655440000.jpeg');
    });

    test('throws ArgumentError when video name is too short', () {
      expect(
        () => FileUtil.videoNameToThumbnailName('video-123.mp4'),
        throwsArgumentError,
      );
    });

    test('generates correct thumbnail name with valid UUID format and different extension', () {
      const videoName = 'video-123e4567-e89b-12d3-a456-426614174000.MOV';
      final thumbnailName = FileUtil.videoNameToThumbnailName(videoName);
      expect(thumbnailName, 'thumbnail-123e4567-e89b-12d3-a456-426614174000.jpeg');
    });
  });
}
