// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get navDiscover => 'Entdecken';

  @override
  String get navMatches => 'Matches';

  @override
  String get navEngage => 'Mitmachen';

  @override
  String get navProfile => 'Profil';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsEditProfileTitle => 'Profil bearbeiten';

  @override
  String get settingsEditProfileSubtitle => 'Deine Angaben aktualisieren';

  @override
  String get settingsPhotosTitle => 'Fotos';

  @override
  String get settingsPhotosSubtitle => 'Deine Fotos verwalten';

  @override
  String get settingsSectionPreferences => 'Präferenzen';

  @override
  String get settingsAppearanceTitle => 'Darstellung';

  @override
  String get settingsAppearanceSubtitle => 'In deinem Konto gespeichert';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsThemeMatchDevice => 'Wie Gerät';

  @override
  String get settingsLooksTitle => 'Looks';

  @override
  String get settingsLooksClassicDescription =>
      'Warm ivory and forest by day. Soft mint and deep forest by night.';

  @override
  String get settingsLooksClassicLabel => 'Today';

  @override
  String get settingsThemeSaveFailed =>
      'Dein Design konnte nicht gespeichert werden. Bitte versuch es noch einmal.';

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageSubtitle => 'App-Sprache auswählen';

  @override
  String get settingsDatingPreferencesTitle => 'Dating-Vorlieben';

  @override
  String get settingsDatingPreferencesSubtitle => 'Alter, Ort, Interessen';

  @override
  String get settingsAccountDataTitle => 'Konto & Daten';

  @override
  String get settingsAccountDataSubtitle =>
      'Konto verbergen, herunterladen oder löschen';

  @override
  String get settingsNotificationsTitle => 'Benachrichtigungen';

  @override
  String get settingsNotificationsSubtitle =>
      'Push- und E-Mail-Benachrichtigungen';

  @override
  String get settingsSectionEngagement => 'Mitmachen';

  @override
  String get settingsTrustBadgesTitle => 'Vertrauensabzeichen';

  @override
  String get settingsTrustBadgesSubtitle =>
      'Verdiente Abzeichen und Vertrauensverlauf ansehen';

  @override
  String get settingsTrustFiltersTitle => 'Vertrauensfilter';

  @override
  String get settingsTrustFiltersSubtitle =>
      'Vertrauensanforderungen fürs Entdecken festlegen';

  @override
  String get settingsConversationRoomsTitle => 'Gesprächsräume';

  @override
  String get settingsConversationRoomsSubtitle =>
      'Räume durchstöbern, beitreten, verlassen und moderieren';

  @override
  String get settingsFriendsTitle => 'Freunde & Kontakte';

  @override
  String get settingsFriendsSubtitle => 'Freundschaften aufbauen und pflegen';

  @override
  String get settingsCallHistoryTitle => 'Anrufverlauf';

  @override
  String get settingsCallHistorySubtitle => 'Vergangene Anrufe ansehen';

  @override
  String get settingsMatchNudgesTitle => 'Match-Anstupser';

  @override
  String get settingsMatchNudgesSubtitle =>
      'Eingeschlafene Gespräche wieder anstoßen';

  @override
  String get settingsSubscriptionsTitle => 'Abos';

  @override
  String get settingsSubscriptionsSubtitle =>
      'Tarife, Berechtigungen und Zahlungen';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsPrivacySafetyTitle => 'Privatsphäre & Sicherheit';

  @override
  String get settingsPrivacySafetySubtitle =>
      'Deine Privatsphäre-Einstellungen verwalten';

  @override
  String get settingsGovernmentVerificationTitle => 'Ausweisprüfung';

  @override
  String get settingsGovernmentVerificationSubtitle =>
      'Status deiner Identitätsprüfung ansehen';

  @override
  String get settingsQaVerificationUploadTitle => 'QA-Verifizierungs-Upload';

  @override
  String get settingsQaVerificationUploadSubtitle =>
      'Ausweis- und Selfie-Ablauf nur für die Automatisierung';

  @override
  String get settingsHelpSupportTitle => 'Hilfe & Support';

  @override
  String get settingsHelpSupportSubtitle => 'FAQ und Kontakt zum Support';

  @override
  String get settingsAboutTitle => 'Über die App';

  @override
  String get settingsAboutSubtitle => 'App-Details und Technik';

  @override
  String get settingsLogout => 'Abmelden';

  @override
  String get languageTitle => 'Sprache';

  @override
  String get languageIntro =>
      'Wähl die Sprache, in der Connect angezeigt wird. Deine Wahl wird in deinem Konto gespeichert und gilt auf jedem Gerät, auf dem du dich anmeldest.';

  @override
  String get languageUseDevice => 'Gerätesprache verwenden';

  @override
  String get languageUseDeviceSubtitle =>
      'Folgt der Spracheinstellung deines Handys';

  @override
  String get languageSaveFailed =>
      'Deine Sprache konnte nicht gespeichert werden. Bitte versuch es noch einmal.';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsInboxTitle => 'Posteingang';

  @override
  String get notificationsInboxCaughtUp => 'Du bist auf dem neuesten Stand';

  @override
  String notificationsInboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ungelesen',
      one: '1 ungelesen',
    );
    return '$_temp0';
  }

  @override
  String get notificationsInAppTitle => 'In-App-Benachrichtigungen';

  @override
  String get notificationsInAppSubtitle =>
      'Benachrichtigungen anzeigen, während du die App nutzt';

  @override
  String get notificationsPushTitle => 'Push-Benachrichtigungen';

  @override
  String get notificationsPushSubtitle =>
      'Zustellung erlauben, wenn die App im Hintergrund ist';

  @override
  String get notificationsNewMatchesTitle => 'Neue Matches';

  @override
  String get notificationsNewMatchesSubtitle =>
      'Bescheid bekommen, wenn ihr ein Match seid';

  @override
  String get notificationsNewMessagesTitle => 'Neue Nachrichten';

  @override
  String get notificationsNewMessagesSubtitle =>
      'Bescheid bekommen bei Chat-Nachrichten';

  @override
  String get notificationsLikesTitle => 'Likes';

  @override
  String get notificationsLikesSubtitle =>
      'Bescheid bekommen, wenn dich jemand liked';

  @override
  String get notificationsMatchNudgesTitle => 'Match-Anstupser';

  @override
  String get notificationsMatchNudgesSubtitle =>
      'Bescheid bekommen, wenn ein Match dich anstupst';

  @override
  String get notificationsIncomingCallsTitle => 'Eingehende Anrufe';

  @override
  String get notificationsIncomingCallsSubtitle =>
      'Hinweise auf eingehende Anrufe anzeigen';

  @override
  String get notificationsSafetyTitle => 'Sicherheitsupdates';

  @override
  String get notificationsSafetySubtitle =>
      'Wichtige Updates zu deinem Sicherheitsstatus erhalten';

  @override
  String get notificationsFriendPlansTitle => 'Date-Pläne von Freunden';

  @override
  String get notificationsFriendPlansSubtitle =>
      'Erfahren, wenn ein Freund ein Date plant oder sich meldet';

  @override
  String get welcomeTagline => 'Fürs echte Leben gemacht.';

  @override
  String get welcomePhotoNote => 'Offline ist das Ziel.';

  @override
  String get welcomeHeadlineLead => 'Eine gute Geschichte\nbeginnt mit ';

  @override
  String get welcomeHeadlineAccent => 'Hallo.';

  @override
  String get welcomeBody =>
      'Finde jemanden, der sich wie dein Typ Mensch anfühlt. Der Rest ergibt sich.';

  @override
  String get welcomeCreateAccount => 'Konto erstellen';

  @override
  String get welcomeAlreadyMember => 'Schon Mitglied? ';

  @override
  String get welcomeSignIn => 'Anmelden';

  @override
  String get welcomeFooter => '18+  ·  Dein Tempo. Deine Entscheidung.';

  @override
  String get authBackTooltip => 'Zurück zur Startseite';

  @override
  String get authHeadline => 'Schön, dich zu sehen.';

  @override
  String get authSubtitle => 'Melde dich mit Benutzernamen und Passwort an';

  @override
  String get authWelcomeBack => 'Willkommen zurück';

  @override
  String get authNextHello => 'Dein nächstes Hallo wartet schon.';

  @override
  String get authUsernameHint => 'benutzername';

  @override
  String get authPasswordHint => 'Passwort';

  @override
  String get authShowPassword => 'Passwort anzeigen';

  @override
  String get authHidePassword => 'Passwort verbergen';

  @override
  String get authCantSignIn => 'Du kannst dich nicht anmelden?';

  @override
  String get authSignIn => 'Anmelden';

  @override
  String get authPrivacyNote =>
      'Dein Passwort wird nur beim Anmelden gesendet und nie in der App gespeichert.';

  @override
  String get authEnterUsername => 'Bitte gib deinen Benutzernamen ein.';

  @override
  String get authEnterPassword => 'Bitte gib dein Passwort ein.';

  @override
  String get commonYes => 'Ja';

  @override
  String get commonNo => 'Nein';

  @override
  String get planVenueCoffee => 'Kaffee';

  @override
  String get planVenueMeal => 'Essen gehen';

  @override
  String get planVenueDrinks => 'Drinks';

  @override
  String get planVenueWalk => 'Spaziergang';

  @override
  String get planVenueActivity => 'Eine Aktivität';

  @override
  String get planVenueEvent => 'Ein Event';

  @override
  String get planVenueVideoCall => 'Videoanruf';

  @override
  String get planVenueOther => 'Etwas anderes';

  @override
  String planProposeTitle(String name) {
    return 'Plan ein Date mit $name';
  }

  @override
  String get planProposeSubtitle =>
      'Shape a first hello together. Contact sharing starts off.';

  @override
  String get planProposeButton => 'Vorschlagen';

  @override
  String planHeadlineProposed(String name) {
    return '$name hat ein Date vorgeschlagen';
  }

  @override
  String planHeadlineWaiting(String name) {
    return 'Warten auf $name';
  }

  @override
  String get planHeadlineUpcoming => 'Das Date steht';

  @override
  String get planHeadlineCheckin => 'Wie ist es gelaufen?';

  @override
  String get planHeadlineDebrief => 'Wie war es?';

  @override
  String get planHeadlineDebriefComplete => 'Nachbesprechung abgeschlossen';

  @override
  String planHeadlineWaitingDebrief(String name) {
    return 'Warten auf die Nachbesprechung von $name';
  }

  @override
  String get planHeadlineCheckedInSafe => 'Du hast dich sicher gemeldet';

  @override
  String get planHeadlineFriendsAlerted => 'Your request for help is recorded';

  @override
  String get planHeadlineDefault => 'Plan';

  @override
  String get planStatusProposed => 'Vorgeschlagen';

  @override
  String get planStatusConfirmed => 'Bestätigt';

  @override
  String get planDebriefButton => 'Kurze Nachbesprechung';

  @override
  String get planDecline => 'Ablehnen';

  @override
  String get planAccept => 'Annehmen';

  @override
  String get planFriendsKnowAccepted =>
      'Choose trusted contacts to share your updates.';

  @override
  String get planFriendsKnowProposed =>
      'Contact sharing is optional for each plan.';

  @override
  String get planCancel => 'Plan absagen';

  @override
  String get planNeedHelp => 'Ich brauche Hilfe';

  @override
  String get planImSafe => 'Mir geht\'s gut';

  @override
  String get planCancelDialogTitle => 'Diesen Plan absagen?';

  @override
  String planCancelDialogBody(String name) {
    return '$name und alle, mit denen du ihn geteilt hast, werden informiert.';
  }

  @override
  String get planKeepIt => 'Behalten';

  @override
  String get planProposeIntro =>
      'This starts between you and your date. After proposing, choose trusted contacts if you want to share plan and check-in updates.';

  @override
  String get planSectionWhen => 'Wann';

  @override
  String get planSectionWhat => 'Was';

  @override
  String get planSectionGroups => 'Trusted contacts';

  @override
  String planDurationHours(int hours) {
    return '$hours Std.';
  }

  @override
  String get planPlaceLabel => 'Ort (optional)';

  @override
  String get planPlaceHint => 'Ein öffentlicher Ort ist am besten';

  @override
  String get planAreaLabel => 'Gegend oder Viertel';

  @override
  String get planNoteLabel => 'Notiz für dein Match (optional)';

  @override
  String get planFutureTimeError => 'Wähl eine Zeit in der Zukunft.';

  @override
  String get planProposeFailed =>
      'Dieser Plan konnte nicht vorgeschlagen werden.';

  @override
  String get planSendButton => 'Plan senden';

  @override
  String get planAcceptTitle => 'Plan annehmen?';

  @override
  String get planAcceptIntro =>
      'Accept this plan with your date. Choose trusted contacts afterwards if you want to share your updates.';

  @override
  String get planAcceptButton => 'Accept plan';

  @override
  String debriefTitle(String name) {
    return 'Wie war es mit $name?';
  }

  @override
  String get debriefIntro =>
      'Deine Antworten sind privat. Wenn ihr beide bestätigt, dass das Date stattgefunden hat, zählt es für dein Shows-Up-Abzeichen.';

  @override
  String get debriefHappened => 'Hat das Date stattgefunden?';

  @override
  String get debriefMeetAgain => 'Würdest du dich wieder treffen?';

  @override
  String get debriefFeltSafe => 'Hast du dich sicher gefühlt?';

  @override
  String get debriefNoteLabel => 'Noch etwas? (optional)';

  @override
  String get debriefMissingHappened =>
      'Sag uns, ob das Date stattgefunden hat.';

  @override
  String get debriefSaveFailed =>
      'Deine Nachbesprechung konnte nicht gespeichert werden.';

  @override
  String get debriefSave => 'Nachbesprechung speichern';

  @override
  String get debriefUnsafeTitle =>
      'Tut uns leid, dass du dich nicht sicher gefühlt hast';

  @override
  String debriefUnsafeBody(String name) {
    return 'Deine Antwort geht an unser Sicherheitsteam. Möchtest du $name auch melden?';
  }

  @override
  String get debriefNotNow => 'Jetzt nicht';

  @override
  String get debriefReport => 'Melden';

  @override
  String get plansTitle => 'Date-Pläne';

  @override
  String get plansTabMine => 'Meine';

  @override
  String get plansTabFriends => 'Freunde';

  @override
  String get plansEmptyMineTitle => 'Noch keine Pläne';

  @override
  String get plansEmptyMineBody =>
      'Propose a date from a conversation. You choose whether to share plan and check-in updates with trusted contacts.';

  @override
  String plansWith(String name) {
    return 'Mit $name';
  }

  @override
  String get plansNextDecide => 'Warten auf deine Antwort';

  @override
  String plansNextAwait(String name) {
    return 'Warten auf $name';
  }

  @override
  String get plansNextUpcoming => 'Confirmed. Your time together is planned.';

  @override
  String get plansNextCheckin => 'Check in after your date';

  @override
  String get plansNextDebrief => 'Erzähl uns, wie es war';

  @override
  String get plansNextCancelled => 'Abgesagt';

  @override
  String get plansNextDone => 'Erledigt';

  @override
  String get plansEmptyFriendsTitle => 'Noch nichts geteilt';

  @override
  String get plansEmptyFriendsBody =>
      'Plans appear here when friends explicitly choose to share with you.';

  @override
  String get plansViaGroup => 'Shared with you';

  @override
  String get plansViaFriend => 'Trusted contact';

  @override
  String plansFriendNeedsHelp(String name) {
    return '$name hat um Hilfe gebeten. Melde dich jetzt.';
  }

  @override
  String plansFriendMissedCheckin(String name) {
    return '$name hat sich noch nicht gemeldet.';
  }

  @override
  String plansFriendCheckedInSafe(String name, String via) {
    return '$name hat sich sicher gemeldet · $via';
  }

  @override
  String plansFriendStatusLine(String via, String status) {
    return '$via · $status';
  }

  @override
  String get plansStatusWordProposed => 'vorgeschlagen';

  @override
  String get plansStatusWordConfirmed => 'bestätigt';

  @override
  String get plansStatusWordCancelled => 'abgesagt';

  @override
  String get plansStatusWordHappened => 'hat stattgefunden';

  @override
  String get chatEmptyDefault =>
      'Sag Hallo. Nachrichten erscheinen hier für alle in dieser Unterhaltung.';

  @override
  String get chatNotSentRetry =>
      'Nicht gesendet. Tippe auf die Nachricht, um es erneut zu versuchen.';

  @override
  String get chatRetrySend => 'Erneut senden';

  @override
  String get chatCopyText => 'Text kopieren';

  @override
  String get chatDeleteMine => 'Meine Nachricht löschen';

  @override
  String get chatRemoveMessage => 'Nachricht entfernen';

  @override
  String get chatReportMessage => 'Nachricht melden';

  @override
  String get chatThisMember => 'Dieses Mitglied';

  @override
  String get chatMember => 'Mitglied';

  @override
  String get chatCopied => 'Kopiert.';

  @override
  String get chatDeleteFailed =>
      'Löschen hat nicht geklappt. Bitte versuche es erneut.';

  @override
  String get chatSubtitleFriends => 'Freunde';

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
    );
    return '$_temp0';
  }

  @override
  String get chatReconnecting =>
      'Verbindung wird wiederhergestellt. Neue Nachrichten können kurz dauern.';

  @override
  String get chatUnavailable =>
      'Diese Unterhaltung ist nicht verfügbar. Vielleicht bist du kein Mitglied mehr.';

  @override
  String get chatTryAgain => 'Erneut versuchen';

  @override
  String get chatStatusNotSent =>
      'Nicht gesendet · gedrückt halten zum Wiederholen';

  @override
  String get chatStatusSending => 'Wird gesendet…';

  @override
  String get chatMessageRemoved => 'Nachricht entfernt';

  @override
  String chatSemanticsYouAt(String time) {
    return 'Du um $time';
  }

  @override
  String chatSemanticsMemberAt(String name, String time) {
    return '$name um $time';
  }

  @override
  String chatAboutMember(String name) {
    return 'Über $name';
  }

  @override
  String get chatComposerHint => 'Schreib eine Nachricht';

  @override
  String get chatMutedComposerHint => 'Du kannst gerade nichts schreiben';

  @override
  String get chatSend => 'Senden';

  @override
  String chatRoomMutedUntil(String when) {
    return 'Du bist in diesem Raum bis $when stummgeschaltet. Mitlesen kannst du weiterhin.';
  }

  @override
  String get chatRoomMuted =>
      'Du bist in diesem Raum stummgeschaltet. Mitlesen kannst du weiterhin.';

  @override
  String chatReadOnlyUntil(String when) {
    return 'Du kannst diese Unterhaltung lesen, aber bis $when nichts schreiben.';
  }

  @override
  String get chatReadOnly =>
      'Du kannst diese Unterhaltung lesen, aber gerade nichts schreiben.';

  @override
  String get chatMuteTooltip => 'Benachrichtigungen stummschalten';

  @override
  String get chatMutedTooltip => 'Benachrichtigungen stummgeschaltet';

  @override
  String get chatMuteSheetTitle => 'Benachrichtigungen stummschalten';

  @override
  String get chatMuteSheetBody =>
      'Nachrichten kommen hier weiter an, nur ohne Benachrichtigung.';

  @override
  String get chatMuteOneHour => 'Für 1 Stunde';

  @override
  String get chatMuteEightHours => 'Für 8 Stunden';

  @override
  String get chatMuteOneWeek => 'Für 1 Woche';

  @override
  String get chatMuteForever => 'Bis ich sie wieder einschalte';

  @override
  String get chatUnmute => 'Benachrichtigungen wieder einschalten';

  @override
  String chatMutedUntilLabel(String when) {
    return 'Stummgeschaltet bis $when';
  }

  @override
  String get chatMutedIndefinitely =>
      'Stummgeschaltet, bis du die Benachrichtigungen wieder einschaltest.';

  @override
  String get chatMuteDone => 'Benachrichtigungen stummgeschaltet.';

  @override
  String get chatUnmuteDone => 'Benachrichtigungen sind wieder an.';

  @override
  String get chatMuteFailed =>
      'Benachrichtigungen konnten nicht geändert werden. Bitte versuche es erneut.';

  @override
  String get roomsClosedSnack => 'Dieser Raum ist geschlossen.';

  @override
  String get roomsChatNotOpen => 'Der Chat dieses Raums ist noch nicht offen.';

  @override
  String get roomsJoinFailed =>
      'Beitritt hat nicht geklappt. Bitte versuche es erneut.';

  @override
  String get roomsStartRoom => 'Raum starten';

  @override
  String get roomsEyebrow => 'LIVE-CHAT';

  @override
  String get roomsTitle => 'Räume';

  @override
  String get roomsSubtitle =>
      'Schau in eine Unterhaltung rein. Wenn es mit jemandem passt, füg die Person als Freund hinzu.';

  @override
  String get roomsSectionRooms => 'RÄUME';

  @override
  String get roomsSectionYours => 'DEINE RÄUME';

  @override
  String get roomsYoursCaption =>
      'Räume, in denen du bist. Tippe, um weiterzuchatten.';

  @override
  String get roomsSectionLive => 'GERADE LIVE';

  @override
  String get roomsLiveTitle => 'Hier wird gerade geredet';

  @override
  String get roomsSectionBrowse => 'STÖBERN';

  @override
  String get roomsBrowseTitle => 'Finde deinen Raum';

  @override
  String get roomsBrowseCaption =>
      'Immer offen. Wähl ein Thema, sag Hallo und schau, mit wem es passt.';

  @override
  String get roomsNoFriendsHere =>
      'Gerade ist keiner deiner Freunde in einem dieser Räume.';

  @override
  String get roomsNoRoomsInTopic => 'Zu diesem Thema gibt es noch keine Räume.';

  @override
  String get roomsSectionComingUp => 'DEMNÄCHST';

  @override
  String get roomsComingUpCaption =>
      'Räume, die Mitglieder veranstalten. Tritt früh bei, um dir einen Platz zu sichern.';

  @override
  String get roomsCategoryAll => 'Alle';

  @override
  String get roomsCategoryTalk => 'Reden';

  @override
  String get roomsCategoryInterests => 'Interessen';

  @override
  String get roomsCategoryActive => 'Unterwegs';

  @override
  String get roomsCategoryCity => 'Deine Stadt';

  @override
  String get roomsFriendsHereChip => 'Freunde da';

  @override
  String get roomsQuiet => 'Gerade ist es ruhig. Sag als Erstes Hallo.';

  @override
  String roomsPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: '1 Person',
    );
    return '$_temp0';
  }

  @override
  String roomsRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Räumen',
      one: '1 Raum',
    );
    return '$_temp0';
  }

  @override
  String roomsChattingIn(String people, String rooms) {
    return '$people chatten in $rooms';
  }

  @override
  String roomsHereNow(int count) {
    return '$count gerade da';
  }

  @override
  String roomsInTheRoom(int count) {
    return '$count im Raum';
  }

  @override
  String roomsFriendsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Freunde da',
      one: '1 Freund da',
    );
    return '$_temp0';
  }

  @override
  String get roomsHostedByYou => 'Von dir veranstaltet';

  @override
  String roomsHostedBy(String name) {
    return 'Veranstaltet von $name';
  }

  @override
  String get roomsActionOpen => 'Öffnen';

  @override
  String get roomsActionFull => 'Voll';

  @override
  String get roomsActionJoin => 'Beitreten';

  @override
  String roomsStartsAt(String time) {
    return 'Beginnt $time';
  }

  @override
  String roomsStartsOn(String day, String time) {
    return 'Beginnt $day, $time';
  }

  @override
  String get roomsStartNameTooShort =>
      'Gib dem Raum einen Namen mit mindestens 3 Zeichen.';

  @override
  String get roomsStartIntro =>
      'Du veranstaltest ihn: Du kannst Leute verwarnen, stummschalten oder entfernen und den Raum schließen, wenn du fertig bist. Ein Raum zur Zeit.';

  @override
  String get roomsStartNameLabel => 'Name des Raums';

  @override
  String get roomsStartNameHint => 'Bücher-Tausch am Sonntag';

  @override
  String get roomsStartAboutLabel => 'Worum geht’s? (optional)';

  @override
  String get roomsStartTopic => 'Thema';

  @override
  String get roomsStartHowLong => 'Wie lange';

  @override
  String get roomsLength30Min => '30 Min.';

  @override
  String get roomsLength1Hour => '1 Stunde';

  @override
  String get roomsLength2Hours => '2 Stunden';

  @override
  String get roomsStartNow => 'Jetzt starten';

  @override
  String get roomsRoleHost => 'Gastgeber';

  @override
  String get roomsRoleModerator => 'Moderator';

  @override
  String get roomsRoomFallback => 'Raum';

  @override
  String roomsChatEmpty(String room) {
    return 'Du bist drin. Sag Hallo: Alle in $room sehen, was du hier schreibst.';
  }

  @override
  String get roomsPeopleTooltip => 'Leute in diesem Raum';

  @override
  String roomsLeaveTitle(String room) {
    return '$room verlassen?';
  }

  @override
  String get roomsLeaveBody =>
      'Du siehst die Nachrichten dieses Raums dann nicht mehr. Solange er offen ist, kannst du jederzeit zurückkommen.';

  @override
  String get roomsLeaveAction => 'Raum verlassen';

  @override
  String get roomsLeaveFailed =>
      'Verlassen hat nicht geklappt. Bitte versuche es erneut.';

  @override
  String roomsCloseTitle(String room) {
    return '$room schließen?';
  }

  @override
  String get roomsCloseBody =>
      'Der Chat endet für alle im Raum. Das lässt sich nicht rückgängig machen.';

  @override
  String get roomsCloseAction => 'Raum schließen';

  @override
  String get roomsCloseFailed =>
      'Schließen hat nicht geklappt. Bitte versuche es erneut.';

  @override
  String get roomsMenuTooltip => 'Raumoptionen';

  @override
  String get roomsMenuPeople => 'Wer da ist';

  @override
  String get roomsMenuModerate => 'Moderieren';

  @override
  String roomsModerateTitle(String room) {
    return '$room moderieren';
  }

  @override
  String get roomsModerateIntro =>
      'Tippe auf jemanden, um die Person zu verwarnen, stummzuschalten oder zu entfernen. Stummgeschaltete können weiter mitlesen; Entfernte können nach Ende der Sitzung zurückkommen.';

  @override
  String get roomsPeopleIntro =>
      'Passt es mit jemandem? Füg die Person als Freund hinzu, um nach dem Raum weiterzureden.';

  @override
  String get roomsMembersLoadFailed =>
      'Wer da ist, konnte nicht geladen werden.';

  @override
  String get roomsStatusFriend => 'Befreundet';

  @override
  String get roomsStatusHereNow => 'Gerade da';

  @override
  String get roomsStatusInRoom => 'Im Raum';

  @override
  String get roomsStatusGone => 'Nicht mehr im Raum';

  @override
  String roomsStatusMutedUntil(String time) {
    return 'Stumm bis $time';
  }

  @override
  String roomsYouSuffix(String name) {
    return '$name (du)';
  }

  @override
  String roomsRemoveTitle(String name) {
    return '$name aus dem Raum entfernen?';
  }

  @override
  String roomsRemoveBodyAlwaysOn(String name) {
    return '$name verlässt den Chat sofort und kann nach 24 Stunden zurückkommen.';
  }

  @override
  String roomsRemoveBodyHosted(String name) {
    return '$name verlässt den Chat sofort und kann erst nach dem Ende dieses Raums wieder beitreten.';
  }

  @override
  String roomsWarnTitle(String name) {
    return '$name verwarnen?';
  }

  @override
  String roomsWarnBody(String name) {
    return '$name bekommt eine private Erinnerung, freundlich und beim Thema zu bleiben.';
  }

  @override
  String get roomsRemoveAction => 'Entfernen';

  @override
  String get roomsWarnAction => 'Verwarnung senden';

  @override
  String roomsRemovedDone(String name) {
    return '$name wurde aus dem Raum entfernt.';
  }

  @override
  String roomsWarnedDone(String name) {
    return 'Verwarnung an $name gesendet.';
  }

  @override
  String get roomsModerationFailed =>
      'Das hat nicht geklappt. Versuch es nochmal.';

  @override
  String roomsBlockedDone(String name) {
    return 'Du hast $name blockiert. Ihr seht hier die Nachrichten des anderen nicht mehr.';
  }

  @override
  String get roomsReport => 'Melden';

  @override
  String get roomsBlock => 'Blockieren';

  @override
  String get roomsModerateEyebrow => 'MODERIEREN';

  @override
  String get roomsWarn => 'Verwarnen';

  @override
  String get roomsRemoveFromRoom => 'Aus dem Raum entfernen';

  @override
  String get roomsMute => 'Stummschalten';

  @override
  String get roomsUnmute => 'Stummschaltung aufheben';

  @override
  String roomsMuteSheetTitle(String name) {
    return '$name stummschalten?';
  }

  @override
  String roomsMuteSheetBody(String name) {
    return '$name kann den Chat weiter lesen, aber bis zum Ende der Stummschaltung nichts schreiben und bekommt eine private Nachricht.';
  }

  @override
  String get roomsMuteTenMinutes => 'Für 10 Minuten';

  @override
  String get roomsMuteOneHour => 'Für 1 Stunde';

  @override
  String get roomsMuteUntilEnd => 'Bis der Raum endet';

  @override
  String get roomsMuteOneDay => 'Für 24 Stunden';

  @override
  String roomsMutedDone(String name) {
    return '$name ist stummgeschaltet.';
  }

  @override
  String roomsUnmutedDone(String name) {
    return '$name kann wieder schreiben.';
  }
}
