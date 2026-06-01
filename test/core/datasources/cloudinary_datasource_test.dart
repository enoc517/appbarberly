import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:barberly/core/datasources/cloudinary_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('CloudinaryDatasource.uploadImage', () {
    late Directory tempDir;
    late File imageFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cloudinary_test_');
      imageFile = File('${tempDir.path}/avatar.jpg');
      await imageFile.writeAsBytes([1, 2, 3]);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('uses cloud name and unsigned upload preset', () async {
      late http.MultipartRequest capturedRequest;
      final datasource = CloudinaryDatasource(
        cloudName: 'ducfjckca',
        uploadPreset: 'mediaflows',
        client: _FakeMultipartClient((request) {
          capturedRequest = request;
          return _jsonResponse(200, {'secure_url': 'https://cdn.test/a.jpg'});
        }),
      );

      final url = await datasource.uploadImage(
        file: imageFile,
        folder: 'users',
        publicId: 'user-1/avatar',
      );

      expect(url, 'https://cdn.test/a.jpg');
      expect(
        capturedRequest.url.toString(),
        'https://api.cloudinary.com/v1_1/ducfjckca/image/upload',
      );
      expect(capturedRequest.fields['upload_preset'], 'mediaflows');
      expect(capturedRequest.fields['folder'], 'users');
      expect(capturedRequest.fields['public_id'], 'user-1/avatar');
      expect(capturedRequest.fields.containsKey('api_key'), isFalse);
    });

    test('surfaces Cloudinary upload errors', () async {
      final datasource = CloudinaryDatasource(
        cloudName: 'ducfjckca',
        uploadPreset: 'mediaflows',
        client: _FakeMultipartClient((_) {
          return _jsonResponse(401, {
            'error': {'message': 'Unknown API key'},
          });
        }),
      );

      expect(
        () => datasource.uploadImage(
          file: imageFile,
          folder: 'users',
          publicId: 'user-1/avatar',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Unknown API key'),
          ),
        ),
      );
    });
  });
}

class _FakeMultipartClient extends http.BaseClient {
  _FakeMultipartClient(this._handler);

  final FutureOr<http.StreamedResponse> Function(http.MultipartRequest request)
  _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is! http.MultipartRequest) {
      throw StateError('Expected MultipartRequest');
    }

    return _handler(request);
  }
}

http.StreamedResponse _jsonResponse(int statusCode, Object body) {
  final bytes = utf8.encode(jsonEncode(body));
  return http.StreamedResponse(Stream.value(bytes), statusCode);
}
