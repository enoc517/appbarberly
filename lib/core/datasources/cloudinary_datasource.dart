import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

abstract class ImageUploadDatasource {
  Future<String> uploadImage({
    required File file,
    required String folder,
    required String publicId,
  });
}

class CloudinaryDatasource implements ImageUploadDatasource {
  final String cloudName;
  final String? apiKey;
  final String? apiSecret;
  final String uploadPreset;
  final http.Client _client;

  CloudinaryDatasource({
    required this.cloudName,
    required this.uploadPreset,
    this.apiKey,
    this.apiSecret,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<String> uploadImage({
    required File file,
    required String folder,
    required String publicId,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..fields['public_id'] = publicId
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await _client.send(request);
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(responseBody);
      return json['secure_url'] as String;
    } else {
      throw Exception(
        'Cloudinary upload failed: ${response.statusCode} - $responseBody',
      );
    }
  }

  Future<void> deleteImage(String publicId) async {
    final apiKey = this.apiKey;
    final apiSecret = this.apiSecret;
    if (apiKey == null || apiSecret == null) {
      throw StateError(
        'Cloudinary signed delete credentials are not configured',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final signature = _generateSignature(publicId, timestamp, apiSecret);

    final response = await http.post(
      uri,
      body: {
        'api_key': apiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
        'public_id': publicId,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Cloudinary delete failed: ${response.statusCode}');
    }
  }

  String _generateSignature(String publicId, int timestamp, String apiSecret) {
    final stringToSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    return _sha1(stringToSign);
  }

  String _sha1(String input) {
    final bytes = utf8.encode(input);
    final digest = _sha1Digest(bytes);
    return digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  List<int> _sha1Digest(List<int> bytes) {
    var h0 = 0x67452301;
    var h1 = 0xEFCDAB89;
    var h2 = 0x98BADCFE;
    var h3 = 0x10325476;
    var h4 = 0xC3D2E1F0;

    final message = List<int>.from(bytes);
    final originalLength = message.length;
    message.add(0x80);
    while (message.length % 64 != 56) {
      message.add(0);
    }
    final bitLength = originalLength * 8;
    for (var i = 56; i >= 0; i -= 8) {
      message.add((bitLength >> i) & 0xFF);
    }

    for (var chunkStart = 0; chunkStart < message.length; chunkStart += 64) {
      final chunk = message.sublist(chunkStart, chunkStart + 64);
      final w = List<int>.filled(80, 0);
      for (var i = 0; i < 16; i++) {
        w[i] =
            (chunk[i * 4] << 24) |
            (chunk[i * 4 + 1] << 16) |
            (chunk[i * 4 + 2] << 8) |
            chunk[i * 4 + 3];
      }
      for (var i = 16; i < 80; i++) {
        w[i] = _leftRotate(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
      }

      var a = h0;
      var b = h1;
      var c = h2;
      var d = h3;
      var e = h4;

      for (var i = 0; i < 80; i++) {
        int f, k;
        if (i < 20) {
          f = (b & c) | ((~b) & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }

        final temp = (_leftRotate(a, 5) + f + e + k + w[i]) & 0xFFFFFFFF;
        e = d;
        d = c;
        c = _leftRotate(b, 30);
        b = a;
        a = temp;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
    }

    return [
      (h0 >> 24) & 0xFF,
      (h0 >> 16) & 0xFF,
      (h0 >> 8) & 0xFF,
      h0 & 0xFF,
      (h1 >> 24) & 0xFF,
      (h1 >> 16) & 0xFF,
      (h1 >> 8) & 0xFF,
      h1 & 0xFF,
      (h2 >> 24) & 0xFF,
      (h2 >> 16) & 0xFF,
      (h2 >> 8) & 0xFF,
      h2 & 0xFF,
      (h3 >> 24) & 0xFF,
      (h3 >> 16) & 0xFF,
      (h3 >> 8) & 0xFF,
      h3 & 0xFF,
      (h4 >> 24) & 0xFF,
      (h4 >> 16) & 0xFF,
      (h4 >> 8) & 0xFF,
      h4 & 0xFF,
    ];
  }

  int _leftRotate(int value, int bits) {
    return ((value << bits) | (value >> (32 - bits))) & 0xFFFFFFFF;
  }
}
