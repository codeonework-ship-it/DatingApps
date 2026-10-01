// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navDiscover => 'Découvrir';

  @override
  String get navMatches => 'Matchs';

  @override
  String get navEngage => 'Participer';

  @override
  String get navProfile => 'Profil';

  @override
  String get navSettings => 'Réglages';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsEditProfileTitle => 'Modifier le profil';

  @override
  String get settingsEditProfileSubtitle => 'Mets à jour tes infos';

  @override
  String get settingsPhotosTitle => 'Photos';

  @override
  String get settingsPhotosSubtitle => 'Gère tes photos';

  @override
  String get settingsSectionPreferences => 'Préférences';

  @override
  String get settingsAppearanceTitle => 'Apparence';

  @override
  String get settingsAppearanceSubtitle => 'Enregistré dans ton compte';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeMatchDevice => 'Comme l\'appareil';

  @override
  String get settingsLooksTitle => 'Looks';

  @override
  String get settingsLooksClassicDescription =>
      'Warm ivory and forest by day. Soft mint and deep forest by night.';

  @override
  String get settingsLooksClassicLabel => 'Today';

  @override
  String get settingsThemeSaveFailed =>
      'Impossible d\'enregistrer ton thème. Réessaie.';

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageSubtitle => 'Choisis la langue de l\'appli';

  @override
  String get settingsDatingPreferencesTitle => 'Préférences de rencontre';

  @override
  String get settingsDatingPreferencesSubtitle =>
      'Âge, lieu, centres d\'intérêt';

  @override
  String get settingsAccountDataTitle => 'Compte et données';

  @override
  String get settingsAccountDataSubtitle =>
      'Masquer, télécharger ou supprimer ton compte';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsSubtitle => 'Notifications push et e-mail';

  @override
  String get settingsSectionEngagement => 'Participer';

  @override
  String get settingsTrustBadgesTitle => 'Badges de confiance';

  @override
  String get settingsTrustBadgesSubtitle =>
      'Vois tes badges et ton historique de confiance';

  @override
  String get settingsTrustFiltersTitle => 'Filtres de confiance';

  @override
  String get settingsTrustFiltersSubtitle =>
      'Définis les critères de confiance pour la découverte';

  @override
  String get settingsConversationRoomsTitle => 'Salons de discussion';

  @override
  String get settingsConversationRoomsSubtitle =>
      'Parcours, rejoins, quitte et modère des salons';

  @override
  String get settingsFriendsTitle => 'Amis et contacts';

  @override
  String get settingsFriendsSubtitle =>
      'Crée et entretiens tes liens d\'amitié';

  @override
  String get settingsCallHistoryTitle => 'Historique des appels';

  @override
  String get settingsCallHistorySubtitle => 'Revois tes appels passés';

  @override
  String get settingsMatchNudgesTitle => 'Coups de pouce';

  @override
  String get settingsMatchNudgesSubtitle =>
      'Relance les conversations qui dorment';

  @override
  String get settingsSubscriptionsTitle => 'Abonnements';

  @override
  String get settingsSubscriptionsSubtitle =>
      'Formules, statut d\'accès et paiements';

  @override
  String get settingsSectionApp => 'Appli';

  @override
  String get settingsPrivacySafetyTitle => 'Confidentialité et sécurité';

  @override
  String get settingsPrivacySafetySubtitle =>
      'Gère tes réglages de confidentialité';

  @override
  String get settingsGovernmentVerificationTitle => 'Vérification d\'identité';

  @override
  String get settingsGovernmentVerificationSubtitle =>
      'Vois le statut de ta vérification d\'identité';

  @override
  String get settingsQaVerificationUploadTitle => 'Envoi de vérification QA';

  @override
  String get settingsQaVerificationUploadSubtitle =>
      'Parcours pièce d\'identité et selfie réservé à l\'automatisation';

  @override
  String get settingsHelpSupportTitle => 'Aide et support';

  @override
  String get settingsHelpSupportSubtitle => 'FAQ et contact du support';

  @override
  String get settingsAboutTitle => 'À propos';

  @override
  String get settingsAboutSubtitle => 'Infos sur l\'appli et la technique';

  @override
  String get settingsLogout => 'Se déconnecter';

  @override
  String get languageTitle => 'Langue';

  @override
  String get languageIntro =>
      'Choisis la langue de Connect. Ton choix est enregistré dans ton compte et s\'applique sur tous les appareils où tu te connectes.';

  @override
  String get languageUseDevice => 'Utiliser la langue de l\'appareil';

  @override
  String get languageUseDeviceSubtitle =>
      'Suit le réglage de langue de ton téléphone';

  @override
  String get languageSaveFailed =>
      'Impossible d\'enregistrer ta langue. Réessaie.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsInboxTitle => 'Boîte de notifications';

  @override
  String get notificationsInboxCaughtUp => 'Tu es à jour';

  @override
  String notificationsInboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count non lues',
      one: '1 non lue',
    );
    return '$_temp0';
  }

  @override
  String get notificationsInAppTitle => 'Notifications dans l\'appli';

  @override
  String get notificationsInAppSubtitle =>
      'Afficher les notifications pendant que tu utilises l\'appli';

  @override
  String get notificationsPushTitle => 'Notifications push';

  @override
  String get notificationsPushSubtitle =>
      'Autoriser la réception quand l\'appli est en arrière-plan';

  @override
  String get notificationsNewMatchesTitle => 'Nouveaux matchs';

  @override
  String get notificationsNewMatchesSubtitle => 'Être prévenu quand tu matches';

  @override
  String get notificationsNewMessagesTitle => 'Nouveaux messages';

  @override
  String get notificationsNewMessagesSubtitle =>
      'Être prévenu des messages du chat';

  @override
  String get notificationsLikesTitle => 'Likes';

  @override
  String get notificationsLikesSubtitle =>
      'Être prévenu quand quelqu\'un te like';

  @override
  String get notificationsMatchNudgesTitle => 'Coups de pouce';

  @override
  String get notificationsMatchNudgesSubtitle =>
      'Être prévenu quand un match te relance';

  @override
  String get notificationsIncomingCallsTitle => 'Appels entrants';

  @override
  String get notificationsIncomingCallsSubtitle =>
      'Afficher les alertes d\'appel entrant';

  @override
  String get notificationsSafetyTitle => 'Mises à jour de sécurité';

  @override
  String get notificationsSafetySubtitle =>
      'Recevoir les mises à jour importantes sur ta sécurité';

  @override
  String get notificationsFriendPlansTitle => 'Rendez-vous de tes amis';

  @override
  String get notificationsFriendPlansSubtitle =>
      'Savoir quand un ami prévoit un rendez-vous ou donne des nouvelles';

  @override
  String get welcomeTagline => 'Fait pour la vraie vie.';

  @override
  String get welcomePhotoNote => 'Le but, c\'est de se voir en vrai.';

  @override
  String get welcomeHeadlineLead => 'Une belle histoire\ncommence par ';

  @override
  String get welcomeHeadlineAccent => 'bonjour.';

  @override
  String get welcomeBody =>
      'Trouve quelqu\'un qui te ressemble vraiment. Et vois où ça te mène.';

  @override
  String get welcomeCreateAccount => 'Créer un compte';

  @override
  String get welcomeAlreadyMember => 'Déjà membre ? ';

  @override
  String get welcomeSignIn => 'Se connecter';

  @override
  String get welcomeFooter => '18+  ·  Ton rythme. Ton choix.';

  @override
  String get authBackTooltip => 'Retour à l\'accueil';

  @override
  String get authHeadline => 'Content de te revoir.';

  @override
  String get authSubtitle =>
      'Connecte-toi avec ton nom d\'utilisateur et ton mot de passe';

  @override
  String get authWelcomeBack => 'Bon retour';

  @override
  String get authNextHello => 'Ton prochain bonjour t\'attend.';

  @override
  String get authUsernameHint => 'nom d\'utilisateur';

  @override
  String get authPasswordHint => 'Mot de passe';

  @override
  String get authShowPassword => 'Afficher le mot de passe';

  @override
  String get authHidePassword => 'Masquer le mot de passe';

  @override
  String get authCantSignIn => 'Impossible de te connecter ?';

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authPrivacyNote =>
      'Ton mot de passe n\'est envoyé qu\'à la connexion et n\'est jamais stocké dans l\'appli.';

  @override
  String get authEnterUsername => 'Entre ton nom d\'utilisateur.';

  @override
  String get authEnterPassword => 'Entre ton mot de passe.';

  @override
  String get commonYes => 'Oui';

  @override
  String get commonNo => 'Non';

  @override
  String get planVenueCoffee => 'Un café';

  @override
  String get planVenueMeal => 'Un repas';

  @override
  String get planVenueDrinks => 'Un verre';

  @override
  String get planVenueWalk => 'Une balade';

  @override
  String get planVenueActivity => 'Une activité';

  @override
  String get planVenueEvent => 'Un événement';

  @override
  String get planVenueVideoCall => 'Appel vidéo';

  @override
  String get planVenueOther => 'Autre chose';

  @override
  String planProposeTitle(String name) {
    return 'Prévois un rendez-vous avec $name';
  }

  @override
  String get planProposeSubtitle =>
      'Shape a first hello together. Contact sharing starts off.';

  @override
  String get planProposeButton => 'Proposer';

  @override
  String planHeadlineProposed(String name) {
    return '$name a proposé un rendez-vous';
  }

  @override
  String planHeadlineWaiting(String name) {
    return 'En attente de $name';
  }

  @override
  String get planHeadlineUpcoming => 'C\'est prévu';

  @override
  String get planHeadlineCheckin => 'Comment ça s\'est passé ?';

  @override
  String get planHeadlineDebrief => 'C\'était comment ?';

  @override
  String get planHeadlineDebriefComplete => 'Bilan terminé';

  @override
  String planHeadlineWaitingDebrief(String name) {
    return 'En attente du bilan de $name';
  }

  @override
  String get planHeadlineCheckedInSafe => 'Tu as signalé que tout va bien';

  @override
  String get planHeadlineFriendsAlerted => 'Your request for help is recorded';

  @override
  String get planHeadlineDefault => 'Rendez-vous';

  @override
  String get planStatusProposed => 'Proposé';

  @override
  String get planStatusConfirmed => 'Confirmé';

  @override
  String get planDebriefButton => 'Bilan en dix secondes';

  @override
  String get planDecline => 'Refuser';

  @override
  String get planAccept => 'Accepter';

  @override
  String get planFriendsKnowAccepted =>
      'Choose trusted contacts to share your updates.';

  @override
  String get planFriendsKnowProposed =>
      'Contact sharing is optional for each plan.';

  @override
  String get planCancel => 'Annuler le rendez-vous';

  @override
  String get planNeedHelp => 'J\'ai besoin d\'aide';

  @override
  String get planImSafe => 'Tout va bien';

  @override
  String get planCancelDialogTitle => 'Annuler ce rendez-vous ?';

  @override
  String planCancelDialogBody(String name) {
    return '$name et toutes les personnes avec qui tu l\'as partagé seront prévenues.';
  }

  @override
  String get planKeepIt => 'Le garder';

  @override
  String get planProposeIntro =>
      'This starts between you and your date. After proposing, choose trusted contacts if you want to share plan and check-in updates.';

  @override
  String get planSectionWhen => 'Quand';

  @override
  String get planSectionWhat => 'Quoi';

  @override
  String get planSectionGroups => 'Trusted contacts';

  @override
  String planDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String get planPlaceLabel => 'Lieu (facultatif)';

  @override
  String get planPlaceHint => 'Un lieu public, c\'est l\'idéal';

  @override
  String get planAreaLabel => 'Quartier ou secteur';

  @override
  String get planNoteLabel => 'Un mot pour l\'autre (facultatif)';

  @override
  String get planFutureTimeError => 'Choisis une heure dans le futur.';

  @override
  String get planProposeFailed => 'Impossible de proposer ce rendez-vous.';

  @override
  String get planSendButton => 'Envoyer la proposition';

  @override
  String get planAcceptTitle => 'Accepter le rendez-vous ?';

  @override
  String get planAcceptIntro =>
      'Accept this plan with your date. Choose trusted contacts afterwards if you want to share your updates.';

  @override
  String get planAcceptButton => 'Accept plan';

  @override
  String debriefTitle(String name) {
    return 'C\'était comment avec $name ?';
  }

  @override
  String get debriefIntro =>
      'Tes réponses restent privées. Quand vous confirmez tous les deux que le rendez-vous a eu lieu, il compte pour ton badge Shows Up.';

  @override
  String get debriefHappened => 'Le rendez-vous a-t-il eu lieu ?';

  @override
  String get debriefMeetAgain => 'Tu reverrais cette personne ?';

  @override
  String get debriefFeltSafe => 'Tu t\'es senti(e) en sécurité ?';

  @override
  String get debriefNoteLabel => 'Quelque chose à ajouter ? (facultatif)';

  @override
  String get debriefMissingHappened => 'Dis-nous si le rendez-vous a eu lieu.';

  @override
  String get debriefSaveFailed => 'Impossible d\'enregistrer ton bilan.';

  @override
  String get debriefSave => 'Enregistrer le bilan';

  @override
  String get debriefUnsafeTitle =>
      'Désolés que tu ne te sois pas senti(e) en sécurité';

  @override
  String debriefUnsafeBody(String name) {
    return 'Ta réponse est transmise à notre équipe sécurité. Veux-tu aussi signaler $name ?';
  }

  @override
  String get debriefNotNow => 'Pas maintenant';

  @override
  String get debriefReport => 'Signaler';

  @override
  String get plansTitle => 'Rendez-vous';

  @override
  String get plansTabMine => 'Les miens';

  @override
  String get plansTabFriends => 'Amis';

  @override
  String get plansEmptyMineTitle => 'Aucun rendez-vous pour l\'instant';

  @override
  String get plansEmptyMineBody =>
      'Propose a date from a conversation. You choose whether to share plan and check-in updates with trusted contacts.';

  @override
  String plansWith(String name) {
    return 'Avec $name';
  }

  @override
  String get plansNextDecide => 'En attente de ta réponse';

  @override
  String plansNextAwait(String name) {
    return 'En attente de $name';
  }

  @override
  String get plansNextUpcoming => 'Confirmed. Your time together is planned.';

  @override
  String get plansNextCheckin => 'Check in after your date';

  @override
  String get plansNextDebrief => 'Dis-nous comment ça s\'est passé';

  @override
  String get plansNextCancelled => 'Annulé';

  @override
  String get plansNextDone => 'Terminé';

  @override
  String get plansEmptyFriendsTitle => 'Rien de partagé pour l\'instant';

  @override
  String get plansEmptyFriendsBody =>
      'Plans appear here when friends explicitly choose to share with you.';

  @override
  String get plansViaGroup => 'Shared with you';

  @override
  String get plansViaFriend => 'Trusted contact';

  @override
  String plansFriendNeedsHelp(String name) {
    return '$name a demandé de l\'aide. Prends contact tout de suite.';
  }

  @override
  String plansFriendMissedCheckin(String name) {
    return '$name n\'a pas encore donné de nouvelles.';
  }

  @override
  String plansFriendCheckedInSafe(String name, String via) {
    return '$name a signalé que tout va bien · $via';
  }

  @override
  String plansFriendStatusLine(String via, String status) {
    return '$via · $status';
  }

  @override
  String get plansStatusWordProposed => 'proposé';

  @override
  String get plansStatusWordConfirmed => 'confirmé';

  @override
  String get plansStatusWordCancelled => 'annulé';

  @override
  String get plansStatusWordHappened => 'a eu lieu';

  @override
  String get chatEmptyDefault =>
      'Dis bonjour. Les messages s’affichent ici pour tout le monde dans cette conversation.';

  @override
  String get chatNotSentRetry =>
      'Non envoyé. Touche le message pour réessayer.';

  @override
  String get chatRetrySend => 'Réessayer l’envoi';

  @override
  String get chatCopyText => 'Copier le texte';

  @override
  String get chatDeleteMine => 'Supprimer mon message';

  @override
  String get chatRemoveMessage => 'Retirer le message';

  @override
  String get chatReportMessage => 'Signaler le message';

  @override
  String get chatThisMember => 'Ce membre';

  @override
  String get chatMember => 'Membre';

  @override
  String get chatCopied => 'Copié.';

  @override
  String get chatDeleteFailed => 'Impossible de supprimer. Réessaie.';

  @override
  String get chatSubtitleFriends => 'Amis';

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String get chatReconnecting =>
      'Reconnexion en cours. Les nouveaux messages peuvent mettre un instant.';

  @override
  String get chatUnavailable =>
      'Cette conversation n’est pas disponible. Tu n’en fais peut-être plus partie.';

  @override
  String get chatTryAgain => 'Réessayer';

  @override
  String get chatStatusNotSent => 'Non envoyé · appui long pour réessayer';

  @override
  String get chatStatusSending => 'Envoi…';

  @override
  String get chatMessageRemoved => 'Message retiré';

  @override
  String chatSemanticsYouAt(String time) {
    return 'Toi à $time';
  }

  @override
  String chatSemanticsMemberAt(String name, String time) {
    return '$name à $time';
  }

  @override
  String chatAboutMember(String name) {
    return 'À propos de $name';
  }

  @override
  String get chatComposerHint => 'Écris un message';

  @override
  String get chatMutedComposerHint => 'Tu ne peux pas écrire pour l’instant';

  @override
  String get chatSend => 'Envoyer';

  @override
  String chatRoomMutedUntil(String when) {
    return 'Tu es en sourdine dans ce salon jusqu’à $when. Tu peux continuer à lire.';
  }

  @override
  String get chatRoomMuted =>
      'Tu es en sourdine dans ce salon. Tu peux continuer à lire.';

  @override
  String chatReadOnlyUntil(String when) {
    return 'Tu peux lire cette conversation, mais pas écrire avant $when.';
  }

  @override
  String get chatReadOnly =>
      'Tu peux lire cette conversation, mais pas écrire pour l’instant.';

  @override
  String get chatMuteTooltip => 'Couper les notifications';

  @override
  String get chatMutedTooltip => 'Notifications coupées';

  @override
  String get chatMuteSheetTitle => 'Couper les notifications';

  @override
  String get chatMuteSheetBody =>
      'Les messages arrivent toujours ici, simplement sans notification.';

  @override
  String get chatMuteOneHour => 'Pendant 1 heure';

  @override
  String get chatMuteEightHours => 'Pendant 8 heures';

  @override
  String get chatMuteOneWeek => 'Pendant 1 semaine';

  @override
  String get chatMuteForever => 'Jusqu’à ce que je les réactive';

  @override
  String get chatUnmute => 'Réactiver les notifications';

  @override
  String chatMutedUntilLabel(String when) {
    return 'Coupées jusqu’à $when';
  }

  @override
  String get chatMutedIndefinitely =>
      'Coupées jusqu’à ce que tu réactives les notifications.';

  @override
  String get chatMuteDone => 'Notifications coupées.';

  @override
  String get chatUnmuteDone => 'Les notifications sont réactivées.';

  @override
  String get chatMuteFailed =>
      'Impossible de modifier les notifications. Réessaie.';

  @override
  String get roomsClosedSnack => 'Ce salon est fermé.';

  @override
  String get roomsChatNotOpen => 'Le chat de ce salon n’est pas encore ouvert.';

  @override
  String get roomsJoinFailed => 'Impossible de rejoindre ce salon. Réessaie.';

  @override
  String get roomsStartRoom => 'Lancer un salon';

  @override
  String get roomsEyebrow => 'CHAT EN DIRECT';

  @override
  String get roomsTitle => 'Salons';

  @override
  String get roomsSubtitle =>
      'Rejoins une conversation. Si le courant passe avec quelqu’un, ajoute-le en ami.';

  @override
  String get roomsSectionRooms => 'SALONS';

  @override
  String get roomsSectionYours => 'TES SALONS';

  @override
  String get roomsYoursCaption =>
      'Les salons où tu es. Touche pour reprendre la discussion.';

  @override
  String get roomsSectionLive => 'EN DIRECT';

  @override
  String get roomsLiveTitle => 'Là où ça discute';

  @override
  String get roomsSectionBrowse => 'PARCOURIR';

  @override
  String get roomsBrowseTitle => 'Trouve ton salon';

  @override
  String get roomsBrowseCaption =>
      'Toujours ouverts. Choisis un sujet, dis bonjour et vois avec qui le courant passe.';

  @override
  String get roomsNoFriendsHere =>
      'Aucun de tes amis n’est dans un salon pour le moment.';

  @override
  String get roomsNoRoomsInTopic => 'Aucun salon sur ce sujet pour l’instant.';

  @override
  String get roomsSectionComingUp => 'BIENTÔT';

  @override
  String get roomsComingUpCaption =>
      'Des salons animés par des membres. Rejoins-les tôt pour garder ta place.';

  @override
  String get roomsCategoryAll => 'Tous';

  @override
  String get roomsCategoryTalk => 'Discussions';

  @override
  String get roomsCategoryInterests => 'Centres d’intérêt';

  @override
  String get roomsCategoryActive => 'Sorties';

  @override
  String get roomsCategoryCity => 'Ta ville';

  @override
  String get roomsFriendsHereChip => 'Amis présents';

  @override
  String get roomsQuiet =>
      'C’est calme pour l’instant. Sois le premier à dire bonjour.';

  @override
  String roomsPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes',
      one: '1 personne',
    );
    return '$_temp0';
  }

  @override
  String roomsRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count salons',
      one: '1 salon',
    );
    return '$_temp0';
  }

  @override
  String roomsChattingIn(String people, String rooms) {
    return '$people discutent dans $rooms';
  }

  @override
  String roomsHereNow(int count) {
    return '$count présents';
  }

  @override
  String roomsInTheRoom(int count) {
    return '$count dans le salon';
  }

  @override
  String roomsFriendsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amis présents',
      one: '1 ami présent',
    );
    return '$_temp0';
  }

  @override
  String get roomsHostedByYou => 'Animé par toi';

  @override
  String roomsHostedBy(String name) {
    return 'Animé par $name';
  }

  @override
  String get roomsActionOpen => 'Ouvrir';

  @override
  String get roomsActionFull => 'Complet';

  @override
  String get roomsActionJoin => 'Rejoindre';

  @override
  String roomsStartsAt(String time) {
    return 'Commence à $time';
  }

  @override
  String roomsStartsOn(String day, String time) {
    return 'Commence le $day à $time';
  }

  @override
  String get roomsStartNameTooShort =>
      'Donne au salon un nom d’au moins 3 caractères.';

  @override
  String get roomsStartIntro =>
      'C’est toi qui l’animes : tu peux avertir, mettre en sourdine ou retirer des personnes, et le fermer quand tu as fini. Un salon à la fois.';

  @override
  String get roomsStartNameLabel => 'Nom du salon';

  @override
  String get roomsStartNameHint => 'Échange de livres du dimanche';

  @override
  String get roomsStartAboutLabel => 'De quoi ça parle ? (facultatif)';

  @override
  String get roomsStartTopic => 'Sujet';

  @override
  String get roomsStartHowLong => 'Durée';

  @override
  String get roomsLength30Min => '30 min';

  @override
  String get roomsLength1Hour => '1 heure';

  @override
  String get roomsLength2Hours => '2 heures';

  @override
  String get roomsStartNow => 'Lancer maintenant';

  @override
  String get roomsRoleHost => 'Hôte';

  @override
  String get roomsRoleModerator => 'Modérateur';

  @override
  String get roomsRoomFallback => 'Salon';

  @override
  String roomsChatEmpty(String room) {
    return 'Tu y es. Dis bonjour : tout le monde dans $room voit ce que tu écris ici.';
  }

  @override
  String get roomsPeopleTooltip => 'Personnes dans ce salon';

  @override
  String roomsLeaveTitle(String room) {
    return 'Quitter $room ?';
  }

  @override
  String get roomsLeaveBody =>
      'Tu ne verras plus les messages de ce salon. Tu peux revenir tant qu’il est ouvert.';

  @override
  String get roomsLeaveAction => 'Quitter le salon';

  @override
  String get roomsLeaveFailed => 'Impossible de quitter le salon. Réessaie.';

  @override
  String roomsCloseTitle(String room) {
    return 'Fermer $room ?';
  }

  @override
  String get roomsCloseBody =>
      'La discussion se termine pour tout le monde dans le salon. C’est définitif.';

  @override
  String get roomsCloseAction => 'Fermer le salon';

  @override
  String get roomsCloseFailed => 'Impossible de fermer le salon. Réessaie.';

  @override
  String get roomsMenuTooltip => 'Options du salon';

  @override
  String get roomsMenuPeople => 'Personnes présentes';

  @override
  String get roomsMenuModerate => 'Modérer';

  @override
  String roomsModerateTitle(String room) {
    return 'Modérer $room';
  }

  @override
  String get roomsModerateIntro =>
      'Touche une personne pour l’avertir, la mettre en sourdine ou la retirer. Les personnes en sourdine peuvent toujours lire ; celles retirées peuvent revenir à la fin de la session.';

  @override
  String get roomsPeopleIntro =>
      'Le courant passe avec quelqu’un ? Ajoute-le en ami pour continuer à discuter après le salon.';

  @override
  String get roomsMembersLoadFailed =>
      'Impossible de charger les personnes présentes.';

  @override
  String get roomsStatusFriend => 'Ami';

  @override
  String get roomsStatusHereNow => 'Présent';

  @override
  String get roomsStatusInRoom => 'Dans le salon';

  @override
  String get roomsStatusGone => 'N’est plus dans le salon';

  @override
  String roomsStatusMutedUntil(String time) {
    return 'En sourdine jusqu’à $time';
  }

  @override
  String roomsYouSuffix(String name) {
    return '$name (toi)';
  }

  @override
  String roomsRemoveTitle(String name) {
    return 'Retirer $name du salon ?';
  }

  @override
  String roomsRemoveBodyAlwaysOn(String name) {
    return '$name quitte la discussion maintenant et pourra revenir dans 24 heures.';
  }

  @override
  String roomsRemoveBodyHosted(String name) {
    return '$name quitte la discussion maintenant et ne pourra pas revenir avant la fin de ce salon.';
  }

  @override
  String roomsWarnTitle(String name) {
    return 'Avertir $name ?';
  }

  @override
  String roomsWarnBody(String name) {
    return '$name reçoit un rappel privé pour garder une conversation bienveillante et dans le sujet.';
  }

  @override
  String get roomsRemoveAction => 'Retirer';

  @override
  String get roomsWarnAction => 'Envoyer l’avertissement';

  @override
  String roomsRemovedDone(String name) {
    return '$name a été retiré du salon.';
  }

  @override
  String roomsWarnedDone(String name) {
    return 'Avertissement envoyé à $name.';
  }

  @override
  String get roomsModerationFailed => 'Ça n’a pas marché. Réessaie.';

  @override
  String roomsBlockedDone(String name) {
    return 'Tu as bloqué $name. Vous ne verrez plus vos messages respectifs ici.';
  }

  @override
  String get roomsReport => 'Signaler';

  @override
  String get roomsBlock => 'Bloquer';

  @override
  String get roomsModerateEyebrow => 'MODÉRER';

  @override
  String get roomsWarn => 'Avertir';

  @override
  String get roomsRemoveFromRoom => 'Retirer du salon';

  @override
  String get roomsMute => 'Mettre en sourdine';

  @override
  String get roomsUnmute => 'Réactiver';

  @override
  String roomsMuteSheetTitle(String name) {
    return 'Mettre $name en sourdine ?';
  }

  @override
  String roomsMuteSheetBody(String name) {
    return '$name peut toujours lire la discussion mais ne peut pas écrire avant la fin de la sourdine. Un message privé le prévient.';
  }

  @override
  String get roomsMuteTenMinutes => 'Pendant 10 minutes';

  @override
  String get roomsMuteOneHour => 'Pendant 1 heure';

  @override
  String get roomsMuteUntilEnd => 'Jusqu’à la fin du salon';

  @override
  String get roomsMuteOneDay => 'Pendant 24 heures';

  @override
  String roomsMutedDone(String name) {
    return '$name est en sourdine.';
  }

  @override
  String roomsUnmutedDone(String name) {
    return '$name peut de nouveau écrire.';
  }
}
