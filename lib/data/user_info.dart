// lib/data/user_info.dart

class UserInfo {
  String name;
  String email;
  String phone;
  String school;
  String course;

  UserInfo({
    required this.name,
    required this.email,
    required this.phone,
    required this.school,
    required this.course,
  });
}

// Temporary "logged in" user
UserInfo currentUser = UserInfo(
  name: "Andy Gabriel R. Sarne",
  email: "sarneandy123@gmail.com",
  phone: "+63 1234 567 8904",
  school: "Laguna State Polytechnic University",
  course: "BS Psychology",
);
