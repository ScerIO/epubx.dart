import 'package:dio/dio.dart';
import 'package:epubx/example/token_interceptor.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class Datasource {
  late final Dio dio;
  void init() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://api.kuka.tech',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    dio.options.headers = {
      'content-type': 'application/json',
      'Accept': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Credentials': 'true',
      'Access-Control-Allow-Headers':
          'Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale',
      'Access-Control-Allow-Methods': 'POST, OPTIONS'
      // "App-Timezone": currentTimeZone
    };
    dio.interceptors.add(PrettyDioLogger(
      requestBody: true,
      requestHeader: true,
      responseHeader: true,
    ));
    dio.interceptors.addAll([
      TokenInterceptor(),
    ]);
  }

  Future<Book> getBook(int bookId) async {
    try {
      final response = await dio.get(
        '/api/books/$bookId',
      );

      final apiResponse = ApiResponse.fromJson(response.data);

      final book = Book.fromJson(apiResponse.data);

      return book;
    } catch (e) {
      return Book(id: -1, fileUrl: '');
    }
  }
}

class Book {
  final int id;
  final String fileUrl;

  Book({required this.id, required this.fileUrl});

  factory Book.fromJson(Map<String, dynamic> json) =>
      Book(id: json['id'], fileUrl: json['file']);
}

class ApiResponse {
  final bool success;
  final dynamic data;

  ApiResponse.fromJson(dynamic json)
      : success = json['success'],
        data = json['data'];
}
