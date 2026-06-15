class AddressModel {
  final String? id;
  final String name;
  final String mobile;
  final String? buildingName;
  final String street;
  final String? area;
  final String? landmark;
  final String city;
  final String state;
  final String zipCode;
  final String? gstNumber;
  final String? panNumber;
  final bool isDefault;

  AddressModel({
    this.id,
    required this.name,
    required this.mobile,
    this.buildingName,
    required this.street,
    this.area,
    this.landmark,
    required this.city,
    required this.state,
    required this.zipCode,
    this.gstNumber,
    this.panNumber,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id'],
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      buildingName: json['buildingName'],
      street: json['street'] ?? '',
      area: json['area'],
      landmark: json['landmark'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      gstNumber: json['gstNumber'],
      panNumber: json['panNumber'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobile': mobile,
      'buildingName': buildingName,
      'street': street,
      'area': area,
      'landmark': landmark,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'gstNumber': gstNumber,
      'panNumber': panNumber,
      'isDefault': isDefault,
    };
  }

  String get fullAddress {
    final List<String> parts = [];
    if (buildingName != null && buildingName!.isNotEmpty) parts.add(buildingName!);
    if (street.isNotEmpty) parts.add(street);
    if (area != null && area!.isNotEmpty) parts.add(area!);
    if (landmark != null && landmark!.isNotEmpty) parts.add(landmark!);
    parts.add(city);
    parts.add(state);
    return '${parts.join(', ')} - $zipCode';
  }
}
