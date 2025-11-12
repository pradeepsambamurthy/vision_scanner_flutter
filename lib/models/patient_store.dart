import 'gender.dart';

class PatientStore {
  static String? name;
  static int? age;
  static Gender? gender;

  static void clear() {
    name = null;
    age = null;
    gender = null;
  }
}
