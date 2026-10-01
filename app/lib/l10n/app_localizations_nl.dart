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
}
