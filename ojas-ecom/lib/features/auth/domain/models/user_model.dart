class UserModel {
  final String? id;
  final String name;
  final String email;
  final String gender;
  final String mobile;
  final String? bio;
  final String? photo;
  final String role;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.mobile,
    this.bio,
    this.photo,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      gender: json['gender'],
      mobile: json['mobile'] ?? '',
      bio: json['bio'] ?? 'New User',
      photo: json['photo'],
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'gender': gender,
      'mobile': mobile,
      if (bio != null) 'bio': bio,
      if (photo != null) 'photo': photo,
    };
  }

}
