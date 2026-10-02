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
      'Date forma insieme a un primo saluto. La condivisione con i contatti parte disattivata.';

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
  String get planHeadlineFriendsAlerted =>
      'La tua richiesta di aiuto è stata registrata';

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
      'Scegli i contatti fidati con cui condividere i tuoi aggiornamenti.';

  @override
  String get planFriendsKnowProposed =>
      'La condivisione con i contatti è facoltativa per ogni piano.';

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
      'Resta tra te e il tuo appuntamento. Dopo la proposta, scegli contatti fidati se vuoi condividere gli aggiornamenti sul piano e sul check-in.';

  @override
  String get planSectionWhen => 'Quando';

  @override
  String get planSectionWhat => 'Cosa';

  @override
  String get planSectionGroups => 'Contatti fidati';

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
      'Accetta questo piano con il tuo appuntamento. Poi scegli i contatti fidati se vuoi condividere i tuoi aggiornamenti.';

  @override
  String get planAcceptButton => 'Accetta il piano';

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
      'Proponi un appuntamento da una conversazione. Scegli tu se condividere gli aggiornamenti su piano e check-in con i contatti fidati.';

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
  String get plansNextUpcoming =>
      'Confermato. Il vostro tempo insieme è organizzato.';

  @override
  String get plansNextCheckin => 'Fai il check-in dopo l’appuntamento';

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
      'I piani compaiono qui quando gli amici scelgono esplicitamente di condividerli con te.';

  @override
  String get plansViaGroup => 'Condiviso con te';

  @override
  String get plansViaFriend => 'Contatto fidato';

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

  @override
  String get callsHistoryTitle => 'Cronologia chiamate';

  @override
  String get callsHistoryEmpty => 'Ancora nessuna chiamata.';

  @override
  String callsHistoryMatch(String id) {
    return 'Match $id';
  }

  @override
  String get callsJoinLiveRoom => 'Entra nella stanza live';

  @override
  String get callsActiveSession => 'Chiamata in corso';

  @override
  String callsEndedWithDuration(String duration) {
    return 'Terminata · $duration';
  }

  @override
  String get callsSessionTitle => 'Chiamata';

  @override
  String get callsStarting => 'Avvio della sessione sicura…';

  @override
  String get callsSessionActive => 'Chiamata attiva';

  @override
  String get callsSessionUnavailable => 'Chiamata non disponibile';

  @override
  String get callsLiveRoomNote =>
      'La stanza live si apre in una finestra sicura del fornitore. Durante la chiamata usa lì i controlli per microfono, fotocamera e uscita.';

  @override
  String get callsEnd => 'Chiudi';

  @override
  String get callsErrorSignInHistory =>
      'Accedi per vedere la cronologia delle chiamate.';

  @override
  String get callsErrorSignInStart => 'Accedi prima di avviare una chiamata.';

  @override
  String get callsErrorPermissions =>
      'Per le chiamate servono i permessi per fotocamera e microfono.';

  @override
  String get callsErrorLoadHistory =>
      'Impossibile caricare la cronologia delle chiamate.';

  @override
  String get callsErrorStart => 'Impossibile avviare la chiamata.';

  @override
  String get callsErrorEnd => 'Impossibile terminare la chiamata.';

  @override
  String get callsErrorNotConfigured =>
      'Le stanze per le chiamate live non sono configurate in questo ambiente.';

  @override
  String get callsErrorOpenRoom =>
      'Impossibile aprire la stanza della chiamata live.';

  @override
  String get commonRetry => 'Riprova';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonCopy => 'Copia';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonBack => 'Indietro';

  @override
  String get commonApply => 'Applica';

  @override
  String get commonReset => 'Reimposta';

  @override
  String get commonOpen => 'Apri';

  @override
  String get commonView => 'Vedi';

  @override
  String get commonDismiss => 'Ignora';

  @override
  String get commonAny => 'Qualsiasi';

  @override
  String get commonSomethingWentWrong => 'Qualcosa è andato storto';

  @override
  String get commonSomethingWentWrongTryAgain =>
      'Qualcosa è andato storto. Riprova.';

  @override
  String get commonTryAgainTitle => 'Riprova';

  @override
  String get commonNothingHereYet => 'Ancora niente qui';

  @override
  String commonLoadingLabel(String label) {
    return '$label, caricamento';
  }

  @override
  String commonDistanceKm(int distance) {
    return '$distance km';
  }

  @override
  String get navToday => 'Oggi';

  @override
  String get navOfflineBanner =>
      'Modalità offline: alcuni dati potrebbero non essere aggiornati.';

  @override
  String navWeakNetworkBanner(int mbps) {
    return 'Rete debole rilevata. Usa almeno $mbps Mbps per un’app più fluida.';
  }

  @override
  String get navIncomingCallTitle => 'Chiamata in arrivo';

  @override
  String get navIncomingCallBody => 'Un match ti sta chiamando.';

  @override
  String get navViewCallDetails => 'Vedi dettagli chiamata';

  @override
  String get filterSheetTitle => 'Filtra i match';

  @override
  String get filterAgeRange => 'Fascia d’età';

  @override
  String get filterProfileLifestyle => 'Filtri profilo e stile di vita';

  @override
  String get filterCountry => 'Paese';

  @override
  String get filterState => 'Stato/regione';

  @override
  String get filterCity => 'Città';

  @override
  String get filterMotherTongue => 'Lingua madre';

  @override
  String get filterReligion => 'Religione';

  @override
  String get filterRelationshipStatus => 'Stato sentimentale';

  @override
  String get filterSmoking => 'Fumo';

  @override
  String get filterDrinking => 'Alcol';

  @override
  String get filterPersonalityType => 'Tipo di personalità';

  @override
  String get filterPartyLoverOnly => 'Solo amanti delle feste';

  @override
  String get filterHookupsOnly => 'Solo avventure';

  @override
  String get filterAdvancedBio => 'Filtri bio avanzati';

  @override
  String get filterAdvancedBioBody =>
      'Libri, romanzi, canzoni, hobby, posizione e attività extra si gestiscono in Impostazioni → Preferenze di incontro.';

  @override
  String get filterOpenDatingPreferences => 'Apri preferenze di incontro';

  @override
  String get filterDistanceKm => 'Distanza (km)';

  @override
  String get filterVerifiedOnlyTitle => 'Solo verificati';

  @override
  String get filterVerifiedOnlyBody => 'Mostra solo profili verificati';

  @override
  String get filterVerifiedOnlyChip => 'Solo verificati';

  @override
  String get filterPartyLoverChip => 'Amante delle feste';

  @override
  String get filterHookupChip => 'Solo avventure';

  @override
  String get filterEnableTrust => 'Attiva il filtro di fiducia';

  @override
  String filterMinimumTrustBadges(int count) {
    return 'Badge di fiducia attivi minimi: $count';
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
      'true': ', solo verificati',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(trust, {
      'true': ', filtro fiducia attivo',
      'other': ', filtro fiducia disattivato',
    });
    return 'Filtri salvati: $minAge-$maxAge anni, $distance km$_temp0$_temp1';
  }

  @override
  String get optionNever => 'Mai';

  @override
  String get optionOccasionally => 'Occasionalmente';

  @override
  String get optionSocially => 'In compagnia';

  @override
  String get optionRegularly => 'Regolarmente';

  @override
  String get optionSingle => 'Single';

  @override
  String get optionDivorced => 'Divorziato/a';

  @override
  String get optionWidowed => 'Vedovo/a';

  @override
  String get optionSeparated => 'Separato/a';

  @override
  String get optionComplicated => 'È complicato';

  @override
  String get optionIntrovert => 'Introverso/a';

  @override
  String get optionAmbivert => 'Ambiverso/a';

  @override
  String get optionExtrovert => 'Estroverso/a';

  @override
  String get optionHighSchool => 'Diploma';

  @override
  String get optionBachelors => 'Laurea triennale';

  @override
  String get optionMasters => 'Laurea magistrale';

  @override
  String get optionPhd => 'Dottorato';

  @override
  String get optionOther => 'Altro';

  @override
  String get optionPreferNotToSay => 'Preferisco non dirlo';

  @override
  String get optionHindu => 'Induista';

  @override
  String get optionMuslim => 'Musulmano/a';

  @override
  String get optionChristian => 'Cristiano/a';

  @override
  String get optionSikh => 'Sikh';

  @override
  String get optionBuddhist => 'Buddista';

  @override
  String get optionJain => 'Giainista';

  @override
  String get optionJewish => 'Ebreo/a';

  @override
  String get optionSpiritual => 'Spirituale';

  @override
  String get optionAgnostic => 'Agnostico/a';

  @override
  String get optionAtheist => 'Ateo/a';

  @override
  String get storiesNudgeTitle => 'Racconta un po’ di più della tua storia';

  @override
  String get storiesNudgeBodyUnknown =>
      'Brevi storie sul tuo profilo danno alle persone qualcosa di vero per salutarti.';

  @override
  String get storiesNudgeActionOpen => 'Apri le tue storie';

  @override
  String get storiesNudgeBodyEmpty =>
      'Aggiungi una breve storia al tuo profilo: una piccola gioia, un weekend da raccontare. Le persone le leggono prima di salutarti.';

  @override
  String get storiesNudgeActionFirst => 'Scrivi la tua prima storia';

  @override
  String get storiesNudgeCompleteTitle => 'La tua storia è completa';

  @override
  String get storiesNudgeCompleteBody =>
      'Tutte e tre le storie sono sul tuo profilo. Aggiornane una quando la vita te ne regala una nuova.';

  @override
  String get storiesNudgeActionEdit => 'Modifica le tue storie';

  @override
  String storiesNudgeSharedTitle(int count, int max) {
    return 'Storie condivise: $count su $max';
  }

  @override
  String get storiesNudgeBodyMore =>
      'Un’altra storia dà alle persone un altro modo per iniziare una conversazione.';

  @override
  String storiesNudgeBodyLatest(String prompt) {
    return 'L’ultima: «$prompt». Un’altra dà alle persone un altro modo per iniziare una conversazione.';
  }

  @override
  String get storiesNudgeActionAdd => 'Aggiungi un’altra storia';

  @override
  String get storiesNudgeIdeas => 'Idee per iniziare';

  @override
  String storiesProgressSemantics(int count, int max) {
    return 'Storie scritte: $count su $max';
  }

  @override
  String get storiesPromptLittleJoy =>
      'Una piccola cosa per cui trovo sempre il tempo';

  @override
  String get storiesPromptWeekend => 'Un weekend da raccontare';

  @override
  String get storiesPromptFirstHello => 'Un primo saluto che adorerei';

  @override
  String get storiesPromptLearning => 'Qualcosa che sto imparando, solo per me';

  @override
  String get storiesPromptCare =>
      'Un piccolo modo in cui dimostro che ci tengo';

  @override
  String get storiesScreenTitle => 'Un po’ più di te';

  @override
  String get storiesSignIn => 'Accedi per modificare le tue storie.';

  @override
  String get storiesLoadFailed =>
      'Non è stato possibile caricare le tue storie.';

  @override
  String get storiesTryAgain => 'Riprova';

  @override
  String get storiesIncomplete =>
      'Aggiungi un testo a ogni storia e una descrizione a ogni foto, oppure rimuovi la storia incompleta.';

  @override
  String get storiesPublished => 'Le storie del tuo profilo sono pubblicate.';

  @override
  String get storiesSavedPrivately =>
      'Salvato in privato. Le tue storie sono nascoste agli altri membri.';

  @override
  String get storiesSaveUnconfirmed =>
      'Non abbiamo potuto confermare il salvataggio. Le tue modifiche sono ancora qui; ricarica le storie salvate per verificare.';

  @override
  String get storiesHeadline =>
      'Fai conoscere a qualcuno\nil te di tutti i giorni.';

  @override
  String get storiesIntro =>
      'Un piccolo rituale, la storia dietro una foto, un primo saluto che ti piacerebbe. Condividi fino a tre momenti, con parole tue.';

  @override
  String get storiesOptionalNote =>
      'Facoltativo, senza punteggi né obblighi di completamento. Evita recapiti o luoghi precisi che non vuoi condividere.';

  @override
  String get storiesPublishSwitch => 'Mostra queste storie sul mio profilo';

  @override
  String get storiesPublishSwitchHint =>
      'Disattivato all’inizio. Visibili ai membri idonei quando il tuo profilo è pubblicato e disponibile. Puoi nasconderle in qualsiasi momento.';

  @override
  String get storiesBackToEditing => 'Torna alla modifica';

  @override
  String get storiesPreview => 'Anteprima delle mie storie';

  @override
  String get storiesPreviewBanner => 'ANTEPRIMA · NON VIENE PUBBLICATA';

  @override
  String get storiesAdd => 'Aggiungi una storia';

  @override
  String get storiesReloadDiscard =>
      'Ricarica le storie salvate · annulla le modifiche';

  @override
  String get storiesSaving => 'Salvataggio…';

  @override
  String get storiesPublishButton => 'Pubblica le storie';

  @override
  String get storiesSavePrivatelyButton => 'Salva in privato';

  @override
  String get storiesPolicyNote =>
      'Le foto provengono dalla galleria approvata del tuo profilo. Storie e foto restano soggette alle segnalazioni dei membri e alle norme di sicurezza.';

  @override
  String storiesMomentLabel(int number) {
    return 'MOMENTO $number';
  }

  @override
  String storiesRemoveTooltip(int number) {
    return 'Rimuovi la storia $number';
  }

  @override
  String get storiesPromptLabel => 'Un punto di partenza';

  @override
  String get storiesTextLabel => 'Con parole tue';

  @override
  String get storiesTextHint => 'Un dettaglio vero la rende tua.';

  @override
  String get storiesTextRequired =>
      'Aggiungi qualche parola oppure rimuovi questa storia.';

  @override
  String get storiesPhotoLabel => 'Una foto, se vuoi';

  @override
  String get storiesWordsOnly => 'Solo testo';

  @override
  String storiesProfilePhoto(int number) {
    return 'Foto del profilo $number';
  }

  @override
  String get storiesPhotoDescriptionLabel => 'Descrivi questa foto';

  @override
  String get storiesPhotoDescriptionHelper =>
      'Aiuta chi usa uno screen reader.';

  @override
  String get storiesPhotoDescriptionRequired =>
      'Aggiungi una breve descrizione della foto.';

  @override
  String get storiesPhotoSemantics => 'Foto di una storia del profilo';

  @override
  String get storiesSectionTitle => 'Un po’ più di me';

  @override
  String get storiesRetryLoad => 'Riprova a caricare le storie';

  @override
  String get authErrorSessionExpired =>
      'La sessione è terminata. Accedi di nuovo.';

  @override
  String get authErrorSignInFailed => 'Impossibile accedere. Riprova.';

  @override
  String get authErrorCreateAccountFailed =>
      'Impossibile creare l\'account. Riprova.';

  @override
  String get authErrorCreateAccountGeneric => 'Impossibile creare l\'account.';

  @override
  String get authErrorInvalidCredentials =>
      'Nome utente o password non validi.';

  @override
  String get authErrorUsernameFormat =>
      'Il nome utente deve avere 3–30 caratteri tra lettere, numeri, _ o .';

  @override
  String get authErrorPasswordFormat =>
      'La password deve essere di 8–72 byte e contenere lettere e numeri.';

  @override
  String get authWelcomeIntroducerLink => 'Sono qui solo per presentare amici';

  @override
  String get signupBackTooltip => 'Indietro';

  @override
  String get signupIntroducerTitle =>
      'Sii l\'amico che fa incontrare le persone.';

  @override
  String get signupIntroducerBody =>
      'Un account solo per amici. Niente profilo di incontri, foto o swipe. La tua età resta privata; Connect è per adulti dai 18 agli 80 anni.';

  @override
  String get signupTitle => 'Crea il tuo account';

  @override
  String get signupSubtitle =>
      'Scegli un nome utente unico e una password sicura';

  @override
  String get signupUsernameLabel => 'Nome utente unico';

  @override
  String get signupUsernameHint => 'il_tuo_nome_utente';

  @override
  String get signupUsernameHelp =>
      '3–30 caratteri. Lettere, numeri, trattino basso e punto.';

  @override
  String get signupPasswordLabel => 'Password';

  @override
  String get signupPasswordHint => 'Almeno 8 caratteri';

  @override
  String get signupConfirmPasswordHint => 'Conferma la password';

  @override
  String get signupNameLabel => 'Nome e cognome';

  @override
  String get signupNameHint => 'Il tuo nome';

  @override
  String get signupDobLabel => 'Data di nascita';

  @override
  String get signupDobPickerHelp => 'Seleziona la data di nascita';

  @override
  String get signupDobPlaceholder => 'Seleziona data';

  @override
  String get signupGenderLabel => 'Mi identifico come';

  @override
  String get signupGenderMan => 'Uomo';

  @override
  String get signupGenderWoman => 'Donna';

  @override
  String get signupGenderOther => 'Altro';

  @override
  String get signupCreateFriendAccount => 'Crea account amico';

  @override
  String get signupAlreadyHaveAccount => 'Hai già un account?';

  @override
  String get signupErrorPasswordMismatch => 'Le password non coincidono.';

  @override
  String get signupErrorFullName => 'Inserisci il tuo nome e cognome.';

  @override
  String get signupErrorDobMissing => 'Seleziona la tua data di nascita.';

  @override
  String get signupErrorUnderage => 'Devi avere almeno 18 anni.';

  @override
  String get signupErrorAgeRange =>
      'Al momento Connect è disponibile per membri dai 18 agli 80 anni.';

  @override
  String get signupErrorGenderMissing => 'Scegli come ti identifichi.';

  @override
  String get authRecoveryEnterUsername => 'Inserisci il tuo nome utente.';

  @override
  String get authRecoveryEnterCode => 'Inserisci il tuo codice di recupero.';

  @override
  String get authRecoveryPasswordRule =>
      'Usa 8–72 caratteri con almeno una lettera e un numero.';

  @override
  String get authRecoveryResetDone =>
      'La tua password è stata reimpostata e tutti i dispositivi sono stati disconnessi. Accedi con la nuova password.';

  @override
  String get authRecoveryAssistanceDone =>
      'Se questo nome utente appartiene a un account Connect, il nostro team sicurezza esaminerà la richiesta.';

  @override
  String get authRecoveryInvalidCode =>
      'Questo codice di recupero non è valido o è scaduto.';

  @override
  String get authRecoveryOffline =>
      'Impossibile raggiungere Connect. Controlla la connessione e riprova.';

  @override
  String get authRecoverySendFailed =>
      'Impossibile inviare la richiesta. Controlla la connessione e riprova.';

  @override
  String get authRecoveryBackToSignIn => 'Torna all\'accesso';

  @override
  String get authRecoveryHaveCode => 'Ho il mio codice';

  @override
  String get authRecoveryLostCode => 'Ho perso il mio codice';

  @override
  String get authRecoveryHaveCodeIntro =>
      'Usa il codice di recupero che hai salvato quando hai creato l\'account, oppure uno fornito dal nostro team sicurezza.';

  @override
  String get authRecoveryLostCodeIntro =>
      'Dicci il tuo nome utente. Confermeremo la tua identità prima di emettere un codice di recupero. Non ti chiediamo mai la password.';

  @override
  String get authRecoveryUsernameLabel => 'Nome utente';

  @override
  String get authRecoveryCodeLabel => 'Codice di recupero';

  @override
  String get authRecoveryNewPasswordLabel => 'Nuova password';

  @override
  String get authRecoveryMessageLabel =>
      'Qualsiasi cosa ci aiuti (facoltativo)';

  @override
  String get authRecoveryMessageHint =>
      'Ad esempio, quando hai effettuato l\'ultimo accesso';

  @override
  String get authRecoverySending => 'Invio…';

  @override
  String get authRecoveryResetPassword => 'Reimposta password';

  @override
  String get authRecoveryAskForHelp => 'Chiedi aiuto';

  @override
  String get authTermsTitle => 'Termini e condizioni';

  @override
  String get authTermsSubtitle =>
      'Una rapida lettura prima di entrare nell\'app.';

  @override
  String get authTermsIntro =>
      'Leggi e accetta i nostri Termini e l\'Informativa sulla privacy per continuare.';

  @override
  String get authTermsCommunityTitle => 'Regole della community';

  @override
  String get authTermsPointRespect => 'Sii rispettoso e autentico.';

  @override
  String get authTermsPointNoHarassment =>
      'Niente molestie né comportamenti fraudolenti.';

  @override
  String get authTermsPointPrivacy =>
      'Sei tu a controllare le impostazioni della privacy e la visibilità del profilo.';

  @override
  String get authTermsPointReports =>
      'Le segnalazioni vengono esaminate per mantenere la community sicura.';

  @override
  String get authTermsPointViolations =>
      'Le violazioni possono comportare la sospensione o la rimozione dell\'account.';

  @override
  String get authTermsReviewLater =>
      'Puoi consultare i dettagli completi più tardi dalle impostazioni, ma devi accettarli prima di usare l\'app.';

  @override
  String get authTermsAgreeCheckbox =>
      'Accetto i Termini e l\'Informativa sulla privacy';

  @override
  String get authTermsAcceptButton => 'Accetto e continuo';

  @override
  String get authTermsSaveFailed =>
      'Impossibile salvare il tuo consenso. Controlla la connessione e riprova.';

  @override
  String discoverSuperLikeSent(String name) {
    return 'Super like inviato a $name';
  }

  @override
  String get discoverMatchPlaceholderMessage => 'Saluta';

  @override
  String discoverChatNeedsMatch(String name) {
    return 'Potrai chattare con $name quando ci sarà un vero match.';
  }

  @override
  String get discoverDailyLimitTitle => 'Hai finito i mi piace di oggi';

  @override
  String get discoverDailyLimitBody =>
      'Torna domani o passa a un piano superiore per avere più mi piace ogni giorno.';

  @override
  String discoverDailyLimitResetBody(String reset) {
    return '$reset. Passa a un piano superiore per avere più mi piace ogni giorno.';
  }

  @override
  String get discoverSeePlans => 'Vedi i piani';

  @override
  String get discoverNotNow => 'Non ora';

  @override
  String get discoverBackToToday => 'Torna a Oggi';

  @override
  String get discoverExploreTitle => 'Esplora';

  @override
  String get discoverSpotlightReviewed => 'Profili in evidenza visti tutti!';

  @override
  String get discoverAllReviewed => 'Visti tutti!';

  @override
  String get discoverCuratedForYou => 'Selezionati per te';

  @override
  String get discoverTitle => 'Scopri i match';

  @override
  String get discoverTagline => 'Un po’ di curiosità. Una connessione vera.';

  @override
  String get discoverMessages => 'Messaggi';

  @override
  String get discoverFilters => 'Filtri';

  @override
  String get discoverYourDeck => 'Il tuo mazzo';

  @override
  String get discoverStatReady => 'Pronti';

  @override
  String get discoverStatLiked => 'Mi piace';

  @override
  String get discoverStatPassed => 'Scartati';

  @override
  String get discoverEdit => 'Modifica';

  @override
  String get discoverShowingEveryone =>
      'Mostriamo tutti in base alle tue preferenze.';

  @override
  String get discoverToday => 'Oggi';

  @override
  String get discoverTodaySubtitle =>
      'Cinque proposte, aggiornate ogni giorno.';

  @override
  String get discoverViewAll => 'Vedi tutti';

  @override
  String get discoverMatchOnYourTerms => 'Fai match alle tue condizioni';

  @override
  String get discoverMatchOnYourTermsBody =>
      'Il match nasce da un interesse reciproco. Puoi bloccare o segnalare chiunque dal suo profilo o dalla conversazione.';

  @override
  String get discoverErrorEyebrow => 'Connessione in pausa';

  @override
  String get discoverErrorTitle => 'Impossibile caricare i profili';

  @override
  String discoverTrustFilteredBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'I filtri di fiducia hanno nascosto $count profili. Prova ad allentarli o aggiorna per ricostruire il tuo mazzo.',
      one:
          'I filtri di fiducia hanno nascosto $count profilo. Prova ad allentarli o aggiorna per ricostruire il tuo mazzo.',
    );
    return '$_temp0';
  }

  @override
  String get discoverDeckPreparingBody =>
      'Stiamo preparando il tuo mazzo. Aggiorna per cercare nuovi profili verificati vicino a te.';

  @override
  String get discoverCheckBackSoon => 'Torna presto';

  @override
  String get discoverNoSpotlightProfiles => 'Nessun profilo in evidenza';

  @override
  String get discoverNoProfiles => 'Nessun profilo';

  @override
  String get discoverRefresh => 'Aggiorna';

  @override
  String get discoverPromisePrivate => 'Privato';

  @override
  String get discoverPremium => 'Premium';

  @override
  String discoverNotificationsUnread(int count) {
    return 'Notifiche, $count non lette';
  }

  @override
  String get discoverLatestUnreadNotifications => 'Ultime notifiche non lette';

  @override
  String get discoverNoUnreadNotifications => 'Nessuna notifica non letta';

  @override
  String get discoverNotificationWhoReplied => 'Chi mi ha risposto';

  @override
  String discoverNotificationRepliesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuove risposte',
      one: '1 nuova risposta',
    );
    return '$_temp0';
  }

  @override
  String get discoverNotificationWhoLiked => 'A chi piaccio';

  @override
  String discoverNotificationLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuovi mi piace',
      one: '1 nuovo mi piace',
    );
    return '$_temp0';
  }

  @override
  String get discoverViewMore => 'Vedi altro';

  @override
  String get discoverFitsYourWeek => 'Adatto alla tua settimana';

  @override
  String discoverTodayPicks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count proposte',
      one: '1 proposta',
    );
    return '$_temp0';
  }

  @override
  String get discoverPickedForYouToday => 'Scelto per te oggi.';

  @override
  String get discoverErrorLoginToDiscover => 'Accedi per scoprire i profili.';

  @override
  String get discoverErrorLoadProfiles =>
      'Impossibile caricare i profili. Riprova.';

  @override
  String get discoverErrorSessionUnavailable =>
      'Sessione non disponibile. Accedi di nuovo.';

  @override
  String get discoverErrorLikeRetry =>
      'Al momento non puoi mettere mi piace. Riprova.';

  @override
  String get discoverErrorLike => 'Al momento non puoi mettere mi piace.';

  @override
  String get discoverErrorPassRetry => 'Al momento non puoi scartare. Riprova.';

  @override
  String get discoverErrorLoadLikedMe =>
      'Impossibile caricare a chi piaci. Riprova.';

  @override
  String get discoverErrorAnswerInFlight =>
      'Stiamo già inviando la tua risposta.';

  @override
  String get discoverErrorAnswer =>
      'Impossibile inviare la tua risposta. Riprova.';

  @override
  String get firstChapterTopicPace => 'Ritmo di comunicazione';

  @override
  String get firstChapterTopicDates => 'Comfort negli appuntamenti';

  @override
  String get firstChapterTopicLanguage => 'Lingue';

  @override
  String get firstChapterTopicFamily => 'Ruolo della famiglia';

  @override
  String get firstChapterInMyWords => 'Con parole mie';

  @override
  String firstChapterComfortOriginal(String language) {
    return 'Originale · $language';
  }

  @override
  String firstChapterComfortMemberTranslation(String language) {
    return 'Traduzione fornita dal membro · $language';
  }

  @override
  String get firstChapterComfortReloadSaved => 'Ricarica la versione salvata';

  @override
  String get firstChapterComfortReloadCards => 'Ricarica le schede';

  @override
  String get firstChapterComfortHeadline => 'Le tue parole. I tuoi limiti.';

  @override
  String get firstChapterComfortIntro =>
      'Un contesto facoltativo per le persone con cui hai un match. Non deduciamo nulla dalle tue origini. Scrivi nella lingua che senti tua.';

  @override
  String get firstChapterComfortShareTitle =>
      'Condividi queste schede con i miei match';

  @override
  String get firstChapterComfortShareSubtitle =>
      'Se disattivato, ogni scheda resta privata.';

  @override
  String get firstChapterComfortRemoveFromDraft => 'Rimuovi dalla bozza';

  @override
  String get firstChapterComfortTopicLabel => 'Un po\' di contesto su';

  @override
  String get firstChapterComfortOriginalLanguage => 'Lingua originale';

  @override
  String get firstChapterComfortOwnWords => 'Con parole tue';

  @override
  String get firstChapterComfortOwnWordsHint =>
      'Per esempio: mi piacciono gli appuntamenti di giorno e un po\' di tempo per sentirmi a mio agio.';

  @override
  String get firstChapterComfortTranslation =>
      'La tua traduzione (facoltativa)';

  @override
  String get firstChapterComfortTranslationLanguage =>
      'Lingua della traduzione (se aggiunta)';

  @override
  String get firstChapterComfortTranslationNote =>
      'Le traduzioni sono indicate come fornite dal membro. Le tue parole originali vengono sempre conservate.';

  @override
  String get firstChapterComfortAddCard =>
      'Aggiungi / sostituisci questa scheda nella bozza';

  @override
  String get firstChapterComfortMissingFields =>
      'Aggiungi le tue parole e la lingua. Anche una traduzione ha bisogno della sua lingua.';

  @override
  String get firstChapterComfortUnaddedCard =>
      'Aggiungi la scheda che hai scritto alla bozza prima di salvare.';

  @override
  String get firstChapterComfortSaveFailed =>
      'La tua bozza è ancora qui. Ricarica per controllare l\'ultima versione salvata prima di riprovare.';

  @override
  String get firstChapterSaving => 'Salvataggio…';

  @override
  String get firstChapterComfortSave => 'Salva le mie scelte';

  @override
  String get firstChapterYourMatch => 'il tuo match';

  @override
  String get firstChapterSaveUnconfirmed =>
      'Non siamo riusciti a confermare il salvataggio. Aggiorna per controllare prima di riprovare.';

  @override
  String get firstChapterJointPreviewTitle =>
      'Una storia che approvate entrambi';

  @override
  String get firstChapterSoloPreviewTitle =>
      'Anteprima del tuo capitolo pubblico';

  @override
  String firstChapterThenSurprise(String surprise) {
    return 'Poi… $surprise';
  }

  @override
  String get firstChapterJointPreviewBody =>
      'La tua approvazione è una metà. Il link funziona solo dopo che anche l\'altra persona approva esattamente questa scheda. Ognuno di voi può revocarlo.';

  @override
  String get firstChapterSoloPreviewBody =>
      'Sono pubblici solo questa scena e l\'inizio che hai scelto. Niente nomi, foto, chat private, posizione o contributi dell\'altra persona. Puoi revocare il link.';

  @override
  String get firstChapterKeepPrivate => 'Mantieni privato';

  @override
  String get firstChapterApproveMyHalf => 'Approva la mia metà';

  @override
  String get firstChapterCreateShareLink => 'Crea link di condivisione';

  @override
  String get firstChapterStudioTitle => 'Studio Primo Capitolo';

  @override
  String get firstChapterRefresh => 'Aggiorna capitolo';

  @override
  String get firstChapterHeroEyebrow => 'UNA PICCOLA AVVENTURA. DUE AUTORI.';

  @override
  String get firstChapterHeroTitle => 'Quello che succede\npoi è vostro.';

  @override
  String get firstChapterHeroSolo =>
      'Crea una scena. Passala a un amico. Oppure crea un primo capitolo con qualcuno con cui hai un match.';

  @override
  String firstChapterHeroPair(String name) {
    return 'Tu e $name. Un inizio, una svolta inaspettata e una storia che potete rendere reale.';
  }

  @override
  String get firstChapterHeroPace =>
      'Facoltativo, con i tuoi tempi. Chattare è sempre una scelta.';

  @override
  String get firstChapterLoadFailed => 'Impossibile caricare il tuo capitolo.';

  @override
  String get firstChapterTryAgain => 'Riprova';

  @override
  String get firstChapterStepChooseScene => '01 / Scegli la tua scena';

  @override
  String get firstChapterStepWriteBeginning => '02 / Scrivi l\'inizio';

  @override
  String get firstChapterStartOurChapter => 'Inizia il nostro capitolo';

  @override
  String get firstChapterPassTheChapter => 'Passa il capitolo';

  @override
  String get firstChapterYourFirstChapter => 'Il vostro primo capitolo';

  @override
  String get firstChapterItBeginsWith => 'INIZIA CON';

  @override
  String get firstChapterAndThen => 'E POI…';

  @override
  String firstChapterDateIdeaNote(String beginning, String surprise) {
    return '$beginning. Poi $surprise.';
  }

  @override
  String get firstChapterMakeDateIdea =>
      'Trasformalo in un\'idea per un appuntamento';

  @override
  String get firstChapterDateIdeaHint =>
      'Un suggerimento da definire insieme. Nessun appuntamento viene prenotato o accettato automaticamente.';

  @override
  String get firstChapterYourTurn => 'Tocca a te: aggiungi una sorpresa.';

  @override
  String get firstChapterBeginningSaved =>
      'Il tuo inizio è salvato. Il tuo match può aggiungere una sorpresa quando vuole. Potete continuare a chattare.';

  @override
  String get firstChapterClose => 'Chiudi questo capitolo';

  @override
  String get firstChapterGiveBackTitle => 'Storie che restituiscono';

  @override
  String get firstChapterGiveBackBody =>
      'Il vostro legame può ispirare un nuovo inizio. Condividete solo questa idea anonima di appuntamento, con l\'approvazione di entrambi.';

  @override
  String get firstChapterPreviewAnonymous =>
      'Anteprima della nostra storia anonima';

  @override
  String get firstChapterGreenLightTitle => 'Un via libera privato';

  @override
  String get firstChapterInTheirWords => 'Con le sue parole';

  @override
  String get firstChapterMakeRoomTitle => 'Fai spazio a ciò che conta per te';

  @override
  String get firstChapterMakeRoomSubtitle =>
      'I tuoi tempi, le lingue, gli appuntamenti e le aspettative della famiglia. Le tue parole, condivise solo quando lo decidi tu.';

  @override
  String get firstChapterCreateWithConnection => 'Crea con una connessione';

  @override
  String get firstChapterCreateTogether => 'Create insieme un primo capitolo';

  @override
  String get firstChapterMatchesAppearHere =>
      'Qui compaiono i tuoi match reciproci. Intanto puoi provare e condividere una scena da solo.';

  @override
  String get firstChapterSharedChapters => 'I tuoi capitoli condivisi';

  @override
  String get firstChapterReloadShared => 'Ricarica i capitoli condivisi';

  @override
  String get firstChapterNothingPublic =>
      'Niente è pubblico finché non scegli di condividerlo.';

  @override
  String get firstChapterGreenChat => 'Continuare a chattare';

  @override
  String get firstChapterGreenCall => 'Provare una chiamata';

  @override
  String get firstChapterGreenDate => 'Proporre un appuntamento';

  @override
  String get firstChapterGreenLightIntro =>
      'Viene rivelata solo una scelta condivisa. Nessuno vede una richiesta senza risposta. Le scelte scadono dopo sette giorni; cancellale per ritirarle.';

  @override
  String get firstChapterSavePrivately => 'Salva in privato';

  @override
  String get firstChapterGreenLightNone =>
      'Qui comparirà ogni prossimo passo condiviso.';

  @override
  String firstChapterGreenLightMutual(String choices) {
    return 'Vi sentite entrambi a vostro agio con: $choices';
  }

  @override
  String get firstChapterGreenLightNote =>
      'Un via libera è il permesso di proporre. Una chiamata o un appuntamento richiedono comunque un accordo a parte.';

  @override
  String get firstChapterLinkRevoked => 'Link revocato';

  @override
  String get firstChapterPublicScene => 'Scena pubblica e anonima';

  @override
  String get firstChapterPrivateUntilBoth =>
      'Privato finché entrambi non approvano';

  @override
  String get firstChapterLinkCopied =>
      'Link del capitolo copiato. Condividilo dove vuoi.';

  @override
  String get firstChapterCopyLink => 'Copia link';

  @override
  String get firstChapterApproveStory => 'Approva esattamente questa storia';

  @override
  String get firstChapterRevokeLink => 'Revoca link';

  @override
  String networkSlowResponse(int mbps) {
    return 'Rete debole rilevata. Usa almeno $mbps Mbps per chat, regali e gesti più fluidi.';
  }

  @override
  String get networkOffline =>
      'Nessuna connessione stabile. Riconnettiti per continuare a usare l’app.';

  @override
  String networkWeak(int mbps) {
    return 'La rete è debole. Usa almeno $mbps Mbps per un’esperienza più fluida.';
  }

  @override
  String get networkCannotReachService =>
      'Impossibile raggiungere il servizio locale. Verifica che l’API sia in esecuzione.';

  @override
  String get gateCheckingTerms => 'Verifica dei termini…';

  @override
  String get gateLoadingProfile => 'Caricamento del tuo profilo…';

  @override
  String get gateConnectionIssue => 'Problema di connessione';

  @override
  String get safetyReportFailed => 'Segnalazione non riuscita';

  @override
  String get safetyBlockFailed => 'Blocco non riuscito';

  @override
  String get safetyUnblockFailed => 'Sblocco non riuscito';

  @override
  String get safetyNotAuthenticated => 'Accesso non effettuato';

  @override
  String get timeAgoJustNow => 'Proprio ora';

  @override
  String timeAgoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuti fa',
      one: '1 minuto fa',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore fa',
      one: '1 ora fa',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni fa',
      one: '1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String timeAgoWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count settimane fa',
      one: '1 settimana fa',
    );
    return '$_temp0';
  }

  @override
  String get themePreviewBarrier => 'Anteprima del tema';

  @override
  String get themeNowShowing => 'ORA IN PROGRAMMAZIONE';

  @override
  String get themeTaglineRealLife => 'Avorio caldo, verde foresta e albicocca.';

  @override
  String get themeTaglineRealLifeNight =>
      'Verde foresta, menta tenue e luce di candela.';

  @override
  String get themeTaglineDaylight =>
      'Crema, inchiostro e un tocco lampone, come il sito.';

  @override
  String get themeTaglineEmber =>
      'Notte nero prugna con braci e bagliori viola.';

  @override
  String get themeTaglineForge =>
      'Rosso fornace, blu acciaio, cromo canna di fucile.';

  @override
  String get themeTaglineNeongrid =>
      'Vetro nero, linee di luce ciano, pulsazione ambra.';

  @override
  String get themeTaglineCrimsonalloy =>
      'Lacca cremisi, oro fuso, bordeaux di mezzanotte.';

  @override
  String get themeTaglineCircuit =>
      'Verde circuito, viola segnale, nero carbonio.';

  @override
  String get themeTaglineDeepfield =>
      'Spazio profondo, blu plasma e un lampo d’oro stellare.';

  @override
  String get themeTaglineLove => 'Cipria, rosa e un po’ d’oro.';

  @override
  String get themeTaglineRose => 'Vino vellutato, rosso rosa e un po’ d’oro.';

  @override
  String get themeTaglinePetal =>
      'Carta cipria, petali in volo, un tocco di salvia.';

  @override
  String get themeTaglineSnow =>
      'Neve fresca, vetro smerigliato e un nastro d’aurora.';

  @override
  String get themeTaglineGothic =>
      'Trafori al chiaro di luna, granato, fumo di candela e oro antico.';

  @override
  String get themeTaglineCalm =>
      'Pochi stimoli, alto contrasto. Sfondo fermo, nessun movimento.';

  @override
  String get themeLooksTodayDescription =>
      'Di giorno avorio caldo e verde foresta. Di notte menta tenue e foresta profonda.';

  @override
  String get settingsEyebrow => 'IMPOSTAZIONI';

  @override
  String get settingsHeaderSubtitle =>
      'Il tuo look, la tua privacy e il tuo account.';

  @override
  String get settingsThemeSection => 'Tema';

  @override
  String get settingsThemeSectionTitle => 'Rendilo tuo';

  @override
  String get settingsThemeSectionCaption =>
      'Ogni schermata segue il look che scegli.';

  @override
  String get settingsSectionYourStory => 'La tua storia';

  @override
  String get settingsDatingRhythmTitle => 'Il tuo ritmo negli incontri';

  @override
  String get settingsDatingRhythmSubtitle =>
      'Intenzioni, ritmo, disponibilità e privacy delle presentazioni';

  @override
  String get settingsProfileStoriesTitle => 'Le storie del tuo profilo';

  @override
  String get settingsProfileStoriesSubtitle =>
      'Piccoli momenti, le tue parole, foto facoltative';

  @override
  String get settingsBlogTitle => 'Blog · Capitoli aperti';

  @override
  String get settingsBlogSubtitle =>
      'Il tuo diario, le tue foto, il tuo pubblico';

  @override
  String get settingsLookPreviewEyebrow => 'OGGI';

  @override
  String get settingsLookPreviewHeadline => 'Qualcosa di vero.';

  @override
  String get friendsEyebrow => 'AMICI';

  @override
  String get friendsTitle => 'La tua gente';

  @override
  String get friendsSubtitle =>
      'Gli amici possono scriversi, fare piani e creare gruppi insieme. Le richieste hanno bisogno del sì di entrambi.';

  @override
  String get friendsBack => 'Indietro';

  @override
  String get friendsAddFriend => 'Aggiungi amico';

  @override
  String get friendsCreateGroup => 'Crea un gruppo';

  @override
  String get friendsSectionRequests => 'RICHIESTE';

  @override
  String get friendsRequestsWaitingOnOthers => 'In attesa degli altri';

  @override
  String get friendsRequestsWaitingOnYou => 'Aspettano te';

  @override
  String get friendsRequestsCaption =>
      'Non si condivide nulla finché non siete d’accordo entrambi.';

  @override
  String get friendsSectionChats => 'CHAT';

  @override
  String get friendsChatsTitle => 'Conversazioni';

  @override
  String get friendsSectionIntros => 'PRESENTAZIONI';

  @override
  String get friendsIntrosTitle => 'Presentazioni per te';

  @override
  String get friendsSectionVouches => 'GARANZIE';

  @override
  String get friendsVouchesPendingTitle =>
      'Garanzie in attesa della tua approvazione';

  @override
  String friendsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amici',
      one: '1 amico',
      zero: 'Ancora nessun amico',
    );
    return '$_temp0';
  }

  @override
  String get friendsIntroduce => 'Presenta';

  @override
  String get friendsEmptyBody =>
      'Trova le persone che conosci per nome o nome utente, oppure aggiungi qualcuno da un match, una stanza o un gruppo.';

  @override
  String get friendsSectionOnProfile => 'SUL TUO PROFILO';

  @override
  String get friendsVouchesOnProfileTitle => 'Garanzie sul tuo profilo';

  @override
  String friendsQuoted(String text) {
    return '«$text»';
  }

  @override
  String friendsVouchedForYou(String name) {
    return '$name garantisce per te';
  }

  @override
  String get friendsHideFromProfile => 'Nascondi dal profilo';

  @override
  String get friendsSectionMore => 'ALTRO';

  @override
  String get friendsMoreTitle => 'Piani e presentazioni';

  @override
  String get friendsPlansLinkTitle => 'Piani di appuntamenti condivisi con te';

  @override
  String get friendsPlansLinkSubtitle =>
      'Gli amici ti avvisano quando pianificano un appuntamento e quando si fanno sentire dopo.';

  @override
  String get friendsInviteIntroducerTitle =>
      'Invita un amico che non cerca l’anima gemella';

  @override
  String get friendsInviteIntroducerSubtitle =>
      'Scegli chi può presentarti. Puoi rivedere o ritirare il permesso in qualsiasi momento.';

  @override
  String get friendsIntroTermsTitle => 'Presentazioni, alle tue condizioni';

  @override
  String get friendsIntroTermsSubtitle =>
      'Scegli se gli amici possono presentarti e cosa mostra un’anteprima.';

  @override
  String get friendsSectionActivity => 'ATTIVITÀ';

  @override
  String get friendsActivityTitle => 'Con i tuoi amici';

  @override
  String friendsVouchSentSnack(String name) {
    return 'Garanzia inviata. $name la approva prima che venga mostrata.';
  }

  @override
  String friendsRemoveTitle(String name) {
    return 'Rimuovere $name?';
  }

  @override
  String get friendsRemoveBody =>
      'Non sarete più amici e la vostra chat verrà chiusa. Non riceverà alcun avviso.';

  @override
  String get friendsRemoveFriend => 'Rimuovi amico';

  @override
  String get friendsIntroMadeSnack =>
      'Presentazione fatta. Entrambi gli amici riceveranno il tuo messaggio.';

  @override
  String get friendsAddSheetLabel => 'AGGIUNGI AMICO';

  @override
  String get friendsAddSheetTitle => 'Trova qualcuno che conosci';

  @override
  String get friendsAddSheetCaption =>
      'Cerca per nome o @nomeutente. L’altra persona sceglie se accettare.';

  @override
  String get friendsSearchHiddenNote =>
      'Non compari nella ricerca amici, quindi gli altri non possono trovarti qui. Puoi cambiarlo in Privacy e sicurezza.';

  @override
  String get friendsSearchLabel => 'Nome o @nomeutente';

  @override
  String get friendsSearchHelper => 'Digita almeno 3 lettere';

  @override
  String get friendsSearchFailed =>
      'La ricerca non è disponibile al momento. Riprova.';

  @override
  String friendsSearchNoResults(String query) {
    return 'Nessuno trovato per «$query».';
  }

  @override
  String get friendsNewGroupLabel => 'NUOVO GRUPPO';

  @override
  String get friendsNewGroupTitle => 'Chi c’è?';

  @override
  String get friendsNewGroupCaption =>
      'Scegli gli amici da invitare. Potrai aggiungerne altri dopo.';

  @override
  String get friendsChooseFriends => 'Scegli gli amici';

  @override
  String friendsCreateGroupWith(int count) {
    return 'Crea un gruppo con $count';
  }

  @override
  String get friendsSourceMatch => 'Dai tuoi match';

  @override
  String get friendsSourceProfile => 'Ha visto il tuo profilo';

  @override
  String get friendsSourceRoom => 'Conosciuti in una stanza';

  @override
  String get friendsSourceGroup => 'Da un gruppo';

  @override
  String get friendsSourceSearch => 'Ti ha trovato per nome';

  @override
  String get friendsWantsToBeFriends => 'Vuole essere tuo amico';

  @override
  String get friendsRequestSent => 'Richiesta inviata';

  @override
  String get friendsCancel => 'Annulla';

  @override
  String get friendsDecline => 'Rifiuta';

  @override
  String get friendsAccept => 'Accetta';

  @override
  String friendsMessageTooltip(String name) {
    return 'Scrivi a $name';
  }

  @override
  String friendsMessageTooltipUnread(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Scrivi a $name, $count non letti',
      one: 'Scrivi a $name, 1 non letto',
    );
    return '$_temp0';
  }

  @override
  String friendsMoreFor(String name) {
    return 'Altro per $name';
  }

  @override
  String get friendsMenuVouch => 'Garantisci per questa persona';

  @override
  String get friendsMenuIntro => 'Presenta a un amico';

  @override
  String friendsChatSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chat con $name, $count non letti',
      one: 'Chat con $name, 1 non letto',
      zero: 'Chat con $name',
    );
    return '$_temp0';
  }

  @override
  String friendsChatSemanticsMuted(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chat con $name, $count non letti, notifiche disattivate',
      one: 'Chat con $name, 1 non letto, notifiche disattivate',
      zero: 'Chat con $name, notifiche disattivate',
    );
    return '$_temp0';
  }

  @override
  String friendsIntroHeadline(String introducer, String person) {
    return '$introducer pensa che dovresti conoscere $person';
  }

  @override
  String friendsIntroHeadlineSomeone(String introducer) {
    return '$introducer pensa che dovresti conoscere qualcuno';
  }

  @override
  String friendsNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String get friendsIntroNoThanks => 'No, grazie';

  @override
  String get friendsIntroImIn => 'Ci sto';

  @override
  String get friendsVouchKeepPrivate => 'Tieni privato';

  @override
  String get friendsVouchShowOnProfile => 'Mostra sul mio profilo';

  @override
  String get memberProfileNoData => 'Nessun dato del profilo trovato.';

  @override
  String get memberProfileSignInToView => 'Accedi per vedere il tuo profilo.';

  @override
  String get memberProfileLoadFailed =>
      'Impossibile caricare il profilo. Riprova.';

  @override
  String get memberProfileConnectionsTitle => 'Le tue connessioni';

  @override
  String get memberProfileConnectionsCaption =>
      'Persone a cui hai messo like, i tuoi match e con chi parli.';

  @override
  String get memberProfileStatLiked => 'I tuoi like';

  @override
  String get memberProfileStatMatches => 'Match';

  @override
  String get memberProfileStatMessages => 'Messaggi';

  @override
  String memberProfileOpenStat(String label) {
    return 'Apri $label';
  }

  @override
  String get memberProfileNoticedTitle => 'Chi ti ha notato';

  @override
  String get memberProfileNoticedCaption =>
      'Like e visite da membri vicino a te.';

  @override
  String get memberProfileWhoLikedMe => 'A chi piaccio';

  @override
  String memberProfileWhoLikedMeCount(int count) {
    return 'A chi piaccio ($count)';
  }

  @override
  String get memberProfileWhoLikedMeSubtitle =>
      'Membri a cui è piaciuto il tuo profilo.';

  @override
  String get memberProfileWhoViewedTitle => 'Chi ha visto il mio profilo';

  @override
  String get memberProfileWhoViewedSubtitle => 'Visite recenti al tuo profilo.';

  @override
  String get memberProfileWhoViewedTooltip => 'Chi ha visto il mio profilo';

  @override
  String get memberProfileRefreshTooltip => 'Aggiorna profilo';

  @override
  String get memberProfilePreferencesTitle => 'Le tue preferenze';

  @override
  String get memberProfilePrefSeeking => 'Cerco';

  @override
  String get memberProfilePrefDistance => 'Distanza';

  @override
  String memberProfileWithinKm(int km) {
    return 'Entro $km km';
  }

  @override
  String get profileViewersTitle => 'Hanno visto il mio profilo';

  @override
  String get profileViewersLoadFailed =>
      'Impossibile caricare le visite al profilo.';

  @override
  String get profileViewersEmpty => 'Nessuno ha ancora visto il tuo profilo.';

  @override
  String get profileViewersViewedRecently => 'Visto di recente';

  @override
  String profileViewersViewedAt(String time) {
    return 'Visto il $time';
  }

  @override
  String get profileMasterReligionParsi => 'Parsi';

  @override
  String get profileMasterReligionBahai => 'Bahá’í';

  @override
  String get profileMasterReligionTribal => 'Tribale / Indigena';

  @override
  String get profileMasterWorkout1to2 => '1-2 volte a settimana';

  @override
  String get profileMasterWorkout3to4 => '3-4 volte a settimana';

  @override
  String get profileMasterWorkout5Plus => '5+ volte a settimana';

  @override
  String get profileMasterWorkoutDaily => 'Ogni giorno';

  @override
  String get profileMasterDietNoPreference => 'Nessuna preferenza';

  @override
  String get profileMasterDietVegetarian => 'Vegetariano';

  @override
  String get profileMasterDietEggetarian => 'Vegetariano con uova';

  @override
  String get profileMasterDietNonVegetarian => 'Non vegetariano';

  @override
  String get profileMasterDietVegan => 'Vegano';

  @override
  String get profileMasterDietJain => 'Dieta giainista';

  @override
  String get profileMasterDietTypeBalanced => 'Equilibrata';

  @override
  String get profileMasterDietTypeHighProtein => 'Iperproteica';

  @override
  String get profileMasterDietTypeLowCarb => 'Low carb';

  @override
  String get profileMasterDietTypeKeto => 'Chetogenica';

  @override
  String get profileMasterDietTypeMediterranean => 'Mediterranea';

  @override
  String get profileMasterDietTypeIntermittentFasting =>
      'Digiuno intermittente';

  @override
  String get profileMasterSleepEarlyBird => 'Mattiniero';

  @override
  String get profileMasterSleepNightOwl => 'Nottambulo';

  @override
  String get profileMasterSleepFlexible => 'Flessibile';

  @override
  String get profileMasterSleepShiftBased => 'A turni';

  @override
  String get profileMasterTravelHomebody => 'Pantofolaio';

  @override
  String get profileMasterTravelOccasional => 'Viaggiatore occasionale';

  @override
  String get profileMasterTravelFrequent => 'Viaggiatore abituale';

  @override
  String get profileMasterTravelAdventure => 'Avventuroso';

  @override
  String get profileMasterTravelLuxury => 'Viaggi di lusso';

  @override
  String get profileMasterTravelBackpacker => 'Zaino in spalla';

  @override
  String get profileMasterPoliticsSimilar => 'Solo opinioni simili';

  @override
  String get profileMasterPoliticsOpen => 'Aperto alle differenze';

  @override
  String get profileMasterPoliticsNotDiscuss => 'Preferisco non parlarne';

  @override
  String get profileMasterPoliticsNoStrong => 'Nessuna preferenza particolare';

  @override
  String get profileMasterIntentLongTerm => 'Relazione stabile';

  @override
  String get profileMasterIntentMarriage => 'Matrimonio';

  @override
  String get profileMasterIntentNewFriends => 'Nuovi amici';

  @override
  String get chatBackToConversations => 'Torna alle conversazioni';

  @override
  String get chatOfflineBanner =>
      'Sei offline. La tua bozza resta qui finché non ti riconnetti.';

  @override
  String get chatVoiceHello => 'Condividi un saluto vocale · leggi e ascolta';

  @override
  String get chatLoadFailedTitle => 'Riconnettiamoci.';

  @override
  String get chatLoadFailedBody =>
      'Non è stato possibile caricare la conversazione. Riprova.';

  @override
  String get chatConversationEnded => 'Questa conversazione è terminata.';

  @override
  String get chatUnlockStepRequired =>
      'Completa il passaggio di sblocco attuale per continuare la conversazione.';

  @override
  String get chatGiftTrayTitle => 'Un pensiero per questa persona';

  @override
  String get chatCloseGifts => 'Chiudi regali';

  @override
  String get chatAllGifts => 'Tutti i regali';

  @override
  String get chatNoGiftsInCollection =>
      'Nessun regalo disponibile in questa collezione.';

  @override
  String get chatAddCoins => 'Aggiungi monete';

  @override
  String get chatFreeGiftDaily => 'Gratis · 1 al giorno';

  @override
  String chatCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monete',
      one: '1 moneta',
    );
    return '$_temp0';
  }

  @override
  String get chatSendingGift => 'Invio del regalo…';

  @override
  String get chatOfflineGifts =>
      'Sei offline. Puoi sfogliare i regali e inviarli quando ti riconnetti.';

  @override
  String chatGiftConfirmTitle(String gift, String name) {
    return 'Inviare $gift a $name?';
  }

  @override
  String chatGiftNoteQuote(String note) {
    return '«$note»';
  }

  @override
  String chatGiftBalanceAfter(int balance, int remaining) {
    return '·  $balance → ne resteranno $remaining';
  }

  @override
  String get chatGiftNoObligation =>
      'Un regalo è un gesto, mai un obbligo di rispondere o di incontrarsi.';

  @override
  String chatGiftSendFor(String price) {
    return 'Invia per $price';
  }

  @override
  String get chatNotNow => 'Non ora';

  @override
  String get chatDeleteMessageTitle => 'Eliminare il messaggio?';

  @override
  String get chatDeleteMessageBody =>
      'Il messaggio verrà rimosso dalle chat di entrambi.';

  @override
  String get chatDeleteForEveryone => 'Elimina per tutti';

  @override
  String get chatMessageDeletedSnack => 'Messaggio eliminato.';

  @override
  String get chatUndo => 'Annulla';

  @override
  String get chatDeleteUndone => 'Eliminazione annullata.';

  @override
  String chatGiftReceivedFrom(String name) {
    return 'Regalo da $name';
  }

  @override
  String get chatGiftReceiverIntro => 'Decidi tu cosa resta nella tua chat.';

  @override
  String get chatHideGift => 'Nascondi regalo';

  @override
  String get chatHideGiftSubtitle => 'Rimuovilo solo dalla tua chat.';

  @override
  String get chatReportAndHide => 'Segnala e nascondi';

  @override
  String get chatReportAndHideSubtitle =>
      'Invialo al team sicurezza e rimuovilo subito.';

  @override
  String get chatGiftHidden => 'Regalo nascosto dalla tua chat.';

  @override
  String get chatReportGiftTitle => 'Segnala questo regalo';

  @override
  String get chatReportGiftIntro =>
      'Scegli un motivo. Il regalo verrà nascosto subito.';

  @override
  String get chatReportReasonLabel => 'Motivo';

  @override
  String get chatReportReasonUnwanted => 'Regalo indesiderato';

  @override
  String get chatReportReasonHarassment => 'Molestie';

  @override
  String get chatReportReasonSexual => 'Contenuti sessuali';

  @override
  String get chatReportReasonScam => 'Truffa o frode';

  @override
  String get chatReportReasonOther => 'Altro';

  @override
  String get chatReportDetailsLabel => 'Aggiungi dettagli (facoltativo)';

  @override
  String get chatReportSubmit => 'Invia segnalazione e nascondi';

  @override
  String get chatGiftReported =>
      'Regalo segnalato e nascosto. Il nostro team sicurezza lo esaminerà.';

  @override
  String get chatQuickEmojis => 'Emoji rapide';

  @override
  String chatWalletTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monete',
      one: '1 moneta',
    );
    return 'Il tuo portafoglio · $_temp0';
  }

  @override
  String get chatDailyLimitReached =>
      'Limite giornaliero di messaggi raggiunto';

  @override
  String get chatDailyLimitFallback =>
      'Riprova domani o passa a un piano superiore.';

  @override
  String chatDailyLimitReset(String reset) {
    return '$reset · passa a un piano superiore per averne di più.';
  }

  @override
  String get chatSeePlans => 'Vedi i piani';

  @override
  String chatQuotaOnPlan(String quota, String plan) {
    return '$quota con $plan';
  }

  @override
  String get chatYourConversation => 'La vostra conversazione';

  @override
  String get chatVerifiedHumans => 'Persone verificate';

  @override
  String get chatVerifiedHumansShowsUp =>
      'Persone verificate · Si presenta agli appuntamenti';

  @override
  String discoverLikedBack(String name) {
    return 'Hai ricambiato il mi piace di $name';
  }

  @override
  String discoverPassedOn(String name) {
    return 'Hai scartato $name';
  }

  @override
  String get discoverLikedMeLoadFailedTitle =>
      'Impossibile caricare i tuoi mi piace';

  @override
  String get discoverLikedMeEmptyTitle => 'Ancora nessun nuovo mi piace';

  @override
  String get discoverLikedMeEmptyBody =>
      'Quando piaci a qualcuno, compare qui. Ricambia il mi piace ed è match.';

  @override
  String get discoverLikedMeIntro =>
      'Piaci già a queste persone. Ricambia per fare match o scarta. Scartare è privato.';

  @override
  String get discoverLikedMeTitle => 'Ti hanno messo mi piace';

  @override
  String discoverLikedMeTitleCount(int count) {
    return 'Ti hanno messo mi piace · $count';
  }

  @override
  String get discoverPass => 'Scarta';

  @override
  String get discoverLikeBack => 'Ricambia';

  @override
  String get discoverLikedJustNow => 'Ti ha messo mi piace proprio ora';

  @override
  String discoverLikedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ti ha messo mi piace $count minuti fa',
      one: 'Ti ha messo mi piace 1 minuto fa',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ti ha messo mi piace $count ore fa',
      one: 'Ti ha messo mi piace 1 ora fa',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ti ha messo mi piace $count giorni fa',
      one: 'Ti ha messo mi piace 1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ti ha messo mi piace $count settimane fa',
      one: 'Ti ha messo mi piace 1 settimana fa',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedOnDate(String date) {
    return 'Ti ha messo mi piace il $date';
  }

  @override
  String discoverLikedProfilesTitle(int count) {
    return 'Profili a cui hai messo mi piace ($count)';
  }

  @override
  String get discoverNoLikedProfiles =>
      'Non hai ancora messo mi piace a nessun profilo';

  @override
  String get discoverLikedProfileFallback => 'Profilo che ti piace';

  @override
  String get discoverPassedProfilesTitle => 'Profili scartati';

  @override
  String get discoverNoPassedProfiles => 'Ancora nessun profilo scartato';

  @override
  String get discoverSavedForLater => 'Salvato per dopo';

  @override
  String get discoverSpotlightFiltersTitle => 'Filtri in evidenza';

  @override
  String get discoverVerifiedOnly => 'Solo verificati';

  @override
  String discoverAgeRange(int min, int max) {
    return 'Fascia d’età: $min - $max';
  }

  @override
  String get discoverSpotlightTitle => 'Match in evidenza';

  @override
  String get discoverSpotlightSubtitle => 'Connessioni premium selezionate';

  @override
  String discoverPassedCount(int count) {
    return 'Scartati ($count)';
  }

  @override
  String get discoverOpenChatsFromDiscover => 'Apri le chat da Scopri';

  @override
  String get discoverNoNewNotifications => 'Nessuna nuova notifica';

  @override
  String get discoverNoSpotlightMatchFilters =>
      'Nessun profilo in evidenza corrisponde ai filtri';

  @override
  String get discoverAllSpotlightReviewed =>
      'Hai visto tutti i profili in evidenza!';

  @override
  String get discoverSpotlightCheckBackLater =>
      'Torna più tardi per nuovi profili in evidenza';

  @override
  String get discoverReportSubmitted => 'Segnalazione inviata.';

  @override
  String get discoverAppeal => 'Ricorso';

  @override
  String discoverAppealPrefill(String userId) {
    return 'Rivedere l’esito della moderazione per la segnalazione sull’utente $userId';
  }

  @override
  String get discoverProfileUnavailable =>
      'Questo profilo al momento non è disponibile.';

  @override
  String get discoverGoBack => 'Torna indietro';

  @override
  String get discoverPremiumView => 'Vista premium';

  @override
  String get todayLabel => 'OGGI';

  @override
  String get todayRefreshTooltip => 'Aggiorna Oggi';

  @override
  String get todayDiscoveryPreferences => 'Preferenze di scoperta';

  @override
  String get todayHeroTitle => 'Un piccolo ciao.\nSpazio per qualcosa di vero.';

  @override
  String get todayHeroSubtitle =>
      'Qualche presentazione scelta con cura, al tuo ritmo.';

  @override
  String get todaySectionPace => 'IL TUO RITMO';

  @override
  String get todayPaceTitle => 'Cosa si adatta alla tua settimana?';

  @override
  String get todayPaceBody =>
      'Il tuo ritmo, il tuo tipo di primo appuntamento, disponibilità facoltativa.';

  @override
  String get todaySetRhythm => 'Imposta il tuo ritmo';

  @override
  String get todaySectionStory => 'LA TUA STORIA';

  @override
  String get todaySectionIntroductions => 'PRESENTAZIONI DI OGGI';

  @override
  String get todayIntroductionsTitle => 'Qualche persona da conoscere';

  @override
  String get todayIntroductionsCaption =>
      'Gli interessi in comune sono un punto di partenza. La chimica sta a te scoprirla.';

  @override
  String get todayPausedTitle => 'Prenditi il tempo che ti serve.';

  @override
  String get todayPausedBody =>
      'Le presentazioni sono in pausa. Le tue conversazioni sono ancora qui.';

  @override
  String get todayManageRhythm => 'Gestisci il tuo ritmo';

  @override
  String get todayLoadingIntroductions => 'Caricamento delle presentazioni';

  @override
  String get todayFailedTitle => 'Le tue presentazioni richiedono un attimo.';

  @override
  String get todayFailedBody =>
      'Non siamo riusciti a caricare le informazioni più recenti. Riprova.';

  @override
  String get todayTryAgain => 'Riprova';

  @override
  String get todayEmptyTitle => 'Un po’ di respiro.';

  @override
  String get todayEmptyBody =>
      'Al momento non ci sono nuove presentazioni per le tue preferenze. Puoi modificare il tuo ritmo o esplorare i profili.';

  @override
  String get todayExploreProfiles => 'Esplora i profili';

  @override
  String get todayAllIntroductions => 'Tutte le presentazioni';

  @override
  String get todayBreatheTitle =>
      'Una bella connessione ha bisogno di respiro.';

  @override
  String get todayBreatheBody =>
      'Queste sono le presentazioni di oggi. Nessun conto alla rovescia e nessun obbligo di decidere su tutti.';

  @override
  String get todayExploreMore => 'Esplora altri profili';

  @override
  String get todayCommonGround => 'QUALCOSA IN COMUNE';

  @override
  String todayMeetName(String name) {
    return 'Conosci $name';
  }

  @override
  String get todayFirstHelloCoffee =>
      'Un primo saluto potrebbe essere un caffè insieme.';

  @override
  String get todayFirstHelloWalk =>
      'Un primo saluto potrebbe essere una passeggiata di giorno.';

  @override
  String get todayFirstHelloMeal =>
      'Un primo saluto potrebbe essere un pasto rilassato.';

  @override
  String get todayFirstHelloVideoCall =>
      'Un primo saluto potrebbe essere una videochiamata.';

  @override
  String get todayFirstHelloEvent =>
      'Un primo saluto potrebbe essere un evento che piace a entrambi.';

  @override
  String get todayFirstHelloDrinks =>
      'Un primo saluto potrebbe essere un drink insieme.';

  @override
  String get todayFirstHelloOther =>
      'Un primo saluto potrebbe essere qualcosa che piace a entrambi.';

  @override
  String get todaySectionTalk => 'QUALCOSA DI CUI PARLARE';

  @override
  String get todayTalkCaption =>
      'Storie, club e spunti che rendono più facile un primo saluto.';

  @override
  String get todayBlogTitle => 'Blog · Capitoli aperti';

  @override
  String get todayBlogSubtitle => 'Leggi le storie dei membri e scrivi le tue.';

  @override
  String get todayBookClubsTitle => 'Club del libro';

  @override
  String get todayBookClubsSubtitle =>
      'Un libro a settimana, di cui parlare insieme.';

  @override
  String get todayFilmClubsTitle => 'Cineclub';

  @override
  String get todayFilmClubsSubtitle =>
      'Guarda il film scelto, poi confrontate le opinioni.';

  @override
  String get todayPhotoThemesTitle => 'Temi fotografici';

  @override
  String get todayPhotoThemesSubtitle =>
      'Una foto per tema. Guarda quelle di tutti.';

  @override
  String get todayChapterStudioTitle => 'Studio Primo capitolo';

  @override
  String get todayChapterStudioSubtitle => 'Iniziate una storia insieme.';

  @override
  String get todayCoverFallbackLine => 'Una foto amata dai membri';

  @override
  String todayCoverSemantics(String name) {
    return 'Apri la copertina della settimana di $name';
  }

  @override
  String get todayCoverTitle => 'COPERTINA DELLA SETTIMANA';

  @override
  String todayCoverBy(String name) {
    return 'DI $name';
  }

  @override
  String get todayLikes => 'Mi piace';

  @override
  String get todayComments => 'Commenti';

  @override
  String get todayThisWeek => 'Questa settimana';

  @override
  String get todayWallLabel => 'DALLA COMMUNITY';

  @override
  String get todayWallTitle => 'La bacheca di oggi';

  @override
  String get todayWallCaption =>
      'Storie e foto amate dai membri — una nuova selezione ogni giorno';

  @override
  String get todayWallPrevious => 'Precedente';

  @override
  String get todayWallNext => 'Successivo';

  @override
  String get todayWallChapter => 'CAPITOLO';

  @override
  String get todayWallUntitled => 'Un capitolo senza titolo';

  @override
  String todayWallBy(String name) {
    return 'di $name';
  }

  @override
  String get todayWallEmpty =>
      'La tua bacheca si riempie man mano che i membri condividono storie e foto che amano';

  @override
  String get todayWallWrite => 'Scrivi un capitolo';

  @override
  String get todayWallShare => 'Condividi una foto';

  @override
  String get profileSetupBackTooltip => 'Indietro';

  @override
  String profileSetupStepCounter(int current, int total) {
    return 'Passaggio $current di $total';
  }

  @override
  String get profileSetupLoadErrorTitle =>
      'Impossibile caricare i dati del profilo.';

  @override
  String get profileSetupRetry => 'Riprova';

  @override
  String get profileSetupEducationHighSchool => 'Diploma di scuola superiore';

  @override
  String get profileSetupEducationBachelors => 'Laurea triennale';

  @override
  String get profileSetupEducationMasters => 'Laurea magistrale';

  @override
  String get profileSetupEducationPhd => 'Dottorato';

  @override
  String get profileSetupEducationOther => 'Altro';

  @override
  String get profileSetupPreferNotToSay => 'Preferisco non dirlo';

  @override
  String profileSetupIncomeBelow(String amount) {
    return 'Meno di $amount';
  }

  @override
  String get profileSetupFrequencyNever => 'Mai';

  @override
  String get profileSetupFrequencySocially => 'In compagnia';

  @override
  String get profileSetupFrequencyOccasionally => 'Occasionalmente';

  @override
  String get profileSetupFrequencyRegularly => 'Regolarmente';

  @override
  String get profileSetupGenderMan => 'Uomo';

  @override
  String get profileSetupGenderWoman => 'Donna';

  @override
  String get profileSetupGenderOther => 'Altro';

  @override
  String profileSetupBioTooShort(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'La bio deve contenere almeno $min caratteri.',
      one: 'La bio deve contenere almeno 1 carattere.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupSaveFailed => 'Salvataggio non riuscito — riprova.';

  @override
  String get profileSetupCouldNotSaveChanges =>
      'Impossibile salvare le modifiche. Riprova.';

  @override
  String get profileSetupAboutTitle => 'Fai brillare il tuo profilo';

  @override
  String get profileSetupAboutSubtitle =>
      'Questi dettagli aiutano a trovare match migliori.';

  @override
  String get profileSetupBioLabel => 'Bio';

  @override
  String profileSetupBioHint(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Racconta qualcosa di te (min. $min caratteri)',
      one: 'Racconta qualcosa di te (min. 1 carattere)',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupHeightLabel => 'Altezza (cm)';

  @override
  String get profileSetupHeightHint => 'Seleziona l’altezza';

  @override
  String profileSetupHeightValue(int cm) {
    return '$cm cm';
  }

  @override
  String get profileSetupEducationLabel => 'Istruzione';

  @override
  String get profileSetupEducationHint => 'Seleziona l’istruzione';

  @override
  String get profileSetupProfessionLabel => 'Professione';

  @override
  String get profileSetupProfessionHint => 'es. ingegnere del software';

  @override
  String get profileSetupIncomeLabel => 'Reddito (facoltativo)';

  @override
  String get profileSetupLifestyleTitle => 'Stile di vita';

  @override
  String get profileSetupDrinkingLabel => 'Alcol';

  @override
  String get profileSetupSmokingLabel => 'Fumo';

  @override
  String get profileSetupSelectHint => 'Seleziona';

  @override
  String get profileSetupReligionOptionalLabel => 'Religione (facoltativo)';

  @override
  String get profileSetupContinue => 'Continua';

  @override
  String get profileSetupSaveAbout => 'Salva «Su di me»';

  @override
  String get profileSetupPhotosSaved => 'Foto salvate.';

  @override
  String profileSetupPhotosMaxReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Puoi caricare al massimo $max foto.',
      one: 'Puoi caricare solo 1 foto.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupRemovePhotoTitle => 'Rimuovere questa foto?';

  @override
  String get profileSetupRemovePhotoBody =>
      'Verrà rimossa dal tuo profilo ed eliminata dall’archivio.';

  @override
  String get profileSetupCancel => 'Annulla';

  @override
  String get profileSetupRemove => 'Rimuovi';

  @override
  String profileSetupPhotosMinRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Carica almeno $min foto per continuare.',
      one: 'Carica almeno 1 foto per continuare.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTitle => 'Aggiungi le tue foto';

  @override
  String profileSetupPhotosSubtitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Aggiungi almeno $min foto per ottenere match',
      one: 'Aggiungi almeno 1 foto per ottenere match',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupChooseSource => 'Scegli la fonte';

  @override
  String get profileSetupGallery => 'Galleria';

  @override
  String get profileSetupCamera => 'Fotocamera';

  @override
  String get profileSetupPhotoRequirements =>
      'JPEG, PNG, WebP o HEIC · minimo 300×300 · 10 MB ciascuna · 50 MB in totale';

  @override
  String profileSetupPhotosTipEmpty(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Aggiungi almeno $min foto per mostrare lati diversi di te.',
      one: 'Aggiungi almeno 1 foto per mostrare lati diversi di te.',
    );
    return '$_temp0';
  }

  @override
  String profileSetupPhotosTipMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aggiungi ancora $count foto per sbloccare tutti i match.',
      one: 'Aggiungi ancora 1 foto per sbloccare tutti i match.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTipDone =>
      'Ottimo! Puoi riordinare le foto trascinandole.';

  @override
  String get profileSetupYourPhotosHeading =>
      'Le tue foto  •  trascina per riordinare';

  @override
  String get profileSetupContinueToAbout => 'Continua con «Su di me»';

  @override
  String get profileSetupSavePhotos => 'Salva foto';

  @override
  String get profileSetupPrimaryPhoto => 'Foto principale';

  @override
  String profileSetupPhotoNumber(int number) {
    return 'Foto $number';
  }

  @override
  String get profileSetupShownFirst => 'Mostrata per prima sul tuo profilo';

  @override
  String get profileSetupDragHandleHint =>
      'Trascina la maniglia per riordinare';

  @override
  String get profileSetupAwaitingSafetyReview =>
      'In attesa di verifica di sicurezza';

  @override
  String get profileSetupSafetyCheckInProgress =>
      'Controllo di sicurezza in corso';

  @override
  String get profileSetupSetAsProfilePicture => 'Imposta come foto profilo';

  @override
  String get profileSetupProfilePictureSelected => 'Foto profilo selezionata';

  @override
  String get profileSetupRemovePhotoTooltip => 'Rimuovi foto';

  @override
  String get profileSetupPhotoTooLarge =>
      'Questa foto supera il limite di 10 MB.';

  @override
  String get profileSetupPhotoUnsupportedType =>
      'Usa una foto JPEG, PNG, WebP o HEIC.';

  @override
  String get profileSetupPhotoBadDimensions =>
      'Le dimensioni della foto devono essere tra 300×300 e 4096×4096.';

  @override
  String get profileSetupPhotoQuotaReached =>
      'Hai raggiunto il limite di foto del profilo.';

  @override
  String get profileSetupPhotoStorageFull =>
      'L’archivio foto è temporaneamente pieno. Riprova più tardi.';

  @override
  String get profileSetupPhotoUpdateFailed =>
      'Aggiornamento della foto non riuscito. Riprova.';

  @override
  String profileSetupPhotoMaxAllowed(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Sono consentite al massimo $max foto.',
      one: 'È consentita al massimo 1 foto.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPreferencesLoadFailed =>
      'Impossibile caricare le preferenze';

  @override
  String get profileSetupOfflineBanner =>
      'Modalità offline — alcuni dati potrebbero non essere aggiornati.';

  @override
  String get profileSetupYourPreferences => 'Le tue preferenze';

  @override
  String get profileSetupEditPreferencesTitle => 'Modifica preferenze';

  @override
  String get profileSetupFinishAndFindMatches => 'Completa e trova match';

  @override
  String get profileSetupSavePreferences => 'Salva preferenze';

  @override
  String get profileSetupSelectGenderPreference =>
      'Seleziona almeno un genere.';

  @override
  String get profileSetupFinishFailed =>
      'Impossibile completare la configurazione. Controlla foto e preferenze, poi riprova.';

  @override
  String get profileSetupPreferencesSaveFailed =>
      'Al momento non è stato possibile salvare alcune preferenze.';

  @override
  String get profileSetupPreferencesSaved => 'Preferenze salvate.';

  @override
  String get profileSetupTabBasic => 'Base';

  @override
  String get profileSetupTabAdvanced => 'Avanzate';

  @override
  String get profileSetupLookingFor => 'Cerco';

  @override
  String get profileSetupSeekingMen => 'Uomini';

  @override
  String get profileSetupSeekingWomen => 'Donne';

  @override
  String get profileSetupSeekingOther => 'Altro';

  @override
  String profileSetupAgeRangeTitle(int min, int max) {
    return 'Fascia d’età: $min – $max';
  }

  @override
  String profileSetupMaxDistanceTitle(int km) {
    return 'Distanza max: $km km';
  }

  @override
  String profileSetupDistanceValue(int km) {
    return '$km km';
  }

  @override
  String get profileSetupRelationshipIntent => 'Tipo di relazione';

  @override
  String get profileSetupSeriousOnly => 'Solo relazione seria';

  @override
  String get profileSetupSeriousOnlySubtitle =>
      'Mostra solo chi cerca un impegno';

  @override
  String get profileSetupVerifiedOnly => 'Solo profili verificati';

  @override
  String get profileSetupVerifiedOnlySubtitle =>
      'Solo account con documento verificato';

  @override
  String get profileSetupHookupsOnly => 'Solo avventure';

  @override
  String get profileSetupHookupsOnlySubtitle =>
      'Mostra solo profili per avventure';

  @override
  String get profileSetupLocation => 'Posizione';

  @override
  String get profileSetupCountry => 'Paese';

  @override
  String get profileSetupStateRegion => 'Stato / Regione';

  @override
  String get profileSetupCity => 'Città';

  @override
  String get profileSetupBackgroundCulture => 'Origini e cultura';

  @override
  String get profileSetupReligionPreference => 'Religione';

  @override
  String get profileSetupMotherTongue => 'Lingua madre';

  @override
  String get profileSetupLanguage => 'Lingua';

  @override
  String get profileSetupDietPreference => 'Preferenza alimentare';

  @override
  String get profileSetupWorkoutFrequency => 'Frequenza di allenamento';

  @override
  String get profileSetupDietType => 'Tipo di dieta';

  @override
  String get profileSetupSleepSchedule => 'Ritmo del sonno';

  @override
  String get profileSetupTravelStyle => 'Stile di viaggio';

  @override
  String get profileSetupPoliticalComfortRange => 'Affinità politica';

  @override
  String get profileSetupInterestsPersonality => 'Interessi e personalità';

  @override
  String get profileSetupInstagramHandle => 'Nome utente Instagram (senza @)';

  @override
  String get profileSetupIntentTags =>
      'Intenzioni (lungo termine, matrimonio, avventura…)';

  @override
  String get profileSetupHobbiesField => 'Hobby (separati da virgole)';

  @override
  String get profileSetupFavouriteBooksField =>
      'Libri preferiti (separati da virgole)';

  @override
  String get profileSetupFavouriteNovelsField =>
      'Romanzi preferiti (separati da virgole)';

  @override
  String get profileSetupFavouriteSongsField =>
      'Canzoni preferite (separate da virgole)';

  @override
  String get profileSetupExtraCurricularField =>
      'Attività extracurricolari (separate da virgole)';

  @override
  String get profileSetupAdditionalInformation => 'Informazioni aggiuntive';

  @override
  String get profileSetupPetPreference => 'Animali domestici';

  @override
  String get profileSetupDealBreakers => 'Non negoziabili';

  @override
  String get profileSetupTagsField => 'Tag (separati da virgole)';

  @override
  String get profileSetupNameRequired => 'Il nome è obbligatorio.';

  @override
  String get profileSetupDobRequired => 'La data di nascita è obbligatoria.';

  @override
  String profileSetupPhotosRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Sono necessarie almeno $min foto.',
      one: 'È necessaria almeno 1 foto.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupServerError => 'Errore del server';

  @override
  String get profileSetupNetworkError => 'Errore di rete — riprova.';

  @override
  String get profileSetupGenericError => 'Qualcosa è andato storto. Riprova.';

  @override
  String get profileSetupPreviewTitle => 'Anteprima del tuo profilo';

  @override
  String get profileSetupPreviewSubtitle => 'Ecco come ti vedranno gli altri.';

  @override
  String profileSetupNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String profileSetupDrinksChip(String value) {
    return 'Alcol: $value';
  }

  @override
  String profileSetupSmokesChip(String value) {
    return 'Fumo: $value';
  }

  @override
  String get profileSetupCompleteProfile => 'Completa il profilo';

  @override
  String profileSetupCompletionPercent(int percent) {
    return 'Profilo completato: $percent%';
  }

  @override
  String get profileEditTitle => 'Modifica profilo';

  @override
  String get profileEditRefreshTooltip => 'Aggiorna profilo';

  @override
  String get profileEditAboutYou => 'Su di te';

  @override
  String get profileEditEditAbout => 'Modifica «Su di me»';

  @override
  String get profileEditName => 'Nome';

  @override
  String get profileEditPhone => 'Telefono';

  @override
  String get profileEditDateOfBirth => 'Data di nascita';

  @override
  String get profileEditGender => 'Genere';

  @override
  String get profileEditHeight => 'Altezza';

  @override
  String get profileEditIncomeRange => 'Fascia di reddito';

  @override
  String get profileEditLocationSocial => 'Posizione e social';

  @override
  String get profileEditEditPreferences => 'Modifica preferenze';

  @override
  String get profileEditState => 'Stato / Regione';

  @override
  String get profileEditInstagram => 'Instagram';

  @override
  String get profileEditDatingPreferences => 'Preferenze di incontro';

  @override
  String get profileEditSeeking => 'Cerco';

  @override
  String get profileEditAgeRange => 'Fascia d’età';

  @override
  String profileEditAgeRangeValue(int min, int max) {
    return '$min–$max';
  }

  @override
  String get profileEditMaxDistance => 'Distanza max';

  @override
  String get profileEditEducationFilter => 'Filtro istruzione';

  @override
  String get profileEditSeriousOnly => 'Solo relazioni serie';

  @override
  String get profileEditVerifiedOnly => 'Solo verificati';

  @override
  String get profileEditHookupOnly => 'Solo avventure';

  @override
  String get profileEditYes => 'Sì';

  @override
  String get profileEditNo => 'No';

  @override
  String get profileEditIntent => 'Intenzione';

  @override
  String get profileEditLanguages => 'Lingue';

  @override
  String get profileEditDealBreakers => 'Non negoziabili';

  @override
  String get profileEditReligion => 'Religione';

  @override
  String get profileEditPets => 'Animali';

  @override
  String get profileEditWorkout => 'Allenamento';

  @override
  String get profileEditPoliticsComfort => 'Affinità politica';

  @override
  String get profileEditInterestsDetails => 'Interessi e dettagli';

  @override
  String get profileEditHobbies => 'Hobby';

  @override
  String get profileEditBooks => 'Libri';

  @override
  String get profileEditNovels => 'Romanzi';

  @override
  String get profileEditSongs => 'Canzoni';

  @override
  String get profileEditExtraCurriculars => 'Attività extracurricolari';

  @override
  String get profileEditAdditionalInfo => 'Info aggiuntive';

  @override
  String get profileEditNotSet => 'Non impostato';

  @override
  String get profileEditLoadingTitle => 'Caricamento del profilo salvato';

  @override
  String get profileEditLoadingBody =>
      'Recupero delle informazioni salvate durante la creazione dell’account.';

  @override
  String get profileEditYourProfile => 'Il tuo profilo';

  @override
  String profileEditPercentComplete(int percent) {
    return '$percent% completato';
  }

  @override
  String get profileEditPhotoGallery => 'Galleria foto';

  @override
  String get profileEditManagePhotos => 'Gestisci foto';

  @override
  String get profileEditNoPhotos => 'Nessuna foto caricata.';

  @override
  String get profileEditPrimaryBadge => 'Principale';

  @override
  String get engagementHubPromptLoading => 'Caricamento della domanda di oggi';

  @override
  String get engagementHubPromptIntro =>
      'Rispondi a una domanda al giorno e allunga la tua serie.';

  @override
  String engagementHubPromptRepliedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persone hanno risposto oggi',
      one: '1 persona ha risposto oggi',
    );
    return '$_temp0';
  }

  @override
  String engagementHubPromptStreakSummary(int days, int similar) {
    return 'Serie $days g · risposte simili: $similar';
  }

  @override
  String get engagementHubBlogTitle => 'Blog · Open Chapters';

  @override
  String get engagementHubBlogSubtitle =>
      'Leggi storie, condividi foto e scrivi la tua.';

  @override
  String get engagementHubPhotoThemesTitle => 'Temi fotografici';

  @override
  String get engagementHubPhotoThemesSubtitle =>
      'Condividi una foto per tema e guarda quelle degli altri.';

  @override
  String get engagementHubClubsTitle => 'Club di libri e film';

  @override
  String get engagementHubClubsSubtitle =>
      'Segui la scelta della settimana, parlane e valutala.';

  @override
  String get engagementHubCityPilotTitle => 'Il pilota in città';

  @override
  String get engagementHubCityPilotSubtitle =>
      'Una piccola community. Conversazioni che diventano piani.';

  @override
  String get engagementDailyPromptTitle => 'Serie della domanda del giorno';

  @override
  String get engagementHubVoiceTitle => 'Rompighiaccio vocali guidati';

  @override
  String get engagementHubVoiceSubtitle =>
      'Un’intro vocale guidata di 20-45 s per match al giorno';

  @override
  String get engagementCirclesTitle => 'Sfide dei circoli locali';

  @override
  String get engagementHubCirclesSubtitle =>
      'Entra in un circolo della tua città e invia la tua risposta della settimana';

  @override
  String get engagementHubCoffeeTitle => 'Sondaggio caffè di gruppo';

  @override
  String get engagementHubCoffeeSubtitle =>
      'Crea, vota e chiudi semplici sondaggi per incontrarvi';

  @override
  String get engagementHubGroupsTitle => 'Gruppi';

  @override
  String get engagementHubGroupsSubtitle =>
      'Community di stile di vita e gruppi privati di amici';

  @override
  String get engagementHubRoomsSubtitle =>
      'Stanze di chat dal vivo: entra, parla, fatti degli amici';

  @override
  String get engagementHubFriendsTitle => 'Amici e presentazioni';

  @override
  String get engagementHubFriendsSubtitle =>
      'Invita un amico fidato, anche se non sta cercando l’anima gemella';

  @override
  String get engagementLevelTitle => 'Livello e XP';

  @override
  String get engagementHubLevelSubtitle =>
      'Segui l’attività significativa, i premi di livello e i requisiti di fiducia';

  @override
  String get engagementHubPaywallFree =>
      'La progressione di base resta senza paywall.';

  @override
  String get engagementHubPolicyUpdating =>
      'La policy di monetizzazione è in aggiornamento.';

  @override
  String engagementHubPremiumAreas(String features) {
    return 'Aree premium facoltative: $features';
  }

  @override
  String get engagementHubEyebrow => 'PARTECIPA';

  @override
  String get engagementHubTitle => 'Create qualcosa insieme.';

  @override
  String get engagementHubSubtitle =>
      'Match più solidi grazie a fiducia e attività condivise.';

  @override
  String get engagementHubSectionCreate => 'CREA E CONDIVIDI';

  @override
  String get engagementHubSectionCreateCaption =>
      'Storie, foto e club che fanno nascere vere conversazioni.';

  @override
  String get engagementHubSectionMeet => 'CONOSCI PERSONE';

  @override
  String get engagementHubSectionMeetCaption =>
      'Piccoli gruppi, domande e piani al tuo ritmo.';

  @override
  String get engagementHubSectionProgress => 'FIDUCIA E PROGRESSI';

  @override
  String get engagementHubSectionProgressCaption =>
      'Il tuo livello, i tuoi badge e chi può trovarti.';

  @override
  String get engagementVoiceAppBarTitle => 'Una voce, un po’ più vicini';

  @override
  String get engagementVoiceHeadline =>
      'Fai in modo che il tuo ciao\nsuoni come te.';

  @override
  String get engagementVoiceIntro =>
      'Una presentazione facoltativa di 20–45 secondi, condivisa solo in questa conversazione. Anche il testo è sempre benvenuto.';

  @override
  String engagementVoiceYouAndName(String name) {
    return 'Tu e $name';
  }

  @override
  String get engagementVoiceYouAndYourMatch => 'Tu e il tuo match';

  @override
  String get engagementVoicePrivate => 'Visibile solo in questa conversazione';

  @override
  String get engagementVoiceConversationsLoadFailed =>
      'Impossibile caricare le tue conversazioni.';

  @override
  String get engagementVoiceNoMatches =>
      'Quando avrai un match, potrai condividere qui una presentazione vocale. Con calma.';

  @override
  String get engagementVoicePickConversation => 'A chi vuoi dire ciao?';

  @override
  String get engagementVoiceStartingPoint => 'Un piccolo spunto';

  @override
  String get engagementVoiceChoosePrompt => 'Scegli uno spunto';

  @override
  String get engagementVoiceTranscriptLabel => 'Le tue parole, per iscritto';

  @override
  String get engagementVoiceTranscriptHelper =>
      'Scrivi quello che dici, così si può anche leggere. Non è una trascrizione automatica.';

  @override
  String engagementVoiceStop(int seconds) {
    return 'Stop · $seconds s';
  }

  @override
  String get engagementVoiceRecord => 'Registra il tuo ciao';

  @override
  String engagementVoiceRecordAgain(int seconds) {
    return 'Registra di nuovo · $seconds s';
  }

  @override
  String get engagementVoiceRecordingReady =>
      'Registrazione pronta. Controlla il testo prima di inviare.';

  @override
  String get engagementVoiceRecordingShort =>
      'Un po’ troppo breve. Registra 20–45 secondi.';

  @override
  String get engagementVoiceDiscard => 'Elimina registrazione';

  @override
  String get engagementVoiceSubmitted =>
      'Presentazione inviata. Le registrazioni approvate compaiono qui sotto.';

  @override
  String get engagementVoiceSending => 'Invio in corso…';

  @override
  String get engagementVoiceShare => 'Condividi il tuo ciao';

  @override
  String get engagementVoiceCheckedNote =>
      'Le registrazioni vengono controllate prima di essere condivise. Non c’è riproduzione automatica.';

  @override
  String get engagementVoiceYourIntros => 'Le vostre presentazioni vocali';

  @override
  String get engagementVoiceLatestNote =>
      'Le ultime 20 registrazioni approvate in questa conversazione. I testi sono sempre leggibili.';

  @override
  String get engagementVoiceIntrosLoadFailed =>
      'Impossibile caricare le presentazioni. La conversazione potrebbe non essere più disponibile.';

  @override
  String get engagementVoiceNothingYet =>
      'Ancora niente. Un semplice ciao è un buon inizio.';

  @override
  String get engagementVoiceYourHello => 'Il tuo ciao';

  @override
  String engagementVoiceHelloFromName(String name) {
    return 'Un ciao da $name';
  }

  @override
  String get engagementVoiceHelloFromYourMatch => 'Un ciao dal tuo match';

  @override
  String get engagementVoiceTranscriptHeading => 'TESTO';

  @override
  String get engagementVoiceStopPlayback => 'Interrompi riproduzione';

  @override
  String engagementVoiceListen(int seconds) {
    return 'Ascolta · $seconds s';
  }

  @override
  String get engagementVoiceReloadPrompts => 'Ricarica gli spunti';

  @override
  String get engagementVoiceMicPermission =>
      'Consenti l’accesso al microfono per registrare. Puoi comunque leggere i testi.';

  @override
  String get engagementVoiceStartFailed =>
      'Impossibile avviare la registrazione. Controlla l’accesso al microfono e riprova.';

  @override
  String get engagementVoiceSaveFailed =>
      'Impossibile salvare la registrazione. Riprova.';

  @override
  String get engagementVoicePromptsLoadFailed =>
      'Al momento non è possibile caricare gli spunti vocali.';

  @override
  String get engagementSessionUnavailable => 'Sessione non disponibile.';

  @override
  String get engagementVoiceChooseConversation =>
      'Scegli prima una conversazione.';

  @override
  String get engagementVoiceSelectPrompt => 'Scegli uno spunto vocale.';

  @override
  String get engagementVoiceEnterTranscript => 'Inserisci il testo.';

  @override
  String get engagementVoiceSessionFailed =>
      'Impossibile creare la sessione del rompighiaccio vocale.';

  @override
  String get engagementVoiceSendFailed =>
      'Al momento non è possibile inviare il rompighiaccio vocale.';

  @override
  String get engagementVoicePlaybackUserRequired =>
      'Serve un ID utente per registrare la riproduzione.';

  @override
  String get engagementVoiceMarkPlaybackFailed =>
      'Al momento non è possibile registrare la riproduzione.';

  @override
  String get engagementVoicePlayFailed =>
      'Al momento non è possibile riprodurre questa registrazione.';

  @override
  String get chatStarterSmile => 'Cosa ti ha fatto sorridere oggi?';

  @override
  String get chatStarterSunday => 'La tua domenica ideale: racconta.';

  @override
  String get chatStarterCoffee =>
      'Un caffè, una passeggiata o una piccola avventura?';

  @override
  String get chatWelcomeTitle => 'Ogni bella storia\ninizia con un ciao.';

  @override
  String get chatWelcomePending =>
      'La conversazione si aprirà quando il match sarà confermato.';

  @override
  String get chatWelcomeBody =>
      'Non serve la frase d’apertura perfetta. Sii te stesso.';

  @override
  String get chatInspirationEyebrow => 'UN PO’ DI ISPIRAZIONE';

  @override
  String get chatAllConversations => 'Tutte le conversazioni';

  @override
  String get chatMakeConnectionEyebrow => 'CREA UN LEGAME';

  @override
  String get chatLessSmallTalk => 'Un po’ meno di chiacchiere di circostanza.';

  @override
  String get chatLessSmallTalkBody =>
      'Chiedi delle cose che l’accendono. Condividi qualcosa che ti somiglia.';

  @override
  String get chatFindTheWords => 'Trova le parole';

  @override
  String get chatSendJoy => 'Regala un po’ di gioia';

  @override
  String get chatPaceTitle => 'I tuoi tempi. I tuoi spazi.';

  @override
  String get chatPaceBody =>
      'Condividi solo ciò che ti fa sentire a tuo agio. Un buon legame rispetta i tuoi confini.';

  @override
  String get chatWriteMessageHint => 'Scrivi un messaggio…';

  @override
  String get chatConversationPaused => 'Conversazione in pausa';

  @override
  String get chatSendingMessageTooltip => 'Invio del messaggio';

  @override
  String get chatSendMessageTooltip => 'Invia messaggio';

  @override
  String get chatSendGiftTooltip => 'Invia un regalo';

  @override
  String get chatAddEmojiTooltip => 'Aggiungi un’emoji';

  @override
  String get chatDraftedWithHelp => 'Scritto con un aiuto';

  @override
  String get chatHelpMeSayIt => 'Aiutami a dirlo';

  @override
  String get chatEnterToSendHint =>
      'Invio per inviare · Maiusc + Invio per andare a capo';

  @override
  String get chatToday => 'Oggi';

  @override
  String get chatYesterday => 'Ieri';

  @override
  String get chatGiftOptions => 'Opzioni regalo';

  @override
  String get chatStatusRead => 'Letto';

  @override
  String get chatStatusDelivered => 'Consegnato';

  @override
  String get chatStatusSent => 'Inviato';

  @override
  String get chatGestureGiftHeading => 'Gesto + rosa in regalo';

  @override
  String get chatGiftForYouHeading => 'Un pensiero per te';

  @override
  String chatGiftTone(String tone) {
    return 'Tono: $tone';
  }

  @override
  String get chatFreeGift => 'Regalo gratuito';

  @override
  String get chatCopilotKindOpener => 'Apertura';

  @override
  String get chatCopilotKindReply => 'Risposta';

  @override
  String get chatCopilotKindDateIdea => 'Idea per un appuntamento';

  @override
  String get chatCopilotToneWarm => 'Caloroso';

  @override
  String get chatCopilotTonePlayful => 'Giocoso';

  @override
  String get chatCopilotToneDirect => 'Diretto';

  @override
  String chatCopilotIntro(String name) {
    return 'Una bozza con il tuo stile, basata sul profilo di $name e sulla vostra conversazione. Non viene mai inviata al posto tuo e, se la invii così com’è, vedrà che è stata scritta con un aiuto.';
  }

  @override
  String chatCopilotDisclosure(String disclosure, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ti restano $count bozze oggi.',
      one: 'Ti resta 1 bozza oggi.',
    );
    return '$disclosure $_temp0';
  }

  @override
  String get chatCopilotDraftIt => 'Scrivi la bozza';

  @override
  String get chatCopilotTryAnother => 'Un’altra';

  @override
  String get chatCopilotUseAndEdit => 'Usa e modifica';

  @override
  String get chatCopilotEmpty => 'Il copilota non ha restituito nulla.';

  @override
  String get chatCopilotUnavailable => 'Il copilota non è disponibile.';

  @override
  String get chatErrorMatchEnded => 'Questo match è terminato.';

  @override
  String get chatErrorLoadMessages =>
      'Impossibile caricare i messaggi. Riprova.';

  @override
  String get chatErrorLockedQuest =>
      'La chat è bloccata finché la sfida non viene approvata.';

  @override
  String get chatErrorSendFailed => 'Impossibile inviare il messaggio.';

  @override
  String get chatErrorDeleteFailed => 'Impossibile eliminare il messaggio.';

  @override
  String get chatErrorDeleteWindowExpired =>
      'Tempo per eliminare scaduto (24 h).';

  @override
  String get chatErrorOnlyReceivedGifts =>
      'Si possono gestire solo i regali ricevuti.';

  @override
  String get chatErrorGiftGone => 'Questo regalo non è più disponibile.';

  @override
  String get chatErrorGiftReportFailed =>
      'Impossibile segnalare questo regalo. Riprova.';

  @override
  String get chatErrorGiftHideFailed =>
      'Impossibile nascondere questo regalo. Riprova.';

  @override
  String get chatErrorGiftsUnavailable =>
      'Le rose in regalo al momento non sono disponibili.';

  @override
  String chatErrorNotEnoughCoins(String gift) {
    return 'Non hai abbastanza monete per inviare $gift.';
  }

  @override
  String get chatErrorNotEnoughCoinsSelected =>
      'Non hai abbastanza monete per il regalo scelto.';

  @override
  String get chatErrorWalletFrozen =>
      'Le tue monete sono bloccate mentre verifichiamo un acquisto rimborsato. I regali gratuiti restano disponibili.';

  @override
  String get chatErrorGiftVelocity =>
      'Hai inviato molti regali in poco tempo. Riprova più tardi.';

  @override
  String get chatErrorFreeGiftUsed =>
      'Hai già inviato il regalo gratuito di oggi. Ne avrai uno nuovo dopo mezzanotte UTC.';

  @override
  String chatErrorGiftNotAvailable(String gift) {
    return '$gift al momento non è disponibile.';
  }

  @override
  String get chatErrorGiftNeedsActiveMatch =>
      'I regali si possono inviare solo in un match attivo.';

  @override
  String get chatErrorExclusiveGiftOnce =>
      'Questo regalo esclusivo si può inviare solo una volta oggi.';

  @override
  String get chatErrorGiftFailed => 'Impossibile inviare il regalo.';

  @override
  String get chatErrorSessionUnavailable => 'Sessione utente non disponibile.';

  @override
  String get chatErrorConversationUnavailable =>
      'Conversazione non disponibile.';

  @override
  String get verificationLandingTitle => 'Verificati in tutta sicurezza';

  @override
  String get verificationLandingBody =>
      'Carica un documento d\'identità ufficiale ben leggibile e un selfie recente. I file vengono trasmessi in forma crittografata e conservati in un\'area riservata.';

  @override
  String get verificationLandingDisclaimer =>
      'La verifica aggiunge contesto al tuo profilo. Non garantisce mai l\'identità, le intenzioni o la sicurezza di un\'altra persona.';

  @override
  String get verificationViewVerifiedStatus => 'Vedi stato verificato';

  @override
  String get verificationViewReviewStatus => 'Vedi stato della verifica';

  @override
  String get verificationStartButton => 'Avvia verifica sicura';

  @override
  String get verificationUploadIdTitle => 'Carica documento';

  @override
  String get verificationUploadIdInstruction =>
      'Scatta o carica una foto nitida del tuo documento d\'identità ufficiale.';

  @override
  String get verificationGallery => 'Galleria';

  @override
  String get verificationCamera => 'Fotocamera';

  @override
  String get verificationNext => 'Avanti';

  @override
  String get verificationSelfieTitle => 'Selfie';

  @override
  String get verificationSelfieInstruction => 'Scatta un selfie nitido.';

  @override
  String get verificationUploadFailed =>
      'Non è stato possibile caricare i documenti. Controlla i file e riprova.';

  @override
  String get verificationSubmit => 'Invia';

  @override
  String get verificationStatusTitle => 'Stato della verifica';

  @override
  String get verificationRetry => 'Riprova';

  @override
  String get verificationStatusVerified => 'Verificato';

  @override
  String get verificationStatusVerifiedMessage => 'La tua verifica è completa.';

  @override
  String get verificationStatusRejected => 'Rifiutato';

  @override
  String get verificationStatusRejectedFallback => 'Riprova.';

  @override
  String get verificationStatusPending => 'In attesa';

  @override
  String get verificationStatusPendingMessage => 'Verifica in corso.';

  @override
  String get verificationStatusNotStarted => 'Non avviata';

  @override
  String get verificationStatusNotStartedMessage =>
      'Avvia la verifica dalle Impostazioni.';

  @override
  String get safetySosTitle => 'SOS di emergenza';

  @override
  String get safetySosDefaultMessage =>
      'Ho bisogno di aiuto immediato. Per favore, verificate che stia bene.';

  @override
  String get safetySosHeadline => 'Attiva un avviso di emergenza';

  @override
  String get safetySosIntro =>
      'Se sei in pericolo immediato, contatta prima i servizi di emergenza locali. Questo avviso viene registrato per il team sicurezza.';

  @override
  String get safetySosLevelUrgent => 'Urgente';

  @override
  String get safetySosLevelCritical => 'Critico';

  @override
  String get safetySosMessageLabel => 'Messaggio per il team sicurezza';

  @override
  String get safetySosActivating => 'Attivazione…';

  @override
  String get safetySosActivate => 'Attiva SOS';

  @override
  String get safetySosLocationNote =>
      'La posizione viene richiesta solo per questo avviso. Puoi continuare anche se neghi l\'autorizzazione.';

  @override
  String get safetySosHistoryTitle => 'Cronologia avvisi';

  @override
  String get safetySosHistoryEmpty => 'Nessun avviso SOS registrato.';

  @override
  String safetySosHistoryHeading(String level, String status) {
    return '$level · $status';
  }

  @override
  String get safetySosAlertLevelLow => 'BASSO';

  @override
  String get safetySosAlertLevelMedium => 'MEDIO';

  @override
  String get safetySosAlertLevelHigh => 'ALTO';

  @override
  String get safetySosAlertLevelCritical => 'CRITICO';

  @override
  String get safetySosAlertStatusOpen => 'aperto';

  @override
  String get safetySosAlertStatusActive => 'attivo';

  @override
  String get safetySosAlertStatusAcknowledged => 'preso in carico';

  @override
  String get safetySosAlertStatusResolved => 'risolto';

  @override
  String safetySosHistoryMetaWithLocation(String date) {
    return '$date · con posizione';
  }

  @override
  String safetySosHistoryMetaNoLocation(String date) {
    return '$date · senza posizione';
  }

  @override
  String safetySosResolution(String note) {
    return 'Risoluzione: $note';
  }

  @override
  String get safetySosConfirmTitle => 'Attivare l\'SOS ora?';

  @override
  String get safetySosConfirmBody =>
      'Viene creato un avviso di emergenza per il team sicurezza e si tenta di allegare la tua posizione attuale.';

  @override
  String get safetySosCancel => 'Annulla';

  @override
  String get safetySosConfirmActivate => 'Attiva';

  @override
  String get safetySosActivatedTitle => 'Avviso SOS attivato';

  @override
  String get safetySosActivatedWithLocation =>
      'Il tuo avviso e la tua posizione attuale sono stati registrati.';

  @override
  String get safetySosActivatedWithoutLocation =>
      'Il tuo avviso è stato registrato senza posizione. L\'autorizzazione alla posizione non era disponibile o è stata negata.';

  @override
  String get safetySosDone => 'Fatto';

  @override
  String get safetySosSignInToView => 'Accedi per vedere la cronologia SOS.';

  @override
  String get safetySosLoadFailed => 'Impossibile caricare la cronologia SOS.';

  @override
  String get safetySosSignInToActivate => 'Accedi prima di attivare l\'SOS.';

  @override
  String get safetySosActivateFailed => 'Impossibile attivare l\'SOS.';

  @override
  String get photoThemesTitle => 'Temi fotografici';

  @override
  String get photoThemesSignIn => 'Accedi per vedere i temi fotografici.';

  @override
  String get photoThemesHeroTitle => 'Mostra un po\' del tuo mondo';

  @override
  String get photoThemesHeroSubtitle =>
      'Scegli un tema, condividi una foto e guarda come hanno risposto gli altri. È un modo facile per iniziare una conversazione.';

  @override
  String get photoThemesLoadFailed => 'Impossibile caricare i temi';

  @override
  String get photoThemesCheckConnection => 'Controlla la connessione.';

  @override
  String get photoThemesLookAround => 'Puoi dare un\'occhiata';

  @override
  String get photoThemesEligibilityShareOwn =>
      'Completa il profilo con due foto approvate per condividere le tue.';

  @override
  String get photoThemesNewPromptsTitle => 'Nuovi temi in arrivo';

  @override
  String get photoThemesNewPromptsBody =>
      'Torna presto per trovare qualcosa da condividere.';

  @override
  String photoThemesSharedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count condivise',
      one: '$count condivisa',
    );
    return '$_temp0';
  }

  @override
  String get photoThemesYouShared => 'Hai condiviso ✓';

  @override
  String get photoThemesBeFirst => 'Condividi per primo →';

  @override
  String get photoThemesSeeEveryone => 'Guarda le foto di tutti →';

  @override
  String get photoThemesSharedSnack => 'La tua foto è condivisa. Ottimo!';

  @override
  String get photoThemesShareFailed =>
      'Impossibile condividere la foto. Usa un JPEG o PNG fino a 10 MB.';

  @override
  String get photoThemesEligibilityShare =>
      'Completa il profilo con due foto approvate per condividere.';

  @override
  String get photoThemesAlreadyShared =>
      'Hai già condiviso per questo tema. Rimuovi la tua foto per condividerne una nuova.';

  @override
  String get photoThemesThemeFallback => 'Tema fotografico';

  @override
  String get photoThemesShareTooltip => 'Condividi una foto per questo tema';

  @override
  String get photoThemesShareYourPhoto => 'Condividi la tua foto';

  @override
  String get photoThemesNoPhotosYet => 'Ancora nessuna foto';

  @override
  String photoThemesBeFirstFor(String title) {
    return 'Condividi per primo per “$title”';
  }

  @override
  String get photoThemesLoadingPrompt => 'Caricamento del tema…';

  @override
  String get photoThemesPhotosLoadFailed => 'Impossibile caricare le foto';

  @override
  String get photoThemesEmptyMessage =>
      'La tua foto potrebbe essere quella che fa parlare tutti.';

  @override
  String get photoThemesMoreFailed =>
      'Impossibile caricare altre foto. Ricarica';

  @override
  String get photoThemesLoadMore => 'Carica altro';

  @override
  String get photoThemesPhotoUnavailable => 'Foto non disponibile. Riprova';

  @override
  String photoThemesOpenPhoto(String name) {
    return 'Apri la foto di $name';
  }

  @override
  String get photoThemesYou => 'Tu';

  @override
  String get photoThemesWallHelp =>
      'Se piace ai membri, la tua foto può arrivare sulle loro bacheche Today: 50 like e 5 commenti la portano su 50 bacheche, 100 like e 10 commenti su 100. Puoi disattivarlo quando vuoi.';

  @override
  String get photoThemesRemoveTitle => 'Rimuovere la tua foto?';

  @override
  String get photoThemesRemoveMessage =>
      'Sparirà da questo tema per tutti. Dopo potrai condividerne una nuova.';

  @override
  String get photoThemesRemoveAction => 'Rimuovi foto';

  @override
  String get photoThemesRemoveFailed => 'Impossibile rimuovere la tua foto.';

  @override
  String get photoThemesReachOn =>
      'Ora la tua foto può arrivare sulle bacheche dei membri quando piace.';

  @override
  String get photoThemesReachOff => 'La tua foto non è più su nessuna bacheca.';

  @override
  String get photoThemesSharedByYou => 'Condivisa da te';

  @override
  String photoThemesSharedBy(String name) {
    return 'Condivisa da $name';
  }

  @override
  String photoThemesPhotoDescription(String text) {
    return 'Descrizione della foto: $text';
  }

  @override
  String get photoThemesReachSwitch =>
      'Lascia che arrivi sulle bacheche degli altri';

  @override
  String get photoThemesReachIdle =>
      'I membri possono portare questa foto più lontano';

  @override
  String get photoThemesReachLive =>
      'I membri la stanno vedendo ora sulle loro bacheche Today.';

  @override
  String get photoThemesRemoveMine => 'Rimuovi la mia foto';

  @override
  String get photoThemesReport => 'Segnala';

  @override
  String photoThemesBlock(String name) {
    return 'Blocca $name';
  }

  @override
  String get photoThemesCommentHint => 'A cosa ti fa pensare?';

  @override
  String get photoThemesCommentApproved =>
      'Approvato. Ora lo vede chiunque possa vedere questa foto.';

  @override
  String get photoThemesDetailsTitle => 'Raccontaci';

  @override
  String get photoThemesCaption => 'Didascalia';

  @override
  String get photoThemesCaptionHint =>
      'Pancake, e poi nessun posto dove andare.';

  @override
  String get photoThemesDescribe => 'Descrivi la foto';

  @override
  String get photoThemesDescribeHelper =>
      'Aiuta i membri che usano uno screen reader.';

  @override
  String get photoThemesShare => 'Condividi';

  @override
  String get photoThemesWallTitle => 'Copertine sulla tua bacheca';

  @override
  String get photoThemesWallCaption => 'Foto che sono piaciute ad altri membri';

  @override
  String get photoThemesMasthead => 'TEMI FOTOGRAFICI';

  @override
  String photoThemesByline(String name) {
    return 'DI $name';
  }

  @override
  String get photoThemesLikes => 'Mi piace';

  @override
  String get photoThemesComments => 'Commenti';

  @override
  String get photoThemesCancel => 'Annulla';

  @override
  String get photoThemesTryAgain => 'Riprova';

  @override
  String get photoThemesSaveFailed => 'Non è stato salvato. Riprova.';

  @override
  String get friendsChatEmpty =>
      'Saluta. Solo voi due potete vedere questa conversazione.';

  @override
  String get friendsChatOpenFailed => 'Impossibile aprire la chat. Riprova.';

  @override
  String get friendsCancelRequestTitle => 'Annullare la richiesta di amicizia?';

  @override
  String friendsCancelRequestBody(String name) {
    return '$name non vedrà più la tua richiesta.';
  }

  @override
  String get friendsCancelRequestBodyUnnamed =>
      'Questo membro non vedrà più la tua richiesta.';

  @override
  String get friendsKeepIt => 'Mantienila';

  @override
  String get friendsCancelRequest => 'Annulla richiesta';

  @override
  String friendsNowFriends(String name) {
    return 'Tu e $name ora siete amici.';
  }

  @override
  String get friendsNowFriendsUnnamed => 'Tu e questo membro ora siete amici.';

  @override
  String friendsRequestSentTo(String name) {
    return 'Richiesta di amicizia inviata a $name.';
  }

  @override
  String get friendsRequestSentToUnnamed =>
      'Richiesta di amicizia inviata a questo membro.';

  @override
  String get friendsRequestCancelled => 'Richiesta annullata.';

  @override
  String get friendsRequestFailed => 'Impossibile inviare la richiesta.';

  @override
  String get friendsAddCaption =>
      'Gli amici possono scriversi e organizzare cose insieme';

  @override
  String get friendsRequested => 'Richiesta inviata';

  @override
  String friendsWaitingFor(String name) {
    return 'In attesa di $name. Tocca per annullare.';
  }

  @override
  String get friendsWaitingForUnnamed =>
      'In attesa di questo membro. Tocca per annullare.';

  @override
  String get friendsAcceptFriend => 'Accetta amicizia';

  @override
  String friendsAskedToBeFriends(String name) {
    return '$name vuole essere tuo amico';
  }

  @override
  String get friendsAskedToBeFriendsUnnamed =>
      'Questo membro vuole essere tuo amico';

  @override
  String get friendsMessage => 'Scrivi';

  @override
  String get friendsYoureFriends => 'Siete amici. Apri la vostra chat.';

  @override
  String friendsVouchTooShort(int min) {
    return 'Scrivi qualcosa in più (almeno $min caratteri).';
  }

  @override
  String friendsVouchTitle(String name) {
    return 'Garantisci per $name';
  }

  @override
  String get friendsVouchBody =>
      'Una frase o due sul perché qualcuno sarebbe fortunato a conoscere questa persona. La approva prima che compaia sul suo profilo, con il tuo nome.';

  @override
  String get friendsVouchLabel => 'La tua garanzia';

  @override
  String get friendsVouchHint => 'Gentile, divertente e sempre puntuale.';

  @override
  String get friendsVouchSend => 'Invia garanzia';

  @override
  String get friendsIntroChooseTwo => 'Scegli due amici diversi.';

  @override
  String get friendsIntroSheetTitle => 'Presenta due amici';

  @override
  String get friendsIntroSheetBody =>
      'Entrambi gli amici devono consentire le presentazioni. Ognuno controlla la propria anteprima e decide in privato. Condividi solo un motivo che hai il permesso di citare. Le loro decisioni e l’esito del match restano privati.';

  @override
  String get friendsIntroNeedTwo =>
      'Ti servono almeno due amici per fare una presentazione.';

  @override
  String get friendsFirstFriend => 'Primo amico';

  @override
  String get friendsSecondFriend => 'Secondo amico';

  @override
  String get friendsIntroWhyLabel =>
      'Perché dovrebbero conoscersi (facoltativo)';

  @override
  String get friendsIntroSubmit => 'Fai la presentazione';

  @override
  String get friendsLoadFailed => 'Impossibile caricare gli amici. Riprova.';

  @override
  String get friendsAddFailed => 'Impossibile aggiungere l’amico.';

  @override
  String get friendsRemoveFailed => 'Impossibile rimuovere l’amico.';

  @override
  String get friendsRespondFailed =>
      'Impossibile rispondere alla richiesta di amicizia.';

  @override
  String get friendsSocialLoadFailed =>
      'Impossibile caricare garanzie e presentazioni.';

  @override
  String get friendsVouchSendFailed => 'Impossibile inviare questa garanzia.';

  @override
  String get friendsVouchUpdateFailed =>
      'Impossibile aggiornare questa garanzia.';

  @override
  String get friendsVouchWithdrawFailed =>
      'Impossibile ritirare questa garanzia.';

  @override
  String get friendsIntroMakeFailed => 'Impossibile fare questa presentazione.';

  @override
  String get friendsIntroAnswerFailed =>
      'Impossibile rispondere a questa presentazione.';

  @override
  String get groupsEyebrow => 'GRUPPI';

  @override
  String get groupsTitle => 'Trova la tua gente.';

  @override
  String get groupsSubtitle =>
      'Community per stile di vita aperte a tutti e gruppi privati solo per i tuoi amici.';

  @override
  String get groupsStartGroup => 'Crea un gruppo';

  @override
  String get groupsInvitationsHeader => 'INVITI';

  @override
  String get groupsInvitationsCaption => 'Alcuni amici ti hanno invitato.';

  @override
  String get groupsAnswerFailed =>
      'Non è stato possibile salvare la tua risposta.';

  @override
  String groupsWelcome(String name) {
    return 'Ora fai parte di $name!';
  }

  @override
  String get groupsInvitationDeclined => 'Invito rifiutato.';

  @override
  String get groupsYourGroupsHeader => 'I TUOI GRUPPI';

  @override
  String get groupsYourGroupsFailed => 'Impossibile caricare i tuoi gruppi';

  @override
  String get groupsErrorCheckConnection => 'Controlla la connessione.';

  @override
  String get groupsEmptyTitle => 'Ancora nessun gruppo';

  @override
  String get groupsEmptyBody =>
      'Unisciti a una community qui sotto o crea un gruppo privato con i tuoi amici.';

  @override
  String get groupsDiscoverHeader => 'SCOPRI PER STILE DI VITA';

  @override
  String get groupsDiscoverCaption => 'I gruppi community sono aperti a tutti.';

  @override
  String get groupsLifestylesFailed => 'Impossibile caricare gli stili di vita';

  @override
  String get groupsCategoryAll => 'Tutti';

  @override
  String get groupsDiscoverFailed => 'Impossibile caricare i gruppi';

  @override
  String get groupsDiscoverEmptyTitle => 'Niente di nuovo a cui unirsi';

  @override
  String groupsDiscoverEmptyCategoryTitle(String category) {
    return 'Ancora nessun gruppo di $category';
  }

  @override
  String get groupsDiscoverEmptyBody =>
      'Fai il primo passo: crea un gruppo community e invita i tuoi amici.';

  @override
  String get groupsStartOne => 'Creane uno';

  @override
  String get groupsJoinFailed =>
      'Non è stato possibile unirti in questo momento.';

  @override
  String get groupsJoin => 'Unisciti';

  @override
  String groupsJoinNamed(String name) {
    return 'Unisciti a $name';
  }

  @override
  String groupsInvitedBy(String name, String kind, String members) {
    return 'Invito da $name · $kind · $members';
  }

  @override
  String groupsInvitedByFriend(String kind, String members) {
    return 'Invito da un amico · $kind · $members';
  }

  @override
  String get groupsDecline => 'Rifiuta';

  @override
  String groupsDeclineNamed(String name) {
    return 'Rifiuta $name';
  }

  @override
  String groupsChatEmpty(String name) {
    return 'Saluta il gruppo. Tutti in $name possono vedere i messaggi qui.';
  }

  @override
  String groupsInviteFriendsTo(String name) {
    return 'Invita amici in $name';
  }

  @override
  String get groupsSendInvitations => 'Invia inviti';

  @override
  String get groupsInvitationsFailed =>
      'Non è stato possibile inviare gli inviti.';

  @override
  String groupsInvitationSentTo(String name) {
    return 'Invito inviato a $name.';
  }

  @override
  String groupsInvitationsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count inviti inviati.',
      one: '1 invito inviato.',
    );
    return '$_temp0';
  }

  @override
  String groupsLeaveTitle(String name) {
    return 'Lasciare $name?';
  }

  @override
  String get groupsLeaveBodyAlone =>
      'Sei l’unico membro, quindi il gruppo e la sua chat verranno eliminati.';

  @override
  String get groupsLeaveBodyOwner =>
      'La proprietà passerà al moderatore più anziano o, in mancanza, al membro più anziano. Perderai l’accesso alla chat.';

  @override
  String get groupsLeaveBodyCommunity =>
      'Perderai l’accesso alla chat del gruppo. Potrai unirti di nuovo più tardi.';

  @override
  String get groupsLeaveBodyPrivate =>
      'Perderai l’accesso alla chat del gruppo. Per tornare ti servirà un nuovo invito.';

  @override
  String get groupsLeave => 'Esci';

  @override
  String get groupsLeaveFailed =>
      'Non è stato possibile uscire in questo momento.';

  @override
  String get groupsCoverUploadFailed =>
      'Non è stato possibile caricare la foto di copertina. Usa un JPEG o PNG fino a 10 MB.';

  @override
  String get groupsRemoveCoverTitle => 'Rimuovere la foto di copertina?';

  @override
  String groupsRemoveCoverBody(String name) {
    return '$name mostrerà di nuovo la copertina con l’emoji.';
  }

  @override
  String get groupsRemove => 'Rimuovi';

  @override
  String get groupsRemoveCoverFailed =>
      'Non è stato possibile rimuovere la foto di copertina.';

  @override
  String get groupsCoverRemoved => 'Foto di copertina rimossa.';

  @override
  String groupsDeleteTitle(String name) {
    return 'Eliminare $name?';
  }

  @override
  String get groupsDeleteBody =>
      'Il gruppo, i suoi inviti e la sua chat verranno eliminati per tutti. L’operazione non si può annullare.';

  @override
  String get groupsDeleteGroup => 'Elimina gruppo';

  @override
  String get groupsDeleteFailed => 'Non è stato possibile eliminare il gruppo.';

  @override
  String get groupsDetailEyebrow => 'GRUPPO';

  @override
  String get groupsDetailTitleFallback => 'Gruppo';

  @override
  String get groupsOwnerTools => 'Strumenti del proprietario';

  @override
  String get groupsEditGroup => 'Modifica gruppo';

  @override
  String get groupsAddCoverPhoto => 'Aggiungi foto di copertina';

  @override
  String get groupsChangeCoverPhoto => 'Cambia foto di copertina';

  @override
  String get groupsRemoveCoverPhoto => 'Rimuovi foto di copertina';

  @override
  String get groupsMoreOptions => 'Altre opzioni';

  @override
  String get groupsReportGroup => 'Segnala gruppo';

  @override
  String get groupsUnavailableTitle => 'Questo gruppo non è disponibile';

  @override
  String get groupsUnavailableBody =>
      'Potrebbe essere stato eliminato o potresti non avere più accesso.';

  @override
  String get groupsOpenToAll => 'Aperto a tutti';

  @override
  String get groupsPrivate => 'Privato';

  @override
  String get groupsYouRunIt => 'Lo gestisci tu';

  @override
  String get groupsYouModerate => 'Moderi tu';

  @override
  String get groupsCoverNotePending =>
      'Solo tu puoi vedere questa foto finché non viene approvata. Nel frattempo i membri vedono la copertina con l’emoji.';

  @override
  String get groupsCoverNoteRejected =>
      'La tua ultima foto di copertina non è stata approvata. Scegline un’altra.';

  @override
  String get groupsCoverUnderReview => 'In revisione';

  @override
  String get groupsChangeCover => 'Cambia copertina';

  @override
  String get groupsRemoveCover => 'Rimuovi copertina';

  @override
  String get groupsRemovedTitle =>
      'Questo gruppo è stato rimosso dopo una verifica';

  @override
  String get groupsRemovedBodyOwner =>
      'Finché è rimosso, i membri non possono chattare, unirsi o invitare. Gli avvisi di verifica spiegano la decisione e ti permettono di fare ricorso.';

  @override
  String get groupsRemovedBodyMember =>
      'Finché è rimosso, i membri non possono chattare, unirsi o invitare. Puoi lasciare il gruppo in qualsiasi momento.';

  @override
  String get groupsMembers => 'Membri';

  @override
  String get groupsChatButton => 'Chat del gruppo';

  @override
  String groupsChatButtonUnread(int count) {
    return 'Chat del gruppo · $count da leggere';
  }

  @override
  String get groupsInviteFriends => 'Invita amici';

  @override
  String get groupsWhosHere => 'CHI C’È';

  @override
  String get groupsSeeAll => 'Vedi tutti';

  @override
  String get groupsYou => 'Tu';

  @override
  String groupsInvitedToJoin(String name) {
    return 'Hai un invito per unirti a $name.';
  }

  @override
  String get groupsJoinGroup => 'Unisciti al gruppo';

  @override
  String get groupsJoinHint => 'I membri vedono chi c’è e chattano insieme.';

  @override
  String get groupsCantJoinTitle => 'Non puoi unirti a questo gruppo';

  @override
  String get groupsCantJoinBody =>
      'Potrebbe essere pieno, oppure un moderatore ti ha tolto l’accesso.';

  @override
  String get groupsInvitationOnly => 'Solo su invito';

  @override
  String get groupsInvitationOnlyBody =>
      'Un membro può invitarti in questo gruppo privato.';

  @override
  String get groupsMakeModerator => 'Rendi moderatore';

  @override
  String get groupsMakeMember => 'Rendi membro';

  @override
  String get groupsRemoveFromGroup => 'Rimuovi dal gruppo';

  @override
  String groupsRemoveMemberTitle(String name) {
    return 'Rimuovere $name?';
  }

  @override
  String get groupsRemoveMemberBodyCommunity =>
      'Uscirà dal gruppo e dalla chat e non potrà rientrare autonomamente.';

  @override
  String get groupsRemoveMemberBodyPrivate => 'Uscirà dal gruppo e dalla chat.';

  @override
  String get groupsChangeFailed => 'Non è stato possibile salvare la modifica.';

  @override
  String get groupsMembersFailed => 'Impossibile caricare i membri';

  @override
  String get groupsPleaseTryAgain => 'Riprova.';

  @override
  String groupsMemberYou(String name) {
    return '$name (tu)';
  }

  @override
  String get groupsRoleOwner => 'Proprietario';

  @override
  String get groupsRoleModerator => 'Moderatore';

  @override
  String get groupsRoleMember => 'Membro';

  @override
  String groupsMemberOptions(String name) {
    return 'Opzioni per $name';
  }

  @override
  String get groupsEditFailed => 'Non è stato possibile salvare le modifiche.';

  @override
  String get groupsSaving => 'Salvataggio…';

  @override
  String get groupsSaveChanges => 'Salva modifiche';

  @override
  String get groupsNameLabel => 'Nome del gruppo';

  @override
  String get groupsAboutLabel => 'Di cosa si tratta?';

  @override
  String get groupsAboutOptionalLabel => 'Di cosa si tratta? (facoltativo)';

  @override
  String get groupsCityLabel => 'Città (facoltativo)';

  @override
  String get groupsCoverColorTheme => 'Tema';

  @override
  String get groupsCoverColorAccent => 'Accento';

  @override
  String get groupsCoverColorWarm => 'Caldo';

  @override
  String get groupsLifestyleLabel => 'Stile di vita';

  @override
  String get groupsCreateCoverUploadFailed =>
      'Il tuo gruppo è pronto, ma non è stato possibile caricare la foto di copertina. Riprova dal gruppo.';

  @override
  String get groupsCreatePickLifestyle =>
      'Scegli uno stile di vita per il tuo gruppo community.';

  @override
  String get groupsCreateNameTooShort =>
      'Dai al tuo gruppo un nome di almeno 3 lettere.';

  @override
  String get groupsCreateFailed =>
      'Non è stato possibile creare il gruppo. Riprova.';

  @override
  String get groupsCreateEyebrow => 'NUOVO GRUPPO';

  @override
  String get groupsCreateSubtitle =>
      'Riunisci le persone attorno a ciò che ami.';

  @override
  String get groupsCreateSubtitleFriends =>
      'Trasforma i tuoi amici in un gruppo.';

  @override
  String get groupsCreateKindHeader => 'CHE TIPO';

  @override
  String get groupsKindCommunity => 'Gruppo community';

  @override
  String get groupsKindPrivate => 'Gruppo privato';

  @override
  String get groupsCreateCommunitySubtitle =>
      'Per stile di vita. Chiunque può trovarlo e unirsi.';

  @override
  String get groupsCreatePrivateSubtitle =>
      'Solo amici. Possono unirsi solo le persone che inviti.';

  @override
  String get groupsCreateLifestyleHeader => 'STILE DI VITA';

  @override
  String get groupsCreateLifestyleCaption =>
      'Dove le persone scopriranno il tuo gruppo.';

  @override
  String get groupsCreateDetailsHeader => 'DETTAGLI';

  @override
  String get groupsCreateNameHintCommunity => 'Runner all’alba di Indiranagar';

  @override
  String get groupsCreateNameHintPrivate => 'La crew del brunch della domenica';

  @override
  String get groupsCreateCoverHeader => 'COPERTINA';

  @override
  String groupsCoverEmojiSemantics(String emoji) {
    return 'Emoji di copertina $emoji';
  }

  @override
  String get groupsCreateCoverPhotoOptional =>
      'Foto di copertina (facoltativa)';

  @override
  String get groupsCreateCoverPhotoHint =>
      'I membri vedono l’emoji finché la tua foto non viene approvata.';

  @override
  String get groupsCreateAddCoverPhoto => 'Aggiungi una foto di copertina';

  @override
  String get groupsCreateChangePhoto => 'Cambia foto';

  @override
  String get groupsCreateRemovePhoto => 'Rimuovi foto';

  @override
  String get groupsCreateFriendsHeader => 'AMICI';

  @override
  String get groupsCreateFriendsCaptionEmpty =>
      'Invita amici ora o più tardi dal gruppo.';

  @override
  String get groupsCreateFriendsCaption => 'Riceveranno un invito a unirsi.';

  @override
  String get groupsFriendFallback => 'Amico';

  @override
  String groupsRemoveInvitee(String name) {
    return 'Rimuovi $name';
  }

  @override
  String get groupsChooseFriends => 'Scegli amici';

  @override
  String get groupsChangeFriends => 'Cambia amici';

  @override
  String get groupsCreating => 'Creazione…';

  @override
  String get groupsCreateGroup => 'Crea gruppo';

  @override
  String get groupsCardRemoved => 'Rimosso dopo una verifica';

  @override
  String groupsCardSemanticsMuted(String name, String details) {
    return '$name, $details, notifiche silenziate';
  }

  @override
  String get groupsNotificationsMuted => 'Notifiche silenziate';

  @override
  String groupsUnreadMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messaggi non letti',
      one: '1 messaggio non letto',
    );
    return '$_temp0';
  }

  @override
  String get groupsCoverSheetTitle => 'Foto di copertina';

  @override
  String get groupsCoverSheetBody =>
      'Ogni foto viene controllata prima che gli altri membri possano vederla. Usa un JPEG o PNG fino a 10 MB.';

  @override
  String get groupsCoverFromPhotos => 'Scegli dalle tue foto';

  @override
  String get groupsCoverTakePhoto => 'Scatta una foto';

  @override
  String get groupsCoverTooLarge =>
      'Questa foto supera i 10 MB. Scegline una più piccola.';

  @override
  String get groupsCoverPreviewTitle => 'Anteprima della copertina';

  @override
  String get groupsCoverPreviewBody =>
      'Le copertine appaiono come un banner largo che mantiene il centro della foto.';

  @override
  String get groupsCancel => 'Annulla';

  @override
  String get groupsCoverUseThisPhoto => 'Usa questa foto';

  @override
  String get groupsCoverPreviewSemantics => 'La tua nuova foto di copertina';

  @override
  String get groupsCoverChecking => 'Verifica della foto di copertina…';

  @override
  String groupsCoverUploading(int percent) {
    return 'Caricamento foto di copertina… $percent%';
  }

  @override
  String get groupsCoverUploadedReview =>
      'La tua copertina è in revisione. Solo tu puoi vederla finché non viene approvata.';

  @override
  String get groupsCoverUpdated => 'Foto di copertina aggiornata.';

  @override
  String get groupsPickerSubtitle =>
      'Puoi invitare solo le persone nella tua lista amici.';

  @override
  String get groupsDone => 'Fatto';

  @override
  String get groupsSearchFriends => 'Cerca amici';

  @override
  String get groupsFriendsFailed => 'Impossibile caricare gli amici';

  @override
  String get groupsNoFriendsTitle => 'Ancora nessun amico';

  @override
  String get groupsNoFriendsBody =>
      'Aggiungi amici da Match, profili o stanze, poi portali in un gruppo.';

  @override
  String get groupsAlreadyMember => 'Già nel gruppo';

  @override
  String get groupsInvitationSent => 'Invito inviato';

  @override
  String get todayActivityCoffee => 'Un caffè';

  @override
  String get todayActivityWalk => 'Una passeggiata di giorno';

  @override
  String get todayActivityMeal => 'Un pasto';

  @override
  String get todayActivityPlayful => 'Qualcosa di giocoso';

  @override
  String get todayActivityEvent => 'Un evento';

  @override
  String get todayActivityVideoCall => 'Un saluto in videochiamata';

  @override
  String get todayActivityDrinks => 'Un drink';

  @override
  String get todayActivityOther => 'Qualcos’altro';

  @override
  String get todayBudgetFlexible => 'Decidiamo insieme';

  @override
  String get todayBudgetFree => 'Senza spendere';

  @override
  String get todayBudgetModest => 'Spesa contenuta';

  @override
  String get todayBudgetTreat => 'Un piccolo sfizio';

  @override
  String get todayRhythmTitle => 'Il tuo ritmo di appuntamenti';

  @override
  String get todayRhythmLoadFailed => 'Impossibile caricare le tue preferenze.';

  @override
  String get todayRhythmSaved =>
      'Il tuo ritmo di appuntamenti è stato salvato.';

  @override
  String get todayRhythmSaveFailed =>
      'Impossibile salvare. Le tue scelte sono ancora qui.';

  @override
  String get todayRhythmHeadline =>
      'Fai spazio al tuo modo di conoscere persone.';

  @override
  String get todayRhythmIntro =>
      'Scegli ciò che si adatta alla tua vita. Disponibilità e presentazioni sono facoltative, e puoi cambiare idea.';

  @override
  String get todayRhythmOpenTo => 'A cosa sei aperto/a?';

  @override
  String get todayRhythmIntentNone => 'Preferisco non dirlo';

  @override
  String get todayRhythmIntentRelationship => 'Una relazione';

  @override
  String get todayRhythmIntentExploring => 'Sto ancora capendo';

  @override
  String get todayRhythmIntentCasual => 'Qualcosa di informale';

  @override
  String get todayRhythmPaceSection => 'Il tuo ritmo di conversazione';

  @override
  String get todayRhythmPaceNone => 'Nessuna preferenza';

  @override
  String get todayRhythmPaceSlow => 'Un po’ più lento';

  @override
  String get todayRhythmPaceSteady => 'Una conversazione regolare';

  @override
  String get todayRhythmPaceFrequent => 'Conversazione frequente';

  @override
  String get todayRhythmSlowWeek => 'Risposte lente questa settimana';

  @override
  String get todayRhythmSlowWeekHint =>
      'Questo stato si azzera dopo sette giorni.';

  @override
  String get todayRhythmSharePace => 'Condividi questo stato con i miei match';

  @override
  String get todayRhythmSharePaceHint =>
      'Solo i tuoi match attuali possono vedere il tuo stato temporaneo.';

  @override
  String get todayRhythmFirstDate => 'Il tuo tipo di primo appuntamento';

  @override
  String get todayRhythmChooseFive =>
      'Scegline fino a cinque. Le preferenze in comune aiutano a spiegare le tue presentazioni.';

  @override
  String get todayRhythmWeekSection => 'Un po’ di spazio nella tua settimana';

  @override
  String get todayRhythmShareAvailability =>
      'Usa la mia disponibilità generale';

  @override
  String get todayRhythmShareAvailabilityHint =>
      'Vengono mostrate solo le sovrapposizioni reali. La tua agenda completa resta privata. Disattivando l’opzione, le fasce salvate vengono eliminate.';

  @override
  String get todayRhythmAvailabilityHint =>
      'Tocca le mattine, i pomeriggi o le sere che ti vanno bene. Gli orari usano l’ora locale di questo dispositivo e scadono automaticamente.';

  @override
  String get todayRhythmMorning => 'Mattina';

  @override
  String get todayRhythmAfternoon => 'Pomeriggio';

  @override
  String get todayRhythmEvening => 'Sera';

  @override
  String get todayRhythmIntrosSection => 'Presentazioni con il tuo permesso';

  @override
  String get todayRhythmFriendIntros =>
      'Consenti presentazioni da amici accettati';

  @override
  String get todayRhythmFriendIntrosHint =>
      'Entrambe le persone devono acconsentire. Il tuo amico non riceve aggiornamenti su match o rifiuti. L’anteprima include il tuo nome e la tua età.';

  @override
  String get todayRhythmIntroPhoto => 'Includi le mie foto del profilo';

  @override
  String get todayRhythmIntroPhotoHint =>
      'Solo la persona che riceve la presentazione può vederle.';

  @override
  String get todayRhythmIntroCity => 'Includi la mia città';

  @override
  String get todayRhythmIntroCityHint =>
      'La tua posizione esatta non viene mai inclusa.';

  @override
  String get todayRhythmReload => 'Ricarica le scelte salvate';

  @override
  String get todayRhythmSaving => 'Salvataggio…';

  @override
  String get todayRhythmSave => 'Salva il mio ritmo';

  @override
  String get todayRhythmBreakTitle => 'Una pausa va sempre bene.';

  @override
  String get todayRhythmBreakBody =>
      'Metti in pausa le nuove presentazioni quando ne hai bisogno. Le conversazioni in corso restano disponibili.';

  @override
  String get todayRhythmPauseFailed => 'Impossibile aggiornare la tua pausa.';

  @override
  String get todayRhythmResume => 'Riprendi le presentazioni';

  @override
  String get todayRhythmPause => 'Metti in pausa le presentazioni';

  @override
  String get datingConnectionSlowTitle => 'Risponde con calma questa settimana';

  @override
  String get datingConnectionSlowBody =>
      'Il tuo match si sta prendendo un ritmo più lento.';

  @override
  String get datingConnectionYourTurn => 'Tocca a te: aggiungi una sorpresa';

  @override
  String get datingConnectionComplete => 'Il vostro primo capitolo è pronto';

  @override
  String get datingConnectionWaiting => 'Il vostro capitolo ha un inizio';

  @override
  String get datingConnectionCreate => 'Create il vostro primo capitolo';

  @override
  String get datingConnectionBody =>
      'Un inizio, una sorpresa e una storia che costruite insieme.';

  @override
  String get chemistryTitle => 'Un po’ di chimica';

  @override
  String get chemistryIntro =>
      'Scegli ciò che ti somiglia. Non ci sono risposte giuste e questo non influisce mai sull’accesso alla chat.';

  @override
  String get chemistrySaveFailed =>
      'Impossibile salvare la tua scelta. Riprova.';

  @override
  String get chemistryRetry => 'Riprova a caricare';

  @override
  String get chemistryRevealedTitle => 'Entrambe le risposte, insieme';

  @override
  String get chemistryYouPicked => 'Hai scelto';

  @override
  String get chemistryMatchPicked => 'Il tuo match ha scelto';

  @override
  String get chemistryRevealedBody =>
      'Un preferito in comune o una bella differenza: avete qualcosa di cui parlare.';

  @override
  String get chemistryWaitingBody =>
      'La tua risposta è salvata in privato. Entrambe le risposte compariranno qui quando avrete scelto tutti e due.';

  @override
  String chemistryYourChoice(String choice) {
    return 'La tua scelta: $choice';
  }

  @override
  String get chemistryAnotherMoment => 'Un altro momento, quando vuoi';

  @override
  String get chemistryChooseMoment => 'Scegli un momento';

  @override
  String get chemistryPromptSunday => 'Costruisci una domenica';

  @override
  String get chemistryPromptAdventure => 'Scegli un’avventura';

  @override
  String get chemistryPromptFirstDate => 'Il tuo tipo di primo appuntamento';

  @override
  String get chemistryQuestionSunday => 'La tua domenica ideale inizia con…';

  @override
  String get chemistryQuestionAdventure => 'Una piccola avventura insieme…';

  @override
  String get chemistryQuestionFirstDate => 'Per un primo saluto, sceglieresti…';

  @override
  String get engagementLevelFrozen =>
      'La progressione è in pausa mentre è in corso una verifica di sicurezza dell’account.';

  @override
  String get engagementLevelTrustGate =>
      'Verifica il profilo e mantieni l’account in regola per sbloccare i livelli legati alla fiducia.';

  @override
  String get engagementLevelPathTitle => 'Percorso dei livelli';

  @override
  String get engagementLevelPathSubtitle =>
      'Gli XP arrivano dall’attività significativa. Gli acquisti non aumentano mai il tuo livello.';

  @override
  String get engagementLevelRewardsTitle => 'Premi';

  @override
  String get engagementLevelRewardsSubtitle =>
      'I premi sono estetici, di comodità o vantaggi di visibilità limitati.';

  @override
  String get engagementLevelRecentTitle => 'XP recenti';

  @override
  String get engagementLevelRecentSubtitle =>
      'Il registro delle tue attività è permanente e verificabile.';

  @override
  String engagementLevelNumber(int level) {
    return 'Livello $level';
  }

  @override
  String engagementLevelXp(String xp) {
    return '$xp XP';
  }

  @override
  String get engagementLevelHighest => 'Livello massimo raggiunto';

  @override
  String engagementLevelProgress(int xp, String percent) {
    return '$xp XP in questo livello · $percent%';
  }

  @override
  String engagementLevelThreshold(int xp, String summary) {
    return '$xp XP · $summary';
  }

  @override
  String get engagementLevelTrustGated => 'Richiede fiducia';

  @override
  String get engagementLevelClaimed => 'Riscattato';

  @override
  String get engagementLevelClaim => 'Riscatta';

  @override
  String get engagementLevelLocked => 'Bloccato';

  @override
  String get engagementLevelStandardAward => 'Assegnazione standard';

  @override
  String engagementLevelQualityWeighting(String multiplier) {
    return 'Ponderazione qualità ×$multiplier';
  }

  @override
  String get engagementLevelEmptyLedger =>
      'Completa attività significative per guadagnare i tuoi primi XP.';

  @override
  String get engagementXpSourceProfileCompleted => 'Profilo completato';

  @override
  String get engagementXpSourceDailyPromptSubmitted =>
      'Domanda del giorno inviata';

  @override
  String get engagementXpSourceMiniActivityCompleted =>
      'Mini attività completata';

  @override
  String get engagementXpSourceCircleChallengeSubmitted =>
      'Sfida del circolo inviata';

  @override
  String get engagementXpSourceVoiceIcebreakerPlayed =>
      'Rompighiaccio vocale ascoltato';

  @override
  String get engagementXpSourceStreak3 => 'Serie di 3 giorni';

  @override
  String get engagementXpSourceStreak7 => 'Serie di 7 giorni';

  @override
  String get engagementXpSourceStreak14 => 'Serie di 14 giorni';

  @override
  String get engagementXpSourceAdminAdjustment => 'Rettifica del team';

  @override
  String get engagementLevelSignIn =>
      'Accedi per vedere i progressi del tuo livello.';

  @override
  String get engagementLevelLoadFailed =>
      'Al momento non è possibile caricare i tuoi progressi.';

  @override
  String get engagementLevelClaimFailed =>
      'Al momento non è possibile riscattare questo premio.';

  @override
  String get engagementCoffeeTitle => 'Sondaggi caffè di gruppo';

  @override
  String get engagementCoffeeCreateHeading =>
      'Crea un semplice sondaggio per un caffè di gruppo';

  @override
  String get engagementCoffeeCreateHint =>
      'Aggiungi fino a 3 ID utente dei partecipanti (separati da virgole) e almeno un’opzione.';

  @override
  String get engagementCoffeeParticipantsLabel =>
      'ID utente dei partecipanti (separati da virgole)';

  @override
  String get engagementCoffeeDeadlineLabel => 'Scadenza ISO (facoltativa)';

  @override
  String engagementCoffeeOptionNumber(int number) {
    return 'Opzione $number';
  }

  @override
  String get engagementCoffeeCreate => 'Crea sondaggio';

  @override
  String get engagementCoffeeActorLabel =>
      'ID utente alternativo per l’azione (facoltativo)';

  @override
  String get engagementCoffeeEmpty =>
      'Ancora nessun sondaggio. Creane uno qui sopra.';

  @override
  String engagementCoffeePollId(String id) {
    return 'Sondaggio $id';
  }

  @override
  String engagementCoffeeStatus(String status) {
    return 'Stato: $status';
  }

  @override
  String get engagementCoffeeStatusOpen => 'aperto';

  @override
  String get engagementCoffeeStatusFinalized => 'concluso';

  @override
  String engagementCoffeeParticipants(String ids) {
    return 'Partecipanti: $ids';
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
      other: '$day · $time · $area ($count voti)',
      one: '$day · $time · $area (1 voto)',
    );
    return '$_temp0';
  }

  @override
  String get engagementCoffeeVote => 'Vota';

  @override
  String get engagementCoffeeFinalize => 'Concludi sondaggio';

  @override
  String get engagementCoffeeDayLabel => 'Giorno';

  @override
  String get engagementCoffeeTimeLabel => 'Fascia oraria';

  @override
  String get engagementCoffeeAreaLabel => 'Quartiere';

  @override
  String get engagementCoffeeLoadFailed =>
      'Al momento non è possibile caricare i sondaggi di gruppo.';

  @override
  String get engagementCoffeeCreateFailed =>
      'Al momento non è possibile creare il sondaggio di gruppo.';

  @override
  String get engagementCoffeeVoteUserRequired =>
      'Serve un ID utente per votare.';

  @override
  String get engagementCoffeeVoteFailed => 'Al momento non è possibile votare.';

  @override
  String get engagementCoffeeFinalizeUserRequired =>
      'Serve un ID utente per concludere.';

  @override
  String get engagementCoffeeFinalizeFailed =>
      'Al momento non è possibile concludere il sondaggio.';

  @override
  String get engagementDailyPromptUnavailable =>
      'Domanda del giorno non disponibile';

  @override
  String get engagementDailyPromptPullToRefresh =>
      'Trascina per aggiornare o riprova tra poco.';

  @override
  String get engagementDailyPromptDomainValues => 'VALORI';

  @override
  String get engagementDailyPromptDomainLifestyle => 'STILE DI VITA';

  @override
  String get engagementDailyPromptDomainRelationshipStyle =>
      'STILE DI RELAZIONE';

  @override
  String get engagementDailyPromptSparkTitle => 'Scintilla di compatibilità';

  @override
  String engagementDailyPromptSparkSummary(int replied, int similar) {
    return 'Risposte oggi: $replied · risposte simili: $similar';
  }

  @override
  String get engagementDailyPromptYourAnswer => 'La tua risposta';

  @override
  String get engagementDailyPromptHint =>
      'Scrivi la tua risposta in meno di 60 secondi.';

  @override
  String engagementDailyPromptEditOpenUntil(String time) {
    return 'Modificabile fino alle $time';
  }

  @override
  String get engagementDailyPromptEditOpenSoon =>
      'Modificabile ancora per poco';

  @override
  String get engagementDailyPromptEditClosed =>
      'Non è più modificabile per oggi.';

  @override
  String get engagementDailyPromptEdited => 'Modificata';

  @override
  String get engagementDailyPromptSubmit => 'Invia la risposta del giorno';

  @override
  String get engagementDailyPromptUpdate => 'Aggiorna risposta';

  @override
  String get engagementDailyPromptStreakProgress => 'Progressi della serie';

  @override
  String engagementDailyPromptStatCurrent(String value) {
    return 'Attuale: $value';
  }

  @override
  String engagementDailyPromptStatBest(String value) {
    return 'Record: $value';
  }

  @override
  String engagementDailyPromptStatNext(String value) {
    return 'Prossimo: $value';
  }

  @override
  String engagementDailyPromptDays(int days) {
    return '$days g';
  }

  @override
  String get engagementDailyPromptComplete => 'Completato';

  @override
  String engagementDailyPromptMilestone(int days) {
    return 'Traguardo sbloccato: serie di $days giorni';
  }

  @override
  String get engagementDailyPromptLoadFailed =>
      'Al momento non è possibile caricare la domanda del giorno.';

  @override
  String get engagementDailyPromptNotLoaded =>
      'La domanda del giorno non è ancora stata caricata.';

  @override
  String get engagementDailyPromptEnterAnswer => 'Scrivi prima una risposta.';

  @override
  String get engagementDailyPromptSubmitFailed =>
      'Impossibile inviare la risposta. Riprova.';

  @override
  String get clubsKindBooks => 'Libri';

  @override
  String get clubsKindFilms => 'Film';

  @override
  String get clubsFilterAll => 'Tutti';

  @override
  String get clubsAudiencePrivate => 'Solo io';

  @override
  String get clubsAudienceFriends => 'Amici';

  @override
  String get clubsAudienceCommunity => 'Community di Connect';

  @override
  String get clubsRoleOwner => 'Responsabile';

  @override
  String get clubsRoleModerator => 'Moderatore';

  @override
  String get clubsRoleMember => 'Membro';

  @override
  String get clubsBadgeBookClub => 'Club del libro';

  @override
  String get clubsBadgeFilmClub => 'Cineclub';

  @override
  String get clubsBadgeBookList => 'Lista di libri';

  @override
  String get clubsBadgeFilmList => 'Lista di film';

  @override
  String get clubsBadgeBook => 'Libro';

  @override
  String get clubsBadgeFilm => 'Film';

  @override
  String get clubsClub => 'Club';

  @override
  String clubsStarsOutOfFive(String rating) {
    return '$rating stelle su 5';
  }

  @override
  String clubsStarCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stelle',
      one: '1 stella',
    );
    return '$_temp0';
  }

  @override
  String get clubsNoRatingsYet => 'Ancora nessuna valutazione';

  @override
  String clubsRatingSummary(String average, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recensioni',
      one: '1 recensione',
    );
    return '$average · $_temp0';
  }

  @override
  String get clubsWeekThis => 'Questa settimana';

  @override
  String get clubsWeekNext => 'La prossima settimana';

  @override
  String get clubsWeekLast => 'La settimana scorsa';

  @override
  String clubsWeekOf(String date) {
    return 'Settimana del $date';
  }

  @override
  String get clubsTitle => 'Club di libri e film';

  @override
  String get clubsMyLists => 'Le mie liste';

  @override
  String get clubsStartClubTooltip => 'Crea un club di libri o di film';

  @override
  String get clubsStartClub => 'Crea un club';

  @override
  String get clubsSignInToSee => 'Accedi per vedere i club.';

  @override
  String get clubsHeroTitle => 'Leggilo. Guardalo. Parlane.';

  @override
  String get clubsHeroSubtitle =>
      'Unisciti a un club, segui una scelta a settimana e condividi cosa ne pensi. Il buon gusto è un ottimo modo per rompere il ghiaccio.';

  @override
  String get clubsScopeMine => 'I miei club';

  @override
  String get clubsScopeDiscover => 'Scopri';

  @override
  String get clubsLoadErrorTitle => 'Impossibile caricare i club';

  @override
  String get clubsCheckConnection => 'Controlla la connessione.';

  @override
  String get clubsLookAroundTitle => 'Puoi dare un’occhiata';

  @override
  String get clubsLookAroundMessage =>
      'Completa il tuo profilo con due foto approvate per creare un club o unirti a uno.';

  @override
  String get clubsEmptyMineTitle => 'Il tuo primo club ti aspetta';

  @override
  String get clubsEmptyMineMessage =>
      'Trova un club che legge o guarda ciò che ami, oppure creane uno tuo.';

  @override
  String get clubsEmptyDiscoverTitle => 'Ancora nessun club qui';

  @override
  String get clubsEmptyDiscoverMessage =>
      'Fai il primo passo: crea un club e scegli qualcosa di bello per questa settimana.';

  @override
  String get clubsDiscoverClubs => 'Scopri i club';

  @override
  String clubsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membri',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String get clubsYouRunIt => 'Lo gestisci tu';

  @override
  String get clubsYouModerate => 'Lo moderi tu';

  @override
  String get clubsJoined => 'Sei dentro ✓';

  @override
  String get clubsNoPickThisWeek => 'Nessuna scelta per questa settimana';

  @override
  String get clubsNameTooShort =>
      'Dai al tuo club un nome di almeno 3 lettere.';

  @override
  String get clubsCreateFailed => 'Impossibile creare il club.';

  @override
  String get clubsNameLabel => 'Nome del club';

  @override
  String get clubsNameHint => 'Letture lente della domenica';

  @override
  String get clubsDescriptionLabel =>
      'Di cosa parla il tuo club? (facoltativo)';

  @override
  String get clubsCreating => 'Creazione…';

  @override
  String get clubsCreateClub => 'Crea club';

  @override
  String clubsLeaveTitle(String name) {
    return 'Lasciare $name?';
  }

  @override
  String get clubsLeaveMessage =>
      'Puoi rientrare più tardi finché il club è aperto.';

  @override
  String get clubsLeaveClub => 'Lascia il club';

  @override
  String clubsWelcome(String name) {
    return 'Ti diamo il benvenuto in $name!';
  }

  @override
  String get clubsChangeNotSaved => 'Impossibile salvare la modifica.';

  @override
  String get clubsOptionsTooltip => 'Opzioni del club';

  @override
  String get clubsMembers => 'Membri';

  @override
  String get clubsReportClub => 'Segnala club';

  @override
  String get clubsDetailLoadErrorTitle => 'Impossibile caricare questo club';

  @override
  String get clubsDetailLoadErrorMessage =>
      'Potrebbe essere stato chiuso. Riprova.';

  @override
  String get clubsEarlierPicks => 'Scelte precedenti';

  @override
  String clubsPickSubtitle(String week, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count post',
      one: '1 post',
    );
    return '$week · $_temp0';
  }

  @override
  String get clubsOpenDiscussion => 'Apri la discussione';

  @override
  String get clubsJoinToSeeTitle => 'Unisciti per vedere la discussione';

  @override
  String get clubsJoinToSeeMessage =>
      'I membri parlano insieme di ogni scelta. Unisciti al club per seguire e dire la tua.';

  @override
  String clubsYouRole(String role) {
    return 'Tu: $role';
  }

  @override
  String get clubsRemovedByModeration =>
      'Questo club è stato rimosso dalla moderazione.';

  @override
  String get clubsJoinClub => 'Unisciti al club';

  @override
  String get clubsNoPickModerator =>
      'Ancora nessuna scelta. Scegli qualcosa di bello per tutti.';

  @override
  String get clubsNoPickMember => 'Ancora nessuna scelta. Torna presto.';

  @override
  String clubsQuotedNote(String note) {
    return '«$note»';
  }

  @override
  String clubsPostsInDiscussion(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count post nella discussione',
      one: '1 post nella discussione',
    );
    return '$_temp0';
  }

  @override
  String get clubsSetThisWeeksPick => 'Imposta la scelta della settimana';

  @override
  String get clubsDiscussThisPick => 'Discuti questa scelta';

  @override
  String get clubsPostNotSent => 'Impossibile inviare il post.';

  @override
  String clubsDiscussionHeading(String title) {
    return 'Discussione · $title';
  }

  @override
  String get clubsDiscussionLoadError => 'Impossibile caricare la discussione';

  @override
  String get clubsStartConversationTitle => 'Inizia la conversazione';

  @override
  String get clubsStartConversationMessage =>
      'Cosa ne pensi finora? Il tuo post potrebbe essere quello che fa parlare tutti.';

  @override
  String get clubsLoadMorePosts => 'Carica altri post';

  @override
  String get clubsComposerLabel => 'Partecipa alla discussione';

  @override
  String get clubsComposerHint => 'Momento preferito? Sorpresa più grande?';

  @override
  String get clubsContainsSpoilers => 'Contiene spoiler';

  @override
  String get clubsSpoilersSubtitle => 'Gli altri toccano per vederlo.';

  @override
  String get clubsPosting => 'Pubblicazione…';

  @override
  String get clubsPost => 'Pubblica';

  @override
  String get clubsDeletePostTitle => 'Eliminare il tuo post?';

  @override
  String get clubsDeletePostMessage =>
      'Verrà rimosso dalla discussione per tutti.';

  @override
  String get clubsActionFailed => 'Impossibile completare l’azione.';

  @override
  String get clubsHideFromMembers => 'Nascondi ai membri';

  @override
  String get clubsShowToMembers => 'Mostra ai membri';

  @override
  String get clubsReport => 'Segnala';

  @override
  String get clubsYou => 'Tu';

  @override
  String get clubsHidden => 'Nascosto';

  @override
  String get clubsPostActions => 'Azioni sul post';

  @override
  String get clubsMakeModerator => 'Rendi moderatore';

  @override
  String get clubsMakeMember => 'Rendi membro';

  @override
  String get clubsRemoveFromClub => 'Rimuovi dal club';

  @override
  String clubsRemoveMemberTitle(String name) {
    return 'Rimuovere $name?';
  }

  @override
  String get clubsRemoveMemberMessage =>
      'Lascerà il club e non potrà rientrare. I suoi post precedenti restano nella discussione.';

  @override
  String get clubsRemove => 'Rimuovi';

  @override
  String get clubsMembersLoadError => 'Impossibile caricare i membri.';

  @override
  String clubsMemberYou(String name) {
    return '$name (tu)';
  }

  @override
  String clubsMemberActions(String name) {
    return 'Azioni per $name';
  }

  @override
  String get clubsChooseFilm => 'Scegli un film';

  @override
  String get clubsChooseBook => 'Scegli un libro';

  @override
  String get clubsChooseTitle => 'Scegli un titolo';

  @override
  String get clubsChooseTitleFirst => 'Scegli prima un titolo.';

  @override
  String get clubsPickNotSaved => 'Impossibile salvare la scelta.';

  @override
  String get clubsSetWeeklyPick => 'Imposta la scelta settimanale';

  @override
  String get clubsChange => 'Cambia';

  @override
  String get clubsPickNoteLabel => 'Una nota per il club (facoltativa)';

  @override
  String get clubsPickNoteHint => 'Perché questo? Da dove iniziare?';

  @override
  String get clubsSaving => 'Salvataggio…';

  @override
  String get clubsSavePick => 'Salva scelta';

  @override
  String get clubsListNameRequired => 'Dai un nome alla tua lista.';

  @override
  String get clubsListNotSaved => 'Impossibile salvare la lista.';

  @override
  String get clubsEditList => 'Modifica lista';

  @override
  String get clubsNewList => 'Nuova lista';

  @override
  String get clubsListNameLabel => 'Nome della lista';

  @override
  String get clubsListNameHint => 'Libri che mi hanno fatto cambiare idea';

  @override
  String get clubsWhoCanSee => 'Chi può vederlo';

  @override
  String get clubsSave => 'Salva';

  @override
  String get clubsCreateList => 'Crea lista';

  @override
  String get clubsYourNote => 'La tua nota';

  @override
  String get clubsNoteLabel => 'Perché è in questa lista';

  @override
  String get clubsSaveNote => 'Salva nota';

  @override
  String get clubsCreateNewListTooltip => 'Crea una nuova lista';

  @override
  String get clubsSignInToSeeLists => 'Accedi per vedere le tue liste.';

  @override
  String get clubsShelfTitle => 'Il tuo scaffale';

  @override
  String get clubsShelfSubtitle =>
      'Tieni traccia di ciò che hai amato e di ciò che viene dopo. Condividi una lista o tienila solo per te.';

  @override
  String get clubsListsLoadErrorTitle => 'Impossibile caricare le tue liste';

  @override
  String get clubsFirstListTitle => 'Crea la tua prima lista';

  @override
  String get clubsFirstListMessage =>
      'Film preferiti, prossime letture, film del cuore da rivedere: decidi tu.';

  @override
  String clubsAddToNamed(String name) {
    return 'Aggiungi a $name';
  }

  @override
  String get clubsAddToThisListFailed =>
      'Impossibile aggiungerlo a questa lista.';

  @override
  String clubsDeleteListTitle(String name) {
    return 'Eliminare $name?';
  }

  @override
  String get clubsDeleteListMessage =>
      'La lista e le sue note verranno rimosse. Non si può annullare.';

  @override
  String get clubsDeleteList => 'Elimina lista';

  @override
  String get clubsListDeleteFailed =>
      'Impossibile eliminare la lista. Ricarica e riprova.';

  @override
  String get clubsNoteNotSaved => 'Impossibile salvare la nota.';

  @override
  String get clubsRemoveFailed => 'Impossibile rimuoverlo.';

  @override
  String get clubsListOptions => 'Opzioni della lista';

  @override
  String get clubsAddATitle => 'Aggiungi un titolo';

  @override
  String clubsTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titoli',
      one: '1 titolo',
    );
    return '$_temp0';
  }

  @override
  String get clubsListEmpty =>
      'Ancora niente qui. Usa «Aggiungi un titolo» dal menu della lista.';

  @override
  String clubsItemOptions(String title) {
    return 'Opzioni per $title';
  }

  @override
  String get clubsAddNote => 'Aggiungi una nota';

  @override
  String get clubsEditNote => 'Modifica nota';

  @override
  String get clubsRemoveFromList => 'Rimuovi dalla lista';

  @override
  String get clubsTapStarError => 'Tocca una stella per valutare.';

  @override
  String get clubsReviewNotSaved => 'Impossibile salvare la recensione.';

  @override
  String get clubsWriteReview => 'Scrivi una recensione';

  @override
  String get clubsEditYourReview => 'Modifica la tua recensione';

  @override
  String get clubsTapStarToRate => 'Tocca una stella per valutare';

  @override
  String clubsRatingOutOfFive(int rating) {
    return '$rating su 5';
  }

  @override
  String get clubsReviewBodyLabel => 'Cosa ne pensi? (facoltativo)';

  @override
  String get clubsSaveReview => 'Salva recensione';

  @override
  String clubsAddedToList(String name) {
    return 'Aggiunto a $name.';
  }

  @override
  String get clubsAddToThatListFailed =>
      'Impossibile aggiungerlo a quella lista.';

  @override
  String get clubsAddToAList => 'Aggiungi a una lista';

  @override
  String get clubsListsLoadError => 'Impossibile caricare le tue liste.';

  @override
  String get clubsNoFilmLists =>
      'Non hai ancora liste di film. Creane una per iniziare la tua raccolta.';

  @override
  String get clubsNoBookLists =>
      'Non hai ancora liste di libri. Creane una per iniziare la tua raccolta.';

  @override
  String get clubsTitleFallback => 'Titolo';

  @override
  String get clubsSignInToSeeReviews => 'Accedi per vedere le recensioni.';

  @override
  String get clubsTitleLoadError => 'Impossibile caricare questo titolo';

  @override
  String get clubsReviews => 'Recensioni';

  @override
  String get clubsNoOtherReviewsTitle => 'Ancora nessun’altra recensione';

  @override
  String get clubsNoOtherReviewsMessage =>
      'Quando i membri che puoi vedere condividono una recensione, la trovi qui.';

  @override
  String get clubsDeleteReviewTitle => 'Eliminare la tua recensione?';

  @override
  String get clubsDeleteReviewMessage =>
      'Il tuo voto e il tuo testo verranno rimossi per tutti.';

  @override
  String get clubsDeleteReview => 'Elimina recensione';

  @override
  String get clubsReviewDeleteFailed =>
      'Impossibile eliminare la recensione. Ricarica e riprova.';

  @override
  String get clubsWhatDidYouThink => 'Cosa ne pensi?';

  @override
  String get clubsReviewPrompt =>
      'Dai un voto e spiega perché. Scegli tu chi può vederlo.';

  @override
  String get clubsYourReview => 'La tua recensione';

  @override
  String get clubsSpoilers => 'Spoiler';

  @override
  String get clubsEdit => 'Modifica';

  @override
  String get clubsReportReview => 'Segnala questa recensione';

  @override
  String get clubsEnterTitle => 'Inserisci il titolo.';

  @override
  String get clubsYearRange => 'Inserisci un anno tra il 1450 e il 2100.';

  @override
  String get clubsTitleAddFailed => 'Impossibile aggiungere il titolo.';

  @override
  String get clubsSearchFilms => 'Cerca film';

  @override
  String get clubsSearchBooks => 'Cerca libri';

  @override
  String get clubsTypeTwoLetters => 'Digita almeno 2 lettere';

  @override
  String get clubsSearchUnavailable => 'La ricerca non è disponibile.';

  @override
  String get clubsNoFilmsMatch =>
      'Nessun film corrisponde. Aggiungilo qui sotto.';

  @override
  String get clubsNoBooksMatch =>
      'Nessun libro corrisponde. Aggiungilo qui sotto.';

  @override
  String get clubsAddNewFilm => 'Aggiungi un nuovo film';

  @override
  String get clubsAddNewBook => 'Aggiungi un nuovo libro';

  @override
  String get clubsTitleFieldLabel => 'Titolo';

  @override
  String get clubsDirector => 'Regia';

  @override
  String get clubsAuthor => 'Autore';

  @override
  String get clubsYearOptional => 'Anno (facoltativo)';

  @override
  String get clubsAdding => 'Aggiunta…';

  @override
  String get clubsAddAndChoose => 'Aggiungi e scegli';

  @override
  String get friendsIntroducerSaveFailed =>
      'Non siamo riusciti a salvare. Aggiorna per controllare i permessi più recenti prima di riprovare.';

  @override
  String friendsIntroducerRevokeTitle(String name) {
    return 'Rimuovere il permesso a $name?';
  }

  @override
  String get friendsIntroducerRevokeBody =>
      'Le presentazioni nuove e senza risposta si fermeranno. Un match reciproco già esistente resta tra le due persone.';

  @override
  String get friendsIntroducerKeepPermission => 'Mantieni il permesso';

  @override
  String get friendsIntroducerRemovePermission => 'Rimuovi permesso';

  @override
  String get friendsIntroducerPermissionRemoved => 'Permesso rimosso.';

  @override
  String get friendsIntroducerMemberTitle => 'I tuoi intermediari';

  @override
  String get friendsIntroducerAppTitle => 'Connect · Amici';

  @override
  String get friendsIntroducerRefresh => 'Aggiorna permessi';

  @override
  String get friendsIntroducerAccount => 'Account';

  @override
  String get friendsIntroducerAccountPrivacy => 'Account e privacy';

  @override
  String get friendsIntroducerSignOut => 'Esci';

  @override
  String get friendsIntroducerMemberHeadline => 'Buoni amici. Decidi tu.';

  @override
  String get friendsIntroducerHeadline => 'Li conosci.\nVedi la possibilità.';

  @override
  String get friendsIntroducerMemberIntro =>
      'Invita una persona di cui ti fidi a presentarti. Può unirsi senza un profilo per incontri. Decidi tu chi riceve il permesso e cosa mostra un’anteprima.';

  @override
  String get friendsIntroducerIntro =>
      'Un po’ di attenzione può far nascere qualcosa di vero. Fai incontrare gli amici che ti hanno chiesto aiuto.';

  @override
  String get friendsIntroducerMemberListTitle => 'Le persone che scegli';

  @override
  String get friendsIntroducerListTitle => 'La tua piccola cerchia';

  @override
  String get friendsIntroducerLoadFailed =>
      'Non siamo riusciti a caricare i permessi. Non è stato cambiato nulla.';

  @override
  String get friendsIntroducerMemberEmpty =>
      'Ancora nessun intermediario. Condividi un invito con un amico fidato per iniziare.';

  @override
  String get friendsIntroducerEmpty =>
      'La tua cerchia inizia con un permesso. Chiedi a un amico su Connect il suo codice di invito.';

  @override
  String get friendsIntroducerStatusPendingMember =>
      'Chiede il tuo permesso per presentarti.';

  @override
  String get friendsIntroducerStatusPending =>
      'In attesa dell’approvazione del tuo amico.';

  @override
  String get friendsIntroducerStatusPaused => 'Le presentazioni sono in pausa.';

  @override
  String get friendsIntroducerStatusActive =>
      'Ha il permesso di suggerire presentazioni.';

  @override
  String friendsIntroducerPreview(String extras) {
    String _temp0 = intl.Intl.selectLogic(extras, {
      'photo':
          'Anteprima per un appuntamento suggerito: nome ed età facoltativa, foto.',
      'city':
          'Anteprima per un appuntamento suggerito: nome ed età facoltativa, città.',
      'both':
          'Anteprima per un appuntamento suggerito: nome ed età facoltativa, foto, città.',
      'other':
          'Anteprima per un appuntamento suggerito: nome ed età facoltativa.',
    });
    return '$_temp0';
  }

  @override
  String get friendsIntroducerApproveNote =>
      'Approvare attiva anche le presentazioni tra amici. Puoi mettere in pausa tutte le presentazioni in Ritmo degli appuntamenti.';

  @override
  String get friendsIntroducerAllow => 'Consenti presentazioni';

  @override
  String friendsIntroducerAllowed(String name) {
    return '$name ora ha il tuo permesso.';
  }

  @override
  String get friendsIntroducerDecline => 'Rifiuta richiesta';

  @override
  String get friendsIntroducerSentTitle => 'Inviate con cura';

  @override
  String get friendsIntroducerSentBody =>
      'Le loro risposte restano tra loro. Entrambi devono dire sì perché nasca un match.';

  @override
  String get friendsIntroducerReloadSent => 'Ricarica presentazioni inviate';

  @override
  String get friendsIntroducerSentSubtitle =>
      'Inviata · la loro decisione è privata';

  @override
  String get friendsIntroducerStepPreview => '1. Scegli l’anteprima';

  @override
  String get friendsIntroducerPreviewBody =>
      'Un appuntamento suggerito vede il tuo nome e la tua età, se la mostri già. Il tuo intermediario vede solo il tuo nome, mai il tuo profilo o la tua attività di incontri.';

  @override
  String get friendsIntroducerIncludePhoto => 'Includi la mia foto profilo';

  @override
  String get friendsIntroducerIncludeCity => 'Includi la mia città';

  @override
  String get friendsIntroducerStepInvite => '2. Invita un amico fidato';

  @override
  String get friendsIntroducerInviteBody =>
      'Il codice funziona una volta e scade dopo 48 ore. Il tuo amico si unisce tramite «Solo per presentare amici» nella schermata di benvenuto. Approverai il suo nome qui prima che venga condiviso qualsiasi cosa.';

  @override
  String get friendsIntroducerInviteReady =>
      'Invito pronto. I codici precedenti non usati non funzionano più.';

  @override
  String get friendsIntroducerCreateCode => 'Crea codice di invito';

  @override
  String get friendsIntroducerShareCode =>
      'Condividilo in privato con il tuo amico. Per cambiare questa anteprima, annulla l’invito non usato e crea un nuovo codice.';

  @override
  String get friendsIntroducerCodeCopied => 'Codice di invito copiato';

  @override
  String get friendsIntroducerCopyCode => 'Copia codice';

  @override
  String get friendsIntroducerInvitesCancelled => 'Inviti non usati annullati.';

  @override
  String get friendsIntroducerCancelInvites => 'Annulla inviti non usati';

  @override
  String get friendsIntroducerManagePrefs =>
      'Gestisci tutte le preferenze di presentazione';

  @override
  String get friendsIntroducerRedeemTitle => 'Un amico ti ha invitato?';

  @override
  String get friendsIntroducerRedeemBody =>
      'Incolla il suo codice di invito privato. Confermerà il tuo nome prima che tu possa presentarlo.';

  @override
  String get friendsIntroducerCodeLabel => 'Codice di invito';

  @override
  String get friendsIntroducerCodeMissing =>
      'Inserisci il codice di invito che ti ha dato il tuo amico.';

  @override
  String get friendsIntroducerRequestSent =>
      'Richiesta inviata. Il tuo amico ora può approvarti in «I tuoi intermediari».';

  @override
  String get friendsIntroducerAskPermission => 'Chiedi il permesso';

  @override
  String get friendsIntroducerNeedTwo =>
      'Quando due amici ti daranno il permesso, potrai suggerire una presentazione qui.';

  @override
  String get friendsIntroducerComposerTitle => 'Vedi una possibilità?';

  @override
  String get friendsIntroducerWhyLabel =>
      'Perché hai pensato a loro (facoltativo)';

  @override
  String get friendsIntroducerWhyHelper =>
      'Lo vedranno entrambi. Evita i dettagli privati.';

  @override
  String get friendsIntroducerIntroSent =>
      'Presentazione inviata. Ognuno può decidere in privato.';

  @override
  String get friendsIntroducerSuggest => 'Suggerisci una presentazione';

  @override
  String get friendsIntroducerPrivacyNote =>
      'Prima il permesso. Nessuna attività di incontri pubblica. Nessun aggiornamento su chi ha detto sì o no.';

  @override
  String get planSharingLoadFailed =>
      'Impossibile caricare le opzioni di condivisione.';

  @override
  String get planSharingOffSnack =>
      'La condivisione con i contatti è disattivata.';

  @override
  String get planSharingSavedSnack =>
      'I contatti che hai scelto ora possono vedere questo piano.';

  @override
  String get planSharingSaveFailed =>
      'Impossibile salvare. Ricarica le scelte prima di riprovare.';

  @override
  String get planSharingTitle => 'Il tuo piano. Le tue persone.';

  @override
  String get planSharingCloseTooltip => 'Chiudi la condivisione';

  @override
  String get planSharingIntro =>
      'La condivisione con i contatti parte disattivata. Scegli fino a 10 amici fidati per questo piano. L\'altra persona sceglie i propri contatti.';

  @override
  String get planSharingNoContacts =>
      'Ancora nessun amico idoneo. Il piano resta disponibile per te e l\'altra persona.';

  @override
  String get planSharingFriendFallback => 'Un amico';

  @override
  String get planSharingPreviewNone =>
      'Anteprima · nessun contatto selezionato';

  @override
  String planSharingPreviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Anteprima · $count selezionati',
      one: 'Anteprima · $count selezionato',
    );
    return '$_temp0';
  }

  @override
  String get planSharingPreviewOffBody =>
      'I tuoi amici non riceveranno aggiornamenti sul piano né sui check-in.';

  @override
  String get planSharingPreviewOnBody =>
      'Questi contatti vedono il nome dell\'altra persona, ora e luogo, lo stato del piano e i tuoi check-in. Ricevono il piano attuale quando salvi.';

  @override
  String get planSharingPrivacyNote =>
      'I messaggi e il feedback privato dopo l\'appuntamento restano privati. Se rimuovi un contatto, non riceverà altri aggiornamenti e perderà l\'accesso al piano nell\'app. Gli aggiornamenti già arrivati su un dispositivo non si possono richiamare.';

  @override
  String get planSharingReload => 'Ricarica le opzioni di condivisione';

  @override
  String get planSharingSaving => 'Salvataggio…';

  @override
  String get planSharingKeepOff => 'Lascia disattivata la condivisione';

  @override
  String get planSharingShareSelected => 'Condividi con i contatti scelti';

  @override
  String get planSharingDeselectAll => 'Deseleziona tutti';

  @override
  String planBudgetLine(String budget) {
    return 'Budget · $budget';
  }

  @override
  String planAtmosphereLine(String atmospheres) {
    return 'Atmosfera · $atmospheres';
  }

  @override
  String get planAtmosphereQuiet => 'Una conversazione tranquilla';

  @override
  String get planAtmosphereRelaxed => 'Rilassato e senza fretta';

  @override
  String get planAtmosphereLively => 'Un posto vivace';

  @override
  String get planAtmosphereOutdoors => 'All\'aperto';

  @override
  String get planAtmosphereIndoors => 'Al chiuso';

  @override
  String get planAccessStepFree => 'Accesso senza gradini';

  @override
  String get planAccessToilet => 'Bagno accessibile';

  @override
  String get planAccessSeating => 'Posti a sedere disponibili';

  @override
  String get planAccessLowNoise => 'Poco rumore di fondo';

  @override
  String get planAccessTransit => 'Vicino ai mezzi pubblici';

  @override
  String get planAccessCaptions => 'Sottotitoli per un appuntamento video';

  @override
  String get planComfortHeading => 'Per stare a proprio agio';

  @override
  String get planPreferencesDisclaimer =>
      'Preferenze condivise per questo piano. Verifica questi dettagli con il locale o il servizio video.';

  @override
  String get planProposeErrorKept =>
      'Non è stato possibile inviare il piano. Le tue scelte sono ancora qui.';

  @override
  String get planChangedError =>
      'Questo piano è cambiato. Chiudi questa schermata per rivedere la conversazione.';

  @override
  String get planProposeHeadline => 'Un piano che entusiasma entrambi.';

  @override
  String get planCounterHeadline => 'Definite insieme questo piano';

  @override
  String planProposeLead(String name) {
    return 'Una proposta per te e $name. Niente è deciso finché l\'altra persona non accetta questa versione.';
  }

  @override
  String get planFindTimeTitle => 'Trovate un po\' di tempo insieme';

  @override
  String get planFindTimeBody =>
      'Vengono mostrati solo gli orari in comune, se entrambi condividete la disponibilità. Puoi sempre proporre tu un orario.';

  @override
  String get planSharedTimesFailed =>
      'Impossibile caricare gli orari in comune. Puoi comunque scegliere tu un orario.';

  @override
  String get planSharedTimesEmpty =>
      'Al momento nessun orario in comune da suggerire. Non significa che uno di voi non sia disponibile.';

  @override
  String get planRefreshSharedTimes => 'Aggiorna gli orari in comune';

  @override
  String get planSetAvailability => 'Imposta la mia disponibilità';

  @override
  String get planWhenTitle => 'Quando ti andrebbe bene?';

  @override
  String get planTimeSourceManual => 'Un orario che proponi tu';

  @override
  String get planTimeSourceShared =>
      'Scelto dalla disponibilità in comune · ricontrollato all\'invio';

  @override
  String planLocalTimeNote(int minutes, String timeZone) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Ora locale del tuo dispositivo ($timeZone). Durata: $minutes minuti.',
      one:
          'Ora locale del tuo dispositivo ($timeZone). Durata: $minutes minuto.',
    );
    return '$_temp0';
  }

  @override
  String planDurationChip(int minutes) {
    return '$minutes min';
  }

  @override
  String get planEnjoyTitle => 'Qualcosa che ti piacerebbe';

  @override
  String get planAreaHint => 'Un quartiere o un punto d\'incontro pubblico';

  @override
  String get planBudgetTitle => 'Quale budget ti fa sentire a tuo agio?';

  @override
  String get planBudgetBody =>
      'Un punto di partenza da concordare insieme, non un preventivo né una promessa su chi paga.';

  @override
  String get planAtmosphereTitle => 'Scegli l\'atmosfera';

  @override
  String get planAtmosphereBody =>
      'Scegli fino a tre atmosfere che ti piacerebbero. Facoltativo.';

  @override
  String get planComfortTitle => 'Perché sia comodo per entrambi';

  @override
  String get planComfortBody =>
      'Preferenze di accessibilità facoltative. Le scelte vengono condivise con il tuo match quando invii il piano. Non vengono aggiunte al profilo pubblico né agli aggiornamenti per i contatti fidati.';

  @override
  String get planComfortDisclaimer =>
      'Non devi spiegare nessuna diagnosi. Sono richieste da verificare con il locale o il servizio video, non servizi garantiti.';

  @override
  String get planNoteHint => 'Sabato pomeriggio, in un posto più tranquillo?';

  @override
  String get planReviewBeforeSending =>
      'Prima di inviare, controlla l\'orario e le scelte qui sopra. L\'altra persona può accettare, rifiutare o proporre una modifica.';

  @override
  String get planReloadLatest =>
      'Ricarica l\'ultimo piano · scarta le modifiche';

  @override
  String get planSending => 'Invio…';

  @override
  String get planSendSuggestion => 'Invia la tua proposta';

  @override
  String get planSecondYesTitle => 'Condividi un secondo sì';

  @override
  String get planSecondYesBody =>
      'Fai sapere che vorresti rivedervi solo se anche il tuo match dice sì e accetta di condividerlo. Le altre risposte restano private.';

  @override
  String get planSecondYesHeadline => 'Un secondo sì, da entrambi';

  @override
  String get planSecondYesCardBody =>
      'Avete scelto entrambi di dire che vorreste rivedervi.';

  @override
  String get planAnotherHello => 'Organizza un altro incontro';

  @override
  String get planSuggestChange => 'Proponi una modifica';

  @override
  String get planChooseUpdates => 'Scegli chi riceve i tuoi aggiornamenti';

  @override
  String planQuotedNote(String note) {
    return '«$note»';
  }

  @override
  String get planStatusDeclined => 'Rifiutato';

  @override
  String get planStatusExpired => 'Scaduto';

  @override
  String get planStatusCompleted => 'Completato';

  @override
  String get planStatusDidNotHappen => 'Non è avvenuto';

  @override
  String get planStatusDisputed => 'Contestato';

  @override
  String get plansManageSharing => 'Gestisci la condivisione con i contatti';

  @override
  String get plansLoadFailed =>
      'Impossibile caricare i piani per gli appuntamenti.';

  @override
  String get plansFeedLoadFailed => 'Impossibile caricare i piani.';

  @override
  String get planAcceptFailed => 'Impossibile accettare questo piano.';

  @override
  String get planDeclineFailed => 'Impossibile rifiutare questo piano.';

  @override
  String get planCancelFailed => 'Impossibile annullare questo piano.';

  @override
  String get planCheckinFailed =>
      'Al momento non è possibile fare il check-in.';

  @override
  String get graduationFoundEachOther => 'Vi siete trovati';

  @override
  String graduationHeadlineDecide(String name) {
    return '$name vuole lasciare Connect insieme a te';
  }

  @override
  String graduationHeadlineWaiting(String name) {
    return 'In attesa di $name';
  }

  @override
  String get graduationBodyConfirmed =>
      'Siete entrambi nascosti in Scopri. Questa chat resta aperta.';

  @override
  String get graduationBodyDecide =>
      'Conferma e uscirete entrambi da Scopri. La vostra chat resta.';

  @override
  String get graduationBodyWaiting =>
      'Hai chiesto di andarvene insieme. L\'altra persona può confermare o rifiutare.';

  @override
  String get graduationCelebrate => 'Festeggia';

  @override
  String get graduationNotYet => 'Non ancora';

  @override
  String get graduationConfirm => 'Conferma';

  @override
  String get graduationFriendsToldOnConfirm =>
      'I tuoi amici lo sapranno quando l\'altra persona confermerà.';

  @override
  String get graduationOnlyTwoOfYouForNow => 'Per ora lo sapete solo voi due.';

  @override
  String get graduationWithdraw => 'Ritira';

  @override
  String graduationProposeTitle(String name) {
    return 'Lasciare Connect con $name?';
  }

  @override
  String graduationProposeBody(String name) {
    return 'Quando $name conferma, sarete entrambi nascosti in Scopri. Questa chat resta aperta e puoi tornare in Scopri in qualsiasi momento da Privacy e sicurezza.';
  }

  @override
  String get graduationNoteLabel =>
      'Un messaggio per l\'altra persona (facoltativo)';

  @override
  String get graduationNoteHint => 'Racconta perché è il momento giusto';

  @override
  String get graduationTellFriends => 'Dillo ai miei amici';

  @override
  String get graduationTellFriendsBody =>
      'I tuoi amici accettati sapranno che hai trovato qualcuno, ma non chi.';

  @override
  String get graduationAskThem => 'Chiedi';

  @override
  String get graduationTitle => 'Il grande passo';

  @override
  String graduationCelebrationBody(String name) {
    return 'Tu e $name lasciate Connect insieme. Siete entrambi nascosti in Scopri e questa chat resta aperta per tutto il tempo che volete.';
  }

  @override
  String get graduationFriendsHaveBeenTold =>
      'I tuoi amici sono stati avvisati.';

  @override
  String get graduationFriendsAreTold => 'I tuoi amici vengono avvisati.';

  @override
  String get graduationOnlyTwoOfYou => 'Lo sapete solo voi due.';

  @override
  String get graduationConfirmAndBack => 'Conferma e torna indietro';

  @override
  String get graduationBackToConnect => 'Torna a Connect';

  @override
  String get graduationLoadFailed => 'Impossibile caricare il grande passo.';

  @override
  String get graduationProposeFailed =>
      'Impossibile proporre di andarvene insieme.';

  @override
  String get graduationConfirmFailed =>
      'Al momento non è possibile confermare.';

  @override
  String get graduationDeclineFailed => 'Al momento non è possibile rifiutare.';

  @override
  String get graduationWithdrawFailed => 'Impossibile ritirare la proposta.';

  @override
  String get graduationPauseLoadFailed =>
      'Impossibile caricare lo stato di Scopri.';

  @override
  String get graduationPauseFailed => 'Impossibile mettere in pausa Scopri.';

  @override
  String get graduationResumeFailed => 'Impossibile riprendere Scopri.';

  @override
  String get engagementCirclesEmptyTitle => 'Nessun circolo disponibile';

  @override
  String get engagementCirclesPullToRefresh =>
      'Trascina verso il basso per aggiornare.';

  @override
  String get engagementCirclesJoined => 'Iscritto';

  @override
  String get engagementCirclesNotJoined => 'Non iscritto';

  @override
  String engagementCirclesParticipants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partecipanti questa settimana',
      one: '1 partecipante questa settimana',
    );
    return '$_temp0';
  }

  @override
  String get engagementCirclesJoin => 'Entra nel circolo';

  @override
  String get engagementCirclesResponseLabel =>
      'La tua risposta alla sfida settimanale';

  @override
  String get engagementCirclesSubmit => 'Invia risposta';

  @override
  String get engagementCirclesTopicFallback => 'Circolo';

  @override
  String get engagementCirclesLoadFailed =>
      'Al momento non è possibile caricare i circoli.';

  @override
  String get engagementCirclesJoinFailed =>
      'Al momento non è possibile entrare nel circolo.';

  @override
  String get engagementCirclesEnterResponse =>
      'Scrivi la tua risposta alla sfida.';

  @override
  String get engagementCirclesSubmitFailed =>
      'Al momento non è possibile inviare la risposta.';

  @override
  String get engagementNudgesTitle => 'Spintarelle ai match';

  @override
  String get engagementNudgesIntro =>
      'Invia un promemoria gentile per riaccendere una conversazione ferma. Limiti giornalieri e regole di sicurezza sono applicati dal server.';

  @override
  String get engagementNudgesEmpty =>
      'Nessun match a cui mandare una spintarella.';

  @override
  String get engagementNudgesSentInSession =>
      'Spintarella inviata in questa sessione';

  @override
  String get engagementNudgesReady => 'Pronta da inviare';

  @override
  String engagementNudgesSentTo(String name) {
    return 'Spintarella inviata a $name.';
  }

  @override
  String get engagementNudgesAction => 'Spintarella';

  @override
  String get engagementNudgesSendFailed =>
      'Impossibile inviare questa spintarella.';

  @override
  String get engagementTrustBadgesEarned => 'Badge ottenuti';

  @override
  String get engagementTrustBadgesEmpty =>
      'Ancora nessun badge. Completa attività per sbloccare i badge di fiducia.';

  @override
  String engagementTrustBadgesDetails(
    String code,
    String status,
    String awardedAt,
  ) {
    return 'Codice: $code\nStato: $status • Ottenuto il $awardedAt';
  }

  @override
  String get engagementTrustBadgesHistory => 'Cronologia recente';

  @override
  String get engagementTrustBadgesHistoryEmpty =>
      'Ancora nessuna cronologia di fiducia.';

  @override
  String get engagementTrustBadgesMilestoneUnavailable =>
      'Stato del traguardo non disponibile.';

  @override
  String get engagementTrustBadgesCurrentMilestone => 'Traguardo attuale';

  @override
  String get engagementTrustBadgesLoadFailed =>
      'Impossibile caricare i badge di fiducia. Riprova.';

  @override
  String get engagementTrustFiltersEnable => 'Attiva i filtri di fiducia';

  @override
  String get engagementTrustFiltersEnableSubtitle =>
      'Nascondi i profili che non soddisfano i tuoi requisiti di fiducia';

  @override
  String engagementTrustFiltersMinimum(int count) {
    return 'Numero minimo di badge attivi: $count';
  }

  @override
  String get engagementTrustFiltersRequired => 'Badge richiesti';

  @override
  String get engagementTrustFiltersSaved => 'Filtri di fiducia salvati.';

  @override
  String get engagementTrustFiltersSave => 'Salva i filtri di fiducia';

  @override
  String get engagementAppealStatusSubmitted => 'Inviato';

  @override
  String get engagementAppealStatusUnderReview => 'In revisione';

  @override
  String get engagementAppealStatusResolvedUpheld => 'Risolto (confermato)';

  @override
  String get engagementAppealStatusResolvedReversed => 'Risolto (annullato)';

  @override
  String get engagementRoomsLeaveFailed =>
      'Impossibile uscire da questa stanza. Riprova.';

  @override
  String get engagementRoomsPresenceFailed =>
      'Collegamento con la stanza perso.';

  @override
  String get engagementRoomsMembersFailed =>
      'Impossibile caricare chi c’è. Riprova.';

  @override
  String get engagementRoomsModerationFailed =>
      'Non è andato a buon fine. Riprova.';

  @override
  String get engagementRoomsCreateFailed =>
      'Impossibile avviare la stanza. Riprova.';

  @override
  String get engagementRoomsLoadFailed =>
      'Le stanze non sono disponibili al momento. Trascina per riprovare.';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonRemove => 'Rimuovi';

  @override
  String get accountTitle => 'Account e dati';

  @override
  String get accountLoadFailed =>
      'Impossibile caricare lo stato del tuo account.';

  @override
  String accountDeletionIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Eliminazione tra $days giorni',
      one: 'Eliminazione tra 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get accountDeletionDue => 'L’eliminazione è imminente';

  @override
  String get accountDeletionCountdownBody =>
      'Il tuo profilo è nascosto. Fino ad allora puoi accedere e annullare: dopo, i tuoi dati non potranno essere recuperati.';

  @override
  String get accountKeepMyAccount => 'Mantieni il mio account';

  @override
  String get accountNotDeletedSnack => 'Il tuo account non verrà eliminato.';

  @override
  String get accountCancelFailed => 'Impossibile annullare. Riprova.';

  @override
  String get accountHiddenTitle => 'Il tuo profilo è nascosto';

  @override
  String get accountTakeBreakTitle => 'Prenditi una pausa';

  @override
  String get accountHiddenBody =>
      'Nessuno può vederti o fare match con te. I tuoi match e messaggi restano salvati e puoi tornare quando vuoi.';

  @override
  String get accountTakeBreakBody =>
      'Nascondi il tuo profilo da Scopri senza perdere nulla. Resti connesso e puoi tornare indietro quando vuoi.';

  @override
  String get accountUnhideProfile => 'Mostra di nuovo il mio profilo';

  @override
  String get accountHideProfile => 'Nascondi il mio profilo';

  @override
  String get accountVisibleAgainSnack => 'Il tuo profilo è di nuovo visibile.';

  @override
  String get accountNowHiddenSnack => 'Il tuo profilo ora è nascosto.';

  @override
  String get accountUpdateFailed => 'Impossibile aggiornare. Riprova.';

  @override
  String get accountDownloadTitle => 'Scarica i tuoi dati';

  @override
  String get accountDownloadBody =>
      'Ottieni una copia del tuo profilo, delle preferenze, dei match e dei messaggi che hai inviato. I messaggi scritti da altri non sono inclusi.';

  @override
  String get accountPreparing => 'Preparazione…';

  @override
  String get accountPrepareData => 'Prepara i miei dati';

  @override
  String get accountPrepareFailed =>
      'Impossibile preparare i tuoi dati. Riprova.';

  @override
  String get accountYourData => 'I tuoi dati';

  @override
  String get accountDeleteTitle => 'Elimina il mio account';

  @override
  String get accountDeleteBody =>
      'Il tuo profilo viene nascosto subito e tutto viene cancellato dopo un periodo di tolleranza. In quel periodo puoi annullare accedendo. Dopo, nulla potrà essere recuperato.';

  @override
  String get accountDeletionAlreadyScheduled => 'Eliminazione già programmata';

  @override
  String get accountDeleteConfirmTitle => 'Eliminare il tuo account?';

  @override
  String get accountDeleteConfirmBody =>
      'Il tuo profilo, le foto, i match e i messaggi verranno cancellati e non potranno essere recuperati.\n\nSe vuoi solo una pausa, nascondere il profilo conserva tutto e si può annullare.';

  @override
  String get accountHideInstead => 'Nascondi invece';

  @override
  String get accountDeletionScheduledSnack =>
      'Eliminazione programmata. Puoi annullarla fino ad allora.';

  @override
  String get privacyTitle => 'Privacy e sicurezza';

  @override
  String get privacyShowAge => 'Mostra età';

  @override
  String get privacyShowAgeSubtitle => 'Scegli se la tua età è visibile';

  @override
  String get privacyShowDistance => 'Mostra distanza esatta';

  @override
  String get privacyShowDistanceSubtitle =>
      'Mostra la distanza precisa sul tuo profilo';

  @override
  String get privacyShowOnline => 'Mostra stato online';

  @override
  String get privacyShowOnlineSubtitle =>
      'Consenti agli altri di vedere se sei online';

  @override
  String get privacyEmergencySos => 'SOS di emergenza';

  @override
  String get privacyEmergencySosSubtitle =>
      'Attiva un avviso e consulta la cronologia';

  @override
  String get privacyEmergencyContacts => 'Contatti di emergenza';

  @override
  String get privacyEmergencyContactsSubtitle =>
      'Gestisci i contatti di emergenza fidati';

  @override
  String get privacyBlockedUsers => 'Utenti bloccati';

  @override
  String get privacyBlockedUsersSubtitle => 'Rivedi e sblocca utenti';

  @override
  String get privacyModerationAppeals => 'Ricorsi di moderazione';

  @override
  String get privacyModerationAppealsSubtitle =>
      'Invia un ricorso e segui lo stato della revisione';

  @override
  String get privacyFriendSearch => 'Fammi trovare nella ricerca amici';

  @override
  String get privacySettingLoadFailed =>
      'Impossibile caricare questa impostazione. Riapri la pagina per riprovare.';

  @override
  String get privacyFriendSearchSubtitle =>
      'I membri possono trovarti per nome o @nomeutente in Aggiungi amico. Le persone con cui fai match o che incontri nelle stanze e nei gruppi possono comunque aggiungerti.';

  @override
  String get privacyChoiceSaveFailed => 'Impossibile salvare la tua scelta.';

  @override
  String get privacyShowcase => 'Mostra i miei scritti pubblici sul profilo';

  @override
  String get privacyShowcaseSubtitle =>
      'I membri vedono sul tuo profilo i capitoli che condividi con la community e le tue foto sulla bacheca. I capitoli privati o solo per amici non compaiono mai.';

  @override
  String get privacyCrashReports =>
      'Condividi i rapporti sugli arresti anomali';

  @override
  String get privacyCrashReportsSubtitle =>
      'I rapporti anonimi su arresti ed errori ci aiutano a risolvere i problemi. Non includono messaggi, foto o dati dell’account.';

  @override
  String get privacyGraduatedReason =>
      'Hai lasciato Connect con il tuo match. La tua scheda non viene mostrata a nessuno.';

  @override
  String get privacyPausedReason =>
      'La tua scheda non viene mostrata a nessuno finché non riprendi.';

  @override
  String get privacyActiveReason =>
      'Vieni mostrato agli altri membri in Scopri.';

  @override
  String get privacyDiscoveryPaused => 'Scopri in pausa';

  @override
  String get privacyDiscoveryActive => 'Scopri attivo';

  @override
  String get privacyResume => 'Riprendi';

  @override
  String get privacyPause => 'Metti in pausa';

  @override
  String get emergencyIntro =>
      'Aggiungi fino a 3 contatti fidati. Verranno usati in futuro per le procedure di sicurezza e le funzioni SOS.';

  @override
  String get emergencyEmpty => 'Nessun contatto di emergenza aggiunto.';

  @override
  String get emergencyMaxReached => 'Numero massimo di contatti raggiunto';

  @override
  String get emergencyAddContact => 'Aggiungi contatto';

  @override
  String get emergencyEditContact => 'Modifica contatto';

  @override
  String get emergencyInvalidInput =>
      'Inserisci un nome e un numero di telefono validi.';

  @override
  String get emergencyAdded => 'Contatto di emergenza aggiunto.';

  @override
  String get emergencyAddFailed =>
      'Impossibile aggiungere il contatto. Riprova.';

  @override
  String get emergencyUpdated => 'Contatto di emergenza aggiornato.';

  @override
  String get emergencyUpdateFailed =>
      'Impossibile aggiornare il contatto. Riprova.';

  @override
  String get emergencyRemoveTitle => 'Rimuovi contatto';

  @override
  String emergencyRemoveBody(String name) {
    return 'Rimuovere $name dai contatti di emergenza?';
  }

  @override
  String get emergencyRemoved => 'Contatto di emergenza rimosso.';

  @override
  String get emergencyRemoveFailed =>
      'Impossibile rimuovere il contatto. Riprova.';

  @override
  String get emergencyNameLabel => 'Nome';

  @override
  String get emergencyPhoneLabel => 'Numero di telefono';

  @override
  String get appealsSubmitTitle => 'Invia un ricorso';

  @override
  String get appealsReasonLabel => 'Motivo';

  @override
  String get appealsReasonHint =>
      'Perché questa decisione di moderazione dovrebbe essere rivista?';

  @override
  String get appealsReportIdLabel => 'ID segnalazione (facoltativo)';

  @override
  String get appealsContextLabel => 'Contesto aggiuntivo (facoltativo)';

  @override
  String get appealsSubmit => 'Invia ricorso';

  @override
  String get appealsEmpty =>
      'Nessun ricorso inviato. I tuoi ricorsi compariranno qui con gli aggiornamenti di stato.';

  @override
  String appealsIdLine(String id) {
    return 'ID ricorso: $id';
  }

  @override
  String appealsSlaLine(String deadline) {
    return 'Scadenza revisione: $deadline';
  }

  @override
  String appealsReviewedBy(String reviewer) {
    return 'Revisionato da: $reviewer';
  }

  @override
  String get appealsReasonRequired => 'Il motivo è obbligatorio.';

  @override
  String get appealsSubmitted => 'Ricorso inviato correttamente.';

  @override
  String get appealsSubmitFailed => 'Impossibile inviare il ricorso. Riprova.';

  @override
  String get blockedEmpty => 'Non hai bloccato nessuno.';

  @override
  String get blockedUnblock => 'Sblocca';

  @override
  String get blockedUnblockTitle => 'Sblocca utente';

  @override
  String blockedUnblockBody(String name) {
    return 'Sbloccare $name?';
  }

  @override
  String blockedUnblockedSnack(String name) {
    return '$name è stato sbloccato.';
  }

  @override
  String get blockedUnblockFailed => 'Impossibile sbloccare. Riprova.';

  @override
  String aboutVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get aboutDescription =>
      'App di incontri basata sulla fiducia: profili autentici, comunicazione sicura e relazioni serie.';

  @override
  String get aboutStack => 'Tecnologie';

  @override
  String get aboutStackFlutter => 'Flutter (prima Android)';

  @override
  String get aboutStackGo => 'Servizi Go + PostgreSQL nativo';

  @override
  String get aboutStackRiverpod => 'Gestione dello stato con Riverpod';

  @override
  String get communitySpoiler => 'Spoiler — tocca per mostrare';

  @override
  String get communityReportFailed => 'Impossibile inviare la segnalazione.';

  @override
  String get communityReportSubmitted => 'Segnalazione inviata. Grazie.';

  @override
  String communityBlockTitle(String name) {
    return 'Bloccare $name?';
  }

  @override
  String get communityBlockBody =>
      'Non vedrete più le foto, i post nei club, le recensioni e le liste l’uno dell’altro. Viene bloccato anche il contatto tramite Connect.';

  @override
  String get communityBlockAction => 'Blocca membro';

  @override
  String get communityBlockFailed =>
      'Impossibile bloccare questo membro. Riprova.';

  @override
  String get reportSheetTitle => 'Segnala';

  @override
  String get reportReasonHarassment => 'Molestie';

  @override
  String get reportReasonInappropriate => 'Contenuti inappropriati';

  @override
  String get reportReasonFraud => 'Frode / truffa';

  @override
  String get reportReasonFake => 'Profilo falso';

  @override
  String get reportReasonLabel => 'Motivo';

  @override
  String get reportDescriptionLabel => 'Descrizione (facoltativa)';

  @override
  String get reportDescriptionHint =>
      'Aggiungi dettagli per aiutarci a esaminare la segnalazione';

  @override
  String get reportSubmitFailed =>
      'Impossibile inviare la segnalazione. Riprova.';

  @override
  String get reportSubmit => 'Invia segnalazione';

  @override
  String get membershipTitle => 'Abbonamento';

  @override
  String get membershipChooseYourPlan => 'Scegli il tuo piano';

  @override
  String get membershipCycleNoteMonthly =>
      'Pagamento con carta. Si rinnova automaticamente ogni mese finché non lo disattivi.';

  @override
  String get membershipCycleNoteYearly =>
      'Pagamento con carta. Si rinnova automaticamente ogni anno finché non lo disattivi.';

  @override
  String get membershipNoPlansOnSale =>
      'Al momento non ci sono piani disponibili.';

  @override
  String get membershipPaymentsTitle => 'Pagamenti';

  @override
  String get membershipNoCardPayments => 'Ancora nessun pagamento con carta.';

  @override
  String get membershipFooterNote =>
      'Il tuo piano si rinnova automaticamente alla fine di ogni periodo di fatturazione. Puoi disattivare il rinnovo automatico in qualsiasi momento; mantieni i vantaggi fino alla fine del periodo. I dati della carta sono gestiti dal fornitore dei pagamenti e non vengono mai salvati nell\'app.';

  @override
  String membershipSwitchTitle(String plan) {
    return 'Passare a $plan?';
  }

  @override
  String membershipSwitchUpgradeBodyMonthly(String price) {
    return 'Ora sulla tua carta viene addebitata la differenza per il resto di questo periodo, poi $price al mese dal prossimo rinnovo.';
  }

  @override
  String membershipSwitchUpgradeBodyYearly(String price) {
    return 'Ora sulla tua carta viene addebitata la differenza per il resto di questo periodo, poi $price all\'anno dal prossimo rinnovo.';
  }

  @override
  String membershipSwitchDowngradeBodyMonthly(
    String currentPlan,
    String price,
  ) {
    return 'Il tuo piano cambia subito. Il tempo non usato di $currentPlan viene accreditato sul prossimo rinnovo, poi paghi $price al mese.';
  }

  @override
  String membershipSwitchDowngradeBodyYearly(String currentPlan, String price) {
    return 'Il tuo piano cambia subito. Il tempo non usato di $currentPlan viene accreditato sul prossimo rinnovo, poi paghi $price all\'anno.';
  }

  @override
  String get membershipNotNow => 'Non ora';

  @override
  String get membershipUpgrade => 'Passa al superiore';

  @override
  String get membershipSwitchPlan => 'Cambia piano';

  @override
  String membershipSwitchedSnack(String plan) {
    return 'Ora hai $plan.';
  }

  @override
  String get membershipCardUpdated => 'La tua carta è stata aggiornata.';

  @override
  String get membershipCardUpdatePending =>
      'Aggiornamento della carta non ancora confermato. Controlla lo stato prima di riprovare.';

  @override
  String get membershipCardUpdateEnded =>
      'Questa sessione di aggiornamento della carta è terminata. Aggiorna per vedere la tua carta attuale.';

  @override
  String get membershipCheckoutTitleCard => 'la tua carta';

  @override
  String get membershipAutoRenewOffTitle =>
      'Disattivare il rinnovo automatico?';

  @override
  String membershipAutoRenewOffBodyDate(String plan, String date) {
    return 'I vantaggi di $plan restano attivi fino al $date. Dopo passi al piano gratuito e la tua carta non viene più addebitata.';
  }

  @override
  String membershipAutoRenewOffBodyPeriodEnd(String plan) {
    return 'I vantaggi di $plan restano attivi fino alla fine del periodo in corso. Dopo passi al piano gratuito e la tua carta non viene più addebitata.';
  }

  @override
  String get membershipKeepRenewing => 'Continua a rinnovare';

  @override
  String get membershipTurnOff => 'Disattiva';

  @override
  String get membershipAutoRenewBackOn =>
      'Il rinnovo automatico è di nuovo attivo.';

  @override
  String get membershipAutoRenewNowOff =>
      'Il rinnovo automatico è disattivato. I tuoi vantaggi restano fino alla fine del periodo.';

  @override
  String membershipSubscribeTitle(String plan) {
    return 'Abbonati a $plan';
  }

  @override
  String membershipSubscribeBodyMonthly(String price) {
    return '$price al mese, addebitati sulla tua carta e rinnovati automaticamente finché non disattivi il rinnovo automatico. Inserirai la carta nella pagina sicura del fornitore dei pagamenti.';
  }

  @override
  String membershipSubscribeBodyYearly(String price) {
    return '$price all\'anno, addebitati sulla tua carta e rinnovati automaticamente finché non disattivi il rinnovo automatico. Inserirai la carta nella pagina sicura del fornitore dei pagamenti.';
  }

  @override
  String membershipSubscribeBodyTestMonthly(String price) {
    return 'Solo pagamento di prova: nessun addebito reale. $price al mese, simulati e rinnovati automaticamente finché non disattivi il rinnovo automatico. Inserirai la carta nella pagina sicura del fornitore dei pagamenti.';
  }

  @override
  String membershipSubscribeBodyTestYearly(String price) {
    return 'Solo pagamento di prova: nessun addebito reale. $price all\'anno, simulati e rinnovati automaticamente finché non disattivi il rinnovo automatico. Inserirai la carta nella pagina sicura del fornitore dei pagamenti.';
  }

  @override
  String get membershipContinueToCard => 'Continua con la carta';

  @override
  String get paymentStillConfirming =>
      'Il pagamento è ancora in fase di conferma. Tra poco trascina verso il basso per aggiornare.';

  @override
  String get membershipCheckoutEnded =>
      'Questa sessione di pagamento è terminata. Aggiorna la cronologia dei pagamenti prima di riprovare.';

  @override
  String get membershipRecoverAccountUnavailable =>
      'Impossibile verificare l\'account di pagamento. Riprova.';

  @override
  String get membershipRecoverCheckoutClosed =>
      'Account di pagamento aggiornato. Questo pagamento non è più aperto.';

  @override
  String get membershipRecoverConfirmed =>
      'Confermato. Il tuo account di pagamento è aggiornato.';

  @override
  String get membershipRecoverPending =>
      'La conferma è ancora in sospeso. Puoi ricontrollare qui.';

  @override
  String get membershipRecoverEnded =>
      'Questa sessione di pagamento è terminata. Controlla la cronologia dei pagamenti prima di avviarne un\'altra.';

  @override
  String membershipCelebrateTitle(String plan) {
    return 'Ora sei $plan';
  }

  @override
  String get membershipCelebrateBodyTest =>
      'Pagamento di prova confermato; non è stato addebitato denaro reale. Il tuo piano di prova si rinnova automaticamente. Gestisci il rinnovo automatico quando vuoi da questa schermata.';

  @override
  String get membershipCelebrateBody =>
      'Pagamento confermato. Il tuo piano si rinnova automaticamente. Gestisci il rinnovo automatico quando vuoi da questa schermata.';

  @override
  String get membershipStartExploring => 'Inizia a esplorare';

  @override
  String get membershipYourMembership => 'Il tuo abbonamento';

  @override
  String get membershipYourPlan => 'Il tuo piano';

  @override
  String get membershipFreePlanName => 'Gratuito';

  @override
  String membershipPricePerMonthShort(String price) {
    return '$price/mese';
  }

  @override
  String membershipPricePerYearShort(String price) {
    return '$price/anno';
  }

  @override
  String get membershipCardOnFile =>
      'Carta registrata presso il fornitore dei pagamenti';

  @override
  String get membershipCardBrandFallback => 'Carta';

  @override
  String get paymentOpening => 'Apertura…';

  @override
  String get membershipUpdateCard => 'Aggiorna carta';

  @override
  String get membershipLastPaymentFailed =>
      'L\'ultimo pagamento non è andato a buon fine. Riproveremo sulla tua carta; i vantaggi restano attivi per qualche giorno.';

  @override
  String membershipRenewsOn(String date) {
    return 'Si rinnova il $date';
  }

  @override
  String get membershipRenewsSoon => 'Si rinnova a breve';

  @override
  String membershipEndsOn(String date) {
    return 'Termina il $date · rinnovo automatico disattivato';
  }

  @override
  String get membershipEndsSoon =>
      'Termina a breve · rinnovo automatico disattivato';

  @override
  String get membershipAutoRenew => 'Rinnovo automatico';

  @override
  String get membershipAutoRenewOnSubtitle =>
      'Addebitato automaticamente a ogni periodo.';

  @override
  String get membershipAutoRenewOffSubtitle =>
      'Disattivato. I vantaggi terminano con il periodo in corso.';

  @override
  String get membershipFreeHeroBody =>
      'Sblocca più Mi piace, messaggi e visibilità in evidenza con un piano qui sotto. Paghi con carta e disdici quando vuoi.';

  @override
  String get membershipStatusFree => 'Gratis';

  @override
  String get membershipStatusPaymentDue => 'Pagamento dovuto';

  @override
  String get membershipStatusEnding => 'In scadenza';

  @override
  String get membershipStatusActive => 'Attivo';

  @override
  String get membershipCycleMonthly => 'Mensile';

  @override
  String get membershipCycleYearly => 'Annuale';

  @override
  String get membershipBadgeYourPlan => 'IL TUO PIANO';

  @override
  String get membershipBadgeMostPopular => 'IL PIÙ POPOLARE';

  @override
  String get membershipPerMonth => 'al mese';

  @override
  String get membershipPerYear => 'all\'anno';

  @override
  String membershipSavePercent(int percent) {
    return 'Risparmi il $percent%';
  }

  @override
  String membershipQuotaLikesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mi piace/giorno',
      one: '1 Mi piace/giorno',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messaggi/giorno',
      one: '1 messaggio/giorno',
    );
    return '$_temp0';
  }

  @override
  String get membershipQuotaUnlimitedLikes => 'Mi piace illimitati';

  @override
  String get membershipQuotaUnlimitedMessages => 'Messaggi illimitati';

  @override
  String get membershipYourCurrentPlan => 'Il tuo piano attuale';

  @override
  String get membershipSwitching => 'Cambio in corso…';

  @override
  String get membershipOpeningSecureCheckout =>
      'Apertura del pagamento sicuro…';

  @override
  String membershipSwitchToPlan(String plan) {
    return 'Passa a $plan';
  }

  @override
  String get membershipSubscribeWithCard => 'Abbonati con carta';

  @override
  String get membershipSettleBeforeSwitch =>
      'Salda il pagamento in sospeso del piano attuale prima di cambiare.';

  @override
  String get membershipPaymentChargeback => 'Storno';

  @override
  String get membershipPaymentDisputed => 'Contestato';

  @override
  String get membershipPaymentRefunded => 'Rimborsato';

  @override
  String get membershipPaymentPartlyRefunded => 'Rimborsato in parte';

  @override
  String get membershipPaymentFailed => 'Non riuscito';

  @override
  String get membershipPaymentPaid => 'Pagato';

  @override
  String get membershipPaymentPending => 'In attesa';

  @override
  String get membershipPaymentReasonFirstCharge => 'Primo addebito';

  @override
  String get membershipPaymentReasonRenewal => 'Rinnovo';

  @override
  String get membershipPaymentReasonPlanChange => 'Cambio piano';

  @override
  String get membershipPaymentReasonCoins => 'Monete';

  @override
  String get membershipPaymentReasonLocalActivation => 'Attivazione locale';

  @override
  String get membershipPaymentReasonCard => 'Pagamento con carta';

  @override
  String get membershipPaymentReasonOther => 'Pagamento';

  @override
  String get paymentModeSandbox => 'Test locale · nessun addebito reale';

  @override
  String get paymentModeStripeTest => 'Test Stripe · nessun addebito reale';

  @override
  String get paymentModeLive => 'Pagamenti reali';

  @override
  String get paymentModeUnavailable => 'Pagamenti non disponibili';

  @override
  String get paymentAccountTitle => 'Il tuo account di pagamento';

  @override
  String get paymentAccountSignedInMember => 'Membro connesso';

  @override
  String get paymentAccountCardTitle => 'Carta di credito o di debito';

  @override
  String get paymentAccountCardUnavailableTitle =>
      'Il pagamento con carta non è disponibile';

  @override
  String get paymentAccountCardBody =>
      'Inserisci la carta nella pagina di pagamento ospitata. Abbonamento e cronologia dei pagamenti appartengono a questo account.';

  @override
  String get paymentAccountCardUnavailableBody =>
      'Puoi continuare a usare il tuo account. I nuovi pagamenti con carta non sono attivi.';

  @override
  String paymentAccountTestCardHint(String cardNumber) {
    return 'Per i test usa $cardNumber, una scadenza futura e un CVC qualsiasi di tre cifre. Usa solo dati di prova.';
  }

  @override
  String get paymentAccountUnfinishedCardUpdate =>
      'Aggiornamento della carta non completato';

  @override
  String paymentAccountUnfinishedCheckout(String plan) {
    return 'Pagamento non completato: $plan';
  }

  @override
  String get paymentAccountPendingHint =>
      'Controlla lo stato più recente o continua lo stesso pagamento.';

  @override
  String get paymentAccountCheckStatus => 'Controlla stato';

  @override
  String get paymentAccountResumeCheckout => 'Riprendi il pagamento';

  @override
  String paymentCheckoutPayFor(String title) {
    return 'Paga: $title';
  }

  @override
  String get paymentCheckoutClose => 'Chiudi il pagamento';

  @override
  String get paymentCheckoutSecureNote =>
      'I dati della carta si inseriscono nella pagina sicura del fornitore dei pagamenti.';

  @override
  String paymentCheckoutCompleteInNewTab(String title) {
    return 'Completa il pagamento ($title) nella nuova scheda';
  }

  @override
  String get paymentCheckoutWaitingBody =>
      'I dati della carta si inseriscono nella pagina sicura del fornitore dei pagamenti. Torna qui quando indica che il pagamento è completato.';

  @override
  String get paymentCheckoutCheckConfirmation => 'Verifica conferma';

  @override
  String get paymentCheckoutBackToAccount => 'Torna all\'account';

  @override
  String get paymentWalletTitle => 'Portafoglio e pagamenti';

  @override
  String get paymentWalletTestNote =>
      'Pagamenti di prova · nessun addebito reale. Usa solo dati di carte di prova.';

  @override
  String get paymentWalletPopularTopUps => 'Ricariche popolari';

  @override
  String get paymentWalletTopUpsIntro =>
      'Paga con carta nella pagina di pagamento sicura. Le monete arrivano nel tuo portafoglio appena il pagamento viene saldato.';

  @override
  String get paymentWalletCardsDisabled =>
      'I pagamenti con carta non sono ancora attivi su questo server.';

  @override
  String get paymentWalletNoPacks =>
      'Al momento non ci sono pacchetti di monete disponibili.';

  @override
  String get paymentWalletActivity => 'Attività del portafoglio';

  @override
  String get paymentWalletNoPurchases => 'Ancora nessun acquisto di monete.';

  @override
  String get paymentWalletFooter =>
      'Le monete si usano per regali e boost in Connect. Gli acquisti sono definitivi una volta saldati; i dati della carta restano al fornitore dei pagamenti.';

  @override
  String paymentCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monete',
      one: '1 moneta',
    );
    return '$_temp0';
  }

  @override
  String paymentCoinsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monete aggiunte al tuo portafoglio.',
      one: '1 moneta aggiunta al tuo portafoglio.',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'monete',
      one: 'moneta',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnitBonus(int count, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'monete · +$bonus bonus',
      one: 'moneta · +$bonus bonus',
    );
    return '$_temp0';
  }

  @override
  String get paymentWalletCheckoutEnded =>
      'Questa sessione di pagamento è terminata. Controlla la cronologia dei pagamenti prima di riprovare.';

  @override
  String get paymentWalletBalanceLabel => 'Saldo del portafoglio Glow';

  @override
  String get paymentWalletSourceSupport => 'Ricarica dall\'assistenza';

  @override
  String get paymentWalletSourcePromo => 'Promozione';

  @override
  String get paymentWalletSourcePurchase => 'Acquisto di monete';

  @override
  String get paymentErrorSignInSubscriptions =>
      'Accedi per gestire gli abbonamenti.';

  @override
  String get paymentErrorSignInWallet =>
      'Accedi per gestire il tuo portafoglio.';

  @override
  String get paymentErrorLoadSubscription =>
      'Impossibile caricare i dettagli dell\'abbonamento.';

  @override
  String get paymentErrorLoadWallet =>
      'Impossibile caricare il tuo portafoglio.';

  @override
  String get paymentErrorStartCheckoutNow =>
      'Al momento non è possibile avviare il pagamento.';

  @override
  String get paymentErrorStartCheckout => 'Impossibile avviare il pagamento.';

  @override
  String get paymentErrorConfirmPayment =>
      'Non è ancora possibile confermare il pagamento.';

  @override
  String get paymentErrorAutoRenewOn =>
      'Impossibile riattivare il rinnovo automatico.';

  @override
  String get paymentErrorAutoRenewOff =>
      'Impossibile disattivare il rinnovo automatico.';

  @override
  String get paymentErrorChangePlan => 'Impossibile cambiare piano.';

  @override
  String get paymentErrorUpdateCard => 'Impossibile aggiornare la carta.';

  @override
  String get paymentErrorSandboxFailed => 'Simulazione sandbox non riuscita.';

  @override
  String get paymentErrorUnreachable =>
      'Impossibile raggiungere il servizio locale. Verifica che l\'API sia in esecuzione.';

  @override
  String membershipQuotaLikesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Oggi restano $remaining Mi piace su $limit',
      one: 'Oggi restano $remaining Mi piace su 1',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Oggi restano $remaining messaggi su $limit',
      one: 'Oggi restano $remaining messaggi su 1',
    );
    return '$_temp0';
  }

  @override
  String membershipLikeLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Hai usato i tuoi $limit Mi piace di oggi con $plan',
      one: 'Hai usato il tuo Mi piace di oggi con $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipMessageLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Hai usato i tuoi $limit messaggi di oggi con $plan',
      one: 'Hai usato il tuo messaggio di oggi con $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaResetsAt(String time) {
    return 'Si azzera alle $time';
  }

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count match',
    );
    return '$_temp0';
  }

  @override
  String get matchesSubtitleConversations =>
      'Un po\' più vicini, un messaggio alla volta.';

  @override
  String get matchesSubtitlePeople =>
      'Persone che hai scelto. Possibilità da costruire insieme.';

  @override
  String get matchesSearchConversations => 'Cerca conversazioni';

  @override
  String get matchesSearchMatches => 'Cerca tra i tuoi match';

  @override
  String get matchesFilterAllConversations => 'Tutte le conversazioni';

  @override
  String matchesFilterUnread(int count) {
    return 'Da leggere · $count';
  }

  @override
  String get matchesLoading => 'Caricamento dei match…';

  @override
  String get matchesLoadErrorTitle => 'Impossibile caricare i match';

  @override
  String get matchesRetry => 'Riprova';

  @override
  String get matchesEmptyTitle => 'Ancora nessun match';

  @override
  String matchesTrustFilteredHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'I filtri di fiducia hanno nascosto $count match. Prova ad allentarli da Scopri.',
      one:
          'I filtri di fiducia hanno nascosto 1 match. Prova ad allentarli da Scopri.',
    );
    return '$_temp0';
  }

  @override
  String get matchesEmptyBody =>
      'Vai su Oggi per scoprire qualcuno che vorresti conoscere.';

  @override
  String get matchesNoConversationResults =>
      'Ancora nessuna conversazione qui. Prova un\'altra ricerca o un altro filtro.';

  @override
  String get matchesNoPeopleResults =>
      'Nessun match trovato. Prova con un altro nome.';

  @override
  String get matchesTabPeople => 'I tuoi match';

  @override
  String get matchesTabConversations => 'Conversazioni';

  @override
  String get matchesActionStartCall => 'Avvia una chiamata';

  @override
  String get matchesActionStartActivity => 'Inizia un\'attività';

  @override
  String get matchesActionPlanDate => 'Organizza un appuntamento';

  @override
  String get matchesActionPlanDateSubtitle =>
      'Scegli un orario e cosa vuoi condividere';

  @override
  String matchesPlanSent(String name) {
    return 'Proposta inviata a $name.';
  }

  @override
  String get matchesActionGraduate => 'Ci siamo trovati';

  @override
  String get matchesActionGraduateSubtitle =>
      'Lasciate Connect insieme; la chat resta';

  @override
  String matchesGraduationAsked(String name) {
    return 'Hai chiesto a $name di uscire insieme. Può confermare dalla vostra chat.';
  }

  @override
  String get matchesActionNudge => 'Invia un colpetto';

  @override
  String matchesNudgeSent(String name) {
    return 'Colpetto inviato a $name.';
  }

  @override
  String get matchesNudgeFailed => 'Impossibile inviare il colpetto.';

  @override
  String get matchesActionClose => 'Chiudi la conversazione';

  @override
  String get matchesActionCloseSubtitle =>
      'Prenditi spazio, senza spiegazioni.';

  @override
  String get matchesCloseDialogTitle => 'Chiudere questa conversazione?';

  @override
  String get matchesCloseDialogBody =>
      'Va bene se questa connessione non fa per te. Il match terminerà. Non devi inviare spiegazioni. La segnalazione resta una scelta separata.';

  @override
  String get matchesCloseDialogKeep => 'Continua a parlare';

  @override
  String get matchesActionReport => 'Segnala';

  @override
  String get matchesReportSubmitted => 'Segnalazione inviata. Grazie.';

  @override
  String get matchesReportAppeal => 'Ricorso';

  @override
  String matchesAppealReason(String userId) {
    return 'Rivedere l\'esito della moderazione per la segnalazione sull\'utente $userId';
  }

  @override
  String get matchesBothChose => 'Avete scelto entrambi di conoscervi';

  @override
  String matchesOptionsTooltip(String name) {
    return 'Opzioni del match con $name';
  }

  @override
  String matchesChatUnread(int count) {
    return 'Chat · $count da leggere';
  }

  @override
  String get matchesOpenChat => 'Apri chat';

  @override
  String get matchesFirstChapter => 'Primo Capitolo';

  @override
  String get matchesUnknownName => 'Sconosciuto';

  @override
  String get matchesSayHi => 'Saluta 👋';

  @override
  String get matchesFallbackName => 'Il tuo match';

  @override
  String get matchesFallbackMessage => 'Inizia la conversazione';

  @override
  String get matchesGiftPreview =>
      'Un piccolo regalo nella vostra conversazione';

  @override
  String matchesConversationOptionsTooltip(String name) {
    return 'Opzioni della conversazione con $name';
  }

  @override
  String get matchesTimeNow => 'Ora';

  @override
  String matchesTimeMinutesAgo(int minutes) {
    return '$minutes min fa';
  }

  @override
  String matchesTimeHoursAgo(int hours) {
    return '$hours h fa';
  }

  @override
  String get matchesTimeToday => 'Oggi';

  @override
  String get matchesTimeYesterday => 'Ieri';

  @override
  String get matchesNewMatchTitle => 'Nuovo match';

  @override
  String get matchesItsAMatch => 'È un match!';

  @override
  String matchesLikedEachOther(String name) {
    return 'Tu e $name vi siete piaciuti a vicenda';
  }

  @override
  String get matchesSendMessage => 'Invia messaggio';

  @override
  String get matchesKeepSwiping => 'Continua a scorrere';

  @override
  String get matchesErrorLoginRequired => 'Accedi per vedere i tuoi match.';

  @override
  String get matchesErrorLoadFailed => 'Impossibile caricare i match. Riprova.';

  @override
  String get matchesErrorUnmatchFailed => 'Impossibile annullare il match.';

  @override
  String get matchesErrorMarkReadFailed => 'Impossibile segnare come letto.';

  @override
  String get matchesErrorSessionUnavailable =>
      'Sessione utente non disponibile.';

  @override
  String get matchesTrustBadgePromptCompleter => 'Prompt completati';

  @override
  String get matchesTrustBadgeRespectful => 'Comunicazione rispettosa';

  @override
  String get matchesTrustBadgeConsistent => 'Profilo coerente';

  @override
  String get matchesTrustBadgeVerifiedActive => 'Verificato e attivo';

  @override
  String get matchesTrustErrorLoad =>
      'Impossibile caricare i filtri di fiducia. Riprova.';

  @override
  String get matchesTrustErrorSave =>
      'Impossibile salvare i filtri di fiducia. Riprova.';

  @override
  String get matchesGestureErrorLoad => 'Impossibile caricare la cronologia';

  @override
  String get matchesGestureErrorPending =>
      'I gesti si sbloccano quando questa conversazione in sospeso diventa un vero match.';

  @override
  String get matchesGestureErrorSend => 'Impossibile inviare il gesto.';

  @override
  String get matchesGestureErrorUpdate =>
      'Impossibile aggiornare lo stato del gesto.';

  @override
  String get matchesActivityTitle => 'Questo o quello in 2 minuti';

  @override
  String get matchesActivityRestartTooltip => 'Inizia una nuova sessione';

  @override
  String matchesActivityCompleteWith(String name) {
    return 'Completalo con $name';
  }

  @override
  String get matchesActivityInstructions =>
      'Rispondi a tutti gli 8 round prima che scada il tempo.';

  @override
  String matchesActivityStatus(String status) {
    return 'Stato: $status';
  }

  @override
  String get matchesActivityStatusActive => 'attiva';

  @override
  String get matchesActivityStatusTimedOut => 'tempo scaduto';

  @override
  String get matchesActivityStatusPartialTimeout => 'parzialmente scaduta';

  @override
  String get matchesActivityStatusCompleted => 'completata';

  @override
  String get matchesActivitySubmit => 'Invia risposte';

  @override
  String get matchesActivityTimeUpLoad => 'Tempo scaduto — Carica il riepilogo';

  @override
  String get matchesActivityWaiting =>
      'Risposte inviate. In attesa che l\'altra persona finisca.';

  @override
  String get matchesActivityRefreshSummary => 'Aggiorna riepilogo';

  @override
  String matchesActivityTimeLeft(String time) {
    return 'Tempo rimasto $time';
  }

  @override
  String get matchesActivitySummaryTitle => 'Riepilogo dell\'attività';

  @override
  String matchesActivityParticipantsCompleted(int completed, int total) {
    return 'Partecipanti che hanno finito: $completed/$total';
  }

  @override
  String get matchesActivitySummaryPending =>
      'Il riepilogo apparirà appena disponibile.';

  @override
  String get matchesActivityShareResult => 'Condividi il risultato in chat';

  @override
  String matchesActivityShareMessage(String status, int completed, int total) {
    return 'Risultato di Questo o quello (2 min): $status • $completed/$total completato';
  }

  @override
  String matchesActivityShareMessageWithInsight(
    String status,
    int completed,
    int total,
    String insight,
  ) {
    return 'Risultato di Questo o quello (2 min): $status • $completed/$total completato • $insight';
  }

  @override
  String matchesActivityRound(int number) {
    return 'Round $number';
  }

  @override
  String get matchesActivityErrorStart =>
      'Impossibile avviare l\'attività ora. Riprova.';

  @override
  String get matchesActivityErrorNotReady => 'La sessione non è ancora pronta.';

  @override
  String get matchesActivityErrorAnswerAll =>
      'Rispondi a tutte le domande prima di inviare.';

  @override
  String get matchesActivityErrorTimeUp =>
      'Tempo scaduto. Caricamento del riepilogo…';

  @override
  String get matchesActivityErrorSubmit =>
      'Impossibile inviare le risposte. Riprova.';

  @override
  String get matchesActivityErrorSummary =>
      'Impossibile recuperare il riepilogo per ora. Riprova.';

  @override
  String get matchesActivityQ1Prompt => 'Primo incontro ideale?';

  @override
  String get matchesActivityQ1OptionA => 'Passeggiata con caffè';

  @override
  String get matchesActivityQ1OptionB => 'Giro in libreria';

  @override
  String get matchesActivityQ2Prompt => 'Mood del weekend preferito?';

  @override
  String get matchesActivityQ2OptionA => 'Restare a casa e ricaricarsi';

  @override
  String get matchesActivityQ2OptionB => 'Esplorare la città';

  @override
  String get matchesActivityQ3Prompt => 'Il posto migliore per parlare?';

  @override
  String get matchesActivityQ3OptionA => 'Lunga passeggiata';

  @override
  String get matchesActivityQ3OptionB => 'Angolo accogliente di un caffè';

  @override
  String get matchesActivityQ4Prompt => 'Come organizzi gli appuntamenti?';

  @override
  String get matchesActivityQ4OptionA => 'In modo spontaneo';

  @override
  String get matchesActivityQ4OptionB => 'In anticipo';

  @override
  String get matchesActivityQ5Prompt => 'Cosa conta di più per te adesso?';

  @override
  String get matchesActivityQ5OptionA => 'Costanza';

  @override
  String get matchesActivityQ5OptionB => 'Emozione';

  @override
  String get matchesActivityQ6Prompt => 'Come preferisci gestire i conflitti?';

  @override
  String get matchesActivityQ6OptionA => 'Risolvere in giornata';

  @override
  String get matchesActivityQ6OptionB => 'Prendersi spazio e poi riparlarne';

  @override
  String get matchesActivityQ7Prompt => 'Attività da fare insieme?';

  @override
  String get matchesActivityQ7OptionA => 'Cucinare insieme';

  @override
  String get matchesActivityQ7OptionB => 'Allenarsi insieme';

  @override
  String get matchesActivityQ8Prompt => 'Che ritmo preferisci?';

  @override
  String get matchesActivityQ8OptionA => 'Calmo e consapevole';

  @override
  String get matchesActivityQ8OptionB => 'Veloce ed energico';

  @override
  String get cityPilotSaveFailed =>
      'Non siamo riusciti a confermare la modifica. Aggiorna per controllare prima di riprovare.';

  @override
  String get cityPilotLeaveTitle => 'Lasciare il progetto pilota della città?';

  @override
  String get cityPilotLeaveBody =>
      'Le tue prenotazioni del progetto pilota verranno annullate e i tuoi feedback sulle esperienze rimossi. La tua attività smetterà di contribuire ai risultati attuali. I tuoi match e le conversazioni restano. Non potrai rientrare in questo progetto pilota.';

  @override
  String get cityPilotStay => 'Resta nel progetto';

  @override
  String get cityPilotLeave => 'Lascia il progetto';

  @override
  String get cityPilotLeftNotice =>
      'Hai lasciato il progetto pilota. I tuoi match restano con te.';

  @override
  String cityPilotJoinEventTitle(String title) {
    return 'Partecipare a $title?';
  }

  @override
  String cityPilotBookingTerms(
    String host,
    String safetyContact,
    String accessibility,
  ) {
    return 'Questa esperienza è gratuita. L’incontro è in un luogo pubblico: rispetta i limiti degli altri e organizza il tuo viaggio. Puoi andartene in qualsiasi momento.\n\nHost: $host\nContatto per la sicurezza: $safetyContact\n\nAccessibilità: $accessibility\n\nIn caso di pericolo immediato, contatta i servizi di emergenza locali.';
  }

  @override
  String get cityPilotAcceptReserve => 'Accetta e prenota un posto';

  @override
  String get cityPilotReservedNotice =>
      'Il tuo posto è prenotato. Puoi annullare qui in qualsiasi momento.';

  @override
  String get cityPilotFeedbackTitle => 'Com’è andata l’esperienza?';

  @override
  String get cityPilotFeedbackIntro =>
      'Facoltativo. Le risposte contribuiscono ai risultati aggregati del progetto pilota. Non vengono mostrate agli altri membri né all’host.';

  @override
  String get cityPilotDidYouAttend => 'Hai partecipato?';

  @override
  String get cityPilotAttendedYes => 'Sì, c’ero';

  @override
  String get cityPilotAttendedNo => 'Non ce l’ho fatta';

  @override
  String get cityPilotWorthwhileQuestion => 'Ne è valsa la pena? (facoltativo)';

  @override
  String get cityPilotNotThisTime => 'Non questa volta';

  @override
  String get cityPilotSkip => 'Salta';

  @override
  String get cityPilotShareFeedback => 'Invia feedback';

  @override
  String get cityPilotFeedbackThanks =>
      'Grazie. Il tuo feedback è stato registrato in modo riservato.';

  @override
  String get cityPilotTimeTbc => 'Orario da confermare';

  @override
  String get cityPilotTitle => 'Il progetto pilota in città';

  @override
  String get cityPilotRefreshTooltip => 'Aggiorna il progetto pilota';

  @override
  String get cityPilotHeroTitle => 'Un po’ più vicini.\nMolto più veri.';

  @override
  String get cityPilotHeroBody =>
      'Una città. Una piccola community. Più possibilità che una conversazione diventi un programma.';

  @override
  String get cityPilotStep1Title => 'Inizia con una conversazione';

  @override
  String get cityPilotStep1Body =>
      'Conosci persone con i tuoi tempi attraverso le presentazioni che hai già.';

  @override
  String get cityPilotStep2Title => 'Fai spazio a un vero appuntamento';

  @override
  String get cityPilotStep2Body =>
      'Costruite un piano insieme. Racconta com’è andata solo se vuoi.';

  @override
  String get cityPilotStep3Title => 'Provate qualcosa insieme';

  @override
  String get cityPilotStep3Body =>
      'Piccole esperienze guidate arriveranno dopo la prima revisione del progetto pilota.';

  @override
  String get cityPilotSaving => 'Salvataggio della preferenza';

  @override
  String get cityPilotUnavailableTitle =>
      'Il tuo progetto pilota non è disponibile';

  @override
  String get cityPilotUnavailableBody =>
      'Controlla la connessione e aggiorna per vedere la tua partecipazione e le prenotazioni aggiornate.';

  @override
  String get cityPilotComingSoonTitle => 'Presto in una città vicino a te';

  @override
  String get cityPilotComingSoonBody =>
      'Non c’è ancora un progetto pilota aperto per la città del tuo profilo. Quando ne aprirà uno, potrai scegliere se partecipare. La tua esperienza di incontri attuale continua come sempre.';

  @override
  String cityPilotPanelTitleJoined(String city) {
    return '$city · Ne fai parte';
  }

  @override
  String cityPilotPanelTitleOpen(String city) {
    return '$city · Progetto pilota';
  }

  @override
  String cityPilotRecruitmentCloses(String date) {
    return 'Chiusura iscrizioni: $date (ora locale).';
  }

  @override
  String get cityPilotPaused =>
      'Nuove adesioni e prenotazioni sono in pausa. Puoi comunque uscire o annullare.';

  @override
  String get cityPilotCompleted =>
      'Questo progetto pilota è concluso. Grazie per averne fatto parte.';

  @override
  String get cityPilotMeasurement =>
      'Partecipando ci permetti di contare conversazioni, piani accettati e risposte facoltative a «l’appuntamento c’è stato?» per i nuovi match in cui entrambe le persone hanno aderito a questo progetto pilota. Usiamo finestre di 7 giorni per le conversazioni e di 28 giorni per gli appuntamenti. Per il progetto pilota non leggiamo il testo dei messaggi né le note private di feedback.';

  @override
  String get cityPilotPrivacy =>
      'La partecipazione resta privata. Non ci sono elenchi pubblici dei presenti né punteggi. Uscire esclude la tua attività dai risultati attuali e annulla le prenotazioni. I risultati aggregati già esaminati non possono essere annullati.';

  @override
  String get cityPilotConsent =>
      'Accetto di partecipare a questo progetto pilota e alla misurazione dei risultati.';

  @override
  String get cityPilotJoinedNotice =>
      'Ci sei. Continua a conoscere persone con i tuoi tempi.';

  @override
  String get cityPilotJoin => 'Partecipa al progetto pilota';

  @override
  String get cityPilotWithdrawn =>
      'Hai lasciato questo progetto pilota. I tuoi match e le conversazioni restano invariati.';

  @override
  String get cityPilotNotAccepting =>
      'Questo progetto pilota al momento non accetta nuovi membri.';

  @override
  String get cityPilotExperiencesHeading =>
      'Piccoli piani. Esperienze condivise.';

  @override
  String get cityPilotNoExperiences =>
      'Le esperienze guidate non sono ancora aperte. Appariranno qui dopo una verifica dei risultati e della sicurezza.';

  @override
  String cityPilotEventDetails(
    String start,
    String end,
    String venue,
    String host,
  ) {
    return '$start → $end\nOra locale · Gratis\n$venue\nOrganizzato da $host';
  }

  @override
  String cityPilotAccessibility(String details) {
    return 'Accessibilità · $details';
  }

  @override
  String cityPilotSafetyContact(String contact) {
    return 'Contatto per la sicurezza · $contact';
  }

  @override
  String get cityPilotEventCancelled =>
      'Questa esperienza è stata annullata. Non recarti sul posto.';

  @override
  String get cityPilotPlaceReserved => 'Il tuo posto è prenotato.';

  @override
  String get cityPilotBookingCancelled => 'La tua prenotazione è annullata.';

  @override
  String get cityPilotCancelPlace => 'Annulla il mio posto';

  @override
  String get cityPilotReserveFree => 'Prenota un posto gratuito';

  @override
  String get cityPilotShareOptionalFeedback => 'Lascia un feedback facoltativo';

  @override
  String get cityPilotFeedbackReceived =>
      'Abbiamo ricevuto il tuo feedback. Grazie.';

  @override
  String get blogAudiencePrivate => 'Solo io';

  @override
  String get blogAudienceFriends => 'Amici';

  @override
  String get blogAudienceCommunity => 'Community Connect';

  @override
  String get blogInvitationNone => 'Nessun invito';

  @override
  String get blogInvitationYourVersion => 'Come sarebbe la tua versione?';

  @override
  String get blogInvitationTeachMe => 'Cosa potresti insegnarmi su questo?';

  @override
  String get blogInvitationWhatNext => 'Cosa proveresti dopo?';

  @override
  String get blogRewardStoryPublishedTitle => 'Condividere un capitolo';

  @override
  String get blogRewardStoryPublishedWho =>
      'Tu, la prima volta che un capitolo viene condiviso oltre «Solo io»';

  @override
  String get blogRewardPhotoSharedTitle =>
      'Condividere una foto nei Temi fotografici';

  @override
  String get blogRewardPhotoSharedWho =>
      'Tu, per una foto che condividi nei Temi fotografici';

  @override
  String get blogRewardLikeReceivedTitle =>
      'Un mi piace al tuo capitolo o alla tua foto';

  @override
  String get blogRewardLikeReceivedWho => 'Tu, per ogni membro a cui piace';

  @override
  String get blogRewardCommentReceivedTitle => 'Un commento che approvi';

  @override
  String get blogRewardCommentReceivedWho =>
      'Tu, quando approvi il commento di un lettore';

  @override
  String get blogRewardCommentApprovedTitle =>
      'Il tuo commento viene approvato';

  @override
  String get blogRewardCommentApprovedWho =>
      'Tu, quando un autore approva il tuo commento';

  @override
  String get blogRewardSubscriberGainedTitle => 'Un nuovo follower';

  @override
  String get blogRewardSubscriberGainedWho =>
      'Tu, per ogni nuovo membro che segue i tuoi capitoli';

  @override
  String get blogRewardWallTierTitle => 'Arrivare su più bacheche';

  @override
  String get blogRewardWallTierWho =>
      'Tu, ogni volta che un capitolo raggiunge un nuovo livello di bacheche';

  @override
  String get blogRewardCoverOfWeekTitle => 'Copertina della settimana';

  @override
  String get blogRewardCoverOfWeekWho =>
      'Tu, quando il tuo lavoro viene scelto come Copertina della settimana';

  @override
  String get blogScopeForYou => 'Per te';

  @override
  String get blogScopeTopRated => 'Più apprezzati';

  @override
  String get blogScopeFollowing => 'Seguiti';

  @override
  String get blogScopeMine => 'Miei';

  @override
  String get blogScopeCaptionMine =>
      'Le tue bozze e i capitoli pubblicati. Scegli tu il pubblico di ciascuno.';

  @override
  String get blogScopeCaptionFriends =>
      'Capitoli condivisi dai tuoi amici su Connect.';

  @override
  String get blogScopeCaptionTop =>
      'Classificati per mi piace, commenti approvati e lettori degli ultimi 30 giorni.';

  @override
  String get blogScopeCaptionFollowing =>
      'I capitoli più recenti degli autori che segui.';

  @override
  String get blogScopeCaptionCommunity =>
      'Per i membri Connect idonei che hanno effettuato l\'accesso. Questi capitoli non sono pubblici sul web.';

  @override
  String get blogTitle => 'Capitoli aperti';

  @override
  String get blogRewardsTitle => 'Come funzionano i premi';

  @override
  String get blogWritersTitle => 'Autori che segui';

  @override
  String get blogConnectionsTooltip =>
      'Risposte private, condivisioni e avvisi';

  @override
  String get blogSignInReadWrite => 'Accedi per leggere e scrivere capitoli.';

  @override
  String get blogHeroTitle => 'Una vita che vale\nla pena conoscere.';

  @override
  String get blogHeroBody =>
      'La storia dietro una foto. Una piccola ossessione. Qualcosa che stai ancora imparando. Lascia parlare la tua vita di tutti i giorni.';

  @override
  String get blogWriteChapter => 'Scrivi un capitolo';

  @override
  String get blogPrivateResponses => 'Risposte private';

  @override
  String get blogSharedLinks => 'Link condivisi';

  @override
  String get blogReviewNotices => 'Avvisi di revisione';

  @override
  String get blogTopicAll => 'Tutti';

  @override
  String get blogFeedLoadFailed => 'Impossibile caricare i capitoli.';

  @override
  String get blogPreviousPage => 'Pagina precedente';

  @override
  String get blogMoreChapters => 'Altri capitoli';

  @override
  String get blogEmptyMineTitle => 'Il tuo prossimo capitolo inizia qui.';

  @override
  String get blogEmptyMineBody =>
      'Inizia da un momento di cui ti piacerebbe che qualcuno ti chiedesse. La tua prima bozza è solo per te.';

  @override
  String get blogEmptyTopTitle => 'Quando i capitoli emozionano, salgono qui.';

  @override
  String get blogEmptyTopFilteredBody =>
      'In questo argomento non è ancora salito nulla. Prova «Tutti» o condividi un tuo capitolo.';

  @override
  String get blogEmptyTopBody =>
      'Qui compariranno i capitoli più amati dai lettori negli ultimi 30 giorni.';

  @override
  String get blogEmptyFollowingFilteredTitle =>
      'Ancora niente di nuovo in questo argomento.';

  @override
  String get blogEmptyFollowingTitle =>
      'Qui compariranno gli autori che segui.';

  @override
  String get blogEmptyFollowingBody =>
      'Quando un capitolo ti colpisce, aprilo e tocca «Segui i suoi capitoli». I nuovi capitoli si raccoglieranno qui, così non ti perderai nulla.';

  @override
  String get blogEmptyCommunityTitle => 'Per ora qui è un po\' tranquillo.';

  @override
  String get blogEmptyCommunityBody =>
      'I capitoli compaiono qui quando i membri scelgono di condividerli con questo pubblico.';

  @override
  String get blogFindWritersTopRated => 'Trova autori in «Più apprezzati»';

  @override
  String blogRankTooltip(int rank) {
    return 'Numero $rank tra i più apprezzati';
  }

  @override
  String get blogUntitled => 'Un capitolo senza titolo';

  @override
  String get blogDraftPlaceholder =>
      'Una bozza privata che aspetta le tue parole.';

  @override
  String get blogReadEdit => 'Leggi e modifica →';

  @override
  String get blogReadChapter => 'Leggi il capitolo →';

  @override
  String get blogPhotoUnavailableRetry => 'Foto non disponibile · Riprova';

  @override
  String get blogTryAgain => 'Riprova';

  @override
  String get blogDetailTitle => 'Un capitolo';

  @override
  String get blogSignInRead => 'Accedi per leggere i capitoli.';

  @override
  String get blogDetailUnavailable =>
      'Questo capitolo non è disponibile o il suo pubblico è cambiato.';

  @override
  String get blogRespondPrivately => 'Rispondi in privato';

  @override
  String get blogCreatePublicPreview => 'Crea un\'anteprima pubblica';

  @override
  String get blogRemovedByModerationNote =>
      'Rimosso dalla moderazione. Apri «Avvisi di revisione» per leggere la decisione o chiedere un\'altra revisione.';

  @override
  String get blogEditChapter => 'Modifica capitolo';

  @override
  String get blogDeleteChapter => 'Elimina capitolo';

  @override
  String get blogDeleteChapterTitle => 'Eliminare questo capitolo?';

  @override
  String get blogDeleteChapterMessage =>
      'Sparirà per tutti. L\'azione non può essere annullata.';

  @override
  String get blogDeleteChapterFailed =>
      'Impossibile confermare l\'eliminazione. Ricarica il capitolo prima di riprovare.';

  @override
  String get blogReportChapter => 'Segnala capitolo';

  @override
  String get blogReportFailed => 'Impossibile inviare la segnalazione.';

  @override
  String get blogBlockThisMember => 'Blocca questo membro';

  @override
  String get blogBlockTitle => 'Bloccare questo membro?';

  @override
  String get blogBlockMessageChapter =>
      'Non vedrete più i capitoli l\'uno dell\'altro. Blocca anche il contatto tramite Connect.';

  @override
  String get blogBlockMember => 'Blocca membro';

  @override
  String get blogBlockRetryFailed =>
      'Impossibile bloccare questo membro. Riprova.';

  @override
  String get blogCancel => 'Annulla';

  @override
  String get blogEditorMissingFields =>
      'Aggiungi un titolo e una storia prima di pubblicare.';

  @override
  String blogPublishConfirmTitle(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Pubblicare per «Solo io»?',
      'friends': 'Pubblicare per gli amici?',
      'community': 'Pubblicare nella community Connect?',
      'other': 'Pubblicare?',
    });
    return '$_temp0';
  }

  @override
  String get blogPublishFriendsBody =>
      'I tuoi amici su Connect potranno leggere il testo e vedere le foto di questo capitolo. Puoi cambiare il pubblico in seguito.';

  @override
  String get blogPublishCommunityBody =>
      'I membri Connect idonei che hanno effettuato l\'accesso potranno leggere questo capitolo. Non comparirà sul web pubblico. Puoi cambiare il pubblico in seguito.';

  @override
  String get blogPublishChapter => 'Pubblica capitolo';

  @override
  String get blogSavedOnlyMe =>
      'Salvato. Solo tu puoi leggere questo capitolo.';

  @override
  String blogPublishedTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Pubblicato per «Solo io».',
      'friends': 'Pubblicato per gli amici.',
      'community': 'Pubblicato nella community Connect.',
      'other': 'Pubblicato.',
    });
    return '$_temp0';
  }

  @override
  String get blogSharedSnack =>
      'Condiviso. I mi piace e i commenti dei lettori ti fanno guadagnare XP.';

  @override
  String get blogSeeMyLevel => 'Vedi il mio livello';

  @override
  String get blogSaveUnconfirmed =>
      'Non siamo riusciti a confermare il salvataggio.';

  @override
  String blogEditsStillHere(String message) {
    return '$message Le tue modifiche sono ancora qui. Controlla la versione salvata prima di continuare.';
  }

  @override
  String blogSavedVersionTitle(String audience) {
    return 'Versione salvata · $audience';
  }

  @override
  String get blogSavedVersionNote =>
      'Le modifiche attuali restano nell\'editor. Chiudi questo pannello per mantenerle o sostituiscile con questa versione salvata.';

  @override
  String get blogKeepMyEdits =>
      'Mantieni le mie modifiche per il prossimo salvataggio';

  @override
  String get blogUseSavedVersion => 'Usa la versione salvata';

  @override
  String get blogSavedVersionLoadFailed =>
      'Impossibile caricare la versione salvata. Le tue modifiche restano qui.';

  @override
  String get blogDescribePhotoTitle => 'Descrivi la tua foto';

  @override
  String get blogDescribePhotoBody =>
      'Una breve descrizione rende il tuo capitolo accessibile. Aggiungendo la foto, il testo viene salvato come bozza «Solo io».';

  @override
  String get blogDescribePhotoLabel => 'Cosa c\'è in questa foto?';

  @override
  String get blogAddToPrivateDraft => 'Aggiungi alla bozza privata';

  @override
  String get blogPhotoAdded => 'Foto aggiunta alla tua bozza privata.';

  @override
  String get blogPhotoAddFailed =>
      'Impossibile aggiungere la foto. Usa un JPEG o PNG fino a 10 MB.';

  @override
  String blogCheckSavedBeforeRetrying(String message) {
    return '$message Controlla la versione salvata prima di riprovare.';
  }

  @override
  String get blogRemoveUnconfirmed =>
      'Impossibile confermare la rimozione. Controlla la versione salvata.';

  @override
  String get blogSignInAsAuthor =>
      'Accedi come autore per modificare questo capitolo.';

  @override
  String get blogLeaveEditorTitle => 'Uscire senza salvare?';

  @override
  String get blogLeaveEditorMessage =>
      'Le modifiche non salvate andranno perse. L\'ultimo capitolo salvato resterà.';

  @override
  String get blogLeaveEditor => 'Esci dall\'editor';

  @override
  String get blogEditorPreviewTitle => 'Anteprima del capitolo';

  @override
  String get blogEditorTitle => 'Il tuo prossimo capitolo';

  @override
  String get blogEditorHeadline => 'Un po\' più te.';

  @override
  String get blogEditorIntro =>
      'Le piccole storie sono benvenute. Un piatto che hai cucinato. Un posto che ti ha fatto cambiare idea. La foto con una storia dietro.';

  @override
  String get blogNotSavedDefault =>
      'Non salvato · «Solo io» per impostazione predefinita';

  @override
  String blogSavedFor(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Salvato per «Solo io»',
      'friends': 'Salvato per gli amici',
      'community': 'Salvato per la community Connect',
      'other': 'Salvato',
    });
    return '$_temp0';
  }

  @override
  String get blogKeepWriting => 'Continua a scrivere';

  @override
  String get blogPreview => 'Anteprima';

  @override
  String get blogCheckSavedVersion => 'Controlla la versione salvata';

  @override
  String blogPreviewNotSaved(String audience) {
    return 'Anteprima · $audience · Non ancora salvato';
  }

  @override
  String get blogStoryPlaceholder => 'Qui comparirà la tua storia.';

  @override
  String get blogChapterTitleLabel => 'Titolo del capitolo';

  @override
  String get blogChapterTitleHint =>
      'La domenica in cui ho imparato a rallentare';

  @override
  String get blogStoryLabel => 'La tua storia';

  @override
  String get blogStoryHint => 'Inizia da dove vuoi. Rendila tua.';

  @override
  String get blogInvitationLabel => 'Termina con un invito (facoltativo)';

  @override
  String get blogInvitationHelp =>
      'Lascia una domanda che aiuti qualcuno a conoscerti.';

  @override
  String get blogRemovePhoto => 'Rimuovi foto';

  @override
  String get blogAddPhoto => 'Aggiungi una foto';

  @override
  String get blogPhotoRules =>
      'Fino a 6 foto JPEG o PNG da 10 MB ciascuna. Le foto devono essere approvate. Salva come «Solo io» prima di cambiare le foto di un capitolo pubblicato.';

  @override
  String get blogWhoFor => 'Per chi è questo capitolo?';

  @override
  String get blogAudiencePrivateHelp =>
      'Solo tu puoi leggere questo capitolo. Amici e match non lo vedono.';

  @override
  String get blogAudienceFriendsHelp =>
      'Solo i tuoi amici su Connect possono leggerlo. Un match da solo non dà accesso.';

  @override
  String get blogAudienceCommunityHelp =>
      'Possono leggerlo i membri idonei che hanno effettuato l\'accesso. Completa il profilo con due foto profilo approvate per pubblicare qui. Non è una condivisione pubblica sul web.';

  @override
  String get blogAllowFeaturing => 'Consenti la messa in evidenza';

  @override
  String get blogAllowFeaturingHelp =>
      'Se piace ai lettori, il tuo capitolo può arrivare sulle bacheche di altri membri: 50 like e 5 commenti lo portano su 50 bacheche, 100 like e 10 commenti su 100. Puoi disattivarlo quando vuoi.';

  @override
  String get blogSaveOnlyForMe => 'Salva solo per me';

  @override
  String blogPublishTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Pubblica per «Solo io»',
      'friends': 'Pubblica per gli amici',
      'community': 'Pubblica nella community Connect',
      'other': 'Pubblica',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveAsOnlyMe => 'Salva come «Solo io»';

  @override
  String get blogSaveNote =>
      'Le tue parole vengono salvate quando scegli Salva o Pubblica. L\'anteprima non pubblica nulla.';

  @override
  String get blogTopicOptional => 'Argomento (facoltativo)';

  @override
  String get blogTopicHelp =>
      'Aiuta i lettori interessati a trovare il tuo capitolo.';

  @override
  String get webDestBlog => 'Blog';

  @override
  String get webDestFirstChapter => 'Studio Primo capitolo';

  @override
  String get webDestDatingPreferences => 'Preferenze di incontro';

  @override
  String get webDestEditProfile => 'Modifica profilo';

  @override
  String get webDestProfilePhotos => 'Foto del profilo';

  @override
  String get webDestLikedYou => 'Ti hanno messo like';

  @override
  String get webDestNotifications => 'Notifiche';

  @override
  String get webDestDailyPrompt => 'Domanda del giorno';

  @override
  String get webDestLevels => 'Livelli e progressi';

  @override
  String get webDestTrustBadges => 'Badge di fiducia';

  @override
  String get webDestTrustFilters => 'Filtri di fiducia';

  @override
  String get webDestIcebreakers => 'Rompighiaccio';

  @override
  String get webDestCircleChallenges => 'Sfide della cerchia';

  @override
  String get webDestCoffeePolls => 'Sondaggi caffè';

  @override
  String get webDestGroups => 'Gruppi';

  @override
  String get webDestRooms => 'Stanze di conversazione';

  @override
  String get webDestMatchNudges => 'Stimoli ai match';

  @override
  String get webDestFriends => 'Amici';

  @override
  String get webDestDatePlans => 'Piani per appuntamenti';

  @override
  String get webDestCallHistory => 'Cronologia chiamate';

  @override
  String get webDestMembership => 'Abbonamento';

  @override
  String get webDestVerification => 'Verifica';

  @override
  String get webDestPrivacySafety => 'Privacy e sicurezza';

  @override
  String get webDestAccountData => 'Account e dati';

  @override
  String get webDestBlockedMembers => 'Membri bloccati';

  @override
  String get webDestEmergencyContacts => 'Contatti di emergenza';

  @override
  String get webDestModerationAppeals => 'Ricorsi di moderazione';

  @override
  String get webDestNotificationPreferences => 'Preferenze di notifica';

  @override
  String get webDestHelpSupport => 'Aiuto e supporto';

  @override
  String get webNavExplore => 'Esplora';

  @override
  String get webNavMyProfile => 'Il mio profilo';

  @override
  String get webNavAllFeatures => 'Tutte le funzioni';

  @override
  String get webNavMoreForYou => 'Altro per te';

  @override
  String get webNavPreferences => 'Preferenze';

  @override
  String get webNavWebsite => 'Sito di Connect';

  @override
  String get webNavSignOut => 'Esci';

  @override
  String get webPageNotFound => 'Pagina non trovata.';

  @override
  String get webBackToDiscover => 'Torna a Scopri';

  @override
  String get webTagline => 'I tuoi tempi. La tua scelta.';

  @override
  String webUnavailableTitle(String label) {
    return '$label non è ancora disponibile.';
  }

  @override
  String get webUnavailableBody =>
      'Non fa parte di questa versione di Connect.';

  @override
  String get webDirectoryTitle => 'Rendi tuo questo spazio.';

  @override
  String get webDirectorySubtitle =>
      'Il tuo profilo, le conversazioni, la community e i controlli: tutto in un unico posto.';

  @override
  String get webIcebreakerTitle => 'Spunti di conversazione';

  @override
  String get webIcebreakerHeadline =>
      'Un po’ di ispirazione per il tuo prossimo ciao.';

  @override
  String get webIcebreakerBody =>
      'La registrazione e la riproduzione vocale non sono ancora disponibili. Puoi usare questi spunti in una conversazione idonea.';

  @override
  String get webIcebreakerOpenMatches => 'Apri i miei match';

  @override
  String get webMembershipHeadline => 'Qualche possibilità in più.';

  @override
  String get webMembershipIntro =>
      'Scopri i piani attuali. Il pagamento nel browser non è ancora disponibile. Da questa pagina non è possibile acquistare né addebitare nulla.';

  @override
  String webMembershipCurrent(String plan) {
    return 'Il tuo abbonamento: $plan';
  }

  @override
  String webMembershipStatus(String status) {
    return 'Stato: $status';
  }

  @override
  String get webMembershipMonthly => 'Mensile';

  @override
  String get webMembershipYearly => 'Annuale';

  @override
  String get webMembershipFree => 'Gratis';

  @override
  String webMembershipPrice(String price, String cycle) {
    String _temp0 = intl.Intl.selectLogic(cycle, {
      'yearly': 'anno',
      'other': 'mese',
    });
    return '$price / $_temp0';
  }

  @override
  String get webMembershipFootnote =>
      'I prezzi del catalogo sono un’anteprima. L’abbonamento non scavalca mai i limiti di un’altra persona né i requisiti per conversare.';

  @override
  String get blogLinkCopied => 'Link copiato. Condividilo dove vuoi.';

  @override
  String get blogYourPublicLink => 'Il tuo link pubblico';

  @override
  String get blogShareUnconfirmed =>
      'Impossibile confermare la condivisione. Controlla «Link condivisi» prima di riprovare.';

  @override
  String get blogSignInAgain => 'Accedi di nuovo per continuare.';

  @override
  String get blogSharedJournalPage => 'Una pagina di diario condivisa';

  @override
  String get blogYourPublicPreview => 'La tua anteprima pubblica';

  @override
  String get blogShareJointHeadline =>
      'Una storia che entrambi scegliete di condividere.';

  @override
  String get blogShareSoloHeadline => 'Una piccola finestra sul tuo mondo.';

  @override
  String get blogShareJointBody =>
      'Entrambi gli autori devono approvare esattamente queste parole perché il link funzioni. Ognuno può ritirarlo.';

  @override
  String get blogShareSoloBody =>
      'Chiunque abbia il link può leggere il testo e vedere le foto selezionate, senza account. Il capitolo completo resta su Connect.';

  @override
  String get blogShareIdentityNote =>
      'Non vengono aggiunti profilo né nome dell\'account. Le tue parole e foto possono comunque identificare persone o luoghi. Pubblica solo ciò che hai il permesso di condividere.';

  @override
  String get blogExcerptLabel => 'Estratto esatto del tuo capitolo';

  @override
  String blogIncludePhoto(String description) {
    return 'Includi: $description';
  }

  @override
  String get blogApproveCopy => 'Approvo esattamente questa copia pubblica';

  @override
  String get blogApproveCopyNote =>
      'Modificare o nascondere il capitolo originale invalida il link. Le copie salvate fuori da Connect non possono essere recuperate.';

  @override
  String get blogSaving => 'Salvataggio…';

  @override
  String get blogRequestOtherApproval =>
      'Chiedi l\'approvazione dell\'altro autore';

  @override
  String get blogCreatePublicLink => 'Crea link pubblico';

  @override
  String get blogJointApprovalRecorded =>
      'La tua approvazione è registrata. Il link resta non disponibile finché l\'altro autore non approva.';

  @override
  String get blogPublicCopyReady => 'La tua copia pubblica è pronta.';

  @override
  String get blogCopyPublicLink => 'Copia link pubblico';

  @override
  String get blogManageSharedLinks => 'Gestisci link condivisi';

  @override
  String blogFollowerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count follower',
      one: '1 follower',
    );
    return '$_temp0';
  }

  @override
  String get blogUnfollowFailed =>
      'Non siamo riusciti a smettere di seguire ora. Riprova.';

  @override
  String get blogFollowFailed =>
      'Non siamo riusciti a seguire questo autore ora. Riprova.';

  @override
  String get blogFollowingButton => 'Segui già';

  @override
  String get blogFollowTheirChapters => 'Segui i suoi capitoli';

  @override
  String get blogRewardsIntro =>
      'Quando ciò che condividi colpisce qualcuno, conta. I mi piace, i commenti approvati e i nuovi follower ti fanno guadagnare XP per il tuo livello. I premi arrivano da ciò che fanno i lettori, mai dai semplici tocchi, e ognuno viene assegnato una sola volta.';

  @override
  String blogRewardDailyCap(int cap) {
    return 'Fino a $cap XP al giorno';
  }

  @override
  String blogRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String get blogSignInWriters => 'Accedi per vedere gli autori che segui.';

  @override
  String get blogWritersLoadFailed =>
      'Impossibile caricare gli autori che segui.';

  @override
  String get blogNoWriters => 'Ancora nessun autore.';

  @override
  String get blogNoWritersBody =>
      'Quando un capitolo ti colpisce, tocca «Segui i suoi capitoli». I nuovi capitoli si raccoglieranno in «Seguiti».';

  @override
  String blogLatest(String title) {
    return 'Ultimo: $title';
  }

  @override
  String get blogReactionFailed =>
      'La tua reazione non è stata inviata. Riprova.';

  @override
  String blogCannotLikeOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Non puoi mettere mi piace alla tua foto',
      'other': 'Non puoi mettere mi piace al tuo capitolo',
    });
    return '$_temp0';
  }

  @override
  String blogYouReacted(String reaction) {
    return 'Hai reagito: $reaction. Tocca per annullare';
  }

  @override
  String blogLikeThis(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Metti mi piace a questa foto',
      'other': 'Metti mi piace a questo capitolo',
    });
    return '$_temp0';
  }

  @override
  String blogCannotReactOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Non puoi reagire alla tua foto',
      'other': 'Non puoi reagire al tuo capitolo',
    });
    return '$_temp0';
  }

  @override
  String get blogReactTooltip =>
      'Reagisci: Ti ascolto, Anche io, Ti mando un abbraccio…';

  @override
  String blogCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commenti',
      one: '1 commento',
    );
    return '$_temp0';
  }

  @override
  String blogWaitingForYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '· $count ti aspettano',
      one: '· $count ti aspetta',
    );
    return '$_temp0';
  }

  @override
  String get blogFeatured => 'In evidenza';

  @override
  String blogTierNeedsBoth(int likes, int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes mi piace',
      one: '1 mi piace',
    );
    String _temp1 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments commenti',
      one: '1 commento',
    );
    String _temp2 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls bacheche',
      one: '1 bacheca',
    );
    return 'Ancora $_temp0 e $_temp1 per arrivare a $_temp2';
  }

  @override
  String blogTierNeedsLikes(int likes, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes mi piace',
      one: '1 mi piace',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls bacheche',
      one: '1 bacheca',
    );
    return 'Ancora $_temp0 per arrivare a $_temp1';
  }

  @override
  String blogTierNeedsComments(int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments commenti',
      one: '1 commento',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls bacheche',
      one: '1 bacheca',
    );
    return 'Ancora $_temp0 per arrivare a $_temp1';
  }

  @override
  String blogTierAlmostThere(int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: 'Ci sei quasi: la prossima tappa sono $walls bacheche',
      one: 'Ci sei quasi: la prossima tappa è 1 bacheca',
    );
    return '$_temp0';
  }

  @override
  String blogOnWalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Su $count bacheche',
      one: 'Su 1 bacheca',
    );
    return '$_temp0';
  }

  @override
  String blogProgressToward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Progresso verso $count bacheche',
      one: 'Progresso verso 1 bacheca',
    );
    return '$_temp0';
  }

  @override
  String get blogReachIdle =>
      'I lettori possono portare questo capitolo più lontano';

  @override
  String get blogReachLive =>
      'I membri che hanno amato storie come la tua lo stanno leggendo ora.';

  @override
  String get blogFeaturedStories => 'Storie in evidenza';

  @override
  String get blogFeaturedCaption =>
      'Storie amate da altri membri, recapitate sulla tua bacheca.';

  @override
  String blogByAuthor(String name) {
    return 'di $name';
  }

  @override
  String get blogLikes => 'Mi piace';

  @override
  String get blogComments => 'Commenti';

  @override
  String get blogCommentHint => 'Cosa ti è rimasto?';

  @override
  String get blogCommentApproved =>
      'Approvato. Ora lo vede chiunque possa leggere questo capitolo.';

  @override
  String get blogCommentSent => 'Inviato all\'autore per l\'approvazione';

  @override
  String get blogCommentSendFailed =>
      'Il tuo commento non è stato inviato. Le tue parole sono ancora qui, puoi riprovare.';

  @override
  String blogCommentDeclined(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Rifiutato. Non comparirà sulla tua foto.',
      'other': 'Rifiutato. Non comparirà sul tuo capitolo.',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveFailed => 'Non è stato salvato. Riprova.';

  @override
  String get blogDeleteCommentTitle => 'Eliminare questo commento?';

  @override
  String get blogDeleteCommentMessage =>
      'Verrà rimosso per tutti. L\'azione non può essere annullata.';

  @override
  String get blogDeleteComment => 'Elimina commento';

  @override
  String get blogCommentDeleted => 'Commento eliminato.';

  @override
  String get blogCommentDeleteFailed =>
      'Impossibile eliminare il commento. Riprova.';

  @override
  String get blogCommentsAuthorNote =>
      'I nuovi commenti attendono la tua approvazione prima che altri li vedano.';

  @override
  String get blogCommentsReaderNote =>
      'L\'autore legge prima ogni commento e sceglie cosa condividere.';

  @override
  String get blogLeaveComment => 'Lascia un commento';

  @override
  String get blogSendToAuthor => 'Invia all\'autore';

  @override
  String get blogCommentsLoadFailed => 'Impossibile caricare i commenti.';

  @override
  String get blogWaitingApproval => 'In attesa della tua approvazione';

  @override
  String get blogNoCommentsInvite =>
      'Ancora nessun commento. Scrivi qualcosa di gentile per iniziare la conversazione.';

  @override
  String get blogNoCommentsShared => 'Ancora nessun commento condiviso.';

  @override
  String get blogCommentNotShared =>
      'L\'autore ha scelto di non condividere questo.';

  @override
  String get blogYou => 'Tu';

  @override
  String get blogCommentOptions => 'Opzioni del commento';

  @override
  String get blogReportComment => 'Segnala commento';

  @override
  String get blogApprove => 'Approva';

  @override
  String get blogDecline => 'Rifiuta';

  @override
  String get blogSignInContinue => 'Accedi per continuare.';

  @override
  String get blogPrivateResponseTitle => 'Una risposta privata';

  @override
  String blogPrivateResponseHelp(String invitation) {
    return '$invitation\n\nSolo l\'autore riceve questa risposta. Può accettare o rifiutare uno scambio facoltativo. Fino a cinque nuove risposte al giorno, e una allo stesso autore.';
  }

  @override
  String get blogSendPrivateResponse => 'Invia risposta privata';

  @override
  String get blogTextSaveUnconfirmed =>
      'Impossibile confermare il salvataggio. Le tue parole sono ancora qui; riprova o ricarica lo scambio salvato.';

  @override
  String get blogLeaveUnsentTitle => 'Uscire senza inviare?';

  @override
  String get blogLeaveUnsentMessage => 'Le parole non inviate andranno perse.';

  @override
  String get blogLeave => 'Esci';

  @override
  String get blogOwnWordsLabel => 'Con parole tue';

  @override
  String get blogSending => 'Invio…';

  @override
  String get blogChangeUnconfirmed =>
      'Impossibile confermare la modifica. Aggiorna per controllare.';

  @override
  String get blogConnectionsTitle => 'Le tue connessioni dei Capitoli';

  @override
  String get blogRefresh => 'Aggiorna';

  @override
  String get blogConnectionsIntro =>
      'Le belle storie lasciano spazio a qualcun altro.';

  @override
  String get blogConnectionsLoadFailed =>
      'Impossibile caricare le tue connessioni.';

  @override
  String get blogResponsesEmpty =>
      'Qui compariranno le risposte ai tuoi capitoli e quelle che invii. Niente richiede una risposta immediata.';

  @override
  String get blogPublicationsEmpty =>
      'Qui compariranno le tue anteprime pubbliche e i link approvati insieme.';

  @override
  String get blogNoticesEmpty => 'Nessun avviso di revisione da mostrare.';

  @override
  String get blogResponseRevealed => 'Il vostro capitolo condiviso è pronto';

  @override
  String get blogResponseIncoming => 'Una risposta per te';

  @override
  String get blogResponseSent => 'Inviato · scelta sua, con i suoi tempi';

  @override
  String get blogResponseAccepted => 'Uno scambio, con i vostri tempi';

  @override
  String get blogResponseClosed => 'Questo scambio è chiuso';

  @override
  String get blogOpenExchange => 'Apri lo scambio privato';

  @override
  String get blogPublicationLive => 'Copia pubblica attiva';

  @override
  String get blogPublicationRemoved => 'Rimosso dalla moderazione';

  @override
  String get blogPublicationNeedsBoth =>
      'Richiede entrambe le approvazioni e un capitolo originale aggiornato';

  @override
  String get blogPublicationSourceChanged =>
      'Originale modificato · crea una nuova anteprima per condividere di nuovo';

  @override
  String get blogApprovePublicCopyTitle => 'Approvare questa copia pubblica?';

  @override
  String get blogApprovePublicCopyMessage =>
      'Le parole esatte qui sopra saranno visibili a chiunque abbia il link. Entrambi potete ritirare la condivisione. Non vengono aggiunti nomi automaticamente, ma le parole potrebbero identificarti.';

  @override
  String get blogApprovePublicCopyAction => 'Approva copia pubblica';

  @override
  String get blogApproveExactPublicCopy =>
      'Approva esattamente la copia pubblica';

  @override
  String get blogCopyLink => 'Copia link';

  @override
  String get blogWithdrawLinkTitle => 'Ritirare questo link?';

  @override
  String get blogWithdrawLinkMessage =>
      'La copia pubblica non sarà più disponibile. Le copie già salvate da altri non possono essere recuperate.';

  @override
  String get blogWithdrawLink => 'Ritira link';

  @override
  String get blogYourAppeal => 'Il tuo ricorso';

  @override
  String get blogRequestReview => 'Chiedi un\'altra revisione';

  @override
  String get blogRequestReviewHelp =>
      'Spiega cosa dovrebbe riconsiderare chi effettua la revisione. Il ricorso arriva in privato al team fiducia e sicurezza. Il contenuto rimosso resta nascosto durante la revisione.';

  @override
  String get blogSubmitAppeal => 'Invia ricorso';

  @override
  String get blogAppealDecision => 'Fai ricorso contro questa decisione';

  @override
  String get blogPrevious => 'Precedente';

  @override
  String get blogMore => 'Altro';

  @override
  String get blogExchangeChangeFailed =>
      'Impossibile confermare questa modifica. Aggiorna e riprova.';

  @override
  String get blogExchangeTitle => 'Uno scambio di Capitoli privato';

  @override
  String get blogExchangeUnavailable => 'Questo scambio non è più disponibile.';

  @override
  String blogExchangeWith(String name) {
    return 'Con $name';
  }

  @override
  String get blogExchangeIntro =>
      'Una risposta è un invito, mai un obbligo. Questo scambio non crea un match né sblocca la chat.';

  @override
  String get blogAcceptExchange => 'Accetta uno scambio';

  @override
  String get blogDeclineKindly => 'Rifiuta con gentilezza';

  @override
  String get blogResponseSentNote =>
      'La tua risposta è stata inviata. Nessun conto alla rovescia e nessun bisogno di insistere.';

  @override
  String get blogExchangeClosedNote =>
      'Questo scambio è chiuso. Fai spazio a un\'altra connessione con i tuoi tempi.';

  @override
  String get blogOneStoryEach => 'Una piccola storia a testa.';

  @override
  String get blogOneStoryEachBody =>
      'Aggiungi un piccolo seguito, un ricordo o la tua versione del momento. I due contributi compaiono insieme, solo dopo che entrambi li avete inviati.';

  @override
  String get blogYourSideTitle => 'La tua parte del capitolo';

  @override
  String get blogYourSideHelp =>
      'Condividi fino a 1000 caratteri. L\'altra persona non potrà leggerlo finché non contribuisce anche lei. Una volta inviato, il testo non si può modificare; puoi ritirare lo scambio in qualsiasi momento.';

  @override
  String get blogSubmitContribution => 'Invia il mio contributo';

  @override
  String get blogAddContribution => 'Aggiungi il mio contributo';

  @override
  String get blogYourContribution => 'Il tuo contributo';

  @override
  String blogPartnerContribution(String name) {
    return 'Contributo di $name';
  }

  @override
  String get blogShapeDate => 'Progettate insieme un appuntamento';

  @override
  String get blogInspiredNote => 'Ispirato dal nostro scambio di Capitoli.';

  @override
  String get blogTryStudio => 'Prova lo Studio Primo Capitolo';

  @override
  String get blogDatePlanningUnavailable =>
      'La pianificazione dell\'appuntamento diventa disponibile se avete un match attivo e la conversazione è sbloccata.';

  @override
  String get blogProposeJournalPage => 'Proponi una pagina di diario condivisa';

  @override
  String get blogSourceUnavailable =>
      'Il capitolo originale non è disponibile.';

  @override
  String get blogContributionSaved =>
      'Il tuo contributo è salvato in privato. Verrà svelato quando sarete pronti entrambi.';

  @override
  String get blogWithdrawExchangeTitle => 'Ritirare questo scambio?';

  @override
  String get blogWithdrawExchangeMessage =>
      'La risposta e i contributi non saranno più disponibili per nessuno dei due. Anche i link pubblici condivisi smetteranno di funzionare.';

  @override
  String get blogWithdrawExchange => 'Ritira scambio';

  @override
  String get blogReportExchange => 'Segnala scambio';

  @override
  String get blogBlockMessageExchange =>
      'Il contatto e l\'accesso ai capitoli dell\'altro termineranno.';

  @override
  String get blogBlockFailed => 'Impossibile bloccare questo membro.';

  @override
  String get notificationsReadAll => 'Segna tutte come lette';

  @override
  String get notificationsFallbackTitle => 'Notifica';

  @override
  String get notificationsLoadFailed => 'Impossibile caricare le notifiche.';

  @override
  String get notificationsPrefsUpdateFailed =>
      'Impossibile aggiornare le preferenze di notifica.';

  @override
  String notificationsAgoMinutes(int count) {
    return '$count min fa';
  }

  @override
  String notificationsAgoHours(int count) {
    return '$count h fa';
  }

  @override
  String notificationsAgoDays(int count) {
    return '$count g fa';
  }

  @override
  String get wallsReactEyebrow => 'REAGISCI';

  @override
  String wallsReactQuestion(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Cosa ti fa provare questa foto?',
      'other': 'Cosa ti fa provare questo capitolo?',
    });
    return '$_temp0';
  }

  @override
  String get wallsReactBody =>
      'La tua reazione fa sapere che sono stati ascoltati. Ogni reazione conta come un like.';

  @override
  String get wallsReactRemove => 'Ritira la mia reazione';

  @override
  String wallsReactionsSemantics(String list) {
    return 'Reazioni: $list';
  }

  @override
  String get wallsReactionLove => 'Lo adoro';

  @override
  String get wallsReactionHearYou => 'Ti ascolto';

  @override
  String get wallsReactionMeToo => 'Anch’io';

  @override
  String get wallsReactionWithYou => 'Sono con te';

  @override
  String get wallsReactionHug => 'Ti mando un abbraccio';

  @override
  String get wallsReactionProud => 'Fiero di te';

  @override
  String get wallsSignInRequired => 'Accedi per vedere la tua bacheca.';

  @override
  String get celebrationCoverHeadline =>
      'La tua foto è la copertina della settimana';

  @override
  String celebrationReachHeadline(String kind, int reach) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'photo': 'La tua foto ha raggiunto $reach bacheche',
      'other': 'Il tuo capitolo ha raggiunto $reach bacheche',
    });
    return '$_temp0';
  }

  @override
  String get celebrationCoverMessage =>
      'Ai membri è piaciuta molto. Questa settimana tutti la vedono in Oggi.';

  @override
  String get celebrationReachMessage =>
      'Ai membri è piaciuto molto. Ora è sulle loro bacheche di Oggi.';

  @override
  String celebrationQuotedTitle(String title) {
    return '«$title»';
  }

  @override
  String get celebrationBarrier => 'Festeggiamento';

  @override
  String get celebrationLovely => 'Che bello';

  @override
  String get celebrationSeePhoto => 'Vedi foto';

  @override
  String get celebrationSeeChapter => 'Vedi capitolo';

  @override
  String rewardXpPill(int xp) {
    return '+$xp XP';
  }

  @override
  String get rewardClaimedTitle => 'Ricompensa riscattata';

  @override
  String rewardNameDescription(String name, String description) {
    return '$name · $description';
  }

  @override
  String rewardPlusXpAnnouncement(int xp) {
    return 'più $xp XP';
  }

  @override
  String rewardSourceXpLine(String source, int xp) {
    return '$source +$xp XP';
  }

  @override
  String rewardAndMore(int count) {
    return 'e altri $count';
  }

  @override
  String rewardBadgeLine(String badge) {
    return 'Badge: $badge';
  }

  @override
  String rewardLevelReached(int level) {
    return 'Livello $level raggiunto';
  }

  @override
  String rewardBadgesEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count badge ottenuti',
      one: 'Badge ottenuto',
    );
    return '$_temp0';
  }

  @override
  String get rewardYourRewardsToday => 'Le tue ricompense di oggi';

  @override
  String rewardNewRewards(int count) {
    return '$count nuove ricompense';
  }

  @override
  String get rewardSourceStoryPublished => 'Capitolo pubblicato';

  @override
  String get rewardSourcePhotoShared => 'Foto condivisa';

  @override
  String get rewardSourceLikeReceived => 'A un membro è piaciuto il tuo lavoro';

  @override
  String get rewardSourceCommentReceived => 'Nuovo commento sul tuo lavoro';

  @override
  String get rewardSourceCommentApproved => 'Il tuo commento è stato approvato';

  @override
  String get rewardSourceSubscriberGained => 'Nuovo iscritto';

  @override
  String get rewardSourceWallTierReached => 'Livello bacheca raggiunto';

  @override
  String get rewardSourceCoverOfWeek => 'Copertina della settimana';

  @override
  String get rewardSourceDailyPromptSubmitted => 'Domanda del giorno risposta';

  @override
  String get rewardLineStoryPublished => 'Il tuo capitolo è nel mondo.';

  @override
  String get rewardLinePhotoShared => 'La tua foto si è unita al tema.';

  @override
  String get rewardLineLikeReceived =>
      'A qualcuno è piaciuto molto ciò che hai condiviso.';

  @override
  String get rewardLineCommentReceived =>
      'Un lettore si è unito alla conversazione.';

  @override
  String get rewardLineSubscriberGained =>
      'Qualcuno aspetta il tuo prossimo capitolo.';

  @override
  String get rewardLineWallTierReached =>
      'Il tuo lavoro ha raggiunto più bacheche.';

  @override
  String get rewardLineCoverOfWeek =>
      'Questa settimana tutti lo vedono in Oggi.';

  @override
  String get rewardLineOther => 'Ottenuto per un’attività significativa.';

  @override
  String get rewardNewBadgeFallback => 'Nuovo badge';

  @override
  String get blockedUnknownUser => 'Utente sconosciuto';

  @override
  String get themeTaglineBluerose =>
      'Velluto di mezzanotte, rose zaffiro e un bordo di platino.';

  @override
  String get themeTaglineBluelotus =>
      'Acqua al chiaro di luna, petali zaffiro e un cuore d’oro.';
}
