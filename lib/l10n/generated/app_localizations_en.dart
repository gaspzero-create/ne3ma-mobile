// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get security => 'Security';

  @override
  String get privacy => 'Privacy';

  @override
  String get language => 'Language';

  @override
  String get supportAndAbout => 'Support & About';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get termsAndPolicies => 'Terms and Policies';

  @override
  String get actions => 'Actions';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get logOut => 'Log out';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get all => 'All';

  @override
  String get fresh => 'Fresh';

  @override
  String get dry => 'Dry';

  @override
  String get urgent => 'Urgent';

  @override
  String get myDonations => 'My Donations';

  @override
  String get nearYou => 'Near You';

  @override
  String get searchAnything => 'Search Anything...';

  @override
  String get seeAll => 'see all';

  @override
  String get reserve => 'Reserve';

  @override
  String get update => 'Update';

  @override
  String get delete => 'Delete';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get enterEmailPassword => 'Enter your email and password to log in';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Your email';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Your password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMin => 'Minimum 8 characters';

  @override
  String get passwordUpper =>
      'Must contain at least one uppercase letter (A-Z)';

  @override
  String get passwordNumber => 'Must contain at least one number (0-9)';

  @override
  String get passwordSpecial =>
      'Must contain at least one special character (!@#...)';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get login => 'Login';

  @override
  String get loggingIn => 'Logging in...';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get or => 'OR';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get signUp => 'Sign Up';

  @override
  String get createAccountDesc => 'Create an account';

  @override
  String get name => 'Name';

  @override
  String get nameHint => 'Your name';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get nameMin => 'Name must be at least 3 characters';

  @override
  String get passwordRules =>
      '• Min 8 characters  • One uppercase  • One number  • One special char';

  @override
  String get register => 'Register';

  @override
  String get registering => 'Registering...';

  @override
  String get signUpFailed => 'Sign up failed';

  @override
  String get haveAccount => 'Have an account? ';

  @override
  String get signIn => 'Sign In';

  @override
  String get agreeTerms =>
      'By clicking register, you agree to our Terms and Conditions';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get verifyCode => 'Verify Code';

  @override
  String enterCodeEmail(Object email) {
    return 'Enter the 6-digit code sent to $email';
  }

  @override
  String enterCodePhone(Object phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get enterAllDigits => 'Please enter all 6 digits';

  @override
  String get verificationFailed => 'Verification failed';

  @override
  String error(Object errorMsg) {
    return 'Error: $errorMsg';
  }

  @override
  String get didntReceiveCode => 'Didn\'t receive the code? ';

  @override
  String get resend => 'Resend';

  @override
  String get resending => 'Resending...';

  @override
  String get codeResent => 'Code resent successfully!';

  @override
  String resendFailed(Object errorMsg) {
    return 'Resend failed: $errorMsg';
  }

  @override
  String get verifying => 'Verifying...';
}
