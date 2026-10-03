// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get navDiscover => 'Ontdekken';

  @override
  String get navMatches => 'Matches';

  @override
  String get navEngage => 'Meedoen';

  @override
  String get navProfile => 'Profiel';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsSectionProfile => 'Profiel';

  @override
  String get settingsEditProfileTitle => 'Profiel bewerken';

  @override
  String get settingsEditProfileSubtitle => 'Werk je gegevens bij';

  @override
  String get settingsPhotosTitle => 'Foto\'s';

  @override
  String get settingsPhotosSubtitle => 'Beheer je foto\'s';

  @override
  String get settingsSectionPreferences => 'Voorkeuren';

  @override
  String get settingsAppearanceTitle => 'Uiterlijk';

  @override
  String get settingsAppearanceSubtitle => 'Opgeslagen in je account';

  @override
  String get settingsThemeLight => 'Licht';

  @override
  String get settingsThemeDark => 'Donker';

  @override
  String get settingsThemeMatchDevice => 'Zoals apparaat';

  @override
  String get settingsLooksTitle => 'Looks';

  @override
  String get settingsLooksClassicDescription =>
      'Overdag warm ivoor en bosgroen. ’s Avonds zachte munt en diep bosgroen.';

  @override
  String get settingsLooksClassicLabel => 'Vandaag';

  @override
  String get settingsThemeSaveFailed =>
      'Je thema kon niet worden opgeslagen. Probeer het opnieuw.';

  @override
  String get settingsLanguageTitle => 'Taal';

  @override
  String get settingsLanguageSubtitle => 'Kies de taal van de app';

  @override
  String get settingsDatingPreferencesTitle => 'Datingvoorkeuren';

  @override
  String get settingsDatingPreferencesSubtitle =>
      'Leeftijd, locatie, interesses';

  @override
  String get settingsAccountDataTitle => 'Account en gegevens';

  @override
  String get settingsAccountDataSubtitle =>
      'Je account verbergen, downloaden of verwijderen';

  @override
  String get settingsNotificationsTitle => 'Meldingen';

  @override
  String get settingsNotificationsSubtitle => 'Push- en e-mailmeldingen';

  @override
  String get settingsSectionEngagement => 'Meedoen';

  @override
  String get settingsTrustBadgesTitle => 'Vertrouwensbadges';

  @override
  String get settingsTrustBadgesSubtitle =>
      'Bekijk je verdiende badges en vertrouwensgeschiedenis';

  @override
  String get settingsTrustFiltersTitle => 'Vertrouwensfilters';

  @override
  String get settingsTrustFiltersSubtitle =>
      'Bepaal de vertrouwenseisen voor ontdekken';

  @override
  String get settingsConversationRoomsTitle => 'Gespreksruimtes';

  @override
  String get settingsConversationRoomsSubtitle =>
      'Bekijk, join, verlaat en modereer ruimtes';

  @override
  String get settingsFriendsTitle => 'Vrienden en connecties';

  @override
  String get settingsFriendsSubtitle =>
      'Bouw vriendschappen op en onderhoud ze';

  @override
  String get settingsCallHistoryTitle => 'Belgeschiedenis';

  @override
  String get settingsCallHistorySubtitle => 'Bekijk je eerdere gesprekken';

  @override
  String get settingsMatchNudgesTitle => 'Match-duwtjes';

  @override
  String get settingsMatchNudgesSubtitle =>
      'Blaas stille gesprekken nieuw leven in';

  @override
  String get settingsSubscriptionsTitle => 'Abonnementen';

  @override
  String get settingsSubscriptionsSubtitle =>
      'Abonnementen, toegangsstatus en betalingen';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsPrivacySafetyTitle => 'Privacy en veiligheid';

  @override
  String get settingsPrivacySafetySubtitle => 'Beheer je privacy-instellingen';

  @override
  String get settingsGovernmentVerificationTitle => 'Identiteitscontrole';

  @override
  String get settingsGovernmentVerificationSubtitle =>
      'Bekijk de status van je identiteitsverificatie';

  @override
  String get settingsQaVerificationUploadTitle => 'QA-verificatie-upload';

  @override
  String get settingsQaVerificationUploadSubtitle =>
      'ID- en selfieflow alleen voor automatisering';

  @override
  String get settingsHelpSupportTitle => 'Hulp en ondersteuning';

  @override
  String get settingsHelpSupportSubtitle =>
      'Veelgestelde vragen en contact met support';

  @override
  String get settingsAboutTitle => 'Over de app';

  @override
  String get settingsAboutSubtitle => 'App-details en techniek';

  @override
  String get settingsLogout => 'Uitloggen';

  @override
  String get languageTitle => 'Taal';

  @override
  String get languageIntro =>
      'Kies de taal waarin Connect wordt weergegeven. Je keuze wordt in je account opgeslagen en geldt op elk apparaat waarop je inlogt.';

  @override
  String get languageUseDevice => 'Taal van je apparaat gebruiken';

  @override
  String get languageUseDeviceSubtitle =>
      'Volgt de taalinstelling van je telefoon';

  @override
  String get languageSaveFailed =>
      'Je taal kon niet worden opgeslagen. Probeer het opnieuw.';

  @override
  String get notificationsTitle => 'Meldingen';

  @override
  String get notificationsInboxTitle => 'Meldingen-inbox';

  @override
  String get notificationsInboxCaughtUp => 'Je bent helemaal bij';

  @override
  String notificationsInboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ongelezen',
      one: '1 ongelezen',
    );
    return '$_temp0';
  }

  @override
  String get notificationsInAppTitle => 'Meldingen in de app';

  @override
  String get notificationsInAppSubtitle =>
      'Meldingen tonen terwijl je de app gebruikt';

  @override
  String get notificationsPushTitle => 'Pushmeldingen';

  @override
  String get notificationsPushSubtitle =>
      'Bezorging toestaan als de app op de achtergrond staat';

  @override
  String get notificationsNewMatchesTitle => 'Nieuwe matches';

  @override
  String get notificationsNewMatchesSubtitle =>
      'Krijg een melding als je een match hebt';

  @override
  String get notificationsNewMessagesTitle => 'Nieuwe berichten';

  @override
  String get notificationsNewMessagesSubtitle =>
      'Krijg een melding bij chatberichten';

  @override
  String get notificationsLikesTitle => 'Likes';

  @override
  String get notificationsLikesSubtitle =>
      'Krijg een melding als iemand je liket';

  @override
  String get notificationsMatchNudgesTitle => 'Match-duwtjes';

  @override
  String get notificationsMatchNudgesSubtitle =>
      'Krijg een melding als een match je een duwtje geeft';

  @override
  String get notificationsIncomingCallsTitle => 'Inkomende oproepen';

  @override
  String get notificationsIncomingCallsSubtitle =>
      'Meldingen van inkomende oproepen tonen';

  @override
  String get notificationsSafetyTitle => 'Veiligheidsupdates';

  @override
  String get notificationsSafetySubtitle =>
      'Ontvang belangrijke updates over je veiligheidsstatus';

  @override
  String get notificationsFriendPlansTitle => 'Dates van vrienden';

  @override
  String get notificationsFriendPlansSubtitle =>
      'Weet wanneer een vriend een date plant of laat weten dat alles goed is';

  @override
  String get welcomeTagline => 'Gemaakt voor het echte leven.';

  @override
  String get welcomePhotoNote => 'Offline is het doel.';

  @override
  String get welcomeHeadlineLead => 'Een goed verhaal\nbegint met ';

  @override
  String get welcomeHeadlineAccent => 'hallo.';

  @override
  String get welcomeBody =>
      'Vind iemand die echt bij je past. De rest komt vanzelf.';

  @override
  String get welcomeCreateAccount => 'Account aanmaken';

  @override
  String get welcomeAlreadyMember => 'Al lid? ';

  @override
  String get welcomeSignIn => 'Inloggen';

  @override
  String get welcomeFooter => '18+  ·  Jouw tempo. Jouw keuze.';

  @override
  String get authBackTooltip => 'Terug naar welkom';

  @override
  String get authHeadline => 'Fijn je weer te zien.';

  @override
  String get authSubtitle => 'Ga verder met je gebruikersnaam en wachtwoord';

  @override
  String get authWelcomeBack => 'Welkom terug';

  @override
  String get authNextHello => 'Je volgende hallo wacht op je.';

  @override
  String get authUsernameHint => 'gebruikersnaam';

  @override
  String get authPasswordHint => 'Wachtwoord';

  @override
  String get authShowPassword => 'Wachtwoord tonen';

  @override
  String get authHidePassword => 'Wachtwoord verbergen';

  @override
  String get authCantSignIn => 'Kun je niet inloggen?';

  @override
  String get authSignIn => 'Inloggen';

  @override
  String get authPrivacyNote =>
      'Je wachtwoord wordt alleen verstuurd als je inlogt en wordt nooit in de app opgeslagen.';

  @override
  String get authEnterUsername => 'Vul je gebruikersnaam in.';

  @override
  String get authEnterPassword => 'Vul je wachtwoord in.';

  @override
  String get commonYes => 'Ja';

  @override
  String get commonNo => 'Nee';

  @override
  String get planVenueCoffee => 'Koffie';

  @override
  String get planVenueMeal => 'Uit eten';

  @override
  String get planVenueDrinks => 'Een drankje';

  @override
  String get planVenueWalk => 'Een wandeling';

  @override
  String get planVenueActivity => 'Een activiteit';

  @override
  String get planVenueEvent => 'Een evenement';

  @override
  String get planVenueVideoCall => 'Videogesprek';

  @override
  String get planVenueOther => 'Iets anders';

  @override
  String planProposeTitle(String name) {
    return 'Plan een date met $name';
  }

  @override
  String get planProposeSubtitle =>
      'Geef samen vorm aan een eerste hallo. Delen met contacten staat eerst uit.';

  @override
  String get planProposeButton => 'Voorstellen';

  @override
  String planHeadlineProposed(String name) {
    return '$name heeft een date voorgesteld';
  }

  @override
  String planHeadlineWaiting(String name) {
    return 'Wachten op $name';
  }

  @override
  String get planHeadlineUpcoming => 'Het staat vast';

  @override
  String get planHeadlineCheckin => 'Hoe ging het?';

  @override
  String get planHeadlineDebrief => 'Hoe was het?';

  @override
  String get planHeadlineDebriefComplete => 'Nabespreking afgerond';

  @override
  String planHeadlineWaitingDebrief(String name) {
    return 'Wachten op de nabespreking van $name';
  }

  @override
  String get planHeadlineCheckedInSafe =>
      'Je hebt laten weten dat alles goed is';

  @override
  String get planHeadlineFriendsAlerted => 'Je verzoek om hulp is vastgelegd';

  @override
  String get planHeadlineDefault => 'Plan';

  @override
  String get planStatusProposed => 'Voorgesteld';

  @override
  String get planStatusConfirmed => 'Bevestigd';

  @override
  String get planDebriefButton => 'Nabespreking van tien seconden';

  @override
  String get planDecline => 'Afwijzen';

  @override
  String get planAccept => 'Accepteren';

  @override
  String get planFriendsKnowAccepted =>
      'Kies vertrouwde contacten om je updates mee te delen.';

  @override
  String get planFriendsKnowProposed =>
      'Delen met contacten is bij elk plan optioneel.';

  @override
  String get planCancel => 'Plan annuleren';

  @override
  String get planNeedHelp => 'Ik heb hulp nodig';

  @override
  String get planImSafe => 'Alles is goed';

  @override
  String get planCancelDialogTitle => 'Dit plan annuleren?';

  @override
  String planCancelDialogBody(String name) {
    return '$name en iedereen met wie je het hebt gedeeld krijgen bericht.';
  }

  @override
  String get planKeepIt => 'Behouden';

  @override
  String get planProposeIntro =>
      'Dit blijft tussen jou en je date. Kies na je voorstel vertrouwde contacten als je updates over het plan en de check-in wilt delen.';

  @override
  String get planSectionWhen => 'Wanneer';

  @override
  String get planSectionWhat => 'Wat';

  @override
  String get planSectionGroups => 'Vertrouwde contacten';

  @override
  String planDurationHours(int hours) {
    return '$hours u';
  }

  @override
  String get planPlaceLabel => 'Plek (optioneel)';

  @override
  String get planPlaceHint => 'Een openbare plek werkt het best';

  @override
  String get planAreaLabel => 'Buurt of wijk';

  @override
  String get planNoteLabel => 'Berichtje voor je match (optioneel)';

  @override
  String get planFutureTimeError => 'Kies een tijd in de toekomst.';

  @override
  String get planProposeFailed => 'Dit plan kon niet worden voorgesteld.';

  @override
  String get planSendButton => 'Plan versturen';

  @override
  String get planAcceptTitle => 'Plan accepteren?';

  @override
  String get planAcceptIntro =>
      'Accepteer dit plan met je date. Kies daarna vertrouwde contacten als je je updates wilt delen.';

  @override
  String get planAcceptButton => 'Plan accepteren';

  @override
  String debriefTitle(String name) {
    return 'Hoe was het met $name?';
  }

  @override
  String get debriefIntro =>
      'Je antwoorden zijn privé. Als jullie allebei bevestigen dat de date is doorgegaan, telt dat mee voor je Shows Up-badge.';

  @override
  String get debriefHappened => 'Is de date doorgegaan?';

  @override
  String get debriefMeetAgain => 'Zou je nog eens afspreken?';

  @override
  String get debriefFeltSafe => 'Voelde je je veilig?';

  @override
  String get debriefNoteLabel => 'Nog iets toe te voegen? (optioneel)';

  @override
  String get debriefMissingHappened =>
      'Laat ons weten of de date is doorgegaan.';

  @override
  String get debriefSaveFailed => 'Je nabespreking kon niet worden opgeslagen.';

  @override
  String get debriefSave => 'Nabespreking opslaan';

  @override
  String get debriefUnsafeTitle => 'Vervelend dat het niet veilig voelde';

  @override
  String debriefUnsafeBody(String name) {
    return 'Je antwoord wordt doorgegeven aan ons veiligheidsteam. Wil je $name ook rapporteren?';
  }

  @override
  String get debriefNotNow => 'Niet nu';

  @override
  String get debriefReport => 'Rapporteren';

  @override
  String get plansTitle => 'Dates';

  @override
  String get plansTabMine => 'Van mij';

  @override
  String get plansTabFriends => 'Vrienden';

  @override
  String get plansEmptyMineTitle => 'Nog geen plannen';

  @override
  String get plansEmptyMineBody =>
      'Stel een date voor vanuit een gesprek. Jij kiest of je updates over het plan en de check-in deelt met vertrouwde contacten.';

  @override
  String plansWith(String name) {
    return 'Met $name';
  }

  @override
  String get plansNextDecide => 'Wachten op je antwoord';

  @override
  String plansNextAwait(String name) {
    return 'Wachten op $name';
  }

  @override
  String get plansNextUpcoming => 'Bevestigd. Jullie tijd samen is gepland.';

  @override
  String get plansNextCheckin => 'Check in na je date';

  @override
  String get plansNextDebrief => 'Vertel ons hoe het ging';

  @override
  String get plansNextCancelled => 'Geannuleerd';

  @override
  String get plansNextDone => 'Klaar';

  @override
  String get plansEmptyFriendsTitle => 'Nog niets gedeeld';

  @override
  String get plansEmptyFriendsBody =>
      'Plannen verschijnen hier als vrienden er bewust voor kiezen ze met je te delen.';

  @override
  String get plansViaGroup => 'Met jou gedeeld';

  @override
  String get plansViaFriend => 'Vertrouwd contact';

  @override
  String plansFriendNeedsHelp(String name) {
    return '$name heeft om hulp gevraagd. Neem nu contact op.';
  }

  @override
  String plansFriendMissedCheckin(String name) {
    return '$name heeft nog niets laten weten.';
  }

  @override
  String plansFriendCheckedInSafe(String name, String via) {
    return '$name heeft laten weten dat alles goed is · $via';
  }

  @override
  String plansFriendStatusLine(String via, String status) {
    return '$via · $status';
  }

  @override
  String get plansStatusWordProposed => 'voorgesteld';

  @override
  String get plansStatusWordConfirmed => 'bevestigd';

  @override
  String get plansStatusWordCancelled => 'geannuleerd';

  @override
  String get plansStatusWordHappened => 'doorgegaan';

  @override
  String get chatEmptyDefault =>
      'Zeg hallo. Berichten verschijnen hier voor iedereen in dit gesprek.';

  @override
  String get chatNotSentRetry =>
      'Niet verstuurd. Tik op het bericht om het opnieuw te proberen.';

  @override
  String get chatRetrySend => 'Opnieuw versturen';

  @override
  String get chatCopyText => 'Tekst kopiëren';

  @override
  String get chatDeleteMine => 'Mijn bericht verwijderen';

  @override
  String get chatRemoveMessage => 'Bericht verwijderen';

  @override
  String get chatReportMessage => 'Bericht melden';

  @override
  String get chatThisMember => 'Dit lid';

  @override
  String get chatMember => 'Lid';

  @override
  String get chatCopied => 'Gekopieerd.';

  @override
  String get chatDeleteFailed =>
      'Verwijderen is niet gelukt. Probeer het opnieuw.';

  @override
  String get chatSubtitleFriends => 'Vrienden';

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leden',
      one: '1 lid',
    );
    return '$_temp0';
  }

  @override
  String get chatReconnecting =>
      'Opnieuw verbinden. Nieuwe berichten kunnen even duren.';

  @override
  String get chatUnavailable =>
      'Dit gesprek is niet beschikbaar. Misschien ben je geen lid meer.';

  @override
  String get chatTryAgain => 'Opnieuw proberen';

  @override
  String get chatStatusNotSent =>
      'Niet verstuurd · houd ingedrukt om opnieuw te proberen';

  @override
  String get chatStatusSending => 'Versturen…';

  @override
  String get chatMessageRemoved => 'Bericht verwijderd';

  @override
  String chatSemanticsYouAt(String time) {
    return 'Jij om $time';
  }

  @override
  String chatSemanticsMemberAt(String name, String time) {
    return '$name om $time';
  }

  @override
  String chatAboutMember(String name) {
    return 'Over $name';
  }

  @override
  String get chatComposerHint => 'Schrijf een bericht';

  @override
  String get chatMutedComposerHint => 'Je kunt nu even niets plaatsen';

  @override
  String get chatSend => 'Versturen';

  @override
  String chatRoomMutedUntil(String when) {
    return 'Je bent in deze ruimte gedempt tot $when. Meelezen kan nog steeds.';
  }

  @override
  String get chatRoomMuted =>
      'Je bent in deze ruimte gedempt. Meelezen kan nog steeds.';

  @override
  String chatReadOnlyUntil(String when) {
    return 'Je kunt dit gesprek lezen, maar tot $when niets plaatsen.';
  }

  @override
  String get chatReadOnly =>
      'Je kunt dit gesprek lezen, maar nu even niets plaatsen.';

  @override
  String get chatMuteTooltip => 'Meldingen dempen';

  @override
  String get chatMutedTooltip => 'Meldingen gedempt';

  @override
  String get chatMuteSheetTitle => 'Meldingen dempen';

  @override
  String get chatMuteSheetBody =>
      'Berichten komen hier gewoon binnen, alleen zonder meldingen.';

  @override
  String get chatMuteOneHour => '1 uur';

  @override
  String get chatMuteEightHours => '8 uur';

  @override
  String get chatMuteOneWeek => '1 week';

  @override
  String get chatMuteForever => 'Tot ik ze weer aanzet';

  @override
  String get chatUnmute => 'Meldingen weer aanzetten';

  @override
  String chatMutedUntilLabel(String when) {
    return 'Gedempt tot $when';
  }

  @override
  String get chatMutedIndefinitely => 'Gedempt tot je meldingen weer aanzet.';

  @override
  String get chatMuteDone => 'Meldingen gedempt.';

  @override
  String get chatUnmuteDone => 'Meldingen staan weer aan.';

  @override
  String get chatMuteFailed =>
      'Meldingen wijzigen is niet gelukt. Probeer het opnieuw.';

  @override
  String get roomsClosedSnack => 'Deze ruimte is gesloten.';

  @override
  String get roomsChatNotOpen => 'De chat van deze ruimte is nog niet open.';

  @override
  String get roomsJoinFailed =>
      'Deelnemen is niet gelukt. Probeer het opnieuw.';

  @override
  String get roomsStartRoom => 'Ruimte starten';

  @override
  String get roomsEyebrow => 'LIVECHAT';

  @override
  String get roomsTitle => 'Ruimtes';

  @override
  String get roomsSubtitle =>
      'Spring in een gesprek. Klikt het met iemand? Voeg die persoon toe als vriend.';

  @override
  String get roomsSectionRooms => 'RUIMTES';

  @override
  String get roomsSectionYours => 'JOUW RUIMTES';

  @override
  String get roomsYoursCaption =>
      'Ruimtes waar je in zit. Tik om verder te chatten.';

  @override
  String get roomsSectionLive => 'NU LIVE';

  @override
  String get roomsLiveTitle => 'Hier wordt nu gepraat';

  @override
  String get roomsSectionBrowse => 'BLADEREN';

  @override
  String get roomsBrowseTitle => 'Vind jouw ruimte';

  @override
  String get roomsBrowseCaption =>
      'Altijd open. Kies een onderwerp, zeg hallo en kijk met wie het klikt.';

  @override
  String get roomsNoFriendsHere =>
      'Er zit nu geen van je vrienden in een van deze ruimtes.';

  @override
  String get roomsNoRoomsInTopic => 'Nog geen ruimtes over dit onderwerp.';

  @override
  String get roomsSectionComingUp => 'BINNENKORT';

  @override
  String get roomsComingUpCaption =>
      'Ruimtes die leden organiseren. Doe vroeg mee om een plek te houden.';

  @override
  String get roomsCategoryAll => 'Alle';

  @override
  String get roomsCategoryTalk => 'Praten';

  @override
  String get roomsCategoryInterests => 'Interesses';

  @override
  String get roomsCategoryActive => 'Op pad';

  @override
  String get roomsCategoryCity => 'Jouw stad';

  @override
  String get roomsFriendsHereChip => 'Vrienden hier';

  @override
  String get roomsQuiet => 'Het is nu rustig. Zeg als eerste hallo.';

  @override
  String roomsPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensen',
      one: '1 persoon',
    );
    return '$_temp0';
  }

  @override
  String roomsRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ruimtes',
      one: '1 ruimte',
    );
    return '$_temp0';
  }

  @override
  String roomsChattingIn(String people, String rooms) {
    return '$people kletsen in $rooms';
  }

  @override
  String roomsHereNow(int count) {
    return '$count nu hier';
  }

  @override
  String roomsInTheRoom(int count) {
    return '$count in de ruimte';
  }

  @override
  String roomsFriendsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vrienden hier',
      one: '1 vriend hier',
    );
    return '$_temp0';
  }

  @override
  String get roomsHostedByYou => 'Georganiseerd door jou';

  @override
  String roomsHostedBy(String name) {
    return 'Georganiseerd door $name';
  }

  @override
  String get roomsActionOpen => 'Openen';

  @override
  String get roomsActionFull => 'Vol';

  @override
  String get roomsActionJoin => 'Meedoen';

  @override
  String roomsStartsAt(String time) {
    return 'Begint om $time';
  }

  @override
  String roomsStartsOn(String day, String time) {
    return 'Begint $day om $time';
  }

  @override
  String get roomsStartNameTooShort =>
      'Geef de ruimte een naam van minstens 3 tekens.';

  @override
  String get roomsStartIntro =>
      'Jij organiseert: je kunt mensen waarschuwen, dempen of verwijderen en de ruimte sluiten als je klaar bent. Eén ruimte tegelijk.';

  @override
  String get roomsStartNameLabel => 'Naam van de ruimte';

  @override
  String get roomsStartNameHint => 'Boekenruil op zondag';

  @override
  String get roomsStartAboutLabel => 'Waar gaat het over? (optioneel)';

  @override
  String get roomsStartTopic => 'Onderwerp';

  @override
  String get roomsStartHowLong => 'Hoe lang';

  @override
  String get roomsLength30Min => '30 min';

  @override
  String get roomsLength1Hour => '1 uur';

  @override
  String get roomsLength2Hours => '2 uur';

  @override
  String get roomsStartNow => 'Nu starten';

  @override
  String get roomsRoleHost => 'Host';

  @override
  String get roomsRoleModerator => 'Moderator';

  @override
  String get roomsRoomFallback => 'Ruimte';

  @override
  String roomsChatEmpty(String room) {
    return 'Je bent binnen. Zeg hallo: iedereen in $room ziet wat je hier schrijft.';
  }

  @override
  String get roomsPeopleTooltip => 'Mensen in deze ruimte';

  @override
  String roomsLeaveTitle(String room) {
    return '$room verlaten?';
  }

  @override
  String get roomsLeaveBody =>
      'Je ziet de berichten van deze ruimte dan niet meer. Zolang ze open is, kun je altijd terugkomen.';

  @override
  String get roomsLeaveAction => 'Ruimte verlaten';

  @override
  String get roomsLeaveFailed =>
      'Verlaten is niet gelukt. Probeer het opnieuw.';

  @override
  String roomsCloseTitle(String room) {
    return '$room sluiten?';
  }

  @override
  String get roomsCloseBody =>
      'De chat stopt voor iedereen in de ruimte. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get roomsCloseAction => 'Ruimte sluiten';

  @override
  String get roomsCloseFailed => 'Sluiten is niet gelukt. Probeer het opnieuw.';

  @override
  String get roomsMenuTooltip => 'Opties voor ruimte';

  @override
  String get roomsMenuPeople => 'Wie er is';

  @override
  String get roomsMenuModerate => 'Modereren';

  @override
  String roomsModerateTitle(String room) {
    return '$room modereren';
  }

  @override
  String get roomsModerateIntro =>
      'Tik op iemand om diegene te waarschuwen, te dempen of te verwijderen. Gedempte leden kunnen nog meelezen; verwijderde leden kunnen terugkomen als de sessie voorbij is.';

  @override
  String get roomsPeopleIntro =>
      'Klikt het met iemand? Voeg die persoon toe als vriend om na de ruimte verder te praten.';

  @override
  String get roomsMembersLoadFailed => 'Kon niet laden wie er is.';

  @override
  String get roomsStatusFriend => 'Vriend';

  @override
  String get roomsStatusHereNow => 'Nu hier';

  @override
  String get roomsStatusInRoom => 'In de ruimte';

  @override
  String get roomsStatusGone => 'Niet meer in de ruimte';

  @override
  String roomsStatusMutedUntil(String time) {
    return 'Gedempt tot $time';
  }

  @override
  String roomsYouSuffix(String name) {
    return '$name (jij)';
  }

  @override
  String roomsRemoveTitle(String name) {
    return '$name uit de ruimte verwijderen?';
  }

  @override
  String roomsRemoveBodyAlwaysOn(String name) {
    return '$name verlaat de chat nu en kan na 24 uur terugkomen.';
  }

  @override
  String roomsRemoveBodyHosted(String name) {
    return '$name verlaat de chat nu en kan pas weer meedoen als deze ruimte is afgelopen.';
  }

  @override
  String roomsWarnTitle(String name) {
    return '$name waarschuwen?';
  }

  @override
  String roomsWarnBody(String name) {
    return '$name krijgt een privéherinnering om het gesprek vriendelijk en bij het onderwerp te houden.';
  }

  @override
  String get roomsRemoveAction => 'Verwijderen';

  @override
  String get roomsWarnAction => 'Waarschuwing sturen';

  @override
  String roomsRemovedDone(String name) {
    return '$name is uit de ruimte verwijderd.';
  }

  @override
  String roomsWarnedDone(String name) {
    return 'Waarschuwing gestuurd naar $name.';
  }

  @override
  String get roomsModerationFailed =>
      'Dat is niet gelukt. Probeer het opnieuw.';

  @override
  String roomsBlockedDone(String name) {
    return 'Je hebt $name geblokkeerd. Jullie zien hier elkaars berichten niet meer.';
  }

  @override
  String get roomsReport => 'Melden';

  @override
  String get roomsBlock => 'Blokkeren';

  @override
  String get roomsModerateEyebrow => 'MODEREREN';

  @override
  String get roomsWarn => 'Waarschuwen';

  @override
  String get roomsRemoveFromRoom => 'Uit de ruimte verwijderen';

  @override
  String get roomsMute => 'Dempen';

  @override
  String get roomsUnmute => 'Dempen opheffen';

  @override
  String roomsMuteSheetTitle(String name) {
    return '$name dempen?';
  }

  @override
  String roomsMuteSheetBody(String name) {
    return '$name kan de chat nog lezen, maar niets plaatsen tot het dempen voorbij is. Diegene krijgt een privébericht.';
  }

  @override
  String get roomsMuteTenMinutes => '10 minuten';

  @override
  String get roomsMuteOneHour => '1 uur';

  @override
  String get roomsMuteUntilEnd => 'Tot de ruimte afloopt';

  @override
  String get roomsMuteOneDay => '24 uur';

  @override
  String roomsMutedDone(String name) {
    return '$name is gedempt.';
  }

  @override
  String roomsUnmutedDone(String name) {
    return '$name kan weer berichten plaatsen.';
  }

  @override
  String get richFormattingToolbar => 'Opmaak';

  @override
  String get richUndo => 'Ongedaan maken';

  @override
  String get richRedo => 'Opnieuw';

  @override
  String get richBold => 'Vet';

  @override
  String get richItalic => 'Cursief';

  @override
  String get richUnderline => 'Onderstrepen';

  @override
  String get richStrikethrough => 'Doorhalen';

  @override
  String get richHighlight => 'Markeren';

  @override
  String get richLink => 'Link';

  @override
  String get richTextStyleMenu => 'Tekststijl';

  @override
  String get richParagraph => 'Alinea';

  @override
  String get richHeading => 'Kop';

  @override
  String get richSubheading => 'Tussenkop';

  @override
  String get richQuote => 'Citaat';

  @override
  String get richCallout => 'Kader';

  @override
  String get richBulletList => 'Opsomming';

  @override
  String get richNumberedList => 'Genummerde lijst';

  @override
  String get richDivider => 'Scheiding';

  @override
  String get richAlignMenu => 'Uitlijning';

  @override
  String get richAlignStart => 'Uitlijnen aan begin';

  @override
  String get richAlignCenter => 'Centreren';

  @override
  String get richAlignEnd => 'Uitlijnen aan eind';

  @override
  String get richClearFormatting => 'Opmaak wissen';

  @override
  String get richWritingStyle => 'Schrijfstijl';

  @override
  String get richStyleClassic => 'Klassiek';

  @override
  String get richStyleClassicHint =>
      'Elegante schreefletter, als een gedrukte pagina';

  @override
  String get richStyleModern => 'Modern';

  @override
  String get richStyleModernHint => 'Strak en goed leesbaar';

  @override
  String get richStyleJournal => 'Dagboek';

  @override
  String get richStyleJournalHint => 'Warme cursief, als een dagboekpagina';

  @override
  String get richStyleTypewriter => 'Typemachine';

  @override
  String get richStyleTypewriterHint => 'Hoekige letters met extra ruimte';

  @override
  String get richStylePoetic => 'Poëtisch';

  @override
  String get richStylePoeticHint => 'Gecentreerde regels met ruimte';

  @override
  String richWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count woorden',
      one: '1 woord',
    );
    return '$_temp0';
  }

  @override
  String get richAlignmentNote =>
      'Uitlijning en witruimte zie je in het voorbeeld en zien je lezers.';

  @override
  String get richLinkTitle => 'Link toevoegen';

  @override
  String get richLinkField => 'Webadres';

  @override
  String get richLinkInvalid => 'Gebruik een volledig https://-adres.';

  @override
  String get richLinkApply => 'Link toevoegen';

  @override
  String get richLinkRemove => 'Link verwijderen';

  @override
  String get richLinkNeedsSelection =>
      'Selecteer eerst de woorden die je wilt linken.';

  @override
  String get richCancel => 'Annuleren';

  @override
  String get richOpenLinkTitle => 'Deze link openen?';

  @override
  String richOpenLinkBody(String host) {
    return '$host opent buiten Connect. Open alleen links die je vertrouwt.';
  }

  @override
  String get richOpenLink => 'Link openen';

  @override
  String get supportCentreEyebrow => 'HULP & SUPPORT';

  @override
  String get supportCentreTitle => 'Waarmee kunnen we helpen?';

  @override
  String get supportCentreSubtitle =>
      'Vind snel een antwoord of vraag het ons team. Elke vraag en elk antwoord blijft in één privégesprek.';

  @override
  String get supportContactSection => 'CONTACT';

  @override
  String get supportContactTitle => 'Contact met support';

  @override
  String get supportContactSubtitle =>
      'Vertel ons wat er gebeurde. We antwoorden hier en laten het je weten.';

  @override
  String get supportMyTicketsTitle => 'Mijn verzoeken';

  @override
  String get supportMyTicketsSubtitle => 'Volg je verzoeken en onze antwoorden';

  @override
  String supportOpenRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open verzoeken',
      one: '1 open verzoek',
    );
    return '$_temp0';
  }

  @override
  String supportUnreadReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieuwe antwoorden',
      one: '1 nieuw antwoord',
    );
    return '$_temp0';
  }

  @override
  String get supportQuickAnswersSection => 'SNELLE ANTWOORDEN';

  @override
  String get supportFaqLoginTitle => 'Inloggen';

  @override
  String get supportFaqLoginBody =>
      'Log in met je unieke gebruikersnaam en wachtwoord.';

  @override
  String get supportFaqVerificationTitle => 'Verificatie';

  @override
  String get supportFaqVerificationBody =>
      'Identiteitsverificatie is optioneel zolang de aanbieder gepauzeerd is.';

  @override
  String get supportFaqAbuseTitle => 'Misbruik';

  @override
  String get supportFaqAbuseBody =>
      'Gebruik Melden op een profiel of gesprek voor een snellere veiligheidsbeoordeling.';

  @override
  String get supportFaqBillingTitle => 'Facturering';

  @override
  String get supportFaqBillingBody =>
      'Vermeld het transactienummer, nooit je kaartgegevens.';

  @override
  String get supportEmergencyNote =>
      'Is iemand in direct gevaar? Neem contact op met de lokale hulpdiensten. Supportverzoeken vervangen geen noodhulp.';

  @override
  String get supportUnavailableTitle =>
      'Supportverzoeken zijn nu niet beschikbaar';

  @override
  String get supportUnavailableBody =>
      'De antwoorden op deze pagina werken nog steeds. Mail voor iets dringends naar support@connect.example.';

  @override
  String get supportBackToHelp => 'Terug naar Hulp & support';

  @override
  String get supportFormEyebrow => 'NIEUW VERZOEK';

  @override
  String get supportFormTitle => 'Contact met support';

  @override
  String get supportFormSubtitle =>
      'Geef ons genoeg details om actie te ondernemen. Deel nooit een wachtwoord, herstelcode, kaartnummer of identiteitsbewijs.';

  @override
  String get supportFormCategorySection => 'ONDERWERP';

  @override
  String get supportFormCategoryLabel => 'Waarmee heb je hulp nodig?';

  @override
  String get supportCategoryAccountLogin => 'Account & inloggen';

  @override
  String get supportCategoryVerification => 'Verificatie';

  @override
  String get supportCategoryPaymentsBilling => 'Betalingen & facturering';

  @override
  String get supportCategorySafetyHarassment => 'Veiligheid & intimidatie';

  @override
  String get supportCategoryMatchesChat => 'Matches & chat';

  @override
  String get supportCategoryTechnical => 'Technisch probleem of bug';

  @override
  String get supportCategoryFeatureRequest => 'Functieverzoek';

  @override
  String get supportCategoryPrivacyData => 'Privacy & gegevensverzoek';

  @override
  String get supportCategoryOther => 'Anders';

  @override
  String get supportSafetyNote =>
      'Ben jij of is iemand anders in direct gevaar? Gebruik SOS in de app of bel de lokale hulpdiensten. Veiligheidsverzoeken krijgen voorrang, maar een verzoek is geen noodlijn.';

  @override
  String get supportOpenSos => 'SOS openen';

  @override
  String get supportFormDetailsSection => 'DETAILS';

  @override
  String get supportFormSubjectLabel => 'Onderwerp';

  @override
  String get supportFormSubjectHint => 'Beschrijf het probleem kort';

  @override
  String get supportFormDescriptionLabel => 'Wat is er gebeurd?';

  @override
  String get supportFormDescriptionHint =>
      'Wat je deed, wat je verwachtte en wat er in plaats daarvan gebeurde';

  @override
  String get supportFormScreenshotsSection => 'SCREENSHOTS';

  @override
  String supportFormScreenshotsCaption(int max) {
    return 'Optioneel. Maximaal $max afbeeldingen.';
  }

  @override
  String get supportAddScreenshot => 'Screenshot toevoegen';

  @override
  String supportRemoveAttachment(String name) {
    return '$name verwijderen';
  }

  @override
  String get supportAttachmentUploading => 'Bezig met uploaden';

  @override
  String get supportRetryUpload => 'Opnieuw uploaden';

  @override
  String supportFormDeviceNote(String version) {
    return 'We voegen je appversie ($version), platform, systeemversie en taal toe om het probleem te helpen oplossen.';
  }

  @override
  String get supportSubmit => 'Verzoek versturen';

  @override
  String get supportErrorCategoryRequired => 'Kies een onderwerp.';

  @override
  String supportErrorSubjectLength(int min, int max) {
    return 'Gebruik $min tot $max tekens voor het onderwerp.';
  }

  @override
  String get supportErrorDescriptionRequired => 'Beschrijf wat er gebeurde.';

  @override
  String supportErrorDescriptionTooLong(int max) {
    return 'Blijf onder de $max tekens.';
  }

  @override
  String get supportErrorUploadsPending =>
      'Wacht tot je screenshots zijn geüpload of verwijder de mislukte.';

  @override
  String supportCreatedSnack(String reference) {
    return 'Verzoek $reference verstuurd. We antwoorden hier.';
  }

  @override
  String supportDuplicateSnack(String reference) {
    return 'Je hebt dit verzoek al verstuurd, dus we hebben het geopend: $reference.';
  }

  @override
  String supportErrorRateLimited(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Je hebt in korte tijd meerdere verzoeken verstuurd. Probeer het over $minutes minuten opnieuw.',
      one:
          'Je hebt in korte tijd meerdere verzoeken verstuurd. Probeer het over 1 minuut opnieuw.',
    );
    return '$_temp0';
  }

  @override
  String get supportErrorRateLimitedGeneric =>
      'Je hebt in korte tijd meerdere verzoeken verstuurd. Probeer het later opnieuw.';

  @override
  String get supportErrorTooManyOpen =>
      'Je hebt al 10 open verzoeken. Sluit er een die je niet meer nodig hebt of wacht op onze antwoorden.';

  @override
  String get supportErrorTicketClosed =>
      'Dit verzoek is gesloten en kan niet meer worden heropend. Start een nieuw verzoek.';

  @override
  String get supportErrorReopenWindowPassed =>
      'De termijn om dit verzoek te heropenen is verstreken. Start een nieuw verzoek.';

  @override
  String get supportErrorAlreadyRated => 'Je hebt dit verzoek al beoordeeld.';

  @override
  String get supportErrorNotResolved =>
      'Je kunt een verzoek beoordelen zodra het is opgelost.';

  @override
  String get supportErrorAttachmentType =>
      'Alleen JPEG- of PNG-afbeeldingen en pdf-bestanden kunnen worden bijgevoegd.';

  @override
  String get supportErrorAttachmentTooLarge =>
      'Dat bestand is te groot. Afbeeldingen mogen maximaal 8 MB zijn.';

  @override
  String get supportErrorOffline =>
      'Connect is nu niet bereikbaar. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get supportErrorNotFound => 'We konden dit verzoek niet vinden.';

  @override
  String get supportErrorGeneric => 'Er ging iets mis. Probeer het opnieuw.';

  @override
  String get supportTryAgain => 'Opnieuw proberen';

  @override
  String get supportTicketsEyebrow => 'SUPPORT';

  @override
  String get supportTicketsTitle => 'Mijn verzoeken';

  @override
  String get supportTicketsSubtitle => 'Je verzoeken en onze antwoorden.';

  @override
  String get supportTicketsActiveSection => 'ACTIEF';

  @override
  String get supportTicketsClosedSection => 'OPGELOST & GESLOTEN';

  @override
  String get supportTicketsEmptyTitle => 'Nog geen verzoeken';

  @override
  String get supportTicketsEmptyBody =>
      'Als je contact opneemt met support, verschijnen je verzoek en onze antwoorden hier.';

  @override
  String get supportTicketsLoadErrorTitle =>
      'Je verzoeken konden niet worden geladen';

  @override
  String supportTicketUpdated(String when) {
    return 'Bijgewerkt $when';
  }

  @override
  String get supportNewTicket => 'Nieuw verzoek';

  @override
  String get supportStatusOpen => 'Open';

  @override
  String get supportStatusWaitingForYou => 'Wacht op jou';

  @override
  String get supportStatusOnHold => 'Gepauzeerd';

  @override
  String get supportStatusResolved => 'Opgelost';

  @override
  String get supportStatusClosed => 'Gesloten';

  @override
  String supportStatusSemantics(String status) {
    return 'Status: $status';
  }

  @override
  String get supportThreadAgentName => 'Connect Support';

  @override
  String get supportThreadYou => 'Jij';

  @override
  String supportTicketMeta(String category, String date) {
    return '$category · Geopend op $date';
  }

  @override
  String get supportBannerOpen =>
      'We hebben je verzoek. Ons team antwoordt hier en laat het je weten.';

  @override
  String get supportBannerWaiting =>
      'Support heeft geantwoord en wacht op jouw reactie.';

  @override
  String get supportBannerOnHold =>
      'Je verzoek is gepauzeerd terwijl we het uitzoeken. We houden je hier op de hoogte.';

  @override
  String get supportBannerResolved =>
      'Gemarkeerd als opgelost. Antwoord om het te heropenen; anders wordt het na 7 dagen automatisch gesloten.';

  @override
  String supportBannerClosedUntil(String date) {
    return 'Dit verzoek is gesloten. Je kunt het heropenen tot $date.';
  }

  @override
  String get supportBannerClosed => 'Dit verzoek is gesloten.';

  @override
  String supportBannerMerged(String reference) {
    return 'Dit verzoek is samengevoegd met $reference. Het gesprek gaat daar verder.';
  }

  @override
  String get supportReplyHint => 'Schrijf een antwoord';

  @override
  String get supportReplyDisabledHint =>
      'Antwoorden is niet meer mogelijk voor dit verzoek';

  @override
  String get supportSendReply => 'Antwoord versturen';

  @override
  String get supportAttachScreenshot => 'Screenshot bijvoegen';

  @override
  String get supportCloseTicket => 'Verzoek sluiten';

  @override
  String get supportCloseConfirmTitle => 'Dit verzoek sluiten?';

  @override
  String get supportCloseConfirmBody =>
      'Sluit het als je probleem is opgelost. Je kunt het 14 dagen lang heropenen.';

  @override
  String get supportCancel => 'Annuleren';

  @override
  String get supportClosedSnack => 'Verzoek gesloten.';

  @override
  String get supportReopen => 'Verzoek heropenen';

  @override
  String get supportReopenedSnack => 'Verzoek heropend.';

  @override
  String get supportRateTitle => 'Hoe hebben we het gedaan?';

  @override
  String get supportRateCaption => 'Beoordeel je ervaring met dit verzoek.';

  @override
  String supportRateStar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sterren',
      one: '1 ster',
    );
    return '$_temp0';
  }

  @override
  String get supportRateCommentLabel => 'Nog iets toe te voegen? (optioneel)';

  @override
  String get supportRateSubmit => 'Beoordeling versturen';

  @override
  String get supportRatedTitle => 'Bedankt voor je feedback';

  @override
  String supportRatedValue(int rating) {
    return 'Je gaf dit een $rating van 5.';
  }

  @override
  String get supportRatingSnack => 'Bedankt voor je beoordeling.';

  @override
  String supportAttachmentImage(String name) {
    return 'Screenshot $name';
  }

  @override
  String get supportAttachmentLoadFailed => 'Bijlage kon niet worden geladen';

  @override
  String get supportThreadLoadErrorTitle =>
      'Dit verzoek kon niet worden geladen';

  @override
  String get chemistryCardEntry => 'Een beetje chemie?';

  @override
  String get memberProfileIntroducing => 'Maak kennis met';

  @override
  String get memberProfileStarring => 'In de hoofdrol';

  @override
  String get memberProfileVerified => 'Geverifieerd';

  @override
  String memberProfilePhotoLabel(String name, int index, int count) {
    return '$name, foto $index van $count';
  }

  @override
  String get memberProfileNoPhoto => 'Nog geen foto';

  @override
  String get memberProfileViewPhotoHint => 'op volledig scherm bekijken';

  @override
  String get memberProfileCloseGallery => 'Foto\'s sluiten';

  @override
  String get memberProfilePhotos => 'Foto\'s';

  @override
  String memberProfileMorePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nog $count foto\'s',
      one: 'nog 1 foto',
    );
    return '$_temp0';
  }

  @override
  String get memberProfileSceneAbout => 'Over mij';

  @override
  String get memberProfileSceneStories => 'Verhalen';

  @override
  String get memberProfileSceneStoriesTitle => 'Een beetje meer van mij';

  @override
  String get memberProfileSceneInterests => 'Interesses';

  @override
  String get memberProfileSceneBasics => 'De basis';

  @override
  String get memberProfileSceneLifestyle => 'Levensstijl';

  @override
  String get memberProfileSceneTrust => 'Vertrouwen';

  @override
  String get memberProfileReadMore => 'Lees meer';

  @override
  String get memberProfileReadLess => 'Minder tonen';

  @override
  String get memberProfileHobbies => 'Hobby\'s';

  @override
  String get memberProfileActivities => 'Activiteiten';

  @override
  String get memberProfileSongs => 'Op repeat';

  @override
  String get memberProfileBooks => 'Boeken en romans';

  @override
  String get memberProfileLookingFor => 'Zoekt';

  @override
  String get memberProfileLanguages => 'Talen';

  @override
  String get memberProfileDealBreakers => 'Dealbreakers';

  @override
  String get memberProfileInCommon => 'Gemeenschappelijk';

  @override
  String get memberProfileFactHeight => 'Lengte';

  @override
  String memberProfileHeightCm(int cm) {
    return '$cm cm';
  }

  @override
  String get memberProfileFactWork => 'Werk';

  @override
  String get memberProfileFactEducation => 'Opleiding';

  @override
  String get memberProfileFactLivesIn => 'Woont in';

  @override
  String get memberProfileFactMotherTongue => 'Moedertaal';

  @override
  String get memberProfileFactReligion => 'Religie';

  @override
  String get memberProfileFactPersonality => 'Persoonlijkheid';

  @override
  String get memberProfileFactRelationship => 'Relatiestatus';

  @override
  String get memberProfileFactInstagram => 'Instagram';

  @override
  String get memberProfileFactDrinking => 'Alcohol';

  @override
  String get memberProfileFactSmoking => 'Roken';

  @override
  String get memberProfileFactWorkout => 'Sporten';

  @override
  String get memberProfileFactDiet => 'Eetpatroon';

  @override
  String get memberProfileFactDietType => 'Dieet';

  @override
  String get memberProfileFactSleep => 'Slaap';

  @override
  String get memberProfileFactTravel => 'Reizen';

  @override
  String get memberProfileFactPets => 'Huisdieren';

  @override
  String get memberProfileFactPolitics => 'Politiek';

  @override
  String get memberProfileFactOpenToCasual => 'Open voor iets luchtigs';

  @override
  String get memberProfileFactPartyLover => 'Houdt van feesten';

  @override
  String get memberProfileVerifiedTitle => 'Geverifieerd profiel';

  @override
  String get memberProfileVerifiedBody => 'Identiteitscontrole voltooid.';

  @override
  String get memberProfileVouchesTitle => 'Aanbevolen door vrienden';

  @override
  String get memberProfileSpotlight => 'Uitgelicht';

  @override
  String get memberProfileFreeWhenYouAre => 'Vrij als jij vrij bent';

  @override
  String get memberProfileMessage => 'Bericht';

  @override
  String get memberProfileLove => 'Hartje';

  @override
  String get memberProfileReport => 'Melden';

  @override
  String get memberProfileOwnerTitle => 'Zo zien anderen jou';

  @override
  String get memberProfileOwnerCaption => 'Leden zien je profiel precies zo.';

  @override
  String memberProfileCompleteness(int percent) {
    return 'Profiel $percent% compleet';
  }

  @override
  String get memberProfileCompletenessHint =>
      'Voeg foto\'s, verhalen en details toe om op te vallen.';

  @override
  String get memberProfileCompletenessDone => 'Je profiel is compleet.';

  @override
  String get memberProfileToolEdit => 'Profiel bewerken';

  @override
  String get memberProfileToolPhotos => 'Foto\'s bewerken';

  @override
  String get memberProfileToolStories => 'Jouw verhalen';

  @override
  String get memberProfileToolViewers => 'Wie je bekeek';

  @override
  String get memberProfileBehindTheScenes => 'Achter de schermen';

  @override
  String get memberProfileOnlyYou => 'Alleen jij ziet dit.';

  @override
  String get memberProfileMine => 'Mijn profiel';

  @override
  String get profileShowcaseLabel => 'Teksten & momenten';

  @override
  String get profileShowcaseTitleOther => 'In eigen woorden';

  @override
  String get profileShowcaseTitleSelf => 'Jouw openbare teksten & foto\'s';

  @override
  String get profileShowcaseChapters => 'Hoofdstukken';

  @override
  String get profileShowcasePhotos => 'Muurfoto\'s';

  @override
  String get profileShowcaseReadAll => 'Alle hoofdstukken lezen';

  @override
  String get profileShowcaseHiddenTitle => 'Alleen jij ziet dit';

  @override
  String get profileShowcaseHiddenBody =>
      'Je openbare hoofdstukken en muurfoto\'s zijn verborgen op je profiel. Zet dit aan zodat leden ze hier zien.';

  @override
  String get profileShowcaseShownBody =>
      'Leden zien deze op je profiel. Alleen hoofdstukken die je met de community deelt en foto\'s op de muur verschijnen.';

  @override
  String get profileShowcaseSwitch => 'Tonen op mijn profiel';

  @override
  String get profileShowcaseSaveFailed =>
      'Je keuze kon niet worden opgeslagen.';

  @override
  String get callsHistoryTitle => 'Belgeschiedenis';

  @override
  String get callsHistoryEmpty => 'Nog geen gesprekken.';

  @override
  String callsHistoryMatch(String id) {
    return 'Match $id';
  }

  @override
  String get callsJoinLiveRoom => 'Naar de live-ruimte';

  @override
  String get callsActiveSession => 'Lopend gesprek';

  @override
  String callsEndedWithDuration(String duration) {
    return 'Beëindigd · $duration';
  }

  @override
  String get callsSessionTitle => 'Gesprek';

  @override
  String get callsStarting => 'Beveiligde sessie wordt gestart…';

  @override
  String get callsSessionActive => 'Gesprek actief';

  @override
  String get callsSessionUnavailable => 'Gesprek niet beschikbaar';

  @override
  String get callsLiveRoomNote =>
      'De live-ruimte opent in een beveiligd venster van de aanbieder. Gebruik tijdens het gesprek daar de knoppen voor microfoon, camera en verlaten.';

  @override
  String get callsEnd => 'Ophangen';

  @override
  String get callsErrorSignInHistory =>
      'Log in om je belgeschiedenis te bekijken.';

  @override
  String get callsErrorSignInStart => 'Log in voordat je een gesprek start.';

  @override
  String get callsErrorPermissions =>
      'Voor gesprekken is toegang tot camera en microfoon nodig.';

  @override
  String get callsErrorLoadHistory =>
      'Belgeschiedenis kan niet worden geladen.';

  @override
  String get callsErrorStart => 'Het gesprek kan niet worden gestart.';

  @override
  String get callsErrorEnd => 'Het gesprek kan niet worden beëindigd.';

  @override
  String get callsErrorNotConfigured =>
      'Live-belruimtes zijn niet ingesteld voor deze omgeving.';

  @override
  String get callsErrorOpenRoom => 'De live-belruimte kan niet worden geopend.';

  @override
  String get commonRetry => 'Opnieuw proberen';

  @override
  String get commonCancel => 'Annuleren';

  @override
  String get commonClose => 'Sluiten';

  @override
  String get commonCopy => 'Kopiëren';

  @override
  String get commonDelete => 'Verwijderen';

  @override
  String get commonBack => 'Terug';

  @override
  String get commonApply => 'Toepassen';

  @override
  String get commonReset => 'Resetten';

  @override
  String get commonOpen => 'Openen';

  @override
  String get commonView => 'Bekijken';

  @override
  String get commonDismiss => 'Negeren';

  @override
  String get commonAny => 'Alle';

  @override
  String get commonSomethingWentWrong => 'Er ging iets mis';

  @override
  String get commonSomethingWentWrongTryAgain =>
      'Er ging iets mis. Probeer het opnieuw.';

  @override
  String get commonTryAgainTitle => 'Opnieuw proberen';

  @override
  String get commonNothingHereYet => 'Hier is nog niets';

  @override
  String commonLoadingLabel(String label) {
    return '$label, laden';
  }

  @override
  String commonDistanceKm(int distance) {
    return '$distance km';
  }

  @override
  String get navToday => 'Vandaag';

  @override
  String get navOfflineBanner =>
      'Offlinemodus: sommige gegevens zijn mogelijk verouderd.';

  @override
  String navWeakNetworkBanner(int mbps) {
    return 'Zwak netwerk gedetecteerd. Gebruik minstens $mbps Mbps voor een soepelere app.';
  }

  @override
  String get navIncomingCallTitle => 'Inkomende oproep';

  @override
  String get navIncomingCallBody => 'Een match belt je.';

  @override
  String get navViewCallDetails => 'Belgegevens bekijken';

  @override
  String get filterSheetTitle => 'Matches filteren';

  @override
  String get filterAgeRange => 'Leeftijdsbereik';

  @override
  String get filterProfileLifestyle => 'Profiel- en levensstijlfilters';

  @override
  String get filterCountry => 'Land';

  @override
  String get filterState => 'Staat/regio';

  @override
  String get filterCity => 'Stad';

  @override
  String get filterMotherTongue => 'Moedertaal';

  @override
  String get filterReligion => 'Religie';

  @override
  String get filterRelationshipStatus => 'Relatiestatus';

  @override
  String get filterSmoking => 'Roken';

  @override
  String get filterDrinking => 'Alcohol';

  @override
  String get filterPersonalityType => 'Persoonlijkheidstype';

  @override
  String get filterPartyLoverOnly => 'Alleen feestliefhebbers';

  @override
  String get filterHookupsOnly => 'Alleen losse contacten';

  @override
  String get filterAdvancedBio => 'Geavanceerde bio-filters';

  @override
  String get filterAdvancedBioBody =>
      'Boeken, romans, liedjes, hobby’s, locatie en andere tags beheer je in Instellingen → Datingvoorkeuren.';

  @override
  String get filterOpenDatingPreferences => 'Datingvoorkeuren openen';

  @override
  String get filterDistanceKm => 'Afstand (km)';

  @override
  String get filterVerifiedOnlyTitle => 'Alleen geverifieerd';

  @override
  String get filterVerifiedOnlyBody => 'Alleen geverifieerde profielen tonen';

  @override
  String get filterVerifiedOnlyChip => 'Alleen geverifieerd';

  @override
  String get filterPartyLoverChip => 'Feestliefhebber';

  @override
  String get filterHookupChip => 'Alleen los contact';

  @override
  String get filterEnableTrust => 'Filteren op vertrouwen inschakelen';

  @override
  String filterMinimumTrustBadges(int count) {
    return 'Minimum aantal actieve vertrouwensbadges: $count';
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
      'true': ', alleen geverifieerd',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(trust, {
      'true': ', vertrouwensfilter aan',
      'other': ', vertrouwensfilter uit',
    });
    return 'Filters opgeslagen: $minAge-$maxAge jaar, $distance km$_temp0$_temp1';
  }

  @override
  String get optionNever => 'Nooit';

  @override
  String get optionOccasionally => 'Af en toe';

  @override
  String get optionSocially => 'Sociaal';

  @override
  String get optionRegularly => 'Regelmatig';

  @override
  String get optionSingle => 'Single';

  @override
  String get optionDivorced => 'Gescheiden';

  @override
  String get optionWidowed => 'Weduwe/weduwnaar';

  @override
  String get optionSeparated => 'Uit elkaar';

  @override
  String get optionComplicated => 'Ingewikkeld';

  @override
  String get optionIntrovert => 'Introvert';

  @override
  String get optionAmbivert => 'Ambivert';

  @override
  String get optionExtrovert => 'Extravert';

  @override
  String get optionHighSchool => 'Middelbare school';

  @override
  String get optionBachelors => 'Bachelor';

  @override
  String get optionMasters => 'Master';

  @override
  String get optionPhd => 'Doctoraat';

  @override
  String get optionOther => 'Anders';

  @override
  String get optionPreferNotToSay => 'Zeg ik liever niet';

  @override
  String get optionHindu => 'Hindoe';

  @override
  String get optionMuslim => 'Moslim';

  @override
  String get optionChristian => 'Christelijk';

  @override
  String get optionSikh => 'Sikh';

  @override
  String get optionBuddhist => 'Boeddhistisch';

  @override
  String get optionJain => 'Jain';

  @override
  String get optionJewish => 'Joods';

  @override
  String get optionSpiritual => 'Spiritueel';

  @override
  String get optionAgnostic => 'Agnostisch';

  @override
  String get optionAtheist => 'Atheïstisch';

  @override
  String get storiesNudgeTitle => 'Vertel iets meer van je verhaal';

  @override
  String get storiesNudgeBodyUnknown =>
      'Korte verhalen op je profiel geven mensen iets echts om hallo over te zeggen.';

  @override
  String get storiesNudgeActionOpen => 'Open je verhalen';

  @override
  String get storiesNudgeBodyEmpty =>
      'Voeg een kort verhaal toe aan je profiel: een klein geluk, een weekend dat het delen waard is. Mensen lezen dit voordat ze hallo zeggen.';

  @override
  String get storiesNudgeActionFirst => 'Schrijf je eerste verhaal';

  @override
  String get storiesNudgeCompleteTitle => 'Je verhaal is compleet';

  @override
  String get storiesNudgeCompleteBody =>
      'Alle drie de verhalen staan op je profiel. Vernieuw er een wanneer het leven je een nieuw verhaal geeft.';

  @override
  String get storiesNudgeActionEdit => 'Je verhalen bewerken';

  @override
  String storiesNudgeSharedTitle(int count, int max) {
    return '$count van $max verhalen gedeeld';
  }

  @override
  String get storiesNudgeBodyMore =>
      'Nog een verhaal geeft mensen een extra manier om een gesprek te beginnen.';

  @override
  String storiesNudgeBodyLatest(String prompt) {
    return 'Laatste: ‘$prompt’. Nog een geeft mensen een extra manier om een gesprek te beginnen.';
  }

  @override
  String get storiesNudgeActionAdd => 'Nog een verhaal toevoegen';

  @override
  String get storiesNudgeIdeas => 'Ideeën om mee te beginnen';

  @override
  String storiesProgressSemantics(int count, int max) {
    return '$count van $max verhalen geschreven';
  }

  @override
  String get storiesPromptLittleJoy =>
      'Iets kleins waar ik altijd tijd voor maak';

  @override
  String get storiesPromptWeekend => 'Een weekend dat het delen waard is';

  @override
  String get storiesPromptFirstHello =>
      'Een eerste hallo waar ik blij van zou worden';

  @override
  String get storiesPromptLearning =>
      'Iets wat ik aan het leren ben, gewoon voor mezelf';

  @override
  String get storiesPromptCare =>
      'Een kleine manier waarop ik laat zien dat ik om iemand geef';

  @override
  String get storiesScreenTitle => 'Een beetje meer jij';

  @override
  String get storiesSignIn => 'Log in om je verhalen te bewerken.';

  @override
  String get storiesLoadFailed => 'Je verhalen konden niet worden geladen.';

  @override
  String get storiesTryAgain => 'Opnieuw proberen';

  @override
  String get storiesIncomplete =>
      'Voeg tekst toe aan elk verhaal en een beschrijving aan elke foto, of verwijder het onafgemaakte verhaal.';

  @override
  String get storiesPublished => 'Je profielverhalen zijn gepubliceerd.';

  @override
  String get storiesSavedPrivately =>
      'Privé opgeslagen. Je verhalen zijn verborgen voor andere leden.';

  @override
  String get storiesSaveUnconfirmed =>
      'We konden het opslaan niet bevestigen. Je wijzigingen staan er nog; laad de opgeslagen verhalen opnieuw om het te controleren.';

  @override
  String get storiesHeadline =>
      'Laat iemand kennismaken\nmet de alledaagse jij.';

  @override
  String get storiesIntro =>
      'Een klein ritueel, het verhaal achter een foto, een eerste hallo waar je van zou genieten. Deel tot drie momenten, in je eigen woorden.';

  @override
  String get storiesOptionalNote =>
      'Optioneel, zonder score of verplichting om alles in te vullen. Vermijd contactgegevens of precieze locaties die je niet wilt delen.';

  @override
  String get storiesPublishSwitch => 'Deze verhalen op mijn profiel tonen';

  @override
  String get storiesPublishSwitchHint =>
      'Staat standaard uit. Zichtbaar voor geschikte leden als je profiel gepubliceerd en beschikbaar is. Je kunt ze altijd verbergen.';

  @override
  String get storiesBackToEditing => 'Terug naar bewerken';

  @override
  String get storiesPreview => 'Voorbeeld van mijn verhalen';

  @override
  String get storiesPreviewBanner => 'VOORBEELD · WORDT NIET GEPUBLICEERD';

  @override
  String get storiesAdd => 'Verhaal toevoegen';

  @override
  String get storiesReloadDiscard =>
      'Opgeslagen verhalen herladen · wijzigingen negeren';

  @override
  String get storiesSaving => 'Opslaan…';

  @override
  String get storiesPublishButton => 'Verhalen publiceren';

  @override
  String get storiesSavePrivatelyButton => 'Privé opslaan';

  @override
  String get storiesPolicyNote =>
      'Foto\'s komen uit je goedgekeurde profielgalerij. Verhalen en foto\'s blijven onderworpen aan meldingen van leden en het veiligheidsbeleid.';

  @override
  String storiesMomentLabel(int number) {
    return 'MOMENT $number';
  }

  @override
  String storiesRemoveTooltip(int number) {
    return 'Verhaal $number verwijderen';
  }

  @override
  String get storiesPromptLabel => 'Een startpunt';

  @override
  String get storiesTextLabel => 'In je eigen woorden';

  @override
  String get storiesTextHint => 'Een echt detail maakt het van jou.';

  @override
  String get storiesTextRequired =>
      'Voeg een paar woorden toe of verwijder dit verhaal.';

  @override
  String get storiesPhotoLabel => 'Een foto, als je wilt';

  @override
  String get storiesWordsOnly => 'Alleen tekst';

  @override
  String storiesProfilePhoto(int number) {
    return 'Profielfoto $number';
  }

  @override
  String get storiesPhotoDescriptionLabel => 'Beschrijf deze foto';

  @override
  String get storiesPhotoDescriptionHelper =>
      'Helpt mensen die een schermlezer gebruiken.';

  @override
  String get storiesPhotoDescriptionRequired =>
      'Voeg een korte fotobeschrijving toe.';

  @override
  String get storiesPhotoSemantics => 'Foto bij profielverhaal';

  @override
  String get storiesSectionTitle => 'Een beetje meer ik';

  @override
  String get storiesRetryLoad => 'Verhalen opnieuw laden';

  @override
  String get authErrorSessionExpired => 'Je bent uitgelogd. Log opnieuw in.';

  @override
  String get authErrorSignInFailed =>
      'Inloggen lukt niet. Probeer het opnieuw.';

  @override
  String get authErrorCreateAccountFailed =>
      'Account aanmaken lukt niet. Probeer het opnieuw.';

  @override
  String get authErrorCreateAccountGeneric => 'Account aanmaken lukt niet.';

  @override
  String get authErrorInvalidCredentials =>
      'Gebruikersnaam of wachtwoord is onjuist.';

  @override
  String get authErrorUsernameFormat =>
      'Je gebruikersnaam moet 3–30 tekens zijn: letters, cijfers, _ of .';

  @override
  String get authErrorPasswordFormat =>
      'Je wachtwoord moet 8–72 bytes zijn, met letters en cijfers.';

  @override
  String get authWelcomeIntroducerLink => 'Ik wil alleen vrienden voorstellen';

  @override
  String get signupBackTooltip => 'Terug';

  @override
  String get signupIntroducerTitle => 'Wees de vriend die mensen samenbrengt.';

  @override
  String get signupIntroducerBody =>
      'Een account alleen voor vrienden. Geen datingprofiel, foto\'s of swipen. Je leeftijd blijft privé; Connect is voor volwassenen van 18–80.';

  @override
  String get signupTitle => 'Maak je account aan';

  @override
  String get signupSubtitle =>
      'Kies een unieke gebruikersnaam en een veilig wachtwoord';

  @override
  String get signupUsernameLabel => 'Unieke gebruikersnaam';

  @override
  String get signupUsernameHint => 'jouw_gebruikersnaam';

  @override
  String get signupUsernameHelp =>
      '3–30 tekens. Letters, cijfers, underscore en punt.';

  @override
  String get signupPasswordLabel => 'Wachtwoord';

  @override
  String get signupPasswordHint => 'Minstens 8 tekens';

  @override
  String get signupConfirmPasswordHint => 'Bevestig wachtwoord';

  @override
  String get signupNameLabel => 'Volledige naam';

  @override
  String get signupNameHint => 'Je naam';

  @override
  String get signupDobLabel => 'Geboortedatum';

  @override
  String get signupDobPickerHelp => 'Kies je geboortedatum';

  @override
  String get signupDobPlaceholder => 'Kies een datum';

  @override
  String get signupGenderLabel => 'Ik identificeer me als';

  @override
  String get signupGenderMan => 'Man';

  @override
  String get signupGenderWoman => 'Vrouw';

  @override
  String get signupGenderOther => 'Anders';

  @override
  String get signupCreateFriendAccount => 'Vriendenaccount aanmaken';

  @override
  String get signupAlreadyHaveAccount => 'Heb je al een account?';

  @override
  String get signupErrorPasswordMismatch =>
      'De wachtwoorden komen niet overeen.';

  @override
  String get signupErrorFullName => 'Vul je volledige naam in.';

  @override
  String get signupErrorDobMissing => 'Kies je geboortedatum.';

  @override
  String get signupErrorUnderage => 'Je moet minstens 18 jaar oud zijn.';

  @override
  String get signupErrorAgeRange =>
      'Connect is momenteel beschikbaar voor leden van 18–80 jaar.';

  @override
  String get signupErrorGenderMissing => 'Kies hoe je je identificeert.';

  @override
  String get authRecoveryEnterUsername => 'Vul je gebruikersnaam in.';

  @override
  String get authRecoveryEnterCode => 'Vul je herstelcode in.';

  @override
  String get authRecoveryPasswordRule =>
      'Gebruik 8–72 tekens met minstens één letter en één cijfer.';

  @override
  String get authRecoveryResetDone =>
      'Je wachtwoord is opnieuw ingesteld en alle apparaten zijn uitgelogd. Log in met je nieuwe wachtwoord.';

  @override
  String get authRecoveryAssistanceDone =>
      'Als deze gebruikersnaam bij een Connect-account hoort, bekijkt ons veiligheidsteam het verzoek.';

  @override
  String get authRecoveryInvalidCode =>
      'Deze herstelcode is ongeldig of verlopen.';

  @override
  String get authRecoveryOffline =>
      'Connect is niet bereikbaar. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get authRecoverySendFailed =>
      'Je verzoek kon niet worden verstuurd. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get authRecoveryBackToSignIn => 'Terug naar inloggen';

  @override
  String get authRecoveryHaveCode => 'Ik heb mijn code';

  @override
  String get authRecoveryLostCode => 'Ik ben mijn code kwijt';

  @override
  String get authRecoveryHaveCodeIntro =>
      'Gebruik de herstelcode die je bij het aanmaken van je account hebt bewaard, of een code van ons veiligheidsteam.';

  @override
  String get authRecoveryLostCodeIntro =>
      'Geef ons je gebruikersnaam. We bevestigen je identiteit voordat we een herstelcode uitgeven. We vragen nooit om je wachtwoord.';

  @override
  String get authRecoveryUsernameLabel => 'Gebruikersnaam';

  @override
  String get authRecoveryCodeLabel => 'Herstelcode';

  @override
  String get authRecoveryNewPasswordLabel => 'Nieuw wachtwoord';

  @override
  String get authRecoveryMessageLabel => 'Alles wat ons helpt (optioneel)';

  @override
  String get authRecoveryMessageHint =>
      'Bijvoorbeeld wanneer je voor het laatst hebt ingelogd';

  @override
  String get authRecoverySending => 'Versturen…';

  @override
  String get authRecoveryResetPassword => 'Wachtwoord opnieuw instellen';

  @override
  String get authRecoveryAskForHelp => 'Om hulp vragen';

  @override
  String get authTermsTitle => 'Algemene voorwaarden';

  @override
  String get authTermsSubtitle => 'Even doorlezen voordat je de app gebruikt.';

  @override
  String get authTermsIntro =>
      'Lees en accepteer onze Voorwaarden en ons Privacybeleid om verder te gaan.';

  @override
  String get authTermsCommunityTitle => 'Wat we van de community verwachten';

  @override
  String get authTermsPointRespect => 'Wees respectvol en authentiek.';

  @override
  String get authTermsPointNoHarassment =>
      'Geen intimidatie of frauduleus gedrag.';

  @override
  String get authTermsPointPrivacy =>
      'Jij bepaalt je privacyinstellingen en de zichtbaarheid van je profiel.';

  @override
  String get authTermsPointReports =>
      'Meldingen worden beoordeeld om de community veilig te houden.';

  @override
  String get authTermsPointViolations =>
      'Overtredingen kunnen leiden tot schorsing of verwijdering van je account.';

  @override
  String get authTermsReviewLater =>
      'Je kunt het volledige beleid later in de instellingen nalezen, maar je moet het accepteren voordat je de app gebruikt.';

  @override
  String get authTermsAgreeCheckbox =>
      'Ik ga akkoord met de Voorwaarden en het Privacybeleid';

  @override
  String get authTermsAcceptButton => 'Accepteren en doorgaan';

  @override
  String get authTermsSaveFailed =>
      'Je akkoord kon niet worden opgeslagen. Controleer je verbinding en probeer het opnieuw.';

  @override
  String discoverSuperLikeSent(String name) {
    return 'Superlike verstuurd naar $name';
  }

  @override
  String get discoverMatchPlaceholderMessage => 'Zeg hallo';

  @override
  String discoverChatNeedsMatch(String name) {
    return 'Je kunt met $name chatten zodra er een echte match is.';
  }

  @override
  String get discoverDailyLimitTitle => 'Je likes voor vandaag zijn op';

  @override
  String get discoverDailyLimitBody =>
      'Kom morgen terug of upgrade voor meer likes per dag.';

  @override
  String discoverDailyLimitResetBody(String reset) {
    return '$reset. Upgrade voor meer likes per dag.';
  }

  @override
  String get discoverSeePlans => 'Bekijk abonnementen';

  @override
  String get discoverNotNow => 'Niet nu';

  @override
  String get discoverBackToToday => 'Terug naar Vandaag';

  @override
  String get discoverExploreTitle => 'Verkennen';

  @override
  String get discoverSpotlightReviewed => 'Alle uitgelichte profielen bekeken!';

  @override
  String get discoverAllReviewed => 'Alles bekeken!';

  @override
  String get discoverCuratedForYou => 'Voor jou geselecteerd';

  @override
  String get discoverTitle => 'Ontdek matches';

  @override
  String get discoverTagline => 'Een beetje nieuwsgierigheid. Een echte klik.';

  @override
  String get discoverMessages => 'Berichten';

  @override
  String get discoverFilters => 'Filters';

  @override
  String get discoverYourDeck => 'Je stapel';

  @override
  String get discoverStatReady => 'Klaar';

  @override
  String get discoverStatLiked => 'Geliket';

  @override
  String get discoverStatPassed => 'Overgeslagen';

  @override
  String get discoverEdit => 'Bewerken';

  @override
  String get discoverShowingEveryone =>
      'Iedereen binnen je voorkeuren wordt getoond.';

  @override
  String get discoverToday => 'Vandaag';

  @override
  String get discoverTodaySubtitle => 'Vijf suggesties, elke dag nieuw.';

  @override
  String get discoverViewAll => 'Alles bekijken';

  @override
  String get discoverMatchOnYourTerms => 'Match op jouw voorwaarden';

  @override
  String get discoverMatchOnYourTermsBody =>
      'Een match ontstaat bij wederzijdse interesse. Je kunt iedereen blokkeren of melden via hun profiel of het gesprek.';

  @override
  String get discoverErrorEyebrow => 'Verbinding onderbroken';

  @override
  String get discoverErrorTitle => 'Kan profielen niet laden';

  @override
  String discoverTrustFilteredBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Vertrouwensfilters verborgen $count profielen. Versoepel ze of vernieuw om je stapel opnieuw op te bouwen.',
      one:
          'Vertrouwensfilters verborgen $count profiel. Versoepel ze of vernieuw om je stapel opnieuw op te bouwen.',
    );
    return '$_temp0';
  }

  @override
  String get discoverDeckPreparingBody =>
      'Je stapel wordt klaargezet. Vernieuw om nieuwe geverifieerde profielen in de buurt te zien.';

  @override
  String get discoverCheckBackSoon => 'Kom snel terug';

  @override
  String get discoverNoSpotlightProfiles => 'Geen uitgelichte profielen';

  @override
  String get discoverNoProfiles => 'Geen profielen';

  @override
  String get discoverRefresh => 'Vernieuwen';

  @override
  String get discoverPromisePrivate => 'Privé';

  @override
  String get discoverPremium => 'Premium';

  @override
  String discoverNotificationsUnread(int count) {
    return 'Meldingen, $count ongelezen';
  }

  @override
  String get discoverLatestUnreadNotifications =>
      'Nieuwste ongelezen meldingen';

  @override
  String get discoverNoUnreadNotifications => 'Geen ongelezen meldingen';

  @override
  String get discoverNotificationWhoReplied => 'Wie mij antwoordde';

  @override
  String discoverNotificationRepliesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieuwe antwoorden',
      one: '1 nieuw antwoord',
    );
    return '$_temp0';
  }

  @override
  String get discoverNotificationWhoLiked => 'Wie mij heeft geliket';

  @override
  String discoverNotificationLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieuwe likes',
      one: '1 nieuwe like',
    );
    return '$_temp0';
  }

  @override
  String get discoverViewMore => 'Meer bekijken';

  @override
  String get discoverFitsYourWeek => 'Past in je week';

  @override
  String discoverTodayPicks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suggesties',
      one: '1 suggestie',
    );
    return '$_temp0';
  }

  @override
  String get discoverPickedForYouToday => 'Vandaag voor jou gekozen.';

  @override
  String get discoverErrorLoginToDiscover =>
      'Log in om profielen te ontdekken.';

  @override
  String get discoverErrorLoadProfiles =>
      'Profielen laden mislukt. Probeer het opnieuw.';

  @override
  String get discoverErrorSessionUnavailable =>
      'Sessie niet beschikbaar. Log opnieuw in.';

  @override
  String get discoverErrorLikeRetry =>
      'Liken lukt nu niet. Probeer het opnieuw.';

  @override
  String get discoverErrorLike => 'Liken lukt nu niet.';

  @override
  String get discoverErrorPassRetry =>
      'Overslaan lukt nu niet. Probeer het opnieuw.';

  @override
  String get discoverErrorLoadLikedMe =>
      'Kan niet laden wie je heeft geliket. Probeer het opnieuw.';

  @override
  String get discoverErrorAnswerInFlight => 'Je antwoord wordt al verstuurd.';

  @override
  String get discoverErrorAnswer =>
      'Je antwoord kon niet worden verstuurd. Probeer het opnieuw.';

  @override
  String get firstChapterTopicPace => 'Communicatietempo';

  @override
  String get firstChapterTopicDates => 'Comfortabel daten';

  @override
  String get firstChapterTopicLanguage => 'Talen';

  @override
  String get firstChapterTopicFamily => 'Rol van familie';

  @override
  String get firstChapterInMyWords => 'In mijn woorden';

  @override
  String firstChapterComfortOriginal(String language) {
    return 'Origineel · $language';
  }

  @override
  String firstChapterComfortMemberTranslation(String language) {
    return 'Vertaling door het lid · $language';
  }

  @override
  String get firstChapterComfortReloadSaved => 'Opgeslagen versie herladen';

  @override
  String get firstChapterComfortReloadCards => 'Kaarten herladen';

  @override
  String get firstChapterComfortHeadline => 'Jouw woorden. Jouw grenzen.';

  @override
  String get firstChapterComfortIntro =>
      'Optionele context voor mensen met wie je een match hebt. Er wordt niets afgeleid uit je achtergrond. Schrijf in de taal die bij je past.';

  @override
  String get firstChapterComfortShareTitle =>
      'Deel deze kaarten met mijn matches';

  @override
  String get firstChapterComfortShareSubtitle => 'Uit houdt elke kaart privé.';

  @override
  String get firstChapterComfortRemoveFromDraft => 'Uit concept verwijderen';

  @override
  String get firstChapterComfortTopicLabel => 'Een beetje context over';

  @override
  String get firstChapterComfortOriginalLanguage => 'Oorspronkelijke taal';

  @override
  String get firstChapterComfortOwnWords => 'In je eigen woorden';

  @override
  String get firstChapterComfortOwnWordsHint =>
      'Bijvoorbeeld: ik hou van dates overdag en een beetje tijd om op mijn gemak te raken.';

  @override
  String get firstChapterComfortTranslation => 'Jouw vertaling (optioneel)';

  @override
  String get firstChapterComfortTranslationLanguage =>
      'Taal van de vertaling (indien toegevoegd)';

  @override
  String get firstChapterComfortTranslationNote =>
      'Vertalingen worden gemarkeerd als aangeleverd door het lid. Je oorspronkelijke woorden blijven altijd bewaard.';

  @override
  String get firstChapterComfortAddCard =>
      'Kaart toevoegen / vervangen in concept';

  @override
  String get firstChapterComfortMissingFields =>
      'Voeg je woorden en de taal toe. Een vertaling heeft ook een taal nodig.';

  @override
  String get firstChapterComfortUnaddedCard =>
      'Voeg je geschreven kaart toe aan het concept voordat je opslaat.';

  @override
  String get firstChapterComfortSaveFailed =>
      'Je concept staat er nog. Herlaad om de laatst opgeslagen versie te controleren voordat je het opnieuw probeert.';

  @override
  String get firstChapterSaving => 'Opslaan…';

  @override
  String get firstChapterComfortSave => 'Mijn keuzes opslaan';

  @override
  String get firstChapterYourMatch => 'je match';

  @override
  String get firstChapterSaveUnconfirmed =>
      'We konden het opslaan niet bevestigen. Vernieuw om te controleren voordat je het opnieuw probeert.';

  @override
  String get firstChapterJointPreviewTitle =>
      'Een verhaal dat jullie allebei goedkeuren';

  @override
  String get firstChapterSoloPreviewTitle =>
      'Voorbeeld van je openbare hoofdstuk';

  @override
  String firstChapterThenSurprise(String surprise) {
    return 'Toen… $surprise';
  }

  @override
  String get firstChapterJointPreviewBody =>
      'Jouw goedkeuring is de helft. De link werkt pas als je partner ook precies deze kaart goedkeurt. Jullie kunnen hem allebei intrekken.';

  @override
  String get firstChapterSoloPreviewBody =>
      'Alleen deze scène en het begin dat je koos zijn openbaar. Geen namen, foto\'s, privéchat, locatie of bijdrage van je partner. Je kunt de link intrekken.';

  @override
  String get firstChapterKeepPrivate => 'Privé houden';

  @override
  String get firstChapterApproveMyHalf => 'Mijn helft goedkeuren';

  @override
  String get firstChapterCreateShareLink => 'Deellink maken';

  @override
  String get firstChapterStudioTitle => 'Eerste Hoofdstuk Studio';

  @override
  String get firstChapterRefresh => 'Hoofdstuk vernieuwen';

  @override
  String get firstChapterHeroEyebrow => 'EEN KLEIN AVONTUUR. TWEE AUTEURS.';

  @override
  String get firstChapterHeroTitle => 'Wat er hierna\ngebeurt, is aan jullie.';

  @override
  String get firstChapterHeroSolo =>
      'Maak een scène. Geef hem door aan een vriend. Of maak een eerste hoofdstuk met iemand met wie je een match hebt.';

  @override
  String firstChapterHeroPair(String name) {
    return 'Jij en $name. Eén begin, één onverwachte wending en een verhaal dat jullie echt kunnen maken.';
  }

  @override
  String get firstChapterHeroPace =>
      'Optioneel, in je eigen tempo. Chatten is altijd een keuze.';

  @override
  String get firstChapterLoadFailed => 'Je hoofdstuk kon niet worden geladen.';

  @override
  String get firstChapterTryAgain => 'Opnieuw proberen';

  @override
  String get firstChapterStepChooseScene => '01 / Kies je scène';

  @override
  String get firstChapterStepWriteBeginning => '02 / Schrijf het begin';

  @override
  String get firstChapterStartOurChapter => 'Ons hoofdstuk beginnen';

  @override
  String get firstChapterPassTheChapter => 'Geef het hoofdstuk door';

  @override
  String get firstChapterYourFirstChapter => 'Jullie eerste hoofdstuk';

  @override
  String get firstChapterItBeginsWith => 'HET BEGINT MET';

  @override
  String get firstChapterAndThen => 'EN TOEN…';

  @override
  String firstChapterDateIdeaNote(String beginning, String surprise) {
    return '$beginning. Toen $surprise.';
  }

  @override
  String get firstChapterMakeDateIdea => 'Maak hier een date-idee van';

  @override
  String get firstChapterDateIdeaHint =>
      'Een voorstel om samen vorm te geven. Er wordt niets automatisch geboekt of geaccepteerd.';

  @override
  String get firstChapterYourTurn => 'Jouw beurt: voeg een verrassing toe.';

  @override
  String get firstChapterBeginningSaved =>
      'Je begin is opgeslagen. Je match kan een verrassing toevoegen wanneer die wil. Jullie kunnen gewoon blijven chatten.';

  @override
  String get firstChapterClose => 'Dit hoofdstuk sluiten';

  @override
  String get firstChapterGiveBackTitle => 'Verhalen die iets teruggeven';

  @override
  String get firstChapterGiveBackBody =>
      'Jullie band kan een nieuw begin inspireren. Deel alleen dit anonieme date-idee, met goedkeuring van jullie allebei.';

  @override
  String get firstChapterPreviewAnonymous =>
      'Voorbeeld van ons anonieme verhaal';

  @override
  String get firstChapterGreenLightTitle => 'Een privé groen licht';

  @override
  String get firstChapterInTheirWords => 'In hun woorden';

  @override
  String get firstChapterMakeRoomTitle =>
      'Maak ruimte voor wat jij belangrijk vindt';

  @override
  String get firstChapterMakeRoomSubtitle =>
      'Je tempo, talen, dates en verwachtingen van familie. Jouw woorden, alleen gedeeld als jij dat kiest.';

  @override
  String get firstChapterCreateWithConnection => 'Maak samen met een connectie';

  @override
  String get firstChapterCreateTogether => 'Samen een eerste hoofdstuk maken';

  @override
  String get firstChapterMatchesAppearHere =>
      'Je wederzijdse matches verschijnen hier. Je kunt nu alvast een solo-scène proberen en delen.';

  @override
  String get firstChapterSharedChapters => 'Je gedeelde hoofdstukken';

  @override
  String get firstChapterReloadShared => 'Gedeelde hoofdstukken herladen';

  @override
  String get firstChapterNothingPublic =>
      'Niets is openbaar totdat jij besluit te delen.';

  @override
  String get firstChapterGreenChat => 'Blijven chatten';

  @override
  String get firstChapterGreenCall => 'Een keer bellen';

  @override
  String get firstChapterGreenDate => 'Een date voorstellen';

  @override
  String get firstChapterGreenLightIntro =>
      'Alleen een gedeelde keuze wordt zichtbaar. Niemand ziet een onbeantwoord verzoek. Keuzes verlopen na zeven dagen; wis ze om ze in te trekken.';

  @override
  String get firstChapterSavePrivately => 'Privé opslaan';

  @override
  String get firstChapterGreenLightNone =>
      'Een gedeelde volgende stap verschijnt hier.';

  @override
  String firstChapterGreenLightMutual(String choices) {
    return 'Jullie voelen je allebei goed bij: $choices';
  }

  @override
  String get firstChapterGreenLightNote =>
      'Groen licht betekent toestemming om iets voor te stellen. Voor een gesprek of date is nog steeds aparte instemming nodig.';

  @override
  String get firstChapterLinkRevoked => 'Link ingetrokken';

  @override
  String get firstChapterPublicScene => 'Openbare, anonieme scène';

  @override
  String get firstChapterPrivateUntilBoth =>
      'Privé totdat jullie allebei goedkeuren';

  @override
  String get firstChapterLinkCopied =>
      'Hoofdstuklink gekopieerd. Deel hem waar je maar wilt.';

  @override
  String get firstChapterCopyLink => 'Link kopiëren';

  @override
  String get firstChapterApproveStory => 'Precies dit verhaal goedkeuren';

  @override
  String get firstChapterRevokeLink => 'Link intrekken';

  @override
  String networkSlowResponse(int mbps) {
    return 'Zwak netwerk gedetecteerd. Gebruik minstens $mbps Mbps voor soepelere chats, cadeaus en gebaren.';
  }

  @override
  String get networkOffline =>
      'Geen stabiele netwerkverbinding. Maak opnieuw verbinding om de app te blijven gebruiken.';

  @override
  String networkWeak(int mbps) {
    return 'Het netwerk is zwak. Gebruik minstens $mbps Mbps voor een soepelere ervaring.';
  }

  @override
  String get networkCannotReachService =>
      'Kan de lokale dienst niet bereiken. Controleer of de API draait.';

  @override
  String get gateCheckingTerms => 'Voorwaarden controleren…';

  @override
  String get gateLoadingProfile => 'Je profiel wordt geladen…';

  @override
  String get gateConnectionIssue => 'Verbindingsprobleem';

  @override
  String get safetyReportFailed => 'Melden mislukt';

  @override
  String get safetyBlockFailed => 'Blokkeren mislukt';

  @override
  String get safetyUnblockFailed => 'Deblokkeren mislukt';

  @override
  String get safetyNotAuthenticated => 'Niet ingelogd';

  @override
  String get timeAgoJustNow => 'Zojuist';

  @override
  String timeAgoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuten geleden',
      one: '1 minuut geleden',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uur geleden',
      one: '1 uur geleden',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen geleden',
      one: '1 dag geleden',
    );
    return '$_temp0';
  }

  @override
  String timeAgoWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weken geleden',
      one: '1 week geleden',
    );
    return '$_temp0';
  }

  @override
  String get themePreviewBarrier => 'Themavoorbeeld';

  @override
  String get themeNowShowing => 'NU TE ZIEN';

  @override
  String get themeTaglineRealLife => 'Warm ivoor, bosgroen en abrikoos.';

  @override
  String get themeTaglineRealLifeNight =>
      'Bosgroen, zachte munt en kaarslicht.';

  @override
  String get themeTaglineDaylight =>
      'Crème, inkt en een frambozen accent, net als de website.';

  @override
  String get themeTaglineEmber =>
      'Pruimzwarte nacht met gloeiende sintels en violette gloed.';

  @override
  String get themeTaglineForge => 'Ovenrood, staalblauw, gunmetal chroom.';

  @override
  String get themeTaglineNeongrid =>
      'Zwart glas, cyaan lichtlijnen, amberkleurige puls.';

  @override
  String get themeTaglineCrimsonalloy =>
      'Karmozijnrode lak, gesmolten goud, middernachtelijk kastanjebruin.';

  @override
  String get themeTaglineCircuit =>
      'Printplaatgroen, signaalviolet, carbonzwart.';

  @override
  String get themeTaglineDeepfield =>
      'Diepe ruimte, plasmablauw en een flits sterrengoud.';

  @override
  String get themeTaglineLove => 'Blush, roze en een beetje goud.';

  @override
  String get themeTaglineRose =>
      'Fluweelzachte wijn, rozenrood en een beetje goud.';

  @override
  String get themeTaglinePetal =>
      'Roze papier, dwarrelende blaadjes, een vleugje salie.';

  @override
  String get themeTaglineSnow =>
      'Verse sneeuw, matglas en een lint van noorderlicht.';

  @override
  String get themeTaglineGothic =>
      'Maanverlicht maaswerk, granaat, kaarsrook en antiek goud.';

  @override
  String get themeTaglineCalm =>
      'Weinig prikkels, hoog contrast. Stille achtergrond, geen beweging.';

  @override
  String get themeLooksTodayDescription =>
      'Overdag warm ivoor en bosgroen. ’s Avonds zachte munt en diep bosgroen.';

  @override
  String get settingsEyebrow => 'INSTELLINGEN';

  @override
  String get settingsHeaderSubtitle => 'Je look, je privacy en je account.';

  @override
  String get settingsThemeSection => 'Thema';

  @override
  String get settingsThemeSectionTitle => 'Maak het van jou';

  @override
  String get settingsThemeSectionCaption =>
      'Elk scherm volgt de look die je kiest.';

  @override
  String get settingsSectionYourStory => 'Jouw verhaal';

  @override
  String get settingsDatingRhythmTitle => 'Jouw datingritme';

  @override
  String get settingsDatingRhythmSubtitle =>
      'Intentie, tempo, beschikbaarheid en privacy bij introducties';

  @override
  String get settingsProfileStoriesTitle => 'Jouw profielverhalen';

  @override
  String get settingsProfileStoriesSubtitle =>
      'Kleine momenten, jouw woorden, optionele foto’s';

  @override
  String get settingsBlogTitle => 'Blog · Open hoofdstukken';

  @override
  String get settingsBlogSubtitle => 'Jouw dagboek, jouw foto’s, jouw publiek';

  @override
  String get settingsLookPreviewEyebrow => 'VANDAAG';

  @override
  String get settingsLookPreviewHeadline => 'Iets echts.';

  @override
  String get friendsEyebrow => 'VRIENDEN';

  @override
  String get friendsTitle => 'Jouw mensen';

  @override
  String get friendsSubtitle =>
      'Vrienden kunnen elkaar berichten sturen, plannen maken en samen groepen starten. Een verzoek heeft een ja van beide kanten nodig.';

  @override
  String get friendsBack => 'Terug';

  @override
  String get friendsAddFriend => 'Vriend toevoegen';

  @override
  String get friendsCreateGroup => 'Groep maken';

  @override
  String get friendsSectionRequests => 'VERZOEKEN';

  @override
  String get friendsRequestsWaitingOnOthers => 'Wachten op anderen';

  @override
  String get friendsRequestsWaitingOnYou => 'Wachten op jou';

  @override
  String get friendsRequestsCaption =>
      'Er wordt niets gedeeld tot jullie allebei akkoord zijn.';

  @override
  String get friendsSectionChats => 'CHATS';

  @override
  String get friendsChatsTitle => 'Gesprekken';

  @override
  String get friendsSectionIntros => 'INTRO’S';

  @override
  String get friendsIntrosTitle => 'Intro’s voor jou';

  @override
  String get friendsSectionVouches => 'AANBEVELINGEN';

  @override
  String get friendsVouchesPendingTitle =>
      'Aanbevelingen die op je goedkeuring wachten';

  @override
  String friendsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vrienden',
      one: '1 vriend',
      zero: 'Nog geen vrienden',
    );
    return '$_temp0';
  }

  @override
  String get friendsIntroduce => 'Voorstellen';

  @override
  String get friendsEmptyBody =>
      'Zoek mensen die je kent op naam of gebruikersnaam, of voeg iemand toe vanuit een match, een ruimte of een groep.';

  @override
  String get friendsSectionOnProfile => 'OP JE PROFIEL';

  @override
  String get friendsVouchesOnProfileTitle => 'Aanbevelingen op je profiel';

  @override
  String friendsQuoted(String text) {
    return '‘$text’';
  }

  @override
  String friendsVouchedForYou(String name) {
    return '$name heeft je aanbevolen';
  }

  @override
  String get friendsHideFromProfile => 'Verbergen op profiel';

  @override
  String get friendsSectionMore => 'MEER';

  @override
  String get friendsMoreTitle => 'Plannen en introducties';

  @override
  String get friendsPlansLinkTitle => 'Dateplannen die met je zijn gedeeld';

  @override
  String get friendsPlansLinkSubtitle =>
      'Vrienden laten je weten wanneer ze een date plannen en wanneer ze zich daarna melden.';

  @override
  String get friendsInviteIntroducerTitle =>
      'Nodig een vriend uit die niet aan het daten is';

  @override
  String get friendsInviteIntroducerSubtitle =>
      'Kies wie je mag voorstellen. Bekijk of trek je toestemming op elk moment in.';

  @override
  String get friendsIntroTermsTitle => 'Introducties, op jouw voorwaarden';

  @override
  String get friendsIntroTermsSubtitle =>
      'Kies of vrienden je mogen voorstellen en wat een voorbeeld laat zien.';

  @override
  String get friendsSectionActivity => 'ACTIVITEIT';

  @override
  String get friendsActivityTitle => 'Met je vrienden';

  @override
  String friendsVouchSentSnack(String name) {
    return 'Aanbeveling verstuurd. $name keurt hem goed voordat hij zichtbaar wordt.';
  }

  @override
  String friendsRemoveTitle(String name) {
    return '$name verwijderen?';
  }

  @override
  String get friendsRemoveBody =>
      'Jullie zijn dan geen vrienden meer en jullie chat wordt gesloten. De ander krijgt geen melding.';

  @override
  String get friendsRemoveFriend => 'Vriend verwijderen';

  @override
  String get friendsIntroMadeSnack =>
      'Intro gemaakt. Beide vrienden horen van je.';

  @override
  String get friendsAddSheetLabel => 'VRIEND TOEVOEGEN';

  @override
  String get friendsAddSheetTitle => 'Zoek iemand die je kent';

  @override
  String get friendsAddSheetCaption =>
      'Zoek op naam of @gebruikersnaam. De ander kiest of hij of zij accepteert.';

  @override
  String get friendsSearchHiddenNote =>
      'Je bent verborgen in vrienden zoeken, dus anderen kunnen je hier niet vinden. Wijzig dit bij Privacy en veiligheid.';

  @override
  String get friendsSearchLabel => 'Naam of @gebruikersnaam';

  @override
  String get friendsSearchHelper => 'Typ minstens 3 letters';

  @override
  String get friendsSearchFailed =>
      'Zoeken is nu niet beschikbaar. Probeer het opnieuw.';

  @override
  String friendsSearchNoResults(String query) {
    return 'Niemand gevonden voor ‘$query’.';
  }

  @override
  String get friendsNewGroupLabel => 'NIEUWE GROEP';

  @override
  String get friendsNewGroupTitle => 'Wie doet er mee?';

  @override
  String get friendsNewGroupCaption =>
      'Kies vrienden om uit te nodigen. Je kunt er later meer toevoegen.';

  @override
  String get friendsChooseFriends => 'Kies vrienden';

  @override
  String friendsCreateGroupWith(int count) {
    return 'Groep maken met $count';
  }

  @override
  String get friendsSourceMatch => 'Uit je matches';

  @override
  String get friendsSourceProfile => 'Zag je profiel';

  @override
  String get friendsSourceRoom => 'Ontmoet in een ruimte';

  @override
  String get friendsSourceGroup => 'Uit een groep';

  @override
  String get friendsSourceSearch => 'Vond je op naam';

  @override
  String get friendsWantsToBeFriends => 'Wil vrienden worden';

  @override
  String get friendsRequestSent => 'Verzoek verstuurd';

  @override
  String get friendsCancel => 'Annuleren';

  @override
  String get friendsDecline => 'Weigeren';

  @override
  String get friendsAccept => 'Accepteren';

  @override
  String friendsMessageTooltip(String name) {
    return '$name een bericht sturen';
  }

  @override
  String friendsMessageTooltipUnread(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$name een bericht sturen, $count ongelezen',
    );
    return '$_temp0';
  }

  @override
  String friendsMoreFor(String name) {
    return 'Meer voor $name';
  }

  @override
  String get friendsMenuVouch => 'Aanbevelen';

  @override
  String get friendsMenuIntro => 'Voorstellen aan een vriend';

  @override
  String friendsChatSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chat met $name, $count ongelezen',
      zero: 'Chat met $name',
    );
    return '$_temp0';
  }

  @override
  String friendsChatSemanticsMuted(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chat met $name, $count ongelezen, meldingen gedempt',
      zero: 'Chat met $name, meldingen gedempt',
    );
    return '$_temp0';
  }

  @override
  String friendsIntroHeadline(String introducer, String person) {
    return '$introducer vindt dat je $person moet ontmoeten';
  }

  @override
  String friendsIntroHeadlineSomeone(String introducer) {
    return '$introducer vindt dat je iemand moet ontmoeten';
  }

  @override
  String friendsNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String get friendsIntroNoThanks => 'Nee, bedankt';

  @override
  String get friendsIntroImIn => 'Ik doe mee';

  @override
  String get friendsVouchKeepPrivate => 'Privé houden';

  @override
  String get friendsVouchShowOnProfile => 'Op mijn profiel tonen';

  @override
  String get memberProfileNoData => 'Geen profielgegevens gevonden.';

  @override
  String get memberProfileSignInToView => 'Log in om je profiel te bekijken.';

  @override
  String get memberProfileLoadFailed =>
      'Profiel kon niet worden geladen. Probeer het opnieuw.';

  @override
  String get memberProfileConnectionsTitle => 'Je connecties';

  @override
  String get memberProfileConnectionsCaption =>
      'Mensen die je leuk vond, je matches en met wie je praat.';

  @override
  String get memberProfileStatLiked => 'Jouw likes';

  @override
  String get memberProfileStatMatches => 'Matches';

  @override
  String get memberProfileStatMessages => 'Berichten';

  @override
  String memberProfileOpenStat(String label) {
    return '$label openen';
  }

  @override
  String get memberProfileNoticedTitle => 'Wie je heeft opgemerkt';

  @override
  String get memberProfileNoticedCaption =>
      'Likes en bezoeken van leden bij jou in de buurt.';

  @override
  String get memberProfileWhoLikedMe => 'Wie mij leuk vindt';

  @override
  String memberProfileWhoLikedMeCount(int count) {
    return 'Wie mij leuk vindt ($count)';
  }

  @override
  String get memberProfileWhoLikedMeSubtitle =>
      'Leden die je profiel leuk vonden.';

  @override
  String get memberProfileWhoViewedTitle => 'Wie mijn profiel bekeek';

  @override
  String get memberProfileWhoViewedSubtitle =>
      'Recente bezoeken aan je profiel.';

  @override
  String get memberProfileWhoViewedTooltip => 'Wie mijn profiel bekeek';

  @override
  String get memberProfileRefreshTooltip => 'Profiel vernieuwen';

  @override
  String get memberProfilePreferencesTitle => 'Je voorkeuren';

  @override
  String get memberProfilePrefSeeking => 'Op zoek naar';

  @override
  String get memberProfilePrefDistance => 'Afstand';

  @override
  String memberProfileWithinKm(int km) {
    return 'Binnen $km km';
  }

  @override
  String get profileViewersTitle => 'Mijn profielbezoekers';

  @override
  String get profileViewersLoadFailed =>
      'Profielbezoekers konden niet worden geladen.';

  @override
  String get profileViewersEmpty => 'Nog niemand heeft je profiel bekeken.';

  @override
  String get profileViewersViewedRecently => 'Onlangs bekeken';

  @override
  String profileViewersViewedAt(String time) {
    return 'Bekeken op $time';
  }

  @override
  String get profileMasterReligionParsi => 'Parsi';

  @override
  String get profileMasterReligionBahai => 'Bahai';

  @override
  String get profileMasterReligionTribal => 'Tribaal / Inheems';

  @override
  String get profileMasterWorkout1to2 => '1-2 keer per week';

  @override
  String get profileMasterWorkout3to4 => '3-4 keer per week';

  @override
  String get profileMasterWorkout5Plus => '5+ keer per week';

  @override
  String get profileMasterWorkoutDaily => 'Dagelijks';

  @override
  String get profileMasterDietNoPreference => 'Geen voorkeur';

  @override
  String get profileMasterDietVegetarian => 'Vegetarisch';

  @override
  String get profileMasterDietEggetarian => 'Vegetarisch met ei';

  @override
  String get profileMasterDietNonVegetarian => 'Niet-vegetarisch';

  @override
  String get profileMasterDietVegan => 'Veganistisch';

  @override
  String get profileMasterDietJain => 'Jaïnistisch dieet';

  @override
  String get profileMasterDietTypeBalanced => 'Gebalanceerd';

  @override
  String get profileMasterDietTypeHighProtein => 'Eiwitrijk';

  @override
  String get profileMasterDietTypeLowCarb => 'Koolhydraatarm';

  @override
  String get profileMasterDietTypeKeto => 'Keto';

  @override
  String get profileMasterDietTypeMediterranean => 'Mediterraan';

  @override
  String get profileMasterDietTypeIntermittentFasting => 'Periodiek vasten';

  @override
  String get profileMasterSleepEarlyBird => 'Vroege vogel';

  @override
  String get profileMasterSleepNightOwl => 'Nachtuil';

  @override
  String get profileMasterSleepFlexible => 'Flexibel';

  @override
  String get profileMasterSleepShiftBased => 'Ploegendienst';

  @override
  String get profileMasterTravelHomebody => 'Huismus';

  @override
  String get profileMasterTravelOccasional => 'Af en toe op reis';

  @override
  String get profileMasterTravelFrequent => 'Vaak op reis';

  @override
  String get profileMasterTravelAdventure => 'Avonturier';

  @override
  String get profileMasterTravelLuxury => 'Luxereiziger';

  @override
  String get profileMasterTravelBackpacker => 'Backpacker';

  @override
  String get profileMasterPoliticsSimilar => 'Alleen vergelijkbare opvattingen';

  @override
  String get profileMasterPoliticsOpen => 'Open voor verschillen';

  @override
  String get profileMasterPoliticsNotDiscuss => 'Liever niet over praten';

  @override
  String get profileMasterPoliticsNoStrong => 'Geen sterke voorkeur';

  @override
  String get profileMasterIntentLongTerm => 'Lange termijn';

  @override
  String get profileMasterIntentMarriage => 'Huwelijk';

  @override
  String get profileMasterIntentNewFriends => 'Nieuwe vrienden';

  @override
  String get chatBackToConversations => 'Terug naar gesprekken';

  @override
  String get chatOfflineBanner =>
      'Je bent offline. Je concept blijft hier staan tot je weer verbonden bent.';

  @override
  String get chatVoiceHello => 'Deel een spraakgroet · lees en luister';

  @override
  String get chatLoadFailedTitle => 'Even opnieuw verbinden.';

  @override
  String get chatLoadFailedBody =>
      'Je gesprek kon niet worden geladen. Probeer het opnieuw.';

  @override
  String get chatConversationEnded => 'Dit gesprek is beëindigd.';

  @override
  String get chatUnlockStepRequired =>
      'Rond de huidige ontgrendelstap af om dit gesprek voort te zetten.';

  @override
  String get chatGiftTrayTitle => 'Een kleine attentie';

  @override
  String get chatCloseGifts => 'Cadeaus sluiten';

  @override
  String get chatAllGifts => 'Alle cadeaus';

  @override
  String get chatNoGiftsInCollection =>
      'Geen cadeaus beschikbaar in deze collectie.';

  @override
  String get chatAddCoins => 'Munten toevoegen';

  @override
  String get chatFreeGiftDaily => 'Gratis · 1 per dag';

  @override
  String chatCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count munten',
      one: '1 munt',
    );
    return '$_temp0';
  }

  @override
  String get chatSendingGift => 'Je cadeau wordt verstuurd…';

  @override
  String get chatOfflineGifts =>
      'Je bent offline. Je kunt cadeaus bekijken en versturen zodra je weer verbonden bent.';

  @override
  String chatGiftConfirmTitle(String gift, String name) {
    return '$gift naar $name sturen?';
  }

  @override
  String chatGiftNoteQuote(String note) {
    return '“$note”';
  }

  @override
  String chatGiftBalanceAfter(int balance, int remaining) {
    return '·  $balance → $remaining over';
  }

  @override
  String get chatGiftNoObligation =>
      'Een cadeau is een gebaar, nooit een verplichting om te antwoorden of af te spreken.';

  @override
  String chatGiftSendFor(String price) {
    return 'Versturen voor $price';
  }

  @override
  String get chatNotNow => 'Niet nu';

  @override
  String get chatDeleteMessageTitle => 'Bericht verwijderen?';

  @override
  String get chatDeleteMessageBody =>
      'Hiermee verdwijnt het bericht bij jullie allebei.';

  @override
  String get chatDeleteForEveryone => 'Voor iedereen verwijderen';

  @override
  String get chatMessageDeletedSnack => 'Bericht verwijderd.';

  @override
  String get chatUndo => 'Ongedaan maken';

  @override
  String get chatDeleteUndone => 'Verwijderen ongedaan gemaakt.';

  @override
  String chatGiftReceivedFrom(String name) {
    return 'Cadeau van $name';
  }

  @override
  String get chatGiftReceiverIntro => 'Jij bepaalt wat er in je chat blijft.';

  @override
  String get chatHideGift => 'Cadeau verbergen';

  @override
  String get chatHideGiftSubtitle => 'Alleen uit jouw chat verwijderen.';

  @override
  String get chatReportAndHide => 'Melden en verbergen';

  @override
  String get chatReportAndHideSubtitle =>
      'Naar het veiligheidsteam sturen en nu verwijderen.';

  @override
  String get chatGiftHidden => 'Cadeau verborgen in je chat.';

  @override
  String get chatReportGiftTitle => 'Dit cadeau melden';

  @override
  String get chatReportGiftIntro =>
      'Kies een reden. Het cadeau wordt meteen verborgen.';

  @override
  String get chatReportReasonLabel => 'Reden';

  @override
  String get chatReportReasonUnwanted => 'Ongewenst cadeau';

  @override
  String get chatReportReasonHarassment => 'Intimidatie';

  @override
  String get chatReportReasonSexual => 'Seksuele inhoud';

  @override
  String get chatReportReasonScam => 'Oplichting of fraude';

  @override
  String get chatReportReasonOther => 'Iets anders';

  @override
  String get chatReportDetailsLabel => 'Details toevoegen (optioneel)';

  @override
  String get chatReportSubmit => 'Melding versturen en verbergen';

  @override
  String get chatGiftReported =>
      'Cadeau gemeld en verborgen. Ons veiligheidsteam bekijkt het.';

  @override
  String get chatQuickEmojis => 'Snelle emoji’s';

  @override
  String chatWalletTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count munten',
      one: '1 munt',
    );
    return 'Je portemonnee · $_temp0';
  }

  @override
  String get chatDailyLimitReached => 'Dagelijkse berichtlimiet bereikt';

  @override
  String get chatDailyLimitFallback =>
      'Probeer het morgen opnieuw of upgrade je abonnement.';

  @override
  String chatDailyLimitReset(String reset) {
    return '$reset · upgrade voor meer.';
  }

  @override
  String get chatSeePlans => 'Abonnementen bekijken';

  @override
  String chatQuotaOnPlan(String quota, String plan) {
    return '$quota met $plan';
  }

  @override
  String get chatYourConversation => 'Jullie gesprek';

  @override
  String get chatVerifiedHumans => 'Geverifieerde mensen';

  @override
  String get chatVerifiedHumansShowsUp => 'Geverifieerde mensen · Komt opdagen';

  @override
  String discoverLikedBack(String name) {
    return 'Je hebt $name teruggeliket';
  }

  @override
  String discoverPassedOn(String name) {
    return '$name overgeslagen';
  }

  @override
  String get discoverLikedMeLoadFailedTitle =>
      'Je likes konden niet worden geladen';

  @override
  String get discoverLikedMeEmptyTitle => 'Nog geen nieuwe likes';

  @override
  String get discoverLikedMeEmptyBody =>
      'Als iemand je liket, verschijnt die persoon hier. Like terug en het is een match.';

  @override
  String get discoverLikedMeIntro =>
      'Zij liken je al. Like terug voor een match of sla over. Overslaan is privé.';

  @override
  String get discoverLikedMeTitle => 'Hebben je geliket';

  @override
  String discoverLikedMeTitleCount(int count) {
    return 'Hebben je geliket · $count';
  }

  @override
  String get discoverPass => 'Overslaan';

  @override
  String get discoverLikeBack => 'Terugliken';

  @override
  String get discoverLikedJustNow => 'Heeft je net geliket';

  @override
  String discoverLikedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Heeft je $count minuten geleden geliket',
      one: 'Heeft je 1 minuut geleden geliket',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Heeft je $count uur geleden geliket',
      one: 'Heeft je 1 uur geleden geliket',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Heeft je $count dagen geleden geliket',
      one: 'Heeft je 1 dag geleden geliket',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Heeft je $count weken geleden geliket',
      one: 'Heeft je 1 week geleden geliket',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedOnDate(String date) {
    return 'Heeft je geliket op $date';
  }

  @override
  String discoverLikedProfilesTitle(int count) {
    return 'Gelikete profielen ($count)';
  }

  @override
  String get discoverNoLikedProfiles => 'Nog geen gelikete profielen';

  @override
  String get discoverLikedProfileFallback => 'Geliket profiel';

  @override
  String get discoverPassedProfilesTitle => 'Overgeslagen profielen';

  @override
  String get discoverNoPassedProfiles => 'Nog geen overgeslagen profielen';

  @override
  String get discoverSavedForLater => 'Bewaard voor later';

  @override
  String get discoverSpotlightFiltersTitle => 'Filters voor uitgelicht';

  @override
  String get discoverVerifiedOnly => 'Alleen geverifieerd';

  @override
  String discoverAgeRange(int min, int max) {
    return 'Leeftijd: $min - $max';
  }

  @override
  String get discoverSpotlightTitle => 'Uitgelichte matches';

  @override
  String get discoverSpotlightSubtitle => 'Geselecteerde premium connecties';

  @override
  String discoverPassedCount(int count) {
    return 'Overgeslagen ($count)';
  }

  @override
  String get discoverOpenChatsFromDiscover => 'Open chats via Ontdekken';

  @override
  String get discoverNoNewNotifications => 'Geen nieuwe meldingen';

  @override
  String get discoverNoSpotlightMatchFilters =>
      'Geen uitgelichte profielen voor deze filters';

  @override
  String get discoverAllSpotlightReviewed =>
      'Alle uitgelichte profielen bekeken!';

  @override
  String get discoverSpotlightCheckBackLater =>
      'Kom later terug voor nieuwe uitgelichte profielen';

  @override
  String get discoverReportSubmitted => 'Melding verstuurd.';

  @override
  String get discoverAppeal => 'Bezwaar';

  @override
  String discoverAppealPrefill(String userId) {
    return 'Moderatieresultaat van melding over gebruiker $userId herzien';
  }

  @override
  String get discoverProfileUnavailable =>
      'Dit profiel is nu niet beschikbaar.';

  @override
  String get discoverGoBack => 'Ga terug';

  @override
  String get discoverPremiumView => 'Premium-weergave';

  @override
  String get todayLabel => 'VANDAAG';

  @override
  String get todayRefreshTooltip => 'Vandaag vernieuwen';

  @override
  String get todayDiscoveryPreferences => 'Ontdekvoorkeuren';

  @override
  String get todayHeroTitle => 'Een klein hallo.\nRuimte voor iets echts.';

  @override
  String get todayHeroSubtitle =>
      'Een paar doordachte kennismakingen, in jouw tempo.';

  @override
  String get todaySectionPace => 'JOUW TEMPO';

  @override
  String get todayPaceTitle => 'Wat past in je week?';

  @override
  String get todayPaceBody =>
      'Jouw tempo, jouw soort eerste date, optionele beschikbaarheid.';

  @override
  String get todaySetRhythm => 'Stel je ritme in';

  @override
  String get todaySectionStory => 'JOUW VERHAAL';

  @override
  String get todaySectionIntroductions => 'KENNISMAKINGEN VAN VANDAAG';

  @override
  String get todayIntroductionsTitle => 'Een paar mensen om te leren kennen';

  @override
  String get todayIntroductionsCaption =>
      'Gedeelde interesses zijn een begin. De klik ontdek je zelf.';

  @override
  String get todayPausedTitle => 'Neem de tijd die je nodig hebt.';

  @override
  String get todayPausedBody =>
      'Kennismakingen zijn gepauzeerd. Je gesprekken zijn er nog steeds.';

  @override
  String get todayManageRhythm => 'Je ritme beheren';

  @override
  String get todayLoadingIntroductions => 'Kennismakingen laden';

  @override
  String get todayFailedTitle => 'Je kennismakingen hebben even tijd nodig.';

  @override
  String get todayFailedBody =>
      'We konden de nieuwste informatie niet laden. Probeer het opnieuw.';

  @override
  String get todayTryAgain => 'Opnieuw proberen';

  @override
  String get todayEmptyTitle => 'Even wat ademruimte.';

  @override
  String get todayEmptyBody =>
      'Er zijn nu geen nieuwe kennismakingen voor je voorkeuren. Je kunt je ritme aanpassen of profielen ontdekken.';

  @override
  String get todayExploreProfiles => 'Profielen ontdekken';

  @override
  String get todayAllIntroductions => 'Alle kennismakingen';

  @override
  String get todayBreatheTitle =>
      'Een goede klik heeft ruimte nodig om te ademen.';

  @override
  String get todayBreatheBody =>
      'Dit zijn de kennismakingen van vandaag. Er loopt geen klok en je hoeft niet over iedereen te beslissen.';

  @override
  String get todayExploreMore => 'Meer profielen ontdekken';

  @override
  String get todayCommonGround => 'IETS GEMEENSCHAPPELIJKS';

  @override
  String todayMeetName(String name) {
    return 'Maak kennis met $name';
  }

  @override
  String get todayFirstHelloCoffee =>
      'Een eerste hallo kan samen koffie drinken zijn.';

  @override
  String get todayFirstHelloWalk =>
      'Een eerste hallo kan een wandeling overdag zijn.';

  @override
  String get todayFirstHelloMeal =>
      'Een eerste hallo kan een ontspannen maaltijd zijn.';

  @override
  String get todayFirstHelloVideoCall =>
      'Een eerste hallo kan een videogesprek zijn.';

  @override
  String get todayFirstHelloEvent =>
      'Een eerste hallo kan een evenement zijn waar jullie allebei van houden.';

  @override
  String get todayFirstHelloDrinks =>
      'Een eerste hallo kan samen iets drinken zijn.';

  @override
  String get todayFirstHelloOther =>
      'Een eerste hallo kan iets zijn waar jullie allebei van houden.';

  @override
  String get todaySectionTalk => 'IETS OM OVER TE PRATEN';

  @override
  String get todayTalkCaption =>
      'Verhalen, clubs en ideeën die een eerste hallo makkelijker maken.';

  @override
  String get todayBlogTitle => 'Blog · Open hoofdstukken';

  @override
  String get todayBlogSubtitle =>
      'Lees verhalen van leden en schrijf je eigen.';

  @override
  String get todayBookClubsTitle => 'Boekenclubs';

  @override
  String get todayBookClubsSubtitle => 'Eén boek per week, samen besproken.';

  @override
  String get todayFilmClubsTitle => 'Filmclubs';

  @override
  String get todayFilmClubsSubtitle =>
      'Kijk de gekozen film en wissel daarna je mening uit.';

  @override
  String get todayPhotoThemesTitle => 'Fotothema\'s';

  @override
  String get todayPhotoThemesSubtitle =>
      'Eén foto per thema. Bekijk die van iedereen.';

  @override
  String get todayChapterStudioTitle => 'Studio Eerste hoofdstuk';

  @override
  String get todayChapterStudioSubtitle => 'Begin samen een verhaal.';

  @override
  String get todayCoverFallbackLine => 'Een foto waar leden dol op waren';

  @override
  String todayCoverSemantics(String name) {
    return 'Cover van de week van $name openen';
  }

  @override
  String get todayCoverTitle => 'COVER VAN DE WEEK';

  @override
  String todayCoverBy(String name) {
    return 'DOOR $name';
  }

  @override
  String get todayLikes => 'Likes';

  @override
  String get todayComments => 'Reacties';

  @override
  String get todayThisWeek => 'Deze week';

  @override
  String get todayWallLabel => 'UIT DE COMMUNITY';

  @override
  String get todayWallTitle => 'De muur van vandaag';

  @override
  String get todayWallCaption =>
      'Verhalen en foto\'s waar leden dol op waren — elke dag een nieuwe selectie';

  @override
  String get todayWallPrevious => 'Vorige';

  @override
  String get todayWallNext => 'Volgende';

  @override
  String get todayWallChapter => 'HOOFDSTUK';

  @override
  String get todayWallUntitled => 'Een hoofdstuk zonder titel';

  @override
  String todayWallBy(String name) {
    return 'door $name';
  }

  @override
  String get todayWallEmpty =>
      'Je muur vult zich zodra leden verhalen en foto\'s delen waar ze van houden';

  @override
  String get todayWallWrite => 'Hoofdstuk schrijven';

  @override
  String get todayWallShare => 'Foto delen';

  @override
  String get profileSetupBackTooltip => 'Terug';

  @override
  String profileSetupStepCounter(int current, int total) {
    return 'Stap $current van $total';
  }

  @override
  String get profileSetupLoadErrorTitle =>
      'Profielgegevens konden niet worden geladen.';

  @override
  String get profileSetupRetry => 'Opnieuw proberen';

  @override
  String get profileSetupEducationHighSchool => 'Middelbare school';

  @override
  String get profileSetupEducationBachelors => 'Bachelor';

  @override
  String get profileSetupEducationMasters => 'Master';

  @override
  String get profileSetupEducationPhd => 'Promotie';

  @override
  String get profileSetupEducationOther => 'Anders';

  @override
  String get profileSetupPreferNotToSay => 'Zeg ik liever niet';

  @override
  String profileSetupIncomeBelow(String amount) {
    return 'Minder dan $amount';
  }

  @override
  String get profileSetupFrequencyNever => 'Nooit';

  @override
  String get profileSetupFrequencySocially => 'Sociaal';

  @override
  String get profileSetupFrequencyOccasionally => 'Af en toe';

  @override
  String get profileSetupFrequencyRegularly => 'Regelmatig';

  @override
  String get profileSetupGenderMan => 'Man';

  @override
  String get profileSetupGenderWoman => 'Vrouw';

  @override
  String get profileSetupGenderOther => 'Anders';

  @override
  String profileSetupBioTooShort(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Je bio moet minstens $min tekens bevatten.',
      one: 'Je bio moet minstens 1 teken bevatten.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupSaveFailed => 'Opslaan mislukt — probeer het opnieuw.';

  @override
  String get profileSetupCouldNotSaveChanges =>
      'Je wijzigingen konden niet worden opgeslagen. Probeer het opnieuw.';

  @override
  String get profileSetupAboutTitle => 'Laat je profiel stralen';

  @override
  String get profileSetupAboutSubtitle =>
      'Deze gegevens helpen betere matches te vinden.';

  @override
  String get profileSetupBioLabel => 'Bio';

  @override
  String profileSetupBioHint(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Vertel iets over jezelf (min. $min tekens)',
      one: 'Vertel iets over jezelf (min. 1 teken)',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupHeightLabel => 'Lengte (cm)';

  @override
  String get profileSetupHeightHint => 'Kies je lengte';

  @override
  String profileSetupHeightValue(int cm) {
    return '$cm cm';
  }

  @override
  String get profileSetupEducationLabel => 'Opleiding';

  @override
  String get profileSetupEducationHint => 'Kies je opleiding';

  @override
  String get profileSetupProfessionLabel => 'Beroep';

  @override
  String get profileSetupProfessionHint => 'bijv. software-engineer';

  @override
  String get profileSetupIncomeLabel => 'Inkomen (optioneel)';

  @override
  String get profileSetupLifestyleTitle => 'Levensstijl';

  @override
  String get profileSetupDrinkingLabel => 'Alcohol';

  @override
  String get profileSetupSmokingLabel => 'Roken';

  @override
  String get profileSetupSelectHint => 'Kiezen';

  @override
  String get profileSetupReligionOptionalLabel => 'Religie (optioneel)';

  @override
  String get profileSetupContinue => 'Doorgaan';

  @override
  String get profileSetupSaveAbout => 'Over mij opslaan';

  @override
  String get profileSetupPhotosSaved => 'Foto\'s opgeslagen.';

  @override
  String profileSetupPhotosMaxReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Je kunt maximaal $max foto\'s uploaden.',
      one: 'Je kunt maar 1 foto uploaden.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupRemovePhotoTitle => 'Deze foto verwijderen?';

  @override
  String get profileSetupRemovePhotoBody =>
      'Hij wordt van je profiel gehaald en uit de opslag verwijderd.';

  @override
  String get profileSetupCancel => 'Annuleren';

  @override
  String get profileSetupRemove => 'Verwijderen';

  @override
  String profileSetupPhotosMinRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Upload minstens $min foto\'s om door te gaan.',
      one: 'Upload minstens 1 foto om door te gaan.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTitle => 'Voeg je foto\'s toe';

  @override
  String profileSetupPhotosSubtitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Voeg minstens $min foto\'s toe om matches te krijgen',
      one: 'Voeg minstens 1 foto toe om matches te krijgen',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupChooseSource => 'Kies een bron';

  @override
  String get profileSetupGallery => 'Galerij';

  @override
  String get profileSetupCamera => 'Camera';

  @override
  String get profileSetupPhotoRequirements =>
      'JPEG, PNG, WebP of HEIC · minimaal 300×300 · 10 MB per foto · 50 MB in totaal';

  @override
  String profileSetupPhotosTipEmpty(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other:
          'Voeg minstens $min foto\'s toe om verschillende kanten van jezelf te laten zien.',
      one:
          'Voeg minstens 1 foto toe om verschillende kanten van jezelf te laten zien.',
    );
    return '$_temp0';
  }

  @override
  String profileSetupPhotosTipMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Voeg nog $count foto\'s toe om volledig matchen te ontgrendelen.',
      one: 'Voeg nog 1 foto toe om volledig matchen te ontgrendelen.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTipDone =>
      'Top! Je kunt je foto\'s slepen om ze te herschikken.';

  @override
  String get profileSetupYourPhotosHeading =>
      'Je foto\'s  •  sleep om te herschikken';

  @override
  String get profileSetupContinueToAbout => 'Verder naar Over mij';

  @override
  String get profileSetupSavePhotos => 'Foto\'s opslaan';

  @override
  String get profileSetupPrimaryPhoto => 'Hoofdfoto';

  @override
  String profileSetupPhotoNumber(int number) {
    return 'Foto $number';
  }

  @override
  String get profileSetupShownFirst => 'Wordt als eerste op je profiel getoond';

  @override
  String get profileSetupDragHandleHint =>
      'Sleep aan de greep om te herschikken';

  @override
  String get profileSetupAwaitingSafetyReview => 'Wacht op veiligheidscontrole';

  @override
  String get profileSetupSafetyCheckInProgress => 'Veiligheidscontrole bezig';

  @override
  String get profileSetupSetAsProfilePicture => 'Instellen als profielfoto';

  @override
  String get profileSetupProfilePictureSelected => 'Profielfoto geselecteerd';

  @override
  String get profileSetupRemovePhotoTooltip => 'Foto verwijderen';

  @override
  String get profileSetupPhotoTooLarge =>
      'Deze foto is groter dan de limiet van 10 MB.';

  @override
  String get profileSetupPhotoUnsupportedType =>
      'Gebruik een JPEG-, PNG-, WebP- of HEIC-foto.';

  @override
  String get profileSetupPhotoBadDimensions =>
      'De afmetingen van de foto moeten tussen 300×300 en 4096×4096 liggen.';

  @override
  String get profileSetupPhotoQuotaReached =>
      'Je hebt je limiet voor profielfoto\'s bereikt.';

  @override
  String get profileSetupPhotoStorageFull =>
      'De fotoopslag is tijdelijk vol. Probeer het later opnieuw.';

  @override
  String get profileSetupPhotoUpdateFailed =>
      'Foto bijwerken mislukt. Probeer het opnieuw.';

  @override
  String profileSetupPhotoMaxAllowed(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Maximaal $max foto\'s toegestaan.',
      one: 'Maximaal 1 foto toegestaan.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPreferencesLoadFailed =>
      'Voorkeuren konden niet worden geladen';

  @override
  String get profileSetupOfflineBanner =>
      'Offlinemodus — sommige gegevens zijn mogelijk verouderd.';

  @override
  String get profileSetupYourPreferences => 'Jouw voorkeuren';

  @override
  String get profileSetupEditPreferencesTitle => 'Voorkeuren bewerken';

  @override
  String get profileSetupFinishAndFindMatches => 'Afronden en matches vinden';

  @override
  String get profileSetupSavePreferences => 'Voorkeuren opslaan';

  @override
  String get profileSetupSelectGenderPreference =>
      'Kies minstens één geslacht.';

  @override
  String get profileSetupFinishFailed =>
      'Instellen kon niet worden afgerond. Controleer je foto\'s en voorkeuren en probeer het opnieuw.';

  @override
  String get profileSetupPreferencesSaveFailed =>
      'Sommige voorkeuren konden nu niet worden opgeslagen.';

  @override
  String get profileSetupPreferencesSaved => 'Voorkeuren opgeslagen.';

  @override
  String get profileSetupTabBasic => 'Basis';

  @override
  String get profileSetupTabAdvanced => 'Geavanceerd';

  @override
  String get profileSetupLookingFor => 'Ik zoek';

  @override
  String get profileSetupSeekingMen => 'Mannen';

  @override
  String get profileSetupSeekingWomen => 'Vrouwen';

  @override
  String get profileSetupSeekingOther => 'Anders';

  @override
  String profileSetupAgeRangeTitle(int min, int max) {
    return 'Leeftijd: $min – $max';
  }

  @override
  String profileSetupMaxDistanceTitle(int km) {
    return 'Max. afstand: $km km';
  }

  @override
  String profileSetupDistanceValue(int km) {
    return '$km km';
  }

  @override
  String get profileSetupRelationshipIntent => 'Relatiedoel';

  @override
  String get profileSetupSeriousOnly => 'Alleen serieuze relatie';

  @override
  String get profileSetupSeriousOnlySubtitle =>
      'Alleen mensen tonen die iets vasts zoeken';

  @override
  String get profileSetupVerifiedOnly => 'Alleen geverifieerde profielen';

  @override
  String get profileSetupVerifiedOnlySubtitle =>
      'Alleen accounts met geverifieerd ID';

  @override
  String get profileSetupHookupsOnly => 'Alleen losse contacten';

  @override
  String get profileSetupHookupsOnlySubtitle =>
      'Alleen profielen voor iets losses tonen';

  @override
  String get profileSetupLocation => 'Locatie';

  @override
  String get profileSetupCountry => 'Land';

  @override
  String get profileSetupStateRegion => 'Staat / Regio';

  @override
  String get profileSetupCity => 'Stad';

  @override
  String get profileSetupBackgroundCulture => 'Achtergrond en cultuur';

  @override
  String get profileSetupReligionPreference => 'Religie';

  @override
  String get profileSetupMotherTongue => 'Moedertaal';

  @override
  String get profileSetupLanguage => 'Taal';

  @override
  String get profileSetupDietPreference => 'Eetpatroon';

  @override
  String get profileSetupWorkoutFrequency => 'Hoe vaak je sport';

  @override
  String get profileSetupDietType => 'Dieet';

  @override
  String get profileSetupSleepSchedule => 'Slaapritme';

  @override
  String get profileSetupTravelStyle => 'Reisstijl';

  @override
  String get profileSetupPoliticalComfortRange => 'Politieke voorkeur';

  @override
  String get profileSetupInterestsPersonality =>
      'Interesses en persoonlijkheid';

  @override
  String get profileSetupInstagramHandle => 'Instagram-naam (zonder @)';

  @override
  String get profileSetupIntentTags =>
      'Bedoelingen (lange termijn, huwelijk, los…)';

  @override
  String get profileSetupHobbiesField => 'Hobby\'s (gescheiden door komma\'s)';

  @override
  String get profileSetupFavouriteBooksField =>
      'Favoriete boeken (gescheiden door komma\'s)';

  @override
  String get profileSetupFavouriteNovelsField =>
      'Favoriete romans (gescheiden door komma\'s)';

  @override
  String get profileSetupFavouriteSongsField =>
      'Favoriete liedjes (gescheiden door komma\'s)';

  @override
  String get profileSetupExtraCurricularField =>
      'Nevenactiviteiten (gescheiden door komma\'s)';

  @override
  String get profileSetupAdditionalInformation => 'Aanvullende informatie';

  @override
  String get profileSetupPetPreference => 'Huisdieren';

  @override
  String get profileSetupDealBreakers => 'Dealbreakers';

  @override
  String get profileSetupTagsField => 'Tags (gescheiden door komma\'s)';

  @override
  String get profileSetupNameRequired => 'Naam is verplicht.';

  @override
  String get profileSetupDobRequired => 'Geboortedatum is verplicht.';

  @override
  String profileSetupPhotosRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Minstens $min foto\'s zijn verplicht.',
      one: 'Minstens 1 foto is verplicht.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupServerError => 'Serverfout';

  @override
  String get profileSetupNetworkError => 'Netwerkfout — probeer het opnieuw.';

  @override
  String get profileSetupGenericError =>
      'Er ging iets mis. Probeer het opnieuw.';

  @override
  String get profileSetupPreviewTitle => 'Voorbeeld van je profiel';

  @override
  String get profileSetupPreviewSubtitle => 'Zo zien anderen jou.';

  @override
  String profileSetupNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String profileSetupDrinksChip(String value) {
    return 'Alcohol: $value';
  }

  @override
  String profileSetupSmokesChip(String value) {
    return 'Roken: $value';
  }

  @override
  String get profileSetupCompleteProfile => 'Profiel voltooien';

  @override
  String profileSetupCompletionPercent(int percent) {
    return 'Profiel voltooid: $percent%';
  }

  @override
  String get profileEditTitle => 'Profiel bewerken';

  @override
  String get profileEditRefreshTooltip => 'Profiel vernieuwen';

  @override
  String get profileEditAboutYou => 'Over jou';

  @override
  String get profileEditEditAbout => 'Over mij bewerken';

  @override
  String get profileEditName => 'Naam';

  @override
  String get profileEditPhone => 'Telefoon';

  @override
  String get profileEditDateOfBirth => 'Geboortedatum';

  @override
  String get profileEditGender => 'Geslacht';

  @override
  String get profileEditHeight => 'Lengte';

  @override
  String get profileEditIncomeRange => 'Inkomensklasse';

  @override
  String get profileEditLocationSocial => 'Locatie en social media';

  @override
  String get profileEditEditPreferences => 'Voorkeuren bewerken';

  @override
  String get profileEditState => 'Staat / Regio';

  @override
  String get profileEditInstagram => 'Instagram';

  @override
  String get profileEditDatingPreferences => 'Datingvoorkeuren';

  @override
  String get profileEditSeeking => 'Zoekt';

  @override
  String get profileEditAgeRange => 'Leeftijd';

  @override
  String profileEditAgeRangeValue(int min, int max) {
    return '$min–$max';
  }

  @override
  String get profileEditMaxDistance => 'Max. afstand';

  @override
  String get profileEditEducationFilter => 'Opleidingsfilter';

  @override
  String get profileEditSeriousOnly => 'Alleen serieus';

  @override
  String get profileEditVerifiedOnly => 'Alleen geverifieerd';

  @override
  String get profileEditHookupOnly => 'Alleen los contact';

  @override
  String get profileEditYes => 'Ja';

  @override
  String get profileEditNo => 'Nee';

  @override
  String get profileEditIntent => 'Bedoeling';

  @override
  String get profileEditLanguages => 'Talen';

  @override
  String get profileEditDealBreakers => 'Dealbreakers';

  @override
  String get profileEditReligion => 'Religie';

  @override
  String get profileEditPets => 'Huisdieren';

  @override
  String get profileEditWorkout => 'Sporten';

  @override
  String get profileEditPoliticsComfort => 'Politieke voorkeur';

  @override
  String get profileEditInterestsDetails => 'Interesses en details';

  @override
  String get profileEditHobbies => 'Hobby\'s';

  @override
  String get profileEditBooks => 'Boeken';

  @override
  String get profileEditNovels => 'Romans';

  @override
  String get profileEditSongs => 'Liedjes';

  @override
  String get profileEditExtraCurriculars => 'Nevenactiviteiten';

  @override
  String get profileEditAdditionalInfo => 'Aanvullende info';

  @override
  String get profileEditNotSet => 'Niet ingesteld';

  @override
  String get profileEditLoadingTitle => 'Je opgeslagen profiel wordt geladen';

  @override
  String get profileEditLoadingBody =>
      'De gegevens van het aanmaken van je account worden opgehaald.';

  @override
  String get profileEditYourProfile => 'Jouw profiel';

  @override
  String profileEditPercentComplete(int percent) {
    return '$percent% voltooid';
  }

  @override
  String get profileEditPhotoGallery => 'Fotogalerij';

  @override
  String get profileEditManagePhotos => 'Foto\'s beheren';

  @override
  String get profileEditNoPhotos => 'Nog geen foto\'s geüpload.';

  @override
  String get profileEditPrimaryBadge => 'Hoofdfoto';

  @override
  String get engagementHubPromptLoading => 'Vraag van vandaag laden';

  @override
  String get engagementHubPromptIntro =>
      'Beantwoord elke dag één vraag en bouw je reeks op.';

  @override
  String engagementHubPromptRepliedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensen hebben vandaag geantwoord',
      one: '1 persoon heeft vandaag geantwoord',
    );
    return '$_temp0';
  }

  @override
  String engagementHubPromptStreakSummary(int days, int similar) {
    return 'Reeks $days d · vergelijkbare antwoorden: $similar';
  }

  @override
  String get engagementHubBlogTitle => 'Blog · Open Chapters';

  @override
  String get engagementHubBlogSubtitle =>
      'Lees verhalen, deel foto’s en schrijf je eigen verhaal.';

  @override
  String get engagementHubPhotoThemesTitle => 'Fotothema’s';

  @override
  String get engagementHubPhotoThemesSubtitle =>
      'Deel één foto per thema en bekijk die van anderen.';

  @override
  String get engagementHubClubsTitle => 'Boeken- & filmclubs';

  @override
  String get engagementHubClubsSubtitle =>
      'Volg de keuze van de week, praat erover en geef een cijfer.';

  @override
  String get engagementHubCityPilotTitle => 'De stadspilot';

  @override
  String get engagementHubCityPilotSubtitle =>
      'Een kleine community. Gesprekken die plannen worden.';

  @override
  String get engagementDailyPromptTitle => 'Reeks dagelijkse vragen';

  @override
  String get engagementHubVoiceTitle => 'Begeleide spraak-ijsbrekers';

  @override
  String get engagementHubVoiceSubtitle =>
      'Eén begeleide spraakintro van 20-45 s per match per dag';

  @override
  String get engagementCirclesTitle => 'Uitdagingen van lokale kringen';

  @override
  String get engagementHubCirclesSubtitle =>
      'Word lid van een kring in je stad en stuur je bijdrage van deze week in';

  @override
  String get engagementHubCoffeeTitle => 'Koffiepeiling voor groepen';

  @override
  String get engagementHubCoffeeSubtitle =>
      'Maak, stem op en rond eenvoudige afspraakpeilingen af';

  @override
  String get engagementHubGroupsTitle => 'Groepen';

  @override
  String get engagementHubGroupsSubtitle =>
      'Lifestylecommunity’s en privévriendengroepen';

  @override
  String get engagementHubRoomsSubtitle =>
      'Live chatruimtes: kom binnen, praat en maak vrienden';

  @override
  String get engagementHubFriendsTitle => 'Vrienden & introducties';

  @override
  String get engagementHubFriendsSubtitle =>
      'Nodig een vriend die je vertrouwt uit, ook als die niet aan het daten is';

  @override
  String get engagementLevelTitle => 'Level & XP';

  @override
  String get engagementHubLevelSubtitle =>
      'Volg zinvolle activiteit, levelbeloningen en vertrouwensdrempels';

  @override
  String get engagementHubPaywallFree =>
      'De kernvoortgang blijft zonder betaalmuur.';

  @override
  String get engagementHubPolicyUpdating =>
      'Het monetisatiebeleid wordt bijgewerkt.';

  @override
  String engagementHubPremiumAreas(String features) {
    return 'Optionele premiumonderdelen: $features';
  }

  @override
  String get engagementHubEyebrow => 'MEEDOEN';

  @override
  String get engagementHubTitle => 'Samen iets maken.';

  @override
  String get engagementHubSubtitle =>
      'Sterkere matches door vertrouwen en gedeelde activiteiten.';

  @override
  String get engagementHubSectionCreate => 'MAKEN & DELEN';

  @override
  String get engagementHubSectionCreateCaption =>
      'Verhalen, foto’s en clubs die echte gesprekken op gang brengen.';

  @override
  String get engagementHubSectionMeet => 'MENSEN ONTMOETEN';

  @override
  String get engagementHubSectionMeetCaption =>
      'Kleine groepen, vragen en plannen in je eigen tempo.';

  @override
  String get engagementHubSectionProgress => 'VERTROUWEN & VOORTGANG';

  @override
  String get engagementHubSectionProgressCaption =>
      'Je level, je badges en wie je kan vinden.';

  @override
  String get engagementVoiceAppBarTitle => 'Een stem, een beetje dichterbij';

  @override
  String get engagementVoiceHeadline => 'Laat je hallo\nklinken zoals jij.';

  @override
  String get engagementVoiceIntro =>
      'Een optionele introductie van 20–45 seconden, alleen gedeeld in dit gesprek. Tekst is ook altijd welkom.';

  @override
  String engagementVoiceYouAndName(String name) {
    return 'Jij en $name';
  }

  @override
  String get engagementVoiceYouAndYourMatch => 'Jij en je match';

  @override
  String get engagementVoicePrivate => 'Alleen zichtbaar in dit gesprek';

  @override
  String get engagementVoiceConversationsLoadFailed =>
      'Je gesprekken konden niet worden geladen.';

  @override
  String get engagementVoiceNoMatches =>
      'Zodra je een match hebt, kun je hier een spraakintroductie delen. Geen haast.';

  @override
  String get engagementVoicePickConversation => 'Wie wil je gedag zeggen?';

  @override
  String get engagementVoiceStartingPoint => 'Een klein beginpunt';

  @override
  String get engagementVoiceChoosePrompt => 'Kies een vraag';

  @override
  String get engagementVoiceTranscriptLabel => 'Je woorden, op schrift';

  @override
  String get engagementVoiceTranscriptHelper =>
      'Schrijf op wat je zegt, zodat de ander het ook kan lezen. Dit is geen automatische transcriptie.';

  @override
  String engagementVoiceStop(int seconds) {
    return 'Stop · $seconds s';
  }

  @override
  String get engagementVoiceRecord => 'Neem je hallo op';

  @override
  String engagementVoiceRecordAgain(int seconds) {
    return 'Opnieuw opnemen · $seconds s';
  }

  @override
  String get engagementVoiceRecordingReady =>
      'Opname klaar. Controleer je tekst voordat je verstuurt.';

  @override
  String get engagementVoiceRecordingShort =>
      'Dat was een beetje kort. Neem 20–45 seconden op.';

  @override
  String get engagementVoiceDiscard => 'Opname weggooien';

  @override
  String get engagementVoiceSubmitted =>
      'Introductie verstuurd. Goedgekeurde opnames verschijnen hieronder.';

  @override
  String get engagementVoiceSending => 'Versturen…';

  @override
  String get engagementVoiceShare => 'Deel je hallo';

  @override
  String get engagementVoiceCheckedNote =>
      'Opnames worden gecontroleerd voordat ze worden gedeeld. Er is geen autoplay.';

  @override
  String get engagementVoiceYourIntros => 'Jullie spraakintroducties';

  @override
  String get engagementVoiceLatestNote =>
      'De laatste 20 goedgekeurde opnames in dit gesprek. De teksten zijn altijd te lezen.';

  @override
  String get engagementVoiceIntrosLoadFailed =>
      'De introducties konden niet worden geladen. Het gesprek is mogelijk niet meer beschikbaar.';

  @override
  String get engagementVoiceNothingYet =>
      'Nog niets gedeeld. Een simpel hallo is een goed begin.';

  @override
  String get engagementVoiceYourHello => 'Jouw hallo';

  @override
  String engagementVoiceHelloFromName(String name) {
    return 'Een hallo van $name';
  }

  @override
  String get engagementVoiceHelloFromYourMatch => 'Een hallo van je match';

  @override
  String get engagementVoiceTranscriptHeading => 'TEKST';

  @override
  String get engagementVoiceStopPlayback => 'Afspelen stoppen';

  @override
  String engagementVoiceListen(int seconds) {
    return 'Luisteren · $seconds s';
  }

  @override
  String get engagementVoiceReloadPrompts => 'Vragen opnieuw laden';

  @override
  String get engagementVoiceMicPermission =>
      'Geef toegang tot de microfoon om op te nemen. De teksten kun je ook zonder lezen.';

  @override
  String get engagementVoiceStartFailed =>
      'Opnemen kon niet starten. Controleer de microfoontoegang en probeer het opnieuw.';

  @override
  String get engagementVoiceSaveFailed =>
      'De opname kon niet worden opgeslagen. Probeer het opnieuw.';

  @override
  String get engagementVoicePromptsLoadFailed =>
      'De spraakvragen kunnen nu niet worden geladen.';

  @override
  String get engagementSessionUnavailable => 'Geen actieve sessie.';

  @override
  String get engagementVoiceChooseConversation => 'Kies eerst een gesprek.';

  @override
  String get engagementVoiceSelectPrompt => 'Kies een spraakvraag.';

  @override
  String get engagementVoiceEnterTranscript => 'Vul de tekst in.';

  @override
  String get engagementVoiceSessionFailed =>
      'De sessie voor de spraak-ijsbreker kon niet worden gemaakt.';

  @override
  String get engagementVoiceSendFailed =>
      'De spraak-ijsbreker kan nu niet worden verstuurd.';

  @override
  String get engagementVoicePlaybackUserRequired =>
      'Er is een gebruikers-ID nodig om het afspelen te registreren.';

  @override
  String get engagementVoiceMarkPlaybackFailed =>
      'Het afspelen kan nu niet worden geregistreerd.';

  @override
  String get engagementVoicePlayFailed =>
      'Deze opname kan nu niet worden afgespeeld.';

  @override
  String get chatStarterSmile => 'Waar moest je vandaag om glimlachen?';

  @override
  String get chatStarterSunday => 'Jouw ideale zondag: vertel.';

  @override
  String get chatStarterCoffee =>
      'Koffie, een wandeling of een klein avontuur?';

  @override
  String get chatWelcomeTitle => 'Elk goed verhaal\nbegint met een hallo.';

  @override
  String get chatWelcomePending =>
      'Jullie gesprek opent zodra de match bevestigd is.';

  @override
  String get chatWelcomeBody =>
      'Geen perfecte openingszin nodig. Wees gewoon jezelf.';

  @override
  String get chatInspirationEyebrow => 'EEN BEETJE INSPIRATIE';

  @override
  String get chatAllConversations => 'Alle gesprekken';

  @override
  String get chatMakeConnectionEyebrow => 'MAAK CONTACT';

  @override
  String get chatLessSmallTalk => 'Iets minder smalltalk.';

  @override
  String get chatLessSmallTalkBody =>
      'Vraag naar de dingen waar de ander van opleeft. Deel iets dat bij jou past.';

  @override
  String get chatFindTheWords => 'De juiste woorden vinden';

  @override
  String get chatSendJoy => 'Stuur een beetje vreugde';

  @override
  String get chatPaceTitle => 'Jouw tempo. Jouw ruimte.';

  @override
  String get chatPaceBody =>
      'Deel alleen wat goed voelt. Een goede klik respecteert je grenzen.';

  @override
  String get chatWriteMessageHint => 'Schrijf een bericht…';

  @override
  String get chatConversationPaused => 'Gesprek gepauzeerd';

  @override
  String get chatSendingMessageTooltip => 'Bericht wordt verstuurd';

  @override
  String get chatSendMessageTooltip => 'Bericht versturen';

  @override
  String get chatSendGiftTooltip => 'Cadeau sturen';

  @override
  String get chatAddEmojiTooltip => 'Emoji toevoegen';

  @override
  String get chatDraftedWithHelp => 'Met hulp geschreven';

  @override
  String get chatHelpMeSayIt => 'Help me het te zeggen';

  @override
  String get chatEnterToSendHint =>
      'Enter om te versturen · Shift + Enter voor een nieuwe regel';

  @override
  String get chatToday => 'Vandaag';

  @override
  String get chatYesterday => 'Gisteren';

  @override
  String get chatGiftOptions => 'Cadeau-opties';

  @override
  String get chatStatusRead => 'Gelezen';

  @override
  String get chatStatusDelivered => 'Afgeleverd';

  @override
  String get chatStatusSent => 'Verzonden';

  @override
  String get chatGestureGiftHeading => 'Gebaar + roos als cadeau';

  @override
  String get chatGiftForYouHeading => 'Iets kleins voor jou';

  @override
  String chatGiftTone(String tone) {
    return 'Toon: $tone';
  }

  @override
  String get chatFreeGift => 'Gratis cadeau';

  @override
  String get chatCopilotKindOpener => 'Opener';

  @override
  String get chatCopilotKindReply => 'Antwoord';

  @override
  String get chatCopilotKindDateIdea => 'Date-idee';

  @override
  String get chatCopilotToneWarm => 'Warm';

  @override
  String get chatCopilotTonePlayful => 'Speels';

  @override
  String get chatCopilotToneDirect => 'Direct';

  @override
  String chatCopilotIntro(String name) {
    return 'Een concept in jouw stijl, op basis van het profiel van $name en jullie gesprek. Het wordt nooit voor je verstuurd, en als je het ongewijzigd verstuurt, ziet de ander dat het met hulp is geschreven.';
  }

  @override
  String chatCopilotDisclosure(String disclosure, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nog $count concepten vandaag.',
      one: 'Nog 1 concept vandaag.',
    );
    return '$disclosure $_temp0';
  }

  @override
  String get chatCopilotDraftIt => 'Opstellen';

  @override
  String get chatCopilotTryAnother => 'Nog een';

  @override
  String get chatCopilotUseAndEdit => 'Gebruiken en bewerken';

  @override
  String get chatCopilotEmpty => 'De copiloot gaf niets terug.';

  @override
  String get chatCopilotUnavailable => 'De copiloot is niet beschikbaar.';

  @override
  String get chatErrorMatchEnded => 'Deze match is beëindigd.';

  @override
  String get chatErrorLoadMessages =>
      'Berichten konden niet worden geladen. Probeer het opnieuw.';

  @override
  String get chatErrorLockedQuest =>
      'De chat is vergrendeld tot de opdracht is goedgekeurd.';

  @override
  String get chatErrorSendFailed => 'Bericht kon niet worden verstuurd.';

  @override
  String get chatErrorDeleteFailed => 'Bericht kon niet worden verwijderd.';

  @override
  String get chatErrorDeleteWindowExpired =>
      'Verwijdertermijn verlopen (24 u).';

  @override
  String get chatErrorOnlyReceivedGifts =>
      'Alleen ontvangen cadeaus kunnen worden beheerd.';

  @override
  String get chatErrorGiftGone => 'Dit cadeau is niet meer beschikbaar.';

  @override
  String get chatErrorGiftReportFailed =>
      'Dit cadeau kon niet worden gemeld. Probeer het opnieuw.';

  @override
  String get chatErrorGiftHideFailed =>
      'Dit cadeau kon niet worden verborgen. Probeer het opnieuw.';

  @override
  String get chatErrorGiftsUnavailable =>
      'Rozen als cadeau zijn momenteel niet beschikbaar.';

  @override
  String chatErrorNotEnoughCoins(String gift) {
    return 'Niet genoeg munten om $gift te sturen.';
  }

  @override
  String get chatErrorNotEnoughCoinsSelected =>
      'Niet genoeg munten voor het gekozen cadeau.';

  @override
  String get chatErrorWalletFrozen =>
      'Je munten staan vast terwijl we een terugbetaalde aankoop controleren. Gratis cadeaus zijn nog beschikbaar.';

  @override
  String get chatErrorGiftVelocity =>
      'Je hebt in korte tijd veel cadeaus verstuurd. Probeer het later opnieuw.';

  @override
  String get chatErrorFreeGiftUsed =>
      'Je hebt het gratis cadeau van vandaag al verstuurd. Na middernacht UTC is er een nieuw.';

  @override
  String chatErrorGiftNotAvailable(String gift) {
    return '$gift is nu niet beschikbaar.';
  }

  @override
  String get chatErrorGiftNeedsActiveMatch =>
      'Cadeaus kun je alleen in een actieve match sturen.';

  @override
  String get chatErrorExclusiveGiftOnce =>
      'Dit exclusieve cadeau kun je vandaag maar één keer sturen.';

  @override
  String get chatErrorGiftFailed => 'Cadeau kon niet worden verstuurd.';

  @override
  String get chatErrorSessionUnavailable =>
      'Gebruikerssessie niet beschikbaar.';

  @override
  String get chatErrorConversationUnavailable => 'Gesprek niet beschikbaar.';

  @override
  String get verificationLandingTitle => 'Verifieer met vertrouwen';

  @override
  String get verificationLandingBody =>
      'Upload een duidelijk officieel identiteitsbewijs en een recente selfie. Bestanden worden versleuteld verstuurd en opgeslagen in een privé-bewijsomgeving.';

  @override
  String get verificationLandingDisclaimer =>
      'Een controle geeft je profiel extra context. Het garandeert nooit de identiteit, bedoelingen of veiligheid van iemand anders.';

  @override
  String get verificationViewVerifiedStatus => 'Bekijk geverifieerde status';

  @override
  String get verificationViewReviewStatus => 'Bekijk status van de controle';

  @override
  String get verificationStartButton => 'Start veilige verificatie';

  @override
  String get verificationUploadIdTitle => 'ID uploaden';

  @override
  String get verificationUploadIdInstruction =>
      'Maak of upload een duidelijke foto van je officiële identiteitsbewijs.';

  @override
  String get verificationGallery => 'Galerij';

  @override
  String get verificationCamera => 'Camera';

  @override
  String get verificationNext => 'Volgende';

  @override
  String get verificationSelfieTitle => 'Selfie';

  @override
  String get verificationSelfieInstruction => 'Maak een duidelijke selfie.';

  @override
  String get verificationUploadFailed =>
      'We konden je bewijsstukken niet uploaden. Controleer de bestanden en probeer het opnieuw.';

  @override
  String get verificationSubmit => 'Versturen';

  @override
  String get verificationStatusTitle => 'Verificatiestatus';

  @override
  String get verificationRetry => 'Opnieuw proberen';

  @override
  String get verificationStatusVerified => 'Geverifieerd';

  @override
  String get verificationStatusVerifiedMessage => 'Je verificatie is voltooid.';

  @override
  String get verificationStatusRejected => 'Afgewezen';

  @override
  String get verificationStatusRejectedFallback => 'Probeer het opnieuw.';

  @override
  String get verificationStatusPending => 'In behandeling';

  @override
  String get verificationStatusPendingMessage => 'De controle is bezig.';

  @override
  String get verificationStatusNotStarted => 'Niet gestart';

  @override
  String get verificationStatusNotStartedMessage =>
      'Start de verificatie via Instellingen.';

  @override
  String get safetySosTitle => 'Nood-SOS';

  @override
  String get safetySosDefaultMessage =>
      'Ik heb direct hulp nodig. Kijk alsjeblieft hoe het met me gaat.';

  @override
  String get safetySosHeadline => 'Noodmelding activeren';

  @override
  String get safetySosIntro =>
      'Ben je in direct gevaar? Neem eerst contact op met de lokale hulpdiensten. Deze melding wordt vastgelegd voor het veiligheidsteam.';

  @override
  String get safetySosLevelUrgent => 'Dringend';

  @override
  String get safetySosLevelCritical => 'Kritiek';

  @override
  String get safetySosMessageLabel => 'Bericht voor het veiligheidsteam';

  @override
  String get safetySosActivating => 'Activeren…';

  @override
  String get safetySosActivate => 'SOS activeren';

  @override
  String get safetySosLocationNote =>
      'Je locatie wordt alleen voor deze melding gevraagd. Je kunt doorgaan als je geen toestemming geeft.';

  @override
  String get safetySosHistoryTitle => 'Meldingsgeschiedenis';

  @override
  String get safetySosHistoryEmpty => 'Geen SOS-meldingen vastgelegd.';

  @override
  String safetySosHistoryHeading(String level, String status) {
    return '$level · $status';
  }

  @override
  String get safetySosAlertLevelLow => 'LAAG';

  @override
  String get safetySosAlertLevelMedium => 'GEMIDDELD';

  @override
  String get safetySosAlertLevelHigh => 'HOOG';

  @override
  String get safetySosAlertLevelCritical => 'KRITIEK';

  @override
  String get safetySosAlertStatusOpen => 'open';

  @override
  String get safetySosAlertStatusActive => 'actief';

  @override
  String get safetySosAlertStatusAcknowledged => 'bevestigd';

  @override
  String get safetySosAlertStatusResolved => 'opgelost';

  @override
  String safetySosHistoryMetaWithLocation(String date) {
    return '$date · met locatie';
  }

  @override
  String safetySosHistoryMetaNoLocation(String date) {
    return '$date · zonder locatie';
  }

  @override
  String safetySosResolution(String note) {
    return 'Afhandeling: $note';
  }

  @override
  String get safetySosConfirmTitle => 'SOS nu activeren?';

  @override
  String get safetySosConfirmBody =>
      'Hiermee maak je een noodmelding voor het veiligheidsteam en proberen we je huidige locatie toe te voegen.';

  @override
  String get safetySosCancel => 'Annuleren';

  @override
  String get safetySosConfirmActivate => 'Activeren';

  @override
  String get safetySosActivatedTitle => 'SOS-melding geactiveerd';

  @override
  String get safetySosActivatedWithLocation =>
      'Je melding en huidige locatie zijn vastgelegd.';

  @override
  String get safetySosActivatedWithoutLocation =>
      'Je melding is vastgelegd zonder locatie. Locatietoestemming was niet beschikbaar of is geweigerd.';

  @override
  String get safetySosDone => 'Klaar';

  @override
  String get safetySosSignInToView =>
      'Log in om je SOS-geschiedenis te bekijken.';

  @override
  String get safetySosLoadFailed => 'SOS-geschiedenis kon niet worden geladen.';

  @override
  String get safetySosSignInToActivate => 'Log in voordat je SOS activeert.';

  @override
  String get safetySosActivateFailed => 'SOS kon niet worden geactiveerd.';

  @override
  String get photoThemesTitle => 'Fotothema\'s';

  @override
  String get photoThemesSignIn => 'Log in om de fotothema\'s te zien.';

  @override
  String get photoThemesHeroTitle => 'Laat een stukje van je wereld zien';

  @override
  String get photoThemesHeroSubtitle =>
      'Kies een thema, deel één foto en bekijk wat anderen deelden. Zo begin je makkelijk een gesprek.';

  @override
  String get photoThemesLoadFailed => 'Thema\'s konden niet worden geladen';

  @override
  String get photoThemesCheckConnection => 'Controleer je verbinding.';

  @override
  String get photoThemesLookAround => 'Je kunt rondkijken';

  @override
  String get photoThemesEligibilityShareOwn =>
      'Maak je profiel compleet met twee goedgekeurde foto\'s om zelf te delen.';

  @override
  String get photoThemesNewPromptsTitle => 'Er komen nieuwe thema\'s aan';

  @override
  String get photoThemesNewPromptsBody =>
      'Kom snel terug voor iets om te delen.';

  @override
  String photoThemesSharedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gedeeld',
      one: '$count gedeeld',
    );
    return '$_temp0';
  }

  @override
  String get photoThemesYouShared => 'Je hebt gedeeld ✓';

  @override
  String get photoThemesBeFirst => 'Deel als eerste →';

  @override
  String get photoThemesSeeEveryone => 'Bekijk ieders foto\'s →';

  @override
  String get photoThemesSharedSnack => 'Je foto is gedeeld. Goed zo!';

  @override
  String get photoThemesShareFailed =>
      'Je foto kon niet worden gedeeld. Gebruik een JPEG of PNG tot 10 MB.';

  @override
  String get photoThemesEligibilityShare =>
      'Maak je profiel compleet met twee goedgekeurde foto\'s om te delen.';

  @override
  String get photoThemesAlreadyShared =>
      'Je hebt al gedeeld voor dit thema. Verwijder je foto om een nieuwe te delen.';

  @override
  String get photoThemesThemeFallback => 'Fotothema';

  @override
  String get photoThemesShareTooltip => 'Deel een foto voor dit thema';

  @override
  String get photoThemesShareYourPhoto => 'Deel je foto';

  @override
  String get photoThemesNoPhotosYet => 'Nog geen foto\'s';

  @override
  String photoThemesBeFirstFor(String title) {
    return 'Deel als eerste voor ‘$title’';
  }

  @override
  String get photoThemesLoadingPrompt => 'Thema laden…';

  @override
  String get photoThemesPhotosLoadFailed =>
      'Foto\'s konden niet worden geladen';

  @override
  String get photoThemesEmptyMessage =>
      'Jouw foto kan net die zijn waar iedereen over praat.';

  @override
  String get photoThemesMoreFailed =>
      'Meer foto\'s konden niet worden geladen. Herladen';

  @override
  String get photoThemesLoadMore => 'Meer laden';

  @override
  String get photoThemesPhotoUnavailable =>
      'Foto niet beschikbaar. Opnieuw proberen';

  @override
  String photoThemesOpenPhoto(String name) {
    return 'Foto van $name openen';
  }

  @override
  String get photoThemesYou => 'Jij';

  @override
  String get photoThemesWallHelp =>
      'Als leden je foto geweldig vinden, kan hij op hun Today-walls komen: 50 likes en 5 reacties brengen hem op 50 walls, 100 likes en 10 reacties op 100. Je kunt dit altijd uitzetten.';

  @override
  String get photoThemesRemoveTitle => 'Je foto verwijderen?';

  @override
  String get photoThemesRemoveMessage =>
      'Hij verdwijnt voor iedereen uit dit thema. Daarna kun je een nieuwe delen.';

  @override
  String get photoThemesRemoveAction => 'Foto verwijderen';

  @override
  String get photoThemesRemoveFailed => 'Je foto kon niet worden verwijderd.';

  @override
  String get photoThemesReachOn =>
      'Je foto kan nu op de walls van leden komen als ze hem geweldig vinden.';

  @override
  String get photoThemesReachOff => 'Je foto staat op geen enkele wall meer.';

  @override
  String get photoThemesSharedByYou => 'Gedeeld door jou';

  @override
  String photoThemesSharedBy(String name) {
    return 'Gedeeld door $name';
  }

  @override
  String photoThemesPhotoDescription(String text) {
    return 'Fotobeschrijving: $text';
  }

  @override
  String get photoThemesReachSwitch =>
      'Laten verschijnen op walls van andere leden';

  @override
  String get photoThemesReachIdle => 'Leden kunnen deze foto verder brengen';

  @override
  String get photoThemesReachLive => 'Leden zien hem nu op hun Today-walls.';

  @override
  String get photoThemesRemoveMine => 'Mijn foto verwijderen';

  @override
  String get photoThemesReport => 'Melden';

  @override
  String photoThemesBlock(String name) {
    return '$name blokkeren';
  }

  @override
  String get photoThemesCommentHint => 'Waar doet het je aan denken?';

  @override
  String get photoThemesCommentApproved =>
      'Goedgekeurd. Iedereen die deze foto kan zien, ziet hem nu.';

  @override
  String get photoThemesDetailsTitle => 'Vertel erover';

  @override
  String get photoThemesCaption => 'Bijschrift';

  @override
  String get photoThemesCaptionHint =>
      'Pannenkoeken, en dan nergens heen hoeven.';

  @override
  String get photoThemesDescribe => 'Beschrijf de foto';

  @override
  String get photoThemesDescribeHelper =>
      'Helpt leden die een schermlezer gebruiken.';

  @override
  String get photoThemesShare => 'Delen';

  @override
  String get photoThemesWallTitle => 'Covers op je wall';

  @override
  String get photoThemesWallCaption => 'Foto\'s waar andere leden dol op waren';

  @override
  String get photoThemesMasthead => 'FOTOTHEMA\'S';

  @override
  String photoThemesByline(String name) {
    return 'DOOR $name';
  }

  @override
  String get photoThemesLikes => 'Likes';

  @override
  String get photoThemesComments => 'Reacties';

  @override
  String get photoThemesCancel => 'Annuleren';

  @override
  String get photoThemesTryAgain => 'Opnieuw proberen';

  @override
  String get photoThemesSaveFailed =>
      'Dat is niet opgeslagen. Probeer het opnieuw.';

  @override
  String get friendsChatEmpty =>
      'Zeg hallo. Alleen jullie tweeën kunnen dit gesprek zien.';

  @override
  String get friendsChatOpenFailed =>
      'Kan de chat niet openen. Probeer het opnieuw.';

  @override
  String get friendsCancelRequestTitle => 'Je vriendschapsverzoek annuleren?';

  @override
  String friendsCancelRequestBody(String name) {
    return '$name ziet je verzoek dan niet meer.';
  }

  @override
  String get friendsCancelRequestBodyUnnamed =>
      'Dit lid ziet je verzoek dan niet meer.';

  @override
  String get friendsKeepIt => 'Behouden';

  @override
  String get friendsCancelRequest => 'Verzoek annuleren';

  @override
  String friendsNowFriends(String name) {
    return 'Jij en $name zijn nu vrienden.';
  }

  @override
  String get friendsNowFriendsUnnamed => 'Jij en dit lid zijn nu vrienden.';

  @override
  String friendsRequestSentTo(String name) {
    return 'Vriendschapsverzoek verstuurd naar $name.';
  }

  @override
  String get friendsRequestSentToUnnamed =>
      'Vriendschapsverzoek verstuurd naar dit lid.';

  @override
  String get friendsRequestCancelled => 'Verzoek geannuleerd.';

  @override
  String get friendsRequestFailed => 'Kan het verzoek niet versturen.';

  @override
  String get friendsAddCaption =>
      'Vrienden kunnen elkaar berichten sturen en samen dingen plannen';

  @override
  String get friendsRequested => 'Aangevraagd';

  @override
  String friendsWaitingFor(String name) {
    return 'Wachten op $name. Tik om te annuleren.';
  }

  @override
  String get friendsWaitingForUnnamed =>
      'Wachten op dit lid. Tik om te annuleren.';

  @override
  String get friendsAcceptFriend => 'Vriend accepteren';

  @override
  String friendsAskedToBeFriends(String name) {
    return '$name wil vrienden worden';
  }

  @override
  String get friendsAskedToBeFriendsUnnamed => 'Dit lid wil vrienden worden';

  @override
  String get friendsMessage => 'Bericht';

  @override
  String get friendsYoureFriends => 'Jullie zijn vrienden. Open jullie chat.';

  @override
  String friendsVouchTooShort(int min) {
    return 'Schrijf iets meer (minstens $min tekens).';
  }

  @override
  String friendsVouchTitle(String name) {
    return '$name aanbevelen';
  }

  @override
  String get friendsVouchBody =>
      'Een zin of twee over waarom iemand geluk heeft om deze persoon te ontmoeten. Die keurt het goed voordat het met je voornaam op het profiel verschijnt.';

  @override
  String get friendsVouchLabel => 'Je aanbeveling';

  @override
  String get friendsVouchHint => 'Lief, grappig en altijd op tijd.';

  @override
  String get friendsVouchSend => 'Aanbeveling versturen';

  @override
  String get friendsIntroChooseTwo => 'Kies twee verschillende vrienden.';

  @override
  String get friendsIntroSheetTitle => 'Twee vrienden aan elkaar voorstellen';

  @override
  String get friendsIntroSheetBody =>
      'Beide vrienden moeten introducties toestaan. Ieder bepaalt het eigen voorbeeld en beslist privé. Deel alleen een reden die je mag noemen. Hun beslissingen en of het een match wordt, blijven privé.';

  @override
  String get friendsIntroNeedTwo =>
      'Je hebt minstens twee geaccepteerde vrienden nodig voor een intro.';

  @override
  String get friendsFirstFriend => 'Eerste vriend';

  @override
  String get friendsSecondFriend => 'Tweede vriend';

  @override
  String get friendsIntroWhyLabel =>
      'Waarom ze elkaar moeten ontmoeten (optioneel)';

  @override
  String get friendsIntroSubmit => 'Intro maken';

  @override
  String get friendsLoadFailed =>
      'Kan vrienden niet laden. Probeer het opnieuw.';

  @override
  String get friendsAddFailed => 'Kan vriend niet toevoegen.';

  @override
  String get friendsRemoveFailed => 'Kan vriend niet verwijderen.';

  @override
  String get friendsRespondFailed =>
      'Kan niet reageren op het vriendschapsverzoek.';

  @override
  String get friendsSocialLoadFailed =>
      'Kan aanbevelingen en intro’s niet laden.';

  @override
  String get friendsVouchSendFailed => 'Kan deze aanbeveling niet versturen.';

  @override
  String get friendsVouchUpdateFailed => 'Kan deze aanbeveling niet bijwerken.';

  @override
  String get friendsVouchWithdrawFailed =>
      'Kan deze aanbeveling niet intrekken.';

  @override
  String get friendsIntroMakeFailed => 'Kan deze intro niet maken.';

  @override
  String get friendsIntroAnswerFailed => 'Kan niet reageren op deze intro.';

  @override
  String get groupsEyebrow => 'GROEPEN';

  @override
  String get groupsTitle => 'Vind je mensen.';

  @override
  String get groupsSubtitle =>
      'Lifestylecommunity’s waar iedereen lid van kan worden, en privégroepen alleen voor je vrienden.';

  @override
  String get groupsStartGroup => 'Groep starten';

  @override
  String get groupsInvitationsHeader => 'UITNODIGINGEN';

  @override
  String get groupsInvitationsCaption => 'Vrienden hebben je uitgenodigd.';

  @override
  String get groupsAnswerFailed => 'Je antwoord kon niet worden opgeslagen.';

  @override
  String groupsWelcome(String name) {
    return 'Welkom bij $name!';
  }

  @override
  String get groupsInvitationDeclined => 'Uitnodiging afgewezen.';

  @override
  String get groupsYourGroupsHeader => 'JOUW GROEPEN';

  @override
  String get groupsYourGroupsFailed => 'Je groepen konden niet worden geladen';

  @override
  String get groupsErrorCheckConnection => 'Controleer je verbinding.';

  @override
  String get groupsEmptyTitle => 'Nog geen groepen';

  @override
  String get groupsEmptyBody =>
      'Word hieronder lid van een community of start een privégroep met je vrienden.';

  @override
  String get groupsDiscoverHeader => 'ONTDEK OP LIFESTYLE';

  @override
  String get groupsDiscoverCaption =>
      'Communitygroepen staan open voor iedereen.';

  @override
  String get groupsLifestylesFailed => 'Lifestyles konden niet worden geladen';

  @override
  String get groupsCategoryAll => 'Alle';

  @override
  String get groupsDiscoverFailed => 'Groepen konden niet worden geladen';

  @override
  String get groupsDiscoverEmptyTitle => 'Niets nieuws om lid van te worden';

  @override
  String groupsDiscoverEmptyCategoryTitle(String category) {
    return 'Nog geen groepen voor $category';
  }

  @override
  String get groupsDiscoverEmptyBody =>
      'Wees de eerste: start een communitygroep en nodig je vrienden uit.';

  @override
  String get groupsStartOne => 'Start er een';

  @override
  String get groupsJoinFailed => 'Lid worden lukte nu niet.';

  @override
  String get groupsJoin => 'Lid worden';

  @override
  String groupsJoinNamed(String name) {
    return 'Lid worden van $name';
  }

  @override
  String groupsInvitedBy(String name, String kind, String members) {
    return '$name heeft je uitgenodigd · $kind · $members';
  }

  @override
  String groupsInvitedByFriend(String kind, String members) {
    return 'Een vriend heeft je uitgenodigd · $kind · $members';
  }

  @override
  String get groupsDecline => 'Afwijzen';

  @override
  String groupsDeclineNamed(String name) {
    return '$name afwijzen';
  }

  @override
  String groupsChatEmpty(String name) {
    return 'Zeg hallo tegen de groep. Iedereen in $name kan de berichten hier zien.';
  }

  @override
  String groupsInviteFriendsTo(String name) {
    return 'Vrienden uitnodigen voor $name';
  }

  @override
  String get groupsSendInvitations => 'Uitnodigingen versturen';

  @override
  String get groupsInvitationsFailed =>
      'De uitnodigingen konden niet worden verstuurd.';

  @override
  String groupsInvitationSentTo(String name) {
    return 'Uitnodiging verstuurd naar $name.';
  }

  @override
  String groupsInvitationsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uitnodigingen verstuurd.',
      one: '1 uitnodiging verstuurd.',
    );
    return '$_temp0';
  }

  @override
  String groupsLeaveTitle(String name) {
    return '$name verlaten?';
  }

  @override
  String get groupsLeaveBodyAlone =>
      'Je bent het enige lid, dus de groep en de chat worden verwijderd.';

  @override
  String get groupsLeaveBodyOwner =>
      'Het eigenaarschap gaat naar je langstzittende moderator, of anders naar het langstzittende lid. Je verliest de toegang tot de chat.';

  @override
  String get groupsLeaveBodyCommunity =>
      'Je verliest de toegang tot de groepschat. Je kunt later opnieuw lid worden.';

  @override
  String get groupsLeaveBodyPrivate =>
      'Je verliest de toegang tot de groepschat. Je hebt een nieuwe uitnodiging nodig om terug te komen.';

  @override
  String get groupsLeave => 'Verlaten';

  @override
  String get groupsLeaveFailed => 'Verlaten lukte nu niet.';

  @override
  String get groupsCoverUploadFailed =>
      'Je omslagfoto kon niet worden geüpload. Gebruik een JPEG of PNG tot 10 MB.';

  @override
  String get groupsRemoveCoverTitle => 'Omslagfoto verwijderen?';

  @override
  String groupsRemoveCoverBody(String name) {
    return '$name toont dan weer de emoji-omslag.';
  }

  @override
  String get groupsRemove => 'Verwijderen';

  @override
  String get groupsRemoveCoverFailed =>
      'De omslagfoto kon niet worden verwijderd.';

  @override
  String get groupsCoverRemoved => 'Omslagfoto verwijderd.';

  @override
  String groupsDeleteTitle(String name) {
    return '$name verwijderen?';
  }

  @override
  String get groupsDeleteBody =>
      'De groep, de uitnodigingen en de chat worden voor iedereen verwijderd. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get groupsDeleteGroup => 'Groep verwijderen';

  @override
  String get groupsDeleteFailed => 'De groep kon niet worden verwijderd.';

  @override
  String get groupsDetailEyebrow => 'GROEP';

  @override
  String get groupsDetailTitleFallback => 'Groep';

  @override
  String get groupsOwnerTools => 'Beheeropties';

  @override
  String get groupsEditGroup => 'Groep bewerken';

  @override
  String get groupsAddCoverPhoto => 'Omslagfoto toevoegen';

  @override
  String get groupsChangeCoverPhoto => 'Omslagfoto wijzigen';

  @override
  String get groupsRemoveCoverPhoto => 'Omslagfoto verwijderen';

  @override
  String get groupsMoreOptions => 'Meer opties';

  @override
  String get groupsReportGroup => 'Groep melden';

  @override
  String get groupsUnavailableTitle => 'Deze groep is niet beschikbaar';

  @override
  String get groupsUnavailableBody =>
      'Misschien is ze verwijderd of heb je geen toegang meer.';

  @override
  String get groupsOpenToAll => 'Open voor iedereen';

  @override
  String get groupsPrivate => 'Privé';

  @override
  String get groupsYouRunIt => 'Jij beheert deze';

  @override
  String get groupsYouModerate => 'Jij modereert';

  @override
  String get groupsCoverNotePending =>
      'Alleen jij ziet deze foto totdat hij is goedgekeurd. Leden zien in de tussentijd de emoji-omslag.';

  @override
  String get groupsCoverNoteRejected =>
      'Je laatste omslagfoto is niet goedgekeurd. Kies een andere.';

  @override
  String get groupsCoverUnderReview => 'Wordt beoordeeld';

  @override
  String get groupsChangeCover => 'Omslag wijzigen';

  @override
  String get groupsRemoveCover => 'Omslag verwijderen';

  @override
  String get groupsRemovedTitle =>
      'Deze groep is na een beoordeling verwijderd';

  @override
  String get groupsRemovedBodyOwner =>
      'Zolang ze verwijderd is, kunnen leden niet chatten, lid worden of uitnodigen. In je beoordelingsmeldingen lees je de beslissing en kun je bezwaar maken.';

  @override
  String get groupsRemovedBodyMember =>
      'Zolang ze verwijderd is, kunnen leden niet chatten, lid worden of uitnodigen. Je kunt de groep altijd verlaten.';

  @override
  String get groupsMembers => 'Leden';

  @override
  String get groupsChatButton => 'Groepschat';

  @override
  String groupsChatButtonUnread(int count) {
    return 'Groepschat · $count nieuw';
  }

  @override
  String get groupsInviteFriends => 'Vrienden uitnodigen';

  @override
  String get groupsWhosHere => 'WIE ER ZIJN';

  @override
  String get groupsSeeAll => 'Alles bekijken';

  @override
  String get groupsYou => 'Jij';

  @override
  String groupsInvitedToJoin(String name) {
    return 'Je bent uitgenodigd voor $name.';
  }

  @override
  String get groupsJoinGroup => 'Lid worden';

  @override
  String get groupsJoinHint => 'Leden zien wie er zijn en chatten samen.';

  @override
  String get groupsCantJoinTitle => 'Je kunt geen lid worden van deze groep';

  @override
  String get groupsCantJoinBody =>
      'Misschien is ze vol, of heeft een moderator je verwijderd.';

  @override
  String get groupsInvitationOnly => 'Alleen op uitnodiging';

  @override
  String get groupsInvitationOnlyBody =>
      'Een lid kan je uitnodigen voor deze privégroep.';

  @override
  String get groupsMakeModerator => 'Moderator maken';

  @override
  String get groupsMakeMember => 'Lid maken';

  @override
  String get groupsRemoveFromGroup => 'Uit de groep verwijderen';

  @override
  String groupsRemoveMemberTitle(String name) {
    return '$name verwijderen?';
  }

  @override
  String get groupsRemoveMemberBodyCommunity =>
      'Diegene verlaat de groep en de chat en kan niet zelf opnieuw lid worden.';

  @override
  String get groupsRemoveMemberBodyPrivate =>
      'Diegene verlaat de groep en de chat.';

  @override
  String get groupsChangeFailed => 'Die wijziging kon niet worden opgeslagen.';

  @override
  String get groupsMembersFailed => 'Leden konden niet worden geladen';

  @override
  String get groupsPleaseTryAgain => 'Probeer het opnieuw.';

  @override
  String groupsMemberYou(String name) {
    return '$name (jij)';
  }

  @override
  String get groupsRoleOwner => 'Eigenaar';

  @override
  String get groupsRoleModerator => 'Moderator';

  @override
  String get groupsRoleMember => 'Lid';

  @override
  String groupsMemberOptions(String name) {
    return 'Opties voor $name';
  }

  @override
  String get groupsEditFailed =>
      'Je wijzigingen konden niet worden opgeslagen.';

  @override
  String get groupsSaving => 'Opslaan…';

  @override
  String get groupsSaveChanges => 'Wijzigingen opslaan';

  @override
  String get groupsNameLabel => 'Groepsnaam';

  @override
  String get groupsAboutLabel => 'Waar gaat het over?';

  @override
  String get groupsAboutOptionalLabel => 'Waar gaat het over? (optioneel)';

  @override
  String get groupsCityLabel => 'Stad (optioneel)';

  @override
  String get groupsCoverColorTheme => 'Thema';

  @override
  String get groupsCoverColorAccent => 'Accent';

  @override
  String get groupsCoverColorWarm => 'Warm';

  @override
  String get groupsLifestyleLabel => 'Lifestyle';

  @override
  String get groupsCreateCoverUploadFailed =>
      'Je groep is klaar, maar de omslagfoto kon niet worden geüpload. Probeer het opnieuw vanuit de groep.';

  @override
  String get groupsCreatePickLifestyle =>
      'Kies een lifestyle voor je communitygroep.';

  @override
  String get groupsCreateNameTooShort =>
      'Geef je groep een naam van minstens 3 letters.';

  @override
  String get groupsCreateFailed =>
      'Je groep kon niet worden aangemaakt. Probeer het opnieuw.';

  @override
  String get groupsCreateEyebrow => 'NIEUWE GROEP';

  @override
  String get groupsCreateSubtitle =>
      'Breng mensen samen rond waar jij van houdt.';

  @override
  String get groupsCreateSubtitleFriends => 'Maak van je vrienden een groep.';

  @override
  String get groupsCreateKindHeader => 'WELK SOORT';

  @override
  String get groupsKindCommunity => 'Communitygroep';

  @override
  String get groupsKindPrivate => 'Privégroep';

  @override
  String get groupsCreateCommunitySubtitle =>
      'Op lifestyle. Iedereen kan hem vinden en lid worden.';

  @override
  String get groupsCreatePrivateSubtitle =>
      'Alleen vrienden. Alleen mensen die je uitnodigt, kunnen lid worden.';

  @override
  String get groupsCreateLifestyleHeader => 'LIFESTYLE';

  @override
  String get groupsCreateLifestyleCaption => 'Waar mensen je groep ontdekken.';

  @override
  String get groupsCreateDetailsHeader => 'DETAILS';

  @override
  String get groupsCreateNameHintCommunity =>
      'Zonsopgangrenners van Indiranagar';

  @override
  String get groupsCreateNameHintPrivate => 'De zondagsbrunchclub';

  @override
  String get groupsCreateCoverHeader => 'OMSLAG';

  @override
  String groupsCoverEmojiSemantics(String emoji) {
    return 'Omslag-emoji $emoji';
  }

  @override
  String get groupsCreateCoverPhotoOptional => 'Omslagfoto (optioneel)';

  @override
  String get groupsCreateCoverPhotoHint =>
      'Leden zien de emoji totdat je foto is goedgekeurd.';

  @override
  String get groupsCreateAddCoverPhoto => 'Een omslagfoto toevoegen';

  @override
  String get groupsCreateChangePhoto => 'Foto wijzigen';

  @override
  String get groupsCreateRemovePhoto => 'Foto verwijderen';

  @override
  String get groupsCreateFriendsHeader => 'VRIENDEN';

  @override
  String get groupsCreateFriendsCaptionEmpty =>
      'Nodig nu vrienden uit, of later vanuit de groep.';

  @override
  String get groupsCreateFriendsCaption =>
      'Ze krijgen een uitnodiging om lid te worden.';

  @override
  String get groupsFriendFallback => 'Vriend';

  @override
  String groupsRemoveInvitee(String name) {
    return '$name verwijderen';
  }

  @override
  String get groupsChooseFriends => 'Vrienden kiezen';

  @override
  String get groupsChangeFriends => 'Vrienden wijzigen';

  @override
  String get groupsCreating => 'Aanmaken…';

  @override
  String get groupsCreateGroup => 'Groep aanmaken';

  @override
  String get groupsCardRemoved => 'Verwijderd na beoordeling';

  @override
  String groupsCardSemanticsMuted(String name, String details) {
    return '$name, $details, meldingen gedempt';
  }

  @override
  String get groupsNotificationsMuted => 'Meldingen gedempt';

  @override
  String groupsUnreadMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ongelezen berichten',
      one: '1 ongelezen bericht',
    );
    return '$_temp0';
  }

  @override
  String get groupsCoverSheetTitle => 'Omslagfoto';

  @override
  String get groupsCoverSheetBody =>
      'Elke foto wordt gecontroleerd voordat andere leden hem kunnen zien. Gebruik een JPEG of PNG tot 10 MB.';

  @override
  String get groupsCoverFromPhotos => 'Kiezen uit je foto’s';

  @override
  String get groupsCoverTakePhoto => 'Foto maken';

  @override
  String get groupsCoverTooLarge =>
      'Die foto is groter dan 10 MB. Kies een kleinere.';

  @override
  String get groupsCoverPreviewTitle => 'Voorbeeld van je omslag';

  @override
  String get groupsCoverPreviewBody =>
      'Omslagen worden als brede banner getoond, met het midden van je foto.';

  @override
  String get groupsCancel => 'Annuleren';

  @override
  String get groupsCoverUseThisPhoto => 'Deze foto gebruiken';

  @override
  String get groupsCoverPreviewSemantics => 'Je nieuwe omslagfoto';

  @override
  String get groupsCoverChecking => 'Je omslagfoto wordt gecontroleerd…';

  @override
  String groupsCoverUploading(int percent) {
    return 'Omslagfoto uploaden… $percent%';
  }

  @override
  String get groupsCoverUploadedReview =>
      'Je omslag wordt beoordeeld. Alleen jij ziet hem totdat hij is goedgekeurd.';

  @override
  String get groupsCoverUpdated => 'Omslagfoto bijgewerkt.';

  @override
  String get groupsPickerSubtitle =>
      'Je kunt alleen vrienden uitnodigen met wie je verbonden bent.';

  @override
  String get groupsDone => 'Klaar';

  @override
  String get groupsSearchFriends => 'Vrienden zoeken';

  @override
  String get groupsFriendsFailed => 'Vrienden konden niet worden geladen';

  @override
  String get groupsNoFriendsTitle => 'Nog geen vrienden';

  @override
  String get groupsNoFriendsBody =>
      'Voeg vrienden toe via Matches, profielen of ruimtes en haal ze daarna in een groep.';

  @override
  String get groupsAlreadyMember => 'Al lid van deze groep';

  @override
  String get groupsInvitationSent => 'Uitnodiging verstuurd';

  @override
  String get todayActivityCoffee => 'Koffie';

  @override
  String get todayActivityWalk => 'Een wandeling overdag';

  @override
  String get todayActivityMeal => 'Een maaltijd';

  @override
  String get todayActivityPlayful => 'Iets speels';

  @override
  String get todayActivityEvent => 'Een evenement';

  @override
  String get todayActivityVideoCall => 'Een videohallo';

  @override
  String get todayActivityDrinks => 'Een drankje';

  @override
  String get todayActivityOther => 'Iets anders';

  @override
  String get todayBudgetFlexible => 'Laten we samen beslissen';

  @override
  String get todayBudgetFree => 'Gratis houden';

  @override
  String get todayBudgetModest => 'Bescheiden houden';

  @override
  String get todayBudgetTreat => 'Een kleine traktatie';

  @override
  String get todayRhythmTitle => 'Jouw datingritme';

  @override
  String get todayRhythmLoadFailed =>
      'Je voorkeuren konden niet worden geladen.';

  @override
  String get todayRhythmSaved => 'Je datingritme is opgeslagen.';

  @override
  String get todayRhythmSaveFailed =>
      'Opslaan is niet gelukt. Je keuzes staan er nog.';

  @override
  String get todayRhythmHeadline => 'Maak ruimte voor jouw manier van daten.';

  @override
  String get todayRhythmIntro =>
      'Kies wat bij je leven past. Beschikbaarheid en kennismakingen zijn optioneel, en je kunt altijd van gedachten veranderen.';

  @override
  String get todayRhythmOpenTo => 'Waar sta je voor open?';

  @override
  String get todayRhythmIntentNone => 'Zeg ik liever niet';

  @override
  String get todayRhythmIntentRelationship => 'Een relatie';

  @override
  String get todayRhythmIntentExploring => 'Ik ben nog zoekende';

  @override
  String get todayRhythmIntentCasual => 'Iets luchtigs';

  @override
  String get todayRhythmPaceSection => 'Jouw gesprekstempo';

  @override
  String get todayRhythmPaceNone => 'Geen voorkeur';

  @override
  String get todayRhythmPaceSlow => 'Iets rustiger';

  @override
  String get todayRhythmPaceSteady => 'Een gestaag gesprek';

  @override
  String get todayRhythmPaceFrequent => 'Vaak contact';

  @override
  String get todayRhythmSlowWeek => 'Trage reacties deze week';

  @override
  String get todayRhythmSlowWeekHint => 'Deze status verdwijnt na zeven dagen.';

  @override
  String get todayRhythmSharePace => 'Deze status delen met mijn matches';

  @override
  String get todayRhythmSharePaceHint =>
      'Alleen je huidige matches zien je tijdelijke status.';

  @override
  String get todayRhythmFirstDate => 'Jouw soort eerste date';

  @override
  String get todayRhythmChooseFive =>
      'Kies er maximaal vijf. Gedeelde voorkeuren helpen je kennismakingen te verklaren.';

  @override
  String get todayRhythmWeekSection => 'Wat ruimte in je week';

  @override
  String get todayRhythmShareAvailability =>
      'Mijn globale beschikbaarheid gebruiken';

  @override
  String get todayRhythmShareAvailabilityHint =>
      'Alleen echte overlap wordt getoond. Je volledige agenda blijft privé. Als je dit uitzet, worden opgeslagen tijdvakken verwijderd.';

  @override
  String get todayRhythmAvailabilityHint =>
      'Tik op elke ochtend, middag of avond die je uitkomt. Tijden volgen de lokale tijd van dit apparaat en verlopen automatisch.';

  @override
  String get todayRhythmMorning => 'Ochtend';

  @override
  String get todayRhythmAfternoon => 'Middag';

  @override
  String get todayRhythmEvening => 'Avond';

  @override
  String get todayRhythmIntrosSection => 'Kennismakingen met jouw toestemming';

  @override
  String get todayRhythmFriendIntros =>
      'Kennismakingen via geaccepteerde vrienden toestaan';

  @override
  String get todayRhythmFriendIntrosHint =>
      'Beide mensen moeten instemmen. Je vriend krijgt geen updates over een match of afwijzing. Een voorbeeld toont je naam en leeftijd.';

  @override
  String get todayRhythmIntroPhoto => 'Mijn profielfoto\'s meesturen';

  @override
  String get todayRhythmIntroPhotoHint =>
      'Alleen degene die de kennismaking ontvangt, kan ze zien.';

  @override
  String get todayRhythmIntroCity => 'Mijn stad meesturen';

  @override
  String get todayRhythmIntroCityHint =>
      'Je exacte locatie wordt nooit gedeeld.';

  @override
  String get todayRhythmReload => 'Opgeslagen keuzes herladen';

  @override
  String get todayRhythmSaving => 'Opslaan…';

  @override
  String get todayRhythmSave => 'Mijn ritme opslaan';

  @override
  String get todayRhythmBreakTitle => 'Een pauze is altijd oké.';

  @override
  String get todayRhythmBreakBody =>
      'Pauzeer nieuwe kennismakingen wanneer je wilt. Je bestaande gesprekken blijven beschikbaar.';

  @override
  String get todayRhythmPauseFailed => 'Je pauze kon niet worden bijgewerkt.';

  @override
  String get todayRhythmResume => 'Kennismakingen hervatten';

  @override
  String get todayRhythmPause => 'Kennismakingen pauzeren';

  @override
  String get datingConnectionSlowTitle => 'Reageert deze week rustiger';

  @override
  String get datingConnectionSlowBody =>
      'Je match neemt even een rustiger tempo.';

  @override
  String get datingConnectionYourTurn => 'Jouw beurt: voeg een verrassing toe';

  @override
  String get datingConnectionComplete => 'Jullie eerste hoofdstuk is klaar';

  @override
  String get datingConnectionWaiting => 'Jullie hoofdstuk heeft een begin';

  @override
  String get datingConnectionCreate => 'Maak jullie eerste hoofdstuk';

  @override
  String get datingConnectionBody =>
      'Een begin, een verrassing en een verhaal dat jullie samen vormen.';

  @override
  String get chemistryTitle => 'Een beetje chemie';

  @override
  String get chemistryIntro =>
      'Kies iets wat bij je past. Er zijn geen goede antwoorden, en dit bepaalt nooit de toegang tot de chat.';

  @override
  String get chemistrySaveFailed =>
      'Je keuze kon niet worden opgeslagen. Probeer het opnieuw.';

  @override
  String get chemistryRetry => 'Opnieuw laden';

  @override
  String get chemistryRevealedTitle => 'Beide antwoorden, samen';

  @override
  String get chemistryYouPicked => 'Jij koos';

  @override
  String get chemistryMatchPicked => 'Je match koos';

  @override
  String get chemistryRevealedBody =>
      'Een gedeelde favoriet of een leuk verschil — jullie hebben iets om over te praten.';

  @override
  String get chemistryWaitingBody =>
      'Je antwoord is privé opgeslagen. Beide antwoorden verschijnen hier zodra jullie allebei hebben gekozen.';

  @override
  String chemistryYourChoice(String choice) {
    return 'Jouw keuze: $choice';
  }

  @override
  String get chemistryAnotherMoment => 'Nog een moment, wanneer je wilt';

  @override
  String get chemistryChooseMoment => 'Kies een moment';

  @override
  String get chemistryPromptSunday => 'Stel een zondag samen';

  @override
  String get chemistryPromptAdventure => 'Kies een avontuur';

  @override
  String get chemistryPromptFirstDate => 'Jouw soort eerste date';

  @override
  String get chemistryQuestionSunday => 'Jouw ideale zondag begint met…';

  @override
  String get chemistryQuestionAdventure => 'Een klein avontuur samen…';

  @override
  String get chemistryQuestionFirstDate =>
      'Voor een eerste hallo zou je kiezen voor…';

  @override
  String get engagementLevelFrozen =>
      'Je voortgang is gepauzeerd zolang er een veiligheidscontrole van je account loopt.';

  @override
  String get engagementLevelTrustGate =>
      'Verifieer je profiel en houd je account gezond om levels met vertrouwensdrempel te ontgrendelen.';

  @override
  String get engagementLevelPathTitle => 'Levelpad';

  @override
  String get engagementLevelPathSubtitle =>
      'XP komt uit zinvolle activiteit. Aankopen verhogen nooit je level.';

  @override
  String get engagementLevelRewardsTitle => 'Beloningen';

  @override
  String get engagementLevelRewardsSubtitle =>
      'Beloningen zijn cosmetisch, handig of geven beperkt extra zichtbaarheid.';

  @override
  String get engagementLevelRecentTitle => 'Recente XP';

  @override
  String get engagementLevelRecentSubtitle =>
      'Je activiteitenlogboek is permanent en controleerbaar.';

  @override
  String engagementLevelNumber(int level) {
    return 'Level $level';
  }

  @override
  String engagementLevelXp(String xp) {
    return '$xp XP';
  }

  @override
  String get engagementLevelHighest => 'Hoogste level bereikt';

  @override
  String engagementLevelProgress(int xp, String percent) {
    return '$xp XP in dit level · $percent%';
  }

  @override
  String engagementLevelThreshold(int xp, String summary) {
    return '$xp XP · $summary';
  }

  @override
  String get engagementLevelTrustGated => 'Vertrouwensdrempel';

  @override
  String get engagementLevelClaimed => 'Geclaimd';

  @override
  String get engagementLevelClaim => 'Claimen';

  @override
  String get engagementLevelLocked => 'Vergrendeld';

  @override
  String get engagementLevelStandardAward => 'Standaardtoekenning';

  @override
  String engagementLevelQualityWeighting(String multiplier) {
    return '$multiplier× kwaliteitsweging';
  }

  @override
  String get engagementLevelEmptyLedger =>
      'Rond zinvolle activiteiten af om je eerste XP te verdienen.';

  @override
  String get engagementXpSourceProfileCompleted => 'Profiel voltooid';

  @override
  String get engagementXpSourceDailyPromptSubmitted => 'Dagvraag beantwoord';

  @override
  String get engagementXpSourceMiniActivityCompleted =>
      'Mini-activiteit voltooid';

  @override
  String get engagementXpSourceCircleChallengeSubmitted =>
      'Kringuitdaging ingestuurd';

  @override
  String get engagementXpSourceVoiceIcebreakerPlayed =>
      'Spraak-ijsbreker afgespeeld';

  @override
  String get engagementXpSourceStreak3 => 'Reeks van 3 dagen';

  @override
  String get engagementXpSourceStreak7 => 'Reeks van 7 dagen';

  @override
  String get engagementXpSourceStreak14 => 'Reeks van 14 dagen';

  @override
  String get engagementXpSourceAdminAdjustment => 'Correctie door het team';

  @override
  String get engagementLevelSignIn => 'Log in om je levelvoortgang te zien.';

  @override
  String get engagementLevelLoadFailed =>
      'Je voortgang kan nu niet worden geladen.';

  @override
  String get engagementLevelClaimFailed =>
      'Deze beloning kan nu niet worden geclaimd.';

  @override
  String get engagementCoffeeTitle => 'Koffiepeilingen voor groepen';

  @override
  String get engagementCoffeeCreateHeading =>
      'Maak een eenvoudige koffiepeiling voor je groep';

  @override
  String get engagementCoffeeCreateHint =>
      'Voeg tot 3 gebruikers-ID’s van deelnemers toe (gescheiden door komma’s) en minstens één optie.';

  @override
  String get engagementCoffeeParticipantsLabel =>
      'Gebruikers-ID’s van deelnemers (gescheiden door komma’s)';

  @override
  String get engagementCoffeeDeadlineLabel => 'Deadline ISO (optioneel)';

  @override
  String engagementCoffeeOptionNumber(int number) {
    return 'Optie $number';
  }

  @override
  String get engagementCoffeeCreate => 'Peiling maken';

  @override
  String get engagementCoffeeActorLabel =>
      'Afwijkende gebruikers-ID voor acties (optioneel)';

  @override
  String get engagementCoffeeEmpty =>
      'Nog geen peilingen. Maak er hierboven een.';

  @override
  String engagementCoffeePollId(String id) {
    return 'Peiling $id';
  }

  @override
  String engagementCoffeeStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get engagementCoffeeStatusOpen => 'open';

  @override
  String get engagementCoffeeStatusFinalized => 'afgerond';

  @override
  String engagementCoffeeParticipants(String ids) {
    return 'Deelnemers: $ids';
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
      other: '$day · $time · $area ($count stemmen)',
      one: '$day · $time · $area (1 stem)',
    );
    return '$_temp0';
  }

  @override
  String get engagementCoffeeVote => 'Stemmen';

  @override
  String get engagementCoffeeFinalize => 'Peiling afronden';

  @override
  String get engagementCoffeeDayLabel => 'Dag';

  @override
  String get engagementCoffeeTimeLabel => 'Tijdvak';

  @override
  String get engagementCoffeeAreaLabel => 'Buurt';

  @override
  String get engagementCoffeeLoadFailed =>
      'De groepspeilingen kunnen nu niet worden geladen.';

  @override
  String get engagementCoffeeCreateFailed =>
      'De groepspeiling kan nu niet worden gemaakt.';

  @override
  String get engagementCoffeeVoteUserRequired =>
      'Er is een gebruikers-ID nodig om te stemmen.';

  @override
  String get engagementCoffeeVoteFailed => 'Stemmen kan nu niet.';

  @override
  String get engagementCoffeeFinalizeUserRequired =>
      'Er is een gebruikers-ID nodig om af te ronden.';

  @override
  String get engagementCoffeeFinalizeFailed =>
      'De peiling kan nu niet worden afgerond.';

  @override
  String get engagementDailyPromptUnavailable => 'Dagvraag niet beschikbaar';

  @override
  String get engagementDailyPromptPullToRefresh =>
      'Trek omlaag om te vernieuwen of probeer het zo nog eens.';

  @override
  String get engagementDailyPromptDomainValues => 'WAARDEN';

  @override
  String get engagementDailyPromptDomainLifestyle => 'LEVENSSTIJL';

  @override
  String get engagementDailyPromptDomainRelationshipStyle => 'RELATIESTIJL';

  @override
  String get engagementDailyPromptSparkTitle => 'Compatibiliteitsvonk';

  @override
  String engagementDailyPromptSparkSummary(int replied, int similar) {
    return 'Antwoorden vandaag: $replied · vergelijkbare antwoorden: $similar';
  }

  @override
  String get engagementDailyPromptYourAnswer => 'Jouw antwoord';

  @override
  String get engagementDailyPromptHint =>
      'Typ je antwoord in minder dan 60 seconden.';

  @override
  String engagementDailyPromptEditOpenUntil(String time) {
    return 'Bewerken kan tot $time';
  }

  @override
  String get engagementDailyPromptEditOpenSoon => 'Bewerken kan nog even';

  @override
  String get engagementDailyPromptEditClosed =>
      'Bewerken is voor vandaag gesloten.';

  @override
  String get engagementDailyPromptEdited => 'Bewerkt';

  @override
  String get engagementDailyPromptSubmit => 'Dagantwoord versturen';

  @override
  String get engagementDailyPromptUpdate => 'Antwoord bijwerken';

  @override
  String get engagementDailyPromptStreakProgress => 'Voortgang van je reeks';

  @override
  String engagementDailyPromptStatCurrent(String value) {
    return 'Huidig: $value';
  }

  @override
  String engagementDailyPromptStatBest(String value) {
    return 'Record: $value';
  }

  @override
  String engagementDailyPromptStatNext(String value) {
    return 'Volgende: $value';
  }

  @override
  String engagementDailyPromptDays(int days) {
    return '$days d';
  }

  @override
  String get engagementDailyPromptComplete => 'Voltooid';

  @override
  String engagementDailyPromptMilestone(int days) {
    return 'Mijlpaal ontgrendeld: reeks van $days dagen';
  }

  @override
  String get engagementDailyPromptLoadFailed =>
      'De dagvraag kan nu niet worden geladen.';

  @override
  String get engagementDailyPromptNotLoaded =>
      'De dagvraag is nog niet geladen.';

  @override
  String get engagementDailyPromptEnterAnswer => 'Vul eerst een antwoord in.';

  @override
  String get engagementDailyPromptSubmitFailed =>
      'Antwoord versturen is niet gelukt. Probeer het opnieuw.';

  @override
  String get clubsKindBooks => 'Boeken';

  @override
  String get clubsKindFilms => 'Films';

  @override
  String get clubsFilterAll => 'Alle';

  @override
  String get clubsAudiencePrivate => 'Alleen ik';

  @override
  String get clubsAudienceFriends => 'Vrienden';

  @override
  String get clubsAudienceCommunity => 'Connect-community';

  @override
  String get clubsRoleOwner => 'Eigenaar';

  @override
  String get clubsRoleModerator => 'Moderator';

  @override
  String get clubsRoleMember => 'Lid';

  @override
  String get clubsBadgeBookClub => 'Boekenclub';

  @override
  String get clubsBadgeFilmClub => 'Filmclub';

  @override
  String get clubsBadgeBookList => 'Boekenlijst';

  @override
  String get clubsBadgeFilmList => 'Filmlijst';

  @override
  String get clubsBadgeBook => 'Boek';

  @override
  String get clubsBadgeFilm => 'Film';

  @override
  String get clubsClub => 'Club';

  @override
  String clubsStarsOutOfFive(String rating) {
    return '$rating van 5 sterren';
  }

  @override
  String clubsStarCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sterren',
      one: '1 ster',
    );
    return '$_temp0';
  }

  @override
  String get clubsNoRatingsYet => 'Nog geen beoordelingen';

  @override
  String clubsRatingSummary(String average, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recensies',
      one: '1 recensie',
    );
    return '$average · $_temp0';
  }

  @override
  String get clubsWeekThis => 'Deze week';

  @override
  String get clubsWeekNext => 'Volgende week';

  @override
  String get clubsWeekLast => 'Vorige week';

  @override
  String clubsWeekOf(String date) {
    return 'Week van $date';
  }

  @override
  String get clubsTitle => 'Boeken- & filmclubs';

  @override
  String get clubsMyLists => 'Mijn lijsten';

  @override
  String get clubsStartClubTooltip => 'Begin een boeken- of filmclub';

  @override
  String get clubsStartClub => 'Club beginnen';

  @override
  String get clubsSignInToSee => 'Log in om clubs te zien.';

  @override
  String get clubsHeroTitle => 'Lees het. Kijk het. Praat erover.';

  @override
  String get clubsHeroSubtitle =>
      'Word lid van een club, volg elke week één keuze en deel wat je ervan vond. Goede smaak is een prima gespreksopener.';

  @override
  String get clubsScopeMine => 'Mijn clubs';

  @override
  String get clubsScopeDiscover => 'Ontdekken';

  @override
  String get clubsLoadErrorTitle => 'Clubs konden niet worden geladen';

  @override
  String get clubsCheckConnection => 'Controleer je verbinding.';

  @override
  String get clubsLookAroundTitle => 'Je kunt rondkijken';

  @override
  String get clubsLookAroundMessage =>
      'Vul je profiel aan met twee goedgekeurde foto’s om een club te beginnen of lid te worden.';

  @override
  String get clubsEmptyMineTitle => 'Je eerste club wacht op je';

  @override
  String get clubsEmptyMineMessage =>
      'Vind een club die leest of kijkt wat jij mooi vindt, of begin je eigen club.';

  @override
  String get clubsEmptyDiscoverTitle => 'Hier zijn nog geen clubs';

  @override
  String get clubsEmptyDiscoverMessage =>
      'Wees de eerste: begin een club en kies iets moois voor deze week.';

  @override
  String get clubsDiscoverClubs => 'Clubs ontdekken';

  @override
  String clubsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leden',
      one: '1 lid',
    );
    return '$_temp0';
  }

  @override
  String get clubsYouRunIt => 'Jij beheert hem';

  @override
  String get clubsYouModerate => 'Jij modereert';

  @override
  String get clubsJoined => 'Lid ✓';

  @override
  String get clubsNoPickThisWeek => 'Nog geen keuze deze week';

  @override
  String get clubsNameTooShort =>
      'Geef je club een naam van minstens 3 letters.';

  @override
  String get clubsCreateFailed => 'Je club kon niet worden aangemaakt.';

  @override
  String get clubsNameLabel => 'Clubnaam';

  @override
  String get clubsNameHint => 'Rustig lezen op zondag';

  @override
  String get clubsDescriptionLabel => 'Waar gaat je club over? (optioneel)';

  @override
  String get clubsCreating => 'Bezig met aanmaken…';

  @override
  String get clubsCreateClub => 'Club aanmaken';

  @override
  String clubsLeaveTitle(String name) {
    return '$name verlaten?';
  }

  @override
  String get clubsLeaveMessage =>
      'Je kunt later opnieuw lid worden zolang de club open is.';

  @override
  String get clubsLeaveClub => 'Club verlaten';

  @override
  String clubsWelcome(String name) {
    return 'Welkom bij $name!';
  }

  @override
  String get clubsChangeNotSaved => 'Die wijziging kon niet worden opgeslagen.';

  @override
  String get clubsOptionsTooltip => 'Clubopties';

  @override
  String get clubsMembers => 'Leden';

  @override
  String get clubsReportClub => 'Club melden';

  @override
  String get clubsDetailLoadErrorTitle => 'Deze club kon niet worden geladen';

  @override
  String get clubsDetailLoadErrorMessage =>
      'Misschien is hij gesloten. Probeer het opnieuw.';

  @override
  String get clubsEarlierPicks => 'Eerdere keuzes';

  @override
  String clubsPickSubtitle(String week, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count berichten',
      one: '1 bericht',
    );
    return '$week · $_temp0';
  }

  @override
  String get clubsOpenDiscussion => 'Discussie openen';

  @override
  String get clubsJoinToSeeTitle => 'Word lid om de discussie te zien';

  @override
  String get clubsJoinToSeeMessage =>
      'Leden praten samen over elke keuze. Word lid van de club om mee te lezen en je gedachten te delen.';

  @override
  String clubsYouRole(String role) {
    return 'Jij: $role';
  }

  @override
  String get clubsRemovedByModeration =>
      'Deze club is verwijderd door de moderatie.';

  @override
  String get clubsJoinClub => 'Lid worden';

  @override
  String get clubsNoPickModerator =>
      'Nog geen keuze. Kies iets moois voor iedereen.';

  @override
  String get clubsNoPickMember => 'Nog geen keuze. Kom snel terug.';

  @override
  String clubsQuotedNote(String note) {
    return '‘$note’';
  }

  @override
  String clubsPostsInDiscussion(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count berichten in de discussie',
      one: '1 bericht in de discussie',
    );
    return '$_temp0';
  }

  @override
  String get clubsSetThisWeeksPick => 'Keuze van deze week instellen';

  @override
  String get clubsDiscussThisPick => 'Over deze keuze praten';

  @override
  String get clubsPostNotSent => 'Je bericht kon niet worden verstuurd.';

  @override
  String clubsDiscussionHeading(String title) {
    return 'Discussie · $title';
  }

  @override
  String get clubsDiscussionLoadError => 'De discussie kon niet worden geladen';

  @override
  String get clubsStartConversationTitle => 'Begin het gesprek';

  @override
  String get clubsStartConversationMessage =>
      'Wat vind je er tot nu toe van? Jouw bericht kan iedereen aan het praten krijgen.';

  @override
  String get clubsLoadMorePosts => 'Meer berichten laden';

  @override
  String get clubsComposerLabel => 'Doe mee aan de discussie';

  @override
  String get clubsComposerHint => 'Favoriete moment? Grootste verrassing?';

  @override
  String get clubsContainsSpoilers => 'Bevat spoilers';

  @override
  String get clubsSpoilersSubtitle => 'Anderen tikken om het te tonen.';

  @override
  String get clubsPosting => 'Bezig met plaatsen…';

  @override
  String get clubsPost => 'Plaatsen';

  @override
  String get clubsDeletePostTitle => 'Je bericht verwijderen?';

  @override
  String get clubsDeletePostMessage =>
      'Het wordt voor iedereen uit de discussie verwijderd.';

  @override
  String get clubsActionFailed => 'Die actie kon niet worden voltooid.';

  @override
  String get clubsHideFromMembers => 'Verbergen voor leden';

  @override
  String get clubsShowToMembers => 'Tonen aan leden';

  @override
  String get clubsReport => 'Melden';

  @override
  String get clubsYou => 'Jij';

  @override
  String get clubsHidden => 'Verborgen';

  @override
  String get clubsPostActions => 'Berichtacties';

  @override
  String get clubsMakeModerator => 'Moderator maken';

  @override
  String get clubsMakeMember => 'Lid maken';

  @override
  String get clubsRemoveFromClub => 'Uit de club verwijderen';

  @override
  String clubsRemoveMemberTitle(String name) {
    return '$name verwijderen?';
  }

  @override
  String get clubsRemoveMemberMessage =>
      'Diegene verlaat de club en kan niet opnieuw lid worden. Eerdere berichten blijven in de discussie staan.';

  @override
  String get clubsRemove => 'Verwijderen';

  @override
  String get clubsMembersLoadError => 'Leden konden niet worden geladen.';

  @override
  String clubsMemberYou(String name) {
    return '$name (jij)';
  }

  @override
  String clubsMemberActions(String name) {
    return 'Acties voor $name';
  }

  @override
  String get clubsChooseFilm => 'Kies een film';

  @override
  String get clubsChooseBook => 'Kies een boek';

  @override
  String get clubsChooseTitle => 'Kies een titel';

  @override
  String get clubsChooseTitleFirst => 'Kies eerst een titel.';

  @override
  String get clubsPickNotSaved => 'De keuze kon niet worden opgeslagen.';

  @override
  String get clubsSetWeeklyPick => 'Weekkeuze instellen';

  @override
  String get clubsChange => 'Wijzigen';

  @override
  String get clubsPickNoteLabel => 'Een notitie voor de club (optioneel)';

  @override
  String get clubsPickNoteHint => 'Waarom deze? Waar begin je?';

  @override
  String get clubsSaving => 'Bezig met opslaan…';

  @override
  String get clubsSavePick => 'Keuze opslaan';

  @override
  String get clubsListNameRequired => 'Geef je lijst een naam.';

  @override
  String get clubsListNotSaved => 'Je lijst kon niet worden opgeslagen.';

  @override
  String get clubsEditList => 'Lijst bewerken';

  @override
  String get clubsNewList => 'Nieuwe lijst';

  @override
  String get clubsListNameLabel => 'Naam van de lijst';

  @override
  String get clubsListNameHint => 'Boeken die mijn kijk veranderden';

  @override
  String get clubsWhoCanSee => 'Wie het kan zien';

  @override
  String get clubsSave => 'Opslaan';

  @override
  String get clubsCreateList => 'Lijst aanmaken';

  @override
  String get clubsYourNote => 'Je notitie';

  @override
  String get clubsNoteLabel => 'Waarom het op deze lijst staat';

  @override
  String get clubsSaveNote => 'Notitie opslaan';

  @override
  String get clubsCreateNewListTooltip => 'Nieuwe lijst aanmaken';

  @override
  String get clubsSignInToSeeLists => 'Log in om je lijsten te zien.';

  @override
  String get clubsShelfTitle => 'Je plank';

  @override
  String get clubsShelfSubtitle =>
      'Houd bij waar je van genoot en wat er nog komt. Deel een lijst of houd hem voor jezelf.';

  @override
  String get clubsListsLoadErrorTitle =>
      'Je lijsten konden niet worden geladen';

  @override
  String get clubsFirstListTitle => 'Begin je eerste lijst';

  @override
  String get clubsFirstListMessage =>
      'Favoriete films, boeken voor straks, feelgoodfilms om opnieuw te kijken: jij bepaalt het.';

  @override
  String clubsAddToNamed(String name) {
    return 'Toevoegen aan $name';
  }

  @override
  String get clubsAddToThisListFailed =>
      'Het kon niet aan deze lijst worden toegevoegd.';

  @override
  String clubsDeleteListTitle(String name) {
    return '$name verwijderen?';
  }

  @override
  String get clubsDeleteListMessage =>
      'De lijst en de notities worden verwijderd. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get clubsDeleteList => 'Lijst verwijderen';

  @override
  String get clubsListDeleteFailed =>
      'De lijst kon niet worden verwijderd. Laad opnieuw en probeer het nog eens.';

  @override
  String get clubsNoteNotSaved => 'Je notitie kon niet worden opgeslagen.';

  @override
  String get clubsRemoveFailed => 'Het kon niet worden verwijderd.';

  @override
  String get clubsListOptions => 'Lijstopties';

  @override
  String get clubsAddATitle => 'Titel toevoegen';

  @override
  String clubsTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titels',
      one: '1 titel',
    );
    return '$_temp0';
  }

  @override
  String get clubsListEmpty =>
      'Nog niets hier. Gebruik ‘Titel toevoegen’ in het lijstmenu.';

  @override
  String clubsItemOptions(String title) {
    return 'Opties voor $title';
  }

  @override
  String get clubsAddNote => 'Notitie toevoegen';

  @override
  String get clubsEditNote => 'Notitie bewerken';

  @override
  String get clubsRemoveFromList => 'Van lijst verwijderen';

  @override
  String get clubsTapStarError => 'Tik op een ster om te beoordelen.';

  @override
  String get clubsReviewNotSaved => 'Je recensie kon niet worden opgeslagen.';

  @override
  String get clubsWriteReview => 'Recensie schrijven';

  @override
  String get clubsEditYourReview => 'Je recensie bewerken';

  @override
  String get clubsTapStarToRate => 'Tik op een ster om te beoordelen';

  @override
  String clubsRatingOutOfFive(int rating) {
    return '$rating van 5';
  }

  @override
  String get clubsReviewBodyLabel => 'Wat vond je ervan? (optioneel)';

  @override
  String get clubsSaveReview => 'Recensie opslaan';

  @override
  String clubsAddedToList(String name) {
    return 'Toegevoegd aan $name.';
  }

  @override
  String get clubsAddToThatListFailed =>
      'Het kon niet aan die lijst worden toegevoegd.';

  @override
  String get clubsAddToAList => 'Aan een lijst toevoegen';

  @override
  String get clubsListsLoadError => 'Je lijsten konden niet worden geladen.';

  @override
  String get clubsNoFilmLists =>
      'Je hebt nog geen filmlijsten. Maak er een om te beginnen met verzamelen.';

  @override
  String get clubsNoBookLists =>
      'Je hebt nog geen boekenlijsten. Maak er een om te beginnen met verzamelen.';

  @override
  String get clubsTitleFallback => 'Titel';

  @override
  String get clubsSignInToSeeReviews => 'Log in om recensies te zien.';

  @override
  String get clubsTitleLoadError => 'Deze titel kon niet worden geladen';

  @override
  String get clubsReviews => 'Recensies';

  @override
  String get clubsNoOtherReviewsTitle => 'Nog geen andere recensies';

  @override
  String get clubsNoOtherReviewsMessage =>
      'Als leden die je kunt zien een recensie delen, verschijnt die hier.';

  @override
  String get clubsDeleteReviewTitle => 'Je recensie verwijderen?';

  @override
  String get clubsDeleteReviewMessage =>
      'Je beoordeling en tekst worden voor iedereen verwijderd.';

  @override
  String get clubsDeleteReview => 'Recensie verwijderen';

  @override
  String get clubsReviewDeleteFailed =>
      'Je recensie kon niet worden verwijderd. Laad opnieuw en probeer het nog eens.';

  @override
  String get clubsWhatDidYouThink => 'Wat vond je ervan?';

  @override
  String get clubsReviewPrompt =>
      'Geef een beoordeling en zeg waarom. Jij kiest wie het ziet.';

  @override
  String get clubsYourReview => 'Je recensie';

  @override
  String get clubsSpoilers => 'Spoilers';

  @override
  String get clubsEdit => 'Bewerken';

  @override
  String get clubsReportReview => 'Deze recensie melden';

  @override
  String get clubsEnterTitle => 'Vul de titel in.';

  @override
  String get clubsYearRange => 'Vul een jaar tussen 1450 en 2100 in.';

  @override
  String get clubsTitleAddFailed => 'De titel kon niet worden toegevoegd.';

  @override
  String get clubsSearchFilms => 'Films zoeken';

  @override
  String get clubsSearchBooks => 'Boeken zoeken';

  @override
  String get clubsTypeTwoLetters => 'Typ minstens 2 letters';

  @override
  String get clubsSearchUnavailable => 'Zoeken is niet beschikbaar.';

  @override
  String get clubsNoFilmsMatch =>
      'Geen films gevonden. Voeg hem hieronder toe.';

  @override
  String get clubsNoBooksMatch =>
      'Geen boeken gevonden. Voeg het hieronder toe.';

  @override
  String get clubsAddNewFilm => 'Nieuwe film toevoegen';

  @override
  String get clubsAddNewBook => 'Nieuw boek toevoegen';

  @override
  String get clubsTitleFieldLabel => 'Titel';

  @override
  String get clubsDirector => 'Regie';

  @override
  String get clubsAuthor => 'Auteur';

  @override
  String get clubsYearOptional => 'Jaar (optioneel)';

  @override
  String get clubsAdding => 'Bezig met toevoegen…';

  @override
  String get clubsAddAndChoose => 'Toevoegen en kiezen';

  @override
  String get friendsIntroducerSaveFailed =>
      'We konden dat niet opslaan. Vernieuw om de nieuwste toestemmingen te bekijken voordat je het opnieuw probeert.';

  @override
  String friendsIntroducerRevokeTitle(String name) {
    return 'Toestemming voor $name intrekken?';
  }

  @override
  String get friendsIntroducerRevokeBody =>
      'Nieuwe en onbeantwoorde introducties stoppen. Een bestaande wederzijdse match blijft tussen die twee mensen.';

  @override
  String get friendsIntroducerKeepPermission => 'Toestemming behouden';

  @override
  String get friendsIntroducerRemovePermission => 'Toestemming intrekken';

  @override
  String get friendsIntroducerPermissionRemoved => 'Toestemming ingetrokken.';

  @override
  String get friendsIntroducerMemberTitle => 'Jouw koppelaars';

  @override
  String get friendsIntroducerAppTitle => 'Connect · Vrienden';

  @override
  String get friendsIntroducerRefresh => 'Toestemmingen vernieuwen';

  @override
  String get friendsIntroducerAccount => 'Account';

  @override
  String get friendsIntroducerAccountPrivacy => 'Account en privacy';

  @override
  String get friendsIntroducerSignOut => 'Uitloggen';

  @override
  String get friendsIntroducerMemberHeadline => 'Goede vrienden. Jij beslist.';

  @override
  String get friendsIntroducerHeadline =>
      'Jij kent ze.\nJij ziet de mogelijkheid.';

  @override
  String get friendsIntroducerMemberIntro =>
      'Nodig iemand die je vertrouwt uit om je voor te stellen. Die kan meedoen zonder datingprofiel. Jij bepaalt wie toestemming krijgt en wat een voorbeeld laat zien.';

  @override
  String get friendsIntroducerIntro =>
      'Een beetje aandacht kan iets echts laten beginnen. Breng vrienden samen die je om hulp hebben gevraagd.';

  @override
  String get friendsIntroducerMemberListTitle => 'Mensen die jij kiest';

  @override
  String get friendsIntroducerListTitle => 'Jouw kleine kring';

  @override
  String get friendsIntroducerLoadFailed =>
      'We konden de toestemmingen niet laden. Er is niets gewijzigd.';

  @override
  String get friendsIntroducerMemberEmpty =>
      'Nog geen koppelaars. Deel een uitnodiging met één vriend die je vertrouwt om te beginnen.';

  @override
  String get friendsIntroducerEmpty =>
      'Je kring begint met toestemming. Vraag een vriend op Connect om zijn of haar uitnodigingscode.';

  @override
  String get friendsIntroducerStatusPendingMember =>
      'Wil je toestemming om je voor te stellen.';

  @override
  String get friendsIntroducerStatusPending =>
      'Wacht op goedkeuring van je vriend.';

  @override
  String get friendsIntroducerStatusPaused => 'Introducties zijn gepauzeerd.';

  @override
  String get friendsIntroducerStatusActive => 'Mag introducties voorstellen.';

  @override
  String friendsIntroducerPreview(String extras) {
    String _temp0 = intl.Intl.selectLogic(extras, {
      'photo':
          'Voorbeeld voor een voorgestelde date: naam en optioneel leeftijd, foto.',
      'city':
          'Voorbeeld voor een voorgestelde date: naam en optioneel leeftijd, stad.',
      'both':
          'Voorbeeld voor een voorgestelde date: naam en optioneel leeftijd, foto, stad.',
      'other':
          'Voorbeeld voor een voorgestelde date: naam en optioneel leeftijd.',
    });
    return '$_temp0';
  }

  @override
  String get friendsIntroducerApproveNote =>
      'Goedkeuren zet ook introducties door vrienden aan. Je kunt alle introducties pauzeren in Datingritme.';

  @override
  String get friendsIntroducerAllow => 'Introducties toestaan';

  @override
  String friendsIntroducerAllowed(String name) {
    return '$name heeft nu je toestemming.';
  }

  @override
  String get friendsIntroducerDecline => 'Verzoek weigeren';

  @override
  String get friendsIntroducerSentTitle => 'Met zorg verstuurd';

  @override
  String get friendsIntroducerSentBody =>
      'Hun antwoorden blijven tussen hen. Allebei moeten ze ja zeggen voordat er een match is.';

  @override
  String get friendsIntroducerReloadSent =>
      'Verstuurde introducties opnieuw laden';

  @override
  String get friendsIntroducerSentSubtitle =>
      'Verstuurd · hun beslissing is privé';

  @override
  String get friendsIntroducerStepPreview => '1. Kies het voorbeeld';

  @override
  String get friendsIntroducerPreviewBody =>
      'Een voorgestelde date ziet je naam en leeftijd als je die al toont. Je koppelaar ziet alleen je naam, nooit je profiel of datingactiviteit.';

  @override
  String get friendsIntroducerIncludePhoto => 'Mijn profielfoto toevoegen';

  @override
  String get friendsIntroducerIncludeCity => 'Mijn stad toevoegen';

  @override
  String get friendsIntroducerStepInvite =>
      '2. Nodig één vriend uit die je vertrouwt';

  @override
  String get friendsIntroducerInviteBody =>
      'De code werkt één keer en verloopt na 48 uur. Je vriend doet mee via ‘Alleen hier om vrienden voor te stellen’ op het welkomstscherm. Je keurt hier eerst zijn of haar naam goed voordat er iets gedeeld wordt.';

  @override
  String get friendsIntroducerInviteReady =>
      'Uitnodiging klaar. Eerdere ongebruikte codes werken niet meer.';

  @override
  String get friendsIntroducerCreateCode => 'Uitnodigingscode maken';

  @override
  String get friendsIntroducerShareCode =>
      'Deel hem privé met je vriend. Om dit voorbeeld te wijzigen, annuleer je de ongebruikte uitnodiging en maak je een nieuwe code.';

  @override
  String get friendsIntroducerCodeCopied => 'Uitnodigingscode gekopieerd';

  @override
  String get friendsIntroducerCopyCode => 'Code kopiëren';

  @override
  String get friendsIntroducerInvitesCancelled =>
      'Ongebruikte uitnodigingen geannuleerd.';

  @override
  String get friendsIntroducerCancelInvites =>
      'Ongebruikte uitnodigingen annuleren';

  @override
  String get friendsIntroducerManagePrefs =>
      'Alle voorkeuren voor introducties beheren';

  @override
  String get friendsIntroducerRedeemTitle => 'Heeft een vriend je uitgenodigd?';

  @override
  String get friendsIntroducerRedeemBody =>
      'Plak de privé-uitnodigingscode. Je vriend bevestigt je naam voordat je hem of haar kunt voorstellen.';

  @override
  String get friendsIntroducerCodeLabel => 'Uitnodigingscode';

  @override
  String get friendsIntroducerCodeMissing =>
      'Vul de uitnodigingscode in die je vriend heeft gedeeld.';

  @override
  String get friendsIntroducerRequestSent =>
      'Verzoek verstuurd. Je vriend kan je nu goedkeuren bij ‘Jouw koppelaars’.';

  @override
  String get friendsIntroducerAskPermission => 'Toestemming vragen';

  @override
  String get friendsIntroducerNeedTwo =>
      'Zodra twee vrienden toestemming geven, kun je hier een introductie voorstellen.';

  @override
  String get friendsIntroducerComposerTitle => 'Zie je een kans?';

  @override
  String get friendsIntroducerWhyLabel => 'Waarom je aan hen dacht (optioneel)';

  @override
  String get friendsIntroducerWhyHelper =>
      'Ze zien dit allebei. Laat privédetails weg.';

  @override
  String get friendsIntroducerIntroSent =>
      'Introductie verstuurd. Ieder kan privé beslissen.';

  @override
  String get friendsIntroducerSuggest => 'Introductie voorstellen';

  @override
  String get friendsIntroducerPrivacyNote =>
      'Eerst toestemming. Geen openbare datingactiviteit. Geen updates over wie ja of nee zei.';

  @override
  String get planSharingLoadFailed => 'Kan de deelopties niet laden.';

  @override
  String get planSharingOffSnack => 'Delen met contacten staat uit.';

  @override
  String get planSharingSavedSnack =>
      'Je gekozen contacten kunnen dit plan nu zien.';

  @override
  String get planSharingSaveFailed =>
      'Opslaan is niet gelukt. Laad de keuzes opnieuw voordat je het nog eens probeert.';

  @override
  String get planSharingTitle => 'Jouw plan. Jouw mensen.';

  @override
  String get planSharingCloseTooltip => 'Delen sluiten';

  @override
  String get planSharingIntro =>
      'Delen met contacten staat eerst uit. Kies voor dit plan tot 10 vrienden die je vertrouwt. Je date kiest zelf eigen contacten.';

  @override
  String get planSharingNoContacts =>
      'Nog geen geschikte vrienden. Je plan blijft beschikbaar voor jou en je date.';

  @override
  String get planSharingFriendFallback => 'Een vriend';

  @override
  String get planSharingPreviewNone => 'Voorbeeld · geen contacten gekozen';

  @override
  String planSharingPreviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Voorbeeld · $count gekozen',
    );
    return '$_temp0';
  }

  @override
  String get planSharingPreviewOffBody =>
      'Je vrienden krijgen van jou geen updates over het plan of je check-ins.';

  @override
  String get planSharingPreviewOnBody =>
      'Deze contacten zien de naam van je date, de tijd en plek, de status van het plan en je check-ins. Ze krijgen het huidige plan zodra je opslaat.';

  @override
  String get planSharingPrivacyNote =>
      'Berichten en je privéfeedback na de date blijven privé. Als je een contact verwijdert, krijgt die geen updates meer en verliest die de toegang tot het plan in de app. Updates die al op een apparaat zijn aangekomen, kun je niet terughalen.';

  @override
  String get planSharingReload => 'Deelopties opnieuw laden';

  @override
  String get planSharingSaving => 'Opslaan…';

  @override
  String get planSharingKeepOff => 'Delen met contacten uit laten';

  @override
  String get planSharingShareSelected => 'Delen met gekozen contacten';

  @override
  String get planSharingDeselectAll => 'Iedereen deselecteren';

  @override
  String planBudgetLine(String budget) {
    return 'Budget · $budget';
  }

  @override
  String planAtmosphereLine(String atmospheres) {
    return 'Sfeer · $atmospheres';
  }

  @override
  String get planAtmosphereQuiet => 'Rustig gesprek';

  @override
  String get planAtmosphereRelaxed => 'Ontspannen & zonder haast';

  @override
  String get planAtmosphereLively => 'Een levendige plek';

  @override
  String get planAtmosphereOutdoors => 'Buiten';

  @override
  String get planAtmosphereIndoors => 'Binnen';

  @override
  String get planAccessStepFree => 'Drempelvrije toegang';

  @override
  String get planAccessToilet => 'Toegankelijk toilet';

  @override
  String get planAccessSeating => 'Zitplaatsen beschikbaar';

  @override
  String get planAccessLowNoise => 'Weinig achtergrondgeluid';

  @override
  String get planAccessTransit => 'Dicht bij het openbaar vervoer';

  @override
  String get planAccessCaptions => 'Ondertiteling bij een videodate';

  @override
  String get planComfortHeading => 'Om het comfortabel te maken';

  @override
  String get planPreferencesDisclaimer =>
      'Voorkeuren gedeeld voor dit plan. Check deze details bij de locatie of de videodienst.';

  @override
  String get planProposeErrorKept =>
      'Je plan kon niet worden verstuurd. Je keuzes staan er nog.';

  @override
  String get planChangedError =>
      'Dit plan is gewijzigd. Sluit dit venster om het gesprek te bekijken.';

  @override
  String get planProposeHeadline =>
      'Een plan waar jullie allebei naar uitkijken.';

  @override
  String get planCounterHeadline => 'Geef dit plan samen vorm';

  @override
  String planProposeLead(String name) {
    return 'Een voorstel voor jou en $name. Er staat pas iets vast als de ander deze versie accepteert.';
  }

  @override
  String get planFindTimeTitle => 'Vind samen even tijd';

  @override
  String get planFindTimeBody =>
      'Overlappende tijden zie je alleen als jullie allebei je beschikbaarheid delen. Je kunt altijd zelf een tijd voorstellen.';

  @override
  String get planSharedTimesFailed =>
      'Gedeelde tijden konden niet worden geladen. Je kunt nog steeds zelf een tijd kiezen.';

  @override
  String get planSharedTimesEmpty =>
      'Op dit moment geen gedeelde tijdsuggesties. Dat betekent niet dat een van jullie niet kan.';

  @override
  String get planRefreshSharedTimes => 'Gedeelde tijden vernieuwen';

  @override
  String get planSetAvailability => 'Mijn beschikbaarheid instellen';

  @override
  String get planWhenTitle => 'Wanneer komt het goed uit?';

  @override
  String get planTimeSourceManual => 'Een tijd die jij voorstelt';

  @override
  String get planTimeSourceShared =>
      'Gekozen uit gedeelde beschikbaarheid · wordt bij versturen opnieuw gecontroleerd';

  @override
  String planLocalTimeNote(int minutes, String timeZone) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Lokale tijd van je apparaat ($timeZone). Duur: $minutes minuten.',
      one: 'Lokale tijd van je apparaat ($timeZone). Duur: $minutes minuut.',
    );
    return '$_temp0';
  }

  @override
  String planDurationChip(int minutes) {
    return '$minutes min';
  }

  @override
  String get planEnjoyTitle => 'Iets wat je leuk zou vinden';

  @override
  String get planAreaHint => 'Een buurt of openbare ontmoetingsplek';

  @override
  String get planBudgetTitle => 'Welk budget voelt goed?';

  @override
  String get planBudgetBody =>
      'Een vertrekpunt om samen af te spreken, geen prijsopgave of belofte over wie betaalt.';

  @override
  String get planAtmosphereTitle => 'Bepaal de sfeer';

  @override
  String get planAtmosphereBody =>
      'Kies maximaal drie sferen die je leuk zou vinden. Optioneel.';

  @override
  String get planComfortTitle => 'Maak het comfortabel voor jullie allebei';

  @override
  String get planComfortBody =>
      'Optionele toegankelijkheidsvoorkeuren. Je keuzes worden met je match gedeeld als je dit plan verstuurt. Ze komen niet op je openbare profiel of in updates voor vertrouwde contacten.';

  @override
  String get planComfortDisclaimer =>
      'Je hoeft geen diagnose uit te leggen. Dit zijn wensen om na te vragen bij de locatie of videodienst, geen gecontroleerde voorzieningen.';

  @override
  String get planNoteHint => 'Zaterdagmiddag, ergens wat rustiger?';

  @override
  String get planReviewBeforeSending =>
      'Controleer voor het versturen de tijd en je keuzes hierboven. De ander kan accepteren, afwijzen of een wijziging voorstellen.';

  @override
  String get planReloadLatest => 'Laatste plan laden · wijzigingen verwerpen';

  @override
  String get planSending => 'Versturen…';

  @override
  String get planSendSuggestion => 'Je voorstel versturen';

  @override
  String get planSecondYesTitle => 'Een tweede ja delen';

  @override
  String get planSecondYesBody =>
      'Laat zien dat je elkaar opnieuw wilt zien, alleen als je match ook ja zegt en het wil delen. Je andere antwoorden blijven privé.';

  @override
  String get planSecondYesHeadline => 'Een tweede ja, van jullie allebei';

  @override
  String get planSecondYesCardBody =>
      'Jullie hebben allebei gedeeld dat je elkaar weer wilt zien.';

  @override
  String get planAnotherHello => 'Nog een ontmoeting plannen';

  @override
  String get planSuggestChange => 'Wijziging voorstellen';

  @override
  String get planChooseUpdates => 'Kies wie je updates krijgt';

  @override
  String planQuotedNote(String note) {
    return '“$note”';
  }

  @override
  String get planStatusDeclined => 'Afgewezen';

  @override
  String get planStatusExpired => 'Verlopen';

  @override
  String get planStatusCompleted => 'Afgerond';

  @override
  String get planStatusDidNotHappen => 'Niet doorgegaan';

  @override
  String get planStatusDisputed => 'Betwist';

  @override
  String get plansManageSharing => 'Delen met contacten beheren';

  @override
  String get plansLoadFailed => 'Kan de dateplannen niet laden.';

  @override
  String get plansFeedLoadFailed => 'Kan de plannen niet laden.';

  @override
  String get planAcceptFailed => 'Kan dit plan niet accepteren.';

  @override
  String get planDeclineFailed => 'Kan dit plan niet afwijzen.';

  @override
  String get planCancelFailed => 'Kan dit plan niet annuleren.';

  @override
  String get planCheckinFailed => 'Inchecken lukt nu niet.';

  @override
  String get graduationFoundEachOther => 'Jullie hebben elkaar gevonden';

  @override
  String graduationHeadlineDecide(String name) {
    return '$name wil samen met jou Connect verlaten';
  }

  @override
  String graduationHeadlineWaiting(String name) {
    return 'Wachten op $name';
  }

  @override
  String get graduationBodyConfirmed =>
      'Jullie zijn allebei verborgen in Ontdekken. Deze chat blijft open.';

  @override
  String get graduationBodyDecide =>
      'Bevestig en jullie verdwijnen allebei uit Ontdekken. Jullie chat blijft.';

  @override
  String get graduationBodyWaiting =>
      'Je hebt gevraagd om samen te vertrekken. De ander kan bevestigen of afwijzen.';

  @override
  String get graduationCelebrate => 'Vieren';

  @override
  String get graduationNotYet => 'Nog niet';

  @override
  String get graduationConfirm => 'Bevestigen';

  @override
  String get graduationFriendsToldOnConfirm =>
      'Je vrienden horen het zodra de ander bevestigt.';

  @override
  String get graduationOnlyTwoOfYouForNow =>
      'Voorlopig weten alleen jullie twee het.';

  @override
  String get graduationWithdraw => 'Intrekken';

  @override
  String graduationProposeTitle(String name) {
    return 'Connect verlaten met $name?';
  }

  @override
  String graduationProposeBody(String name) {
    return 'Zodra $name bevestigt, zijn jullie allebei verborgen in Ontdekken. Deze chat blijft open en je kunt altijd terug naar Ontdekken via Privacy en veiligheid.';
  }

  @override
  String get graduationNoteLabel => 'Een berichtje voor je match (optioneel)';

  @override
  String get graduationNoteHint => 'Vertel waarom je er klaar voor bent';

  @override
  String get graduationTellFriends => 'Mijn vrienden laten weten';

  @override
  String get graduationTellFriendsBody =>
      'Je geaccepteerde vrienden horen dat je iemand hebt gevonden, maar niet wie.';

  @override
  String get graduationAskThem => 'Vragen';

  @override
  String get graduationTitle => 'Samen verder';

  @override
  String graduationCelebrationBody(String name) {
    return 'Jij en $name verlaten Connect samen. Jullie zijn allebei verborgen in Ontdekken en deze chat blijft open zo lang je wilt.';
  }

  @override
  String get graduationFriendsHaveBeenTold =>
      'Je vrienden zijn op de hoogte gebracht.';

  @override
  String get graduationFriendsAreTold => 'Je vrienden worden ingelicht.';

  @override
  String get graduationOnlyTwoOfYou => 'Alleen jullie twee weten het.';

  @override
  String get graduationConfirmAndBack => 'Bevestigen en teruggaan';

  @override
  String get graduationBackToConnect => 'Terug naar Connect';

  @override
  String get graduationLoadFailed => 'Kan Samen verder niet laden.';

  @override
  String get graduationProposeFailed =>
      'Kan niet voorstellen om samen te vertrekken.';

  @override
  String get graduationConfirmFailed => 'Bevestigen lukt nu niet.';

  @override
  String get graduationDeclineFailed => 'Afwijzen lukt nu niet.';

  @override
  String get graduationWithdrawFailed => 'Kan het voorstel niet intrekken.';

  @override
  String get graduationPauseLoadFailed =>
      'Kan je status in Ontdekken niet laden.';

  @override
  String get graduationPauseFailed => 'Kan Ontdekken niet pauzeren.';

  @override
  String get graduationResumeFailed => 'Kan Ontdekken niet hervatten.';

  @override
  String get engagementCirclesEmptyTitle => 'Geen kringen beschikbaar';

  @override
  String get engagementCirclesPullToRefresh => 'Trek omlaag om te vernieuwen.';

  @override
  String get engagementCirclesJoined => 'Lid';

  @override
  String get engagementCirclesNotJoined => 'Geen lid';

  @override
  String engagementCirclesParticipants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count deelnemers deze week',
      one: '1 deelnemer deze week',
    );
    return '$_temp0';
  }

  @override
  String get engagementCirclesJoin => 'Lid worden';

  @override
  String get engagementCirclesResponseLabel =>
      'Je antwoord op de weekuitdaging';

  @override
  String get engagementCirclesSubmit => 'Bijdrage insturen';

  @override
  String get engagementCirclesTopicFallback => 'Kring';

  @override
  String get engagementCirclesLoadFailed =>
      'De kringen kunnen nu niet worden geladen.';

  @override
  String get engagementCirclesJoinFailed =>
      'Lid worden van de kring lukt nu niet.';

  @override
  String get engagementCirclesEnterResponse =>
      'Vul je antwoord op de uitdaging in.';

  @override
  String get engagementCirclesSubmitFailed =>
      'Je bijdrage kan nu niet worden ingestuurd.';

  @override
  String get engagementNudgesTitle => 'Match-duwtjes';

  @override
  String get engagementNudgesIntro =>
      'Stuur een vriendelijke herinnering om een stil gesprek weer op gang te brengen. Daglimieten en veiligheidsregels worden door de server gehandhaafd.';

  @override
  String get engagementNudgesEmpty => 'Geen matches om een duwtje te geven.';

  @override
  String get engagementNudgesSentInSession => 'Duwtje verstuurd in deze sessie';

  @override
  String get engagementNudgesReady => 'Klaar om te versturen';

  @override
  String engagementNudgesSentTo(String name) {
    return 'Duwtje verstuurd naar $name.';
  }

  @override
  String get engagementNudgesAction => 'Duwtje';

  @override
  String get engagementNudgesSendFailed =>
      'Dit duwtje kon niet worden verstuurd.';

  @override
  String get engagementTrustBadgesEarned => 'Verdiende badges';

  @override
  String get engagementTrustBadgesEmpty =>
      'Nog geen badges. Rond activiteiten af om vertrouwensbadges te ontgrendelen.';

  @override
  String engagementTrustBadgesDetails(
    String code,
    String status,
    String awardedAt,
  ) {
    return 'Code: $code\nStatus: $status • Toegekend $awardedAt';
  }

  @override
  String get engagementTrustBadgesHistory => 'Recente geschiedenis';

  @override
  String get engagementTrustBadgesHistoryEmpty =>
      'Nog geen vertrouwensgeschiedenis.';

  @override
  String get engagementTrustBadgesMilestoneUnavailable =>
      'Status van de mijlpaal niet beschikbaar.';

  @override
  String get engagementTrustBadgesCurrentMilestone => 'Huidige mijlpaal';

  @override
  String get engagementTrustBadgesLoadFailed =>
      'Vertrouwensbadges laden is niet gelukt. Probeer het opnieuw.';

  @override
  String get engagementTrustFiltersEnable => 'Vertrouwensfilters inschakelen';

  @override
  String get engagementTrustFiltersEnableSubtitle =>
      'Profielen verbergen die niet aan je vertrouwenseisen voldoen';

  @override
  String engagementTrustFiltersMinimum(int count) {
    return 'Minimumaantal actieve badges: $count';
  }

  @override
  String get engagementTrustFiltersRequired => 'Vereiste badges';

  @override
  String get engagementTrustFiltersSaved => 'Vertrouwensfilters opgeslagen.';

  @override
  String get engagementTrustFiltersSave => 'Vertrouwensfilters opslaan';

  @override
  String get engagementAppealStatusSubmitted => 'Ingediend';

  @override
  String get engagementAppealStatusUnderReview => 'In behandeling';

  @override
  String get engagementAppealStatusResolvedUpheld =>
      'Afgehandeld (gehandhaafd)';

  @override
  String get engagementAppealStatusResolvedReversed =>
      'Afgehandeld (teruggedraaid)';

  @override
  String get engagementRoomsLeaveFailed =>
      'Deze ruimte verlaten is niet gelukt. Probeer het opnieuw.';

  @override
  String get engagementRoomsPresenceFailed =>
      'Verbinding met de ruimte verloren.';

  @override
  String get engagementRoomsMembersFailed =>
      'Kon niet laden wie er is. Probeer het opnieuw.';

  @override
  String get engagementRoomsModerationFailed =>
      'Dat is niet gelukt. Probeer het opnieuw.';

  @override
  String get engagementRoomsCreateFailed =>
      'De ruimte kon niet worden gestart. Probeer het opnieuw.';

  @override
  String get engagementRoomsLoadFailed =>
      'Ruimtes zijn nu niet beschikbaar. Trek omlaag om het opnieuw te proberen.';

  @override
  String get commonSave => 'Opslaan';

  @override
  String get commonRemove => 'Verwijderen';

  @override
  String get accountTitle => 'Account & gegevens';

  @override
  String get accountLoadFailed => 'Je accountstatus kon niet worden geladen.';

  @override
  String accountDeletionIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Verwijdering over $days dagen',
      one: 'Verwijdering over 1 dag',
    );
    return '$_temp0';
  }

  @override
  String get accountDeletionDue => 'Verwijdering staat gepland voor nu';

  @override
  String get accountDeletionCountdownBody =>
      'Je profiel is verborgen. Tot die tijd kun je nog inloggen en annuleren — daarna zijn je gegevens niet meer te herstellen.';

  @override
  String get accountKeepMyAccount => 'Mijn account houden';

  @override
  String get accountNotDeletedSnack => 'Je account wordt niet verwijderd.';

  @override
  String get accountCancelFailed =>
      'Annuleren is mislukt. Probeer het opnieuw.';

  @override
  String get accountHiddenTitle => 'Je profiel is verborgen';

  @override
  String get accountTakeBreakTitle => 'Neem een pauze';

  @override
  String get accountHiddenBody =>
      'Niemand kan je zien of met je matchen. Je matches en berichten blijven bewaard en je kunt terugkomen wanneer je wilt.';

  @override
  String get accountTakeBreakBody =>
      'Verberg je profiel in Ontdekken zonder iets te verliezen. Je blijft ingelogd en kunt altijd terugschakelen.';

  @override
  String get accountUnhideProfile => 'Mijn profiel weer tonen';

  @override
  String get accountHideProfile => 'Mijn profiel verbergen';

  @override
  String get accountVisibleAgainSnack => 'Je profiel is weer zichtbaar.';

  @override
  String get accountNowHiddenSnack => 'Je profiel is nu verborgen.';

  @override
  String get accountUpdateFailed =>
      'Bijwerken is mislukt. Probeer het opnieuw.';

  @override
  String get accountDownloadTitle => 'Je gegevens downloaden';

  @override
  String get accountDownloadBody =>
      'Ontvang een kopie van je profiel, voorkeuren, matches en de berichten die je hebt verstuurd. Berichten van anderen zitten er niet bij.';

  @override
  String get accountPreparing => 'Bezig met voorbereiden…';

  @override
  String get accountPrepareData => 'Mijn gegevens klaarzetten';

  @override
  String get accountPrepareFailed =>
      'Je gegevens konden niet worden klaargezet. Probeer het opnieuw.';

  @override
  String get accountYourData => 'Je gegevens';

  @override
  String get accountDeleteTitle => 'Mijn account verwijderen';

  @override
  String get accountDeleteBody =>
      'Je profiel wordt meteen verborgen en na een bedenktijd wordt alles gewist. In die tijd kun je annuleren door in te loggen. Daarna is niets meer te herstellen.';

  @override
  String get accountDeletionAlreadyScheduled => 'Verwijdering al gepland';

  @override
  String get accountDeleteConfirmTitle => 'Je account verwijderen?';

  @override
  String get accountDeleteConfirmBody =>
      'Je profiel, foto’s, matches en berichten worden gewist en zijn niet te herstellen.\n\nWil je alleen een pauze? Als je je profiel verbergt, blijft alles bewaard en kun je het terugdraaien.';

  @override
  String get accountHideInstead => 'Liever verbergen';

  @override
  String get accountDeletionScheduledSnack =>
      'Verwijdering gepland. Tot die tijd kun je annuleren.';

  @override
  String get privacyTitle => 'Privacy & veiligheid';

  @override
  String get privacyShowAge => 'Leeftijd tonen';

  @override
  String get privacyShowAgeSubtitle => 'Bepaal of je leeftijd zichtbaar is';

  @override
  String get privacyShowDistance => 'Exacte afstand tonen';

  @override
  String get privacyShowDistanceSubtitle =>
      'Toon de precieze afstand op je profiel';

  @override
  String get privacyShowOnline => 'Onlinestatus tonen';

  @override
  String get privacyShowOnlineSubtitle =>
      'Anderen laten zien of je online bent';

  @override
  String get privacyEmergencySos => 'Nood-SOS';

  @override
  String get privacyEmergencySosSubtitle =>
      'Een alarm activeren en de alarmgeschiedenis bekijken';

  @override
  String get privacyEmergencyContacts => 'Noodcontacten';

  @override
  String get privacyEmergencyContactsSubtitle =>
      'Vertrouwde noodcontacten beheren';

  @override
  String get privacyBlockedUsers => 'Geblokkeerde gebruikers';

  @override
  String get privacyBlockedUsersSubtitle =>
      'Gebruikers bekijken en deblokkeren';

  @override
  String get privacyModerationAppeals => 'Bezwaren tegen moderatie';

  @override
  String get privacyModerationAppealsSubtitle =>
      'Dien bezwaar in en volg de beoordeling';

  @override
  String get privacyFriendSearch =>
      'Mensen laten me vinden via vrienden zoeken';

  @override
  String get privacySettingLoadFailed =>
      'Deze instelling kon niet worden geladen. Open deze pagina opnieuw om het nog eens te proberen.';

  @override
  String get privacyFriendSearchSubtitle =>
      'Leden kunnen je vinden op naam of @gebruikersnaam via Vriend toevoegen. Mensen met wie je matcht of die je in ruimtes en groepen ontmoet, kunnen je nog steeds toevoegen.';

  @override
  String get privacyChoiceSaveFailed => 'Je keuze kon niet worden opgeslagen.';

  @override
  String get privacyShowcase => 'Mijn openbare teksten op mijn profiel tonen';

  @override
  String get privacyShowcaseSubtitle =>
      'Leden zien op je profiel de hoofdstukken die je met de community deelt en je foto’s op de muur. Privéhoofdstukken en hoofdstukken alleen voor vrienden verschijnen nooit.';

  @override
  String get privacyCrashReports => 'Crashrapporten delen';

  @override
  String get privacyCrashReportsSubtitle =>
      'Anonieme crash- en foutrapporten helpen ons problemen op te lossen. Er zitten geen berichten, foto’s of accountgegevens in.';

  @override
  String get privacyGraduatedReason =>
      'Je hebt Connect verlaten met je match. Je kaart wordt aan niemand getoond.';

  @override
  String get privacyPausedReason =>
      'Je kaart wordt aan niemand getoond tot je hervat.';

  @override
  String get privacyActiveReason =>
      'Je wordt aan andere leden getoond in Ontdekken.';

  @override
  String get privacyDiscoveryPaused => 'Ontdekken gepauzeerd';

  @override
  String get privacyDiscoveryActive => 'Ontdekken actief';

  @override
  String get privacyResume => 'Hervatten';

  @override
  String get privacyPause => 'Pauzeren';

  @override
  String get emergencyIntro =>
      'Voeg maximaal 3 vertrouwde contacten toe. Ze worden later gebruikt voor veiligheidsprocessen en SOS-functies.';

  @override
  String get emergencyEmpty => 'Nog geen noodcontacten toegevoegd.';

  @override
  String get emergencyMaxReached => 'Maximaal aantal contacten bereikt';

  @override
  String get emergencyAddContact => 'Contact toevoegen';

  @override
  String get emergencyEditContact => 'Contact bewerken';

  @override
  String get emergencyInvalidInput =>
      'Voer een geldige naam en telefoonnummer in.';

  @override
  String get emergencyAdded => 'Noodcontact toegevoegd.';

  @override
  String get emergencyAddFailed =>
      'Contact toevoegen mislukt. Probeer het opnieuw.';

  @override
  String get emergencyUpdated => 'Noodcontact bijgewerkt.';

  @override
  String get emergencyUpdateFailed =>
      'Contact bijwerken mislukt. Probeer het opnieuw.';

  @override
  String get emergencyRemoveTitle => 'Contact verwijderen';

  @override
  String emergencyRemoveBody(String name) {
    return '$name verwijderen uit je noodcontacten?';
  }

  @override
  String get emergencyRemoved => 'Noodcontact verwijderd.';

  @override
  String get emergencyRemoveFailed =>
      'Contact verwijderen mislukt. Probeer het opnieuw.';

  @override
  String get emergencyNameLabel => 'Naam';

  @override
  String get emergencyPhoneLabel => 'Telefoonnummer';

  @override
  String get appealsSubmitTitle => 'Bezwaar indienen';

  @override
  String get appealsReasonLabel => 'Reden';

  @override
  String get appealsReasonHint =>
      'Waarom moet deze moderatiebeslissing worden herzien?';

  @override
  String get appealsReportIdLabel => 'Meldings-ID (optioneel)';

  @override
  String get appealsContextLabel => 'Extra context (optioneel)';

  @override
  String get appealsSubmit => 'Bezwaar versturen';

  @override
  String get appealsEmpty =>
      'Nog geen bezwaren ingediend. Je bezwaren verschijnen hier met statusupdates.';

  @override
  String appealsIdLine(String id) {
    return 'Bezwaar-ID: $id';
  }

  @override
  String appealsSlaLine(String deadline) {
    return 'Uiterste beoordelingsdatum: $deadline';
  }

  @override
  String appealsReviewedBy(String reviewer) {
    return 'Beoordeeld door: $reviewer';
  }

  @override
  String get appealsReasonRequired => 'Een reden is verplicht.';

  @override
  String get appealsSubmitted => 'Bezwaar verstuurd.';

  @override
  String get appealsSubmitFailed =>
      'Bezwaar versturen mislukt. Probeer het opnieuw.';

  @override
  String get blockedEmpty => 'Je hebt niemand geblokkeerd.';

  @override
  String get blockedUnblock => 'Deblokkeren';

  @override
  String get blockedUnblockTitle => 'Gebruiker deblokkeren';

  @override
  String blockedUnblockBody(String name) {
    return '$name deblokkeren?';
  }

  @override
  String blockedUnblockedSnack(String name) {
    return '$name is gedeblokkeerd.';
  }

  @override
  String get blockedUnblockFailed =>
      'Deblokkeren mislukt. Probeer het opnieuw.';

  @override
  String aboutVersion(String version) {
    return 'Versie $version';
  }

  @override
  String get aboutDescription =>
      'Datingapp die draait om vertrouwen: echte profielen, veilige communicatie en serieuze relaties.';

  @override
  String get aboutStack => 'Techniek';

  @override
  String get aboutStackFlutter => 'Flutter (Android eerst)';

  @override
  String get aboutStackGo => 'Go-services + native PostgreSQL';

  @override
  String get aboutStackRiverpod => 'Riverpod voor state management';

  @override
  String get communitySpoiler => 'Spoiler — tik om te tonen';

  @override
  String get communityReportFailed => 'De melding kon niet worden verstuurd.';

  @override
  String get communityReportSubmitted => 'Melding verstuurd. Bedankt.';

  @override
  String communityBlockTitle(String name) {
    return '$name blokkeren?';
  }

  @override
  String get communityBlockBody =>
      'Jullie zien elkaars foto’s, clubberichten, reviews en lijsten niet meer. Dit blokkeert ook contact via Connect.';

  @override
  String get communityBlockAction => 'Lid blokkeren';

  @override
  String get communityBlockFailed =>
      'Kon dit lid niet blokkeren. Probeer het opnieuw.';

  @override
  String get reportSheetTitle => 'Melden';

  @override
  String get reportReasonHarassment => 'Intimidatie';

  @override
  String get reportReasonInappropriate => 'Ongepaste inhoud';

  @override
  String get reportReasonFraud => 'Fraude / oplichting';

  @override
  String get reportReasonFake => 'Nepprofiel';

  @override
  String get reportReasonLabel => 'Reden';

  @override
  String get reportDescriptionLabel => 'Beschrijving (optioneel)';

  @override
  String get reportDescriptionHint =>
      'Voeg context toe zodat we je melding kunnen beoordelen';

  @override
  String get reportSubmitFailed =>
      'Melding versturen mislukt. Probeer het opnieuw.';

  @override
  String get reportSubmit => 'Melding versturen';

  @override
  String get membershipTitle => 'Lidmaatschap';

  @override
  String get membershipChooseYourPlan => 'Kies je abonnement';

  @override
  String get membershipCycleNoteMonthly =>
      'Betaal met je kaart. Wordt elke maand automatisch verlengd tot je dit uitzet.';

  @override
  String get membershipCycleNoteYearly =>
      'Betaal met je kaart. Wordt elk jaar automatisch verlengd tot je dit uitzet.';

  @override
  String get membershipNoPlansOnSale =>
      'Er zijn op dit moment geen abonnementen te koop.';

  @override
  String get membershipPaymentsTitle => 'Betalingen';

  @override
  String get membershipNoCardPayments => 'Nog geen kaartbetalingen.';

  @override
  String get membershipFooterNote =>
      'Je abonnement wordt aan het einde van elke factuurperiode automatisch verlengd. Je kunt automatische verlenging altijd uitzetten; je voordelen blijven tot het einde van de periode. Kaartgegevens worden door de betaalprovider verwerkt en nooit in de app opgeslagen.';

  @override
  String membershipSwitchTitle(String plan) {
    return 'Overstappen naar $plan?';
  }

  @override
  String membershipSwitchUpgradeBodyMonthly(String price) {
    return 'Je kaart wordt nu belast voor het verschil over de rest van deze periode, daarna $price per maand vanaf de volgende verlenging.';
  }

  @override
  String membershipSwitchUpgradeBodyYearly(String price) {
    return 'Je kaart wordt nu belast voor het verschil over de rest van deze periode, daarna $price per jaar vanaf de volgende verlenging.';
  }

  @override
  String membershipSwitchDowngradeBodyMonthly(
    String currentPlan,
    String price,
  ) {
    return 'Je abonnement verandert nu. Ongebruikte tijd van $currentPlan wordt verrekend met je volgende verlenging, daarna betaal je $price per maand.';
  }

  @override
  String membershipSwitchDowngradeBodyYearly(String currentPlan, String price) {
    return 'Je abonnement verandert nu. Ongebruikte tijd van $currentPlan wordt verrekend met je volgende verlenging, daarna betaal je $price per jaar.';
  }

  @override
  String get membershipNotNow => 'Niet nu';

  @override
  String get membershipUpgrade => 'Upgraden';

  @override
  String get membershipSwitchPlan => 'Abonnement wijzigen';

  @override
  String membershipSwitchedSnack(String plan) {
    return 'Je hebt nu $plan.';
  }

  @override
  String get membershipCardUpdated => 'Je kaart is bijgewerkt.';

  @override
  String get membershipCardUpdatePending =>
      'Kaartupdate nog niet bevestigd. Controleer de status voordat je het opnieuw probeert.';

  @override
  String get membershipCardUpdateEnded =>
      'Deze sessie voor je kaartupdate is beëindigd. Vernieuw om je huidige kaart te zien.';

  @override
  String get membershipCheckoutTitleCard => 'je kaart';

  @override
  String get membershipAutoRenewOffTitle =>
      'Automatische verlenging uitzetten?';

  @override
  String membershipAutoRenewOffBodyDate(String plan, String date) {
    return 'Je $plan-voordelen blijven actief tot $date. Daarna ga je over naar het gratis abonnement en wordt je kaart niet meer belast.';
  }

  @override
  String membershipAutoRenewOffBodyPeriodEnd(String plan) {
    return 'Je $plan-voordelen blijven actief tot het einde van de huidige periode. Daarna ga je over naar het gratis abonnement en wordt je kaart niet meer belast.';
  }

  @override
  String get membershipKeepRenewing => 'Blijven verlengen';

  @override
  String get membershipTurnOff => 'Uitzetten';

  @override
  String get membershipAutoRenewBackOn =>
      'Automatische verlenging staat weer aan.';

  @override
  String get membershipAutoRenewNowOff =>
      'Automatische verlenging staat uit. Je voordelen blijven tot het einde van de periode.';

  @override
  String membershipSubscribeTitle(String plan) {
    return 'Abonneren op $plan';
  }

  @override
  String membershipSubscribeBodyMonthly(String price) {
    return '$price per maand, afgeschreven van je kaart en automatisch verlengd tot je automatische verlenging uitzet. Je voert je kaart in op de beveiligde pagina van de betaalprovider.';
  }

  @override
  String membershipSubscribeBodyYearly(String price) {
    return '$price per jaar, afgeschreven van je kaart en automatisch verlengd tot je automatische verlenging uitzet. Je voert je kaart in op de beveiligde pagina van de betaalprovider.';
  }

  @override
  String membershipSubscribeBodyTestMonthly(String price) {
    return 'Alleen testbetaling — er wordt niets echt afgeschreven. $price per maand, gesimuleerd en automatisch verlengd tot je automatische verlenging uitzet. Je voert je kaart in op de beveiligde pagina van de betaalprovider.';
  }

  @override
  String membershipSubscribeBodyTestYearly(String price) {
    return 'Alleen testbetaling — er wordt niets echt afgeschreven. $price per jaar, gesimuleerd en automatisch verlengd tot je automatische verlenging uitzet. Je voert je kaart in op de beveiligde pagina van de betaalprovider.';
  }

  @override
  String get membershipContinueToCard => 'Verder naar kaart';

  @override
  String get paymentStillConfirming =>
      'De betaling wordt nog bevestigd. Trek zo naar beneden om te vernieuwen.';

  @override
  String get membershipCheckoutEnded =>
      'Deze betaalsessie is beëindigd. Vernieuw je betaalgeschiedenis voordat je het opnieuw probeert.';

  @override
  String get membershipRecoverAccountUnavailable =>
      'Kan de betaalaccount niet controleren. Probeer het opnieuw.';

  @override
  String get membershipRecoverCheckoutClosed =>
      'Betaalaccount vernieuwd. Deze betaling staat niet meer open.';

  @override
  String get membershipRecoverConfirmed =>
      'Bevestigd. Je betaalaccount is bijgewerkt.';

  @override
  String get membershipRecoverPending =>
      'De bevestiging is nog in behandeling. Je kunt hier opnieuw controleren.';

  @override
  String get membershipRecoverEnded =>
      'Deze betaalsessie is beëindigd. Bekijk je betaalgeschiedenis voordat je een nieuwe start.';

  @override
  String membershipCelebrateTitle(String plan) {
    return 'Je bent nu $plan';
  }

  @override
  String get membershipCelebrateBodyTest =>
      'Testbetaling bevestigd; er is geen echt geld afgeschreven. Je testabonnement wordt automatisch verlengd. Beheer automatische verlenging altijd via dit scherm.';

  @override
  String get membershipCelebrateBody =>
      'Betaling bevestigd. Je abonnement wordt automatisch verlengd. Beheer automatische verlenging altijd via dit scherm.';

  @override
  String get membershipStartExploring => 'Begin met ontdekken';

  @override
  String get membershipYourMembership => 'Je lidmaatschap';

  @override
  String get membershipYourPlan => 'Je abonnement';

  @override
  String get membershipFreePlanName => 'Gratis';

  @override
  String membershipPricePerMonthShort(String price) {
    return '$price/mnd';
  }

  @override
  String membershipPricePerYearShort(String price) {
    return '$price/jaar';
  }

  @override
  String get membershipCardOnFile => 'Kaart opgeslagen bij de betaalprovider';

  @override
  String get membershipCardBrandFallback => 'Kaart';

  @override
  String get paymentOpening => 'Openen…';

  @override
  String get membershipUpdateCard => 'Kaart wijzigen';

  @override
  String get membershipLastPaymentFailed =>
      'De laatste betaling is mislukt. We proberen je kaart opnieuw; je voordelen blijven nog een paar dagen actief.';

  @override
  String membershipRenewsOn(String date) {
    return 'Wordt verlengd op $date';
  }

  @override
  String get membershipRenewsSoon => 'Wordt binnenkort verlengd';

  @override
  String membershipEndsOn(String date) {
    return 'Eindigt op $date · automatische verlenging uit';
  }

  @override
  String get membershipEndsSoon =>
      'Eindigt binnenkort · automatische verlenging uit';

  @override
  String get membershipAutoRenew => 'Automatisch verlengen';

  @override
  String get membershipAutoRenewOnSubtitle =>
      'Wordt elke periode automatisch afgeschreven.';

  @override
  String get membershipAutoRenewOffSubtitle =>
      'Uit. Voordelen eindigen met de huidige periode.';

  @override
  String get membershipFreeHeroBody =>
      'Ontgrendel meer likes, berichten en uitgelichte plekken met een abonnement hieronder. Betaal met je kaart, altijd opzegbaar.';

  @override
  String get membershipStatusFree => 'Gratis';

  @override
  String get membershipStatusPaymentDue => 'Betaling vereist';

  @override
  String get membershipStatusEnding => 'Loopt af';

  @override
  String get membershipStatusActive => 'Actief';

  @override
  String get membershipCycleMonthly => 'Maandelijks';

  @override
  String get membershipCycleYearly => 'Jaarlijks';

  @override
  String get membershipBadgeYourPlan => 'JOUW ABONNEMENT';

  @override
  String get membershipBadgeMostPopular => 'MEEST GEKOZEN';

  @override
  String get membershipPerMonth => 'per maand';

  @override
  String get membershipPerYear => 'per jaar';

  @override
  String membershipSavePercent(int percent) {
    return 'Bespaar $percent%';
  }

  @override
  String membershipQuotaLikesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes/dag',
      one: '1 like/dag',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count berichten/dag',
      one: '1 bericht/dag',
    );
    return '$_temp0';
  }

  @override
  String get membershipQuotaUnlimitedLikes => 'Onbeperkt likes';

  @override
  String get membershipQuotaUnlimitedMessages => 'Onbeperkt berichten';

  @override
  String get membershipYourCurrentPlan => 'Je huidige abonnement';

  @override
  String get membershipSwitching => 'Overstappen…';

  @override
  String get membershipOpeningSecureCheckout => 'Beveiligde betaling openen…';

  @override
  String membershipSwitchToPlan(String plan) {
    return 'Overstappen naar $plan';
  }

  @override
  String get membershipSubscribeWithCard => 'Abonneren met kaart';

  @override
  String get membershipSettleBeforeSwitch =>
      'Betaal eerst de openstaande betaling van je huidige abonnement voordat je overstapt.';

  @override
  String get membershipPaymentChargeback => 'Terugboeking';

  @override
  String get membershipPaymentDisputed => 'Betwist';

  @override
  String get membershipPaymentRefunded => 'Terugbetaald';

  @override
  String get membershipPaymentPartlyRefunded => 'Deels terugbetaald';

  @override
  String get membershipPaymentFailed => 'Mislukt';

  @override
  String get membershipPaymentPaid => 'Betaald';

  @override
  String get membershipPaymentPending => 'In behandeling';

  @override
  String get membershipPaymentReasonFirstCharge => 'Eerste afschrijving';

  @override
  String get membershipPaymentReasonRenewal => 'Verlenging';

  @override
  String get membershipPaymentReasonPlanChange => 'Abonnementswijziging';

  @override
  String get membershipPaymentReasonCoins => 'Munten';

  @override
  String get membershipPaymentReasonLocalActivation => 'Lokale activering';

  @override
  String get membershipPaymentReasonCard => 'Kaartbetaling';

  @override
  String get membershipPaymentReasonOther => 'Betaling';

  @override
  String get paymentModeSandbox => 'Lokale test · geen echte afschrijving';

  @override
  String get paymentModeStripeTest => 'Stripe-test · geen echte afschrijving';

  @override
  String get paymentModeLive => 'Echte betalingen';

  @override
  String get paymentModeUnavailable => 'Betalingen niet beschikbaar';

  @override
  String get paymentAccountTitle => 'Je betaalaccount';

  @override
  String get paymentAccountSignedInMember => 'Ingelogd lid';

  @override
  String get paymentAccountCardTitle => 'Creditcard of betaalpas';

  @override
  String get paymentAccountCardUnavailableTitle =>
      'Betalen met kaart is niet beschikbaar';

  @override
  String get paymentAccountCardBody =>
      'Voer je kaart in via de gehoste betaalpagina. Lidmaatschap en betaalgeschiedenis horen bij dit account.';

  @override
  String get paymentAccountCardUnavailableBody =>
      'Je kunt je bestaande account blijven gebruiken. Nieuwe kaartbetalingen zijn niet ingeschakeld.';

  @override
  String paymentAccountTestCardHint(String cardNumber) {
    return 'Gebruik om te testen $cardNumber, een vervaldatum in de toekomst en een willekeurige CVC van drie cijfers. Gebruik alleen testgegevens.';
  }

  @override
  String get paymentAccountUnfinishedCardUpdate => 'Onvoltooide kaartupdate';

  @override
  String paymentAccountUnfinishedCheckout(String plan) {
    return 'Onvoltooide betaling: $plan';
  }

  @override
  String get paymentAccountPendingHint =>
      'Controleer de laatste status of ga verder met dezelfde betaling.';

  @override
  String get paymentAccountCheckStatus => 'Status controleren';

  @override
  String get paymentAccountResumeCheckout => 'Betaling hervatten';

  @override
  String paymentCheckoutPayFor(String title) {
    return 'Betalen: $title';
  }

  @override
  String get paymentCheckoutClose => 'Betaling sluiten';

  @override
  String get paymentCheckoutSecureNote =>
      'Kaartgegevens worden ingevoerd op de beveiligde pagina van de betaalprovider.';

  @override
  String paymentCheckoutCompleteInNewTab(String title) {
    return 'Rond de betaling ($title) af in het nieuwe tabblad';
  }

  @override
  String get paymentCheckoutWaitingBody =>
      'Je kaartgegevens voer je in op de beveiligde pagina van de betaalprovider. Kom hier terug zodra daar staat dat de betaling is voltooid.';

  @override
  String get paymentCheckoutCheckConfirmation => 'Bevestiging controleren';

  @override
  String get paymentCheckoutBackToAccount => 'Terug naar account';

  @override
  String get paymentWalletTitle => 'Wallet & betalingen';

  @override
  String get paymentWalletTestNote =>
      'Testbetalingen · er wordt niets echt afgeschreven. Gebruik alleen testkaartgegevens.';

  @override
  String get paymentWalletPopularTopUps => 'Populaire opwaarderingen';

  @override
  String get paymentWalletTopUpsIntro =>
      'Betaal met je kaart op de beveiligde betaalpagina. De munten staan in je wallet zodra de betaling is verwerkt.';

  @override
  String get paymentWalletCardsDisabled =>
      'Kaartbetalingen zijn op deze server nog niet ingeschakeld.';

  @override
  String get paymentWalletNoPacks =>
      'Er zijn op dit moment geen muntpakketten te koop.';

  @override
  String get paymentWalletActivity => 'Walletactiviteit';

  @override
  String get paymentWalletNoPurchases => 'Nog geen munten gekocht.';

  @override
  String get paymentWalletFooter =>
      'Munten gebruik je voor cadeaus en boosts in Connect. Aankopen zijn definitief zodra ze verwerkt zijn; kaartgegevens blijven bij de betaalprovider.';

  @override
  String paymentCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count munten',
      one: '1 munt',
    );
    return '$_temp0';
  }

  @override
  String paymentCoinsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count munten toegevoegd aan je wallet.',
      one: '1 munt toegevoegd aan je wallet.',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'munten',
      one: 'munt',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnitBonus(int count, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'munten · +$bonus bonus',
      one: 'munt · +$bonus bonus',
    );
    return '$_temp0';
  }

  @override
  String get paymentWalletCheckoutEnded =>
      'Deze betaalsessie is beëindigd. Bekijk je betaalgeschiedenis voordat je het opnieuw probeert.';

  @override
  String get paymentWalletBalanceLabel => 'Saldo Glow-wallet';

  @override
  String get paymentWalletSourceSupport => 'Opwaardering door support';

  @override
  String get paymentWalletSourcePromo => 'Promotie';

  @override
  String get paymentWalletSourcePurchase => 'Muntenaankoop';

  @override
  String get paymentErrorSignInSubscriptions =>
      'Log in om abonnementen te beheren.';

  @override
  String get paymentErrorSignInWallet => 'Log in om je wallet te beheren.';

  @override
  String get paymentErrorLoadSubscription =>
      'Kan abonnementsgegevens niet laden.';

  @override
  String get paymentErrorLoadWallet => 'Kan je wallet niet laden.';

  @override
  String get paymentErrorStartCheckoutNow => 'Kan de betaling nu niet starten.';

  @override
  String get paymentErrorStartCheckout => 'Kan de betaling niet starten.';

  @override
  String get paymentErrorConfirmPayment =>
      'Kan de betaling nog niet bevestigen.';

  @override
  String get paymentErrorAutoRenewOn =>
      'Kan automatische verlenging niet weer aanzetten.';

  @override
  String get paymentErrorAutoRenewOff =>
      'Kan automatische verlenging niet uitzetten.';

  @override
  String get paymentErrorChangePlan => 'Kan abonnement niet wijzigen.';

  @override
  String get paymentErrorUpdateCard => 'Kan de kaart niet bijwerken.';

  @override
  String get paymentErrorSandboxFailed => 'Sandboxsimulatie mislukt.';

  @override
  String get paymentErrorUnreachable =>
      'Kan de lokale dienst niet bereiken. Controleer of de API draait.';

  @override
  String membershipQuotaLikesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Vandaag nog $remaining van $limit likes over',
      one: 'Vandaag nog $remaining van 1 like over',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Vandaag nog $remaining van $limit berichten over',
      one: 'Vandaag nog $remaining van 1 bericht over',
    );
    return '$_temp0';
  }

  @override
  String membershipLikeLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Je hebt je $limit likes van vandaag op $plan gebruikt',
      one: 'Je hebt je like van vandaag op $plan gebruikt',
    );
    return '$_temp0';
  }

  @override
  String membershipMessageLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Je hebt je $limit berichten van vandaag op $plan gebruikt',
      one: 'Je hebt je bericht van vandaag op $plan gebruikt',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaResetsAt(String time) {
    return 'Wordt om $time gereset';
  }

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '$count match',
    );
    return '$_temp0';
  }

  @override
  String get matchesSubtitleConversations =>
      'Een beetje dichterbij, bericht voor bericht.';

  @override
  String get matchesSubtitlePeople =>
      'Mensen die jij hebt gekozen. Mogelijkheden die jullie samen vormgeven.';

  @override
  String get matchesSearchConversations => 'Gesprekken zoeken';

  @override
  String get matchesSearchMatches => 'Je matches zoeken';

  @override
  String get matchesFilterAllConversations => 'Alle gesprekken';

  @override
  String matchesFilterUnread(int count) {
    return 'Ongelezen · $count';
  }

  @override
  String get matchesLoading => 'Matches laden…';

  @override
  String get matchesLoadErrorTitle => 'Kan matches niet laden';

  @override
  String get matchesRetry => 'Opnieuw proberen';

  @override
  String get matchesEmptyTitle => 'Nog geen matches';

  @override
  String matchesTrustFilteredHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Vertrouwensfilters hebben $count matches verborgen. Probeer ze te versoepelen via Ontdekken.',
      one:
          'Vertrouwensfilters hebben 1 match verborgen. Probeer ze te versoepelen via Ontdekken.',
    );
    return '$_temp0';
  }

  @override
  String get matchesEmptyBody =>
      'Ga naar Vandaag om iemand te ontdekken die je graag wilt ontmoeten.';

  @override
  String get matchesNoConversationResults =>
      'Hier zijn nog geen gesprekken. Probeer een andere zoekopdracht of filter.';

  @override
  String get matchesNoPeopleResults =>
      'Geen matches gevonden. Probeer een andere naam.';

  @override
  String get matchesTabPeople => 'Je matches';

  @override
  String get matchesTabConversations => 'Gesprekken';

  @override
  String get matchesActionStartCall => 'Belsessie starten';

  @override
  String get matchesActionStartActivity => 'Activiteit starten';

  @override
  String get matchesActionPlanDate => 'Date plannen';

  @override
  String get matchesActionPlanDateSubtitle =>
      'Kies een tijd en wat je wilt delen';

  @override
  String matchesPlanSent(String name) {
    return 'Plan verstuurd naar $name.';
  }

  @override
  String get matchesActionGraduate => 'We hebben elkaar gevonden';

  @override
  String get matchesActionGraduateSubtitle =>
      'Verlaat Connect samen; jullie chat blijft';

  @override
  String matchesGraduationAsked(String name) {
    return 'Je hebt $name gevraagd om samen te vertrekken. Bevestigen kan in jullie chat.';
  }

  @override
  String get matchesActionNudge => 'Een duwtje sturen';

  @override
  String matchesNudgeSent(String name) {
    return 'Duwtje verstuurd naar $name.';
  }

  @override
  String get matchesNudgeFailed => 'Kan dit duwtje niet versturen.';

  @override
  String get matchesActionClose => 'Gesprek sluiten';

  @override
  String get matchesActionCloseSubtitle => 'Maak ruimte, zonder uitleg.';

  @override
  String get matchesCloseDialogTitle => 'Dit gesprek sluiten?';

  @override
  String get matchesCloseDialogBody =>
      'Het is oké als deze connectie niet bij je past. Hiermee eindigt de match. Je hoeft geen uitleg te sturen. Melden blijft een aparte keuze.';

  @override
  String get matchesCloseDialogKeep => 'Blijven praten';

  @override
  String get matchesActionReport => 'Melden';

  @override
  String get matchesReportSubmitted => 'Melding verstuurd. Bedankt.';

  @override
  String get matchesReportAppeal => 'Bezwaar maken';

  @override
  String matchesAppealReason(String userId) {
    return 'Moderatie-uitkomst beoordelen voor melding over gebruiker $userId';
  }

  @override
  String get matchesBothChose => 'Jullie kozen allebei voor elkaar';

  @override
  String matchesOptionsTooltip(String name) {
    return 'Matchopties voor $name';
  }

  @override
  String matchesChatUnread(int count) {
    return 'Chat · $count ongelezen';
  }

  @override
  String get matchesOpenChat => 'Chat openen';

  @override
  String get matchesFirstChapter => 'Eerste Hoofdstuk';

  @override
  String get matchesUnknownName => 'Onbekend';

  @override
  String get matchesSayHi => 'Zeg hoi 👋';

  @override
  String get matchesFallbackName => 'Je match';

  @override
  String get matchesFallbackMessage => 'Begin jullie gesprek';

  @override
  String get matchesGiftPreview => 'Een klein cadeautje in jullie gesprek';

  @override
  String matchesConversationOptionsTooltip(String name) {
    return 'Gespreksopties voor $name';
  }

  @override
  String get matchesTimeNow => 'Nu';

  @override
  String matchesTimeMinutesAgo(int minutes) {
    return '$minutes min geleden';
  }

  @override
  String matchesTimeHoursAgo(int hours) {
    return '$hours u geleden';
  }

  @override
  String get matchesTimeToday => 'Vandaag';

  @override
  String get matchesTimeYesterday => 'Gisteren';

  @override
  String get matchesNewMatchTitle => 'Nieuwe match';

  @override
  String get matchesItsAMatch => 'Het is een match!';

  @override
  String matchesLikedEachOther(String name) {
    return 'Jij en $name vinden elkaar leuk';
  }

  @override
  String get matchesSendMessage => 'Bericht sturen';

  @override
  String get matchesKeepSwiping => 'Verder swipen';

  @override
  String get matchesErrorLoginRequired => 'Log in om je matches te zien.';

  @override
  String get matchesErrorLoadFailed =>
      'Matches laden mislukt. Probeer het opnieuw.';

  @override
  String get matchesErrorUnmatchFailed => 'Match opheffen mislukt.';

  @override
  String get matchesErrorMarkReadFailed => 'Markeren als gelezen mislukt.';

  @override
  String get matchesErrorSessionUnavailable =>
      'Gebruikerssessie niet beschikbaar.';

  @override
  String get matchesTrustBadgePromptCompleter => 'Prompts ingevuld';

  @override
  String get matchesTrustBadgeRespectful => 'Respectvolle communicatie';

  @override
  String get matchesTrustBadgeConsistent => 'Consistent profiel';

  @override
  String get matchesTrustBadgeVerifiedActive => 'Geverifieerd & actief';

  @override
  String get matchesTrustErrorLoad =>
      'Vertrouwensfilters laden mislukt. Probeer het opnieuw.';

  @override
  String get matchesTrustErrorSave =>
      'Vertrouwensfilters opslaan mislukt. Probeer het opnieuw.';

  @override
  String get matchesGestureErrorLoad => 'Tijdlijn laden mislukt';

  @override
  String get matchesGestureErrorPending =>
      'Gebaren worden ontgrendeld zodra dit openstaande gesprek een echte match wordt.';

  @override
  String get matchesGestureErrorSend => 'Gebaar versturen mislukt.';

  @override
  String get matchesGestureErrorUpdate =>
      'Status van gebaar bijwerken mislukt.';

  @override
  String get matchesActivityTitle => 'Dit-of-dat in 2 minuten';

  @override
  String get matchesActivityRestartTooltip => 'Nieuwe sessie starten';

  @override
  String matchesActivityCompleteWith(String name) {
    return 'Doe dit samen met $name';
  }

  @override
  String get matchesActivityInstructions =>
      'Beantwoord alle 8 rondes voordat de tijd op is.';

  @override
  String matchesActivityStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get matchesActivityStatusActive => 'actief';

  @override
  String get matchesActivityStatusTimedOut => 'tijd verstreken';

  @override
  String get matchesActivityStatusPartialTimeout => 'deels verlopen';

  @override
  String get matchesActivityStatusCompleted => 'voltooid';

  @override
  String get matchesActivitySubmit => 'Antwoorden versturen';

  @override
  String get matchesActivityTimeUpLoad => 'De tijd is om — Samenvatting laden';

  @override
  String get matchesActivityWaiting =>
      'Antwoorden verstuurd. Wachten tot de ander klaar is.';

  @override
  String get matchesActivityRefreshSummary => 'Samenvatting vernieuwen';

  @override
  String matchesActivityTimeLeft(String time) {
    return 'Resterende tijd $time';
  }

  @override
  String get matchesActivitySummaryTitle => 'Samenvatting van de activiteit';

  @override
  String matchesActivityParticipantsCompleted(int completed, int total) {
    return 'Deelnemers klaar: $completed/$total';
  }

  @override
  String get matchesActivitySummaryPending =>
      'De samenvatting verschijnt zodra die beschikbaar is.';

  @override
  String get matchesActivityShareResult => 'Resultaat delen in chat';

  @override
  String matchesActivityShareMessage(String status, int completed, int total) {
    return 'Resultaat Dit-of-dat (2 min): $status • $completed/$total voltooid';
  }

  @override
  String matchesActivityShareMessageWithInsight(
    String status,
    int completed,
    int total,
    String insight,
  ) {
    return 'Resultaat Dit-of-dat (2 min): $status • $completed/$total voltooid • $insight';
  }

  @override
  String matchesActivityRound(int number) {
    return 'Ronde $number';
  }

  @override
  String get matchesActivityErrorStart =>
      'Kan de activiteit nu niet starten. Probeer het opnieuw.';

  @override
  String get matchesActivityErrorNotReady => 'De sessie is nog niet klaar.';

  @override
  String get matchesActivityErrorAnswerAll =>
      'Beantwoord alle vragen voordat je verstuurt.';

  @override
  String get matchesActivityErrorTimeUp => 'De tijd is om. Samenvatting laden…';

  @override
  String get matchesActivityErrorSubmit =>
      'Antwoorden versturen mislukt. Probeer het opnieuw.';

  @override
  String get matchesActivityErrorSummary =>
      'Kan de samenvatting nog niet ophalen. Probeer het opnieuw.';

  @override
  String get matchesActivityQ1Prompt => 'Ideale eerste ontmoeting?';

  @override
  String get matchesActivityQ1OptionA => 'Wandelen met koffie';

  @override
  String get matchesActivityQ1OptionB => 'Snuffelen in een boekwinkel';

  @override
  String get matchesActivityQ2Prompt => 'Favoriete weekendstemming?';

  @override
  String get matchesActivityQ2OptionA => 'Thuisblijven en opladen';

  @override
  String get matchesActivityQ2OptionB => 'De stad verkennen';

  @override
  String get matchesActivityQ3Prompt => 'Beste plek voor een gesprek?';

  @override
  String get matchesActivityQ3OptionA => 'Lange wandeling';

  @override
  String get matchesActivityQ3OptionB => 'Knus hoekje in een café';

  @override
  String get matchesActivityQ4Prompt => 'Hoe plan je dates?';

  @override
  String get matchesActivityQ4OptionA => 'Spontaan';

  @override
  String get matchesActivityQ4OptionB => 'Van tevoren gepland';

  @override
  String get matchesActivityQ5Prompt => 'Wat is nu belangrijker?';

  @override
  String get matchesActivityQ5OptionA => 'Stabiliteit';

  @override
  String get matchesActivityQ5OptionB => 'Spanning';

  @override
  String get matchesActivityQ6Prompt => 'Hoe ga je met conflicten om?';

  @override
  String get matchesActivityQ6OptionA => 'Dezelfde dag uitpraten';

  @override
  String get matchesActivityQ6OptionB => 'Eerst afstand, dan erop terugkomen';

  @override
  String get matchesActivityQ7Prompt => 'Samen iets doen?';

  @override
  String get matchesActivityQ7OptionA => 'Samen koken';

  @override
  String get matchesActivityQ7OptionB => 'Samen sporten';

  @override
  String get matchesActivityQ8Prompt => 'Welk tempo heb je liever?';

  @override
  String get matchesActivityQ8OptionA => 'Rustig en bewust';

  @override
  String get matchesActivityQ8OptionB => 'Snel en energiek';

  @override
  String get cityPilotSaveFailed =>
      'We konden die wijziging niet bevestigen. Vernieuw om het te controleren voordat je het opnieuw probeert.';

  @override
  String get cityPilotLeaveTitle => 'De stadspilot verlaten?';

  @override
  String get cityPilotLeaveBody =>
      'Je boekingen in de pilot worden geannuleerd en je feedback over ervaringen wordt verwijderd. Je activiteit telt niet meer mee voor de huidige resultaten. Je matches en gesprekken blijven. Je kunt niet opnieuw meedoen aan deze pilot.';

  @override
  String get cityPilotStay => 'In de pilot blijven';

  @override
  String get cityPilotLeave => 'Pilot verlaten';

  @override
  String get cityPilotLeftNotice =>
      'Je hebt de pilot verlaten. Je matches blijven bij je.';

  @override
  String cityPilotJoinEventTitle(String title) {
    return 'Meedoen aan $title?';
  }

  @override
  String cityPilotBookingTerms(
    String host,
    String safetyContact,
    String accessibility,
  ) {
    return 'Deze ervaring is gratis. Jullie ontmoeten elkaar op een openbare locatie: respecteer de grenzen van anderen en regel je eigen vervoer. Je kunt op elk moment weggaan.\n\nHost: $host\nVeiligheidscontact: $safetyContact\n\nToegankelijkheid: $accessibility\n\nBij acuut gevaar: neem contact op met de lokale hulpdiensten.';
  }

  @override
  String get cityPilotAcceptReserve => 'Accepteren & plek reserveren';

  @override
  String get cityPilotReservedNotice =>
      'Je plek is gereserveerd. Je kunt hier altijd annuleren.';

  @override
  String get cityPilotFeedbackTitle => 'Hoe was de ervaring?';

  @override
  String get cityPilotFeedbackIntro =>
      'Optioneel. Antwoorden tellen mee in de gecombineerde resultaten van de pilot. Ze worden niet getoond aan andere leden of de host.';

  @override
  String get cityPilotDidYouAttend => 'Was je erbij?';

  @override
  String get cityPilotAttendedYes => 'Ja, ik was er';

  @override
  String get cityPilotAttendedNo => 'Het lukte me niet';

  @override
  String get cityPilotWorthwhileQuestion =>
      'Was het je tijd waard? (optioneel)';

  @override
  String get cityPilotNotThisTime => 'Deze keer niet';

  @override
  String get cityPilotSkip => 'Overslaan';

  @override
  String get cityPilotShareFeedback => 'Feedback delen';

  @override
  String get cityPilotFeedbackThanks =>
      'Bedankt. Je feedback is vertrouwelijk vastgelegd.';

  @override
  String get cityPilotTimeTbc => 'Tijd volgt nog';

  @override
  String get cityPilotTitle => 'De stadspilot';

  @override
  String get cityPilotRefreshTooltip => 'Pilot vernieuwen';

  @override
  String get cityPilotHeroTitle => 'Iets dichterbij.\nVeel echter.';

  @override
  String get cityPilotHeroBody =>
      'Eén stad. Een kleine community. Meer kans dat een gesprek een plan wordt.';

  @override
  String get cityPilotStep1Title => 'Begin met een gesprek';

  @override
  String get cityPilotStep1Body =>
      'Leer mensen kennen in je eigen tempo via je bestaande introducties.';

  @override
  String get cityPilotStep2Title => 'Maak ruimte voor een echte date';

  @override
  String get cityPilotStep2Body =>
      'Maak samen een plan. Deel hoe het ging alleen als je dat wilt.';

  @override
  String get cityPilotStep3Title => 'Probeer samen iets';

  @override
  String get cityPilotStep3Body =>
      'Kleine, begeleide ervaringen volgen na de eerste evaluatie van de pilot.';

  @override
  String get cityPilotSaving => 'Pilotvoorkeur opslaan';

  @override
  String get cityPilotUnavailableTitle => 'Je pilot is niet beschikbaar';

  @override
  String get cityPilotUnavailableBody =>
      'Controleer je verbinding en vernieuw om je actuele deelname en boekingen te zien.';

  @override
  String get cityPilotComingSoonTitle =>
      'Binnenkort in een stad bij jou in de buurt';

  @override
  String get cityPilotComingSoonBody =>
      'Er is nog geen open pilot voor de stad in je profiel. Zodra er een opent, kun je kiezen of je meedoet. Je huidige datingervaring gaat gewoon door.';

  @override
  String cityPilotPanelTitleJoined(String city) {
    return '$city · Je doet mee';
  }

  @override
  String cityPilotPanelTitleOpen(String city) {
    return '$city · Stadspilot';
  }

  @override
  String cityPilotRecruitmentCloses(String date) {
    return 'Aanmelden sluit: $date (jouw lokale tijd).';
  }

  @override
  String get cityPilotPaused =>
      'Nieuwe deelnames en boekingen zijn gepauzeerd. Je kunt nog steeds stoppen of annuleren.';

  @override
  String get cityPilotCompleted =>
      'Deze pilot is afgerond. Bedankt dat je meedeed.';

  @override
  String get cityPilotMeasurement =>
      'Als je meedoet, tellen we gesprekken, geaccepteerde plannen en optionele antwoorden op ‘Is de date doorgegaan?’ voor nieuwe matches waarbij beide personen aan deze pilot meedoen. We gebruiken een venster van 7 dagen voor gesprekken en 28 dagen voor dates. We lezen geen berichtteksten of privéfeedbacknotities voor de pilot.';

  @override
  String get cityPilotPrivacy =>
      'Deelname blijft privé. Er is geen openbare aanwezigheidslijst of datingscore. Stoppen sluit je activiteit uit van de huidige resultaten en annuleert je boekingen. Eerder bekeken gecombineerde resultaten kunnen niet ongedaan worden gemaakt.';

  @override
  String get cityPilotConsent =>
      'Ik ga akkoord met deelname aan deze pilot en het meten van de resultaten.';

  @override
  String get cityPilotJoinedNotice =>
      'Je doet mee. Blijf mensen leren kennen in je eigen tempo.';

  @override
  String get cityPilotJoin => 'Meedoen met de stadspilot';

  @override
  String get cityPilotWithdrawn =>
      'Je hebt deze pilot verlaten. Je matches en gesprekken blijven ongewijzigd.';

  @override
  String get cityPilotNotAccepting =>
      'Deze pilot neemt momenteel geen nieuwe leden aan.';

  @override
  String get cityPilotExperiencesHeading =>
      'Kleine plannen. Gedeelde ervaringen.';

  @override
  String get cityPilotNoExperiences =>
      'Begeleide ervaringen zijn nog niet open. Ze verschijnen hier na een evaluatie van resultaten en veiligheid.';

  @override
  String cityPilotEventDetails(
    String start,
    String end,
    String venue,
    String host,
  ) {
    return '$start → $end\nJouw lokale tijd · Gratis\n$venue\nGehost door $host';
  }

  @override
  String cityPilotAccessibility(String details) {
    return 'Toegankelijkheid · $details';
  }

  @override
  String cityPilotSafetyContact(String contact) {
    return 'Veiligheidscontact · $contact';
  }

  @override
  String get cityPilotEventCancelled =>
      'Deze ervaring is geannuleerd. Ga niet naar de locatie.';

  @override
  String get cityPilotPlaceReserved => 'Je plek is gereserveerd.';

  @override
  String get cityPilotBookingCancelled => 'Je boeking is geannuleerd.';

  @override
  String get cityPilotCancelPlace => 'Mijn plek annuleren';

  @override
  String get cityPilotReserveFree => 'Gratis plek reserveren';

  @override
  String get cityPilotShareOptionalFeedback => 'Optionele feedback delen';

  @override
  String get cityPilotFeedbackReceived => 'Je feedback is ontvangen. Bedankt.';

  @override
  String get blogAudiencePrivate => 'Alleen ik';

  @override
  String get blogAudienceFriends => 'Vrienden';

  @override
  String get blogAudienceCommunity => 'Connect-community';

  @override
  String get blogInvitationNone => 'Geen uitnodiging';

  @override
  String get blogInvitationYourVersion => 'Hoe zou jouw versie eruitzien?';

  @override
  String get blogInvitationTeachMe => 'Wat zou jij me hierover kunnen leren?';

  @override
  String get blogInvitationWhatNext => 'Wat zou jij hierna proberen?';

  @override
  String get blogRewardStoryPublishedTitle => 'Een hoofdstuk delen';

  @override
  String get blogRewardStoryPublishedWho =>
      'Jij, de eerste keer dat een hoofdstuk verder gaat dan ‘Alleen ik’';

  @override
  String get blogRewardPhotoSharedTitle => 'Een foto delen bij Fotothema\'s';

  @override
  String get blogRewardPhotoSharedWho =>
      'Jij, voor een foto die je deelt bij Fotothema\'s';

  @override
  String get blogRewardLikeReceivedTitle => 'Een like op je hoofdstuk of foto';

  @override
  String get blogRewardLikeReceivedWho =>
      'Jij, voor elk lid dat het leuk vindt';

  @override
  String get blogRewardCommentReceivedTitle => 'Een reactie die je goedkeurt';

  @override
  String get blogRewardCommentReceivedWho =>
      'Jij, wanneer je de reactie van een lezer goedkeurt';

  @override
  String get blogRewardCommentApprovedTitle => 'Je reactie is goedgekeurd';

  @override
  String get blogRewardCommentApprovedWho =>
      'Jij, wanneer een auteur je reactie goedkeurt';

  @override
  String get blogRewardSubscriberGainedTitle => 'Een nieuwe volger';

  @override
  String get blogRewardSubscriberGainedWho =>
      'Jij, voor elk nieuw lid dat je hoofdstukken volgt';

  @override
  String get blogRewardWallTierTitle => 'Op meer walls komen';

  @override
  String get blogRewardWallTierWho =>
      'Jij, elke keer dat een hoofdstuk een nieuw wall-niveau bereikt';

  @override
  String get blogRewardCoverOfWeekTitle => 'Cover van de week';

  @override
  String get blogRewardCoverOfWeekWho =>
      'Jij, wanneer je werk wordt gekozen als Cover van de week';

  @override
  String get blogScopeForYou => 'Voor jou';

  @override
  String get blogScopeTopRated => 'Best beoordeeld';

  @override
  String get blogScopeFollowing => 'Gevolgd';

  @override
  String get blogScopeMine => 'Van mij';

  @override
  String get blogScopeCaptionMine =>
      'Je concepten en gepubliceerde hoofdstukken. Jij kiest per hoofdstuk het publiek.';

  @override
  String get blogScopeCaptionFriends =>
      'Hoofdstukken gedeeld door je Connect-vrienden.';

  @override
  String get blogScopeCaptionTop =>
      'Gerangschikt op likes, goedgekeurde reacties en lezers van de afgelopen 30 dagen.';

  @override
  String get blogScopeCaptionFollowing =>
      'De nieuwste hoofdstukken van schrijvers die je volgt.';

  @override
  String get blogScopeCaptionCommunity =>
      'Voor ingelogde Connect-leden die daarvoor in aanmerking komen. Deze hoofdstukken zijn niet openbaar op het web.';

  @override
  String get blogTitle => 'Open hoofdstukken';

  @override
  String get blogRewardsTitle => 'Zo werken beloningen';

  @override
  String get blogWritersTitle => 'Schrijvers die je volgt';

  @override
  String get blogConnectionsTooltip => 'Privéreacties, delen en meldingen';

  @override
  String get blogSignInReadWrite =>
      'Log in om hoofdstukken te lezen en te schrijven.';

  @override
  String get blogHeroTitle => 'Een leven dat het\nleren kennen waard is.';

  @override
  String get blogHeroBody =>
      'Het verhaal achter een foto. Een kleine obsessie. Iets wat je nog aan het leren bent. Laat je dagelijks leven voor je spreken.';

  @override
  String get blogWriteChapter => 'Hoofdstuk schrijven';

  @override
  String get blogPrivateResponses => 'Privéreacties';

  @override
  String get blogSharedLinks => 'Gedeelde links';

  @override
  String get blogReviewNotices => 'Beoordelingsmeldingen';

  @override
  String get blogTopicAll => 'Alle';

  @override
  String get blogFeedLoadFailed => 'Hoofdstukken konden niet worden geladen.';

  @override
  String get blogPreviousPage => 'Vorige pagina';

  @override
  String get blogMoreChapters => 'Meer hoofdstukken';

  @override
  String get blogEmptyMineTitle => 'Je volgende hoofdstuk begint hier.';

  @override
  String get blogEmptyMineBody =>
      'Begin met een moment waar je graag naar gevraagd zou worden. Je eerste concept is alleen voor jou.';

  @override
  String get blogEmptyTopTitle =>
      'Als hoofdstukken mensen raken, stijgen ze hier.';

  @override
  String get blogEmptyTopFilteredBody =>
      'In dit onderwerp is nog niets gestegen. Probeer ‘Alle’ of deel zelf een hoofdstuk.';

  @override
  String get blogEmptyTopBody =>
      'Hoofdstukken waar lezers de afgelopen 30 dagen dol op waren, verschijnen hier.';

  @override
  String get blogEmptyFollowingFilteredTitle =>
      'Nog niets nieuws in dit onderwerp.';

  @override
  String get blogEmptyFollowingTitle =>
      'Schrijvers die je volgt, verschijnen hier.';

  @override
  String get blogEmptyFollowingBody =>
      'Raakt een hoofdstuk je, open het dan en tik op ‘Hun hoofdstukken volgen’. Nieuwe hoofdstukken verzamelen zich hier, zodat je niets mist.';

  @override
  String get blogEmptyCommunityTitle => 'Het is hier nog even stil.';

  @override
  String get blogEmptyCommunityBody =>
      'Hoofdstukken verschijnen hier zodra leden ze met dit publiek delen.';

  @override
  String get blogFindWritersTopRated =>
      'Schrijvers vinden in ‘Best beoordeeld’';

  @override
  String blogRankTooltip(int rank) {
    return 'Nummer $rank in ‘Best beoordeeld’';
  }

  @override
  String get blogUntitled => 'Een hoofdstuk zonder titel';

  @override
  String get blogDraftPlaceholder =>
      'Een privéconcept dat op je woorden wacht.';

  @override
  String get blogReadEdit => 'Lezen & bewerken →';

  @override
  String get blogReadChapter => 'Hoofdstuk lezen →';

  @override
  String get blogPhotoUnavailableRetry => 'Foto niet beschikbaar · Opnieuw';

  @override
  String get blogTryAgain => 'Opnieuw proberen';

  @override
  String get blogDetailTitle => 'Een hoofdstuk';

  @override
  String get blogSignInRead => 'Log in om hoofdstukken te lezen.';

  @override
  String get blogDetailUnavailable =>
      'Dit hoofdstuk is niet beschikbaar of het publiek is gewijzigd.';

  @override
  String get blogRespondPrivately => 'Privé reageren';

  @override
  String get blogCreatePublicPreview => 'Openbare preview maken';

  @override
  String get blogRemovedByModerationNote =>
      'Verwijderd door moderatie. Open ‘Beoordelingsmeldingen’ om de beslissing te lezen of een nieuwe beoordeling aan te vragen.';

  @override
  String get blogEditChapter => 'Hoofdstuk bewerken';

  @override
  String get blogDeleteChapter => 'Hoofdstuk verwijderen';

  @override
  String get blogDeleteChapterTitle => 'Dit hoofdstuk verwijderen?';

  @override
  String get blogDeleteChapterMessage =>
      'Het verdwijnt voor alle lezers. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get blogDeleteChapterFailed =>
      'Verwijderen kon niet worden bevestigd. Herlaad het hoofdstuk voordat je het opnieuw probeert.';

  @override
  String get blogReportChapter => 'Hoofdstuk melden';

  @override
  String get blogReportFailed => 'De melding kon niet worden verstuurd.';

  @override
  String get blogBlockThisMember => 'Dit lid blokkeren';

  @override
  String get blogBlockTitle => 'Dit lid blokkeren?';

  @override
  String get blogBlockMessageChapter =>
      'Jullie zien elkaars hoofdstukken niet meer. Dit blokkeert ook contact via Connect.';

  @override
  String get blogBlockMember => 'Lid blokkeren';

  @override
  String get blogBlockRetryFailed =>
      'Dit lid kon niet worden geblokkeerd. Probeer het opnieuw.';

  @override
  String get blogCancel => 'Annuleren';

  @override
  String get blogEditorMissingFields =>
      'Voeg een titel en verhaal toe voordat je publiceert.';

  @override
  String blogPublishConfirmTitle(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Publiceren voor ‘Alleen ik’?',
      'friends': 'Publiceren voor vrienden?',
      'community': 'Publiceren in de Connect-community?',
      'other': 'Publiceren?',
    });
    return '$_temp0';
  }

  @override
  String get blogPublishFriendsBody =>
      'Je Connect-vrienden kunnen de tekst en foto\'s van dit hoofdstuk zien. Je kunt het publiek later wijzigen.';

  @override
  String get blogPublishCommunityBody =>
      'Ingelogde Connect-leden die daarvoor in aanmerking komen, kunnen dit hoofdstuk lezen. Het verschijnt niet op het openbare web. Je kunt het publiek later wijzigen.';

  @override
  String get blogPublishChapter => 'Hoofdstuk publiceren';

  @override
  String get blogSavedOnlyMe =>
      'Opgeslagen. Alleen jij kunt dit hoofdstuk lezen.';

  @override
  String blogPublishedTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Gepubliceerd voor ‘Alleen ik’.',
      'friends': 'Gepubliceerd voor vrienden.',
      'community': 'Gepubliceerd in de Connect-community.',
      'other': 'Gepubliceerd.',
    });
    return '$_temp0';
  }

  @override
  String get blogSharedSnack =>
      'Gedeeld. Likes en reacties van lezers leveren je XP op.';

  @override
  String get blogSeeMyLevel => 'Mijn niveau bekijken';

  @override
  String get blogSaveUnconfirmed => 'We konden het opslaan niet bevestigen.';

  @override
  String blogEditsStillHere(String message) {
    return '$message Je wijzigingen staan er nog. Controleer de opgeslagen versie voordat je verdergaat.';
  }

  @override
  String blogSavedVersionTitle(String audience) {
    return 'Opgeslagen versie · $audience';
  }

  @override
  String get blogSavedVersionNote =>
      'Je huidige wijzigingen blijven in de editor. Sluit dit venster om ze te houden, of vervang ze door deze opgeslagen versie.';

  @override
  String get blogKeepMyEdits =>
      'Mijn wijzigingen bewaren voor de volgende keer opslaan';

  @override
  String get blogUseSavedVersion => 'Opgeslagen versie gebruiken';

  @override
  String get blogSavedVersionLoadFailed =>
      'De opgeslagen versie kon niet worden geladen. Je wijzigingen blijven hier.';

  @override
  String get blogDescribePhotoTitle => 'Beschrijf je foto';

  @override
  String get blogDescribePhotoBody =>
      'Een korte beschrijving maakt je hoofdstuk toegankelijk. Door de foto toe te voegen, worden je woorden opgeslagen als ‘Alleen ik’-concept.';

  @override
  String get blogDescribePhotoLabel => 'Wat staat er op deze foto?';

  @override
  String get blogAddToPrivateDraft => 'Toevoegen aan privéconcept';

  @override
  String get blogPhotoAdded => 'Foto toegevoegd aan je privéconcept.';

  @override
  String get blogPhotoAddFailed =>
      'De foto kon niet worden toegevoegd. Gebruik een JPEG of PNG tot 10 MB.';

  @override
  String blogCheckSavedBeforeRetrying(String message) {
    return '$message Controleer de opgeslagen versie voordat je het opnieuw probeert.';
  }

  @override
  String get blogRemoveUnconfirmed =>
      'Verwijderen kon niet worden bevestigd. Controleer de opgeslagen versie.';

  @override
  String get blogSignInAsAuthor =>
      'Log in als de auteur om dit hoofdstuk te bewerken.';

  @override
  String get blogLeaveEditorTitle => 'Verlaten zonder op te slaan?';

  @override
  String get blogLeaveEditorMessage =>
      'Je niet-opgeslagen wijzigingen gaan verloren. Je laatst opgeslagen hoofdstuk blijft bestaan.';

  @override
  String get blogLeaveEditor => 'Editor verlaten';

  @override
  String get blogEditorPreviewTitle => 'Hoofdstukvoorbeeld';

  @override
  String get blogEditorTitle => 'Je volgende hoofdstuk';

  @override
  String get blogEditorHeadline => 'Een beetje meer jij.';

  @override
  String get blogEditorIntro =>
      'Kleine verhalen zijn welkom. Een maaltijd die je maakte. Een plek die je van gedachten deed veranderen. De foto met een verhaal erachter.';

  @override
  String get blogNotSavedDefault => 'Niet opgeslagen · Standaard ‘Alleen ik’';

  @override
  String blogSavedFor(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Opgeslagen voor ‘Alleen ik’',
      'friends': 'Opgeslagen voor vrienden',
      'community': 'Opgeslagen voor de Connect-community',
      'other': 'Opgeslagen',
    });
    return '$_temp0';
  }

  @override
  String get blogKeepWriting => 'Verder schrijven';

  @override
  String get blogPreview => 'Voorbeeld';

  @override
  String get blogCheckSavedVersion => 'Opgeslagen versie controleren';

  @override
  String blogPreviewNotSaved(String audience) {
    return 'Voorbeeld · $audience · Nog niet opgeslagen';
  }

  @override
  String get blogStoryPlaceholder => 'Je verhaal verschijnt hier.';

  @override
  String get blogChapterTitleLabel => 'Titel van het hoofdstuk';

  @override
  String get blogChapterTitleHint => 'De zondag waarop ik leerde vertragen';

  @override
  String get blogStoryLabel => 'Je verhaal';

  @override
  String get blogStoryHint => 'Begin waar je wilt. Maak het van jou.';

  @override
  String get blogInvitationLabel => 'Eindigen met een uitnodiging (optioneel)';

  @override
  String get blogInvitationHelp =>
      'Laat een vraag achter die iemand helpt je te leren kennen.';

  @override
  String get blogRemovePhoto => 'Foto verwijderen';

  @override
  String get blogAddPhoto => 'Foto toevoegen';

  @override
  String get blogPhotoRules =>
      'Maximaal 6 JPEG- of PNG-foto\'s van elk 10 MB. Foto\'s moeten worden goedgekeurd. Sla op als ‘Alleen ik’ voordat je foto\'s in een gepubliceerd hoofdstuk wijzigt.';

  @override
  String get blogWhoFor => 'Voor wie is dit hoofdstuk?';

  @override
  String get blogAudiencePrivateHelp =>
      'Alleen jij kunt dit hoofdstuk lezen. Vrienden en matches zien het niet.';

  @override
  String get blogAudienceFriendsHelp =>
      'Alleen je Connect-vrienden kunnen het lezen. Een match alleen geeft geen toegang.';

  @override
  String get blogAudienceCommunityHelp =>
      'Ingelogde leden die daarvoor in aanmerking komen, kunnen het lezen. Maak je profiel compleet met twee goedgekeurde profielfoto\'s om hier te publiceren. Dit is geen openbaar delen op het web.';

  @override
  String get blogAllowFeaturing => 'Uitlichten toestaan';

  @override
  String get blogAllowFeaturingHelp =>
      'Als lezers het geweldig vinden, kan je hoofdstuk op de walls van andere leden komen: 50 likes en 5 reacties brengen het op 50 walls, 100 likes en 10 reacties op 100. Je kunt dit altijd uitzetten.';

  @override
  String get blogSaveOnlyForMe => 'Alleen voor mij opslaan';

  @override
  String blogPublishTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Publiceren voor ‘Alleen ik’',
      'friends': 'Publiceren voor vrienden',
      'community': 'Publiceren in de Connect-community',
      'other': 'Publiceren',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveAsOnlyMe => 'Opslaan als ‘Alleen ik’';

  @override
  String get blogSaveNote =>
      'Je woorden worden opgeslagen als je Opslaan of Publiceren kiest. Het voorbeeld publiceert niets.';

  @override
  String get blogTopicOptional => 'Onderwerp (optioneel)';

  @override
  String get blogTopicHelp =>
      'Help lezers die hierom geven je hoofdstuk te vinden.';

  @override
  String get webDestBlog => 'Blog';

  @override
  String get webDestFirstChapter => 'Studio Eerste hoofdstuk';

  @override
  String get webDestDatingPreferences => 'Datingvoorkeuren';

  @override
  String get webDestEditProfile => 'Profiel bewerken';

  @override
  String get webDestProfilePhotos => 'Profielfoto’s';

  @override
  String get webDestLikedYou => 'Vinden jou leuk';

  @override
  String get webDestNotifications => 'Meldingen';

  @override
  String get webDestDailyPrompt => 'Dagelijkse vraag';

  @override
  String get webDestLevels => 'Levels & voortgang';

  @override
  String get webDestTrustBadges => 'Vertrouwensbadges';

  @override
  String get webDestTrustFilters => 'Vertrouwensfilters';

  @override
  String get webDestIcebreakers => 'IJsbrekers';

  @override
  String get webDestCircleChallenges => 'Kringuitdagingen';

  @override
  String get webDestCoffeePolls => 'Koffiepolls';

  @override
  String get webDestGroups => 'Groepen';

  @override
  String get webDestRooms => 'Gespreksruimtes';

  @override
  String get webDestMatchNudges => 'Matchherinneringen';

  @override
  String get webDestFriends => 'Vrienden';

  @override
  String get webDestDatePlans => 'Dateplannen';

  @override
  String get webDestCallHistory => 'Belgeschiedenis';

  @override
  String get webDestMembership => 'Lidmaatschap';

  @override
  String get webDestVerification => 'Verificatie';

  @override
  String get webDestPrivacySafety => 'Privacy & veiligheid';

  @override
  String get webDestAccountData => 'Account & gegevens';

  @override
  String get webDestBlockedMembers => 'Geblokkeerde leden';

  @override
  String get webDestEmergencyContacts => 'Noodcontacten';

  @override
  String get webDestModerationAppeals => 'Bezwaren tegen moderatie';

  @override
  String get webDestNotificationPreferences => 'Meldingsvoorkeuren';

  @override
  String get webDestHelpSupport => 'Hulp & ondersteuning';

  @override
  String get webNavExplore => 'Verkennen';

  @override
  String get webNavMyProfile => 'Mijn profiel';

  @override
  String get webNavAllFeatures => 'Alle functies';

  @override
  String get webNavMoreForYou => 'Meer voor jou';

  @override
  String get webNavPreferences => 'Voorkeuren';

  @override
  String get webNavWebsite => 'Connect-website';

  @override
  String get webNavSignOut => 'Uitloggen';

  @override
  String get webPageNotFound => 'Deze pagina is niet gevonden.';

  @override
  String get webBackToDiscover => 'Terug naar Ontdekken';

  @override
  String get webTagline => 'Jouw tempo. Jouw keuze.';

  @override
  String webUnavailableTitle(String label) {
    return '$label is nog niet beschikbaar.';
  }

  @override
  String get webUnavailableBody =>
      'Het maakt geen deel uit van deze versie van Connect.';

  @override
  String get webDirectoryTitle => 'Maak deze plek van jou.';

  @override
  String get webDirectorySubtitle =>
      'Je profiel, gesprekken, community en instellingen — alles op één plek.';

  @override
  String get webIcebreakerTitle => 'Gespreksstarters';

  @override
  String get webIcebreakerHeadline =>
      'Een beetje inspiratie voor je volgende hallo.';

  @override
  String get webIcebreakerBody =>
      'Spraakopname en -weergave zijn nog niet beschikbaar. Je kunt deze ideeën gebruiken in een geschikt gesprek.';

  @override
  String get webIcebreakerOpenMatches => 'Mijn matches openen';

  @override
  String get webMembershipHeadline => 'Net iets meer mogelijkheden.';

  @override
  String get webMembershipIntro =>
      'Bekijk de huidige abonnementen. Afrekenen in de browser is nog niet beschikbaar. Op deze pagina kan niets worden gekocht of afgeschreven.';

  @override
  String webMembershipCurrent(String plan) {
    return 'Je lidmaatschap: $plan';
  }

  @override
  String webMembershipStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get webMembershipMonthly => 'Maandelijks';

  @override
  String get webMembershipYearly => 'Jaarlijks';

  @override
  String get webMembershipFree => 'Gratis';

  @override
  String webMembershipPrice(String price, String cycle) {
    String _temp0 = intl.Intl.selectLogic(cycle, {
      'yearly': 'jaar',
      'other': 'maand',
    });
    return '$price / $_temp0';
  }

  @override
  String get webMembershipFootnote =>
      'Catalogusprijzen zijn een voorproefje. Een lidmaatschap gaat nooit voorbij aan de grenzen van een ander of aan de voorwaarden om te chatten.';

  @override
  String get blogLinkCopied => 'Link gekopieerd. Deel hem waar je maar wilt.';

  @override
  String get blogYourPublicLink => 'Je openbare link';

  @override
  String get blogShareUnconfirmed =>
      'Delen kon niet worden bevestigd. Controleer ‘Gedeelde links’ voordat je het opnieuw probeert.';

  @override
  String get blogSignInAgain => 'Log opnieuw in om verder te gaan.';

  @override
  String get blogSharedJournalPage => 'Een gedeelde dagboekpagina';

  @override
  String get blogYourPublicPreview => 'Je openbare preview';

  @override
  String get blogShareJointHeadline =>
      'Een verhaal dat jullie allebei willen delen.';

  @override
  String get blogShareSoloHeadline => 'Een klein kijkje in jouw wereld.';

  @override
  String get blogShareJointBody =>
      'Beide auteurs moeten precies deze woorden goedkeuren voordat de link werkt. Jullie kunnen hem allebei intrekken.';

  @override
  String get blogShareSoloBody =>
      'Iedereen met de link kan de gekozen woorden en foto\'s zien, zonder account. Je volledige hoofdstuk blijft in Connect.';

  @override
  String get blogShareIdentityNote =>
      'Er wordt geen profiel of accountnaam toegevoegd. Je woorden en foto\'s kunnen mensen of plaatsen nog steeds herkenbaar maken. Publiceer alleen wat je mag delen.';

  @override
  String get blogExcerptLabel => 'Exact fragment uit je hoofdstuk';

  @override
  String blogIncludePhoto(String description) {
    return 'Toevoegen: $description';
  }

  @override
  String get blogApproveCopy => 'Ik keur precies deze openbare versie goed';

  @override
  String get blogApproveCopyNote =>
      'Als je het oorspronkelijke hoofdstuk bewerkt of verbergt, werkt de link niet meer. Kopieën die buiten Connect zijn opgeslagen, kunnen niet worden teruggehaald.';

  @override
  String get blogSaving => 'Opslaan…';

  @override
  String get blogRequestOtherApproval =>
      'Goedkeuring van de andere auteur vragen';

  @override
  String get blogCreatePublicLink => 'Openbare link maken';

  @override
  String get blogJointApprovalRecorded =>
      'Je goedkeuring is vastgelegd. De link blijft onbeschikbaar totdat de andere auteur goedkeurt.';

  @override
  String get blogPublicCopyReady => 'Je openbare versie is klaar.';

  @override
  String get blogCopyPublicLink => 'Openbare link kopiëren';

  @override
  String get blogManageSharedLinks => 'Gedeelde links beheren';

  @override
  String blogFollowerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count volgers',
      one: '1 volger',
    );
    return '$_temp0';
  }

  @override
  String get blogUnfollowFailed =>
      'Ontvolgen lukte nu niet. Probeer het opnieuw.';

  @override
  String get blogFollowFailed =>
      'Deze schrijver volgen lukte nu niet. Probeer het opnieuw.';

  @override
  String get blogFollowingButton => 'Volgend';

  @override
  String get blogFollowTheirChapters => 'Hun hoofdstukken volgen';

  @override
  String get blogRewardsIntro =>
      'Als wat je deelt iemand raakt, telt dat. Likes van lezers, goedgekeurde reacties en nieuwe volgers leveren je XP op voor je niveau. Beloningen komen van wat lezers doen, nooit van zomaar tikken, en elke beloning krijg je maar één keer.';

  @override
  String blogRewardDailyCap(int cap) {
    return 'Tot $cap XP per dag';
  }

  @override
  String blogRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String get blogSignInWriters =>
      'Log in om de schrijvers te zien die je volgt.';

  @override
  String get blogWritersLoadFailed =>
      'De schrijvers die je volgt, konden niet worden geladen.';

  @override
  String get blogNoWriters => 'Nog geen schrijvers.';

  @override
  String get blogNoWritersBody =>
      'Raakt een hoofdstuk je, tik dan op ‘Hun hoofdstukken volgen’. Nieuwe hoofdstukken verzamelen zich onder ‘Gevolgd’.';

  @override
  String blogLatest(String title) {
    return 'Nieuwste: $title';
  }

  @override
  String get blogReactionFailed =>
      'Je reactie is niet doorgekomen. Probeer het opnieuw.';

  @override
  String blogCannotLikeOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Je kunt je eigen foto niet liken',
      'other': 'Je kunt je eigen hoofdstuk niet liken',
    });
    return '$_temp0';
  }

  @override
  String blogYouReacted(String reaction) {
    return 'Je reageerde: $reaction. Tik om het terug te draaien';
  }

  @override
  String blogLikeThis(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Deze foto liken',
      'other': 'Dit hoofdstuk liken',
    });
    return '$_temp0';
  }

  @override
  String blogCannotReactOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Je kunt niet reageren op je eigen foto',
      'other': 'Je kunt niet reageren op je eigen hoofdstuk',
    });
    return '$_temp0';
  }

  @override
  String get blogReactTooltip => 'Reageren: Ik hoor je, Ik ook, Dikke knuffel…';

  @override
  String blogCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reacties',
      one: '1 reactie',
    );
    return '$_temp0';
  }

  @override
  String blogWaitingForYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '· $count wachten op jou',
      one: '· $count wacht op jou',
    );
    return '$_temp0';
  }

  @override
  String get blogFeatured => 'Uitgelicht';

  @override
  String blogTierNeedsBoth(int likes, int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes likes',
      one: '1 like',
    );
    String _temp1 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments reacties',
      one: '1 reactie',
    );
    String _temp2 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls walls',
      one: '1 wall',
    );
    return 'Nog $_temp0 en $_temp1 om $_temp2 te bereiken';
  }

  @override
  String blogTierNeedsLikes(int likes, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes likes',
      one: '1 like',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls walls',
      one: '1 wall',
    );
    return 'Nog $_temp0 om $_temp1 te bereiken';
  }

  @override
  String blogTierNeedsComments(int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments reacties',
      one: '1 reactie',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls walls',
      one: '1 wall',
    );
    return 'Nog $_temp0 om $_temp1 te bereiken';
  }

  @override
  String blogTierAlmostThere(int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: 'Bijna: hierna $walls walls',
      one: 'Bijna: hierna 1 wall',
    );
    return '$_temp0';
  }

  @override
  String blogOnWalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Op $count walls',
      one: 'Op 1 wall',
    );
    return '$_temp0';
  }

  @override
  String blogProgressToward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Voortgang naar $count walls',
      one: 'Voortgang naar 1 wall',
    );
    return '$_temp0';
  }

  @override
  String get blogReachIdle => 'Lezers kunnen dit hoofdstuk verder brengen';

  @override
  String get blogReachLive =>
      'Leden die van verhalen zoals het jouwe hielden, lezen het nu.';

  @override
  String get blogFeaturedStories => 'Uitgelichte verhalen';

  @override
  String get blogFeaturedCaption =>
      'Verhalen waar andere leden dol op waren, op je wall bezorgd.';

  @override
  String blogByAuthor(String name) {
    return 'door $name';
  }

  @override
  String get blogLikes => 'Likes';

  @override
  String get blogComments => 'Reacties';

  @override
  String get blogCommentHint => 'Wat is je bijgebleven?';

  @override
  String get blogCommentApproved =>
      'Goedgekeurd. Iedereen die dit hoofdstuk kan lezen, ziet hem nu.';

  @override
  String get blogCommentSent => 'Ter goedkeuring naar de auteur gestuurd';

  @override
  String get blogCommentSendFailed =>
      'Je reactie is niet verstuurd. Je woorden staan er nog, dus je kunt het opnieuw proberen.';

  @override
  String blogCommentDeclined(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Afgewezen. Hij verschijnt niet bij je foto.',
      'other': 'Afgewezen. Hij verschijnt niet bij je hoofdstuk.',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveFailed => 'Dat is niet opgeslagen. Probeer het opnieuw.';

  @override
  String get blogDeleteCommentTitle => 'Deze reactie verwijderen?';

  @override
  String get blogDeleteCommentMessage =>
      'Hij wordt voor iedereen verwijderd. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get blogDeleteComment => 'Reactie verwijderen';

  @override
  String get blogCommentDeleted => 'Reactie verwijderd.';

  @override
  String get blogCommentDeleteFailed =>
      'De reactie kon niet worden verwijderd. Probeer het opnieuw.';

  @override
  String get blogCommentsAuthorNote =>
      'Nieuwe reacties wachten op je goedkeuring voordat anderen ze zien.';

  @override
  String get blogCommentsReaderNote =>
      'De auteur leest elke reactie eerst en kiest wat er gedeeld wordt.';

  @override
  String get blogLeaveComment => 'Laat een reactie achter';

  @override
  String get blogSendToAuthor => 'Naar de auteur sturen';

  @override
  String get blogCommentsLoadFailed => 'Reacties konden niet worden geladen.';

  @override
  String get blogWaitingApproval => 'Wachten op je goedkeuring';

  @override
  String get blogNoCommentsInvite =>
      'Nog geen reacties. Zeg iets aardigs om het gesprek te beginnen.';

  @override
  String get blogNoCommentsShared => 'Nog geen reacties gedeeld.';

  @override
  String get blogCommentNotShared =>
      'De auteur heeft ervoor gekozen deze niet te delen.';

  @override
  String get blogYou => 'Jij';

  @override
  String get blogCommentOptions => 'Reactie-opties';

  @override
  String get blogReportComment => 'Reactie melden';

  @override
  String get blogApprove => 'Goedkeuren';

  @override
  String get blogDecline => 'Afwijzen';

  @override
  String get blogSignInContinue => 'Log in om verder te gaan.';

  @override
  String get blogPrivateResponseTitle => 'Een privéreactie';

  @override
  String blogPrivateResponseHelp(String invitation) {
    return '$invitation\n\nAlleen de auteur ontvangt deze reactie en kan een optionele uitwisseling accepteren of afwijzen. Maximaal vijf nieuwe reacties per dag, en één aan dezelfde auteur.';
  }

  @override
  String get blogSendPrivateResponse => 'Privéreactie versturen';

  @override
  String get blogTextSaveUnconfirmed =>
      'Opslaan kon niet worden bevestigd. Je woorden staan er nog; probeer het opnieuw of herlaad de opgeslagen uitwisseling.';

  @override
  String get blogLeaveUnsentTitle => 'Verlaten zonder te versturen?';

  @override
  String get blogLeaveUnsentMessage =>
      'Je niet-verstuurde woorden worden verwijderd.';

  @override
  String get blogLeave => 'Verlaten';

  @override
  String get blogOwnWordsLabel => 'In je eigen woorden';

  @override
  String get blogSending => 'Versturen…';

  @override
  String get blogChangeUnconfirmed =>
      'De wijziging kon niet worden bevestigd. Vernieuw om te controleren.';

  @override
  String get blogConnectionsTitle => 'Je hoofdstukconnecties';

  @override
  String get blogRefresh => 'Vernieuwen';

  @override
  String get blogConnectionsIntro =>
      'Goede verhalen laten ruimte voor iemand anders.';

  @override
  String get blogConnectionsLoadFailed =>
      'Je connecties konden niet worden geladen.';

  @override
  String get blogResponsesEmpty =>
      'Reacties op je hoofdstukken en reacties die jij stuurt, verschijnen hier. Niets hoeft direct beantwoord te worden.';

  @override
  String get blogPublicationsEmpty =>
      'Je openbare previews en samen goedgekeurde links verschijnen hier.';

  @override
  String get blogNoticesEmpty => 'Geen beoordelingsmeldingen.';

  @override
  String get blogResponseRevealed => 'Jullie gedeelde hoofdstuk is klaar';

  @override
  String get blogResponseIncoming => 'Een reactie voor jou';

  @override
  String get blogResponseSent => 'Verstuurd · hun keuze, hun tempo';

  @override
  String get blogResponseAccepted => 'Een uitwisseling, in jullie tempo';

  @override
  String get blogResponseClosed => 'Deze uitwisseling is gesloten';

  @override
  String get blogOpenExchange => 'Privé-uitwisseling openen';

  @override
  String get blogPublicationLive => 'Openbare versie actief';

  @override
  String get blogPublicationRemoved => 'Verwijderd door moderatie';

  @override
  String get blogPublicationNeedsBoth =>
      'Vereist beide goedkeuringen en een actueel bronhoofdstuk';

  @override
  String get blogPublicationSourceChanged =>
      'Bron gewijzigd · maak een nieuwe preview om opnieuw te delen';

  @override
  String get blogApprovePublicCopyTitle => 'Deze openbare versie goedkeuren?';

  @override
  String get blogApprovePublicCopyMessage =>
      'Precies de woorden hierboven zijn zichtbaar voor iedereen met de link. Jullie kunnen het delen allebei intrekken. Er worden geen namen automatisch toegevoegd, maar de woorden kunnen jou herkenbaar maken.';

  @override
  String get blogApprovePublicCopyAction => 'Openbare versie goedkeuren';

  @override
  String get blogApproveExactPublicCopy =>
      'Precies deze openbare versie goedkeuren';

  @override
  String get blogCopyLink => 'Link kopiëren';

  @override
  String get blogWithdrawLinkTitle => 'Deze link intrekken?';

  @override
  String get blogWithdrawLinkMessage =>
      'De openbare versie wordt onbeschikbaar. Kopieën die iemand anders al heeft opgeslagen, kunnen niet worden teruggehaald.';

  @override
  String get blogWithdrawLink => 'Link intrekken';

  @override
  String get blogYourAppeal => 'Je bezwaar';

  @override
  String get blogRequestReview => 'Nieuwe beoordeling aanvragen';

  @override
  String get blogRequestReviewHelp =>
      'Leg uit wat er heroverwogen moet worden. Je bezwaar gaat privé naar het trust-team. Verwijderde content blijft verborgen tijdens de beoordeling.';

  @override
  String get blogSubmitAppeal => 'Bezwaar indienen';

  @override
  String get blogAppealDecision => 'Bezwaar maken tegen deze beslissing';

  @override
  String get blogPrevious => 'Vorige';

  @override
  String get blogMore => 'Meer';

  @override
  String get blogExchangeChangeFailed =>
      'Deze wijziging kon niet worden bevestigd. Vernieuw en probeer het opnieuw.';

  @override
  String get blogExchangeTitle => 'Een privé-hoofdstukuitwisseling';

  @override
  String get blogExchangeUnavailable =>
      'Deze uitwisseling is niet meer beschikbaar.';

  @override
  String blogExchangeWith(String name) {
    return 'Met $name';
  }

  @override
  String get blogExchangeIntro =>
      'Een reactie is een uitnodiging, nooit een verplichting. Deze uitwisseling maakt geen match en ontgrendelt de chat niet.';

  @override
  String get blogAcceptExchange => 'Uitwisseling accepteren';

  @override
  String get blogDeclineKindly => 'Vriendelijk afwijzen';

  @override
  String get blogResponseSentNote =>
      'Je reactie is verstuurd. Er loopt geen klok en je hoeft niet na te vragen.';

  @override
  String get blogExchangeClosedNote =>
      'Deze uitwisseling is gesloten. Maak in je eigen tempo ruimte voor een nieuwe connectie.';

  @override
  String get blogOneStoryEach => 'Ieder één klein verhaal.';

  @override
  String get blogOneStoryEachBody =>
      'Voeg een klein vervolg, een herinnering of jouw versie van het moment toe. Beide bijdragen verschijnen samen, pas als jullie allebei iets hebben ingediend.';

  @override
  String get blogYourSideTitle => 'Jouw kant van het hoofdstuk';

  @override
  String get blogYourSideHelp =>
      'Deel maximaal 1000 tekens. Je partner kan dit pas lezen als die ook iets bijdraagt. Na het indienen kun je de woorden niet meer bewerken; je kunt de uitwisseling altijd intrekken.';

  @override
  String get blogSubmitContribution => 'Mijn bijdrage indienen';

  @override
  String get blogAddContribution => 'Mijn bijdrage toevoegen';

  @override
  String get blogYourContribution => 'Jouw bijdrage';

  @override
  String blogPartnerContribution(String name) {
    return 'Bijdrage van $name';
  }

  @override
  String get blogShapeDate => 'Samen een date vormgeven';

  @override
  String get blogInspiredNote =>
      'Geïnspireerd door onze hoofdstukuitwisseling.';

  @override
  String get blogTryStudio => 'Eerste Hoofdstuk Studio proberen';

  @override
  String get blogDatePlanningUnavailable =>
      'Een date plannen kan zodra jullie een actieve match hebben en jullie gesprek ontgrendeld is.';

  @override
  String get blogProposeJournalPage => 'Een gedeelde dagboekpagina voorstellen';

  @override
  String get blogSourceUnavailable => 'Het bronhoofdstuk is niet beschikbaar.';

  @override
  String get blogContributionSaved =>
      'Je bijdrage is privé opgeslagen. Hij wordt onthuld als jullie er allebei klaar voor zijn.';

  @override
  String get blogWithdrawExchangeTitle => 'Deze uitwisseling intrekken?';

  @override
  String get blogWithdrawExchangeMessage =>
      'De reactie en bijdragen zijn dan voor geen van jullie meer beschikbaar. Gezamenlijke openbare links werken ook niet meer.';

  @override
  String get blogWithdrawExchange => 'Uitwisseling intrekken';

  @override
  String get blogReportExchange => 'Uitwisseling melden';

  @override
  String get blogBlockMessageExchange =>
      'Contact en toegang tot elkaars hoofdstukken stoppen.';

  @override
  String get blogBlockFailed => 'Dit lid kon niet worden geblokkeerd.';

  @override
  String get notificationsReadAll => 'Alles gelezen';

  @override
  String get notificationsFallbackTitle => 'Melding';

  @override
  String get notificationsLoadFailed => 'Meldingen konden niet worden geladen.';

  @override
  String get notificationsPrefsUpdateFailed =>
      'Meldingsvoorkeuren konden niet worden bijgewerkt.';

  @override
  String notificationsAgoMinutes(int count) {
    return '$count min geleden';
  }

  @override
  String notificationsAgoHours(int count) {
    return '$count u geleden';
  }

  @override
  String notificationsAgoDays(int count) {
    return '$count d geleden';
  }

  @override
  String get wallsReactEyebrow => 'REAGEREN';

  @override
  String wallsReactQuestion(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Wat doet deze foto met je?',
      'other': 'Wat doet dit hoofdstuk met je?',
    });
    return '$_temp0';
  }

  @override
  String get wallsReactBody =>
      'Je reactie laat merken dat ze gehoord zijn. Elke reactie telt als een like.';

  @override
  String get wallsReactRemove => 'Mijn reactie intrekken';

  @override
  String wallsReactionsSemantics(String list) {
    return 'Reacties: $list';
  }

  @override
  String get wallsReactionLove => 'Prachtig';

  @override
  String get wallsReactionHearYou => 'Ik hoor je';

  @override
  String get wallsReactionMeToo => 'Ik ook';

  @override
  String get wallsReactionWithYou => 'Ik sta naast je';

  @override
  String get wallsReactionHug => 'Een dikke knuffel';

  @override
  String get wallsReactionProud => 'Trots op je';

  @override
  String get wallsSignInRequired => 'Log in om je muur te zien.';

  @override
  String get celebrationCoverHeadline => 'Jouw foto is de cover van de week';

  @override
  String celebrationReachHeadline(String kind, int reach) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'photo': 'Je foto heeft $reach muren bereikt',
      'other': 'Je hoofdstuk heeft $reach muren bereikt',
    });
    return '$_temp0';
  }

  @override
  String get celebrationCoverMessage =>
      'Leden vonden het geweldig. Deze week ziet iedereen het bij Vandaag.';

  @override
  String get celebrationReachMessage =>
      'Leden vonden het geweldig. Het staat nu op hun Vandaag-muren.';

  @override
  String celebrationQuotedTitle(String title) {
    return '‘$title’';
  }

  @override
  String get celebrationBarrier => 'Viering';

  @override
  String get celebrationLovely => 'Mooi';

  @override
  String get celebrationSeePhoto => 'Foto bekijken';

  @override
  String get celebrationSeeChapter => 'Hoofdstuk bekijken';

  @override
  String rewardXpPill(int xp) {
    return '+$xp XP';
  }

  @override
  String get rewardClaimedTitle => 'Beloning geclaimd';

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
    return 'en nog $count';
  }

  @override
  String rewardBadgeLine(String badge) {
    return 'Badge: $badge';
  }

  @override
  String rewardLevelReached(int level) {
    return 'Level $level bereikt';
  }

  @override
  String rewardBadgesEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count badges verdiend',
      one: 'Badge verdiend',
    );
    return '$_temp0';
  }

  @override
  String get rewardYourRewardsToday => 'Je beloningen vandaag';

  @override
  String rewardNewRewards(int count) {
    return '$count nieuwe beloningen';
  }

  @override
  String get rewardSourceStoryPublished => 'Hoofdstuk gepubliceerd';

  @override
  String get rewardSourcePhotoShared => 'Foto gedeeld';

  @override
  String get rewardSourceLikeReceived => 'Een lid vond je werk leuk';

  @override
  String get rewardSourceCommentReceived => 'Nieuwe reactie op je werk';

  @override
  String get rewardSourceCommentApproved => 'Je reactie is goedgekeurd';

  @override
  String get rewardSourceSubscriberGained => 'Nieuwe abonnee';

  @override
  String get rewardSourceWallTierReached => 'Muurniveau bereikt';

  @override
  String get rewardSourceCoverOfWeek => 'Cover van de week';

  @override
  String get rewardSourceDailyPromptSubmitted => 'Dagelijkse vraag beantwoord';

  @override
  String get rewardLineStoryPublished => 'Je hoofdstuk is de wereld in.';

  @override
  String get rewardLinePhotoShared => 'Je foto hoort nu bij het thema.';

  @override
  String get rewardLineLikeReceived => 'Iemand vond geweldig wat je deelde.';

  @override
  String get rewardLineCommentReceived => 'Een lezer doet mee aan het gesprek.';

  @override
  String get rewardLineSubscriberGained =>
      'Iemand wil je volgende hoofdstuk lezen.';

  @override
  String get rewardLineWallTierReached => 'Je werk heeft meer muren bereikt.';

  @override
  String get rewardLineCoverOfWeek =>
      'Deze week ziet iedereen het bij Vandaag.';

  @override
  String get rewardLineOther => 'Verdiend met waardevolle activiteit.';

  @override
  String get rewardNewBadgeFallback => 'Nieuwe badge';

  @override
  String get blockedUnknownUser => 'Onbekende gebruiker';

  @override
  String get themeTaglineBluerose =>
      'Middernachtfluweel, saffierblauwe rozen en een platina randje.';

  @override
  String get themeTaglineBluelotus =>
      'Maanverlicht water, saffierblauwe blaadjes en een gouden hart.';

  @override
  String discoverMessageLikeSent(String name) {
    return 'Love verstuurd naar $name. Jullie kunnen chatten zodra $name jou ook liket.';
  }

  @override
  String get notificationsDismissFailed =>
      'Kon die melding niet verwijderen. Probeer het opnieuw.';

  @override
  String get notificationsReadAllFailed =>
      'Kon niet alles als gelezen markeren. Probeer het opnieuw.';

  @override
  String get blogReportSubmitted => 'Melding verstuurd. Bedankt.';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String settingsSignedInAs(String username) {
    return 'Ingelogd als @$username';
  }

  @override
  String get settingsSignOut => 'Uitloggen';

  @override
  String get settingsSignOutSubtitle => 'Beëindig je sessie op dit apparaat';

  @override
  String get settingsSignOutAllTitle => 'Uitloggen op alle apparaten';

  @override
  String get settingsSignOutAllSubtitle =>
      'Beëindig elke sessie, op elke telefoon en in elke browser';

  @override
  String get settingsSignOutConfirmTitle => 'Uitloggen?';

  @override
  String get settingsSignOutConfirmBody =>
      'Je hebt je gebruikersnaam en wachtwoord nodig om op dit apparaat opnieuw in te loggen.';

  @override
  String get settingsSignOutAllConfirmTitle => 'Uitloggen op alle apparaten?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'Je sessie wordt beëindigd op elke telefoon, tablet en browser, ook op dit apparaat. Iedereen die elders op je account is ingelogd, wordt uitgelogd.';

  @override
  String get settingsSignOutAllConfirmAction => 'Overal uitloggen';

  @override
  String get settingsSignOutAllFailed =>
      'Je andere apparaten konden niet worden uitgelogd. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get supportPaymentHelpLink =>
      'Probleem met een betaling? Neem contact op met support';

  @override
  String get supportReportHelpLink =>
      'Meer hulp nodig? Neem contact op met support';

  @override
  String get supportSignedOutHelpLink =>
      'Ander probleem? Neem contact op met support';

  @override
  String get supportGuestSubtitle =>
      'Kun je niet inloggen of werkt er iets anders niet? Vertel ons wat er is gebeurd, dan antwoorden we per e-mail.';

  @override
  String get supportGuestEmailLabel => 'Je e-mailadres';

  @override
  String get supportGuestEmailHint => 'We antwoorden naar dit adres';

  @override
  String get supportGuestNameLabel => 'Je naam (optioneel)';

  @override
  String get supportGuestEmailInvalid =>
      'Vul een geldig e-mailadres in zodat we kunnen antwoorden.';

  @override
  String get supportGuestSentTitle => 'Verzoek verzonden';

  @override
  String supportGuestSentBody(String reference, String email) {
    return 'Bedankt. Je referentie is $reference. We antwoorden naar $email.';
  }

  @override
  String get supportGuestUnavailableBody =>
      'Supportverzoeken kunnen nu niet vanuit de app worden verstuurd. Mail voor iets dringends naar support@connect.example.';

  @override
  String get supportDraftRestored =>
      'We hebben je niet-verzonden verzoek bewaard.';

  @override
  String get supportDraftDiscard => 'Concept verwijderen';

  @override
  String get discoverActionUndo => 'Ongedaan maken';

  @override
  String get discoverActionLike => 'Leuk';

  @override
  String get discoverActionSuperLike => 'Superlike';

  @override
  String get navQaVerifyShortcut => 'Verifiëren';

  @override
  String get chatMessageDeletedPlaceholder => 'Bericht verwijderd';

  @override
  String get chatGiftYouSentHeading => 'Je hebt een cadeau gestuurd';

  @override
  String get commonMemberFallbackName => 'Een lid';

  @override
  String get giftNameRoseRedSingle => 'Eén rode roos';

  @override
  String get giftNameRosePinkSoft => 'Roze roos';

  @override
  String get giftNameRoseWhitePure => 'Witte roos';

  @override
  String get giftNameRoseYellowFriendship => 'Gele roos';

  @override
  String get giftNameRoseLavenderCrush => 'Lavendelroos';

  @override
  String get giftNameRoseBlueRare => 'Blauwe roos';

  @override
  String get giftNameRoseBlackMystery => 'Zwarte roos';

  @override
  String get giftNameRoseSparkle => 'Glitterroos';

  @override
  String get giftNameRoseHeartPetal => 'Roos met hartjesblaadjes';

  @override
  String get giftNameRoseNeonGlow => 'Neonroos';

  @override
  String get giftNameRoseRain => 'Rozenregen';

  @override
  String get giftNameRoseBurningFlame => 'Brandende roos';

  @override
  String get giftNameRoseGolden => 'Gouden roos';

  @override
  String get giftNameRoseCrystal => 'Kristallen roos';

  @override
  String get giftNameRoseBouquet12 => 'Rozenboeket (12)';

  @override
  String get giftNameRoseBouquet24 => 'Rozenboeket (24)';

  @override
  String get giftNameRoseSeasonalWeekly => 'Limited seizoensroos';

  @override
  String get giftNameChocolateBox => 'Doos bonbons';

  @override
  String get giftNameHeartBalloon => 'Hartjesballon';

  @override
  String get giftNameTeddyBear => 'Teddybeer';

  @override
  String get giftNameFlowerBouquet => 'Bloemenboeket';

  @override
  String get giftNameJewelleryBox => 'Juwelenkistje';

  @override
  String get giftNameChampagneToast => 'Proosten met champagne';

  @override
  String get giftNameHeartExplosion => 'Hartjesexplosie';

  @override
  String get giftNameConfettiShower => 'Confettiregen';

  @override
  String get giftNameFireworksBurst => 'Vuurwerk';

  @override
  String get giftNameStarShower => 'Sterrenregen';

  @override
  String get giftNameGoldenSparkle => 'Gouden glitter';

  @override
  String get giftNameRainbowWave => 'Regenbooggolf';

  @override
  String get giftNameCoffeeDateInvite => 'Uitnodiging voor koffie';

  @override
  String get giftNamePicnicInvite => 'Uitnodiging voor een picknick';

  @override
  String get giftNameMovieNightInvite => 'Uitnodiging voor een filmavond';

  @override
  String get giftNameSunsetWalkInvite =>
      'Uitnodiging voor een wandeling bij zonsondergang';

  @override
  String get giftNameDateNightCard => 'Kaart voor een dateavond';

  @override
  String get giftNameValentineSurprise => 'Valentijnsverrassing';

  @override
  String get giftNameDiamondRing => 'Diamanten ring';

  @override
  String get giftNameLuxuryDate => 'Luxe date';

  @override
  String get blogPublicationUnavailableTitle => 'Delen niet beschikbaar';

  @override
  String get blogPublicationUnavailableExcerpt =>
      'De bron is gewijzigd of de toegang is ingetrokken. Trek deze link in.';

  @override
  String get blogNoticeKindPost => 'Bericht';

  @override
  String get blogNoticeKindResponse => 'Antwoord';

  @override
  String get blogNoticeKindPublication => 'Openbare kopie';

  @override
  String get blogNoticeKindThemeEntry => 'Themafoto';

  @override
  String get blogNoticeKindClub => 'Club';

  @override
  String get blogNoticeKindClubPost => 'Clubbericht';

  @override
  String get blogNoticeKindReview => 'Recensie';

  @override
  String get blogNoticeKindList => 'Lijst';

  @override
  String get blogNoticeKindComment => 'Opmerking';

  @override
  String get blogNoticeKindPhotoComment => 'Opmerking bij foto';

  @override
  String get blogNoticeKindChatMessage => 'Chatbericht';

  @override
  String get blogNoticeKindGroup => 'Groep';

  @override
  String get blogNoticeKindOther => 'Inhoud';

  @override
  String get blogNoticeStatusPending => 'Wordt beoordeeld';

  @override
  String get blogNoticeStatusDismissed => 'Geen actie ondernomen';

  @override
  String get blogNoticeStatusRemoved => 'Verwijderd';

  @override
  String get blogNoticeStatusRestored => 'Hersteld';

  @override
  String get engagementTrustMilestoneProfileDepth => 'Profieldiepte';

  @override
  String get engagementTrustMilestoneCommunication => 'Communicatie';

  @override
  String get engagementTrustMilestoneConsistency => 'Consistentie';

  @override
  String get engagementTrustMilestonePromptCompletion => 'Beantwoorde vragen';

  @override
  String get engagementTrustMilestoneActivitySignals => 'Activiteitssignalen';

  @override
  String get engagementTrustMilestoneUnsafeSignals => 'Veiligheidsmeldingen';

  @override
  String get engagementTrustMilestoneReportPenalty => 'Aftrek door meldingen';

  @override
  String get engagementTrustMilestoneVerification => 'Verificatie klopt';

  @override
  String get engagementTrustMilestoneSafety => 'Veiligheid';

  @override
  String engagementTrustMilestoneLine(String label, String value) {
    return '$label: $value';
  }

  @override
  String get networkOfflineTryAgain =>
      'Er is nu geen verbinding. Controleer je internetverbinding en probeer het opnieuw.';

  @override
  String get apiErrorFeatureUnavailable =>
      'Deze functie is nu niet beschikbaar.';

  @override
  String get apiErrorConversationUnavailable =>
      'Dit gesprek is niet meer beschikbaar.';

  @override
  String get apiErrorMemberUnavailable => 'Dit lid is niet beschikbaar.';

  @override
  String get apiErrorChatLocked => 'Ontgrendel eerst dit gesprek.';

  @override
  String get apiErrorCopilotDailyLimit =>
      'Je hebt je concepten voor vandaag gebruikt. Schrijf deze zelf.';

  @override
  String get apiErrorCopilotUnavailable =>
      'Schrijfhulp is nu niet beschikbaar.';

  @override
  String get apiErrorCopilotProfileUnavailable =>
      'Het profiel is nu niet beschikbaar.';

  @override
  String get apiErrorDatePlanAlreadyOpen =>
      'Er staat al een dateplan open voor deze match.';

  @override
  String get apiErrorDatePlanMatchInactive =>
      'Dateplannen hebben een actieve match nodig.';

  @override
  String get apiErrorDatePlanNotOpen => 'Dit dateplan staat niet meer open.';

  @override
  String get apiErrorDatePlanCheckInTooEarly =>
      'Je kunt inchecken zodra het plan begint.';

  @override
  String get apiErrorDatePlanDebriefTooEarly =>
      'De nabespreking opent zodra het plan begint.';

  @override
  String get apiErrorSharedAvailabilityChanged =>
      'De gedeelde beschikbaarheid is veranderd. Vernieuw de voorgestelde tijden of kies zelf een tijd.';

  @override
  String get apiErrorGraduationAlreadyOpen =>
      'Er staat al een voorstel om samen verder te gaan open voor deze match.';

  @override
  String get apiErrorGraduationMatchInactive =>
      'Samen verder gaan kan alleen met een actieve match.';

  @override
  String get apiErrorGraduationNotOpen =>
      'Dit voorstel om samen verder te gaan staat niet meer open.';

  @override
  String get apiErrorGraduationAlreadyConfirmed =>
      'Jullie zijn al samen verdergegaan.';

  @override
  String get apiErrorOutOfDate =>
      'Deze weergave is verouderd. Vernieuw en probeer het opnieuw.';

  @override
  String get apiErrorOutcomeUncertain =>
      'We konden dat niet bevestigen. Vernieuw om het te controleren voordat je het opnieuw probeert.';

  @override
  String get apiErrorInsufficientCoins =>
      'Je hebt hier niet genoeg munten voor.';

  @override
  String get apiErrorChannelReadOnly => 'Deze chat is nu alleen-lezen.';

  @override
  String get apiErrorRoomFull =>
      'Deze ruimte is nu vol. Probeer het zo meteen opnieuw.';

  @override
  String get apiErrorRoomRemoved =>
      'Een host heeft je uit deze ruimte verwijderd. Je kunt weer meedoen als deze sessie voorbij is.';

  @override
  String get apiErrorRoomNotJoined => 'Je zit niet in deze ruimte.';

  @override
  String get apiErrorDailyMessageLimit =>
      'Je hebt je berichten voor vandaag gebruikt. Probeer het na de reset opnieuw of upgrade je abonnement.';

  @override
  String get apiErrorDailyLikeLimit =>
      'Je hebt je likes voor vandaag gebruikt. Probeer het na de reset opnieuw of upgrade je abonnement.';

  @override
  String get apiErrorFriendRequired => 'Jullie moeten eerst vrienden zijn.';

  @override
  String get apiErrorVouchExists =>
      'Je hebt al een aanbeveling voor deze persoon geschreven.';

  @override
  String get apiErrorIntroUnavailable => 'Deze intro is niet meer beschikbaar.';

  @override
  String get apiErrorIntroAlreadyOpen =>
      'Er staat al een intro voor deze twee open.';

  @override
  String get apiErrorIntroNotOpen => 'Deze intro staat niet meer open.';

  @override
  String get apiErrorTooManyTries =>
      'Te veel pogingen. Wacht even en probeer het opnieuw.';

  @override
  String get apiErrorQuestCooldown =>
      'Deze quest staat even op pauze. Probeer het wat later opnieuw.';

  @override
  String get apiErrorQuestSelfReview =>
      'Je match beoordeelt je antwoord op de quest, niet jij.';

  @override
  String get apiErrorQuestNotParticipant =>
      'Alleen de leden van deze match kunnen meedoen aan de quest.';

  @override
  String get apiErrorPaymentsUnavailable => 'Munten kopen is nu niet mogelijk.';

  @override
  String get apiErrorServiceBusy =>
      'De dienst is nu druk. Probeer het zo opnieuw.';

  @override
  String get apiErrorSignInAgain => 'Log opnieuw in om verder te gaan.';

  @override
  String get friendsMemberFallback => 'Een lid';

  @override
  String get friendsActivityFallback => 'Activiteit';

  @override
  String get membershipPlanFallback => 'Pakket';

  @override
  String get membershipSubscriptionFallback => 'Abonnement';

  @override
  String engagementLevelRewardFallback(int level) {
    return 'Beloning voor level $level';
  }

  @override
  String get engagementTrustBadgeUnknown => 'Onbekende badge';

  @override
  String get firstChapterComfortDefaultLanguage => 'Nederlands';

  @override
  String paymentWalletBalanceCoins(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString munten',
      one: '1 munt',
    );
    return '$_temp0';
  }

  @override
  String get languageIntroSignedOut =>
      'Kies de taal van Connect. Die geldt meteen en wordt bij het inloggen in je account opgeslagen.';

  @override
  String languagePickerButtonSemantics(String language) {
    return 'Taal: $language. Taal wijzigen';
  }

  @override
  String get authErrorUsernameTaken =>
      'Die gebruikersnaam is al bezet. Probeer een andere.';

  @override
  String get authErrorAccountSuspended =>
      'Dit account is geschorst. Neem contact op met support als je denkt dat dit een vergissing is.';

  @override
  String get authErrorAccountLocked =>
      'Te veel inlogpogingen. Probeer het over een paar minuten opnieuw.';

  @override
  String get authErrorTooManyRequests =>
      'Te veel pogingen. Wacht even en probeer het opnieuw.';

  @override
  String get authErrorAccountTypeUnavailable =>
      'Dit soort account is nu niet beschikbaar.';

  @override
  String get authErrorNetwork =>
      'Er is nu geen verbinding. Controleer je internetverbinding en probeer het opnieuw.';

  @override
  String get profileSetupReorderPhoto => 'Sleep om deze foto te verplaatsen';

  @override
  String get profileLanguageAssamese => 'Assamees';

  @override
  String get profileLanguageBengali => 'Bengaals';

  @override
  String get profileLanguageBodo => 'Bodo';

  @override
  String get profileLanguageDogri => 'Dogri';

  @override
  String get profileLanguageEnglish => 'Engels';

  @override
  String get profileLanguageGujarati => 'Gujarati';

  @override
  String get profileLanguageHindi => 'Hindi';

  @override
  String get profileLanguageKannada => 'Kannada';

  @override
  String get profileLanguageKashmiri => 'Kasjmiri';

  @override
  String get profileLanguageKonkani => 'Konkani';

  @override
  String get profileLanguageMaithili => 'Maithili';

  @override
  String get profileLanguageMalayalam => 'Malayalam';

  @override
  String get profileLanguageManipuri => 'Manipuri';

  @override
  String get profileLanguageMarathi => 'Marathi';

  @override
  String get profileLanguageNepali => 'Nepalees';

  @override
  String get profileLanguageOdia => 'Odia';

  @override
  String get profileLanguagePunjabi => 'Punjabi';

  @override
  String get profileLanguageSanskrit => 'Sanskriet';

  @override
  String get profileLanguageSantali => 'Santali';

  @override
  String get profileLanguageSindhi => 'Sindhi';

  @override
  String get profileLanguageTamil => 'Tamil';

  @override
  String get profileLanguageTelugu => 'Telugu';

  @override
  String get profileLanguageUrdu => 'Urdu';

  @override
  String get profileCountryIndia => 'India';

  @override
  String get profileCountryUnitedKingdom => 'Verenigd Koninkrijk';

  @override
  String get profileCountryIreland => 'Ierland';

  @override
  String get profileCountryGermany => 'Duitsland';

  @override
  String get profileCountryAustria => 'Oostenrijk';

  @override
  String get profileMasterWorkoutSometimes => 'Soms';

  @override
  String get profileMasterWorkoutWeekly => 'Wekelijks';

  @override
  String get profileMasterTravelRoadTrips => 'Roadtrips';

  @override
  String get profileMasterTravelBackpacking => 'Backpacken';

  @override
  String get profileMasterTravelLuxuryShort => 'Luxe';

  @override
  String get profileMasterTravelStaycations => 'Vakantie thuis';

  @override
  String get profileMasterPoliticsSimilarShort => 'Vergelijkbaar';

  @override
  String get profileMasterPoliticsModerate => 'Gematigd';

  @override
  String get profileMasterPoliticsAny => 'Maakt niet uit';
}
