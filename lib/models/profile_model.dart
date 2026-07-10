class UserProfile {
  final int id;

  final String firstName;

  final String lastName;

  final String fullName;

  final String email;

  final String mobile;

  final String position;

  final String organization;

  final String avatar;

  final List<UserSession> sessions;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.position,
    required this.organization,
    required this.avatar,
    required this.sessions,
  });

  factory UserProfile.sample() {
    return UserProfile(
      id: 1,
      firstName: "محمد مهدی",
      lastName: "حق شناس",
      fullName: "محمد مهدی حق شناس - مدیر فناوری اطلاعات دانشگاه",
      email: "admin@example.com",
      mobile: "09123456789",
      position: "مدیر فناوری اطلاعات",
      organization: "دانشگاه نمونه",
      avatar: "",
      sessions: UserSession.sample(),
    );
  }
}

class UserSession {
  final String id;

  final String deviceName;

  final String platform;

  final String browser;

  final String ip;

  final String location;

  final String lastActivity;

  final bool current;

  const UserSession({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.browser,
    required this.ip,
    required this.location,
    required this.lastActivity,
    required this.current,
  });

  static List<UserSession> sample() {
    return const [
      UserSession(
        id: "1",
        deviceName: "Windows 11",
        platform: "Desktop",
        browser: "Chrome 138",
        ip: "192.168.1.25",
        location: "دانشگاه",
        lastActivity: "۲ دقیقه قبل",
        current: true,
      ),
      UserSession(
        id: "2",
        deviceName: "Samsung S24 Ultra",
        platform: "Android",
        browser: "Application",
        ip: "192.168.1.40",
        location: "شبکه داخلی",
        lastActivity: "۱ ساعت قبل",
        current: false,
      ),
      UserSession(
        id: "3",
        deviceName: "MacBook Pro",
        platform: "macOS",
        browser: "Safari",
        ip: "10.0.0.18",
        location: "دفتر مرکزی",
        lastActivity: "دیروز",
        current: false,
      ),
    ];
  }
}
