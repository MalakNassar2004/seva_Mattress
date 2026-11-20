/// How long a phone can be left and picked up again without asking for Face
/// ID, and whether the SMS code is asked at sign-in. Both come from the store
/// settings (the owner chooses them).
class AppLockSettings {
  AppLockSettings._();

  static const List<int> options = [0, 1, 5, 15, 30, 60];

  /// false until the real SMS sending is built (it needs the paid Firebase
  /// plan and the SMS setup). While it is false the owner cannot turn the SMS
  /// code on, because nobody could sign in with it.
  /// TODO(otp-real): set to true when FirebaseOtpService really works.
  static const bool smsAvailable = false;

  /// 0 = Face ID is asked every time the app comes back.
  static int graceMinutes = 0;

  /// true = after the password, the employee must enter an SMS code.
  static bool requireSms = false;

  static void apply(int minutes, {bool sms = false}) {
    graceMinutes = options.contains(minutes) ? minutes : 0;
    requireSms = sms;
  }

  static String label(int minutes) => switch (minutes) {
        0 => 'Immediately',
        60 => '1 hour',
        _ => '$minutes min',
      };
}