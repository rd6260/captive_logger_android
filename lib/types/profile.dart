
class Profile {
  final String name;
  final String id;
  final String password;

  Profile({required this.name, required this.id, required this.password});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'],
      id: json['id'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'password': password,
    };
  }
}