// import 'package:dio/dio.dart';
//
// class TokenInterceptor extends Interceptor {
//   TokenInterceptor({
//     required this.tokenLocalRepository,
//   });
//
//   final TokenLocalRepository tokenLocalRepository;
//
//   @override
//   Future<void> onRequest(
//       RequestOptions options, RequestInterceptorHandler handler) async {
//     final token = await tokenLocalRepository.getToken();
//     token.fold(
//       (failure) => null, // throw GetTokenException(),
//       (data) => {
//         if (options.headers.containsKey('Authorization'))
//           {options.headers['Authorization'] = '$data'}
//         else
//           {
//             options.headers.putIfAbsent('Authorization', () => '$data'),
//           }
//       },
//     );
//     super.onRequest(options, handler);
//   }
// }
/// INSERT TOKEN FROM SHARED PREFERENCES TO REQUEST HEADER IN NEEDED
///

import 'package:dio/dio.dart';

class TokenInterceptor extends Interceptor {
  TokenInterceptor();

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = '854|9noijrhCh9IfX8CyZH2POFgOc28kuEqJVPWyURSk';

    if (token != '') {
      if (options.headers.containsKey('Authorization')) {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        options.headers.putIfAbsent('Authorization', () => 'Bearer $token');
      }
    }

    super.onRequest(options, handler);
  }
}
