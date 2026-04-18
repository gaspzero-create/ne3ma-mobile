// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get settings => 'Paramètres';

  @override
  String get account => 'Compte';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get security => 'Sécurité';

  @override
  String get privacy => 'Confidentialité';

  @override
  String get language => 'Langue';

  @override
  String get supportAndAbout => 'Assistance et À propos';

  @override
  String get helpAndSupport => 'Aide et assistance';

  @override
  String get termsAndPolicies => 'Conditions et politiques';

  @override
  String get actions => 'Actions';

  @override
  String get reportProblem => 'Signaler un problème';

  @override
  String get logOut => 'Déconnexion';

  @override
  String get selectLanguage => 'Choisir la langue';

  @override
  String get all => 'Tout';

  @override
  String get fresh => 'Frais';

  @override
  String get dry => 'Sec';

  @override
  String get urgent => 'Urgent';

  @override
  String get myDonations => 'Mes dons';

  @override
  String get nearYou => 'Près de chez vous';

  @override
  String get searchAnything => 'Rechercher...';

  @override
  String get seeAll => 'voir tout';

  @override
  String get reserve => 'Réserver';

  @override
  String get update => 'Mettre à jour';

  @override
  String get delete => 'Supprimer';

  @override
  String get welcomeBack => 'Bon retour !';

  @override
  String get enterEmailPassword => 'Entrez votre email et mot de passe';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Votre email';

  @override
  String get emailRequired => 'L\'email est requis';

  @override
  String get emailInvalid => 'Entrez une adresse email valide';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordHint => 'Votre mot de passe';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get passwordMin => '8 caractères minimum';

  @override
  String get passwordUpper =>
      'Doit contenir au moins une lettre majuscule (A-Z)';

  @override
  String get passwordNumber => 'Doit contenir au moins un chiffre (0-9)';

  @override
  String get passwordSpecial =>
      'Doit contenir au moins un caractère spécial (!@#...)';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get login => 'Connexion';

  @override
  String get loggingIn => 'Connexion en cours...';

  @override
  String get loginFailed => 'Échec de la connexion';

  @override
  String get or => 'OU';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte ? ';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get createAccountDesc => 'Créez votre compte';

  @override
  String get name => 'Nom';

  @override
  String get nameHint => 'Votre nom';

  @override
  String get nameRequired => 'Le nom est requis';

  @override
  String get nameMin => 'Le nom doit comporter au moins 3 caractères';

  @override
  String get passwordRules =>
      '• Min 8 caractères  • Une majuscule  • Un chiffre  • Un caractère spécial';

  @override
  String get register => 'S\'inscrire';

  @override
  String get registering => 'Inscription en cours...';

  @override
  String get signUpFailed => 'L\'inscription a échoué';

  @override
  String get haveAccount => 'Vous avez déjà un compte ? ';

  @override
  String get signIn => 'Se connecter';

  @override
  String get agreeTerms =>
      'En cliquant sur s\'inscrire, vous acceptez nos conditions générales';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get verifyCode => 'Vérifier le code';

  @override
  String enterCodeEmail(Object email) {
    return 'Entrez le code à 6 chiffres envoyé à $email';
  }

  @override
  String enterCodePhone(Object phone) {
    return 'Entrez le code à 6 chiffres envoyé à $phone';
  }

  @override
  String get enterAllDigits => 'Veuillez entrer les 6 chiffres';

  @override
  String get verificationFailed => 'La vérification a échoué';

  @override
  String error(Object errorMsg) {
    return 'Erreur: $errorMsg';
  }

  @override
  String get didntReceiveCode => 'Vous n\'avez pas reçu le code ? ';

  @override
  String get resend => 'Renvoyer';

  @override
  String get resending => 'Renvoi en cours...';

  @override
  String get codeResent => 'Code renvoyé avec succès !';

  @override
  String resendFailed(Object errorMsg) {
    return 'L\'envoi a échoué : $errorMsg';
  }

  @override
  String get verifying => 'Vérification...';
}
