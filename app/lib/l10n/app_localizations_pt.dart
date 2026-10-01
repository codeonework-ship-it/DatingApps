// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get navDiscover => 'Descobrir';

  @override
  String get navMatches => 'Matches';

  @override
  String get navEngage => 'Participar';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navSettings => 'Definições';

  @override
  String get settingsTitle => 'Definições';

  @override
  String get settingsSectionProfile => 'Perfil';

  @override
  String get settingsEditProfileTitle => 'Editar perfil';

  @override
  String get settingsEditProfileSubtitle => 'Atualiza as tuas informações';

  @override
  String get settingsPhotosTitle => 'Fotos';

  @override
  String get settingsPhotosSubtitle => 'Gere as tuas fotos';

  @override
  String get settingsSectionPreferences => 'Preferências';

  @override
  String get settingsAppearanceTitle => 'Aparência';

  @override
  String get settingsAppearanceSubtitle => 'Guardado na tua conta';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsThemeMatchDevice => 'Como o dispositivo';

  @override
  String get settingsLooksTitle => 'Estilos';

  @override
  String get settingsLooksClassicDescription =>
      'Warm ivory and forest by day. Soft mint and deep forest by night.';

  @override
  String get settingsLooksClassicLabel => 'Today';

  @override
  String get settingsThemeSaveFailed =>
      'Não foi possível guardar o teu tema. Tenta outra vez.';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Escolhe o idioma da app';

  @override
  String get settingsDatingPreferencesTitle => 'Preferências de encontros';

  @override
  String get settingsDatingPreferencesSubtitle =>
      'Idade, localização, interesses';

  @override
  String get settingsAccountDataTitle => 'Conta e dados';

  @override
  String get settingsAccountDataSubtitle =>
      'Ocultar, transferir ou eliminar a tua conta';

  @override
  String get settingsNotificationsTitle => 'Notificações';

  @override
  String get settingsNotificationsSubtitle => 'Notificações push e por e-mail';

  @override
  String get settingsSectionEngagement => 'Participar';

  @override
  String get settingsTrustBadgesTitle => 'Selos de confiança';

  @override
  String get settingsTrustBadgesSubtitle =>
      'Vê os selos conquistados e o teu histórico de confiança';

  @override
  String get settingsTrustFiltersTitle => 'Filtros de confiança';

  @override
  String get settingsTrustFiltersSubtitle =>
      'Define os requisitos de confiança para a descoberta';

  @override
  String get settingsConversationRoomsTitle => 'Salas de conversa';

  @override
  String get settingsConversationRoomsSubtitle =>
      'Explora, entra, sai e modera salas';

  @override
  String get settingsFriendsTitle => 'Amigos e ligações';

  @override
  String get settingsFriendsSubtitle => 'Cria e cuida das tuas amizades';

  @override
  String get settingsCallHistoryTitle => 'Histórico de chamadas';

  @override
  String get settingsCallHistorySubtitle => 'Revê as tuas chamadas anteriores';

  @override
  String get settingsMatchNudgesTitle => 'Toques nos matches';

  @override
  String get settingsMatchNudgesSubtitle =>
      'Reanima conversas que ficaram em silêncio';

  @override
  String get settingsSubscriptionsTitle => 'Subscrições';

  @override
  String get settingsSubscriptionsSubtitle =>
      'Planos, estado de acesso e pagamentos';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsPrivacySafetyTitle => 'Privacidade e segurança';

  @override
  String get settingsPrivacySafetySubtitle =>
      'Gere as tuas definições de privacidade';

  @override
  String get settingsGovernmentVerificationTitle => 'Verificação de identidade';

  @override
  String get settingsGovernmentVerificationSubtitle =>
      'Vê o estado da tua verificação de identidade';

  @override
  String get settingsQaVerificationUploadTitle => 'Envio de verificação QA';

  @override
  String get settingsQaVerificationUploadSubtitle =>
      'Fluxo de documento e selfie só para automação';

  @override
  String get settingsHelpSupportTitle => 'Ajuda e apoio';

  @override
  String get settingsHelpSupportSubtitle =>
      'Perguntas frequentes e contacto com o apoio';

  @override
  String get settingsAboutTitle => 'Sobre';

  @override
  String get settingsAboutSubtitle => 'Detalhes da app e tecnologia';

  @override
  String get settingsLogout => 'Terminar sessão';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageIntro =>
      'Escolhe o idioma em que o Connect aparece. A tua escolha fica guardada na tua conta e aplica-se em todos os dispositivos onde iniciares sessão.';

  @override
  String get languageUseDevice => 'Usar o idioma do dispositivo';

  @override
  String get languageUseDeviceSubtitle =>
      'Segue a definição de idioma do teu telemóvel';

  @override
  String get languageSaveFailed =>
      'Não foi possível guardar o teu idioma. Tenta outra vez.';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String get notificationsInboxTitle => 'Caixa de notificações';

  @override
  String get notificationsInboxCaughtUp => 'Estás em dia';

  @override
  String notificationsInboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count por ler',
      one: '1 por ler',
    );
    return '$_temp0';
  }

  @override
  String get notificationsInAppTitle => 'Notificações na app';

  @override
  String get notificationsInAppSubtitle =>
      'Mostrar notificações enquanto usas a app';

  @override
  String get notificationsPushTitle => 'Notificações push';

  @override
  String get notificationsPushSubtitle =>
      'Permitir a entrega quando a app está em segundo plano';

  @override
  String get notificationsNewMatchesTitle => 'Novos matches';

  @override
  String get notificationsNewMatchesSubtitle =>
      'Recebe um aviso quando fizeres match';

  @override
  String get notificationsNewMessagesTitle => 'Novas mensagens';

  @override
  String get notificationsNewMessagesSubtitle =>
      'Recebe um aviso das mensagens do chat';

  @override
  String get notificationsLikesTitle => 'Gostos';

  @override
  String get notificationsLikesSubtitle =>
      'Recebe um aviso quando alguém gostar de ti';

  @override
  String get notificationsMatchNudgesTitle => 'Toques dos matches';

  @override
  String get notificationsMatchNudgesSubtitle =>
      'Recebe um aviso quando um match te der um toque';

  @override
  String get notificationsIncomingCallsTitle => 'Chamadas recebidas';

  @override
  String get notificationsIncomingCallsSubtitle =>
      'Mostrar alertas de chamadas recebidas';

  @override
  String get notificationsSafetyTitle => 'Atualizações de segurança';

  @override
  String get notificationsSafetySubtitle =>
      'Recebe atualizações importantes sobre o teu estado de segurança';

  @override
  String get notificationsFriendPlansTitle => 'Encontros dos teus amigos';

  @override
  String get notificationsFriendPlansSubtitle =>
      'Fica a saber quando um amigo marca um encontro ou avisa que está bem';

  @override
  String get welcomeTagline => 'Feito para a vida real.';

  @override
  String get welcomePhotoNote => 'O objetivo é encontrarem-se ao vivo.';

  @override
  String get welcomeHeadlineLead => 'Uma boa história\ncomeça com um ';

  @override
  String get welcomeHeadlineAccent => 'olá.';

  @override
  String get welcomeBody =>
      'Encontra alguém que seja mesmo o teu género de pessoa. Depois, é só seguir.';

  @override
  String get welcomeCreateAccount => 'Criar conta';

  @override
  String get welcomeAlreadyMember => 'Já tens conta? ';

  @override
  String get welcomeSignIn => 'Iniciar sessão';

  @override
  String get welcomeFooter => '18+  ·  Ao teu ritmo. A tua escolha.';

  @override
  String get authBackTooltip => 'Voltar ao início';

  @override
  String get authHeadline => 'É bom ver-te.';

  @override
  String get authSubtitle =>
      'Usa o teu nome de utilizador e palavra-passe para continuar';

  @override
  String get authWelcomeBack => 'Que bom ter-te de volta';

  @override
  String get authNextHello => 'O teu próximo olá está à espera.';

  @override
  String get authUsernameHint => 'nome de utilizador';

  @override
  String get authPasswordHint => 'Palavra-passe';

  @override
  String get authShowPassword => 'Mostrar palavra-passe';

  @override
  String get authHidePassword => 'Ocultar palavra-passe';

  @override
  String get authCantSignIn => 'Não consegues iniciar sessão?';

  @override
  String get authSignIn => 'Iniciar sessão';

  @override
  String get authPrivacyNote =>
      'A tua palavra-passe só é enviada quando inicias sessão e nunca fica guardada na app.';

  @override
  String get authEnterUsername => 'Escreve o teu nome de utilizador.';

  @override
  String get authEnterPassword => 'Escreve a tua palavra-passe.';

  @override
  String get commonYes => 'Sim';

  @override
  String get commonNo => 'Não';

  @override
  String get planVenueCoffee => 'Um café';

  @override
  String get planVenueMeal => 'Uma refeição';

  @override
  String get planVenueDrinks => 'Uns copos';

  @override
  String get planVenueWalk => 'Um passeio';

  @override
  String get planVenueActivity => 'Uma atividade';

  @override
  String get planVenueEvent => 'Um evento';

  @override
  String get planVenueVideoCall => 'Videochamada';

  @override
  String get planVenueOther => 'Outra coisa';

  @override
  String planProposeTitle(String name) {
    return 'Marca um encontro com $name';
  }

  @override
  String get planProposeSubtitle =>
      'Shape a first hello together. Contact sharing starts off.';

  @override
  String get planProposeButton => 'Propor';

  @override
  String planHeadlineProposed(String name) {
    return '$name propôs um encontro';
  }

  @override
  String planHeadlineWaiting(String name) {
    return 'À espera de $name';
  }

  @override
  String get planHeadlineUpcoming => 'Está marcado';

  @override
  String get planHeadlineCheckin => 'Como correu?';

  @override
  String get planHeadlineDebrief => 'Como foi?';

  @override
  String get planHeadlineDebriefComplete => 'Balanço concluído';

  @override
  String planHeadlineWaitingDebrief(String name) {
    return 'À espera do balanço de $name';
  }

  @override
  String get planHeadlineCheckedInSafe => 'Avisaste que estás bem';

  @override
  String get planHeadlineFriendsAlerted => 'Your request for help is recorded';

  @override
  String get planHeadlineDefault => 'Encontro';

  @override
  String get planStatusProposed => 'Proposto';

  @override
  String get planStatusConfirmed => 'Confirmado';

  @override
  String get planDebriefButton => 'Balanço de dez segundos';

  @override
  String get planDecline => 'Recusar';

  @override
  String get planAccept => 'Aceitar';

  @override
  String get planFriendsKnowAccepted =>
      'Choose trusted contacts to share your updates.';

  @override
  String get planFriendsKnowProposed =>
      'Contact sharing is optional for each plan.';

  @override
  String get planCancel => 'Cancelar encontro';

  @override
  String get planNeedHelp => 'Preciso de ajuda';

  @override
  String get planImSafe => 'Estou bem';

  @override
  String get planCancelDialogTitle => 'Cancelar este encontro?';

  @override
  String planCancelDialogBody(String name) {
    return '$name e todas as pessoas com quem o partilhaste vão ser avisadas.';
  }

  @override
  String get planKeepIt => 'Manter';

  @override
  String get planProposeIntro =>
      'This starts between you and your date. After proposing, choose trusted contacts if you want to share plan and check-in updates.';

  @override
  String get planSectionWhen => 'Quando';

  @override
  String get planSectionWhat => 'O quê';

  @override
  String get planSectionGroups => 'Trusted contacts';

  @override
  String planDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String get planPlaceLabel => 'Local (opcional)';

  @override
  String get planPlaceHint => 'Um sítio público é o ideal';

  @override
  String get planAreaLabel => 'Zona ou bairro';

  @override
  String get planNoteLabel => 'Nota para a outra pessoa (opcional)';

  @override
  String get planFutureTimeError => 'Escolhe uma hora no futuro.';

  @override
  String get planProposeFailed => 'Não foi possível propor este encontro.';

  @override
  String get planSendButton => 'Enviar proposta';

  @override
  String get planAcceptTitle => 'Aceitar o encontro?';

  @override
  String get planAcceptIntro =>
      'Accept this plan with your date. Choose trusted contacts afterwards if you want to share your updates.';

  @override
  String get planAcceptButton => 'Accept plan';

  @override
  String debriefTitle(String name) {
    return 'Como foi com $name?';
  }

  @override
  String get debriefIntro =>
      'As tuas respostas são privadas. Quando ambos confirmam que o encontro aconteceu, conta para o teu selo Shows Up.';

  @override
  String get debriefHappened => 'O encontro aconteceu?';

  @override
  String get debriefMeetAgain => 'Voltarias a encontrar-te?';

  @override
  String get debriefFeltSafe => 'Sentiste-te em segurança?';

  @override
  String get debriefNoteLabel => 'Queres acrescentar algo? (opcional)';

  @override
  String get debriefMissingHappened => 'Diz-nos se o encontro aconteceu.';

  @override
  String get debriefSaveFailed => 'Não foi possível guardar o teu balanço.';

  @override
  String get debriefSave => 'Guardar balanço';

  @override
  String get debriefUnsafeTitle =>
      'Lamentamos que não te tenhas sentido em segurança';

  @override
  String debriefUnsafeBody(String name) {
    return 'A tua resposta fica registada para a nossa equipa de segurança. Queres também denunciar $name?';
  }

  @override
  String get debriefNotNow => 'Agora não';

  @override
  String get debriefReport => 'Denunciar';

  @override
  String get plansTitle => 'Encontros';

  @override
  String get plansTabMine => 'Meus';

  @override
  String get plansTabFriends => 'Amigos';

  @override
  String get plansEmptyMineTitle => 'Ainda sem encontros';

  @override
  String get plansEmptyMineBody =>
      'Propose a date from a conversation. You choose whether to share plan and check-in updates with trusted contacts.';

  @override
  String plansWith(String name) {
    return 'Com $name';
  }

  @override
  String get plansNextDecide => 'À espera da tua resposta';

  @override
  String plansNextAwait(String name) {
    return 'À espera de $name';
  }

  @override
  String get plansNextUpcoming => 'Confirmed. Your time together is planned.';

  @override
  String get plansNextCheckin => 'Check in after your date';

  @override
  String get plansNextDebrief => 'Conta-nos como correu';

  @override
  String get plansNextCancelled => 'Cancelado';

  @override
  String get plansNextDone => 'Concluído';

  @override
  String get plansEmptyFriendsTitle => 'Ainda nada partilhado';

  @override
  String get plansEmptyFriendsBody =>
      'Plans appear here when friends explicitly choose to share with you.';

  @override
  String get plansViaGroup => 'Shared with you';

  @override
  String get plansViaFriend => 'Trusted contact';

  @override
  String plansFriendNeedsHelp(String name) {
    return '$name pediu ajuda. Entra em contacto já.';
  }

  @override
  String plansFriendMissedCheckin(String name) {
    return '$name ainda não avisou que está bem.';
  }

  @override
  String plansFriendCheckedInSafe(String name, String via) {
    return '$name avisou que está bem · $via';
  }

  @override
  String plansFriendStatusLine(String via, String status) {
    return '$via · $status';
  }

  @override
  String get plansStatusWordProposed => 'proposto';

  @override
  String get plansStatusWordConfirmed => 'confirmado';

  @override
  String get plansStatusWordCancelled => 'cancelado';

  @override
  String get plansStatusWordHappened => 'aconteceu';

  @override
  String get chatEmptyDefault =>
      'Diz olá. As mensagens aparecem aqui para todas as pessoas desta conversa.';

  @override
  String get chatNotSentRetry =>
      'Não enviada. Toca na mensagem para tentar de novo.';

  @override
  String get chatRetrySend => 'Tentar enviar de novo';

  @override
  String get chatCopyText => 'Copiar texto';

  @override
  String get chatDeleteMine => 'Apagar a minha mensagem';

  @override
  String get chatRemoveMessage => 'Remover mensagem';

  @override
  String get chatReportMessage => 'Denunciar mensagem';

  @override
  String get chatThisMember => 'Este membro';

  @override
  String get chatMember => 'Membro';

  @override
  String get chatCopied => 'Copiado.';

  @override
  String get chatDeleteFailed => 'Não foi possível apagar. Tenta de novo.';

  @override
  String get chatSubtitleFriends => 'Amigos';

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membros',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String get chatReconnecting =>
      'A religar. As novas mensagens podem demorar um pouco.';

  @override
  String get chatUnavailable =>
      'Esta conversa não está disponível. Talvez já não faças parte dela.';

  @override
  String get chatTryAgain => 'Tentar de novo';

  @override
  String get chatStatusNotSent =>
      'Não enviada · mantém premido para tentar de novo';

  @override
  String get chatStatusSending => 'A enviar…';

  @override
  String get chatMessageRemoved => 'Mensagem removida';

  @override
  String chatSemanticsYouAt(String time) {
    return 'Tu às $time';
  }

  @override
  String chatSemanticsMemberAt(String name, String time) {
    return '$name às $time';
  }

  @override
  String chatAboutMember(String name) {
    return 'Sobre $name';
  }

  @override
  String get chatComposerHint => 'Escreve uma mensagem';

  @override
  String get chatMutedComposerHint => 'Neste momento não podes escrever';

  @override
  String get chatSend => 'Enviar';

  @override
  String chatRoomMutedUntil(String when) {
    return 'Estás silenciado nesta sala até às $when. Podes continuar a ler.';
  }

  @override
  String get chatRoomMuted =>
      'Estás silenciado nesta sala. Podes continuar a ler.';

  @override
  String chatReadOnlyUntil(String when) {
    return 'Podes ler esta conversa, mas não escrever até às $when.';
  }

  @override
  String get chatReadOnly =>
      'Podes ler esta conversa, mas neste momento não podes escrever.';

  @override
  String get chatMuteTooltip => 'Silenciar notificações';

  @override
  String get chatMutedTooltip => 'Notificações silenciadas';

  @override
  String get chatMuteSheetTitle => 'Silenciar notificações';

  @override
  String get chatMuteSheetBody =>
      'As mensagens continuam a chegar aqui, só que sem notificações.';

  @override
  String get chatMuteOneHour => 'Durante 1 hora';

  @override
  String get chatMuteEightHours => 'Durante 8 horas';

  @override
  String get chatMuteOneWeek => 'Durante 1 semana';

  @override
  String get chatMuteForever => 'Até eu voltar a ativar';

  @override
  String get chatUnmute => 'Voltar a ativar as notificações';

  @override
  String chatMutedUntilLabel(String when) {
    return 'Silenciadas até às $when';
  }

  @override
  String get chatMutedIndefinitely =>
      'Silenciadas até voltares a ativar as notificações.';

  @override
  String get chatMuteDone => 'Notificações silenciadas.';

  @override
  String get chatUnmuteDone => 'As notificações voltaram a estar ativas.';

  @override
  String get chatMuteFailed =>
      'Não foi possível alterar as notificações. Tenta de novo.';

  @override
  String get roomsClosedSnack => 'Esta sala fechou.';

  @override
  String get roomsChatNotOpen => 'O chat desta sala ainda não está aberto.';

  @override
  String get roomsJoinFailed =>
      'Não foi possível entrar nesta sala. Tenta de novo.';

  @override
  String get roomsStartRoom => 'Abrir uma sala';

  @override
  String get roomsEyebrow => 'CHAT AO VIVO';

  @override
  String get roomsTitle => 'Salas';

  @override
  String get roomsSubtitle =>
      'Entra numa conversa. Se te deres bem com alguém, adiciona-o como amigo.';

  @override
  String get roomsSectionRooms => 'SALAS';

  @override
  String get roomsSectionYours => 'AS TUAS SALAS';

  @override
  String get roomsYoursCaption =>
      'As salas onde estás. Toca para continuar a conversa.';

  @override
  String get roomsSectionLive => 'AO VIVO AGORA';

  @override
  String get roomsLiveTitle => 'Onde se está a conversar';

  @override
  String get roomsSectionBrowse => 'EXPLORAR';

  @override
  String get roomsBrowseTitle => 'Encontra a tua sala';

  @override
  String get roomsBrowseCaption =>
      'Sempre abertas. Escolhe um tema, diz olá e vê com quem te dás bem.';

  @override
  String get roomsNoFriendsHere =>
      'Neste momento nenhum dos teus amigos está numa destas salas.';

  @override
  String get roomsNoRoomsInTopic => 'Ainda não há salas sobre este tema.';

  @override
  String get roomsSectionComingUp => 'EM BREVE';

  @override
  String get roomsComingUpCaption =>
      'Salas organizadas por membros. Entra cedo para guardar lugar.';

  @override
  String get roomsCategoryAll => 'Todas';

  @override
  String get roomsCategoryTalk => 'Conversa';

  @override
  String get roomsCategoryInterests => 'Interesses';

  @override
  String get roomsCategoryActive => 'Por aí';

  @override
  String get roomsCategoryCity => 'A tua cidade';

  @override
  String get roomsFriendsHereChip => 'Amigos cá';

  @override
  String get roomsQuiet => 'Está tudo calmo. Sê o primeiro a dizer olá.';

  @override
  String roomsPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas',
      one: '1 pessoa',
    );
    return '$_temp0';
  }

  @override
  String roomsRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count salas',
      one: '1 sala',
    );
    return '$_temp0';
  }

  @override
  String roomsChattingIn(String people, String rooms) {
    return '$people a conversar em $rooms';
  }

  @override
  String roomsHereNow(int count) {
    return '$count cá agora';
  }

  @override
  String roomsInTheRoom(int count) {
    return '$count na sala';
  }

  @override
  String roomsFriendsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amigos cá',
      one: '1 amigo cá',
    );
    return '$_temp0';
  }

  @override
  String get roomsHostedByYou => 'Organizada por ti';

  @override
  String roomsHostedBy(String name) {
    return 'Organizada por $name';
  }

  @override
  String get roomsActionOpen => 'Abrir';

  @override
  String get roomsActionFull => 'Cheia';

  @override
  String get roomsActionJoin => 'Entrar';

  @override
  String roomsStartsAt(String time) {
    return 'Começa às $time';
  }

  @override
  String roomsStartsOn(String day, String time) {
    return 'Começa a $day às $time';
  }

  @override
  String get roomsStartNameTooShort =>
      'Dá à sala um nome com pelo menos 3 letras.';

  @override
  String get roomsStartIntro =>
      'És tu quem organiza: podes avisar, silenciar ou remover pessoas e fechá-la quando terminares. Uma sala de cada vez.';

  @override
  String get roomsStartNameLabel => 'Nome da sala';

  @override
  String get roomsStartNameHint => 'Troca de livros de domingo';

  @override
  String get roomsStartAboutLabel => 'Sobre o que é? (opcional)';

  @override
  String get roomsStartTopic => 'Tema';

  @override
  String get roomsStartHowLong => 'Duração';

  @override
  String get roomsLength30Min => '30 min';

  @override
  String get roomsLength1Hour => '1 hora';

  @override
  String get roomsLength2Hours => '2 horas';

  @override
  String get roomsStartNow => 'Começar agora';

  @override
  String get roomsRoleHost => 'Anfitrião';

  @override
  String get roomsRoleModerator => 'Moderador';

  @override
  String get roomsRoomFallback => 'Sala';

  @override
  String roomsChatEmpty(String room) {
    return 'Já estás cá. Diz olá: todos em $room veem o que escreves aqui.';
  }

  @override
  String get roomsPeopleTooltip => 'Pessoas nesta sala';

  @override
  String roomsLeaveTitle(String room) {
    return 'Sair de $room?';
  }

  @override
  String get roomsLeaveBody =>
      'Deixas de ver as mensagens desta sala. Podes voltar quando quiseres enquanto estiver aberta.';

  @override
  String get roomsLeaveAction => 'Sair da sala';

  @override
  String get roomsLeaveFailed => 'Não foi possível sair. Tenta de novo.';

  @override
  String roomsCloseTitle(String room) {
    return 'Fechar $room?';
  }

  @override
  String get roomsCloseBody =>
      'O chat termina para todas as pessoas da sala. Não é possível anular.';

  @override
  String get roomsCloseAction => 'Fechar a sala';

  @override
  String get roomsCloseFailed => 'Não foi possível fechar. Tenta de novo.';

  @override
  String get roomsMenuTooltip => 'Opções da sala';

  @override
  String get roomsMenuPeople => 'Quem está cá';

  @override
  String get roomsMenuModerate => 'Moderar';

  @override
  String roomsModerateTitle(String room) {
    return 'Moderar $room';
  }

  @override
  String get roomsModerateIntro =>
      'Toca em alguém para o avisar, silenciar ou remover. Quem está silenciado continua a poder ler; quem é removido pode voltar quando a sessão terminar.';

  @override
  String get roomsPeopleIntro =>
      'Deste-te bem com alguém? Adiciona-o como amigo para continuarem a falar depois da sala.';

  @override
  String get roomsMembersLoadFailed =>
      'Não foi possível carregar quem está cá.';

  @override
  String get roomsStatusFriend => 'Amigo';

  @override
  String get roomsStatusHereNow => 'Cá agora';

  @override
  String get roomsStatusInRoom => 'Na sala';

  @override
  String get roomsStatusGone => 'Já não está na sala';

  @override
  String roomsStatusMutedUntil(String time) {
    return 'Silenciado até às $time';
  }

  @override
  String roomsYouSuffix(String name) {
    return '$name (tu)';
  }

  @override
  String roomsRemoveTitle(String name) {
    return 'Remover $name da sala?';
  }

  @override
  String roomsRemoveBodyAlwaysOn(String name) {
    return '$name sai já do chat e pode voltar daqui a 24 horas.';
  }

  @override
  String roomsRemoveBodyHosted(String name) {
    return '$name sai já do chat e não pode voltar até esta sala terminar.';
  }

  @override
  String roomsWarnTitle(String name) {
    return 'Avisar $name?';
  }

  @override
  String roomsWarnBody(String name) {
    return '$name recebe um lembrete privado para manter a conversa simpática e dentro do tema.';
  }

  @override
  String get roomsRemoveAction => 'Remover';

  @override
  String get roomsWarnAction => 'Enviar aviso';

  @override
  String roomsRemovedDone(String name) {
    return '$name foi removido da sala.';
  }

  @override
  String roomsWarnedDone(String name) {
    return 'Aviso enviado a $name.';
  }

  @override
  String get roomsModerationFailed => 'Não resultou. Tenta outra vez.';

  @override
  String roomsBlockedDone(String name) {
    return 'Bloqueaste $name. Aqui não vão ver as mensagens um do outro.';
  }

  @override
  String get roomsReport => 'Denunciar';

  @override
  String get roomsBlock => 'Bloquear';

  @override
  String get roomsModerateEyebrow => 'MODERAR';

  @override
  String get roomsWarn => 'Avisar';

  @override
  String get roomsRemoveFromRoom => 'Remover da sala';

  @override
  String get roomsMute => 'Silenciar';

  @override
  String get roomsUnmute => 'Tirar silêncio';

  @override
  String roomsMuteSheetTitle(String name) {
    return 'Silenciar $name?';
  }

  @override
  String roomsMuteSheetBody(String name) {
    return '$name continua a poder ler o chat, mas não pode escrever até o silêncio terminar. Vai receber uma nota privada.';
  }

  @override
  String get roomsMuteTenMinutes => 'Durante 10 minutos';

  @override
  String get roomsMuteOneHour => 'Durante 1 hora';

  @override
  String get roomsMuteUntilEnd => 'Até a sala terminar';

  @override
  String get roomsMuteOneDay => 'Durante 24 horas';

  @override
  String roomsMutedDone(String name) {
    return '$name está silenciado.';
  }

  @override
  String roomsUnmutedDone(String name) {
    return '$name já pode voltar a escrever.';
  }
}
