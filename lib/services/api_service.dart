// ignore_for_file: avoid_print

import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ApiService {
  //static const String baseUrl = 'http://18.188.18.80:3000/api/v1';
  static const String baseUrl = 'http://127.0.0.1:3000';
  static String? _authToken;

  // Set auth token
  static void setAuthToken(String token) {
    _authToken = token;
  }

  // Get headers with auth
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // Login method
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setAuthToken(data['token']);
          // Store token locally
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
          await prefs.setString('user_data', jsonEncode(data['user']));
        }
        return data;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Submit content method
  static Future<Map<String, dynamic>> submitContent({
    required String title,
    required String contentType,
    String? content,
    File? file,
    int? moodleAssignmentId,
    int? moodleCourseId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/content/submit'),
      );

      // Add headers
      request.headers.addAll(_headers);

      // Add fields
      request.fields['title'] = title;
      request.fields['content_type'] = contentType;
      if (content != null) request.fields['content'] = content;
      if (moodleAssignmentId != null) {
        request.fields['moodle_assignment_id'] = moodleAssignmentId.toString();
      }
      if (moodleCourseId != null) {
        request.fields['moodle_course_id'] = moodleCourseId.toString();
      }

      // Add file if provided
      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Submission failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Submission error: $e');
    }
  }

  // Get submissions
  static Future<List<dynamic>> getSubmissions({
    int page = 1,
    int limit = 20,
    String? status,
    int? courseId,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (courseId != null) 'course_id': courseId.toString(),
      };

      final uri = Uri.parse('$baseUrl/content/submissions').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['submissions'] ?? [];
      } else {
        throw Exception('Failed to fetch submissions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Initialize auth token from storage
  static Future<void> initializeAuth() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        setAuthToken(token);
      }
    } catch (e) {
      print('Failed to initialize auth: $e');
    }
  }

  /// Fetches all course data in nested format from the API
  ///
  /// Returns a nested Map structure containing courses, assignments, and submissions
  /// Throws [ApiException] for any API errors or timeouts
  static Future<Map<String, dynamic>> getAllData() async {
    try {
      final uri = Uri.parse('$baseUrl/courses/all/nested');
      final response = await http
          .get(
            uri,
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timed out', 408);
    } on http.ClientException catch (e) {
      throw ApiException('Connection error: ${e.message}', 500);
    } on FormatException catch (e) {
      throw ApiException('Invalid response format: ${e.message}', 500);
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}', 500);
    }
  }

  /// Handles the API response and converts it to a Dart Map
  ///
  /// [response] The HTTP response from the API call
  /// Throws [ApiException] for non-200 status codes
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      switch (response.statusCode) {
        case 200:
          return responseBody;
        case 400:
          final error = responseBody['error'] ?? 'Bad request';
          throw ApiException(error, 400);
        case 401:
          throw ApiException('Unauthorized - Please login again', 401);
        case 403:
          throw ApiException('Forbidden - You don\'t have permission', 403);
        case 404:
          throw ApiException('Resource not found', 404);
        case 500:
          throw ApiException(
            responseBody['error'] ?? 'Internal server error',
            500,
          );
        default:
          throw ApiException(
            'Request failed with status: ${response.statusCode}',
            response.statusCode,
          );
      }
    } on FormatException catch (e) {
      throw ApiException('Invalid JSON format: ${e.message}', 500);
    }
  }

  static void logout() {
    _authToken = null;
  }
}

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
