enum Gender { male, female, other, preferNot }

extension GenderLabel on Gender {
  String get label {
    switch (this) {
      case Gender.male: return 'Male';
      case Gender.female: return 'Female';
      case Gender.other: return 'Other';
      case Gender.preferNot: return 'Prefer not to say';
    }
  }
}
