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
      'Le jour, ivoire chaud et vert forêt. La nuit, menthe douce et forêt profonde.';

  @override
  String get settingsLooksClassicLabel => 'Aujourd’hui';

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
      'Imaginez ensemble un premier bonjour. Le partage avec tes contacts est désactivé au départ.';

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
  String get planHeadlineFriendsAlerted => 'Ta demande d’aide est enregistrée';

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
      'Choisis des contacts de confiance avec qui partager tes nouvelles.';

  @override
  String get planFriendsKnowProposed =>
      'Le partage avec tes contacts est facultatif pour chaque plan.';

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
      'Ça reste entre toi et ton rendez-vous. Après ta proposition, choisis des contacts de confiance si tu veux partager les nouvelles du plan et du check-in.';

  @override
  String get planSectionWhen => 'Quand';

  @override
  String get planSectionWhat => 'Quoi';

  @override
  String get planSectionGroups => 'Contacts de confiance';

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
      'Accepte ce plan avec ton rendez-vous. Choisis ensuite des contacts de confiance si tu veux partager tes nouvelles.';

  @override
  String get planAcceptButton => 'Accepter le plan';

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
      'Propose un rendez-vous depuis une conversation. Tu choisis de partager ou non les nouvelles du plan et du check-in avec tes contacts de confiance.';

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
  String get plansNextUpcoming => 'Confirmé. Votre moment ensemble est prévu.';

  @override
  String get plansNextCheckin => 'Fais le point après ton rendez-vous';

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
      'Les plans apparaissent ici quand des amis choisissent explicitement de les partager avec toi.';

  @override
  String get plansViaGroup => 'Partagé avec toi';

  @override
  String get plansViaFriend => 'Contact de confiance';

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

  @override
  String get richFormattingToolbar => 'Mise en forme';

  @override
  String get richUndo => 'Annuler';

  @override
  String get richRedo => 'Rétablir';

  @override
  String get richBold => 'Gras';

  @override
  String get richItalic => 'Italique';

  @override
  String get richUnderline => 'Souligné';

  @override
  String get richStrikethrough => 'Barré';

  @override
  String get richHighlight => 'Surligner';

  @override
  String get richLink => 'Lien';

  @override
  String get richTextStyleMenu => 'Style de texte';

  @override
  String get richParagraph => 'Paragraphe';

  @override
  String get richHeading => 'Titre';

  @override
  String get richSubheading => 'Sous-titre';

  @override
  String get richQuote => 'Citation';

  @override
  String get richCallout => 'Encadré';

  @override
  String get richBulletList => 'Liste à puces';

  @override
  String get richNumberedList => 'Liste numérotée';

  @override
  String get richDivider => 'Séparateur';

  @override
  String get richAlignMenu => 'Alignement';

  @override
  String get richAlignStart => 'Aligner au début';

  @override
  String get richAlignCenter => 'Centrer';

  @override
  String get richAlignEnd => 'Aligner à la fin';

  @override
  String get richClearFormatting => 'Effacer la mise en forme';

  @override
  String get richWritingStyle => 'Style d\'écriture';

  @override
  String get richStyleClassic => 'Classique';

  @override
  String get richStyleClassicHint =>
      'Un sérif élégant, comme une page imprimée';

  @override
  String get richStyleModern => 'Moderne';

  @override
  String get richStyleModernHint => 'Net et facile à lire';

  @override
  String get richStyleJournal => 'Journal intime';

  @override
  String get richStyleJournalHint =>
      'Une italique chaleureuse, comme un journal';

  @override
  String get richStyleTypewriter => 'Machine à écrire';

  @override
  String get richStyleTypewriterHint => 'Lettres carrées et espacées';

  @override
  String get richStylePoetic => 'Poétique';

  @override
  String get richStylePoeticHint => 'Lignes centrées, aérées';

  @override
  String richWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots',
      one: '1 mot',
      zero: '0 mot',
    );
    return '$_temp0';
  }

  @override
  String get richAlignmentNote =>
      'L\'alignement et l\'espacement apparaissent dans l\'aperçu et pour vos lecteurs.';

  @override
  String get richLinkTitle => 'Ajouter un lien';

  @override
  String get richLinkField => 'Adresse web';

  @override
  String get richLinkInvalid => 'Saisissez une adresse https:// complète.';

  @override
  String get richLinkApply => 'Ajouter le lien';

  @override
  String get richLinkRemove => 'Supprimer le lien';

  @override
  String get richLinkNeedsSelection => 'Sélectionnez d\'abord les mots à lier.';

  @override
  String get richCancel => 'Annuler';

  @override
  String get richOpenLinkTitle => 'Ouvrir ce lien ?';

  @override
  String richOpenLinkBody(String host) {
    return '$host s\'ouvre en dehors de Connect. N\'ouvrez que les liens de confiance.';
  }

  @override
  String get richOpenLink => 'Ouvrir le lien';

  @override
  String get supportCentreEyebrow => 'AIDE ET ASSISTANCE';

  @override
  String get supportCentreTitle => 'Comment pouvons-nous vous aider ?';

  @override
  String get supportCentreSubtitle =>
      'Trouvez une réponse rapide ou contactez notre équipe. Chaque demande et réponse reste dans une conversation privée.';

  @override
  String get supportContactSection => 'NOUS CONTACTER';

  @override
  String get supportContactTitle => 'Contacter l’assistance';

  @override
  String get supportContactSubtitle =>
      'Dites-nous ce qui s’est passé. Nous répondons ici et vous prévenons.';

  @override
  String get supportMyTicketsTitle => 'Mes demandes';

  @override
  String get supportMyTicketsSubtitle => 'Suivez vos demandes et nos réponses';

  @override
  String supportOpenRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count demandes ouvertes',
      one: '1 demande ouverte',
    );
    return '$_temp0';
  }

  @override
  String supportUnreadReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouvelles réponses',
      one: '1 nouvelle réponse',
    );
    return '$_temp0';
  }

  @override
  String get supportQuickAnswersSection => 'RÉPONSES RAPIDES';

  @override
  String get supportFaqLoginTitle => 'Connexion';

  @override
  String get supportFaqLoginBody =>
      'Connectez-vous avec votre nom d’utilisateur unique et votre mot de passe.';

  @override
  String get supportFaqVerificationTitle => 'Vérification';

  @override
  String get supportFaqVerificationBody =>
      'La vérification d’identité est facultative tant que le prestataire est en pause.';

  @override
  String get supportFaqAbuseTitle => 'Abus';

  @override
  String get supportFaqAbuseBody =>
      'Utilisez Signaler sur un profil ou une conversation pour un traitement de sécurité plus rapide.';

  @override
  String get supportFaqBillingTitle => 'Facturation';

  @override
  String get supportFaqBillingBody =>
      'Indiquez la référence de la transaction, jamais les données de votre carte.';

  @override
  String get supportEmergencyNote =>
      'Si quelqu’un est en danger immédiat, contactez les services d’urgence locaux. Les demandes d’assistance ne remplacent pas l’aide d’urgence.';

  @override
  String get supportUnavailableTitle =>
      'Les demandes d’assistance ne sont pas disponibles pour le moment';

  @override
  String get supportUnavailableBody =>
      'Les réponses de cette page restent disponibles. Pour toute urgence, écrivez à support@connect.example.';

  @override
  String get supportBackToHelp => 'Retour à Aide et assistance';

  @override
  String get supportFormEyebrow => 'NOUVELLE DEMANDE';

  @override
  String get supportFormTitle => 'Contacter l’assistance';

  @override
  String get supportFormSubtitle =>
      'Donnez-nous assez de détails pour agir. N’indiquez jamais de mot de passe, code de récupération, numéro de carte ni pièce d’identité.';

  @override
  String get supportFormCategorySection => 'SUJET';

  @override
  String get supportFormCategoryLabel => 'Pour quoi avez-vous besoin d’aide ?';

  @override
  String get supportCategoryAccountLogin => 'Compte et connexion';

  @override
  String get supportCategoryVerification => 'Vérification';

  @override
  String get supportCategoryPaymentsBilling => 'Paiements et facturation';

  @override
  String get supportCategorySafetyHarassment => 'Sécurité et harcèlement';

  @override
  String get supportCategoryMatchesChat => 'Matchs et discussion';

  @override
  String get supportCategoryTechnical => 'Problème technique ou bug';

  @override
  String get supportCategoryFeatureRequest => 'Suggestion de fonctionnalité';

  @override
  String get supportCategoryPrivacyData => 'Confidentialité et données';

  @override
  String get supportCategoryOther => 'Autre';

  @override
  String get supportSafetyNote =>
      'Si vous ou quelqu’un d’autre êtes en danger immédiat, utilisez SOS dans l’app ou appelez les services d’urgence locaux. Les demandes de sécurité sont prioritaires, mais une demande n’est pas une ligne d’urgence.';

  @override
  String get supportOpenSos => 'Ouvrir SOS';

  @override
  String get supportFormDetailsSection => 'DÉTAILS';

  @override
  String get supportFormSubjectLabel => 'Objet';

  @override
  String get supportFormSubjectHint => 'Décrivez brièvement le problème';

  @override
  String get supportFormDescriptionLabel => 'Que s’est-il passé ?';

  @override
  String get supportFormDescriptionHint =>
      'Ce que vous avez fait, ce que vous attendiez et ce qui s’est passé à la place';

  @override
  String get supportFormScreenshotsSection => 'CAPTURES D’ÉCRAN';

  @override
  String supportFormScreenshotsCaption(int max) {
    return 'Facultatif. Jusqu’à $max images.';
  }

  @override
  String get supportAddScreenshot => 'Ajouter une capture';

  @override
  String supportRemoveAttachment(String name) {
    return 'Retirer $name';
  }

  @override
  String get supportAttachmentUploading => 'Envoi en cours';

  @override
  String get supportRetryUpload => 'Réessayer l’envoi';

  @override
  String supportFormDeviceNote(String version) {
    return 'Nous joindrons la version de l’app ($version), la plateforme, la version du système et la langue pour nous aider à résoudre le problème.';
  }

  @override
  String get supportSubmit => 'Envoyer la demande';

  @override
  String get supportErrorCategoryRequired => 'Choisissez un sujet.';

  @override
  String supportErrorSubjectLength(int min, int max) {
    return 'L’objet doit compter entre $min et $max caractères.';
  }

  @override
  String get supportErrorDescriptionRequired => 'Décrivez ce qui s’est passé.';

  @override
  String supportErrorDescriptionTooLong(int max) {
    return 'Restez sous $max caractères.';
  }

  @override
  String get supportErrorUploadsPending =>
      'Attendez la fin de l’envoi des captures ou retirez celles qui ont échoué.';

  @override
  String supportCreatedSnack(String reference) {
    return 'Demande $reference envoyée. Nous répondrons ici.';
  }

  @override
  String supportDuplicateSnack(String reference) {
    return 'Vous avez déjà envoyé cette demande, nous l’avons donc ouverte : $reference.';
  }

  @override
  String supportErrorRateLimited(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Vous avez envoyé plusieurs demandes en peu de temps. Réessayez dans $minutes minutes.',
      one:
          'Vous avez envoyé plusieurs demandes en peu de temps. Réessayez dans 1 minute.',
    );
    return '$_temp0';
  }

  @override
  String get supportErrorRateLimitedGeneric =>
      'Vous avez envoyé plusieurs demandes en peu de temps. Réessayez plus tard.';

  @override
  String get supportErrorTooManyOpen =>
      'Vous avez déjà 10 demandes ouvertes. Fermez-en une dont vous n’avez plus besoin ou attendez nos réponses.';

  @override
  String get supportErrorTicketClosed =>
      'Cette demande est fermée et ne peut plus être rouverte. Veuillez créer une nouvelle demande.';

  @override
  String get supportErrorReopenWindowPassed =>
      'Le délai pour rouvrir cette demande est dépassé. Veuillez créer une nouvelle demande.';

  @override
  String get supportErrorAlreadyRated => 'Vous avez déjà évalué cette demande.';

  @override
  String get supportErrorNotResolved =>
      'Vous pourrez évaluer la demande une fois résolue.';

  @override
  String get supportErrorAttachmentType =>
      'Seules les images JPEG ou PNG et les fichiers PDF peuvent être joints.';

  @override
  String get supportErrorAttachmentTooLarge =>
      'Ce fichier est trop volumineux. Les images peuvent faire jusqu’à 8 Mo.';

  @override
  String get supportErrorOffline =>
      'Impossible de joindre Connect pour le moment. Vérifiez votre connexion et réessayez.';

  @override
  String get supportErrorNotFound => 'Nous n’avons pas trouvé cette demande.';

  @override
  String get supportErrorGeneric =>
      'Une erreur s’est produite. Veuillez réessayer.';

  @override
  String get supportTryAgain => 'Réessayer';

  @override
  String get supportTicketsEyebrow => 'ASSISTANCE';

  @override
  String get supportTicketsTitle => 'Mes demandes';

  @override
  String get supportTicketsSubtitle => 'Vos demandes et nos réponses.';

  @override
  String get supportTicketsActiveSection => 'EN COURS';

  @override
  String get supportTicketsClosedSection => 'RÉSOLUES ET FERMÉES';

  @override
  String get supportTicketsEmptyTitle => 'Aucune demande pour l’instant';

  @override
  String get supportTicketsEmptyBody =>
      'Quand vous contactez l’assistance, votre demande et nos réponses apparaissent ici.';

  @override
  String get supportTicketsLoadErrorTitle =>
      'Impossible de charger vos demandes';

  @override
  String supportTicketUpdated(String when) {
    return 'Mise à jour $when';
  }

  @override
  String get supportNewTicket => 'Nouvelle demande';

  @override
  String get supportStatusOpen => 'Ouverte';

  @override
  String get supportStatusWaitingForYou => 'En attente de votre réponse';

  @override
  String get supportStatusOnHold => 'En pause';

  @override
  String get supportStatusResolved => 'Résolue';

  @override
  String get supportStatusClosed => 'Fermée';

  @override
  String supportStatusSemantics(String status) {
    return 'Statut : $status';
  }

  @override
  String get supportThreadAgentName => 'Assistance Connect';

  @override
  String get supportThreadYou => 'Vous';

  @override
  String supportTicketMeta(String category, String date) {
    return '$category · Ouverte le $date';
  }

  @override
  String get supportBannerOpen =>
      'Nous avons bien reçu votre demande. Notre équipe répondra ici et vous préviendra.';

  @override
  String get supportBannerWaiting =>
      'L’assistance a répondu et attend votre retour.';

  @override
  String get supportBannerOnHold =>
      'Votre demande est en pause pendant que nous l’examinons. Nous vous tiendrons informé ici.';

  @override
  String get supportBannerResolved =>
      'Marquée comme résolue. Répondez pour la rouvrir ; sinon, elle sera fermée automatiquement après 7 jours.';

  @override
  String supportBannerClosedUntil(String date) {
    return 'Cette demande est fermée. Vous pouvez la rouvrir jusqu’au $date.';
  }

  @override
  String get supportBannerClosed => 'Cette demande est fermée.';

  @override
  String supportBannerMerged(String reference) {
    return 'Cette demande a été fusionnée avec $reference. La conversation continue là-bas.';
  }

  @override
  String get supportReplyHint => 'Écrire une réponse';

  @override
  String get supportReplyDisabledHint =>
      'Les réponses sont fermées pour cette demande';

  @override
  String get supportSendReply => 'Envoyer la réponse';

  @override
  String get supportAttachScreenshot => 'Joindre une capture';

  @override
  String get supportCloseTicket => 'Fermer la demande';

  @override
  String get supportCloseConfirmTitle => 'Fermer cette demande ?';

  @override
  String get supportCloseConfirmBody =>
      'Fermez-la si votre problème est résolu. Vous pourrez la rouvrir pendant 14 jours.';

  @override
  String get supportCancel => 'Annuler';

  @override
  String get supportClosedSnack => 'Demande fermée.';

  @override
  String get supportReopen => 'Rouvrir la demande';

  @override
  String get supportReopenedSnack => 'Demande rouverte.';

  @override
  String get supportRateTitle => 'Comment nous sommes-nous débrouillés ?';

  @override
  String get supportRateCaption =>
      'Évaluez votre expérience pour cette demande.';

  @override
  String supportRateStar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étoiles',
      one: '1 étoile',
    );
    return '$_temp0';
  }

  @override
  String get supportRateCommentLabel =>
      'Quelque chose à ajouter ? (facultatif)';

  @override
  String get supportRateSubmit => 'Envoyer l’évaluation';

  @override
  String get supportRatedTitle => 'Merci pour votre avis';

  @override
  String supportRatedValue(int rating) {
    return 'Vous avez donné $rating sur 5.';
  }

  @override
  String get supportRatingSnack => 'Merci d’avoir évalué votre expérience.';

  @override
  String supportAttachmentImage(String name) {
    return 'Capture $name';
  }

  @override
  String get supportAttachmentLoadFailed =>
      'Impossible de charger la pièce jointe';

  @override
  String get supportThreadLoadErrorTitle =>
      'Impossible de charger cette demande';

  @override
  String get chemistryCardEntry => 'Un peu d’alchimie ?';

  @override
  String get memberProfileIntroducing => 'Découvre';

  @override
  String get memberProfileStarring => 'En vedette';

  @override
  String get memberProfileVerified => 'Vérifié';

  @override
  String memberProfilePhotoLabel(String name, int index, int count) {
    return '$name, photo $index sur $count';
  }

  @override
  String get memberProfileNoPhoto => 'Pas encore de photo';

  @override
  String get memberProfileViewPhotoHint => 'afficher en plein écran';

  @override
  String get memberProfileCloseGallery => 'Fermer les photos';

  @override
  String get memberProfilePhotos => 'Photos';

  @override
  String memberProfileMorePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autres photos',
      one: '1 autre photo',
    );
    return '$_temp0';
  }

  @override
  String get memberProfileSceneAbout => 'À propos';

  @override
  String get memberProfileSceneStories => 'Histoires';

  @override
  String get memberProfileSceneStoriesTitle => 'Un peu plus de moi';

  @override
  String get memberProfileSceneInterests => 'Centres d’intérêt';

  @override
  String get memberProfileSceneBasics => 'L’essentiel';

  @override
  String get memberProfileSceneLifestyle => 'Mode de vie';

  @override
  String get memberProfileSceneTrust => 'Confiance';

  @override
  String get memberProfileReadMore => 'Lire la suite';

  @override
  String get memberProfileReadLess => 'Réduire';

  @override
  String get memberProfileHobbies => 'Loisirs';

  @override
  String get memberProfileActivities => 'Activités';

  @override
  String get memberProfileSongs => 'En boucle';

  @override
  String get memberProfileBooks => 'Livres et romans';

  @override
  String get memberProfileLookingFor => 'Recherche';

  @override
  String get memberProfileLanguages => 'Langues';

  @override
  String get memberProfileDealBreakers => 'Points non négociables';

  @override
  String get memberProfileInCommon => 'En commun';

  @override
  String get memberProfileFactHeight => 'Taille';

  @override
  String memberProfileHeightCm(int cm) {
    return '$cm cm';
  }

  @override
  String get memberProfileFactWork => 'Métier';

  @override
  String get memberProfileFactEducation => 'Études';

  @override
  String get memberProfileFactLivesIn => 'Habite à';

  @override
  String get memberProfileFactMotherTongue => 'Langue maternelle';

  @override
  String get memberProfileFactReligion => 'Religion';

  @override
  String get memberProfileFactPersonality => 'Personnalité';

  @override
  String get memberProfileFactRelationship => 'Situation';

  @override
  String get memberProfileFactInstagram => 'Instagram';

  @override
  String get memberProfileFactDrinking => 'Alcool';

  @override
  String get memberProfileFactSmoking => 'Tabac';

  @override
  String get memberProfileFactWorkout => 'Sport';

  @override
  String get memberProfileFactDiet => 'Alimentation';

  @override
  String get memberProfileFactDietType => 'Régime';

  @override
  String get memberProfileFactSleep => 'Sommeil';

  @override
  String get memberProfileFactTravel => 'Voyages';

  @override
  String get memberProfileFactPets => 'Animaux';

  @override
  String get memberProfileFactPolitics => 'Politique';

  @override
  String get memberProfileFactOpenToCasual => 'Ouvert·e au léger';

  @override
  String get memberProfileFactPartyLover => 'Aime faire la fête';

  @override
  String get memberProfileVerifiedTitle => 'Profil vérifié';

  @override
  String get memberProfileVerifiedBody => 'Vérification d’identité effectuée.';

  @override
  String get memberProfileVouchesTitle => 'Recommandé·e par des amis';

  @override
  String get memberProfileSpotlight => 'À la une';

  @override
  String get memberProfileFreeWhenYouAre => 'Libre quand tu l’es';

  @override
  String get memberProfileMessage => 'Message';

  @override
  String get memberProfileLove => 'Coup de cœur';

  @override
  String get memberProfileReport => 'Signaler';

  @override
  String get memberProfileOwnerTitle => 'Voilà comment on te voit';

  @override
  String get memberProfileOwnerCaption =>
      'Les membres voient ton profil exactement ainsi.';

  @override
  String memberProfileCompleteness(int percent) {
    return 'Profil complété à $percent %';
  }

  @override
  String get memberProfileCompletenessHint =>
      'Ajoute des photos, des histoires et des détails pour te démarquer.';

  @override
  String get memberProfileCompletenessDone => 'Ton profil est complet.';

  @override
  String get memberProfileToolEdit => 'Modifier le profil';

  @override
  String get memberProfileToolPhotos => 'Modifier les photos';

  @override
  String get memberProfileToolStories => 'Tes histoires';

  @override
  String get memberProfileToolViewers => 'Qui t’a vu';

  @override
  String get memberProfileBehindTheScenes => 'Dans les coulisses';

  @override
  String get memberProfileOnlyYou => 'Toi seul·e peux voir ceci.';

  @override
  String get memberProfileMine => 'Mon profil';

  @override
  String get profileShowcaseLabel => 'Écrits et moments';

  @override
  String get profileShowcaseTitleOther => 'Avec ses propres mots';

  @override
  String get profileShowcaseTitleSelf => 'Tes écrits et photos publics';

  @override
  String get profileShowcaseChapters => 'Chapitres';

  @override
  String get profileShowcasePhotos => 'Photos du mur';

  @override
  String get profileShowcaseReadAll => 'Lire tous ses chapitres';

  @override
  String get profileShowcaseHiddenTitle => 'Toi seul·e peux voir ceci';

  @override
  String get profileShowcaseHiddenBody =>
      'Tes chapitres publics et photos du mur sont masqués sur ton profil. Active cette option pour que les membres les voient ici.';

  @override
  String get profileShowcaseShownBody =>
      'Les membres peuvent les voir sur ton profil. Seuls les chapitres partagés avec la communauté et les photos du mur apparaissent.';

  @override
  String get profileShowcaseSwitch => 'Afficher sur mon profil';

  @override
  String get profileShowcaseSaveFailed =>
      'Ton choix n\'a pas pu être enregistré.';

  @override
  String get callsHistoryTitle => 'Historique des appels';

  @override
  String get callsHistoryEmpty => 'Aucun appel pour l’instant.';

  @override
  String callsHistoryMatch(String id) {
    return 'Match $id';
  }

  @override
  String get callsJoinLiveRoom => 'Rejoindre le salon en direct';

  @override
  String get callsActiveSession => 'Appel en cours';

  @override
  String callsEndedWithDuration(String duration) {
    return 'Terminé · $duration';
  }

  @override
  String get callsSessionTitle => 'Appel';

  @override
  String get callsStarting => 'Démarrage de l’appel sécurisé…';

  @override
  String get callsSessionActive => 'Appel actif';

  @override
  String get callsSessionUnavailable => 'Appel indisponible';

  @override
  String get callsLiveRoomNote =>
      'Le salon en direct s’ouvre dans une fenêtre sécurisée du fournisseur. Pendant l’appel, utilise ses commandes de micro, de caméra et de sortie.';

  @override
  String get callsEnd => 'Raccrocher';

  @override
  String get callsErrorSignInHistory =>
      'Connecte-toi pour voir l’historique des appels.';

  @override
  String get callsErrorSignInStart => 'Connecte-toi avant de lancer un appel.';

  @override
  String get callsErrorPermissions =>
      'Les appels nécessitent l’accès à la caméra et au micro.';

  @override
  String get callsErrorLoadHistory =>
      'Impossible de charger l’historique des appels.';

  @override
  String get callsErrorStart => 'Impossible de lancer l’appel.';

  @override
  String get callsErrorEnd => 'Impossible de terminer l’appel.';

  @override
  String get callsErrorNotConfigured =>
      'Les salons d’appel en direct ne sont pas configurés dans cet environnement.';

  @override
  String get callsErrorOpenRoom =>
      'Impossible d’ouvrir le salon d’appel en direct.';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonApply => 'Appliquer';

  @override
  String get commonReset => 'Réinitialiser';

  @override
  String get commonOpen => 'Ouvrir';

  @override
  String get commonView => 'Voir';

  @override
  String get commonDismiss => 'Ignorer';

  @override
  String get commonAny => 'Indifférent';

  @override
  String get commonSomethingWentWrong => 'Une erreur s’est produite';

  @override
  String get commonSomethingWentWrongTryAgain =>
      'Une erreur s’est produite. Réessaie.';

  @override
  String get commonTryAgainTitle => 'Réessayer';

  @override
  String get commonNothingHereYet => 'Rien pour l’instant';

  @override
  String commonLoadingLabel(String label) {
    return '$label, chargement';
  }

  @override
  String commonDistanceKm(int distance) {
    return '$distance km';
  }

  @override
  String get navToday => 'Aujourd’hui';

  @override
  String get navOfflineBanner =>
      'Mode hors ligne : certaines données peuvent être obsolètes.';

  @override
  String navWeakNetworkBanner(int mbps) {
    return 'Réseau faible détecté. Utilise au moins $mbps Mb/s pour une app plus fluide.';
  }

  @override
  String get navIncomingCallTitle => 'Appel entrant';

  @override
  String get navIncomingCallBody => 'Un match t’appelle.';

  @override
  String get navViewCallDetails => 'Voir les détails de l’appel';

  @override
  String get filterSheetTitle => 'Filtrer les matchs';

  @override
  String get filterAgeRange => 'Tranche d’âge';

  @override
  String get filterProfileLifestyle => 'Filtres profil et mode de vie';

  @override
  String get filterCountry => 'Pays';

  @override
  String get filterState => 'État/région';

  @override
  String get filterCity => 'Ville';

  @override
  String get filterMotherTongue => 'Langue maternelle';

  @override
  String get filterReligion => 'Religion';

  @override
  String get filterRelationshipStatus => 'Situation amoureuse';

  @override
  String get filterSmoking => 'Tabac';

  @override
  String get filterDrinking => 'Alcool';

  @override
  String get filterPersonalityType => 'Type de personnalité';

  @override
  String get filterPartyLoverOnly => 'Fêtards uniquement';

  @override
  String get filterHookupsOnly => 'Rencontres d’un soir uniquement';

  @override
  String get filterAdvancedBio => 'Filtres de bio avancés';

  @override
  String get filterAdvancedBioBody =>
      'Livres, romans, chansons, loisirs, lieu et activités se gèrent dans Réglages → Préférences de rencontre.';

  @override
  String get filterOpenDatingPreferences =>
      'Ouvrir les préférences de rencontre';

  @override
  String get filterDistanceKm => 'Distance (km)';

  @override
  String get filterVerifiedOnlyTitle => 'Profils vérifiés uniquement';

  @override
  String get filterVerifiedOnlyBody =>
      'Afficher uniquement les profils vérifiés';

  @override
  String get filterVerifiedOnlyChip => 'Vérifiés uniquement';

  @override
  String get filterPartyLoverChip => 'Fêtard';

  @override
  String get filterHookupChip => 'Rencontre d’un soir';

  @override
  String get filterEnableTrust => 'Activer le filtrage par confiance';

  @override
  String filterMinimumTrustBadges(int count) {
    return 'Badges de confiance actifs minimum : $count';
  }

  @override
  String filterSavedSnack(
    int minAge,
    int maxAge,
    int distance,
    String verified,
    String trust,
  ) {
    String _temp0 = intl.Intl.selectLogic(verified, {
      'true': ', vérifiés uniquement',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(trust, {
      'true': ', filtre de confiance activé',
      'other': ', filtre de confiance désactivé',
    });
    return 'Filtres enregistrés : $minAge-$maxAge ans, $distance km$_temp0$_temp1';
  }

  @override
  String get optionNever => 'Jamais';

  @override
  String get optionOccasionally => 'Occasionnellement';

  @override
  String get optionSocially => 'En soirée';

  @override
  String get optionRegularly => 'Régulièrement';

  @override
  String get optionSingle => 'Célibataire';

  @override
  String get optionDivorced => 'Divorcé(e)';

  @override
  String get optionWidowed => 'Veuf/veuve';

  @override
  String get optionSeparated => 'Séparé(e)';

  @override
  String get optionComplicated => 'C’est compliqué';

  @override
  String get optionIntrovert => 'Introverti(e)';

  @override
  String get optionAmbivert => 'Ambiverti(e)';

  @override
  String get optionExtrovert => 'Extraverti(e)';

  @override
  String get optionHighSchool => 'Lycée';

  @override
  String get optionBachelors => 'Licence';

  @override
  String get optionMasters => 'Master';

  @override
  String get optionPhd => 'Doctorat';

  @override
  String get optionOther => 'Autre';

  @override
  String get optionPreferNotToSay => 'Je préfère ne pas le dire';

  @override
  String get optionHindu => 'Hindou(e)';

  @override
  String get optionMuslim => 'Musulman(e)';

  @override
  String get optionChristian => 'Chrétien(ne)';

  @override
  String get optionSikh => 'Sikh';

  @override
  String get optionBuddhist => 'Bouddhiste';

  @override
  String get optionJain => 'Jaïn(e)';

  @override
  String get optionJewish => 'Juif/juive';

  @override
  String get optionSpiritual => 'Spirituel(le)';

  @override
  String get optionAgnostic => 'Agnostique';

  @override
  String get optionAtheist => 'Athée';

  @override
  String get storiesNudgeTitle => 'Raconte un peu plus ton histoire';

  @override
  String get storiesNudgeBodyUnknown =>
      'De courtes histoires sur ton profil donnent aux autres une vraie raison de te dire bonjour.';

  @override
  String get storiesNudgeActionOpen => 'Ouvrir tes histoires';

  @override
  String get storiesNudgeBodyEmpty =>
      'Ajoute une courte histoire à ton profil : un petit bonheur, un week-end à partager. Les gens les lisent avant de te dire bonjour.';

  @override
  String get storiesNudgeActionFirst => 'Écris ta première histoire';

  @override
  String get storiesNudgeCompleteTitle => 'Ton histoire est complète';

  @override
  String get storiesNudgeCompleteBody =>
      'Tes trois histoires sont sur ton profil. Renouvelles-en une dès que la vie t’en offre une nouvelle.';

  @override
  String get storiesNudgeActionEdit => 'Modifier tes histoires';

  @override
  String storiesNudgeSharedTitle(int count, int max) {
    return 'Histoires partagées : $count sur $max';
  }

  @override
  String get storiesNudgeBodyMore =>
      'Une histoire de plus, c’est une autre façon de lancer la conversation.';

  @override
  String storiesNudgeBodyLatest(String prompt) {
    return 'Dernière : « $prompt ». Une de plus, c’est une autre façon de lancer la conversation.';
  }

  @override
  String get storiesNudgeActionAdd => 'Ajouter une autre histoire';

  @override
  String get storiesNudgeIdeas => 'Des idées pour commencer';

  @override
  String storiesProgressSemantics(int count, int max) {
    return 'Histoires écrites : $count sur $max';
  }

  @override
  String get storiesPromptLittleJoy =>
      'Une petite chose pour laquelle je prends toujours le temps';

  @override
  String get storiesPromptWeekend => 'Un week-end à partager';

  @override
  String get storiesPromptFirstHello => 'Un premier bonjour qui me plairait';

  @override
  String get storiesPromptLearning =>
      'Quelque chose que j’apprends, juste pour moi';

  @override
  String get storiesPromptCare =>
      'Une petite façon de montrer que je tiens à quelqu’un';

  @override
  String get storiesScreenTitle => 'Un peu plus de toi';

  @override
  String get storiesSignIn => 'Connecte-toi pour modifier tes histoires.';

  @override
  String get storiesLoadFailed => 'Impossible de charger tes histoires.';

  @override
  String get storiesTryAgain => 'Réessayer';

  @override
  String get storiesIncomplete =>
      'Ajoute du texte à chaque histoire et une description à chaque photo, ou supprime l’histoire inachevée.';

  @override
  String get storiesPublished => 'Tes histoires de profil sont publiées.';

  @override
  String get storiesSavedPrivately =>
      'Enregistré en privé. Tes histoires sont masquées pour les autres membres.';

  @override
  String get storiesSaveUnconfirmed =>
      'Nous n’avons pas pu confirmer l’enregistrement. Tes modifications sont toujours là ; recharge les histoires enregistrées pour vérifier.';

  @override
  String get storiesHeadline =>
      'Laisse quelqu’un découvrir\nle toi de tous les jours.';

  @override
  String get storiesIntro =>
      'Un petit rituel, l’histoire derrière une photo, un premier bonjour qui te plairait. Partage jusqu’à trois moments, avec tes propres mots.';

  @override
  String get storiesOptionalNote =>
      'Facultatif, sans score ni obligation de tout remplir. Évite les coordonnées ou les lieux précis que tu ne veux pas partager.';

  @override
  String get storiesPublishSwitch => 'Afficher ces histoires sur mon profil';

  @override
  String get storiesPublishSwitchHint =>
      'Désactivé par défaut. Visible par les membres éligibles quand ton profil est publié et disponible. Tu peux les masquer à tout moment.';

  @override
  String get storiesBackToEditing => 'Retour à la modification';

  @override
  String get storiesPreview => 'Aperçu de mes histoires';

  @override
  String get storiesPreviewBanner => 'APERÇU · RIEN N’EST PUBLIÉ';

  @override
  String get storiesAdd => 'Ajouter une histoire';

  @override
  String get storiesReloadDiscard =>
      'Recharger les histoires enregistrées · annuler les modifications';

  @override
  String get storiesSaving => 'Enregistrement…';

  @override
  String get storiesPublishButton => 'Publier les histoires';

  @override
  String get storiesSavePrivatelyButton => 'Enregistrer en privé';

  @override
  String get storiesPolicyNote =>
      'Les photos proviennent de ta galerie de profil approuvée. Les histoires et les photos restent soumises aux signalements des membres et aux règles de sécurité.';

  @override
  String storiesMomentLabel(int number) {
    return 'MOMENT $number';
  }

  @override
  String storiesRemoveTooltip(int number) {
    return 'Supprimer l’histoire $number';
  }

  @override
  String get storiesPromptLabel => 'Un point de départ';

  @override
  String get storiesTextLabel => 'Avec tes mots';

  @override
  String get storiesTextHint => 'Un vrai détail la rend unique.';

  @override
  String get storiesTextRequired =>
      'Ajoute quelques mots ou supprime cette histoire.';

  @override
  String get storiesPhotoLabel => 'Une photo, si tu veux';

  @override
  String get storiesWordsOnly => 'Texte seulement';

  @override
  String storiesProfilePhoto(int number) {
    return 'Photo de profil $number';
  }

  @override
  String get storiesPhotoDescriptionLabel => 'Décris cette photo';

  @override
  String get storiesPhotoDescriptionHelper =>
      'Aide les personnes qui utilisent un lecteur d’écran.';

  @override
  String get storiesPhotoDescriptionRequired =>
      'Ajoute une courte description de la photo.';

  @override
  String get storiesPhotoSemantics => 'Photo d’une histoire du profil';

  @override
  String get storiesSectionTitle => 'Un peu plus de moi';

  @override
  String get storiesRetryLoad => 'Recharger les histoires';

  @override
  String get authErrorSessionExpired =>
      'Ta session a pris fin. Reconnecte-toi.';

  @override
  String get authErrorSignInFailed => 'Connexion impossible. Réessaie.';

  @override
  String get authErrorCreateAccountFailed =>
      'Impossible de créer le compte. Réessaie.';

  @override
  String get authErrorCreateAccountGeneric => 'Impossible de créer le compte.';

  @override
  String get authErrorInvalidCredentials =>
      'Nom d\'utilisateur ou mot de passe incorrect.';

  @override
  String get authErrorUsernameFormat =>
      'Le nom d\'utilisateur doit contenir 3 à 30 caractères : lettres, chiffres, _ ou .';

  @override
  String get authErrorPasswordFormat =>
      'Le mot de passe doit faire 8 à 72 octets et contenir des lettres et des chiffres.';

  @override
  String get authWelcomeIntroducerLink => 'Juste là pour présenter des amis';

  @override
  String get signupBackTooltip => 'Retour';

  @override
  String get signupIntroducerTitle => 'Sois l\'ami qui rapproche les gens.';

  @override
  String get signupIntroducerBody =>
      'Un compte réservé aux amis. Pas de profil de rencontre, pas de photos, pas de swipe. Ton âge reste privé ; Connect est réservé aux adultes de 18 à 80 ans.';

  @override
  String get signupTitle => 'Crée ton compte';

  @override
  String get signupSubtitle =>
      'Choisis un nom d\'utilisateur unique et un mot de passe sécurisé';

  @override
  String get signupUsernameLabel => 'Nom d\'utilisateur unique';

  @override
  String get signupUsernameHint => 'ton_pseudo';

  @override
  String get signupUsernameHelp =>
      '3 à 30 caractères. Lettres, chiffres, tiret bas et point.';

  @override
  String get signupPasswordLabel => 'Mot de passe';

  @override
  String get signupPasswordHint => 'Au moins 8 caractères';

  @override
  String get signupConfirmPasswordHint => 'Confirme le mot de passe';

  @override
  String get signupNameLabel => 'Nom complet';

  @override
  String get signupNameHint => 'Ton nom';

  @override
  String get signupDobLabel => 'Date de naissance';

  @override
  String get signupDobPickerHelp => 'Choisis ta date de naissance';

  @override
  String get signupDobPlaceholder => 'Choisir une date';

  @override
  String get signupGenderLabel => 'Je m\'identifie comme';

  @override
  String get signupGenderMan => 'Homme';

  @override
  String get signupGenderWoman => 'Femme';

  @override
  String get signupGenderOther => 'Autre';

  @override
  String get signupCreateFriendAccount => 'Créer un compte ami';

  @override
  String get signupAlreadyHaveAccount => 'Tu as déjà un compte ?';

  @override
  String get signupErrorPasswordMismatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get signupErrorFullName => 'Saisis ton nom complet.';

  @override
  String get signupErrorDobMissing => 'Choisis ta date de naissance.';

  @override
  String get signupErrorUnderage => 'Tu dois avoir au moins 18 ans.';

  @override
  String get signupErrorAgeRange =>
      'Connect accueille actuellement les membres âgés de 18 à 80 ans.';

  @override
  String get signupErrorGenderMissing => 'Choisis comment tu t\'identifies.';

  @override
  String get authRecoveryEnterUsername => 'Saisis ton nom d\'utilisateur.';

  @override
  String get authRecoveryEnterCode => 'Saisis ton code de récupération.';

  @override
  String get authRecoveryPasswordRule =>
      'Utilise 8 à 72 caractères avec au moins une lettre et un chiffre.';

  @override
  String get authRecoveryResetDone =>
      'Ton mot de passe a été réinitialisé et tous les appareils ont été déconnectés. Connecte-toi avec ton nouveau mot de passe.';

  @override
  String get authRecoveryAssistanceDone =>
      'Si ce nom d\'utilisateur correspond à un compte Connect, notre équipe sécurité examinera la demande.';

  @override
  String get authRecoveryInvalidCode =>
      'Ce code de récupération n\'est pas valide ou a expiré.';

  @override
  String get authRecoveryOffline =>
      'Impossible de joindre Connect. Vérifie ta connexion et réessaie.';

  @override
  String get authRecoverySendFailed =>
      'Impossible d\'envoyer ta demande. Vérifie ta connexion et réessaie.';

  @override
  String get authRecoveryBackToSignIn => 'Retour à la connexion';

  @override
  String get authRecoveryHaveCode => 'J\'ai mon code';

  @override
  String get authRecoveryLostCode => 'J\'ai perdu mon code';

  @override
  String get authRecoveryHaveCodeIntro =>
      'Utilise le code de récupération enregistré lors de la création de ton compte, ou celui fourni par notre équipe sécurité.';

  @override
  String get authRecoveryLostCodeIntro =>
      'Indique-nous ton nom d\'utilisateur. Nous confirmerons ton identité avant d\'émettre un code de récupération. Nous ne demandons jamais ton mot de passe.';

  @override
  String get authRecoveryUsernameLabel => 'Nom d\'utilisateur';

  @override
  String get authRecoveryCodeLabel => 'Code de récupération';

  @override
  String get authRecoveryNewPasswordLabel => 'Nouveau mot de passe';

  @override
  String get authRecoveryMessageLabel =>
      'Tout ce qui peut nous aider (facultatif)';

  @override
  String get authRecoveryMessageHint =>
      'Par exemple, la date de ta dernière connexion';

  @override
  String get authRecoverySending => 'Envoi…';

  @override
  String get authRecoveryResetPassword => 'Réinitialiser le mot de passe';

  @override
  String get authRecoveryAskForHelp => 'Demander de l\'aide';

  @override
  String get authTermsTitle => 'Conditions générales';

  @override
  String get authTermsSubtitle =>
      'Un petit tour d\'horizon avant d\'entrer dans l\'appli.';

  @override
  String get authTermsIntro =>
      'Lis et accepte nos Conditions et notre Politique de confidentialité pour continuer.';

  @override
  String get authTermsCommunityTitle => 'Règles de la communauté';

  @override
  String get authTermsPointRespect => 'Sois respectueux et authentique.';

  @override
  String get authTermsPointNoHarassment =>
      'Pas de harcèlement ni de comportement frauduleux.';

  @override
  String get authTermsPointPrivacy =>
      'Tu contrôles tes paramètres de confidentialité et la visibilité de ton profil.';

  @override
  String get authTermsPointReports =>
      'Les signalements sont examinés pour assurer la sécurité de la communauté.';

  @override
  String get authTermsPointViolations =>
      'Les infractions peuvent entraîner une suspension ou la suppression du compte.';

  @override
  String get authTermsReviewLater =>
      'Tu pourras consulter le détail des règles plus tard dans les paramètres, mais tu dois les accepter avant d\'utiliser l\'appli.';

  @override
  String get authTermsAgreeCheckbox =>
      'J\'accepte les Conditions et la Politique de confidentialité';

  @override
  String get authTermsAcceptButton => 'J\'accepte et je continue';

  @override
  String get authTermsSaveFailed =>
      'Impossible d\'enregistrer ton accord. Vérifie ta connexion et réessaie.';

  @override
  String discoverSuperLikeSent(String name) {
    return 'Super like envoyé à $name';
  }

  @override
  String get discoverMatchPlaceholderMessage => 'Dis bonjour';

  @override
  String discoverChatNeedsMatch(String name) {
    return 'Tu pourras discuter avec $name une fois qu’un vrai match sera créé.';
  }

  @override
  String get discoverDailyLimitTitle => 'Tu as utilisé tous tes likes du jour';

  @override
  String get discoverDailyLimitBody =>
      'Reviens demain, ou passe à une offre supérieure pour plus de likes chaque jour.';

  @override
  String discoverDailyLimitResetBody(String reset) {
    return '$reset. Passe à une offre supérieure pour plus de likes chaque jour.';
  }

  @override
  String get discoverSeePlans => 'Voir les offres';

  @override
  String get discoverNotNow => 'Pas maintenant';

  @override
  String get discoverBackToToday => 'Retour à Aujourd’hui';

  @override
  String get discoverExploreTitle => 'Explorer';

  @override
  String get discoverSpotlightReviewed =>
      'Tous les profils à la une sont vus !';

  @override
  String get discoverAllReviewed => 'Tout est vu !';

  @override
  String get discoverCuratedForYou => 'Sélectionné pour toi';

  @override
  String get discoverTitle => 'Découvre des matchs';

  @override
  String get discoverTagline => 'Un peu de curiosité. Une vraie connexion.';

  @override
  String get discoverMessages => 'Messages';

  @override
  String get discoverFilters => 'Filtres';

  @override
  String get discoverYourDeck => 'Ta pile';

  @override
  String get discoverStatReady => 'Prêts';

  @override
  String get discoverStatLiked => 'Likés';

  @override
  String get discoverStatPassed => 'Passés';

  @override
  String get discoverEdit => 'Modifier';

  @override
  String get discoverShowingEveryone =>
      'Tous les profils correspondant à tes préférences s’affichent.';

  @override
  String get discoverToday => 'Aujourd’hui';

  @override
  String get discoverTodaySubtitle =>
      'Cinq suggestions, renouvelées chaque jour.';

  @override
  String get discoverViewAll => 'Tout voir';

  @override
  String get discoverMatchOnYourTerms => 'Matche selon tes règles';

  @override
  String get discoverMatchOnYourTermsBody =>
      'Un match naît d’un intérêt mutuel. Tu peux bloquer ou signaler n’importe qui depuis son profil ou votre conversation.';

  @override
  String get discoverErrorEyebrow => 'Connexion interrompue';

  @override
  String get discoverErrorTitle => 'Impossible de charger les profils';

  @override
  String discoverTrustFilteredBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Les filtres de confiance ont masqué $count profils. Assouplis-les ou actualise pour reconstituer ta pile.',
      one:
          'Les filtres de confiance ont masqué $count profil. Assouplis-les ou actualise pour reconstituer ta pile.',
    );
    return '$_temp0';
  }

  @override
  String get discoverDeckPreparingBody =>
      'Ta pile sélectionnée est en préparation. Actualise pour voir les nouveaux profils vérifiés près de chez toi.';

  @override
  String get discoverCheckBackSoon => 'Reviens bientôt';

  @override
  String get discoverNoSpotlightProfiles => 'Aucun profil à la une';

  @override
  String get discoverNoProfiles => 'Aucun profil';

  @override
  String get discoverRefresh => 'Actualiser';

  @override
  String get discoverPromisePrivate => 'Privé';

  @override
  String get discoverPremium => 'Premium';

  @override
  String discoverNotificationsUnread(int count) {
    return 'Notifications, $count non lues';
  }

  @override
  String get discoverLatestUnreadNotifications =>
      'Dernières notifications non lues';

  @override
  String get discoverNoUnreadNotifications => 'Aucune notification non lue';

  @override
  String get discoverNotificationWhoReplied => 'Qui m’a répondu';

  @override
  String discoverNotificationRepliesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouvelles réponses',
      one: '1 nouvelle réponse',
    );
    return '$_temp0';
  }

  @override
  String get discoverNotificationWhoLiked => 'Qui m’a liké';

  @override
  String discoverNotificationLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux likes',
      one: '1 nouveau like',
    );
    return '$_temp0';
  }

  @override
  String get discoverViewMore => 'Voir plus';

  @override
  String get discoverFitsYourWeek => 'Compatible avec ta semaine';

  @override
  String discoverTodayPicks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suggestions',
      one: '1 suggestion',
    );
    return '$_temp0';
  }

  @override
  String get discoverPickedForYouToday => 'Choisi pour toi aujourd’hui.';

  @override
  String get discoverErrorLoginToDiscover =>
      'Connecte-toi pour découvrir des profils.';

  @override
  String get discoverErrorLoadProfiles =>
      'Impossible de charger les profils. Réessaie.';

  @override
  String get discoverErrorSessionUnavailable =>
      'Session indisponible. Reconnecte-toi.';

  @override
  String get discoverErrorLikeRetry =>
      'Impossible de liker pour le moment. Réessaie.';

  @override
  String get discoverErrorLike => 'Impossible de liker pour le moment.';

  @override
  String get discoverErrorPassRetry =>
      'Impossible de passer ce profil pour le moment. Réessaie.';

  @override
  String get discoverErrorLoadLikedMe =>
      'Impossible de charger qui t’a liké. Réessaie.';

  @override
  String get discoverErrorAnswerInFlight =>
      'Ta réponse est déjà en cours d’envoi.';

  @override
  String get discoverErrorAnswer =>
      'Impossible d’envoyer ta réponse. Réessaie.';

  @override
  String get firstChapterTopicPace => 'Rythme de communication';

  @override
  String get firstChapterTopicDates => 'Confort en rendez-vous';

  @override
  String get firstChapterTopicLanguage => 'Langues';

  @override
  String get firstChapterTopicFamily => 'Place de la famille';

  @override
  String get firstChapterInMyWords => 'Avec mes mots';

  @override
  String firstChapterComfortOriginal(String language) {
    return 'Original · $language';
  }

  @override
  String firstChapterComfortMemberTranslation(String language) {
    return 'Traduction fournie par le membre · $language';
  }

  @override
  String get firstChapterComfortReloadSaved =>
      'Recharger la version enregistrée';

  @override
  String get firstChapterComfortReloadCards => 'Recharger les cartes';

  @override
  String get firstChapterComfortHeadline => 'Tes mots. Tes limites.';

  @override
  String get firstChapterComfortIntro =>
      'Un contexte facultatif pour les personnes avec qui tu as matché. Rien n\'est déduit de tes origines. Écris dans la langue qui te ressemble.';

  @override
  String get firstChapterComfortShareTitle =>
      'Partager ces cartes avec mes matchs';

  @override
  String get firstChapterComfortShareSubtitle =>
      'Désactivé, chaque carte reste privée.';

  @override
  String get firstChapterComfortRemoveFromDraft => 'Retirer du brouillon';

  @override
  String get firstChapterComfortTopicLabel => 'Un peu de contexte sur';

  @override
  String get firstChapterComfortOriginalLanguage => 'Langue d\'origine';

  @override
  String get firstChapterComfortOwnWords => 'Avec tes propres mots';

  @override
  String get firstChapterComfortOwnWordsHint =>
      'Par exemple : j\'aime les rendez-vous en journée et prendre un peu de temps pour être à l\'aise.';

  @override
  String get firstChapterComfortTranslation => 'Ta traduction (facultatif)';

  @override
  String get firstChapterComfortTranslationLanguage =>
      'Langue de la traduction (si ajoutée)';

  @override
  String get firstChapterComfortTranslationNote =>
      'Les traductions sont indiquées comme fournies par le membre. Tes mots d\'origine sont toujours conservés.';

  @override
  String get firstChapterComfortAddCard =>
      'Ajouter / remplacer cette carte dans le brouillon';

  @override
  String get firstChapterComfortMissingFields =>
      'Ajoute tes mots et leur langue. Une traduction a aussi besoin de sa langue.';

  @override
  String get firstChapterComfortUnaddedCard =>
      'Ajoute ta carte au brouillon avant d\'enregistrer.';

  @override
  String get firstChapterComfortSaveFailed =>
      'Ton brouillon est toujours là. Recharge pour vérifier la dernière version enregistrée avant de réessayer.';

  @override
  String get firstChapterSaving => 'Enregistrement…';

  @override
  String get firstChapterComfortSave => 'Enregistrer mes choix';

  @override
  String get firstChapterYourMatch => 'ton match';

  @override
  String get firstChapterSaveUnconfirmed =>
      'Nous n\'avons pas pu confirmer l\'enregistrement. Actualise pour vérifier avant de réessayer.';

  @override
  String get firstChapterJointPreviewTitle =>
      'Une histoire que vous approuvez tous les deux';

  @override
  String get firstChapterSoloPreviewTitle => 'Aperçu de ton chapitre public';

  @override
  String firstChapterThenSurprise(String surprise) {
    return 'Puis… $surprise';
  }

  @override
  String get firstChapterJointPreviewBody =>
      'Ton accord n\'est qu\'une moitié. Le lien ne fonctionne qu\'une fois que ton partenaire a aussi approuvé exactement cette carte. Chacun de vous peut le révoquer.';

  @override
  String get firstChapterSoloPreviewBody =>
      'Seuls cette scène et le début que tu as choisi sont publics. Pas de noms, de photos, de discussion privée, de lieu ni de contribution de ton partenaire. Tu peux révoquer le lien.';

  @override
  String get firstChapterKeepPrivate => 'Garder privé';

  @override
  String get firstChapterApproveMyHalf => 'Approuver ma moitié';

  @override
  String get firstChapterCreateShareLink => 'Créer un lien de partage';

  @override
  String get firstChapterStudioTitle => 'Studio Premier Chapitre';

  @override
  String get firstChapterRefresh => 'Actualiser le chapitre';

  @override
  String get firstChapterHeroEyebrow => 'UNE PETITE AVENTURE. DEUX AUTEURS.';

  @override
  String get firstChapterHeroTitle => 'La suite\nvous appartient.';

  @override
  String get firstChapterHeroSolo =>
      'Crée une scène. Transmets-la à un ami. Ou écris un premier chapitre avec une personne avec qui tu as matché.';

  @override
  String firstChapterHeroPair(String name) {
    return 'Toi et $name. Un début, un rebondissement inattendu et une histoire que vous pouvez vivre pour de vrai.';
  }

  @override
  String get firstChapterHeroPace =>
      'Facultatif, à ton rythme. Discuter reste toujours un choix.';

  @override
  String get firstChapterLoadFailed => 'Impossible de charger ton chapitre.';

  @override
  String get firstChapterTryAgain => 'Réessayer';

  @override
  String get firstChapterStepChooseScene => '01 / Choisis ta scène';

  @override
  String get firstChapterStepWriteBeginning => '02 / Écris le début';

  @override
  String get firstChapterStartOurChapter => 'Commencer notre chapitre';

  @override
  String get firstChapterPassTheChapter => 'Faire passer le chapitre';

  @override
  String get firstChapterYourFirstChapter => 'Votre premier chapitre';

  @override
  String get firstChapterItBeginsWith => 'TOUT COMMENCE PAR';

  @override
  String get firstChapterAndThen => 'ET PUIS…';

  @override
  String firstChapterDateIdeaNote(String beginning, String surprise) {
    return '$beginning. Puis $surprise.';
  }

  @override
  String get firstChapterMakeDateIdea => 'En faire une idée de rendez-vous';

  @override
  String get firstChapterDateIdeaHint =>
      'Une suggestion à façonner ensemble. Aucun rendez-vous n\'est réservé ni accepté automatiquement.';

  @override
  String get firstChapterYourTurn => 'À toi : ajoute une surprise.';

  @override
  String get firstChapterBeginningSaved =>
      'Ton début est enregistré. Ton match peut ajouter une surprise quand il le souhaite. Vous pouvez continuer à discuter.';

  @override
  String get firstChapterClose => 'Clore ce chapitre';

  @override
  String get firstChapterGiveBackTitle => 'Des histoires qui inspirent';

  @override
  String get firstChapterGiveBackBody =>
      'Votre lien peut inspirer un nouveau départ. Ne partagez que cette idée de rendez-vous anonyme, avec vos deux accords.';

  @override
  String get firstChapterPreviewAnonymous => 'Aperçu de notre histoire anonyme';

  @override
  String get firstChapterGreenLightTitle => 'Un feu vert privé';

  @override
  String get firstChapterInTheirWords => 'Avec ses mots';

  @override
  String get firstChapterMakeRoomTitle =>
      'Fais de la place à ce qui compte pour toi';

  @override
  String get firstChapterMakeRoomSubtitle =>
      'Ton rythme, tes langues, tes rendez-vous et les attentes de ta famille. Tes mots, partagés seulement quand tu le choisis.';

  @override
  String get firstChapterCreateWithConnection => 'Créer avec une connexion';

  @override
  String get firstChapterCreateTogether => 'Créer un premier chapitre ensemble';

  @override
  String get firstChapterMatchesAppearHere =>
      'Tes matchs réciproques apparaissent ici. Tu peux dès maintenant essayer et partager une scène en solo.';

  @override
  String get firstChapterSharedChapters => 'Tes chapitres partagés';

  @override
  String get firstChapterReloadShared => 'Recharger les chapitres partagés';

  @override
  String get firstChapterNothingPublic =>
      'Rien n\'est public tant que tu ne choisis pas de partager.';

  @override
  String get firstChapterGreenChat => 'Continuer à discuter';

  @override
  String get firstChapterGreenCall => 'Essayer un appel';

  @override
  String get firstChapterGreenDate => 'Proposer un rendez-vous';

  @override
  String get firstChapterGreenLightIntro =>
      'Seul un choix commun est révélé. Personne ne voit une demande restée sans réponse. Les choix expirent après sept jours ; efface-les pour les retirer.';

  @override
  String get firstChapterSavePrivately => 'Enregistrer en privé';

  @override
  String get firstChapterGreenLightNone =>
      'Toute étape suivante en commun apparaîtra ici.';

  @override
  String firstChapterGreenLightMutual(String choices) {
    return 'Vous êtes tous les deux à l\'aise avec : $choices';
  }

  @override
  String get firstChapterGreenLightNote =>
      'Un feu vert autorise à proposer. Un appel ou un rendez-vous nécessite toujours un accord séparé.';

  @override
  String get firstChapterLinkRevoked => 'Lien révoqué';

  @override
  String get firstChapterPublicScene => 'Scène publique et anonyme';

  @override
  String get firstChapterPrivateUntilBoth =>
      'Privé jusqu\'à l\'accord des deux';

  @override
  String get firstChapterLinkCopied =>
      'Lien du chapitre copié. Partage-le où tu veux.';

  @override
  String get firstChapterCopyLink => 'Copier le lien';

  @override
  String get firstChapterApproveStory => 'Approuver exactement cette histoire';

  @override
  String get firstChapterRevokeLink => 'Révoquer le lien';

  @override
  String networkSlowResponse(int mbps) {
    return 'Réseau faible détecté. Utilise au moins $mbps Mb/s pour des discussions, cadeaux et gestes plus fluides.';
  }

  @override
  String get networkOffline =>
      'Pas de connexion réseau stable. Reconnecte-toi pour continuer à utiliser l’app.';

  @override
  String networkWeak(int mbps) {
    return 'Le réseau est faible. Utilise au moins $mbps Mb/s pour une expérience plus fluide.';
  }

  @override
  String get networkCannotReachService =>
      'Impossible de joindre le service local. Vérifie que l’API est en cours d’exécution.';

  @override
  String get gateCheckingTerms => 'Vérification des conditions…';

  @override
  String get gateLoadingProfile => 'Chargement de ton profil…';

  @override
  String get gateConnectionIssue => 'Problème de connexion';

  @override
  String get safetyReportFailed => 'Le signalement a échoué';

  @override
  String get safetyBlockFailed => 'Le blocage a échoué';

  @override
  String get safetyUnblockFailed => 'Le déblocage a échoué';

  @override
  String get safetyNotAuthenticated => 'Non connecté';

  @override
  String get timeAgoJustNow => 'À l’instant';

  @override
  String timeAgoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String timeAgoWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count semaines',
      one: 'il y a 1 semaine',
    );
    return '$_temp0';
  }

  @override
  String get themePreviewBarrier => 'Aperçu du thème';

  @override
  String get themeNowShowing => 'À L’AFFICHE';

  @override
  String get themeTaglineRealLife => 'Ivoire chaud, vert forêt et abricot.';

  @override
  String get themeTaglineRealLifeNight =>
      'Vert forêt, menthe douce et lueur de bougie.';

  @override
  String get themeTaglineDaylight =>
      'Crème, encre et une touche framboise, comme le site web.';

  @override
  String get themeTaglineEmber => 'Nuit noir prune, braises et lueur violette.';

  @override
  String get themeTaglineForge =>
      'Rouge fournaise, bleu acier, chrome canon de fusil.';

  @override
  String get themeTaglineNeongrid =>
      'Verre noir, lignes de lumière cyan, pulsation ambre.';

  @override
  String get themeTaglineCrimsonalloy =>
      'Laque cramoisie, or fondu, bordeaux de minuit.';

  @override
  String get themeTaglineCircuit =>
      'Vert circuit, violet signal, noir carbone.';

  @override
  String get themeTaglineDeepfield =>
      'Espace profond, bleu plasma et un éclat d’or stellaire.';

  @override
  String get themeTaglineLove => 'Rose poudré, rose et un peu d’or.';

  @override
  String get themeTaglineRose => 'Vin velouté, rouge rose et un peu d’or.';

  @override
  String get themeTaglinePetal =>
      'Papier rosé, pétales qui volent, une touche de sauge.';

  @override
  String get themeTaglineSnow =>
      'Neige fraîche, verre givré et un ruban d’aurore boréale.';

  @override
  String get themeTaglineGothic =>
      'Remplages au clair de lune, grenat, fumée de bougie et or ancien.';

  @override
  String get themeTaglineCalm =>
      'Peu de stimulation, contraste élevé. Fond immobile, aucun mouvement.';

  @override
  String get themeLooksTodayDescription =>
      'Le jour, ivoire chaud et vert forêt. La nuit, menthe douce et forêt profonde.';

  @override
  String get settingsEyebrow => 'RÉGLAGES';

  @override
  String get settingsHeaderSubtitle =>
      'Ton style, ta vie privée et ton compte.';

  @override
  String get settingsThemeSection => 'Thème';

  @override
  String get settingsThemeSectionTitle => 'Personnalise-le';

  @override
  String get settingsThemeSectionCaption =>
      'Chaque écran suit le style que tu choisis.';

  @override
  String get settingsSectionYourStory => 'Ton histoire';

  @override
  String get settingsDatingRhythmTitle => 'Ton rythme de rencontres';

  @override
  String get settingsDatingRhythmSubtitle =>
      'Intention, rythme, disponibilités et confidentialité des présentations';

  @override
  String get settingsProfileStoriesTitle => 'Tes histoires de profil';

  @override
  String get settingsProfileStoriesSubtitle =>
      'Petits moments, tes mots, photos facultatives';

  @override
  String get settingsBlogTitle => 'Blog · Chapitres ouverts';

  @override
  String get settingsBlogSubtitle => 'Ton journal, tes photos, ton public';

  @override
  String get settingsLookPreviewEyebrow => 'AUJOURD’HUI';

  @override
  String get settingsLookPreviewHeadline => 'Quelque chose de vrai.';

  @override
  String get friendsEyebrow => 'AMIS';

  @override
  String get friendsTitle => 'Tes proches';

  @override
  String get friendsSubtitle =>
      'Entre amis, vous pouvez vous écrire, faire des plans et créer des groupes. Une demande doit être acceptée des deux côtés.';

  @override
  String get friendsBack => 'Retour';

  @override
  String get friendsAddFriend => 'Ajouter un ami';

  @override
  String get friendsCreateGroup => 'Créer un groupe';

  @override
  String get friendsSectionRequests => 'DEMANDES';

  @override
  String get friendsRequestsWaitingOnOthers => 'En attente des autres';

  @override
  String get friendsRequestsWaitingOnYou => 'On attend ta réponse';

  @override
  String get friendsRequestsCaption =>
      'Rien n’est partagé tant que vous n’êtes pas d’accord tous les deux.';

  @override
  String get friendsSectionChats => 'DISCUSSIONS';

  @override
  String get friendsChatsTitle => 'Conversations';

  @override
  String get friendsSectionIntros => 'PRÉSENTATIONS';

  @override
  String get friendsIntrosTitle => 'Présentations pour toi';

  @override
  String get friendsSectionVouches => 'RECOMMANDATIONS';

  @override
  String get friendsVouchesPendingTitle =>
      'Recommandations en attente de ton accord';

  @override
  String friendsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amis',
      one: '1 ami',
      zero: 'Pas encore d’amis',
    );
    return '$_temp0';
  }

  @override
  String get friendsIntroduce => 'Présenter';

  @override
  String get friendsEmptyBody =>
      'Trouve des personnes que tu connais par leur nom ou nom d’utilisateur, ou ajoute quelqu’un depuis un match, un salon ou un groupe.';

  @override
  String get friendsSectionOnProfile => 'SUR TON PROFIL';

  @override
  String get friendsVouchesOnProfileTitle => 'Recommandations sur ton profil';

  @override
  String friendsQuoted(String text) {
    return '« $text »';
  }

  @override
  String friendsVouchedForYou(String name) {
    return '$name t’a recommandé·e';
  }

  @override
  String get friendsHideFromProfile => 'Masquer du profil';

  @override
  String get friendsSectionMore => 'PLUS';

  @override
  String get friendsMoreTitle => 'Plans et présentations';

  @override
  String get friendsPlansLinkTitle => 'Plans de rendez-vous partagés avec toi';

  @override
  String get friendsPlansLinkSubtitle =>
      'Tes amis te préviennent quand ils prévoient un rendez-vous et quand ils donnent des nouvelles après.';

  @override
  String get friendsInviteIntroducerTitle =>
      'Invite un ami qui n’est pas sur les sites de rencontre';

  @override
  String get friendsInviteIntroducerSubtitle =>
      'Choisis qui peut te présenter. Tu peux revoir ou retirer ton autorisation à tout moment.';

  @override
  String get friendsIntroTermsTitle => 'Des présentations selon tes règles';

  @override
  String get friendsIntroTermsSubtitle =>
      'Choisis si tes amis peuvent te présenter et ce qu’un aperçu montre.';

  @override
  String get friendsSectionActivity => 'ACTIVITÉ';

  @override
  String get friendsActivityTitle => 'Avec tes amis';

  @override
  String friendsVouchSentSnack(String name) {
    return 'Recommandation envoyée. $name doit l’approuver avant qu’elle s’affiche.';
  }

  @override
  String friendsRemoveTitle(String name) {
    return 'Retirer $name ?';
  }

  @override
  String get friendsRemoveBody =>
      'Vous ne serez plus amis et votre discussion sera fermée. Cette personne n’est pas prévenue.';

  @override
  String get friendsRemoveFriend => 'Retirer cet ami';

  @override
  String get friendsIntroMadeSnack =>
      'Présentation faite. Tes deux amis vont recevoir ton message.';

  @override
  String get friendsAddSheetLabel => 'AJOUTER UN AMI';

  @override
  String get friendsAddSheetTitle => 'Trouve quelqu’un que tu connais';

  @override
  String get friendsAddSheetCaption =>
      'Cherche par nom ou @nom d’utilisateur. La personne choisit d’accepter ou non.';

  @override
  String get friendsSearchHiddenNote =>
      'Tu es masqué·e dans la recherche d’amis, donc les autres ne peuvent pas te trouver ici. Modifie ce réglage dans Confidentialité et sécurité.';

  @override
  String get friendsSearchLabel => 'Nom ou @nom d’utilisateur';

  @override
  String get friendsSearchHelper => 'Tape au moins 3 lettres';

  @override
  String get friendsSearchFailed =>
      'La recherche est indisponible pour le moment. Réessaie.';

  @override
  String friendsSearchNoResults(String query) {
    return 'Personne trouvé pour « $query ».';
  }

  @override
  String get friendsNewGroupLabel => 'NOUVEAU GROUPE';

  @override
  String get friendsNewGroupTitle => 'Qui en fait partie ?';

  @override
  String get friendsNewGroupCaption =>
      'Choisis les amis à inviter. Tu pourras en ajouter d’autres plus tard.';

  @override
  String get friendsChooseFriends => 'Choisis des amis';

  @override
  String friendsCreateGroupWith(int count) {
    return 'Créer un groupe avec $count';
  }

  @override
  String get friendsSourceMatch => 'Depuis tes matchs';

  @override
  String get friendsSourceProfile => 'A vu ton profil';

  @override
  String get friendsSourceRoom => 'Rencontré dans un salon';

  @override
  String get friendsSourceGroup => 'Depuis un groupe';

  @override
  String get friendsSourceSearch => 'T’a trouvé par ton nom';

  @override
  String get friendsWantsToBeFriends => 'Veut être ami·e avec toi';

  @override
  String get friendsRequestSent => 'Demande envoyée';

  @override
  String get friendsCancel => 'Annuler';

  @override
  String get friendsDecline => 'Refuser';

  @override
  String get friendsAccept => 'Accepter';

  @override
  String friendsMessageTooltip(String name) {
    return 'Écrire à $name';
  }

  @override
  String friendsMessageTooltipUnread(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Écrire à $name, $count non lus',
      one: 'Écrire à $name, 1 non lu',
    );
    return '$_temp0';
  }

  @override
  String friendsMoreFor(String name) {
    return 'Plus d’options pour $name';
  }

  @override
  String get friendsMenuVouch => 'Le recommander';

  @override
  String get friendsMenuIntro => 'Présenter à un ami';

  @override
  String friendsChatSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Discussion avec $name, $count non lus',
      one: 'Discussion avec $name, 1 non lu',
      zero: 'Discussion avec $name',
    );
    return '$_temp0';
  }

  @override
  String friendsChatSemanticsMuted(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Discussion avec $name, $count non lus, notifications désactivées',
      one: 'Discussion avec $name, 1 non lu, notifications désactivées',
      zero: 'Discussion avec $name, notifications désactivées',
    );
    return '$_temp0';
  }

  @override
  String friendsIntroHeadline(String introducer, String person) {
    return '$introducer pense que tu devrais rencontrer $person';
  }

  @override
  String friendsIntroHeadlineSomeone(String introducer) {
    return '$introducer pense que tu devrais rencontrer quelqu’un';
  }

  @override
  String friendsNameAge(String name, int age) {
    return '$name, $age ans';
  }

  @override
  String get friendsIntroNoThanks => 'Non merci';

  @override
  String get friendsIntroImIn => 'Ça me tente';

  @override
  String get friendsVouchKeepPrivate => 'Garder privé';

  @override
  String get friendsVouchShowOnProfile => 'Afficher sur mon profil';

  @override
  String get memberProfileNoData => 'Aucune donnée de profil trouvée.';

  @override
  String get memberProfileSignInToView => 'Connecte-toi pour voir ton profil.';

  @override
  String get memberProfileLoadFailed =>
      'Impossible de charger le profil. Réessaie.';

  @override
  String get memberProfileConnectionsTitle => 'Tes connexions';

  @override
  String get memberProfileConnectionsCaption =>
      'Les personnes que tu as likées, tes matchs et tes conversations.';

  @override
  String get memberProfileStatLiked => 'Tes likes';

  @override
  String get memberProfileStatMatches => 'Matchs';

  @override
  String get memberProfileStatMessages => 'Messages';

  @override
  String memberProfileOpenStat(String label) {
    return 'Ouvrir $label';
  }

  @override
  String get memberProfileNoticedTitle => 'Qui t’a remarqué';

  @override
  String get memberProfileNoticedCaption =>
      'Likes et visites de membres près de toi.';

  @override
  String get memberProfileWhoLikedMe => 'Qui m’a liké';

  @override
  String memberProfileWhoLikedMeCount(int count) {
    return 'Qui m’a liké ($count)';
  }

  @override
  String get memberProfileWhoLikedMeSubtitle =>
      'Les membres qui ont liké ton profil.';

  @override
  String get memberProfileWhoViewedTitle => 'Qui a vu mon profil';

  @override
  String get memberProfileWhoViewedSubtitle =>
      'Visites récentes sur ton profil.';

  @override
  String get memberProfileWhoViewedTooltip => 'Qui a vu mon profil';

  @override
  String get memberProfileRefreshTooltip => 'Actualiser le profil';

  @override
  String get memberProfilePreferencesTitle => 'Tes préférences';

  @override
  String get memberProfilePrefSeeking => 'Je cherche';

  @override
  String get memberProfilePrefDistance => 'Distance';

  @override
  String memberProfileWithinKm(int km) {
    return 'Dans un rayon de $km km';
  }

  @override
  String get profileViewersTitle => 'Visiteurs de mon profil';

  @override
  String get profileViewersLoadFailed =>
      'Impossible de charger les visiteurs du profil.';

  @override
  String get profileViewersEmpty => 'Personne n’a encore vu ton profil.';

  @override
  String get profileViewersViewedRecently => 'Vu récemment';

  @override
  String profileViewersViewedAt(String time) {
    return 'Vu le $time';
  }

  @override
  String get profileMasterReligionParsi => 'Parsi(e)';

  @override
  String get profileMasterReligionBahai => 'Baha’i(e)';

  @override
  String get profileMasterReligionTribal => 'Tribal(e) / Autochtone';

  @override
  String get profileMasterWorkout1to2 => '1 à 2 fois par semaine';

  @override
  String get profileMasterWorkout3to4 => '3 à 4 fois par semaine';

  @override
  String get profileMasterWorkout5Plus => '5 fois ou plus par semaine';

  @override
  String get profileMasterWorkoutDaily => 'Tous les jours';

  @override
  String get profileMasterDietNoPreference => 'Pas de préférence';

  @override
  String get profileMasterDietVegetarian => 'Végétarien(ne)';

  @override
  String get profileMasterDietEggetarian => 'Végétarien(ne) avec œufs';

  @override
  String get profileMasterDietNonVegetarian => 'Non végétarien(ne)';

  @override
  String get profileMasterDietVegan => 'Végan(e)';

  @override
  String get profileMasterDietJain => 'Alimentation jaïne';

  @override
  String get profileMasterDietTypeBalanced => 'Équilibrée';

  @override
  String get profileMasterDietTypeHighProtein => 'Riche en protéines';

  @override
  String get profileMasterDietTypeLowCarb => 'Pauvre en glucides';

  @override
  String get profileMasterDietTypeKeto => 'Cétogène';

  @override
  String get profileMasterDietTypeMediterranean => 'Méditerranéenne';

  @override
  String get profileMasterDietTypeIntermittentFasting => 'Jeûne intermittent';

  @override
  String get profileMasterSleepEarlyBird => 'Lève-tôt';

  @override
  String get profileMasterSleepNightOwl => 'Couche-tard';

  @override
  String get profileMasterSleepFlexible => 'Flexible';

  @override
  String get profileMasterSleepShiftBased => 'Horaires décalés';

  @override
  String get profileMasterTravelHomebody => 'Casanier(ère)';

  @override
  String get profileMasterTravelOccasional => 'Voyageur(se) occasionnel(le)';

  @override
  String get profileMasterTravelFrequent => 'Grand(e) voyageur(se)';

  @override
  String get profileMasterTravelAdventure => 'Amateur(trice) d’aventure';

  @override
  String get profileMasterTravelLuxury => 'Voyages de luxe';

  @override
  String get profileMasterTravelBackpacker => 'Routard(e)';

  @override
  String get profileMasterPoliticsSimilar => 'Seulement des opinions proches';

  @override
  String get profileMasterPoliticsOpen => 'Ouvert(e) aux différences';

  @override
  String get profileMasterPoliticsNotDiscuss => 'Préfère ne pas en parler';

  @override
  String get profileMasterPoliticsNoStrong => 'Pas de préférence marquée';

  @override
  String get profileMasterIntentLongTerm => 'Relation durable';

  @override
  String get profileMasterIntentMarriage => 'Mariage';

  @override
  String get profileMasterIntentNewFriends => 'Nouveaux amis';

  @override
  String get chatBackToConversations => 'Retour aux conversations';

  @override
  String get chatOfflineBanner =>
      'Tu es hors ligne. Ton brouillon reste ici le temps de te reconnecter.';

  @override
  String get chatVoiceHello => 'Partager un bonjour vocal · lire et écouter';

  @override
  String get chatLoadFailedTitle => 'Reconnectons-nous.';

  @override
  String get chatLoadFailedBody =>
      'Ta conversation n’a pas pu se charger. Réessaie.';

  @override
  String get chatConversationEnded => 'Cette conversation est terminée.';

  @override
  String get chatUnlockStepRequired =>
      'Termine l’étape de déblocage en cours pour continuer cette conversation.';

  @override
  String get chatGiftTrayTitle => 'Une petite attention';

  @override
  String get chatCloseGifts => 'Fermer les cadeaux';

  @override
  String get chatAllGifts => 'Tous les cadeaux';

  @override
  String get chatNoGiftsInCollection =>
      'Aucun cadeau disponible dans cette collection.';

  @override
  String get chatAddCoins => 'Ajouter des pièces';

  @override
  String get chatFreeGiftDaily => 'Gratuit · 1 par jour';

  @override
  String chatCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièces',
      one: '1 pièce',
    );
    return '$_temp0';
  }

  @override
  String get chatSendingGift => 'Envoi de ton cadeau…';

  @override
  String get chatOfflineGifts =>
      'Tu es hors ligne. Tu peux parcourir les cadeaux et les envoyer une fois reconnecté·e.';

  @override
  String chatGiftConfirmTitle(String gift, String name) {
    return 'Envoyer $gift à $name ?';
  }

  @override
  String chatGiftNoteQuote(String note) {
    return '« $note »';
  }

  @override
  String chatGiftBalanceAfter(int balance, int remaining) {
    return '·  $balance → il en restera $remaining';
  }

  @override
  String get chatGiftNoObligation =>
      'Un cadeau est un geste, jamais une obligation de répondre ou de se rencontrer.';

  @override
  String chatGiftSendFor(String price) {
    return 'Envoyer pour $price';
  }

  @override
  String get chatNotNow => 'Pas maintenant';

  @override
  String get chatDeleteMessageTitle => 'Supprimer le message ?';

  @override
  String get chatDeleteMessageBody =>
      'Le message sera supprimé de vos deux conversations.';

  @override
  String get chatDeleteForEveryone => 'Supprimer pour tout le monde';

  @override
  String get chatMessageDeletedSnack => 'Message supprimé.';

  @override
  String get chatUndo => 'Annuler';

  @override
  String get chatDeleteUndone => 'Suppression annulée.';

  @override
  String chatGiftReceivedFrom(String name) {
    return 'Cadeau reçu de $name';
  }

  @override
  String get chatGiftReceiverIntro =>
      'C’est toi qui décides de ce qui reste dans ta conversation.';

  @override
  String get chatHideGift => 'Masquer le cadeau';

  @override
  String get chatHideGiftSubtitle =>
      'Le retirer uniquement de ta conversation.';

  @override
  String get chatReportAndHide => 'Signaler et masquer';

  @override
  String get chatReportAndHideSubtitle =>
      'L’envoyer à l’équipe sécurité et le retirer tout de suite.';

  @override
  String get chatGiftHidden => 'Cadeau masqué de ta conversation.';

  @override
  String get chatReportGiftTitle => 'Signaler ce cadeau';

  @override
  String get chatReportGiftIntro =>
      'Choisis une raison. Le cadeau sera masqué immédiatement.';

  @override
  String get chatReportReasonLabel => 'Raison';

  @override
  String get chatReportReasonUnwanted => 'Cadeau non désiré';

  @override
  String get chatReportReasonHarassment => 'Harcèlement';

  @override
  String get chatReportReasonSexual => 'Contenu sexuel';

  @override
  String get chatReportReasonScam => 'Arnaque ou fraude';

  @override
  String get chatReportReasonOther => 'Autre chose';

  @override
  String get chatReportDetailsLabel => 'Ajouter des détails (facultatif)';

  @override
  String get chatReportSubmit => 'Envoyer le signalement et masquer';

  @override
  String get chatGiftReported =>
      'Cadeau signalé et masqué. Notre équipe sécurité va l’examiner.';

  @override
  String get chatQuickEmojis => 'Émojis rapides';

  @override
  String chatWalletTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièces',
      one: '1 pièce',
    );
    return 'Ton portefeuille · $_temp0';
  }

  @override
  String get chatDailyLimitReached => 'Limite quotidienne de messages atteinte';

  @override
  String get chatDailyLimitFallback =>
      'Réessaie demain ou passe à une formule supérieure.';

  @override
  String chatDailyLimitReset(String reset) {
    return '$reset · passe à une formule supérieure pour en avoir plus.';
  }

  @override
  String get chatSeePlans => 'Voir les formules';

  @override
  String chatQuotaOnPlan(String quota, String plan) {
    return '$quota avec $plan';
  }

  @override
  String get chatYourConversation => 'Votre conversation';

  @override
  String get chatVerifiedHumans => 'Humains vérifiés';

  @override
  String get chatVerifiedHumansShowsUp =>
      'Humains vérifiés · Vient aux rendez-vous';

  @override
  String discoverLikedBack(String name) {
    return 'Tu as liké $name en retour';
  }

  @override
  String discoverPassedOn(String name) {
    return 'Tu as passé $name';
  }

  @override
  String get discoverLikedMeLoadFailedTitle =>
      'Impossible de charger tes likes';

  @override
  String get discoverLikedMeEmptyTitle => 'Pas encore de nouveaux likes';

  @override
  String get discoverLikedMeEmptyBody =>
      'Quand quelqu’un te like, il apparaît ici. Like-le en retour et c’est un match.';

  @override
  String get discoverLikedMeIntro =>
      'Ces personnes te likent déjà. Like en retour pour matcher, ou passe. Passer reste privé.';

  @override
  String get discoverLikedMeTitle => 'T’ont liké';

  @override
  String discoverLikedMeTitleCount(int count) {
    return 'T’ont liké · $count';
  }

  @override
  String get discoverPass => 'Passer';

  @override
  String get discoverLikeBack => 'Liker en retour';

  @override
  String get discoverLikedJustNow => 'T’a liké à l’instant';

  @override
  String discoverLikedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'T’a liké il y a $count minutes',
      one: 'T’a liké il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'T’a liké il y a $count heures',
      one: 'T’a liké il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'T’a liké il y a $count jours',
      one: 'T’a liké il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'T’a liké il y a $count semaines',
      one: 'T’a liké il y a 1 semaine',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedOnDate(String date) {
    return 'T’a liké le $date';
  }

  @override
  String discoverLikedProfilesTitle(int count) {
    return 'Profils likés ($count)';
  }

  @override
  String get discoverNoLikedProfiles => 'Aucun profil liké pour l’instant';

  @override
  String get discoverLikedProfileFallback => 'Profil liké';

  @override
  String get discoverPassedProfilesTitle => 'Profils passés';

  @override
  String get discoverNoPassedProfiles => 'Aucun profil passé pour l’instant';

  @override
  String get discoverSavedForLater => 'Gardé pour plus tard';

  @override
  String get discoverSpotlightFiltersTitle => 'Filtres à la une';

  @override
  String get discoverVerifiedOnly => 'Vérifiés uniquement';

  @override
  String discoverAgeRange(int min, int max) {
    return 'Tranche d’âge : $min - $max';
  }

  @override
  String get discoverSpotlightTitle => 'Matchs à la une';

  @override
  String get discoverSpotlightSubtitle =>
      'Des connexions premium sélectionnées';

  @override
  String discoverPassedCount(int count) {
    return 'Passés ($count)';
  }

  @override
  String get discoverOpenChatsFromDiscover =>
      'Ouvre tes discussions depuis Découvrir';

  @override
  String get discoverNoNewNotifications => 'Aucune nouvelle notification';

  @override
  String get discoverNoSpotlightMatchFilters =>
      'Aucun profil à la une ne correspond aux filtres';

  @override
  String get discoverAllSpotlightReviewed =>
      'Tous les profils à la une sont vus !';

  @override
  String get discoverSpotlightCheckBackLater =>
      'Reviens plus tard pour de nouveaux profils à la une';

  @override
  String get discoverReportSubmitted => 'Signalement envoyé.';

  @override
  String get discoverAppeal => 'Faire appel';

  @override
  String discoverAppealPrefill(String userId) {
    return 'Réexaminer la décision de modération pour le signalement de l’utilisateur $userId';
  }

  @override
  String get discoverProfileUnavailable =>
      'Ce profil est indisponible pour le moment.';

  @override
  String get discoverGoBack => 'Retour';

  @override
  String get discoverPremiumView => 'Vue premium';

  @override
  String get todayLabel => 'AUJOURD’HUI';

  @override
  String get todayRefreshTooltip => 'Actualiser Aujourd’hui';

  @override
  String get todayDiscoveryPreferences => 'Préférences de découverte';

  @override
  String get todayHeroTitle => 'Un petit bonjour.\nDe la place pour du vrai.';

  @override
  String get todayHeroSubtitle =>
      'Quelques présentations choisies avec soin, à ton rythme.';

  @override
  String get todaySectionPace => 'TON RYTHME';

  @override
  String get todayPaceTitle => 'Qu’est-ce qui convient à ta semaine ?';

  @override
  String get todayPaceBody =>
      'Ton rythme, ton genre de premier rendez-vous, tes disponibilités si tu veux.';

  @override
  String get todaySetRhythm => 'Définir ton rythme';

  @override
  String get todaySectionStory => 'TON HISTOIRE';

  @override
  String get todaySectionIntroductions => 'PRÉSENTATIONS DU JOUR';

  @override
  String get todayIntroductionsTitle => 'Quelques personnes à découvrir';

  @override
  String get todayIntroductionsCaption =>
      'Les centres d’intérêt communs sont un point de départ. L’alchimie, c’est à toi de la découvrir.';

  @override
  String get todayPausedTitle => 'Prends le temps qu’il te faut.';

  @override
  String get todayPausedBody =>
      'Les présentations sont en pause. Tes conversations sont toujours là.';

  @override
  String get todayManageRhythm => 'Gérer ton rythme';

  @override
  String get todayLoadingIntroductions => 'Chargement des présentations';

  @override
  String get todayFailedTitle => 'Tes présentations prennent un peu de temps.';

  @override
  String get todayFailedBody =>
      'Nous n’avons pas pu charger les dernières informations. Réessaie.';

  @override
  String get todayTryAgain => 'Réessayer';

  @override
  String get todayEmptyTitle => 'Un peu de répit.';

  @override
  String get todayEmptyBody =>
      'Il n’y a pas de nouvelles présentations pour tes préférences pour le moment. Tu peux ajuster ton rythme ou explorer des profils.';

  @override
  String get todayExploreProfiles => 'Explorer les profils';

  @override
  String get todayAllIntroductions => 'Toutes les présentations';

  @override
  String get todayBreatheTitle =>
      'Une belle connexion a besoin d’espace pour respirer.';

  @override
  String get todayBreatheBody =>
      'Voici les présentations du jour. Pas de compte à rebours, et pas besoin de te décider pour tout le monde.';

  @override
  String get todayExploreMore => 'Explorer d’autres profils';

  @override
  String get todayCommonGround => 'UN PEU DE TERRAIN COMMUN';

  @override
  String todayMeetName(String name) {
    return 'Découvrir $name';
  }

  @override
  String get todayFirstHelloCoffee =>
      'Un premier bonjour pourrait être un café ensemble.';

  @override
  String get todayFirstHelloWalk =>
      'Un premier bonjour pourrait être une balade en journée.';

  @override
  String get todayFirstHelloMeal =>
      'Un premier bonjour pourrait être un repas détendu.';

  @override
  String get todayFirstHelloVideoCall =>
      'Un premier bonjour pourrait être un appel vidéo.';

  @override
  String get todayFirstHelloEvent =>
      'Un premier bonjour pourrait être un événement que vous aimez tous les deux.';

  @override
  String get todayFirstHelloDrinks =>
      'Un premier bonjour pourrait être un verre ensemble.';

  @override
  String get todayFirstHelloOther =>
      'Un premier bonjour pourrait être quelque chose que vous aimez tous les deux.';

  @override
  String get todaySectionTalk => 'DE QUOI PARLER';

  @override
  String get todayTalkCaption =>
      'Des histoires, des clubs et des idées pour faciliter un premier bonjour.';

  @override
  String get todayBlogTitle => 'Blog · Chapitres ouverts';

  @override
  String get todayBlogSubtitle =>
      'Lis les histoires des membres et écris la tienne.';

  @override
  String get todayBookClubsTitle => 'Clubs de lecture';

  @override
  String get todayBookClubsSubtitle =>
      'Un livre par semaine, dont on parle ensemble.';

  @override
  String get todayFilmClubsTitle => 'Ciné-clubs';

  @override
  String get todayFilmClubsSubtitle =>
      'Regarde le film choisi, puis échangez vos avis.';

  @override
  String get todayPhotoThemesTitle => 'Thèmes photo';

  @override
  String get todayPhotoThemesSubtitle =>
      'Une photo par thème. Découvre celles de tout le monde.';

  @override
  String get todayChapterStudioTitle => 'Studio Premier chapitre';

  @override
  String get todayChapterStudioSubtitle => 'Commencez une histoire ensemble.';

  @override
  String get todayCoverFallbackLine => 'Une photo que les membres ont adorée';

  @override
  String todayCoverSemantics(String name) {
    return 'Ouvrir la couverture de la semaine de $name';
  }

  @override
  String get todayCoverTitle => 'COUVERTURE DE LA SEMAINE';

  @override
  String todayCoverBy(String name) {
    return 'PAR $name';
  }

  @override
  String get todayLikes => 'J’aime';

  @override
  String get todayComments => 'Commentaires';

  @override
  String get todayThisWeek => 'Cette semaine';

  @override
  String get todayWallLabel => 'DE LA COMMUNAUTÉ';

  @override
  String get todayWallTitle => 'Le mur du jour';

  @override
  String get todayWallCaption =>
      'Des histoires et des photos que les membres ont adorées — une nouvelle sélection chaque jour';

  @override
  String get todayWallPrevious => 'Sélection précédente';

  @override
  String get todayWallNext => 'Sélection suivante';

  @override
  String get todayWallChapter => 'CHAPITRE';

  @override
  String get todayWallUntitled => 'Un chapitre sans titre';

  @override
  String todayWallBy(String name) {
    return 'par $name';
  }

  @override
  String get todayWallEmpty =>
      'Ton mur se remplit à mesure que les membres partagent les histoires et les photos qu’ils aiment';

  @override
  String get todayWallWrite => 'Écrire un chapitre';

  @override
  String get todayWallShare => 'Partager une photo';

  @override
  String get profileSetupBackTooltip => 'Retour';

  @override
  String profileSetupStepCounter(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get profileSetupLoadErrorTitle =>
      'Impossible de charger les données du profil.';

  @override
  String get profileSetupRetry => 'Réessayer';

  @override
  String get profileSetupEducationHighSchool => 'Lycée';

  @override
  String get profileSetupEducationBachelors => 'Licence';

  @override
  String get profileSetupEducationMasters => 'Master';

  @override
  String get profileSetupEducationPhd => 'Doctorat';

  @override
  String get profileSetupEducationOther => 'Autre';

  @override
  String get profileSetupPreferNotToSay => 'Je préfère ne pas répondre';

  @override
  String profileSetupIncomeBelow(String amount) {
    return 'Moins de $amount';
  }

  @override
  String get profileSetupFrequencyNever => 'Jamais';

  @override
  String get profileSetupFrequencySocially => 'En soirée';

  @override
  String get profileSetupFrequencyOccasionally => 'Occasionnellement';

  @override
  String get profileSetupFrequencyRegularly => 'Régulièrement';

  @override
  String get profileSetupGenderMan => 'Homme';

  @override
  String get profileSetupGenderWoman => 'Femme';

  @override
  String get profileSetupGenderOther => 'Autre';

  @override
  String profileSetupBioTooShort(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'La bio doit contenir au moins $min caractères.',
      one: 'La bio doit contenir au moins 1 caractère.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupSaveFailed => 'Échec de l’enregistrement — réessaie.';

  @override
  String get profileSetupCouldNotSaveChanges =>
      'Impossible d’enregistrer tes modifications. Réessaie.';

  @override
  String get profileSetupAboutTitle => 'Fais briller ton profil';

  @override
  String get profileSetupAboutSubtitle =>
      'Ces infos aident à trouver de meilleurs matchs.';

  @override
  String get profileSetupBioLabel => 'Bio';

  @override
  String profileSetupBioHint(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Parle un peu de toi (min. $min caractères)',
      one: 'Parle un peu de toi (min. 1 caractère)',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupHeightLabel => 'Taille (cm)';

  @override
  String get profileSetupHeightHint => 'Choisis ta taille';

  @override
  String profileSetupHeightValue(int cm) {
    return '$cm cm';
  }

  @override
  String get profileSetupEducationLabel => 'Études';

  @override
  String get profileSetupEducationHint => 'Choisis ton niveau d’études';

  @override
  String get profileSetupProfessionLabel => 'Profession';

  @override
  String get profileSetupProfessionHint => 'ex. : ingénieur logiciel';

  @override
  String get profileSetupIncomeLabel => 'Revenus (facultatif)';

  @override
  String get profileSetupLifestyleTitle => 'Mode de vie';

  @override
  String get profileSetupDrinkingLabel => 'Alcool';

  @override
  String get profileSetupSmokingLabel => 'Tabac';

  @override
  String get profileSetupSelectHint => 'Choisir';

  @override
  String get profileSetupReligionOptionalLabel => 'Religion (facultatif)';

  @override
  String get profileSetupContinue => 'Continuer';

  @override
  String get profileSetupSaveAbout => 'Enregistrer « À propos »';

  @override
  String get profileSetupPhotosSaved => 'Photos enregistrées.';

  @override
  String profileSetupPhotosMaxReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Tu peux importer $max photos au maximum.',
      one: 'Tu ne peux importer qu’1 photo.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupRemovePhotoTitle => 'Supprimer cette photo ?';

  @override
  String get profileSetupRemovePhotoBody =>
      'Elle sera retirée de ton profil et supprimée du stockage.';

  @override
  String get profileSetupCancel => 'Annuler';

  @override
  String get profileSetupRemove => 'Supprimer';

  @override
  String profileSetupPhotosMinRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Importe au moins $min photos pour continuer.',
      one: 'Importe au moins 1 photo pour continuer.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTitle => 'Ajoute tes photos';

  @override
  String profileSetupPhotosSubtitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Ajoute au moins $min photos pour obtenir des matchs',
      one: 'Ajoute au moins 1 photo pour obtenir des matchs',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupChooseSource => 'Choisis la source';

  @override
  String get profileSetupGallery => 'Galerie';

  @override
  String get profileSetupCamera => 'Appareil photo';

  @override
  String get profileSetupPhotoRequirements =>
      'JPEG, PNG, WebP ou HEIC · 300×300 minimum · 10 Mo chacune · 50 Mo au total';

  @override
  String profileSetupPhotosTipEmpty(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other:
          'Ajoute au moins $min photos pour montrer différentes facettes de toi.',
      one: 'Ajoute au moins 1 photo pour montrer différentes facettes de toi.',
    );
    return '$_temp0';
  }

  @override
  String profileSetupPhotosTipMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajoute encore $count photos pour débloquer tous les matchs.',
      one: 'Ajoute encore 1 photo pour débloquer tous les matchs.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTipDone =>
      'Super ! Tu peux réorganiser tes photos en les faisant glisser.';

  @override
  String get profileSetupYourPhotosHeading =>
      'Tes photos  •  fais glisser pour réorganiser';

  @override
  String get profileSetupContinueToAbout => 'Continuer vers « À propos »';

  @override
  String get profileSetupSavePhotos => 'Enregistrer les photos';

  @override
  String get profileSetupPrimaryPhoto => 'Photo principale';

  @override
  String profileSetupPhotoNumber(int number) {
    return 'Photo $number';
  }

  @override
  String get profileSetupShownFirst => 'Affichée en premier sur ton profil';

  @override
  String get profileSetupDragHandleHint =>
      'Fais glisser la poignée pour réorganiser';

  @override
  String get profileSetupAwaitingSafetyReview => 'En attente de vérification';

  @override
  String get profileSetupSafetyCheckInProgress =>
      'Vérification de sécurité en cours';

  @override
  String get profileSetupSetAsProfilePicture => 'Définir comme photo de profil';

  @override
  String get profileSetupProfilePictureSelected =>
      'Photo de profil sélectionnée';

  @override
  String get profileSetupRemovePhotoTooltip => 'Supprimer la photo';

  @override
  String get profileSetupPhotoTooLarge =>
      'Cette photo dépasse la limite de 10 Mo.';

  @override
  String get profileSetupPhotoUnsupportedType =>
      'Utilise une photo JPEG, PNG, WebP ou HEIC.';

  @override
  String get profileSetupPhotoBadDimensions =>
      'Les dimensions de la photo doivent être comprises entre 300×300 et 4096×4096.';

  @override
  String get profileSetupPhotoQuotaReached =>
      'Tu as atteint ton quota de photos de profil.';

  @override
  String get profileSetupPhotoStorageFull =>
      'Le stockage des photos est temporairement plein. Réessaie plus tard.';

  @override
  String get profileSetupPhotoUpdateFailed =>
      'La mise à jour de la photo a échoué. Réessaie.';

  @override
  String profileSetupPhotoMaxAllowed(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$max photos maximum autorisées.',
      one: '1 photo maximum autorisée.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPreferencesLoadFailed =>
      'Impossible de charger les préférences';

  @override
  String get profileSetupOfflineBanner =>
      'Mode hors ligne — certaines données peuvent être obsolètes.';

  @override
  String get profileSetupYourPreferences => 'Tes préférences';

  @override
  String get profileSetupEditPreferencesTitle => 'Modifier les préférences';

  @override
  String get profileSetupFinishAndFindMatches =>
      'Terminer et trouver des matchs';

  @override
  String get profileSetupSavePreferences => 'Enregistrer les préférences';

  @override
  String get profileSetupSelectGenderPreference => 'Choisis au moins un genre.';

  @override
  String get profileSetupFinishFailed =>
      'Impossible de terminer la configuration. Vérifie tes photos et tes préférences, puis réessaie.';

  @override
  String get profileSetupPreferencesSaveFailed =>
      'Certaines préférences n’ont pas pu être enregistrées pour le moment.';

  @override
  String get profileSetupPreferencesSaved => 'Préférences enregistrées.';

  @override
  String get profileSetupTabBasic => 'Essentiel';

  @override
  String get profileSetupTabAdvanced => 'Avancé';

  @override
  String get profileSetupLookingFor => 'Je recherche';

  @override
  String get profileSetupSeekingMen => 'Hommes';

  @override
  String get profileSetupSeekingWomen => 'Femmes';

  @override
  String get profileSetupSeekingOther => 'Autre';

  @override
  String profileSetupAgeRangeTitle(int min, int max) {
    return 'Tranche d’âge : $min – $max';
  }

  @override
  String profileSetupMaxDistanceTitle(int km) {
    return 'Distance max. : $km km';
  }

  @override
  String profileSetupDistanceValue(int km) {
    return '$km km';
  }

  @override
  String get profileSetupRelationshipIntent => 'Type de relation';

  @override
  String get profileSetupSeriousOnly => 'Relation sérieuse uniquement';

  @override
  String get profileSetupSeriousOnlySubtitle =>
      'Afficher uniquement les personnes qui cherchent à s’engager';

  @override
  String get profileSetupVerifiedOnly => 'Profils vérifiés uniquement';

  @override
  String get profileSetupVerifiedOnlySubtitle =>
      'Uniquement les comptes avec pièce d’identité vérifiée';

  @override
  String get profileSetupHookupsOnly => 'Rencontres d’un soir uniquement';

  @override
  String get profileSetupHookupsOnlySubtitle =>
      'Afficher uniquement les profils sans engagement';

  @override
  String get profileSetupLocation => 'Lieu';

  @override
  String get profileSetupCountry => 'Pays';

  @override
  String get profileSetupStateRegion => 'État / Région';

  @override
  String get profileSetupCity => 'Ville';

  @override
  String get profileSetupBackgroundCulture => 'Origines et culture';

  @override
  String get profileSetupReligionPreference => 'Religion';

  @override
  String get profileSetupMotherTongue => 'Langue maternelle';

  @override
  String get profileSetupLanguage => 'Langue';

  @override
  String get profileSetupDietPreference => 'Alimentation';

  @override
  String get profileSetupWorkoutFrequency => 'Fréquence de sport';

  @override
  String get profileSetupDietType => 'Régime';

  @override
  String get profileSetupSleepSchedule => 'Rythme de sommeil';

  @override
  String get profileSetupTravelStyle => 'Style de voyage';

  @override
  String get profileSetupPoliticalComfortRange => 'Ouverture politique';

  @override
  String get profileSetupInterestsPersonality =>
      'Centres d’intérêt et personnalité';

  @override
  String get profileSetupInstagramHandle => 'Pseudo Instagram (sans @)';

  @override
  String get profileSetupIntentTags =>
      'Intentions (long terme, mariage, sans engagement…)';

  @override
  String get profileSetupHobbiesField => 'Loisirs (séparés par des virgules)';

  @override
  String get profileSetupFavouriteBooksField =>
      'Livres préférés (séparés par des virgules)';

  @override
  String get profileSetupFavouriteNovelsField =>
      'Romans préférés (séparés par des virgules)';

  @override
  String get profileSetupFavouriteSongsField =>
      'Chansons préférées (séparées par des virgules)';

  @override
  String get profileSetupExtraCurricularField =>
      'Activités extrascolaires (séparées par des virgules)';

  @override
  String get profileSetupAdditionalInformation =>
      'Informations complémentaires';

  @override
  String get profileSetupPetPreference => 'Animaux de compagnie';

  @override
  String get profileSetupDealBreakers => 'Points non négociables';

  @override
  String get profileSetupTagsField => 'Tags (séparés par des virgules)';

  @override
  String get profileSetupNameRequired => 'Le prénom est obligatoire.';

  @override
  String get profileSetupDobRequired => 'La date de naissance est obligatoire.';

  @override
  String profileSetupPhotosRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Au moins $min photos sont requises.',
      one: 'Au moins 1 photo est requise.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupServerError => 'Erreur du serveur';

  @override
  String get profileSetupNetworkError => 'Erreur réseau — réessaie.';

  @override
  String get profileSetupGenericError => 'Un problème est survenu. Réessaie.';

  @override
  String get profileSetupPreviewTitle => 'Aperçu de ton profil';

  @override
  String get profileSetupPreviewSubtitle =>
      'Voici comment les autres te verront.';

  @override
  String profileSetupNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String profileSetupDrinksChip(String value) {
    return 'Alcool : $value';
  }

  @override
  String profileSetupSmokesChip(String value) {
    return 'Tabac : $value';
  }

  @override
  String get profileSetupCompleteProfile => 'Terminer le profil';

  @override
  String profileSetupCompletionPercent(int percent) {
    return 'Profil complété : $percent %';
  }

  @override
  String get profileEditTitle => 'Modifier le profil';

  @override
  String get profileEditRefreshTooltip => 'Actualiser le profil';

  @override
  String get profileEditAboutYou => 'À propos de toi';

  @override
  String get profileEditEditAbout => 'Modifier « À propos »';

  @override
  String get profileEditName => 'Prénom';

  @override
  String get profileEditPhone => 'Téléphone';

  @override
  String get profileEditDateOfBirth => 'Date de naissance';

  @override
  String get profileEditGender => 'Genre';

  @override
  String get profileEditHeight => 'Taille';

  @override
  String get profileEditIncomeRange => 'Tranche de revenus';

  @override
  String get profileEditLocationSocial => 'Lieu et réseaux';

  @override
  String get profileEditEditPreferences => 'Modifier les préférences';

  @override
  String get profileEditState => 'État / Région';

  @override
  String get profileEditInstagram => 'Instagram';

  @override
  String get profileEditDatingPreferences => 'Préférences de rencontre';

  @override
  String get profileEditSeeking => 'Recherche';

  @override
  String get profileEditAgeRange => 'Tranche d’âge';

  @override
  String profileEditAgeRangeValue(int min, int max) {
    return '$min–$max';
  }

  @override
  String get profileEditMaxDistance => 'Distance max.';

  @override
  String get profileEditEducationFilter => 'Filtre d’études';

  @override
  String get profileEditSeriousOnly => 'Sérieux uniquement';

  @override
  String get profileEditVerifiedOnly => 'Vérifiés uniquement';

  @override
  String get profileEditHookupOnly => 'Rencontre d’un soir';

  @override
  String get profileEditYes => 'Oui';

  @override
  String get profileEditNo => 'Non';

  @override
  String get profileEditIntent => 'Intention';

  @override
  String get profileEditLanguages => 'Langues';

  @override
  String get profileEditDealBreakers => 'Points non négociables';

  @override
  String get profileEditReligion => 'Religion';

  @override
  String get profileEditPets => 'Animaux';

  @override
  String get profileEditWorkout => 'Sport';

  @override
  String get profileEditPoliticsComfort => 'Ouverture politique';

  @override
  String get profileEditInterestsDetails => 'Centres d’intérêt et détails';

  @override
  String get profileEditHobbies => 'Loisirs';

  @override
  String get profileEditBooks => 'Livres';

  @override
  String get profileEditNovels => 'Romans';

  @override
  String get profileEditSongs => 'Chansons';

  @override
  String get profileEditExtraCurriculars => 'Activités extrascolaires';

  @override
  String get profileEditAdditionalInfo => 'Infos complémentaires';

  @override
  String get profileEditNotSet => 'Non renseigné';

  @override
  String get profileEditLoadingTitle => 'Chargement de ton profil enregistré';

  @override
  String get profileEditLoadingBody =>
      'Récupération des informations enregistrées lors de la création du compte.';

  @override
  String get profileEditYourProfile => 'Ton profil';

  @override
  String profileEditPercentComplete(int percent) {
    return '$percent % complété';
  }

  @override
  String get profileEditPhotoGallery => 'Galerie photos';

  @override
  String get profileEditManagePhotos => 'Gérer les photos';

  @override
  String get profileEditNoPhotos => 'Aucune photo importée pour l’instant.';

  @override
  String get profileEditPrimaryBadge => 'Principale';

  @override
  String get engagementHubPromptLoading => 'Chargement de la question du jour';

  @override
  String get engagementHubPromptIntro =>
      'Réponds à une question par jour et construis ta série.';

  @override
  String engagementHubPromptRepliedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes ont répondu aujourd’hui',
      one: '1 personne a répondu aujourd’hui',
    );
    return '$_temp0';
  }

  @override
  String engagementHubPromptStreakSummary(int days, int similar) {
    return 'Série $days j · réponses similaires : $similar';
  }

  @override
  String get engagementHubBlogTitle => 'Blog · Open Chapters';

  @override
  String get engagementHubBlogSubtitle =>
      'Lis des histoires, partage des photos et écris la tienne.';

  @override
  String get engagementHubPhotoThemesTitle => 'Thèmes photo';

  @override
  String get engagementHubPhotoThemesSubtitle =>
      'Partage une photo par thème et découvre celles des autres.';

  @override
  String get engagementHubClubsTitle => 'Clubs lecture & ciné';

  @override
  String get engagementHubClubsSubtitle =>
      'Suis la sélection de la semaine, discutes-en, note-la.';

  @override
  String get engagementHubCityPilotTitle => 'Le pilote en ville';

  @override
  String get engagementHubCityPilotSubtitle =>
      'Une petite communauté. Des conversations qui deviennent des projets.';

  @override
  String get engagementDailyPromptTitle => 'Série de questions du jour';

  @override
  String get engagementHubVoiceTitle => 'Brise-glace vocaux guidés';

  @override
  String get engagementHubVoiceSubtitle =>
      'Une intro vocale guidée de 20 à 45 s par match et par jour';

  @override
  String get engagementCirclesTitle => 'Défis des cercles locaux';

  @override
  String get engagementHubCirclesSubtitle =>
      'Rejoins un cercle de ta ville et envoie ta participation de la semaine';

  @override
  String get engagementHubCoffeeTitle => 'Sondage café en groupe';

  @override
  String get engagementHubCoffeeSubtitle =>
      'Crée, vote et valide de petits sondages de rendez-vous';

  @override
  String get engagementHubGroupsTitle => 'Groupes';

  @override
  String get engagementHubGroupsSubtitle =>
      'Communautés art de vivre et groupes d’amis privés';

  @override
  String get engagementHubRoomsSubtitle =>
      'Salons de discussion en direct : passe, discute, fais-toi des amis';

  @override
  String get engagementHubFriendsTitle => 'Amis & présentations';

  @override
  String get engagementHubFriendsSubtitle =>
      'Invite un ami de confiance, même s’il ne cherche personne';

  @override
  String get engagementLevelTitle => 'Niveau & XP';

  @override
  String get engagementHubLevelSubtitle =>
      'Suis ton activité utile, tes récompenses de niveau et les paliers de confiance';

  @override
  String get engagementHubPaywallFree =>
      'La progression de base reste sans paywall.';

  @override
  String get engagementHubPolicyUpdating =>
      'La politique de monétisation est en cours de mise à jour.';

  @override
  String engagementHubPremiumAreas(String features) {
    return 'Espaces premium facultatifs : $features';
  }

  @override
  String get engagementHubEyebrow => 'PARTICIPER';

  @override
  String get engagementHubTitle => 'Créer quelque chose ensemble.';

  @override
  String get engagementHubSubtitle =>
      'Des matchs plus solides grâce à la confiance et aux activités partagées.';

  @override
  String get engagementHubSectionCreate => 'CRÉER & PARTAGER';

  @override
  String get engagementHubSectionCreateCaption =>
      'Des histoires, des photos et des clubs qui lancent de vraies conversations.';

  @override
  String get engagementHubSectionMeet => 'RENCONTRER DU MONDE';

  @override
  String get engagementHubSectionMeetCaption =>
      'Petits groupes, questions et projets, à ton rythme.';

  @override
  String get engagementHubSectionProgress => 'CONFIANCE & PROGRÈS';

  @override
  String get engagementHubSectionProgressCaption =>
      'Ton niveau, tes badges et qui peut te trouver.';

  @override
  String get engagementVoiceAppBarTitle => 'Une voix, un peu plus près';

  @override
  String get engagementVoiceHeadline => 'Que ton bonjour\nte ressemble.';

  @override
  String get engagementVoiceIntro =>
      'Une présentation facultative de 20 à 45 secondes, partagée uniquement dans cette conversation. Le texte est toujours le bienvenu aussi.';

  @override
  String engagementVoiceYouAndName(String name) {
    return 'Toi et $name';
  }

  @override
  String get engagementVoiceYouAndYourMatch => 'Toi et ton match';

  @override
  String get engagementVoicePrivate =>
      'Visible uniquement dans cette conversation';

  @override
  String get engagementVoiceConversationsLoadFailed =>
      'Impossible de charger tes conversations.';

  @override
  String get engagementVoiceNoMatches =>
      'Quand tu auras un match, tu pourras partager une présentation vocale ici. Rien ne presse.';

  @override
  String get engagementVoicePickConversation => 'À qui veux-tu dire bonjour ?';

  @override
  String get engagementVoiceStartingPoint => 'Un petit point de départ';

  @override
  String get engagementVoiceChoosePrompt => 'Choisis une question';

  @override
  String get engagementVoiceTranscriptLabel => 'Tes mots, par écrit';

  @override
  String get engagementVoiceTranscriptHelper =>
      'Écris ce que tu dis pour que l’autre puisse aussi le lire. Ce n’est pas une transcription automatique.';

  @override
  String engagementVoiceStop(int seconds) {
    return 'Arrêter · $seconds s';
  }

  @override
  String get engagementVoiceRecord => 'Enregistre ton bonjour';

  @override
  String engagementVoiceRecordAgain(int seconds) {
    return 'Réenregistrer · $seconds s';
  }

  @override
  String get engagementVoiceRecordingReady =>
      'Enregistrement prêt. Vérifie ton texte avant l’envoi.';

  @override
  String get engagementVoiceRecordingShort =>
      'C’était un peu court. Enregistre entre 20 et 45 secondes.';

  @override
  String get engagementVoiceDiscard => 'Supprimer l’enregistrement';

  @override
  String get engagementVoiceSubmitted =>
      'Présentation envoyée. Les enregistrements approuvés s’affichent ci-dessous.';

  @override
  String get engagementVoiceSending => 'Envoi…';

  @override
  String get engagementVoiceShare => 'Partager ton bonjour';

  @override
  String get engagementVoiceCheckedNote =>
      'Les enregistrements sont vérifiés avant d’être partagés. Il n’y a pas de lecture automatique.';

  @override
  String get engagementVoiceYourIntros => 'Vos présentations vocales';

  @override
  String get engagementVoiceLatestNote =>
      'Les 20 derniers enregistrements approuvés de cette conversation. Les textes sont toujours lisibles.';

  @override
  String get engagementVoiceIntrosLoadFailed =>
      'Impossible de charger les présentations. La conversation n’est peut-être plus disponible.';

  @override
  String get engagementVoiceNothingYet =>
      'Rien de partagé pour l’instant. Un simple bonjour, c’est un bon début.';

  @override
  String get engagementVoiceYourHello => 'Ton bonjour';

  @override
  String engagementVoiceHelloFromName(String name) {
    return 'Un bonjour de $name';
  }

  @override
  String get engagementVoiceHelloFromYourMatch => 'Un bonjour de ton match';

  @override
  String get engagementVoiceTranscriptHeading => 'TEXTE';

  @override
  String get engagementVoiceStopPlayback => 'Arrêter la lecture';

  @override
  String engagementVoiceListen(int seconds) {
    return 'Écouter · $seconds s';
  }

  @override
  String get engagementVoiceReloadPrompts => 'Recharger les questions';

  @override
  String get engagementVoiceMicPermission =>
      'Autorise l’accès au micro pour enregistrer. Tu peux quand même lire les textes sans.';

  @override
  String get engagementVoiceStartFailed =>
      'Impossible de lancer l’enregistrement. Vérifie l’accès au micro et réessaie.';

  @override
  String get engagementVoiceSaveFailed =>
      'Impossible d’enregistrer le fichier audio. Réessaie.';

  @override
  String get engagementVoicePromptsLoadFailed =>
      'Impossible de charger les questions vocales pour le moment.';

  @override
  String get engagementSessionUnavailable => 'Session indisponible.';

  @override
  String get engagementVoiceChooseConversation =>
      'Choisis d’abord une conversation.';

  @override
  String get engagementVoiceSelectPrompt => 'Choisis une question vocale.';

  @override
  String get engagementVoiceEnterTranscript => 'Saisis le texte.';

  @override
  String get engagementVoiceSessionFailed =>
      'Impossible de créer la session de brise-glace vocal.';

  @override
  String get engagementVoiceSendFailed =>
      'Impossible d’envoyer le brise-glace vocal pour le moment.';

  @override
  String get engagementVoicePlaybackUserRequired =>
      'Un identifiant utilisateur est requis pour enregistrer la lecture.';

  @override
  String get engagementVoiceMarkPlaybackFailed =>
      'Impossible d’enregistrer la lecture pour le moment.';

  @override
  String get engagementVoicePlayFailed =>
      'Impossible de lire cet enregistrement pour le moment.';

  @override
  String get chatStarterSmile => 'Qu’est-ce qui t’a fait sourire aujourd’hui ?';

  @override
  String get chatStarterSunday => 'Ton dimanche idéal : raconte.';

  @override
  String get chatStarterCoffee =>
      'Un café, une balade ou une petite aventure ?';

  @override
  String get chatWelcomeTitle =>
      'Toute belle histoire\ncommence par un bonjour.';

  @override
  String get chatWelcomePending =>
      'La conversation s’ouvrira quand le match sera confirmé.';

  @override
  String get chatWelcomeBody =>
      'Pas besoin de la phrase d’accroche parfaite. Sois toi-même.';

  @override
  String get chatInspirationEyebrow => 'UN PEU D’INSPIRATION';

  @override
  String get chatAllConversations => 'Toutes les conversations';

  @override
  String get chatMakeConnectionEyebrow => 'CRÉER UN LIEN';

  @override
  String get chatLessSmallTalk => 'Un peu moins de banalités.';

  @override
  String get chatLessSmallTalkBody =>
      'Interroge l’autre sur ce qui le fait vibrer. Partage quelque chose qui te ressemble.';

  @override
  String get chatFindTheWords => 'Trouver les mots';

  @override
  String get chatSendJoy => 'Envoyer un peu de joie';

  @override
  String get chatPaceTitle => 'Ton rythme. Ton espace.';

  @override
  String get chatPaceBody =>
      'Ne partage que ce qui te met à l’aise. Une belle relation respecte tes limites.';

  @override
  String get chatWriteMessageHint => 'Écris un message…';

  @override
  String get chatConversationPaused => 'Conversation en pause';

  @override
  String get chatSendingMessageTooltip => 'Envoi du message';

  @override
  String get chatSendMessageTooltip => 'Envoyer le message';

  @override
  String get chatSendGiftTooltip => 'Envoyer un cadeau';

  @override
  String get chatAddEmojiTooltip => 'Ajouter un émoji';

  @override
  String get chatDraftedWithHelp => 'Rédigé avec de l’aide';

  @override
  String get chatHelpMeSayIt => 'Aide-moi à le dire';

  @override
  String get chatEnterToSendHint =>
      'Entrée pour envoyer · Maj + Entrée pour aller à la ligne';

  @override
  String get chatToday => 'Aujourd’hui';

  @override
  String get chatYesterday => 'Hier';

  @override
  String get chatGiftOptions => 'Options du cadeau';

  @override
  String get chatStatusRead => 'Lu';

  @override
  String get chatStatusDelivered => 'Distribué';

  @override
  String get chatStatusSent => 'Envoyé';

  @override
  String get chatGestureGiftHeading => 'Geste + rose offerte';

  @override
  String get chatGiftForYouHeading => 'Une petite attention pour toi';

  @override
  String chatGiftTone(String tone) {
    return 'Ton : $tone';
  }

  @override
  String get chatFreeGift => 'Cadeau gratuit';

  @override
  String get chatCopilotKindOpener => 'Premier message';

  @override
  String get chatCopilotKindReply => 'Réponse';

  @override
  String get chatCopilotKindDateIdea => 'Idée de rendez-vous';

  @override
  String get chatCopilotToneWarm => 'Chaleureux';

  @override
  String get chatCopilotTonePlayful => 'Espiègle';

  @override
  String get chatCopilotToneDirect => 'Direct';

  @override
  String chatCopilotIntro(String name) {
    return 'Un brouillon à ta façon, inspiré du profil de $name et de votre conversation. Il n’est jamais envoyé à ta place, et si tu l’envoies tel quel, l’autre personne verra qu’il a été rédigé avec de l’aide.';
  }

  @override
  String chatCopilotDisclosure(String disclosure, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore $count brouillons aujourd’hui.',
      one: 'Encore 1 brouillon aujourd’hui.',
    );
    return '$disclosure $_temp0';
  }

  @override
  String get chatCopilotDraftIt => 'Rédiger';

  @override
  String get chatCopilotTryAnother => 'Un autre';

  @override
  String get chatCopilotUseAndEdit => 'Utiliser et modifier';

  @override
  String get chatCopilotEmpty => 'Le copilote n’a rien proposé.';

  @override
  String get chatCopilotUnavailable => 'Le copilote est indisponible.';

  @override
  String get chatErrorMatchEnded => 'Ce match est terminé.';

  @override
  String get chatErrorLoadMessages =>
      'Impossible de charger les messages. Réessaie.';

  @override
  String get chatErrorLockedQuest =>
      'La discussion est verrouillée jusqu’à la validation de la quête.';

  @override
  String get chatErrorSendFailed => 'Impossible d’envoyer le message.';

  @override
  String get chatErrorDeleteFailed => 'Impossible de supprimer le message.';

  @override
  String get chatErrorDeleteWindowExpired =>
      'Délai de suppression dépassé (24 h).';

  @override
  String get chatErrorOnlyReceivedGifts =>
      'Seuls les cadeaux reçus peuvent être gérés.';

  @override
  String get chatErrorGiftGone => 'Ce cadeau n’est plus disponible.';

  @override
  String get chatErrorGiftReportFailed =>
      'Impossible de signaler ce cadeau. Réessaie.';

  @override
  String get chatErrorGiftHideFailed =>
      'Impossible de masquer ce cadeau. Réessaie.';

  @override
  String get chatErrorGiftsUnavailable =>
      'Les roses à offrir sont indisponibles pour le moment.';

  @override
  String chatErrorNotEnoughCoins(String gift) {
    return 'Pas assez de pièces pour envoyer $gift.';
  }

  @override
  String get chatErrorNotEnoughCoinsSelected =>
      'Pas assez de pièces pour envoyer le cadeau choisi.';

  @override
  String get chatErrorWalletFrozen =>
      'Tes pièces sont bloquées pendant que nous examinons un achat remboursé. Les cadeaux gratuits restent disponibles.';

  @override
  String get chatErrorGiftVelocity =>
      'Tu as envoyé beaucoup de cadeaux en peu de temps. Réessaie plus tard.';

  @override
  String get chatErrorFreeGiftUsed =>
      'Tu as déjà envoyé ton cadeau gratuit du jour. Un nouveau sera disponible après minuit UTC.';

  @override
  String chatErrorGiftNotAvailable(String gift) {
    return '$gift n’est pas disponible pour le moment.';
  }

  @override
  String get chatErrorGiftNeedsActiveMatch =>
      'Les cadeaux ne peuvent être envoyés que dans un match actif.';

  @override
  String get chatErrorExclusiveGiftOnce =>
      'Ce cadeau exclusif ne peut être envoyé qu’une fois par jour.';

  @override
  String get chatErrorGiftFailed => 'Impossible d’envoyer le cadeau.';

  @override
  String get chatErrorSessionUnavailable => 'Session utilisateur indisponible.';

  @override
  String get chatErrorConversationUnavailable => 'Conversation indisponible.';

  @override
  String get verificationLandingTitle => 'Vérifie-toi en toute confiance';

  @override
  String get verificationLandingBody =>
      'Importe une pièce d\'identité officielle bien lisible et un selfie récent. Les fichiers sont transmis de façon chiffrée et stockés dans un espace de preuves privé.';

  @override
  String get verificationLandingDisclaimer =>
      'Une vérification ajoute du contexte à ton profil. Elle ne garantit jamais l\'identité, les intentions ou la sécurité d\'une autre personne.';

  @override
  String get verificationViewVerifiedStatus => 'Voir le statut vérifié';

  @override
  String get verificationViewReviewStatus => 'Voir l\'état de la vérification';

  @override
  String get verificationStartButton => 'Commencer la vérification sécurisée';

  @override
  String get verificationUploadIdTitle => 'Importer une pièce d\'identité';

  @override
  String get verificationUploadIdInstruction =>
      'Prends ou importe une photo nette de ta pièce d\'identité officielle.';

  @override
  String get verificationGallery => 'Galerie';

  @override
  String get verificationCamera => 'Appareil photo';

  @override
  String get verificationNext => 'Suivant';

  @override
  String get verificationSelfieTitle => 'Selfie';

  @override
  String get verificationSelfieInstruction => 'Prends un selfie net.';

  @override
  String get verificationUploadFailed =>
      'Impossible d\'importer tes justificatifs. Vérifie les fichiers et réessaie.';

  @override
  String get verificationSubmit => 'Envoyer';

  @override
  String get verificationStatusTitle => 'Statut de vérification';

  @override
  String get verificationRetry => 'Réessayer';

  @override
  String get verificationStatusVerified => 'Vérifié';

  @override
  String get verificationStatusVerifiedMessage =>
      'Ta vérification est terminée.';

  @override
  String get verificationStatusRejected => 'Refusé';

  @override
  String get verificationStatusRejectedFallback => 'Réessaie.';

  @override
  String get verificationStatusPending => 'En attente';

  @override
  String get verificationStatusPendingMessage => 'Vérification en cours.';

  @override
  String get verificationStatusNotStarted => 'Non commencée';

  @override
  String get verificationStatusNotStartedMessage =>
      'Lance la vérification depuis les Paramètres.';

  @override
  String get safetySosTitle => 'SOS urgence';

  @override
  String get safetySosDefaultMessage =>
      'J\'ai besoin d\'aide immédiatement. Merci de vérifier que je vais bien.';

  @override
  String get safetySosHeadline => 'Déclencher une alerte d\'urgence';

  @override
  String get safetySosIntro =>
      'Si tu es en danger immédiat, contacte d\'abord les services d\'urgence locaux. Cette alerte est enregistrée pour l\'équipe sécurité.';

  @override
  String get safetySosLevelUrgent => 'Urgent';

  @override
  String get safetySosLevelCritical => 'Critique';

  @override
  String get safetySosMessageLabel => 'Message pour l\'équipe sécurité';

  @override
  String get safetySosActivating => 'Déclenchement…';

  @override
  String get safetySosActivate => 'Déclencher le SOS';

  @override
  String get safetySosLocationNote =>
      'La position n\'est demandée que pour cette alerte. Tu peux continuer si tu refuses l\'autorisation.';

  @override
  String get safetySosHistoryTitle => 'Historique des alertes';

  @override
  String get safetySosHistoryEmpty => 'Aucune alerte SOS enregistrée.';

  @override
  String safetySosHistoryHeading(String level, String status) {
    return '$level · $status';
  }

  @override
  String get safetySosAlertLevelLow => 'FAIBLE';

  @override
  String get safetySosAlertLevelMedium => 'MOYEN';

  @override
  String get safetySosAlertLevelHigh => 'ÉLEVÉ';

  @override
  String get safetySosAlertLevelCritical => 'CRITIQUE';

  @override
  String get safetySosAlertStatusOpen => 'ouverte';

  @override
  String get safetySosAlertStatusActive => 'active';

  @override
  String get safetySosAlertStatusAcknowledged => 'prise en compte';

  @override
  String get safetySosAlertStatusResolved => 'résolue';

  @override
  String safetySosHistoryMetaWithLocation(String date) {
    return '$date · position incluse';
  }

  @override
  String safetySosHistoryMetaNoLocation(String date) {
    return '$date · sans position';
  }

  @override
  String safetySosResolution(String note) {
    return 'Résolution : $note';
  }

  @override
  String get safetySosConfirmTitle => 'Déclencher le SOS maintenant ?';

  @override
  String get safetySosConfirmBody =>
      'Cela crée une alerte d\'urgence pour l\'équipe sécurité et tente d\'y joindre ta position actuelle.';

  @override
  String get safetySosCancel => 'Annuler';

  @override
  String get safetySosConfirmActivate => 'Déclencher';

  @override
  String get safetySosActivatedTitle => 'Alerte SOS déclenchée';

  @override
  String get safetySosActivatedWithLocation =>
      'Ton alerte et ta position actuelle ont été enregistrées.';

  @override
  String get safetySosActivatedWithoutLocation =>
      'Ton alerte a été enregistrée sans position. L\'autorisation de localisation était indisponible ou refusée.';

  @override
  String get safetySosDone => 'OK';

  @override
  String get safetySosSignInToView =>
      'Connecte-toi pour voir l\'historique SOS.';

  @override
  String get safetySosLoadFailed => 'Impossible de charger l\'historique SOS.';

  @override
  String get safetySosSignInToActivate =>
      'Connecte-toi avant de déclencher le SOS.';

  @override
  String get safetySosActivateFailed => 'Impossible de déclencher le SOS.';

  @override
  String get photoThemesTitle => 'Thèmes photo';

  @override
  String get photoThemesSignIn => 'Connecte-toi pour voir les thèmes photo.';

  @override
  String get photoThemesHeroTitle => 'Montre un peu de ton univers';

  @override
  String get photoThemesHeroSubtitle =>
      'Choisis un thème, partage une photo et découvre ce que les autres ont répondu. C\'est une façon simple de lancer la conversation.';

  @override
  String get photoThemesLoadFailed => 'Impossible de charger les thèmes';

  @override
  String get photoThemesCheckConnection => 'Vérifie ta connexion.';

  @override
  String get photoThemesLookAround => 'Tu peux jeter un œil';

  @override
  String get photoThemesEligibilityShareOwn =>
      'Complète ton profil avec deux photos approuvées pour partager les tiennes.';

  @override
  String get photoThemesNewPromptsTitle => 'De nouveaux thèmes arrivent';

  @override
  String get photoThemesNewPromptsBody =>
      'Reviens bientôt pour avoir quelque chose à partager.';

  @override
  String photoThemesSharedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partagées',
      one: '$count partagée',
    );
    return '$_temp0';
  }

  @override
  String get photoThemesYouShared => 'Tu as partagé ✓';

  @override
  String get photoThemesBeFirst => 'Sois le premier à partager →';

  @override
  String get photoThemesSeeEveryone => 'Voir les photos de tout le monde →';

  @override
  String get photoThemesSharedSnack => 'Ta photo est partagée. Bien joué !';

  @override
  String get photoThemesShareFailed =>
      'Ta photo n\'a pas pu être partagée. Utilise un JPEG ou un PNG de 10 Mo maximum.';

  @override
  String get photoThemesEligibilityShare =>
      'Complète ton profil avec deux photos approuvées pour partager.';

  @override
  String get photoThemesAlreadyShared =>
      'Tu as déjà partagé pour ce thème. Retire ta photo pour en partager une nouvelle.';

  @override
  String get photoThemesThemeFallback => 'Thème photo';

  @override
  String get photoThemesShareTooltip => 'Partager une photo pour ce thème';

  @override
  String get photoThemesShareYourPhoto => 'Partager ta photo';

  @override
  String get photoThemesNoPhotosYet => 'Pas encore de photos';

  @override
  String photoThemesBeFirstFor(String title) {
    return 'Sois le premier à partager pour « $title »';
  }

  @override
  String get photoThemesLoadingPrompt => 'Chargement du thème…';

  @override
  String get photoThemesPhotosLoadFailed => 'Impossible de charger les photos';

  @override
  String get photoThemesEmptyMessage =>
      'Ta photo pourrait bien être celle qui fait parler tout le monde.';

  @override
  String get photoThemesMoreFailed =>
      'Impossible de charger plus de photos. Recharger';

  @override
  String get photoThemesLoadMore => 'Charger plus';

  @override
  String get photoThemesPhotoUnavailable => 'Photo indisponible. Réessayer';

  @override
  String photoThemesOpenPhoto(String name) {
    return 'Ouvrir la photo de $name';
  }

  @override
  String get photoThemesYou => 'Toi';

  @override
  String get photoThemesWallHelp =>
      'Si les membres l\'adorent, ta photo peut apparaître sur leurs murs Today : 50 j\'aime et 5 commentaires la font arriver sur 50 murs, 100 j\'aime et 10 commentaires sur 100. Tu peux désactiver cette option à tout moment.';

  @override
  String get photoThemesRemoveTitle => 'Retirer ta photo ?';

  @override
  String get photoThemesRemoveMessage =>
      'Elle disparaît de ce thème pour tout le monde. Tu pourras en partager une nouvelle ensuite.';

  @override
  String get photoThemesRemoveAction => 'Retirer la photo';

  @override
  String get photoThemesRemoveFailed => 'Ta photo n\'a pas pu être retirée.';

  @override
  String get photoThemesReachOn =>
      'Ta photo peut maintenant apparaître sur les murs des membres qui l\'adorent.';

  @override
  String get photoThemesReachOff => 'Ta photo n\'apparaît plus sur aucun mur.';

  @override
  String get photoThemesSharedByYou => 'Partagée par toi';

  @override
  String photoThemesSharedBy(String name) {
    return 'Partagée par $name';
  }

  @override
  String photoThemesPhotoDescription(String text) {
    return 'Description de la photo : $text';
  }

  @override
  String get photoThemesReachSwitch =>
      'Le laisser apparaître sur les murs des autres membres';

  @override
  String get photoThemesReachIdle =>
      'Les membres peuvent faire voyager cette photo';

  @override
  String get photoThemesReachLive =>
      'Des membres la voient en ce moment sur leurs murs Today.';

  @override
  String get photoThemesRemoveMine => 'Retirer ma photo';

  @override
  String get photoThemesReport => 'Signaler';

  @override
  String photoThemesBlock(String name) {
    return 'Bloquer $name';
  }

  @override
  String get photoThemesCommentHint => 'À quoi ça te fait penser ?';

  @override
  String get photoThemesCommentApproved =>
      'Approuvé. Toutes les personnes qui peuvent voir cette photo le voient désormais.';

  @override
  String get photoThemesDetailsTitle => 'Raconte-nous';

  @override
  String get photoThemesCaption => 'Légende';

  @override
  String get photoThemesCaptionHint => 'Des pancakes, et nulle part où aller.';

  @override
  String get photoThemesDescribe => 'Décris la photo';

  @override
  String get photoThemesDescribeHelper =>
      'Aide les membres qui utilisent un lecteur d\'écran.';

  @override
  String get photoThemesShare => 'Partager';

  @override
  String get photoThemesWallTitle => 'Les couvertures de ton mur';

  @override
  String get photoThemesWallCaption =>
      'Des photos que d\'autres membres ont adorées';

  @override
  String get photoThemesMasthead => 'THÈMES PHOTO';

  @override
  String photoThemesByline(String name) {
    return 'PAR $name';
  }

  @override
  String get photoThemesLikes => 'J\'aime';

  @override
  String get photoThemesComments => 'Commentaires';

  @override
  String get photoThemesCancel => 'Annuler';

  @override
  String get photoThemesTryAgain => 'Réessayer';

  @override
  String get photoThemesSaveFailed => 'Ça n\'a pas été enregistré. Réessaie.';

  @override
  String get friendsChatEmpty =>
      'Dis bonjour. Vous seuls pouvez voir cette discussion.';

  @override
  String get friendsChatOpenFailed =>
      'Impossible d’ouvrir la discussion. Réessaie.';

  @override
  String get friendsCancelRequestTitle => 'Annuler ta demande d’ami ?';

  @override
  String friendsCancelRequestBody(String name) {
    return '$name ne verra plus ta demande.';
  }

  @override
  String get friendsCancelRequestBodyUnnamed =>
      'Ce membre ne verra plus ta demande.';

  @override
  String get friendsKeepIt => 'La garder';

  @override
  String get friendsCancelRequest => 'Annuler la demande';

  @override
  String friendsNowFriends(String name) {
    return '$name et toi êtes maintenant amis.';
  }

  @override
  String get friendsNowFriendsUnnamed =>
      'Ce membre et toi êtes maintenant amis.';

  @override
  String friendsRequestSentTo(String name) {
    return 'Demande d’ami envoyée à $name.';
  }

  @override
  String get friendsRequestSentToUnnamed =>
      'Demande d’ami envoyée à ce membre.';

  @override
  String get friendsRequestCancelled => 'Demande annulée.';

  @override
  String get friendsRequestFailed => 'Impossible d’envoyer la demande.';

  @override
  String get friendsAddCaption =>
      'Entre amis, vous pouvez vous écrire et faire des plans';

  @override
  String get friendsRequested => 'Demandé';

  @override
  String friendsWaitingFor(String name) {
    return 'En attente de $name. Touche pour annuler.';
  }

  @override
  String get friendsWaitingForUnnamed =>
      'En attente de ce membre. Touche pour annuler.';

  @override
  String get friendsAcceptFriend => 'Accepter l’ami';

  @override
  String friendsAskedToBeFriends(String name) {
    return '$name veut être ami·e avec toi';
  }

  @override
  String get friendsAskedToBeFriendsUnnamed =>
      'Ce membre veut être ami·e avec toi';

  @override
  String get friendsMessage => 'Écrire';

  @override
  String get friendsYoureFriends => 'Vous êtes amis. Ouvre votre discussion.';

  @override
  String friendsVouchTooShort(int min) {
    return 'Écris-en un peu plus (au moins $min caractères).';
  }

  @override
  String friendsVouchTitle(String name) {
    return 'Recommander $name';
  }

  @override
  String get friendsVouchBody =>
      'Une phrase ou deux sur la chance qu’on aurait de rencontrer cette personne. Elle l’approuve avant que ça s’affiche sur son profil, avec ton prénom.';

  @override
  String get friendsVouchLabel => 'Ta recommandation';

  @override
  String get friendsVouchHint => 'Gentil, drôle et toujours à l’heure.';

  @override
  String get friendsVouchSend => 'Envoyer la recommandation';

  @override
  String get friendsIntroChooseTwo => 'Choisis deux amis différents.';

  @override
  String get friendsIntroSheetTitle => 'Présenter deux amis';

  @override
  String get friendsIntroSheetBody =>
      'Tes deux amis doivent autoriser les présentations. Chacun contrôle son aperçu et décide en privé. Ne donne qu’une raison que tu as le droit de mentionner. Leurs décisions et l’issue du match restent privées.';

  @override
  String get friendsIntroNeedTwo =>
      'Il te faut au moins deux amis pour faire une présentation.';

  @override
  String get friendsFirstFriend => 'Premier ami';

  @override
  String get friendsSecondFriend => 'Deuxième ami';

  @override
  String get friendsIntroWhyLabel =>
      'Pourquoi ils devraient se rencontrer (facultatif)';

  @override
  String get friendsIntroSubmit => 'Faire la présentation';

  @override
  String get friendsLoadFailed => 'Impossible de charger tes amis. Réessaie.';

  @override
  String get friendsAddFailed => 'Impossible d’ajouter cet ami.';

  @override
  String get friendsRemoveFailed => 'Impossible de retirer cet ami.';

  @override
  String get friendsRespondFailed =>
      'Impossible de répondre à la demande d’ami.';

  @override
  String get friendsSocialLoadFailed =>
      'Impossible de charger les recommandations et les présentations.';

  @override
  String get friendsVouchSendFailed =>
      'Impossible d’envoyer cette recommandation.';

  @override
  String get friendsVouchUpdateFailed =>
      'Impossible de mettre à jour cette recommandation.';

  @override
  String get friendsVouchWithdrawFailed =>
      'Impossible de retirer cette recommandation.';

  @override
  String get friendsIntroMakeFailed =>
      'Impossible de faire cette présentation.';

  @override
  String get friendsIntroAnswerFailed =>
      'Impossible de répondre à cette présentation.';

  @override
  String get groupsEyebrow => 'GROUPES';

  @override
  String get groupsTitle => 'Trouve ta communauté.';

  @override
  String get groupsSubtitle =>
      'Des communautés par style de vie ouvertes à tous, et des groupes privés rien que pour tes amis.';

  @override
  String get groupsStartGroup => 'Créer un groupe';

  @override
  String get groupsInvitationsHeader => 'INVITATIONS';

  @override
  String get groupsInvitationsCaption => 'Des amis t’invitent à les rejoindre.';

  @override
  String get groupsAnswerFailed => 'Ta réponse n’a pas pu être enregistrée.';

  @override
  String groupsWelcome(String name) {
    return 'Bienvenue dans $name !';
  }

  @override
  String get groupsInvitationDeclined => 'Invitation refusée.';

  @override
  String get groupsYourGroupsHeader => 'TES GROUPES';

  @override
  String get groupsYourGroupsFailed => 'Impossible de charger tes groupes';

  @override
  String get groupsErrorCheckConnection => 'Vérifie ta connexion.';

  @override
  String get groupsEmptyTitle => 'Aucun groupe pour l’instant';

  @override
  String get groupsEmptyBody =>
      'Rejoins une communauté ci-dessous, ou crée un groupe privé avec tes amis.';

  @override
  String get groupsDiscoverHeader => 'DÉCOUVRIR PAR STYLE DE VIE';

  @override
  String get groupsDiscoverCaption =>
      'Les groupes communautaires sont ouverts à tous.';

  @override
  String get groupsLifestylesFailed =>
      'Impossible de charger les styles de vie';

  @override
  String get groupsCategoryAll => 'Tous';

  @override
  String get groupsDiscoverFailed => 'Impossible de charger les groupes';

  @override
  String get groupsDiscoverEmptyTitle => 'Rien de nouveau à rejoindre';

  @override
  String groupsDiscoverEmptyCategoryTitle(String category) {
    return 'Aucun groupe $category pour l’instant';
  }

  @override
  String get groupsDiscoverEmptyBody =>
      'Lance-toi : crée un groupe communautaire et invite tes amis.';

  @override
  String get groupsStartOne => 'En créer un';

  @override
  String get groupsJoinFailed =>
      'Impossible de rejoindre le groupe pour le moment.';

  @override
  String get groupsJoin => 'Rejoindre';

  @override
  String groupsJoinNamed(String name) {
    return 'Rejoindre $name';
  }

  @override
  String groupsInvitedBy(String name, String kind, String members) {
    return 'Invitation de $name · $kind · $members';
  }

  @override
  String groupsInvitedByFriend(String kind, String members) {
    return 'Invitation d’un ami · $kind · $members';
  }

  @override
  String get groupsDecline => 'Refuser';

  @override
  String groupsDeclineNamed(String name) {
    return 'Refuser $name';
  }

  @override
  String groupsChatEmpty(String name) {
    return 'Dis bonjour au groupe. Tout le monde dans $name peut voir les messages ici.';
  }

  @override
  String groupsInviteFriendsTo(String name) {
    return 'Inviter des amis dans $name';
  }

  @override
  String get groupsSendInvitations => 'Envoyer les invitations';

  @override
  String get groupsInvitationsFailed =>
      'Les invitations n’ont pas pu être envoyées.';

  @override
  String groupsInvitationSentTo(String name) {
    return 'Invitation envoyée à $name.';
  }

  @override
  String groupsInvitationsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invitations envoyées.',
      one: '1 invitation envoyée.',
    );
    return '$_temp0';
  }

  @override
  String groupsLeaveTitle(String name) {
    return 'Quitter $name ?';
  }

  @override
  String get groupsLeaveBodyAlone =>
      'Tu es le seul membre : le groupe et son chat seront donc supprimés.';

  @override
  String get groupsLeaveBodyOwner =>
      'La propriété passe à ton modérateur le plus ancien, ou à défaut au membre le plus ancien. Tu perdras l’accès au chat.';

  @override
  String get groupsLeaveBodyCommunity =>
      'Tu perdras l’accès au chat du groupe. Tu pourras le rejoindre à nouveau plus tard.';

  @override
  String get groupsLeaveBodyPrivate =>
      'Tu perdras l’accès au chat du groupe. Il te faudra une nouvelle invitation pour revenir.';

  @override
  String get groupsLeave => 'Quitter';

  @override
  String get groupsLeaveFailed =>
      'Impossible de quitter le groupe pour le moment.';

  @override
  String get groupsCoverUploadFailed =>
      'Ta photo de couverture n’a pas pu être envoyée. Utilise un JPEG ou un PNG de 10 Mo maximum.';

  @override
  String get groupsRemoveCoverTitle => 'Retirer la photo de couverture ?';

  @override
  String groupsRemoveCoverBody(String name) {
    return '$name affichera à nouveau sa couverture emoji.';
  }

  @override
  String get groupsRemove => 'Retirer';

  @override
  String get groupsRemoveCoverFailed =>
      'La photo de couverture n’a pas pu être retirée.';

  @override
  String get groupsCoverRemoved => 'Photo de couverture retirée.';

  @override
  String groupsDeleteTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get groupsDeleteBody =>
      'Le groupe, ses invitations et son chat seront supprimés pour tout le monde. Cette action est irréversible.';

  @override
  String get groupsDeleteGroup => 'Supprimer le groupe';

  @override
  String get groupsDeleteFailed => 'Le groupe n’a pas pu être supprimé.';

  @override
  String get groupsDetailEyebrow => 'GROUPE';

  @override
  String get groupsDetailTitleFallback => 'Groupe';

  @override
  String get groupsOwnerTools => 'Outils du propriétaire';

  @override
  String get groupsEditGroup => 'Modifier le groupe';

  @override
  String get groupsAddCoverPhoto => 'Ajouter une photo de couverture';

  @override
  String get groupsChangeCoverPhoto => 'Changer la photo de couverture';

  @override
  String get groupsRemoveCoverPhoto => 'Retirer la photo de couverture';

  @override
  String get groupsMoreOptions => 'Plus d’options';

  @override
  String get groupsReportGroup => 'Signaler le groupe';

  @override
  String get groupsUnavailableTitle => 'Ce groupe n’est pas disponible';

  @override
  String get groupsUnavailableBody =>
      'Il a peut-être été supprimé, ou tu n’y as plus accès.';

  @override
  String get groupsOpenToAll => 'Ouvert à tous';

  @override
  String get groupsPrivate => 'Privé';

  @override
  String get groupsYouRunIt => 'C’est toi qui le gères';

  @override
  String get groupsYouModerate => 'Tu modères';

  @override
  String get groupsCoverNotePending =>
      'Tant qu’elle n’est pas approuvée, cette photo n’est visible que par toi. Les membres voient la couverture emoji en attendant.';

  @override
  String get groupsCoverNoteRejected =>
      'Ta dernière photo de couverture n’a pas été approuvée. Choisis-en une autre.';

  @override
  String get groupsCoverUnderReview => 'En cours de vérification';

  @override
  String get groupsChangeCover => 'Changer la couverture';

  @override
  String get groupsRemoveCover => 'Retirer la couverture';

  @override
  String get groupsRemovedTitle => 'Ce groupe a été retiré après examen';

  @override
  String get groupsRemovedBodyOwner =>
      'Les membres ne peuvent ni discuter, ni rejoindre, ni inviter tant qu’il est retiré. Tes avis d’examen expliquent la décision et te permettent de faire appel.';

  @override
  String get groupsRemovedBodyMember =>
      'Les membres ne peuvent ni discuter, ni rejoindre, ni inviter tant qu’il est retiré. Tu peux quitter le groupe à tout moment.';

  @override
  String get groupsMembers => 'Membres';

  @override
  String get groupsChatButton => 'Chat du groupe';

  @override
  String groupsChatButtonUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chat du groupe · $count non lus',
      one: 'Chat du groupe · 1 non lu',
    );
    return '$_temp0';
  }

  @override
  String get groupsInviteFriends => 'Inviter des amis';

  @override
  String get groupsWhosHere => 'QUI EST LÀ';

  @override
  String get groupsSeeAll => 'Tout voir';

  @override
  String get groupsYou => 'Toi';

  @override
  String groupsInvitedToJoin(String name) {
    return 'Tu as une invitation pour rejoindre $name.';
  }

  @override
  String get groupsJoinGroup => 'Rejoindre le groupe';

  @override
  String get groupsJoinHint =>
      'Les membres voient qui est là et discutent ensemble.';

  @override
  String get groupsCantJoinTitle => 'Tu ne peux pas rejoindre ce groupe';

  @override
  String get groupsCantJoinBody =>
      'Il est peut-être complet, ou la modération a retiré ton accès.';

  @override
  String get groupsInvitationOnly => 'Sur invitation uniquement';

  @override
  String get groupsInvitationOnlyBody =>
      'Un membre peut t’inviter dans ce groupe privé.';

  @override
  String get groupsMakeModerator => 'Nommer modérateur';

  @override
  String get groupsMakeMember => 'Repasser membre';

  @override
  String get groupsRemoveFromGroup => 'Retirer du groupe';

  @override
  String groupsRemoveMemberTitle(String name) {
    return 'Retirer $name ?';
  }

  @override
  String get groupsRemoveMemberBodyCommunity =>
      'Cette personne quitte le groupe et son chat, et ne pourra pas le rejoindre d’elle-même.';

  @override
  String get groupsRemoveMemberBodyPrivate =>
      'Cette personne quitte le groupe et son chat.';

  @override
  String get groupsChangeFailed =>
      'Cette modification n’a pas pu être enregistrée.';

  @override
  String get groupsMembersFailed => 'Impossible de charger les membres';

  @override
  String get groupsPleaseTryAgain => 'Réessaie.';

  @override
  String groupsMemberYou(String name) {
    return '$name (toi)';
  }

  @override
  String get groupsRoleOwner => 'Propriétaire';

  @override
  String get groupsRoleModerator => 'Modérateur';

  @override
  String get groupsRoleMember => 'Membre';

  @override
  String groupsMemberOptions(String name) {
    return 'Options pour $name';
  }

  @override
  String get groupsEditFailed =>
      'Tes modifications n’ont pas pu être enregistrées.';

  @override
  String get groupsSaving => 'Enregistrement…';

  @override
  String get groupsSaveChanges => 'Enregistrer';

  @override
  String get groupsNameLabel => 'Nom du groupe';

  @override
  String get groupsAboutLabel => 'De quoi s’agit-il ?';

  @override
  String get groupsAboutOptionalLabel => 'De quoi s’agit-il ? (facultatif)';

  @override
  String get groupsCityLabel => 'Ville (facultatif)';

  @override
  String get groupsCoverColorTheme => 'Thème';

  @override
  String get groupsCoverColorAccent => 'Accent';

  @override
  String get groupsCoverColorWarm => 'Chaud';

  @override
  String get groupsLifestyleLabel => 'Style de vie';

  @override
  String get groupsCreateCoverUploadFailed =>
      'Ton groupe est prêt, mais la photo de couverture n’a pas pu être envoyée. Réessaie depuis le groupe.';

  @override
  String get groupsCreatePickLifestyle =>
      'Choisis un style de vie pour ton groupe communautaire.';

  @override
  String get groupsCreateNameTooShort =>
      'Donne à ton groupe un nom d’au moins 3 lettres.';

  @override
  String get groupsCreateFailed => 'Ton groupe n’a pas pu être créé. Réessaie.';

  @override
  String get groupsCreateEyebrow => 'NOUVEAU GROUPE';

  @override
  String get groupsCreateSubtitle =>
      'Rassemble des gens autour de ce que tu aimes.';

  @override
  String get groupsCreateSubtitleFriends => 'Transforme tes amis en groupe.';

  @override
  String get groupsCreateKindHeader => 'QUEL TYPE';

  @override
  String get groupsKindCommunity => 'Groupe communautaire';

  @override
  String get groupsKindPrivate => 'Groupe privé';

  @override
  String get groupsCreateCommunitySubtitle =>
      'Par style de vie. Tout le monde peut le trouver et le rejoindre.';

  @override
  String get groupsCreatePrivateSubtitle =>
      'Rien qu’entre amis. Seules les personnes que tu invites peuvent le rejoindre.';

  @override
  String get groupsCreateLifestyleHeader => 'STYLE DE VIE';

  @override
  String get groupsCreateLifestyleCaption =>
      'Là où les gens découvriront ton groupe.';

  @override
  String get groupsCreateDetailsHeader => 'DÉTAILS';

  @override
  String get groupsCreateNameHintCommunity =>
      'Les coureurs de l’aube d’Indiranagar';

  @override
  String get groupsCreateNameHintPrivate => 'La bande du brunch du dimanche';

  @override
  String get groupsCreateCoverHeader => 'COUVERTURE';

  @override
  String groupsCoverEmojiSemantics(String emoji) {
    return 'Emoji de couverture $emoji';
  }

  @override
  String get groupsCreateCoverPhotoOptional =>
      'Photo de couverture (facultatif)';

  @override
  String get groupsCreateCoverPhotoHint =>
      'Les membres voient l’emoji jusqu’à ce que ta photo soit approuvée.';

  @override
  String get groupsCreateAddCoverPhoto => 'Ajouter une photo de couverture';

  @override
  String get groupsCreateChangePhoto => 'Changer de photo';

  @override
  String get groupsCreateRemovePhoto => 'Retirer la photo';

  @override
  String get groupsCreateFriendsHeader => 'AMIS';

  @override
  String get groupsCreateFriendsCaptionEmpty =>
      'Invite des amis maintenant, ou plus tard depuis le groupe.';

  @override
  String get groupsCreateFriendsCaption =>
      'Ils recevront une invitation à rejoindre le groupe.';

  @override
  String get groupsFriendFallback => 'Ami';

  @override
  String groupsRemoveInvitee(String name) {
    return 'Retirer $name';
  }

  @override
  String get groupsChooseFriends => 'Choisir des amis';

  @override
  String get groupsChangeFriends => 'Modifier les amis';

  @override
  String get groupsCreating => 'Création…';

  @override
  String get groupsCreateGroup => 'Créer le groupe';

  @override
  String get groupsCardRemoved => 'Retiré après examen';

  @override
  String groupsCardSemanticsMuted(String name, String details) {
    return '$name, $details, notifications désactivées';
  }

  @override
  String get groupsNotificationsMuted => 'Notifications désactivées';

  @override
  String groupsUnreadMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages non lus',
      one: '1 message non lu',
    );
    return '$_temp0';
  }

  @override
  String get groupsCoverSheetTitle => 'Photo de couverture';

  @override
  String get groupsCoverSheetBody =>
      'Chaque photo est vérifiée avant que les autres membres puissent la voir. Utilise un JPEG ou un PNG de 10 Mo maximum.';

  @override
  String get groupsCoverFromPhotos => 'Choisir dans tes photos';

  @override
  String get groupsCoverTakePhoto => 'Prendre une photo';

  @override
  String get groupsCoverTooLarge =>
      'Cette photo dépasse 10 Mo. Choisis-en une plus petite.';

  @override
  String get groupsCoverPreviewTitle => 'Aperçu de ta couverture';

  @override
  String get groupsCoverPreviewBody =>
      'Les couvertures s’affichent en large bannière, centrée sur le milieu de ta photo.';

  @override
  String get groupsCancel => 'Annuler';

  @override
  String get groupsCoverUseThisPhoto => 'Utiliser cette photo';

  @override
  String get groupsCoverPreviewSemantics => 'Ta nouvelle photo de couverture';

  @override
  String get groupsCoverChecking => 'Vérification de ta photo de couverture…';

  @override
  String groupsCoverUploading(int percent) {
    return 'Envoi de la photo de couverture… $percent %';
  }

  @override
  String get groupsCoverUploadedReview =>
      'Ta couverture est en cours de vérification. Tant qu’elle n’est pas approuvée, elle n’est visible que par toi.';

  @override
  String get groupsCoverUpdated => 'Photo de couverture mise à jour.';

  @override
  String get groupsPickerSubtitle =>
      'Tu ne peux inviter que des personnes de ta liste d’amis.';

  @override
  String get groupsDone => 'Terminé';

  @override
  String get groupsSearchFriends => 'Rechercher des amis';

  @override
  String get groupsFriendsFailed => 'Impossible de charger tes amis';

  @override
  String get groupsNoFriendsTitle => 'Pas encore d’amis';

  @override
  String get groupsNoFriendsBody =>
      'Ajoute des amis depuis les Matchs, les profils ou les salons, puis invite-les dans un groupe.';

  @override
  String get groupsAlreadyMember => 'Déjà dans ce groupe';

  @override
  String get groupsInvitationSent => 'Invitation envoyée';

  @override
  String get todayActivityCoffee => 'Un café';

  @override
  String get todayActivityWalk => 'Une balade en journée';

  @override
  String get todayActivityMeal => 'Un repas';

  @override
  String get todayActivityPlayful => 'Quelque chose de ludique';

  @override
  String get todayActivityEvent => 'Un événement';

  @override
  String get todayActivityVideoCall => 'Un bonjour en vidéo';

  @override
  String get todayActivityDrinks => 'Un verre';

  @override
  String get todayActivityOther => 'Autre chose';

  @override
  String get todayBudgetFlexible => 'Décidons ensemble';

  @override
  String get todayBudgetFree => 'Rester gratuit';

  @override
  String get todayBudgetModest => 'Rester raisonnable';

  @override
  String get todayBudgetTreat => 'Se faire un petit plaisir';

  @override
  String get todayRhythmTitle => 'Ton rythme de rencontres';

  @override
  String get todayRhythmLoadFailed => 'Impossible de charger tes préférences.';

  @override
  String get todayRhythmSaved => 'Ton rythme de rencontres est enregistré.';

  @override
  String get todayRhythmSaveFailed =>
      'Impossible d’enregistrer. Tes choix sont toujours là.';

  @override
  String get todayRhythmHeadline =>
      'Fais de la place à ta façon de faire des rencontres.';

  @override
  String get todayRhythmIntro =>
      'Choisis ce qui convient à ta vie. Les disponibilités et les présentations sont facultatives, et tu peux changer d’avis.';

  @override
  String get todayRhythmOpenTo => 'À quoi es-tu ouvert·e ?';

  @override
  String get todayRhythmIntentNone => 'Je préfère ne pas le dire';

  @override
  String get todayRhythmIntentRelationship => 'Une relation';

  @override
  String get todayRhythmIntentExploring => 'Je cherche encore ma voie';

  @override
  String get todayRhythmIntentCasual => 'Quelque chose de léger';

  @override
  String get todayRhythmPaceSection => 'Ton rythme de conversation';

  @override
  String get todayRhythmPaceNone => 'Pas de préférence';

  @override
  String get todayRhythmPaceSlow => 'Un peu plus lent';

  @override
  String get todayRhythmPaceSteady => 'Une conversation régulière';

  @override
  String get todayRhythmPaceFrequent => 'Des échanges fréquents';

  @override
  String get todayRhythmSlowWeek => 'Réponses lentes cette semaine';

  @override
  String get todayRhythmSlowWeekHint =>
      'Ce statut disparaît au bout de sept jours.';

  @override
  String get todayRhythmSharePace => 'Partager ce statut avec mes matchs';

  @override
  String get todayRhythmSharePaceHint =>
      'Seuls tes matchs actuels peuvent voir ton statut temporaire.';

  @override
  String get todayRhythmFirstDate => 'Ton genre de premier rendez-vous';

  @override
  String get todayRhythmChooseFive =>
      'Choisis-en jusqu’à cinq. Les préférences communes aident à expliquer tes présentations.';

  @override
  String get todayRhythmWeekSection => 'Un peu de place dans ta semaine';

  @override
  String get todayRhythmShareAvailability =>
      'Utiliser mes disponibilités générales';

  @override
  String get todayRhythmShareAvailabilityHint =>
      'Seuls les vrais créneaux communs sont affichés. Ton emploi du temps complet reste privé. Désactiver cette option supprime les créneaux enregistrés.';

  @override
  String get todayRhythmAvailabilityHint =>
      'Touche les matinées, après-midi ou soirées qui te conviennent. Les horaires suivent l’heure locale de cet appareil et expirent automatiquement.';

  @override
  String get todayRhythmMorning => 'Matin';

  @override
  String get todayRhythmAfternoon => 'Après-midi';

  @override
  String get todayRhythmEvening => 'Soir';

  @override
  String get todayRhythmIntrosSection => 'Des présentations avec ton accord';

  @override
  String get todayRhythmFriendIntros =>
      'Autoriser les présentations par des ami·es accepté·es';

  @override
  String get todayRhythmFriendIntrosHint =>
      'Les deux personnes doivent accepter. Ton ami·e n’est pas informé·e d’un match ou d’un refus. Un aperçu inclut ton prénom et ton âge.';

  @override
  String get todayRhythmIntroPhoto => 'Inclure mes photos de profil';

  @override
  String get todayRhythmIntroPhotoHint =>
      'Seule la personne qui reçoit la présentation peut les voir.';

  @override
  String get todayRhythmIntroCity => 'Inclure ma ville';

  @override
  String get todayRhythmIntroCityHint =>
      'Ta position exacte n’est jamais incluse.';

  @override
  String get todayRhythmReload => 'Recharger les choix enregistrés';

  @override
  String get todayRhythmSaving => 'Enregistrement…';

  @override
  String get todayRhythmSave => 'Enregistrer mon rythme';

  @override
  String get todayRhythmBreakTitle => 'Faire une pause, c’est toujours permis.';

  @override
  String get todayRhythmBreakBody =>
      'Mets les nouvelles présentations en pause quand tu en as besoin. Tes conversations en cours restent disponibles.';

  @override
  String get todayRhythmPauseFailed => 'Impossible de mettre à jour ta pause.';

  @override
  String get todayRhythmResume => 'Reprendre les présentations';

  @override
  String get todayRhythmPause => 'Mettre les présentations en pause';

  @override
  String get datingConnectionSlowTitle => 'Répond plus lentement cette semaine';

  @override
  String get datingConnectionSlowBody =>
      'Ton match s’accorde un rythme plus calme.';

  @override
  String get datingConnectionYourTurn => 'À toi : ajoute une surprise';

  @override
  String get datingConnectionComplete => 'Votre premier chapitre est prêt';

  @override
  String get datingConnectionWaiting => 'Votre chapitre a un début';

  @override
  String get datingConnectionCreate => 'Créez votre premier chapitre';

  @override
  String get datingConnectionBody =>
      'Un début, une surprise et une histoire que vous façonnez ensemble.';

  @override
  String get chemistryTitle => 'Un peu d’alchimie';

  @override
  String get chemistryIntro =>
      'Choisis ce qui te ressemble. Il n’y a pas de bonne réponse, et cela ne conditionne jamais l’accès au chat.';

  @override
  String get chemistrySaveFailed =>
      'Impossible d’enregistrer ton choix. Réessaie.';

  @override
  String get chemistryRetry => 'Recharger';

  @override
  String get chemistryRevealedTitle => 'Vos deux réponses, ensemble';

  @override
  String get chemistryYouPicked => 'Ton choix';

  @override
  String get chemistryMatchPicked => 'Le choix de ton match';

  @override
  String get chemistryRevealedBody =>
      'Un coup de cœur commun ou une jolie différence : vous avez de quoi parler.';

  @override
  String get chemistryWaitingBody =>
      'Ta réponse est enregistrée en privé. Les deux réponses s’afficheront ici quand vous aurez choisi tous les deux.';

  @override
  String chemistryYourChoice(String choice) {
    return 'Ton choix : $choice';
  }

  @override
  String get chemistryAnotherMoment => 'Un autre moment, quand tu veux';

  @override
  String get chemistryChooseMoment => 'Choisis un moment';

  @override
  String get chemistryPromptSunday => 'Imagine un dimanche';

  @override
  String get chemistryPromptAdventure => 'Choisis une aventure';

  @override
  String get chemistryPromptFirstDate => 'Ton genre de premier rendez-vous';

  @override
  String get chemistryQuestionSunday => 'Ton dimanche idéal commence par…';

  @override
  String get chemistryQuestionAdventure => 'Une petite aventure à deux…';

  @override
  String get chemistryQuestionFirstDate =>
      'Pour un premier bonjour, tu choisirais…';

  @override
  String get engagementLevelFrozen =>
      'Ta progression est en pause pendant l’examen de sécurité de ton compte.';

  @override
  String get engagementLevelTrustGate =>
      'Vérifie ton profil et garde un compte en règle pour débloquer les niveaux soumis à la confiance.';

  @override
  String get engagementLevelPathTitle => 'Parcours de niveaux';

  @override
  String get engagementLevelPathSubtitle =>
      'Les XP viennent d’une activité utile. Les achats n’augmentent jamais ton niveau.';

  @override
  String get engagementLevelRewardsTitle => 'Récompenses';

  @override
  String get engagementLevelRewardsSubtitle =>
      'Les récompenses sont esthétiques, pratiques ou offrent un gain de visibilité limité.';

  @override
  String get engagementLevelRecentTitle => 'XP récents';

  @override
  String get engagementLevelRecentSubtitle =>
      'Ton historique d’activité est permanent et vérifiable.';

  @override
  String engagementLevelNumber(int level) {
    return 'Niveau $level';
  }

  @override
  String engagementLevelXp(String xp) {
    return '$xp XP';
  }

  @override
  String get engagementLevelHighest => 'Niveau maximum atteint';

  @override
  String engagementLevelProgress(int xp, String percent) {
    return '$xp XP dans ce niveau · $percent %';
  }

  @override
  String engagementLevelThreshold(int xp, String summary) {
    return '$xp XP · $summary';
  }

  @override
  String get engagementLevelTrustGated => 'Soumis à la confiance';

  @override
  String get engagementLevelClaimed => 'Récupérée';

  @override
  String get engagementLevelClaim => 'Récupérer';

  @override
  String get engagementLevelLocked => 'Verrouillée';

  @override
  String get engagementLevelStandardAward => 'Attribution standard';

  @override
  String engagementLevelQualityWeighting(String multiplier) {
    return 'Pondération qualité ×$multiplier';
  }

  @override
  String get engagementLevelEmptyLedger =>
      'Termine des activités utiles pour gagner tes premiers XP.';

  @override
  String get engagementXpSourceProfileCompleted => 'Profil complété';

  @override
  String get engagementXpSourceDailyPromptSubmitted =>
      'Question du jour envoyée';

  @override
  String get engagementXpSourceMiniActivityCompleted =>
      'Mini-activité terminée';

  @override
  String get engagementXpSourceCircleChallengeSubmitted =>
      'Défi de cercle envoyé';

  @override
  String get engagementXpSourceVoiceIcebreakerPlayed =>
      'Brise-glace vocal écouté';

  @override
  String get engagementXpSourceStreak3 => 'Série de 3 jours';

  @override
  String get engagementXpSourceStreak7 => 'Série de 7 jours';

  @override
  String get engagementXpSourceStreak14 => 'Série de 14 jours';

  @override
  String get engagementXpSourceAdminAdjustment => 'Ajustement par l’équipe';

  @override
  String get engagementLevelSignIn =>
      'Connecte-toi pour voir ta progression de niveau.';

  @override
  String get engagementLevelLoadFailed =>
      'Impossible de charger ta progression pour le moment.';

  @override
  String get engagementLevelClaimFailed =>
      'Impossible de récupérer cette récompense pour le moment.';

  @override
  String get engagementCoffeeTitle => 'Sondages café en groupe';

  @override
  String get engagementCoffeeCreateHeading =>
      'Crée un petit sondage café pour ton groupe';

  @override
  String get engagementCoffeeCreateHint =>
      'Ajoute jusqu’à 3 identifiants de participants (séparés par des virgules) et au moins une option.';

  @override
  String get engagementCoffeeParticipantsLabel =>
      'Identifiants des participants (séparés par des virgules)';

  @override
  String get engagementCoffeeDeadlineLabel => 'Date limite ISO (facultatif)';

  @override
  String engagementCoffeeOptionNumber(int number) {
    return 'Option $number';
  }

  @override
  String get engagementCoffeeCreate => 'Créer le sondage';

  @override
  String get engagementCoffeeActorLabel =>
      'Identifiant utilisateur pour l’action (facultatif)';

  @override
  String get engagementCoffeeEmpty =>
      'Aucun sondage pour l’instant. Crée-en un ci-dessus.';

  @override
  String engagementCoffeePollId(String id) {
    return 'Sondage $id';
  }

  @override
  String engagementCoffeeStatus(String status) {
    return 'Statut : $status';
  }

  @override
  String get engagementCoffeeStatusOpen => 'ouvert';

  @override
  String get engagementCoffeeStatusFinalized => 'validé';

  @override
  String engagementCoffeeParticipants(String ids) {
    return 'Participants : $ids';
  }

  @override
  String engagementCoffeeOptionSummary(
    String day,
    String time,
    String area,
    int count,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$day · $time · $area ($count votes)',
      one: '$day · $time · $area (1 vote)',
      zero: '$day · $time · $area (0 vote)',
    );
    return '$_temp0';
  }

  @override
  String get engagementCoffeeVote => 'Voter';

  @override
  String get engagementCoffeeFinalize => 'Valider le sondage';

  @override
  String get engagementCoffeeDayLabel => 'Jour';

  @override
  String get engagementCoffeeTimeLabel => 'Créneau';

  @override
  String get engagementCoffeeAreaLabel => 'Quartier';

  @override
  String get engagementCoffeeLoadFailed =>
      'Impossible de charger les sondages de groupe pour le moment.';

  @override
  String get engagementCoffeeCreateFailed =>
      'Impossible de créer le sondage de groupe pour le moment.';

  @override
  String get engagementCoffeeVoteUserRequired =>
      'Un identifiant utilisateur est requis pour voter.';

  @override
  String get engagementCoffeeVoteFailed =>
      'Impossible de voter pour le moment.';

  @override
  String get engagementCoffeeFinalizeUserRequired =>
      'Un identifiant utilisateur est requis pour valider.';

  @override
  String get engagementCoffeeFinalizeFailed =>
      'Impossible de valider le sondage pour le moment.';

  @override
  String get engagementDailyPromptUnavailable =>
      'Question du jour indisponible';

  @override
  String get engagementDailyPromptPullToRefresh =>
      'Tire pour actualiser ou réessaie dans un instant.';

  @override
  String get engagementDailyPromptDomainValues => 'VALEURS';

  @override
  String get engagementDailyPromptDomainLifestyle => 'MODE DE VIE';

  @override
  String get engagementDailyPromptDomainRelationshipStyle =>
      'STYLE DE RELATION';

  @override
  String get engagementDailyPromptSparkTitle => 'Étincelle de compatibilité';

  @override
  String engagementDailyPromptSparkSummary(int replied, int similar) {
    return 'Réponses aujourd’hui : $replied · réponses similaires : $similar';
  }

  @override
  String get engagementDailyPromptYourAnswer => 'Ta réponse';

  @override
  String get engagementDailyPromptHint =>
      'Écris ta réponse en moins de 60 secondes.';

  @override
  String engagementDailyPromptEditOpenUntil(String time) {
    return 'Modification possible jusqu’à $time';
  }

  @override
  String get engagementDailyPromptEditOpenSoon =>
      'Modification possible encore un court moment';

  @override
  String get engagementDailyPromptEditClosed =>
      'Modification fermée pour aujourd’hui.';

  @override
  String get engagementDailyPromptEdited => 'Modifiée';

  @override
  String get engagementDailyPromptSubmit => 'Envoyer ma réponse du jour';

  @override
  String get engagementDailyPromptUpdate => 'Mettre à jour ma réponse';

  @override
  String get engagementDailyPromptStreakProgress => 'Progression de la série';

  @override
  String engagementDailyPromptStatCurrent(String value) {
    return 'En cours : $value';
  }

  @override
  String engagementDailyPromptStatBest(String value) {
    return 'Record : $value';
  }

  @override
  String engagementDailyPromptStatNext(String value) {
    return 'Prochain palier : $value';
  }

  @override
  String engagementDailyPromptDays(int days) {
    return '$days j';
  }

  @override
  String get engagementDailyPromptComplete => 'Terminé';

  @override
  String engagementDailyPromptMilestone(int days) {
    return 'Palier débloqué : série de $days jours';
  }

  @override
  String get engagementDailyPromptLoadFailed =>
      'Impossible de charger la question du jour pour le moment.';

  @override
  String get engagementDailyPromptNotLoaded =>
      'La question du jour n’est pas encore chargée.';

  @override
  String get engagementDailyPromptEnterAnswer => 'Écris d’abord une réponse.';

  @override
  String get engagementDailyPromptSubmitFailed =>
      'Impossible d’envoyer la réponse. Réessaie.';

  @override
  String get clubsKindBooks => 'Livres';

  @override
  String get clubsKindFilms => 'Films';

  @override
  String get clubsFilterAll => 'Tous';

  @override
  String get clubsAudiencePrivate => 'Moi seulement';

  @override
  String get clubsAudienceFriends => 'Amis';

  @override
  String get clubsAudienceCommunity => 'Communauté Connect';

  @override
  String get clubsRoleOwner => 'Responsable';

  @override
  String get clubsRoleModerator => 'Modérateur';

  @override
  String get clubsRoleMember => 'Membre';

  @override
  String get clubsBadgeBookClub => 'Club de lecture';

  @override
  String get clubsBadgeFilmClub => 'Ciné-club';

  @override
  String get clubsBadgeBookList => 'Liste de livres';

  @override
  String get clubsBadgeFilmList => 'Liste de films';

  @override
  String get clubsBadgeBook => 'Livre';

  @override
  String get clubsBadgeFilm => 'Film';

  @override
  String get clubsClub => 'Club';

  @override
  String clubsStarsOutOfFive(String rating) {
    return '$rating étoiles sur 5';
  }

  @override
  String clubsStarCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étoiles',
      one: '1 étoile',
    );
    return '$_temp0';
  }

  @override
  String get clubsNoRatingsYet => 'Pas encore de note';

  @override
  String clubsRatingSummary(String average, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avis',
      one: '1 avis',
    );
    return '$average · $_temp0';
  }

  @override
  String get clubsWeekThis => 'Cette semaine';

  @override
  String get clubsWeekNext => 'La semaine prochaine';

  @override
  String get clubsWeekLast => 'La semaine dernière';

  @override
  String clubsWeekOf(String date) {
    return 'Semaine du $date';
  }

  @override
  String get clubsTitle => 'Clubs de lecture et ciné-clubs';

  @override
  String get clubsMyLists => 'Mes listes';

  @override
  String get clubsStartClubTooltip =>
      'Lance un club de lecture ou un ciné-club';

  @override
  String get clubsStartClub => 'Lancer un club';

  @override
  String get clubsSignInToSee => 'Connecte-toi pour voir les clubs.';

  @override
  String get clubsHeroTitle => 'Lis-le. Regarde-le. Parles-en.';

  @override
  String get clubsHeroSubtitle =>
      'Rejoins un club, suis une sélection par semaine et partage ce que tu en as pensé. Le bon goût, c’est un super point de départ pour discuter.';

  @override
  String get clubsScopeMine => 'Mes clubs';

  @override
  String get clubsScopeDiscover => 'Découvrir';

  @override
  String get clubsLoadErrorTitle => 'Impossible de charger les clubs';

  @override
  String get clubsCheckConnection => 'Vérifie ta connexion.';

  @override
  String get clubsLookAroundTitle => 'Tu peux jeter un œil';

  @override
  String get clubsLookAroundMessage =>
      'Complète ton profil avec deux photos approuvées pour lancer ou rejoindre un club.';

  @override
  String get clubsEmptyMineTitle => 'Ton premier club t’attend';

  @override
  String get clubsEmptyMineMessage =>
      'Trouve un club qui lit ou regarde ce que tu aimes, ou lance le tien.';

  @override
  String get clubsEmptyDiscoverTitle => 'Pas encore de club ici';

  @override
  String get clubsEmptyDiscoverMessage =>
      'Lance-toi : crée un club et choisis quelque chose de génial pour cette semaine.';

  @override
  String get clubsDiscoverClubs => 'Découvrir des clubs';

  @override
  String clubsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String get clubsYouRunIt => 'C’est ton club';

  @override
  String get clubsYouModerate => 'Tu modères';

  @override
  String get clubsJoined => 'Membre ✓';

  @override
  String get clubsNoPickThisWeek => 'Pas encore de sélection cette semaine';

  @override
  String get clubsNameTooShort =>
      'Donne à ton club un nom d’au moins 3 lettres.';

  @override
  String get clubsCreateFailed => 'Impossible de créer ton club.';

  @override
  String get clubsNameLabel => 'Nom du club';

  @override
  String get clubsNameHint => 'Lectures lentes du dimanche';

  @override
  String get clubsDescriptionLabel => 'De quoi parle ton club ? (facultatif)';

  @override
  String get clubsCreating => 'Création…';

  @override
  String get clubsCreateClub => 'Créer le club';

  @override
  String clubsLeaveTitle(String name) {
    return 'Quitter $name ?';
  }

  @override
  String get clubsLeaveMessage =>
      'Tu pourras revenir plus tard tant que le club est ouvert.';

  @override
  String get clubsLeaveClub => 'Quitter le club';

  @override
  String clubsWelcome(String name) {
    return 'Bienvenue dans $name !';
  }

  @override
  String get clubsChangeNotSaved =>
      'Impossible d’enregistrer cette modification.';

  @override
  String get clubsOptionsTooltip => 'Options du club';

  @override
  String get clubsMembers => 'Membres';

  @override
  String get clubsReportClub => 'Signaler le club';

  @override
  String get clubsDetailLoadErrorTitle => 'Impossible de charger ce club';

  @override
  String get clubsDetailLoadErrorMessage => 'Il a peut-être fermé. Réessaie.';

  @override
  String get clubsEarlierPicks => 'Sélections précédentes';

  @override
  String clubsPickSubtitle(String week, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$week · $_temp0';
  }

  @override
  String get clubsOpenDiscussion => 'Ouvrir la discussion';

  @override
  String get clubsJoinToSeeTitle => 'Rejoins le club pour voir la discussion';

  @override
  String get clubsJoinToSeeMessage =>
      'Les membres discutent ensemble de chaque sélection. Rejoins le club pour suivre et donner ton avis.';

  @override
  String clubsYouRole(String role) {
    return 'Toi : $role';
  }

  @override
  String get clubsRemovedByModeration =>
      'Ce club a été retiré par la modération.';

  @override
  String get clubsJoinClub => 'Rejoindre le club';

  @override
  String get clubsNoPickModerator =>
      'Pas encore de sélection. Choisis quelque chose de génial pour tout le monde.';

  @override
  String get clubsNoPickMember => 'Pas encore de sélection. Repasse bientôt.';

  @override
  String clubsQuotedNote(String note) {
    return '« $note »';
  }

  @override
  String clubsPostsInDiscussion(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages dans la discussion',
      one: '1 message dans la discussion',
    );
    return '$_temp0';
  }

  @override
  String get clubsSetThisWeeksPick => 'Choisir la sélection de la semaine';

  @override
  String get clubsDiscussThisPick => 'Discuter de cette sélection';

  @override
  String get clubsPostNotSent => 'Impossible d’envoyer ton message.';

  @override
  String clubsDiscussionHeading(String title) {
    return 'Discussion · $title';
  }

  @override
  String get clubsDiscussionLoadError => 'Impossible de charger la discussion';

  @override
  String get clubsStartConversationTitle => 'Lance la conversation';

  @override
  String get clubsStartConversationMessage =>
      'Qu’en penses-tu jusqu’ici ? Ton message pourrait lancer la discussion.';

  @override
  String get clubsLoadMorePosts => 'Charger plus de messages';

  @override
  String get clubsComposerLabel => 'Participer à la discussion';

  @override
  String get clubsComposerHint => 'Moment préféré ? Plus grosse surprise ?';

  @override
  String get clubsContainsSpoilers => 'Contient des spoilers';

  @override
  String get clubsSpoilersSubtitle => 'Les autres touchent pour l’afficher.';

  @override
  String get clubsPosting => 'Publication…';

  @override
  String get clubsPost => 'Publier';

  @override
  String get clubsDeletePostTitle => 'Supprimer ton message ?';

  @override
  String get clubsDeletePostMessage =>
      'Il sera retiré de la discussion pour tout le monde.';

  @override
  String get clubsActionFailed => 'Impossible de terminer cette action.';

  @override
  String get clubsHideFromMembers => 'Masquer aux membres';

  @override
  String get clubsShowToMembers => 'Afficher aux membres';

  @override
  String get clubsReport => 'Signaler';

  @override
  String get clubsYou => 'Toi';

  @override
  String get clubsHidden => 'Masqué';

  @override
  String get clubsPostActions => 'Actions sur le message';

  @override
  String get clubsMakeModerator => 'Nommer modérateur';

  @override
  String get clubsMakeMember => 'Repasser membre';

  @override
  String get clubsRemoveFromClub => 'Retirer du club';

  @override
  String clubsRemoveMemberTitle(String name) {
    return 'Retirer $name ?';
  }

  @override
  String get clubsRemoveMemberMessage =>
      'Cette personne quitte le club et ne pourra pas revenir. Ses anciens messages restent dans la discussion.';

  @override
  String get clubsRemove => 'Retirer';

  @override
  String get clubsMembersLoadError => 'Impossible de charger les membres.';

  @override
  String clubsMemberYou(String name) {
    return '$name (toi)';
  }

  @override
  String clubsMemberActions(String name) {
    return 'Actions pour $name';
  }

  @override
  String get clubsChooseFilm => 'Choisis un film';

  @override
  String get clubsChooseBook => 'Choisis un livre';

  @override
  String get clubsChooseTitle => 'Choisis un titre';

  @override
  String get clubsChooseTitleFirst => 'Choisis d’abord un titre.';

  @override
  String get clubsPickNotSaved => 'Impossible d’enregistrer la sélection.';

  @override
  String get clubsSetWeeklyPick => 'Choisir la sélection de la semaine';

  @override
  String get clubsChange => 'Changer';

  @override
  String get clubsPickNoteLabel => 'Un mot pour le club (facultatif)';

  @override
  String get clubsPickNoteHint => 'Pourquoi celui-ci ? Par où commencer ?';

  @override
  String get clubsSaving => 'Enregistrement…';

  @override
  String get clubsSavePick => 'Enregistrer la sélection';

  @override
  String get clubsListNameRequired => 'Donne un nom à ta liste.';

  @override
  String get clubsListNotSaved => 'Impossible d’enregistrer ta liste.';

  @override
  String get clubsEditList => 'Modifier la liste';

  @override
  String get clubsNewList => 'Nouvelle liste';

  @override
  String get clubsListNameLabel => 'Nom de la liste';

  @override
  String get clubsListNameHint => 'Les livres qui m’ont fait changer d’avis';

  @override
  String get clubsWhoCanSee => 'Qui peut le voir';

  @override
  String get clubsSave => 'Enregistrer';

  @override
  String get clubsCreateList => 'Créer la liste';

  @override
  String get clubsYourNote => 'Ta note';

  @override
  String get clubsNoteLabel => 'Pourquoi il est dans cette liste';

  @override
  String get clubsSaveNote => 'Enregistrer la note';

  @override
  String get clubsCreateNewListTooltip => 'Créer une nouvelle liste';

  @override
  String get clubsSignInToSeeLists => 'Connecte-toi pour voir tes listes.';

  @override
  String get clubsShelfTitle => 'Ton étagère';

  @override
  String get clubsShelfSubtitle =>
      'Garde une trace de ce que tu as adoré et de ce qui t’attend. Partage une liste ou garde-la pour toi.';

  @override
  String get clubsListsLoadErrorTitle => 'Impossible de charger tes listes';

  @override
  String get clubsFirstListTitle => 'Crée ta première liste';

  @override
  String get clubsFirstListMessage =>
      'Films préférés, livres à lire ensuite, films doudous à revoir : c’est toi qui choisis.';

  @override
  String clubsAddToNamed(String name) {
    return 'Ajouter à $name';
  }

  @override
  String get clubsAddToThisListFailed =>
      'Impossible de l’ajouter à cette liste.';

  @override
  String clubsDeleteListTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get clubsDeleteListMessage =>
      'La liste et ses notes seront supprimées. C’est irréversible.';

  @override
  String get clubsDeleteList => 'Supprimer la liste';

  @override
  String get clubsListDeleteFailed =>
      'Impossible de supprimer la liste. Recharge et réessaie.';

  @override
  String get clubsNoteNotSaved => 'Impossible d’enregistrer ta note.';

  @override
  String get clubsRemoveFailed => 'Impossible de le retirer.';

  @override
  String get clubsListOptions => 'Options de la liste';

  @override
  String get clubsAddATitle => 'Ajouter un titre';

  @override
  String clubsTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
    );
    return '$_temp0';
  }

  @override
  String get clubsListEmpty =>
      'Rien pour l’instant. Utilise « Ajouter un titre » dans le menu de la liste.';

  @override
  String clubsItemOptions(String title) {
    return 'Options pour $title';
  }

  @override
  String get clubsAddNote => 'Ajouter une note';

  @override
  String get clubsEditNote => 'Modifier la note';

  @override
  String get clubsRemoveFromList => 'Retirer de la liste';

  @override
  String get clubsTapStarError => 'Touche une étoile pour noter.';

  @override
  String get clubsReviewNotSaved => 'Impossible d’enregistrer ton avis.';

  @override
  String get clubsWriteReview => 'Écrire un avis';

  @override
  String get clubsEditYourReview => 'Modifier ton avis';

  @override
  String get clubsTapStarToRate => 'Touche une étoile pour noter';

  @override
  String clubsRatingOutOfFive(int rating) {
    return '$rating sur 5';
  }

  @override
  String get clubsReviewBodyLabel => 'Qu’en as-tu pensé ? (facultatif)';

  @override
  String get clubsSaveReview => 'Enregistrer l’avis';

  @override
  String clubsAddedToList(String name) {
    return 'Ajouté à $name.';
  }

  @override
  String get clubsAddToThatListFailed =>
      'Impossible de l’ajouter à cette liste.';

  @override
  String get clubsAddToAList => 'Ajouter à une liste';

  @override
  String get clubsListsLoadError => 'Impossible de charger tes listes.';

  @override
  String get clubsNoFilmLists =>
      'Tu n’as pas encore de liste de films. Crées-en une pour commencer ta collection.';

  @override
  String get clubsNoBookLists =>
      'Tu n’as pas encore de liste de livres. Crées-en une pour commencer ta collection.';

  @override
  String get clubsTitleFallback => 'Titre';

  @override
  String get clubsSignInToSeeReviews => 'Connecte-toi pour voir les avis.';

  @override
  String get clubsTitleLoadError => 'Impossible de charger ce titre';

  @override
  String get clubsReviews => 'Avis';

  @override
  String get clubsNoOtherReviewsTitle => 'Pas encore d’autres avis';

  @override
  String get clubsNoOtherReviewsMessage =>
      'Quand des membres que tu peux voir partagent un avis, il apparaît ici.';

  @override
  String get clubsDeleteReviewTitle => 'Supprimer ton avis ?';

  @override
  String get clubsDeleteReviewMessage =>
      'Ta note et ton texte seront supprimés pour tout le monde.';

  @override
  String get clubsDeleteReview => 'Supprimer l’avis';

  @override
  String get clubsReviewDeleteFailed =>
      'Impossible de supprimer ton avis. Recharge et réessaie.';

  @override
  String get clubsWhatDidYouThink => 'Qu’en as-tu pensé ?';

  @override
  String get clubsReviewPrompt =>
      'Note-le et explique pourquoi. Tu choisis qui peut le voir.';

  @override
  String get clubsYourReview => 'Ton avis';

  @override
  String get clubsSpoilers => 'Spoilers';

  @override
  String get clubsEdit => 'Modifier';

  @override
  String get clubsReportReview => 'Signaler cet avis';

  @override
  String get clubsEnterTitle => 'Saisis le titre.';

  @override
  String get clubsYearRange => 'Saisis une année entre 1450 et 2100.';

  @override
  String get clubsTitleAddFailed => 'Impossible d’ajouter le titre.';

  @override
  String get clubsSearchFilms => 'Rechercher des films';

  @override
  String get clubsSearchBooks => 'Rechercher des livres';

  @override
  String get clubsTypeTwoLetters => 'Saisis au moins 2 lettres';

  @override
  String get clubsSearchUnavailable => 'La recherche est indisponible.';

  @override
  String get clubsNoFilmsMatch =>
      'Aucun film ne correspond. Ajoute-le ci-dessous.';

  @override
  String get clubsNoBooksMatch =>
      'Aucun livre ne correspond. Ajoute-le ci-dessous.';

  @override
  String get clubsAddNewFilm => 'Ajouter un nouveau film';

  @override
  String get clubsAddNewBook => 'Ajouter un nouveau livre';

  @override
  String get clubsTitleFieldLabel => 'Titre';

  @override
  String get clubsDirector => 'Réalisation';

  @override
  String get clubsAuthor => 'Auteur';

  @override
  String get clubsYearOptional => 'Année (facultatif)';

  @override
  String get clubsAdding => 'Ajout…';

  @override
  String get clubsAddAndChoose => 'Ajouter et choisir';

  @override
  String get friendsIntroducerSaveFailed =>
      'Nous n’avons pas pu enregistrer. Actualise pour vérifier les dernières autorisations avant de réessayer.';

  @override
  String friendsIntroducerRevokeTitle(String name) {
    return 'Retirer l’autorisation de $name ?';
  }

  @override
  String get friendsIntroducerRevokeBody =>
      'Les présentations nouvelles ou sans réponse s’arrêtent. Un match mutuel existant reste entre les deux personnes.';

  @override
  String get friendsIntroducerKeepPermission => 'Garder l’autorisation';

  @override
  String get friendsIntroducerRemovePermission => 'Retirer l’autorisation';

  @override
  String get friendsIntroducerPermissionRemoved => 'Autorisation retirée.';

  @override
  String get friendsIntroducerMemberTitle => 'Tes entremetteurs';

  @override
  String get friendsIntroducerAppTitle => 'Connect · Amis';

  @override
  String get friendsIntroducerRefresh => 'Actualiser les autorisations';

  @override
  String get friendsIntroducerAccount => 'Compte';

  @override
  String get friendsIntroducerAccountPrivacy => 'Compte et confidentialité';

  @override
  String get friendsIntroducerSignOut => 'Se déconnecter';

  @override
  String get friendsIntroducerMemberHeadline =>
      'De bons amis. C’est toi qui décides.';

  @override
  String get friendsIntroducerHeadline =>
      'Tu les connais.\nTu vois ce qui pourrait naître.';

  @override
  String get friendsIntroducerMemberIntro =>
      'Invite une personne de confiance à te présenter. Elle peut rejoindre l’app sans profil de rencontre. Tu décides qui obtient l’autorisation et ce qu’un aperçu montre.';

  @override
  String get friendsIntroducerIntro =>
      'Un peu d’attention peut faire naître quelque chose de vrai. Rapproche des amis qui t’ont demandé un coup de main.';

  @override
  String get friendsIntroducerMemberListTitle => 'Les personnes que tu choisis';

  @override
  String get friendsIntroducerListTitle => 'Ton petit cercle';

  @override
  String get friendsIntroducerLoadFailed =>
      'Nous n’avons pas pu charger les autorisations. Rien n’a été modifié.';

  @override
  String get friendsIntroducerMemberEmpty =>
      'Pas encore d’entremetteur. Partage une invitation avec un ami de confiance pour commencer.';

  @override
  String get friendsIntroducerEmpty =>
      'Ton cercle commence par une autorisation. Demande son code d’invitation à un ami sur Connect.';

  @override
  String get friendsIntroducerStatusPendingMember =>
      'Demande ton autorisation pour te présenter.';

  @override
  String get friendsIntroducerStatusPending =>
      'En attente de l’accord de ton ami.';

  @override
  String get friendsIntroducerStatusPaused =>
      'Les présentations sont en pause.';

  @override
  String get friendsIntroducerStatusActive =>
      'Autorisé à proposer des présentations.';

  @override
  String friendsIntroducerPreview(String extras) {
    String _temp0 = intl.Intl.selectLogic(extras, {
      'photo':
          'Aperçu partagé avec une personne suggérée : prénom et âge facultatif, photo.',
      'city':
          'Aperçu partagé avec une personne suggérée : prénom et âge facultatif, ville.',
      'both':
          'Aperçu partagé avec une personne suggérée : prénom et âge facultatif, photo, ville.',
      'other':
          'Aperçu partagé avec une personne suggérée : prénom et âge facultatif.',
    });
    return '$_temp0';
  }

  @override
  String get friendsIntroducerApproveNote =>
      'Approuver active aussi les présentations par des amis. Tu peux mettre toutes les présentations en pause dans Rythme des rencontres.';

  @override
  String get friendsIntroducerAllow => 'Autoriser les présentations';

  @override
  String friendsIntroducerAllowed(String name) {
    return '$name a maintenant ton autorisation.';
  }

  @override
  String get friendsIntroducerDecline => 'Refuser la demande';

  @override
  String get friendsIntroducerSentTitle => 'Envoyées avec soin';

  @override
  String get friendsIntroducerSentBody =>
      'Leurs réponses restent entre eux. Les deux doivent dire oui pour qu’il y ait un match.';

  @override
  String get friendsIntroducerReloadSent =>
      'Recharger les présentations envoyées';

  @override
  String get friendsIntroducerSentSubtitle =>
      'Envoyée · leur décision est privée';

  @override
  String get friendsIntroducerStepPreview => '1. Choisis l’aperçu';

  @override
  String get friendsIntroducerPreviewBody =>
      'Une personne suggérée voit ton prénom et ton âge si tu l’affiches déjà. Ton entremetteur ne voit que ton prénom, jamais ton profil ni ton activité de rencontre.';

  @override
  String get friendsIntroducerIncludePhoto => 'Inclure ma photo de profil';

  @override
  String get friendsIntroducerIncludeCity => 'Inclure ma ville';

  @override
  String get friendsIntroducerStepInvite => '2. Invite un ami de confiance';

  @override
  String get friendsIntroducerInviteBody =>
      'Le code ne fonctionne qu’une fois et expire au bout de 48 heures. Ton ami rejoint l’app via « Juste là pour présenter des amis » sur l’écran d’accueil. Tu approuveras son nom ici avant que quoi que ce soit soit partagé.';

  @override
  String get friendsIntroducerInviteReady =>
      'Invitation prête. Tout code précédent non utilisé ne fonctionne plus.';

  @override
  String get friendsIntroducerCreateCode => 'Créer un code d’invitation';

  @override
  String get friendsIntroducerShareCode =>
      'Partage-le en privé avec ton ami. Pour modifier cet aperçu, annule l’invitation non utilisée et crée un nouveau code.';

  @override
  String get friendsIntroducerCodeCopied => 'Code d’invitation copié';

  @override
  String get friendsIntroducerCopyCode => 'Copier le code';

  @override
  String get friendsIntroducerInvitesCancelled =>
      'Invitations non utilisées annulées.';

  @override
  String get friendsIntroducerCancelInvites =>
      'Annuler les invitations non utilisées';

  @override
  String get friendsIntroducerManagePrefs =>
      'Gérer toutes les préférences de présentation';

  @override
  String get friendsIntroducerRedeemTitle => 'Un ami t’a invité ?';

  @override
  String get friendsIntroducerRedeemBody =>
      'Colle son code d’invitation privé. Ton ami confirmera ton nom avant que tu puisses le présenter.';

  @override
  String get friendsIntroducerCodeLabel => 'Code d’invitation';

  @override
  String get friendsIntroducerCodeMissing =>
      'Saisis le code d’invitation que ton ami t’a envoyé.';

  @override
  String get friendsIntroducerRequestSent =>
      'Demande envoyée. Ton ami peut maintenant t’approuver dans « Tes entremetteurs ».';

  @override
  String get friendsIntroducerAskPermission => 'Demander l’autorisation';

  @override
  String get friendsIntroducerNeedTwo =>
      'Dès que deux amis t’auront donné leur autorisation, tu pourras proposer une présentation ici.';

  @override
  String get friendsIntroducerComposerTitle => 'Tu vois une possibilité ?';

  @override
  String get friendsIntroducerWhyLabel =>
      'Pourquoi tu as pensé à eux (facultatif)';

  @override
  String get friendsIntroducerWhyHelper =>
      'Les deux le verront. Évite les détails privés.';

  @override
  String get friendsIntroducerIntroSent =>
      'Présentation envoyée. Chacun peut décider en privé.';

  @override
  String get friendsIntroducerSuggest => 'Proposer une présentation';

  @override
  String get friendsIntroducerPrivacyNote =>
      'L’autorisation d’abord. Aucune activité de rencontre publique. Aucune info sur qui a dit oui ou non.';

  @override
  String get planSharingLoadFailed =>
      'Impossible de charger les options de partage.';

  @override
  String get planSharingOffSnack =>
      'Le partage avec tes contacts est désactivé.';

  @override
  String get planSharingSavedSnack =>
      'Les contacts choisis peuvent maintenant voir ce plan.';

  @override
  String get planSharingSaveFailed =>
      'Impossible d\'enregistrer. Recharge les choix avant de réessayer.';

  @override
  String get planSharingTitle => 'Ton plan. Tes proches.';

  @override
  String get planSharingCloseTooltip => 'Fermer le partage';

  @override
  String get planSharingIntro =>
      'Le partage avec tes contacts est désactivé au départ. Choisis jusqu\'à 10 amis de confiance pour ce plan. L\'autre personne choisit ses propres contacts.';

  @override
  String get planSharingNoContacts =>
      'Aucun ami éligible pour l\'instant. Ton plan reste accessible à toi et à l\'autre personne.';

  @override
  String get planSharingFriendFallback => 'Un ami';

  @override
  String get planSharingPreviewNone => 'Aperçu · aucun contact sélectionné';

  @override
  String planSharingPreviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aperçu · $count sélectionnés',
      one: 'Aperçu · $count sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get planSharingPreviewOffBody =>
      'Tes amis ne recevront aucune mise à jour de ton plan ni de tes check-ins.';

  @override
  String get planSharingPreviewOnBody =>
      'Ces contacts voient le prénom de l\'autre personne, l\'heure et le lieu, le statut du plan et tes check-ins. Ils reçoivent le plan actuel quand tu enregistres.';

  @override
  String get planSharingPrivacyNote =>
      'Les messages et ton avis privé après le rendez-vous restent privés. Retirer un contact arrête les prochaines mises à jour et lui retire l\'accès au plan dans l\'app. Les mises à jour déjà reçues sur un appareil ne peuvent pas être rappelées.';

  @override
  String get planSharingReload => 'Recharger les options de partage';

  @override
  String get planSharingSaving => 'Enregistrement…';

  @override
  String get planSharingKeepOff => 'Garder le partage désactivé';

  @override
  String get planSharingShareSelected => 'Partager avec les contacts choisis';

  @override
  String get planSharingDeselectAll => 'Tout désélectionner';

  @override
  String planBudgetLine(String budget) {
    return 'Budget · $budget';
  }

  @override
  String planAtmosphereLine(String atmospheres) {
    return 'Ambiance · $atmospheres';
  }

  @override
  String get planAtmosphereQuiet => 'Une conversation au calme';

  @override
  String get planAtmosphereRelaxed => 'Détendu et sans se presser';

  @override
  String get planAtmosphereLively => 'Un endroit animé';

  @override
  String get planAtmosphereOutdoors => 'En plein air';

  @override
  String get planAtmosphereIndoors => 'En intérieur';

  @override
  String get planAccessStepFree => 'Accès sans marche';

  @override
  String get planAccessToilet => 'Toilettes accessibles';

  @override
  String get planAccessSeating => 'Places assises disponibles';

  @override
  String get planAccessLowNoise => 'Peu de bruit ambiant';

  @override
  String get planAccessTransit => 'Près des transports en commun';

  @override
  String get planAccessCaptions => 'Sous-titres pour un rendez-vous vidéo';

  @override
  String get planComfortHeading => 'Pour que ce soit confortable';

  @override
  String get planPreferencesDisclaimer =>
      'Préférences partagées pour ce plan. Vérifie ces détails auprès du lieu ou du service vidéo.';

  @override
  String get planProposeErrorKept =>
      'Ton plan n\'a pas pu être envoyé. Tes choix sont toujours là.';

  @override
  String get planChangedError =>
      'Ce plan a changé. Ferme ce volet pour revoir la conversation.';

  @override
  String get planProposeHeadline =>
      'Un plan qui vous fait envie à tous les deux.';

  @override
  String get planCounterHeadline => 'Construisez ce plan ensemble';

  @override
  String planProposeLead(String name) {
    return 'Une proposition pour toi et $name. Rien n\'est décidé tant que l\'autre personne n\'a pas accepté cette version.';
  }

  @override
  String get planFindTimeTitle => 'Trouver un moment ensemble';

  @override
  String get planFindTimeBody =>
      'Seuls les créneaux communs s\'affichent, si vous partagez tous les deux vos disponibilités. Tu peux toujours proposer une heure toi-même.';

  @override
  String get planSharedTimesFailed =>
      'Impossible de charger les créneaux communs. Tu peux toujours choisir une heure toi-même.';

  @override
  String get planSharedTimesEmpty =>
      'Aucun créneau commun suggéré pour l\'instant. Ça ne veut pas dire que l\'un de vous n\'est pas disponible.';

  @override
  String get planRefreshSharedTimes => 'Actualiser les créneaux communs';

  @override
  String get planSetAvailability => 'Indiquer mes disponibilités';

  @override
  String get planWhenTitle => 'Quel moment te conviendrait ?';

  @override
  String get planTimeSourceManual => 'Une heure que tu proposes';

  @override
  String get planTimeSourceShared =>
      'Choisi parmi les disponibilités communes · revérifié à l\'envoi';

  @override
  String planLocalTimeNote(int minutes, String timeZone) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Heure locale de ton appareil ($timeZone). Durée : $minutes minutes.',
      one: 'Heure locale de ton appareil ($timeZone). Durée : $minutes minute.',
    );
    return '$_temp0';
  }

  @override
  String planDurationChip(int minutes) {
    return '$minutes min';
  }

  @override
  String get planEnjoyTitle => 'Quelque chose qui te plairait';

  @override
  String get planAreaHint => 'Un quartier ou un lieu de rendez-vous public';

  @override
  String get planBudgetTitle => 'Quel budget te convient ?';

  @override
  String get planBudgetBody =>
      'Un point de départ à décider ensemble, pas un devis ni une promesse sur qui paie.';

  @override
  String get planAtmosphereTitle => 'Choisir l\'ambiance';

  @override
  String get planAtmosphereBody =>
      'Choisis jusqu\'à trois ambiances qui te plairaient. Facultatif.';

  @override
  String get planComfortTitle => 'Pour que ce soit confortable pour vous deux';

  @override
  String get planComfortBody =>
      'Préférences d\'accessibilité facultatives. Tes choix sont partagés avec ton match quand tu envoies ce plan. Ils ne sont ajoutés ni à ton profil public ni aux mises à jour de tes contacts de confiance.';

  @override
  String get planComfortDisclaimer =>
      'Tu n\'as pas à expliquer de diagnostic. Ce sont des demandes à vérifier auprès du lieu ou du service vidéo, pas des équipements vérifiés.';

  @override
  String get planNoteHint => 'Samedi après-midi, dans un coin plus calme ?';

  @override
  String get planReviewBeforeSending =>
      'Avant d\'envoyer, vérifie l\'heure et tes choix ci-dessus. L\'autre personne peut accepter, refuser ou proposer un changement.';

  @override
  String get planReloadLatest =>
      'Recharger le dernier plan · annuler les modifications';

  @override
  String get planSending => 'Envoi…';

  @override
  String get planSendSuggestion => 'Envoyer ta proposition';

  @override
  String get planSecondYesTitle => 'Partager un second oui';

  @override
  String get planSecondYesBody =>
      'Indique que tu aimerais un nouveau rendez-vous, seulement si ton match dit oui aussi et accepte de le partager. Tes autres réponses restent privées.';

  @override
  String get planSecondYesHeadline => 'Un second oui, de vous deux';

  @override
  String get planSecondYesCardBody =>
      'Vous avez tous les deux choisi de dire que vous aimeriez vous revoir.';

  @override
  String get planAnotherHello => 'Prévoir un autre rendez-vous';

  @override
  String get planSuggestChange => 'Proposer un changement';

  @override
  String get planChooseUpdates => 'Choisir qui reçoit tes mises à jour';

  @override
  String planQuotedNote(String note) {
    return '« $note »';
  }

  @override
  String get planStatusDeclined => 'Refusé';

  @override
  String get planStatusExpired => 'Expiré';

  @override
  String get planStatusCompleted => 'Terminé';

  @override
  String get planStatusDidNotHappen => 'N\'a pas eu lieu';

  @override
  String get planStatusDisputed => 'Contesté';

  @override
  String get plansManageSharing => 'Gérer le partage avec tes contacts';

  @override
  String get plansLoadFailed =>
      'Impossible de charger les plans de rendez-vous.';

  @override
  String get plansFeedLoadFailed => 'Impossible de charger les plans.';

  @override
  String get planAcceptFailed => 'Impossible d\'accepter ce plan.';

  @override
  String get planDeclineFailed => 'Impossible de refuser ce plan.';

  @override
  String get planCancelFailed => 'Impossible d\'annuler ce plan.';

  @override
  String get planCheckinFailed =>
      'Impossible de faire ton check-in pour le moment.';

  @override
  String get graduationFoundEachOther => 'Vous vous êtes trouvés';

  @override
  String graduationHeadlineDecide(String name) {
    return '$name veut quitter Connect avec toi';
  }

  @override
  String graduationHeadlineWaiting(String name) {
    return 'En attente de $name';
  }

  @override
  String get graduationBodyConfirmed =>
      'Vous êtes tous les deux masqués dans Découvrir. Cette discussion reste ouverte.';

  @override
  String get graduationBodyDecide =>
      'Confirme et vous quittez tous les deux Découvrir. Votre discussion reste.';

  @override
  String get graduationBodyWaiting =>
      'Tu as proposé de partir ensemble. L\'autre personne peut confirmer ou refuser.';

  @override
  String get graduationCelebrate => 'Célébrer';

  @override
  String get graduationNotYet => 'Pas encore';

  @override
  String get graduationConfirm => 'Confirmer';

  @override
  String get graduationFriendsToldOnConfirm =>
      'Tes amis seront prévenus dès que l\'autre personne aura confirmé.';

  @override
  String get graduationOnlyTwoOfYouForNow =>
      'Pour l\'instant, vous êtes les seuls à savoir.';

  @override
  String get graduationWithdraw => 'Retirer';

  @override
  String graduationProposeTitle(String name) {
    return 'Quitter Connect avec $name ?';
  }

  @override
  String graduationProposeBody(String name) {
    return 'Dès que $name confirme, vous êtes tous les deux masqués dans Découvrir. Cette discussion reste ouverte, et tu peux revenir dans Découvrir à tout moment depuis Confidentialité et sécurité.';
  }

  @override
  String get graduationNoteLabel => 'Un mot pour l\'autre (facultatif)';

  @override
  String get graduationNoteHint => 'Explique pourquoi c\'est le bon moment';

  @override
  String get graduationTellFriends => 'Prévenir mes amis';

  @override
  String get graduationTellFriendsBody =>
      'Tes amis confirmés apprennent que tu as trouvé quelqu\'un, sans savoir qui.';

  @override
  String get graduationAskThem => 'Lui demander';

  @override
  String get graduationTitle => 'Départ à deux';

  @override
  String graduationCelebrationBody(String name) {
    return 'Toi et $name quittez Connect ensemble. Vous êtes tous les deux masqués dans Découvrir, et cette discussion reste ouverte aussi longtemps que vous le souhaitez.';
  }

  @override
  String get graduationFriendsHaveBeenTold => 'Tes amis ont été prévenus.';

  @override
  String get graduationFriendsAreTold => 'Tes amis sont prévenus.';

  @override
  String get graduationOnlyTwoOfYou => 'Vous êtes les seuls à savoir.';

  @override
  String get graduationConfirmAndBack => 'Confirmer et revenir';

  @override
  String get graduationBackToConnect => 'Retour à Connect';

  @override
  String get graduationLoadFailed => 'Impossible de charger le départ à deux.';

  @override
  String get graduationProposeFailed =>
      'Impossible de proposer de partir ensemble.';

  @override
  String get graduationConfirmFailed =>
      'Impossible de confirmer pour le moment.';

  @override
  String get graduationDeclineFailed => 'Impossible de refuser pour le moment.';

  @override
  String get graduationWithdrawFailed =>
      'Impossible de retirer la proposition.';

  @override
  String get graduationPauseLoadFailed =>
      'Impossible de charger ton statut dans Découvrir.';

  @override
  String get graduationPauseFailed =>
      'Impossible de mettre Découvrir en pause.';

  @override
  String get graduationResumeFailed => 'Impossible de réactiver Découvrir.';

  @override
  String get engagementCirclesEmptyTitle => 'Aucun cercle disponible';

  @override
  String get engagementCirclesPullToRefresh =>
      'Tire vers le bas pour actualiser.';

  @override
  String get engagementCirclesJoined => 'Membre';

  @override
  String get engagementCirclesNotJoined => 'Pas membre';

  @override
  String engagementCirclesParticipants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participants cette semaine',
      one: '1 participant cette semaine',
      zero: '0 participant cette semaine',
    );
    return '$_temp0';
  }

  @override
  String get engagementCirclesJoin => 'Rejoindre le cercle';

  @override
  String get engagementCirclesResponseLabel =>
      'Ta réponse au défi de la semaine';

  @override
  String get engagementCirclesSubmit => 'Envoyer ma participation';

  @override
  String get engagementCirclesTopicFallback => 'Cercle';

  @override
  String get engagementCirclesLoadFailed =>
      'Impossible de charger les cercles pour le moment.';

  @override
  String get engagementCirclesJoinFailed =>
      'Impossible de rejoindre le cercle pour le moment.';

  @override
  String get engagementCirclesEnterResponse => 'Écris ta réponse au défi.';

  @override
  String get engagementCirclesSubmitFailed =>
      'Impossible d’envoyer ta participation pour le moment.';

  @override
  String get engagementNudgesTitle => 'Coups de pouce';

  @override
  String get engagementNudgesIntro =>
      'Envoie un petit rappel pour relancer une conversation au point mort. Les limites quotidiennes et les règles de sécurité sont appliquées par le serveur.';

  @override
  String get engagementNudgesEmpty => 'Aucun match à relancer.';

  @override
  String get engagementNudgesSentInSession =>
      'Coup de pouce envoyé pendant cette session';

  @override
  String get engagementNudgesReady => 'Prêt à envoyer';

  @override
  String engagementNudgesSentTo(String name) {
    return 'Coup de pouce envoyé à $name.';
  }

  @override
  String get engagementNudgesAction => 'Relancer';

  @override
  String get engagementNudgesSendFailed =>
      'Impossible d’envoyer ce coup de pouce.';

  @override
  String get engagementTrustBadgesEarned => 'Badges obtenus';

  @override
  String get engagementTrustBadgesEmpty =>
      'Pas encore de badge. Termine des activités pour débloquer des badges de confiance.';

  @override
  String engagementTrustBadgesDetails(
    String code,
    String status,
    String awardedAt,
  ) {
    return 'Code : $code\nStatut : $status • Obtenu le $awardedAt';
  }

  @override
  String get engagementTrustBadgesHistory => 'Historique récent';

  @override
  String get engagementTrustBadgesHistoryEmpty =>
      'Pas encore d’historique de confiance.';

  @override
  String get engagementTrustBadgesMilestoneUnavailable =>
      'État du palier indisponible.';

  @override
  String get engagementTrustBadgesCurrentMilestone => 'Palier actuel';

  @override
  String get engagementTrustBadgesLoadFailed =>
      'Impossible de charger les badges de confiance. Réessaie.';

  @override
  String get engagementTrustFiltersEnable => 'Activer les filtres de confiance';

  @override
  String get engagementTrustFiltersEnableSubtitle =>
      'Masquer les profils qui ne remplissent pas tes critères de confiance';

  @override
  String engagementTrustFiltersMinimum(int count) {
    return 'Nombre minimum de badges actifs : $count';
  }

  @override
  String get engagementTrustFiltersRequired => 'Badges requis';

  @override
  String get engagementTrustFiltersSaved => 'Filtres de confiance enregistrés.';

  @override
  String get engagementTrustFiltersSave =>
      'Enregistrer les filtres de confiance';

  @override
  String get engagementAppealStatusSubmitted => 'Envoyé';

  @override
  String get engagementAppealStatusUnderReview => 'En cours d’examen';

  @override
  String get engagementAppealStatusResolvedUpheld =>
      'Traité (décision maintenue)';

  @override
  String get engagementAppealStatusResolvedReversed =>
      'Traité (décision annulée)';

  @override
  String get engagementRoomsLeaveFailed =>
      'Impossible de quitter ce salon. Réessaie.';

  @override
  String get engagementRoomsPresenceFailed => 'Connexion au salon perdue.';

  @override
  String get engagementRoomsMembersFailed =>
      'Impossible de charger les personnes présentes. Réessaie.';

  @override
  String get engagementRoomsModerationFailed =>
      'Ça n’a pas fonctionné. Réessaie.';

  @override
  String get engagementRoomsCreateFailed =>
      'Impossible de lancer le salon. Réessaie.';

  @override
  String get engagementRoomsLoadFailed =>
      'Les salons sont indisponibles pour le moment. Tire pour réessayer.';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonRemove => 'Retirer';

  @override
  String get accountTitle => 'Compte et données';

  @override
  String get accountLoadFailed => 'Impossible de charger l’état de ton compte.';

  @override
  String accountDeletionIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Suppression dans $days jours',
      one: 'Suppression dans 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get accountDeletionDue => 'La suppression est imminente';

  @override
  String get accountDeletionCountdownBody =>
      'Ton profil est masqué. Tu peux encore te connecter et annuler d’ici là — ensuite, tes données ne pourront plus être récupérées.';

  @override
  String get accountKeepMyAccount => 'Garder mon compte';

  @override
  String get accountNotDeletedSnack => 'Ton compte ne sera pas supprimé.';

  @override
  String get accountCancelFailed => 'Impossible d’annuler. Réessaie.';

  @override
  String get accountHiddenTitle => 'Ton profil est masqué';

  @override
  String get accountTakeBreakTitle => 'Fais une pause';

  @override
  String get accountHiddenBody =>
      'Personne ne peut te voir ni matcher avec toi. Tes matchs et messages sont conservés et tu peux revenir quand tu veux.';

  @override
  String get accountTakeBreakBody =>
      'Masque ton profil dans Découvrir sans rien perdre. Tu restes connecté(e) et peux revenir en arrière à tout moment.';

  @override
  String get accountUnhideProfile => 'Réafficher mon profil';

  @override
  String get accountHideProfile => 'Masquer mon profil';

  @override
  String get accountVisibleAgainSnack => 'Ton profil est de nouveau visible.';

  @override
  String get accountNowHiddenSnack => 'Ton profil est maintenant masqué.';

  @override
  String get accountUpdateFailed => 'Mise à jour impossible. Réessaie.';

  @override
  String get accountDownloadTitle => 'Télécharger tes données';

  @override
  String get accountDownloadBody =>
      'Obtiens une copie de ton profil, de tes préférences, de tes matchs et des messages que tu as envoyés. Les messages écrits par d’autres ne sont pas inclus.';

  @override
  String get accountPreparing => 'Préparation…';

  @override
  String get accountPrepareData => 'Préparer mes données';

  @override
  String get accountPrepareFailed =>
      'Impossible de préparer tes données. Réessaie.';

  @override
  String get accountYourData => 'Tes données';

  @override
  String get accountDeleteTitle => 'Supprimer mon compte';

  @override
  String get accountDeleteBody =>
      'Ton profil est masqué immédiatement et tout est effacé après un délai de grâce. Tu peux annuler pendant ce délai en te connectant. Ensuite, rien ne pourra être récupéré.';

  @override
  String get accountDeletionAlreadyScheduled => 'Suppression déjà programmée';

  @override
  String get accountDeleteConfirmTitle => 'Supprimer ton compte ?';

  @override
  String get accountDeleteConfirmBody =>
      'Ton profil, tes photos, tes matchs et tes messages seront effacés et ne pourront pas être récupérés.\n\nSi tu veux juste faire une pause, masquer ton profil conserve tout et peut être annulé.';

  @override
  String get accountHideInstead => 'Masquer plutôt';

  @override
  String get accountDeletionScheduledSnack =>
      'Suppression programmée. Tu peux annuler d’ici là.';

  @override
  String get privacyTitle => 'Confidentialité et sécurité';

  @override
  String get privacyShowAge => 'Afficher l’âge';

  @override
  String get privacyShowAgeSubtitle => 'Choisis si ton âge est visible';

  @override
  String get privacyShowDistance => 'Afficher la distance exacte';

  @override
  String get privacyShowDistanceSubtitle =>
      'Affiche la distance précise sur ton profil';

  @override
  String get privacyShowOnline => 'Afficher le statut en ligne';

  @override
  String get privacyShowOnlineSubtitle =>
      'Permettre aux autres de voir si tu es en ligne';

  @override
  String get privacyEmergencySos => 'SOS d’urgence';

  @override
  String get privacyEmergencySosSubtitle =>
      'Déclencher une alerte et consulter l’historique';

  @override
  String get privacyEmergencyContacts => 'Contacts d’urgence';

  @override
  String get privacyEmergencyContactsSubtitle =>
      'Gérer tes contacts d’urgence de confiance';

  @override
  String get privacyBlockedUsers => 'Utilisateurs bloqués';

  @override
  String get privacyBlockedUsersSubtitle =>
      'Consulter et débloquer des utilisateurs';

  @override
  String get privacyModerationAppeals => 'Recours de modération';

  @override
  String get privacyModerationAppealsSubtitle =>
      'Soumettre un recours et suivre son examen';

  @override
  String get privacyFriendSearch =>
      'Me laisser trouver dans la recherche d’amis';

  @override
  String get privacySettingLoadFailed =>
      'Ce réglage n’a pas pu être chargé. Rouvre cette page pour réessayer.';

  @override
  String get privacyFriendSearchSubtitle =>
      'Les membres peuvent te trouver par ton nom ou ton @pseudo dans Ajouter un ami. Les personnes avec qui tu matches ou que tu croises dans les salons et groupes peuvent toujours t’ajouter.';

  @override
  String get privacyChoiceSaveFailed => 'Ton choix n’a pas pu être enregistré.';

  @override
  String get privacyShowcase => 'Afficher mes écrits publics sur mon profil';

  @override
  String get privacyShowcaseSubtitle =>
      'Les membres voient sur ton profil les chapitres que tu partages avec la communauté et tes photos sur le mur. Les chapitres privés ou réservés aux amis n’apparaissent jamais.';

  @override
  String get privacyCrashReports => 'Partager les rapports de plantage';

  @override
  String get privacyCrashReportsSubtitle =>
      'Les rapports anonymes de plantage et d’erreur nous aident à corriger les problèmes. Aucun message, photo ni détail de compte n’est inclus.';

  @override
  String get privacyGraduatedReason =>
      'Tu as quitté Connect avec ton match. Ta carte n’est montrée à personne.';

  @override
  String get privacyPausedReason =>
      'Ta carte n’est montrée à personne tant que tu ne reprends pas.';

  @override
  String get privacyActiveReason =>
      'Tu es visible par les autres membres dans Découvrir.';

  @override
  String get privacyDiscoveryPaused => 'Découverte en pause';

  @override
  String get privacyDiscoveryActive => 'Découverte active';

  @override
  String get privacyResume => 'Reprendre';

  @override
  String get privacyPause => 'Mettre en pause';

  @override
  String get emergencyIntro =>
      'Ajoute jusqu’à 3 contacts de confiance. Ils serviront plus tard aux procédures de sécurité et aux fonctions SOS.';

  @override
  String get emergencyEmpty => 'Aucun contact d’urgence ajouté pour l’instant.';

  @override
  String get emergencyMaxReached => 'Nombre maximal de contacts atteint';

  @override
  String get emergencyAddContact => 'Ajouter un contact';

  @override
  String get emergencyEditContact => 'Modifier le contact';

  @override
  String get emergencyInvalidInput =>
      'Saisis un nom et un numéro de téléphone valides.';

  @override
  String get emergencyAdded => 'Contact d’urgence ajouté.';

  @override
  String get emergencyAddFailed => 'Impossible d’ajouter le contact. Réessaie.';

  @override
  String get emergencyUpdated => 'Contact d’urgence mis à jour.';

  @override
  String get emergencyUpdateFailed =>
      'Impossible de mettre à jour le contact. Réessaie.';

  @override
  String get emergencyRemoveTitle => 'Retirer le contact';

  @override
  String emergencyRemoveBody(String name) {
    return 'Retirer $name de tes contacts d’urgence ?';
  }

  @override
  String get emergencyRemoved => 'Contact d’urgence retiré.';

  @override
  String get emergencyRemoveFailed =>
      'Impossible de retirer le contact. Réessaie.';

  @override
  String get emergencyNameLabel => 'Nom';

  @override
  String get emergencyPhoneLabel => 'Numéro de téléphone';

  @override
  String get appealsSubmitTitle => 'Soumettre un recours';

  @override
  String get appealsReasonLabel => 'Motif';

  @override
  String get appealsReasonHint =>
      'Pourquoi cette décision de modération devrait-elle être réexaminée ?';

  @override
  String get appealsReportIdLabel => 'ID du signalement (facultatif)';

  @override
  String get appealsContextLabel => 'Contexte supplémentaire (facultatif)';

  @override
  String get appealsSubmit => 'Envoyer le recours';

  @override
  String get appealsEmpty =>
      'Aucun recours soumis pour l’instant. Tes recours apparaîtront ici avec leur statut.';

  @override
  String appealsIdLine(String id) {
    return 'ID du recours : $id';
  }

  @override
  String appealsSlaLine(String deadline) {
    return 'Délai de traitement : $deadline';
  }

  @override
  String appealsReviewedBy(String reviewer) {
    return 'Examiné par : $reviewer';
  }

  @override
  String get appealsReasonRequired => 'Le motif est obligatoire.';

  @override
  String get appealsSubmitted => 'Recours envoyé.';

  @override
  String get appealsSubmitFailed =>
      'Impossible d’envoyer le recours. Réessaie.';

  @override
  String get blockedEmpty => 'Tu n’as bloqué personne.';

  @override
  String get blockedUnblock => 'Débloquer';

  @override
  String get blockedUnblockTitle => 'Débloquer l’utilisateur';

  @override
  String blockedUnblockBody(String name) {
    return 'Débloquer $name ?';
  }

  @override
  String blockedUnblockedSnack(String name) {
    return '$name a été débloqué(e).';
  }

  @override
  String get blockedUnblockFailed => 'Impossible de débloquer. Réessaie.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutDescription =>
      'Une app de rencontre axée sur la confiance : profils authentiques, échanges sûrs et relations sérieuses.';

  @override
  String get aboutStack => 'Technologies';

  @override
  String get aboutStackFlutter => 'Flutter (Android d’abord)';

  @override
  String get aboutStackGo => 'Services Go + PostgreSQL natif';

  @override
  String get aboutStackRiverpod => 'Gestion d’état avec Riverpod';

  @override
  String get communitySpoiler => 'Spoiler — touche pour afficher';

  @override
  String get communityReportFailed => 'Le signalement n’a pas pu être envoyé.';

  @override
  String get communityReportSubmitted => 'Signalement envoyé. Merci.';

  @override
  String communityBlockTitle(String name) {
    return 'Bloquer $name ?';
  }

  @override
  String get communityBlockBody =>
      'Vous ne verrez plus les photos, publications de club, avis et listes l’un de l’autre. Cela bloque aussi tout contact via Connect.';

  @override
  String get communityBlockAction => 'Bloquer le membre';

  @override
  String get communityBlockFailed =>
      'Impossible de bloquer ce membre. Réessaie.';

  @override
  String get reportSheetTitle => 'Signaler';

  @override
  String get reportReasonHarassment => 'Harcèlement';

  @override
  String get reportReasonInappropriate => 'Contenu inapproprié';

  @override
  String get reportReasonFraud => 'Fraude / arnaque';

  @override
  String get reportReasonFake => 'Faux profil';

  @override
  String get reportReasonLabel => 'Motif';

  @override
  String get reportDescriptionLabel => 'Description (facultatif)';

  @override
  String get reportDescriptionHint =>
      'Ajoute du contexte pour aider à examiner ton signalement';

  @override
  String get reportSubmitFailed =>
      'Impossible d’envoyer le signalement. Réessaie.';

  @override
  String get reportSubmit => 'Envoyer le signalement';

  @override
  String get membershipTitle => 'Abonnement';

  @override
  String get membershipChooseYourPlan => 'Choisis ton forfait';

  @override
  String get membershipCycleNoteMonthly =>
      'Paiement par carte. Renouvelé automatiquement chaque mois jusqu\'à ce que tu le désactives.';

  @override
  String get membershipCycleNoteYearly =>
      'Paiement par carte. Renouvelé automatiquement chaque année jusqu\'à ce que tu le désactives.';

  @override
  String get membershipNoPlansOnSale =>
      'Aucun forfait n\'est disponible pour le moment.';

  @override
  String get membershipPaymentsTitle => 'Paiements';

  @override
  String get membershipNoCardPayments =>
      'Aucun paiement par carte pour l\'instant.';

  @override
  String get membershipFooterNote =>
      'Ton forfait se renouvelle automatiquement à la fin de chaque période de facturation. Tu peux désactiver le renouvellement automatique à tout moment ; tu conserves tes avantages jusqu\'à la fin de la période. Les données de carte sont traitées par le prestataire de paiement et ne sont jamais enregistrées dans l\'app.';

  @override
  String membershipSwitchTitle(String plan) {
    return 'Passer à $plan ?';
  }

  @override
  String membershipSwitchUpgradeBodyMonthly(String price) {
    return 'Ta carte est débitée maintenant de la différence pour le reste de cette période, puis de $price par mois à partir du prochain renouvellement.';
  }

  @override
  String membershipSwitchUpgradeBodyYearly(String price) {
    return 'Ta carte est débitée maintenant de la différence pour le reste de cette période, puis de $price par an à partir du prochain renouvellement.';
  }

  @override
  String membershipSwitchDowngradeBodyMonthly(
    String currentPlan,
    String price,
  ) {
    return 'Ton forfait change maintenant. Le temps non utilisé sur $currentPlan est crédité sur ton prochain renouvellement, puis tu paies $price par mois.';
  }

  @override
  String membershipSwitchDowngradeBodyYearly(String currentPlan, String price) {
    return 'Ton forfait change maintenant. Le temps non utilisé sur $currentPlan est crédité sur ton prochain renouvellement, puis tu paies $price par an.';
  }

  @override
  String get membershipNotNow => 'Pas maintenant';

  @override
  String get membershipUpgrade => 'Passer au supérieur';

  @override
  String get membershipSwitchPlan => 'Changer de forfait';

  @override
  String membershipSwitchedSnack(String plan) {
    return 'Tu as maintenant $plan.';
  }

  @override
  String get membershipCardUpdated => 'Ta carte a été mise à jour.';

  @override
  String get membershipCardUpdatePending =>
      'La mise à jour de la carte n\'est pas encore confirmée. Vérifie son statut avant de réessayer.';

  @override
  String get membershipCardUpdateEnded =>
      'Cette session de mise à jour de carte est terminée. Actualise pour voir ta carte actuelle.';

  @override
  String get membershipCheckoutTitleCard => 'ta carte';

  @override
  String get membershipAutoRenewOffTitle =>
      'Désactiver le renouvellement automatique ?';

  @override
  String membershipAutoRenewOffBodyDate(String plan, String date) {
    return 'Tes avantages $plan restent actifs jusqu\'au $date. Ensuite, tu passes au forfait gratuit et ta carte n\'est plus débitée.';
  }

  @override
  String membershipAutoRenewOffBodyPeriodEnd(String plan) {
    return 'Tes avantages $plan restent actifs jusqu\'à la fin de la période en cours. Ensuite, tu passes au forfait gratuit et ta carte n\'est plus débitée.';
  }

  @override
  String get membershipKeepRenewing => 'Garder le renouvellement';

  @override
  String get membershipTurnOff => 'Désactiver';

  @override
  String get membershipAutoRenewBackOn =>
      'Le renouvellement automatique est réactivé.';

  @override
  String get membershipAutoRenewNowOff =>
      'Le renouvellement automatique est désactivé. Tes avantages restent actifs jusqu\'à la fin de la période.';

  @override
  String membershipSubscribeTitle(String plan) {
    return 'S\'abonner à $plan';
  }

  @override
  String membershipSubscribeBodyMonthly(String price) {
    return '$price par mois, débités sur ta carte et renouvelés automatiquement jusqu\'à ce que tu désactives le renouvellement automatique. Tu saisiras ta carte sur la page sécurisée du prestataire de paiement.';
  }

  @override
  String membershipSubscribeBodyYearly(String price) {
    return '$price par an, débités sur ta carte et renouvelés automatiquement jusqu\'à ce que tu désactives le renouvellement automatique. Tu saisiras ta carte sur la page sécurisée du prestataire de paiement.';
  }

  @override
  String membershipSubscribeBodyTestMonthly(String price) {
    return 'Paiement de test uniquement — aucun débit réel. $price par mois, simulés et renouvelés automatiquement jusqu\'à ce que tu désactives le renouvellement automatique. Tu saisiras ta carte sur la page sécurisée du prestataire de paiement.';
  }

  @override
  String membershipSubscribeBodyTestYearly(String price) {
    return 'Paiement de test uniquement — aucun débit réel. $price par an, simulés et renouvelés automatiquement jusqu\'à ce que tu désactives le renouvellement automatique. Tu saisiras ta carte sur la page sécurisée du prestataire de paiement.';
  }

  @override
  String get membershipContinueToCard => 'Continuer vers la carte';

  @override
  String get paymentStillConfirming =>
      'Le paiement est en cours de confirmation. Tire vers le bas pour actualiser dans un instant.';

  @override
  String get membershipCheckoutEnded =>
      'Cette session de paiement est terminée. Actualise ton historique de paiements avant de réessayer.';

  @override
  String get membershipRecoverAccountUnavailable =>
      'Impossible de vérifier le compte de paiement. Réessaie.';

  @override
  String get membershipRecoverCheckoutClosed =>
      'Compte de paiement actualisé. Ce paiement n\'est plus ouvert.';

  @override
  String get membershipRecoverConfirmed =>
      'Confirmé. Ton compte de paiement est à jour.';

  @override
  String get membershipRecoverPending =>
      'La confirmation est toujours en attente. Tu peux vérifier à nouveau ici.';

  @override
  String get membershipRecoverEnded =>
      'Cette session de paiement est terminée. Consulte ton historique de paiements avant d\'en lancer une autre.';

  @override
  String membershipCelebrateTitle(String plan) {
    return 'Tu es $plan maintenant';
  }

  @override
  String get membershipCelebrateBodyTest =>
      'Paiement de test confirmé ; aucun argent réel n\'a été débité. Ton forfait de test se renouvelle automatiquement. Gère le renouvellement automatique à tout moment depuis cet écran.';

  @override
  String get membershipCelebrateBody =>
      'Paiement confirmé. Ton forfait se renouvelle automatiquement. Gère le renouvellement automatique à tout moment depuis cet écran.';

  @override
  String get membershipStartExploring => 'Commencer à explorer';

  @override
  String get membershipYourMembership => 'Ton abonnement';

  @override
  String get membershipYourPlan => 'Ton forfait';

  @override
  String get membershipFreePlanName => 'Gratuit';

  @override
  String membershipPricePerMonthShort(String price) {
    return '$price/mois';
  }

  @override
  String membershipPricePerYearShort(String price) {
    return '$price/an';
  }

  @override
  String get membershipCardOnFile =>
      'Carte enregistrée chez le prestataire de paiement';

  @override
  String get membershipCardBrandFallback => 'Carte';

  @override
  String get paymentOpening => 'Ouverture…';

  @override
  String get membershipUpdateCard => 'Changer de carte';

  @override
  String get membershipLastPaymentFailed =>
      'Le dernier paiement a échoué. Nous allons réessayer ta carte ; tes avantages restent actifs quelques jours.';

  @override
  String membershipRenewsOn(String date) {
    return 'Renouvellement le $date';
  }

  @override
  String get membershipRenewsSoon => 'Renouvellement prochainement';

  @override
  String membershipEndsOn(String date) {
    return 'Prend fin le $date · renouvellement automatique désactivé';
  }

  @override
  String get membershipEndsSoon =>
      'Prend fin prochainement · renouvellement automatique désactivé';

  @override
  String get membershipAutoRenew => 'Renouvellement automatique';

  @override
  String get membershipAutoRenewOnSubtitle =>
      'Débité automatiquement à chaque période.';

  @override
  String get membershipAutoRenewOffSubtitle =>
      'Désactivé. Les avantages prennent fin avec la période en cours.';

  @override
  String get membershipFreeHeroBody =>
      'Débloque plus de likes, de messages et la mise à la une avec un forfait ci-dessous. Paiement par carte, résiliable à tout moment.';

  @override
  String get membershipStatusFree => 'Gratuit';

  @override
  String get membershipStatusPaymentDue => 'Paiement dû';

  @override
  String get membershipStatusEnding => 'Se termine';

  @override
  String get membershipStatusActive => 'Actif';

  @override
  String get membershipCycleMonthly => 'Mensuel';

  @override
  String get membershipCycleYearly => 'Annuel';

  @override
  String get membershipBadgeYourPlan => 'TON FORFAIT';

  @override
  String get membershipBadgeMostPopular => 'LE PLUS POPULAIRE';

  @override
  String get membershipPerMonth => 'par mois';

  @override
  String get membershipPerYear => 'par an';

  @override
  String membershipSavePercent(int percent) {
    return 'Économise $percent %';
  }

  @override
  String membershipQuotaLikesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes/jour',
      one: '1 like/jour',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages/jour',
      one: '1 message/jour',
    );
    return '$_temp0';
  }

  @override
  String get membershipQuotaUnlimitedLikes => 'Likes illimités';

  @override
  String get membershipQuotaUnlimitedMessages => 'Messages illimités';

  @override
  String get membershipYourCurrentPlan => 'Ton forfait actuel';

  @override
  String get membershipSwitching => 'Changement…';

  @override
  String get membershipOpeningSecureCheckout =>
      'Ouverture du paiement sécurisé…';

  @override
  String membershipSwitchToPlan(String plan) {
    return 'Passer à $plan';
  }

  @override
  String get membershipSubscribeWithCard => 'S\'abonner par carte';

  @override
  String get membershipSettleBeforeSwitch =>
      'Règle le paiement en attente de ton forfait actuel avant de changer.';

  @override
  String get membershipPaymentChargeback => 'Rétrofacturation';

  @override
  String get membershipPaymentDisputed => 'Contesté';

  @override
  String get membershipPaymentRefunded => 'Remboursé';

  @override
  String get membershipPaymentPartlyRefunded => 'Partiellement remboursé';

  @override
  String get membershipPaymentFailed => 'Échoué';

  @override
  String get membershipPaymentPaid => 'Payé';

  @override
  String get membershipPaymentPending => 'En attente';

  @override
  String get membershipPaymentReasonFirstCharge => 'Premier prélèvement';

  @override
  String get membershipPaymentReasonRenewal => 'Renouvellement';

  @override
  String get membershipPaymentReasonPlanChange => 'Changement de forfait';

  @override
  String get membershipPaymentReasonCoins => 'Pièces';

  @override
  String get membershipPaymentReasonLocalActivation => 'Activation locale';

  @override
  String get membershipPaymentReasonCard => 'Paiement par carte';

  @override
  String get membershipPaymentReasonOther => 'Paiement';

  @override
  String get paymentModeSandbox => 'Test local · aucun débit réel';

  @override
  String get paymentModeStripeTest => 'Test Stripe · aucun débit réel';

  @override
  String get paymentModeLive => 'Paiements réels';

  @override
  String get paymentModeUnavailable => 'Paiements indisponibles';

  @override
  String get paymentAccountTitle => 'Ton compte de paiement';

  @override
  String get paymentAccountSignedInMember => 'Membre connecté';

  @override
  String get paymentAccountCardTitle => 'Carte de crédit ou de débit';

  @override
  String get paymentAccountCardUnavailableTitle =>
      'Le paiement par carte est indisponible';

  @override
  String get paymentAccountCardBody =>
      'Saisis ta carte sur la page de paiement hébergée. L\'abonnement et l\'historique des paiements sont liés à ce compte.';

  @override
  String get paymentAccountCardUnavailableBody =>
      'Tu peux continuer à utiliser ton compte actuel. Les nouveaux paiements par carte ne sont pas activés.';

  @override
  String paymentAccountTestCardHint(String cardNumber) {
    return 'Pour tester, utilise $cardNumber, une date d\'expiration future et n\'importe quel CVC à trois chiffres. Utilise uniquement des données de test.';
  }

  @override
  String get paymentAccountUnfinishedCardUpdate =>
      'Mise à jour de carte inachevée';

  @override
  String paymentAccountUnfinishedCheckout(String plan) {
    return 'Paiement inachevé : $plan';
  }

  @override
  String get paymentAccountPendingHint =>
      'Vérifie le dernier statut ou reprends le même paiement.';

  @override
  String get paymentAccountCheckStatus => 'Vérifier le statut';

  @override
  String get paymentAccountResumeCheckout => 'Reprendre le paiement';

  @override
  String paymentCheckoutPayFor(String title) {
    return 'Payer : $title';
  }

  @override
  String get paymentCheckoutClose => 'Fermer le paiement';

  @override
  String get paymentCheckoutSecureNote =>
      'Les données de carte sont saisies sur la page sécurisée du prestataire de paiement.';

  @override
  String paymentCheckoutCompleteInNewTab(String title) {
    return 'Termine le paiement ($title) dans le nouvel onglet';
  }

  @override
  String get paymentCheckoutWaitingBody =>
      'Tu saisis tes données de carte sur la page sécurisée du prestataire de paiement. Reviens ici quand elle indique que le paiement est terminé.';

  @override
  String get paymentCheckoutCheckConfirmation => 'Vérifier la confirmation';

  @override
  String get paymentCheckoutBackToAccount => 'Retour au compte';

  @override
  String get paymentWalletTitle => 'Portefeuille et paiements';

  @override
  String get paymentWalletTestNote =>
      'Paiements de test · aucun débit réel. Utilise uniquement des données de carte de test.';

  @override
  String get paymentWalletPopularTopUps => 'Recharges populaires';

  @override
  String get paymentWalletTopUpsIntro =>
      'Paie par carte sur la page de paiement sécurisée. Les pièces arrivent dans ton portefeuille dès que le paiement est réglé.';

  @override
  String get paymentWalletCardsDisabled =>
      'Les paiements par carte ne sont pas encore activés sur ce serveur.';

  @override
  String get paymentWalletNoPacks =>
      'Aucun pack de pièces n\'est disponible pour le moment.';

  @override
  String get paymentWalletActivity => 'Activité du portefeuille';

  @override
  String get paymentWalletNoPurchases =>
      'Aucun achat de pièces pour l\'instant.';

  @override
  String get paymentWalletFooter =>
      'Les pièces servent aux cadeaux et aux boosts dans Connect. Les achats sont définitifs une fois réglés ; les données de carte restent chez le prestataire de paiement.';

  @override
  String paymentCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièces',
      one: '1 pièce',
    );
    return '$_temp0';
  }

  @override
  String paymentCoinsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièces ajoutées à ton portefeuille.',
      one: '1 pièce ajoutée à ton portefeuille.',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pièces',
      one: 'pièce',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnitBonus(int count, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pièces · +$bonus en bonus',
      one: 'pièce · +$bonus en bonus',
    );
    return '$_temp0';
  }

  @override
  String get paymentWalletCheckoutEnded =>
      'Cette session de paiement est terminée. Consulte ton historique de paiements avant de réessayer.';

  @override
  String get paymentWalletBalanceLabel => 'Solde du portefeuille Glow';

  @override
  String get paymentWalletSourceSupport => 'Recharge par le support';

  @override
  String get paymentWalletSourcePromo => 'Promotion';

  @override
  String get paymentWalletSourcePurchase => 'Achat de pièces';

  @override
  String get paymentErrorSignInSubscriptions =>
      'Connecte-toi pour gérer tes abonnements.';

  @override
  String get paymentErrorSignInWallet =>
      'Connecte-toi pour gérer ton portefeuille.';

  @override
  String get paymentErrorLoadSubscription =>
      'Impossible de charger les détails de l\'abonnement.';

  @override
  String get paymentErrorLoadWallet =>
      'Impossible de charger ton portefeuille.';

  @override
  String get paymentErrorStartCheckoutNow =>
      'Impossible de lancer le paiement pour le moment.';

  @override
  String get paymentErrorStartCheckout => 'Impossible de lancer le paiement.';

  @override
  String get paymentErrorConfirmPayment =>
      'Impossible de confirmer le paiement pour l\'instant.';

  @override
  String get paymentErrorAutoRenewOn =>
      'Impossible de réactiver le renouvellement automatique.';

  @override
  String get paymentErrorAutoRenewOff =>
      'Impossible de désactiver le renouvellement automatique.';

  @override
  String get paymentErrorChangePlan => 'Impossible de changer de forfait.';

  @override
  String get paymentErrorUpdateCard => 'Impossible de mettre à jour la carte.';

  @override
  String get paymentErrorSandboxFailed => 'La simulation sandbox a échoué.';

  @override
  String get paymentErrorUnreachable =>
      'Impossible de joindre le service local. Vérifie que l\'API est lancée.';

  @override
  String membershipQuotaLikesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$remaining likes sur $limit restants aujourd\'hui',
      one: '$remaining like sur 1 restant aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$remaining messages sur $limit restants aujourd\'hui',
      one: '$remaining message sur 1 restant aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String membershipLikeLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Tu as utilisé tes $limit likes du jour avec $plan',
      one: 'Tu as utilisé ton like du jour avec $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipMessageLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Tu as utilisé tes $limit messages du jour avec $plan',
      one: 'Tu as utilisé ton message du jour avec $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaResetsAt(String time) {
    return 'Réinitialisation à $time';
  }

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matchs',
      one: '$count match',
    );
    return '$_temp0';
  }

  @override
  String get matchesSubtitleConversations =>
      'Un peu plus proches, un message à la fois.';

  @override
  String get matchesSubtitlePeople =>
      'Des personnes que tu as choisies. Des possibilités que vous façonnez ensemble.';

  @override
  String get matchesSearchConversations => 'Rechercher des conversations';

  @override
  String get matchesSearchMatches => 'Rechercher dans tes matchs';

  @override
  String get matchesFilterAllConversations => 'Toutes les conversations';

  @override
  String matchesFilterUnread(int count) {
    return 'Non lus · $count';
  }

  @override
  String get matchesLoading => 'Chargement des matchs…';

  @override
  String get matchesLoadErrorTitle => 'Impossible de charger les matchs';

  @override
  String get matchesRetry => 'Réessayer';

  @override
  String get matchesEmptyTitle => 'Pas encore de match';

  @override
  String matchesTrustFilteredHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Les filtres de confiance ont masqué $count matchs. Essaie d\'assouplir les filtres de confiance depuis Découvrir.',
      one:
          'Les filtres de confiance ont masqué $count match. Essaie d\'assouplir les filtres de confiance depuis Découvrir.',
    );
    return '$_temp0';
  }

  @override
  String get matchesEmptyBody =>
      'Va dans Aujourd’hui pour découvrir quelqu’un que tu aimerais rencontrer.';

  @override
  String get matchesNoConversationResults =>
      'Aucune conversation ici pour l\'instant. Essaie une autre recherche ou un autre filtre.';

  @override
  String get matchesNoPeopleResults =>
      'Aucun match trouvé. Essaie un autre prénom.';

  @override
  String get matchesTabPeople => 'Tes matchs';

  @override
  String get matchesTabConversations => 'Conversations';

  @override
  String get matchesActionStartCall => 'Démarrer un appel';

  @override
  String get matchesActionStartActivity => 'Lancer une activité';

  @override
  String get matchesActionPlanDate => 'Planifier un rendez-vous';

  @override
  String get matchesActionPlanDateSubtitle =>
      'Choisis un moment et ce que tu veux partager';

  @override
  String matchesPlanSent(String name) {
    return 'Proposition envoyée à $name.';
  }

  @override
  String get matchesActionGraduate => 'On s\'est trouvés';

  @override
  String get matchesActionGraduateSubtitle =>
      'Quittez Connect ensemble ; votre chat reste';

  @override
  String matchesGraduationAsked(String name) {
    return 'Demande envoyée à $name pour partir ensemble. La confirmation se fait depuis votre chat.';
  }

  @override
  String get matchesActionNudge => 'Envoyer un petit signe';

  @override
  String matchesNudgeSent(String name) {
    return 'Petit signe envoyé à $name.';
  }

  @override
  String get matchesNudgeFailed => 'Impossible d\'envoyer ce petit signe.';

  @override
  String get matchesActionClose => 'Clore la conversation';

  @override
  String get matchesActionCloseSubtitle =>
      'Prends de la distance, sans explication.';

  @override
  String get matchesCloseDialogTitle => 'Clore cette conversation ?';

  @override
  String get matchesCloseDialogBody =>
      'Ce n\'est pas grave si cette connexion n\'est pas pour toi. Cela met fin au match. Tu n\'as pas besoin d\'envoyer d\'explication. Signaler reste un choix distinct.';

  @override
  String get matchesCloseDialogKeep => 'Continuer à discuter';

  @override
  String get matchesActionReport => 'Signaler';

  @override
  String get matchesReportSubmitted => 'Signalement envoyé. Merci.';

  @override
  String get matchesReportAppeal => 'Faire appel';

  @override
  String matchesAppealReason(String userId) {
    return 'Revoir la décision de modération pour le signalement de l\'utilisateur $userId';
  }

  @override
  String get matchesBothChose =>
      'Vous avez choisi tous les deux de vous rencontrer';

  @override
  String matchesOptionsTooltip(String name) {
    return 'Options du match avec $name';
  }

  @override
  String matchesChatUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chat · $count non lus',
      one: 'Chat · $count non lu',
    );
    return '$_temp0';
  }

  @override
  String get matchesOpenChat => 'Ouvrir le chat';

  @override
  String get matchesFirstChapter => 'Premier Chapitre';

  @override
  String get matchesUnknownName => 'Inconnu';

  @override
  String get matchesSayHi => 'Dis bonjour 👋';

  @override
  String get matchesFallbackName => 'Ton match';

  @override
  String get matchesFallbackMessage => 'Lance votre conversation';

  @override
  String get matchesGiftPreview => 'Un petit cadeau dans votre conversation';

  @override
  String matchesConversationOptionsTooltip(String name) {
    return 'Options de la conversation avec $name';
  }

  @override
  String get matchesTimeNow => 'À l\'instant';

  @override
  String matchesTimeMinutesAgo(int minutes) {
    return 'il y a $minutes min';
  }

  @override
  String matchesTimeHoursAgo(int hours) {
    return 'il y a $hours h';
  }

  @override
  String get matchesTimeToday => 'Aujourd\'hui';

  @override
  String get matchesTimeYesterday => 'Hier';

  @override
  String get matchesNewMatchTitle => 'Nouveau match';

  @override
  String get matchesItsAMatch => 'C\'est un match !';

  @override
  String matchesLikedEachOther(String name) {
    return '$name et toi, vous vous êtes plu';
  }

  @override
  String get matchesSendMessage => 'Envoyer un message';

  @override
  String get matchesKeepSwiping => 'Continuer à swiper';

  @override
  String get matchesErrorLoginRequired => 'Connecte-toi pour voir tes matchs.';

  @override
  String get matchesErrorLoadFailed =>
      'Impossible de charger les matchs. Réessaie.';

  @override
  String get matchesErrorUnmatchFailed => 'Impossible d\'annuler le match.';

  @override
  String get matchesErrorMarkReadFailed => 'Impossible de marquer comme lu.';

  @override
  String get matchesErrorSessionUnavailable =>
      'Session utilisateur indisponible.';

  @override
  String get matchesTrustBadgePromptCompleter => 'Prompts complétés';

  @override
  String get matchesTrustBadgeRespectful => 'Communication respectueuse';

  @override
  String get matchesTrustBadgeConsistent => 'Profil cohérent';

  @override
  String get matchesTrustBadgeVerifiedActive => 'Vérifié et actif';

  @override
  String get matchesTrustErrorLoad =>
      'Impossible de charger les filtres de confiance. Réessaie.';

  @override
  String get matchesTrustErrorSave =>
      'Impossible d\'enregistrer les filtres de confiance. Réessaie.';

  @override
  String get matchesGestureErrorLoad => 'Impossible de charger l\'historique';

  @override
  String get matchesGestureErrorPending =>
      'Les attentions se débloquent quand cette conversation en attente devient un vrai match.';

  @override
  String get matchesGestureErrorSend => 'Impossible d\'envoyer l\'attention.';

  @override
  String get matchesGestureErrorUpdate =>
      'Impossible de mettre à jour l\'attention.';

  @override
  String get matchesActivityTitle => 'Ceci ou cela en 2 minutes';

  @override
  String get matchesActivityRestartTooltip => 'Lancer une nouvelle session';

  @override
  String matchesActivityCompleteWith(String name) {
    return 'Fais-le avec $name';
  }

  @override
  String get matchesActivityInstructions =>
      'Réponds aux 8 manches avant la fin du temps.';

  @override
  String matchesActivityStatus(String status) {
    return 'Statut : $status';
  }

  @override
  String get matchesActivityStatusActive => 'en cours';

  @override
  String get matchesActivityStatusTimedOut => 'temps écoulé';

  @override
  String get matchesActivityStatusPartialTimeout => 'partiellement expiré';

  @override
  String get matchesActivityStatusCompleted => 'terminé';

  @override
  String get matchesActivitySubmit => 'Envoyer mes réponses';

  @override
  String get matchesActivityTimeUpLoad => 'Temps écoulé — Charger le résumé';

  @override
  String get matchesActivityWaiting =>
      'Réponses envoyées. En attente de l\'autre participant.';

  @override
  String get matchesActivityRefreshSummary => 'Actualiser le résumé';

  @override
  String matchesActivityTimeLeft(String time) {
    return 'Temps restant $time';
  }

  @override
  String get matchesActivitySummaryTitle => 'Résumé de l\'activité';

  @override
  String matchesActivityParticipantsCompleted(int completed, int total) {
    return 'Participants ayant terminé : $completed/$total';
  }

  @override
  String get matchesActivitySummaryPending =>
      'Le résumé s\'affichera dès qu\'il sera disponible.';

  @override
  String get matchesActivityShareResult => 'Partager le résultat dans le chat';

  @override
  String matchesActivityShareMessage(String status, int completed, int total) {
    return 'Résultat Ceci ou cela (2 min) : $status • $completed/$total ont terminé';
  }

  @override
  String matchesActivityShareMessageWithInsight(
    String status,
    int completed,
    int total,
    String insight,
  ) {
    return 'Résultat Ceci ou cela (2 min) : $status • $completed/$total ont terminé • $insight';
  }

  @override
  String matchesActivityRound(int number) {
    return 'Manche $number';
  }

  @override
  String get matchesActivityErrorStart =>
      'Impossible de lancer l\'activité pour le moment. Réessaie.';

  @override
  String get matchesActivityErrorNotReady =>
      'La session n\'est pas encore prête.';

  @override
  String get matchesActivityErrorAnswerAll =>
      'Réponds à toutes les questions avant d\'envoyer.';

  @override
  String get matchesActivityErrorTimeUp =>
      'Le temps est écoulé. Chargement du résumé…';

  @override
  String get matchesActivityErrorSubmit =>
      'Impossible d\'envoyer tes réponses. Réessaie.';

  @override
  String get matchesActivityErrorSummary =>
      'Impossible de récupérer le résumé pour l\'instant. Réessaie.';

  @override
  String get matchesActivityQ1Prompt => 'Premier rendez-vous idéal ?';

  @override
  String get matchesActivityQ1OptionA => 'Balade avec un café';

  @override
  String get matchesActivityQ1OptionB => 'Flâner en librairie';

  @override
  String get matchesActivityQ2Prompt => 'Ambiance de week-end préférée ?';

  @override
  String get matchesActivityQ2OptionA => 'Rester chez soi et se ressourcer';

  @override
  String get matchesActivityQ2OptionB => 'Explorer la ville';

  @override
  String get matchesActivityQ3Prompt => 'Meilleur cadre pour discuter ?';

  @override
  String get matchesActivityQ3OptionA => 'Longue balade';

  @override
  String get matchesActivityQ3OptionB => 'Coin douillet dans un café';

  @override
  String get matchesActivityQ4Prompt =>
      'Comment organises-tu tes rendez-vous ?';

  @override
  String get matchesActivityQ4OptionA => 'Spontanément';

  @override
  String get matchesActivityQ4OptionB => 'À l\'avance';

  @override
  String get matchesActivityQ5Prompt =>
      'Qu\'est-ce qui compte le plus pour toi en ce moment ?';

  @override
  String get matchesActivityQ5OptionA => 'La constance';

  @override
  String get matchesActivityQ5OptionB => 'Le frisson';

  @override
  String get matchesActivityQ6Prompt => 'Ta façon de gérer un conflit ?';

  @override
  String get matchesActivityQ6OptionA => 'Régler le jour même';

  @override
  String get matchesActivityQ6OptionB => 'Prendre du recul puis en reparler';

  @override
  String get matchesActivityQ7Prompt => 'Activité à partager ?';

  @override
  String get matchesActivityQ7OptionA => 'Cuisiner ensemble';

  @override
  String get matchesActivityQ7OptionB => 'Faire du sport ensemble';

  @override
  String get matchesActivityQ8Prompt => 'Quel rythme préfères-tu ?';

  @override
  String get matchesActivityQ8OptionA => 'Posé et réfléchi';

  @override
  String get matchesActivityQ8OptionB => 'Rapide et énergique';

  @override
  String get cityPilotSaveFailed =>
      'Nous n’avons pas pu confirmer ce changement. Actualise pour vérifier avant de réessayer.';

  @override
  String get cityPilotLeaveTitle => 'Quitter le projet pilote de ta ville ?';

  @override
  String get cityPilotLeaveBody =>
      'Tes réservations du projet pilote seront annulées et tes avis sur les expériences supprimés. Ton activité ne comptera plus dans les résultats actuels. Tes matchs et conversations restent. Tu ne pourras pas rejoindre à nouveau ce projet pilote.';

  @override
  String get cityPilotStay => 'Rester dans le projet';

  @override
  String get cityPilotLeave => 'Quitter le projet';

  @override
  String get cityPilotLeftNotice =>
      'Tu as quitté le projet pilote. Tes matchs restent avec toi.';

  @override
  String cityPilotJoinEventTitle(String title) {
    return 'Rejoindre $title ?';
  }

  @override
  String cityPilotBookingTerms(
    String host,
    String safetyContact,
    String accessibility,
  ) {
    return 'Cette expérience est gratuite. Le rendez-vous a lieu dans un lieu public : respecte les limites des autres et organise ton propre trajet. Tu peux partir à tout moment.\n\nHôte : $host\nContact sécurité : $safetyContact\n\nAccessibilité : $accessibility\n\nEn cas de danger immédiat, contacte les services d’urgence locaux.';
  }

  @override
  String get cityPilotAcceptReserve => 'Accepter et réserver une place';

  @override
  String get cityPilotReservedNotice =>
      'Ta place est réservée. Tu peux annuler ici à tout moment.';

  @override
  String get cityPilotFeedbackTitle => 'Comment s’est passée l’expérience ?';

  @override
  String get cityPilotFeedbackIntro =>
      'Facultatif. Les réponses alimentent les résultats agrégés du projet pilote. Elles ne sont montrées ni aux autres membres ni à l’hôte.';

  @override
  String get cityPilotDidYouAttend => 'As-tu participé ?';

  @override
  String get cityPilotAttendedYes => 'Oui, j’y étais';

  @override
  String get cityPilotAttendedNo => 'Je n’ai pas pu venir';

  @override
  String get cityPilotWorthwhileQuestion =>
      'Est-ce que ça valait le coup ? (facultatif)';

  @override
  String get cityPilotNotThisTime => 'Pas cette fois';

  @override
  String get cityPilotSkip => 'Passer';

  @override
  String get cityPilotShareFeedback => 'Envoyer mon avis';

  @override
  String get cityPilotFeedbackThanks =>
      'Merci. Ton avis a été enregistré en toute confidentialité.';

  @override
  String get cityPilotTimeTbc => 'Horaire à confirmer';

  @override
  String get cityPilotTitle => 'Le projet pilote de ta ville';

  @override
  String get cityPilotRefreshTooltip => 'Actualiser le projet pilote';

  @override
  String get cityPilotHeroTitle => 'Un peu plus proche.\nBeaucoup plus réel.';

  @override
  String get cityPilotHeroBody =>
      'Une ville. Une petite communauté. Plus de chances qu’une conversation devienne un vrai projet.';

  @override
  String get cityPilotStep1Title => 'Commencer par une conversation';

  @override
  String get cityPilotStep1Body =>
      'Fais connaissance à ton rythme grâce à tes présentations existantes.';

  @override
  String get cityPilotStep2Title =>
      'Faire de la place pour un vrai rendez-vous';

  @override
  String get cityPilotStep2Body =>
      'Construisez un projet ensemble. Raconte comment ça s’est passé seulement si tu le souhaites.';

  @override
  String get cityPilotStep3Title => 'Essayer quelque chose ensemble';

  @override
  String get cityPilotStep3Body =>
      'De petites expériences encadrées arriveront après le premier bilan du projet pilote.';

  @override
  String get cityPilotSaving => 'Enregistrement de ta préférence';

  @override
  String get cityPilotUnavailableTitle => 'Ton projet pilote est indisponible';

  @override
  String get cityPilotUnavailableBody =>
      'Vérifie ta connexion et actualise pour voir ta participation et tes réservations à jour.';

  @override
  String get cityPilotComingSoonTitle =>
      'Bientôt dans une ville près de chez toi';

  @override
  String get cityPilotComingSoonBody =>
      'Il n’y a pas encore de projet pilote ouvert pour la ville de ton profil. Quand il y en aura un, tu pourras choisir d’y participer. Ton expérience de rencontre actuelle continue comme d’habitude.';

  @override
  String cityPilotPanelTitleJoined(String city) {
    return '$city · Tu en fais partie';
  }

  @override
  String cityPilotPanelTitleOpen(String city) {
    return '$city · Projet pilote';
  }

  @override
  String cityPilotRecruitmentCloses(String date) {
    return 'Fin des inscriptions : $date (heure locale).';
  }

  @override
  String get cityPilotPaused =>
      'Les nouvelles participations et réservations sont en pause. Tu peux toujours quitter ou annuler.';

  @override
  String get cityPilotCompleted =>
      'Ce projet pilote est terminé. Merci d’y avoir participé.';

  @override
  String get cityPilotMeasurement =>
      'En participant, tu nous permets de compter les conversations, les projets acceptés et les réponses facultatives à « le rendez-vous a-t-il eu lieu ? » pour les nouveaux matchs dont les deux personnes ont rejoint ce projet pilote. Nous utilisons des fenêtres de 7 jours pour les conversations et de 28 jours pour les rendez-vous. Nous ne lisons ni le texte des messages ni les notes d’avis privées pour le projet pilote.';

  @override
  String get cityPilotPrivacy =>
      'Ta participation reste privée. Il n’y a ni liste publique de présence ni score de rencontre. Quitter exclut ton activité des résultats actuels et annule tes réservations. Les résultats agrégés déjà examinés ne peuvent pas être oubliés.';

  @override
  String get cityPilotConsent =>
      'J’accepte de participer à ce projet pilote et à la mesure de ses résultats.';

  @override
  String get cityPilotJoinedNotice =>
      'C’est fait. Continue de rencontrer des gens à ton rythme.';

  @override
  String get cityPilotJoin => 'Rejoindre le projet pilote';

  @override
  String get cityPilotWithdrawn =>
      'Tu as quitté ce projet pilote. Tes matchs et conversations restent inchangés.';

  @override
  String get cityPilotNotAccepting =>
      'Ce projet pilote n’accepte pas de nouveaux membres pour le moment.';

  @override
  String get cityPilotExperiencesHeading =>
      'Petits projets. Expériences partagées.';

  @override
  String get cityPilotNoExperiences =>
      'Les expériences encadrées ne sont pas encore ouvertes. Elles apparaîtront ici après un bilan des résultats et de la sécurité.';

  @override
  String cityPilotEventDetails(
    String start,
    String end,
    String venue,
    String host,
  ) {
    return '$start → $end\nHeure locale · Gratuit\n$venue\nOrganisé par $host';
  }

  @override
  String cityPilotAccessibility(String details) {
    return 'Accessibilité · $details';
  }

  @override
  String cityPilotSafetyContact(String contact) {
    return 'Contact sécurité · $contact';
  }

  @override
  String get cityPilotEventCancelled =>
      'Cette expérience a été annulée. Ne te rends pas sur place.';

  @override
  String get cityPilotPlaceReserved => 'Ta place est réservée.';

  @override
  String get cityPilotBookingCancelled => 'Ta réservation est annulée.';

  @override
  String get cityPilotCancelPlace => 'Annuler ma place';

  @override
  String get cityPilotReserveFree => 'Réserver une place gratuite';

  @override
  String get cityPilotShareOptionalFeedback => 'Donner un avis facultatif';

  @override
  String get cityPilotFeedbackReceived => 'Ton avis a bien été reçu. Merci.';

  @override
  String get blogAudiencePrivate => 'Moi uniquement';

  @override
  String get blogAudienceFriends => 'Amis';

  @override
  String get blogAudienceCommunity => 'Communauté Connect';

  @override
  String get blogInvitationNone => 'Pas d\'invitation';

  @override
  String get blogInvitationYourVersion => 'À quoi ressemblerait ta version ?';

  @override
  String get blogInvitationTeachMe =>
      'Qu\'est-ce que tu pourrais m\'apprendre là-dessus ?';

  @override
  String get blogInvitationWhatNext => 'Qu\'est-ce que tu essaierais ensuite ?';

  @override
  String get blogRewardStoryPublishedTitle => 'Partager un chapitre';

  @override
  String get blogRewardStoryPublishedWho =>
      'Toi, la première fois qu\'un chapitre est partagé au-delà de « Moi uniquement »';

  @override
  String get blogRewardPhotoSharedTitle =>
      'Partager une photo dans Thèmes photo';

  @override
  String get blogRewardPhotoSharedWho =>
      'Toi, pour une photo que tu partages dans Thèmes photo';

  @override
  String get blogRewardLikeReceivedTitle =>
      'Un j\'aime sur ton chapitre ou ta photo';

  @override
  String get blogRewardLikeReceivedWho => 'Toi, pour chaque membre qui l\'aime';

  @override
  String get blogRewardCommentReceivedTitle =>
      'Un commentaire que tu approuves';

  @override
  String get blogRewardCommentReceivedWho =>
      'Toi, quand tu approuves le commentaire d\'un lecteur';

  @override
  String get blogRewardCommentApprovedTitle => 'Ton commentaire est approuvé';

  @override
  String get blogRewardCommentApprovedWho =>
      'Toi, quand un auteur approuve ton commentaire';

  @override
  String get blogRewardSubscriberGainedTitle => 'Un nouvel abonné';

  @override
  String get blogRewardSubscriberGainedWho =>
      'Toi, pour chaque nouveau membre qui suit tes chapitres';

  @override
  String get blogRewardWallTierTitle => 'Apparaître sur plus de murs';

  @override
  String get blogRewardWallTierWho =>
      'Toi, chaque fois qu\'un chapitre atteint un nouveau palier de murs';

  @override
  String get blogRewardCoverOfWeekTitle => 'Couverture de la semaine';

  @override
  String get blogRewardCoverOfWeekWho =>
      'Toi, quand ton travail est choisi comme couverture de la semaine';

  @override
  String get blogScopeForYou => 'Pour toi';

  @override
  String get blogScopeTopRated => 'Les mieux notés';

  @override
  String get blogScopeFollowing => 'Abonnements';

  @override
  String get blogScopeMine => 'Les miens';

  @override
  String get blogScopeCaptionMine =>
      'Tes brouillons et tes chapitres publiés. Tu choisis le public de chacun.';

  @override
  String get blogScopeCaptionFriends =>
      'Les chapitres partagés par tes amis Connect.';

  @override
  String get blogScopeCaptionTop =>
      'Classés selon les j\'aime, les commentaires approuvés et les lecteurs des 30 derniers jours.';

  @override
  String get blogScopeCaptionFollowing =>
      'Les derniers chapitres des auteurs que tu suis.';

  @override
  String get blogScopeCaptionCommunity =>
      'Pour les membres Connect connectés et éligibles. Ces chapitres ne sont pas publics sur le web.';

  @override
  String get blogTitle => 'Chapitres ouverts';

  @override
  String get blogRewardsTitle => 'Comment fonctionnent les récompenses';

  @override
  String get blogWritersTitle => 'Les auteurs que tu suis';

  @override
  String get blogConnectionsTooltip => 'Réponses privées, partages et avis';

  @override
  String get blogSignInReadWrite =>
      'Connecte-toi pour lire et écrire des chapitres.';

  @override
  String get blogHeroTitle => 'Une vie qui mérite\nd\'être connue.';

  @override
  String get blogHeroBody =>
      'L\'histoire derrière une photo. Une petite obsession. Quelque chose que tu apprends encore. Laisse ton quotidien parler pour toi.';

  @override
  String get blogWriteChapter => 'Écrire un chapitre';

  @override
  String get blogPrivateResponses => 'Réponses privées';

  @override
  String get blogSharedLinks => 'Liens partagés';

  @override
  String get blogReviewNotices => 'Avis de modération';

  @override
  String get blogTopicAll => 'Tous';

  @override
  String get blogFeedLoadFailed => 'Impossible de charger les chapitres.';

  @override
  String get blogPreviousPage => 'Page précédente';

  @override
  String get blogMoreChapters => 'Plus de chapitres';

  @override
  String get blogEmptyMineTitle => 'Ton prochain chapitre commence ici.';

  @override
  String get blogEmptyMineBody =>
      'Commence par un moment dont tu aimerais qu\'on te parle. Ton premier brouillon n\'est que pour toi.';

  @override
  String get blogEmptyTopTitle =>
      'Quand des chapitres touchent les gens, ils montent ici.';

  @override
  String get blogEmptyTopFilteredBody =>
      'Rien n\'est encore monté dans ce thème. Essaie « Tous » ou partage un chapitre à toi.';

  @override
  String get blogEmptyTopBody =>
      'Les chapitres que les lecteurs ont adorés ces 30 derniers jours apparaîtront ici.';

  @override
  String get blogEmptyFollowingFilteredTitle =>
      'Rien de nouveau dans ce thème pour l\'instant.';

  @override
  String get blogEmptyFollowingTitle =>
      'Les auteurs que tu suis apparaîtront ici.';

  @override
  String get blogEmptyFollowingBody =>
      'Quand un chapitre te parle, ouvre-le et appuie sur « Suivre ses chapitres ». Ses nouveaux chapitres se retrouveront ici pour que tu ne rates rien.';

  @override
  String get blogEmptyCommunityTitle =>
      'C\'est un peu calme ici, pour le moment.';

  @override
  String get blogEmptyCommunityBody =>
      'Les chapitres apparaissent ici quand des membres choisissent de les partager avec ce public.';

  @override
  String get blogFindWritersTopRated =>
      'Trouver des auteurs dans « Les mieux notés »';

  @override
  String blogRankTooltip(int rank) {
    return 'Numéro $rank des mieux notés';
  }

  @override
  String get blogUntitled => 'Un chapitre sans titre';

  @override
  String get blogDraftPlaceholder => 'Un brouillon privé qui attend tes mots.';

  @override
  String get blogReadEdit => 'Lire et modifier →';

  @override
  String get blogReadChapter => 'Lire le chapitre →';

  @override
  String get blogPhotoUnavailableRetry => 'Photo indisponible · Réessayer';

  @override
  String get blogTryAgain => 'Réessayer';

  @override
  String get blogDetailTitle => 'Un chapitre';

  @override
  String get blogSignInRead => 'Connecte-toi pour lire des chapitres.';

  @override
  String get blogDetailUnavailable =>
      'Ce chapitre n\'est pas disponible ou son public a changé.';

  @override
  String get blogRespondPrivately => 'Répondre en privé';

  @override
  String get blogCreatePublicPreview => 'Créer un aperçu public';

  @override
  String get blogRemovedByModerationNote =>
      'Retiré par la modération. Ouvre « Avis de modération » pour lire la décision ou demander un nouvel examen.';

  @override
  String get blogEditChapter => 'Modifier le chapitre';

  @override
  String get blogDeleteChapter => 'Supprimer le chapitre';

  @override
  String get blogDeleteChapterTitle => 'Supprimer ce chapitre ?';

  @override
  String get blogDeleteChapterMessage =>
      'Il disparaîtra pour tous les publics. Cette action est irréversible.';

  @override
  String get blogDeleteChapterFailed =>
      'Impossible de confirmer la suppression. Recharge le chapitre avant de réessayer.';

  @override
  String get blogReportChapter => 'Signaler le chapitre';

  @override
  String get blogReportFailed => 'Le signalement n\'a pas pu être envoyé.';

  @override
  String get blogBlockThisMember => 'Bloquer ce membre';

  @override
  String get blogBlockTitle => 'Bloquer ce membre ?';

  @override
  String get blogBlockMessageChapter =>
      'Vous ne verrez plus les chapitres l\'un de l\'autre. Cela bloque aussi tout contact via Connect.';

  @override
  String get blogBlockMember => 'Bloquer le membre';

  @override
  String get blogBlockRetryFailed =>
      'Impossible de bloquer ce membre. Réessaie.';

  @override
  String get blogCancel => 'Annuler';

  @override
  String get blogEditorMissingFields =>
      'Ajoute un titre et une histoire avant de publier.';

  @override
  String blogPublishConfirmTitle(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Publier pour « Moi uniquement » ?',
      'friends': 'Publier pour tes amis ?',
      'community': 'Publier dans la communauté Connect ?',
      'other': 'Publier ?',
    });
    return '$_temp0';
  }

  @override
  String get blogPublishFriendsBody =>
      'Tes amis Connect pourront lire les mots et voir les photos de ce chapitre. Tu pourras changer le public plus tard.';

  @override
  String get blogPublishCommunityBody =>
      'Les membres Connect connectés et éligibles pourront lire ce chapitre. Il n\'apparaîtra pas sur le web public. Tu pourras changer le public plus tard.';

  @override
  String get blogPublishChapter => 'Publier le chapitre';

  @override
  String get blogSavedOnlyMe => 'Enregistré. Toi seul peux lire ce chapitre.';

  @override
  String blogPublishedTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Publié pour « Moi uniquement ».',
      'friends': 'Publié pour tes amis.',
      'community': 'Publié dans la communauté Connect.',
      'other': 'Publié.',
    });
    return '$_temp0';
  }

  @override
  String get blogSharedSnack =>
      'Partagé. Les j\'aime et commentaires des lecteurs te rapportent des XP.';

  @override
  String get blogSeeMyLevel => 'Voir mon niveau';

  @override
  String get blogSaveUnconfirmed =>
      'Nous n\'avons pas pu confirmer l\'enregistrement.';

  @override
  String blogEditsStillHere(String message) {
    return '$message Tes modifications sont toujours là. Vérifie la version enregistrée avant de continuer.';
  }

  @override
  String blogSavedVersionTitle(String audience) {
    return 'Version enregistrée · $audience';
  }

  @override
  String get blogSavedVersionNote =>
      'Tes modifications actuelles restent dans l\'éditeur. Ferme ce panneau pour les garder ou remplace-les par cette version enregistrée.';

  @override
  String get blogKeepMyEdits =>
      'Garder mes modifications pour le prochain enregistrement';

  @override
  String get blogUseSavedVersion => 'Utiliser la version enregistrée';

  @override
  String get blogSavedVersionLoadFailed =>
      'La version enregistrée n\'a pas pu être chargée. Tes modifications restent ici.';

  @override
  String get blogDescribePhotoTitle => 'Décris ta photo';

  @override
  String get blogDescribePhotoBody =>
      'Une courte description rend ton chapitre accessible. Ajouter la photo enregistre tes mots en brouillon « Moi uniquement ».';

  @override
  String get blogDescribePhotoLabel => 'Que montre cette photo ?';

  @override
  String get blogAddToPrivateDraft => 'Ajouter au brouillon privé';

  @override
  String get blogPhotoAdded => 'Photo ajoutée à ton brouillon privé.';

  @override
  String get blogPhotoAddFailed =>
      'La photo n\'a pas pu être ajoutée. Utilise un JPEG ou un PNG de 10 Mo maximum.';

  @override
  String blogCheckSavedBeforeRetrying(String message) {
    return '$message Vérifie la version enregistrée avant de réessayer.';
  }

  @override
  String get blogRemoveUnconfirmed =>
      'Impossible de confirmer la suppression. Vérifie la version enregistrée.';

  @override
  String get blogSignInAsAuthor =>
      'Connecte-toi en tant qu\'auteur pour modifier ce chapitre.';

  @override
  String get blogLeaveEditorTitle => 'Quitter sans enregistrer ?';

  @override
  String get blogLeaveEditorMessage =>
      'Tes modifications non enregistrées seront perdues. Ton dernier chapitre enregistré sera conservé.';

  @override
  String get blogLeaveEditor => 'Quitter l\'éditeur';

  @override
  String get blogEditorPreviewTitle => 'Aperçu du chapitre';

  @override
  String get blogEditorTitle => 'Ton prochain chapitre';

  @override
  String get blogEditorHeadline => 'Un peu plus toi.';

  @override
  String get blogEditorIntro =>
      'Les petites histoires sont les bienvenues. Un plat que tu as cuisiné. Un lieu qui t\'a fait changer d\'avis. La photo qui cache une histoire.';

  @override
  String get blogNotSavedDefault =>
      'Non enregistré · « Moi uniquement » par défaut';

  @override
  String blogSavedFor(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Enregistré pour « Moi uniquement »',
      'friends': 'Enregistré pour tes amis',
      'community': 'Enregistré pour la communauté Connect',
      'other': 'Enregistré',
    });
    return '$_temp0';
  }

  @override
  String get blogKeepWriting => 'Continuer à écrire';

  @override
  String get blogPreview => 'Aperçu';

  @override
  String get blogCheckSavedVersion => 'Vérifier la version enregistrée';

  @override
  String blogPreviewNotSaved(String audience) {
    return 'Aperçu · $audience · Pas encore enregistré';
  }

  @override
  String get blogStoryPlaceholder => 'Ton histoire apparaîtra ici.';

  @override
  String get blogChapterTitleLabel => 'Titre du chapitre';

  @override
  String get blogChapterTitleHint => 'Le dimanche où j\'ai appris à ralentir';

  @override
  String get blogStoryLabel => 'Ton histoire';

  @override
  String get blogStoryHint => 'Commence où tu veux. Fais-en la tienne.';

  @override
  String get blogInvitationLabel => 'Terminer par une invitation (facultatif)';

  @override
  String get blogInvitationHelp =>
      'Laisse une question qui aide quelqu\'un à te connaître.';

  @override
  String get blogRemovePhoto => 'Retirer la photo';

  @override
  String get blogAddPhoto => 'Ajouter une photo';

  @override
  String get blogPhotoRules =>
      'Jusqu\'à 6 photos JPEG ou PNG de 10 Mo chacune. Les photos doivent être approuvées. Enregistre en « Moi uniquement » avant de modifier les photos d\'un chapitre publié.';

  @override
  String get blogWhoFor => 'À qui s\'adresse ce chapitre ?';

  @override
  String get blogAudiencePrivateHelp =>
      'Toi seul peux lire ce chapitre. Tes amis et tes matchs ne le voient pas.';

  @override
  String get blogAudienceFriendsHelp =>
      'Seuls tes amis Connect peuvent le lire. Un match seul ne donne pas accès.';

  @override
  String get blogAudienceCommunityHelp =>
      'Les membres connectés et éligibles peuvent le lire. Complète ton profil avec deux photos de profil approuvées pour publier ici. Ce n\'est pas un partage public sur le web.';

  @override
  String get blogAllowFeaturing => 'Autoriser la mise en avant';

  @override
  String get blogAllowFeaturingHelp =>
      'Si les lecteurs l\'adorent, ton chapitre peut apparaître sur les murs d\'autres membres : 50 j\'aime et 5 commentaires le font arriver sur 50 murs, 100 j\'aime et 10 commentaires sur 100. Tu peux désactiver cette option à tout moment.';

  @override
  String get blogSaveOnlyForMe => 'Enregistrer pour moi uniquement';

  @override
  String blogPublishTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Publier pour « Moi uniquement »',
      'friends': 'Publier pour tes amis',
      'community': 'Publier dans la communauté Connect',
      'other': 'Publier',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveAsOnlyMe => 'Enregistrer en « Moi uniquement »';

  @override
  String get blogSaveNote =>
      'Tes mots sont enregistrés quand tu choisis Enregistrer ou Publier. L\'aperçu ne publie rien.';

  @override
  String get blogTopicOptional => 'Thème (facultatif)';

  @override
  String get blogTopicHelp =>
      'Aide les lecteurs que ce sujet intéresse à trouver ton chapitre.';

  @override
  String get webDestBlog => 'Blog';

  @override
  String get webDestFirstChapter => 'Studio Premier chapitre';

  @override
  String get webDestDatingPreferences => 'Préférences de rencontre';

  @override
  String get webDestEditProfile => 'Modifier le profil';

  @override
  String get webDestProfilePhotos => 'Photos de profil';

  @override
  String get webDestLikedYou => 'T’ont liké';

  @override
  String get webDestNotifications => 'Notifications';

  @override
  String get webDestDailyPrompt => 'Question du jour';

  @override
  String get webDestLevels => 'Niveaux et progression';

  @override
  String get webDestTrustBadges => 'Badges de confiance';

  @override
  String get webDestTrustFilters => 'Filtres de confiance';

  @override
  String get webDestIcebreakers => 'Brise-glace';

  @override
  String get webDestCircleChallenges => 'Défis de cercle';

  @override
  String get webDestCoffeePolls => 'Sondages café';

  @override
  String get webDestGroups => 'Groupes';

  @override
  String get webDestRooms => 'Salons de discussion';

  @override
  String get webDestMatchNudges => 'Relances de match';

  @override
  String get webDestFriends => 'Amis';

  @override
  String get webDestDatePlans => 'Projets de rendez-vous';

  @override
  String get webDestCallHistory => 'Historique des appels';

  @override
  String get webDestMembership => 'Abonnement';

  @override
  String get webDestVerification => 'Vérification';

  @override
  String get webDestPrivacySafety => 'Confidentialité et sécurité';

  @override
  String get webDestAccountData => 'Compte et données';

  @override
  String get webDestBlockedMembers => 'Membres bloqués';

  @override
  String get webDestEmergencyContacts => 'Contacts d’urgence';

  @override
  String get webDestModerationAppeals => 'Recours de modération';

  @override
  String get webDestNotificationPreferences => 'Préférences de notification';

  @override
  String get webDestHelpSupport => 'Aide et assistance';

  @override
  String get webNavExplore => 'Explorer';

  @override
  String get webNavMyProfile => 'Mon profil';

  @override
  String get webNavAllFeatures => 'Toutes les fonctionnalités';

  @override
  String get webNavMoreForYou => 'Plus pour toi';

  @override
  String get webNavPreferences => 'Préférences';

  @override
  String get webNavWebsite => 'Site web de Connect';

  @override
  String get webNavSignOut => 'Se déconnecter';

  @override
  String get webPageNotFound => 'Cette page est introuvable.';

  @override
  String get webBackToDiscover => 'Retour à Découvrir';

  @override
  String get webTagline => 'Ton rythme. Ton choix.';

  @override
  String webUnavailableTitle(String label) {
    return '$label n’est pas encore disponible.';
  }

  @override
  String get webUnavailableBody =>
      'Cette fonctionnalité ne fait pas partie de cette version de Connect.';

  @override
  String get webDirectoryTitle => 'Fais de cet espace le tien.';

  @override
  String get webDirectorySubtitle =>
      'Ton profil, tes conversations, ta communauté et tes réglages — tout au même endroit.';

  @override
  String get webIcebreakerTitle => 'Idées pour lancer la conversation';

  @override
  String get webIcebreakerHeadline =>
      'Un peu d’inspiration pour ton prochain bonjour.';

  @override
  String get webIcebreakerBody =>
      'L’enregistrement et la lecture vocale ne sont pas encore disponibles. Tu peux utiliser ces idées dans une conversation éligible.';

  @override
  String get webIcebreakerOpenMatches => 'Ouvrir mes matchs';

  @override
  String get webMembershipHeadline => 'Un peu plus de possibilités.';

  @override
  String get webMembershipIntro =>
      'Découvre les offres actuelles. Le paiement dans le navigateur n’est pas encore disponible. Aucun achat ni débit ne peut être effectué depuis cette page.';

  @override
  String webMembershipCurrent(String plan) {
    return 'Ton abonnement : $plan';
  }

  @override
  String webMembershipStatus(String status) {
    return 'Statut : $status';
  }

  @override
  String get webMembershipMonthly => 'Mensuel';

  @override
  String get webMembershipYearly => 'Annuel';

  @override
  String get webMembershipFree => 'Gratuit';

  @override
  String webMembershipPrice(String price, String cycle) {
    String _temp0 = intl.Intl.selectLogic(cycle, {
      'yearly': 'an',
      'other': 'mois',
    });
    return '$price / $_temp0';
  }

  @override
  String get webMembershipFootnote =>
      'Les prix du catalogue sont un aperçu. Un abonnement ne contourne jamais les limites d’une autre personne ni les conditions pour discuter.';

  @override
  String get blogLinkCopied => 'Lien copié. Partage-le où tu veux.';

  @override
  String get blogYourPublicLink => 'Ton lien public';

  @override
  String get blogShareUnconfirmed =>
      'Impossible de confirmer le partage. Vérifie « Liens partagés » avant de réessayer.';

  @override
  String get blogSignInAgain => 'Reconnecte-toi pour continuer.';

  @override
  String get blogSharedJournalPage => 'Une page de journal partagée';

  @override
  String get blogYourPublicPreview => 'Ton aperçu public';

  @override
  String get blogShareJointHeadline =>
      'Une histoire que vous choisissez tous les deux de partager.';

  @override
  String get blogShareSoloHeadline => 'Une petite fenêtre sur ton univers.';

  @override
  String get blogShareJointBody =>
      'Les deux auteurs doivent approuver exactement ces mots pour que le lien fonctionne. Chacun peut le retirer.';

  @override
  String get blogShareSoloBody =>
      'Toute personne ayant le lien peut lire les mots et voir les photos sélectionnés, sans compte. Ton chapitre complet reste dans Connect.';

  @override
  String get blogShareIdentityNote =>
      'Aucun profil ni nom de compte n\'est ajouté. Tes mots et tes photos peuvent quand même permettre d\'identifier des personnes ou des lieux. Ne publie que ce que tu as le droit de partager.';

  @override
  String get blogExcerptLabel => 'Extrait exact de ton chapitre';

  @override
  String blogIncludePhoto(String description) {
    return 'Inclure : $description';
  }

  @override
  String get blogApproveCopy => 'J\'approuve exactement cette copie publique';

  @override
  String get blogApproveCopyNote =>
      'Modifier ou masquer le chapitre d\'origine invalide le lien. Les copies enregistrées en dehors de Connect ne peuvent pas être récupérées.';

  @override
  String get blogSaving => 'Enregistrement…';

  @override
  String get blogRequestOtherApproval =>
      'Demander l\'accord de l\'autre auteur';

  @override
  String get blogCreatePublicLink => 'Créer un lien public';

  @override
  String get blogJointApprovalRecorded =>
      'Ton accord est enregistré. Le lien reste indisponible jusqu\'à l\'accord de l\'autre auteur.';

  @override
  String get blogPublicCopyReady => 'Ta copie publique est prête.';

  @override
  String get blogCopyPublicLink => 'Copier le lien public';

  @override
  String get blogManageSharedLinks => 'Gérer les liens partagés';

  @override
  String blogFollowerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abonnés',
      one: '1 abonné',
    );
    return '$_temp0';
  }

  @override
  String get blogUnfollowFailed =>
      'Impossible d\'arrêter de suivre pour le moment. Réessaie.';

  @override
  String get blogFollowFailed =>
      'Impossible de suivre cet auteur pour le moment. Réessaie.';

  @override
  String get blogFollowingButton => 'Abonné';

  @override
  String get blogFollowTheirChapters => 'Suivre ses chapitres';

  @override
  String get blogRewardsIntro =>
      'Quand ce que tu partages touche quelqu\'un, ça compte. Les j\'aime, les commentaires approuvés et les nouveaux abonnés te rapportent des XP pour ton niveau. Les récompenses viennent de ce que font les lecteurs, jamais de simples appuis, et chacune n\'est donnée qu\'une fois.';

  @override
  String blogRewardDailyCap(int cap) {
    return 'Jusqu\'à $cap XP par jour';
  }

  @override
  String blogRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String get blogSignInWriters =>
      'Connecte-toi pour voir les auteurs que tu suis.';

  @override
  String get blogWritersLoadFailed =>
      'Impossible de charger les auteurs que tu suis.';

  @override
  String get blogNoWriters => 'Aucun auteur pour l\'instant.';

  @override
  String get blogNoWritersBody =>
      'Quand un chapitre te parle, appuie sur « Suivre ses chapitres ». Ses nouveaux chapitres se retrouveront dans « Abonnements ».';

  @override
  String blogLatest(String title) {
    return 'Dernier : $title';
  }

  @override
  String get blogReactionFailed => 'Ta réaction n\'est pas passée. Réessaie.';

  @override
  String blogCannotLikeOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Tu ne peux pas aimer ta propre photo',
      'other': 'Tu ne peux pas aimer ton propre chapitre',
    });
    return '$_temp0';
  }

  @override
  String blogYouReacted(String reaction) {
    return 'Ta réaction : $reaction. Appuie pour l\'annuler';
  }

  @override
  String blogLikeThis(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Aimer cette photo',
      'other': 'Aimer ce chapitre',
    });
    return '$_temp0';
  }

  @override
  String blogCannotReactOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Tu ne peux pas réagir à ta propre photo',
      'other': 'Tu ne peux pas réagir à ton propre chapitre',
    });
    return '$_temp0';
  }

  @override
  String get blogReactTooltip =>
      'Réagir : Je t\'entends, Moi aussi, Je t\'envoie un câlin…';

  @override
  String blogCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commentaires',
      one: '1 commentaire',
    );
    return '$_temp0';
  }

  @override
  String blogWaitingForYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '· $count t\'attendent',
      one: '· $count t\'attend',
    );
    return '$_temp0';
  }

  @override
  String get blogFeatured => 'À la une';

  @override
  String blogTierNeedsBoth(int likes, int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes j\'aime',
      one: '1 j\'aime',
    );
    String _temp1 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments commentaires',
      one: '1 commentaire',
    );
    String _temp2 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls murs',
      one: '1 mur',
    );
    return 'Encore $_temp0 et $_temp1 pour atteindre $_temp2';
  }

  @override
  String blogTierNeedsLikes(int likes, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes j\'aime',
      one: '1 j\'aime',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls murs',
      one: '1 mur',
    );
    return 'Encore $_temp0 pour atteindre $_temp1';
  }

  @override
  String blogTierNeedsComments(int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments commentaires',
      one: '1 commentaire',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls murs',
      one: '1 mur',
    );
    return 'Encore $_temp0 pour atteindre $_temp1';
  }

  @override
  String blogTierAlmostThere(int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: 'Presque : prochaine étape, $walls murs',
      one: 'Presque : prochaine étape, 1 mur',
    );
    return '$_temp0';
  }

  @override
  String blogOnWalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sur $count murs',
      one: 'Sur 1 mur',
    );
    return '$_temp0';
  }

  @override
  String blogProgressToward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Progression vers $count murs',
      one: 'Progression vers 1 mur',
    );
    return '$_temp0';
  }

  @override
  String get blogReachIdle => 'Les lecteurs peuvent faire voyager ce chapitre';

  @override
  String get blogReachLive =>
      'Des membres qui ont aimé des histoires comme la tienne la lisent en ce moment.';

  @override
  String get blogFeaturedStories => 'Histoires à la une';

  @override
  String get blogFeaturedCaption =>
      'Des histoires que d\'autres membres ont adorées, livrées sur ton mur.';

  @override
  String blogByAuthor(String name) {
    return 'par $name';
  }

  @override
  String get blogLikes => 'J\'aime';

  @override
  String get blogComments => 'Commentaires';

  @override
  String get blogCommentHint => 'Qu\'est-ce qui t\'a marqué ?';

  @override
  String get blogCommentApproved =>
      'Approuvé. Toutes les personnes qui peuvent lire ce chapitre le voient désormais.';

  @override
  String get blogCommentSent => 'Envoyé à l\'auteur pour approbation';

  @override
  String get blogCommentSendFailed =>
      'Ton commentaire n\'est pas parti. Tes mots sont toujours là, tu peux réessayer.';

  @override
  String blogCommentDeclined(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Refusé. Il n\'apparaîtra pas sur ta photo.',
      'other': 'Refusé. Il n\'apparaîtra pas sur ton chapitre.',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveFailed => 'Ça n\'a pas été enregistré. Réessaie.';

  @override
  String get blogDeleteCommentTitle => 'Supprimer ce commentaire ?';

  @override
  String get blogDeleteCommentMessage =>
      'Il sera supprimé pour tout le monde. Cette action est irréversible.';

  @override
  String get blogDeleteComment => 'Supprimer le commentaire';

  @override
  String get blogCommentDeleted => 'Commentaire supprimé.';

  @override
  String get blogCommentDeleteFailed =>
      'Le commentaire n\'a pas pu être supprimé. Réessaie.';

  @override
  String get blogCommentsAuthorNote =>
      'Les nouveaux commentaires attendent ton approbation avant d\'être visibles par les autres.';

  @override
  String get blogCommentsReaderNote =>
      'L\'auteur lit chaque commentaire en premier et choisit ce qu\'il partage.';

  @override
  String get blogLeaveComment => 'Laisser un commentaire';

  @override
  String get blogSendToAuthor => 'Envoyer à l\'auteur';

  @override
  String get blogCommentsLoadFailed =>
      'Impossible de charger les commentaires.';

  @override
  String get blogWaitingApproval => 'En attente de ton approbation';

  @override
  String get blogNoCommentsInvite =>
      'Pas encore de commentaires. Dis quelque chose de gentil pour lancer la conversation.';

  @override
  String get blogNoCommentsShared =>
      'Aucun commentaire partagé pour l\'instant.';

  @override
  String get blogCommentNotShared =>
      'L\'auteur a choisi de ne pas partager celui-ci.';

  @override
  String get blogYou => 'Toi';

  @override
  String get blogCommentOptions => 'Options du commentaire';

  @override
  String get blogReportComment => 'Signaler le commentaire';

  @override
  String get blogApprove => 'Approuver';

  @override
  String get blogDecline => 'Refuser';

  @override
  String get blogSignInContinue => 'Connecte-toi pour continuer.';

  @override
  String get blogPrivateResponseTitle => 'Une réponse privée';

  @override
  String blogPrivateResponseHelp(String invitation) {
    return '$invitation\n\nSeul l\'auteur reçoit cette réponse. Il peut accepter ou refuser un échange facultatif. Jusqu\'à cinq nouvelles réponses par jour, dont une seule au même auteur.';
  }

  @override
  String get blogSendPrivateResponse => 'Envoyer la réponse privée';

  @override
  String get blogTextSaveUnconfirmed =>
      'Impossible de confirmer l\'enregistrement. Tes mots sont toujours là ; réessaie ou recharge l\'échange enregistré.';

  @override
  String get blogLeaveUnsentTitle => 'Quitter sans envoyer ?';

  @override
  String get blogLeaveUnsentMessage => 'Tes mots non envoyés seront supprimés.';

  @override
  String get blogLeave => 'Quitter';

  @override
  String get blogOwnWordsLabel => 'Avec tes propres mots';

  @override
  String get blogSending => 'Envoi…';

  @override
  String get blogChangeUnconfirmed =>
      'Impossible de confirmer la modification. Actualise pour vérifier.';

  @override
  String get blogConnectionsTitle => 'Tes liens autour des chapitres';

  @override
  String get blogRefresh => 'Actualiser';

  @override
  String get blogConnectionsIntro =>
      'Les belles histoires laissent de la place à quelqu\'un d\'autre.';

  @override
  String get blogConnectionsLoadFailed => 'Impossible de charger tes liens.';

  @override
  String get blogResponsesEmpty =>
      'Les réponses à tes chapitres et celles que tu envoies apparaîtront ici. Rien n\'exige de réponse immédiate.';

  @override
  String get blogPublicationsEmpty =>
      'Tes aperçus publics et les liens approuvés à deux apparaîtront ici.';

  @override
  String get blogNoticesEmpty => 'Aucun avis de modération à afficher.';

  @override
  String get blogResponseRevealed => 'Votre chapitre commun est prêt';

  @override
  String get blogResponseIncoming => 'Une réponse pour toi';

  @override
  String get blogResponseSent => 'Envoyé · à son choix, à son rythme';

  @override
  String get blogResponseAccepted => 'Un échange, à votre rythme';

  @override
  String get blogResponseClosed => 'Cet échange est clos';

  @override
  String get blogOpenExchange => 'Ouvrir l\'échange privé';

  @override
  String get blogPublicationLive => 'Copie publique en ligne';

  @override
  String get blogPublicationRemoved => 'Retiré par la modération';

  @override
  String get blogPublicationNeedsBoth =>
      'Nécessite les deux accords et un chapitre d\'origine à jour';

  @override
  String get blogPublicationSourceChanged =>
      'Source modifiée · crée un nouvel aperçu pour partager à nouveau';

  @override
  String get blogApprovePublicCopyTitle => 'Approuver cette copie publique ?';

  @override
  String get blogApprovePublicCopyMessage =>
      'Les mots ci-dessus seront accessibles à toute personne ayant le lien. Chacun de vous peut retirer le partage. Aucun nom n\'est ajouté automatiquement, mais les mots peuvent permettre de t\'identifier.';

  @override
  String get blogApprovePublicCopyAction => 'Approuver la copie publique';

  @override
  String get blogApproveExactPublicCopy =>
      'Approuver exactement la copie publique';

  @override
  String get blogCopyLink => 'Copier le lien';

  @override
  String get blogWithdrawLinkTitle => 'Retirer ce lien ?';

  @override
  String get blogWithdrawLinkMessage =>
      'La copie publique deviendra indisponible. Les copies déjà enregistrées par d\'autres ne peuvent pas être récupérées.';

  @override
  String get blogWithdrawLink => 'Retirer le lien';

  @override
  String get blogYourAppeal => 'Ton recours';

  @override
  String get blogRequestReview => 'Demander un nouvel examen';

  @override
  String get blogRequestReviewHelp =>
      'Explique ce que la personne chargée de l\'examen devrait reconsidérer. Ton recours est transmis en privé à l\'équipe de confiance. Le contenu retiré reste masqué pendant l\'examen.';

  @override
  String get blogSubmitAppeal => 'Envoyer le recours';

  @override
  String get blogAppealDecision => 'Contester cette décision';

  @override
  String get blogPrevious => 'Précédent';

  @override
  String get blogMore => 'Plus';

  @override
  String get blogExchangeChangeFailed =>
      'Impossible de confirmer cette modification. Actualise et réessaie.';

  @override
  String get blogExchangeTitle => 'Un échange de chapitres privé';

  @override
  String get blogExchangeUnavailable => 'Cet échange n\'est plus disponible.';

  @override
  String blogExchangeWith(String name) {
    return 'Avec $name';
  }

  @override
  String get blogExchangeIntro =>
      'Une réponse est une invitation, jamais une obligation. Cet échange ne crée pas de match et ne débloque pas la discussion.';

  @override
  String get blogAcceptExchange => 'Accepter un échange';

  @override
  String get blogDeclineKindly => 'Refuser gentiment';

  @override
  String get blogResponseSentNote =>
      'Ta réponse a été envoyée. Pas de compte à rebours, pas besoin de relancer.';

  @override
  String get blogExchangeClosedNote =>
      'Cet échange est clos. Fais de la place pour une autre rencontre, à ton rythme.';

  @override
  String get blogOneStoryEach => 'Une petite histoire chacun.';

  @override
  String get blogOneStoryEachBody =>
      'Ajoute une petite suite, un souvenir ou ta version du moment. Les deux contributions apparaissent ensemble, seulement une fois que vous avez tous les deux envoyé la vôtre.';

  @override
  String get blogYourSideTitle => 'Ta part du chapitre';

  @override
  String get blogYourSideHelp =>
      'Partage jusqu\'à 1 000 caractères. L\'autre personne ne pourra pas le lire avant d\'avoir contribué à son tour. Une fois envoyés, les mots ne peuvent plus être modifiés ; tu peux retirer l\'échange à tout moment.';

  @override
  String get blogSubmitContribution => 'Envoyer ma contribution';

  @override
  String get blogAddContribution => 'Ajouter ma contribution';

  @override
  String get blogYourContribution => 'Ta contribution';

  @override
  String blogPartnerContribution(String name) {
    return 'Contribution de $name';
  }

  @override
  String get blogShapeDate => 'Imaginer un rendez-vous ensemble';

  @override
  String get blogInspiredNote => 'Inspiré par notre échange de chapitres.';

  @override
  String get blogTryStudio => 'Essayer le Studio Premier Chapitre';

  @override
  String get blogDatePlanningUnavailable =>
      'La planification d\'un rendez-vous est disponible si vous avez un match actif et que votre conversation est débloquée.';

  @override
  String get blogProposeJournalPage => 'Proposer une page de journal partagée';

  @override
  String get blogSourceUnavailable =>
      'Le chapitre d\'origine n\'est pas disponible.';

  @override
  String get blogContributionSaved =>
      'Ta contribution est enregistrée en privé. Elle sera révélée quand vous serez prêts tous les deux.';

  @override
  String get blogWithdrawExchangeTitle => 'Retirer cet échange ?';

  @override
  String get blogWithdrawExchangeMessage =>
      'La réponse et les contributions ne seront plus accessibles à aucun de vous deux. Les liens publics communs cesseront aussi de fonctionner.';

  @override
  String get blogWithdrawExchange => 'Retirer l\'échange';

  @override
  String get blogReportExchange => 'Signaler l\'échange';

  @override
  String get blogBlockMessageExchange =>
      'Le contact et l\'accès aux chapitres de l\'autre prendront fin.';

  @override
  String get blogBlockFailed => 'Impossible de bloquer ce membre.';

  @override
  String get notificationsReadAll => 'Tout marquer comme lu';

  @override
  String get notificationsFallbackTitle => 'Notification';

  @override
  String get notificationsLoadFailed =>
      'Impossible de charger les notifications.';

  @override
  String get notificationsPrefsUpdateFailed =>
      'Impossible de mettre à jour les préférences de notification.';

  @override
  String notificationsAgoMinutes(int count) {
    return 'il y a $count min';
  }

  @override
  String notificationsAgoHours(int count) {
    return 'il y a $count h';
  }

  @override
  String notificationsAgoDays(int count) {
    return 'il y a $count j';
  }

  @override
  String get wallsReactEyebrow => 'RÉAGIR';

  @override
  String wallsReactQuestion(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Que ressens-tu face à cette photo ?',
      'other': 'Que ressens-tu face à ce chapitre ?',
    });
    return '$_temp0';
  }

  @override
  String get wallsReactBody =>
      'Ta réaction leur montre qu’ils ont été entendus. Chaque réaction compte comme un like.';

  @override
  String get wallsReactRemove => 'Retirer ma réaction';

  @override
  String wallsReactionsSemantics(String list) {
    return 'Réactions : $list';
  }

  @override
  String get wallsReactionLove => 'J’adore';

  @override
  String get wallsReactionHearYou => 'Je t’entends';

  @override
  String get wallsReactionMeToo => 'Moi aussi';

  @override
  String get wallsReactionWithYou => 'Je suis avec toi';

  @override
  String get wallsReactionHug => 'Je t’envoie un câlin';

  @override
  String get wallsReactionProud => 'Fier de toi';

  @override
  String get wallsSignInRequired => 'Connecte-toi pour voir ton mur.';

  @override
  String get celebrationCoverHeadline =>
      'Ta photo est la couverture de la semaine';

  @override
  String celebrationReachHeadline(String kind, int reach) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'photo': 'Ta photo a atteint $reach murs',
      'other': 'Ton chapitre a atteint $reach murs',
    });
    return '$_temp0';
  }

  @override
  String get celebrationCoverMessage =>
      'Les membres ont adoré. Tout le monde la voit dans Aujourd’hui cette semaine.';

  @override
  String get celebrationReachMessage =>
      'Les membres ont adoré. C’est maintenant sur leurs murs Aujourd’hui.';

  @override
  String celebrationQuotedTitle(String title) {
    return '« $title »';
  }

  @override
  String get celebrationBarrier => 'Célébration';

  @override
  String get celebrationLovely => 'Génial';

  @override
  String get celebrationSeePhoto => 'Voir la photo';

  @override
  String get celebrationSeeChapter => 'Voir le chapitre';

  @override
  String rewardXpPill(int xp) {
    return '+$xp XP';
  }

  @override
  String get rewardClaimedTitle => 'Récompense obtenue';

  @override
  String rewardNameDescription(String name, String description) {
    return '$name · $description';
  }

  @override
  String rewardPlusXpAnnouncement(int xp) {
    return 'plus $xp XP';
  }

  @override
  String rewardSourceXpLine(String source, int xp) {
    return '$source +$xp XP';
  }

  @override
  String rewardAndMore(int count) {
    return 'et $count de plus';
  }

  @override
  String rewardBadgeLine(String badge) {
    return 'Badge : $badge';
  }

  @override
  String rewardLevelReached(int level) {
    return 'Niveau $level atteint';
  }

  @override
  String rewardBadgesEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count badges obtenus',
      one: 'Badge obtenu',
    );
    return '$_temp0';
  }

  @override
  String get rewardYourRewardsToday => 'Tes récompenses du jour';

  @override
  String rewardNewRewards(int count) {
    return '$count nouvelles récompenses';
  }

  @override
  String get rewardSourceStoryPublished => 'Chapitre publié';

  @override
  String get rewardSourcePhotoShared => 'Photo partagée';

  @override
  String get rewardSourceLikeReceived => 'Un membre a aimé ton travail';

  @override
  String get rewardSourceCommentReceived =>
      'Nouveau commentaire sur ton travail';

  @override
  String get rewardSourceCommentApproved => 'Ton commentaire a été approuvé';

  @override
  String get rewardSourceSubscriberGained => 'Nouvel abonné';

  @override
  String get rewardSourceWallTierReached => 'Palier de mur atteint';

  @override
  String get rewardSourceCoverOfWeek => 'Couverture de la semaine';

  @override
  String get rewardSourceDailyPromptSubmitted => 'Question du jour répondue';

  @override
  String get rewardLineStoryPublished =>
      'Ton chapitre est lancé dans le monde.';

  @override
  String get rewardLinePhotoShared => 'Ta photo a rejoint le thème.';

  @override
  String get rewardLineLikeReceived =>
      'Quelqu’un a adoré ce que tu as partagé.';

  @override
  String get rewardLineCommentReceived =>
      'Un lecteur a rejoint la conversation.';

  @override
  String get rewardLineSubscriberGained =>
      'Quelqu’un attend ton prochain chapitre.';

  @override
  String get rewardLineWallTierReached => 'Ton travail a atteint plus de murs.';

  @override
  String get rewardLineCoverOfWeek =>
      'Tout le monde le voit dans Aujourd’hui cette semaine.';

  @override
  String get rewardLineOther => 'Obtenu pour une activité qui compte.';

  @override
  String get rewardNewBadgeFallback => 'Nouveau badge';

  @override
  String get blockedUnknownUser => 'Utilisateur inconnu';

  @override
  String get themeTaglineBluerose =>
      'Velours de minuit, roses saphir et un liseré platine.';

  @override
  String get themeTaglineBluelotus =>
      'Eau au clair de lune, pétales saphir et un cœur doré.';

  @override
  String discoverMessageLikeSent(String name) {
    return 'Love envoyé à $name. Vous pourrez discuter dès que $name te likera en retour.';
  }

  @override
  String get notificationsDismissFailed =>
      'Impossible de supprimer cette notification. Réessaie.';

  @override
  String get notificationsReadAllFailed =>
      'Impossible de tout marquer comme lu. Réessaie.';

  @override
  String get blogReportSubmitted => 'Signalement envoyé. Merci.';

  @override
  String get settingsSectionAccount => 'Compte';

  @override
  String settingsSignedInAs(String username) {
    return 'Session ouverte en tant que @$username';
  }

  @override
  String get settingsSignOut => 'Se déconnecter';

  @override
  String get settingsSignOutSubtitle => 'Termine ta session sur cet appareil';

  @override
  String get settingsSignOutAllTitle => 'Se déconnecter de tous les appareils';

  @override
  String get settingsSignOutAllSubtitle =>
      'Termine toutes tes sessions, sur chaque téléphone et navigateur';

  @override
  String get settingsSignOutConfirmTitle => 'Se déconnecter ?';

  @override
  String get settingsSignOutConfirmBody =>
      'Tu auras besoin de ton nom d’utilisateur et de ton mot de passe pour te reconnecter sur cet appareil.';

  @override
  String get settingsSignOutAllConfirmTitle =>
      'Se déconnecter de tous les appareils ?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'Ta session prendra fin sur chaque téléphone, tablette et navigateur, y compris celui-ci. Toute personne connectée à ton compte ailleurs sera déconnectée.';

  @override
  String get settingsSignOutAllConfirmAction => 'Se déconnecter partout';

  @override
  String get settingsSignOutAllFailed =>
      'Impossible de déconnecter tes autres appareils. Vérifie ta connexion et réessaie.';
}
