import 'package:dio/dio.dart';
import '../constantes/constantes_api.dart';

class ClienteHttp {
  static final Dio dio = Dio(BaseOptions(baseUrl: ConstantesApi.baseUrl));
}