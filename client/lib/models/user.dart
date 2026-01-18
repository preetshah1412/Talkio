class User {
  final String id;
  final String username;
  final String email;
  final String pic;
  final String token;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.pic,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      username: json['username'],
      email: json['email'],
      pic: json['pic'],
      token: json['token'],
    );
  }
}
