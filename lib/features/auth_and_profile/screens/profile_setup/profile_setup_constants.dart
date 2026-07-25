/// Profile Setup Constants
class ProfileSetupConstants {
  static const String kiitEmailDomain = '@kiit.ac.in';
  static const int yearBaseValue = 2000;
  static const int academicYearStartMonth = 6; // June

  static const List<String> academicYears = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  static const Map<String, List<String>> semestersByYear = {
    '1st Year': ['Semester 1', 'Semester 2'],
    '2nd Year': ['Semester 3', 'Semester 4'],
    '3rd Year': ['Semester 5', 'Semester 6'],
    '4th Year': ['Semester 7', 'Semester 8'],
  };

  static const int minAcademicYear = 1;
  static const int maxAcademicYear = 4;
}
