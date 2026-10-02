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
      'Tagsüber warmes Elfenbein und Waldgrün. Nachts sanfte Minze und tiefes Waldgrün.';

  @override
  String get settingsLooksClassicLabel => 'Heute';

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
      'Gestaltet gemeinsam ein erstes Hallo. Kontakte werden erst mal nicht informiert.';

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
  String get planHeadlineFriendsAlerted =>
      'Deine Bitte um Hilfe ist eingegangen';

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
      'Wähle Vertrauenspersonen, mit denen du deine Updates teilst.';

  @override
  String get planFriendsKnowProposed =>
      'Das Teilen mit Kontakten ist bei jedem Plan freiwillig.';

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
      'Das bleibt erst mal zwischen dir und deinem Date. Nach dem Vorschlag kannst du Vertrauenspersonen wählen, wenn du Plan- und Check-in-Updates teilen möchtest.';

  @override
  String get planSectionWhen => 'Wann';

  @override
  String get planSectionWhat => 'Was';

  @override
  String get planSectionGroups => 'Vertrauenspersonen';

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
      'Nimm diesen Plan mit deinem Date an. Danach kannst du Vertrauenspersonen wählen, wenn du deine Updates teilen möchtest.';

  @override
  String get planAcceptButton => 'Plan annehmen';

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
      'Schlag ein Date aus einem Chat heraus vor. Du entscheidest, ob du Plan- und Check-in-Updates mit Vertrauenspersonen teilst.';

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
  String get plansNextUpcoming =>
      'Bestätigt. Eure gemeinsame Zeit ist geplant.';

  @override
  String get plansNextCheckin => 'Melde dich nach deinem Date';

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
      'Pläne erscheinen hier, wenn Freunde sie ausdrücklich mit dir teilen.';

  @override
  String get plansViaGroup => 'Mit dir geteilt';

  @override
  String get plansViaFriend => 'Vertrauensperson';

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

  @override
  String get callsHistoryTitle => 'Anrufverlauf';

  @override
  String get callsHistoryEmpty => 'Noch keine Anrufe.';

  @override
  String callsHistoryMatch(String id) {
    return 'Match $id';
  }

  @override
  String get callsJoinLiveRoom => 'Live-Raum betreten';

  @override
  String get callsActiveSession => 'Laufender Anruf';

  @override
  String callsEndedWithDuration(String duration) {
    return 'Beendet · $duration';
  }

  @override
  String get callsSessionTitle => 'Anruf';

  @override
  String get callsStarting => 'Sichere Verbindung wird gestartet …';

  @override
  String get callsSessionActive => 'Anruf aktiv';

  @override
  String get callsSessionUnavailable => 'Anruf nicht verfügbar';

  @override
  String get callsLiveRoomNote =>
      'Der Live-Raum öffnet sich in einem sicheren Fenster des Anbieters. Nutze während des Anrufs dort die Steuerung für Mikrofon, Kamera und Verlassen.';

  @override
  String get callsEnd => 'Beenden';

  @override
  String get callsErrorSignInHistory =>
      'Bitte melde dich an, um deinen Anrufverlauf zu sehen.';

  @override
  String get callsErrorSignInStart =>
      'Bitte melde dich an, bevor du einen Anruf startest.';

  @override
  String get callsErrorPermissions =>
      'Für Anrufe brauchen wir Zugriff auf Kamera und Mikrofon.';

  @override
  String get callsErrorLoadHistory =>
      'Der Anrufverlauf konnte nicht geladen werden.';

  @override
  String get callsErrorStart => 'Der Anruf konnte nicht gestartet werden.';

  @override
  String get callsErrorEnd => 'Der Anruf konnte nicht beendet werden.';

  @override
  String get callsErrorNotConfigured =>
      'Live-Anrufräume sind in dieser Umgebung nicht eingerichtet.';

  @override
  String get callsErrorOpenRoom =>
      'Der Live-Anrufraum konnte nicht geöffnet werden.';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonCopy => 'Kopieren';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonApply => 'Anwenden';

  @override
  String get commonReset => 'Zurücksetzen';

  @override
  String get commonOpen => 'Öffnen';

  @override
  String get commonView => 'Ansehen';

  @override
  String get commonDismiss => 'Ausblenden';

  @override
  String get commonAny => 'Beliebig';

  @override
  String get commonSomethingWentWrong => 'Etwas ist schiefgelaufen';

  @override
  String get commonSomethingWentWrongTryAgain =>
      'Etwas ist schiefgelaufen. Bitte versuch es erneut.';

  @override
  String get commonTryAgainTitle => 'Erneut versuchen';

  @override
  String get commonNothingHereYet => 'Hier ist noch nichts';

  @override
  String commonLoadingLabel(String label) {
    return '$label, wird geladen';
  }

  @override
  String commonDistanceKm(int distance) {
    return '$distance km';
  }

  @override
  String get navToday => 'Heute';

  @override
  String get navOfflineBanner =>
      'Offline-Modus: Einige Daten sind möglicherweise veraltet.';

  @override
  String navWeakNetworkBanner(int mbps) {
    return 'Schwaches Netz erkannt. Nutze mindestens $mbps Mbit/s, damit die App flüssiger läuft.';
  }

  @override
  String get navIncomingCallTitle => 'Eingehender Anruf';

  @override
  String get navIncomingCallBody => 'Ein Match ruft dich an.';

  @override
  String get navViewCallDetails => 'Anrufdetails ansehen';

  @override
  String get filterSheetTitle => 'Matches filtern';

  @override
  String get filterAgeRange => 'Altersbereich';

  @override
  String get filterProfileLifestyle => 'Profil- & Lifestyle-Filter';

  @override
  String get filterCountry => 'Land';

  @override
  String get filterState => 'Bundesland/Region';

  @override
  String get filterCity => 'Stadt';

  @override
  String get filterMotherTongue => 'Muttersprache';

  @override
  String get filterReligion => 'Religion';

  @override
  String get filterRelationshipStatus => 'Beziehungsstatus';

  @override
  String get filterSmoking => 'Rauchen';

  @override
  String get filterDrinking => 'Alkohol';

  @override
  String get filterPersonalityType => 'Persönlichkeitstyp';

  @override
  String get filterPartyLoverOnly => 'Nur Partyfans';

  @override
  String get filterHookupsOnly => 'Nur Lockeres';

  @override
  String get filterAdvancedBio => 'Erweiterte Profilfilter';

  @override
  String get filterAdvancedBioBody =>
      'Bücher, Romane, Songs, Hobbys, Ort und Freizeit-Tags verwaltest du unter Einstellungen → Dating-Präferenzen.';

  @override
  String get filterOpenDatingPreferences => 'Dating-Präferenzen öffnen';

  @override
  String get filterDistanceKm => 'Entfernung (km)';

  @override
  String get filterVerifiedOnlyTitle => 'Nur verifiziert';

  @override
  String get filterVerifiedOnlyBody => 'Nur verifizierte Profile anzeigen';

  @override
  String get filterVerifiedOnlyChip => 'Nur verifiziert';

  @override
  String get filterPartyLoverChip => 'Partyfan';

  @override
  String get filterHookupChip => 'Nur Lockeres';

  @override
  String get filterEnableTrust => 'Vertrauensfilter aktivieren';

  @override
  String filterMinimumTrustBadges(int count) {
    return 'Mindestanzahl aktiver Vertrauensabzeichen: $count';
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
      'true': ', nur verifiziert',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(trust, {
      'true': ', Vertrauensfilter an',
      'other': ', Vertrauensfilter aus',
    });
    return 'Filter gespeichert: $minAge–$maxAge Jahre, $distance km$_temp0$_temp1';
  }

  @override
  String get optionNever => 'Nie';

  @override
  String get optionOccasionally => 'Gelegentlich';

  @override
  String get optionSocially => 'In Gesellschaft';

  @override
  String get optionRegularly => 'Regelmäßig';

  @override
  String get optionSingle => 'Single';

  @override
  String get optionDivorced => 'Geschieden';

  @override
  String get optionWidowed => 'Verwitwet';

  @override
  String get optionSeparated => 'Getrennt';

  @override
  String get optionComplicated => 'Kompliziert';

  @override
  String get optionIntrovert => 'Introvertiert';

  @override
  String get optionAmbivert => 'Ambivertiert';

  @override
  String get optionExtrovert => 'Extrovertiert';

  @override
  String get optionHighSchool => 'Schulabschluss';

  @override
  String get optionBachelors => 'Bachelor';

  @override
  String get optionMasters => 'Master';

  @override
  String get optionPhd => 'Promotion';

  @override
  String get optionOther => 'Sonstiges';

  @override
  String get optionPreferNotToSay => 'Keine Angabe';

  @override
  String get optionHindu => 'Hinduistisch';

  @override
  String get optionMuslim => 'Muslimisch';

  @override
  String get optionChristian => 'Christlich';

  @override
  String get optionSikh => 'Sikh';

  @override
  String get optionBuddhist => 'Buddhistisch';

  @override
  String get optionJain => 'Jainistisch';

  @override
  String get optionJewish => 'Jüdisch';

  @override
  String get optionSpiritual => 'Spirituell';

  @override
  String get optionAgnostic => 'Agnostisch';

  @override
  String get optionAtheist => 'Atheistisch';

  @override
  String get storiesNudgeTitle =>
      'Erzähl ein bisschen mehr von deiner Geschichte';

  @override
  String get storiesNudgeBodyUnknown =>
      'Kurze Geschichten in deinem Profil geben anderen etwas Echtes, worüber sie Hallo sagen können.';

  @override
  String get storiesNudgeActionOpen => 'Deine Geschichten öffnen';

  @override
  String get storiesNudgeBodyEmpty =>
      'Füge deinem Profil eine kurze Geschichte hinzu: eine kleine Freude, ein Wochenende, das sich zu erzählen lohnt. Viele lesen das, bevor sie Hallo sagen.';

  @override
  String get storiesNudgeActionFirst => 'Schreib deine erste Geschichte';

  @override
  String get storiesNudgeCompleteTitle => 'Deine Geschichte ist komplett';

  @override
  String get storiesNudgeCompleteBody =>
      'Alle drei Geschichten sind in deinem Profil. Erneuere eine, wann immer das Leben dir eine neue schenkt.';

  @override
  String get storiesNudgeActionEdit => 'Deine Geschichten bearbeiten';

  @override
  String storiesNudgeSharedTitle(int count, int max) {
    return '$count von $max Geschichten geteilt';
  }

  @override
  String get storiesNudgeBodyMore =>
      'Eine weitere Geschichte gibt anderen noch einen Weg, ein Gespräch zu beginnen.';

  @override
  String storiesNudgeBodyLatest(String prompt) {
    return 'Zuletzt: „$prompt“. Noch eine gibt anderen einen weiteren Weg, ein Gespräch zu beginnen.';
  }

  @override
  String get storiesNudgeActionAdd => 'Weitere Geschichte hinzufügen';

  @override
  String get storiesNudgeIdeas => 'Ideen für den Anfang';

  @override
  String storiesProgressSemantics(int count, int max) {
    return '$count von $max Geschichten geschrieben';
  }

  @override
  String get storiesPromptLittleJoy =>
      'Eine Kleinigkeit, für die ich mir immer Zeit nehme';

  @override
  String get storiesPromptWeekend =>
      'Ein Wochenende, das sich zu erzählen lohnt';

  @override
  String get storiesPromptFirstHello =>
      'Ein erstes Hallo, das mir gefallen würde';

  @override
  String get storiesPromptLearning =>
      'Etwas, das ich gerade nur für mich lerne';

  @override
  String get storiesPromptCare =>
      'Eine kleine Art, wie ich zeige, dass mir jemand wichtig ist';

  @override
  String get storiesScreenTitle => 'Ein bisschen mehr du';

  @override
  String get storiesSignIn =>
      'Melde dich an, um deine Geschichten zu bearbeiten.';

  @override
  String get storiesLoadFailed =>
      'Deine Geschichten konnten nicht geladen werden.';

  @override
  String get storiesTryAgain => 'Erneut versuchen';

  @override
  String get storiesIncomplete =>
      'Füge jeder Geschichte Text und jedem Foto eine Beschreibung hinzu oder entferne die unfertige Geschichte.';

  @override
  String get storiesPublished => 'Deine Profilgeschichten sind veröffentlicht.';

  @override
  String get storiesSavedPrivately =>
      'Privat gespeichert. Deine Geschichten sind für andere Mitglieder verborgen.';

  @override
  String get storiesSaveUnconfirmed =>
      'Wir konnten das Speichern nicht bestätigen. Deine Änderungen sind noch da; lade die gespeicherten Geschichten neu, um nachzusehen.';

  @override
  String get storiesHeadline => 'Lass jemanden\ndein Alltags-Ich kennenlernen.';

  @override
  String get storiesIntro =>
      'Ein kleines Ritual, die Geschichte hinter einem Foto, ein erstes Hallo, das dir gefallen würde. Teile bis zu drei Momente in deinen eigenen Worten.';

  @override
  String get storiesOptionalNote =>
      'Freiwillig, ohne Punkte oder Pflicht zur Vollständigkeit. Vermeide Kontaktdaten oder genaue Orte, die du nicht teilen möchtest.';

  @override
  String get storiesPublishSwitch =>
      'Diese Geschichten in meinem Profil zeigen';

  @override
  String get storiesPublishSwitchHint =>
      'Standardmäßig aus. Sichtbar für berechtigte Mitglieder, wenn dein Profil veröffentlicht und verfügbar ist. Du kannst sie jederzeit ausblenden.';

  @override
  String get storiesBackToEditing => 'Zurück zum Bearbeiten';

  @override
  String get storiesPreview => 'Vorschau meiner Geschichten';

  @override
  String get storiesPreviewBanner => 'VORSCHAU · WIRD NICHT VERÖFFENTLICHT';

  @override
  String get storiesAdd => 'Geschichte hinzufügen';

  @override
  String get storiesReloadDiscard =>
      'Gespeicherte Geschichten neu laden · Änderungen verwerfen';

  @override
  String get storiesSaving => 'Wird gespeichert…';

  @override
  String get storiesPublishButton => 'Geschichten veröffentlichen';

  @override
  String get storiesSavePrivatelyButton => 'Privat speichern';

  @override
  String get storiesPolicyNote =>
      'Fotos stammen aus deiner freigegebenen Profilgalerie. Geschichten und Fotos unterliegen weiterhin Meldungen durch Mitglieder und unseren Sicherheitsrichtlinien.';

  @override
  String storiesMomentLabel(int number) {
    return 'MOMENT $number';
  }

  @override
  String storiesRemoveTooltip(int number) {
    return 'Geschichte $number entfernen';
  }

  @override
  String get storiesPromptLabel => 'Ein Ausgangspunkt';

  @override
  String get storiesTextLabel => 'In deinen Worten';

  @override
  String get storiesTextHint => 'Ein echtes Detail macht sie zu deiner.';

  @override
  String get storiesTextRequired =>
      'Schreib ein paar Worte oder entferne diese Geschichte.';

  @override
  String get storiesPhotoLabel => 'Ein Foto, wenn du magst';

  @override
  String get storiesWordsOnly => 'Nur Text';

  @override
  String storiesProfilePhoto(int number) {
    return 'Profilfoto $number';
  }

  @override
  String get storiesPhotoDescriptionLabel => 'Beschreibe dieses Foto';

  @override
  String get storiesPhotoDescriptionHelper =>
      'Hilft Menschen, die Screenreader nutzen.';

  @override
  String get storiesPhotoDescriptionRequired =>
      'Füge eine kurze Fotobeschreibung hinzu.';

  @override
  String get storiesPhotoSemantics => 'Foto zur Profilgeschichte';

  @override
  String get storiesSectionTitle => 'Ein bisschen mehr ich';

  @override
  String get storiesRetryLoad => 'Geschichten erneut laden';

  @override
  String get authErrorSessionExpired =>
      'Du wurdest abgemeldet. Bitte melde dich erneut an.';

  @override
  String get authErrorSignInFailed =>
      'Anmelden nicht möglich. Versuch es noch einmal.';

  @override
  String get authErrorCreateAccountFailed =>
      'Konto konnte nicht erstellt werden. Versuch es noch einmal.';

  @override
  String get authErrorCreateAccountGeneric =>
      'Konto konnte nicht erstellt werden.';

  @override
  String get authErrorInvalidCredentials =>
      'Benutzername oder Passwort ist falsch.';

  @override
  String get authErrorUsernameFormat =>
      'Der Benutzername muss 3–30 Zeichen lang sein und darf nur Buchstaben, Ziffern, _ oder . enthalten.';

  @override
  String get authErrorPasswordFormat =>
      'Das Passwort muss 8–72 Byte lang sein und Buchstaben und Ziffern enthalten.';

  @override
  String get authWelcomeIntroducerLink => 'Ich will nur Freunde vorstellen';

  @override
  String get signupBackTooltip => 'Zurück';

  @override
  String get signupIntroducerTitle =>
      'Sei der Mensch, der andere zusammenbringt.';

  @override
  String get signupIntroducerBody =>
      'Ein reines Freundeskonto. Kein Dating-Profil, keine Fotos, kein Swipen. Dein Alter bleibt privat; Connect ist für Erwachsene von 18–80.';

  @override
  String get signupTitle => 'Erstelle dein Konto';

  @override
  String get signupSubtitle =>
      'Wähle einen eindeutigen Benutzernamen und ein sicheres Passwort';

  @override
  String get signupUsernameLabel => 'Eindeutiger Benutzername';

  @override
  String get signupUsernameHint => 'dein_benutzername';

  @override
  String get signupUsernameHelp =>
      '3–30 Zeichen. Buchstaben, Ziffern, Unterstrich und Punkt.';

  @override
  String get signupPasswordLabel => 'Passwort';

  @override
  String get signupPasswordHint => 'Mindestens 8 Zeichen';

  @override
  String get signupConfirmPasswordHint => 'Passwort bestätigen';

  @override
  String get signupNameLabel => 'Vollständiger Name';

  @override
  String get signupNameHint => 'Dein Name';

  @override
  String get signupDobLabel => 'Geburtsdatum';

  @override
  String get signupDobPickerHelp => 'Geburtsdatum auswählen';

  @override
  String get signupDobPlaceholder => 'Datum auswählen';

  @override
  String get signupGenderLabel => 'Ich identifiziere mich als';

  @override
  String get signupGenderMan => 'Mann';

  @override
  String get signupGenderWoman => 'Frau';

  @override
  String get signupGenderOther => 'Divers';

  @override
  String get signupCreateFriendAccount => 'Freundeskonto erstellen';

  @override
  String get signupAlreadyHaveAccount => 'Du hast schon ein Konto?';

  @override
  String get signupErrorPasswordMismatch =>
      'Die Passwörter stimmen nicht überein.';

  @override
  String get signupErrorFullName => 'Bitte gib deinen vollständigen Namen ein.';

  @override
  String get signupErrorDobMissing => 'Bitte wähle dein Geburtsdatum aus.';

  @override
  String get signupErrorUnderage => 'Du musst mindestens 18 Jahre alt sein.';

  @override
  String get signupErrorAgeRange =>
      'Connect ist derzeit für Mitglieder von 18–80 Jahren verfügbar.';

  @override
  String get signupErrorGenderMissing =>
      'Bitte wähle aus, wie du dich identifizierst.';

  @override
  String get authRecoveryEnterUsername => 'Gib deinen Benutzernamen ein.';

  @override
  String get authRecoveryEnterCode => 'Gib deinen Wiederherstellungscode ein.';

  @override
  String get authRecoveryPasswordRule =>
      'Verwende 8–72 Zeichen mit mindestens einem Buchstaben und einer Ziffer.';

  @override
  String get authRecoveryResetDone =>
      'Dein Passwort wurde zurückgesetzt und alle Geräte wurden abgemeldet. Melde dich mit deinem neuen Passwort an.';

  @override
  String get authRecoveryAssistanceDone =>
      'Wenn dieser Benutzername zu einem Connect-Konto gehört, prüft unser Sicherheitsteam die Anfrage.';

  @override
  String get authRecoveryInvalidCode =>
      'Dieser Wiederherstellungscode ist ungültig oder abgelaufen.';

  @override
  String get authRecoveryOffline =>
      'Connect ist nicht erreichbar. Prüfe deine Verbindung und versuch es noch einmal.';

  @override
  String get authRecoverySendFailed =>
      'Deine Anfrage konnte nicht gesendet werden. Prüfe deine Verbindung und versuch es noch einmal.';

  @override
  String get authRecoveryBackToSignIn => 'Zurück zur Anmeldung';

  @override
  String get authRecoveryHaveCode => 'Ich habe meinen Code';

  @override
  String get authRecoveryLostCode => 'Ich habe meinen Code verloren';

  @override
  String get authRecoveryHaveCodeIntro =>
      'Verwende den Wiederherstellungscode, den du beim Erstellen deines Kontos gespeichert hast, oder einen von unserem Sicherheitsteam ausgestellten.';

  @override
  String get authRecoveryLostCodeIntro =>
      'Nenn uns deinen Benutzernamen. Wir bestätigen deine Identität, bevor wir einen Wiederherstellungscode ausstellen. Wir fragen nie nach deinem Passwort.';

  @override
  String get authRecoveryUsernameLabel => 'Benutzername';

  @override
  String get authRecoveryCodeLabel => 'Wiederherstellungscode';

  @override
  String get authRecoveryNewPasswordLabel => 'Neues Passwort';

  @override
  String get authRecoveryMessageLabel => 'Was uns sonst noch hilft (optional)';

  @override
  String get authRecoveryMessageHint =>
      'Zum Beispiel, wann du dich zuletzt angemeldet hast';

  @override
  String get authRecoverySending => 'Wird gesendet…';

  @override
  String get authRecoveryResetPassword => 'Passwort zurücksetzen';

  @override
  String get authRecoveryAskForHelp => 'Um Hilfe bitten';

  @override
  String get authTermsTitle => 'Nutzungsbedingungen';

  @override
  String get authTermsSubtitle => 'Ein kurzer Überblick, bevor es losgeht.';

  @override
  String get authTermsIntro =>
      'Bitte lies unsere Nutzungsbedingungen und Datenschutzerklärung und akzeptiere sie, um fortzufahren.';

  @override
  String get authTermsCommunityTitle => 'Was wir von der Community erwarten';

  @override
  String get authTermsPointRespect => 'Sei respektvoll und authentisch.';

  @override
  String get authTermsPointNoHarassment =>
      'Keine Belästigung und kein betrügerisches Verhalten.';

  @override
  String get authTermsPointPrivacy =>
      'Du bestimmst deine Datenschutzeinstellungen und die Sichtbarkeit deines Profils.';

  @override
  String get authTermsPointReports =>
      'Meldungen werden geprüft, damit die Community sicher bleibt.';

  @override
  String get authTermsPointViolations =>
      'Verstöße können zur Sperrung oder Löschung des Kontos führen.';

  @override
  String get authTermsReviewLater =>
      'Die vollständigen Richtlinien kannst du später in den Einstellungen nachlesen. Um die App zu nutzen, musst du sie aber zuerst akzeptieren.';

  @override
  String get authTermsAgreeCheckbox =>
      'Ich stimme den Nutzungsbedingungen und der Datenschutzerklärung zu';

  @override
  String get authTermsAcceptButton => 'Akzeptieren und fortfahren';

  @override
  String get authTermsSaveFailed =>
      'Deine Zustimmung konnte nicht gespeichert werden. Prüfe deine Verbindung und versuch es noch einmal.';

  @override
  String discoverSuperLikeSent(String name) {
    return 'Super-Like an $name gesendet';
  }

  @override
  String get discoverMatchPlaceholderMessage => 'Sag Hallo';

  @override
  String discoverChatNeedsMatch(String name) {
    return 'Du kannst mit $name chatten, sobald ein echtes Match entstanden ist.';
  }

  @override
  String get discoverDailyLimitTitle =>
      'Deine Likes für heute sind aufgebraucht';

  @override
  String get discoverDailyLimitBody =>
      'Komm morgen wieder oder upgrade für mehr Likes pro Tag.';

  @override
  String discoverDailyLimitResetBody(String reset) {
    return '$reset. Upgrade für mehr Likes pro Tag.';
  }

  @override
  String get discoverSeePlans => 'Tarife ansehen';

  @override
  String get discoverNotNow => 'Jetzt nicht';

  @override
  String get discoverBackToToday => 'Zurück zu Heute';

  @override
  String get discoverExploreTitle => 'Entdecken';

  @override
  String get discoverSpotlightReviewed => 'Spotlight durchgesehen!';

  @override
  String get discoverAllReviewed => 'Alles durchgesehen!';

  @override
  String get discoverCuratedForYou => 'Für dich ausgewählt';

  @override
  String get discoverTitle => 'Matches entdecken';

  @override
  String get discoverTagline => 'Ein wenig Neugier. Eine echte Verbindung.';

  @override
  String get discoverMessages => 'Nachrichten';

  @override
  String get discoverFilters => 'Filter';

  @override
  String get discoverYourDeck => 'Dein Stapel';

  @override
  String get discoverStatReady => 'Bereit';

  @override
  String get discoverStatLiked => 'Geliked';

  @override
  String get discoverStatPassed => 'Übersprungen';

  @override
  String get discoverEdit => 'Bearbeiten';

  @override
  String get discoverShowingEveryone =>
      'Es werden alle angezeigt, die zu deinen Präferenzen passen.';

  @override
  String get discoverToday => 'Heute';

  @override
  String get discoverTodaySubtitle => 'Fünf Vorschläge, jeden Tag neu.';

  @override
  String get discoverViewAll => 'Alle ansehen';

  @override
  String get discoverMatchOnYourTerms => 'Matche zu deinen Bedingungen';

  @override
  String get discoverMatchOnYourTermsBody =>
      'Ein Match entsteht nur bei gegenseitigem Interesse. Du kannst jede Person über ihr Profil oder den Chat blockieren oder melden.';

  @override
  String get discoverErrorEyebrow => 'Verbindung unterbrochen';

  @override
  String get discoverErrorTitle => 'Profile konnten nicht geladen werden';

  @override
  String discoverTrustFilteredBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Vertrauensfilter haben $count Profile ausgeblendet. Lockere die Vertrauensfilter oder aktualisiere, um deinen Stapel neu aufzubauen.',
      one:
          'Vertrauensfilter haben $count Profil ausgeblendet. Lockere die Vertrauensfilter oder aktualisiere, um deinen Stapel neu aufzubauen.',
    );
    return '$_temp0';
  }

  @override
  String get discoverDeckPreparingBody =>
      'Dein ausgewählter Stapel wird vorbereitet. Aktualisiere, um nach neuen verifizierten Profilen in deiner Nähe zu suchen.';

  @override
  String get discoverCheckBackSoon => 'Schau bald wieder vorbei';

  @override
  String get discoverNoSpotlightProfiles => 'Keine Spotlight-Profile';

  @override
  String get discoverNoProfiles => 'Keine Profile';

  @override
  String get discoverRefresh => 'Aktualisieren';

  @override
  String get discoverPromisePrivate => 'Privat';

  @override
  String get discoverPremium => 'Premium';

  @override
  String discoverNotificationsUnread(int count) {
    return 'Benachrichtigungen, $count ungelesen';
  }

  @override
  String get discoverLatestUnreadNotifications =>
      'Neueste ungelesene Benachrichtigungen';

  @override
  String get discoverNoUnreadNotifications =>
      'Keine ungelesenen Benachrichtigungen';

  @override
  String get discoverNotificationWhoReplied => 'Wer mir geantwortet hat';

  @override
  String discoverNotificationRepliesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Antworten',
      one: '1 neue Antwort',
    );
    return '$_temp0';
  }

  @override
  String get discoverNotificationWhoLiked => 'Wer mich geliked hat';

  @override
  String discoverNotificationLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Likes',
      one: '1 neues Like',
    );
    return '$_temp0';
  }

  @override
  String get discoverViewMore => 'Mehr ansehen';

  @override
  String get discoverFitsYourWeek => 'Passt in deine Woche';

  @override
  String discoverTodayPicks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Vorschläge',
      one: '1 Vorschlag',
    );
    return '$_temp0';
  }

  @override
  String get discoverPickedForYouToday => 'Heute für dich ausgewählt.';

  @override
  String get discoverErrorLoginToDiscover =>
      'Bitte melde dich an, um Profile zu entdecken.';

  @override
  String get discoverErrorLoadProfiles =>
      'Profile konnten nicht geladen werden. Bitte versuch es noch einmal.';

  @override
  String get discoverErrorSessionUnavailable =>
      'Sitzung nicht verfügbar. Bitte melde dich erneut an.';

  @override
  String get discoverErrorLikeRetry =>
      'Liken ist gerade nicht möglich. Bitte versuch es noch einmal.';

  @override
  String get discoverErrorLike => 'Liken ist gerade nicht möglich.';

  @override
  String get discoverErrorPassRetry =>
      'Überspringen ist gerade nicht möglich. Bitte versuch es noch einmal.';

  @override
  String get discoverErrorLoadLikedMe =>
      'Wer dich geliked hat, konnte nicht geladen werden. Bitte versuch es noch einmal.';

  @override
  String get discoverErrorAnswerInFlight =>
      'Deine Antwort wird bereits gesendet.';

  @override
  String get discoverErrorAnswer =>
      'Deine Antwort konnte nicht gesendet werden. Bitte versuch es noch einmal.';

  @override
  String get firstChapterTopicPace => 'Kommunikationstempo';

  @override
  String get firstChapterTopicDates => 'Wohlfühlen beim Dating';

  @override
  String get firstChapterTopicLanguage => 'Sprachen';

  @override
  String get firstChapterTopicFamily => 'Rolle der Familie';

  @override
  String get firstChapterInMyWords => 'In meinen Worten';

  @override
  String firstChapterComfortOriginal(String language) {
    return 'Original · $language';
  }

  @override
  String firstChapterComfortMemberTranslation(String language) {
    return 'Übersetzung vom Mitglied · $language';
  }

  @override
  String get firstChapterComfortReloadSaved => 'Gespeicherte Version neu laden';

  @override
  String get firstChapterComfortReloadCards => 'Karten neu laden';

  @override
  String get firstChapterComfortHeadline => 'Deine Worte. Deine Grenzen.';

  @override
  String get firstChapterComfortIntro =>
      'Optionaler Kontext für Menschen, mit denen du ein Match hast. Aus deiner Herkunft wird nichts abgeleitet. Schreib in der Sprache, die sich nach dir anfühlt.';

  @override
  String get firstChapterComfortShareTitle =>
      'Diese Karten mit meinen Matches teilen';

  @override
  String get firstChapterComfortShareSubtitle =>
      'Aus bedeutet: Alle Karten bleiben privat.';

  @override
  String get firstChapterComfortRemoveFromDraft => 'Aus dem Entwurf entfernen';

  @override
  String get firstChapterComfortTopicLabel => 'Ein wenig Kontext zu';

  @override
  String get firstChapterComfortOriginalLanguage => 'Originalsprache';

  @override
  String get firstChapterComfortOwnWords => 'In deinen eigenen Worten';

  @override
  String get firstChapterComfortOwnWordsHint =>
      'Zum Beispiel: Ich mag Dates tagsüber und ein bisschen Zeit, um warm zu werden.';

  @override
  String get firstChapterComfortTranslation => 'Deine Übersetzung (optional)';

  @override
  String get firstChapterComfortTranslationLanguage =>
      'Sprache der Übersetzung (falls vorhanden)';

  @override
  String get firstChapterComfortTranslationNote =>
      'Übersetzungen werden als vom Mitglied bereitgestellt gekennzeichnet. Deine Originalworte bleiben immer erhalten.';

  @override
  String get firstChapterComfortAddCard =>
      'Karte im Entwurf hinzufügen / ersetzen';

  @override
  String get firstChapterComfortMissingFields =>
      'Füge deine Worte und die Sprache hinzu. Eine Übersetzung braucht ebenfalls ihre Sprache.';

  @override
  String get firstChapterComfortUnaddedCard =>
      'Füge deine geschriebene Karte vor dem Speichern zum Entwurf hinzu.';

  @override
  String get firstChapterComfortSaveFailed =>
      'Dein Entwurf ist noch da. Lade neu, um die zuletzt gespeicherte Version zu prüfen, bevor du es erneut versuchst.';

  @override
  String get firstChapterSaving => 'Wird gespeichert …';

  @override
  String get firstChapterComfortSave => 'Meine Auswahl speichern';

  @override
  String get firstChapterYourMatch => 'dein Match';

  @override
  String get firstChapterSaveUnconfirmed =>
      'Wir konnten das Speichern nicht bestätigen. Aktualisiere, um es zu prüfen, bevor du es erneut versuchst.';

  @override
  String get firstChapterJointPreviewTitle =>
      'Eine Geschichte, der ihr beide zustimmt';

  @override
  String get firstChapterSoloPreviewTitle =>
      'Vorschau deines öffentlichen Kapitels';

  @override
  String firstChapterThenSurprise(String surprise) {
    return 'Dann … $surprise';
  }

  @override
  String get firstChapterJointPreviewBody =>
      'Deine Zustimmung ist eine Hälfte. Der Link funktioniert erst, wenn auch dein Gegenüber genau dieser Karte zustimmt. Ihr könnt ihn beide jederzeit widerrufen.';

  @override
  String get firstChapterSoloPreviewBody =>
      'Öffentlich sind nur diese Szene und dein gewählter Anfang. Keine Namen, Fotos, privaten Chats, Standorte oder Beiträge deines Gegenübers. Du kannst den Link widerrufen.';

  @override
  String get firstChapterKeepPrivate => 'Privat lassen';

  @override
  String get firstChapterApproveMyHalf => 'Meine Hälfte bestätigen';

  @override
  String get firstChapterCreateShareLink => 'Link zum Teilen erstellen';

  @override
  String get firstChapterStudioTitle => 'First-Chapter-Studio';

  @override
  String get firstChapterRefresh => 'Kapitel aktualisieren';

  @override
  String get firstChapterHeroEyebrow => 'EIN KLEINES ABENTEUER. ZWEI AUTOREN.';

  @override
  String get firstChapterHeroTitle =>
      'Was als Nächstes\npassiert, liegt bei euch.';

  @override
  String get firstChapterHeroSolo =>
      'Erschaffe eine Szene. Gib sie an jemanden weiter. Oder schreib ein erstes Kapitel mit einem deiner Matches.';

  @override
  String firstChapterHeroPair(String name) {
    return 'Du und $name. Ein Anfang, eine unerwartete Wendung und eine Geschichte, die ihr wahr machen könnt.';
  }

  @override
  String get firstChapterHeroPace =>
      'Freiwillig, in deinem Tempo. Chatten ist immer eine Wahl.';

  @override
  String get firstChapterLoadFailed =>
      'Dein Kapitel konnte nicht geladen werden.';

  @override
  String get firstChapterTryAgain => 'Erneut versuchen';

  @override
  String get firstChapterStepChooseScene => '01 / Wähle deine Szene';

  @override
  String get firstChapterStepWriteBeginning => '02 / Schreib den Anfang';

  @override
  String get firstChapterStartOurChapter => 'Unser Kapitel beginnen';

  @override
  String get firstChapterPassTheChapter => 'Kapitel weitergeben';

  @override
  String get firstChapterYourFirstChapter => 'Euer erstes Kapitel';

  @override
  String get firstChapterItBeginsWith => 'ES BEGINNT MIT';

  @override
  String get firstChapterAndThen => 'UND DANN …';

  @override
  String firstChapterDateIdeaNote(String beginning, String surprise) {
    return '$beginning. Dann $surprise.';
  }

  @override
  String get firstChapterMakeDateIdea => 'Daraus eine Date-Idee machen';

  @override
  String get firstChapterDateIdeaHint =>
      'Ein Vorschlag, den ihr gemeinsam gestaltet. Es wird kein Date automatisch gebucht oder angenommen.';

  @override
  String get firstChapterYourTurn =>
      'Du bist dran: Füge eine Überraschung hinzu.';

  @override
  String get firstChapterBeginningSaved =>
      'Dein Anfang ist gespeichert. Dein Match kann jederzeit eine Überraschung hinzufügen. Ihr könnt weiter chatten.';

  @override
  String get firstChapterClose => 'Dieses Kapitel schließen';

  @override
  String get firstChapterGiveBackTitle => 'Geschichten, die etwas zurückgeben';

  @override
  String get firstChapterGiveBackBody =>
      'Eure Verbindung kann einen neuen Anfang inspirieren. Teilt nur diese anonyme Date-Idee – mit euer beider Zustimmung.';

  @override
  String get firstChapterPreviewAnonymous =>
      'Vorschau unserer anonymen Geschichte';

  @override
  String get firstChapterGreenLightTitle => 'Ein privates grünes Licht';

  @override
  String get firstChapterInTheirWords => 'In ihren Worten';

  @override
  String get firstChapterMakeRoomTitle =>
      'Schaffe Raum für das, was dir wichtig ist';

  @override
  String get firstChapterMakeRoomSubtitle =>
      'Dein Tempo, deine Sprachen, Dates und Erwartungen der Familie. Deine Worte, nur geteilt, wenn du es möchtest.';

  @override
  String get firstChapterCreateWithConnection => 'Mit einem Match gestalten';

  @override
  String get firstChapterCreateTogether =>
      'Gemeinsam ein erstes Kapitel schreiben';

  @override
  String get firstChapterMatchesAppearHere =>
      'Hier erscheinen deine gegenseitigen Matches. Du kannst jetzt schon eine Szene allein ausprobieren und teilen.';

  @override
  String get firstChapterSharedChapters => 'Deine geteilten Kapitel';

  @override
  String get firstChapterReloadShared => 'Geteilte Kapitel neu laden';

  @override
  String get firstChapterNothingPublic =>
      'Nichts ist öffentlich, bis du dich entscheidest, es zu teilen.';

  @override
  String get firstChapterGreenChat => 'Weiter chatten';

  @override
  String get firstChapterGreenCall => 'Einen Anruf wagen';

  @override
  String get firstChapterGreenDate => 'Ein Date vorschlagen';

  @override
  String get firstChapterGreenLightIntro =>
      'Nur eine gemeinsame Wahl wird sichtbar. Niemand sieht eine unbeantwortete Anfrage. Deine Auswahl läuft nach sieben Tagen ab; entferne sie, um sie zurückzuziehen.';

  @override
  String get firstChapterSavePrivately => 'Privat speichern';

  @override
  String get firstChapterGreenLightNone =>
      'Ein gemeinsamer nächster Schritt erscheint hier.';

  @override
  String firstChapterGreenLightMutual(String choices) {
    return 'Ihr fühlt euch beide wohl mit: $choices';
  }

  @override
  String get firstChapterGreenLightNote =>
      'Grünes Licht heißt: Du darfst etwas vorschlagen. Ein Anruf oder Date braucht trotzdem eine eigene Zustimmung.';

  @override
  String get firstChapterLinkRevoked => 'Link widerrufen';

  @override
  String get firstChapterPublicScene => 'Öffentliche, anonyme Szene';

  @override
  String get firstChapterPrivateUntilBoth => 'Privat, bis beide zustimmen';

  @override
  String get firstChapterLinkCopied =>
      'Kapitel-Link kopiert. Teile ihn, wo immer du möchtest.';

  @override
  String get firstChapterCopyLink => 'Link kopieren';

  @override
  String get firstChapterApproveStory => 'Genau dieser Geschichte zustimmen';

  @override
  String get firstChapterRevokeLink => 'Link widerrufen';

  @override
  String networkSlowResponse(int mbps) {
    return 'Schwaches Netz erkannt. Nutze mindestens $mbps Mbit/s für flüssigere Chats, Geschenke und Gesten.';
  }

  @override
  String get networkOffline =>
      'Keine stabile Netzwerkverbindung. Verbinde dich erneut, um die App weiter zu nutzen.';

  @override
  String networkWeak(int mbps) {
    return 'Das Netz ist schwach. Nutze mindestens $mbps Mbit/s für ein flüssigeres Erlebnis.';
  }

  @override
  String get networkCannotReachService =>
      'Der lokale Dienst ist nicht erreichbar. Prüfe, ob die API läuft.';

  @override
  String get gateCheckingTerms => 'Nutzungsbedingungen werden geprüft…';

  @override
  String get gateLoadingProfile => 'Dein Profil wird geladen…';

  @override
  String get gateConnectionIssue => 'Verbindungsproblem';

  @override
  String get safetyReportFailed => 'Meldung fehlgeschlagen';

  @override
  String get safetyBlockFailed => 'Blockieren fehlgeschlagen';

  @override
  String get safetyUnblockFailed => 'Entsperren fehlgeschlagen';

  @override
  String get safetyNotAuthenticated => 'Nicht angemeldet';

  @override
  String get timeAgoJustNow => 'Gerade eben';

  @override
  String timeAgoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Minuten',
      one: 'vor 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String timeAgoWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Wochen',
      one: 'vor 1 Woche',
    );
    return '$_temp0';
  }

  @override
  String get themePreviewBarrier => 'Design-Vorschau';

  @override
  String get themeNowShowing => 'JETZT IM PROGRAMM';

  @override
  String get themeTaglineRealLife => 'Warmes Elfenbein, Waldgrün und Aprikose.';

  @override
  String get themeTaglineRealLifeNight =>
      'Waldgrün, sanfte Minze und Kerzenschein.';

  @override
  String get themeTaglineDaylight =>
      'Creme, Tinte und ein Himbeer-Akzent, wie die Website.';

  @override
  String get themeTaglineEmber =>
      'Pflaumenschwarze Nacht mit Glut und violettem Schimmer.';

  @override
  String get themeTaglineForge => 'Glutrot, Stahlblau, Rotguss-Chrom.';

  @override
  String get themeTaglineNeongrid =>
      'Schwarzes Glas, cyanfarbene Lichtlinien, bernsteinfarbener Puls.';

  @override
  String get themeTaglineCrimsonalloy =>
      'Karminlack, flüssiges Gold, mitternächtliches Kastanienrot.';

  @override
  String get themeTaglineCircuit =>
      'Platinengrün, Signalviolett, Carbonschwarz.';

  @override
  String get themeTaglineDeepfield =>
      'Tiefer Weltraum, Plasmablau und ein Hauch Sternengold.';

  @override
  String get themeTaglineLove => 'Zartrosa, Rosé und ein wenig Gold.';

  @override
  String get themeTaglineRose =>
      'Samtiger Weinton, Rosenrot und ein wenig Gold.';

  @override
  String get themeTaglinePetal =>
      'Rosé Papier, schwebende Blütenblätter, ein Hauch Salbei.';

  @override
  String get themeTaglineSnow =>
      'Frischer Schnee, Milchglas und ein Band aus Polarlicht.';

  @override
  String get themeTaglineGothic =>
      'Mondbeschienenes Maßwerk, Granat, Kerzenrauch und Altgold.';

  @override
  String get themeTaglineCalm =>
      'Wenig Reize, hoher Kontrast. Ruhiger Hintergrund, keine Bewegung.';

  @override
  String get themeLooksTodayDescription =>
      'Tagsüber warmes Elfenbein und Waldgrün. Nachts sanfte Minze und tiefes Waldgrün.';

  @override
  String get settingsEyebrow => 'EINSTELLUNGEN';

  @override
  String get settingsHeaderSubtitle =>
      'Dein Look, deine Privatsphäre und dein Konto.';

  @override
  String get settingsThemeSection => 'Design';

  @override
  String get settingsThemeSectionTitle => 'Mach es zu deinem';

  @override
  String get settingsThemeSectionCaption =>
      'Jeder Bildschirm folgt dem Look, den du wählst.';

  @override
  String get settingsSectionYourStory => 'Deine Geschichte';

  @override
  String get settingsDatingRhythmTitle => 'Dein Dating-Rhythmus';

  @override
  String get settingsDatingRhythmSubtitle =>
      'Absicht, Tempo, Verfügbarkeit und Privatsphäre bei Vorstellungen';

  @override
  String get settingsProfileStoriesTitle => 'Deine Profilgeschichten';

  @override
  String get settingsProfileStoriesSubtitle =>
      'Kleine Momente, deine Worte, optionale Fotos';

  @override
  String get settingsBlogTitle => 'Blog · Offene Kapitel';

  @override
  String get settingsBlogSubtitle =>
      'Dein Tagebuch, deine Fotos, dein Publikum';

  @override
  String get settingsLookPreviewEyebrow => 'HEUTE';

  @override
  String get settingsLookPreviewHeadline => 'Etwas Echtes.';

  @override
  String get friendsEyebrow => 'FREUNDE';

  @override
  String get friendsTitle => 'Deine Leute';

  @override
  String get friendsSubtitle =>
      'Freunde können sich schreiben, Pläne machen und gemeinsam Gruppen gründen. Anfragen brauchen ein Ja von beiden Seiten.';

  @override
  String get friendsBack => 'Zurück';

  @override
  String get friendsAddFriend => 'Freund hinzufügen';

  @override
  String get friendsCreateGroup => 'Gruppe erstellen';

  @override
  String get friendsSectionRequests => 'ANFRAGEN';

  @override
  String get friendsRequestsWaitingOnOthers => 'Warten auf andere';

  @override
  String get friendsRequestsWaitingOnYou => 'Warten auf dich';

  @override
  String get friendsRequestsCaption =>
      'Es wird nichts geteilt, bevor ihr beide zustimmt.';

  @override
  String get friendsSectionChats => 'CHATS';

  @override
  String get friendsChatsTitle => 'Unterhaltungen';

  @override
  String get friendsSectionIntros => 'VORSTELLUNGEN';

  @override
  String get friendsIntrosTitle => 'Vorstellungen für dich';

  @override
  String get friendsSectionVouches => 'EMPFEHLUNGEN';

  @override
  String get friendsVouchesPendingTitle =>
      'Empfehlungen warten auf deine Freigabe';

  @override
  String friendsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Freunde',
      one: '1 Freund',
      zero: 'Noch keine Freunde',
    );
    return '$_temp0';
  }

  @override
  String get friendsIntroduce => 'Vorstellen';

  @override
  String get friendsEmptyBody =>
      'Finde Leute, die du kennst, über Namen oder Benutzernamen, oder füge jemanden aus einem Match, einem Raum oder einer Gruppe hinzu.';

  @override
  String get friendsSectionOnProfile => 'IN DEINEM PROFIL';

  @override
  String get friendsVouchesOnProfileTitle => 'Empfehlungen in deinem Profil';

  @override
  String friendsQuoted(String text) {
    return '„$text“';
  }

  @override
  String friendsVouchedForYou(String name) {
    return '$name hat sich für dich verbürgt';
  }

  @override
  String get friendsHideFromProfile => 'Im Profil ausblenden';

  @override
  String get friendsSectionMore => 'MEHR';

  @override
  String get friendsMoreTitle => 'Pläne und Vorstellungen';

  @override
  String get friendsPlansLinkTitle => 'Mit dir geteilte Date-Pläne';

  @override
  String get friendsPlansLinkSubtitle =>
      'Freunde sagen dir Bescheid, wenn sie ein Date planen und wenn sie sich danach melden.';

  @override
  String get friendsInviteIntroducerTitle =>
      'Lade einen Freund ein, der nicht datet';

  @override
  String get friendsInviteIntroducerSubtitle =>
      'Wähle, wer dich vorstellen darf. Du kannst die Erlaubnis jederzeit prüfen oder zurückziehen.';

  @override
  String get friendsIntroTermsTitle => 'Vorstellungen, wie du es willst';

  @override
  String get friendsIntroTermsSubtitle =>
      'Lege fest, ob Freunde dich vorstellen dürfen und was eine Vorschau zeigt.';

  @override
  String get friendsSectionActivity => 'AKTIVITÄT';

  @override
  String get friendsActivityTitle => 'Mit deinen Freunden';

  @override
  String friendsVouchSentSnack(String name) {
    return 'Empfehlung gesendet. $name muss sie freigeben, bevor sie erscheint.';
  }

  @override
  String friendsRemoveTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String get friendsRemoveBody =>
      'Ihr seid dann nicht mehr befreundet und euer Chat wird geschlossen. Die andere Person erfährt es nicht.';

  @override
  String get friendsRemoveFriend => 'Freund entfernen';

  @override
  String get friendsIntroMadeSnack =>
      'Vorstellung gemacht. Beide Freunde hören von dir.';

  @override
  String get friendsAddSheetLabel => 'FREUND HINZUFÜGEN';

  @override
  String get friendsAddSheetTitle => 'Finde jemanden, den du kennst';

  @override
  String get friendsAddSheetCaption =>
      'Suche nach Namen oder @Benutzernamen. Die Person entscheidet, ob sie annimmt.';

  @override
  String get friendsSearchHiddenNote =>
      'Du bist in der Freundesuche verborgen, daher können andere dich hier nicht finden. Das kannst du unter Privatsphäre & Sicherheit ändern.';

  @override
  String get friendsSearchLabel => 'Name oder @Benutzername';

  @override
  String get friendsSearchHelper => 'Gib mindestens 3 Buchstaben ein';

  @override
  String get friendsSearchFailed =>
      'Die Suche ist gerade nicht verfügbar. Versuch es noch einmal.';

  @override
  String friendsSearchNoResults(String query) {
    return 'Niemand gefunden für „$query“.';
  }

  @override
  String get friendsNewGroupLabel => 'NEUE GRUPPE';

  @override
  String get friendsNewGroupTitle => 'Wer ist dabei?';

  @override
  String get friendsNewGroupCaption =>
      'Wähle Freunde zum Einladen. Du kannst später weitere hinzufügen.';

  @override
  String get friendsChooseFriends => 'Freunde wählen';

  @override
  String friendsCreateGroupWith(int count) {
    return 'Gruppe mit $count erstellen';
  }

  @override
  String get friendsSourceMatch => 'Aus deinen Matches';

  @override
  String get friendsSourceProfile => 'Hat dein Profil gesehen';

  @override
  String get friendsSourceRoom => 'In einem Raum kennengelernt';

  @override
  String get friendsSourceGroup => 'Aus einer Gruppe';

  @override
  String get friendsSourceSearch => 'Hat dich über den Namen gefunden';

  @override
  String get friendsWantsToBeFriends => 'Möchte befreundet sein';

  @override
  String get friendsRequestSent => 'Anfrage gesendet';

  @override
  String get friendsCancel => 'Abbrechen';

  @override
  String get friendsDecline => 'Ablehnen';

  @override
  String get friendsAccept => 'Annehmen';

  @override
  String friendsMessageTooltip(String name) {
    return '$name schreiben';
  }

  @override
  String friendsMessageTooltipUnread(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$name schreiben, $count ungelesen',
    );
    return '$_temp0';
  }

  @override
  String friendsMoreFor(String name) {
    return 'Mehr für $name';
  }

  @override
  String get friendsMenuVouch => 'Für sie verbürgen';

  @override
  String get friendsMenuIntro => 'Einem Freund vorstellen';

  @override
  String friendsChatSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chat mit $name, $count ungelesen',
      zero: 'Chat mit $name',
    );
    return '$_temp0';
  }

  @override
  String friendsChatSemanticsMuted(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chat mit $name, $count ungelesen, Benachrichtigungen stumm',
      zero: 'Chat mit $name, Benachrichtigungen stumm',
    );
    return '$_temp0';
  }

  @override
  String friendsIntroHeadline(String introducer, String person) {
    return '$introducer findet, du solltest $person kennenlernen';
  }

  @override
  String friendsIntroHeadlineSomeone(String introducer) {
    return '$introducer findet, du solltest jemanden kennenlernen';
  }

  @override
  String friendsNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String get friendsIntroNoThanks => 'Nein, danke';

  @override
  String get friendsIntroImIn => 'Bin dabei';

  @override
  String get friendsVouchKeepPrivate => 'Privat halten';

  @override
  String get friendsVouchShowOnProfile => 'In meinem Profil zeigen';

  @override
  String get memberProfileNoData => 'Keine Profildaten gefunden.';

  @override
  String get memberProfileSignInToView =>
      'Bitte melde dich an, um dein Profil zu sehen.';

  @override
  String get memberProfileLoadFailed =>
      'Profil konnte nicht geladen werden. Bitte versuche es erneut.';

  @override
  String get memberProfileConnectionsTitle => 'Deine Kontakte';

  @override
  String get memberProfileConnectionsCaption =>
      'Deine Likes, Matches und Chats.';

  @override
  String get memberProfileStatLiked => 'Deine Likes';

  @override
  String get memberProfileStatMatches => 'Matches';

  @override
  String get memberProfileStatMessages => 'Nachrichten';

  @override
  String memberProfileOpenStat(String label) {
    return '$label öffnen';
  }

  @override
  String get memberProfileNoticedTitle => 'Wer dich bemerkt hat';

  @override
  String get memberProfileNoticedCaption =>
      'Likes und Profilbesuche von Mitgliedern in deiner Nähe.';

  @override
  String get memberProfileWhoLikedMe => 'Wer mich geliked hat';

  @override
  String memberProfileWhoLikedMeCount(int count) {
    return 'Wer mich geliked hat ($count)';
  }

  @override
  String get memberProfileWhoLikedMeSubtitle =>
      'Mitglieder, denen dein Profil gefällt.';

  @override
  String get memberProfileWhoViewedTitle => 'Wer mein Profil angesehen hat';

  @override
  String get memberProfileWhoViewedSubtitle =>
      'Letzte Besuche auf deinem Profil.';

  @override
  String get memberProfileWhoViewedTooltip => 'Wer mein Profil angesehen hat';

  @override
  String get memberProfileRefreshTooltip => 'Profil aktualisieren';

  @override
  String get memberProfilePreferencesTitle => 'Deine Vorlieben';

  @override
  String get memberProfilePrefSeeking => 'Ich suche';

  @override
  String get memberProfilePrefDistance => 'Entfernung';

  @override
  String memberProfileWithinKm(int km) {
    return 'Im Umkreis von $km km';
  }

  @override
  String get profileViewersTitle => 'Profilbesucher';

  @override
  String get profileViewersLoadFailed =>
      'Profilbesucher konnten nicht geladen werden.';

  @override
  String get profileViewersEmpty => 'Noch hat niemand dein Profil angesehen.';

  @override
  String get profileViewersViewedRecently => 'Kürzlich angesehen';

  @override
  String profileViewersViewedAt(String time) {
    return 'Angesehen am $time';
  }

  @override
  String get profileMasterReligionParsi => 'Parsisch';

  @override
  String get profileMasterReligionBahai => 'Bahai';

  @override
  String get profileMasterReligionTribal => 'Stammesreligion / Indigen';

  @override
  String get profileMasterWorkout1to2 => '1-2 Mal pro Woche';

  @override
  String get profileMasterWorkout3to4 => '3-4 Mal pro Woche';

  @override
  String get profileMasterWorkout5Plus => '5+ Mal pro Woche';

  @override
  String get profileMasterWorkoutDaily => 'Täglich';

  @override
  String get profileMasterDietNoPreference => 'Keine Präferenz';

  @override
  String get profileMasterDietVegetarian => 'Vegetarisch';

  @override
  String get profileMasterDietEggetarian => 'Vegetarisch mit Ei';

  @override
  String get profileMasterDietNonVegetarian => 'Nicht vegetarisch';

  @override
  String get profileMasterDietVegan => 'Vegan';

  @override
  String get profileMasterDietJain => 'Jainistische Ernährung';

  @override
  String get profileMasterDietTypeBalanced => 'Ausgewogen';

  @override
  String get profileMasterDietTypeHighProtein => 'Proteinreich';

  @override
  String get profileMasterDietTypeLowCarb => 'Low Carb';

  @override
  String get profileMasterDietTypeKeto => 'Keto';

  @override
  String get profileMasterDietTypeMediterranean => 'Mediterran';

  @override
  String get profileMasterDietTypeIntermittentFasting => 'Intervallfasten';

  @override
  String get profileMasterSleepEarlyBird => 'Frühaufsteher';

  @override
  String get profileMasterSleepNightOwl => 'Nachteule';

  @override
  String get profileMasterSleepFlexible => 'Flexibel';

  @override
  String get profileMasterSleepShiftBased => 'Schichtarbeit';

  @override
  String get profileMasterTravelHomebody => 'Häuslich';

  @override
  String get profileMasterTravelOccasional => 'Gelegentlich auf Reisen';

  @override
  String get profileMasterTravelFrequent => 'Viel unterwegs';

  @override
  String get profileMasterTravelAdventure => 'Abenteuerlustig';

  @override
  String get profileMasterTravelLuxury => 'Luxusreisen';

  @override
  String get profileMasterTravelBackpacker => 'Backpacker';

  @override
  String get profileMasterPoliticsSimilar => 'Nur ähnliche Ansichten';

  @override
  String get profileMasterPoliticsOpen => 'Offen für andere Ansichten';

  @override
  String get profileMasterPoliticsNotDiscuss => 'Lieber kein Thema';

  @override
  String get profileMasterPoliticsNoStrong => 'Keine feste Präferenz';

  @override
  String get profileMasterIntentLongTerm => 'Etwas Langfristiges';

  @override
  String get profileMasterIntentMarriage => 'Ehe';

  @override
  String get profileMasterIntentNewFriends => 'Neue Freunde';

  @override
  String get chatBackToConversations => 'Zurück zu den Unterhaltungen';

  @override
  String get chatOfflineBanner =>
      'Du bist offline. Dein Entwurf bleibt hier, bis die Verbindung wieder steht.';

  @override
  String get chatVoiceHello => 'Sprachgruß teilen · lesen & anhören';

  @override
  String get chatLoadFailedTitle => 'Lass uns neu verbinden.';

  @override
  String get chatLoadFailedBody =>
      'Deine Unterhaltung konnte nicht geladen werden. Versuch es noch einmal.';

  @override
  String get chatConversationEnded => 'Diese Unterhaltung ist beendet.';

  @override
  String get chatUnlockStepRequired =>
      'Schließ den aktuellen Freischaltschritt ab, um die Unterhaltung fortzusetzen.';

  @override
  String get chatGiftTrayTitle => 'Eine kleine Aufmerksamkeit';

  @override
  String get chatCloseGifts => 'Geschenke schließen';

  @override
  String get chatAllGifts => 'Alle Geschenke';

  @override
  String get chatNoGiftsInCollection =>
      'In dieser Kollektion gibt es keine Geschenke.';

  @override
  String get chatAddCoins => 'Coins aufladen';

  @override
  String get chatFreeGiftDaily => 'Gratis · 1 pro Tag';

  @override
  String chatCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Coins',
      one: '1 Coin',
    );
    return '$_temp0';
  }

  @override
  String get chatSendingGift => 'Dein Geschenk wird gesendet …';

  @override
  String get chatOfflineGifts =>
      'Du bist offline. Du kannst Geschenke ansehen und sie senden, sobald du wieder verbunden bist.';

  @override
  String chatGiftConfirmTitle(String gift, String name) {
    return '$gift an $name senden?';
  }

  @override
  String chatGiftNoteQuote(String note) {
    return '„$note“';
  }

  @override
  String chatGiftBalanceAfter(int balance, int remaining) {
    return '·  $balance → $remaining übrig';
  }

  @override
  String get chatGiftNoObligation =>
      'Ein Geschenk ist eine Geste, keine Verpflichtung zu antworten oder sich zu treffen.';

  @override
  String chatGiftSendFor(String price) {
    return 'Für $price senden';
  }

  @override
  String get chatNotNow => 'Nicht jetzt';

  @override
  String get chatDeleteMessageTitle => 'Nachricht löschen?';

  @override
  String get chatDeleteMessageBody =>
      'Damit wird die Nachricht bei euch beiden gelöscht.';

  @override
  String get chatDeleteForEveryone => 'Für alle löschen';

  @override
  String get chatMessageDeletedSnack => 'Nachricht gelöscht.';

  @override
  String get chatUndo => 'Rückgängig';

  @override
  String get chatDeleteUndone => 'Löschen rückgängig gemacht.';

  @override
  String chatGiftReceivedFrom(String name) {
    return 'Geschenk von $name';
  }

  @override
  String get chatGiftReceiverIntro =>
      'Du entscheidest, was in deinem Chat bleibt.';

  @override
  String get chatHideGift => 'Geschenk ausblenden';

  @override
  String get chatHideGiftSubtitle => 'Nur aus deinem Chat entfernen.';

  @override
  String get chatReportAndHide => 'Melden und ausblenden';

  @override
  String get chatReportAndHideSubtitle =>
      'An das Sicherheitsteam senden und sofort entfernen.';

  @override
  String get chatGiftHidden => 'Geschenk aus deinem Chat ausgeblendet.';

  @override
  String get chatReportGiftTitle => 'Dieses Geschenk melden';

  @override
  String get chatReportGiftIntro =>
      'Wähle einen Grund. Das Geschenk wird sofort ausgeblendet.';

  @override
  String get chatReportReasonLabel => 'Grund';

  @override
  String get chatReportReasonUnwanted => 'Unerwünschtes Geschenk';

  @override
  String get chatReportReasonHarassment => 'Belästigung';

  @override
  String get chatReportReasonSexual => 'Sexuelle Inhalte';

  @override
  String get chatReportReasonScam => 'Betrug';

  @override
  String get chatReportReasonOther => 'Etwas anderes';

  @override
  String get chatReportDetailsLabel => 'Details hinzufügen (optional)';

  @override
  String get chatReportSubmit => 'Melden und ausblenden';

  @override
  String get chatGiftReported =>
      'Geschenk gemeldet und ausgeblendet. Unser Sicherheitsteam sieht es sich an.';

  @override
  String get chatQuickEmojis => 'Schnelle Emojis';

  @override
  String chatWalletTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Coins',
      one: '1 Coin',
    );
    return 'Dein Wallet · $_temp0';
  }

  @override
  String get chatDailyLimitReached => 'Tageslimit für Nachrichten erreicht';

  @override
  String get chatDailyLimitFallback =>
      'Versuch es morgen wieder oder wechsle zu einem größeren Abo.';

  @override
  String chatDailyLimitReset(String reset) {
    return '$reset · Upgrade für mehr.';
  }

  @override
  String get chatSeePlans => 'Abos ansehen';

  @override
  String chatQuotaOnPlan(String quota, String plan) {
    return '$quota mit $plan';
  }

  @override
  String get chatYourConversation => 'Eure Unterhaltung';

  @override
  String get chatVerifiedHumans => 'Verifizierte Menschen';

  @override
  String get chatVerifiedHumansShowsUp =>
      'Verifizierte Menschen · Erscheint zuverlässig';

  @override
  String discoverLikedBack(String name) {
    return 'Du hast $name zurückgeliked';
  }

  @override
  String discoverPassedOn(String name) {
    return '$name übersprungen';
  }

  @override
  String get discoverLikedMeLoadFailedTitle =>
      'Deine Likes konnten nicht geladen werden';

  @override
  String get discoverLikedMeEmptyTitle => 'Noch keine neuen Likes';

  @override
  String get discoverLikedMeEmptyBody =>
      'Wenn dich jemand liked, erscheint die Person hier. Like zurück und ihr habt ein Match.';

  @override
  String get discoverLikedMeIntro =>
      'Diese Personen liken dich schon. Like zurück für ein Match oder überspringe. Überspringen bleibt privat.';

  @override
  String get discoverLikedMeTitle => 'Haben dich geliked';

  @override
  String discoverLikedMeTitleCount(int count) {
    return 'Haben dich geliked · $count';
  }

  @override
  String get discoverPass => 'Überspringen';

  @override
  String get discoverLikeBack => 'Zurückliken';

  @override
  String get discoverLikedJustNow => 'Hat dich gerade geliked';

  @override
  String discoverLikedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hat dich vor $count Minuten geliked',
      one: 'Hat dich vor 1 Minute geliked',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hat dich vor $count Stunden geliked',
      one: 'Hat dich vor 1 Stunde geliked',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hat dich vor $count Tagen geliked',
      one: 'Hat dich vor 1 Tag geliked',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hat dich vor $count Wochen geliked',
      one: 'Hat dich vor 1 Woche geliked',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedOnDate(String date) {
    return 'Hat dich am $date geliked';
  }

  @override
  String discoverLikedProfilesTitle(int count) {
    return 'Gelikte Profile ($count)';
  }

  @override
  String get discoverNoLikedProfiles => 'Noch keine gelikten Profile';

  @override
  String get discoverLikedProfileFallback => 'Gelikets Profil';

  @override
  String get discoverPassedProfilesTitle => 'Übersprungene Profile';

  @override
  String get discoverNoPassedProfiles => 'Noch keine übersprungenen Profile';

  @override
  String get discoverSavedForLater => 'Für später gemerkt';

  @override
  String get discoverSpotlightFiltersTitle => 'Spotlight-Filter';

  @override
  String get discoverVerifiedOnly => 'Nur verifizierte';

  @override
  String discoverAgeRange(int min, int max) {
    return 'Alter: $min – $max';
  }

  @override
  String get discoverSpotlightTitle => 'Spotlight-Matches';

  @override
  String get discoverSpotlightSubtitle => 'Ausgewählte Premium-Kontakte';

  @override
  String discoverPassedCount(int count) {
    return 'Übersprungen ($count)';
  }

  @override
  String get discoverOpenChatsFromDiscover => 'Öffne Chats über Entdecken';

  @override
  String get discoverNoNewNotifications => 'Keine neuen Benachrichtigungen';

  @override
  String get discoverNoSpotlightMatchFilters =>
      'Keine Spotlight-Profile passen zu den Filtern';

  @override
  String get discoverAllSpotlightReviewed =>
      'Alle Spotlight-Profile durchgesehen!';

  @override
  String get discoverSpotlightCheckBackLater =>
      'Schau später nach neuen Spotlight-Profilen';

  @override
  String get discoverReportSubmitted => 'Meldung gesendet.';

  @override
  String get discoverAppeal => 'Einspruch';

  @override
  String discoverAppealPrefill(String userId) {
    return 'Moderationsergebnis zur Meldung über Nutzer $userId prüfen';
  }

  @override
  String get discoverProfileUnavailable =>
      'Dieses Profil ist gerade nicht verfügbar.';

  @override
  String get discoverGoBack => 'Zurück';

  @override
  String get discoverPremiumView => 'Premium-Ansicht';

  @override
  String get todayLabel => 'HEUTE';

  @override
  String get todayRefreshTooltip => 'Heute aktualisieren';

  @override
  String get todayDiscoveryPreferences => 'Entdecken-Einstellungen';

  @override
  String get todayHeroTitle => 'Ein kleines Hallo.\nRaum für etwas Echtes.';

  @override
  String get todayHeroSubtitle =>
      'Ein paar durchdachte Vorstellungen, in deinem Tempo.';

  @override
  String get todaySectionPace => 'DEIN TEMPO';

  @override
  String get todayPaceTitle => 'Was passt in deine Woche?';

  @override
  String get todayPaceBody =>
      'Dein Tempo, deine Art von erstem Date, freiwillige Verfügbarkeit.';

  @override
  String get todaySetRhythm => 'Deinen Rhythmus festlegen';

  @override
  String get todaySectionStory => 'DEINE GESCHICHTE';

  @override
  String get todaySectionIntroductions => 'HEUTIGE VORSTELLUNGEN';

  @override
  String get todayIntroductionsTitle => 'Ein paar Menschen zum Kennenlernen';

  @override
  String get todayIntroductionsCaption =>
      'Gemeinsame Interessen sind ein Anfang. Die Chemie entdeckst du selbst.';

  @override
  String get todayPausedTitle => 'Nimm dir die Zeit, die du brauchst.';

  @override
  String get todayPausedBody =>
      'Vorstellungen sind pausiert. Deine Unterhaltungen sind weiterhin da.';

  @override
  String get todayManageRhythm => 'Deinen Rhythmus verwalten';

  @override
  String get todayLoadingIntroductions => 'Vorstellungen werden geladen';

  @override
  String get todayFailedTitle =>
      'Deine Vorstellungen brauchen noch einen Moment.';

  @override
  String get todayFailedBody =>
      'Wir konnten die neuesten Informationen nicht laden. Bitte versuche es erneut.';

  @override
  String get todayTryAgain => 'Erneut versuchen';

  @override
  String get todayEmptyTitle => 'Ein bisschen Luft zum Atmen.';

  @override
  String get todayEmptyBody =>
      'Für deine Einstellungen gibt es gerade keine neuen Vorstellungen. Du kannst deinen Rhythmus anpassen oder Profile entdecken.';

  @override
  String get todayExploreProfiles => 'Profile entdecken';

  @override
  String get todayAllIntroductions => 'Alle Vorstellungen';

  @override
  String get todayBreatheTitle =>
      'Eine gute Verbindung braucht Raum zum Atmen.';

  @override
  String get todayBreatheBody =>
      'Das sind die heutigen Vorstellungen. Es gibt keinen Countdown und du musst dich nicht bei allen entscheiden.';

  @override
  String get todayExploreMore => 'Mehr Profile entdecken';

  @override
  String get todayCommonGround => 'EIN BISSCHEN GEMEINSAMKEIT';

  @override
  String todayMeetName(String name) {
    return '$name kennenlernen';
  }

  @override
  String get todayFirstHelloCoffee =>
      'Ein erstes Hallo könnte ein gemeinsamer Kaffee sein.';

  @override
  String get todayFirstHelloWalk =>
      'Ein erstes Hallo könnte ein Spaziergang bei Tag sein.';

  @override
  String get todayFirstHelloMeal =>
      'Ein erstes Hallo könnte ein entspanntes Essen sein.';

  @override
  String get todayFirstHelloVideoCall =>
      'Ein erstes Hallo könnte ein Videoanruf sein.';

  @override
  String get todayFirstHelloEvent =>
      'Ein erstes Hallo könnte ein Event sein, das euch beiden gefällt.';

  @override
  String get todayFirstHelloDrinks =>
      'Ein erstes Hallo könnte ein gemeinsamer Drink sein.';

  @override
  String get todayFirstHelloOther =>
      'Ein erstes Hallo könnte etwas sein, das euch beiden gefällt.';

  @override
  String get todaySectionTalk => 'GESPRÄCHSSTOFF';

  @override
  String get todayTalkCaption =>
      'Geschichten, Clubs und Impulse, die ein erstes Hallo leichter machen.';

  @override
  String get todayBlogTitle => 'Blog · Offene Kapitel';

  @override
  String get todayBlogSubtitle =>
      'Lies Geschichten anderer Mitglieder und schreib deine eigenen.';

  @override
  String get todayBookClubsTitle => 'Buchclubs';

  @override
  String get todayBookClubsSubtitle =>
      'Ein Buch pro Woche, gemeinsam besprochen.';

  @override
  String get todayFilmClubsTitle => 'Filmclubs';

  @override
  String get todayFilmClubsSubtitle =>
      'Schau den ausgewählten Film und tauscht euch dann aus.';

  @override
  String get todayPhotoThemesTitle => 'Fotothemen';

  @override
  String get todayPhotoThemesSubtitle =>
      'Ein Foto pro Thema. Sieh dir alle an.';

  @override
  String get todayChapterStudioTitle => 'Studio „Erstes Kapitel“';

  @override
  String get todayChapterStudioSubtitle => 'Beginnt gemeinsam eine Geschichte.';

  @override
  String get todayCoverFallbackLine => 'Ein Foto, das Mitglieder geliebt haben';

  @override
  String todayCoverSemantics(String name) {
    return 'Cover der Woche von $name öffnen';
  }

  @override
  String get todayCoverTitle => 'COVER DER WOCHE';

  @override
  String todayCoverBy(String name) {
    return 'VON $name';
  }

  @override
  String get todayLikes => 'Likes';

  @override
  String get todayComments => 'Kommentare';

  @override
  String get todayThisWeek => 'Diese Woche';

  @override
  String get todayWallLabel => 'AUS DER COMMUNITY';

  @override
  String get todayWallTitle => 'Die Wand von heute';

  @override
  String get todayWallCaption =>
      'Geschichten und Fotos, die Mitglieder geliebt haben – jeden Tag eine neue Auswahl';

  @override
  String get todayWallPrevious => 'Vorheriger Beitrag';

  @override
  String get todayWallNext => 'Nächster Beitrag';

  @override
  String get todayWallChapter => 'KAPITEL';

  @override
  String get todayWallUntitled => 'Ein Kapitel ohne Titel';

  @override
  String todayWallBy(String name) {
    return 'von $name';
  }

  @override
  String get todayWallEmpty =>
      'Deine Wand füllt sich, sobald Mitglieder Geschichten und Fotos teilen, die sie lieben';

  @override
  String get todayWallWrite => 'Kapitel schreiben';

  @override
  String get todayWallShare => 'Foto teilen';

  @override
  String get profileSetupBackTooltip => 'Zurück';

  @override
  String profileSetupStepCounter(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get profileSetupLoadErrorTitle =>
      'Profildaten konnten nicht geladen werden.';

  @override
  String get profileSetupRetry => 'Erneut versuchen';

  @override
  String get profileSetupEducationHighSchool => 'Schulabschluss';

  @override
  String get profileSetupEducationBachelors => 'Bachelor';

  @override
  String get profileSetupEducationMasters => 'Master';

  @override
  String get profileSetupEducationPhd => 'Promotion';

  @override
  String get profileSetupEducationOther => 'Sonstiges';

  @override
  String get profileSetupPreferNotToSay => 'Keine Angabe';

  @override
  String profileSetupIncomeBelow(String amount) {
    return 'Unter $amount';
  }

  @override
  String get profileSetupFrequencyNever => 'Nie';

  @override
  String get profileSetupFrequencySocially => 'Gesellig';

  @override
  String get profileSetupFrequencyOccasionally => 'Gelegentlich';

  @override
  String get profileSetupFrequencyRegularly => 'Regelmäßig';

  @override
  String get profileSetupGenderMan => 'Mann';

  @override
  String get profileSetupGenderWoman => 'Frau';

  @override
  String get profileSetupGenderOther => 'Divers';

  @override
  String profileSetupBioTooShort(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Die Bio muss mindestens $min Zeichen lang sein.',
      one: 'Die Bio muss mindestens 1 Zeichen lang sein.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupSaveFailed =>
      'Speichern fehlgeschlagen — bitte versuch es noch einmal.';

  @override
  String get profileSetupCouldNotSaveChanges =>
      'Deine Änderungen konnten nicht gespeichert werden. Bitte versuch es noch einmal.';

  @override
  String get profileSetupAboutTitle => 'Lass dein Profil glänzen';

  @override
  String get profileSetupAboutSubtitle =>
      'Diese Angaben helfen, passendere Matches zu finden.';

  @override
  String get profileSetupBioLabel => 'Bio';

  @override
  String profileSetupBioHint(int min) {
    return 'Erzähl etwas über dich (mind. $min Zeichen)';
  }

  @override
  String get profileSetupHeightLabel => 'Größe (cm)';

  @override
  String get profileSetupHeightHint => 'Größe wählen';

  @override
  String profileSetupHeightValue(int cm) {
    return '$cm cm';
  }

  @override
  String get profileSetupEducationLabel => 'Ausbildung';

  @override
  String get profileSetupEducationHint => 'Ausbildung wählen';

  @override
  String get profileSetupProfessionLabel => 'Beruf';

  @override
  String get profileSetupProfessionHint => 'z. B. Softwareentwickler:in';

  @override
  String get profileSetupIncomeLabel => 'Einkommen (optional)';

  @override
  String get profileSetupLifestyleTitle => 'Lebensstil';

  @override
  String get profileSetupDrinkingLabel => 'Alkohol';

  @override
  String get profileSetupSmokingLabel => 'Rauchen';

  @override
  String get profileSetupSelectHint => 'Auswählen';

  @override
  String get profileSetupReligionOptionalLabel => 'Religion (optional)';

  @override
  String get profileSetupContinue => 'Weiter';

  @override
  String get profileSetupSaveAbout => 'Über mich speichern';

  @override
  String get profileSetupPhotosSaved => 'Fotos gespeichert.';

  @override
  String profileSetupPhotosMaxReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Du kannst höchstens $max Fotos hochladen.',
      one: 'Du kannst nur 1 Foto hochladen.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupRemovePhotoTitle => 'Dieses Foto entfernen?';

  @override
  String get profileSetupRemovePhotoBody =>
      'Es wird aus deinem Profil entfernt und aus dem Speicher gelöscht.';

  @override
  String get profileSetupCancel => 'Abbrechen';

  @override
  String get profileSetupRemove => 'Entfernen';

  @override
  String profileSetupPhotosMinRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Lade mindestens $min Fotos hoch, um fortzufahren.',
      one: 'Lade mindestens 1 Foto hoch, um fortzufahren.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTitle => 'Füge deine Fotos hinzu';

  @override
  String profileSetupPhotosSubtitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Füge mindestens $min Fotos hinzu, um Matches zu bekommen',
      one: 'Füge mindestens 1 Foto hinzu, um Matches zu bekommen',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupChooseSource => 'Quelle wählen';

  @override
  String get profileSetupGallery => 'Galerie';

  @override
  String get profileSetupCamera => 'Kamera';

  @override
  String get profileSetupPhotoRequirements =>
      'JPEG, PNG, WebP oder HEIC · mind. 300×300 · je 10 MB · insgesamt 50 MB';

  @override
  String profileSetupPhotosTipEmpty(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other:
          'Füge mindestens $min Fotos hinzu, die verschiedene Seiten von dir zeigen.',
      one:
          'Füge mindestens 1 Foto hinzu, das verschiedene Seiten von dir zeigt.',
    );
    return '$_temp0';
  }

  @override
  String profileSetupPhotosTipMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Füge noch $count Fotos hinzu, um alle Matching-Funktionen freizuschalten.',
      one:
          'Füge noch 1 Foto hinzu, um alle Matching-Funktionen freizuschalten.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTipDone =>
      'Super! Du kannst die Fotos per Ziehen neu anordnen.';

  @override
  String get profileSetupYourPhotosHeading =>
      'Deine Fotos  •  zum Anordnen ziehen';

  @override
  String get profileSetupContinueToAbout => 'Weiter zu Über mich';

  @override
  String get profileSetupSavePhotos => 'Fotos speichern';

  @override
  String get profileSetupPrimaryPhoto => 'Hauptfoto';

  @override
  String profileSetupPhotoNumber(int number) {
    return 'Foto $number';
  }

  @override
  String get profileSetupShownFirst => 'Wird in deinem Profil zuerst angezeigt';

  @override
  String get profileSetupDragHandleHint => 'Zum Anordnen am Griff ziehen';

  @override
  String get profileSetupAwaitingSafetyReview =>
      'Wartet auf Sicherheitsprüfung';

  @override
  String get profileSetupSafetyCheckInProgress => 'Sicherheitsprüfung läuft';

  @override
  String get profileSetupSetAsProfilePicture => 'Als Profilbild festlegen';

  @override
  String get profileSetupProfilePictureSelected => 'Als Profilbild ausgewählt';

  @override
  String get profileSetupRemovePhotoTooltip => 'Foto entfernen';

  @override
  String get profileSetupPhotoTooLarge =>
      'Dieses Foto ist größer als das Limit von 10 MB.';

  @override
  String get profileSetupPhotoUnsupportedType =>
      'Verwende ein Foto im Format JPEG, PNG, WebP oder HEIC.';

  @override
  String get profileSetupPhotoBadDimensions =>
      'Die Fotoabmessungen müssen zwischen 300×300 und 4096×4096 liegen.';

  @override
  String get profileSetupPhotoQuotaReached =>
      'Dein Kontingent für Profilfotos ist erreicht.';

  @override
  String get profileSetupPhotoStorageFull =>
      'Der Fotospeicher ist vorübergehend voll. Bitte versuch es später noch einmal.';

  @override
  String get profileSetupPhotoUpdateFailed =>
      'Foto konnte nicht aktualisiert werden. Bitte versuch es noch einmal.';

  @override
  String profileSetupPhotoMaxAllowed(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Es sind höchstens $max Fotos erlaubt.',
      one: 'Es ist höchstens 1 Foto erlaubt.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPreferencesLoadFailed =>
      'Präferenzen konnten nicht geladen werden';

  @override
  String get profileSetupOfflineBanner =>
      'Offlinemodus — manche Daten sind eventuell veraltet.';

  @override
  String get profileSetupYourPreferences => 'Deine Präferenzen';

  @override
  String get profileSetupEditPreferencesTitle => 'Präferenzen bearbeiten';

  @override
  String get profileSetupFinishAndFindMatches => 'Abschließen & Matches finden';

  @override
  String get profileSetupSavePreferences => 'Präferenzen speichern';

  @override
  String get profileSetupSelectGenderPreference =>
      'Wähle mindestens ein Geschlecht aus.';

  @override
  String get profileSetupFinishFailed =>
      'Die Einrichtung konnte nicht abgeschlossen werden. Prüf deine Fotos und Präferenzen und versuch es dann noch einmal.';

  @override
  String get profileSetupPreferencesSaveFailed =>
      'Einige Präferenzen konnten gerade nicht gespeichert werden.';

  @override
  String get profileSetupPreferencesSaved => 'Präferenzen gespeichert.';

  @override
  String get profileSetupTabBasic => 'Basis';

  @override
  String get profileSetupTabAdvanced => 'Erweitert';

  @override
  String get profileSetupLookingFor => 'Ich suche';

  @override
  String get profileSetupSeekingMen => 'Männer';

  @override
  String get profileSetupSeekingWomen => 'Frauen';

  @override
  String get profileSetupSeekingOther => 'Divers';

  @override
  String profileSetupAgeRangeTitle(int min, int max) {
    return 'Altersbereich: $min – $max';
  }

  @override
  String profileSetupMaxDistanceTitle(int km) {
    return 'Max. Entfernung: $km km';
  }

  @override
  String profileSetupDistanceValue(int km) {
    return '$km km';
  }

  @override
  String get profileSetupRelationshipIntent => 'Beziehungsabsicht';

  @override
  String get profileSetupSeriousOnly => 'Nur ernsthafte Beziehung';

  @override
  String get profileSetupSeriousOnlySubtitle =>
      'Nur Leute zeigen, die etwas Festes suchen';

  @override
  String get profileSetupVerifiedOnly => 'Nur verifizierte Profile';

  @override
  String get profileSetupVerifiedOnlySubtitle =>
      'Nur Konten mit verifiziertem Ausweis';

  @override
  String get profileSetupHookupsOnly => 'Nur Lockeres';

  @override
  String get profileSetupHookupsOnlySubtitle =>
      'Nur Profile für Lockeres zeigen';

  @override
  String get profileSetupLocation => 'Ort';

  @override
  String get profileSetupCountry => 'Land';

  @override
  String get profileSetupStateRegion => 'Bundesland / Region';

  @override
  String get profileSetupCity => 'Stadt';

  @override
  String get profileSetupBackgroundCulture => 'Herkunft & Kultur';

  @override
  String get profileSetupReligionPreference => 'Religion';

  @override
  String get profileSetupMotherTongue => 'Muttersprache';

  @override
  String get profileSetupLanguage => 'Sprache';

  @override
  String get profileSetupDietPreference => 'Ernährung';

  @override
  String get profileSetupWorkoutFrequency => 'Wie oft du trainierst';

  @override
  String get profileSetupDietType => 'Ernährungsweise';

  @override
  String get profileSetupSleepSchedule => 'Schlafrhythmus';

  @override
  String get profileSetupTravelStyle => 'Reisestil';

  @override
  String get profileSetupPoliticalComfortRange => 'Politische Toleranz';

  @override
  String get profileSetupInterestsPersonality => 'Interessen & Persönlichkeit';

  @override
  String get profileSetupInstagramHandle => 'Instagram-Name (ohne @)';

  @override
  String get profileSetupIntentTags => 'Absichten (langfristig, Ehe, locker…)';

  @override
  String get profileSetupHobbiesField => 'Hobbys (durch Kommas getrennt)';

  @override
  String get profileSetupFavouriteBooksField =>
      'Lieblingsbücher (durch Kommas getrennt)';

  @override
  String get profileSetupFavouriteNovelsField =>
      'Lieblingsromane (durch Kommas getrennt)';

  @override
  String get profileSetupFavouriteSongsField =>
      'Lieblingssongs (durch Kommas getrennt)';

  @override
  String get profileSetupExtraCurricularField =>
      'Freizeitaktivitäten (durch Kommas getrennt)';

  @override
  String get profileSetupAdditionalInformation => 'Weitere Informationen';

  @override
  String get profileSetupPetPreference => 'Haustiere';

  @override
  String get profileSetupDealBreakers => 'No-Gos';

  @override
  String get profileSetupTagsField => 'Tags (durch Kommas getrennt)';

  @override
  String get profileSetupNameRequired => 'Name ist erforderlich.';

  @override
  String get profileSetupDobRequired => 'Geburtsdatum ist erforderlich.';

  @override
  String profileSetupPhotosRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Mindestens $min Fotos sind erforderlich.',
      one: 'Mindestens 1 Foto ist erforderlich.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupServerError => 'Serverfehler';

  @override
  String get profileSetupNetworkError =>
      'Netzwerkfehler — bitte versuch es noch einmal.';

  @override
  String get profileSetupGenericError =>
      'Etwas ist schiefgelaufen. Bitte versuch es noch einmal.';

  @override
  String get profileSetupPreviewTitle => 'Vorschau deines Profils';

  @override
  String get profileSetupPreviewSubtitle => 'So sehen dich andere.';

  @override
  String profileSetupNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String profileSetupDrinksChip(String value) {
    return 'Alkohol: $value';
  }

  @override
  String profileSetupSmokesChip(String value) {
    return 'Rauchen: $value';
  }

  @override
  String get profileSetupCompleteProfile => 'Profil abschließen';

  @override
  String profileSetupCompletionPercent(int percent) {
    return 'Profil vollständig: $percent %';
  }

  @override
  String get profileEditTitle => 'Profil bearbeiten';

  @override
  String get profileEditRefreshTooltip => 'Profil aktualisieren';

  @override
  String get profileEditAboutYou => 'Über dich';

  @override
  String get profileEditEditAbout => 'Über mich bearbeiten';

  @override
  String get profileEditName => 'Name';

  @override
  String get profileEditPhone => 'Telefon';

  @override
  String get profileEditDateOfBirth => 'Geburtsdatum';

  @override
  String get profileEditGender => 'Geschlecht';

  @override
  String get profileEditHeight => 'Größe';

  @override
  String get profileEditIncomeRange => 'Einkommensspanne';

  @override
  String get profileEditLocationSocial => 'Ort & Social Media';

  @override
  String get profileEditEditPreferences => 'Präferenzen bearbeiten';

  @override
  String get profileEditState => 'Bundesland';

  @override
  String get profileEditInstagram => 'Instagram';

  @override
  String get profileEditDatingPreferences => 'Dating-Präferenzen';

  @override
  String get profileEditSeeking => 'Sucht';

  @override
  String get profileEditAgeRange => 'Altersbereich';

  @override
  String profileEditAgeRangeValue(int min, int max) {
    return '$min–$max';
  }

  @override
  String get profileEditMaxDistance => 'Max. Entfernung';

  @override
  String get profileEditEducationFilter => 'Ausbildungsfilter';

  @override
  String get profileEditSeriousOnly => 'Nur Ernstes';

  @override
  String get profileEditVerifiedOnly => 'Nur verifiziert';

  @override
  String get profileEditHookupOnly => 'Nur Lockeres';

  @override
  String get profileEditYes => 'Ja';

  @override
  String get profileEditNo => 'Nein';

  @override
  String get profileEditIntent => 'Absicht';

  @override
  String get profileEditLanguages => 'Sprachen';

  @override
  String get profileEditDealBreakers => 'No-Gos';

  @override
  String get profileEditReligion => 'Religion';

  @override
  String get profileEditPets => 'Haustiere';

  @override
  String get profileEditWorkout => 'Training';

  @override
  String get profileEditPoliticsComfort => 'Politische Toleranz';

  @override
  String get profileEditInterestsDetails => 'Interessen & Details';

  @override
  String get profileEditHobbies => 'Hobbys';

  @override
  String get profileEditBooks => 'Bücher';

  @override
  String get profileEditNovels => 'Romane';

  @override
  String get profileEditSongs => 'Songs';

  @override
  String get profileEditExtraCurriculars => 'Freizeitaktivitäten';

  @override
  String get profileEditAdditionalInfo => 'Weitere Infos';

  @override
  String get profileEditNotSet => 'Nicht angegeben';

  @override
  String get profileEditLoadingTitle =>
      'Dein gespeichertes Profil wird geladen';

  @override
  String get profileEditLoadingBody =>
      'Die bei der Kontoeinrichtung gespeicherten Angaben werden übernommen.';

  @override
  String get profileEditYourProfile => 'Dein Profil';

  @override
  String profileEditPercentComplete(int percent) {
    return '$percent % vollständig';
  }

  @override
  String get profileEditPhotoGallery => 'Fotogalerie';

  @override
  String get profileEditManagePhotos => 'Fotos verwalten';

  @override
  String get profileEditNoPhotos => 'Noch keine Fotos hochgeladen.';

  @override
  String get profileEditPrimaryBadge => 'Hauptfoto';

  @override
  String get engagementHubPromptLoading => 'Heutiger Impuls wird geladen';

  @override
  String get engagementHubPromptIntro =>
      'Beantworte jeden Tag einen Impuls und bau deine Serie aus.';

  @override
  String engagementHubPromptRepliedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen haben heute geantwortet',
      one: '1 Person hat heute geantwortet',
    );
    return '$_temp0';
  }

  @override
  String engagementHubPromptStreakSummary(int days, int similar) {
    return 'Serie $days T. · ähnliche Antworten: $similar';
  }

  @override
  String get engagementHubBlogTitle => 'Blog · Open Chapters';

  @override
  String get engagementHubBlogSubtitle =>
      'Lies Geschichten, teile Fotos und schreib deine eigene.';

  @override
  String get engagementHubPhotoThemesTitle => 'Fotothemen';

  @override
  String get engagementHubPhotoThemesSubtitle =>
      'Teile ein Foto pro Thema und sieh dir die der anderen an.';

  @override
  String get engagementHubClubsTitle => 'Buch- & Filmclubs';

  @override
  String get engagementHubClubsSubtitle =>
      'Folge dem Tipp der Woche, sprich darüber, bewerte ihn.';

  @override
  String get engagementHubCityPilotTitle => 'Der Stadt-Pilot';

  @override
  String get engagementHubCityPilotSubtitle =>
      'Eine kleine Community. Gespräche, aus denen Pläne werden.';

  @override
  String get engagementDailyPromptTitle => 'Tägliche Impuls-Serie';

  @override
  String get engagementHubVoiceTitle => 'Geführte Sprach-Eisbrecher';

  @override
  String get engagementHubVoiceSubtitle =>
      'Ein geführtes Sprach-Intro (20–45 s) pro Match und Tag';

  @override
  String get engagementCirclesTitle => 'Lokale Kreis-Challenges';

  @override
  String get engagementHubCirclesSubtitle =>
      'Tritt einem Kreis in deiner Stadt bei und reiche deinen Beitrag der Woche ein';

  @override
  String get engagementHubCoffeeTitle => 'Kaffee-Umfrage für Gruppen';

  @override
  String get engagementHubCoffeeSubtitle =>
      'Einfache Treffen-Umfragen erstellen, abstimmen und festlegen';

  @override
  String get engagementHubGroupsTitle => 'Gruppen';

  @override
  String get engagementHubGroupsSubtitle =>
      'Lifestyle-Communitys und private Freundesgruppen';

  @override
  String get engagementHubRoomsSubtitle =>
      'Live-Chaträume: reinschauen, reden, Freunde finden';

  @override
  String get engagementHubFriendsTitle => 'Freunde & Vorstellungen';

  @override
  String get engagementHubFriendsSubtitle =>
      'Lade eine vertraute Person ein, auch wenn sie nicht datet';

  @override
  String get engagementLevelTitle => 'Level & XP';

  @override
  String get engagementHubLevelSubtitle =>
      'Behalte sinnvolle Aktivität, Level-Belohnungen und Vertrauensstufen im Blick';

  @override
  String get engagementHubPaywallFree =>
      'Der Kern-Fortschritt bleibt ohne Bezahlschranke.';

  @override
  String get engagementHubPolicyUpdating =>
      'Die Monetarisierungsrichtlinie wird aktualisiert.';

  @override
  String engagementHubPremiumAreas(String features) {
    return 'Optionale Premium-Bereiche: $features';
  }

  @override
  String get engagementHubEyebrow => 'MITMACHEN';

  @override
  String get engagementHubTitle => 'Gemeinsam etwas schaffen.';

  @override
  String get engagementHubSubtitle =>
      'Stärkere Matches durch Vertrauen und gemeinsame Aktivitäten.';

  @override
  String get engagementHubSectionCreate => 'ERSTELLEN & TEILEN';

  @override
  String get engagementHubSectionCreateCaption =>
      'Geschichten, Fotos und Clubs, die echte Gespräche anstoßen.';

  @override
  String get engagementHubSectionMeet => 'LEUTE KENNENLERNEN';

  @override
  String get engagementHubSectionMeetCaption =>
      'Kleine Gruppen, Impulse und Pläne in deinem Tempo.';

  @override
  String get engagementHubSectionProgress => 'VERTRAUEN & FORTSCHRITT';

  @override
  String get engagementHubSectionProgressCaption =>
      'Dein Level, deine Abzeichen und wer dich finden kann.';

  @override
  String get engagementVoiceAppBarTitle => 'Eine Stimme, ein bisschen näher';

  @override
  String get engagementVoiceHeadline => 'Lass dein Hallo\nnach dir klingen.';

  @override
  String get engagementVoiceIntro =>
      'Eine freiwillige Vorstellung von 20–45 Sekunden, die nur in diesem Gespräch geteilt wird. Text ist natürlich auch immer willkommen.';

  @override
  String engagementVoiceYouAndName(String name) {
    return 'Du und $name';
  }

  @override
  String get engagementVoiceYouAndYourMatch => 'Du und dein Match';

  @override
  String get engagementVoicePrivate => 'Nur in diesem Gespräch sichtbar';

  @override
  String get engagementVoiceConversationsLoadFailed =>
      'Deine Gespräche konnten nicht geladen werden.';

  @override
  String get engagementVoiceNoMatches =>
      'Sobald du ein Match hast, kannst du hier eine Sprachvorstellung teilen. Ganz ohne Eile.';

  @override
  String get engagementVoicePickConversation => 'Wem möchtest du Hallo sagen?';

  @override
  String get engagementVoiceStartingPoint => 'Ein kleiner Einstieg';

  @override
  String get engagementVoiceChoosePrompt => 'Wähle einen Impuls';

  @override
  String get engagementVoiceTranscriptLabel => 'Deine Worte, schriftlich';

  @override
  String get engagementVoiceTranscriptHelper =>
      'Schreib auf, was du sagst, damit man es auch lesen kann. Das ist keine automatische Transkription.';

  @override
  String engagementVoiceStop(int seconds) {
    return 'Stopp · $seconds s';
  }

  @override
  String get engagementVoiceRecord => 'Hallo aufnehmen';

  @override
  String engagementVoiceRecordAgain(int seconds) {
    return 'Neu aufnehmen · $seconds s';
  }

  @override
  String get engagementVoiceRecordingReady =>
      'Aufnahme fertig. Prüf deinen Text vor dem Senden.';

  @override
  String get engagementVoiceRecordingShort =>
      'Das war etwas kurz. Nimm 20–45 Sekunden auf.';

  @override
  String get engagementVoiceDiscard => 'Aufnahme verwerfen';

  @override
  String get engagementVoiceSubmitted =>
      'Vorstellung gesendet. Freigegebene Aufnahmen erscheinen unten.';

  @override
  String get engagementVoiceSending => 'Wird gesendet…';

  @override
  String get engagementVoiceShare => 'Hallo teilen';

  @override
  String get engagementVoiceCheckedNote =>
      'Aufnahmen werden vor dem Teilen geprüft. Es gibt keine automatische Wiedergabe.';

  @override
  String get engagementVoiceYourIntros => 'Eure Sprachvorstellungen';

  @override
  String get engagementVoiceLatestNote =>
      'Die letzten 20 freigegebenen Aufnahmen in diesem Gespräch. Die Texte kannst du jederzeit lesen.';

  @override
  String get engagementVoiceIntrosLoadFailed =>
      'Die Vorstellungen konnten nicht geladen werden. Das Gespräch ist eventuell nicht mehr verfügbar.';

  @override
  String get engagementVoiceNothingYet =>
      'Noch nichts geteilt. Ein einfaches Hallo ist ein guter Anfang.';

  @override
  String get engagementVoiceYourHello => 'Dein Hallo';

  @override
  String engagementVoiceHelloFromName(String name) {
    return 'Ein Hallo von $name';
  }

  @override
  String get engagementVoiceHelloFromYourMatch => 'Ein Hallo von deinem Match';

  @override
  String get engagementVoiceTranscriptHeading => 'TEXT';

  @override
  String get engagementVoiceStopPlayback => 'Wiedergabe stoppen';

  @override
  String engagementVoiceListen(int seconds) {
    return 'Anhören · $seconds s';
  }

  @override
  String get engagementVoiceReloadPrompts => 'Impulse neu laden';

  @override
  String get engagementVoiceMicPermission =>
      'Erlaube den Mikrofonzugriff, um aufzunehmen. Die Texte kannst du auch ohne lesen.';

  @override
  String get engagementVoiceStartFailed =>
      'Aufnahme konnte nicht gestartet werden. Prüf den Mikrofonzugriff und versuch es noch einmal.';

  @override
  String get engagementVoiceSaveFailed =>
      'Die Aufnahme konnte nicht gespeichert werden. Bitte versuch es noch einmal.';

  @override
  String get engagementVoicePromptsLoadFailed =>
      'Die Sprach-Impulse können gerade nicht geladen werden.';

  @override
  String get engagementSessionUnavailable => 'Keine aktive Sitzung.';

  @override
  String get engagementVoiceChooseConversation => 'Wähle zuerst ein Gespräch.';

  @override
  String get engagementVoiceSelectPrompt => 'Bitte wähle einen Sprach-Impuls.';

  @override
  String get engagementVoiceEnterTranscript => 'Bitte gib den Text ein.';

  @override
  String get engagementVoiceSessionFailed =>
      'Die Sprach-Eisbrecher-Sitzung konnte nicht erstellt werden.';

  @override
  String get engagementVoiceSendFailed =>
      'Der Sprach-Eisbrecher kann gerade nicht gesendet werden.';

  @override
  String get engagementVoicePlaybackUserRequired =>
      'Zum Erfassen der Wiedergabe ist eine Nutzer-ID nötig.';

  @override
  String get engagementVoiceMarkPlaybackFailed =>
      'Die Wiedergabe kann gerade nicht erfasst werden.';

  @override
  String get engagementVoicePlayFailed =>
      'Diese Aufnahme kann gerade nicht abgespielt werden.';

  @override
  String get chatStarterSmile => 'Was hat dich heute zum Lächeln gebracht?';

  @override
  String get chatStarterSunday => 'Dein perfekter Sonntag: erzähl.';

  @override
  String get chatStarterCoffee =>
      'Kaffee, ein Spaziergang oder ein kleines Abenteuer?';

  @override
  String get chatWelcomeTitle =>
      'Jede gute Geschichte\nbeginnt mit einem Hallo.';

  @override
  String get chatWelcomePending =>
      'Eure Unterhaltung startet, sobald das Match bestätigt ist.';

  @override
  String get chatWelcomeBody =>
      'Du brauchst keinen perfekten ersten Satz. Sei einfach du.';

  @override
  String get chatInspirationEyebrow => 'EIN BISSCHEN INSPIRATION';

  @override
  String get chatAllConversations => 'Alle Unterhaltungen';

  @override
  String get chatMakeConnectionEyebrow => 'VERBINDUNG SCHAFFEN';

  @override
  String get chatLessSmallTalk => 'Ein bisschen weniger Smalltalk.';

  @override
  String get chatLessSmallTalkBody =>
      'Frag nach den Dingen, für die die andere Person brennt. Erzähl etwas, das zu dir passt.';

  @override
  String get chatFindTheWords => 'Die richtigen Worte finden';

  @override
  String get chatSendJoy => 'Ein bisschen Freude senden';

  @override
  String get chatPaceTitle => 'Dein Tempo. Dein Raum.';

  @override
  String get chatPaceBody =>
      'Teil nur, was sich gut anfühlt. Eine gute Verbindung respektiert deine Grenzen.';

  @override
  String get chatWriteMessageHint => 'Schreib eine Nachricht …';

  @override
  String get chatConversationPaused => 'Unterhaltung pausiert';

  @override
  String get chatSendingMessageTooltip => 'Nachricht wird gesendet';

  @override
  String get chatSendMessageTooltip => 'Nachricht senden';

  @override
  String get chatSendGiftTooltip => 'Geschenk senden';

  @override
  String get chatAddEmojiTooltip => 'Emoji hinzufügen';

  @override
  String get chatDraftedWithHelp => 'Mit Hilfe formuliert';

  @override
  String get chatHelpMeSayIt => 'Hilf mir, es zu sagen';

  @override
  String get chatEnterToSendHint =>
      'Enter zum Senden · Umschalt + Enter für neue Zeile';

  @override
  String get chatToday => 'Heute';

  @override
  String get chatYesterday => 'Gestern';

  @override
  String get chatGiftOptions => 'Geschenkoptionen';

  @override
  String get chatStatusRead => 'Gelesen';

  @override
  String get chatStatusDelivered => 'Zugestellt';

  @override
  String get chatStatusSent => 'Gesendet';

  @override
  String get chatGestureGiftHeading => 'Geste + Rosengeschenk';

  @override
  String get chatGiftForYouHeading => 'Eine kleine Aufmerksamkeit für dich';

  @override
  String chatGiftTone(String tone) {
    return 'Ton: $tone';
  }

  @override
  String get chatFreeGift => 'Gratis-Geschenk';

  @override
  String get chatCopilotKindOpener => 'Einstieg';

  @override
  String get chatCopilotKindReply => 'Antwort';

  @override
  String get chatCopilotKindDateIdea => 'Date-Idee';

  @override
  String get chatCopilotToneWarm => 'Herzlich';

  @override
  String get chatCopilotTonePlayful => 'Verspielt';

  @override
  String get chatCopilotToneDirect => 'Direkt';

  @override
  String chatCopilotIntro(String name) {
    return 'Ein Entwurf in deinem Ton, basierend auf dem Profil von $name und eurer Unterhaltung. Er wird nie für dich gesendet, und wenn du ihn unverändert schickst, sieht die andere Person, dass er mit Hilfe geschrieben wurde.';
  }

  @override
  String chatCopilotDisclosure(String disclosure, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Heute noch $count Entwürfe.',
      one: 'Heute noch 1 Entwurf.',
    );
    return '$disclosure $_temp0';
  }

  @override
  String get chatCopilotDraftIt => 'Entwurf erstellen';

  @override
  String get chatCopilotTryAnother => 'Anderen Entwurf';

  @override
  String get chatCopilotUseAndEdit => 'Übernehmen und bearbeiten';

  @override
  String get chatCopilotEmpty => 'Der Copilot hat nichts geliefert.';

  @override
  String get chatCopilotUnavailable => 'Der Copilot ist nicht verfügbar.';

  @override
  String get chatErrorMatchEnded => 'Dieses Match ist beendet.';

  @override
  String get chatErrorLoadMessages =>
      'Nachrichten konnten nicht geladen werden. Bitte versuche es erneut.';

  @override
  String get chatErrorLockedQuest =>
      'Der Chat ist gesperrt, bis die Aufgabe bestätigt ist.';

  @override
  String get chatErrorSendFailed => 'Nachricht konnte nicht gesendet werden.';

  @override
  String get chatErrorDeleteFailed => 'Nachricht konnte nicht gelöscht werden.';

  @override
  String get chatErrorDeleteWindowExpired => 'Löschfrist abgelaufen (24 Std.).';

  @override
  String get chatErrorOnlyReceivedGifts =>
      'Nur erhaltene Geschenke können verwaltet werden.';

  @override
  String get chatErrorGiftGone => 'Dieses Geschenk ist nicht mehr verfügbar.';

  @override
  String get chatErrorGiftReportFailed =>
      'Das Geschenk konnte nicht gemeldet werden. Bitte versuche es erneut.';

  @override
  String get chatErrorGiftHideFailed =>
      'Das Geschenk konnte nicht ausgeblendet werden. Bitte versuche es erneut.';

  @override
  String get chatErrorGiftsUnavailable =>
      'Rosengeschenke sind gerade nicht verfügbar.';

  @override
  String chatErrorNotEnoughCoins(String gift) {
    return 'Nicht genug Coins für $gift.';
  }

  @override
  String get chatErrorNotEnoughCoinsSelected =>
      'Nicht genug Coins für das ausgewählte Geschenk.';

  @override
  String get chatErrorWalletFrozen =>
      'Deine Coins sind gesperrt, während wir einen erstatteten Kauf prüfen. Gratis-Geschenke kannst du weiterhin senden.';

  @override
  String get chatErrorGiftVelocity =>
      'Du hast in kurzer Zeit viele Geschenke gesendet. Bitte versuch es später noch einmal.';

  @override
  String get chatErrorFreeGiftUsed =>
      'Du hast dein Gratis-Geschenk für heute schon gesendet. Nach Mitternacht (UTC) gibt es ein neues.';

  @override
  String chatErrorGiftNotAvailable(String gift) {
    return '$gift ist gerade nicht verfügbar.';
  }

  @override
  String get chatErrorGiftNeedsActiveMatch =>
      'Geschenke kannst du nur in einem aktiven Match senden.';

  @override
  String get chatErrorExclusiveGiftOnce =>
      'Dieses exklusive Geschenk kannst du heute nur einmal senden.';

  @override
  String get chatErrorGiftFailed => 'Geschenk konnte nicht gesendet werden.';

  @override
  String get chatErrorSessionUnavailable => 'Sitzung nicht verfügbar.';

  @override
  String get chatErrorConversationUnavailable =>
      'Unterhaltung nicht verfügbar.';

  @override
  String get verificationLandingTitle => 'Sicher verifizieren';

  @override
  String get verificationLandingBody =>
      'Lade ein gut lesbares amtliches Ausweisdokument und ein aktuelles Selfie hoch. Die Dateien werden verschlüsselt übertragen und in einem privaten Nachweisbereich gespeichert.';

  @override
  String get verificationLandingDisclaimer =>
      'Eine Prüfung ergänzt dein Profil um Kontext. Sie garantiert nie die Identität, Absichten oder Sicherheit einer anderen Person.';

  @override
  String get verificationViewVerifiedStatus => 'Verifizierungsstatus ansehen';

  @override
  String get verificationViewReviewStatus => 'Prüfstatus ansehen';

  @override
  String get verificationStartButton => 'Sichere Verifizierung starten';

  @override
  String get verificationUploadIdTitle => 'Ausweis hochladen';

  @override
  String get verificationUploadIdInstruction =>
      'Mach ein gut lesbares Foto deines amtlichen Ausweises oder lade eines hoch.';

  @override
  String get verificationGallery => 'Galerie';

  @override
  String get verificationCamera => 'Kamera';

  @override
  String get verificationNext => 'Weiter';

  @override
  String get verificationSelfieTitle => 'Selfie';

  @override
  String get verificationSelfieInstruction =>
      'Mach ein gut erkennbares Selfie.';

  @override
  String get verificationUploadFailed =>
      'Deine Nachweise konnten nicht hochgeladen werden. Prüfe die Dateien und versuch es noch einmal.';

  @override
  String get verificationSubmit => 'Absenden';

  @override
  String get verificationStatusTitle => 'Verifizierungsstatus';

  @override
  String get verificationRetry => 'Erneut versuchen';

  @override
  String get verificationStatusVerified => 'Verifiziert';

  @override
  String get verificationStatusVerifiedMessage =>
      'Deine Verifizierung ist abgeschlossen.';

  @override
  String get verificationStatusRejected => 'Abgelehnt';

  @override
  String get verificationStatusRejectedFallback =>
      'Bitte versuch es noch einmal.';

  @override
  String get verificationStatusPending => 'In Prüfung';

  @override
  String get verificationStatusPendingMessage => 'Die Prüfung läuft.';

  @override
  String get verificationStatusNotStarted => 'Nicht gestartet';

  @override
  String get verificationStatusNotStartedMessage =>
      'Starte die Verifizierung in den Einstellungen.';

  @override
  String get safetySosTitle => 'Notfall-SOS';

  @override
  String get safetySosDefaultMessage =>
      'Ich brauche sofort Hilfe. Bitte meldet euch bei mir.';

  @override
  String get safetySosHeadline => 'Notfallalarm auslösen';

  @override
  String get safetySosIntro =>
      'Wenn du in unmittelbarer Gefahr bist, wende dich zuerst an den örtlichen Notruf. Dieser Alarm wird für das Sicherheitsteam erfasst.';

  @override
  String get safetySosLevelUrgent => 'Dringend';

  @override
  String get safetySosLevelCritical => 'Kritisch';

  @override
  String get safetySosMessageLabel => 'Nachricht an das Sicherheitsteam';

  @override
  String get safetySosActivating => 'Wird ausgelöst…';

  @override
  String get safetySosActivate => 'SOS auslösen';

  @override
  String get safetySosLocationNote =>
      'Dein Standort wird nur für diesen Alarm abgefragt. Du kannst auch ohne Berechtigung fortfahren.';

  @override
  String get safetySosHistoryTitle => 'Alarmverlauf';

  @override
  String get safetySosHistoryEmpty => 'Keine SOS-Alarme erfasst.';

  @override
  String safetySosHistoryHeading(String level, String status) {
    return '$level · $status';
  }

  @override
  String get safetySosAlertLevelLow => 'NIEDRIG';

  @override
  String get safetySosAlertLevelMedium => 'MITTEL';

  @override
  String get safetySosAlertLevelHigh => 'HOCH';

  @override
  String get safetySosAlertLevelCritical => 'KRITISCH';

  @override
  String get safetySosAlertStatusOpen => 'offen';

  @override
  String get safetySosAlertStatusActive => 'aktiv';

  @override
  String get safetySosAlertStatusAcknowledged => 'bestätigt';

  @override
  String get safetySosAlertStatusResolved => 'gelöst';

  @override
  String safetySosHistoryMetaWithLocation(String date) {
    return '$date · mit Standort';
  }

  @override
  String safetySosHistoryMetaNoLocation(String date) {
    return '$date · ohne Standort';
  }

  @override
  String safetySosResolution(String note) {
    return 'Lösung: $note';
  }

  @override
  String get safetySosConfirmTitle => 'SOS jetzt auslösen?';

  @override
  String get safetySosConfirmBody =>
      'Dadurch wird ein Notfallalarm für das Sicherheitsteam erstellt und versucht, deinen aktuellen Standort anzuhängen.';

  @override
  String get safetySosCancel => 'Abbrechen';

  @override
  String get safetySosConfirmActivate => 'Auslösen';

  @override
  String get safetySosActivatedTitle => 'SOS-Alarm ausgelöst';

  @override
  String get safetySosActivatedWithLocation =>
      'Dein Alarm und dein aktueller Standort wurden erfasst.';

  @override
  String get safetySosActivatedWithoutLocation =>
      'Dein Alarm wurde ohne Standort erfasst. Die Standortberechtigung war nicht verfügbar oder wurde abgelehnt.';

  @override
  String get safetySosDone => 'Fertig';

  @override
  String get safetySosSignInToView =>
      'Bitte melde dich an, um deinen SOS-Verlauf zu sehen.';

  @override
  String get safetySosLoadFailed => 'SOS-Verlauf konnte nicht geladen werden.';

  @override
  String get safetySosSignInToActivate =>
      'Bitte melde dich an, bevor du SOS auslöst.';

  @override
  String get safetySosActivateFailed => 'SOS konnte nicht ausgelöst werden.';

  @override
  String get photoThemesTitle => 'Fotothemen';

  @override
  String get photoThemesSignIn => 'Melde dich an, um die Fotothemen zu sehen.';

  @override
  String get photoThemesHeroTitle => 'Zeig ein bisschen von deiner Welt';

  @override
  String get photoThemesHeroSubtitle =>
      'Wähle ein Thema, teile ein Foto und sieh dir an, was die anderen geteilt haben. So kommt ihr ganz leicht ins Gespräch.';

  @override
  String get photoThemesLoadFailed => 'Themen konnten nicht geladen werden';

  @override
  String get photoThemesCheckConnection => 'Bitte prüfe deine Verbindung.';

  @override
  String get photoThemesLookAround => 'Du kannst dich umsehen';

  @override
  String get photoThemesEligibilityShareOwn =>
      'Vervollständige dein Profil mit zwei freigegebenen Fotos, um selbst etwas zu teilen.';

  @override
  String get photoThemesNewPromptsTitle => 'Neue Themen sind unterwegs';

  @override
  String get photoThemesNewPromptsBody =>
      'Schau bald wieder vorbei, um etwas zu teilen.';

  @override
  String photoThemesSharedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count geteilt',
      one: '$count geteilt',
    );
    return '$_temp0';
  }

  @override
  String get photoThemesYouShared => 'Du hast geteilt ✓';

  @override
  String get photoThemesBeFirst => 'Mach den Anfang und teile →';

  @override
  String get photoThemesSeeEveryone => 'Alle Fotos ansehen →';

  @override
  String get photoThemesSharedSnack => 'Dein Foto ist geteilt. Stark!';

  @override
  String get photoThemesShareFailed =>
      'Dein Foto konnte nicht geteilt werden. Nutze ein JPEG oder PNG bis 10 MB.';

  @override
  String get photoThemesEligibilityShare =>
      'Vervollständige dein Profil mit zwei freigegebenen Fotos, um zu teilen.';

  @override
  String get photoThemesAlreadyShared =>
      'Du hast zu diesem Thema schon etwas geteilt. Entferne dein Foto, um ein neues zu teilen.';

  @override
  String get photoThemesThemeFallback => 'Fotothema';

  @override
  String get photoThemesShareTooltip => 'Ein Foto zu diesem Thema teilen';

  @override
  String get photoThemesShareYourPhoto => 'Dein Foto teilen';

  @override
  String get photoThemesNoPhotosYet => 'Noch keine Fotos';

  @override
  String photoThemesBeFirstFor(String title) {
    return 'Mach den Anfang bei „$title“';
  }

  @override
  String get photoThemesLoadingPrompt => 'Thema wird geladen …';

  @override
  String get photoThemesPhotosLoadFailed =>
      'Fotos konnten nicht geladen werden';

  @override
  String get photoThemesEmptyMessage =>
      'Vielleicht bringt gerade dein Foto alle ins Gespräch.';

  @override
  String get photoThemesMoreFailed =>
      'Weitere Fotos konnten nicht geladen werden. Neu laden';

  @override
  String get photoThemesLoadMore => 'Mehr laden';

  @override
  String get photoThemesPhotoUnavailable =>
      'Foto nicht verfügbar. Erneut versuchen';

  @override
  String photoThemesOpenPhoto(String name) {
    return 'Foto von $name öffnen';
  }

  @override
  String get photoThemesYou => 'Du';

  @override
  String get photoThemesWallHelp =>
      'Wenn dein Foto gut ankommt, kann es auf den Today-Walls anderer landen: 50 Likes und 5 Kommentare bringen es auf 50 Walls, 100 Likes und 10 Kommentare auf 100. Du kannst das jederzeit ausschalten.';

  @override
  String get photoThemesRemoveTitle => 'Dein Foto entfernen?';

  @override
  String get photoThemesRemoveMessage =>
      'Es verschwindet für alle aus diesem Thema. Danach kannst du ein neues teilen.';

  @override
  String get photoThemesRemoveAction => 'Foto entfernen';

  @override
  String get photoThemesRemoveFailed =>
      'Dein Foto konnte nicht entfernt werden.';

  @override
  String get photoThemesReachOn =>
      'Dein Foto kann jetzt auf den Walls anderer landen, wenn es gut ankommt.';

  @override
  String get photoThemesReachOff => 'Dein Foto ist von allen Walls entfernt.';

  @override
  String get photoThemesSharedByYou => 'Von dir geteilt';

  @override
  String photoThemesSharedBy(String name) {
    return 'Geteilt von $name';
  }

  @override
  String photoThemesPhotoDescription(String text) {
    return 'Fotobeschreibung: $text';
  }

  @override
  String get photoThemesReachSwitch =>
      'Auf den Walls anderer erscheinen lassen';

  @override
  String get photoThemesReachIdle => 'Andere können dieses Foto weitertragen';

  @override
  String get photoThemesReachLive =>
      'Andere sehen es gerade auf ihren Today-Walls.';

  @override
  String get photoThemesRemoveMine => 'Mein Foto entfernen';

  @override
  String get photoThemesReport => 'Melden';

  @override
  String photoThemesBlock(String name) {
    return '$name blockieren';
  }

  @override
  String get photoThemesCommentHint => 'Woran erinnert es dich?';

  @override
  String get photoThemesCommentApproved =>
      'Freigegeben. Alle, die dieses Foto sehen können, sehen ihn jetzt.';

  @override
  String get photoThemesDetailsTitle => 'Erzähl uns davon';

  @override
  String get photoThemesCaption => 'Bildunterschrift';

  @override
  String get photoThemesCaptionHint =>
      'Pfannkuchen, und dann nirgendwohin müssen.';

  @override
  String get photoThemesDescribe => 'Beschreibe das Foto';

  @override
  String get photoThemesDescribeHelper =>
      'Hilft Mitgliedern, die einen Screenreader nutzen.';

  @override
  String get photoThemesShare => 'Teilen';

  @override
  String get photoThemesWallTitle => 'Cover auf deiner Wall';

  @override
  String get photoThemesWallCaption => 'Fotos, die anderen gefallen haben';

  @override
  String get photoThemesMasthead => 'FOTOTHEMEN';

  @override
  String photoThemesByline(String name) {
    return 'VON $name';
  }

  @override
  String get photoThemesLikes => 'Likes';

  @override
  String get photoThemesComments => 'Kommentare';

  @override
  String get photoThemesCancel => 'Abbrechen';

  @override
  String get photoThemesTryAgain => 'Erneut versuchen';

  @override
  String get photoThemesSaveFailed =>
      'Das wurde nicht gespeichert. Bitte versuch es noch einmal.';

  @override
  String get friendsChatEmpty =>
      'Sag Hallo. Nur ihr beide könnt diese Unterhaltung sehen.';

  @override
  String get friendsChatOpenFailed =>
      'Der Chat konnte nicht geöffnet werden. Versuch es noch einmal.';

  @override
  String get friendsCancelRequestTitle => 'Freundschaftsanfrage zurückziehen?';

  @override
  String friendsCancelRequestBody(String name) {
    return '$name sieht deine Anfrage dann nicht mehr.';
  }

  @override
  String get friendsCancelRequestBodyUnnamed =>
      'Dieses Mitglied sieht deine Anfrage dann nicht mehr.';

  @override
  String get friendsKeepIt => 'Behalten';

  @override
  String get friendsCancelRequest => 'Anfrage zurückziehen';

  @override
  String friendsNowFriends(String name) {
    return 'Du und $name seid jetzt befreundet.';
  }

  @override
  String get friendsNowFriendsUnnamed =>
      'Du und dieses Mitglied seid jetzt befreundet.';

  @override
  String friendsRequestSentTo(String name) {
    return 'Freundschaftsanfrage an $name gesendet.';
  }

  @override
  String get friendsRequestSentToUnnamed =>
      'Freundschaftsanfrage an dieses Mitglied gesendet.';

  @override
  String get friendsRequestCancelled => 'Anfrage zurückgezogen.';

  @override
  String get friendsRequestFailed =>
      'Die Anfrage konnte nicht gesendet werden.';

  @override
  String get friendsAddCaption =>
      'Freunde können sich schreiben und gemeinsam Dinge planen';

  @override
  String get friendsRequested => 'Angefragt';

  @override
  String friendsWaitingFor(String name) {
    return 'Warten auf $name. Zum Zurückziehen tippen.';
  }

  @override
  String get friendsWaitingForUnnamed =>
      'Warten auf dieses Mitglied. Zum Zurückziehen tippen.';

  @override
  String get friendsAcceptFriend => 'Freundschaft annehmen';

  @override
  String friendsAskedToBeFriends(String name) {
    return '$name möchte befreundet sein';
  }

  @override
  String get friendsAskedToBeFriendsUnnamed =>
      'Dieses Mitglied möchte befreundet sein';

  @override
  String get friendsMessage => 'Schreiben';

  @override
  String get friendsYoureFriends => 'Ihr seid befreundet. Öffne euren Chat.';

  @override
  String friendsVouchTooShort(int min) {
    return 'Schreib noch etwas mehr (mindestens $min Zeichen).';
  }

  @override
  String friendsVouchTitle(String name) {
    return 'Für $name verbürgen';
  }

  @override
  String get friendsVouchBody =>
      'Ein, zwei Sätze darüber, warum man sich glücklich schätzen kann, diese Person kennenzulernen. Sie gibt es frei, bevor es mit deinem Vornamen in ihrem Profil erscheint.';

  @override
  String get friendsVouchLabel => 'Deine Empfehlung';

  @override
  String get friendsVouchHint => 'Herzlich, witzig und immer pünktlich.';

  @override
  String get friendsVouchSend => 'Empfehlung senden';

  @override
  String get friendsIntroChooseTwo => 'Wähle zwei verschiedene Freunde.';

  @override
  String get friendsIntroSheetTitle => 'Zwei Freunde einander vorstellen';

  @override
  String get friendsIntroSheetBody =>
      'Beide Freunde müssen Vorstellungen erlauben. Jeder bestimmt die eigene Vorschau und entscheidet privat. Nenne nur einen Grund, den du erwähnen darfst. Ihre Entscheidungen und ob es ein Match wird, bleiben privat.';

  @override
  String get friendsIntroNeedTwo =>
      'Du brauchst mindestens zwei Freunde, um jemanden vorzustellen.';

  @override
  String get friendsFirstFriend => 'Erster Freund';

  @override
  String get friendsSecondFriend => 'Zweiter Freund';

  @override
  String get friendsIntroWhyLabel =>
      'Warum sie sich kennenlernen sollten (optional)';

  @override
  String get friendsIntroSubmit => 'Vorstellung machen';

  @override
  String get friendsLoadFailed =>
      'Freunde konnten nicht geladen werden. Bitte versuch es noch einmal.';

  @override
  String get friendsAddFailed => 'Freund konnte nicht hinzugefügt werden.';

  @override
  String get friendsRemoveFailed => 'Freund konnte nicht entfernt werden.';

  @override
  String get friendsRespondFailed =>
      'Auf die Freundschaftsanfrage konnte nicht geantwortet werden.';

  @override
  String get friendsSocialLoadFailed =>
      'Empfehlungen und Vorstellungen konnten nicht geladen werden.';

  @override
  String get friendsVouchSendFailed =>
      'Diese Empfehlung konnte nicht gesendet werden.';

  @override
  String get friendsVouchUpdateFailed =>
      'Diese Empfehlung konnte nicht aktualisiert werden.';

  @override
  String get friendsVouchWithdrawFailed =>
      'Diese Empfehlung konnte nicht zurückgezogen werden.';

  @override
  String get friendsIntroMakeFailed =>
      'Diese Vorstellung konnte nicht gemacht werden.';

  @override
  String get friendsIntroAnswerFailed =>
      'Auf diese Vorstellung konnte nicht geantwortet werden.';

  @override
  String get groupsEyebrow => 'GRUPPEN';

  @override
  String get groupsTitle => 'Finde deine Leute.';

  @override
  String get groupsSubtitle =>
      'Lifestyle-Communitys, denen alle beitreten können, und private Gruppen nur für deine Freunde.';

  @override
  String get groupsStartGroup => 'Gruppe gründen';

  @override
  String get groupsInvitationsHeader => 'EINLADUNGEN';

  @override
  String get groupsInvitationsCaption => 'Freunde haben dich eingeladen.';

  @override
  String get groupsAnswerFailed =>
      'Deine Antwort konnte nicht gespeichert werden.';

  @override
  String groupsWelcome(String name) {
    return 'Willkommen bei $name!';
  }

  @override
  String get groupsInvitationDeclined => 'Einladung abgelehnt.';

  @override
  String get groupsYourGroupsHeader => 'DEINE GRUPPEN';

  @override
  String get groupsYourGroupsFailed =>
      'Deine Gruppen konnten nicht geladen werden';

  @override
  String get groupsErrorCheckConnection => 'Bitte prüfe deine Verbindung.';

  @override
  String get groupsEmptyTitle => 'Noch keine Gruppen';

  @override
  String get groupsEmptyBody =>
      'Tritt unten einer Community bei oder gründe eine private Gruppe mit deinen Freunden.';

  @override
  String get groupsDiscoverHeader => 'NACH LIFESTYLE ENTDECKEN';

  @override
  String get groupsDiscoverCaption => 'Community-Gruppen stehen allen offen.';

  @override
  String get groupsLifestylesFailed =>
      'Lifestyles konnten nicht geladen werden';

  @override
  String get groupsCategoryAll => 'Alle';

  @override
  String get groupsDiscoverFailed => 'Gruppen konnten nicht geladen werden';

  @override
  String get groupsDiscoverEmptyTitle => 'Nichts Neues zum Beitreten';

  @override
  String groupsDiscoverEmptyCategoryTitle(String category) {
    return 'Noch keine Gruppen für $category';
  }

  @override
  String get groupsDiscoverEmptyBody =>
      'Mach den Anfang: Gründe eine Community-Gruppe und lade deine Freunde ein.';

  @override
  String get groupsStartOne => 'Jetzt gründen';

  @override
  String get groupsJoinFailed => 'Beitreten hat gerade nicht geklappt.';

  @override
  String get groupsJoin => 'Beitreten';

  @override
  String groupsJoinNamed(String name) {
    return '$name beitreten';
  }

  @override
  String groupsInvitedBy(String name, String kind, String members) {
    return '$name hat dich eingeladen · $kind · $members';
  }

  @override
  String groupsInvitedByFriend(String kind, String members) {
    return 'Einladung von einem Freund · $kind · $members';
  }

  @override
  String get groupsDecline => 'Ablehnen';

  @override
  String groupsDeclineNamed(String name) {
    return '$name ablehnen';
  }

  @override
  String groupsChatEmpty(String name) {
    return 'Sag hallo zur Gruppe. Alle in $name sehen die Nachrichten hier.';
  }

  @override
  String groupsInviteFriendsTo(String name) {
    return 'Freunde zu $name einladen';
  }

  @override
  String get groupsSendInvitations => 'Einladungen senden';

  @override
  String get groupsInvitationsFailed =>
      'Die Einladungen konnten nicht gesendet werden.';

  @override
  String groupsInvitationSentTo(String name) {
    return 'Einladung an $name gesendet.';
  }

  @override
  String groupsInvitationsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einladungen gesendet.',
      one: '1 Einladung gesendet.',
    );
    return '$_temp0';
  }

  @override
  String groupsLeaveTitle(String name) {
    return '$name verlassen?';
  }

  @override
  String get groupsLeaveBodyAlone =>
      'Du bist das einzige Mitglied, deshalb werden die Gruppe und ihr Chat gelöscht.';

  @override
  String get groupsLeaveBodyOwner =>
      'Die Leitung geht an die Person aus der Moderation über, die am längsten dabei ist, sonst an das älteste Mitglied. Du verlierst den Zugriff auf den Chat.';

  @override
  String get groupsLeaveBodyCommunity =>
      'Du verlierst den Zugriff auf den Gruppenchat. Du kannst später wieder beitreten.';

  @override
  String get groupsLeaveBodyPrivate =>
      'Du verlierst den Zugriff auf den Gruppenchat. Um zurückzukommen, brauchst du eine neue Einladung.';

  @override
  String get groupsLeave => 'Verlassen';

  @override
  String get groupsLeaveFailed => 'Verlassen hat gerade nicht geklappt.';

  @override
  String get groupsCoverUploadFailed =>
      'Dein Titelbild konnte nicht hochgeladen werden. Nutze ein JPEG oder PNG bis 10 MB.';

  @override
  String get groupsRemoveCoverTitle => 'Titelbild entfernen?';

  @override
  String groupsRemoveCoverBody(String name) {
    return '$name zeigt dann wieder das Emoji-Titelbild.';
  }

  @override
  String get groupsRemove => 'Entfernen';

  @override
  String get groupsRemoveCoverFailed =>
      'Das Titelbild konnte nicht entfernt werden.';

  @override
  String get groupsCoverRemoved => 'Titelbild entfernt.';

  @override
  String groupsDeleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get groupsDeleteBody =>
      'Die Gruppe, ihre Einladungen und ihr Chat werden für alle entfernt. Das kann nicht rückgängig gemacht werden.';

  @override
  String get groupsDeleteGroup => 'Gruppe löschen';

  @override
  String get groupsDeleteFailed => 'Die Gruppe konnte nicht gelöscht werden.';

  @override
  String get groupsDetailEyebrow => 'GRUPPE';

  @override
  String get groupsDetailTitleFallback => 'Gruppe';

  @override
  String get groupsOwnerTools => 'Verwaltung';

  @override
  String get groupsEditGroup => 'Gruppe bearbeiten';

  @override
  String get groupsAddCoverPhoto => 'Titelbild hinzufügen';

  @override
  String get groupsChangeCoverPhoto => 'Titelbild ändern';

  @override
  String get groupsRemoveCoverPhoto => 'Titelbild entfernen';

  @override
  String get groupsMoreOptions => 'Weitere Optionen';

  @override
  String get groupsReportGroup => 'Gruppe melden';

  @override
  String get groupsUnavailableTitle => 'Diese Gruppe ist nicht verfügbar';

  @override
  String get groupsUnavailableBody =>
      'Sie wurde vielleicht gelöscht oder du hast keinen Zugriff mehr.';

  @override
  String get groupsOpenToAll => 'Offen für alle';

  @override
  String get groupsPrivate => 'Privat';

  @override
  String get groupsYouRunIt => 'Du leitest sie';

  @override
  String get groupsYouModerate => 'Du moderierst';

  @override
  String get groupsCoverNotePending =>
      'Bis zur Freigabe siehst nur du dieses Foto. Mitglieder sehen solange das Emoji-Titelbild.';

  @override
  String get groupsCoverNoteRejected =>
      'Dein letztes Titelbild wurde nicht freigegeben. Wähle ein anderes.';

  @override
  String get groupsCoverUnderReview => 'Wird geprüft';

  @override
  String get groupsChangeCover => 'Titelbild ändern';

  @override
  String get groupsRemoveCover => 'Titelbild entfernen';

  @override
  String get groupsRemovedTitle =>
      'Diese Gruppe wurde nach einer Prüfung entfernt';

  @override
  String get groupsRemovedBodyOwner =>
      'Mitglieder können nicht chatten, beitreten oder einladen, solange sie entfernt ist. Deine Prüfhinweise erklären die Entscheidung, dort kannst du auch Einspruch einlegen.';

  @override
  String get groupsRemovedBodyMember =>
      'Mitglieder können nicht chatten, beitreten oder einladen, solange sie entfernt ist. Du kannst die Gruppe jederzeit verlassen.';

  @override
  String get groupsMembers => 'Mitglieder';

  @override
  String get groupsChatButton => 'Gruppenchat';

  @override
  String groupsChatButtonUnread(int count) {
    return 'Gruppenchat · $count neu';
  }

  @override
  String get groupsInviteFriends => 'Freunde einladen';

  @override
  String get groupsWhosHere => 'WER DABEI IST';

  @override
  String get groupsSeeAll => 'Alle ansehen';

  @override
  String get groupsYou => 'Du';

  @override
  String groupsInvitedToJoin(String name) {
    return 'Du bist eingeladen, $name beizutreten.';
  }

  @override
  String get groupsJoinGroup => 'Gruppe beitreten';

  @override
  String get groupsJoinHint =>
      'Mitglieder sehen, wer dabei ist, und chatten miteinander.';

  @override
  String get groupsCantJoinTitle => 'Du kannst dieser Gruppe nicht beitreten';

  @override
  String get groupsCantJoinBody =>
      'Vielleicht ist sie voll oder du wurdest von der Moderation entfernt.';

  @override
  String get groupsInvitationOnly => 'Nur auf Einladung';

  @override
  String get groupsInvitationOnlyBody =>
      'Ein Mitglied kann dich in diese private Gruppe einladen.';

  @override
  String get groupsMakeModerator => 'Zum Moderator machen';

  @override
  String get groupsMakeMember => 'Zum Mitglied machen';

  @override
  String get groupsRemoveFromGroup => 'Aus der Gruppe entfernen';

  @override
  String groupsRemoveMemberTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String get groupsRemoveMemberBodyCommunity =>
      'Die Person verlässt die Gruppe und ihren Chat und kann nicht selbst wieder beitreten.';

  @override
  String get groupsRemoveMemberBodyPrivate =>
      'Die Person verlässt die Gruppe und ihren Chat.';

  @override
  String get groupsChangeFailed =>
      'Diese Änderung konnte nicht gespeichert werden.';

  @override
  String get groupsMembersFailed => 'Mitglieder konnten nicht geladen werden';

  @override
  String get groupsPleaseTryAgain => 'Bitte versuche es noch einmal.';

  @override
  String groupsMemberYou(String name) {
    return '$name (du)';
  }

  @override
  String get groupsRoleOwner => 'Leitung';

  @override
  String get groupsRoleModerator => 'Moderator';

  @override
  String get groupsRoleMember => 'Mitglied';

  @override
  String groupsMemberOptions(String name) {
    return 'Optionen für $name';
  }

  @override
  String get groupsEditFailed =>
      'Deine Änderungen konnten nicht gespeichert werden.';

  @override
  String get groupsSaving => 'Wird gespeichert…';

  @override
  String get groupsSaveChanges => 'Änderungen speichern';

  @override
  String get groupsNameLabel => 'Gruppenname';

  @override
  String get groupsAboutLabel => 'Worum geht es?';

  @override
  String get groupsAboutOptionalLabel => 'Worum geht es? (optional)';

  @override
  String get groupsCityLabel => 'Stadt (optional)';

  @override
  String get groupsCoverColorTheme => 'Design';

  @override
  String get groupsCoverColorAccent => 'Akzent';

  @override
  String get groupsCoverColorWarm => 'Warm';

  @override
  String get groupsLifestyleLabel => 'Lifestyle';

  @override
  String get groupsCreateCoverUploadFailed =>
      'Deine Gruppe ist fertig, aber das Titelbild konnte nicht hochgeladen werden. Versuch es in der Gruppe noch einmal.';

  @override
  String get groupsCreatePickLifestyle =>
      'Wähle einen Lifestyle für deine Community-Gruppe.';

  @override
  String get groupsCreateNameTooShort =>
      'Gib deiner Gruppe einen Namen mit mindestens 3 Buchstaben.';

  @override
  String get groupsCreateFailed =>
      'Deine Gruppe konnte nicht erstellt werden. Bitte versuche es noch einmal.';

  @override
  String get groupsCreateEyebrow => 'NEUE GRUPPE';

  @override
  String get groupsCreateSubtitle =>
      'Bring Menschen zusammen, rund um das, was du liebst.';

  @override
  String get groupsCreateSubtitleFriends =>
      'Mach aus deinen Freunden eine Gruppe.';

  @override
  String get groupsCreateKindHeader => 'WELCHE ART';

  @override
  String get groupsKindCommunity => 'Community-Gruppe';

  @override
  String get groupsKindPrivate => 'Private Gruppe';

  @override
  String get groupsCreateCommunitySubtitle =>
      'Nach Lifestyle. Alle können sie finden und beitreten.';

  @override
  String get groupsCreatePrivateSubtitle =>
      'Nur Freunde. Nur Leute, die du einlädst, können beitreten.';

  @override
  String get groupsCreateLifestyleHeader => 'LIFESTYLE';

  @override
  String get groupsCreateLifestyleCaption =>
      'Hier entdecken andere deine Gruppe.';

  @override
  String get groupsCreateDetailsHeader => 'DETAILS';

  @override
  String get groupsCreateNameHintCommunity =>
      'Sonnenaufgangsläufer aus Indiranagar';

  @override
  String get groupsCreateNameHintPrivate => 'Die Sonntagsbrunch-Crew';

  @override
  String get groupsCreateCoverHeader => 'TITELBILD';

  @override
  String groupsCoverEmojiSemantics(String emoji) {
    return 'Titelbild-Emoji $emoji';
  }

  @override
  String get groupsCreateCoverPhotoOptional => 'Titelbild (optional)';

  @override
  String get groupsCreateCoverPhotoHint =>
      'Mitglieder sehen das Emoji, bis dein Foto freigegeben ist.';

  @override
  String get groupsCreateAddCoverPhoto => 'Titelbild hinzufügen';

  @override
  String get groupsCreateChangePhoto => 'Foto ändern';

  @override
  String get groupsCreateRemovePhoto => 'Foto entfernen';

  @override
  String get groupsCreateFriendsHeader => 'FREUNDE';

  @override
  String get groupsCreateFriendsCaptionEmpty =>
      'Lade Freunde jetzt ein oder später aus der Gruppe.';

  @override
  String get groupsCreateFriendsCaption =>
      'Sie bekommen eine Einladung zum Beitreten.';

  @override
  String get groupsFriendFallback => 'Freund';

  @override
  String groupsRemoveInvitee(String name) {
    return '$name entfernen';
  }

  @override
  String get groupsChooseFriends => 'Freunde auswählen';

  @override
  String get groupsChangeFriends => 'Freunde ändern';

  @override
  String get groupsCreating => 'Wird erstellt…';

  @override
  String get groupsCreateGroup => 'Gruppe erstellen';

  @override
  String get groupsCardRemoved => 'Nach einer Prüfung entfernt';

  @override
  String groupsCardSemanticsMuted(String name, String details) {
    return '$name, $details, Benachrichtigungen stummgeschaltet';
  }

  @override
  String get groupsNotificationsMuted => 'Benachrichtigungen stummgeschaltet';

  @override
  String groupsUnreadMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ungelesene Nachrichten',
      one: '1 ungelesene Nachricht',
    );
    return '$_temp0';
  }

  @override
  String get groupsCoverSheetTitle => 'Titelbild';

  @override
  String get groupsCoverSheetBody =>
      'Jedes Foto wird geprüft, bevor andere Mitglieder es sehen. Nutze ein JPEG oder PNG bis 10 MB.';

  @override
  String get groupsCoverFromPhotos => 'Aus deinen Fotos auswählen';

  @override
  String get groupsCoverTakePhoto => 'Foto aufnehmen';

  @override
  String get groupsCoverTooLarge =>
      'Dieses Foto ist größer als 10 MB. Wähle ein kleineres.';

  @override
  String get groupsCoverPreviewTitle => 'Vorschau deines Titelbilds';

  @override
  String get groupsCoverPreviewBody =>
      'Titelbilder erscheinen als breites Banner, die Mitte deines Fotos bleibt sichtbar.';

  @override
  String get groupsCancel => 'Abbrechen';

  @override
  String get groupsCoverUseThisPhoto => 'Dieses Foto verwenden';

  @override
  String get groupsCoverPreviewSemantics => 'Dein neues Titelbild';

  @override
  String get groupsCoverChecking => 'Dein Titelbild wird geprüft…';

  @override
  String groupsCoverUploading(int percent) {
    return 'Titelbild wird hochgeladen… $percent %';
  }

  @override
  String get groupsCoverUploadedReview =>
      'Dein Titelbild wird geprüft. Bis zur Freigabe siehst nur du es.';

  @override
  String get groupsCoverUpdated => 'Titelbild aktualisiert.';

  @override
  String get groupsPickerSubtitle =>
      'Du kannst nur Personen aus deiner Freundesliste einladen.';

  @override
  String get groupsDone => 'Fertig';

  @override
  String get groupsSearchFriends => 'Freunde suchen';

  @override
  String get groupsFriendsFailed => 'Freunde konnten nicht geladen werden';

  @override
  String get groupsNoFriendsTitle => 'Noch keine Freunde';

  @override
  String get groupsNoFriendsBody =>
      'Füge Freunde über Matches, Profile oder Räume hinzu und hol sie dann in eine Gruppe.';

  @override
  String get groupsAlreadyMember => 'Bereits in dieser Gruppe';

  @override
  String get groupsInvitationSent => 'Einladung gesendet';

  @override
  String get todayActivityCoffee => 'Kaffee';

  @override
  String get todayActivityWalk => 'Ein Spaziergang bei Tag';

  @override
  String get todayActivityMeal => 'Ein Essen';

  @override
  String get todayActivityPlayful => 'Etwas Verspieltes';

  @override
  String get todayActivityEvent => 'Ein Event';

  @override
  String get todayActivityVideoCall => 'Ein Hallo per Video';

  @override
  String get todayActivityDrinks => 'Drinks';

  @override
  String get todayActivityOther => 'Etwas anderes';

  @override
  String get todayBudgetFlexible => 'Lass uns das gemeinsam entscheiden';

  @override
  String get todayBudgetFree => 'Kostenlos bleiben';

  @override
  String get todayBudgetModest => 'Eher günstig';

  @override
  String get todayBudgetTreat => 'Ein kleines Extra';

  @override
  String get todayRhythmTitle => 'Dein Dating-Rhythmus';

  @override
  String get todayRhythmLoadFailed =>
      'Deine Einstellungen konnten nicht geladen werden.';

  @override
  String get todayRhythmSaved => 'Dein Dating-Rhythmus ist gespeichert.';

  @override
  String get todayRhythmSaveFailed =>
      'Speichern nicht möglich. Deine Auswahl ist noch da.';

  @override
  String get todayRhythmHeadline => 'Schaff Raum für deine Art zu daten.';

  @override
  String get todayRhythmIntro =>
      'Wähle, was zu deinem Leben passt. Verfügbarkeit und Vorstellungen sind freiwillig, und du kannst es dir jederzeit anders überlegen.';

  @override
  String get todayRhythmOpenTo => 'Wofür bist du offen?';

  @override
  String get todayRhythmIntentNone => 'Keine Angabe';

  @override
  String get todayRhythmIntentRelationship => 'Eine Beziehung';

  @override
  String get todayRhythmIntentExploring => 'Ich finde noch meinen Weg';

  @override
  String get todayRhythmIntentCasual => 'Etwas Lockeres';

  @override
  String get todayRhythmPaceSection => 'Dein Gesprächstempo';

  @override
  String get todayRhythmPaceNone => 'Keine Vorliebe';

  @override
  String get todayRhythmPaceSlow => 'Etwas langsamer';

  @override
  String get todayRhythmPaceSteady => 'Ein gleichmäßiges Gespräch';

  @override
  String get todayRhythmPaceFrequent => 'Häufige Gespräche';

  @override
  String get todayRhythmSlowWeek => 'Langsame Antworten diese Woche';

  @override
  String get todayRhythmSlowWeekHint =>
      'Dieser Status endet nach sieben Tagen.';

  @override
  String get todayRhythmSharePace => 'Diesen Status mit meinen Matches teilen';

  @override
  String get todayRhythmSharePaceHint =>
      'Nur aktuelle Matches sehen deinen vorübergehenden Status.';

  @override
  String get todayRhythmFirstDate => 'Deine Art von erstem Date';

  @override
  String get todayRhythmChooseFive =>
      'Wähle bis zu fünf. Gemeinsame Vorlieben helfen, deine Vorstellungen zu erklären.';

  @override
  String get todayRhythmWeekSection => 'Ein bisschen Platz in deiner Woche';

  @override
  String get todayRhythmShareAvailability => 'Meine grobe Verfügbarkeit nutzen';

  @override
  String get todayRhythmShareAvailabilityHint =>
      'Nur echte Überschneidungen werden gezeigt. Dein vollständiger Zeitplan bleibt privat. Beim Ausschalten werden gespeicherte Zeitfenster gelöscht.';

  @override
  String get todayRhythmAvailabilityHint =>
      'Tippe auf jeden Morgen, Nachmittag oder Abend, der dir passt. Die Zeiten richten sich nach der Ortszeit dieses Geräts und laufen automatisch ab.';

  @override
  String get todayRhythmMorning => 'Morgen';

  @override
  String get todayRhythmAfternoon => 'Nachmittag';

  @override
  String get todayRhythmEvening => 'Abend';

  @override
  String get todayRhythmIntrosSection => 'Vorstellungen mit deiner Erlaubnis';

  @override
  String get todayRhythmFriendIntros =>
      'Vorstellungen durch bestätigte Freunde erlauben';

  @override
  String get todayRhythmFriendIntrosHint =>
      'Beide müssen zustimmen. Deine Freundin oder dein Freund erfährt nichts über Match oder Absage. Eine Vorschau enthält deinen Namen und dein Alter.';

  @override
  String get todayRhythmIntroPhoto => 'Meine Profilfotos einbeziehen';

  @override
  String get todayRhythmIntroPhotoHint =>
      'Nur die Person, die die Vorstellung erhält, kann sie sehen.';

  @override
  String get todayRhythmIntroCity => 'Meine Stadt einbeziehen';

  @override
  String get todayRhythmIntroCityHint =>
      'Dein genauer Standort wird nie geteilt.';

  @override
  String get todayRhythmReload => 'Gespeicherte Auswahl neu laden';

  @override
  String get todayRhythmSaving => 'Wird gespeichert…';

  @override
  String get todayRhythmSave => 'Meinen Rhythmus speichern';

  @override
  String get todayRhythmBreakTitle => 'Eine Pause ist immer in Ordnung.';

  @override
  String get todayRhythmBreakBody =>
      'Pausiere neue Vorstellungen, wann immer du möchtest. Deine bestehenden Unterhaltungen bleiben verfügbar.';

  @override
  String get todayRhythmPauseFailed =>
      'Deine Pause konnte nicht aktualisiert werden.';

  @override
  String get todayRhythmResume => 'Vorstellungen fortsetzen';

  @override
  String get todayRhythmPause => 'Vorstellungen pausieren';

  @override
  String get datingConnectionSlowTitle => 'Antwortet diese Woche langsamer';

  @override
  String get datingConnectionSlowBody =>
      'Dein Match nimmt sich gerade Raum für ein langsameres Tempo.';

  @override
  String get datingConnectionYourTurn =>
      'Du bist dran: Füg eine Überraschung hinzu';

  @override
  String get datingConnectionComplete => 'Euer erstes Kapitel ist fertig';

  @override
  String get datingConnectionWaiting => 'Euer Kapitel hat einen Anfang';

  @override
  String get datingConnectionCreate => 'Erstellt euer erstes Kapitel';

  @override
  String get datingConnectionBody =>
      'Ein Anfang, eine Überraschung und eine Geschichte, die ihr gemeinsam gestaltet.';

  @override
  String get chemistryTitle => 'Ein bisschen Chemie';

  @override
  String get chemistryIntro =>
      'Wähle, was sich nach dir anfühlt. Es gibt keine richtigen Antworten, und das hat nie Einfluss auf den Zugang zum Chat.';

  @override
  String get chemistrySaveFailed =>
      'Deine Auswahl konnte nicht gespeichert werden. Bitte versuche es erneut.';

  @override
  String get chemistryRetry => 'Erneut laden';

  @override
  String get chemistryRevealedTitle => 'Beide Antworten, zusammen';

  @override
  String get chemistryYouPicked => 'Deine Wahl';

  @override
  String get chemistryMatchPicked => 'Die Wahl deines Matches';

  @override
  String get chemistryRevealedBody =>
      'Ein gemeinsamer Favorit oder ein schöner Unterschied – so oder so habt ihr Gesprächsstoff.';

  @override
  String get chemistryWaitingBody =>
      'Deine Antwort ist privat gespeichert. Beide Antworten erscheinen hier, sobald ihr beide gewählt habt.';

  @override
  String chemistryYourChoice(String choice) {
    return 'Deine Wahl: $choice';
  }

  @override
  String get chemistryAnotherMoment => 'Noch ein Moment, wann immer du magst';

  @override
  String get chemistryChooseMoment => 'Wähle einen Moment';

  @override
  String get chemistryPromptSunday => 'Gestalte einen Sonntag';

  @override
  String get chemistryPromptAdventure => 'Wähle ein Abenteuer';

  @override
  String get chemistryPromptFirstDate => 'Deine Art von erstem Date';

  @override
  String get chemistryQuestionSunday => 'Dein idealer Sonntag beginnt mit…';

  @override
  String get chemistryQuestionAdventure => 'Ein kleines gemeinsames Abenteuer…';

  @override
  String get chemistryQuestionFirstDate =>
      'Für ein erstes Hallo würdest du wählen…';

  @override
  String get engagementLevelFrozen =>
      'Dein Fortschritt ist pausiert, solange eine Sicherheitsprüfung deines Kontos läuft.';

  @override
  String get engagementLevelTrustGate =>
      'Verifiziere dein Profil und halte dein Konto in gutem Zustand, um vertrauensgebundene Level freizuschalten.';

  @override
  String get engagementLevelPathTitle => 'Level-Pfad';

  @override
  String get engagementLevelPathSubtitle =>
      'XP gibt es für sinnvolle Aktivität. Käufe erhöhen dein Level nie.';

  @override
  String get engagementLevelRewardsTitle => 'Belohnungen';

  @override
  String get engagementLevelRewardsSubtitle =>
      'Verdiente Belohnungen sind optisch, praktisch oder begrenzte Sichtbarkeitsvorteile.';

  @override
  String get engagementLevelRecentTitle => 'Letzte XP';

  @override
  String get engagementLevelRecentSubtitle =>
      'Dein Aktivitätsprotokoll ist dauerhaft und nachprüfbar.';

  @override
  String engagementLevelNumber(int level) {
    return 'Level $level';
  }

  @override
  String engagementLevelXp(String xp) {
    return '$xp XP';
  }

  @override
  String get engagementLevelHighest => 'Höchstes Level erreicht';

  @override
  String engagementLevelProgress(int xp, String percent) {
    return '$xp XP in diesem Level · $percent %';
  }

  @override
  String engagementLevelThreshold(int xp, String summary) {
    return '$xp XP · $summary';
  }

  @override
  String get engagementLevelTrustGated => 'Vertrauensgebunden';

  @override
  String get engagementLevelClaimed => 'Eingelöst';

  @override
  String get engagementLevelClaim => 'Einlösen';

  @override
  String get engagementLevelLocked => 'Gesperrt';

  @override
  String get engagementLevelStandardAward => 'Standardvergabe';

  @override
  String engagementLevelQualityWeighting(String multiplier) {
    return '$multiplier× Qualitätsgewichtung';
  }

  @override
  String get engagementLevelEmptyLedger =>
      'Schließ sinnvolle Aktivitäten ab, um deine ersten XP zu sammeln.';

  @override
  String get engagementXpSourceProfileCompleted => 'Profil vervollständigt';

  @override
  String get engagementXpSourceDailyPromptSubmitted =>
      'Tagesimpuls beantwortet';

  @override
  String get engagementXpSourceMiniActivityCompleted =>
      'Mini-Aktivität abgeschlossen';

  @override
  String get engagementXpSourceCircleChallengeSubmitted =>
      'Kreis-Challenge eingereicht';

  @override
  String get engagementXpSourceVoiceIcebreakerPlayed =>
      'Sprach-Eisbrecher angehört';

  @override
  String get engagementXpSourceStreak3 => '3-Tage-Serie';

  @override
  String get engagementXpSourceStreak7 => '7-Tage-Serie';

  @override
  String get engagementXpSourceStreak14 => '14-Tage-Serie';

  @override
  String get engagementXpSourceAdminAdjustment => 'Korrektur durch das Team';

  @override
  String get engagementLevelSignIn =>
      'Melde dich an, um deinen Level-Fortschritt zu sehen.';

  @override
  String get engagementLevelLoadFailed =>
      'Dein Fortschritt kann gerade nicht geladen werden.';

  @override
  String get engagementLevelClaimFailed =>
      'Diese Belohnung kann gerade nicht eingelöst werden.';

  @override
  String get engagementCoffeeTitle => 'Kaffee-Umfragen für Gruppen';

  @override
  String get engagementCoffeeCreateHeading =>
      'Erstelle eine einfache Kaffee-Umfrage für deine Gruppe';

  @override
  String get engagementCoffeeCreateHint =>
      'Füge bis zu 3 Nutzer-IDs von Teilnehmenden (durch Kommas getrennt) und mindestens eine Option hinzu.';

  @override
  String get engagementCoffeeParticipantsLabel =>
      'Nutzer-IDs der Teilnehmenden (durch Kommas getrennt)';

  @override
  String get engagementCoffeeDeadlineLabel => 'Frist im ISO-Format (optional)';

  @override
  String engagementCoffeeOptionNumber(int number) {
    return 'Option $number';
  }

  @override
  String get engagementCoffeeCreate => 'Umfrage erstellen';

  @override
  String get engagementCoffeeActorLabel =>
      'Abweichende Nutzer-ID für Aktionen (optional)';

  @override
  String get engagementCoffeeEmpty =>
      'Noch keine Umfragen. Erstelle oben eine.';

  @override
  String engagementCoffeePollId(String id) {
    return 'Umfrage $id';
  }

  @override
  String engagementCoffeeStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get engagementCoffeeStatusOpen => 'offen';

  @override
  String get engagementCoffeeStatusFinalized => 'abgeschlossen';

  @override
  String engagementCoffeeParticipants(String ids) {
    return 'Teilnehmende: $ids';
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
      other: '$day · $time · $area ($count Stimmen)',
      one: '$day · $time · $area (1 Stimme)',
    );
    return '$_temp0';
  }

  @override
  String get engagementCoffeeVote => 'Abstimmen';

  @override
  String get engagementCoffeeFinalize => 'Umfrage abschließen';

  @override
  String get engagementCoffeeDayLabel => 'Tag';

  @override
  String get engagementCoffeeTimeLabel => 'Zeitfenster';

  @override
  String get engagementCoffeeAreaLabel => 'Viertel';

  @override
  String get engagementCoffeeLoadFailed =>
      'Die Gruppenumfragen können gerade nicht geladen werden.';

  @override
  String get engagementCoffeeCreateFailed =>
      'Die Gruppenumfrage kann gerade nicht erstellt werden.';

  @override
  String get engagementCoffeeVoteUserRequired =>
      'Zum Abstimmen ist eine Nutzer-ID nötig.';

  @override
  String get engagementCoffeeVoteFailed =>
      'Abstimmen ist gerade nicht möglich.';

  @override
  String get engagementCoffeeFinalizeUserRequired =>
      'Zum Abschließen ist eine Nutzer-ID nötig.';

  @override
  String get engagementCoffeeFinalizeFailed =>
      'Die Umfrage kann gerade nicht abgeschlossen werden.';

  @override
  String get engagementDailyPromptUnavailable => 'Tagesimpuls nicht verfügbar';

  @override
  String get engagementDailyPromptPullToRefresh =>
      'Zum Aktualisieren nach unten ziehen oder gleich noch einmal versuchen.';

  @override
  String get engagementDailyPromptDomainValues => 'WERTE';

  @override
  String get engagementDailyPromptDomainLifestyle => 'LEBENSSTIL';

  @override
  String get engagementDailyPromptDomainRelationshipStyle => 'BEZIEHUNGSSTIL';

  @override
  String get engagementDailyPromptSparkTitle => 'Kompatibilitäts-Funke';

  @override
  String engagementDailyPromptSparkSummary(int replied, int similar) {
    return 'Antworten heute: $replied · ähnliche Antworten: $similar';
  }

  @override
  String get engagementDailyPromptYourAnswer => 'Deine Antwort';

  @override
  String get engagementDailyPromptHint =>
      'Schreib deine Antwort in unter 60 Sekunden.';

  @override
  String engagementDailyPromptEditOpenUntil(String time) {
    return 'Bearbeiten möglich bis $time';
  }

  @override
  String get engagementDailyPromptEditOpenSoon =>
      'Bearbeiten nur noch kurz möglich';

  @override
  String get engagementDailyPromptEditClosed =>
      'Bearbeiten ist für heute nicht mehr möglich.';

  @override
  String get engagementDailyPromptEdited => 'Bearbeitet';

  @override
  String get engagementDailyPromptSubmit => 'Tagesantwort senden';

  @override
  String get engagementDailyPromptUpdate => 'Antwort aktualisieren';

  @override
  String get engagementDailyPromptStreakProgress => 'Serienfortschritt';

  @override
  String engagementDailyPromptStatCurrent(String value) {
    return 'Aktuell: $value';
  }

  @override
  String engagementDailyPromptStatBest(String value) {
    return 'Rekord: $value';
  }

  @override
  String engagementDailyPromptStatNext(String value) {
    return 'Nächstes Ziel: $value';
  }

  @override
  String engagementDailyPromptDays(int days) {
    return '$days T.';
  }

  @override
  String get engagementDailyPromptComplete => 'Alles erreicht';

  @override
  String engagementDailyPromptMilestone(int days) {
    return 'Meilenstein erreicht: $days-Tage-Serie';
  }

  @override
  String get engagementDailyPromptLoadFailed =>
      'Der Tagesimpuls kann gerade nicht geladen werden.';

  @override
  String get engagementDailyPromptNotLoaded =>
      'Der Tagesimpuls ist noch nicht geladen.';

  @override
  String get engagementDailyPromptEnterAnswer =>
      'Bitte schreib zuerst eine Antwort.';

  @override
  String get engagementDailyPromptSubmitFailed =>
      'Antwort konnte nicht gesendet werden. Bitte versuch es noch einmal.';

  @override
  String get clubsKindBooks => 'Bücher';

  @override
  String get clubsKindFilms => 'Filme';

  @override
  String get clubsFilterAll => 'Alle';

  @override
  String get clubsAudiencePrivate => 'Nur ich';

  @override
  String get clubsAudienceFriends => 'Freunde';

  @override
  String get clubsAudienceCommunity => 'Connect-Community';

  @override
  String get clubsRoleOwner => 'Leitung';

  @override
  String get clubsRoleModerator => 'Moderator';

  @override
  String get clubsRoleMember => 'Mitglied';

  @override
  String get clubsBadgeBookClub => 'Buchclub';

  @override
  String get clubsBadgeFilmClub => 'Filmclub';

  @override
  String get clubsBadgeBookList => 'Bücherliste';

  @override
  String get clubsBadgeFilmList => 'Filmliste';

  @override
  String get clubsBadgeBook => 'Buch';

  @override
  String get clubsBadgeFilm => 'Film';

  @override
  String get clubsClub => 'Club';

  @override
  String clubsStarsOutOfFive(String rating) {
    return '$rating von 5 Sternen';
  }

  @override
  String clubsStarCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sterne',
      one: '1 Stern',
    );
    return '$_temp0';
  }

  @override
  String get clubsNoRatingsYet => 'Noch keine Bewertungen';

  @override
  String clubsRatingSummary(String average, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Rezensionen',
      one: '1 Rezension',
    );
    return '$average · $_temp0';
  }

  @override
  String get clubsWeekThis => 'Diese Woche';

  @override
  String get clubsWeekNext => 'Nächste Woche';

  @override
  String get clubsWeekLast => 'Letzte Woche';

  @override
  String clubsWeekOf(String date) {
    return 'Woche vom $date';
  }

  @override
  String get clubsTitle => 'Buch- & Filmclubs';

  @override
  String get clubsMyLists => 'Meine Listen';

  @override
  String get clubsStartClubTooltip => 'Gründe einen Buch- oder Filmclub';

  @override
  String get clubsStartClub => 'Club gründen';

  @override
  String get clubsSignInToSee => 'Melde dich an, um Clubs zu sehen.';

  @override
  String get clubsHeroTitle => 'Lesen. Schauen. Darüber reden.';

  @override
  String get clubsHeroSubtitle =>
      'Tritt einem Club bei, folge einer Auswahl pro Woche und teile, was du denkst. Guter Geschmack ist ein toller Gesprächsstarter.';

  @override
  String get clubsScopeMine => 'Meine Clubs';

  @override
  String get clubsScopeDiscover => 'Entdecken';

  @override
  String get clubsLoadErrorTitle => 'Clubs konnten nicht geladen werden';

  @override
  String get clubsCheckConnection => 'Bitte prüfe deine Verbindung.';

  @override
  String get clubsLookAroundTitle => 'Du kannst dich umsehen';

  @override
  String get clubsLookAroundMessage =>
      'Vervollständige dein Profil mit zwei freigegebenen Fotos, um einen Club zu gründen oder beizutreten.';

  @override
  String get clubsEmptyMineTitle => 'Dein erster Club wartet';

  @override
  String get clubsEmptyMineMessage =>
      'Finde einen Club, der liest oder schaut, was du liebst – oder gründe deinen eigenen.';

  @override
  String get clubsEmptyDiscoverTitle => 'Hier gibt es noch keine Clubs';

  @override
  String get clubsEmptyDiscoverMessage =>
      'Mach den Anfang: Gründe einen Club und wähle etwas Tolles für diese Woche aus.';

  @override
  String get clubsDiscoverClubs => 'Clubs entdecken';

  @override
  String clubsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
    );
    return '$_temp0';
  }

  @override
  String get clubsYouRunIt => 'Du leitest ihn';

  @override
  String get clubsYouModerate => 'Du moderierst';

  @override
  String get clubsJoined => 'Beigetreten ✓';

  @override
  String get clubsNoPickThisWeek => 'Diese Woche noch keine Auswahl';

  @override
  String get clubsNameTooShort =>
      'Gib deinem Club einen Namen mit mindestens 3 Buchstaben.';

  @override
  String get clubsCreateFailed => 'Dein Club konnte nicht erstellt werden.';

  @override
  String get clubsNameLabel => 'Clubname';

  @override
  String get clubsNameHint => 'Sonntagslesekreis';

  @override
  String get clubsDescriptionLabel =>
      'Worum geht es in deinem Club? (optional)';

  @override
  String get clubsCreating => 'Wird erstellt…';

  @override
  String get clubsCreateClub => 'Club erstellen';

  @override
  String clubsLeaveTitle(String name) {
    return '$name verlassen?';
  }

  @override
  String get clubsLeaveMessage =>
      'Du kannst später wieder beitreten, solange der Club offen ist.';

  @override
  String get clubsLeaveClub => 'Club verlassen';

  @override
  String clubsWelcome(String name) {
    return 'Willkommen bei $name!';
  }

  @override
  String get clubsChangeNotSaved =>
      'Diese Änderung konnte nicht gespeichert werden.';

  @override
  String get clubsOptionsTooltip => 'Club-Optionen';

  @override
  String get clubsMembers => 'Mitglieder';

  @override
  String get clubsReportClub => 'Club melden';

  @override
  String get clubsDetailLoadErrorTitle =>
      'Dieser Club konnte nicht geladen werden';

  @override
  String get clubsDetailLoadErrorMessage =>
      'Vielleicht wurde er geschlossen. Bitte versuch es noch mal.';

  @override
  String get clubsEarlierPicks => 'Frühere Auswahlen';

  @override
  String clubsPickSubtitle(String week, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Beiträge',
      one: '1 Beitrag',
    );
    return '$week · $_temp0';
  }

  @override
  String get clubsOpenDiscussion => 'Diskussion öffnen';

  @override
  String get clubsJoinToSeeTitle => 'Tritt bei, um die Diskussion zu sehen';

  @override
  String get clubsJoinToSeeMessage =>
      'Mitglieder sprechen gemeinsam über jede Auswahl. Tritt dem Club bei, um mitzulesen und deine Gedanken zu teilen.';

  @override
  String clubsYouRole(String role) {
    return 'Du: $role';
  }

  @override
  String get clubsRemovedByModeration =>
      'Dieser Club wurde von der Moderation entfernt.';

  @override
  String get clubsJoinClub => 'Club beitreten';

  @override
  String get clubsNoPickModerator =>
      'Noch keine Auswahl. Wähle etwas Tolles für alle aus.';

  @override
  String get clubsNoPickMember =>
      'Noch keine Auswahl. Schau bald wieder vorbei.';

  @override
  String clubsQuotedNote(String note) {
    return '„$note“';
  }

  @override
  String clubsPostsInDiscussion(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Beiträge in der Diskussion',
      one: '1 Beitrag in der Diskussion',
    );
    return '$_temp0';
  }

  @override
  String get clubsSetThisWeeksPick => 'Auswahl dieser Woche festlegen';

  @override
  String get clubsDiscussThisPick => 'Über diese Auswahl diskutieren';

  @override
  String get clubsPostNotSent => 'Dein Beitrag konnte nicht gesendet werden.';

  @override
  String clubsDiscussionHeading(String title) {
    return 'Diskussion · $title';
  }

  @override
  String get clubsDiscussionLoadError =>
      'Die Diskussion konnte nicht geladen werden';

  @override
  String get clubsStartConversationTitle => 'Starte das Gespräch';

  @override
  String get clubsStartConversationMessage =>
      'Wie findest du es bisher? Dein Beitrag könnte das Gespräch ins Rollen bringen.';

  @override
  String get clubsLoadMorePosts => 'Weitere Beiträge laden';

  @override
  String get clubsComposerLabel => 'Zur Diskussion beitragen';

  @override
  String get clubsComposerHint => 'Lieblingsmoment? Größte Überraschung?';

  @override
  String get clubsContainsSpoilers => 'Enthält Spoiler';

  @override
  String get clubsSpoilersSubtitle => 'Andere tippen, um ihn anzuzeigen.';

  @override
  String get clubsPosting => 'Wird gepostet…';

  @override
  String get clubsPost => 'Posten';

  @override
  String get clubsDeletePostTitle => 'Deinen Beitrag löschen?';

  @override
  String get clubsDeletePostMessage =>
      'Er wird für alle aus der Diskussion entfernt.';

  @override
  String get clubsActionFailed =>
      'Diese Aktion konnte nicht abgeschlossen werden.';

  @override
  String get clubsHideFromMembers => 'Vor Mitgliedern verbergen';

  @override
  String get clubsShowToMembers => 'Für Mitglieder anzeigen';

  @override
  String get clubsReport => 'Melden';

  @override
  String get clubsYou => 'Du';

  @override
  String get clubsHidden => 'Verborgen';

  @override
  String get clubsPostActions => 'Beitragsaktionen';

  @override
  String get clubsMakeModerator => 'Zum Moderator machen';

  @override
  String get clubsMakeMember => 'Zum Mitglied machen';

  @override
  String get clubsRemoveFromClub => 'Aus dem Club entfernen';

  @override
  String clubsRemoveMemberTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String get clubsRemoveMemberMessage =>
      'Die Person verlässt den Club und kann nicht wieder beitreten. Ihre bisherigen Beiträge bleiben in der Diskussion.';

  @override
  String get clubsRemove => 'Entfernen';

  @override
  String get clubsMembersLoadError =>
      'Mitglieder konnten nicht geladen werden.';

  @override
  String clubsMemberYou(String name) {
    return '$name (du)';
  }

  @override
  String clubsMemberActions(String name) {
    return 'Aktionen für $name';
  }

  @override
  String get clubsChooseFilm => 'Wähle einen Film';

  @override
  String get clubsChooseBook => 'Wähle ein Buch';

  @override
  String get clubsChooseTitle => 'Wähle einen Titel';

  @override
  String get clubsChooseTitleFirst => 'Wähle zuerst einen Titel.';

  @override
  String get clubsPickNotSaved =>
      'Die Auswahl konnte nicht gespeichert werden.';

  @override
  String get clubsSetWeeklyPick => 'Wochenauswahl festlegen';

  @override
  String get clubsChange => 'Ändern';

  @override
  String get clubsPickNoteLabel => 'Eine Notiz für den Club (optional)';

  @override
  String get clubsPickNoteHint => 'Warum das? Wo anfangen?';

  @override
  String get clubsSaving => 'Wird gespeichert…';

  @override
  String get clubsSavePick => 'Auswahl speichern';

  @override
  String get clubsListNameRequired => 'Gib deiner Liste einen Namen.';

  @override
  String get clubsListNotSaved =>
      'Deine Liste konnte nicht gespeichert werden.';

  @override
  String get clubsEditList => 'Liste bearbeiten';

  @override
  String get clubsNewList => 'Neue Liste';

  @override
  String get clubsListNameLabel => 'Name der Liste';

  @override
  String get clubsListNameHint => 'Bücher, die meine Sicht verändert haben';

  @override
  String get clubsWhoCanSee => 'Wer es sehen kann';

  @override
  String get clubsSave => 'Speichern';

  @override
  String get clubsCreateList => 'Liste erstellen';

  @override
  String get clubsYourNote => 'Deine Notiz';

  @override
  String get clubsNoteLabel => 'Warum es auf dieser Liste steht';

  @override
  String get clubsSaveNote => 'Notiz speichern';

  @override
  String get clubsCreateNewListTooltip => 'Neue Liste erstellen';

  @override
  String get clubsSignInToSeeLists =>
      'Melde dich an, um deine Listen zu sehen.';

  @override
  String get clubsShelfTitle => 'Dein Regal';

  @override
  String get clubsShelfSubtitle =>
      'Behalte im Blick, was du geliebt hast und was als Nächstes kommt. Teile eine Liste oder behalte sie für dich.';

  @override
  String get clubsListsLoadErrorTitle =>
      'Deine Listen konnten nicht geladen werden';

  @override
  String get clubsFirstListTitle => 'Leg deine erste Liste an';

  @override
  String get clubsFirstListMessage =>
      'Lieblingsfilme, Bücher für danach, Wohlfühlfilme zum x-ten Mal: Du entscheidest.';

  @override
  String clubsAddToNamed(String name) {
    return 'Zu $name hinzufügen';
  }

  @override
  String get clubsAddToThisListFailed =>
      'Es konnte nicht zu dieser Liste hinzugefügt werden.';

  @override
  String clubsDeleteListTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get clubsDeleteListMessage =>
      'Die Liste und ihre Notizen werden entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String get clubsDeleteList => 'Liste löschen';

  @override
  String get clubsListDeleteFailed =>
      'Die Liste konnte nicht gelöscht werden. Lade neu und versuch es noch mal.';

  @override
  String get clubsNoteNotSaved =>
      'Deine Notiz konnte nicht gespeichert werden.';

  @override
  String get clubsRemoveFailed => 'Es konnte nicht entfernt werden.';

  @override
  String get clubsListOptions => 'Listenoptionen';

  @override
  String get clubsAddATitle => 'Titel hinzufügen';

  @override
  String clubsTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel',
      one: '1 Titel',
    );
    return '$_temp0';
  }

  @override
  String get clubsListEmpty =>
      'Hier ist noch nichts. Nutze „Titel hinzufügen“ im Listenmenü.';

  @override
  String clubsItemOptions(String title) {
    return 'Optionen für $title';
  }

  @override
  String get clubsAddNote => 'Notiz hinzufügen';

  @override
  String get clubsEditNote => 'Notiz bearbeiten';

  @override
  String get clubsRemoveFromList => 'Von der Liste entfernen';

  @override
  String get clubsTapStarError => 'Tippe auf einen Stern, um zu bewerten.';

  @override
  String get clubsReviewNotSaved =>
      'Deine Rezension konnte nicht gespeichert werden.';

  @override
  String get clubsWriteReview => 'Rezension schreiben';

  @override
  String get clubsEditYourReview => 'Rezension bearbeiten';

  @override
  String get clubsTapStarToRate => 'Tippe auf einen Stern';

  @override
  String clubsRatingOutOfFive(int rating) {
    return '$rating von 5';
  }

  @override
  String get clubsReviewBodyLabel => 'Wie fandest du es? (optional)';

  @override
  String get clubsSaveReview => 'Rezension speichern';

  @override
  String clubsAddedToList(String name) {
    return 'Zu $name hinzugefügt.';
  }

  @override
  String get clubsAddToThatListFailed =>
      'Es konnte nicht zu dieser Liste hinzugefügt werden.';

  @override
  String get clubsAddToAList => 'Zu einer Liste hinzufügen';

  @override
  String get clubsListsLoadError =>
      'Deine Listen konnten nicht geladen werden.';

  @override
  String get clubsNoFilmLists =>
      'Du hast noch keine Filmlisten. Erstelle eine, um zu sammeln.';

  @override
  String get clubsNoBookLists =>
      'Du hast noch keine Bücherlisten. Erstelle eine, um zu sammeln.';

  @override
  String get clubsTitleFallback => 'Titel';

  @override
  String get clubsSignInToSeeReviews =>
      'Melde dich an, um Rezensionen zu sehen.';

  @override
  String get clubsTitleLoadError => 'Dieser Titel konnte nicht geladen werden';

  @override
  String get clubsReviews => 'Rezensionen';

  @override
  String get clubsNoOtherReviewsTitle => 'Noch keine weiteren Rezensionen';

  @override
  String get clubsNoOtherReviewsMessage =>
      'Wenn Mitglieder, die du sehen kannst, eine Rezension teilen, erscheint sie hier.';

  @override
  String get clubsDeleteReviewTitle => 'Rezension löschen?';

  @override
  String get clubsDeleteReviewMessage =>
      'Deine Bewertung und dein Text werden für alle entfernt.';

  @override
  String get clubsDeleteReview => 'Rezension löschen';

  @override
  String get clubsReviewDeleteFailed =>
      'Deine Rezension konnte nicht gelöscht werden. Lade neu und versuch es noch mal.';

  @override
  String get clubsWhatDidYouThink => 'Wie fandest du es?';

  @override
  String get clubsReviewPrompt =>
      'Bewerte es und sag, warum. Du entscheidest, wer es sieht.';

  @override
  String get clubsYourReview => 'Deine Rezension';

  @override
  String get clubsSpoilers => 'Spoiler';

  @override
  String get clubsEdit => 'Bearbeiten';

  @override
  String get clubsReportReview => 'Diese Rezension melden';

  @override
  String get clubsEnterTitle => 'Gib den Titel ein.';

  @override
  String get clubsYearRange => 'Gib ein Jahr zwischen 1450 und 2100 ein.';

  @override
  String get clubsTitleAddFailed =>
      'Der Titel konnte nicht hinzugefügt werden.';

  @override
  String get clubsSearchFilms => 'Filme suchen';

  @override
  String get clubsSearchBooks => 'Bücher suchen';

  @override
  String get clubsTypeTwoLetters => 'Gib mindestens 2 Buchstaben ein';

  @override
  String get clubsSearchUnavailable => 'Die Suche ist nicht verfügbar.';

  @override
  String get clubsNoFilmsMatch => 'Keine passenden Filme. Füg ihn unten hinzu.';

  @override
  String get clubsNoBooksMatch => 'Keine passenden Bücher. Füg es unten hinzu.';

  @override
  String get clubsAddNewFilm => 'Neuen Film hinzufügen';

  @override
  String get clubsAddNewBook => 'Neues Buch hinzufügen';

  @override
  String get clubsTitleFieldLabel => 'Titel';

  @override
  String get clubsDirector => 'Regie';

  @override
  String get clubsAuthor => 'Autor';

  @override
  String get clubsYearOptional => 'Jahr (optional)';

  @override
  String get clubsAdding => 'Wird hinzugefügt…';

  @override
  String get clubsAddAndChoose => 'Hinzufügen und auswählen';

  @override
  String get friendsIntroducerSaveFailed =>
      'Das konnten wir nicht speichern. Aktualisiere, um die neuesten Berechtigungen zu prüfen, bevor du es noch einmal versuchst.';

  @override
  String friendsIntroducerRevokeTitle(String name) {
    return 'Erlaubnis für $name entfernen?';
  }

  @override
  String get friendsIntroducerRevokeBody =>
      'Neue und unbeantwortete Vorstellungen werden gestoppt. Ein bestehendes gegenseitiges Match bleibt zwischen den beiden Personen.';

  @override
  String get friendsIntroducerKeepPermission => 'Erlaubnis behalten';

  @override
  String get friendsIntroducerRemovePermission => 'Erlaubnis entfernen';

  @override
  String get friendsIntroducerPermissionRemoved => 'Erlaubnis entfernt.';

  @override
  String get friendsIntroducerMemberTitle => 'Deine Vermittler';

  @override
  String get friendsIntroducerAppTitle => 'Connect · Freunde';

  @override
  String get friendsIntroducerRefresh => 'Berechtigungen aktualisieren';

  @override
  String get friendsIntroducerAccount => 'Konto';

  @override
  String get friendsIntroducerAccountPrivacy => 'Konto & Privatsphäre';

  @override
  String get friendsIntroducerSignOut => 'Abmelden';

  @override
  String get friendsIntroducerMemberHeadline =>
      'Gute Freunde. Du entscheidest.';

  @override
  String get friendsIntroducerHeadline =>
      'Du kennst sie.\nDu siehst, was möglich ist.';

  @override
  String get friendsIntroducerMemberIntro =>
      'Lade jemanden, dem du vertraust, ein, dich vorzustellen. Die Person kann ohne Dating-Profil mitmachen. Du entscheidest, wer die Erlaubnis bekommt und was eine Vorschau zeigt.';

  @override
  String get friendsIntroducerIntro =>
      'Ein bisschen Aufmerksamkeit kann etwas Echtes beginnen lassen. Bring Freunde zusammen, die dich um Hilfe gebeten haben.';

  @override
  String get friendsIntroducerMemberListTitle => 'Menschen, die du auswählst';

  @override
  String get friendsIntroducerListTitle => 'Dein kleiner Kreis';

  @override
  String get friendsIntroducerLoadFailed =>
      'Die Berechtigungen konnten nicht geladen werden. Es wurde nichts geändert.';

  @override
  String get friendsIntroducerMemberEmpty =>
      'Noch keine Vermittler. Teile eine Einladung mit einem Freund, dem du vertraust, um loszulegen.';

  @override
  String get friendsIntroducerEmpty =>
      'Dein Kreis beginnt mit einer Erlaubnis. Bitte einen Freund auf Connect um seinen Einladungscode.';

  @override
  String get friendsIntroducerStatusPendingMember =>
      'Möchte deine Erlaubnis, dich vorzustellen.';

  @override
  String get friendsIntroducerStatusPending =>
      'Wartet auf die Freigabe deines Freundes.';

  @override
  String get friendsIntroducerStatusPaused => 'Vorstellungen sind pausiert.';

  @override
  String get friendsIntroducerStatusActive => 'Darf Vorstellungen vorschlagen.';

  @override
  String friendsIntroducerPreview(String extras) {
    String _temp0 = intl.Intl.selectLogic(extras, {
      'photo':
          'Vorschau für ein vorgeschlagenes Date: Name und optional Alter, Foto.',
      'city':
          'Vorschau für ein vorgeschlagenes Date: Name und optional Alter, Stadt.',
      'both':
          'Vorschau für ein vorgeschlagenes Date: Name und optional Alter, Foto, Stadt.',
      'other':
          'Vorschau für ein vorgeschlagenes Date: Name und optional Alter.',
    });
    return '$_temp0';
  }

  @override
  String get friendsIntroducerApproveNote =>
      'Mit der Freigabe schaltest du auch Vorstellungen durch Freunde ein. Du kannst alle Vorstellungen im Dating-Rhythmus pausieren.';

  @override
  String get friendsIntroducerAllow => 'Vorstellungen erlauben';

  @override
  String friendsIntroducerAllowed(String name) {
    return '$name hat jetzt deine Erlaubnis.';
  }

  @override
  String get friendsIntroducerDecline => 'Anfrage ablehnen';

  @override
  String get friendsIntroducerSentTitle => 'Mit Bedacht gesendet';

  @override
  String get friendsIntroducerSentBody =>
      'Ihre Antworten bleiben unter ihnen. Beide müssen Ja sagen, bevor ein Match entsteht.';

  @override
  String get friendsIntroducerReloadSent => 'Gesendete Vorstellungen neu laden';

  @override
  String get friendsIntroducerSentSubtitle =>
      'Gesendet · ihre Entscheidung ist privat';

  @override
  String get friendsIntroducerStepPreview => '1. Vorschau wählen';

  @override
  String get friendsIntroducerPreviewBody =>
      'Ein vorgeschlagenes Date sieht deinen Namen und dein Alter, wenn du es schon zeigst. Dein Vermittler sieht nur deinen Namen, nie dein Profil oder deine Dating-Aktivität.';

  @override
  String get friendsIntroducerIncludePhoto => 'Mein Profilfoto einbeziehen';

  @override
  String get friendsIntroducerIncludeCity => 'Meine Stadt einbeziehen';

  @override
  String get friendsIntroducerStepInvite =>
      '2. Einen vertrauten Freund einladen';

  @override
  String get friendsIntroducerInviteBody =>
      'Der Code funktioniert einmal und läuft nach 48 Stunden ab. Dein Freund tritt über „Nur hier, um Freunde vorzustellen“ auf dem Startbildschirm bei. Du bestätigst hier seinen Namen, bevor etwas geteilt werden kann.';

  @override
  String get friendsIntroducerInviteReady =>
      'Einladung bereit. Frühere, ungenutzte Codes funktionieren nicht mehr.';

  @override
  String get friendsIntroducerCreateCode => 'Einladungscode erstellen';

  @override
  String get friendsIntroducerShareCode =>
      'Teile ihn privat mit deinem Freund. Um diese Vorschau zu ändern, storniere die ungenutzte Einladung und erstelle einen neuen Code.';

  @override
  String get friendsIntroducerCodeCopied => 'Einladungscode kopiert';

  @override
  String get friendsIntroducerCopyCode => 'Code kopieren';

  @override
  String get friendsIntroducerInvitesCancelled =>
      'Ungenutzte Einladungen storniert.';

  @override
  String get friendsIntroducerCancelInvites =>
      'Ungenutzte Einladungen stornieren';

  @override
  String get friendsIntroducerManagePrefs =>
      'Alle Einstellungen für Vorstellungen verwalten';

  @override
  String get friendsIntroducerRedeemTitle => 'Ein Freund hat dich eingeladen?';

  @override
  String get friendsIntroducerRedeemBody =>
      'Füge den privaten Einladungscode ein. Dein Freund bestätigt deinen Namen, bevor du ihn vorstellen kannst.';

  @override
  String get friendsIntroducerCodeLabel => 'Einladungscode';

  @override
  String get friendsIntroducerCodeMissing =>
      'Gib den Einladungscode ein, den dein Freund geteilt hat.';

  @override
  String get friendsIntroducerRequestSent =>
      'Anfrage gesendet. Dein Freund kann dich jetzt unter „Deine Vermittler“ bestätigen.';

  @override
  String get friendsIntroducerAskPermission => 'Um Erlaubnis bitten';

  @override
  String get friendsIntroducerNeedTwo =>
      'Sobald zwei Freunde ihre Erlaubnis geben, kannst du hier eine Vorstellung vorschlagen.';

  @override
  String get friendsIntroducerComposerTitle => 'Siehst du eine Chance?';

  @override
  String get friendsIntroducerWhyLabel =>
      'Warum du an sie gedacht hast (optional)';

  @override
  String get friendsIntroducerWhyHelper =>
      'Beide sehen das. Lass private Details weg.';

  @override
  String get friendsIntroducerIntroSent =>
      'Vorstellung gesendet. Beide können für sich entscheiden.';

  @override
  String get friendsIntroducerSuggest => 'Vorstellung vorschlagen';

  @override
  String get friendsIntroducerPrivacyNote =>
      'Erst die Erlaubnis. Keine öffentliche Dating-Aktivität. Keine Infos darüber, wer Ja oder Nein gesagt hat.';

  @override
  String get planSharingLoadFailed =>
      'Die Freigabe-Optionen konnten nicht geladen werden.';

  @override
  String get planSharingOffSnack => 'Das Teilen mit Kontakten ist aus.';

  @override
  String get planSharingSavedSnack =>
      'Deine ausgewählten Kontakte können diesen Plan jetzt sehen.';

  @override
  String get planSharingSaveFailed =>
      'Speichern nicht möglich. Lade die Auswahl neu, bevor du es noch mal versuchst.';

  @override
  String get planSharingTitle => 'Dein Plan. Deine Leute.';

  @override
  String get planSharingCloseTooltip => 'Teilen schließen';

  @override
  String get planSharingIntro =>
      'Das Teilen mit Kontakten ist zunächst aus. Wähle für diesen Plan bis zu 10 Freunde, denen du vertraust. Dein Date wählt eigene Kontakte.';

  @override
  String get planSharingNoContacts =>
      'Noch keine passenden Freunde. Dein Plan bleibt für dich und dein Date verfügbar.';

  @override
  String get planSharingFriendFallback => 'Ein Freund';

  @override
  String get planSharingPreviewNone => 'Vorschau · keine Kontakte ausgewählt';

  @override
  String planSharingPreviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vorschau · $count ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get planSharingPreviewOffBody =>
      'Deine Freunde bekommen von dir keine Updates zum Plan oder zum Check-in.';

  @override
  String get planSharingPreviewOnBody =>
      'Diese Kontakte sehen den Namen deines Dates, Zeit und Ort, den Status des Plans und deine Check-in-Updates. Beim Speichern bekommen sie den aktuellen Plan.';

  @override
  String get planSharingPrivacyNote =>
      'Nachrichten und privates Feedback nach dem Date bleiben privat. Wenn du einen Kontakt entfernst, bekommt er keine weiteren Updates und verliert den Zugriff auf den Plan in der App. Bereits zugestellte Updates lassen sich nicht zurückholen.';

  @override
  String get planSharingReload => 'Freigabe-Optionen neu laden';

  @override
  String get planSharingSaving => 'Wird gespeichert…';

  @override
  String get planSharingKeepOff => 'Teilen mit Kontakten aus lassen';

  @override
  String get planSharingShareSelected => 'Mit ausgewählten Kontakten teilen';

  @override
  String get planSharingDeselectAll => 'Alle abwählen';

  @override
  String planBudgetLine(String budget) {
    return 'Budget · $budget';
  }

  @override
  String planAtmosphereLine(String atmospheres) {
    return 'Atmosphäre · $atmospheres';
  }

  @override
  String get planAtmosphereQuiet => 'Ruhiges Gespräch';

  @override
  String get planAtmosphereRelaxed => 'Entspannt & ohne Eile';

  @override
  String get planAtmosphereLively => 'Lebhafte Umgebung';

  @override
  String get planAtmosphereOutdoors => 'Draußen';

  @override
  String get planAtmosphereIndoors => 'Drinnen';

  @override
  String get planAccessStepFree => 'Stufenloser Zugang';

  @override
  String get planAccessToilet => 'Barrierefreie Toilette';

  @override
  String get planAccessSeating => 'Sitzplätze vorhanden';

  @override
  String get planAccessLowNoise => 'Wenig Hintergrundlärm';

  @override
  String get planAccessTransit => 'Nah an Bus & Bahn';

  @override
  String get planAccessCaptions => 'Untertitel beim Video-Date';

  @override
  String get planComfortHeading => 'Damit es angenehm wird';

  @override
  String get planPreferencesDisclaimer =>
      'Für diesen Plan geteilte Wünsche. Klär die Details mit dem Ort oder dem Videodienst ab.';

  @override
  String get planProposeErrorKept =>
      'Dein Plan konnte nicht gesendet werden. Deine Auswahl ist noch da.';

  @override
  String get planChangedError =>
      'Dieser Plan hat sich geändert. Schließ dieses Fenster, um den Chat anzusehen.';

  @override
  String get planProposeHeadline => 'Ein Plan, auf den ihr euch beide freut.';

  @override
  String get planCounterHeadline => 'Gestaltet diesen Plan gemeinsam';

  @override
  String planProposeLead(String name) {
    return 'Ein Vorschlag für dich und $name. Fest steht erst etwas, wenn die andere Person diese Version annimmt.';
  }

  @override
  String get planFindTimeTitle => 'Findet ein bisschen gemeinsame Zeit';

  @override
  String get planFindTimeBody =>
      'Gemeinsame Zeiten erscheinen nur, wenn ihr beide eure Verfügbarkeit teilt. Du kannst jederzeit selbst eine Zeit vorschlagen.';

  @override
  String get planSharedTimesFailed =>
      'Gemeinsame Zeiten konnten nicht geladen werden. Du kannst die Zeit weiterhin selbst wählen.';

  @override
  String get planSharedTimesEmpty =>
      'Gerade keine gemeinsamen Zeitvorschläge. Das heißt nicht, dass einer von euch keine Zeit hat.';

  @override
  String get planRefreshSharedTimes => 'Gemeinsame Zeiten aktualisieren';

  @override
  String get planSetAvailability => 'Meine Verfügbarkeit festlegen';

  @override
  String get planWhenTitle => 'Wann würde es passen?';

  @override
  String get planTimeSourceManual => 'Eine Zeit, die du vorschlägst';

  @override
  String get planTimeSourceShared =>
      'Aus gemeinsamer Verfügbarkeit gewählt · wird beim Senden erneut geprüft';

  @override
  String planLocalTimeNote(int minutes, String timeZone) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Ortszeit deines Geräts ($timeZone). Dauer: $minutes Minuten.',
      one: 'Ortszeit deines Geräts ($timeZone). Dauer: $minutes Minute.',
    );
    return '$_temp0';
  }

  @override
  String planDurationChip(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get planEnjoyTitle => 'Etwas, das dir Spaß machen würde';

  @override
  String get planAreaHint => 'Ein Viertel oder ein öffentlicher Treffpunkt';

  @override
  String get planBudgetTitle => 'Welches Budget fühlt sich gut an?';

  @override
  String get planBudgetBody =>
      'Ein Ausgangspunkt, auf den ihr euch einigt – kein Preisangebot und kein Versprechen, wer zahlt.';

  @override
  String get planAtmosphereTitle => 'Die passende Atmosphäre';

  @override
  String get planAtmosphereBody =>
      'Wähl bis zu drei Umgebungen, die dir gefallen würden. Optional.';

  @override
  String get planComfortTitle => 'Damit es für euch beide angenehm ist';

  @override
  String get planComfortBody =>
      'Optionale Wünsche zur Barrierefreiheit. Deine Auswahl wird beim Senden mit deinem Match geteilt. Sie erscheint weder in deinem öffentlichen Profil noch in Updates an Vertrauenskontakte.';

  @override
  String get planComfortDisclaimer =>
      'Du musst keine Diagnose erklären. Das sind Wünsche, die ihr mit dem Ort oder dem Videodienst klärt – keine geprüften Ausstattungsmerkmale.';

  @override
  String get planNoteHint => 'Samstagnachmittag, irgendwo ruhiger?';

  @override
  String get planReviewBeforeSending =>
      'Prüf vor dem Senden die Zeit und deine Auswahl oben. Die andere Person kann annehmen, ablehnen oder eine Änderung vorschlagen.';

  @override
  String get planReloadLatest => 'Neuesten Plan laden · Änderungen verwerfen';

  @override
  String get planSending => 'Wird gesendet…';

  @override
  String get planSendSuggestion => 'Vorschlag senden';

  @override
  String get planSecondYesTitle => 'Ein zweites Ja teilen';

  @override
  String get planSecondYesBody =>
      'Zeig, dass du dich wiedersehen möchtest – aber nur, wenn dein Match auch Ja sagt und dem Teilen zustimmt. Deine anderen Antworten bleiben privat.';

  @override
  String get planSecondYesHeadline => 'Ein zweites Ja von euch beiden';

  @override
  String get planSecondYesCardBody =>
      'Ihr habt beide geteilt, dass ihr euch wiedersehen möchtet.';

  @override
  String get planAnotherHello => 'Noch ein Treffen planen';

  @override
  String get planSuggestChange => 'Änderung vorschlagen';

  @override
  String get planChooseUpdates => 'Wähle, wer deine Updates bekommt';

  @override
  String planQuotedNote(String note) {
    return '„$note“';
  }

  @override
  String get planStatusDeclined => 'Abgelehnt';

  @override
  String get planStatusExpired => 'Abgelaufen';

  @override
  String get planStatusCompleted => 'Abgeschlossen';

  @override
  String get planStatusDidNotHappen => 'Hat nicht stattgefunden';

  @override
  String get planStatusDisputed => 'Strittig';

  @override
  String get plansManageSharing => 'Teilen mit Kontakten verwalten';

  @override
  String get plansLoadFailed => 'Date-Pläne konnten nicht geladen werden.';

  @override
  String get plansFeedLoadFailed => 'Pläne konnten nicht geladen werden.';

  @override
  String get planAcceptFailed => 'Dieser Plan konnte nicht angenommen werden.';

  @override
  String get planDeclineFailed => 'Dieser Plan konnte nicht abgelehnt werden.';

  @override
  String get planCancelFailed => 'Dieser Plan konnte nicht abgesagt werden.';

  @override
  String get planCheckinFailed => 'Melden ist gerade nicht möglich.';

  @override
  String get graduationFoundEachOther => 'Ihr habt euch gefunden';

  @override
  String graduationHeadlineDecide(String name) {
    return '$name möchte Connect gemeinsam mit dir verlassen';
  }

  @override
  String graduationHeadlineWaiting(String name) {
    return 'Warten auf $name';
  }

  @override
  String get graduationBodyConfirmed =>
      'Ihr seid beide in Entdecken ausgeblendet. Dieser Chat bleibt offen.';

  @override
  String get graduationBodyDecide =>
      'Wenn du bestätigst, verschwindet ihr beide aus Entdecken. Euer Chat bleibt.';

  @override
  String get graduationBodyWaiting =>
      'Du hast gefragt, ob ihr gemeinsam geht. Die andere Person kann bestätigen oder ablehnen.';

  @override
  String get graduationCelebrate => 'Feiern';

  @override
  String get graduationNotYet => 'Noch nicht';

  @override
  String get graduationConfirm => 'Bestätigen';

  @override
  String get graduationFriendsToldOnConfirm =>
      'Deine Freunde erfahren es, sobald die andere Person bestätigt.';

  @override
  String get graduationOnlyTwoOfYouForNow =>
      'Vorerst wisst nur ihr beide davon.';

  @override
  String get graduationWithdraw => 'Zurückziehen';

  @override
  String graduationProposeTitle(String name) {
    return 'Connect mit $name verlassen?';
  }

  @override
  String graduationProposeBody(String name) {
    return 'Sobald $name bestätigt, seid ihr beide in Entdecken ausgeblendet. Dieser Chat bleibt offen, und du kannst jederzeit über Privatsphäre & Sicherheit zu Entdecken zurückkehren.';
  }

  @override
  String get graduationNoteLabel => 'Eine Notiz für dein Match (optional)';

  @override
  String get graduationNoteHint => 'Sag, warum du bereit bist';

  @override
  String get graduationTellFriends => 'Meinen Freunden Bescheid sagen';

  @override
  String get graduationTellFriendsBody =>
      'Deine bestätigten Freunde erfahren, dass du jemanden gefunden hast – aber nicht, wen.';

  @override
  String get graduationAskThem => 'Fragen';

  @override
  String get graduationTitle => 'Gemeinsamer Abschied';

  @override
  String graduationCelebrationBody(String name) {
    return 'Du und $name verlasst Connect gemeinsam. Ihr seid beide in Entdecken ausgeblendet, und dieser Chat bleibt offen, so lange ihr wollt.';
  }

  @override
  String get graduationFriendsHaveBeenTold => 'Deine Freunde wissen Bescheid.';

  @override
  String get graduationFriendsAreTold => 'Deine Freunde werden informiert.';

  @override
  String get graduationOnlyTwoOfYou => 'Nur ihr beide wisst davon.';

  @override
  String get graduationConfirmAndBack => 'Bestätigen und zurück';

  @override
  String get graduationBackToConnect => 'Zurück zu Connect';

  @override
  String get graduationLoadFailed =>
      'Der gemeinsame Abschied konnte nicht geladen werden.';

  @override
  String get graduationProposeFailed =>
      'Der Vorschlag, gemeinsam zu gehen, konnte nicht gesendet werden.';

  @override
  String get graduationConfirmFailed => 'Bestätigen ist gerade nicht möglich.';

  @override
  String get graduationDeclineFailed => 'Ablehnen ist gerade nicht möglich.';

  @override
  String get graduationWithdrawFailed =>
      'Der Vorschlag konnte nicht zurückgezogen werden.';

  @override
  String get graduationPauseLoadFailed =>
      'Der Status von Entdecken konnte nicht geladen werden.';

  @override
  String get graduationPauseFailed => 'Entdecken konnte nicht pausiert werden.';

  @override
  String get graduationResumeFailed =>
      'Entdecken konnte nicht fortgesetzt werden.';

  @override
  String get engagementCirclesEmptyTitle => 'Keine Kreise verfügbar';

  @override
  String get engagementCirclesPullToRefresh =>
      'Zum Aktualisieren nach unten ziehen.';

  @override
  String get engagementCirclesJoined => 'Dabei';

  @override
  String get engagementCirclesNotJoined => 'Nicht dabei';

  @override
  String engagementCirclesParticipants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen machen diese Woche mit',
      one: '1 Person macht diese Woche mit',
    );
    return '$_temp0';
  }

  @override
  String get engagementCirclesJoin => 'Kreis beitreten';

  @override
  String get engagementCirclesResponseLabel =>
      'Deine Antwort auf die Wochen-Challenge';

  @override
  String get engagementCirclesSubmit => 'Beitrag einreichen';

  @override
  String get engagementCirclesTopicFallback => 'Kreis';

  @override
  String get engagementCirclesLoadFailed =>
      'Die Kreise können gerade nicht geladen werden.';

  @override
  String get engagementCirclesJoinFailed =>
      'Du kannst dem Kreis gerade nicht beitreten.';

  @override
  String get engagementCirclesEnterResponse =>
      'Bitte schreib deine Antwort auf die Challenge.';

  @override
  String get engagementCirclesSubmitFailed =>
      'Dein Beitrag kann gerade nicht eingereicht werden.';

  @override
  String get engagementNudgesTitle => 'Match-Anstupser';

  @override
  String get engagementNudgesIntro =>
      'Schick eine freundliche Erinnerung, um ein eingeschlafenes Gespräch wieder anzustoßen. Tageslimits und Sicherheitsregeln werden vom Server durchgesetzt.';

  @override
  String get engagementNudgesEmpty => 'Keine Matches zum Anstupsen.';

  @override
  String get engagementNudgesSentInSession => 'In dieser Sitzung angestupst';

  @override
  String get engagementNudgesReady => 'Bereit zum Senden';

  @override
  String engagementNudgesSentTo(String name) {
    return '$name wurde angestupst.';
  }

  @override
  String get engagementNudgesAction => 'Anstupsen';

  @override
  String get engagementNudgesSendFailed =>
      'Dieser Anstupser konnte nicht gesendet werden.';

  @override
  String get engagementTrustBadgesEarned => 'Verdiente Abzeichen';

  @override
  String get engagementTrustBadgesEmpty =>
      'Noch keine Abzeichen. Schließ Aktivitäten ab, um Vertrauensabzeichen freizuschalten.';

  @override
  String engagementTrustBadgesDetails(
    String code,
    String status,
    String awardedAt,
  ) {
    return 'Code: $code\nStatus: $status • Verliehen $awardedAt';
  }

  @override
  String get engagementTrustBadgesHistory => 'Letzter Verlauf';

  @override
  String get engagementTrustBadgesHistoryEmpty =>
      'Noch kein Vertrauensverlauf vorhanden.';

  @override
  String get engagementTrustBadgesMilestoneUnavailable =>
      'Meilensteinstatus nicht verfügbar.';

  @override
  String get engagementTrustBadgesCurrentMilestone => 'Aktueller Meilenstein';

  @override
  String get engagementTrustBadgesLoadFailed =>
      'Vertrauensabzeichen konnten nicht geladen werden. Bitte versuch es noch einmal.';

  @override
  String get engagementTrustFiltersEnable => 'Vertrauensfilter aktivieren';

  @override
  String get engagementTrustFiltersEnableSubtitle =>
      'Profile ausblenden, die deine Vertrauensanforderungen nicht erfüllen';

  @override
  String engagementTrustFiltersMinimum(int count) {
    return 'Mindestanzahl aktiver Abzeichen: $count';
  }

  @override
  String get engagementTrustFiltersRequired => 'Erforderliche Abzeichen';

  @override
  String get engagementTrustFiltersSaved => 'Vertrauensfilter gespeichert.';

  @override
  String get engagementTrustFiltersSave => 'Vertrauensfilter speichern';

  @override
  String get engagementAppealStatusSubmitted => 'Eingereicht';

  @override
  String get engagementAppealStatusUnderReview => 'In Prüfung';

  @override
  String get engagementAppealStatusResolvedUpheld =>
      'Abgeschlossen (bestätigt)';

  @override
  String get engagementAppealStatusResolvedReversed =>
      'Abgeschlossen (aufgehoben)';

  @override
  String get engagementRoomsLeaveFailed =>
      'Du konntest den Raum nicht verlassen. Bitte versuche es erneut.';

  @override
  String get engagementRoomsPresenceFailed =>
      'Die Verbindung zum Raum ist abgebrochen.';

  @override
  String get engagementRoomsMembersFailed =>
      'Wer da ist, konnte nicht geladen werden. Bitte versuche es erneut.';

  @override
  String get engagementRoomsModerationFailed =>
      'Das hat nicht geklappt. Bitte versuche es erneut.';

  @override
  String get engagementRoomsCreateFailed =>
      'Der Raum konnte nicht gestartet werden. Bitte versuche es erneut.';

  @override
  String get engagementRoomsLoadFailed =>
      'Räume sind gerade nicht verfügbar. Zum erneuten Laden nach unten ziehen.';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonRemove => 'Entfernen';

  @override
  String get accountTitle => 'Konto & Daten';

  @override
  String get accountLoadFailed =>
      'Dein Kontostatus konnte nicht geladen werden.';

  @override
  String accountDeletionIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Löschung in $days Tagen',
      one: 'Löschung in 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get accountDeletionDue => 'Die Löschung steht an';

  @override
  String get accountDeletionCountdownBody =>
      'Dein Profil ist ausgeblendet. Bis dahin kannst du dich noch anmelden und abbrechen – danach lassen sich deine Daten nicht wiederherstellen.';

  @override
  String get accountKeepMyAccount => 'Mein Konto behalten';

  @override
  String get accountNotDeletedSnack => 'Dein Konto wird nicht gelöscht.';

  @override
  String get accountCancelFailed =>
      'Abbrechen nicht möglich. Bitte versuch es erneut.';

  @override
  String get accountHiddenTitle => 'Dein Profil ist ausgeblendet';

  @override
  String get accountTakeBreakTitle => 'Mach eine Pause';

  @override
  String get accountHiddenBody =>
      'Niemand kann dich sehen oder mit dir matchen. Deine Matches und Nachrichten bleiben erhalten, und du kannst jederzeit zurückkommen.';

  @override
  String get accountTakeBreakBody =>
      'Blende dein Profil in Entdecken aus, ohne etwas zu verlieren. Du bleibst angemeldet und kannst jederzeit zurückwechseln.';

  @override
  String get accountUnhideProfile => 'Mein Profil wieder anzeigen';

  @override
  String get accountHideProfile => 'Mein Profil ausblenden';

  @override
  String get accountVisibleAgainSnack => 'Dein Profil ist wieder sichtbar.';

  @override
  String get accountNowHiddenSnack => 'Dein Profil ist jetzt ausgeblendet.';

  @override
  String get accountUpdateFailed =>
      'Aktualisierung fehlgeschlagen. Bitte versuch es erneut.';

  @override
  String get accountDownloadTitle => 'Deine Daten herunterladen';

  @override
  String get accountDownloadBody =>
      'Erhalte eine Kopie deines Profils, deiner Präferenzen, Matches und der Nachrichten, die du gesendet hast. Nachrichten anderer sind nicht enthalten.';

  @override
  String get accountPreparing => 'Wird vorbereitet…';

  @override
  String get accountPrepareData => 'Meine Daten vorbereiten';

  @override
  String get accountPrepareFailed =>
      'Deine Daten konnten nicht vorbereitet werden. Bitte versuch es erneut.';

  @override
  String get accountYourData => 'Deine Daten';

  @override
  String get accountDeleteTitle => 'Mein Konto löschen';

  @override
  String get accountDeleteBody =>
      'Dein Profil wird sofort ausgeblendet und nach einer Schonfrist wird alles gelöscht. In dieser Zeit kannst du dich anmelden und abbrechen. Danach lässt sich nichts wiederherstellen.';

  @override
  String get accountDeletionAlreadyScheduled => 'Löschung bereits geplant';

  @override
  String get accountDeleteConfirmTitle => 'Dein Konto löschen?';

  @override
  String get accountDeleteConfirmBody =>
      'Dein Profil, deine Fotos, Matches und Nachrichten werden gelöscht und können nicht wiederhergestellt werden.\n\nWenn du nur eine Pause willst: Wenn du dein Profil ausblendest, bleibt alles erhalten und lässt sich rückgängig machen.';

  @override
  String get accountHideInstead => 'Stattdessen ausblenden';

  @override
  String get accountDeletionScheduledSnack =>
      'Löschung geplant. Bis dahin kannst du sie abbrechen.';

  @override
  String get privacyTitle => 'Privatsphäre & Sicherheit';

  @override
  String get privacyShowAge => 'Alter anzeigen';

  @override
  String get privacyShowAgeSubtitle => 'Lege fest, ob dein Alter sichtbar ist';

  @override
  String get privacyShowDistance => 'Genaue Entfernung anzeigen';

  @override
  String get privacyShowDistanceSubtitle =>
      'Zeige die genaue Entfernung in deinem Profil';

  @override
  String get privacyShowOnline => 'Online-Status anzeigen';

  @override
  String get privacyShowOnlineSubtitle =>
      'Andere sehen lassen, ob du online bist';

  @override
  String get privacyEmergencySos => 'Notfall-SOS';

  @override
  String get privacyEmergencySosSubtitle =>
      'Alarm auslösen und Alarmverlauf ansehen';

  @override
  String get privacyEmergencyContacts => 'Notfallkontakte';

  @override
  String get privacyEmergencyContactsSubtitle =>
      'Vertrauenswürdige Notfallkontakte verwalten';

  @override
  String get privacyBlockedUsers => 'Blockierte Personen';

  @override
  String get privacyBlockedUsersSubtitle => 'Blockierte ansehen und entsperren';

  @override
  String get privacyModerationAppeals => 'Einsprüche gegen Moderation';

  @override
  String get privacyModerationAppealsSubtitle =>
      'Einspruch einlegen und Prüfstatus verfolgen';

  @override
  String get privacyFriendSearch => 'In der Freundessuche auffindbar sein';

  @override
  String get privacySettingLoadFailed =>
      'Diese Einstellung konnte nicht geladen werden. Öffne die Seite erneut, um es noch einmal zu versuchen.';

  @override
  String get privacyFriendSearchSubtitle =>
      'Mitglieder finden dich unter „Freund hinzufügen“ über deinen Namen oder @Nutzernamen. Leute, mit denen du matchst oder die du in Räumen und Gruppen triffst, können dich trotzdem hinzufügen.';

  @override
  String get privacyChoiceSaveFailed =>
      'Deine Auswahl konnte nicht gespeichert werden.';

  @override
  String get privacyShowcase =>
      'Meine öffentlichen Texte in meinem Profil zeigen';

  @override
  String get privacyShowcaseSubtitle =>
      'Mitglieder sehen in deinem Profil die Kapitel, die du mit der Community teilst, und deine Fotos an der Wand. Private Kapitel und Kapitel nur für Freunde erscheinen nie.';

  @override
  String get privacyCrashReports => 'Absturzberichte teilen';

  @override
  String get privacyCrashReportsSubtitle =>
      'Anonyme Absturz- und Fehlerberichte helfen uns, Probleme zu beheben. Nachrichten, Fotos und Kontodaten sind nicht enthalten.';

  @override
  String get privacyGraduatedReason =>
      'Du hast Connect mit deinem Match verlassen. Deine Karte wird niemandem gezeigt.';

  @override
  String get privacyPausedReason =>
      'Deine Karte wird niemandem gezeigt, bis du fortsetzt.';

  @override
  String get privacyActiveReason =>
      'Du wirst anderen Mitgliedern beim Entdecken angezeigt.';

  @override
  String get privacyDiscoveryPaused => 'Entdecken pausiert';

  @override
  String get privacyDiscoveryActive => 'Entdecken aktiv';

  @override
  String get privacyResume => 'Fortsetzen';

  @override
  String get privacyPause => 'Pausieren';

  @override
  String get emergencyIntro =>
      'Füge bis zu 3 vertrauenswürdige Kontakte hinzu. Sie werden künftig für Sicherheitsabläufe und SOS-Funktionen genutzt.';

  @override
  String get emergencyEmpty => 'Noch keine Notfallkontakte hinzugefügt.';

  @override
  String get emergencyMaxReached => 'Maximale Anzahl erreicht';

  @override
  String get emergencyAddContact => 'Kontakt hinzufügen';

  @override
  String get emergencyEditContact => 'Kontakt bearbeiten';

  @override
  String get emergencyInvalidInput =>
      'Gib einen gültigen Namen und eine gültige Telefonnummer ein.';

  @override
  String get emergencyAdded => 'Notfallkontakt hinzugefügt.';

  @override
  String get emergencyAddFailed =>
      'Kontakt konnte nicht hinzugefügt werden. Bitte versuch es erneut.';

  @override
  String get emergencyUpdated => 'Notfallkontakt aktualisiert.';

  @override
  String get emergencyUpdateFailed =>
      'Kontakt konnte nicht aktualisiert werden. Bitte versuch es erneut.';

  @override
  String get emergencyRemoveTitle => 'Kontakt entfernen';

  @override
  String emergencyRemoveBody(String name) {
    return '$name aus den Notfallkontakten entfernen?';
  }

  @override
  String get emergencyRemoved => 'Notfallkontakt entfernt.';

  @override
  String get emergencyRemoveFailed =>
      'Kontakt konnte nicht entfernt werden. Bitte versuch es erneut.';

  @override
  String get emergencyNameLabel => 'Name';

  @override
  String get emergencyPhoneLabel => 'Telefonnummer';

  @override
  String get appealsSubmitTitle => 'Einspruch einlegen';

  @override
  String get appealsReasonLabel => 'Grund';

  @override
  String get appealsReasonHint =>
      'Warum sollte diese Moderationsentscheidung überprüft werden?';

  @override
  String get appealsReportIdLabel => 'Meldungs-ID (optional)';

  @override
  String get appealsContextLabel => 'Weitere Infos (optional)';

  @override
  String get appealsSubmit => 'Einspruch senden';

  @override
  String get appealsEmpty =>
      'Noch keine Einsprüche. Deine Einsprüche erscheinen hier mit Statusupdates.';

  @override
  String appealsIdLine(String id) {
    return 'Einspruchs-ID: $id';
  }

  @override
  String appealsSlaLine(String deadline) {
    return 'Bearbeitungsfrist: $deadline';
  }

  @override
  String appealsReviewedBy(String reviewer) {
    return 'Geprüft von: $reviewer';
  }

  @override
  String get appealsReasonRequired => 'Bitte gib einen Grund an.';

  @override
  String get appealsSubmitted => 'Einspruch erfolgreich gesendet.';

  @override
  String get appealsSubmitFailed =>
      'Einspruch konnte nicht gesendet werden. Bitte versuch es erneut.';

  @override
  String get blockedEmpty => 'Du hast niemanden blockiert.';

  @override
  String get blockedUnblock => 'Entsperren';

  @override
  String get blockedUnblockTitle => 'Person entsperren';

  @override
  String blockedUnblockBody(String name) {
    return '$name entsperren?';
  }

  @override
  String blockedUnblockedSnack(String name) {
    return '$name wurde entsperrt.';
  }

  @override
  String get blockedUnblockFailed =>
      'Entsperren fehlgeschlagen. Bitte versuch es erneut.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutDescription =>
      'Dating-App, die auf Vertrauen setzt: echte Profile, sichere Kommunikation und ernsthafte Beziehungen.';

  @override
  String get aboutStack => 'Technik';

  @override
  String get aboutStackFlutter => 'Flutter (Android zuerst)';

  @override
  String get aboutStackGo => 'Go-Dienste + natives PostgreSQL';

  @override
  String get aboutStackRiverpod => 'Riverpod für State-Management';

  @override
  String get communitySpoiler => 'Spoiler – zum Anzeigen tippen';

  @override
  String get communityReportFailed =>
      'Die Meldung konnte nicht gesendet werden.';

  @override
  String get communityReportSubmitted => 'Meldung gesendet. Danke!';

  @override
  String communityBlockTitle(String name) {
    return '$name blockieren?';
  }

  @override
  String get communityBlockBody =>
      'Ihr seht dann gegenseitig keine Fotos, Clubbeiträge, Bewertungen und Listen mehr. Außerdem wird der Kontakt über Connect blockiert.';

  @override
  String get communityBlockAction => 'Mitglied blockieren';

  @override
  String get communityBlockFailed =>
      'Dieses Mitglied konnte nicht blockiert werden. Bitte versuch es erneut.';

  @override
  String get reportSheetTitle => 'Melden';

  @override
  String get reportReasonHarassment => 'Belästigung';

  @override
  String get reportReasonInappropriate => 'Unangemessene Inhalte';

  @override
  String get reportReasonFraud => 'Betrug / Abzocke';

  @override
  String get reportReasonFake => 'Fake-Profil';

  @override
  String get reportReasonLabel => 'Grund';

  @override
  String get reportDescriptionLabel => 'Beschreibung (optional)';

  @override
  String get reportDescriptionHint =>
      'Füge Details hinzu, damit wir deine Meldung prüfen können';

  @override
  String get reportSubmitFailed =>
      'Meldung konnte nicht gesendet werden. Bitte versuch es erneut.';

  @override
  String get reportSubmit => 'Meldung senden';

  @override
  String get membershipTitle => 'Mitgliedschaft';

  @override
  String get membershipChooseYourPlan => 'Wähle deinen Plan';

  @override
  String get membershipCycleNoteMonthly =>
      'Bezahlung per Karte. Verlängert sich jeden Monat automatisch, bis du es ausschaltest.';

  @override
  String get membershipCycleNoteYearly =>
      'Bezahlung per Karte. Verlängert sich jedes Jahr automatisch, bis du es ausschaltest.';

  @override
  String get membershipNoPlansOnSale => 'Derzeit sind keine Pläne erhältlich.';

  @override
  String get membershipPaymentsTitle => 'Zahlungen';

  @override
  String get membershipNoCardPayments => 'Noch keine Kartenzahlungen.';

  @override
  String get membershipFooterNote =>
      'Dein Plan verlängert sich am Ende jedes Abrechnungszeitraums automatisch. Du kannst die automatische Verlängerung jederzeit ausschalten; deine Vorteile bleiben bis zum Ende des Zeitraums erhalten. Kartendaten werden vom Zahlungsanbieter verarbeitet und nie in der App gespeichert.';

  @override
  String membershipSwitchTitle(String plan) {
    return 'Zu $plan wechseln?';
  }

  @override
  String membershipSwitchUpgradeBodyMonthly(String price) {
    return 'Deine Karte wird jetzt mit der Differenz für den Rest dieses Zeitraums belastet, ab der nächsten Verlängerung dann mit $price pro Monat.';
  }

  @override
  String membershipSwitchUpgradeBodyYearly(String price) {
    return 'Deine Karte wird jetzt mit der Differenz für den Rest dieses Zeitraums belastet, ab der nächsten Verlängerung dann mit $price pro Jahr.';
  }

  @override
  String membershipSwitchDowngradeBodyMonthly(
    String currentPlan,
    String price,
  ) {
    return 'Dein Plan ändert sich sofort. Ungenutzte Zeit von $currentPlan wird auf deine nächste Verlängerung angerechnet, danach zahlst du $price pro Monat.';
  }

  @override
  String membershipSwitchDowngradeBodyYearly(String currentPlan, String price) {
    return 'Dein Plan ändert sich sofort. Ungenutzte Zeit von $currentPlan wird auf deine nächste Verlängerung angerechnet, danach zahlst du $price pro Jahr.';
  }

  @override
  String get membershipNotNow => 'Nicht jetzt';

  @override
  String get membershipUpgrade => 'Upgraden';

  @override
  String get membershipSwitchPlan => 'Plan wechseln';

  @override
  String membershipSwitchedSnack(String plan) {
    return 'Du hast jetzt $plan.';
  }

  @override
  String get membershipCardUpdated => 'Deine Karte wurde aktualisiert.';

  @override
  String get membershipCardUpdatePending =>
      'Kartenaktualisierung noch nicht bestätigt. Prüfe den Status, bevor du es erneut versuchst.';

  @override
  String get membershipCardUpdateEnded =>
      'Diese Sitzung zur Kartenaktualisierung ist beendet. Aktualisiere, um deine aktuelle Karte zu sehen.';

  @override
  String get membershipCheckoutTitleCard => 'deine Karte';

  @override
  String get membershipAutoRenewOffTitle =>
      'Automatische Verlängerung ausschalten?';

  @override
  String membershipAutoRenewOffBodyDate(String plan, String date) {
    return 'Deine $plan-Vorteile bleiben bis zum $date aktiv. Danach wechselst du in den kostenlosen Plan und deine Karte wird nicht mehr belastet.';
  }

  @override
  String membershipAutoRenewOffBodyPeriodEnd(String plan) {
    return 'Deine $plan-Vorteile bleiben bis zum Ende des aktuellen Zeitraums aktiv. Danach wechselst du in den kostenlosen Plan und deine Karte wird nicht mehr belastet.';
  }

  @override
  String get membershipKeepRenewing => 'Weiter verlängern';

  @override
  String get membershipTurnOff => 'Ausschalten';

  @override
  String get membershipAutoRenewBackOn =>
      'Die automatische Verlängerung ist wieder an.';

  @override
  String get membershipAutoRenewNowOff =>
      'Die automatische Verlängerung ist aus. Deine Vorteile bleiben bis zum Ende des Zeitraums erhalten.';

  @override
  String membershipSubscribeTitle(String plan) {
    return '$plan abonnieren';
  }

  @override
  String membershipSubscribeBodyMonthly(String price) {
    return '$price pro Monat, von deiner Karte abgebucht und automatisch verlängert, bis du die automatische Verlängerung ausschaltest. Deine Karte gibst du auf der sicheren Seite des Zahlungsanbieters ein.';
  }

  @override
  String membershipSubscribeBodyYearly(String price) {
    return '$price pro Jahr, von deiner Karte abgebucht und automatisch verlängert, bis du die automatische Verlängerung ausschaltest. Deine Karte gibst du auf der sicheren Seite des Zahlungsanbieters ein.';
  }

  @override
  String membershipSubscribeBodyTestMonthly(String price) {
    return 'Nur Test-Checkout – keine echte Abbuchung. $price pro Monat, simuliert und automatisch verlängert, bis du die automatische Verlängerung ausschaltest. Deine Karte gibst du auf der sicheren Seite des Zahlungsanbieters ein.';
  }

  @override
  String membershipSubscribeBodyTestYearly(String price) {
    return 'Nur Test-Checkout – keine echte Abbuchung. $price pro Jahr, simuliert und automatisch verlängert, bis du die automatische Verlängerung ausschaltest. Deine Karte gibst du auf der sicheren Seite des Zahlungsanbieters ein.';
  }

  @override
  String get membershipContinueToCard => 'Weiter zur Karteneingabe';

  @override
  String get paymentStillConfirming =>
      'Die Zahlung wird noch bestätigt. Zieh gleich zum Aktualisieren nach unten.';

  @override
  String get membershipCheckoutEnded =>
      'Diese Checkout-Sitzung ist beendet. Aktualisiere deinen Zahlungsverlauf, bevor du es erneut versuchst.';

  @override
  String get membershipRecoverAccountUnavailable =>
      'Das Zahlungskonto konnte nicht geprüft werden. Bitte versuch es noch einmal.';

  @override
  String get membershipRecoverCheckoutClosed =>
      'Zahlungskonto aktualisiert. Dieser Checkout ist nicht mehr offen.';

  @override
  String get membershipRecoverConfirmed =>
      'Bestätigt. Dein Zahlungskonto ist auf dem neuesten Stand.';

  @override
  String get membershipRecoverPending =>
      'Die Bestätigung steht noch aus. Du kannst hier erneut nachsehen.';

  @override
  String get membershipRecoverEnded =>
      'Diese Checkout-Sitzung ist beendet. Prüfe deinen Zahlungsverlauf, bevor du einen neuen startest.';

  @override
  String membershipCelebrateTitle(String plan) {
    return 'Du bist jetzt $plan';
  }

  @override
  String get membershipCelebrateBodyTest =>
      'Testzahlung bestätigt; es wurde kein echtes Geld abgebucht. Dein Testplan verlängert sich automatisch. Die automatische Verlängerung kannst du jederzeit auf diesem Bildschirm verwalten.';

  @override
  String get membershipCelebrateBody =>
      'Zahlung bestätigt. Dein Plan verlängert sich automatisch. Die automatische Verlängerung kannst du jederzeit auf diesem Bildschirm verwalten.';

  @override
  String get membershipStartExploring => 'Jetzt entdecken';

  @override
  String get membershipYourMembership => 'Deine Mitgliedschaft';

  @override
  String get membershipYourPlan => 'Dein Plan';

  @override
  String get membershipFreePlanName => 'Kostenlos';

  @override
  String membershipPricePerMonthShort(String price) {
    return '$price/Monat';
  }

  @override
  String membershipPricePerYearShort(String price) {
    return '$price/Jahr';
  }

  @override
  String get membershipCardOnFile => 'Karte beim Zahlungsanbieter hinterlegt';

  @override
  String get membershipCardBrandFallback => 'Karte';

  @override
  String get paymentOpening => 'Wird geöffnet…';

  @override
  String get membershipUpdateCard => 'Karte ändern';

  @override
  String get membershipLastPaymentFailed =>
      'Die letzte Zahlung ist fehlgeschlagen. Wir versuchen es erneut mit deiner Karte; deine Vorteile bleiben noch ein paar Tage aktiv.';

  @override
  String membershipRenewsOn(String date) {
    return 'Verlängert sich am $date';
  }

  @override
  String get membershipRenewsSoon => 'Verlängert sich bald';

  @override
  String membershipEndsOn(String date) {
    return 'Endet am $date · automatische Verlängerung aus';
  }

  @override
  String get membershipEndsSoon => 'Endet bald · automatische Verlängerung aus';

  @override
  String get membershipAutoRenew => 'Automatische Verlängerung';

  @override
  String get membershipAutoRenewOnSubtitle =>
      'Wird in jedem Zeitraum automatisch abgebucht.';

  @override
  String get membershipAutoRenewOffSubtitle =>
      'Aus. Die Vorteile enden mit dem aktuellen Zeitraum.';

  @override
  String get membershipFreeHeroBody =>
      'Schalte mit einem Plan unten mehr Likes, Nachrichten und Spotlight frei. Zahlung per Karte, jederzeit kündbar.';

  @override
  String get membershipStatusFree => 'Kostenlos';

  @override
  String get membershipStatusPaymentDue => 'Zahlung fällig';

  @override
  String get membershipStatusEnding => 'Läuft aus';

  @override
  String get membershipStatusActive => 'Aktiv';

  @override
  String get membershipCycleMonthly => 'Monatlich';

  @override
  String get membershipCycleYearly => 'Jährlich';

  @override
  String get membershipBadgeYourPlan => 'DEIN PLAN';

  @override
  String get membershipBadgeMostPopular => 'AM BELIEBTESTEN';

  @override
  String get membershipPerMonth => 'pro Monat';

  @override
  String get membershipPerYear => 'pro Jahr';

  @override
  String membershipSavePercent(int percent) {
    return '$percent % sparen';
  }

  @override
  String membershipQuotaLikesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Likes/Tag',
      one: '1 Like/Tag',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nachrichten/Tag',
      one: '1 Nachricht/Tag',
    );
    return '$_temp0';
  }

  @override
  String get membershipQuotaUnlimitedLikes => 'Unbegrenzte Likes';

  @override
  String get membershipQuotaUnlimitedMessages => 'Unbegrenzte Nachrichten';

  @override
  String get membershipYourCurrentPlan => 'Dein aktueller Plan';

  @override
  String get membershipSwitching => 'Wird gewechselt…';

  @override
  String get membershipOpeningSecureCheckout =>
      'Sicherer Checkout wird geöffnet…';

  @override
  String membershipSwitchToPlan(String plan) {
    return 'Zu $plan wechseln';
  }

  @override
  String get membershipSubscribeWithCard => 'Mit Karte abonnieren';

  @override
  String get membershipSettleBeforeSwitch =>
      'Begleiche vor dem Wechsel die offene Zahlung für deinen aktuellen Plan.';

  @override
  String get membershipPaymentChargeback => 'Rückbuchung';

  @override
  String get membershipPaymentDisputed => 'Angefochten';

  @override
  String get membershipPaymentRefunded => 'Erstattet';

  @override
  String get membershipPaymentPartlyRefunded => 'Teilweise erstattet';

  @override
  String get membershipPaymentFailed => 'Fehlgeschlagen';

  @override
  String get membershipPaymentPaid => 'Bezahlt';

  @override
  String get membershipPaymentPending => 'Ausstehend';

  @override
  String get membershipPaymentReasonFirstCharge => 'Erste Abbuchung';

  @override
  String get membershipPaymentReasonRenewal => 'Verlängerung';

  @override
  String get membershipPaymentReasonPlanChange => 'Planwechsel';

  @override
  String get membershipPaymentReasonCoins => 'Münzen';

  @override
  String get membershipPaymentReasonLocalActivation => 'Lokale Aktivierung';

  @override
  String get membershipPaymentReasonCard => 'Kartenzahlung';

  @override
  String get membershipPaymentReasonOther => 'Zahlung';

  @override
  String get paymentModeSandbox => 'Lokaler Test · keine echte Abbuchung';

  @override
  String get paymentModeStripeTest => 'Stripe-Test · keine echte Abbuchung';

  @override
  String get paymentModeLive => 'Echte Zahlungen';

  @override
  String get paymentModeUnavailable => 'Zahlungen nicht verfügbar';

  @override
  String get paymentAccountTitle => 'Dein Zahlungskonto';

  @override
  String get paymentAccountSignedInMember => 'Angemeldetes Mitglied';

  @override
  String get paymentAccountCardTitle => 'Kredit- oder Debitkarte';

  @override
  String get paymentAccountCardUnavailableTitle =>
      'Kartenzahlung ist nicht verfügbar';

  @override
  String get paymentAccountCardBody =>
      'Gib deine Karte im gehosteten Checkout ein. Mitgliedschaft und Zahlungsverlauf gehören zu diesem Konto.';

  @override
  String get paymentAccountCardUnavailableBody =>
      'Du kannst dein bestehendes Konto weiter nutzen. Neue Kartenzahlungen sind nicht aktiviert.';

  @override
  String paymentAccountTestCardHint(String cardNumber) {
    return 'Verwende zum Testen $cardNumber, ein Ablaufdatum in der Zukunft und eine beliebige dreistellige CVC. Verwende nur Testdaten.';
  }

  @override
  String get paymentAccountUnfinishedCardUpdate =>
      'Nicht abgeschlossene Kartenänderung';

  @override
  String paymentAccountUnfinishedCheckout(String plan) {
    return 'Nicht abgeschlossener Checkout: $plan';
  }

  @override
  String get paymentAccountPendingHint =>
      'Prüfe den aktuellen Status oder setze denselben Checkout fort.';

  @override
  String get paymentAccountCheckStatus => 'Status prüfen';

  @override
  String get paymentAccountResumeCheckout => 'Checkout fortsetzen';

  @override
  String paymentCheckoutPayFor(String title) {
    return 'Bezahlen: $title';
  }

  @override
  String get paymentCheckoutClose => 'Checkout schließen';

  @override
  String get paymentCheckoutSecureNote =>
      'Kartendaten werden auf der sicheren Seite des Zahlungsanbieters eingegeben.';

  @override
  String paymentCheckoutCompleteInNewTab(String title) {
    return 'Schließe den Bezahlvorgang ($title) im neuen Tab ab';
  }

  @override
  String get paymentCheckoutWaitingBody =>
      'Deine Kartendaten gibst du auf der sicheren Seite des Zahlungsanbieters ein. Komm hierher zurück, wenn dort steht, dass die Zahlung abgeschlossen ist.';

  @override
  String get paymentCheckoutCheckConfirmation => 'Bestätigung prüfen';

  @override
  String get paymentCheckoutBackToAccount => 'Zurück zum Konto';

  @override
  String get paymentWalletTitle => 'Wallet & Zahlungen';

  @override
  String get paymentWalletTestNote =>
      'Testzahlungen · keine echte Abbuchung. Verwende nur Testkartendaten.';

  @override
  String get paymentWalletPopularTopUps => 'Beliebte Aufladungen';

  @override
  String get paymentWalletTopUpsIntro =>
      'Bezahle per Karte auf der sicheren Checkout-Seite. Die Münzen landen in deinem Wallet, sobald die Zahlung abgeschlossen ist.';

  @override
  String get paymentWalletCardsDisabled =>
      'Kartenzahlungen sind auf diesem Server noch nicht aktiviert.';

  @override
  String get paymentWalletNoPacks =>
      'Derzeit sind keine Münzpakete erhältlich.';

  @override
  String get paymentWalletActivity => 'Wallet-Aktivität';

  @override
  String get paymentWalletNoPurchases => 'Noch keine Münzkäufe.';

  @override
  String get paymentWalletFooter =>
      'Münzen kannst du in Connect für Geschenke und Boosts verwenden. Käufe sind nach Abschluss endgültig; Kartendaten bleiben beim Zahlungsanbieter.';

  @override
  String paymentCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Münzen',
      one: '1 Münze',
    );
    return '$_temp0';
  }

  @override
  String paymentCoinsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Münzen wurden deinem Wallet gutgeschrieben.',
      one: '1 Münze wurde deinem Wallet gutgeschrieben.',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Münzen',
      one: 'Münze',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnitBonus(int count, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Münzen · +$bonus Bonus',
      one: 'Münze · +$bonus Bonus',
    );
    return '$_temp0';
  }

  @override
  String get paymentWalletCheckoutEnded =>
      'Diese Checkout-Sitzung ist beendet. Prüfe deinen Zahlungsverlauf, bevor du es erneut versuchst.';

  @override
  String get paymentWalletBalanceLabel => 'Glow-Wallet-Guthaben';

  @override
  String get paymentWalletSourceSupport => 'Aufladung durch den Support';

  @override
  String get paymentWalletSourcePromo => 'Aktion';

  @override
  String get paymentWalletSourcePurchase => 'Münzkauf';

  @override
  String get paymentErrorSignInSubscriptions =>
      'Bitte melde dich an, um Abos zu verwalten.';

  @override
  String get paymentErrorSignInWallet =>
      'Bitte melde dich an, um dein Wallet zu verwalten.';

  @override
  String get paymentErrorLoadSubscription =>
      'Abo-Details konnten nicht geladen werden.';

  @override
  String get paymentErrorLoadWallet =>
      'Dein Wallet konnte nicht geladen werden.';

  @override
  String get paymentErrorStartCheckoutNow =>
      'Der Checkout kann gerade nicht gestartet werden.';

  @override
  String get paymentErrorStartCheckout =>
      'Checkout konnte nicht gestartet werden.';

  @override
  String get paymentErrorConfirmPayment =>
      'Die Zahlung kann noch nicht bestätigt werden.';

  @override
  String get paymentErrorAutoRenewOn =>
      'Die automatische Verlängerung konnte nicht wieder eingeschaltet werden.';

  @override
  String get paymentErrorAutoRenewOff =>
      'Die automatische Verlängerung konnte nicht ausgeschaltet werden.';

  @override
  String get paymentErrorChangePlan =>
      'Der Plan konnte nicht gewechselt werden.';

  @override
  String get paymentErrorUpdateCard =>
      'Die Karte konnte nicht aktualisiert werden.';

  @override
  String get paymentErrorSandboxFailed => 'Sandbox-Simulation fehlgeschlagen.';

  @override
  String get paymentErrorUnreachable =>
      'Der lokale Dienst ist nicht erreichbar. Prüfe, ob die API läuft.';

  @override
  String membershipQuotaLikesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Heute noch $remaining von $limit Likes',
      one: 'Heute noch $remaining von 1 Like',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Heute noch $remaining von $limit Nachrichten',
      one: 'Heute noch $remaining von 1 Nachricht',
    );
    return '$_temp0';
  }

  @override
  String membershipLikeLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Du hast heute deine $limit Likes mit $plan verbraucht',
      one: 'Du hast heute dein 1 Like mit $plan verbraucht',
    );
    return '$_temp0';
  }

  @override
  String membershipMessageLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Du hast heute deine $limit Nachrichten mit $plan verbraucht',
      one: 'Du hast heute deine 1 Nachricht mit $plan verbraucht',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaResetsAt(String time) {
    return 'Wird um $time zurückgesetzt';
  }

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Matches',
      one: '$count Match',
    );
    return '$_temp0';
  }

  @override
  String get matchesSubtitleConversations =>
      'Ein Stückchen näher, eine Nachricht nach der anderen.';

  @override
  String get matchesSubtitlePeople =>
      'Menschen, die du gewählt hast. Möglichkeiten, die ihr gemeinsam gestaltet.';

  @override
  String get matchesSearchConversations => 'Unterhaltungen durchsuchen';

  @override
  String get matchesSearchMatches => 'Deine Matches durchsuchen';

  @override
  String get matchesFilterAllConversations => 'Alle Unterhaltungen';

  @override
  String matchesFilterUnread(int count) {
    return 'Ungelesen · $count';
  }

  @override
  String get matchesLoading => 'Matches werden geladen …';

  @override
  String get matchesLoadErrorTitle => 'Matches konnten nicht geladen werden';

  @override
  String get matchesRetry => 'Erneut versuchen';

  @override
  String get matchesEmptyTitle => 'Noch keine Matches';

  @override
  String matchesTrustFilteredHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Vertrauensfilter haben $count Matches ausgeblendet. Lockere die Vertrauensfilter unter Entdecken.',
      one:
          'Vertrauensfilter haben 1 Match ausgeblendet. Lockere die Vertrauensfilter unter Entdecken.',
    );
    return '$_temp0';
  }

  @override
  String get matchesEmptyBody =>
      'Schau bei Heute vorbei und entdecke jemanden, den du gern kennenlernen möchtest.';

  @override
  String get matchesNoConversationResults =>
      'Hier gibt es noch keine Unterhaltungen. Versuch es mit einer anderen Suche oder einem anderen Filter.';

  @override
  String get matchesNoPeopleResults =>
      'Keine Matches gefunden. Versuch es mit einem anderen Namen.';

  @override
  String get matchesTabPeople => 'Deine Matches';

  @override
  String get matchesTabConversations => 'Unterhaltungen';

  @override
  String get matchesActionStartCall => 'Anruf starten';

  @override
  String get matchesActionStartActivity => 'Aktivität starten';

  @override
  String get matchesActionPlanDate => 'Date planen';

  @override
  String get matchesActionPlanDateSubtitle =>
      'Wähle eine Zeit und was du teilen möchtest';

  @override
  String matchesPlanSent(String name) {
    return 'Plan an $name gesendet.';
  }

  @override
  String get matchesActionGraduate => 'Wir haben uns gefunden';

  @override
  String get matchesActionGraduateSubtitle =>
      'Verlasst Connect gemeinsam – euer Chat bleibt';

  @override
  String matchesGraduationAsked(String name) {
    return 'Anfrage an $name gesendet, Connect gemeinsam zu verlassen. Die Bestätigung ist in eurem Chat möglich.';
  }

  @override
  String get matchesActionNudge => 'Anstupsen';

  @override
  String matchesNudgeSent(String name) {
    return '$name wurde angestupst.';
  }

  @override
  String get matchesNudgeFailed => 'Anstupsen hat nicht geklappt.';

  @override
  String get matchesActionClose => 'Unterhaltung beenden';

  @override
  String get matchesActionCloseSubtitle => 'Schaffe Abstand – ohne Erklärung.';

  @override
  String get matchesCloseDialogTitle => 'Diese Unterhaltung beenden?';

  @override
  String get matchesCloseDialogBody =>
      'Es ist okay, wenn diese Verbindung nicht zu dir passt. Damit endet das Match. Du musst keine Erklärung schicken. Eine Meldung bleibt eine separate Entscheidung.';

  @override
  String get matchesCloseDialogKeep => 'Weiter schreiben';

  @override
  String get matchesActionReport => 'Melden';

  @override
  String get matchesReportSubmitted => 'Meldung gesendet. Danke.';

  @override
  String get matchesReportAppeal => 'Einspruch';

  @override
  String matchesAppealReason(String userId) {
    return 'Moderationsergebnis zur Meldung über Nutzer $userId prüfen';
  }

  @override
  String get matchesBothChose => 'Ihr habt euch beide füreinander entschieden';

  @override
  String matchesOptionsTooltip(String name) {
    return 'Match-Optionen für $name';
  }

  @override
  String matchesChatUnread(int count) {
    return 'Chat · $count ungelesen';
  }

  @override
  String get matchesOpenChat => 'Chat öffnen';

  @override
  String get matchesFirstChapter => 'First Chapter';

  @override
  String get matchesUnknownName => 'Unbekannt';

  @override
  String get matchesSayHi => 'Sag Hallo 👋';

  @override
  String get matchesFallbackName => 'Dein Match';

  @override
  String get matchesFallbackMessage => 'Beginne eure Unterhaltung';

  @override
  String get matchesGiftPreview => 'Ein kleines Geschenk in eurer Unterhaltung';

  @override
  String matchesConversationOptionsTooltip(String name) {
    return 'Optionen für die Unterhaltung mit $name';
  }

  @override
  String get matchesTimeNow => 'Jetzt';

  @override
  String matchesTimeMinutesAgo(int minutes) {
    return 'vor $minutes Min.';
  }

  @override
  String matchesTimeHoursAgo(int hours) {
    return 'vor $hours Std.';
  }

  @override
  String get matchesTimeToday => 'Heute';

  @override
  String get matchesTimeYesterday => 'Gestern';

  @override
  String get matchesNewMatchTitle => 'Neues Match';

  @override
  String get matchesItsAMatch => 'Es ist ein Match!';

  @override
  String matchesLikedEachOther(String name) {
    return 'Du und $name habt euch gegenseitig geliked';
  }

  @override
  String get matchesSendMessage => 'Nachricht senden';

  @override
  String get matchesKeepSwiping => 'Weiter swipen';

  @override
  String get matchesErrorLoginRequired =>
      'Bitte melde dich an, um deine Matches zu sehen.';

  @override
  String get matchesErrorLoadFailed =>
      'Matches konnten nicht geladen werden. Bitte versuch es erneut.';

  @override
  String get matchesErrorUnmatchFailed =>
      'Match konnte nicht aufgelöst werden.';

  @override
  String get matchesErrorMarkReadFailed =>
      'Konnte nicht als gelesen markiert werden.';

  @override
  String get matchesErrorSessionUnavailable =>
      'Deine Sitzung ist nicht verfügbar.';

  @override
  String get matchesTrustBadgePromptCompleter => 'Prompts beantwortet';

  @override
  String get matchesTrustBadgeRespectful => 'Respektvoll im Austausch';

  @override
  String get matchesTrustBadgeConsistent => 'Stimmiges Profil';

  @override
  String get matchesTrustBadgeVerifiedActive => 'Verifiziert & aktiv';

  @override
  String get matchesTrustErrorLoad =>
      'Vertrauensfilter konnten nicht geladen werden. Bitte versuch es erneut.';

  @override
  String get matchesTrustErrorSave =>
      'Vertrauensfilter konnten nicht gespeichert werden. Bitte versuch es erneut.';

  @override
  String get matchesGestureErrorLoad => 'Verlauf konnte nicht geladen werden';

  @override
  String get matchesGestureErrorPending =>
      'Gesten werden freigeschaltet, sobald aus dieser offenen Unterhaltung ein echtes Match wird.';

  @override
  String get matchesGestureErrorSend => 'Geste konnte nicht gesendet werden.';

  @override
  String get matchesGestureErrorUpdate =>
      'Status der Geste konnte nicht aktualisiert werden.';

  @override
  String get matchesActivityTitle => '2-Minuten-Entweder-oder';

  @override
  String get matchesActivityRestartTooltip => 'Neue Runde starten';

  @override
  String matchesActivityCompleteWith(String name) {
    return 'Mach das zusammen mit $name';
  }

  @override
  String get matchesActivityInstructions =>
      'Beantworte alle 8 Runden, bevor die Zeit abläuft.';

  @override
  String matchesActivityStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get matchesActivityStatusActive => 'aktiv';

  @override
  String get matchesActivityStatusTimedOut => 'Zeit abgelaufen';

  @override
  String get matchesActivityStatusPartialTimeout => 'teilweise abgelaufen';

  @override
  String get matchesActivityStatusCompleted => 'abgeschlossen';

  @override
  String get matchesActivitySubmit => 'Antworten senden';

  @override
  String get matchesActivityTimeUpLoad => 'Zeit ist um – Zusammenfassung laden';

  @override
  String get matchesActivityWaiting =>
      'Antworten gesendet. Warte, bis die andere Person fertig ist.';

  @override
  String get matchesActivityRefreshSummary => 'Zusammenfassung aktualisieren';

  @override
  String matchesActivityTimeLeft(String time) {
    return 'Verbleibende Zeit $time';
  }

  @override
  String get matchesActivitySummaryTitle => 'Zusammenfassung';

  @override
  String matchesActivityParticipantsCompleted(int completed, int total) {
    return 'Teilnehmende fertig: $completed/$total';
  }

  @override
  String get matchesActivitySummaryPending =>
      'Die Zusammenfassung erscheint, sobald sie verfügbar ist.';

  @override
  String get matchesActivityShareResult => 'Ergebnis im Chat teilen';

  @override
  String matchesActivityShareMessage(String status, int completed, int total) {
    return 'Ergebnis 2-Minuten-Entweder-oder: $status • $completed/$total fertig';
  }

  @override
  String matchesActivityShareMessageWithInsight(
    String status,
    int completed,
    int total,
    String insight,
  ) {
    return 'Ergebnis 2-Minuten-Entweder-oder: $status • $completed/$total fertig • $insight';
  }

  @override
  String matchesActivityRound(int number) {
    return 'Runde $number';
  }

  @override
  String get matchesActivityErrorStart =>
      'Die Aktivität kann gerade nicht gestartet werden. Bitte versuch es erneut.';

  @override
  String get matchesActivityErrorNotReady =>
      'Die Sitzung ist noch nicht bereit.';

  @override
  String get matchesActivityErrorAnswerAll =>
      'Bitte beantworte alle Fragen, bevor du absendest.';

  @override
  String get matchesActivityErrorTimeUp =>
      'Die Zeit ist um. Zusammenfassung wird geladen …';

  @override
  String get matchesActivityErrorSubmit =>
      'Antworten konnten nicht gesendet werden. Bitte versuch es erneut.';

  @override
  String get matchesActivityErrorSummary =>
      'Die Zusammenfassung ist noch nicht abrufbar. Bitte versuch es erneut.';

  @override
  String get matchesActivityQ1Prompt => 'Ideales erstes Treffen?';

  @override
  String get matchesActivityQ1OptionA => 'Spaziergang mit Kaffee';

  @override
  String get matchesActivityQ1OptionB => 'Stöbern im Buchladen';

  @override
  String get matchesActivityQ2Prompt => 'Lieblingsstimmung am Wochenende?';

  @override
  String get matchesActivityQ2OptionA => 'Zu Hause auftanken';

  @override
  String get matchesActivityQ2OptionB => 'Die Stadt erkunden';

  @override
  String get matchesActivityQ3Prompt => 'Bester Ort für ein Gespräch?';

  @override
  String get matchesActivityQ3OptionA => 'Langer Spaziergang';

  @override
  String get matchesActivityQ3OptionB => 'Gemütliche Café-Ecke';

  @override
  String get matchesActivityQ4Prompt => 'Wie planst du Dates?';

  @override
  String get matchesActivityQ4OptionA => 'Spontan';

  @override
  String get matchesActivityQ4OptionB => 'Im Voraus geplant';

  @override
  String get matchesActivityQ5Prompt => 'Was ist dir gerade wichtiger?';

  @override
  String get matchesActivityQ5OptionA => 'Beständigkeit';

  @override
  String get matchesActivityQ5OptionB => 'Aufregung';

  @override
  String get matchesActivityQ6Prompt => 'Wie gehst du mit Konflikten um?';

  @override
  String get matchesActivityQ6OptionA => 'Am selben Tag klären';

  @override
  String get matchesActivityQ6OptionB => 'Erst Abstand, dann darüber reden';

  @override
  String get matchesActivityQ7Prompt => 'Gemeinsame Aktivität?';

  @override
  String get matchesActivityQ7OptionA => 'Zusammen kochen';

  @override
  String get matchesActivityQ7OptionB => 'Zusammen trainieren';

  @override
  String get matchesActivityQ8Prompt => 'Welches Tempo magst du?';

  @override
  String get matchesActivityQ8OptionA => 'Ruhig und bewusst';

  @override
  String get matchesActivityQ8OptionB => 'Schnell und energiegeladen';

  @override
  String get cityPilotSaveFailed =>
      'Wir konnten diese Änderung nicht bestätigen. Aktualisiere, um nachzusehen, bevor du es erneut versuchst.';

  @override
  String get cityPilotLeaveTitle => 'Das Stadt-Pilotprojekt verlassen?';

  @override
  String get cityPilotLeaveBody =>
      'Deine Buchungen im Pilotprojekt werden storniert und dein Feedback zu Erlebnissen wird entfernt. Deine Aktivität fließt nicht mehr in die aktuellen Ergebnisse ein. Deine Matches und Unterhaltungen bleiben erhalten. Du kannst diesem Pilotprojekt nicht erneut beitreten.';

  @override
  String get cityPilotStay => 'Im Pilotprojekt bleiben';

  @override
  String get cityPilotLeave => 'Pilotprojekt verlassen';

  @override
  String get cityPilotLeftNotice =>
      'Du hast das Pilotprojekt verlassen. Deine Matches bleiben dir erhalten.';

  @override
  String cityPilotJoinEventTitle(String title) {
    return 'An $title teilnehmen?';
  }

  @override
  String cityPilotBookingTerms(
    String host,
    String safetyContact,
    String accessibility,
  ) {
    return 'Dieses Erlebnis ist kostenlos. Ihr trefft euch am öffentlichen Ort. Respektiere die Grenzen anderer und organisiere deine Anreise selbst. Du kannst jederzeit gehen.\n\nGastgeber: $host\nSicherheitskontakt: $safetyContact\n\nBarrierefreiheit: $accessibility\n\nBei akuter Gefahr wende dich an den örtlichen Notruf.';
  }

  @override
  String get cityPilotAcceptReserve => 'Akzeptieren & Platz reservieren';

  @override
  String get cityPilotReservedNotice =>
      'Dein Platz ist reserviert. Du kannst hier jederzeit stornieren.';

  @override
  String get cityPilotFeedbackTitle => 'Wie war das Erlebnis?';

  @override
  String get cityPilotFeedbackIntro =>
      'Optional. Die Antworten fließen in die zusammengefassten Ergebnisse des Pilotprojekts ein. Sie werden weder anderen Mitgliedern noch dem Gastgeber gezeigt.';

  @override
  String get cityPilotDidYouAttend => 'Warst du dabei?';

  @override
  String get cityPilotAttendedYes => 'Ja, ich war da';

  @override
  String get cityPilotAttendedNo => 'Ich konnte nicht';

  @override
  String get cityPilotWorthwhileQuestion =>
      'War es deine Zeit wert? (optional)';

  @override
  String get cityPilotNotThisTime => 'Diesmal nicht';

  @override
  String get cityPilotSkip => 'Überspringen';

  @override
  String get cityPilotShareFeedback => 'Feedback teilen';

  @override
  String get cityPilotFeedbackThanks =>
      'Danke. Dein Feedback wurde vertraulich gespeichert.';

  @override
  String get cityPilotTimeTbc => 'Uhrzeit wird noch bestätigt';

  @override
  String get cityPilotTitle => 'Das Stadt-Pilotprojekt';

  @override
  String get cityPilotRefreshTooltip => 'Pilotprojekt aktualisieren';

  @override
  String get cityPilotHeroTitle => 'Ein bisschen näher.\nViel echter.';

  @override
  String get cityPilotHeroBody =>
      'Eine Stadt. Eine kleine Community. Mehr Chancen, dass aus einem Gespräch ein Plan wird.';

  @override
  String get cityPilotStep1Title => 'Mit einem Gespräch beginnen';

  @override
  String get cityPilotStep1Body =>
      'Lerne Menschen in deinem Tempo über deine bisherigen Vorstellungen kennen.';

  @override
  String get cityPilotStep2Title => 'Raum für ein echtes Date schaffen';

  @override
  String get cityPilotStep2Body =>
      'Schmiedet gemeinsam einen Plan. Erzähl nur, wie es war, wenn du möchtest.';

  @override
  String get cityPilotStep3Title => 'Gemeinsam etwas ausprobieren';

  @override
  String get cityPilotStep3Body =>
      'Kleine, begleitete Erlebnisse folgen nach der ersten Auswertung des Pilotprojekts.';

  @override
  String get cityPilotSaving => 'Pilot-Einstellung wird gespeichert';

  @override
  String get cityPilotUnavailableTitle =>
      'Dein Pilotprojekt ist nicht verfügbar';

  @override
  String get cityPilotUnavailableBody =>
      'Prüfe deine Verbindung und aktualisiere, um deine aktuelle Teilnahme und Buchungen zu sehen.';

  @override
  String get cityPilotComingSoonTitle => 'Bald in einer Stadt in deiner Nähe';

  @override
  String get cityPilotComingSoonBody =>
      'Für die Stadt in deinem Profil gibt es noch kein offenes Pilotprojekt. Sobald eines startet, kannst du entscheiden, ob du mitmachst. Dein gewohntes Dating geht wie bisher weiter.';

  @override
  String cityPilotPanelTitleJoined(String city) {
    return '$city · Du bist dabei';
  }

  @override
  String cityPilotPanelTitleOpen(String city) {
    return '$city · Stadt-Pilotprojekt';
  }

  @override
  String cityPilotRecruitmentCloses(String date) {
    return 'Anmeldeschluss: $date (deine Ortszeit).';
  }

  @override
  String get cityPilotPaused =>
      'Neue Teilnahmen und Buchungen sind pausiert. Du kannst trotzdem austreten oder stornieren.';

  @override
  String get cityPilotCompleted =>
      'Dieses Pilotprojekt ist abgeschlossen. Danke, dass du dabei warst.';

  @override
  String get cityPilotMeasurement =>
      'Wenn du mitmachst, zählen wir Unterhaltungen, angenommene Pläne und optionale Antworten auf „Hat das Date stattgefunden?“ bei neuen Matches, bei denen beide Personen diesem Pilotprojekt beigetreten sind. Wir nutzen Zeitfenster von 7 Tagen für Unterhaltungen und 28 Tagen für Dates. Für das Pilotprojekt lesen wir weder Nachrichtentexte noch private Feedback-Notizen.';

  @override
  String get cityPilotPrivacy =>
      'Deine Teilnahme bleibt privat. Es gibt keine öffentliche Teilnehmerliste und keinen Dating-Score. Wenn du austrittst, wird deine Aktivität aus den aktuellen Ergebnissen ausgeschlossen und deine Buchungen werden storniert. Bereits ausgewertete Gesamtergebnisse lassen sich nicht ungesehen machen.';

  @override
  String get cityPilotConsent =>
      'Ich stimme zu, an diesem Pilotprojekt und seiner Ergebnismessung teilzunehmen.';

  @override
  String get cityPilotJoinedNotice =>
      'Du bist dabei. Lerne weiter Menschen in deinem Tempo kennen.';

  @override
  String get cityPilotJoin => 'Am Stadt-Pilotprojekt teilnehmen';

  @override
  String get cityPilotWithdrawn =>
      'Du hast dieses Pilotprojekt verlassen. Deine Matches und Unterhaltungen bleiben unverändert.';

  @override
  String get cityPilotNotAccepting =>
      'Dieses Pilotprojekt nimmt gerade keine neuen Mitglieder auf.';

  @override
  String get cityPilotExperiencesHeading =>
      'Kleine Pläne. Gemeinsame Erlebnisse.';

  @override
  String get cityPilotNoExperiences =>
      'Begleitete Erlebnisse sind noch nicht geöffnet. Sie erscheinen hier nach einer Ergebnis- und Sicherheitsprüfung.';

  @override
  String cityPilotEventDetails(
    String start,
    String end,
    String venue,
    String host,
  ) {
    return '$start → $end\nDeine Ortszeit · Kostenlos\n$venue\nGastgeber: $host';
  }

  @override
  String cityPilotAccessibility(String details) {
    return 'Barrierefreiheit · $details';
  }

  @override
  String cityPilotSafetyContact(String contact) {
    return 'Sicherheitskontakt · $contact';
  }

  @override
  String get cityPilotEventCancelled =>
      'Dieses Erlebnis wurde abgesagt. Bitte komm nicht zum Veranstaltungsort.';

  @override
  String get cityPilotPlaceReserved => 'Dein Platz ist reserviert.';

  @override
  String get cityPilotBookingCancelled => 'Deine Buchung ist storniert.';

  @override
  String get cityPilotCancelPlace => 'Meinen Platz stornieren';

  @override
  String get cityPilotReserveFree => 'Kostenlosen Platz reservieren';

  @override
  String get cityPilotShareOptionalFeedback => 'Optionales Feedback geben';

  @override
  String get cityPilotFeedbackReceived =>
      'Dein Feedback ist eingegangen. Danke.';

  @override
  String get blogAudiencePrivate => 'Nur ich';

  @override
  String get blogAudienceFriends => 'Freunde';

  @override
  String get blogAudienceCommunity => 'Connect-Community';

  @override
  String get blogInvitationNone => 'Keine Einladung';

  @override
  String get blogInvitationYourVersion => 'Wie würde deine Version aussehen?';

  @override
  String get blogInvitationTeachMe => 'Was könntest du mir darüber beibringen?';

  @override
  String get blogInvitationWhatNext =>
      'Was würdest du als Nächstes ausprobieren?';

  @override
  String get blogRewardStoryPublishedTitle => 'Ein Kapitel teilen';

  @override
  String get blogRewardStoryPublishedWho =>
      'Du, wenn ein Kapitel zum ersten Mal über „Nur ich“ hinaus geteilt wird';

  @override
  String get blogRewardPhotoSharedTitle => 'Ein Foto bei Fotothemen teilen';

  @override
  String get blogRewardPhotoSharedWho =>
      'Du, für ein Foto, das du bei Fotothemen teilst';

  @override
  String get blogRewardLikeReceivedTitle =>
      'Ein Like für dein Kapitel oder Foto';

  @override
  String get blogRewardLikeReceivedWho =>
      'Du, für jedes Mitglied, dem es gefällt';

  @override
  String get blogRewardCommentReceivedTitle =>
      'Ein Kommentar, den du freigibst';

  @override
  String get blogRewardCommentReceivedWho =>
      'Du, wenn du den Kommentar einer Leserin oder eines Lesers freigibst';

  @override
  String get blogRewardCommentApprovedTitle =>
      'Dein Kommentar wird freigegeben';

  @override
  String get blogRewardCommentApprovedWho =>
      'Du, wenn jemand deinen Kommentar freigibt';

  @override
  String get blogRewardSubscriberGainedTitle => 'Ein neuer Follower';

  @override
  String get blogRewardSubscriberGainedWho =>
      'Du, für jedes neue Mitglied, das deinen Kapiteln folgt';

  @override
  String get blogRewardWallTierTitle => 'Auf mehr Walls landen';

  @override
  String get blogRewardWallTierWho =>
      'Du, jedes Mal, wenn ein Kapitel eine neue Wall-Stufe erreicht';

  @override
  String get blogRewardCoverOfWeekTitle => 'Cover der Woche';

  @override
  String get blogRewardCoverOfWeekWho =>
      'Du, wenn dein Beitrag zum Cover der Woche gewählt wird';

  @override
  String get blogScopeForYou => 'Für dich';

  @override
  String get blogScopeTopRated => 'Top bewertet';

  @override
  String get blogScopeFollowing => 'Gefolgt';

  @override
  String get blogScopeMine => 'Meine';

  @override
  String get blogScopeCaptionMine =>
      'Deine Entwürfe und veröffentlichten Kapitel. Du wählst für jedes das Publikum.';

  @override
  String get blogScopeCaptionFriends =>
      'Kapitel, die deine bestätigten Connect-Freunde geteilt haben.';

  @override
  String get blogScopeCaptionTop =>
      'Sortiert nach Likes, freigegebenen Kommentaren und Lesenden der letzten 30 Tage.';

  @override
  String get blogScopeCaptionFollowing =>
      'Die neuesten Kapitel von Menschen, denen du folgst.';

  @override
  String get blogScopeCaptionCommunity =>
      'Für berechtigte, angemeldete Connect-Mitglieder. Diese Kapitel sind im Web nicht öffentlich.';

  @override
  String get blogTitle => 'Offene Kapitel';

  @override
  String get blogRewardsTitle => 'So funktionieren Belohnungen';

  @override
  String get blogWritersTitle => 'Schreibende, denen du folgst';

  @override
  String get blogConnectionsTooltip => 'Private Antworten, Teilen und Hinweise';

  @override
  String get blogSignInReadWrite =>
      'Melde dich an, um Kapitel zu lesen und zu schreiben.';

  @override
  String get blogHeroTitle => 'Ein Leben, das es\nwert ist, kennenzulernen.';

  @override
  String get blogHeroBody =>
      'Die Geschichte hinter einem Foto. Eine kleine Leidenschaft. Etwas, das du gerade lernst. Lass deinen Alltag für dich sprechen.';

  @override
  String get blogWriteChapter => 'Kapitel schreiben';

  @override
  String get blogPrivateResponses => 'Private Antworten';

  @override
  String get blogSharedLinks => 'Geteilte Links';

  @override
  String get blogReviewNotices => 'Prüfhinweise';

  @override
  String get blogTopicAll => 'Alle';

  @override
  String get blogFeedLoadFailed => 'Kapitel konnten nicht geladen werden.';

  @override
  String get blogPreviousPage => 'Vorherige Seite';

  @override
  String get blogMoreChapters => 'Weitere Kapitel';

  @override
  String get blogEmptyMineTitle => 'Dein nächstes Kapitel beginnt hier.';

  @override
  String get blogEmptyMineBody =>
      'Beginne mit einem Moment, nach dem dich gern jemand fragen dürfte. Dein erster Entwurf ist nur für dich.';

  @override
  String get blogEmptyTopTitle =>
      'Wenn Kapitel berühren, steigen sie hier auf.';

  @override
  String get blogEmptyTopFilteredBody =>
      'In diesem Thema ist noch nichts aufgestiegen. Versuch es mit „Alle“ oder teile selbst ein Kapitel.';

  @override
  String get blogEmptyTopBody =>
      'Hier erscheinen Kapitel aus den letzten 30 Tagen, die Lesende lieben.';

  @override
  String get blogEmptyFollowingFilteredTitle =>
      'In diesem Thema gibt es noch nichts Neues.';

  @override
  String get blogEmptyFollowingTitle =>
      'Hier erscheinen die Schreibenden, denen du folgst.';

  @override
  String get blogEmptyFollowingBody =>
      'Wenn dich ein Kapitel anspricht, öffne es und tippe auf „Ihren Kapiteln folgen“. Neue Kapitel sammeln sich dann hier, damit du nichts verpasst.';

  @override
  String get blogEmptyCommunityTitle => 'Noch ist es hier ein bisschen ruhig.';

  @override
  String get blogEmptyCommunityBody =>
      'Kapitel erscheinen hier, wenn Mitglieder sie mit diesem Publikum teilen.';

  @override
  String get blogFindWritersTopRated => 'Schreibende in „Top bewertet“ finden';

  @override
  String blogRankTooltip(int rank) {
    return 'Platz $rank in „Top bewertet“';
  }

  @override
  String get blogUntitled => 'Ein Kapitel ohne Titel';

  @override
  String get blogDraftPlaceholder =>
      'Ein privater Entwurf, der auf deine Worte wartet.';

  @override
  String get blogReadEdit => 'Lesen & bearbeiten →';

  @override
  String get blogReadChapter => 'Kapitel lesen →';

  @override
  String get blogPhotoUnavailableRetry =>
      'Foto nicht verfügbar · Erneut versuchen';

  @override
  String get blogTryAgain => 'Erneut versuchen';

  @override
  String get blogDetailTitle => 'Ein Kapitel';

  @override
  String get blogSignInRead => 'Melde dich an, um Kapitel zu lesen.';

  @override
  String get blogDetailUnavailable =>
      'Dieses Kapitel ist nicht verfügbar oder sein Publikum hat sich geändert.';

  @override
  String get blogRespondPrivately => 'Privat antworten';

  @override
  String get blogCreatePublicPreview => 'Öffentliche Vorschau erstellen';

  @override
  String get blogRemovedByModerationNote =>
      'Von der Moderation entfernt. Öffne „Prüfhinweise“, um die Entscheidung zu lesen oder eine erneute Prüfung zu beantragen.';

  @override
  String get blogEditChapter => 'Kapitel bearbeiten';

  @override
  String get blogDeleteChapter => 'Kapitel löschen';

  @override
  String get blogDeleteChapterTitle => 'Dieses Kapitel löschen?';

  @override
  String get blogDeleteChapterMessage =>
      'Es verschwindet für alle Lesenden. Das kann nicht rückgängig gemacht werden.';

  @override
  String get blogDeleteChapterFailed =>
      'Löschen konnte nicht bestätigt werden. Lade das Kapitel neu, bevor du es erneut versuchst.';

  @override
  String get blogReportChapter => 'Kapitel melden';

  @override
  String get blogReportFailed => 'Die Meldung konnte nicht gesendet werden.';

  @override
  String get blogBlockThisMember => 'Dieses Mitglied blockieren';

  @override
  String get blogBlockTitle => 'Dieses Mitglied blockieren?';

  @override
  String get blogBlockMessageChapter =>
      'Ihr seht dann die Kapitel des anderen nicht mehr. Außerdem wird der Kontakt über Connect blockiert.';

  @override
  String get blogBlockMember => 'Mitglied blockieren';

  @override
  String get blogBlockRetryFailed =>
      'Dieses Mitglied konnte nicht blockiert werden. Bitte versuch es noch einmal.';

  @override
  String get blogCancel => 'Abbrechen';

  @override
  String get blogEditorMissingFields =>
      'Füge vor dem Veröffentlichen einen Titel und eine Geschichte hinzu.';

  @override
  String blogPublishConfirmTitle(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Für „Nur ich“ veröffentlichen?',
      'friends': 'Für Freunde veröffentlichen?',
      'community': 'In der Connect-Community veröffentlichen?',
      'other': 'Veröffentlichen?',
    });
    return '$_temp0';
  }

  @override
  String get blogPublishFriendsBody =>
      'Deine bestätigten Connect-Freunde können Text und Fotos dieses Kapitels lesen. Du kannst das Publikum später ändern.';

  @override
  String get blogPublishCommunityBody =>
      'Berechtigte, angemeldete Connect-Mitglieder können dieses Kapitel lesen. Es erscheint nicht im öffentlichen Web. Du kannst das Publikum später ändern.';

  @override
  String get blogPublishChapter => 'Kapitel veröffentlichen';

  @override
  String get blogSavedOnlyMe =>
      'Gespeichert. Nur du kannst dieses Kapitel lesen.';

  @override
  String blogPublishedTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Für „Nur ich“ veröffentlicht.',
      'friends': 'Für Freunde veröffentlicht.',
      'community': 'In der Connect-Community veröffentlicht.',
      'other': 'Veröffentlicht.',
    });
    return '$_temp0';
  }

  @override
  String get blogSharedSnack =>
      'Geteilt. Likes und Kommentare deiner Lesenden bringen dir XP.';

  @override
  String get blogSeeMyLevel => 'Mein Level ansehen';

  @override
  String get blogSaveUnconfirmed =>
      'Wir konnten das Speichern nicht bestätigen.';

  @override
  String blogEditsStillHere(String message) {
    return '$message Deine Änderungen sind noch da. Prüfe die gespeicherte Version, bevor du weitermachst.';
  }

  @override
  String blogSavedVersionTitle(String audience) {
    return 'Gespeicherte Version · $audience';
  }

  @override
  String get blogSavedVersionNote =>
      'Deine aktuellen Änderungen bleiben im Editor. Schließe dieses Fenster, um sie zu behalten, oder ersetze sie durch diese gespeicherte Version.';

  @override
  String get blogKeepMyEdits =>
      'Meine Änderungen für das nächste Speichern behalten';

  @override
  String get blogUseSavedVersion => 'Gespeicherte Version verwenden';

  @override
  String get blogSavedVersionLoadFailed =>
      'Die gespeicherte Version konnte nicht geladen werden. Deine Änderungen bleiben erhalten.';

  @override
  String get blogDescribePhotoTitle => 'Beschreibe dein Foto';

  @override
  String get blogDescribePhotoBody =>
      'Eine kurze Beschreibung macht dein Kapitel barrierefrei. Beim Hinzufügen des Fotos werden deine Worte als „Nur ich“-Entwurf gespeichert.';

  @override
  String get blogDescribePhotoLabel => 'Was ist auf diesem Foto?';

  @override
  String get blogAddToPrivateDraft => 'Zum privaten Entwurf hinzufügen';

  @override
  String get blogPhotoAdded => 'Foto zu deinem privaten Entwurf hinzugefügt.';

  @override
  String get blogPhotoAddFailed =>
      'Das Foto konnte nicht hinzugefügt werden. Nutze ein JPEG oder PNG bis 10 MB.';

  @override
  String blogCheckSavedBeforeRetrying(String message) {
    return '$message Prüfe die gespeicherte Version, bevor du es erneut versuchst.';
  }

  @override
  String get blogRemoveUnconfirmed =>
      'Entfernen konnte nicht bestätigt werden. Prüfe die gespeicherte Version.';

  @override
  String get blogSignInAsAuthor =>
      'Melde dich mit dem Konto an, das dieses Kapitel geschrieben hat, um es zu bearbeiten.';

  @override
  String get blogLeaveEditorTitle => 'Ohne Speichern verlassen?';

  @override
  String get blogLeaveEditorMessage =>
      'Deine ungespeicherten Änderungen gehen verloren. Dein zuletzt gespeichertes Kapitel bleibt erhalten.';

  @override
  String get blogLeaveEditor => 'Editor verlassen';

  @override
  String get blogEditorPreviewTitle => 'Kapitelvorschau';

  @override
  String get blogEditorTitle => 'Dein nächstes Kapitel';

  @override
  String get blogEditorHeadline => 'Ein bisschen mehr du.';

  @override
  String get blogEditorIntro =>
      'Kleine Geschichten sind willkommen. Ein Essen, das du gekocht hast. Ein Ort, der deine Meinung geändert hat. Das Foto mit einer Geschichte dahinter.';

  @override
  String get blogNotSavedDefault =>
      'Nicht gespeichert · Standardmäßig „Nur ich“';

  @override
  String blogSavedFor(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Gespeichert für „Nur ich“',
      'friends': 'Gespeichert für Freunde',
      'community': 'Gespeichert für die Connect-Community',
      'other': 'Gespeichert',
    });
    return '$_temp0';
  }

  @override
  String get blogKeepWriting => 'Weiterschreiben';

  @override
  String get blogPreview => 'Vorschau';

  @override
  String get blogCheckSavedVersion => 'Gespeicherte Version prüfen';

  @override
  String blogPreviewNotSaved(String audience) {
    return 'Vorschau · $audience · Noch nicht gespeichert';
  }

  @override
  String get blogStoryPlaceholder => 'Hier erscheint deine Geschichte.';

  @override
  String get blogChapterTitleLabel => 'Kapiteltitel';

  @override
  String get blogChapterTitleHint => 'Der Sonntag, an dem ich langsamer wurde';

  @override
  String get blogStoryLabel => 'Deine Geschichte';

  @override
  String get blogStoryHint => 'Fang irgendwo an. Mach es zu deinem.';

  @override
  String get blogInvitationLabel => 'Mit einer Einladung enden (optional)';

  @override
  String get blogInvitationHelp =>
      'Hinterlasse eine Frage, die anderen hilft, dich kennenzulernen.';

  @override
  String get blogRemovePhoto => 'Foto entfernen';

  @override
  String get blogAddPhoto => 'Foto hinzufügen';

  @override
  String get blogPhotoRules =>
      'Bis zu 6 Fotos als JPEG oder PNG, je 10 MB. Fotos müssen freigegeben werden. Speichere als „Nur ich“, bevor du Fotos in einem veröffentlichten Kapitel änderst.';

  @override
  String get blogWhoFor => 'Für wen ist dieses Kapitel?';

  @override
  String get blogAudiencePrivateHelp =>
      'Nur du kannst dieses Kapitel lesen. Freunde und Matches sehen es nicht.';

  @override
  String get blogAudienceFriendsHelp =>
      'Nur bestätigte Connect-Freunde können es lesen. Ein Match allein gibt keinen Zugriff.';

  @override
  String get blogAudienceCommunityHelp =>
      'Berechtigte, angemeldete Mitglieder können es lesen. Vervollständige dein Profil mit zwei freigegebenen Profilfotos, um hier zu veröffentlichen. Das ist keine öffentliche Freigabe im Web.';

  @override
  String get blogAllowFeaturing => 'Hervorheben erlauben';

  @override
  String get blogAllowFeaturingHelp =>
      'Wenn dein Kapitel gut ankommt, kann es auf den Walls anderer landen: 50 Likes und 5 Kommentare bringen es auf 50 Walls, 100 Likes und 10 Kommentare auf 100. Du kannst das jederzeit ausschalten.';

  @override
  String get blogSaveOnlyForMe => 'Nur für mich speichern';

  @override
  String blogPublishTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Für „Nur ich“ veröffentlichen',
      'friends': 'Für Freunde veröffentlichen',
      'community': 'In der Connect-Community veröffentlichen',
      'other': 'Veröffentlichen',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveAsOnlyMe => 'Als „Nur ich“ speichern';

  @override
  String get blogSaveNote =>
      'Deine Worte werden gespeichert, wenn du „Speichern“ oder „Veröffentlichen“ wählst. Die Vorschau veröffentlicht nichts.';

  @override
  String get blogTopicOptional => 'Thema (optional)';

  @override
  String get blogTopicHelp =>
      'Hilf Lesenden, die sich dafür interessieren, dein Kapitel zu finden.';

  @override
  String get webDestBlog => 'Blog';

  @override
  String get webDestFirstChapter => 'First-Chapter-Studio';

  @override
  String get webDestDatingPreferences => 'Dating-Präferenzen';

  @override
  String get webDestEditProfile => 'Profil bearbeiten';

  @override
  String get webDestProfilePhotos => 'Profilfotos';

  @override
  String get webDestLikedYou => 'Mögen dich';

  @override
  String get webDestNotifications => 'Benachrichtigungen';

  @override
  String get webDestDailyPrompt => 'Tägliche Frage';

  @override
  String get webDestLevels => 'Level & Fortschritt';

  @override
  String get webDestTrustBadges => 'Vertrauensabzeichen';

  @override
  String get webDestTrustFilters => 'Vertrauensfilter';

  @override
  String get webDestIcebreakers => 'Eisbrecher';

  @override
  String get webDestCircleChallenges => 'Kreis-Challenges';

  @override
  String get webDestCoffeePolls => 'Kaffee-Umfragen';

  @override
  String get webDestGroups => 'Gruppen';

  @override
  String get webDestRooms => 'Gesprächsräume';

  @override
  String get webDestMatchNudges => 'Match-Anstupser';

  @override
  String get webDestFriends => 'Freunde';

  @override
  String get webDestDatePlans => 'Date-Pläne';

  @override
  String get webDestCallHistory => 'Anrufverlauf';

  @override
  String get webDestMembership => 'Mitgliedschaft';

  @override
  String get webDestVerification => 'Verifizierung';

  @override
  String get webDestPrivacySafety => 'Privatsphäre & Sicherheit';

  @override
  String get webDestAccountData => 'Konto & Daten';

  @override
  String get webDestBlockedMembers => 'Blockierte Mitglieder';

  @override
  String get webDestEmergencyContacts => 'Notfallkontakte';

  @override
  String get webDestModerationAppeals => 'Einsprüche gegen Moderation';

  @override
  String get webDestNotificationPreferences => 'Benachrichtigungseinstellungen';

  @override
  String get webDestHelpSupport => 'Hilfe & Support';

  @override
  String get webNavExplore => 'Entdecken';

  @override
  String get webNavMyProfile => 'Mein Profil';

  @override
  String get webNavAllFeatures => 'Alle Funktionen';

  @override
  String get webNavMoreForYou => 'Mehr für dich';

  @override
  String get webNavPreferences => 'Präferenzen';

  @override
  String get webNavWebsite => 'Connect-Website';

  @override
  String get webNavSignOut => 'Abmelden';

  @override
  String get webPageNotFound => 'Diese Seite wurde nicht gefunden.';

  @override
  String get webBackToDiscover => 'Zurück zu Entdecken';

  @override
  String get webTagline => 'Dein Tempo. Deine Wahl.';

  @override
  String webUnavailableTitle(String label) {
    return '$label ist noch nicht verfügbar.';
  }

  @override
  String get webUnavailableBody => 'Es ist nicht Teil dieser Connect-Version.';

  @override
  String get webDirectoryTitle => 'Mach diesen Ort zu deinem.';

  @override
  String get webDirectorySubtitle =>
      'Dein Profil, deine Gespräche, Community und Einstellungen – alles an einem Ort.';

  @override
  String get webIcebreakerTitle => 'Gesprächsstarter';

  @override
  String get webIcebreakerHeadline =>
      'Ein wenig Inspiration für dein nächstes Hallo.';

  @override
  String get webIcebreakerBody =>
      'Sprachaufnahme und -wiedergabe sind noch nicht verfügbar. Du kannst diese Impulse in einem berechtigten Gespräch nutzen.';

  @override
  String get webIcebreakerOpenMatches => 'Meine Matches öffnen';

  @override
  String get webMembershipHeadline => 'Ein bisschen mehr Möglichkeiten.';

  @override
  String get webMembershipIntro =>
      'Sieh dir die aktuellen Pläne an. Bezahlen im Browser ist noch nicht möglich. Auf dieser Seite kann nichts gekauft oder abgebucht werden.';

  @override
  String webMembershipCurrent(String plan) {
    return 'Deine Mitgliedschaft: $plan';
  }

  @override
  String webMembershipStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get webMembershipMonthly => 'Monatlich';

  @override
  String get webMembershipYearly => 'Jährlich';

  @override
  String get webMembershipFree => 'Kostenlos';

  @override
  String webMembershipPrice(String price, String cycle) {
    String _temp0 = intl.Intl.selectLogic(cycle, {
      'yearly': 'Jahr',
      'other': 'Monat',
    });
    return '$price / $_temp0';
  }

  @override
  String get webMembershipFootnote =>
      'Die Katalogpreise sind eine Vorschau. Eine Mitgliedschaft setzt sich nie über die Grenzen anderer oder die Gesprächsberechtigung hinweg.';

  @override
  String get blogLinkCopied => 'Link kopiert. Teile ihn, wo immer du möchtest.';

  @override
  String get blogYourPublicLink => 'Dein öffentlicher Link';

  @override
  String get blogShareUnconfirmed =>
      'Teilen konnte nicht bestätigt werden. Prüfe „Geteilte Links“, bevor du es erneut versuchst.';

  @override
  String get blogSignInAgain => 'Melde dich erneut an, um fortzufahren.';

  @override
  String get blogSharedJournalPage => 'Eine gemeinsame Tagebuchseite';

  @override
  String get blogYourPublicPreview => 'Deine öffentliche Vorschau';

  @override
  String get blogShareJointHeadline =>
      'Eine Geschichte, die ihr beide teilen wollt.';

  @override
  String get blogShareSoloHeadline => 'Ein kleiner Einblick in deine Welt.';

  @override
  String get blogShareJointBody =>
      'Beide müssen genau diesen Worten zustimmen, bevor der Link funktioniert. Ihr könnt ihn beide zurückziehen.';

  @override
  String get blogShareSoloBody =>
      'Alle mit dem Link können die ausgewählten Worte und Fotos ohne Konto sehen. Dein ganzes Kapitel bleibt in Connect.';

  @override
  String get blogShareIdentityNote =>
      'Es werden kein Profil und kein Kontoname hinzugefügt. Deine Worte und Fotos können trotzdem Personen oder Orte erkennbar machen. Veröffentliche nur, was du teilen darfst.';

  @override
  String get blogExcerptLabel => 'Genauer Auszug aus deinem Kapitel';

  @override
  String blogIncludePhoto(String description) {
    return 'Einbeziehen: $description';
  }

  @override
  String get blogApproveCopy =>
      'Ich stimme genau dieser öffentlichen Fassung zu';

  @override
  String get blogApproveCopyNote =>
      'Wenn du das Originalkapitel bearbeitest oder verbirgst, wird der Link ungültig. Außerhalb von Connect gespeicherte Kopien lassen sich nicht zurückholen.';

  @override
  String get blogSaving => 'Wird gespeichert …';

  @override
  String get blogRequestOtherApproval =>
      'Zustimmung des anderen Autors anfragen';

  @override
  String get blogCreatePublicLink => 'Öffentlichen Link erstellen';

  @override
  String get blogJointApprovalRecorded =>
      'Deine Zustimmung ist gespeichert. Der Link bleibt unverfügbar, bis die andere Person zustimmt.';

  @override
  String get blogPublicCopyReady => 'Deine öffentliche Fassung ist fertig.';

  @override
  String get blogCopyPublicLink => 'Öffentlichen Link kopieren';

  @override
  String get blogManageSharedLinks => 'Geteilte Links verwalten';

  @override
  String blogFollowerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Follower',
      one: '1 Follower',
    );
    return '$_temp0';
  }

  @override
  String get blogUnfollowFailed =>
      'Entfolgen hat gerade nicht geklappt. Bitte versuch es noch einmal.';

  @override
  String get blogFollowFailed =>
      'Folgen hat gerade nicht geklappt. Bitte versuch es noch einmal.';

  @override
  String get blogFollowingButton => 'Folge ich';

  @override
  String get blogFollowTheirChapters => 'Ihren Kapiteln folgen';

  @override
  String get blogRewardsIntro =>
      'Wenn das, was du teilst, jemanden berührt, zählt das. Likes, freigegebene Kommentare und neue Follower bringen dir XP für dein Level. Belohnungen entstehen durch das, was Lesende tun, nie durch bloßes Tippen, und jede gibt es nur einmal.';

  @override
  String blogRewardDailyCap(int cap) {
    return 'Bis zu $cap XP pro Tag';
  }

  @override
  String blogRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String get blogSignInWriters =>
      'Melde dich an, um die Schreibenden zu sehen, denen du folgst.';

  @override
  String get blogWritersLoadFailed =>
      'Die Schreibenden, denen du folgst, konnten nicht geladen werden.';

  @override
  String get blogNoWriters => 'Noch keine Schreibenden.';

  @override
  String get blogNoWritersBody =>
      'Wenn dich ein Kapitel anspricht, tippe darauf auf „Ihren Kapiteln folgen“. Neue Kapitel sammeln sich dann unter „Gefolgt“.';

  @override
  String blogLatest(String title) {
    return 'Neuestes: $title';
  }

  @override
  String get blogReactionFailed =>
      'Deine Reaktion wurde nicht gesendet. Bitte versuch es noch einmal.';

  @override
  String blogCannotLikeOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Du kannst dein eigenes Foto nicht liken',
      'other': 'Du kannst dein eigenes Kapitel nicht liken',
    });
    return '$_temp0';
  }

  @override
  String blogYouReacted(String reaction) {
    return 'Deine Reaktion: $reaction. Tippe, um sie zurückzunehmen';
  }

  @override
  String blogLikeThis(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Dieses Foto liken',
      'other': 'Dieses Kapitel liken',
    });
    return '$_temp0';
  }

  @override
  String blogCannotReactOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Du kannst nicht auf dein eigenes Foto reagieren',
      'other': 'Du kannst nicht auf dein eigenes Kapitel reagieren',
    });
    return '$_temp0';
  }

  @override
  String get blogReactTooltip =>
      'Reagieren: Ich höre dich, Ich auch, Eine Umarmung …';

  @override
  String blogCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kommentare',
      one: '1 Kommentar',
    );
    return '$_temp0';
  }

  @override
  String blogWaitingForYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '· $count warten auf dich',
      one: '· $count wartet auf dich',
    );
    return '$_temp0';
  }

  @override
  String get blogFeatured => 'Hervorgehoben';

  @override
  String blogTierNeedsBoth(int likes, int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes Likes',
      one: '1 Like',
    );
    String _temp1 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments Kommentare',
      one: '1 Kommentar',
    );
    String _temp2 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls Walls',
      one: '1 Wall',
    );
    return 'Noch $_temp0 und $_temp1 bis zu $_temp2';
  }

  @override
  String blogTierNeedsLikes(int likes, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes Likes',
      one: '1 Like',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls Walls',
      one: '1 Wall',
    );
    return 'Noch $_temp0 bis zu $_temp1';
  }

  @override
  String blogTierNeedsComments(int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments Kommentare',
      one: '1 Kommentar',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls Walls',
      one: '1 Wall',
    );
    return 'Noch $_temp0 bis zu $_temp1';
  }

  @override
  String blogTierAlmostThere(int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: 'Fast geschafft: Als Nächstes $walls Walls',
      one: 'Fast geschafft: Als Nächstes 1 Wall',
    );
    return '$_temp0';
  }

  @override
  String blogOnWalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Auf $count Walls',
      one: 'Auf 1 Wall',
    );
    return '$_temp0';
  }

  @override
  String blogProgressToward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fortschritt bis zu $count Walls',
      one: 'Fortschritt bis zu 1 Wall',
    );
    return '$_temp0';
  }

  @override
  String get blogReachIdle => 'Lesende können dieses Kapitel weitertragen';

  @override
  String get blogReachLive =>
      'Mitglieder, die Geschichten wie deine lieben, lesen es gerade.';

  @override
  String get blogFeaturedStories => 'Ausgewählte Geschichten';

  @override
  String get blogFeaturedCaption =>
      'Geschichten, die anderen gefallen haben – direkt auf deiner Wall.';

  @override
  String blogByAuthor(String name) {
    return 'von $name';
  }

  @override
  String get blogLikes => 'Likes';

  @override
  String get blogComments => 'Kommentare';

  @override
  String get blogCommentHint => 'Was ist dir im Gedächtnis geblieben?';

  @override
  String get blogCommentApproved =>
      'Freigegeben. Alle, die dieses Kapitel lesen können, sehen ihn jetzt.';

  @override
  String get blogCommentSent =>
      'Zur Freigabe an die Autorin / den Autor gesendet';

  @override
  String get blogCommentSendFailed =>
      'Dein Kommentar wurde nicht gesendet. Deine Worte sind noch da, du kannst es also erneut versuchen.';

  @override
  String blogCommentDeclined(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Abgelehnt. Er erscheint nicht bei deinem Foto.',
      'other': 'Abgelehnt. Er erscheint nicht bei deinem Kapitel.',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveFailed =>
      'Das wurde nicht gespeichert. Bitte versuch es noch einmal.';

  @override
  String get blogDeleteCommentTitle => 'Diesen Kommentar löschen?';

  @override
  String get blogDeleteCommentMessage =>
      'Er wird für alle entfernt. Das kann nicht rückgängig gemacht werden.';

  @override
  String get blogDeleteComment => 'Kommentar löschen';

  @override
  String get blogCommentDeleted => 'Kommentar gelöscht.';

  @override
  String get blogCommentDeleteFailed =>
      'Der Kommentar konnte nicht gelöscht werden. Bitte versuch es noch einmal.';

  @override
  String get blogCommentsAuthorNote =>
      'Neue Kommentare warten auf deine Freigabe, bevor andere sie sehen.';

  @override
  String get blogCommentsReaderNote =>
      'Die Autorin oder der Autor liest jeden Kommentar zuerst und entscheidet, was geteilt wird.';

  @override
  String get blogLeaveComment => 'Kommentar schreiben';

  @override
  String get blogSendToAuthor => 'An die Autorin / den Autor senden';

  @override
  String get blogCommentsLoadFailed =>
      'Kommentare konnten nicht geladen werden.';

  @override
  String get blogWaitingApproval => 'Warten auf deine Freigabe';

  @override
  String get blogNoCommentsInvite =>
      'Noch keine Kommentare. Schreib etwas Nettes, um das Gespräch zu beginnen.';

  @override
  String get blogNoCommentsShared => 'Noch keine Kommentare geteilt.';

  @override
  String get blogCommentNotShared =>
      'Die Autorin oder der Autor hat sich entschieden, diesen nicht zu teilen.';

  @override
  String get blogYou => 'Du';

  @override
  String get blogCommentOptions => 'Kommentaroptionen';

  @override
  String get blogReportComment => 'Kommentar melden';

  @override
  String get blogApprove => 'Freigeben';

  @override
  String get blogDecline => 'Ablehnen';

  @override
  String get blogSignInContinue => 'Melde dich an, um fortzufahren.';

  @override
  String get blogPrivateResponseTitle => 'Eine private Antwort';

  @override
  String blogPrivateResponseHelp(String invitation) {
    return '$invitation\n\nNur die Autorin oder der Autor erhält diese Antwort und kann einen optionalen Austausch annehmen oder ablehnen. Bis zu fünf neue Antworten pro Tag, eine davon an dieselbe Person.';
  }

  @override
  String get blogSendPrivateResponse => 'Private Antwort senden';

  @override
  String get blogTextSaveUnconfirmed =>
      'Speichern konnte nicht bestätigt werden. Deine Worte sind noch da; versuch es erneut oder lade den gespeicherten Austausch neu.';

  @override
  String get blogLeaveUnsentTitle => 'Ohne Senden verlassen?';

  @override
  String get blogLeaveUnsentMessage =>
      'Deine nicht gesendeten Worte werden verworfen.';

  @override
  String get blogLeave => 'Verlassen';

  @override
  String get blogOwnWordsLabel => 'In deinen eigenen Worten';

  @override
  String get blogSending => 'Wird gesendet …';

  @override
  String get blogChangeUnconfirmed =>
      'Die Änderung konnte nicht bestätigt werden. Aktualisiere, um es zu prüfen.';

  @override
  String get blogConnectionsTitle => 'Deine Kapitel-Verbindungen';

  @override
  String get blogRefresh => 'Aktualisieren';

  @override
  String get blogConnectionsIntro =>
      'Gute Geschichten lassen Raum für jemand anderen.';

  @override
  String get blogConnectionsLoadFailed =>
      'Deine Verbindungen konnten nicht geladen werden.';

  @override
  String get blogResponsesEmpty =>
      'Hier erscheinen Antworten auf deine Kapitel und die, die du sendest. Nichts braucht eine sofortige Antwort.';

  @override
  String get blogPublicationsEmpty =>
      'Hier erscheinen deine öffentlichen Vorschauen und gemeinsam freigegebenen Links.';

  @override
  String get blogNoticesEmpty => 'Keine Prüfhinweise vorhanden.';

  @override
  String get blogResponseRevealed => 'Euer gemeinsames Kapitel ist fertig';

  @override
  String get blogResponseIncoming => 'Eine Antwort für dich';

  @override
  String get blogResponseSent => 'Gesendet · ihre Wahl, ihr Tempo';

  @override
  String get blogResponseAccepted => 'Ein Austausch in eurem Tempo';

  @override
  String get blogResponseClosed => 'Dieser Austausch ist beendet';

  @override
  String get blogOpenExchange => 'Privaten Austausch öffnen';

  @override
  String get blogPublicationLive => 'Aktive öffentliche Fassung';

  @override
  String get blogPublicationRemoved => 'Von der Moderation entfernt';

  @override
  String get blogPublicationNeedsBoth =>
      'Braucht beide Zustimmungen und ein aktuelles Originalkapitel';

  @override
  String get blogPublicationSourceChanged =>
      'Original geändert · erstelle eine neue Vorschau, um erneut zu teilen';

  @override
  String get blogApprovePublicCopyTitle =>
      'Dieser öffentlichen Fassung zustimmen?';

  @override
  String get blogApprovePublicCopyMessage =>
      'Genau diese Worte sind dann für alle mit dem Link sichtbar. Ihr könnt das Teilen beide zurückziehen. Es werden keine Namen automatisch hinzugefügt, aber die Worte könnten dich erkennbar machen.';

  @override
  String get blogApprovePublicCopyAction => 'Öffentlicher Fassung zustimmen';

  @override
  String get blogApproveExactPublicCopy =>
      'Genau dieser öffentlichen Fassung zustimmen';

  @override
  String get blogCopyLink => 'Link kopieren';

  @override
  String get blogWithdrawLinkTitle => 'Diesen Link zurückziehen?';

  @override
  String get blogWithdrawLinkMessage =>
      'Die öffentliche Fassung ist dann nicht mehr verfügbar. Kopien, die andere bereits gespeichert haben, lassen sich nicht zurückholen.';

  @override
  String get blogWithdrawLink => 'Link zurückziehen';

  @override
  String get blogYourAppeal => 'Dein Einspruch';

  @override
  String get blogRequestReview => 'Erneute Prüfung beantragen';

  @override
  String get blogRequestReviewHelp =>
      'Erkläre, was bei der Prüfung noch einmal bedacht werden sollte. Dein Einspruch geht vertraulich an das Trust-Team. Entfernte Inhalte bleiben während der Prüfung verborgen.';

  @override
  String get blogSubmitAppeal => 'Einspruch einreichen';

  @override
  String get blogAppealDecision => 'Gegen diese Entscheidung Einspruch erheben';

  @override
  String get blogPrevious => 'Zurück';

  @override
  String get blogMore => 'Mehr';

  @override
  String get blogExchangeChangeFailed =>
      'Diese Änderung konnte nicht bestätigt werden. Aktualisiere und versuch es erneut.';

  @override
  String get blogExchangeTitle => 'Ein privater Kapitel-Austausch';

  @override
  String get blogExchangeUnavailable =>
      'Dieser Austausch ist nicht mehr verfügbar.';

  @override
  String blogExchangeWith(String name) {
    return 'Mit $name';
  }

  @override
  String get blogExchangeIntro =>
      'Eine Antwort ist eine Einladung, nie eine Verpflichtung. Dieser Austausch erzeugt kein Match und schaltet keinen Chat frei.';

  @override
  String get blogAcceptExchange => 'Austausch annehmen';

  @override
  String get blogDeclineKindly => 'Freundlich ablehnen';

  @override
  String get blogResponseSentNote =>
      'Deine Antwort wurde gesendet. Es gibt keinen Countdown und du musst nicht nachhaken.';

  @override
  String get blogExchangeClosedNote =>
      'Dieser Austausch ist beendet. Mach in deinem Tempo Platz für eine neue Verbindung.';

  @override
  String get blogOneStoryEach => 'Für jeden von euch eine kleine Geschichte.';

  @override
  String get blogOneStoryEachBody =>
      'Füge eine kleine Fortsetzung, eine Erinnerung oder deine Version des Moments hinzu. Beide Beiträge erscheinen zusammen – erst, wenn ihr beide etwas eingereicht habt.';

  @override
  String get blogYourSideTitle => 'Deine Seite des Kapitels';

  @override
  String get blogYourSideHelp =>
      'Teile bis zu 1.000 Zeichen. Dein Gegenüber kann das erst lesen, wenn er oder sie auch etwas beiträgt. Nach dem Absenden lässt sich der Text nicht mehr bearbeiten; du kannst den Austausch aber jederzeit zurückziehen.';

  @override
  String get blogSubmitContribution => 'Meinen Beitrag absenden';

  @override
  String get blogAddContribution => 'Meinen Beitrag hinzufügen';

  @override
  String get blogYourContribution => 'Dein Beitrag';

  @override
  String blogPartnerContribution(String name) {
    return 'Beitrag von $name';
  }

  @override
  String get blogShapeDate => 'Gemeinsam ein Date planen';

  @override
  String get blogInspiredNote => 'Inspiriert von unserem Kapitel-Austausch.';

  @override
  String get blogTryStudio => 'First-Chapter-Studio ausprobieren';

  @override
  String get blogDatePlanningUnavailable =>
      'Die Date-Planung wird verfügbar, wenn ihr ein aktives Match habt und euer Chat freigeschaltet ist.';

  @override
  String get blogProposeJournalPage => 'Gemeinsame Tagebuchseite vorschlagen';

  @override
  String get blogSourceUnavailable =>
      'Das Originalkapitel ist nicht verfügbar.';

  @override
  String get blogContributionSaved =>
      'Dein Beitrag ist privat gespeichert. Aufgedeckt wird, wenn ihr beide so weit seid.';

  @override
  String get blogWithdrawExchangeTitle => 'Diesen Austausch zurückziehen?';

  @override
  String get blogWithdrawExchangeMessage =>
      'Die Antwort und die Beiträge sind dann für euch beide nicht mehr verfügbar. Gemeinsame öffentliche Links funktionieren ebenfalls nicht mehr.';

  @override
  String get blogWithdrawExchange => 'Austausch zurückziehen';

  @override
  String get blogReportExchange => 'Austausch melden';

  @override
  String get blogBlockMessageExchange =>
      'Kontakt und Zugriff auf die Kapitel des anderen werden beendet.';

  @override
  String get blogBlockFailed =>
      'Dieses Mitglied konnte nicht blockiert werden.';

  @override
  String get notificationsReadAll => 'Alle gelesen';

  @override
  String get notificationsFallbackTitle => 'Benachrichtigung';

  @override
  String get notificationsLoadFailed =>
      'Benachrichtigungen konnten nicht geladen werden.';

  @override
  String get notificationsPrefsUpdateFailed =>
      'Benachrichtigungseinstellungen konnten nicht aktualisiert werden.';

  @override
  String notificationsAgoMinutes(int count) {
    return 'vor $count Min.';
  }

  @override
  String notificationsAgoHours(int count) {
    return 'vor $count Std.';
  }

  @override
  String notificationsAgoDays(int count) {
    return 'vor $count T.';
  }

  @override
  String get wallsReactEyebrow => 'REAGIEREN';

  @override
  String wallsReactQuestion(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Was löst dieses Foto in dir aus?',
      'other': 'Was löst dieses Kapitel in dir aus?',
    });
    return '$_temp0';
  }

  @override
  String get wallsReactBody =>
      'Deine Reaktion zeigt ihnen, dass sie gehört wurden. Jede Reaktion zählt als Like.';

  @override
  String get wallsReactRemove => 'Meine Reaktion zurücknehmen';

  @override
  String wallsReactionsSemantics(String list) {
    return 'Reaktionen: $list';
  }

  @override
  String get wallsReactionLove => 'Liebe ich';

  @override
  String get wallsReactionHearYou => 'Ich höre dich';

  @override
  String get wallsReactionMeToo => 'Ich auch';

  @override
  String get wallsReactionWithYou => 'Ich bin bei dir';

  @override
  String get wallsReactionHug => 'Fühl dich gedrückt';

  @override
  String get wallsReactionProud => 'Stolz auf dich';

  @override
  String get wallsSignInRequired => 'Melde dich an, um deine Wand zu sehen.';

  @override
  String get celebrationCoverHeadline => 'Dein Foto ist das Cover der Woche';

  @override
  String celebrationReachHeadline(String kind, int reach) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'photo': 'Dein Foto hat $reach Wände erreicht',
      'other': 'Dein Kapitel hat $reach Wände erreicht',
    });
    return '$_temp0';
  }

  @override
  String get celebrationCoverMessage =>
      'Die Mitglieder lieben es. Diese Woche sehen es alle unter Heute.';

  @override
  String get celebrationReachMessage =>
      'Die Mitglieder lieben es. Es ist jetzt auf ihren Heute-Wänden.';

  @override
  String celebrationQuotedTitle(String title) {
    return '„$title“';
  }

  @override
  String get celebrationBarrier => 'Feier';

  @override
  String get celebrationLovely => 'Schön';

  @override
  String get celebrationSeePhoto => 'Foto ansehen';

  @override
  String get celebrationSeeChapter => 'Kapitel ansehen';

  @override
  String rewardXpPill(int xp) {
    return '+$xp XP';
  }

  @override
  String get rewardClaimedTitle => 'Belohnung eingelöst';

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
    return 'und $count weitere';
  }

  @override
  String rewardBadgeLine(String badge) {
    return 'Abzeichen: $badge';
  }

  @override
  String rewardLevelReached(int level) {
    return 'Level $level erreicht';
  }

  @override
  String rewardBadgesEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Abzeichen erhalten',
      one: 'Abzeichen erhalten',
    );
    return '$_temp0';
  }

  @override
  String get rewardYourRewardsToday => 'Deine Belohnungen heute';

  @override
  String rewardNewRewards(int count) {
    return '$count neue Belohnungen';
  }

  @override
  String get rewardSourceStoryPublished => 'Kapitel veröffentlicht';

  @override
  String get rewardSourcePhotoShared => 'Foto geteilt';

  @override
  String get rewardSourceLikeReceived => 'Jemand mag deinen Beitrag';

  @override
  String get rewardSourceCommentReceived => 'Neuer Kommentar zu deinem Beitrag';

  @override
  String get rewardSourceCommentApproved => 'Dein Kommentar wurde freigegeben';

  @override
  String get rewardSourceSubscriberGained => 'Neue Abonnentin / neuer Abonnent';

  @override
  String get rewardSourceWallTierReached => 'Wand-Stufe erreicht';

  @override
  String get rewardSourceCoverOfWeek => 'Cover der Woche';

  @override
  String get rewardSourceDailyPromptSubmitted => 'Tägliche Frage beantwortet';

  @override
  String get rewardLineStoryPublished => 'Dein Kapitel ist in der Welt.';

  @override
  String get rewardLinePhotoShared => 'Dein Foto ist jetzt Teil des Themas.';

  @override
  String get rewardLineLikeReceived => 'Jemand liebt, was du geteilt hast.';

  @override
  String get rewardLineCommentReceived =>
      'Jemand hat sich dem Gespräch angeschlossen.';

  @override
  String get rewardLineSubscriberGained =>
      'Jemand wartet auf dein nächstes Kapitel.';

  @override
  String get rewardLineWallTierReached =>
      'Dein Beitrag hat mehr Wände erreicht.';

  @override
  String get rewardLineCoverOfWeek => 'Diese Woche sehen es alle unter Heute.';

  @override
  String get rewardLineOther => 'Verdient für sinnvolle Aktivität.';

  @override
  String get rewardNewBadgeFallback => 'Neues Abzeichen';

  @override
  String get blockedUnknownUser => 'Unbekannte Person';

  @override
  String get themeTaglineBluerose =>
      'Mitternachtssamt, Saphirrosen und ein Hauch Platin.';

  @override
  String get themeTaglineBluelotus =>
      'Mondbeschienenes Wasser, Saphirblüten und ein goldenes Herz.';

  @override
  String discoverMessageLikeSent(String name) {
    return 'Love an $name gesendet. Ihr könnt chatten, sobald $name dich auch liked.';
  }

  @override
  String get notificationsDismissFailed =>
      'Die Benachrichtigung konnte nicht entfernt werden. Versuch es noch mal.';

  @override
  String get notificationsReadAllFailed =>
      'Konnte nicht alle als gelesen markieren. Versuch es noch mal.';

  @override
  String get blogReportSubmitted => 'Meldung gesendet. Danke!';

  @override
  String get settingsSectionAccount => 'Konto';

  @override
  String settingsSignedInAs(String username) {
    return 'Angemeldet als @$username';
  }

  @override
  String get settingsSignOut => 'Abmelden';

  @override
  String get settingsSignOutSubtitle => 'Beende deine Sitzung auf diesem Gerät';

  @override
  String get settingsSignOutAllTitle => 'Auf allen Geräten abmelden';

  @override
  String get settingsSignOutAllSubtitle =>
      'Beende jede Sitzung auf jedem Handy und in jedem Browser';

  @override
  String get settingsSignOutConfirmTitle => 'Abmelden?';

  @override
  String get settingsSignOutConfirmBody =>
      'Um dich auf diesem Gerät wieder anzumelden, brauchst du deinen Benutzernamen und dein Passwort.';

  @override
  String get settingsSignOutAllConfirmTitle => 'Auf allen Geräten abmelden?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'Damit endet deine Sitzung auf jedem Handy, Tablet und in jedem Browser, auch auf diesem Gerät. Wer anderswo mit deinem Konto angemeldet ist, wird abgemeldet.';

  @override
  String get settingsSignOutAllConfirmAction => 'Überall abmelden';

  @override
  String get settingsSignOutAllFailed =>
      'Deine anderen Geräte konnten nicht abgemeldet werden. Prüfe deine Verbindung und versuch es noch einmal.';
}
