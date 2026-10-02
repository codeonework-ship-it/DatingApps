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
      'Warm ivory and forest by day. Soft mint and deep forest by night.';

  @override
  String get settingsLooksClassicLabel => 'Today';

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
      'Shape a first hello together. Contact sharing starts off.';

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
  String get planHeadlineFriendsAlerted => 'Your request for help is recorded';

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
      'Choose trusted contacts to share your updates.';

  @override
  String get planFriendsKnowProposed =>
      'Contact sharing is optional for each plan.';

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
      'This starts between you and your date. After proposing, choose trusted contacts if you want to share plan and check-in updates.';

  @override
  String get planSectionWhen => 'Wanneer';

  @override
  String get planSectionWhat => 'Wat';

  @override
  String get planSectionGroups => 'Trusted contacts';

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
      'Accept this plan with your date. Choose trusted contacts afterwards if you want to share your updates.';

  @override
  String get planAcceptButton => 'Accept plan';

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
      'Propose a date from a conversation. You choose whether to share plan and check-in updates with trusted contacts.';

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
  String get plansNextUpcoming => 'Confirmed. Your time together is planned.';

  @override
  String get plansNextCheckin => 'Check in after your date';

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
      'Plans appear here when friends explicitly choose to share with you.';

  @override
  String get plansViaGroup => 'Shared with you';

  @override
  String get plansViaFriend => 'Trusted contact';

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
}
