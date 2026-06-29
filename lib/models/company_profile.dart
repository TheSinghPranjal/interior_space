class CompanyProfile {
  const CompanyProfile({
    this.companyName = '',
    this.address = '',
    this.contactNumber = '',
    this.email = '',
    this.logoPath,
    this.coverImagePath,
  });

  final String companyName;
  final String address;
  final String contactNumber;
  final String email;
  final String? logoPath;
  final String? coverImagePath;

  bool get hasLogo => logoPath != null && logoPath!.isNotEmpty;
  bool get hasCover => coverImagePath != null && coverImagePath!.isNotEmpty;
  bool get hasAnyDetails =>
      companyName.isNotEmpty ||
      address.isNotEmpty ||
      contactNumber.isNotEmpty ||
      email.isNotEmpty ||
      hasLogo ||
      hasCover;

  CompanyProfile copyWith({
    String? companyName,
    String? address,
    String? contactNumber,
    String? email,
    String? logoPath,
    String? coverImagePath,
    bool clearLogo = false,
    bool clearCover = false,
  }) {
    return CompanyProfile(
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
      coverImagePath: clearCover ? null : (coverImagePath ?? this.coverImagePath),
    );
  }

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'address': address,
        'contactNumber': contactNumber,
        'email': email,
        'logoPath': logoPath,
        'coverImagePath': coverImagePath,
      };

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      companyName: json['companyName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      logoPath: json['logoPath'] as String?,
      coverImagePath: json['coverImagePath'] as String?,
    );
  }
}
