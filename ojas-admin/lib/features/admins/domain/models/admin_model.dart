class AdminModel {
  final String id;
  final String name;
  final String email;
  final String department;
  final String role;
  final String status;
  final DateTime appliedDate;
  final DateTime? lastLogin;
  final List<String> permissions;

  AdminModel({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.status,
    required this.appliedDate,
    this.lastLogin,
    this.permissions = const [],
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      department: json['department'] ?? 'Platform Governance',
      role: json['role'] ?? 'Administrator',
      status: json['status'] ?? 'Approved',
      appliedDate: DateTime.parse(json['createdAt']),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      permissions: json['permissions'] != null ? List<String>.from(json['permissions']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
      'role': role,
      'status': status,
      'appliedDate': appliedDate.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'permissions': permissions,
    };
  }
}
