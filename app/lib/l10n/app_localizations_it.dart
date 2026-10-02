// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get navDiscover => 'Scopri';

  @override
  String get navMatches => 'Match';

  @override
  String get navEngage => 'Partecipa';

  @override
  String get navProfile => 'Profilo';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsSectionProfile => 'Profilo';

  @override
  String get settingsEditProfileTitle => 'Modifica profilo';

  @override
  String get settingsEditProfileSubtitle => 'Aggiorna le tue informazioni';

  @override
  String get settingsPhotosTitle => 'Foto';

  @override
  String get settingsPhotosSubtitle => 'Gestisci le tue foto';

  @override
  String get settingsSectionPreferences => 'Preferenze';

  @override
  String get settingsAppearanceTitle => 'Aspetto';

  @override
  String get settingsAppearanceSubtitle => 'Salvato nel tuo account';

  @override
  String get settingsThemeLight => 'Chiaro';

  @override
  String get settingsThemeDark => 'Scuro';

  @override
  String get settingsThemeMatchDevice => 'Come il dispositivo';

  @override
  String get settingsLooksTitle => 'Stili';

  @override
  String get settingsLooksClassicDescription =>
      'Warm ivory and forest by day. Soft mint and deep forest by night.';

  @override
  String get settingsLooksClassicLabel => 'Today';

  @override
  String get settingsThemeSaveFailed => 'Impossibile salvare il tema. Riprova.';

  @override
  String get settingsLanguageTitle => 'Lingua';

  @override
  String get settingsLanguageSubtitle => 'Scegli la lingua dell\'app';

  @override
  String get settingsDatingPreferencesTitle => 'Preferenze di incontro';

  @override
  String get settingsDatingPreferencesSubtitle => 'Età, luogo, interessi';

  @override
  String get settingsAccountDataTitle => 'Account e dati';

  @override
  String get settingsAccountDataSubtitle =>
      'Nascondi, scarica o elimina il tuo account';

  @override
  String get settingsNotificationsTitle => 'Notifiche';

  @override
  String get settingsNotificationsSubtitle => 'Notifiche push ed e-mail';

  @override
  String get settingsSectionEngagement => 'Partecipa';

  @override
  String get settingsTrustBadgesTitle => 'Badge di fiducia';

  @override
  String get settingsTrustBadgesSubtitle =>
      'Guarda i badge ottenuti e la cronologia della fiducia';

  @override
  String get settingsTrustFiltersTitle => 'Filtri di fiducia';

  @override
  String get settingsTrustFiltersSubtitle =>
      'Imposta i requisiti di fiducia per la scoperta';

  @override
  String get settingsConversationRoomsTitle => 'Stanze di conversazione';

  @override
  String get settingsConversationRoomsSubtitle =>
      'Sfoglia, entra, esci e modera le stanze';

  @override
  String get settingsFriendsTitle => 'Amici e contatti';

  @override
  String get settingsFriendsSubtitle => 'Crea e coltiva le tue amicizie';

  @override
  String get settingsCallHistoryTitle => 'Cronologia chiamate';

  @override
  String get settingsCallHistorySubtitle => 'Rivedi le chiamate passate';

  @override
  String get settingsMatchNudgesTitle => 'Spintarelle ai match';

  @override
  String get settingsMatchNudgesSubtitle =>
      'Riaccendi le conversazioni silenziose';

  @override
  String get settingsSubscriptionsTitle => 'Abbonamenti';

  @override
  String get settingsSubscriptionsSubtitle =>
      'Piani, stato di accesso e pagamenti';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsPrivacySafetyTitle => 'Privacy e sicurezza';

  @override
  String get settingsPrivacySafetySubtitle =>
      'Gestisci le tue impostazioni sulla privacy';

  @override
  String get settingsGovernmentVerificationTitle => 'Verifica del documento';

  @override
  String get settingsGovernmentVerificationSubtitle =>
      'Vedi lo stato della verifica dell\'identità';

  @override
  String get settingsQaVerificationUploadTitle => 'Caricamento verifica QA';

  @override
  String get settingsQaVerificationUploadSubtitle =>
      'Flusso documento e selfie solo per l\'automazione';

  @override
  String get settingsHelpSupportTitle => 'Aiuto e supporto';

  @override
  String get settingsHelpSupportSubtitle => 'FAQ e contatto con il supporto';

  @override
  String get settingsAboutTitle => 'Informazioni';

  @override
  String get settingsAboutSubtitle => 'Dettagli sull\'app e tecnologia';

  @override
  String get settingsLogout => 'Esci';

  @override
  String get languageTitle => 'Lingua';

  @override
  String get languageIntro =>
      'Scegli la lingua in cui usare Connect. La tua scelta viene salvata nel tuo account e vale su ogni dispositivo in cui accedi.';

  @override
  String get languageUseDevice => 'Usa la lingua del dispositivo';

  @override
  String get languageUseDeviceSubtitle =>
      'Segue l\'impostazione della lingua del tuo telefono';

  @override
  String get languageSaveFailed => 'Impossibile salvare la lingua. Riprova.';

  @override
  String get notificationsTitle => 'Notifiche';

  @override
  String get notificationsInboxTitle => 'Notifiche ricevute';

  @override
  String get notificationsInboxCaughtUp => 'Sei in pari';

  @override
  String notificationsInboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count da leggere',
      one: '1 da leggere',
    );
    return '$_temp0';
  }

  @override
  String get notificationsInAppTitle => 'Notifiche nell\'app';

  @override
  String get notificationsInAppSubtitle =>
      'Mostra le notifiche mentre usi l\'app';

  @override
  String get notificationsPushTitle => 'Notifiche push';

  @override
  String get notificationsPushSubtitle =>
      'Consenti la consegna quando l\'app è in background';

  @override
  String get notificationsNewMatchesTitle => 'Nuovi match';

  @override
  String get notificationsNewMatchesSubtitle =>
      'Ricevi un avviso quando fai match';

  @override
  String get notificationsNewMessagesTitle => 'Nuovi messaggi';

  @override
  String get notificationsNewMessagesSubtitle =>
      'Ricevi un avviso per i messaggi in chat';

  @override
  String get notificationsLikesTitle => 'Mi piace';

  @override
  String get notificationsLikesSubtitle =>
      'Ricevi un avviso quando qualcuno ti mette mi piace';

  @override
  String get notificationsMatchNudgesTitle => 'Spintarelle dai match';

  @override
  String get notificationsMatchNudgesSubtitle =>
      'Ricevi un avviso quando un match ti dà una spintarella';

  @override
  String get notificationsIncomingCallsTitle => 'Chiamate in arrivo';

  @override
  String get notificationsIncomingCallsSubtitle =>
      'Mostra gli avvisi delle chiamate in arrivo';

  @override
  String get notificationsSafetyTitle => 'Aggiornamenti sulla sicurezza';

  @override
  String get notificationsSafetySubtitle =>
      'Ricevi aggiornamenti importanti sul tuo stato di sicurezza';

  @override
  String get notificationsFriendPlansTitle => 'Appuntamenti degli amici';

  @override
  String get notificationsFriendPlansSubtitle =>
      'Scopri quando un amico organizza un appuntamento o fa sapere che sta bene';

  @override
  String get welcomeTagline => 'Fatto per la vita vera.';

  @override
  String get welcomePhotoNote => 'L\'obiettivo è vedersi dal vivo.';

  @override
  String get welcomeHeadlineLead => 'Una bella storia\ninizia con un ';

  @override
  String get welcomeHeadlineAccent => 'ciao.';

  @override
  String get welcomeBody =>
      'Trova qualcuno che senti davvero affine. Il resto viene da sé.';

  @override
  String get welcomeCreateAccount => 'Crea un account';

  @override
  String get welcomeAlreadyMember => 'Hai già un account? ';

  @override
  String get welcomeSignIn => 'Accedi';

  @override
  String get welcomeFooter => '18+  ·  Il tuo ritmo. La tua scelta.';

  @override
  String get authBackTooltip => 'Torna all\'inizio';

  @override
  String get authHeadline => 'Che bello rivederti.';

  @override
  String get authSubtitle =>
      'Usa il tuo nome utente e la password per continuare';

  @override
  String get authWelcomeBack => 'Che bello riaverti qui';

  @override
  String get authNextHello => 'Il tuo prossimo ciao ti aspetta.';

  @override
  String get authUsernameHint => 'nome utente';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authShowPassword => 'Mostra password';

  @override
  String get authHidePassword => 'Nascondi password';

  @override
  String get authCantSignIn => 'Non riesci ad accedere?';

  @override
  String get authSignIn => 'Accedi';

  @override
  String get authPrivacyNote =>
      'La password viene inviata solo quando accedi e non viene mai salvata nell\'app.';

  @override
  String get authEnterUsername => 'Inserisci il tuo nome utente.';

  @override
  String get authEnterPassword => 'Inserisci la tua password.';

  @override
  String get commonYes => 'Sì';

  @override
  String get commonNo => 'No';

  @override
  String get planVenueCoffee => 'Un caffè';

  @override
  String get planVenueMeal => 'Un pasto';

  @override
  String get planVenueDrinks => 'Un drink';

  @override
  String get planVenueWalk => 'Una passeggiata';

  @override
  String get planVenueActivity => 'Un\'attività';

  @override
  String get planVenueEvent => 'Un evento';

  @override
  String get planVenueVideoCall => 'Videochiamata';

  @override
  String get planVenueOther => 'Qualcos\'altro';

  @override
  String planProposeTitle(String name) {
    return 'Organizza un appuntamento con $name';
  }

  @override
  String get planProposeSubtitle =>
      'Shape a first hello together. Contact sharing starts off.';

  @override
  String get planProposeButton => 'Proponi';

  @override
  String planHeadlineProposed(String name) {
    return '$name ti ha proposto un appuntamento';
  }

  @override
  String planHeadlineWaiting(String name) {
    return 'In attesa di $name';
  }

  @override
  String get planHeadlineUpcoming => 'È un appuntamento';

  @override
  String get planHeadlineCheckin => 'Com\'è andata?';

  @override
  String get planHeadlineDebrief => 'Com\'è stato?';

  @override
  String get planHeadlineDebriefComplete => 'Resoconto completato';

  @override
  String planHeadlineWaitingDebrief(String name) {
    return 'In attesa del resoconto di $name';
  }

  @override
  String get planHeadlineCheckedInSafe => 'Hai fatto sapere che stai bene';

  @override
  String get planHeadlineFriendsAlerted => 'Your request for help is recorded';

  @override
  String get planHeadlineDefault => 'Appuntamento';

  @override
  String get planStatusProposed => 'Proposto';

  @override
  String get planStatusConfirmed => 'Confermato';

  @override
  String get planDebriefButton => 'Resoconto in dieci secondi';

  @override
  String get planDecline => 'Rifiuta';

  @override
  String get planAccept => 'Accetta';

  @override
  String get planFriendsKnowAccepted =>
      'Choose trusted contacts to share your updates.';

  @override
  String get planFriendsKnowProposed =>
      'Contact sharing is optional for each plan.';

  @override
  String get planCancel => 'Annulla l\'appuntamento';

  @override
  String get planNeedHelp => 'Ho bisogno di aiuto';

  @override
  String get planImSafe => 'Sto bene';

  @override
  String get planCancelDialogTitle => 'Annullare questo appuntamento?';

  @override
  String planCancelDialogBody(String name) {
    return '$name e tutte le persone con cui l\'hai condiviso saranno avvisate.';
  }

  @override
  String get planKeepIt => 'Tienilo';

  @override
  String get planProposeIntro =>
      'This starts between you and your date. After proposing, choose trusted contacts if you want to share plan and check-in updates.';

  @override
  String get planSectionWhen => 'Quando';

  @override
  String get planSectionWhat => 'Cosa';

  @override
  String get planSectionGroups => 'Trusted contacts';

  @override
  String planDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String get planPlaceLabel => 'Luogo (facoltativo)';

  @override
  String get planPlaceHint => 'Meglio un posto pubblico';

  @override
  String get planAreaLabel => 'Zona o quartiere';

  @override
  String get planNoteLabel => 'Un messaggio per l\'altra persona (facoltativo)';

  @override
  String get planFutureTimeError => 'Scegli un orario futuro.';

  @override
  String get planProposeFailed => 'Impossibile proporre questo appuntamento.';

  @override
  String get planSendButton => 'Invia la proposta';

  @override
  String get planAcceptTitle => 'Accettare l\'appuntamento?';

  @override
  String get planAcceptIntro =>
      'Accept this plan with your date. Choose trusted contacts afterwards if you want to share your updates.';

  @override
  String get planAcceptButton => 'Accept plan';

  @override
  String debriefTitle(String name) {
    return 'Com\'è andata con $name?';
  }

  @override
  String get debriefIntro =>
      'Le tue risposte sono private. Quando entrambi confermate che l\'appuntamento c\'è stato, conta per il tuo badge Shows Up.';

  @override
  String get debriefHappened => 'L\'appuntamento c\'è stato?';

  @override
  String get debriefMeetAgain => 'Ti rivedresti con questa persona?';

  @override
  String get debriefFeltSafe => 'Ti sei sentito/a al sicuro?';

  @override
  String get debriefNoteLabel => 'Vuoi aggiungere qualcosa? (facoltativo)';

  @override
  String get debriefMissingHappened => 'Dicci se l\'appuntamento c\'è stato.';

  @override
  String get debriefSaveFailed => 'Impossibile salvare il resoconto.';

  @override
  String get debriefSave => 'Salva resoconto';

  @override
  String get debriefUnsafeTitle =>
      'Ci dispiace che tu non ti sia sentito/a al sicuro';

  @override
  String debriefUnsafeBody(String name) {
    return 'La tua risposta viene registrata per il nostro team sicurezza. Vuoi anche segnalare $name?';
  }

  @override
  String get debriefNotNow => 'Non ora';

  @override
  String get debriefReport => 'Segnala';

  @override
  String get plansTitle => 'Appuntamenti';

  @override
  String get plansTabMine => 'Miei';

  @override
  String get plansTabFriends => 'Amici';

  @override
  String get plansEmptyMineTitle => 'Ancora nessun appuntamento';

  @override
  String get plansEmptyMineBody =>
      'Propose a date from a conversation. You choose whether to share plan and check-in updates with trusted contacts.';

  @override
  String plansWith(String name) {
    return 'Con $name';
  }

  @override
  String get plansNextDecide => 'In attesa della tua risposta';

  @override
  String plansNextAwait(String name) {
    return 'In attesa di $name';
  }

  @override
  String get plansNextUpcoming => 'Confirmed. Your time together is planned.';

  @override
  String get plansNextCheckin => 'Check in after your date';

  @override
  String get plansNextDebrief => 'Raccontaci com\'è andata';

  @override
  String get plansNextCancelled => 'Annullato';

  @override
  String get plansNextDone => 'Fatto';

  @override
  String get plansEmptyFriendsTitle => 'Ancora niente di condiviso';

  @override
  String get plansEmptyFriendsBody =>
      'Plans appear here when friends explicitly choose to share with you.';

  @override
  String get plansViaGroup => 'Shared with you';

  @override
  String get plansViaFriend => 'Trusted contact';

  @override
  String plansFriendNeedsHelp(String name) {
    return '$name ha chiesto aiuto. Fatti sentire subito.';
  }

  @override
  String plansFriendMissedCheckin(String name) {
    return '$name non ha ancora fatto sapere come sta.';
  }

  @override
  String plansFriendCheckedInSafe(String name, String via) {
    return '$name ha fatto sapere che sta bene · $via';
  }

  @override
  String plansFriendStatusLine(String via, String status) {
    return '$via · $status';
  }

  @override
  String get plansStatusWordProposed => 'proposto';

  @override
  String get plansStatusWordConfirmed => 'confermato';

  @override
  String get plansStatusWordCancelled => 'annullato';

  @override
  String get plansStatusWordHappened => 'avvenuto';

  @override
  String get chatEmptyDefault =>
      'Saluta. I messaggi compaiono qui per tutte le persone della conversazione.';

  @override
  String get chatNotSentRetry =>
      'Non inviato. Tocca il messaggio per riprovare.';

  @override
  String get chatRetrySend => 'Riprova a inviare';

  @override
  String get chatCopyText => 'Copia testo';

  @override
  String get chatDeleteMine => 'Elimina il mio messaggio';

  @override
  String get chatRemoveMessage => 'Rimuovi messaggio';

  @override
  String get chatReportMessage => 'Segnala messaggio';

  @override
  String get chatThisMember => 'Questo membro';

  @override
  String get chatMember => 'Membro';

  @override
  String get chatCopied => 'Copiato.';

  @override
  String get chatDeleteFailed => 'Impossibile eliminare. Riprova.';

  @override
  String get chatSubtitleFriends => 'Amici';

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membri',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String get chatReconnecting =>
      'Riconnessione in corso. I nuovi messaggi potrebbero tardare un po’.';

  @override
  String get chatUnavailable =>
      'Questa conversazione non è disponibile. Forse non ne fai più parte.';

  @override
  String get chatTryAgain => 'Riprova';

  @override
  String get chatStatusNotSent => 'Non inviato · tieni premuto per riprovare';

  @override
  String get chatStatusSending => 'Invio…';

  @override
  String get chatMessageRemoved => 'Messaggio rimosso';

  @override
  String chatSemanticsYouAt(String time) {
    return 'Tu alle $time';
  }

  @override
  String chatSemanticsMemberAt(String name, String time) {
    return '$name alle $time';
  }

  @override
  String chatAboutMember(String name) {
    return 'Su $name';
  }

  @override
  String get chatComposerHint => 'Scrivi un messaggio';

  @override
  String get chatMutedComposerHint => 'Al momento non puoi scrivere';

  @override
  String get chatSend => 'Invia';

  @override
  String chatRoomMutedUntil(String when) {
    return 'Sei in silenzio in questa stanza fino alle $when. Puoi continuare a leggere.';
  }

  @override
  String get chatRoomMuted =>
      'Sei in silenzio in questa stanza. Puoi continuare a leggere.';

  @override
  String chatReadOnlyUntil(String when) {
    return 'Puoi leggere questa conversazione, ma non scrivere fino alle $when.';
  }

  @override
  String get chatReadOnly =>
      'Puoi leggere questa conversazione, ma al momento non puoi scrivere.';

  @override
  String get chatMuteTooltip => 'Silenzia notifiche';

  @override
  String get chatMutedTooltip => 'Notifiche silenziate';

  @override
  String get chatMuteSheetTitle => 'Silenzia notifiche';

  @override
  String get chatMuteSheetBody =>
      'I messaggi continuano ad arrivare qui, solo senza notifiche.';

  @override
  String get chatMuteOneHour => 'Per 1 ora';

  @override
  String get chatMuteEightHours => 'Per 8 ore';

  @override
  String get chatMuteOneWeek => 'Per 1 settimana';

  @override
  String get chatMuteForever => 'Finché non le riattivo';

  @override
  String get chatUnmute => 'Riattiva le notifiche';

  @override
  String chatMutedUntilLabel(String when) {
    return 'Silenziate fino alle $when';
  }

  @override
  String get chatMutedIndefinitely =>
      'Silenziate finché non riattivi le notifiche.';

  @override
  String get chatMuteDone => 'Notifiche silenziate.';

  @override
  String get chatUnmuteDone => 'Le notifiche sono di nuovo attive.';

  @override
  String get chatMuteFailed => 'Impossibile modificare le notifiche. Riprova.';

  @override
  String get roomsClosedSnack => 'Questa stanza è chiusa.';

  @override
  String get roomsChatNotOpen =>
      'La chat di questa stanza non è ancora aperta.';

  @override
  String get roomsJoinFailed =>
      'Impossibile entrare in questa stanza. Riprova.';

  @override
  String get roomsStartRoom => 'Apri una stanza';

  @override
  String get roomsEyebrow => 'CHAT DAL VIVO';

  @override
  String get roomsTitle => 'Stanze';

  @override
  String get roomsSubtitle =>
      'Entra in una conversazione. Se scatta la scintilla con qualcuno, aggiungilo agli amici.';

  @override
  String get roomsSectionRooms => 'STANZE';

  @override
  String get roomsSectionYours => 'LE TUE STANZE';

  @override
  String get roomsYoursCaption =>
      'Le stanze in cui sei. Tocca per riprendere la chat.';

  @override
  String get roomsSectionLive => 'IN DIRETTA ORA';

  @override
  String get roomsLiveTitle => 'Dove si sta chiacchierando';

  @override
  String get roomsSectionBrowse => 'SFOGLIA';

  @override
  String get roomsBrowseTitle => 'Trova la tua stanza';

  @override
  String get roomsBrowseCaption =>
      'Sempre aperte. Scegli un argomento, saluta e scopri con chi c’è intesa.';

  @override
  String get roomsNoFriendsHere =>
      'Al momento nessuno dei tuoi amici è in una di queste stanze.';

  @override
  String get roomsNoRoomsInTopic =>
      'Ancora nessuna stanza su questo argomento.';

  @override
  String get roomsSectionComingUp => 'IN ARRIVO';

  @override
  String get roomsComingUpCaption =>
      'Stanze organizzate dai membri. Entra presto per tenerti il posto.';

  @override
  String get roomsCategoryAll => 'Tutte';

  @override
  String get roomsCategoryTalk => 'Chiacchiere';

  @override
  String get roomsCategoryInterests => 'Interessi';

  @override
  String get roomsCategoryActive => 'In giro';

  @override
  String get roomsCategoryCity => 'La tua città';

  @override
  String get roomsFriendsHereChip => 'Amici presenti';

  @override
  String get roomsQuiet => 'Al momento è tutto tranquillo. Saluta per primo.';

  @override
  String roomsPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persone',
      one: '1 persona',
    );
    return '$_temp0';
  }

  @override
  String roomsRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stanze',
      one: '1 stanza',
    );
    return '$_temp0';
  }

  @override
  String roomsChattingIn(String people, String rooms) {
    return '$people in chat in $rooms';
  }

  @override
  String roomsHereNow(int count) {
    return '$count presenti ora';
  }

  @override
  String roomsInTheRoom(int count) {
    return '$count nella stanza';
  }

  @override
  String roomsFriendsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amici presenti',
      one: '1 amico presente',
    );
    return '$_temp0';
  }

  @override
  String get roomsHostedByYou => 'Organizzata da te';

  @override
  String roomsHostedBy(String name) {
    return 'Organizzata da $name';
  }

  @override
  String get roomsActionOpen => 'Apri';

  @override
  String get roomsActionFull => 'Piena';

  @override
  String get roomsActionJoin => 'Entra';

  @override
  String roomsStartsAt(String time) {
    return 'Inizia alle $time';
  }

  @override
  String roomsStartsOn(String day, String time) {
    return 'Inizia il $day alle $time';
  }

  @override
  String get roomsStartNameTooShort =>
      'Dai alla stanza un nome di almeno 3 lettere.';

  @override
  String get roomsStartIntro =>
      'La organizzi tu: puoi avvisare, silenziare o rimuovere persone e chiuderla quando hai finito. Una stanza alla volta.';

  @override
  String get roomsStartNameLabel => 'Nome della stanza';

  @override
  String get roomsStartNameHint => 'Scambio di libri della domenica';

  @override
  String get roomsStartAboutLabel => 'Di cosa si parla? (facoltativo)';

  @override
  String get roomsStartTopic => 'Argomento';

  @override
  String get roomsStartHowLong => 'Durata';

  @override
  String get roomsLength30Min => '30 min';

  @override
  String get roomsLength1Hour => '1 ora';

  @override
  String get roomsLength2Hours => '2 ore';

  @override
  String get roomsStartNow => 'Inizia ora';

  @override
  String get roomsRoleHost => 'Host';

  @override
  String get roomsRoleModerator => 'Moderatore';

  @override
  String get roomsRoomFallback => 'Stanza';

  @override
  String roomsChatEmpty(String room) {
    return 'Ci sei. Saluta: tutti in $room vedono quello che scrivi qui.';
  }

  @override
  String get roomsPeopleTooltip => 'Persone in questa stanza';

  @override
  String roomsLeaveTitle(String room) {
    return 'Uscire da $room?';
  }

  @override
  String get roomsLeaveBody =>
      'Non vedrai più i messaggi di questa stanza. Puoi tornare quando vuoi finché è aperta.';

  @override
  String get roomsLeaveAction => 'Esci dalla stanza';

  @override
  String get roomsLeaveFailed => 'Impossibile uscire. Riprova.';

  @override
  String roomsCloseTitle(String room) {
    return 'Chiudere $room?';
  }

  @override
  String get roomsCloseBody =>
      'La chat finisce per tutti nella stanza. Non si può annullare.';

  @override
  String get roomsCloseAction => 'Chiudi la stanza';

  @override
  String get roomsCloseFailed => 'Impossibile chiudere. Riprova.';

  @override
  String get roomsMenuTooltip => 'Opzioni stanza';

  @override
  String get roomsMenuPeople => 'Chi c’è';

  @override
  String get roomsMenuModerate => 'Modera';

  @override
  String roomsModerateTitle(String room) {
    return 'Modera $room';
  }

  @override
  String get roomsModerateIntro =>
      'Tocca qualcuno per avvisarlo, silenziarlo o rimuoverlo. Chi è silenziato può continuare a leggere; chi è rimosso può rientrare a fine sessione.';

  @override
  String get roomsPeopleIntro =>
      'C’è intesa con qualcuno? Aggiungilo agli amici per continuare a parlare dopo la stanza.';

  @override
  String get roomsMembersLoadFailed => 'Impossibile caricare chi c’è.';

  @override
  String get roomsStatusFriend => 'Amico';

  @override
  String get roomsStatusHereNow => 'Presente ora';

  @override
  String get roomsStatusInRoom => 'Nella stanza';

  @override
  String get roomsStatusGone => 'Non è più nella stanza';

  @override
  String roomsStatusMutedUntil(String time) {
    return 'Silenziato fino alle $time';
  }

  @override
  String roomsYouSuffix(String name) {
    return '$name (tu)';
  }

  @override
  String roomsRemoveTitle(String name) {
    return 'Rimuovere $name dalla stanza?';
  }

  @override
  String roomsRemoveBodyAlwaysOn(String name) {
    return '$name lascia subito la chat e potrà tornare dopo 24 ore.';
  }

  @override
  String roomsRemoveBodyHosted(String name) {
    return '$name lascia subito la chat e non potrà rientrare finché la stanza non finisce.';
  }

  @override
  String roomsWarnTitle(String name) {
    return 'Avvisare $name?';
  }

  @override
  String roomsWarnBody(String name) {
    return '$name riceve un promemoria privato per mantenere la conversazione gentile e in tema.';
  }

  @override
  String get roomsRemoveAction => 'Rimuovi';

  @override
  String get roomsWarnAction => 'Invia avviso';

  @override
  String roomsRemovedDone(String name) {
    return '$name è stato rimosso dalla stanza.';
  }

  @override
  String roomsWarnedDone(String name) {
    return 'Avviso inviato a $name.';
  }

  @override
  String get roomsModerationFailed => 'Non è andato a buon fine. Riprova.';

  @override
  String roomsBlockedDone(String name) {
    return 'Hai bloccato $name. Qui non vedrete più i messaggi l’uno dell’altro.';
  }

  @override
  String get roomsReport => 'Segnala';

  @override
  String get roomsBlock => 'Blocca';

  @override
  String get roomsModerateEyebrow => 'MODERA';

  @override
  String get roomsWarn => 'Avvisa';

  @override
  String get roomsRemoveFromRoom => 'Rimuovi dalla stanza';

  @override
  String get roomsMute => 'Silenzia';

  @override
  String get roomsUnmute => 'Riattiva';

  @override
  String roomsMuteSheetTitle(String name) {
    return 'Silenziare $name?';
  }

  @override
  String roomsMuteSheetBody(String name) {
    return '$name può continuare a leggere la chat ma non scrivere finché il silenzio non finisce. Riceverà una nota privata.';
  }

  @override
  String get roomsMuteTenMinutes => 'Per 10 minuti';

  @override
  String get roomsMuteOneHour => 'Per 1 ora';

  @override
  String get roomsMuteUntilEnd => 'Fino alla fine della stanza';

  @override
  String get roomsMuteOneDay => 'Per 24 ore';

  @override
  String roomsMutedDone(String name) {
    return '$name è silenziato.';
  }

  @override
  String roomsUnmutedDone(String name) {
    return '$name può di nuovo scrivere.';
  }

  @override
  String get richFormattingToolbar => 'Formattazione';

  @override
  String get richUndo => 'Annulla';

  @override
  String get richRedo => 'Ripeti';

  @override
  String get richBold => 'Grassetto';

  @override
  String get richItalic => 'Corsivo';

  @override
  String get richUnderline => 'Sottolineato';

  @override
  String get richStrikethrough => 'Barrato';

  @override
  String get richHighlight => 'Evidenzia';

  @override
  String get richLink => 'Link';

  @override
  String get richTextStyleMenu => 'Stile del testo';

  @override
  String get richParagraph => 'Paragrafo';

  @override
  String get richHeading => 'Titolo';

  @override
  String get richSubheading => 'Sottotitolo';

  @override
  String get richQuote => 'Citazione';

  @override
  String get richCallout => 'Riquadro';

  @override
  String get richBulletList => 'Elenco puntato';

  @override
  String get richNumberedList => 'Elenco numerato';

  @override
  String get richDivider => 'Separatore';

  @override
  String get richAlignMenu => 'Allineamento';

  @override
  String get richAlignStart => 'Allinea all\'inizio';

  @override
  String get richAlignCenter => 'Centra';

  @override
  String get richAlignEnd => 'Allinea alla fine';

  @override
  String get richClearFormatting => 'Cancella formattazione';

  @override
  String get richWritingStyle => 'Stile di scrittura';

  @override
  String get richStyleClassic => 'Classico';

  @override
  String get richStyleClassicHint => 'Serif elegante, come una pagina stampata';

  @override
  String get richStyleModern => 'Moderno';

  @override
  String get richStyleModernHint => 'Pulito e facile da leggere';

  @override
  String get richStyleJournal => 'Diario';

  @override
  String get richStyleJournalHint => 'Corsivo caldo, come una pagina di diario';

  @override
  String get richStyleTypewriter => 'Macchina da scrivere';

  @override
  String get richStyleTypewriterHint => 'Lettere squadrate e spaziate';

  @override
  String get richStylePoetic => 'Poetico';

  @override
  String get richStylePoeticHint => 'Righe centrate e ariose';

  @override
  String richWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parole',
      one: '1 parola',
    );
    return '$_temp0';
  }

  @override
  String get richAlignmentNote =>
      'Allineamento e spaziatura si vedono nell\'anteprima e da chi legge.';

  @override
  String get richLinkTitle => 'Aggiungi un link';

  @override
  String get richLinkField => 'Indirizzo web';

  @override
  String get richLinkInvalid => 'Usa un indirizzo https:// completo.';

  @override
  String get richLinkApply => 'Aggiungi link';

  @override
  String get richLinkRemove => 'Rimuovi link';

  @override
  String get richLinkNeedsSelection =>
      'Prima seleziona le parole da collegare.';

  @override
  String get richCancel => 'Annulla';

  @override
  String get richOpenLinkTitle => 'Aprire questo link?';

  @override
  String richOpenLinkBody(String host) {
    return '$host si apre fuori da Connect. Apri solo link di cui ti fidi.';
  }

  @override
  String get richOpenLink => 'Apri link';

  @override
  String get supportCentreEyebrow => 'AIUTO E SUPPORTO';

  @override
  String get supportCentreTitle => 'Come possiamo aiutarti?';

  @override
  String get supportCentreSubtitle =>
      'Trova una risposta rapida o chiedi al nostro team. Ogni richiesta e risposta resta in una conversazione privata.';

  @override
  String get supportContactSection => 'CONTATTACI';

  @override
  String get supportContactTitle => 'Contatta il supporto';

  @override
  String get supportContactSubtitle =>
      'Raccontaci cosa è successo. Rispondiamo qui e ti avvisiamo.';

  @override
  String get supportMyTicketsTitle => 'Le mie richieste';

  @override
  String get supportMyTicketsSubtitle =>
      'Segui le tue richieste e le nostre risposte';

  @override
  String supportOpenRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count richieste aperte',
      one: '1 richiesta aperta',
    );
    return '$_temp0';
  }

  @override
  String supportUnreadReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuove risposte',
      one: '1 nuova risposta',
    );
    return '$_temp0';
  }

  @override
  String get supportQuickAnswersSection => 'RISPOSTE RAPIDE';

  @override
  String get supportFaqLoginTitle => 'Accesso';

  @override
  String get supportFaqLoginBody =>
      'Accedi con il tuo nome utente univoco e la password.';

  @override
  String get supportFaqVerificationTitle => 'Verifica';

  @override
  String get supportFaqVerificationBody =>
      'La verifica dell’identità è facoltativa finché il fornitore è in pausa.';

  @override
  String get supportFaqAbuseTitle => 'Abusi';

  @override
  String get supportFaqAbuseBody =>
      'Usa Segnala su un profilo o una conversazione per una verifica di sicurezza più rapida.';

  @override
  String get supportFaqBillingTitle => 'Fatturazione';

  @override
  String get supportFaqBillingBody =>
      'Indica il riferimento della transazione, mai i dati della tua carta.';

  @override
  String get supportEmergencyNote =>
      'Se qualcuno è in pericolo immediato, contatta i servizi di emergenza locali. Le richieste di supporto non sostituiscono l’aiuto di emergenza.';

  @override
  String get supportUnavailableTitle =>
      'Le richieste di supporto non sono disponibili al momento';

  @override
  String get supportUnavailableBody =>
      'Le risposte di questa pagina restano disponibili. Per qualcosa di urgente, scrivi a support@connect.example.';

  @override
  String get supportBackToHelp => 'Torna ad Aiuto e supporto';

  @override
  String get supportFormEyebrow => 'NUOVA RICHIESTA';

  @override
  String get supportFormTitle => 'Contatta il supporto';

  @override
  String get supportFormSubtitle =>
      'Dacci abbastanza dettagli per intervenire. Non includere mai password, codici di recupero, numeri di carta o documenti d’identità.';

  @override
  String get supportFormCategorySection => 'ARGOMENTO';

  @override
  String get supportFormCategoryLabel => 'Per cosa ti serve aiuto?';

  @override
  String get supportCategoryAccountLogin => 'Account e accesso';

  @override
  String get supportCategoryVerification => 'Verifica';

  @override
  String get supportCategoryPaymentsBilling => 'Pagamenti e fatturazione';

  @override
  String get supportCategorySafetyHarassment => 'Sicurezza e molestie';

  @override
  String get supportCategoryMatchesChat => 'Match e chat';

  @override
  String get supportCategoryTechnical => 'Problema tecnico o bug';

  @override
  String get supportCategoryFeatureRequest => 'Richiesta di funzionalità';

  @override
  String get supportCategoryPrivacyData => 'Privacy e dati';

  @override
  String get supportCategoryOther => 'Altro';

  @override
  String get supportSafetyNote =>
      'Se tu o qualcun altro siete in pericolo immediato, usa SOS nell’app o chiama i servizi di emergenza locali. Le richieste sulla sicurezza hanno la priorità, ma una richiesta non è una linea di emergenza.';

  @override
  String get supportOpenSos => 'Apri SOS';

  @override
  String get supportFormDetailsSection => 'DETTAGLI';

  @override
  String get supportFormSubjectLabel => 'Oggetto';

  @override
  String get supportFormSubjectHint => 'Descrivi brevemente il problema';

  @override
  String get supportFormDescriptionLabel => 'Cosa è successo?';

  @override
  String get supportFormDescriptionHint =>
      'Cosa hai fatto, cosa ti aspettavi e cosa è successo invece';

  @override
  String get supportFormScreenshotsSection => 'SCREENSHOT';

  @override
  String supportFormScreenshotsCaption(int max) {
    return 'Facoltativo. Fino a $max immagini.';
  }

  @override
  String get supportAddScreenshot => 'Aggiungi screenshot';

  @override
  String supportRemoveAttachment(String name) {
    return 'Rimuovi $name';
  }

  @override
  String get supportAttachmentUploading => 'Caricamento';

  @override
  String get supportRetryUpload => 'Riprova il caricamento';

  @override
  String supportFormDeviceNote(String version) {
    return 'Includeremo la versione dell’app ($version), la piattaforma, la versione del sistema e la lingua per aiutarci a risolvere il problema.';
  }

  @override
  String get supportSubmit => 'Invia richiesta';

  @override
  String get supportErrorCategoryRequired => 'Scegli un argomento.';

  @override
  String supportErrorSubjectLength(int min, int max) {
    return 'L’oggetto deve avere da $min a $max caratteri.';
  }

  @override
  String get supportErrorDescriptionRequired => 'Descrivi cosa è successo.';

  @override
  String supportErrorDescriptionTooLong(int max) {
    return 'Resta sotto i $max caratteri.';
  }

  @override
  String get supportErrorUploadsPending =>
      'Attendi il termine del caricamento degli screenshot o rimuovi quelli non riusciti.';

  @override
  String supportCreatedSnack(String reference) {
    return 'Richiesta $reference inviata. Ti risponderemo qui.';
  }

  @override
  String supportDuplicateSnack(String reference) {
    return 'Hai già inviato questa richiesta, quindi l’abbiamo aperta: $reference.';
  }

  @override
  String supportErrorRateLimited(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Hai inviato diverse richieste in poco tempo. Riprova tra $minutes minuti.',
      one: 'Hai inviato diverse richieste in poco tempo. Riprova tra 1 minuto.',
    );
    return '$_temp0';
  }

  @override
  String get supportErrorRateLimitedGeneric =>
      'Hai inviato diverse richieste in poco tempo. Riprova più tardi.';

  @override
  String get supportErrorTooManyOpen =>
      'Hai già 10 richieste aperte. Chiudine una che non ti serve più o attendi le nostre risposte.';

  @override
  String get supportErrorTicketClosed =>
      'Questa richiesta è chiusa e non può più essere riaperta. Apri una nuova richiesta.';

  @override
  String get supportErrorReopenWindowPassed =>
      'Il tempo per riaprire questa richiesta è scaduto. Apri una nuova richiesta.';

  @override
  String get supportErrorAlreadyRated => 'Hai già valutato questa richiesta.';

  @override
  String get supportErrorNotResolved =>
      'Potrai valutare la richiesta una volta risolta.';

  @override
  String get supportErrorAttachmentType =>
      'Puoi allegare solo immagini JPEG o PNG e file PDF.';

  @override
  String get supportErrorAttachmentTooLarge =>
      'Il file è troppo grande. Le immagini possono arrivare a 8 MB.';

  @override
  String get supportErrorOffline =>
      'Impossibile raggiungere Connect al momento. Controlla la connessione e riprova.';

  @override
  String get supportErrorNotFound => 'Non abbiamo trovato questa richiesta.';

  @override
  String get supportErrorGeneric => 'Qualcosa è andato storto. Riprova.';

  @override
  String get supportTryAgain => 'Riprova';

  @override
  String get supportTicketsEyebrow => 'SUPPORTO';

  @override
  String get supportTicketsTitle => 'Le mie richieste';

  @override
  String get supportTicketsSubtitle => 'Le tue richieste e le nostre risposte.';

  @override
  String get supportTicketsActiveSection => 'ATTIVE';

  @override
  String get supportTicketsClosedSection => 'RISOLTE E CHIUSE';

  @override
  String get supportTicketsEmptyTitle => 'Ancora nessuna richiesta';

  @override
  String get supportTicketsEmptyBody =>
      'Quando contatti il supporto, la tua richiesta e le nostre risposte compaiono qui.';

  @override
  String get supportTicketsLoadErrorTitle =>
      'Impossibile caricare le tue richieste';

  @override
  String supportTicketUpdated(String when) {
    return 'Aggiornata $when';
  }

  @override
  String get supportNewTicket => 'Nuova richiesta';

  @override
  String get supportStatusOpen => 'Aperta';

  @override
  String get supportStatusWaitingForYou => 'In attesa di te';

  @override
  String get supportStatusOnHold => 'In pausa';

  @override
  String get supportStatusResolved => 'Risolta';

  @override
  String get supportStatusClosed => 'Chiusa';

  @override
  String supportStatusSemantics(String status) {
    return 'Stato: $status';
  }

  @override
  String get supportThreadAgentName => 'Supporto Connect';

  @override
  String get supportThreadYou => 'Tu';

  @override
  String supportTicketMeta(String category, String date) {
    return '$category · Aperta il $date';
  }

  @override
  String get supportBannerOpen =>
      'Abbiamo ricevuto la tua richiesta. Il nostro team risponderà qui e ti avviserà.';

  @override
  String get supportBannerWaiting =>
      'Il supporto ha risposto e attende un tuo riscontro.';

  @override
  String get supportBannerOnHold =>
      'La tua richiesta è in pausa mentre la esaminiamo. Ti aggiorneremo qui.';

  @override
  String get supportBannerResolved =>
      'Segnata come risolta. Rispondi per riaprirla; altrimenti si chiuderà automaticamente dopo 7 giorni.';

  @override
  String supportBannerClosedUntil(String date) {
    return 'Questa richiesta è chiusa. Puoi riaprirla fino al $date.';
  }

  @override
  String get supportBannerClosed => 'Questa richiesta è chiusa.';

  @override
  String supportBannerMerged(String reference) {
    return 'Questa richiesta è stata unita a $reference. La conversazione continua lì.';
  }

  @override
  String get supportReplyHint => 'Scrivi una risposta';

  @override
  String get supportReplyDisabledHint =>
      'Non è più possibile rispondere a questa richiesta';

  @override
  String get supportSendReply => 'Invia risposta';

  @override
  String get supportAttachScreenshot => 'Allega screenshot';

  @override
  String get supportCloseTicket => 'Chiudi richiesta';

  @override
  String get supportCloseConfirmTitle => 'Chiudere questa richiesta?';

  @override
  String get supportCloseConfirmBody =>
      'Chiudila se il problema è risolto. Potrai riaprirla per 14 giorni.';

  @override
  String get supportCancel => 'Annulla';

  @override
  String get supportClosedSnack => 'Richiesta chiusa.';

  @override
  String get supportReopen => 'Riapri richiesta';

  @override
  String get supportReopenedSnack => 'Richiesta riaperta.';

  @override
  String get supportRateTitle => 'Come ci siamo comportati?';

  @override
  String get supportRateCaption =>
      'Valuta la tua esperienza con questa richiesta.';

  @override
  String supportRateStar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stelle',
      one: '1 stella',
    );
    return '$_temp0';
  }

  @override
  String get supportRateCommentLabel => 'Qualcosa da aggiungere? (facoltativo)';

  @override
  String get supportRateSubmit => 'Invia valutazione';

  @override
  String get supportRatedTitle => 'Grazie per il tuo feedback';

  @override
  String supportRatedValue(int rating) {
    return 'Hai dato $rating su 5.';
  }

  @override
  String get supportRatingSnack =>
      'Grazie per aver valutato la tua esperienza.';

  @override
  String supportAttachmentImage(String name) {
    return 'Screenshot $name';
  }

  @override
  String get supportAttachmentLoadFailed => 'Impossibile caricare l’allegato';

  @override
  String get supportThreadLoadErrorTitle =>
      'Impossibile caricare questa richiesta';

  @override
  String get chemistryCardEntry => 'Un po’ di chimica?';

  @override
  String get memberProfileIntroducing => 'Ti presentiamo';

  @override
  String get memberProfileStarring => 'Protagonista';

  @override
  String get memberProfileVerified => 'Verificato';

  @override
  String memberProfilePhotoLabel(String name, int index, int count) {
    return '$name, foto $index di $count';
  }

  @override
  String get memberProfileNoPhoto => 'Ancora nessuna foto';

  @override
  String get memberProfileViewPhotoHint => 'vedere a schermo intero';

  @override
  String get memberProfileCloseGallery => 'Chiudi foto';

  @override
  String get memberProfilePhotos => 'Foto';

  @override
  String memberProfileMorePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'altre $count foto',
      one: '1 altra foto',
    );
    return '$_temp0';
  }

  @override
  String get memberProfileSceneAbout => 'Su di me';

  @override
  String get memberProfileSceneStories => 'Storie';

  @override
  String get memberProfileSceneStoriesTitle => 'Un po\' più di me';

  @override
  String get memberProfileSceneInterests => 'Interessi';

  @override
  String get memberProfileSceneBasics => 'In breve';

  @override
  String get memberProfileSceneLifestyle => 'Stile di vita';

  @override
  String get memberProfileSceneTrust => 'Fiducia';

  @override
  String get memberProfileReadMore => 'Leggi di più';

  @override
  String get memberProfileReadLess => 'Mostra meno';

  @override
  String get memberProfileHobbies => 'Hobby';

  @override
  String get memberProfileActivities => 'Attività';

  @override
  String get memberProfileSongs => 'In ripetizione';

  @override
  String get memberProfileBooks => 'Libri e romanzi';

  @override
  String get memberProfileLookingFor => 'Cerca';

  @override
  String get memberProfileLanguages => 'Lingue';

  @override
  String get memberProfileDealBreakers => 'Non negoziabili';

  @override
  String get memberProfileInCommon => 'In comune';

  @override
  String get memberProfileFactHeight => 'Altezza';

  @override
  String memberProfileHeightCm(int cm) {
    return '$cm cm';
  }

  @override
  String get memberProfileFactWork => 'Lavoro';

  @override
  String get memberProfileFactEducation => 'Istruzione';

  @override
  String get memberProfileFactLivesIn => 'Vive a';

  @override
  String get memberProfileFactMotherTongue => 'Lingua madre';

  @override
  String get memberProfileFactReligion => 'Religione';

  @override
  String get memberProfileFactPersonality => 'Personalità';

  @override
  String get memberProfileFactRelationship => 'Situazione sentimentale';

  @override
  String get memberProfileFactInstagram => 'Instagram';

  @override
  String get memberProfileFactDrinking => 'Alcol';

  @override
  String get memberProfileFactSmoking => 'Fumo';

  @override
  String get memberProfileFactWorkout => 'Allenamento';

  @override
  String get memberProfileFactDiet => 'Dieta';

  @override
  String get memberProfileFactDietType => 'Tipo di dieta';

  @override
  String get memberProfileFactSleep => 'Sonno';

  @override
  String get memberProfileFactTravel => 'Viaggi';

  @override
  String get memberProfileFactPets => 'Animali';

  @override
  String get memberProfileFactPolitics => 'Politica';

  @override
  String get memberProfileFactOpenToCasual => 'Aperto a storie leggere';

  @override
  String get memberProfileFactPartyLover => 'Ama le feste';

  @override
  String get memberProfileVerifiedTitle => 'Profilo verificato';

  @override
  String get memberProfileVerifiedBody => 'Verifica dell’identità completata.';

  @override
  String get memberProfileVouchesTitle => 'Garantito dagli amici';

  @override
  String get memberProfileSpotlight => 'In evidenza';

  @override
  String get memberProfileFreeWhenYouAre => 'Libero quando lo sei tu';

  @override
  String get memberProfileMessage => 'Messaggio';

  @override
  String get memberProfileLove => 'Adoro';

  @override
  String get memberProfileReport => 'Segnala';

  @override
  String get memberProfileOwnerTitle => 'Ecco come ti vedono';

  @override
  String get memberProfileOwnerCaption =>
      'Gli altri membri vedono il tuo profilo proprio così.';

  @override
  String memberProfileCompleteness(int percent) {
    return 'Profilo completo al $percent%';
  }

  @override
  String get memberProfileCompletenessHint =>
      'Aggiungi foto, storie e dettagli per farti notare.';

  @override
  String get memberProfileCompletenessDone => 'Il tuo profilo è completo.';

  @override
  String get memberProfileToolEdit => 'Modifica profilo';

  @override
  String get memberProfileToolPhotos => 'Modifica foto';

  @override
  String get memberProfileToolStories => 'Le tue storie';

  @override
  String get memberProfileToolViewers => 'Chi ti ha visto';

  @override
  String get memberProfileBehindTheScenes => 'Dietro le quinte';

  @override
  String get memberProfileOnlyYou => 'Solo tu puoi vederlo.';

  @override
  String get memberProfileMine => 'Il mio profilo';

  @override
  String get profileShowcaseLabel => 'Scritti e momenti';

  @override
  String get profileShowcaseTitleOther => 'Con parole sue';

  @override
  String get profileShowcaseTitleSelf => 'I tuoi scritti e foto pubblici';

  @override
  String get profileShowcaseChapters => 'Capitoli';

  @override
  String get profileShowcasePhotos => 'Foto della bacheca';

  @override
  String get profileShowcaseReadAll => 'Leggi tutti i suoi capitoli';

  @override
  String get profileShowcaseHiddenTitle => 'Solo tu puoi vederlo';

  @override
  String get profileShowcaseHiddenBody =>
      'I tuoi capitoli pubblici e le foto della bacheca sono nascosti dal profilo. Attiva questa opzione perché i membri li vedano qui.';

  @override
  String get profileShowcaseShownBody =>
      'I membri possono vederli sul tuo profilo. Compaiono solo i capitoli condivisi con la community e le foto della bacheca.';

  @override
  String get profileShowcaseSwitch => 'Mostra sul mio profilo';

  @override
  String get profileShowcaseSaveFailed =>
      'Non è stato possibile salvare la tua scelta.';
}
