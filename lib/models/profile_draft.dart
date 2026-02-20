class ProfileDraft {
  String name;
  DateTime? birthdate;
  String? gender; // 'male' | 'female'
  String? preference; // 'men' | 'women' | 'everyone'

  /// Up to 6 local file paths.
  final List<String?> photos;

  String bio;
  String city;
  String job;
  String education;

  ProfileDraft({
    this.name = '',
    this.birthdate,
    this.gender,
    this.preference,
    List<String?>? photos,
    this.bio = '',
    this.city = '',
    this.job = '',
    this.education = '',
  }) : photos = photos ?? List<String?>.filled(6, null);
}

