class AuthApiModel {
  final String token;

  AuthApiModel({required this.token});

  factory AuthApiModel.fromJson(Map<String, dynamic> json) {
    return AuthApiModel(token: json['token']);
  }
}
