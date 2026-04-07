class ProfileDraft {
  String name;
  String surname;
  DateTime? birthdate;
  String? gender; // 'male' | 'female'
  String? preference; // 'men' | 'women' | 'everyone'

  /// Up to 6 local file paths.
  final List<String?> photos;

  String bio;
  String city;
  String job;
  String educationLevel; // ключ из kEducationLevels
  String university;

  ProfileDraft({
    this.name = '',
    this.surname = '',
    this.birthdate,
    this.gender,
    this.preference,
    List<String?>? photos,
    this.bio = '',
    this.city = '',
    this.job = '',
    this.educationLevel = '',
    this.university = '',
  }) : photos = photos ?? List<String?>.filled(6, null);
}

