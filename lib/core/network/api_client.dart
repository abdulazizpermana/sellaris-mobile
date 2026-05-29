// lib/core/network/api_client.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';

// ─── Response Wrapper ─────────────────────────────────────────
class ApiResponse {
  final bool success;
  final dynamic data;
  final int statusCode;
  const ApiResponse({
    required this.success,
    required this.data,
    required this.statusCode,
  });
}

// ─── Exceptions ───────────────────────────────────────────────
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;

  const ApiException(this.message, {this.errors});

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message, {super.errors});
}

class ValidationException extends ApiException {
  const ValidationException(super.message, {super.errors});
}

class ServerException extends ApiException {
  const ServerException(super.message, {super.errors});
}

// ─── API Client ───────────────────────────────────────────────
class ApiClient {
  final SecureStorage _storage;
  final http.Client _http;

  ApiClient(this._storage) : _http = http.Client();

  // Build headers
  Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _storage.getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Uri _uri(String endpoint, [Map<String, String>? query]) {
    var uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    if (query != null) uri = uri.replace(queryParameters: query);
    return uri;
  }

  // ─── GET ──────────────────────────────────────────────────
  Future<ApiResponse> get(
    String endpoint, {
    bool auth = true,
    Map<String, String>? query,
  }) async {
    try {
      final res = await _http
          .get(_uri(endpoint, query), headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } on SocketException {
      throw const NetworkException('Tidak ada koneksi internet');
    } on TimeoutException {
      throw const NetworkException('Koneksi timeout, coba lagi');
    }
  }

  // ─── POST JSON ────────────────────────────────────────────
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final res = await _http
          .post(
            _uri(endpoint),
            headers: await _headers(auth: auth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } on SocketException {
      throw const NetworkException('Tidak ada koneksi internet');
    } on TimeoutException {
      throw const NetworkException('Koneksi timeout, coba lagi');
    }
  }

  // ─── POST Multipart (upload foto produk) ──────────────────
  Future<ApiResponse> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    File? imageFile,
    String imageField = 'image',
  }) async {
    try {
      final token = await _storage.getToken();
      final req = http.MultipartRequest('POST', _uri(endpoint));

      req.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      req.fields.addAll(fields);

      if (imageFile != null) {
        req.files.add(
          await http.MultipartFile.fromPath(imageField, imageFile.path),
        );
      }

      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      return _handle(res);
    } on SocketException {
      throw const NetworkException('Tidak ada koneksi internet');
    } on TimeoutException {
      throw const NetworkException('Upload timeout, coba lagi');
    }
  }

  // ─── PUT ──────────────────────────────────────────────────
  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final res = await _http
          .put(
            _uri(endpoint),
            headers: await _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } on SocketException {
      throw const NetworkException('Tidak ada koneksi internet');
    }
  }

  // ─── PUT Multipart (update profil + upload foto) ──────────
  Future<ApiResponse> putMultipart(
    String endpoint, {
    required Map<String, String> fields,
    File? imageFile,
    String imageField = 'image',
  }) async {
    try {
      final token = await _storage.getToken();
      final req = http.MultipartRequest('POST', _uri(endpoint));

      req.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      req.fields.addAll({...fields, '_method': 'PUT'});

      if (imageFile != null) {
        req.files.add(
          await http.MultipartFile.fromPath(imageField, imageFile.path),
        );
      }

      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      return _handle(res);
    } on SocketException {
      throw const NetworkException('Tidak ada koneksi internet');
    } on TimeoutException {
      throw const NetworkException('Upload timeout, coba lagi');
    }
  }

  // ─── DELETE ───────────────────────────────────────────────
  Future<ApiResponse> delete(String endpoint) async {
    try {
      final res = await _http
          .delete(_uri(endpoint), headers: await _headers())
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } on SocketException {
      throw const NetworkException('Tidak ada koneksi internet');
    }
  }

  // ─── Response Handler ─────────────────────────────────────
  ApiResponse _handle(http.Response res) {
    print('=== API RESPONSE STATUS: ${res.statusCode}');
    print('=== API RESPONSE BODY: ${res.body}');
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      body = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return ApiResponse(success: true, data: body, statusCode: res.statusCode);
    } else if (res.statusCode == 401) {
      throw const UnauthorizedException('Sesi habis, silakan login ulang');
    } else if (res.statusCode == 422) {
      final errors = body is Map<String, dynamic>
          ? body['errors'] as Map<String, dynamic>?
          : null;
      String msg = body is Map<String, dynamic>
          ? body['message'] ?? 'Data tidak valid'
          : 'Data tidak valid';
      if (errors != null && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) msg = first.first.toString();
      }
      throw ValidationException(msg, errors: errors);
    } else if (res.statusCode == 404) {
      final errors = body is Map<String, dynamic>
          ? body['errors'] as Map<String, dynamic>?
          : null;
      final msg = body is Map<String, dynamic>
          ? body['message'] ?? 'Data tidak ditemukan'
          : 'Data tidak ditemukan';
      throw ApiException(msg, errors: errors);
    } else if (res.statusCode >= 500) {
      final errors = body is Map<String, dynamic>
          ? body['errors'] as Map<String, dynamic>?
          : null;
      final msg = body is Map<String, dynamic>
          ? body['message'] ?? 'Server bermasalah, coba lagi nanti'
          : 'Server bermasalah, coba lagi nanti';
      throw ServerException(msg, errors: errors);
    } else {
      final errors = body is Map<String, dynamic>
          ? body['errors'] as Map<String, dynamic>?
          : null;
      final msg = body is Map<String, dynamic>
          ? body['message'] ?? 'Terjadi kesalahan'
          : 'Terjadi kesalahan';
      throw ApiException(msg, errors: errors);
    }
  }
}
