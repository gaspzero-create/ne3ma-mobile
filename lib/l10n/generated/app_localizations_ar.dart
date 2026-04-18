// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get settings => 'الإعدادات';

  @override
  String get account => 'الحساب';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get security => 'الأمان';

  @override
  String get privacy => 'الخصوصية';

  @override
  String get language => 'اللغة';

  @override
  String get supportAndAbout => 'الدعم والمعلومات';

  @override
  String get helpAndSupport => 'المساعدة والدعم';

  @override
  String get termsAndPolicies => 'الشروط والسياسات';

  @override
  String get actions => 'الإجراءات';

  @override
  String get reportProblem => 'الإبلاغ عن مشكلة';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get all => 'الكل';

  @override
  String get fresh => 'طازج';

  @override
  String get dry => 'جاف';

  @override
  String get urgent => 'عاجل';

  @override
  String get myDonations => 'تبرعاتي';

  @override
  String get nearYou => 'بالقرب منك';

  @override
  String get searchAnything => 'ابحث عن أي شيء...';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get reserve => 'حجز';

  @override
  String get update => 'تحديث';

  @override
  String get delete => 'حذف';

  @override
  String get welcomeBack => 'مرحباً بعودتك!';

  @override
  String get enterEmailPassword =>
      'أدخل بريدك الإلكتروني وكلمة المرور لتسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailHint => 'بريدك الإلكتروني';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get emailInvalid => 'أدخل عنوان بريد إلكتروني صالح';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordHint => 'كلمة المرور الخاصة بك';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get passwordMin => '8 أحرف كحد أدنى';

  @override
  String get passwordUpper => 'يجب أن تحتوي على حرف كبير واحد على الأقل';

  @override
  String get passwordNumber => 'يجب أن تحتوي على رقم واحد على الأقل';

  @override
  String get passwordSpecial =>
      'يجب أن تحتوي على رمز خاص واحد على الأقل (!@#...)';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get loggingIn => 'جاري تسجيل الدخول...';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get or => 'أو';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟ ';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get createAccountDesc => 'قم بإنشاء حسابك';

  @override
  String get name => 'الاسم';

  @override
  String get nameHint => 'اسمك الكامل';

  @override
  String get nameRequired => 'الاسم مطلوب';

  @override
  String get nameMin => 'الاسم يجب أن يكون 3 أحرف على الأقل';

  @override
  String get passwordRules =>
      '• 8 أحرف كحد أدنى • حرف كبير واحد • رقم واحد • رمز خاص';

  @override
  String get register => 'تسجيل';

  @override
  String get registering => 'جاري التسجيل...';

  @override
  String get signUpFailed => 'فشل التسجيل';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟ ';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get agreeTerms => 'بالنقر على تسجيل، فإنك توافق على الشروط والأحكام';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get verifyCode => 'رمز التحقق';

  @override
  String enterCodeEmail(Object email) {
    return 'أدخل الرمز المكون من 6 أرقام المرسل إلى $email';
  }

  @override
  String enterCodePhone(Object phone) {
    return 'أدخل الرمز المكون من 6 أرقام المرسل إلى $phone';
  }

  @override
  String get enterAllDigits => 'الرجاء إدخال الأرقام الستة كاملة';

  @override
  String get verificationFailed => 'فشل التحقق';

  @override
  String error(Object errorMsg) {
    return 'خطأ: $errorMsg';
  }

  @override
  String get didntReceiveCode => 'لم تتلق الرمز؟ ';

  @override
  String get resend => 'إعادة الإرسال';

  @override
  String get resending => 'جاري إعادة الإرسال...';

  @override
  String get codeResent => 'تم إعادة إرسال الرمز بنجاح!';

  @override
  String resendFailed(Object errorMsg) {
    return 'فشل إعادة الإرسال: $errorMsg';
  }

  @override
  String get verifying => 'جاري التحقق...';
}
