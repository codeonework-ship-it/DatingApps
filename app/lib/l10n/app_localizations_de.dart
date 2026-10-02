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

  @override
  String get richFormattingToolbar => 'Formatierung';

  @override
  String get richUndo => 'Rückgängig';

  @override
  String get richRedo => 'Wiederholen';

  @override
  String get richBold => 'Fett';

  @override
  String get richItalic => 'Kursiv';

  @override
  String get richUnderline => 'Unterstrichen';

  @override
  String get richStrikethrough => 'Durchgestrichen';

  @override
  String get richHighlight => 'Hervorheben';

  @override
  String get richLink => 'Link';

  @override
  String get richTextStyleMenu => 'Textart';

  @override
  String get richParagraph => 'Absatz';

  @override
  String get richHeading => 'Überschrift';

  @override
  String get richSubheading => 'Zwischenüberschrift';

  @override
  String get richQuote => 'Zitat';

  @override
  String get richCallout => 'Hinweisbox';

  @override
  String get richBulletList => 'Aufzählung';

  @override
  String get richNumberedList => 'Nummerierte Liste';

  @override
  String get richDivider => 'Abschnittswechsel';

  @override
  String get richAlignMenu => 'Ausrichtung';

  @override
  String get richAlignStart => 'Am Anfang ausrichten';

  @override
  String get richAlignCenter => 'Zentrieren';

  @override
  String get richAlignEnd => 'Am Ende ausrichten';

  @override
  String get richClearFormatting => 'Formatierung entfernen';

  @override
  String get richWritingStyle => 'Schreibstil';

  @override
  String get richStyleClassic => 'Klassisch';

  @override
  String get richStyleClassicHint =>
      'Elegante Serifenschrift wie auf einer gedruckten Seite';

  @override
  String get richStyleModern => 'Modern';

  @override
  String get richStyleModernHint => 'Klar und gut lesbar';

  @override
  String get richStyleJournal => 'Tagebuch';

  @override
  String get richStyleJournalHint => 'Warme Kursive wie ein Tagebucheintrag';

  @override
  String get richStyleTypewriter => 'Schreibmaschine';

  @override
  String get richStyleTypewriterHint => 'Kantige Buchstaben mit mehr Abstand';

  @override
  String get richStylePoetic => 'Poetisch';

  @override
  String get richStylePoeticHint => 'Zentrierte Zeilen mit viel Luft';

  @override
  String richWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter',
      one: '1 Wort',
    );
    return '$_temp0';
  }

  @override
  String get richAlignmentNote =>
      'Ausrichtung und Abstände siehst du in der Vorschau und deine Leser beim Lesen.';

  @override
  String get richLinkTitle => 'Link hinzufügen';

  @override
  String get richLinkField => 'Webadresse';

  @override
  String get richLinkInvalid => 'Gib eine vollständige https://-Adresse ein.';

  @override
  String get richLinkApply => 'Link hinzufügen';

  @override
  String get richLinkRemove => 'Link entfernen';

  @override
  String get richLinkNeedsSelection =>
      'Markiere zuerst die Wörter, die du verlinken möchtest.';

  @override
  String get richCancel => 'Abbrechen';

  @override
  String get richOpenLinkTitle => 'Diesen Link öffnen?';

  @override
  String richOpenLinkBody(String host) {
    return '$host öffnet sich außerhalb von Connect. Öffne nur Links, denen du vertraust.';
  }

  @override
  String get richOpenLink => 'Link öffnen';

  @override
  String get supportCentreEyebrow => 'HILFE & SUPPORT';

  @override
  String get supportCentreTitle => 'Wie können wir helfen?';

  @override
  String get supportCentreSubtitle =>
      'Finde eine schnelle Antwort oder frag unser Team. Jede Anfrage und Antwort bleibt in einem privaten Gespräch.';

  @override
  String get supportContactSection => 'KONTAKT';

  @override
  String get supportContactTitle => 'Support kontaktieren';

  @override
  String get supportContactSubtitle =>
      'Erzähl uns, was passiert ist. Wir antworten hier und benachrichtigen dich.';

  @override
  String get supportMyTicketsTitle => 'Meine Anfragen';

  @override
  String get supportMyTicketsSubtitle =>
      'Verfolge deine Anfragen und unsere Antworten';

  @override
  String supportOpenRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offene Anfragen',
      one: '1 offene Anfrage',
    );
    return '$_temp0';
  }

  @override
  String supportUnreadReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Antworten',
      one: '1 neue Antwort',
    );
    return '$_temp0';
  }

  @override
  String get supportQuickAnswersSection => 'SCHNELLE ANTWORTEN';

  @override
  String get supportFaqLoginTitle => 'Anmeldung';

  @override
  String get supportFaqLoginBody =>
      'Melde dich mit deinem eindeutigen Benutzernamen und Passwort an.';

  @override
  String get supportFaqVerificationTitle => 'Verifizierung';

  @override
  String get supportFaqVerificationBody =>
      'Die Identitätsprüfung ist optional, solange der Anbieter pausiert ist.';

  @override
  String get supportFaqAbuseTitle => 'Missbrauch';

  @override
  String get supportFaqAbuseBody =>
      'Nutze „Melden“ in einem Profil oder Gespräch, damit wir schneller reagieren können.';

  @override
  String get supportFaqBillingTitle => 'Abrechnung';

  @override
  String get supportFaqBillingBody =>
      'Gib die Transaktionsnummer an, niemals deine Kartendaten.';

  @override
  String get supportEmergencyNote =>
      'Wenn jemand in unmittelbarer Gefahr ist, wende dich an den örtlichen Notruf. Support-Anfragen ersetzen keine Nothilfe.';

  @override
  String get supportUnavailableTitle =>
      'Support-Anfragen sind gerade nicht verfügbar';

  @override
  String get supportUnavailableBody =>
      'Die Antworten auf dieser Seite funktionieren weiterhin. Schreib uns bei dringenden Anliegen an support@connect.example.';

  @override
  String get supportBackToHelp => 'Zurück zu Hilfe & Support';

  @override
  String get supportFormEyebrow => 'NEUE ANFRAGE';

  @override
  String get supportFormTitle => 'Support kontaktieren';

  @override
  String get supportFormSubtitle =>
      'Gib uns genug Details, um zu helfen. Teile niemals Passwort, Wiederherstellungscode, Kartennummer oder Ausweisdokument.';

  @override
  String get supportFormCategorySection => 'THEMA';

  @override
  String get supportFormCategoryLabel => 'Wobei brauchst du Hilfe?';

  @override
  String get supportCategoryAccountLogin => 'Konto & Anmeldung';

  @override
  String get supportCategoryVerification => 'Verifizierung';

  @override
  String get supportCategoryPaymentsBilling => 'Zahlungen & Abrechnung';

  @override
  String get supportCategorySafetyHarassment => 'Sicherheit & Belästigung';

  @override
  String get supportCategoryMatchesChat => 'Matches & Chat';

  @override
  String get supportCategoryTechnical => 'Technisches Problem oder Fehler';

  @override
  String get supportCategoryFeatureRequest => 'Funktionswunsch';

  @override
  String get supportCategoryPrivacyData => 'Datenschutz & Datenanfrage';

  @override
  String get supportCategoryOther => 'Sonstiges';

  @override
  String get supportSafetyNote =>
      'Wenn du oder jemand anderes in unmittelbarer Gefahr ist, nutze SOS in der App oder ruf den örtlichen Notruf an. Sicherheitsanfragen haben Vorrang, aber eine Anfrage ist keine Notrufleitung.';

  @override
  String get supportOpenSos => 'SOS öffnen';

  @override
  String get supportFormDetailsSection => 'DETAILS';

  @override
  String get supportFormSubjectLabel => 'Betreff';

  @override
  String get supportFormSubjectHint => 'Beschreib das Problem kurz';

  @override
  String get supportFormDescriptionLabel => 'Was ist passiert?';

  @override
  String get supportFormDescriptionHint =>
      'Was du getan hast, was du erwartet hast und was stattdessen passiert ist';

  @override
  String get supportFormScreenshotsSection => 'SCREENSHOTS';

  @override
  String supportFormScreenshotsCaption(int max) {
    return 'Optional. Bis zu $max Bilder.';
  }

  @override
  String get supportAddScreenshot => 'Screenshot hinzufügen';

  @override
  String supportRemoveAttachment(String name) {
    return '$name entfernen';
  }

  @override
  String get supportAttachmentUploading => 'Wird hochgeladen';

  @override
  String get supportRetryUpload => 'Erneut hochladen';

  @override
  String supportFormDeviceNote(String version) {
    return 'Wir fügen deine App-Version ($version), Plattform, Systemversion und Sprache hinzu, um bei der Fehlersuche zu helfen.';
  }

  @override
  String get supportSubmit => 'Anfrage senden';

  @override
  String get supportErrorCategoryRequired => 'Wähle ein Thema.';

  @override
  String supportErrorSubjectLength(int min, int max) {
    return 'Der Betreff braucht $min bis $max Zeichen.';
  }

  @override
  String get supportErrorDescriptionRequired => 'Beschreib, was passiert ist.';

  @override
  String supportErrorDescriptionTooLong(int max) {
    return 'Bitte bleib unter $max Zeichen.';
  }

  @override
  String get supportErrorUploadsPending =>
      'Warte, bis deine Screenshots hochgeladen sind, oder entferne fehlgeschlagene.';

  @override
  String supportCreatedSnack(String reference) {
    return 'Anfrage $reference gesendet. Wir antworten hier.';
  }

  @override
  String supportDuplicateSnack(String reference) {
    return 'Du hast diese Anfrage schon gesendet, deshalb haben wir sie geöffnet: $reference.';
  }

  @override
  String supportErrorRateLimited(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Du hast in kurzer Zeit mehrere Anfragen gesendet. Versuch es in $minutes Minuten erneut.',
      one:
          'Du hast in kurzer Zeit mehrere Anfragen gesendet. Versuch es in 1 Minute erneut.',
    );
    return '$_temp0';
  }

  @override
  String get supportErrorRateLimitedGeneric =>
      'Du hast in kurzer Zeit mehrere Anfragen gesendet. Bitte versuch es später erneut.';

  @override
  String get supportErrorTooManyOpen =>
      'Du hast bereits 10 offene Anfragen. Schließ eine, die du nicht mehr brauchst, oder warte auf unsere Antworten.';

  @override
  String get supportErrorTicketClosed =>
      'Diese Anfrage ist geschlossen und kann nicht mehr geöffnet werden. Bitte starte eine neue Anfrage.';

  @override
  String get supportErrorReopenWindowPassed =>
      'Die Frist zum Wiedereröffnen ist abgelaufen. Bitte starte eine neue Anfrage.';

  @override
  String get supportErrorAlreadyRated =>
      'Du hast diese Anfrage bereits bewertet.';

  @override
  String get supportErrorNotResolved =>
      'Du kannst eine Anfrage bewerten, sobald sie gelöst ist.';

  @override
  String get supportErrorAttachmentType =>
      'Nur JPEG- oder PNG-Bilder und PDF-Dateien können angehängt werden.';

  @override
  String get supportErrorAttachmentTooLarge =>
      'Diese Datei ist zu groß. Bilder dürfen bis zu 8 MB groß sein.';

  @override
  String get supportErrorOffline =>
      'Connect ist gerade nicht erreichbar. Prüf deine Verbindung und versuch es erneut.';

  @override
  String get supportErrorNotFound => 'Wir konnten diese Anfrage nicht finden.';

  @override
  String get supportErrorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuch es erneut.';

  @override
  String get supportTryAgain => 'Erneut versuchen';

  @override
  String get supportTicketsEyebrow => 'SUPPORT';

  @override
  String get supportTicketsTitle => 'Meine Anfragen';

  @override
  String get supportTicketsSubtitle => 'Deine Anfragen und unsere Antworten.';

  @override
  String get supportTicketsActiveSection => 'AKTIV';

  @override
  String get supportTicketsClosedSection => 'GELÖST & GESCHLOSSEN';

  @override
  String get supportTicketsEmptyTitle => 'Noch keine Anfragen';

  @override
  String get supportTicketsEmptyBody =>
      'Wenn du den Support kontaktierst, erscheinen deine Anfrage und unsere Antworten hier.';

  @override
  String get supportTicketsLoadErrorTitle =>
      'Deine Anfragen konnten nicht geladen werden';

  @override
  String supportTicketUpdated(String when) {
    return 'Aktualisiert $when';
  }

  @override
  String get supportNewTicket => 'Neue Anfrage';

  @override
  String get supportStatusOpen => 'Offen';

  @override
  String get supportStatusWaitingForYou => 'Wartet auf dich';

  @override
  String get supportStatusOnHold => 'Pausiert';

  @override
  String get supportStatusResolved => 'Gelöst';

  @override
  String get supportStatusClosed => 'Geschlossen';

  @override
  String supportStatusSemantics(String status) {
    return 'Status: $status';
  }

  @override
  String get supportThreadAgentName => 'Connect Support';

  @override
  String get supportThreadYou => 'Du';

  @override
  String supportTicketMeta(String category, String date) {
    return '$category · Eröffnet am $date';
  }

  @override
  String get supportBannerOpen =>
      'Wir haben deine Anfrage. Unser Team antwortet hier und benachrichtigt dich.';

  @override
  String get supportBannerWaiting =>
      'Der Support hat geantwortet und wartet auf deine Rückmeldung.';

  @override
  String get supportBannerOnHold =>
      'Deine Anfrage ist pausiert, während wir sie prüfen. Wir melden uns hier.';

  @override
  String get supportBannerResolved =>
      'Als gelöst markiert. Antworte, um sie wieder zu öffnen; sonst wird sie nach 7 Tagen automatisch geschlossen.';

  @override
  String supportBannerClosedUntil(String date) {
    return 'Diese Anfrage ist geschlossen. Du kannst sie bis $date wieder öffnen.';
  }

  @override
  String get supportBannerClosed => 'Diese Anfrage ist geschlossen.';

  @override
  String supportBannerMerged(String reference) {
    return 'Diese Anfrage wurde mit $reference zusammengeführt. Das Gespräch geht dort weiter.';
  }

  @override
  String get supportReplyHint => 'Antwort schreiben';

  @override
  String get supportReplyDisabledHint =>
      'Für diese Anfrage sind keine Antworten mehr möglich';

  @override
  String get supportSendReply => 'Antwort senden';

  @override
  String get supportAttachScreenshot => 'Screenshot anhängen';

  @override
  String get supportCloseTicket => 'Anfrage schließen';

  @override
  String get supportCloseConfirmTitle => 'Diese Anfrage schließen?';

  @override
  String get supportCloseConfirmBody =>
      'Schließ sie, wenn dein Problem gelöst ist. Du kannst sie 14 Tage lang wieder öffnen.';

  @override
  String get supportCancel => 'Abbrechen';

  @override
  String get supportClosedSnack => 'Anfrage geschlossen.';

  @override
  String get supportReopen => 'Anfrage wieder öffnen';

  @override
  String get supportReopenedSnack => 'Anfrage wieder geöffnet.';

  @override
  String get supportRateTitle => 'Wie war unser Support?';

  @override
  String get supportRateCaption =>
      'Bewerte deine Erfahrung mit dieser Anfrage.';

  @override
  String supportRateStar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sterne',
      one: '1 Stern',
    );
    return '$_temp0';
  }

  @override
  String get supportRateCommentLabel =>
      'Möchtest du etwas ergänzen? (optional)';

  @override
  String get supportRateSubmit => 'Bewertung senden';

  @override
  String get supportRatedTitle => 'Danke für dein Feedback';

  @override
  String supportRatedValue(int rating) {
    return 'Du hast $rating von 5 vergeben.';
  }

  @override
  String get supportRatingSnack => 'Danke für deine Bewertung.';

  @override
  String supportAttachmentImage(String name) {
    return 'Screenshot $name';
  }

  @override
  String get supportAttachmentLoadFailed =>
      'Anhang konnte nicht geladen werden';

  @override
  String get supportThreadLoadErrorTitle =>
      'Diese Anfrage konnte nicht geladen werden';

  @override
  String get chemistryCardEntry => 'Ein bisschen Chemie?';

  @override
  String get memberProfileIntroducing => 'Wir stellen vor';

  @override
  String get memberProfileStarring => 'In der Hauptrolle';

  @override
  String get memberProfileVerified => 'Verifiziert';

  @override
  String memberProfilePhotoLabel(String name, int index, int count) {
    return '$name, Foto $index von $count';
  }

  @override
  String get memberProfileNoPhoto => 'Noch kein Foto';

  @override
  String get memberProfileViewPhotoHint => 'im Vollbild ansehen';

  @override
  String get memberProfileCloseGallery => 'Fotos schließen';

  @override
  String get memberProfilePhotos => 'Fotos';

  @override
  String memberProfileMorePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere Fotos',
      one: '1 weiteres Foto',
    );
    return '$_temp0';
  }

  @override
  String get memberProfileSceneAbout => 'Über mich';

  @override
  String get memberProfileSceneStories => 'Geschichten';

  @override
  String get memberProfileSceneStoriesTitle => 'Ein bisschen mehr von mir';

  @override
  String get memberProfileSceneInterests => 'Interessen';

  @override
  String get memberProfileSceneBasics => 'Das Wichtigste';

  @override
  String get memberProfileSceneLifestyle => 'Lebensstil';

  @override
  String get memberProfileSceneTrust => 'Vertrauen';

  @override
  String get memberProfileReadMore => 'Mehr lesen';

  @override
  String get memberProfileReadLess => 'Weniger anzeigen';

  @override
  String get memberProfileHobbies => 'Hobbys';

  @override
  String get memberProfileActivities => 'Aktivitäten';

  @override
  String get memberProfileSongs => 'In Dauerschleife';

  @override
  String get memberProfileBooks => 'Bücher & Romane';

  @override
  String get memberProfileLookingFor => 'Sucht';

  @override
  String get memberProfileLanguages => 'Sprachen';

  @override
  String get memberProfileDealBreakers => 'No-Gos';

  @override
  String get memberProfileInCommon => 'Gemeinsam';

  @override
  String get memberProfileFactHeight => 'Größe';

  @override
  String memberProfileHeightCm(int cm) {
    return '$cm cm';
  }

  @override
  String get memberProfileFactWork => 'Beruf';

  @override
  String get memberProfileFactEducation => 'Ausbildung';

  @override
  String get memberProfileFactLivesIn => 'Wohnt in';

  @override
  String get memberProfileFactMotherTongue => 'Muttersprache';

  @override
  String get memberProfileFactReligion => 'Religion';

  @override
  String get memberProfileFactPersonality => 'Persönlichkeit';

  @override
  String get memberProfileFactRelationship => 'Beziehungsstatus';

  @override
  String get memberProfileFactInstagram => 'Instagram';

  @override
  String get memberProfileFactDrinking => 'Alkohol';

  @override
  String get memberProfileFactSmoking => 'Rauchen';

  @override
  String get memberProfileFactWorkout => 'Training';

  @override
  String get memberProfileFactDiet => 'Ernährung';

  @override
  String get memberProfileFactDietType => 'Ernährungsweise';

  @override
  String get memberProfileFactSleep => 'Schlaf';

  @override
  String get memberProfileFactTravel => 'Reisen';

  @override
  String get memberProfileFactPets => 'Haustiere';

  @override
  String get memberProfileFactPolitics => 'Politik';

  @override
  String get memberProfileFactOpenToCasual => 'Offen für Lockeres';

  @override
  String get memberProfileFactPartyLover => 'Feiert gern';

  @override
  String get memberProfileVerifiedTitle => 'Verifiziertes Profil';

  @override
  String get memberProfileVerifiedBody => 'Identitätsprüfung abgeschlossen.';

  @override
  String get memberProfileVouchesTitle => 'Freunde verbürgen sich';

  @override
  String get memberProfileSpotlight => 'Spotlight';

  @override
  String get memberProfileFreeWhenYouAre => 'Hat Zeit, wenn du Zeit hast';

  @override
  String get memberProfileMessage => 'Nachricht';

  @override
  String get memberProfileLove => 'Herz';

  @override
  String get memberProfileReport => 'Melden';

  @override
  String get memberProfileOwnerTitle => 'So sehen dich andere';

  @override
  String get memberProfileOwnerCaption =>
      'Mitglieder sehen dein Profil genau so.';

  @override
  String memberProfileCompleteness(int percent) {
    return 'Profil zu $percent % vollständig';
  }

  @override
  String get memberProfileCompletenessHint =>
      'Füge Fotos, Geschichten und Details hinzu, um aufzufallen.';

  @override
  String get memberProfileCompletenessDone => 'Dein Profil ist vollständig.';

  @override
  String get memberProfileToolEdit => 'Profil bearbeiten';

  @override
  String get memberProfileToolPhotos => 'Fotos bearbeiten';

  @override
  String get memberProfileToolStories => 'Deine Geschichten';

  @override
  String get memberProfileToolViewers => 'Wer dich angesehen hat';

  @override
  String get memberProfileBehindTheScenes => 'Hinter den Kulissen';

  @override
  String get memberProfileOnlyYou => 'Nur du siehst das.';

  @override
  String get memberProfileMine => 'Mein Profil';

  @override
  String get profileShowcaseLabel => 'Texte & Momente';

  @override
  String get profileShowcaseTitleOther => 'In eigenen Worten';

  @override
  String get profileShowcaseTitleSelf => 'Deine öffentlichen Texte & Fotos';

  @override
  String get profileShowcaseChapters => 'Kapitel';

  @override
  String get profileShowcasePhotos => 'Wand-Fotos';

  @override
  String get profileShowcaseReadAll => 'Alle Kapitel lesen';

  @override
  String get profileShowcaseHiddenTitle => 'Nur du siehst das';

  @override
  String get profileShowcaseHiddenBody =>
      'Deine öffentlichen Kapitel und Wand-Fotos sind in deinem Profil ausgeblendet. Schalte das ein, damit Mitglieder sie hier sehen.';

  @override
  String get profileShowcaseShownBody =>
      'Mitglieder sehen diese in deinem Profil. Es erscheinen nur Kapitel, die du mit der Community teilst, und Fotos auf der Wand.';

  @override
  String get profileShowcaseSwitch => 'In meinem Profil zeigen';

  @override
  String get profileShowcaseSaveFailed =>
      'Deine Auswahl konnte nicht gespeichert werden.';
}
