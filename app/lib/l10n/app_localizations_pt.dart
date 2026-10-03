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
      'De dia, marfim quente e verde-floresta. À noite, menta suave e floresta profunda.';

  @override
  String get settingsLooksClassicLabel => 'Hoje';

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
      'Deem forma juntos a um primeiro olá. A partilha com contactos começa desligada.';

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
  String get planHeadlineFriendsAlerted =>
      'O teu pedido de ajuda foi registado';

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
      'Escolhe contactos de confiança para partilhar as tuas novidades.';

  @override
  String get planFriendsKnowProposed =>
      'Partilhar com contactos é opcional em cada plano.';

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
      'Isto fica entre ti e o teu encontro. Depois de propores, escolhe contactos de confiança se quiseres partilhar novidades do plano e do check-in.';

  @override
  String get planSectionWhen => 'Quando';

  @override
  String get planSectionWhat => 'O quê';

  @override
  String get planSectionGroups => 'Contactos de confiança';

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
      'Aceita este plano com o teu encontro. Depois, escolhe contactos de confiança se quiseres partilhar as tuas novidades.';

  @override
  String get planAcceptButton => 'Aceitar plano';

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
      'Propõe um encontro a partir de uma conversa. Tu escolhes se partilhas as novidades do plano e do check-in com contactos de confiança.';

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
  String get plansNextUpcoming =>
      'Confirmado. O vosso tempo juntos está planeado.';

  @override
  String get plansNextCheckin => 'Faz check-in depois do encontro';

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
      'Os planos aparecem aqui quando os amigos escolhem partilhá-los contigo.';

  @override
  String get plansViaGroup => 'Partilhado contigo';

  @override
  String get plansViaFriend => 'Contacto de confiança';

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

  @override
  String get richFormattingToolbar => 'Formatação';

  @override
  String get richUndo => 'Desfazer';

  @override
  String get richRedo => 'Refazer';

  @override
  String get richBold => 'Negrito';

  @override
  String get richItalic => 'Itálico';

  @override
  String get richUnderline => 'Sublinhado';

  @override
  String get richStrikethrough => 'Riscado';

  @override
  String get richHighlight => 'Destacar';

  @override
  String get richLink => 'Link';

  @override
  String get richTextStyleMenu => 'Estilo do texto';

  @override
  String get richParagraph => 'Parágrafo';

  @override
  String get richHeading => 'Título';

  @override
  String get richSubheading => 'Subtítulo';

  @override
  String get richQuote => 'Citação';

  @override
  String get richCallout => 'Destaque';

  @override
  String get richBulletList => 'Lista com marcadores';

  @override
  String get richNumberedList => 'Lista numerada';

  @override
  String get richDivider => 'Separador';

  @override
  String get richAlignMenu => 'Alinhamento';

  @override
  String get richAlignStart => 'Alinhar ao início';

  @override
  String get richAlignCenter => 'Centralizar';

  @override
  String get richAlignEnd => 'Alinhar ao fim';

  @override
  String get richClearFormatting => 'Limpar formatação';

  @override
  String get richWritingStyle => 'Estilo de escrita';

  @override
  String get richStyleClassic => 'Clássico';

  @override
  String get richStyleClassicHint =>
      'Serifa elegante, como uma página impressa';

  @override
  String get richStyleModern => 'Moderno';

  @override
  String get richStyleModernHint => 'Limpo e fácil de ler';

  @override
  String get richStyleJournal => 'Diário';

  @override
  String get richStyleJournalHint => 'Itálico acolhedor, como um diário';

  @override
  String get richStyleTypewriter => 'Máquina de escrever';

  @override
  String get richStyleTypewriterHint => 'Letras quadradas com mais espaço';

  @override
  String get richStylePoetic => 'Poético';

  @override
  String get richStylePoeticHint => 'Linhas centralizadas e arejadas';

  @override
  String richWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palavras',
      one: '1 palavra',
    );
    return '$_temp0';
  }

  @override
  String get richAlignmentNote =>
      'O alinhamento e o espaçamento aparecem na pré-visualização e para quem lê.';

  @override
  String get richLinkTitle => 'Adicionar um link';

  @override
  String get richLinkField => 'Endereço web';

  @override
  String get richLinkInvalid => 'Use um endereço https:// completo.';

  @override
  String get richLinkApply => 'Adicionar link';

  @override
  String get richLinkRemove => 'Remover link';

  @override
  String get richLinkNeedsSelection =>
      'Primeiro selecione as palavras que quer ligar.';

  @override
  String get richCancel => 'Cancelar';

  @override
  String get richOpenLinkTitle => 'Abrir este link?';

  @override
  String richOpenLinkBody(String host) {
    return '$host abre fora do Connect. Abra apenas links em que confia.';
  }

  @override
  String get richOpenLink => 'Abrir link';

  @override
  String get supportCentreEyebrow => 'AJUDA E SUPORTE';

  @override
  String get supportCentreTitle => 'Como podemos ajudar?';

  @override
  String get supportCentreSubtitle =>
      'Encontre uma resposta rápida ou fale com nossa equipe. Cada pedido e resposta fica em uma conversa privada.';

  @override
  String get supportContactSection => 'FALE CONOSCO';

  @override
  String get supportContactTitle => 'Contatar o suporte';

  @override
  String get supportContactSubtitle =>
      'Conte o que aconteceu. Respondemos aqui e avisamos você.';

  @override
  String get supportMyTicketsTitle => 'Meus pedidos';

  @override
  String get supportMyTicketsSubtitle =>
      'Acompanhe seus pedidos e nossas respostas';

  @override
  String supportOpenRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pedidos abertos',
      one: '1 pedido aberto',
    );
    return '$_temp0';
  }

  @override
  String supportUnreadReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count novas respostas',
      one: '1 nova resposta',
    );
    return '$_temp0';
  }

  @override
  String get supportQuickAnswersSection => 'RESPOSTAS RÁPIDAS';

  @override
  String get supportFaqLoginTitle => 'Início de sessão';

  @override
  String get supportFaqLoginBody =>
      'Entre com seu nome de usuário exclusivo e sua senha.';

  @override
  String get supportFaqVerificationTitle => 'Verificação';

  @override
  String get supportFaqVerificationBody =>
      'A verificação de identidade é opcional enquanto o provedor estiver pausado.';

  @override
  String get supportFaqAbuseTitle => 'Abuso';

  @override
  String get supportFaqAbuseBody =>
      'Use Denunciar em um perfil ou conversa para uma análise de segurança mais rápida.';

  @override
  String get supportFaqBillingTitle => 'Cobrança';

  @override
  String get supportFaqBillingBody =>
      'Inclua a referência da transação, nunca os dados do seu cartão.';

  @override
  String get supportEmergencyNote =>
      'Se alguém estiver em perigo imediato, contate os serviços de emergência locais. Pedidos de suporte não substituem a ajuda de emergência.';

  @override
  String get supportUnavailableTitle =>
      'Os pedidos de suporte não estão disponíveis agora';

  @override
  String get supportUnavailableBody =>
      'As respostas desta página continuam funcionando. Para algo urgente, escreva para support@connect.example.';

  @override
  String get supportBackToHelp => 'Voltar para Ajuda e suporte';

  @override
  String get supportFormEyebrow => 'NOVO PEDIDO';

  @override
  String get supportFormTitle => 'Contatar o suporte';

  @override
  String get supportFormSubtitle =>
      'Dê detalhes suficientes para agirmos. Nunca inclua senha, código de recuperação, número do cartão ou documento de identidade.';

  @override
  String get supportFormCategorySection => 'ASSUNTO';

  @override
  String get supportFormCategoryLabel => 'Com o que você precisa de ajuda?';

  @override
  String get supportCategoryAccountLogin => 'Conta e login';

  @override
  String get supportCategoryVerification => 'Verificação';

  @override
  String get supportCategoryPaymentsBilling => 'Pagamentos e cobrança';

  @override
  String get supportCategorySafetyHarassment => 'Segurança e assédio';

  @override
  String get supportCategoryMatchesChat => 'Matches e chat';

  @override
  String get supportCategoryTechnical => 'Problema técnico ou bug';

  @override
  String get supportCategoryFeatureRequest => 'Sugestão de recurso';

  @override
  String get supportCategoryPrivacyData => 'Privacidade e dados';

  @override
  String get supportCategoryOther => 'Outro';

  @override
  String get supportSafetyNote =>
      'Se você ou outra pessoa estiver em perigo imediato, use o SOS no app ou ligue para os serviços de emergência locais. Pedidos de segurança têm prioridade, mas um pedido não é uma linha de emergência.';

  @override
  String get supportOpenSos => 'Abrir SOS';

  @override
  String get supportFormDetailsSection => 'DETALHES';

  @override
  String get supportFormSubjectLabel => 'Assunto';

  @override
  String get supportFormSubjectHint => 'Descreva o problema rapidamente';

  @override
  String get supportFormDescriptionLabel => 'O que aconteceu?';

  @override
  String get supportFormDescriptionHint =>
      'O que você fez, o que esperava e o que aconteceu em vez disso';

  @override
  String get supportFormScreenshotsSection => 'CAPTURAS DE TELA';

  @override
  String supportFormScreenshotsCaption(int max) {
    return 'Opcional. Até $max imagens.';
  }

  @override
  String get supportAddScreenshot => 'Adicionar captura';

  @override
  String supportRemoveAttachment(String name) {
    return 'Remover $name';
  }

  @override
  String get supportAttachmentUploading => 'Enviando';

  @override
  String get supportRetryUpload => 'Tentar enviar de novo';

  @override
  String supportFormDeviceNote(String version) {
    return 'Vamos incluir a versão do app ($version), a plataforma, a versão do sistema e o idioma para ajudar a resolver o problema.';
  }

  @override
  String get supportSubmit => 'Enviar pedido';

  @override
  String get supportErrorCategoryRequired => 'Escolha um assunto.';

  @override
  String supportErrorSubjectLength(int min, int max) {
    return 'Use de $min a $max caracteres no assunto.';
  }

  @override
  String get supportErrorDescriptionRequired => 'Descreva o que aconteceu.';

  @override
  String supportErrorDescriptionTooLong(int max) {
    return 'Use menos de $max caracteres.';
  }

  @override
  String get supportErrorUploadsPending =>
      'Aguarde o envio das capturas terminar ou remova as que falharam.';

  @override
  String supportCreatedSnack(String reference) {
    return 'Pedido $reference enviado. Responderemos aqui.';
  }

  @override
  String supportDuplicateSnack(String reference) {
    return 'Você já enviou este pedido, então o abrimos: $reference.';
  }

  @override
  String supportErrorRateLimited(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Você enviou vários pedidos em pouco tempo. Tente de novo em $minutes minutos.',
      one:
          'Você enviou vários pedidos em pouco tempo. Tente de novo em 1 minuto.',
    );
    return '$_temp0';
  }

  @override
  String get supportErrorRateLimitedGeneric =>
      'Você enviou vários pedidos em pouco tempo. Tente de novo mais tarde.';

  @override
  String get supportErrorTooManyOpen =>
      'Você já tem 10 pedidos abertos. Feche um de que não precisa mais ou aguarde nossas respostas.';

  @override
  String get supportErrorTicketClosed =>
      'Este pedido está fechado e não pode mais ser reaberto. Crie um novo pedido.';

  @override
  String get supportErrorReopenWindowPassed =>
      'O prazo para reabrir este pedido terminou. Crie um novo pedido.';

  @override
  String get supportErrorAlreadyRated => 'Você já avaliou este pedido.';

  @override
  String get supportErrorNotResolved =>
      'Você pode avaliar o pedido quando ele for resolvido.';

  @override
  String get supportErrorAttachmentType =>
      'Só é possível anexar imagens JPEG ou PNG e arquivos PDF.';

  @override
  String get supportErrorAttachmentTooLarge =>
      'Esse arquivo é grande demais. As imagens podem ter até 8 MB.';

  @override
  String get supportErrorOffline =>
      'Não foi possível acessar o Connect agora. Verifique sua conexão e tente de novo.';

  @override
  String get supportErrorNotFound => 'Não encontramos este pedido.';

  @override
  String get supportErrorGeneric => 'Algo deu errado. Tente de novo.';

  @override
  String get supportTryAgain => 'Tentar de novo';

  @override
  String get supportTicketsEyebrow => 'SUPORTE';

  @override
  String get supportTicketsTitle => 'Meus pedidos';

  @override
  String get supportTicketsSubtitle => 'Seus pedidos e nossas respostas.';

  @override
  String get supportTicketsActiveSection => 'ATIVOS';

  @override
  String get supportTicketsClosedSection => 'RESOLVIDOS E FECHADOS';

  @override
  String get supportTicketsEmptyTitle => 'Nenhum pedido ainda';

  @override
  String get supportTicketsEmptyBody =>
      'Quando você contatar o suporte, seu pedido e nossas respostas aparecerão aqui.';

  @override
  String get supportTicketsLoadErrorTitle =>
      'Não foi possível carregar seus pedidos';

  @override
  String supportTicketUpdated(String when) {
    return 'Atualizado $when';
  }

  @override
  String get supportNewTicket => 'Novo pedido';

  @override
  String get supportStatusOpen => 'Aberto';

  @override
  String get supportStatusWaitingForYou => 'Aguardando você';

  @override
  String get supportStatusOnHold => 'Em espera';

  @override
  String get supportStatusResolved => 'Resolvido';

  @override
  String get supportStatusClosed => 'Fechado';

  @override
  String supportStatusSemantics(String status) {
    return 'Status: $status';
  }

  @override
  String get supportThreadAgentName => 'Suporte Connect';

  @override
  String get supportThreadYou => 'Você';

  @override
  String supportTicketMeta(String category, String date) {
    return '$category · Aberto em $date';
  }

  @override
  String get supportBannerOpen =>
      'Recebemos seu pedido. Nossa equipe responderá aqui e avisará você.';

  @override
  String get supportBannerWaiting =>
      'O suporte respondeu e está aguardando sua resposta.';

  @override
  String get supportBannerOnHold =>
      'Seu pedido está em espera enquanto analisamos. Atualizaremos você aqui.';

  @override
  String get supportBannerResolved =>
      'Marcado como resolvido. Responda para reabrir; caso contrário, ele será fechado automaticamente após 7 dias.';

  @override
  String supportBannerClosedUntil(String date) {
    return 'Este pedido está fechado. Você pode reabri-lo até $date.';
  }

  @override
  String get supportBannerClosed => 'Este pedido está fechado.';

  @override
  String supportBannerMerged(String reference) {
    return 'Este pedido foi unido a $reference. A conversa continua lá.';
  }

  @override
  String get supportReplyHint => 'Escreva uma resposta';

  @override
  String get supportReplyDisabledHint =>
      'Não é mais possível responder a este pedido';

  @override
  String get supportSendReply => 'Enviar resposta';

  @override
  String get supportAttachScreenshot => 'Anexar captura';

  @override
  String get supportCloseTicket => 'Fechar pedido';

  @override
  String get supportCloseConfirmTitle => 'Fechar este pedido?';

  @override
  String get supportCloseConfirmBody =>
      'Feche se o problema foi resolvido. Você poderá reabri-lo por 14 dias.';

  @override
  String get supportCancel => 'Cancelar';

  @override
  String get supportClosedSnack => 'Pedido fechado.';

  @override
  String get supportReopen => 'Reabrir pedido';

  @override
  String get supportReopenedSnack => 'Pedido reaberto.';

  @override
  String get supportRateTitle => 'Como nos saímos?';

  @override
  String get supportRateCaption => 'Avalie sua experiência com este pedido.';

  @override
  String supportRateStar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrelas',
      one: '1 estrela',
    );
    return '$_temp0';
  }

  @override
  String get supportRateCommentLabel => 'Algo a acrescentar? (opcional)';

  @override
  String get supportRateSubmit => 'Enviar avaliação';

  @override
  String get supportRatedTitle => 'Obrigado pelo seu feedback';

  @override
  String supportRatedValue(int rating) {
    return 'Você deu $rating de 5.';
  }

  @override
  String get supportRatingSnack => 'Obrigado por avaliar sua experiência.';

  @override
  String supportAttachmentImage(String name) {
    return 'Captura $name';
  }

  @override
  String get supportAttachmentLoadFailed => 'Não foi possível carregar o anexo';

  @override
  String get supportThreadLoadErrorTitle =>
      'Não foi possível carregar este pedido';

  @override
  String get chemistryCardEntry => 'Um pouco de química?';

  @override
  String get memberProfileIntroducing => 'Apresentamos';

  @override
  String get memberProfileStarring => 'No papel principal';

  @override
  String get memberProfileVerified => 'Verificado';

  @override
  String memberProfilePhotoLabel(String name, int index, int count) {
    return '$name, foto $index de $count';
  }

  @override
  String get memberProfileNoPhoto => 'Ainda sem foto';

  @override
  String get memberProfileViewPhotoHint => 'ver em ecrã inteiro';

  @override
  String get memberProfileCloseGallery => 'Fechar fotos';

  @override
  String get memberProfilePhotos => 'Fotos';

  @override
  String memberProfileMorePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mais $count fotos',
      one: 'mais 1 foto',
    );
    return '$_temp0';
  }

  @override
  String get memberProfileSceneAbout => 'Sobre mim';

  @override
  String get memberProfileSceneStories => 'Histórias';

  @override
  String get memberProfileSceneStoriesTitle => 'Um pouco mais de mim';

  @override
  String get memberProfileSceneInterests => 'Interesses';

  @override
  String get memberProfileSceneBasics => 'O essencial';

  @override
  String get memberProfileSceneLifestyle => 'Estilo de vida';

  @override
  String get memberProfileSceneTrust => 'Confiança';

  @override
  String get memberProfileReadMore => 'Ler mais';

  @override
  String get memberProfileReadLess => 'Ler menos';

  @override
  String get memberProfileHobbies => 'Passatempos';

  @override
  String get memberProfileActivities => 'Atividades';

  @override
  String get memberProfileSongs => 'Em repetição';

  @override
  String get memberProfileBooks => 'Livros e romances';

  @override
  String get memberProfileLookingFor => 'Procura';

  @override
  String get memberProfileLanguages => 'Idiomas';

  @override
  String get memberProfileDealBreakers => 'Inegociáveis';

  @override
  String get memberProfileInCommon => 'Em comum';

  @override
  String get memberProfileFactHeight => 'Altura';

  @override
  String memberProfileHeightCm(int cm) {
    return '$cm cm';
  }

  @override
  String get memberProfileFactWork => 'Trabalho';

  @override
  String get memberProfileFactEducation => 'Formação';

  @override
  String get memberProfileFactLivesIn => 'Vive em';

  @override
  String get memberProfileFactMotherTongue => 'Língua materna';

  @override
  String get memberProfileFactReligion => 'Religião';

  @override
  String get memberProfileFactPersonality => 'Personalidade';

  @override
  String get memberProfileFactRelationship => 'Situação amorosa';

  @override
  String get memberProfileFactInstagram => 'Instagram';

  @override
  String get memberProfileFactDrinking => 'Álcool';

  @override
  String get memberProfileFactSmoking => 'Tabaco';

  @override
  String get memberProfileFactWorkout => 'Exercício';

  @override
  String get memberProfileFactDiet => 'Dieta';

  @override
  String get memberProfileFactDietType => 'Tipo de dieta';

  @override
  String get memberProfileFactSleep => 'Sono';

  @override
  String get memberProfileFactTravel => 'Viagens';

  @override
  String get memberProfileFactPets => 'Animais';

  @override
  String get memberProfileFactPolitics => 'Política';

  @override
  String get memberProfileFactOpenToCasual => 'Aberto a algo casual';

  @override
  String get memberProfileFactPartyLover => 'Gosta de festas';

  @override
  String get memberProfileVerifiedTitle => 'Perfil verificado';

  @override
  String get memberProfileVerifiedBody =>
      'Verificação de identidade concluída.';

  @override
  String get memberProfileVouchesTitle => 'Recomendado por amigos';

  @override
  String get memberProfileSpotlight => 'Destaque';

  @override
  String get memberProfileFreeWhenYouAre => 'Livre quando tu estás';

  @override
  String get memberProfileMessage => 'Mensagem';

  @override
  String get memberProfileLove => 'Adoro';

  @override
  String get memberProfileReport => 'Denunciar';

  @override
  String get memberProfileOwnerTitle => 'É assim que te veem';

  @override
  String get memberProfileOwnerCaption =>
      'Os membros veem o teu perfil exatamente assim.';

  @override
  String memberProfileCompleteness(int percent) {
    return 'Perfil $percent% completo';
  }

  @override
  String get memberProfileCompletenessHint =>
      'Adiciona fotos, histórias e detalhes para te destacares.';

  @override
  String get memberProfileCompletenessDone => 'O teu perfil está completo.';

  @override
  String get memberProfileToolEdit => 'Editar perfil';

  @override
  String get memberProfileToolPhotos => 'Editar fotos';

  @override
  String get memberProfileToolStories => 'As tuas histórias';

  @override
  String get memberProfileToolViewers => 'Quem te viu';

  @override
  String get memberProfileBehindTheScenes => 'Nos bastidores';

  @override
  String get memberProfileOnlyYou => 'Só tu podes ver isto.';

  @override
  String get memberProfileMine => 'O meu perfil';

  @override
  String get profileShowcaseLabel => 'Escritos e momentos';

  @override
  String get profileShowcaseTitleOther => 'Nas próprias palavras';

  @override
  String get profileShowcaseTitleSelf => 'Os teus escritos e fotos públicos';

  @override
  String get profileShowcaseChapters => 'Capítulos';

  @override
  String get profileShowcasePhotos => 'Fotos do mural';

  @override
  String get profileShowcaseReadAll => 'Ler todos os capítulos';

  @override
  String get profileShowcaseHiddenTitle => 'Só tu vês isto';

  @override
  String get profileShowcaseHiddenBody =>
      'Os teus capítulos públicos e fotos do mural estão ocultos no teu perfil. Ativa esta opção para que os membros os vejam aqui.';

  @override
  String get profileShowcaseShownBody =>
      'Os membros podem vê-los no teu perfil. Só aparecem capítulos partilhados com a comunidade e fotos do mural.';

  @override
  String get profileShowcaseSwitch => 'Mostrar no meu perfil';

  @override
  String get profileShowcaseSaveFailed =>
      'Não foi possível guardar a tua escolha.';

  @override
  String get callsHistoryTitle => 'Histórico de chamadas';

  @override
  String get callsHistoryEmpty => 'Ainda não há chamadas.';

  @override
  String callsHistoryMatch(String id) {
    return 'Match $id';
  }

  @override
  String get callsJoinLiveRoom => 'Entrar na sala ao vivo';

  @override
  String get callsActiveSession => 'Chamada em andamento';

  @override
  String callsEndedWithDuration(String duration) {
    return 'Encerrada · $duration';
  }

  @override
  String get callsSessionTitle => 'Chamada';

  @override
  String get callsStarting => 'Iniciando sessão segura…';

  @override
  String get callsSessionActive => 'Chamada ativa';

  @override
  String get callsSessionUnavailable => 'Chamada indisponível';

  @override
  String get callsLiveRoomNote =>
      'A sala ao vivo abre numa janela segura do provedor. Durante a chamada, use os controles de microfone, câmera e saída dessa sala.';

  @override
  String get callsEnd => 'Encerrar';

  @override
  String get callsErrorSignInHistory =>
      'Entre na sua conta para ver o histórico de chamadas.';

  @override
  String get callsErrorSignInStart =>
      'Entre na sua conta antes de iniciar uma chamada.';

  @override
  String get callsErrorPermissions =>
      'As chamadas precisam de permissão para a câmera e o microfone.';

  @override
  String get callsErrorLoadHistory =>
      'Não foi possível carregar o histórico de chamadas.';

  @override
  String get callsErrorStart => 'Não foi possível iniciar a chamada.';

  @override
  String get callsErrorEnd => 'Não foi possível encerrar a chamada.';

  @override
  String get callsErrorNotConfigured =>
      'As salas de chamada ao vivo não estão configuradas neste ambiente.';

  @override
  String get callsErrorOpenRoom =>
      'Não foi possível abrir a sala de chamada ao vivo.';

  @override
  String get commonRetry => 'Tentar de novo';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonCopy => 'Copiar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get commonReset => 'Repor';

  @override
  String get commonOpen => 'Abrir';

  @override
  String get commonView => 'Ver';

  @override
  String get commonDismiss => 'Ignorar';

  @override
  String get commonAny => 'Qualquer';

  @override
  String get commonSomethingWentWrong => 'Algo correu mal';

  @override
  String get commonSomethingWentWrongTryAgain =>
      'Algo correu mal. Tenta novamente.';

  @override
  String get commonTryAgainTitle => 'Tentar de novo';

  @override
  String get commonNothingHereYet => 'Ainda não há nada aqui';

  @override
  String commonLoadingLabel(String label) {
    return '$label, a carregar';
  }

  @override
  String commonDistanceKm(int distance) {
    return '$distance km';
  }

  @override
  String get navToday => 'Hoje';

  @override
  String get navOfflineBanner =>
      'Modo offline: alguns dados podem estar desatualizados.';

  @override
  String navWeakNetworkBanner(int mbps) {
    return 'Rede fraca detetada. Usa pelo menos $mbps Mbps para a app funcionar melhor.';
  }

  @override
  String get navIncomingCallTitle => 'Chamada recebida';

  @override
  String get navIncomingCallBody => 'Um match está a ligar-te.';

  @override
  String get navViewCallDetails => 'Ver detalhes da chamada';

  @override
  String get filterSheetTitle => 'Filtrar matches';

  @override
  String get filterAgeRange => 'Faixa etária';

  @override
  String get filterProfileLifestyle => 'Filtros de perfil e estilo de vida';

  @override
  String get filterCountry => 'País';

  @override
  String get filterState => 'Estado/região';

  @override
  String get filterCity => 'Cidade';

  @override
  String get filterMotherTongue => 'Língua materna';

  @override
  String get filterReligion => 'Religião';

  @override
  String get filterRelationshipStatus => 'Estado civil';

  @override
  String get filterSmoking => 'Tabaco';

  @override
  String get filterDrinking => 'Álcool';

  @override
  String get filterPersonalityType => 'Tipo de personalidade';

  @override
  String get filterPartyLoverOnly => 'Só amantes de festas';

  @override
  String get filterHookupsOnly => 'Só encontros casuais';

  @override
  String get filterAdvancedBio => 'Filtros avançados de biografia';

  @override
  String get filterAdvancedBioBody =>
      'Livros, romances, músicas, passatempos, localização e atividades gerem-se em Definições → Preferências de encontros.';

  @override
  String get filterOpenDatingPreferences => 'Abrir preferências de encontros';

  @override
  String get filterDistanceKm => 'Distância (km)';

  @override
  String get filterVerifiedOnlyTitle => 'Só verificados';

  @override
  String get filterVerifiedOnlyBody => 'Mostrar apenas perfis verificados';

  @override
  String get filterVerifiedOnlyChip => 'Só verificados';

  @override
  String get filterPartyLoverChip => 'Amante de festas';

  @override
  String get filterHookupChip => 'Só casual';

  @override
  String get filterEnableTrust => 'Ativar filtro de confiança';

  @override
  String filterMinimumTrustBadges(int count) {
    return 'Mínimo de selos de confiança ativos: $count';
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
      'true': ', só verificados',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(trust, {
      'true': ', filtro de confiança ativo',
      'other': ', filtro de confiança desativado',
    });
    return 'Filtros guardados: $minAge-$maxAge anos, $distance km$_temp0$_temp1';
  }

  @override
  String get optionNever => 'Nunca';

  @override
  String get optionOccasionally => 'Ocasionalmente';

  @override
  String get optionSocially => 'Socialmente';

  @override
  String get optionRegularly => 'Regularmente';

  @override
  String get optionSingle => 'Solteiro/a';

  @override
  String get optionDivorced => 'Divorciado/a';

  @override
  String get optionWidowed => 'Viúvo/a';

  @override
  String get optionSeparated => 'Separado/a';

  @override
  String get optionComplicated => 'É complicado';

  @override
  String get optionIntrovert => 'Introvertido/a';

  @override
  String get optionAmbivert => 'Ambivertido/a';

  @override
  String get optionExtrovert => 'Extrovertido/a';

  @override
  String get optionHighSchool => 'Ensino secundário';

  @override
  String get optionBachelors => 'Licenciatura';

  @override
  String get optionMasters => 'Mestrado';

  @override
  String get optionPhd => 'Doutoramento';

  @override
  String get optionOther => 'Outro';

  @override
  String get optionPreferNotToSay => 'Prefiro não dizer';

  @override
  String get optionHindu => 'Hindu';

  @override
  String get optionMuslim => 'Muçulmano/a';

  @override
  String get optionChristian => 'Cristão/ã';

  @override
  String get optionSikh => 'Sikh';

  @override
  String get optionBuddhist => 'Budista';

  @override
  String get optionJain => 'Jainista';

  @override
  String get optionJewish => 'Judeu/judia';

  @override
  String get optionSpiritual => 'Espiritual';

  @override
  String get optionAgnostic => 'Agnóstico/a';

  @override
  String get optionAtheist => 'Ateu/ateia';

  @override
  String get storiesNudgeTitle => 'Conta um pouco mais da tua história';

  @override
  String get storiesNudgeBodyUnknown =>
      'Histórias curtas no teu perfil dão às pessoas algo real para começar a conversa.';

  @override
  String get storiesNudgeActionOpen => 'Abrir as tuas histórias';

  @override
  String get storiesNudgeBodyEmpty =>
      'Adiciona uma história curta ao teu perfil: uma pequena alegria, um fim de semana que vale a pena partilhar. As pessoas leem-nas antes de dizer olá.';

  @override
  String get storiesNudgeActionFirst => 'Escreve a tua primeira história';

  @override
  String get storiesNudgeCompleteTitle => 'A tua história está completa';

  @override
  String get storiesNudgeCompleteBody =>
      'As três histórias estão no teu perfil. Renova uma sempre que a vida te der uma nova.';

  @override
  String get storiesNudgeActionEdit => 'Editar as tuas histórias';

  @override
  String storiesNudgeSharedTitle(int count, int max) {
    return '$count de $max histórias partilhadas';
  }

  @override
  String get storiesNudgeBodyMore =>
      'Mais uma história dá às pessoas outra forma de começar uma conversa.';

  @override
  String storiesNudgeBodyLatest(String prompt) {
    return 'A mais recente: «$prompt». Mais uma dá às pessoas outra forma de começar uma conversa.';
  }

  @override
  String get storiesNudgeActionAdd => 'Adicionar outra história';

  @override
  String get storiesNudgeIdeas => 'Ideias para começar';

  @override
  String storiesProgressSemantics(int count, int max) {
    return '$count de $max histórias escritas';
  }

  @override
  String get storiesPromptLittleJoy =>
      'Uma pequena coisa para a qual arranjo sempre tempo';

  @override
  String get storiesPromptWeekend =>
      'Um fim de semana que vale a pena partilhar';

  @override
  String get storiesPromptFirstHello => 'Um primeiro olá de que eu ia gostar';

  @override
  String get storiesPromptLearning => 'Algo que estou a aprender, só para mim';

  @override
  String get storiesPromptCare => 'Uma pequena forma de mostrar que me importo';

  @override
  String get storiesScreenTitle => 'Um pouco mais de ti';

  @override
  String get storiesSignIn => 'Inicia sessão para editar as tuas histórias.';

  @override
  String get storiesLoadFailed =>
      'Não foi possível carregar as tuas histórias.';

  @override
  String get storiesTryAgain => 'Tentar novamente';

  @override
  String get storiesIncomplete =>
      'Adiciona texto a cada história e uma descrição a cada foto, ou remove a história por terminar.';

  @override
  String get storiesPublished => 'As histórias do teu perfil foram publicadas.';

  @override
  String get storiesSavedPrivately =>
      'Guardado em privado. As tuas histórias estão ocultas para os outros membros.';

  @override
  String get storiesSaveUnconfirmed =>
      'Não conseguimos confirmar a gravação. As tuas alterações continuam aqui; recarrega as histórias guardadas para verificar.';

  @override
  String get storiesHeadline =>
      'Deixa alguém conhecer\no teu eu de todos os dias.';

  @override
  String get storiesIntro =>
      'Um pequeno ritual, a história por trás de uma foto, um primeiro olá de que ias gostar. Partilha até três momentos, por palavras tuas.';

  @override
  String get storiesOptionalNote =>
      'Opcional, sem pontuação nem obrigação de completar. Evita dados de contacto ou localizações exatas que não queiras partilhar.';

  @override
  String get storiesPublishSwitch => 'Mostrar estas histórias no meu perfil';

  @override
  String get storiesPublishSwitchHint =>
      'Começa desativado. Visível para membros elegíveis quando o teu perfil está publicado e disponível. Podes ocultá-las a qualquer momento.';

  @override
  String get storiesBackToEditing => 'Voltar à edição';

  @override
  String get storiesPreview => 'Pré-visualizar as minhas histórias';

  @override
  String get storiesPreviewBanner => 'PRÉ-VISUALIZAÇÃO · NÃO É PUBLICADA';

  @override
  String get storiesAdd => 'Adicionar uma história';

  @override
  String get storiesReloadDiscard =>
      'Recarregar histórias guardadas · descartar alterações';

  @override
  String get storiesSaving => 'A guardar…';

  @override
  String get storiesPublishButton => 'Publicar histórias';

  @override
  String get storiesSavePrivatelyButton => 'Guardar em privado';

  @override
  String get storiesPolicyNote =>
      'As fotos vêm da galeria aprovada do teu perfil. As histórias e fotos continuam sujeitas a denúncias dos membros e às políticas de segurança.';

  @override
  String storiesMomentLabel(int number) {
    return 'MOMENTO $number';
  }

  @override
  String storiesRemoveTooltip(int number) {
    return 'Remover a história $number';
  }

  @override
  String get storiesPromptLabel => 'Um ponto de partida';

  @override
  String get storiesTextLabel => 'Por palavras tuas';

  @override
  String get storiesTextHint => 'Um detalhe verdadeiro torna-a tua.';

  @override
  String get storiesTextRequired =>
      'Adiciona algumas palavras ou remove esta história.';

  @override
  String get storiesPhotoLabel => 'Uma foto, se quiseres';

  @override
  String get storiesWordsOnly => 'Só texto';

  @override
  String storiesProfilePhoto(int number) {
    return 'Foto de perfil $number';
  }

  @override
  String get storiesPhotoDescriptionLabel => 'Descreve esta foto';

  @override
  String get storiesPhotoDescriptionHelper =>
      'Ajuda quem usa leitores de ecrã.';

  @override
  String get storiesPhotoDescriptionRequired =>
      'Adiciona uma breve descrição da foto.';

  @override
  String get storiesPhotoSemantics => 'Foto de uma história do perfil';

  @override
  String get storiesSectionTitle => 'Um pouco mais de mim';

  @override
  String get storiesRetryLoad => 'Tentar carregar as histórias novamente';

  @override
  String get authErrorSessionExpired =>
      'A tua sessão terminou. Inicia sessão novamente.';

  @override
  String get authErrorSignInFailed =>
      'Não foi possível iniciar sessão. Tenta novamente.';

  @override
  String get authErrorCreateAccountFailed =>
      'Não foi possível criar a conta. Tenta novamente.';

  @override
  String get authErrorCreateAccountGeneric => 'Não foi possível criar a conta.';

  @override
  String get authErrorInvalidCredentials =>
      'Nome de utilizador ou palavra-passe inválidos.';

  @override
  String get authErrorUsernameFormat =>
      'O nome de utilizador deve ter 3–30 caracteres: letras, números, _ ou .';

  @override
  String get authErrorPasswordFormat =>
      'A palavra-passe deve ter 8–72 bytes, com letras e números.';

  @override
  String get authWelcomeIntroducerLink =>
      'Só estou aqui para apresentar amigos';

  @override
  String get signupBackTooltip => 'Voltar';

  @override
  String get signupIntroducerTitle => 'Sê o amigo que aproxima as pessoas.';

  @override
  String get signupIntroducerBody =>
      'Uma conta só para amigos. Sem perfil de encontros, fotos ou swipes. A tua idade fica privada; o Connect é para adultos dos 18 aos 80 anos.';

  @override
  String get signupTitle => 'Cria a tua conta';

  @override
  String get signupSubtitle =>
      'Escolhe um nome de utilizador único e uma palavra-passe segura';

  @override
  String get signupUsernameLabel => 'Nome de utilizador único';

  @override
  String get signupUsernameHint => 'o_teu_utilizador';

  @override
  String get signupUsernameHelp =>
      '3–30 caracteres. Letras, números, sublinhado e ponto.';

  @override
  String get signupPasswordLabel => 'Palavra-passe';

  @override
  String get signupPasswordHint => 'Pelo menos 8 caracteres';

  @override
  String get signupConfirmPasswordHint => 'Confirma a palavra-passe';

  @override
  String get signupNameLabel => 'Nome completo';

  @override
  String get signupNameHint => 'O teu nome';

  @override
  String get signupDobLabel => 'Data de nascimento';

  @override
  String get signupDobPickerHelp => 'Seleciona a data de nascimento';

  @override
  String get signupDobPlaceholder => 'Selecionar data';

  @override
  String get signupGenderLabel => 'Identifico-me como';

  @override
  String get signupGenderMan => 'Homem';

  @override
  String get signupGenderWoman => 'Mulher';

  @override
  String get signupGenderOther => 'Outro';

  @override
  String get signupCreateFriendAccount => 'Criar conta de amigo';

  @override
  String get signupAlreadyHaveAccount => 'Já tens conta?';

  @override
  String get signupErrorPasswordMismatch => 'As palavras-passe não coincidem.';

  @override
  String get signupErrorFullName => 'Escreve o teu nome completo.';

  @override
  String get signupErrorDobMissing => 'Seleciona a tua data de nascimento.';

  @override
  String get signupErrorUnderage => 'Tens de ter pelo menos 18 anos.';

  @override
  String get signupErrorAgeRange =>
      'De momento, o Connect está disponível para membros dos 18 aos 80 anos.';

  @override
  String get signupErrorGenderMissing => 'Escolhe como te identificas.';

  @override
  String get authRecoveryEnterUsername => 'Escreve o teu nome de utilizador.';

  @override
  String get authRecoveryEnterCode => 'Escreve o teu código de recuperação.';

  @override
  String get authRecoveryPasswordRule =>
      'Usa 8–72 caracteres, com pelo menos uma letra e um número.';

  @override
  String get authRecoveryResetDone =>
      'A tua palavra-passe foi reposta e todos os dispositivos terminaram sessão. Inicia sessão com a nova palavra-passe.';

  @override
  String get authRecoveryAssistanceDone =>
      'Se este nome de utilizador pertencer a uma conta Connect, a nossa equipa de segurança vai analisar o pedido.';

  @override
  String get authRecoveryInvalidCode =>
      'Esse código de recuperação não é válido ou expirou.';

  @override
  String get authRecoveryOffline =>
      'Não foi possível contactar o Connect. Verifica a tua ligação e tenta novamente.';

  @override
  String get authRecoverySendFailed =>
      'Não foi possível enviar o teu pedido. Verifica a tua ligação e tenta novamente.';

  @override
  String get authRecoveryBackToSignIn => 'Voltar ao início de sessão';

  @override
  String get authRecoveryHaveCode => 'Tenho o meu código';

  @override
  String get authRecoveryLostCode => 'Perdi o meu código';

  @override
  String get authRecoveryHaveCodeIntro =>
      'Usa o código de recuperação que guardaste quando criaste a conta, ou um emitido pela nossa equipa de segurança.';

  @override
  String get authRecoveryLostCodeIntro =>
      'Diz-nos o teu nome de utilizador. Vamos confirmar a tua identidade antes de emitir um código de recuperação. Nunca pedimos a tua palavra-passe.';

  @override
  String get authRecoveryUsernameLabel => 'Nome de utilizador';

  @override
  String get authRecoveryCodeLabel => 'Código de recuperação';

  @override
  String get authRecoveryNewPasswordLabel => 'Nova palavra-passe';

  @override
  String get authRecoveryMessageLabel => 'Algo que nos ajude (opcional)';

  @override
  String get authRecoveryMessageHint =>
      'Por exemplo, quando iniciaste sessão pela última vez';

  @override
  String get authRecoverySending => 'A enviar…';

  @override
  String get authRecoveryResetPassword => 'Repor palavra-passe';

  @override
  String get authRecoveryAskForHelp => 'Pedir ajuda';

  @override
  String get authTermsTitle => 'Termos e condições';

  @override
  String get authTermsSubtitle =>
      'Uma revisão rápida antes de entrares na app.';

  @override
  String get authTermsIntro =>
      'Lê e aceita os nossos Termos e a Política de Privacidade para continuar.';

  @override
  String get authTermsCommunityTitle => 'Regras da comunidade';

  @override
  String get authTermsPointRespect => 'Sê respeitoso e autêntico.';

  @override
  String get authTermsPointNoHarassment =>
      'Nada de assédio nem comportamentos fraudulentos.';

  @override
  String get authTermsPointPrivacy =>
      'Controlas as tuas definições de privacidade e a visibilidade do teu perfil.';

  @override
  String get authTermsPointReports =>
      'As denúncias são analisadas para manter a comunidade segura.';

  @override
  String get authTermsPointViolations =>
      'As infrações podem levar à suspensão ou remoção da conta.';

  @override
  String get authTermsReviewLater =>
      'Podes rever os detalhes completos mais tarde nas definições, mas tens de os aceitar antes de usar a app.';

  @override
  String get authTermsAgreeCheckbox =>
      'Aceito os Termos e a Política de Privacidade';

  @override
  String get authTermsAcceptButton => 'Aceitar e continuar';

  @override
  String get authTermsSaveFailed =>
      'Não foi possível guardar a tua aceitação. Verifica a ligação e tenta novamente.';

  @override
  String discoverSuperLikeSent(String name) {
    return 'Super like enviado a $name';
  }

  @override
  String get discoverMatchPlaceholderMessage => 'Diz olá';

  @override
  String discoverChatNeedsMatch(String name) {
    return 'Podes conversar com $name quando houver um match a sério.';
  }

  @override
  String get discoverDailyLimitTitle => 'Já usaste os gostos de hoje';

  @override
  String get discoverDailyLimitBody =>
      'Volta amanhã ou faz upgrade para teres mais gostos todos os dias.';

  @override
  String discoverDailyLimitResetBody(String reset) {
    return '$reset. Faz upgrade para teres mais gostos todos os dias.';
  }

  @override
  String get discoverSeePlans => 'Ver planos';

  @override
  String get discoverNotNow => 'Agora não';

  @override
  String get discoverBackToToday => 'Voltar a Hoje';

  @override
  String get discoverExploreTitle => 'Explorar';

  @override
  String get discoverSpotlightReviewed => 'Destaques vistos!';

  @override
  String get discoverAllReviewed => 'Tudo visto!';

  @override
  String get discoverCuratedForYou => 'Escolhidos para ti';

  @override
  String get discoverTitle => 'Descobre matches';

  @override
  String get discoverTagline => 'Um pouco de curiosidade. Uma ligação a sério.';

  @override
  String get discoverMessages => 'Mensagens';

  @override
  String get discoverFilters => 'Filtros';

  @override
  String get discoverYourDeck => 'O teu baralho';

  @override
  String get discoverStatReady => 'Prontos';

  @override
  String get discoverStatLiked => 'Gostos';

  @override
  String get discoverStatPassed => 'Passados';

  @override
  String get discoverEdit => 'Editar';

  @override
  String get discoverShowingEveryone =>
      'A mostrar todas as pessoas nas tuas preferências.';

  @override
  String get discoverToday => 'Hoje';

  @override
  String get discoverTodaySubtitle =>
      'Cinco sugestões, renovadas todos os dias.';

  @override
  String get discoverViewAll => 'Ver tudo';

  @override
  String get discoverMatchOnYourTerms => 'Faz match à tua maneira';

  @override
  String get discoverMatchOnYourTermsBody =>
      'Um match nasce do interesse mútuo. Podes bloquear ou denunciar qualquer pessoa a partir do perfil ou da conversa.';

  @override
  String get discoverErrorEyebrow => 'Ligação em pausa';

  @override
  String get discoverErrorTitle => 'Não foi possível carregar os perfis';

  @override
  String discoverTrustFilteredBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Os filtros de confiança ocultaram $count perfis. Experimenta aliviá-los ou atualiza para refazer o teu baralho.',
      one:
          'Os filtros de confiança ocultaram $count perfil. Experimenta aliviá-los ou atualiza para refazer o teu baralho.',
    );
    return '$_temp0';
  }

  @override
  String get discoverDeckPreparingBody =>
      'O teu baralho está a ser preparado. Atualiza para ver novos perfis verificados perto de ti.';

  @override
  String get discoverCheckBackSoon => 'Volta em breve';

  @override
  String get discoverNoSpotlightProfiles => 'Sem perfis em destaque';

  @override
  String get discoverNoProfiles => 'Sem perfis';

  @override
  String get discoverRefresh => 'Atualizar';

  @override
  String get discoverPromisePrivate => 'Privado';

  @override
  String get discoverPremium => 'Premium';

  @override
  String discoverNotificationsUnread(int count) {
    return 'Notificações, $count por ler';
  }

  @override
  String get discoverLatestUnreadNotifications =>
      'Notificações por ler mais recentes';

  @override
  String get discoverNoUnreadNotifications => 'Sem notificações por ler';

  @override
  String get discoverNotificationWhoReplied => 'Quem me respondeu';

  @override
  String discoverNotificationRepliesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count novas respostas',
      one: '1 nova resposta',
    );
    return '$_temp0';
  }

  @override
  String get discoverNotificationWhoLiked => 'Quem gostou de mim';

  @override
  String discoverNotificationLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count novos gostos',
      one: '1 novo gosto',
    );
    return '$_temp0';
  }

  @override
  String get discoverViewMore => 'Ver mais';

  @override
  String get discoverFitsYourWeek => 'Encaixa na tua semana';

  @override
  String discoverTodayPicks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sugestões',
      one: '1 sugestão',
    );
    return '$_temp0';
  }

  @override
  String get discoverPickedForYouToday => 'Escolhido para ti hoje.';

  @override
  String get discoverErrorLoginToDiscover =>
      'Inicia sessão para descobrir perfis.';

  @override
  String get discoverErrorLoadProfiles =>
      'Não foi possível carregar os perfis. Tenta outra vez.';

  @override
  String get discoverErrorSessionUnavailable =>
      'Sessão indisponível. Inicia sessão novamente.';

  @override
  String get discoverErrorLikeRetry =>
      'Não é possível pôr gosto agora. Tenta outra vez.';

  @override
  String get discoverErrorLike => 'Não é possível pôr gosto agora.';

  @override
  String get discoverErrorPassRetry =>
      'Não é possível passar agora. Tenta outra vez.';

  @override
  String get discoverErrorLoadLikedMe =>
      'Não foi possível carregar quem gostou de ti. Tenta outra vez.';

  @override
  String get discoverErrorAnswerInFlight =>
      'A tua resposta já está a ser enviada.';

  @override
  String get discoverErrorAnswer =>
      'Não foi possível enviar a tua resposta. Tenta outra vez.';

  @override
  String get firstChapterTopicPace => 'Ritmo de comunicação';

  @override
  String get firstChapterTopicDates => 'Conforto nos encontros';

  @override
  String get firstChapterTopicLanguage => 'Línguas';

  @override
  String get firstChapterTopicFamily => 'Envolvimento da família';

  @override
  String get firstChapterInMyWords => 'Nas minhas palavras';

  @override
  String firstChapterComfortOriginal(String language) {
    return 'Original · $language';
  }

  @override
  String firstChapterComfortMemberTranslation(String language) {
    return 'Tradução feita pelo membro · $language';
  }

  @override
  String get firstChapterComfortReloadSaved => 'Recarregar a versão guardada';

  @override
  String get firstChapterComfortReloadCards => 'Recarregar os cartões';

  @override
  String get firstChapterComfortHeadline =>
      'As tuas palavras. Os teus limites.';

  @override
  String get firstChapterComfortIntro =>
      'Contexto opcional para as pessoas com quem fizeste match. Nada é deduzido das tuas origens. Escreve na língua que sentes como tua.';

  @override
  String get firstChapterComfortShareTitle =>
      'Partilhar estes cartões com os meus matches';

  @override
  String get firstChapterComfortShareSubtitle =>
      'Desligado, todos os cartões ficam privados.';

  @override
  String get firstChapterComfortRemoveFromDraft => 'Remover do rascunho';

  @override
  String get firstChapterComfortTopicLabel => 'Um pouco de contexto sobre';

  @override
  String get firstChapterComfortOriginalLanguage => 'Língua original';

  @override
  String get firstChapterComfortOwnWords => 'Nas tuas próprias palavras';

  @override
  String get firstChapterComfortOwnWordsHint =>
      'Por exemplo: gosto de encontros durante o dia e de algum tempo para me sentir à vontade.';

  @override
  String get firstChapterComfortTranslation => 'A tua tradução (opcional)';

  @override
  String get firstChapterComfortTranslationLanguage =>
      'Língua da tradução (se adicionada)';

  @override
  String get firstChapterComfortTranslationNote =>
      'As traduções são assinaladas como feitas pelo membro. As tuas palavras originais são sempre preservadas.';

  @override
  String get firstChapterComfortAddCard =>
      'Adicionar / substituir este cartão no rascunho';

  @override
  String get firstChapterComfortMissingFields =>
      'Adiciona as tuas palavras e a língua. Uma tradução também precisa da sua língua.';

  @override
  String get firstChapterComfortUnaddedCard =>
      'Adiciona o cartão que escreveste ao rascunho antes de guardar.';

  @override
  String get firstChapterComfortSaveFailed =>
      'O teu rascunho continua aqui. Recarrega para verificar a última versão guardada antes de tentar de novo.';

  @override
  String get firstChapterSaving => 'A guardar…';

  @override
  String get firstChapterComfortSave => 'Guardar as minhas escolhas';

  @override
  String get firstChapterYourMatch => 'o teu match';

  @override
  String get firstChapterSaveUnconfirmed =>
      'Não conseguimos confirmar que foi guardado. Atualiza para verificar antes de tentar de novo.';

  @override
  String get firstChapterJointPreviewTitle => 'Uma história que ambos aprovam';

  @override
  String get firstChapterSoloPreviewTitle =>
      'Pré-visualizar o teu capítulo público';

  @override
  String firstChapterThenSurprise(String surprise) {
    return 'Depois… $surprise';
  }

  @override
  String get firstChapterJointPreviewBody =>
      'A tua aprovação é metade. A ligação só funciona depois de a outra pessoa aprovar também exatamente este cartão. Qualquer um de vocês a pode revogar.';

  @override
  String get firstChapterSoloPreviewBody =>
      'Só esta cena e o início que escolheste são públicos. Sem nomes, fotos, conversa privada, localização ou contributo da outra pessoa. Podes revogar a ligação.';

  @override
  String get firstChapterKeepPrivate => 'Manter privado';

  @override
  String get firstChapterApproveMyHalf => 'Aprovar a minha metade';

  @override
  String get firstChapterCreateShareLink => 'Criar ligação para partilhar';

  @override
  String get firstChapterStudioTitle => 'Estúdio Primeiro Capítulo';

  @override
  String get firstChapterRefresh => 'Atualizar capítulo';

  @override
  String get firstChapterHeroEyebrow => 'UMA PEQUENA AVENTURA. DOIS AUTORES.';

  @override
  String get firstChapterHeroTitle => 'O que acontece\na seguir é vosso.';

  @override
  String get firstChapterHeroSolo =>
      'Cria uma cena. Passa-a a um amigo. Ou cria um primeiro capítulo com alguém com quem fizeste match.';

  @override
  String firstChapterHeroPair(String name) {
    return 'Tu e $name. Um início, uma reviravolta inesperada e uma história que podem tornar real.';
  }

  @override
  String get firstChapterHeroPace =>
      'Opcional, ao teu ritmo. Conversar é sempre uma escolha.';

  @override
  String get firstChapterLoadFailed =>
      'Não foi possível carregar o teu capítulo.';

  @override
  String get firstChapterTryAgain => 'Tentar de novo';

  @override
  String get firstChapterStepChooseScene => '01 / Escolhe a tua cena';

  @override
  String get firstChapterStepWriteBeginning => '02 / Escreve o início';

  @override
  String get firstChapterStartOurChapter => 'Começar o nosso capítulo';

  @override
  String get firstChapterPassTheChapter => 'Passar o capítulo';

  @override
  String get firstChapterYourFirstChapter => 'O vosso primeiro capítulo';

  @override
  String get firstChapterItBeginsWith => 'COMEÇA COM';

  @override
  String get firstChapterAndThen => 'E DEPOIS…';

  @override
  String firstChapterDateIdeaNote(String beginning, String surprise) {
    return '$beginning. Depois $surprise.';
  }

  @override
  String get firstChapterMakeDateIdea =>
      'Transformar isto numa ideia de encontro';

  @override
  String get firstChapterDateIdeaHint =>
      'Uma sugestão para moldarem juntos. Nenhum encontro é marcado ou aceite automaticamente.';

  @override
  String get firstChapterYourTurn => 'É a tua vez: adiciona uma surpresa.';

  @override
  String get firstChapterBeginningSaved =>
      'O teu início está guardado. O teu match pode adicionar uma surpresa quando quiser. Podem continuar a conversar.';

  @override
  String get firstChapterClose => 'Fechar este capítulo';

  @override
  String get firstChapterGiveBackTitle => 'Histórias que inspiram';

  @override
  String get firstChapterGiveBackBody =>
      'A vossa ligação pode inspirar um novo começo. Partilhem só esta ideia de encontro anónima, com a aprovação de ambos.';

  @override
  String get firstChapterPreviewAnonymous =>
      'Pré-visualizar a nossa história anónima';

  @override
  String get firstChapterGreenLightTitle => 'Uma luz verde privada';

  @override
  String get firstChapterInTheirWords => 'Nas palavras dele ou dela';

  @override
  String get firstChapterMakeRoomTitle =>
      'Abre espaço para o que importa para ti';

  @override
  String get firstChapterMakeRoomSubtitle =>
      'O teu ritmo, línguas, encontros e expectativas da família. As tuas palavras, partilhadas só quando decidires.';

  @override
  String get firstChapterCreateWithConnection => 'Criar com uma ligação';

  @override
  String get firstChapterCreateTogether => 'Criar juntos um primeiro capítulo';

  @override
  String get firstChapterMatchesAppearHere =>
      'Os teus matches mútuos aparecem aqui. Já podes experimentar e partilhar uma cena sozinho.';

  @override
  String get firstChapterSharedChapters => 'Os teus capítulos partilhados';

  @override
  String get firstChapterReloadShared => 'Recarregar capítulos partilhados';

  @override
  String get firstChapterNothingPublic =>
      'Nada é público até decidires partilhar.';

  @override
  String get firstChapterGreenChat => 'Continuar a conversar';

  @override
  String get firstChapterGreenCall => 'Experimentar uma chamada';

  @override
  String get firstChapterGreenDate => 'Sugerir um encontro';

  @override
  String get firstChapterGreenLightIntro =>
      'Só uma escolha em comum é revelada. Ninguém vê um pedido sem resposta. As escolhas expiram após sete dias; limpa-as para as retirar.';

  @override
  String get firstChapterSavePrivately => 'Guardar em privado';

  @override
  String get firstChapterGreenLightNone =>
      'Qualquer próximo passo em comum aparecerá aqui.';

  @override
  String firstChapterGreenLightMutual(String choices) {
    return 'Ambos se sentem à vontade com: $choices';
  }

  @override
  String get firstChapterGreenLightNote =>
      'Uma luz verde é permissão para sugerir. Uma chamada ou encontro continuam a precisar de um acordo à parte.';

  @override
  String get firstChapterLinkRevoked => 'Ligação revogada';

  @override
  String get firstChapterPublicScene => 'Cena pública e anónima';

  @override
  String get firstChapterPrivateUntilBoth => 'Privado até ambos aprovarem';

  @override
  String get firstChapterLinkCopied =>
      'Ligação do capítulo copiada. Partilha-a onde quiseres.';

  @override
  String get firstChapterCopyLink => 'Copiar ligação';

  @override
  String get firstChapterApproveStory => 'Aprovar exatamente esta história';

  @override
  String get firstChapterRevokeLink => 'Revogar ligação';

  @override
  String networkSlowResponse(int mbps) {
    return 'Rede fraca detetada. Usa pelo menos $mbps Mbps para conversas, presentes e gestos mais fluidos.';
  }

  @override
  String get networkOffline =>
      'Sem ligação de rede estável. Volta a ligar-te para continuar a usar a app.';

  @override
  String networkWeak(int mbps) {
    return 'A rede está fraca. Usa pelo menos $mbps Mbps para uma experiência mais fluida.';
  }

  @override
  String get networkCannotReachService =>
      'Não é possível contactar o serviço local. Verifica se a API está a correr.';

  @override
  String get gateCheckingTerms => 'A verificar os termos…';

  @override
  String get gateLoadingProfile => 'A carregar o teu perfil…';

  @override
  String get gateConnectionIssue => 'Problema de ligação';

  @override
  String get safetyReportFailed => 'Não foi possível denunciar o utilizador';

  @override
  String get safetyBlockFailed => 'Não foi possível bloquear o utilizador';

  @override
  String get safetyUnblockFailed => 'Não foi possível desbloquear o utilizador';

  @override
  String get safetyNotAuthenticated => 'Sessão não iniciada';

  @override
  String get timeAgoJustNow => 'Agora mesmo';

  @override
  String timeAgoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count minutos',
      one: 'há 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count horas',
      one: 'há 1 hora',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count dias',
      one: 'há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String timeAgoWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count semanas',
      one: 'há 1 semana',
    );
    return '$_temp0';
  }

  @override
  String get themePreviewBarrier => 'Pré-visualização do tema';

  @override
  String get themeNowShowing => 'EM EXIBIÇÃO';

  @override
  String get themeTaglineRealLife => 'Marfim quente, verde-floresta e alperce.';

  @override
  String get themeTaglineRealLifeNight =>
      'Verde-floresta, menta suave e luz de velas.';

  @override
  String get themeTaglineDaylight =>
      'Creme, tinta e um toque de framboesa, como o site.';

  @override
  String get themeTaglineEmber =>
      'Noite negro-ameixa com brasas e brilho violeta.';

  @override
  String get themeTaglineForge =>
      'Vermelho fornalha, azul-aço, cromado grafite.';

  @override
  String get themeTaglineNeongrid =>
      'Vidro negro, linhas de luz ciano, pulsação âmbar.';

  @override
  String get themeTaglineCrimsonalloy =>
      'Laca carmesim, ouro fundido, grená da meia-noite.';

  @override
  String get themeTaglineCircuit =>
      'Verde circuito, violeta sinal, preto carbono.';

  @override
  String get themeTaglineDeepfield =>
      'Espaço profundo, azul plasma e um clarão de ouro estelar.';

  @override
  String get themeTaglineLove => 'Rosa-pálido, rosa e um pouco de dourado.';

  @override
  String get themeTaglineRose =>
      'Vinho aveludado, vermelho-rosa e um pouco de dourado.';

  @override
  String get themeTaglinePetal =>
      'Papel rosado, pétalas a esvoaçar, um toque de salva.';

  @override
  String get themeTaglineSnow =>
      'Neve fresca, vidro fosco e uma fita de aurora.';

  @override
  String get themeTaglineGothic =>
      'Rendilhado ao luar, granada, fumo de vela e ouro antigo.';

  @override
  String get themeTaglineCalm =>
      'Pouca estimulação, alto contraste. Fundo imóvel, sem movimento.';

  @override
  String get themeLooksTodayDescription =>
      'De dia, marfim quente e verde-floresta. À noite, menta suave e floresta profunda.';

  @override
  String get settingsEyebrow => 'DEFINIÇÕES';

  @override
  String get settingsHeaderSubtitle =>
      'O teu visual, a tua privacidade e a tua conta.';

  @override
  String get settingsThemeSection => 'Tema';

  @override
  String get settingsThemeSectionTitle => 'Torna-o teu';

  @override
  String get settingsThemeSectionCaption =>
      'Cada ecrã segue o visual que escolheres.';

  @override
  String get settingsSectionYourStory => 'A tua história';

  @override
  String get settingsDatingRhythmTitle => 'O teu ritmo de encontros';

  @override
  String get settingsDatingRhythmSubtitle =>
      'Intenção, ritmo, disponibilidade e privacidade das apresentações';

  @override
  String get settingsProfileStoriesTitle => 'As histórias do teu perfil';

  @override
  String get settingsProfileStoriesSubtitle =>
      'Pequenos momentos, as tuas palavras, fotos opcionais';

  @override
  String get settingsBlogTitle => 'Blog · Capítulos abertos';

  @override
  String get settingsBlogSubtitle =>
      'O teu diário, as tuas fotos, o teu público';

  @override
  String get settingsLookPreviewEyebrow => 'HOJE';

  @override
  String get settingsLookPreviewHeadline => 'Algo real.';

  @override
  String get friendsEyebrow => 'AMIGOS';

  @override
  String get friendsTitle => 'A tua gente';

  @override
  String get friendsSubtitle =>
      'Os amigos podem trocar mensagens, fazer planos e criar grupos juntos. Os pedidos precisam do sim de ambos os lados.';

  @override
  String get friendsBack => 'Voltar';

  @override
  String get friendsAddFriend => 'Adicionar amigo';

  @override
  String get friendsCreateGroup => 'Criar um grupo';

  @override
  String get friendsSectionRequests => 'PEDIDOS';

  @override
  String get friendsRequestsWaitingOnOthers => 'À espera dos outros';

  @override
  String get friendsRequestsWaitingOnYou => 'À tua espera';

  @override
  String get friendsRequestsCaption =>
      'Nada é partilhado até ambos concordarem.';

  @override
  String get friendsSectionChats => 'CONVERSAS';

  @override
  String get friendsChatsTitle => 'Conversas';

  @override
  String get friendsSectionIntros => 'APRESENTAÇÕES';

  @override
  String get friendsIntrosTitle => 'Apresentações para ti';

  @override
  String get friendsSectionVouches => 'RECOMENDAÇÕES';

  @override
  String get friendsVouchesPendingTitle =>
      'Recomendações à espera da tua aprovação';

  @override
  String friendsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amigos',
      one: '1 amigo',
      zero: 'Ainda sem amigos',
    );
    return '$_temp0';
  }

  @override
  String get friendsIntroduce => 'Apresentar';

  @override
  String get friendsEmptyBody =>
      'Encontra pessoas que conheces pelo nome ou nome de utilizador, ou adiciona alguém a partir de um match, de uma sala ou de um grupo.';

  @override
  String get friendsSectionOnProfile => 'NO TEU PERFIL';

  @override
  String get friendsVouchesOnProfileTitle => 'Recomendações no teu perfil';

  @override
  String friendsQuoted(String text) {
    return '«$text»';
  }

  @override
  String friendsVouchedForYou(String name) {
    return '$name recomendou-te';
  }

  @override
  String get friendsHideFromProfile => 'Ocultar do perfil';

  @override
  String get friendsSectionMore => 'MAIS';

  @override
  String get friendsMoreTitle => 'Planos e apresentações';

  @override
  String get friendsPlansLinkTitle => 'Planos de encontros partilhados contigo';

  @override
  String get friendsPlansLinkSubtitle =>
      'Os amigos avisam-te quando planeiam um encontro e quando dão notícias depois.';

  @override
  String get friendsInviteIntroducerTitle =>
      'Convida um amigo que não anda à procura de par';

  @override
  String get friendsInviteIntroducerSubtitle =>
      'Escolhe quem te pode apresentar. Revê ou retira a autorização quando quiseres.';

  @override
  String get friendsIntroTermsTitle => 'Apresentações, à tua maneira';

  @override
  String get friendsIntroTermsSubtitle =>
      'Escolhe se os amigos te podem apresentar e o que uma pré-visualização mostra.';

  @override
  String get friendsSectionActivity => 'ATIVIDADE';

  @override
  String get friendsActivityTitle => 'Com os teus amigos';

  @override
  String friendsVouchSentSnack(String name) {
    return 'Recomendação enviada. $name aprova-a antes de aparecer.';
  }

  @override
  String friendsRemoveTitle(String name) {
    return 'Remover $name?';
  }

  @override
  String get friendsRemoveBody =>
      'Deixam de ser amigos e a vossa conversa fecha. A outra pessoa não é avisada.';

  @override
  String get friendsRemoveFriend => 'Remover amigo';

  @override
  String get friendsIntroMadeSnack =>
      'Apresentação feita. Os dois amigos vão receber notícias tuas.';

  @override
  String get friendsAddSheetLabel => 'ADICIONAR AMIGO';

  @override
  String get friendsAddSheetTitle => 'Encontra alguém que conheces';

  @override
  String get friendsAddSheetCaption =>
      'Pesquisa por nome ou @utilizador. A outra pessoa decide se aceita.';

  @override
  String get friendsSearchHiddenNote =>
      'Não apareces na pesquisa de amigos, por isso os outros não te encontram aqui. Altera isto em Privacidade e segurança.';

  @override
  String get friendsSearchLabel => 'Nome ou @utilizador';

  @override
  String get friendsSearchHelper => 'Escreve pelo menos 3 letras';

  @override
  String get friendsSearchFailed =>
      'A pesquisa não está disponível agora. Tenta de novo.';

  @override
  String friendsSearchNoResults(String query) {
    return 'Ninguém encontrado para «$query».';
  }

  @override
  String get friendsNewGroupLabel => 'NOVO GRUPO';

  @override
  String get friendsNewGroupTitle => 'Quem alinha?';

  @override
  String get friendsNewGroupCaption =>
      'Escolhe os amigos a convidar. Podes adicionar mais depois.';

  @override
  String get friendsChooseFriends => 'Escolhe amigos';

  @override
  String friendsCreateGroupWith(int count) {
    return 'Criar um grupo com $count';
  }

  @override
  String get friendsSourceMatch => 'Dos teus matches';

  @override
  String get friendsSourceProfile => 'Viu o teu perfil';

  @override
  String get friendsSourceRoom => 'Conheceram-se numa sala';

  @override
  String get friendsSourceGroup => 'De um grupo';

  @override
  String get friendsSourceSearch => 'Encontrou-te pelo nome';

  @override
  String get friendsWantsToBeFriends => 'Quer ser teu amigo';

  @override
  String get friendsRequestSent => 'Pedido enviado';

  @override
  String get friendsCancel => 'Cancelar';

  @override
  String get friendsDecline => 'Recusar';

  @override
  String get friendsAccept => 'Aceitar';

  @override
  String friendsMessageTooltip(String name) {
    return 'Enviar mensagem a $name';
  }

  @override
  String friendsMessageTooltipUnread(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enviar mensagem a $name, $count por ler',
      one: 'Enviar mensagem a $name, 1 por ler',
    );
    return '$_temp0';
  }

  @override
  String friendsMoreFor(String name) {
    return 'Mais opções para $name';
  }

  @override
  String get friendsMenuVouch => 'Recomendar';

  @override
  String get friendsMenuIntro => 'Apresentar a um amigo';

  @override
  String friendsChatSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conversa com $name, $count por ler',
      zero: 'Conversa com $name',
    );
    return '$_temp0';
  }

  @override
  String friendsChatSemanticsMuted(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conversa com $name, $count por ler, notificações silenciadas',
      zero: 'Conversa com $name, notificações silenciadas',
    );
    return '$_temp0';
  }

  @override
  String friendsIntroHeadline(String introducer, String person) {
    return '$introducer acha que devias conhecer $person';
  }

  @override
  String friendsIntroHeadlineSomeone(String introducer) {
    return '$introducer acha que devias conhecer alguém';
  }

  @override
  String friendsNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String get friendsIntroNoThanks => 'Não, obrigado';

  @override
  String get friendsIntroImIn => 'Alinho';

  @override
  String get friendsVouchKeepPrivate => 'Manter privado';

  @override
  String get friendsVouchShowOnProfile => 'Mostrar no meu perfil';

  @override
  String get memberProfileNoData => 'Não foram encontrados dados do perfil.';

  @override
  String get memberProfileSignInToView =>
      'Inicia sessão para veres o teu perfil.';

  @override
  String get memberProfileLoadFailed =>
      'Não foi possível carregar o perfil. Tenta novamente.';

  @override
  String get memberProfileConnectionsTitle => 'As tuas ligações';

  @override
  String get memberProfileConnectionsCaption =>
      'Pessoas de quem gostaste, os teus matches e com quem falas.';

  @override
  String get memberProfileStatLiked => 'Os teus likes';

  @override
  String get memberProfileStatMatches => 'Matches';

  @override
  String get memberProfileStatMessages => 'Mensagens';

  @override
  String memberProfileOpenStat(String label) {
    return 'Abrir $label';
  }

  @override
  String get memberProfileNoticedTitle => 'Quem reparou em ti';

  @override
  String get memberProfileNoticedCaption =>
      'Likes e visitas de membros perto de ti.';

  @override
  String get memberProfileWhoLikedMe => 'Quem gostou de mim';

  @override
  String memberProfileWhoLikedMeCount(int count) {
    return 'Quem gostou de mim ($count)';
  }

  @override
  String get memberProfileWhoLikedMeSubtitle =>
      'Membros que gostaram do teu perfil.';

  @override
  String get memberProfileWhoViewedTitle => 'Quem viu o meu perfil';

  @override
  String get memberProfileWhoViewedSubtitle =>
      'Visitas recentes ao teu perfil.';

  @override
  String get memberProfileWhoViewedTooltip => 'Quem viu o meu perfil';

  @override
  String get memberProfileRefreshTooltip => 'Atualizar perfil';

  @override
  String get memberProfilePreferencesTitle => 'As tuas preferências';

  @override
  String get memberProfilePrefSeeking => 'Procuro';

  @override
  String get memberProfilePrefDistance => 'Distância';

  @override
  String memberProfileWithinKm(int km) {
    return 'Até $km km';
  }

  @override
  String get profileViewersTitle => 'Viram o meu perfil';

  @override
  String get profileViewersLoadFailed =>
      'Não foi possível carregar as visitas ao perfil.';

  @override
  String get profileViewersEmpty => 'Ainda ninguém viu o teu perfil.';

  @override
  String get profileViewersViewedRecently => 'Visto recentemente';

  @override
  String profileViewersViewedAt(String time) {
    return 'Visto em $time';
  }

  @override
  String get profileMasterReligionParsi => 'Parsi';

  @override
  String get profileMasterReligionBahai => 'Bahá’í';

  @override
  String get profileMasterReligionTribal => 'Tribal / Indígena';

  @override
  String get profileMasterWorkout1to2 => '1-2 vezes por semana';

  @override
  String get profileMasterWorkout3to4 => '3-4 vezes por semana';

  @override
  String get profileMasterWorkout5Plus => '5+ vezes por semana';

  @override
  String get profileMasterWorkoutDaily => 'Todos os dias';

  @override
  String get profileMasterDietNoPreference => 'Sem preferência';

  @override
  String get profileMasterDietVegetarian => 'Vegetariano';

  @override
  String get profileMasterDietEggetarian => 'Vegetariano com ovos';

  @override
  String get profileMasterDietNonVegetarian => 'Não vegetariano';

  @override
  String get profileMasterDietVegan => 'Vegano';

  @override
  String get profileMasterDietJain => 'Dieta jainista';

  @override
  String get profileMasterDietTypeBalanced => 'Equilibrada';

  @override
  String get profileMasterDietTypeHighProtein => 'Rica em proteína';

  @override
  String get profileMasterDietTypeLowCarb => 'Baixa em hidratos';

  @override
  String get profileMasterDietTypeKeto => 'Cetogénica';

  @override
  String get profileMasterDietTypeMediterranean => 'Mediterrânica';

  @override
  String get profileMasterDietTypeIntermittentFasting => 'Jejum intermitente';

  @override
  String get profileMasterSleepEarlyBird => 'Madrugador';

  @override
  String get profileMasterSleepNightOwl => 'Noctívago';

  @override
  String get profileMasterSleepFlexible => 'Flexível';

  @override
  String get profileMasterSleepShiftBased => 'Por turnos';

  @override
  String get profileMasterTravelHomebody => 'Caseiro';

  @override
  String get profileMasterTravelOccasional => 'Viajante ocasional';

  @override
  String get profileMasterTravelFrequent => 'Viajante frequente';

  @override
  String get profileMasterTravelAdventure => 'Aventureiro';

  @override
  String get profileMasterTravelLuxury => 'Viagens de luxo';

  @override
  String get profileMasterTravelBackpacker => 'Mochileiro';

  @override
  String get profileMasterPoliticsSimilar => 'Só opiniões semelhantes';

  @override
  String get profileMasterPoliticsOpen => 'Aberto a diferenças';

  @override
  String get profileMasterPoliticsNotDiscuss => 'Prefiro não falar disso';

  @override
  String get profileMasterPoliticsNoStrong => 'Sem preferência marcada';

  @override
  String get profileMasterIntentLongTerm => 'Relação duradoura';

  @override
  String get profileMasterIntentMarriage => 'Casamento';

  @override
  String get profileMasterIntentNewFriends => 'Novos amigos';

  @override
  String get chatBackToConversations => 'Voltar às conversas';

  @override
  String get chatOfflineBanner =>
      'Você está offline. Seu rascunho fica aqui enquanto a conexão volta.';

  @override
  String get chatVoiceHello => 'Compartilhe um olá de voz · leia e ouça';

  @override
  String get chatLoadFailedTitle => 'Vamos reconectar.';

  @override
  String get chatLoadFailedBody =>
      'Não foi possível carregar sua conversa. Tente novamente.';

  @override
  String get chatConversationEnded => 'Esta conversa foi encerrada.';

  @override
  String get chatUnlockStepRequired =>
      'Conclua a etapa de desbloqueio atual para continuar esta conversa.';

  @override
  String get chatGiftTrayTitle => 'Um mimo para essa pessoa';

  @override
  String get chatCloseGifts => 'Fechar presentes';

  @override
  String get chatAllGifts => 'Todos os presentes';

  @override
  String get chatNoGiftsInCollection =>
      'Nenhum presente disponível nesta coleção.';

  @override
  String get chatAddCoins => 'Adicionar moedas';

  @override
  String get chatFreeGiftDaily => 'Grátis · 1 por dia';

  @override
  String chatCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moedas',
      one: '1 moeda',
    );
    return '$_temp0';
  }

  @override
  String get chatSendingGift => 'Enviando seu presente…';

  @override
  String get chatOfflineGifts =>
      'Você está offline. Dá para ver os presentes e enviar quando a conexão voltar.';

  @override
  String chatGiftConfirmTitle(String gift, String name) {
    return 'Enviar $gift para $name?';
  }

  @override
  String chatGiftNoteQuote(String note) {
    return '“$note”';
  }

  @override
  String chatGiftBalanceAfter(int balance, int remaining) {
    return '·  $balance → restarão $remaining';
  }

  @override
  String get chatGiftNoObligation =>
      'Um presente é um gesto, nunca uma obrigação de responder ou de se encontrar.';

  @override
  String chatGiftSendFor(String price) {
    return 'Enviar por $price';
  }

  @override
  String get chatNotNow => 'Agora não';

  @override
  String get chatDeleteMessageTitle => 'Apagar a mensagem?';

  @override
  String get chatDeleteMessageBody =>
      'Isso remove a mensagem das conversas de vocês dois.';

  @override
  String get chatDeleteForEveryone => 'Apagar para todos';

  @override
  String get chatMessageDeletedSnack => 'Mensagem apagada.';

  @override
  String get chatUndo => 'Desfazer';

  @override
  String get chatDeleteUndone => 'Exclusão desfeita.';

  @override
  String chatGiftReceivedFrom(String name) {
    return 'Presente de $name';
  }

  @override
  String get chatGiftReceiverIntro => 'Você decide o que fica na sua conversa.';

  @override
  String get chatHideGift => 'Ocultar presente';

  @override
  String get chatHideGiftSubtitle => 'Remover só da sua conversa.';

  @override
  String get chatReportAndHide => 'Denunciar e ocultar';

  @override
  String get chatReportAndHideSubtitle =>
      'Enviar para a equipe de segurança e remover agora.';

  @override
  String get chatGiftHidden => 'Presente ocultado da sua conversa.';

  @override
  String get chatReportGiftTitle => 'Denunciar este presente';

  @override
  String get chatReportGiftIntro =>
      'Escolha um motivo. O presente será ocultado na hora.';

  @override
  String get chatReportReasonLabel => 'Motivo';

  @override
  String get chatReportReasonUnwanted => 'Presente indesejado';

  @override
  String get chatReportReasonHarassment => 'Assédio';

  @override
  String get chatReportReasonSexual => 'Conteúdo sexual';

  @override
  String get chatReportReasonScam => 'Golpe ou fraude';

  @override
  String get chatReportReasonOther => 'Outro motivo';

  @override
  String get chatReportDetailsLabel => 'Adicionar detalhes (opcional)';

  @override
  String get chatReportSubmit => 'Enviar denúncia e ocultar';

  @override
  String get chatGiftReported =>
      'Presente denunciado e ocultado. Nossa equipe de segurança vai analisar.';

  @override
  String get chatQuickEmojis => 'Emojis rápidos';

  @override
  String chatWalletTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moedas',
      one: '1 moeda',
    );
    return 'Sua carteira · $_temp0';
  }

  @override
  String get chatDailyLimitReached => 'Limite diário de mensagens atingido';

  @override
  String get chatDailyLimitFallback =>
      'Tente amanhã ou faça upgrade do seu plano.';

  @override
  String chatDailyLimitReset(String reset) {
    return '$reset · faça upgrade para ter mais.';
  }

  @override
  String get chatSeePlans => 'Ver planos';

  @override
  String chatQuotaOnPlan(String quota, String plan) {
    return '$quota no $plan';
  }

  @override
  String get chatYourConversation => 'A conversa de vocês';

  @override
  String get chatVerifiedHumans => 'Pessoas verificadas';

  @override
  String get chatVerifiedHumansShowsUp =>
      'Pessoas verificadas · Comparece aos encontros';

  @override
  String discoverLikedBack(String name) {
    return 'Retribuíste o gosto de $name';
  }

  @override
  String discoverPassedOn(String name) {
    return 'Passaste $name';
  }

  @override
  String get discoverLikedMeLoadFailedTitle =>
      'Não foi possível carregar os teus gostos';

  @override
  String get discoverLikedMeEmptyTitle => 'Ainda sem gostos novos';

  @override
  String get discoverLikedMeEmptyBody =>
      'Quando alguém gostar de ti, aparece aqui. Retribui o gosto e é match.';

  @override
  String get discoverLikedMeIntro =>
      'Estas pessoas já gostam de ti. Retribui para fazer match ou passa. Passar é privado.';

  @override
  String get discoverLikedMeTitle => 'Gostaram de ti';

  @override
  String discoverLikedMeTitleCount(int count) {
    return 'Gostaram de ti · $count';
  }

  @override
  String get discoverPass => 'Passar';

  @override
  String get discoverLikeBack => 'Retribuir';

  @override
  String get discoverLikedJustNow => 'Gostou de ti agora mesmo';

  @override
  String discoverLikedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gostou de ti há $count minutos',
      one: 'Gostou de ti há 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gostou de ti há $count horas',
      one: 'Gostou de ti há 1 hora',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gostou de ti há $count dias',
      one: 'Gostou de ti há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gostou de ti há $count semanas',
      one: 'Gostou de ti há 1 semana',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedOnDate(String date) {
    return 'Gostou de ti a $date';
  }

  @override
  String discoverLikedProfilesTitle(int count) {
    return 'Perfis de que gostaste ($count)';
  }

  @override
  String get discoverNoLikedProfiles => 'Ainda não gostaste de nenhum perfil';

  @override
  String get discoverLikedProfileFallback => 'Perfil de que gostaste';

  @override
  String get discoverPassedProfilesTitle => 'Perfis passados';

  @override
  String get discoverNoPassedProfiles => 'Ainda sem perfis passados';

  @override
  String get discoverSavedForLater => 'Guardado para mais tarde';

  @override
  String get discoverSpotlightFiltersTitle => 'Filtros de destaque';

  @override
  String get discoverVerifiedOnly => 'Só verificados';

  @override
  String discoverAgeRange(int min, int max) {
    return 'Faixa etária: $min - $max';
  }

  @override
  String get discoverSpotlightTitle => 'Matches em destaque';

  @override
  String get discoverSpotlightSubtitle => 'Ligações premium escolhidas';

  @override
  String discoverPassedCount(int count) {
    return 'Passados ($count)';
  }

  @override
  String get discoverOpenChatsFromDiscover =>
      'Abre as conversas a partir de Descobrir';

  @override
  String get discoverNoNewNotifications => 'Sem notificações novas';

  @override
  String get discoverNoSpotlightMatchFilters =>
      'Nenhum perfil em destaque corresponde aos filtros';

  @override
  String get discoverAllSpotlightReviewed =>
      'Viste todos os perfis em destaque!';

  @override
  String get discoverSpotlightCheckBackLater =>
      'Volta mais tarde para ver novos perfis em destaque';

  @override
  String get discoverReportSubmitted => 'Denúncia enviada.';

  @override
  String get discoverAppeal => 'Recorrer';

  @override
  String discoverAppealPrefill(String userId) {
    return 'Rever o resultado da moderação da denúncia sobre o utilizador $userId';
  }

  @override
  String get discoverProfileUnavailable =>
      'Este perfil não está disponível neste momento.';

  @override
  String get discoverGoBack => 'Voltar';

  @override
  String get discoverPremiumView => 'Vista premium';

  @override
  String get todayLabel => 'HOJE';

  @override
  String get todayRefreshTooltip => 'Atualizar Hoje';

  @override
  String get todayDiscoveryPreferences => 'Preferências de descoberta';

  @override
  String get todayHeroTitle => 'Um pequeno olá.\nEspaço para algo verdadeiro.';

  @override
  String get todayHeroSubtitle =>
      'Algumas apresentações pensadas, ao teu ritmo.';

  @override
  String get todaySectionPace => 'O TEU RITMO';

  @override
  String get todayPaceTitle => 'O que encaixa na tua semana?';

  @override
  String get todayPaceBody =>
      'O teu ritmo, o teu tipo de primeiro encontro, disponibilidade opcional.';

  @override
  String get todaySetRhythm => 'Define o teu ritmo';

  @override
  String get todaySectionStory => 'A TUA HISTÓRIA';

  @override
  String get todaySectionIntroductions => 'APRESENTAÇÕES DE HOJE';

  @override
  String get todayIntroductionsTitle => 'Algumas pessoas para conhecer';

  @override
  String get todayIntroductionsCaption =>
      'Os interesses em comum são um ponto de partida. A química, descobres tu.';

  @override
  String get todayPausedTitle => 'Tira o tempo de que precisas.';

  @override
  String get todayPausedBody =>
      'As apresentações estão em pausa. As tuas conversas continuam aqui.';

  @override
  String get todayManageRhythm => 'Gerir o teu ritmo';

  @override
  String get todayLoadingIntroductions => 'A carregar apresentações';

  @override
  String get todayFailedTitle =>
      'As tuas apresentações estão a demorar um pouco.';

  @override
  String get todayFailedBody =>
      'Não conseguimos carregar as informações mais recentes. Tenta novamente.';

  @override
  String get todayTryAgain => 'Tentar novamente';

  @override
  String get todayEmptyTitle => 'Um pequeno respiro.';

  @override
  String get todayEmptyBody =>
      'De momento não há novas apresentações para as tuas preferências. Podes ajustar o teu ritmo ou explorar perfis.';

  @override
  String get todayExploreProfiles => 'Explorar perfis';

  @override
  String get todayAllIntroductions => 'Todas as apresentações';

  @override
  String get todayBreatheTitle =>
      'Uma boa ligação precisa de espaço para respirar.';

  @override
  String get todayBreatheBody =>
      'Estas são as apresentações de hoje. Não há contagem decrescente nem necessidade de decidir sobre todos.';

  @override
  String get todayExploreMore => 'Explorar mais perfis';

  @override
  String get todayCommonGround => 'ALGO EM COMUM';

  @override
  String todayMeetName(String name) {
    return 'Conhecer $name';
  }

  @override
  String get todayFirstHelloCoffee =>
      'Um primeiro olá podia ser um café juntos.';

  @override
  String get todayFirstHelloWalk =>
      'Um primeiro olá podia ser um passeio de dia.';

  @override
  String get todayFirstHelloMeal =>
      'Um primeiro olá podia ser uma refeição descontraída.';

  @override
  String get todayFirstHelloVideoCall =>
      'Um primeiro olá podia ser uma videochamada.';

  @override
  String get todayFirstHelloEvent =>
      'Um primeiro olá podia ser um evento de que ambos gostem.';

  @override
  String get todayFirstHelloDrinks =>
      'Um primeiro olá podia ser uma bebida juntos.';

  @override
  String get todayFirstHelloOther =>
      'Um primeiro olá podia ser algo de que ambos gostem.';

  @override
  String get todaySectionTalk => 'ALGO DE QUE FALAR';

  @override
  String get todayTalkCaption =>
      'Histórias, clubes e sugestões que tornam um primeiro olá mais fácil.';

  @override
  String get todayBlogTitle => 'Blog · Capítulos abertos';

  @override
  String get todayBlogSubtitle =>
      'Lê as histórias dos membros e escreve as tuas.';

  @override
  String get todayBookClubsTitle => 'Clubes de leitura';

  @override
  String get todayBookClubsSubtitle =>
      'Um livro por semana, conversado em conjunto.';

  @override
  String get todayFilmClubsTitle => 'Cineclubes';

  @override
  String get todayFilmClubsSubtitle =>
      'Vê o filme escolhido e depois troquem opiniões.';

  @override
  String get todayPhotoThemesTitle => 'Temas de fotografia';

  @override
  String get todayPhotoThemesSubtitle => 'Uma foto por tema. Vê as de todos.';

  @override
  String get todayChapterStudioTitle => 'Estúdio Primeiro capítulo';

  @override
  String get todayChapterStudioSubtitle => 'Comecem uma história juntos.';

  @override
  String get todayCoverFallbackLine => 'Uma foto que os membros adoraram';

  @override
  String todayCoverSemantics(String name) {
    return 'Abrir a capa da semana de $name';
  }

  @override
  String get todayCoverTitle => 'CAPA DA SEMANA';

  @override
  String todayCoverBy(String name) {
    return 'DE $name';
  }

  @override
  String get todayLikes => 'Gostos';

  @override
  String get todayComments => 'Comentários';

  @override
  String get todayThisWeek => 'Esta semana';

  @override
  String get todayWallLabel => 'DA COMUNIDADE';

  @override
  String get todayWallTitle => 'O mural de hoje';

  @override
  String get todayWallCaption =>
      'Histórias e fotos que os membros adoraram — uma nova seleção todos os dias';

  @override
  String get todayWallPrevious => 'Anterior';

  @override
  String get todayWallNext => 'Seguinte';

  @override
  String get todayWallChapter => 'CAPÍTULO';

  @override
  String get todayWallUntitled => 'Um capítulo sem título';

  @override
  String todayWallBy(String name) {
    return 'de $name';
  }

  @override
  String get todayWallEmpty =>
      'O teu mural enche-se à medida que os membros partilham histórias e fotos de que gostam';

  @override
  String get todayWallWrite => 'Escrever um capítulo';

  @override
  String get todayWallShare => 'Partilhar uma foto';

  @override
  String get profileSetupBackTooltip => 'Voltar';

  @override
  String profileSetupStepCounter(int current, int total) {
    return 'Passo $current de $total';
  }

  @override
  String get profileSetupLoadErrorTitle =>
      'Não foi possível carregar os dados do perfil.';

  @override
  String get profileSetupRetry => 'Tentar novamente';

  @override
  String get profileSetupEducationHighSchool => 'Ensino secundário';

  @override
  String get profileSetupEducationBachelors => 'Licenciatura';

  @override
  String get profileSetupEducationMasters => 'Mestrado';

  @override
  String get profileSetupEducationPhd => 'Doutoramento';

  @override
  String get profileSetupEducationOther => 'Outro';

  @override
  String get profileSetupPreferNotToSay => 'Prefiro não dizer';

  @override
  String profileSetupIncomeBelow(String amount) {
    return 'Menos de $amount';
  }

  @override
  String get profileSetupFrequencyNever => 'Nunca';

  @override
  String get profileSetupFrequencySocially => 'Socialmente';

  @override
  String get profileSetupFrequencyOccasionally => 'Ocasionalmente';

  @override
  String get profileSetupFrequencyRegularly => 'Regularmente';

  @override
  String get profileSetupGenderMan => 'Homem';

  @override
  String get profileSetupGenderWoman => 'Mulher';

  @override
  String get profileSetupGenderOther => 'Outro';

  @override
  String profileSetupBioTooShort(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'A bio tem de ter pelo menos $min caracteres.',
      one: 'A bio tem de ter pelo menos 1 carácter.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupSaveFailed =>
      'Não foi possível guardar — tenta novamente.';

  @override
  String get profileSetupCouldNotSaveChanges =>
      'Não foi possível guardar as tuas alterações. Tenta novamente.';

  @override
  String get profileSetupAboutTitle => 'Faz o teu perfil brilhar';

  @override
  String get profileSetupAboutSubtitle =>
      'Estes detalhes ajudam a encontrar melhores matches.';

  @override
  String get profileSetupBioLabel => 'Bio';

  @override
  String profileSetupBioHint(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Fala um pouco de ti (mín. $min caracteres)',
      one: 'Fala um pouco de ti (mín. 1 carácter)',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupHeightLabel => 'Altura (cm)';

  @override
  String get profileSetupHeightHint => 'Seleciona a altura';

  @override
  String profileSetupHeightValue(int cm) {
    return '$cm cm';
  }

  @override
  String get profileSetupEducationLabel => 'Formação';

  @override
  String get profileSetupEducationHint => 'Seleciona a formação';

  @override
  String get profileSetupProfessionLabel => 'Profissão';

  @override
  String get profileSetupProfessionHint => 'ex.: engenheiro de software';

  @override
  String get profileSetupIncomeLabel => 'Rendimento (opcional)';

  @override
  String get profileSetupLifestyleTitle => 'Estilo de vida';

  @override
  String get profileSetupDrinkingLabel => 'Álcool';

  @override
  String get profileSetupSmokingLabel => 'Tabaco';

  @override
  String get profileSetupSelectHint => 'Selecionar';

  @override
  String get profileSetupReligionOptionalLabel => 'Religião (opcional)';

  @override
  String get profileSetupContinue => 'Continuar';

  @override
  String get profileSetupSaveAbout => 'Guardar «Sobre mim»';

  @override
  String get profileSetupPhotosSaved => 'Fotos guardadas.';

  @override
  String profileSetupPhotosMaxReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Só podes carregar até $max fotos.',
      one: 'Só podes carregar 1 foto.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupRemovePhotoTitle => 'Remover esta foto?';

  @override
  String get profileSetupRemovePhotoBody =>
      'Será removida do teu perfil e eliminada do armazenamento.';

  @override
  String get profileSetupCancel => 'Cancelar';

  @override
  String get profileSetupRemove => 'Remover';

  @override
  String profileSetupPhotosMinRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Carrega pelo menos $min fotos para continuar.',
      one: 'Carrega pelo menos 1 foto para continuar.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTitle => 'Adiciona as tuas fotos';

  @override
  String profileSetupPhotosSubtitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Adiciona pelo menos $min fotos para teres matches',
      one: 'Adiciona pelo menos 1 foto para teres matches',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupChooseSource => 'Escolhe a origem';

  @override
  String get profileSetupGallery => 'Galeria';

  @override
  String get profileSetupCamera => 'Câmara';

  @override
  String get profileSetupPhotoRequirements =>
      'JPEG, PNG, WebP ou HEIC · mínimo 300×300 · 10 MB cada · 50 MB no total';

  @override
  String profileSetupPhotosTipEmpty(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other:
          'Adiciona pelo menos $min fotos para mostrares diferentes lados de ti.',
      one: 'Adiciona pelo menos 1 foto para mostrares diferentes lados de ti.',
    );
    return '$_temp0';
  }

  @override
  String profileSetupPhotosTipMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Adiciona mais $count fotos para desbloquear todos os matches.',
      one: 'Adiciona mais 1 foto para desbloquear todos os matches.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTipDone =>
      'Ótimo! Podes reordenar as fotos arrastando-as.';

  @override
  String get profileSetupYourPhotosHeading =>
      'As tuas fotos  •  arrasta para reordenar';

  @override
  String get profileSetupContinueToAbout => 'Continuar para «Sobre mim»';

  @override
  String get profileSetupSavePhotos => 'Guardar fotos';

  @override
  String get profileSetupPrimaryPhoto => 'Foto principal';

  @override
  String profileSetupPhotoNumber(int number) {
    return 'Foto $number';
  }

  @override
  String get profileSetupShownFirst => 'Aparece primeiro no teu perfil';

  @override
  String get profileSetupDragHandleHint => 'Arrasta a pega para reordenar';

  @override
  String get profileSetupAwaitingSafetyReview =>
      'A aguardar revisão de segurança';

  @override
  String get profileSetupSafetyCheckInProgress =>
      'Verificação de segurança em curso';

  @override
  String get profileSetupSetAsProfilePicture => 'Definir como foto de perfil';

  @override
  String get profileSetupProfilePictureSelected => 'Foto de perfil selecionada';

  @override
  String get profileSetupRemovePhotoTooltip => 'Remover foto';

  @override
  String get profileSetupPhotoTooLarge => 'Esta foto excede o limite de 10 MB.';

  @override
  String get profileSetupPhotoUnsupportedType =>
      'Usa uma foto JPEG, PNG, WebP ou HEIC.';

  @override
  String get profileSetupPhotoBadDimensions =>
      'As dimensões da foto têm de estar entre 300×300 e 4096×4096.';

  @override
  String get profileSetupPhotoQuotaReached =>
      'Atingiste o limite de fotos de perfil.';

  @override
  String get profileSetupPhotoStorageFull =>
      'O armazenamento de fotos está temporariamente cheio. Tenta mais tarde.';

  @override
  String get profileSetupPhotoUpdateFailed =>
      'Não foi possível atualizar a foto. Tenta novamente.';

  @override
  String profileSetupPhotoMaxAllowed(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'São permitidas no máximo $max fotos.',
      one: 'É permitida no máximo 1 foto.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPreferencesLoadFailed =>
      'Não foi possível carregar as preferências';

  @override
  String get profileSetupOfflineBanner =>
      'Modo offline — alguns dados podem estar desatualizados.';

  @override
  String get profileSetupYourPreferences => 'As tuas preferências';

  @override
  String get profileSetupEditPreferencesTitle => 'Editar preferências';

  @override
  String get profileSetupFinishAndFindMatches => 'Concluir e encontrar matches';

  @override
  String get profileSetupSavePreferences => 'Guardar preferências';

  @override
  String get profileSetupSelectGenderPreference =>
      'Seleciona pelo menos um género.';

  @override
  String get profileSetupFinishFailed =>
      'Não foi possível concluir a configuração. Verifica as tuas fotos e preferências e tenta novamente.';

  @override
  String get profileSetupPreferencesSaveFailed =>
      'Não foi possível guardar algumas preferências neste momento.';

  @override
  String get profileSetupPreferencesSaved => 'Preferências guardadas.';

  @override
  String get profileSetupTabBasic => 'Básico';

  @override
  String get profileSetupTabAdvanced => 'Avançado';

  @override
  String get profileSetupLookingFor => 'Procuro';

  @override
  String get profileSetupSeekingMen => 'Homens';

  @override
  String get profileSetupSeekingWomen => 'Mulheres';

  @override
  String get profileSetupSeekingOther => 'Outros';

  @override
  String profileSetupAgeRangeTitle(int min, int max) {
    return 'Faixa etária: $min – $max';
  }

  @override
  String profileSetupMaxDistanceTitle(int km) {
    return 'Distância máx.: $km km';
  }

  @override
  String profileSetupDistanceValue(int km) {
    return '$km km';
  }

  @override
  String get profileSetupRelationshipIntent => 'Tipo de relação';

  @override
  String get profileSetupSeriousOnly => 'Só relação séria';

  @override
  String get profileSetupSeriousOnlySubtitle =>
      'Mostrar só quem procura compromisso';

  @override
  String get profileSetupVerifiedOnly => 'Só perfis verificados';

  @override
  String get profileSetupVerifiedOnlySubtitle =>
      'Só contas com identidade verificada';

  @override
  String get profileSetupHookupsOnly => 'Só encontros casuais';

  @override
  String get profileSetupHookupsOnlySubtitle => 'Mostrar só perfis casuais';

  @override
  String get profileSetupLocation => 'Localização';

  @override
  String get profileSetupCountry => 'País';

  @override
  String get profileSetupStateRegion => 'Estado / Região';

  @override
  String get profileSetupCity => 'Cidade';

  @override
  String get profileSetupBackgroundCulture => 'Origem e cultura';

  @override
  String get profileSetupReligionPreference => 'Religião';

  @override
  String get profileSetupMotherTongue => 'Língua materna';

  @override
  String get profileSetupLanguage => 'Idioma';

  @override
  String get profileSetupDietPreference => 'Preferência alimentar';

  @override
  String get profileSetupWorkoutFrequency => 'Frequência de exercício';

  @override
  String get profileSetupDietType => 'Tipo de dieta';

  @override
  String get profileSetupSleepSchedule => 'Horário de sono';

  @override
  String get profileSetupTravelStyle => 'Estilo de viagem';

  @override
  String get profileSetupPoliticalComfortRange => 'Afinidade política';

  @override
  String get profileSetupInterestsPersonality => 'Interesses e personalidade';

  @override
  String get profileSetupInstagramHandle => 'Utilizador do Instagram (sem @)';

  @override
  String get profileSetupIntentTags =>
      'Intenções (longo prazo, casamento, casual…)';

  @override
  String get profileSetupHobbiesField => 'Passatempos (separados por vírgulas)';

  @override
  String get profileSetupFavouriteBooksField =>
      'Livros favoritos (separados por vírgulas)';

  @override
  String get profileSetupFavouriteNovelsField =>
      'Romances favoritos (separados por vírgulas)';

  @override
  String get profileSetupFavouriteSongsField =>
      'Músicas favoritas (separadas por vírgulas)';

  @override
  String get profileSetupExtraCurricularField =>
      'Atividades extracurriculares (separadas por vírgulas)';

  @override
  String get profileSetupAdditionalInformation => 'Informações adicionais';

  @override
  String get profileSetupPetPreference => 'Animais de estimação';

  @override
  String get profileSetupDealBreakers => 'Inegociáveis';

  @override
  String get profileSetupTagsField => 'Etiquetas (separadas por vírgulas)';

  @override
  String get profileSetupNameRequired => 'O nome é obrigatório.';

  @override
  String get profileSetupDobRequired => 'A data de nascimento é obrigatória.';

  @override
  String profileSetupPhotosRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'São necessárias pelo menos $min fotos.',
      one: 'É necessária pelo menos 1 foto.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupServerError => 'Erro do servidor';

  @override
  String get profileSetupNetworkError => 'Erro de rede — tenta novamente.';

  @override
  String get profileSetupGenericError => 'Algo correu mal. Tenta novamente.';

  @override
  String get profileSetupPreviewTitle => 'Pré-visualiza o teu perfil';

  @override
  String get profileSetupPreviewSubtitle => 'É assim que os outros te vão ver.';

  @override
  String profileSetupNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String profileSetupDrinksChip(String value) {
    return 'Álcool: $value';
  }

  @override
  String profileSetupSmokesChip(String value) {
    return 'Tabaco: $value';
  }

  @override
  String get profileSetupCompleteProfile => 'Concluir perfil';

  @override
  String profileSetupCompletionPercent(int percent) {
    return 'Perfil concluído: $percent%';
  }

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileEditRefreshTooltip => 'Atualizar perfil';

  @override
  String get profileEditAboutYou => 'Sobre ti';

  @override
  String get profileEditEditAbout => 'Editar «Sobre mim»';

  @override
  String get profileEditName => 'Nome';

  @override
  String get profileEditPhone => 'Telemóvel';

  @override
  String get profileEditDateOfBirth => 'Data de nascimento';

  @override
  String get profileEditGender => 'Género';

  @override
  String get profileEditHeight => 'Altura';

  @override
  String get profileEditIncomeRange => 'Escalão de rendimento';

  @override
  String get profileEditLocationSocial => 'Localização e redes sociais';

  @override
  String get profileEditEditPreferences => 'Editar preferências';

  @override
  String get profileEditState => 'Estado / Região';

  @override
  String get profileEditInstagram => 'Instagram';

  @override
  String get profileEditDatingPreferences => 'Preferências de encontros';

  @override
  String get profileEditSeeking => 'Procuro';

  @override
  String get profileEditAgeRange => 'Faixa etária';

  @override
  String profileEditAgeRangeValue(int min, int max) {
    return '$min–$max';
  }

  @override
  String get profileEditMaxDistance => 'Distância máx.';

  @override
  String get profileEditEducationFilter => 'Filtro de formação';

  @override
  String get profileEditSeriousOnly => 'Só relações sérias';

  @override
  String get profileEditVerifiedOnly => 'Só verificados';

  @override
  String get profileEditHookupOnly => 'Só casual';

  @override
  String get profileEditYes => 'Sim';

  @override
  String get profileEditNo => 'Não';

  @override
  String get profileEditIntent => 'Intenção';

  @override
  String get profileEditLanguages => 'Idiomas';

  @override
  String get profileEditDealBreakers => 'Inegociáveis';

  @override
  String get profileEditReligion => 'Religião';

  @override
  String get profileEditPets => 'Animais';

  @override
  String get profileEditWorkout => 'Exercício';

  @override
  String get profileEditPoliticsComfort => 'Afinidade política';

  @override
  String get profileEditInterestsDetails => 'Interesses e detalhes';

  @override
  String get profileEditHobbies => 'Passatempos';

  @override
  String get profileEditBooks => 'Livros';

  @override
  String get profileEditNovels => 'Romances';

  @override
  String get profileEditSongs => 'Músicas';

  @override
  String get profileEditExtraCurriculars => 'Atividades extracurriculares';

  @override
  String get profileEditAdditionalInfo => 'Informações adicionais';

  @override
  String get profileEditNotSet => 'Não definido';

  @override
  String get profileEditLoadingTitle => 'A carregar o teu perfil guardado';

  @override
  String get profileEditLoadingBody =>
      'A recuperar as informações guardadas na criação da conta.';

  @override
  String get profileEditYourProfile => 'O teu perfil';

  @override
  String profileEditPercentComplete(int percent) {
    return '$percent% concluído';
  }

  @override
  String get profileEditPhotoGallery => 'Galeria de fotos';

  @override
  String get profileEditManagePhotos => 'Gerir fotos';

  @override
  String get profileEditNoPhotos => 'Ainda não carregaste fotos.';

  @override
  String get profileEditPrimaryBadge => 'Principal';

  @override
  String get engagementHubPromptLoading => 'A carregar a pergunta de hoje';

  @override
  String get engagementHubPromptIntro =>
      'Responde a uma pergunta por dia e aumenta a tua sequência.';

  @override
  String engagementHubPromptRepliedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas responderam hoje',
      one: '1 pessoa respondeu hoje',
    );
    return '$_temp0';
  }

  @override
  String engagementHubPromptStreakSummary(int days, int similar) {
    return 'Sequência $days d · respostas parecidas: $similar';
  }

  @override
  String get engagementHubBlogTitle => 'Blogue · Open Chapters';

  @override
  String get engagementHubBlogSubtitle =>
      'Lê histórias, partilha fotos e escreve a tua.';

  @override
  String get engagementHubPhotoThemesTitle => 'Temas de fotos';

  @override
  String get engagementHubPhotoThemesSubtitle =>
      'Partilha uma foto por tema e vê as de toda a gente.';

  @override
  String get engagementHubClubsTitle => 'Clubes de livros e cinema';

  @override
  String get engagementHubClubsSubtitle =>
      'Segue a escolha da semana, conversa sobre ela e avalia-a.';

  @override
  String get engagementHubCityPilotTitle => 'O piloto na cidade';

  @override
  String get engagementHubCityPilotSubtitle =>
      'Uma comunidade pequena. Conversas que se tornam planos.';

  @override
  String get engagementDailyPromptTitle => 'Sequência da pergunta diária';

  @override
  String get engagementHubVoiceTitle => 'Quebra-gelos de voz guiados';

  @override
  String get engagementHubVoiceSubtitle =>
      'Uma apresentação de voz guiada de 20-45 s por match por dia';

  @override
  String get engagementCirclesTitle => 'Desafios dos círculos locais';

  @override
  String get engagementHubCirclesSubtitle =>
      'Junta-te a um círculo da tua cidade e envia a tua participação desta semana';

  @override
  String get engagementHubCoffeeTitle => 'Sondagem de café em grupo';

  @override
  String get engagementHubCoffeeSubtitle =>
      'Cria, vota e fecha sondagens simples para combinar encontros';

  @override
  String get engagementHubGroupsTitle => 'Grupos';

  @override
  String get engagementHubGroupsSubtitle =>
      'Comunidades de estilo de vida e grupos privados de amigos';

  @override
  String get engagementHubRoomsSubtitle =>
      'Salas de chat em direto: entra, conversa, faz amigos';

  @override
  String get engagementHubFriendsTitle => 'Amigos e apresentações';

  @override
  String get engagementHubFriendsSubtitle =>
      'Convida um amigo de confiança, mesmo que não ande à procura de par';

  @override
  String get engagementLevelTitle => 'Nível e XP';

  @override
  String get engagementHubLevelSubtitle =>
      'Acompanha a atividade relevante, as recompensas de nível e os requisitos de confiança';

  @override
  String get engagementHubPaywallFree =>
      'A progressão principal continua sem paywall.';

  @override
  String get engagementHubPolicyUpdating =>
      'A política de monetização está a ser atualizada.';

  @override
  String engagementHubPremiumAreas(String features) {
    return 'Áreas premium opcionais: $features';
  }

  @override
  String get engagementHubEyebrow => 'PARTICIPAR';

  @override
  String get engagementHubTitle => 'Façam algo juntos.';

  @override
  String get engagementHubSubtitle =>
      'Matches mais sólidos com confiança e atividades partilhadas.';

  @override
  String get engagementHubSectionCreate => 'CRIA E PARTILHA';

  @override
  String get engagementHubSectionCreateCaption =>
      'Histórias, fotos e clubes que dão início a conversas a sério.';

  @override
  String get engagementHubSectionMeet => 'CONHECE PESSOAS';

  @override
  String get engagementHubSectionMeetCaption =>
      'Pequenos grupos, perguntas e planos ao teu ritmo.';

  @override
  String get engagementHubSectionProgress => 'CONFIANÇA E PROGRESSO';

  @override
  String get engagementHubSectionProgressCaption =>
      'O teu nível, os teus selos e quem te pode encontrar.';

  @override
  String get engagementVoiceAppBarTitle => 'Uma voz, um pouco mais perto';

  @override
  String get engagementVoiceHeadline => 'Deixa o teu olá\nsoar a ti.';

  @override
  String get engagementVoiceIntro =>
      'Uma apresentação opcional de 20 a 45 segundos, partilhada só nesta conversa. O texto também é sempre bem-vindo.';

  @override
  String engagementVoiceYouAndName(String name) {
    return 'Tu e $name';
  }

  @override
  String get engagementVoiceYouAndYourMatch => 'Tu e o teu match';

  @override
  String get engagementVoicePrivate => 'Visível apenas nesta conversa';

  @override
  String get engagementVoiceConversationsLoadFailed =>
      'Não foi possível carregar as tuas conversas.';

  @override
  String get engagementVoiceNoMatches =>
      'Quando tiveres um match, podes partilhar aqui uma apresentação de voz. Sem pressa.';

  @override
  String get engagementVoicePickConversation => 'A quem queres dizer olá?';

  @override
  String get engagementVoiceStartingPoint => 'Um pequeno ponto de partida';

  @override
  String get engagementVoiceChoosePrompt => 'Escolhe uma pergunta';

  @override
  String get engagementVoiceTranscriptLabel => 'As tuas palavras, por escrito';

  @override
  String get engagementVoiceTranscriptHelper =>
      'Escreve o que dizes para que também possa ser lido. Isto não é uma transcrição automática.';

  @override
  String engagementVoiceStop(int seconds) {
    return 'Parar · $seconds s';
  }

  @override
  String get engagementVoiceRecord => 'Grava o teu olá';

  @override
  String engagementVoiceRecordAgain(int seconds) {
    return 'Gravar de novo · $seconds s';
  }

  @override
  String get engagementVoiceRecordingReady =>
      'Gravação pronta. Revê o teu texto antes de enviar.';

  @override
  String get engagementVoiceRecordingShort =>
      'Ficou um pouco curto. Grava entre 20 e 45 segundos.';

  @override
  String get engagementVoiceDiscard => 'Descartar gravação';

  @override
  String get engagementVoiceSubmitted =>
      'Apresentação enviada. As gravações aprovadas aparecem abaixo.';

  @override
  String get engagementVoiceSending => 'A enviar…';

  @override
  String get engagementVoiceShare => 'Partilhar o teu olá';

  @override
  String get engagementVoiceCheckedNote =>
      'As gravações são verificadas antes de serem partilhadas. Não há reprodução automática.';

  @override
  String get engagementVoiceYourIntros => 'As vossas apresentações de voz';

  @override
  String get engagementVoiceLatestNote =>
      'As últimas 20 gravações aprovadas nesta conversa. Os textos podem ser sempre lidos.';

  @override
  String get engagementVoiceIntrosLoadFailed =>
      'Não foi possível carregar as apresentações. A conversa pode já não estar disponível.';

  @override
  String get engagementVoiceNothingYet =>
      'Ainda nada partilhado. Um simples olá é um bom começo.';

  @override
  String get engagementVoiceYourHello => 'O teu olá';

  @override
  String engagementVoiceHelloFromName(String name) {
    return 'Um olá de $name';
  }

  @override
  String get engagementVoiceHelloFromYourMatch => 'Um olá do teu match';

  @override
  String get engagementVoiceTranscriptHeading => 'TEXTO';

  @override
  String get engagementVoiceStopPlayback => 'Parar reprodução';

  @override
  String engagementVoiceListen(int seconds) {
    return 'Ouvir · $seconds s';
  }

  @override
  String get engagementVoiceReloadPrompts => 'Recarregar perguntas';

  @override
  String get engagementVoiceMicPermission =>
      'Permite o acesso ao microfone para gravar. Podes ler os textos na mesma.';

  @override
  String get engagementVoiceStartFailed =>
      'Não foi possível começar a gravar. Verifica o acesso ao microfone e tenta de novo.';

  @override
  String get engagementVoiceSaveFailed =>
      'Não foi possível guardar a gravação. Tenta de novo.';

  @override
  String get engagementVoicePromptsLoadFailed =>
      'Não é possível carregar as perguntas de voz neste momento.';

  @override
  String get engagementSessionUnavailable => 'Sessão indisponível.';

  @override
  String get engagementVoiceChooseConversation =>
      'Escolhe primeiro uma conversa.';

  @override
  String get engagementVoiceSelectPrompt => 'Escolhe uma pergunta de voz.';

  @override
  String get engagementVoiceEnterTranscript => 'Escreve o texto.';

  @override
  String get engagementVoiceSessionFailed =>
      'Não foi possível criar a sessão do quebra-gelo de voz.';

  @override
  String get engagementVoiceSendFailed =>
      'Não é possível enviar o quebra-gelo de voz neste momento.';

  @override
  String get engagementVoicePlaybackUserRequired =>
      'É necessário um ID de utilizador para registar a reprodução.';

  @override
  String get engagementVoiceMarkPlaybackFailed =>
      'Não é possível registar a reprodução neste momento.';

  @override
  String get engagementVoicePlayFailed =>
      'Não é possível reproduzir esta gravação neste momento.';

  @override
  String get chatStarterSmile => 'O que fez você sorrir hoje?';

  @override
  String get chatStarterSunday => 'Seu domingo ideal: conta aí.';

  @override
  String get chatStarterCoffee =>
      'Um café, uma caminhada ou uma pequena aventura?';

  @override
  String get chatWelcomeTitle => 'Toda boa história\ncomeça com um olá.';

  @override
  String get chatWelcomePending =>
      'A conversa abre quando o match for confirmado.';

  @override
  String get chatWelcomeBody => 'Não precisa da frase perfeita. Seja você.';

  @override
  String get chatInspirationEyebrow => 'UM POUCO DE INSPIRAÇÃO';

  @override
  String get chatAllConversations => 'Todas as conversas';

  @override
  String get chatMakeConnectionEyebrow => 'CRIE UMA CONEXÃO';

  @override
  String get chatLessSmallTalk => 'Um pouco menos de papo furado.';

  @override
  String get chatLessSmallTalkBody =>
      'Pergunte sobre o que deixa a pessoa animada. Compartilhe algo que tenha a sua cara.';

  @override
  String get chatFindTheWords => 'Encontrar as palavras';

  @override
  String get chatSendJoy => 'Envie um pouco de alegria';

  @override
  String get chatPaceTitle => 'Seu ritmo. Seu espaço.';

  @override
  String get chatPaceBody =>
      'Compartilhe só o que for confortável. Uma boa conexão respeita seus limites.';

  @override
  String get chatWriteMessageHint => 'Escreva uma mensagem…';

  @override
  String get chatConversationPaused => 'Conversa pausada';

  @override
  String get chatSendingMessageTooltip => 'Enviando mensagem';

  @override
  String get chatSendMessageTooltip => 'Enviar mensagem';

  @override
  String get chatSendGiftTooltip => 'Enviar um presente';

  @override
  String get chatAddEmojiTooltip => 'Adicionar um emoji';

  @override
  String get chatDraftedWithHelp => 'Escrito com ajuda';

  @override
  String get chatHelpMeSayIt => 'Me ajude a dizer';

  @override
  String get chatEnterToSendHint =>
      'Enter para enviar · Shift + Enter para nova linha';

  @override
  String get chatToday => 'Hoje';

  @override
  String get chatYesterday => 'Ontem';

  @override
  String get chatGiftOptions => 'Opções do presente';

  @override
  String get chatStatusRead => 'Lida';

  @override
  String get chatStatusDelivered => 'Entregue';

  @override
  String get chatStatusSent => 'Enviada';

  @override
  String get chatGestureGiftHeading => 'Gesto + rosa de presente';

  @override
  String get chatGiftForYouHeading => 'Um mimo para você';

  @override
  String chatGiftTone(String tone) {
    return 'Tom: $tone';
  }

  @override
  String get chatFreeGift => 'Presente grátis';

  @override
  String get chatCopilotKindOpener => 'Primeira mensagem';

  @override
  String get chatCopilotKindReply => 'Resposta';

  @override
  String get chatCopilotKindDateIdea => 'Ideia de encontro';

  @override
  String get chatCopilotToneWarm => 'Caloroso';

  @override
  String get chatCopilotTonePlayful => 'Brincalhão';

  @override
  String get chatCopilotToneDirect => 'Direto';

  @override
  String chatCopilotIntro(String name) {
    return 'Um rascunho com o seu jeito, a partir do perfil de $name e da conversa de vocês. Nunca é enviado por você e, se você enviar como está, a pessoa verá que foi escrito com ajuda.';
  }

  @override
  String chatCopilotDisclosure(String disclosure, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restam $count rascunhos hoje.',
      one: 'Resta 1 rascunho hoje.',
    );
    return '$disclosure $_temp0';
  }

  @override
  String get chatCopilotDraftIt => 'Criar rascunho';

  @override
  String get chatCopilotTryAnother => 'Tentar outro';

  @override
  String get chatCopilotUseAndEdit => 'Usar e editar';

  @override
  String get chatCopilotEmpty => 'O copiloto não retornou nada.';

  @override
  String get chatCopilotUnavailable => 'O copiloto está indisponível.';

  @override
  String get chatErrorMatchEnded => 'Este match foi encerrado.';

  @override
  String get chatErrorLoadMessages =>
      'Não foi possível carregar as mensagens. Tente novamente.';

  @override
  String get chatErrorLockedQuest =>
      'A conversa fica bloqueada até o desafio ser aprovado.';

  @override
  String get chatErrorSendFailed => 'Não foi possível enviar a mensagem.';

  @override
  String get chatErrorDeleteFailed => 'Não foi possível apagar a mensagem.';

  @override
  String get chatErrorDeleteWindowExpired =>
      'O prazo para apagar expirou (24 h).';

  @override
  String get chatErrorOnlyReceivedGifts =>
      'Só é possível gerenciar presentes recebidos.';

  @override
  String get chatErrorGiftGone => 'Este presente não está mais disponível.';

  @override
  String get chatErrorGiftReportFailed =>
      'Não foi possível denunciar este presente. Tente novamente.';

  @override
  String get chatErrorGiftHideFailed =>
      'Não foi possível ocultar este presente. Tente novamente.';

  @override
  String get chatErrorGiftsUnavailable =>
      'Os presentes de rosas estão indisponíveis no momento.';

  @override
  String chatErrorNotEnoughCoins(String gift) {
    return 'Moedas insuficientes para enviar $gift.';
  }

  @override
  String get chatErrorNotEnoughCoinsSelected =>
      'Moedas insuficientes para o presente escolhido.';

  @override
  String get chatErrorWalletFrozen =>
      'Suas moedas estão retidas enquanto analisamos uma compra reembolsada. Os presentes grátis continuam disponíveis.';

  @override
  String get chatErrorGiftVelocity =>
      'Você enviou muitos presentes em pouco tempo. Tente mais tarde.';

  @override
  String get chatErrorFreeGiftUsed =>
      'Você já enviou o presente grátis de hoje. Um novo fica disponível após a meia-noite UTC.';

  @override
  String chatErrorGiftNotAvailable(String gift) {
    return '$gift não está disponível agora.';
  }

  @override
  String get chatErrorGiftNeedsActiveMatch =>
      'Presentes só podem ser enviados em um match ativo.';

  @override
  String get chatErrorExclusiveGiftOnce =>
      'Este presente exclusivo só pode ser enviado uma vez hoje.';

  @override
  String get chatErrorGiftFailed => 'Não foi possível enviar o presente.';

  @override
  String get chatErrorSessionUnavailable => 'Sessão do usuário indisponível.';

  @override
  String get chatErrorConversationUnavailable => 'Conversa indisponível.';

  @override
  String get verificationLandingTitle => 'Verifica-te com confiança';

  @override
  String get verificationLandingBody =>
      'Carrega um documento de identificação oficial legível e uma selfie recente. Os ficheiros são enviados de forma encriptada e guardados numa área de provas privada.';

  @override
  String get verificationLandingDisclaimer =>
      'A verificação acrescenta contexto ao teu perfil. Nunca garante a identidade, as intenções ou a segurança de outra pessoa.';

  @override
  String get verificationViewVerifiedStatus => 'Ver estado verificado';

  @override
  String get verificationViewReviewStatus => 'Ver estado da análise';

  @override
  String get verificationStartButton => 'Iniciar verificação segura';

  @override
  String get verificationUploadIdTitle => 'Carregar documento';

  @override
  String get verificationUploadIdInstruction =>
      'Tira ou carrega uma fotografia nítida do teu documento de identificação oficial.';

  @override
  String get verificationGallery => 'Galeria';

  @override
  String get verificationCamera => 'Câmara';

  @override
  String get verificationNext => 'Seguinte';

  @override
  String get verificationSelfieTitle => 'Selfie';

  @override
  String get verificationSelfieInstruction => 'Tira uma selfie nítida.';

  @override
  String get verificationUploadFailed =>
      'Não foi possível carregar as tuas provas. Verifica os ficheiros e tenta novamente.';

  @override
  String get verificationSubmit => 'Enviar';

  @override
  String get verificationStatusTitle => 'Estado da verificação';

  @override
  String get verificationRetry => 'Tentar novamente';

  @override
  String get verificationStatusVerified => 'Verificado';

  @override
  String get verificationStatusVerifiedMessage =>
      'A tua verificação está concluída.';

  @override
  String get verificationStatusRejected => 'Rejeitado';

  @override
  String get verificationStatusRejectedFallback => 'Tenta novamente.';

  @override
  String get verificationStatusPending => 'Pendente';

  @override
  String get verificationStatusPendingMessage => 'Análise em curso.';

  @override
  String get verificationStatusNotStarted => 'Não iniciada';

  @override
  String get verificationStatusNotStartedMessage =>
      'Inicia a verificação nas Definições.';

  @override
  String get safetySosTitle => 'SOS de emergência';

  @override
  String get safetySosDefaultMessage =>
      'Preciso de ajuda imediata. Por favor, verifiquem se estou bem.';

  @override
  String get safetySosHeadline => 'Ativar um alerta de emergência';

  @override
  String get safetySosIntro =>
      'Se estiveres em perigo imediato, contacta primeiro os serviços de emergência locais. Este alerta fica registado para a equipa de segurança.';

  @override
  String get safetySosLevelUrgent => 'Urgente';

  @override
  String get safetySosLevelCritical => 'Crítico';

  @override
  String get safetySosMessageLabel => 'Mensagem para a equipa de segurança';

  @override
  String get safetySosActivating => 'A ativar…';

  @override
  String get safetySosActivate => 'Ativar SOS';

  @override
  String get safetySosLocationNote =>
      'A localização só é pedida para este alerta. Podes continuar se recusares a permissão.';

  @override
  String get safetySosHistoryTitle => 'Histórico de alertas';

  @override
  String get safetySosHistoryEmpty => 'Nenhum alerta SOS registado.';

  @override
  String safetySosHistoryHeading(String level, String status) {
    return '$level · $status';
  }

  @override
  String get safetySosAlertLevelLow => 'BAIXO';

  @override
  String get safetySosAlertLevelMedium => 'MÉDIO';

  @override
  String get safetySosAlertLevelHigh => 'ALTO';

  @override
  String get safetySosAlertLevelCritical => 'CRÍTICO';

  @override
  String get safetySosAlertStatusOpen => 'aberto';

  @override
  String get safetySosAlertStatusActive => 'ativo';

  @override
  String get safetySosAlertStatusAcknowledged => 'recebido';

  @override
  String get safetySosAlertStatusResolved => 'resolvido';

  @override
  String safetySosHistoryMetaWithLocation(String date) {
    return '$date · com localização';
  }

  @override
  String safetySosHistoryMetaNoLocation(String date) {
    return '$date · sem localização';
  }

  @override
  String safetySosResolution(String note) {
    return 'Resolução: $note';
  }

  @override
  String get safetySosConfirmTitle => 'Ativar o SOS agora?';

  @override
  String get safetySosConfirmBody =>
      'Isto cria um alerta de emergência para a equipa de segurança e tenta anexar a tua localização atual.';

  @override
  String get safetySosCancel => 'Cancelar';

  @override
  String get safetySosConfirmActivate => 'Ativar';

  @override
  String get safetySosActivatedTitle => 'Alerta SOS ativado';

  @override
  String get safetySosActivatedWithLocation =>
      'O teu alerta e a tua localização atual foram registados.';

  @override
  String get safetySosActivatedWithoutLocation =>
      'O teu alerta foi registado sem localização. A permissão de localização não estava disponível ou foi recusada.';

  @override
  String get safetySosDone => 'Concluído';

  @override
  String get safetySosSignInToView =>
      'Inicia sessão para ver o histórico de SOS.';

  @override
  String get safetySosLoadFailed =>
      'Não foi possível carregar o histórico de SOS.';

  @override
  String get safetySosSignInToActivate =>
      'Inicia sessão antes de ativar o SOS.';

  @override
  String get safetySosActivateFailed => 'Não foi possível ativar o SOS.';

  @override
  String get photoThemesTitle => 'Temas de fotos';

  @override
  String get photoThemesSignIn => 'Inicia sessão para ver os temas de fotos.';

  @override
  String get photoThemesHeroTitle => 'Mostra um pouco do teu mundo';

  @override
  String get photoThemesHeroSubtitle =>
      'Escolhe um tema, partilha uma foto e vê como os outros responderam. É uma forma fácil de começar uma conversa.';

  @override
  String get photoThemesLoadFailed => 'Não foi possível carregar os temas';

  @override
  String get photoThemesCheckConnection => 'Verifica a tua ligação.';

  @override
  String get photoThemesLookAround => 'Podes dar uma vista de olhos';

  @override
  String get photoThemesEligibilityShareOwn =>
      'Completa o teu perfil com duas fotos aprovadas para partilhares as tuas.';

  @override
  String get photoThemesNewPromptsTitle => 'Novos temas a caminho';

  @override
  String get photoThemesNewPromptsBody =>
      'Volta em breve para teres algo para partilhar.';

  @override
  String photoThemesSharedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partilhadas',
      one: '$count partilhada',
    );
    return '$_temp0';
  }

  @override
  String get photoThemesYouShared => 'Já partilhaste ✓';

  @override
  String get photoThemesBeFirst => 'Sê o primeiro a partilhar →';

  @override
  String get photoThemesSeeEveryone => 'Ver as fotos de todos →';

  @override
  String get photoThemesSharedSnack => 'A tua foto foi partilhada. Boa!';

  @override
  String get photoThemesShareFailed =>
      'Não foi possível partilhar a tua foto. Usa um JPEG ou PNG até 10 MB.';

  @override
  String get photoThemesEligibilityShare =>
      'Completa o teu perfil com duas fotos aprovadas para partilhar.';

  @override
  String get photoThemesAlreadyShared =>
      'Já partilhaste neste tema. Remove a tua foto para partilhares outra.';

  @override
  String get photoThemesThemeFallback => 'Tema de fotos';

  @override
  String get photoThemesShareTooltip => 'Partilha uma foto para este tema';

  @override
  String get photoThemesShareYourPhoto => 'Partilha a tua foto';

  @override
  String get photoThemesNoPhotosYet => 'Ainda não há fotos';

  @override
  String photoThemesBeFirstFor(String title) {
    return 'Sê o primeiro a partilhar em “$title”';
  }

  @override
  String get photoThemesLoadingPrompt => 'A carregar o tema…';

  @override
  String get photoThemesPhotosLoadFailed =>
      'Não foi possível carregar as fotos';

  @override
  String get photoThemesEmptyMessage =>
      'A tua foto pode ser a que põe toda a gente a falar.';

  @override
  String get photoThemesMoreFailed =>
      'Não foi possível carregar mais fotos. Recarregar';

  @override
  String get photoThemesLoadMore => 'Carregar mais';

  @override
  String get photoThemesPhotoUnavailable => 'Foto indisponível. Tentar de novo';

  @override
  String photoThemesOpenPhoto(String name) {
    return 'Abrir a foto de $name';
  }

  @override
  String get photoThemesYou => 'Tu';

  @override
  String get photoThemesWallHelp =>
      'Se os membros adorarem, a tua foto pode chegar aos murais Today deles: 50 gostos e 5 comentários chegam a 50 murais, 100 gostos e 10 comentários a 100. Podes desativar isto a qualquer momento.';

  @override
  String get photoThemesRemoveTitle => 'Remover a tua foto?';

  @override
  String get photoThemesRemoveMessage =>
      'Desaparece deste tema para toda a gente. Depois podes partilhar outra.';

  @override
  String get photoThemesRemoveAction => 'Remover foto';

  @override
  String get photoThemesRemoveFailed => 'Não foi possível remover a tua foto.';

  @override
  String get photoThemesReachOn =>
      'A tua foto já pode chegar aos murais dos membros quando a adorarem.';

  @override
  String get photoThemesReachOff => 'A tua foto saiu de todos os murais.';

  @override
  String get photoThemesSharedByYou => 'Partilhada por ti';

  @override
  String photoThemesSharedBy(String name) {
    return 'Partilhada por $name';
  }

  @override
  String photoThemesPhotoDescription(String text) {
    return 'Descrição da foto: $text';
  }

  @override
  String get photoThemesReachSwitch =>
      'Deixar chegar aos murais de outros membros';

  @override
  String get photoThemesReachIdle =>
      'Os membros podem levar esta foto mais longe';

  @override
  String get photoThemesReachLive =>
      'Há membros a vê-la agora nos murais Today.';

  @override
  String get photoThemesRemoveMine => 'Remover a minha foto';

  @override
  String get photoThemesReport => 'Denunciar';

  @override
  String photoThemesBlock(String name) {
    return 'Bloquear $name';
  }

  @override
  String get photoThemesCommentHint => 'Em que te faz pensar?';

  @override
  String get photoThemesCommentApproved =>
      'Aprovado. Agora quem pode ver esta foto também o vê.';

  @override
  String get photoThemesDetailsTitle => 'Conta-nos';

  @override
  String get photoThemesCaption => 'Legenda';

  @override
  String get photoThemesCaptionHint => 'Panquecas e nenhum sítio para onde ir.';

  @override
  String get photoThemesDescribe => 'Descreve a foto';

  @override
  String get photoThemesDescribeHelper =>
      'Ajuda os membros que usam um leitor de ecrã.';

  @override
  String get photoThemesShare => 'Partilhar';

  @override
  String get photoThemesWallTitle => 'Capas no teu mural';

  @override
  String get photoThemesWallCaption => 'Fotos que outros membros adoraram';

  @override
  String get photoThemesMasthead => 'TEMAS DE FOTOS';

  @override
  String photoThemesByline(String name) {
    return 'POR $name';
  }

  @override
  String get photoThemesLikes => 'Gostos';

  @override
  String get photoThemesComments => 'Comentários';

  @override
  String get photoThemesCancel => 'Cancelar';

  @override
  String get photoThemesTryAgain => 'Tentar de novo';

  @override
  String get photoThemesSaveFailed => 'Não ficou guardado. Tenta outra vez.';

  @override
  String get friendsChatEmpty =>
      'Diz olá. Só vocês os dois podem ver esta conversa.';

  @override
  String get friendsChatOpenFailed =>
      'Não foi possível abrir a conversa. Tenta de novo.';

  @override
  String get friendsCancelRequestTitle => 'Cancelar o teu pedido de amizade?';

  @override
  String friendsCancelRequestBody(String name) {
    return '$name deixa de ver o teu pedido.';
  }

  @override
  String get friendsCancelRequestBodyUnnamed =>
      'Este membro deixa de ver o teu pedido.';

  @override
  String get friendsKeepIt => 'Manter';

  @override
  String get friendsCancelRequest => 'Cancelar pedido';

  @override
  String friendsNowFriends(String name) {
    return 'Tu e $name são agora amigos.';
  }

  @override
  String get friendsNowFriendsUnnamed => 'Tu e este membro são agora amigos.';

  @override
  String friendsRequestSentTo(String name) {
    return 'Pedido de amizade enviado a $name.';
  }

  @override
  String get friendsRequestSentToUnnamed =>
      'Pedido de amizade enviado a este membro.';

  @override
  String get friendsRequestCancelled => 'Pedido cancelado.';

  @override
  String get friendsRequestFailed => 'Não foi possível enviar o pedido.';

  @override
  String get friendsAddCaption =>
      'Os amigos podem trocar mensagens e fazer planos juntos';

  @override
  String get friendsRequested => 'Pedido enviado';

  @override
  String friendsWaitingFor(String name) {
    return 'À espera de $name. Toca para cancelar.';
  }

  @override
  String get friendsWaitingForUnnamed =>
      'À espera deste membro. Toca para cancelar.';

  @override
  String get friendsAcceptFriend => 'Aceitar amizade';

  @override
  String friendsAskedToBeFriends(String name) {
    return '$name quer ser teu amigo';
  }

  @override
  String get friendsAskedToBeFriendsUnnamed => 'Este membro quer ser teu amigo';

  @override
  String get friendsMessage => 'Mensagem';

  @override
  String get friendsYoureFriends => 'São amigos. Abre a vossa conversa.';

  @override
  String friendsVouchTooShort(int min) {
    return 'Escreve um pouco mais (pelo menos $min caracteres).';
  }

  @override
  String friendsVouchTitle(String name) {
    return 'Recomendar $name';
  }

  @override
  String get friendsVouchBody =>
      'Uma ou duas frases sobre porque alguém teria sorte em conhecer esta pessoa. Ela aprova antes de aparecer no perfil, com o teu primeiro nome.';

  @override
  String get friendsVouchLabel => 'A tua recomendação';

  @override
  String get friendsVouchHint => 'Simpático, divertido e sempre pontual.';

  @override
  String get friendsVouchSend => 'Enviar recomendação';

  @override
  String get friendsIntroChooseTwo => 'Escolhe dois amigos diferentes.';

  @override
  String get friendsIntroSheetTitle => 'Apresentar dois amigos';

  @override
  String get friendsIntroSheetBody =>
      'Os dois amigos têm de permitir apresentações. Cada um controla a sua pré-visualização e decide em privado. Partilha só um motivo que tenhas autorização para mencionar. As decisões e o resultado do match ficam privados.';

  @override
  String get friendsIntroNeedTwo =>
      'Precisas de pelo menos dois amigos aceites para fazer uma apresentação.';

  @override
  String get friendsFirstFriend => 'Primeiro amigo';

  @override
  String get friendsSecondFriend => 'Segundo amigo';

  @override
  String get friendsIntroWhyLabel => 'Porque se deviam conhecer (opcional)';

  @override
  String get friendsIntroSubmit => 'Fazer a apresentação';

  @override
  String get friendsLoadFailed =>
      'Não foi possível carregar os amigos. Tenta de novo.';

  @override
  String get friendsAddFailed => 'Não foi possível adicionar o amigo.';

  @override
  String get friendsRemoveFailed => 'Não foi possível remover o amigo.';

  @override
  String get friendsRespondFailed =>
      'Não foi possível responder ao pedido de amizade.';

  @override
  String get friendsSocialLoadFailed =>
      'Não foi possível carregar as recomendações e apresentações.';

  @override
  String get friendsVouchSendFailed =>
      'Não foi possível enviar esta recomendação.';

  @override
  String get friendsVouchUpdateFailed =>
      'Não foi possível atualizar esta recomendação.';

  @override
  String get friendsVouchWithdrawFailed =>
      'Não foi possível retirar esta recomendação.';

  @override
  String get friendsIntroMakeFailed =>
      'Não foi possível fazer esta apresentação.';

  @override
  String get friendsIntroAnswerFailed =>
      'Não foi possível responder a esta apresentação.';

  @override
  String get groupsEyebrow => 'GRUPOS';

  @override
  String get groupsTitle => 'Encontra a tua gente.';

  @override
  String get groupsSubtitle =>
      'Comunidades por estilo de vida onde qualquer pessoa pode entrar, e grupos privados só para os teus amigos.';

  @override
  String get groupsStartGroup => 'Criar um grupo';

  @override
  String get groupsInvitationsHeader => 'CONVITES';

  @override
  String get groupsInvitationsCaption => 'Amigos convidaram-te para entrar.';

  @override
  String get groupsAnswerFailed => 'Não foi possível guardar a tua resposta.';

  @override
  String groupsWelcome(String name) {
    return 'Já fazes parte de $name!';
  }

  @override
  String get groupsInvitationDeclined => 'Convite recusado.';

  @override
  String get groupsYourGroupsHeader => 'OS TEUS GRUPOS';

  @override
  String get groupsYourGroupsFailed =>
      'Não foi possível carregar os teus grupos';

  @override
  String get groupsErrorCheckConnection => 'Verifica a tua ligação.';

  @override
  String get groupsEmptyTitle => 'Ainda não há grupos';

  @override
  String get groupsEmptyBody =>
      'Entra numa comunidade abaixo ou cria um grupo privado com os teus amigos.';

  @override
  String get groupsDiscoverHeader => 'DESCOBRIR POR ESTILO DE VIDA';

  @override
  String get groupsDiscoverCaption =>
      'Os grupos de comunidade estão abertos a todos.';

  @override
  String get groupsLifestylesFailed =>
      'Não foi possível carregar os estilos de vida';

  @override
  String get groupsCategoryAll => 'Todos';

  @override
  String get groupsDiscoverFailed => 'Não foi possível carregar os grupos';

  @override
  String get groupsDiscoverEmptyTitle => 'Nada de novo para entrar';

  @override
  String groupsDiscoverEmptyCategoryTitle(String category) {
    return 'Ainda não há grupos de $category';
  }

  @override
  String get groupsDiscoverEmptyBody =>
      'Dá o primeiro passo: cria um grupo de comunidade e convida os teus amigos.';

  @override
  String get groupsStartOne => 'Criar um';

  @override
  String get groupsJoinFailed => 'Não foi possível entrar agora.';

  @override
  String get groupsJoin => 'Entrar';

  @override
  String groupsJoinNamed(String name) {
    return 'Entrar em $name';
  }

  @override
  String groupsInvitedBy(String name, String kind, String members) {
    return '$name convidou-te · $kind · $members';
  }

  @override
  String groupsInvitedByFriend(String kind, String members) {
    return 'Um amigo convidou-te · $kind · $members';
  }

  @override
  String get groupsDecline => 'Recusar';

  @override
  String groupsDeclineNamed(String name) {
    return 'Recusar $name';
  }

  @override
  String groupsChatEmpty(String name) {
    return 'Diz olá ao grupo. Todos em $name podem ver as mensagens aqui.';
  }

  @override
  String groupsInviteFriendsTo(String name) {
    return 'Convidar amigos para $name';
  }

  @override
  String get groupsSendInvitations => 'Enviar convites';

  @override
  String get groupsInvitationsFailed => 'Não foi possível enviar os convites.';

  @override
  String groupsInvitationSentTo(String name) {
    return 'Convite enviado a $name.';
  }

  @override
  String groupsInvitationsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count convites enviados.',
      one: '1 convite enviado.',
    );
    return '$_temp0';
  }

  @override
  String groupsLeaveTitle(String name) {
    return 'Sair de $name?';
  }

  @override
  String get groupsLeaveBodyAlone =>
      'És o único membro, por isso o grupo e o respetivo chat serão eliminados.';

  @override
  String get groupsLeaveBodyOwner =>
      'A gestão passa para o moderador mais antigo ou, se não houver, para o membro mais antigo. Vais perder o acesso ao chat.';

  @override
  String get groupsLeaveBodyCommunity =>
      'Vais perder o acesso ao chat do grupo. Podes voltar a entrar mais tarde.';

  @override
  String get groupsLeaveBodyPrivate =>
      'Vais perder o acesso ao chat do grupo. Vais precisar de um novo convite para voltar.';

  @override
  String get groupsLeave => 'Sair';

  @override
  String get groupsLeaveFailed => 'Não foi possível sair agora.';

  @override
  String get groupsCoverUploadFailed =>
      'Não foi possível carregar a tua foto de capa. Usa um JPEG ou PNG até 10 MB.';

  @override
  String get groupsRemoveCoverTitle => 'Remover a foto de capa?';

  @override
  String groupsRemoveCoverBody(String name) {
    return '$name voltará a mostrar a capa com emoji.';
  }

  @override
  String get groupsRemove => 'Remover';

  @override
  String get groupsRemoveCoverFailed =>
      'Não foi possível remover a foto de capa.';

  @override
  String get groupsCoverRemoved => 'Foto de capa removida.';

  @override
  String groupsDeleteTitle(String name) {
    return 'Eliminar $name?';
  }

  @override
  String get groupsDeleteBody =>
      'O grupo, os convites e o chat serão eliminados para todos. Não é possível anular.';

  @override
  String get groupsDeleteGroup => 'Eliminar grupo';

  @override
  String get groupsDeleteFailed => 'Não foi possível eliminar o grupo.';

  @override
  String get groupsDetailEyebrow => 'GRUPO';

  @override
  String get groupsDetailTitleFallback => 'Grupo';

  @override
  String get groupsOwnerTools => 'Ferramentas do proprietário';

  @override
  String get groupsEditGroup => 'Editar grupo';

  @override
  String get groupsAddCoverPhoto => 'Adicionar foto de capa';

  @override
  String get groupsChangeCoverPhoto => 'Alterar foto de capa';

  @override
  String get groupsRemoveCoverPhoto => 'Remover foto de capa';

  @override
  String get groupsMoreOptions => 'Mais opções';

  @override
  String get groupsReportGroup => 'Denunciar grupo';

  @override
  String get groupsUnavailableTitle => 'Este grupo não está disponível';

  @override
  String get groupsUnavailableBody =>
      'Pode ter sido eliminado ou já não tens acesso.';

  @override
  String get groupsOpenToAll => 'Aberto a todos';

  @override
  String get groupsPrivate => 'Privado';

  @override
  String get groupsYouRunIt => 'És tu quem gere';

  @override
  String get groupsYouModerate => 'Moderas';

  @override
  String get groupsCoverNotePending =>
      'Só tu podes ver esta foto até ser aprovada. Entretanto, os membros veem a capa com emoji.';

  @override
  String get groupsCoverNoteRejected =>
      'A tua última foto de capa não foi aprovada. Escolhe outra.';

  @override
  String get groupsCoverUnderReview => 'Em revisão';

  @override
  String get groupsChangeCover => 'Alterar capa';

  @override
  String get groupsRemoveCover => 'Remover capa';

  @override
  String get groupsRemovedTitle => 'Este grupo foi removido após uma revisão';

  @override
  String get groupsRemovedBodyOwner =>
      'Enquanto estiver removido, os membros não podem conversar, entrar nem convidar. Os teus avisos de revisão explicam a decisão e permitem-te recorrer.';

  @override
  String get groupsRemovedBodyMember =>
      'Enquanto estiver removido, os membros não podem conversar, entrar nem convidar. Podes sair do grupo a qualquer momento.';

  @override
  String get groupsMembers => 'Membros';

  @override
  String get groupsChatButton => 'Chat do grupo';

  @override
  String groupsChatButtonUnread(int count) {
    return 'Chat do grupo · $count por ler';
  }

  @override
  String get groupsInviteFriends => 'Convidar amigos';

  @override
  String get groupsWhosHere => 'QUEM ESTÁ CÁ';

  @override
  String get groupsSeeAll => 'Ver todos';

  @override
  String get groupsYou => 'Tu';

  @override
  String groupsInvitedToJoin(String name) {
    return 'Tens um convite para entrar em $name.';
  }

  @override
  String get groupsJoinGroup => 'Entrar no grupo';

  @override
  String get groupsJoinHint =>
      'Os membros veem quem está cá e conversam em conjunto.';

  @override
  String get groupsCantJoinTitle => 'Não podes entrar neste grupo';

  @override
  String get groupsCantJoinBody =>
      'Pode estar cheio ou um moderador removeu-te.';

  @override
  String get groupsInvitationOnly => 'Só por convite';

  @override
  String get groupsInvitationOnlyBody =>
      'Um membro pode convidar-te para este grupo privado.';

  @override
  String get groupsMakeModerator => 'Tornar moderador';

  @override
  String get groupsMakeMember => 'Tornar membro';

  @override
  String get groupsRemoveFromGroup => 'Remover do grupo';

  @override
  String groupsRemoveMemberTitle(String name) {
    return 'Remover $name?';
  }

  @override
  String get groupsRemoveMemberBodyCommunity =>
      'Sai do grupo e do chat, e não pode voltar a entrar por conta própria.';

  @override
  String get groupsRemoveMemberBodyPrivate => 'Sai do grupo e do chat.';

  @override
  String get groupsChangeFailed => 'Não foi possível guardar a alteração.';

  @override
  String get groupsMembersFailed => 'Não foi possível carregar os membros';

  @override
  String get groupsPleaseTryAgain => 'Tenta de novo.';

  @override
  String groupsMemberYou(String name) {
    return '$name (tu)';
  }

  @override
  String get groupsRoleOwner => 'Proprietário';

  @override
  String get groupsRoleModerator => 'Moderador';

  @override
  String get groupsRoleMember => 'Membro';

  @override
  String groupsMemberOptions(String name) {
    return 'Opções para $name';
  }

  @override
  String get groupsEditFailed => 'Não foi possível guardar as tuas alterações.';

  @override
  String get groupsSaving => 'A guardar…';

  @override
  String get groupsSaveChanges => 'Guardar alterações';

  @override
  String get groupsNameLabel => 'Nome do grupo';

  @override
  String get groupsAboutLabel => 'Sobre o que é?';

  @override
  String get groupsAboutOptionalLabel => 'Sobre o que é? (opcional)';

  @override
  String get groupsCityLabel => 'Cidade (opcional)';

  @override
  String get groupsCoverColorTheme => 'Tema';

  @override
  String get groupsCoverColorAccent => 'Destaque';

  @override
  String get groupsCoverColorWarm => 'Quente';

  @override
  String get groupsLifestyleLabel => 'Estilo de vida';

  @override
  String get groupsCreateCoverUploadFailed =>
      'O teu grupo está pronto, mas não foi possível carregar a foto de capa. Tenta de novo a partir do grupo.';

  @override
  String get groupsCreatePickLifestyle =>
      'Escolhe um estilo de vida para o teu grupo de comunidade.';

  @override
  String get groupsCreateNameTooShort =>
      'Dá ao teu grupo um nome com pelo menos 3 letras.';

  @override
  String get groupsCreateFailed =>
      'Não foi possível criar o teu grupo. Tenta de novo.';

  @override
  String get groupsCreateEyebrow => 'NOVO GRUPO';

  @override
  String get groupsCreateSubtitle => 'Junta pessoas à volta do que adoras.';

  @override
  String get groupsCreateSubtitleFriends =>
      'Transforma os teus amigos num grupo.';

  @override
  String get groupsCreateKindHeader => 'QUE TIPO';

  @override
  String get groupsKindCommunity => 'Grupo de comunidade';

  @override
  String get groupsKindPrivate => 'Grupo privado';

  @override
  String get groupsCreateCommunitySubtitle =>
      'Por estilo de vida. Qualquer pessoa o pode encontrar e entrar.';

  @override
  String get groupsCreatePrivateSubtitle =>
      'Só amigos. Só podem entrar as pessoas que convidares.';

  @override
  String get groupsCreateLifestyleHeader => 'ESTILO DE VIDA';

  @override
  String get groupsCreateLifestyleCaption =>
      'Onde as pessoas vão descobrir o teu grupo.';

  @override
  String get groupsCreateDetailsHeader => 'DETALHES';

  @override
  String get groupsCreateNameHintCommunity =>
      'Corredores do nascer do sol de Indiranagar';

  @override
  String get groupsCreateNameHintPrivate => 'A malta do brunch de domingo';

  @override
  String get groupsCreateCoverHeader => 'CAPA';

  @override
  String groupsCoverEmojiSemantics(String emoji) {
    return 'Emoji da capa $emoji';
  }

  @override
  String get groupsCreateCoverPhotoOptional => 'Foto de capa (opcional)';

  @override
  String get groupsCreateCoverPhotoHint =>
      'Os membros veem o emoji até a tua foto ser aprovada.';

  @override
  String get groupsCreateAddCoverPhoto => 'Adicionar uma foto de capa';

  @override
  String get groupsCreateChangePhoto => 'Alterar foto';

  @override
  String get groupsCreateRemovePhoto => 'Remover foto';

  @override
  String get groupsCreateFriendsHeader => 'AMIGOS';

  @override
  String get groupsCreateFriendsCaptionEmpty =>
      'Convida amigos agora ou mais tarde a partir do grupo.';

  @override
  String get groupsCreateFriendsCaption =>
      'Vão receber um convite para entrar.';

  @override
  String get groupsFriendFallback => 'Amigo';

  @override
  String groupsRemoveInvitee(String name) {
    return 'Remover $name';
  }

  @override
  String get groupsChooseFriends => 'Escolher amigos';

  @override
  String get groupsChangeFriends => 'Alterar amigos';

  @override
  String get groupsCreating => 'A criar…';

  @override
  String get groupsCreateGroup => 'Criar grupo';

  @override
  String get groupsCardRemoved => 'Removido após uma revisão';

  @override
  String groupsCardSemanticsMuted(String name, String details) {
    return '$name, $details, notificações silenciadas';
  }

  @override
  String get groupsNotificationsMuted => 'Notificações silenciadas';

  @override
  String groupsUnreadMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens por ler',
      one: '1 mensagem por ler',
    );
    return '$_temp0';
  }

  @override
  String get groupsCoverSheetTitle => 'Foto de capa';

  @override
  String get groupsCoverSheetBody =>
      'Cada foto é verificada antes de os outros membros a poderem ver. Usa um JPEG ou PNG até 10 MB.';

  @override
  String get groupsCoverFromPhotos => 'Escolher das tuas fotos';

  @override
  String get groupsCoverTakePhoto => 'Tirar uma foto';

  @override
  String get groupsCoverTooLarge =>
      'Essa foto tem mais de 10 MB. Escolhe uma mais pequena.';

  @override
  String get groupsCoverPreviewTitle => 'Pré-visualizar a capa';

  @override
  String get groupsCoverPreviewBody =>
      'As capas aparecem como um banner largo, mantendo o centro da tua foto.';

  @override
  String get groupsCancel => 'Cancelar';

  @override
  String get groupsCoverUseThisPhoto => 'Usar esta foto';

  @override
  String get groupsCoverPreviewSemantics => 'A tua nova foto de capa';

  @override
  String get groupsCoverChecking => 'A verificar a tua foto de capa…';

  @override
  String groupsCoverUploading(int percent) {
    return 'A carregar a foto de capa… $percent%';
  }

  @override
  String get groupsCoverUploadedReview =>
      'A tua capa está em revisão. Só tu a podes ver até ser aprovada.';

  @override
  String get groupsCoverUpdated => 'Foto de capa atualizada.';

  @override
  String get groupsPickerSubtitle =>
      'Só podes convidar pessoas da tua lista de amigos.';

  @override
  String get groupsDone => 'Concluído';

  @override
  String get groupsSearchFriends => 'Pesquisar amigos';

  @override
  String get groupsFriendsFailed => 'Não foi possível carregar os amigos';

  @override
  String get groupsNoFriendsTitle => 'Ainda não tens amigos';

  @override
  String get groupsNoFriendsBody =>
      'Adiciona amigos a partir de Matches, perfis ou salas e depois traz-os para um grupo.';

  @override
  String get groupsAlreadyMember => 'Já está neste grupo';

  @override
  String get groupsInvitationSent => 'Convite enviado';

  @override
  String get todayActivityCoffee => 'Um café';

  @override
  String get todayActivityWalk => 'Um passeio de dia';

  @override
  String get todayActivityMeal => 'Uma refeição';

  @override
  String get todayActivityPlayful => 'Algo divertido';

  @override
  String get todayActivityEvent => 'Um evento';

  @override
  String get todayActivityVideoCall => 'Um olá por vídeo';

  @override
  String get todayActivityDrinks => 'Uma bebida';

  @override
  String get todayActivityOther => 'Outra coisa';

  @override
  String get todayBudgetFlexible => 'Vamos decidir juntos';

  @override
  String get todayBudgetFree => 'Sem gastar nada';

  @override
  String get todayBudgetModest => 'Algo modesto';

  @override
  String get todayBudgetTreat => 'Um pequeno mimo';

  @override
  String get todayRhythmTitle => 'O teu ritmo de encontros';

  @override
  String get todayRhythmLoadFailed =>
      'Não foi possível carregar as tuas preferências.';

  @override
  String get todayRhythmSaved => 'O teu ritmo de encontros foi guardado.';

  @override
  String get todayRhythmSaveFailed =>
      'Não foi possível guardar. As tuas escolhas continuam aqui.';

  @override
  String get todayRhythmHeadline => 'Abre espaço à tua forma de ter encontros.';

  @override
  String get todayRhythmIntro =>
      'Escolhe o que encaixa na tua vida. A disponibilidade e as apresentações são opcionais, e podes mudar de ideias.';

  @override
  String get todayRhythmOpenTo => 'Para que estás aberto/a?';

  @override
  String get todayRhythmIntentNone => 'Prefiro não dizer';

  @override
  String get todayRhythmIntentRelationship => 'Uma relação';

  @override
  String get todayRhythmIntentExploring => 'Ainda a descobrir';

  @override
  String get todayRhythmIntentCasual => 'Algo descontraído';

  @override
  String get todayRhythmPaceSection => 'O teu ritmo de conversa';

  @override
  String get todayRhythmPaceNone => 'Sem preferência';

  @override
  String get todayRhythmPaceSlow => 'Um pouco mais devagar';

  @override
  String get todayRhythmPaceSteady => 'Uma conversa regular';

  @override
  String get todayRhythmPaceFrequent => 'Conversa frequente';

  @override
  String get todayRhythmSlowWeek => 'Respostas lentas esta semana';

  @override
  String get todayRhythmSlowWeekHint =>
      'Este estado desaparece ao fim de sete dias.';

  @override
  String get todayRhythmSharePace =>
      'Partilhar este estado com os meus matches';

  @override
  String get todayRhythmSharePaceHint =>
      'Só os teus matches atuais podem ver o teu estado temporário.';

  @override
  String get todayRhythmFirstDate => 'O teu tipo de primeiro encontro';

  @override
  String get todayRhythmChooseFive =>
      'Escolhe até cinco. As preferências em comum ajudam a explicar as tuas apresentações.';

  @override
  String get todayRhythmWeekSection => 'Um pouco de espaço na tua semana';

  @override
  String get todayRhythmShareAvailability =>
      'Usar a minha disponibilidade geral';

  @override
  String get todayRhythmShareAvailabilityHint =>
      'Só são mostradas sobreposições reais. A tua agenda completa é privada. Desativar esta opção apaga os horários guardados.';

  @override
  String get todayRhythmAvailabilityHint =>
      'Toca em qualquer manhã, tarde ou noite que te dê jeito. As horas usam a hora local deste dispositivo e expiram automaticamente.';

  @override
  String get todayRhythmMorning => 'Manhã';

  @override
  String get todayRhythmAfternoon => 'Tarde';

  @override
  String get todayRhythmEvening => 'Noite';

  @override
  String get todayRhythmIntrosSection => 'Apresentações com a tua autorização';

  @override
  String get todayRhythmFriendIntros =>
      'Permitir apresentações de amigos aceites';

  @override
  String get todayRhythmFriendIntrosHint =>
      'As duas pessoas têm de aceitar. O teu amigo não recebe atualizações de match nem de recusa. A pré-visualização inclui o teu nome e a tua idade.';

  @override
  String get todayRhythmIntroPhoto => 'Incluir as minhas fotos de perfil';

  @override
  String get todayRhythmIntroPhotoHint =>
      'Só a pessoa que recebe a apresentação as pode ver.';

  @override
  String get todayRhythmIntroCity => 'Incluir a minha cidade';

  @override
  String get todayRhythmIntroCityHint =>
      'A tua localização exata nunca é incluída.';

  @override
  String get todayRhythmReload => 'Recarregar escolhas guardadas';

  @override
  String get todayRhythmSaving => 'A guardar…';

  @override
  String get todayRhythmSave => 'Guardar o meu ritmo';

  @override
  String get todayRhythmBreakTitle => 'Fazer uma pausa está sempre bem.';

  @override
  String get todayRhythmBreakBody =>
      'Pausa as novas apresentações sempre que precisares. As tuas conversas atuais continuam disponíveis.';

  @override
  String get todayRhythmPauseFailed =>
      'Não foi possível atualizar a tua pausa.';

  @override
  String get todayRhythmResume => 'Retomar apresentações';

  @override
  String get todayRhythmPause => 'Pausar apresentações';

  @override
  String get datingConnectionSlowTitle => 'Responde com calma esta semana';

  @override
  String get datingConnectionSlowBody =>
      'O teu match está a dar espaço a um ritmo mais lento.';

  @override
  String get datingConnectionYourTurn => 'É a tua vez: acrescenta uma surpresa';

  @override
  String get datingConnectionComplete =>
      'O vosso primeiro capítulo está pronto';

  @override
  String get datingConnectionWaiting => 'O vosso capítulo já tem um início';

  @override
  String get datingConnectionCreate => 'Criem o vosso primeiro capítulo';

  @override
  String get datingConnectionBody =>
      'Um início, uma surpresa e uma história que constroem juntos.';

  @override
  String get chemistryTitle => 'Um pouco de química';

  @override
  String get chemistryIntro =>
      'Escolhe algo que tenha a ver contigo. Não há respostas certas, e isto nunca condiciona o acesso ao chat.';

  @override
  String get chemistrySaveFailed =>
      'Não foi possível guardar a tua escolha. Tenta novamente.';

  @override
  String get chemistryRetry => 'Tentar carregar novamente';

  @override
  String get chemistryRevealedTitle => 'As duas respostas, juntas';

  @override
  String get chemistryYouPicked => 'Escolheste';

  @override
  String get chemistryMatchPicked => 'O teu match escolheu';

  @override
  String get chemistryRevealedBody =>
      'Um favorito em comum ou uma diferença feliz: há assunto para conversar.';

  @override
  String get chemistryWaitingBody =>
      'A tua resposta está guardada em privado. As duas respostas aparecem aqui quando ambos tiverem escolhido.';

  @override
  String chemistryYourChoice(String choice) {
    return 'A tua escolha: $choice';
  }

  @override
  String get chemistryAnotherMoment => 'Outro momento, quando quiseres';

  @override
  String get chemistryChooseMoment => 'Escolhe um momento';

  @override
  String get chemistryPromptSunday => 'Constrói um domingo';

  @override
  String get chemistryPromptAdventure => 'Escolhe uma aventura';

  @override
  String get chemistryPromptFirstDate => 'O teu tipo de primeiro encontro';

  @override
  String get chemistryQuestionSunday => 'O teu domingo ideal começa com…';

  @override
  String get chemistryQuestionAdventure => 'Uma pequena aventura a dois…';

  @override
  String get chemistryQuestionFirstDate => 'Para um primeiro olá, escolherias…';

  @override
  String get engagementLevelFrozen =>
      'A progressão está em pausa enquanto decorre uma revisão de segurança da conta.';

  @override
  String get engagementLevelTrustGate =>
      'Verifica o teu perfil e mantém a conta em bom estado para desbloquear os níveis que exigem confiança.';

  @override
  String get engagementLevelPathTitle => 'Percurso de níveis';

  @override
  String get engagementLevelPathSubtitle =>
      'A XP vem da atividade relevante. As compras nunca aumentam o teu nível.';

  @override
  String get engagementLevelRewardsTitle => 'Recompensas';

  @override
  String get engagementLevelRewardsSubtitle =>
      'As recompensas são estéticas, de conveniência ou benefícios de visibilidade limitados.';

  @override
  String get engagementLevelRecentTitle => 'XP recente';

  @override
  String get engagementLevelRecentSubtitle =>
      'O teu registo de atividade é permanente e verificável.';

  @override
  String engagementLevelNumber(int level) {
    return 'Nível $level';
  }

  @override
  String engagementLevelXp(String xp) {
    return '$xp XP';
  }

  @override
  String get engagementLevelHighest => 'Nível máximo alcançado';

  @override
  String engagementLevelProgress(int xp, String percent) {
    return '$xp XP neste nível · $percent%';
  }

  @override
  String engagementLevelThreshold(int xp, String summary) {
    return '$xp XP · $summary';
  }

  @override
  String get engagementLevelTrustGated => 'Exige confiança';

  @override
  String get engagementLevelClaimed => 'Resgatada';

  @override
  String get engagementLevelClaim => 'Resgatar';

  @override
  String get engagementLevelLocked => 'Bloqueada';

  @override
  String get engagementLevelStandardAward => 'Atribuição normal';

  @override
  String engagementLevelQualityWeighting(String multiplier) {
    return 'Ponderação de qualidade ×$multiplier';
  }

  @override
  String get engagementLevelEmptyLedger =>
      'Conclui atividades relevantes para ganhar a tua primeira XP.';

  @override
  String get engagementXpSourceProfileCompleted => 'Perfil concluído';

  @override
  String get engagementXpSourceDailyPromptSubmitted =>
      'Pergunta diária respondida';

  @override
  String get engagementXpSourceMiniActivityCompleted =>
      'Miniatividade concluída';

  @override
  String get engagementXpSourceCircleChallengeSubmitted =>
      'Desafio do círculo enviado';

  @override
  String get engagementXpSourceVoiceIcebreakerPlayed =>
      'Quebra-gelo de voz ouvido';

  @override
  String get engagementXpSourceStreak3 => 'Sequência de 3 dias';

  @override
  String get engagementXpSourceStreak7 => 'Sequência de 7 dias';

  @override
  String get engagementXpSourceStreak14 => 'Sequência de 14 dias';

  @override
  String get engagementXpSourceAdminAdjustment => 'Ajuste da equipa';

  @override
  String get engagementLevelSignIn =>
      'Inicia sessão para veres o progresso do teu nível.';

  @override
  String get engagementLevelLoadFailed =>
      'Não é possível carregar o teu progresso neste momento.';

  @override
  String get engagementLevelClaimFailed =>
      'Não é possível resgatar esta recompensa neste momento.';

  @override
  String get engagementCoffeeTitle => 'Sondagens de café em grupo';

  @override
  String get engagementCoffeeCreateHeading =>
      'Cria uma sondagem simples para um café em grupo';

  @override
  String get engagementCoffeeCreateHint =>
      'Adiciona até 3 IDs de participantes (separados por vírgulas) e pelo menos uma opção.';

  @override
  String get engagementCoffeeParticipantsLabel =>
      'IDs dos participantes (separados por vírgulas)';

  @override
  String get engagementCoffeeDeadlineLabel => 'Prazo ISO (opcional)';

  @override
  String engagementCoffeeOptionNumber(int number) {
    return 'Opção $number';
  }

  @override
  String get engagementCoffeeCreate => 'Criar sondagem';

  @override
  String get engagementCoffeeActorLabel =>
      'ID de utilizador alternativo para a ação (opcional)';

  @override
  String get engagementCoffeeEmpty => 'Ainda não há sondagens. Cria uma acima.';

  @override
  String engagementCoffeePollId(String id) {
    return 'Sondagem $id';
  }

  @override
  String engagementCoffeeStatus(String status) {
    return 'Estado: $status';
  }

  @override
  String get engagementCoffeeStatusOpen => 'aberta';

  @override
  String get engagementCoffeeStatusFinalized => 'fechada';

  @override
  String engagementCoffeeParticipants(String ids) {
    return 'Participantes: $ids';
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
      other: '$day · $time · $area ($count votos)',
      one: '$day · $time · $area (1 voto)',
    );
    return '$_temp0';
  }

  @override
  String get engagementCoffeeVote => 'Votar';

  @override
  String get engagementCoffeeFinalize => 'Fechar sondagem';

  @override
  String get engagementCoffeeDayLabel => 'Dia';

  @override
  String get engagementCoffeeTimeLabel => 'Horário';

  @override
  String get engagementCoffeeAreaLabel => 'Bairro';

  @override
  String get engagementCoffeeLoadFailed =>
      'Não é possível carregar as sondagens de grupo neste momento.';

  @override
  String get engagementCoffeeCreateFailed =>
      'Não é possível criar a sondagem de grupo neste momento.';

  @override
  String get engagementCoffeeVoteUserRequired =>
      'É necessário um ID de utilizador para votar.';

  @override
  String get engagementCoffeeVoteFailed =>
      'Não é possível votar neste momento.';

  @override
  String get engagementCoffeeFinalizeUserRequired =>
      'É necessário um ID de utilizador para fechar.';

  @override
  String get engagementCoffeeFinalizeFailed =>
      'Não é possível fechar a sondagem neste momento.';

  @override
  String get engagementDailyPromptUnavailable => 'Pergunta diária indisponível';

  @override
  String get engagementDailyPromptPullToRefresh =>
      'Puxa para atualizar ou tenta de novo daqui a pouco.';

  @override
  String get engagementDailyPromptDomainValues => 'VALORES';

  @override
  String get engagementDailyPromptDomainLifestyle => 'ESTILO DE VIDA';

  @override
  String get engagementDailyPromptDomainRelationshipStyle =>
      'ESTILO DE RELAÇÃO';

  @override
  String get engagementDailyPromptSparkTitle => 'Faísca de compatibilidade';

  @override
  String engagementDailyPromptSparkSummary(int replied, int similar) {
    return 'Respostas hoje: $replied · respostas parecidas: $similar';
  }

  @override
  String get engagementDailyPromptYourAnswer => 'A tua resposta';

  @override
  String get engagementDailyPromptHint =>
      'Escreve a tua resposta em menos de 60 segundos.';

  @override
  String engagementDailyPromptEditOpenUntil(String time) {
    return 'Podes editar até às $time';
  }

  @override
  String get engagementDailyPromptEditOpenSoon =>
      'Podes editar só por mais um pouco';

  @override
  String get engagementDailyPromptEditClosed => 'Já não podes editar hoje.';

  @override
  String get engagementDailyPromptEdited => 'Editada';

  @override
  String get engagementDailyPromptSubmit => 'Enviar resposta diária';

  @override
  String get engagementDailyPromptUpdate => 'Atualizar resposta';

  @override
  String get engagementDailyPromptStreakProgress => 'Progresso da sequência';

  @override
  String engagementDailyPromptStatCurrent(String value) {
    return 'Atual: $value';
  }

  @override
  String engagementDailyPromptStatBest(String value) {
    return 'Recorde: $value';
  }

  @override
  String engagementDailyPromptStatNext(String value) {
    return 'Seguinte: $value';
  }

  @override
  String engagementDailyPromptDays(int days) {
    return '$days d';
  }

  @override
  String get engagementDailyPromptComplete => 'Concluído';

  @override
  String engagementDailyPromptMilestone(int days) {
    return 'Marco desbloqueado: sequência de $days dias';
  }

  @override
  String get engagementDailyPromptLoadFailed =>
      'Não é possível carregar a pergunta diária neste momento.';

  @override
  String get engagementDailyPromptNotLoaded =>
      'A pergunta diária ainda não foi carregada.';

  @override
  String get engagementDailyPromptEnterAnswer =>
      'Escreve primeiro uma resposta.';

  @override
  String get engagementDailyPromptSubmitFailed =>
      'Não foi possível enviar a resposta. Tenta de novo.';

  @override
  String get clubsKindBooks => 'Livros';

  @override
  String get clubsKindFilms => 'Filmes';

  @override
  String get clubsFilterAll => 'Todos';

  @override
  String get clubsAudiencePrivate => 'Só eu';

  @override
  String get clubsAudienceFriends => 'Amigos';

  @override
  String get clubsAudienceCommunity => 'Comunidade Connect';

  @override
  String get clubsRoleOwner => 'Responsável';

  @override
  String get clubsRoleModerator => 'Moderador';

  @override
  String get clubsRoleMember => 'Membro';

  @override
  String get clubsBadgeBookClub => 'Clube do livro';

  @override
  String get clubsBadgeFilmClub => 'Clube de cinema';

  @override
  String get clubsBadgeBookList => 'Lista de livros';

  @override
  String get clubsBadgeFilmList => 'Lista de filmes';

  @override
  String get clubsBadgeBook => 'Livro';

  @override
  String get clubsBadgeFilm => 'Filme';

  @override
  String get clubsClub => 'Clube';

  @override
  String clubsStarsOutOfFive(String rating) {
    return '$rating de 5 estrelas';
  }

  @override
  String clubsStarCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrelas',
      one: '1 estrela',
    );
    return '$_temp0';
  }

  @override
  String get clubsNoRatingsYet => 'Ainda sem avaliações';

  @override
  String clubsRatingSummary(String average, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count críticas',
      one: '1 crítica',
    );
    return '$average · $_temp0';
  }

  @override
  String get clubsWeekThis => 'Esta semana';

  @override
  String get clubsWeekNext => 'Próxima semana';

  @override
  String get clubsWeekLast => 'Semana passada';

  @override
  String clubsWeekOf(String date) {
    return 'Semana de $date';
  }

  @override
  String get clubsTitle => 'Clubes de livros e cinema';

  @override
  String get clubsMyLists => 'As minhas listas';

  @override
  String get clubsStartClubTooltip => 'Cria um clube de livros ou de cinema';

  @override
  String get clubsStartClub => 'Criar um clube';

  @override
  String get clubsSignInToSee => 'Inicia sessão para ver os clubes.';

  @override
  String get clubsHeroTitle => 'Lê. Vê. Conversa sobre isso.';

  @override
  String get clubsHeroSubtitle =>
      'Junta-te a um clube, acompanha uma escolha por semana e partilha o que achaste. Bom gosto é um ótimo início de conversa.';

  @override
  String get clubsScopeMine => 'Os meus clubes';

  @override
  String get clubsScopeDiscover => 'Descobrir';

  @override
  String get clubsLoadErrorTitle => 'Não foi possível carregar os clubes';

  @override
  String get clubsCheckConnection => 'Verifica a tua ligação.';

  @override
  String get clubsLookAroundTitle => 'Podes dar uma vista de olhos';

  @override
  String get clubsLookAroundMessage =>
      'Completa o teu perfil com duas fotos aprovadas para criar um clube ou juntar-te a um.';

  @override
  String get clubsEmptyMineTitle => 'O teu primeiro clube está à espera';

  @override
  String get clubsEmptyMineMessage =>
      'Encontra um clube que lê ou vê aquilo de que gostas, ou cria o teu.';

  @override
  String get clubsEmptyDiscoverTitle => 'Ainda não há clubes aqui';

  @override
  String get clubsEmptyDiscoverMessage =>
      'Dá o primeiro passo: cria um clube e escolhe algo incrível para esta semana.';

  @override
  String get clubsDiscoverClubs => 'Descobrir clubes';

  @override
  String clubsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membros',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String get clubsYouRunIt => 'És tu que geres';

  @override
  String get clubsYouModerate => 'Moderas tu';

  @override
  String get clubsJoined => 'Aderiste ✓';

  @override
  String get clubsNoPickThisWeek => 'Ainda sem escolha esta semana';

  @override
  String get clubsNameTooShort =>
      'Dá ao teu clube um nome com pelo menos 3 letras.';

  @override
  String get clubsCreateFailed => 'Não foi possível criar o teu clube.';

  @override
  String get clubsNameLabel => 'Nome do clube';

  @override
  String get clubsNameHint => 'Leituras lentas de domingo';

  @override
  String get clubsDescriptionLabel => 'Sobre o que é o teu clube? (opcional)';

  @override
  String get clubsCreating => 'A criar…';

  @override
  String get clubsCreateClub => 'Criar clube';

  @override
  String clubsLeaveTitle(String name) {
    return 'Sair de $name?';
  }

  @override
  String get clubsLeaveMessage =>
      'Podes voltar mais tarde enquanto o clube estiver aberto.';

  @override
  String get clubsLeaveClub => 'Sair do clube';

  @override
  String clubsWelcome(String name) {
    return 'Boas-vindas a $name!';
  }

  @override
  String get clubsChangeNotSaved => 'Não foi possível guardar essa alteração.';

  @override
  String get clubsOptionsTooltip => 'Opções do clube';

  @override
  String get clubsMembers => 'Membros';

  @override
  String get clubsReportClub => 'Denunciar clube';

  @override
  String get clubsDetailLoadErrorTitle =>
      'Não foi possível carregar este clube';

  @override
  String get clubsDetailLoadErrorMessage =>
      'Pode ter sido fechado. Tenta de novo.';

  @override
  String get clubsEarlierPicks => 'Escolhas anteriores';

  @override
  String clubsPickSubtitle(String week, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count publicações',
      one: '1 publicação',
    );
    return '$week · $_temp0';
  }

  @override
  String get clubsOpenDiscussion => 'Abrir a discussão';

  @override
  String get clubsJoinToSeeTitle => 'Junta-te para ver a discussão';

  @override
  String get clubsJoinToSeeMessage =>
      'Os membros conversam juntos sobre cada escolha. Junta-te ao clube para acompanhar e partilhar o que pensas.';

  @override
  String clubsYouRole(String role) {
    return 'Tu: $role';
  }

  @override
  String get clubsRemovedByModeration =>
      'Este clube foi removido pela moderação.';

  @override
  String get clubsJoinClub => 'Aderir ao clube';

  @override
  String get clubsNoPickModerator =>
      'Ainda sem escolha. Escolhe algo incrível para todos.';

  @override
  String get clubsNoPickMember => 'Ainda sem escolha. Volta em breve.';

  @override
  String clubsQuotedNote(String note) {
    return '«$note»';
  }

  @override
  String clubsPostsInDiscussion(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count publicações na discussão',
      one: '1 publicação na discussão',
    );
    return '$_temp0';
  }

  @override
  String get clubsSetThisWeeksPick => 'Definir a escolha desta semana';

  @override
  String get clubsDiscussThisPick => 'Discutir esta escolha';

  @override
  String get clubsPostNotSent => 'Não foi possível enviar a tua publicação.';

  @override
  String clubsDiscussionHeading(String title) {
    return 'Discussão · $title';
  }

  @override
  String get clubsDiscussionLoadError =>
      'Não foi possível carregar a discussão';

  @override
  String get clubsStartConversationTitle => 'Começa a conversa';

  @override
  String get clubsStartConversationMessage =>
      'O que achaste até agora? A tua publicação pode ser a que põe toda a gente a falar.';

  @override
  String get clubsLoadMorePosts => 'Carregar mais publicações';

  @override
  String get clubsComposerLabel => 'Participa na discussão';

  @override
  String get clubsComposerHint => 'Momento favorito? Maior surpresa?';

  @override
  String get clubsContainsSpoilers => 'Contém spoilers';

  @override
  String get clubsSpoilersSubtitle => 'Os outros tocam para a ver.';

  @override
  String get clubsPosting => 'A publicar…';

  @override
  String get clubsPost => 'Publicar';

  @override
  String get clubsDeletePostTitle => 'Apagar a tua publicação?';

  @override
  String get clubsDeletePostMessage => 'Será removida da discussão para todos.';

  @override
  String get clubsActionFailed => 'Não foi possível concluir essa ação.';

  @override
  String get clubsHideFromMembers => 'Ocultar aos membros';

  @override
  String get clubsShowToMembers => 'Mostrar aos membros';

  @override
  String get clubsReport => 'Denunciar';

  @override
  String get clubsYou => 'Tu';

  @override
  String get clubsHidden => 'Oculta';

  @override
  String get clubsPostActions => 'Ações da publicação';

  @override
  String get clubsMakeModerator => 'Tornar moderador';

  @override
  String get clubsMakeMember => 'Tornar membro';

  @override
  String get clubsRemoveFromClub => 'Remover do clube';

  @override
  String clubsRemoveMemberTitle(String name) {
    return 'Remover $name?';
  }

  @override
  String get clubsRemoveMemberMessage =>
      'Esta pessoa sai do clube e não pode voltar. As publicações anteriores ficam na discussão.';

  @override
  String get clubsRemove => 'Remover';

  @override
  String get clubsMembersLoadError => 'Não foi possível carregar os membros.';

  @override
  String clubsMemberYou(String name) {
    return '$name (tu)';
  }

  @override
  String clubsMemberActions(String name) {
    return 'Ações para $name';
  }

  @override
  String get clubsChooseFilm => 'Escolhe um filme';

  @override
  String get clubsChooseBook => 'Escolhe um livro';

  @override
  String get clubsChooseTitle => 'Escolhe um título';

  @override
  String get clubsChooseTitleFirst => 'Escolhe primeiro um título.';

  @override
  String get clubsPickNotSaved => 'Não foi possível guardar a escolha.';

  @override
  String get clubsSetWeeklyPick => 'Definir a escolha da semana';

  @override
  String get clubsChange => 'Trocar';

  @override
  String get clubsPickNoteLabel => 'Uma nota para o clube (opcional)';

  @override
  String get clubsPickNoteHint => 'Porquê este? Por onde começar?';

  @override
  String get clubsSaving => 'A guardar…';

  @override
  String get clubsSavePick => 'Guardar escolha';

  @override
  String get clubsListNameRequired => 'Dá um nome à tua lista.';

  @override
  String get clubsListNotSaved => 'Não foi possível guardar a tua lista.';

  @override
  String get clubsEditList => 'Editar lista';

  @override
  String get clubsNewList => 'Nova lista';

  @override
  String get clubsListNameLabel => 'Nome da lista';

  @override
  String get clubsListNameHint => 'Livros que me fizeram mudar de ideias';

  @override
  String get clubsWhoCanSee => 'Quem pode ver';

  @override
  String get clubsSave => 'Guardar';

  @override
  String get clubsCreateList => 'Criar lista';

  @override
  String get clubsYourNote => 'A tua nota';

  @override
  String get clubsNoteLabel => 'Porque está nesta lista';

  @override
  String get clubsSaveNote => 'Guardar nota';

  @override
  String get clubsCreateNewListTooltip => 'Criar uma nova lista';

  @override
  String get clubsSignInToSeeLists => 'Inicia sessão para ver as tuas listas.';

  @override
  String get clubsShelfTitle => 'A tua estante';

  @override
  String get clubsShelfSubtitle =>
      'Acompanha o que adoraste e o que vem a seguir. Partilha uma lista ou guarda-a só para ti.';

  @override
  String get clubsListsLoadErrorTitle =>
      'Não foi possível carregar as tuas listas';

  @override
  String get clubsFirstListTitle => 'Cria a tua primeira lista';

  @override
  String get clubsFirstListMessage =>
      'Filmes favoritos, livros para ler a seguir, filmes para rever: tu decides.';

  @override
  String clubsAddToNamed(String name) {
    return 'Adicionar a $name';
  }

  @override
  String get clubsAddToThisListFailed =>
      'Não foi possível adicionar a esta lista.';

  @override
  String clubsDeleteListTitle(String name) {
    return 'Apagar $name?';
  }

  @override
  String get clubsDeleteListMessage =>
      'A lista e as notas são removidas. Isto não pode ser desfeito.';

  @override
  String get clubsDeleteList => 'Apagar lista';

  @override
  String get clubsListDeleteFailed =>
      'Não foi possível apagar a lista. Recarrega e tenta de novo.';

  @override
  String get clubsNoteNotSaved => 'Não foi possível guardar a tua nota.';

  @override
  String get clubsRemoveFailed => 'Não foi possível remover.';

  @override
  String get clubsListOptions => 'Opções da lista';

  @override
  String get clubsAddATitle => 'Adicionar um título';

  @override
  String clubsTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count títulos',
      one: '1 título',
    );
    return '$_temp0';
  }

  @override
  String get clubsListEmpty =>
      'Ainda não há nada aqui. Usa «Adicionar um título» no menu da lista.';

  @override
  String clubsItemOptions(String title) {
    return 'Opções para $title';
  }

  @override
  String get clubsAddNote => 'Adicionar uma nota';

  @override
  String get clubsEditNote => 'Editar nota';

  @override
  String get clubsRemoveFromList => 'Remover da lista';

  @override
  String get clubsTapStarError => 'Toca numa estrela para avaliar.';

  @override
  String get clubsReviewNotSaved => 'Não foi possível guardar a tua crítica.';

  @override
  String get clubsWriteReview => 'Escrever uma crítica';

  @override
  String get clubsEditYourReview => 'Editar a tua crítica';

  @override
  String get clubsTapStarToRate => 'Toca numa estrela para avaliar';

  @override
  String clubsRatingOutOfFive(int rating) {
    return '$rating de 5';
  }

  @override
  String get clubsReviewBodyLabel => 'O que achaste? (opcional)';

  @override
  String get clubsSaveReview => 'Guardar crítica';

  @override
  String clubsAddedToList(String name) {
    return 'Adicionado a $name.';
  }

  @override
  String get clubsAddToThatListFailed =>
      'Não foi possível adicionar a essa lista.';

  @override
  String get clubsAddToAList => 'Adicionar a uma lista';

  @override
  String get clubsListsLoadError => 'Não foi possível carregar as tuas listas.';

  @override
  String get clubsNoFilmLists =>
      'Ainda não tens listas de filmes. Cria uma para começar a colecionar.';

  @override
  String get clubsNoBookLists =>
      'Ainda não tens listas de livros. Cria uma para começar a colecionar.';

  @override
  String get clubsTitleFallback => 'Título';

  @override
  String get clubsSignInToSeeReviews => 'Inicia sessão para ver as críticas.';

  @override
  String get clubsTitleLoadError => 'Não foi possível carregar este título';

  @override
  String get clubsReviews => 'Críticas';

  @override
  String get clubsNoOtherReviewsTitle => 'Ainda não há outras críticas';

  @override
  String get clubsNoOtherReviewsMessage =>
      'Quando membros que podes ver partilharem uma crítica, ela aparece aqui.';

  @override
  String get clubsDeleteReviewTitle => 'Apagar a tua crítica?';

  @override
  String get clubsDeleteReviewMessage =>
      'A tua avaliação e o teu texto são removidos para todos.';

  @override
  String get clubsDeleteReview => 'Apagar crítica';

  @override
  String get clubsReviewDeleteFailed =>
      'Não foi possível apagar a tua crítica. Recarrega e tenta de novo.';

  @override
  String get clubsWhatDidYouThink => 'O que achaste?';

  @override
  String get clubsReviewPrompt => 'Avalia e diz porquê. Tu escolhes quem vê.';

  @override
  String get clubsYourReview => 'A tua crítica';

  @override
  String get clubsSpoilers => 'Spoilers';

  @override
  String get clubsEdit => 'Editar';

  @override
  String get clubsReportReview => 'Denunciar esta crítica';

  @override
  String get clubsEnterTitle => 'Introduz o título.';

  @override
  String get clubsYearRange => 'Introduz um ano entre 1450 e 2100.';

  @override
  String get clubsTitleAddFailed => 'Não foi possível adicionar o título.';

  @override
  String get clubsSearchFilms => 'Pesquisar filmes';

  @override
  String get clubsSearchBooks => 'Pesquisar livros';

  @override
  String get clubsTypeTwoLetters => 'Escreve pelo menos 2 letras';

  @override
  String get clubsSearchUnavailable => 'A pesquisa não está disponível.';

  @override
  String get clubsNoFilmsMatch =>
      'Nenhum filme corresponde. Adiciona-o abaixo.';

  @override
  String get clubsNoBooksMatch =>
      'Nenhum livro corresponde. Adiciona-o abaixo.';

  @override
  String get clubsAddNewFilm => 'Adicionar um novo filme';

  @override
  String get clubsAddNewBook => 'Adicionar um novo livro';

  @override
  String get clubsTitleFieldLabel => 'Título';

  @override
  String get clubsDirector => 'Realização';

  @override
  String get clubsAuthor => 'Autor';

  @override
  String get clubsYearOptional => 'Ano (opcional)';

  @override
  String get clubsAdding => 'A adicionar…';

  @override
  String get clubsAddAndChoose => 'Adicionar e escolher';

  @override
  String get friendsIntroducerSaveFailed =>
      'Não conseguimos guardar. Atualiza para ver as autorizações mais recentes antes de tentares de novo.';

  @override
  String friendsIntroducerRevokeTitle(String name) {
    return 'Retirar a autorização a $name?';
  }

  @override
  String get friendsIntroducerRevokeBody =>
      'As apresentações novas e sem resposta param. Um match mútuo que já exista fica entre as duas pessoas.';

  @override
  String get friendsIntroducerKeepPermission => 'Manter a autorização';

  @override
  String get friendsIntroducerRemovePermission => 'Retirar autorização';

  @override
  String get friendsIntroducerPermissionRemoved => 'Autorização retirada.';

  @override
  String get friendsIntroducerMemberTitle => 'Os teus cupidos';

  @override
  String get friendsIntroducerAppTitle => 'Connect · Amigos';

  @override
  String get friendsIntroducerRefresh => 'Atualizar autorizações';

  @override
  String get friendsIntroducerAccount => 'Conta';

  @override
  String get friendsIntroducerAccountPrivacy => 'Conta e privacidade';

  @override
  String get friendsIntroducerSignOut => 'Terminar sessão';

  @override
  String get friendsIntroducerMemberHeadline => 'Bons amigos. Tu decides.';

  @override
  String get friendsIntroducerHeadline =>
      'Conheces estas pessoas.\nVês a possibilidade.';

  @override
  String get friendsIntroducerMemberIntro =>
      'Convida alguém em quem confias para te apresentar. Pode juntar-se sem perfil de encontros. Tu decides quem tem autorização e o que uma pré-visualização mostra.';

  @override
  String get friendsIntroducerIntro =>
      'Um pouco de atenção pode começar algo verdadeiro. Junta amigos que te pediram ajuda.';

  @override
  String get friendsIntroducerMemberListTitle => 'Pessoas que escolhes';

  @override
  String get friendsIntroducerListTitle => 'O teu pequeno círculo';

  @override
  String get friendsIntroducerLoadFailed =>
      'Não conseguimos carregar as autorizações. Nada foi alterado.';

  @override
  String get friendsIntroducerMemberEmpty =>
      'Ainda não tens cupidos. Partilha um convite com um amigo de confiança para começar.';

  @override
  String get friendsIntroducerEmpty =>
      'O teu círculo começa com uma autorização. Pede a um amigo no Connect o código de convite dele.';

  @override
  String get friendsIntroducerStatusPendingMember =>
      'Pede a tua autorização para te apresentar.';

  @override
  String get friendsIntroducerStatusPending =>
      'À espera da aprovação do teu amigo.';

  @override
  String get friendsIntroducerStatusPaused =>
      'As apresentações estão em pausa.';

  @override
  String get friendsIntroducerStatusActive =>
      'Tem autorização para sugerir apresentações.';

  @override
  String friendsIntroducerPreview(String extras) {
    String _temp0 = intl.Intl.selectLogic(extras, {
      'photo':
          'Pré-visualização para um encontro sugerido: nome e idade opcional, foto.',
      'city':
          'Pré-visualização para um encontro sugerido: nome e idade opcional, cidade.',
      'both':
          'Pré-visualização para um encontro sugerido: nome e idade opcional, foto, cidade.',
      'other':
          'Pré-visualização para um encontro sugerido: nome e idade opcional.',
    });
    return '$_temp0';
  }

  @override
  String get friendsIntroducerApproveNote =>
      'Aprovar também ativa as apresentações por amigos. Podes pausar todas as apresentações em Ritmo de encontros.';

  @override
  String get friendsIntroducerAllow => 'Permitir apresentações';

  @override
  String friendsIntroducerAllowed(String name) {
    return '$name tem agora a tua autorização.';
  }

  @override
  String get friendsIntroducerDecline => 'Recusar pedido';

  @override
  String get friendsIntroducerSentTitle => 'Enviadas com cuidado';

  @override
  String get friendsIntroducerSentBody =>
      'As respostas ficam entre eles. Os dois têm de dizer que sim para haver match.';

  @override
  String get friendsIntroducerReloadSent => 'Recarregar apresentações enviadas';

  @override
  String get friendsIntroducerSentSubtitle =>
      'Enviada · a decisão deles é privada';

  @override
  String get friendsIntroducerStepPreview => '1. Escolhe a pré-visualização';

  @override
  String get friendsIntroducerPreviewBody =>
      'Um encontro sugerido vê o teu nome e a tua idade, se já a mostras. O teu cupido só vê o teu nome, nunca o teu perfil nem a tua atividade de encontros.';

  @override
  String get friendsIntroducerIncludePhoto => 'Incluir a minha foto de perfil';

  @override
  String get friendsIntroducerIncludeCity => 'Incluir a minha cidade';

  @override
  String get friendsIntroducerStepInvite => '2. Convida um amigo de confiança';

  @override
  String get friendsIntroducerInviteBody =>
      'O código funciona uma vez e expira em 48 horas. O teu amigo entra através de «Só para apresentar amigos» no ecrã de boas-vindas. Vais aprovar o nome dele aqui antes de qualquer coisa ser partilhada.';

  @override
  String get friendsIntroducerInviteReady =>
      'Convite pronto. Os códigos anteriores não usados deixam de funcionar.';

  @override
  String get friendsIntroducerCreateCode => 'Criar código de convite';

  @override
  String get friendsIntroducerShareCode =>
      'Partilha-o em privado com o teu amigo. Para mudar esta pré-visualização, cancela o convite não usado e cria um código novo.';

  @override
  String get friendsIntroducerCodeCopied => 'Código de convite copiado';

  @override
  String get friendsIntroducerCopyCode => 'Copiar código';

  @override
  String get friendsIntroducerInvitesCancelled =>
      'Convites não usados cancelados.';

  @override
  String get friendsIntroducerCancelInvites => 'Cancelar convites não usados';

  @override
  String get friendsIntroducerManagePrefs =>
      'Gerir todas as preferências de apresentações';

  @override
  String get friendsIntroducerRedeemTitle => 'Um amigo convidou-te?';

  @override
  String get friendsIntroducerRedeemBody =>
      'Cola o código de convite privado. A pessoa vai confirmar o teu nome antes de a poderes apresentar.';

  @override
  String get friendsIntroducerCodeLabel => 'Código de convite';

  @override
  String get friendsIntroducerCodeMissing =>
      'Escreve o código de convite que o teu amigo partilhou.';

  @override
  String get friendsIntroducerRequestSent =>
      'Pedido enviado. O teu amigo pode agora aprovar-te em «Os teus cupidos».';

  @override
  String get friendsIntroducerAskPermission => 'Pedir autorização';

  @override
  String get friendsIntroducerNeedTwo =>
      'Quando dois amigos te derem autorização, podes sugerir uma apresentação aqui.';

  @override
  String get friendsIntroducerComposerTitle => 'Vês uma possibilidade?';

  @override
  String get friendsIntroducerWhyLabel => 'Porque pensaste neles (opcional)';

  @override
  String get friendsIntroducerWhyHelper =>
      'Os dois vão ver isto. Deixa de fora detalhes privados.';

  @override
  String get friendsIntroducerIntroSent =>
      'Apresentação enviada. Cada um pode decidir em privado.';

  @override
  String get friendsIntroducerSuggest => 'Sugerir uma apresentação';

  @override
  String get friendsIntroducerPrivacyNote =>
      'Primeiro a autorização. Sem atividade de encontros pública. Sem atualizações sobre quem disse sim ou não.';

  @override
  String get planSharingLoadFailed =>
      'Não foi possível carregar as opções de partilha.';

  @override
  String get planSharingOffSnack => 'A partilha com contactos está desativada.';

  @override
  String get planSharingSavedSnack =>
      'Os contactos que escolheste já podem ver este plano.';

  @override
  String get planSharingSaveFailed =>
      'Não foi possível guardar. Recarrega as opções antes de tentares de novo.';

  @override
  String get planSharingTitle => 'O teu plano. A tua gente.';

  @override
  String get planSharingCloseTooltip => 'Fechar partilha';

  @override
  String get planSharingIntro =>
      'A partilha com contactos começa desativada. Escolhe até 10 amigos de confiança para este plano. A outra pessoa escolhe os seus próprios contactos.';

  @override
  String get planSharingNoContacts =>
      'Ainda não há amigos elegíveis. O teu plano continua disponível para ti e para a outra pessoa.';

  @override
  String get planSharingFriendFallback => 'Um amigo';

  @override
  String get planSharingPreviewNone =>
      'Pré-visualização · nenhum contacto selecionado';

  @override
  String planSharingPreviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pré-visualização · $count selecionados',
      one: 'Pré-visualização · $count selecionado',
    );
    return '$_temp0';
  }

  @override
  String get planSharingPreviewOffBody =>
      'Os teus amigos não vão receber atualizações do plano nem dos check-ins.';

  @override
  String get planSharingPreviewOnBody =>
      'Estes contactos veem o nome da outra pessoa, a hora e o local, o estado do plano e os teus check-ins. Recebem o plano atual quando guardares.';

  @override
  String get planSharingPrivacyNote =>
      'As mensagens e a tua opinião privada depois do encontro continuam privadas. Remover um contacto para as próximas atualizações e retira-lhe o acesso ao plano na app. As atualizações já entregues num dispositivo não podem ser anuladas.';

  @override
  String get planSharingReload => 'Recarregar opções de partilha';

  @override
  String get planSharingSaving => 'A guardar…';

  @override
  String get planSharingKeepOff => 'Manter a partilha desativada';

  @override
  String get planSharingShareSelected =>
      'Partilhar com os contactos escolhidos';

  @override
  String get planSharingDeselectAll => 'Desmarcar todos';

  @override
  String planBudgetLine(String budget) {
    return 'Orçamento · $budget';
  }

  @override
  String planAtmosphereLine(String atmospheres) {
    return 'Ambiente · $atmospheres';
  }

  @override
  String get planAtmosphereQuiet => 'Conversa tranquila';

  @override
  String get planAtmosphereRelaxed => 'Descontraído e sem pressas';

  @override
  String get planAtmosphereLively => 'Um sítio animado';

  @override
  String get planAtmosphereOutdoors => 'Ao ar livre';

  @override
  String get planAtmosphereIndoors => 'Em interior';

  @override
  String get planAccessStepFree => 'Acesso sem degraus';

  @override
  String get planAccessToilet => 'Casa de banho acessível';

  @override
  String get planAccessSeating => 'Lugares sentados disponíveis';

  @override
  String get planAccessLowNoise => 'Pouco ruído de fundo';

  @override
  String get planAccessTransit => 'Perto de transportes públicos';

  @override
  String get planAccessCaptions => 'Legendas num encontro por vídeo';

  @override
  String get planComfortHeading => 'Para ser confortável';

  @override
  String get planPreferencesDisclaimer =>
      'Preferências partilhadas para este plano. Confirma estes detalhes com o local ou o serviço de vídeo.';

  @override
  String get planProposeErrorKept =>
      'Não foi possível enviar o teu plano. As tuas escolhas continuam aqui.';

  @override
  String get planChangedError =>
      'Este plano mudou. Fecha esta janela para rever a conversa.';

  @override
  String get planProposeHeadline => 'Um plano que entusiasme os dois.';

  @override
  String get planCounterHeadline => 'Construam este plano juntos';

  @override
  String planProposeLead(String name) {
    return 'Uma sugestão para ti e $name. Nada fica combinado até a outra pessoa aceitar esta versão.';
  }

  @override
  String get planFindTimeTitle => 'Encontrem um tempo juntos';

  @override
  String get planFindTimeBody =>
      'Só aparecem horários em comum quando os dois partilham a disponibilidade. Podes sempre sugerir uma hora tu.';

  @override
  String get planSharedTimesFailed =>
      'Não foi possível carregar os horários em comum. Podes continuar a escolher uma hora manualmente.';

  @override
  String get planSharedTimesEmpty =>
      'De momento não há sugestões de horários em comum. Isso não quer dizer que algum de vocês esteja indisponível.';

  @override
  String get planRefreshSharedTimes => 'Atualizar horários em comum';

  @override
  String get planSetAvailability => 'Definir a minha disponibilidade';

  @override
  String get planWhenTitle => 'Quando é que te dava jeito?';

  @override
  String get planTimeSourceManual => 'Uma hora sugerida por ti';

  @override
  String get planTimeSourceShared =>
      'Escolhida da disponibilidade em comum · verificada de novo ao enviar';

  @override
  String planLocalTimeNote(int minutes, String timeZone) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Hora local do teu dispositivo ($timeZone). Duração: $minutes minutos.',
      one:
          'Hora local do teu dispositivo ($timeZone). Duração: $minutes minuto.',
    );
    return '$_temp0';
  }

  @override
  String planDurationChip(int minutes) {
    return '$minutes min';
  }

  @override
  String get planEnjoyTitle => 'Algo de que gostasses';

  @override
  String get planAreaHint => 'Um bairro ou um ponto de encontro público';

  @override
  String get planBudgetTitle => 'Que orçamento te parece confortável?';

  @override
  String get planBudgetBody =>
      'Um ponto de partida para combinarem juntos, não um orçamento fechado nem uma promessa sobre quem paga.';

  @override
  String get planAtmosphereTitle => 'Escolhe o ambiente';

  @override
  String get planAtmosphereBody =>
      'Escolhe até três ambientes de que gostarias. Opcional.';

  @override
  String get planComfortTitle => 'Para ser confortável para os dois';

  @override
  String get planComfortBody =>
      'Preferências de acessibilidade opcionais. O que escolheres é partilhado com o teu match quando enviares este plano. Não é adicionado ao teu perfil público nem às atualizações para contactos de confiança.';

  @override
  String get planComfortDisclaimer =>
      'Não precisas de explicar nenhum diagnóstico. São pedidos a confirmar com o local ou o serviço de vídeo, não instalações verificadas.';

  @override
  String get planNoteHint => 'Sábado à tarde, num sítio mais calmo?';

  @override
  String get planReviewBeforeSending =>
      'Antes de enviar, revê a hora e as escolhas acima. A outra pessoa pode aceitar, recusar ou sugerir uma alteração.';

  @override
  String get planReloadLatest =>
      'Recarregar o plano mais recente · descartar alterações';

  @override
  String get planSending => 'A enviar…';

  @override
  String get planSendSuggestion => 'Enviar a tua sugestão';

  @override
  String get planSecondYesTitle => 'Partilhar um segundo sim';

  @override
  String get planSecondYesBody =>
      'Mostra que queres voltar a encontrar-te só se o teu match também disser que sim e aceitar partilhar. As tuas outras respostas continuam privadas.';

  @override
  String get planSecondYesHeadline => 'Um segundo sim, dos dois';

  @override
  String get planSecondYesCardBody =>
      'Os dois partilharam que gostariam de se voltar a encontrar.';

  @override
  String get planAnotherHello => 'Planear outro encontro';

  @override
  String get planSuggestChange => 'Sugerir uma alteração';

  @override
  String get planChooseUpdates => 'Escolher quem recebe as tuas atualizações';

  @override
  String planQuotedNote(String note) {
    return '«$note»';
  }

  @override
  String get planStatusDeclined => 'Recusado';

  @override
  String get planStatusExpired => 'Expirado';

  @override
  String get planStatusCompleted => 'Concluído';

  @override
  String get planStatusDidNotHappen => 'Não aconteceu';

  @override
  String get planStatusDisputed => 'Contestado';

  @override
  String get plansManageSharing => 'Gerir a partilha com contactos';

  @override
  String get plansLoadFailed =>
      'Não foi possível carregar os planos de encontro.';

  @override
  String get plansFeedLoadFailed => 'Não foi possível carregar os planos.';

  @override
  String get planAcceptFailed => 'Não foi possível aceitar este plano.';

  @override
  String get planDeclineFailed => 'Não foi possível recusar este plano.';

  @override
  String get planCancelFailed => 'Não foi possível cancelar este plano.';

  @override
  String get planCheckinFailed => 'De momento não é possível fazer o check-in.';

  @override
  String get graduationFoundEachOther => 'Encontraram-se um ao outro';

  @override
  String graduationHeadlineDecide(String name) {
    return '$name quer sair do Connect contigo';
  }

  @override
  String graduationHeadlineWaiting(String name) {
    return 'À espera de $name';
  }

  @override
  String get graduationBodyConfirmed =>
      'Os dois estão ocultos em Descobrir. Esta conversa continua aberta.';

  @override
  String get graduationBodyDecide =>
      'Confirma e os dois saem de Descobrir. A vossa conversa fica.';

  @override
  String get graduationBodyWaiting =>
      'Pediste para saírem juntos. A outra pessoa pode confirmar ou recusar.';

  @override
  String get graduationCelebrate => 'Celebrar';

  @override
  String get graduationNotYet => 'Ainda não';

  @override
  String get graduationConfirm => 'Confirmar';

  @override
  String get graduationFriendsToldOnConfirm =>
      'Os teus amigos vão saber quando a outra pessoa confirmar.';

  @override
  String get graduationOnlyTwoOfYouForNow =>
      'Por agora, só vocês os dois sabem.';

  @override
  String get graduationWithdraw => 'Retirar';

  @override
  String graduationProposeTitle(String name) {
    return 'Sair do Connect com $name?';
  }

  @override
  String graduationProposeBody(String name) {
    return 'Quando $name confirmar, ficam os dois ocultos em Descobrir. Esta conversa continua aberta e podes voltar a Descobrir a qualquer momento em Privacidade e segurança.';
  }

  @override
  String get graduationNoteLabel => 'Uma nota para a outra pessoa (opcional)';

  @override
  String get graduationNoteHint => 'Diz porque é o momento certo';

  @override
  String get graduationTellFriends => 'Contar aos meus amigos';

  @override
  String get graduationTellFriendsBody =>
      'Os teus amigos aceites ficam a saber que encontraste alguém, mas não quem.';

  @override
  String get graduationAskThem => 'Perguntar';

  @override
  String get graduationTitle => 'Graduação';

  @override
  String graduationCelebrationBody(String name) {
    return 'Tu e $name vão sair do Connect juntos. Ficam os dois ocultos em Descobrir e esta conversa continua aberta durante o tempo que quiserem.';
  }

  @override
  String get graduationFriendsHaveBeenTold =>
      'Os teus amigos já foram avisados.';

  @override
  String get graduationFriendsAreTold => 'Os teus amigos são avisados.';

  @override
  String get graduationOnlyTwoOfYou => 'Só vocês os dois sabem.';

  @override
  String get graduationConfirmAndBack => 'Confirmar e voltar';

  @override
  String get graduationBackToConnect => 'Voltar ao Connect';

  @override
  String get graduationLoadFailed => 'Não foi possível carregar a graduação.';

  @override
  String get graduationProposeFailed =>
      'Não foi possível propor saírem juntos.';

  @override
  String get graduationConfirmFailed => 'De momento não é possível confirmar.';

  @override
  String get graduationDeclineFailed => 'De momento não é possível recusar.';

  @override
  String get graduationWithdrawFailed => 'Não foi possível retirar a proposta.';

  @override
  String get graduationPauseLoadFailed =>
      'Não foi possível carregar o teu estado em Descobrir.';

  @override
  String get graduationPauseFailed => 'Não foi possível pausar Descobrir.';

  @override
  String get graduationResumeFailed => 'Não foi possível retomar Descobrir.';

  @override
  String get engagementCirclesEmptyTitle => 'Não há círculos disponíveis';

  @override
  String get engagementCirclesPullToRefresh =>
      'Puxa para baixo para atualizar.';

  @override
  String get engagementCirclesJoined => 'Aderiste';

  @override
  String get engagementCirclesNotJoined => 'Não aderiste';

  @override
  String engagementCirclesParticipants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participantes esta semana',
      one: '1 participante esta semana',
    );
    return '$_temp0';
  }

  @override
  String get engagementCirclesJoin => 'Aderir ao círculo';

  @override
  String get engagementCirclesResponseLabel =>
      'A tua resposta ao desafio semanal';

  @override
  String get engagementCirclesSubmit => 'Enviar participação';

  @override
  String get engagementCirclesTopicFallback => 'Círculo';

  @override
  String get engagementCirclesLoadFailed =>
      'Não é possível carregar os círculos neste momento.';

  @override
  String get engagementCirclesJoinFailed =>
      'Não é possível aderir ao círculo neste momento.';

  @override
  String get engagementCirclesEnterResponse =>
      'Escreve a tua resposta ao desafio.';

  @override
  String get engagementCirclesSubmitFailed =>
      'Não é possível enviar a tua participação neste momento.';

  @override
  String get engagementNudgesTitle => 'Toques nos matches';

  @override
  String get engagementNudgesIntro =>
      'Envia um lembrete simpático para retomar uma conversa parada. Os limites diários e as regras de segurança são aplicados pelo servidor.';

  @override
  String get engagementNudgesEmpty => 'Não há matches para dar um toque.';

  @override
  String get engagementNudgesSentInSession => 'Toque enviado nesta sessão';

  @override
  String get engagementNudgesReady => 'Pronto para enviar';

  @override
  String engagementNudgesSentTo(String name) {
    return 'Toque enviado a $name.';
  }

  @override
  String get engagementNudgesAction => 'Dar um toque';

  @override
  String get engagementNudgesSendFailed =>
      'Não foi possível enviar este toque.';

  @override
  String get engagementTrustBadgesEarned => 'Selos conquistados';

  @override
  String get engagementTrustBadgesEmpty =>
      'Ainda não tens selos. Conclui atividades para desbloquear selos de confiança.';

  @override
  String engagementTrustBadgesDetails(
    String code,
    String status,
    String awardedAt,
  ) {
    return 'Código: $code\nEstado: $status • Atribuído em $awardedAt';
  }

  @override
  String get engagementTrustBadgesHistory => 'Histórico recente';

  @override
  String get engagementTrustBadgesHistoryEmpty =>
      'Ainda não há histórico de confiança.';

  @override
  String get engagementTrustBadgesMilestoneUnavailable =>
      'Estado do marco indisponível.';

  @override
  String get engagementTrustBadgesCurrentMilestone => 'Marco atual';

  @override
  String get engagementTrustBadgesLoadFailed =>
      'Não foi possível carregar os selos de confiança. Tenta de novo.';

  @override
  String get engagementTrustFiltersEnable => 'Ativar filtros de confiança';

  @override
  String get engagementTrustFiltersEnableSubtitle =>
      'Ocultar perfis que não cumprem os teus requisitos de confiança';

  @override
  String engagementTrustFiltersMinimum(int count) {
    return 'Mínimo de selos ativos: $count';
  }

  @override
  String get engagementTrustFiltersRequired => 'Selos obrigatórios';

  @override
  String get engagementTrustFiltersSaved => 'Filtros de confiança guardados.';

  @override
  String get engagementTrustFiltersSave => 'Guardar filtros de confiança';

  @override
  String get engagementAppealStatusSubmitted => 'Enviado';

  @override
  String get engagementAppealStatusUnderReview => 'Em análise';

  @override
  String get engagementAppealStatusResolvedUpheld => 'Resolvido (mantido)';

  @override
  String get engagementAppealStatusResolvedReversed => 'Resolvido (revertido)';

  @override
  String get engagementRoomsLeaveFailed =>
      'Não foi possível sair desta sala. Tenta de novo.';

  @override
  String get engagementRoomsPresenceFailed => 'Perdeu-se a ligação à sala.';

  @override
  String get engagementRoomsMembersFailed =>
      'Não foi possível carregar quem está cá. Tenta de novo.';

  @override
  String get engagementRoomsModerationFailed => 'Não resultou. Tenta de novo.';

  @override
  String get engagementRoomsCreateFailed =>
      'Não foi possível abrir a sala. Tenta de novo.';

  @override
  String get engagementRoomsLoadFailed =>
      'As salas não estão disponíveis neste momento. Puxa para tentar de novo.';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonRemove => 'Remover';

  @override
  String get accountTitle => 'Conta e dados';

  @override
  String get accountLoadFailed =>
      'Não foi possível carregar o estado da tua conta.';

  @override
  String accountDeletionIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Eliminação dentro de $days dias',
      one: 'Eliminação dentro de 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get accountDeletionDue => 'A eliminação está iminente';

  @override
  String get accountDeletionCountdownBody =>
      'O teu perfil está oculto. Até lá podes iniciar sessão e cancelar — depois disso, os teus dados não podem ser recuperados.';

  @override
  String get accountKeepMyAccount => 'Manter a minha conta';

  @override
  String get accountNotDeletedSnack => 'A tua conta não será eliminada.';

  @override
  String get accountCancelFailed =>
      'Não foi possível cancelar. Tenta novamente.';

  @override
  String get accountHiddenTitle => 'O teu perfil está oculto';

  @override
  String get accountTakeBreakTitle => 'Faz uma pausa';

  @override
  String get accountHiddenBody =>
      'Ninguém te pode ver nem fazer match contigo. Os teus matches e mensagens ficam guardados e podes voltar quando quiseres.';

  @override
  String get accountTakeBreakBody =>
      'Oculta o teu perfil em Descobrir sem perder nada. Continuas com sessão iniciada e podes voltar atrás a qualquer momento.';

  @override
  String get accountUnhideProfile => 'Mostrar o meu perfil';

  @override
  String get accountHideProfile => 'Ocultar o meu perfil';

  @override
  String get accountVisibleAgainSnack => 'O teu perfil está novamente visível.';

  @override
  String get accountNowHiddenSnack => 'O teu perfil está agora oculto.';

  @override
  String get accountUpdateFailed =>
      'Não foi possível atualizar. Tenta novamente.';

  @override
  String get accountDownloadTitle => 'Transferir os teus dados';

  @override
  String get accountDownloadBody =>
      'Obtém uma cópia do teu perfil, preferências, matches e das mensagens que enviaste. As mensagens escritas por outras pessoas não estão incluídas.';

  @override
  String get accountPreparing => 'A preparar…';

  @override
  String get accountPrepareData => 'Preparar os meus dados';

  @override
  String get accountPrepareFailed =>
      'Não foi possível preparar os teus dados. Tenta novamente.';

  @override
  String get accountYourData => 'Os teus dados';

  @override
  String get accountDeleteTitle => 'Eliminar a minha conta';

  @override
  String get accountDeleteBody =>
      'O teu perfil fica oculto de imediato e tudo é apagado após um período de carência. Podes cancelar durante esse tempo iniciando sessão. Depois, nada pode ser recuperado.';

  @override
  String get accountDeletionAlreadyScheduled => 'Eliminação já agendada';

  @override
  String get accountDeleteConfirmTitle => 'Eliminar a tua conta?';

  @override
  String get accountDeleteConfirmBody =>
      'O teu perfil, fotos, matches e mensagens serão apagados e não podem ser recuperados.\n\nSe só queres uma pausa, ocultar o perfil guarda tudo e pode ser anulado.';

  @override
  String get accountHideInstead => 'Ocultar em vez disso';

  @override
  String get accountDeletionScheduledSnack =>
      'Eliminação agendada. Podes cancelar até lá.';

  @override
  String get privacyTitle => 'Privacidade e segurança';

  @override
  String get privacyShowAge => 'Mostrar idade';

  @override
  String get privacyShowAgeSubtitle => 'Controla se a tua idade é visível';

  @override
  String get privacyShowDistance => 'Mostrar distância exata';

  @override
  String get privacyShowDistanceSubtitle =>
      'Mostra a distância precisa no teu perfil';

  @override
  String get privacyShowOnline => 'Mostrar estado online';

  @override
  String get privacyShowOnlineSubtitle =>
      'Permitir que outros vejam se estás online';

  @override
  String get privacyEmergencySos => 'SOS de emergência';

  @override
  String get privacyEmergencySosSubtitle =>
      'Ativar um alerta e rever o histórico';

  @override
  String get privacyEmergencyContacts => 'Contactos de emergência';

  @override
  String get privacyEmergencyContactsSubtitle =>
      'Gerir contactos de emergência de confiança';

  @override
  String get privacyBlockedUsers => 'Utilizadores bloqueados';

  @override
  String get privacyBlockedUsersSubtitle => 'Rever e desbloquear utilizadores';

  @override
  String get privacyModerationAppeals => 'Recursos de moderação';

  @override
  String get privacyModerationAppealsSubtitle =>
      'Submeter um recurso e acompanhar a análise';

  @override
  String get privacyFriendSearch =>
      'Deixar que me encontrem na pesquisa de amigos';

  @override
  String get privacySettingLoadFailed =>
      'Não foi possível carregar esta definição. Abre esta página novamente para tentar de novo.';

  @override
  String get privacyFriendSearchSubtitle =>
      'Os membros podem encontrar-te pelo nome ou @utilizador em Adicionar amigo. As pessoas com quem fazes match ou que conheces em salas e grupos podem continuar a adicionar-te.';

  @override
  String get privacyChoiceSaveFailed =>
      'Não foi possível guardar a tua escolha.';

  @override
  String get privacyShowcase => 'Mostrar os meus textos públicos no perfil';

  @override
  String get privacyShowcaseSubtitle =>
      'Os membros podem ver no teu perfil os capítulos que partilhas com a comunidade e as tuas fotos no mural. Os capítulos privados ou só para amigos nunca aparecem.';

  @override
  String get privacyCrashReports => 'Partilhar relatórios de falhas';

  @override
  String get privacyCrashReportsSubtitle =>
      'Os relatórios anónimos de falhas e erros ajudam-nos a resolver problemas. Não incluem mensagens, fotos nem dados da conta.';

  @override
  String get privacyGraduatedReason =>
      'Saíste do Connect com o teu match. O teu cartão não é mostrado a ninguém.';

  @override
  String get privacyPausedReason =>
      'O teu cartão não é mostrado a ninguém até retomares.';

  @override
  String get privacyActiveReason =>
      'És mostrado a outros membros em Descobrir.';

  @override
  String get privacyDiscoveryPaused => 'Descobrir em pausa';

  @override
  String get privacyDiscoveryActive => 'Descobrir ativo';

  @override
  String get privacyResume => 'Retomar';

  @override
  String get privacyPause => 'Pausar';

  @override
  String get emergencyIntro =>
      'Adiciona até 3 contactos de confiança. Serão usados mais tarde em processos de segurança e funções SOS.';

  @override
  String get emergencyEmpty => 'Ainda não adicionaste contactos de emergência.';

  @override
  String get emergencyMaxReached => 'Número máximo de contactos atingido';

  @override
  String get emergencyAddContact => 'Adicionar contacto';

  @override
  String get emergencyEditContact => 'Editar contacto';

  @override
  String get emergencyInvalidInput =>
      'Introduz um nome e um número de telefone válidos.';

  @override
  String get emergencyAdded => 'Contacto de emergência adicionado.';

  @override
  String get emergencyAddFailed =>
      'Não foi possível adicionar o contacto. Tenta novamente.';

  @override
  String get emergencyUpdated => 'Contacto de emergência atualizado.';

  @override
  String get emergencyUpdateFailed =>
      'Não foi possível atualizar o contacto. Tenta novamente.';

  @override
  String get emergencyRemoveTitle => 'Remover contacto';

  @override
  String emergencyRemoveBody(String name) {
    return 'Remover $name dos contactos de emergência?';
  }

  @override
  String get emergencyRemoved => 'Contacto de emergência removido.';

  @override
  String get emergencyRemoveFailed =>
      'Não foi possível remover o contacto. Tenta novamente.';

  @override
  String get emergencyNameLabel => 'Nome';

  @override
  String get emergencyPhoneLabel => 'Número de telefone';

  @override
  String get appealsSubmitTitle => 'Submeter um recurso';

  @override
  String get appealsReasonLabel => 'Motivo';

  @override
  String get appealsReasonHint =>
      'Porque deve esta decisão de moderação ser revista?';

  @override
  String get appealsReportIdLabel => 'ID da denúncia (opcional)';

  @override
  String get appealsContextLabel => 'Contexto adicional (opcional)';

  @override
  String get appealsSubmit => 'Submeter recurso';

  @override
  String get appealsEmpty =>
      'Ainda não submeteste recursos. Vão aparecer aqui com o respetivo estado.';

  @override
  String appealsIdLine(String id) {
    return 'ID do recurso: $id';
  }

  @override
  String appealsSlaLine(String deadline) {
    return 'Prazo de análise: $deadline';
  }

  @override
  String appealsReviewedBy(String reviewer) {
    return 'Analisado por: $reviewer';
  }

  @override
  String get appealsReasonRequired => 'O motivo é obrigatório.';

  @override
  String get appealsSubmitted => 'Recurso submetido com sucesso.';

  @override
  String get appealsSubmitFailed =>
      'Não foi possível submeter o recurso. Tenta novamente.';

  @override
  String get blockedEmpty => 'Não bloqueaste ninguém.';

  @override
  String get blockedUnblock => 'Desbloquear';

  @override
  String get blockedUnblockTitle => 'Desbloquear utilizador';

  @override
  String blockedUnblockBody(String name) {
    return 'Desbloquear $name?';
  }

  @override
  String blockedUnblockedSnack(String name) {
    return '$name foi desbloqueado.';
  }

  @override
  String get blockedUnblockFailed =>
      'Não foi possível desbloquear. Tenta novamente.';

  @override
  String aboutVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get aboutDescription =>
      'App de encontros centrada na confiança: perfis autênticos, comunicação segura e relações sérias.';

  @override
  String get aboutStack => 'Tecnologia';

  @override
  String get aboutStackFlutter => 'Flutter (Android primeiro)';

  @override
  String get aboutStackGo => 'Serviços Go + PostgreSQL nativo';

  @override
  String get aboutStackRiverpod => 'Gestão de estado com Riverpod';

  @override
  String get communitySpoiler => 'Spoiler — toca para ver';

  @override
  String get communityReportFailed => 'Não foi possível enviar a denúncia.';

  @override
  String get communityReportSubmitted => 'Denúncia enviada. Obrigado.';

  @override
  String communityBlockTitle(String name) {
    return 'Bloquear $name?';
  }

  @override
  String get communityBlockBody =>
      'Deixam de ver as fotos, publicações de clubes, avaliações e listas um do outro. Também bloqueia o contacto através do Connect.';

  @override
  String get communityBlockAction => 'Bloquear membro';

  @override
  String get communityBlockFailed =>
      'Não foi possível bloquear este membro. Tenta novamente.';

  @override
  String get reportSheetTitle => 'Denunciar';

  @override
  String get reportReasonHarassment => 'Assédio';

  @override
  String get reportReasonInappropriate => 'Conteúdo impróprio';

  @override
  String get reportReasonFraud => 'Fraude / burla';

  @override
  String get reportReasonFake => 'Perfil falso';

  @override
  String get reportReasonLabel => 'Motivo';

  @override
  String get reportDescriptionLabel => 'Descrição (opcional)';

  @override
  String get reportDescriptionHint =>
      'Acrescenta contexto para ajudar a analisar a denúncia';

  @override
  String get reportSubmitFailed =>
      'Não foi possível enviar a denúncia. Tenta novamente.';

  @override
  String get reportSubmit => 'Enviar denúncia';

  @override
  String get membershipTitle => 'Subscrição';

  @override
  String get membershipChooseYourPlan => 'Escolhe o teu plano';

  @override
  String get membershipCycleNoteMonthly =>
      'Pagamento com cartão. Renova automaticamente todos os meses até o desativares.';

  @override
  String get membershipCycleNoteYearly =>
      'Pagamento com cartão. Renova automaticamente todos os anos até o desativares.';

  @override
  String get membershipNoPlansOnSale => 'De momento, não há planos à venda.';

  @override
  String get membershipPaymentsTitle => 'Pagamentos';

  @override
  String get membershipNoCardPayments => 'Ainda não há pagamentos com cartão.';

  @override
  String get membershipFooterNote =>
      'O teu plano renova automaticamente no fim de cada período de faturação. Podes desativar a renovação automática a qualquer momento; manténs os benefícios até ao fim do período. Os dados do cartão são tratados pelo prestador de pagamentos e nunca são guardados na app.';

  @override
  String membershipSwitchTitle(String plan) {
    return 'Mudar para $plan?';
  }

  @override
  String membershipSwitchUpgradeBodyMonthly(String price) {
    return 'O teu cartão é cobrado agora pela diferença no resto deste período e, a partir da próxima renovação, $price por mês.';
  }

  @override
  String membershipSwitchUpgradeBodyYearly(String price) {
    return 'O teu cartão é cobrado agora pela diferença no resto deste período e, a partir da próxima renovação, $price por ano.';
  }

  @override
  String membershipSwitchDowngradeBodyMonthly(
    String currentPlan,
    String price,
  ) {
    return 'O teu plano muda agora. O tempo não usado do $currentPlan é creditado na tua próxima renovação e depois pagas $price por mês.';
  }

  @override
  String membershipSwitchDowngradeBodyYearly(String currentPlan, String price) {
    return 'O teu plano muda agora. O tempo não usado do $currentPlan é creditado na tua próxima renovação e depois pagas $price por ano.';
  }

  @override
  String get membershipNotNow => 'Agora não';

  @override
  String get membershipUpgrade => 'Fazer upgrade';

  @override
  String get membershipSwitchPlan => 'Mudar de plano';

  @override
  String membershipSwitchedSnack(String plan) {
    return 'Agora tens o $plan.';
  }

  @override
  String get membershipCardUpdated => 'O teu cartão foi atualizado.';

  @override
  String get membershipCardUpdatePending =>
      'A atualização do cartão ainda não foi confirmada. Verifica o estado antes de tentares novamente.';

  @override
  String get membershipCardUpdateEnded =>
      'Esta sessão de atualização do cartão terminou. Atualiza para veres o teu cartão atual.';

  @override
  String get membershipCheckoutTitleCard => 'o teu cartão';

  @override
  String get membershipAutoRenewOffTitle => 'Desativar a renovação automática?';

  @override
  String membershipAutoRenewOffBodyDate(String plan, String date) {
    return 'Os benefícios do $plan continuam ativos até $date. Depois passas para o plano gratuito e o teu cartão não volta a ser cobrado.';
  }

  @override
  String membershipAutoRenewOffBodyPeriodEnd(String plan) {
    return 'Os benefícios do $plan continuam ativos até ao fim do período atual. Depois passas para o plano gratuito e o teu cartão não volta a ser cobrado.';
  }

  @override
  String get membershipKeepRenewing => 'Continuar a renovar';

  @override
  String get membershipTurnOff => 'Desativar';

  @override
  String get membershipAutoRenewBackOn =>
      'A renovação automática voltou a estar ativa.';

  @override
  String get membershipAutoRenewNowOff =>
      'A renovação automática está desativada. Os teus benefícios continuam até ao fim do período.';

  @override
  String membershipSubscribeTitle(String plan) {
    return 'Subscrever o $plan';
  }

  @override
  String membershipSubscribeBodyMonthly(String price) {
    return '$price por mês, cobrados no teu cartão e renovados automaticamente até desativares a renovação automática. Vais introduzir o cartão na página segura do prestador de pagamentos.';
  }

  @override
  String membershipSubscribeBodyYearly(String price) {
    return '$price por ano, cobrados no teu cartão e renovados automaticamente até desativares a renovação automática. Vais introduzir o cartão na página segura do prestador de pagamentos.';
  }

  @override
  String membershipSubscribeBodyTestMonthly(String price) {
    return 'Apenas pagamento de teste — sem cobrança real. $price por mês, simulados e renovados automaticamente até desativares a renovação automática. Vais introduzir o cartão na página segura do prestador de pagamentos.';
  }

  @override
  String membershipSubscribeBodyTestYearly(String price) {
    return 'Apenas pagamento de teste — sem cobrança real. $price por ano, simulados e renovados automaticamente até desativares a renovação automática. Vais introduzir o cartão na página segura do prestador de pagamentos.';
  }

  @override
  String get membershipContinueToCard => 'Continuar para o cartão';

  @override
  String get paymentStillConfirming =>
      'O pagamento ainda está a ser confirmado. Daqui a pouco, puxa para baixo para atualizar.';

  @override
  String get membershipCheckoutEnded =>
      'Esta sessão de pagamento terminou. Atualiza o teu histórico de pagamentos antes de tentares novamente.';

  @override
  String get membershipRecoverAccountUnavailable =>
      'Não foi possível verificar a conta de pagamento. Tenta novamente.';

  @override
  String get membershipRecoverCheckoutClosed =>
      'Conta de pagamento atualizada. Este pagamento já não está aberto.';

  @override
  String get membershipRecoverConfirmed =>
      'Confirmado. A tua conta de pagamento está atualizada.';

  @override
  String get membershipRecoverPending =>
      'A confirmação ainda está pendente. Podes verificar novamente aqui.';

  @override
  String get membershipRecoverEnded =>
      'Esta sessão de pagamento terminou. Revê o teu histórico de pagamentos antes de iniciares outra.';

  @override
  String membershipCelebrateTitle(String plan) {
    return 'Agora és $plan';
  }

  @override
  String get membershipCelebrateBodyTest =>
      'Pagamento de teste confirmado; não foi cobrado dinheiro real. O teu plano de teste renova automaticamente. Gere a renovação automática a qualquer momento neste ecrã.';

  @override
  String get membershipCelebrateBody =>
      'Pagamento confirmado. O teu plano renova automaticamente. Gere a renovação automática a qualquer momento neste ecrã.';

  @override
  String get membershipStartExploring => 'Começar a explorar';

  @override
  String get membershipYourMembership => 'A tua subscrição';

  @override
  String get membershipYourPlan => 'O teu plano';

  @override
  String get membershipFreePlanName => 'Grátis';

  @override
  String membershipPricePerMonthShort(String price) {
    return '$price/mês';
  }

  @override
  String membershipPricePerYearShort(String price) {
    return '$price/ano';
  }

  @override
  String get membershipCardOnFile =>
      'Cartão registado no prestador de pagamentos';

  @override
  String get membershipCardBrandFallback => 'Cartão';

  @override
  String get paymentOpening => 'A abrir…';

  @override
  String get membershipUpdateCard => 'Atualizar cartão';

  @override
  String get membershipLastPaymentFailed =>
      'O último pagamento falhou. Vamos tentar novamente com o teu cartão; os benefícios continuam ativos durante alguns dias.';

  @override
  String membershipRenewsOn(String date) {
    return 'Renova a $date';
  }

  @override
  String get membershipRenewsSoon => 'Renova em breve';

  @override
  String membershipEndsOn(String date) {
    return 'Termina a $date · renovação automática desativada';
  }

  @override
  String get membershipEndsSoon =>
      'Termina em breve · renovação automática desativada';

  @override
  String get membershipAutoRenew => 'Renovação automática';

  @override
  String get membershipAutoRenewOnSubtitle =>
      'Cobrado automaticamente em cada período.';

  @override
  String get membershipAutoRenewOffSubtitle =>
      'Desativada. Os benefícios terminam com o período atual.';

  @override
  String get membershipFreeHeroBody =>
      'Desbloqueia mais gostos, mensagens e destaque com um plano abaixo. Pagamento com cartão; cancela quando quiseres.';

  @override
  String get membershipStatusFree => 'Grátis';

  @override
  String get membershipStatusPaymentDue => 'Pagamento em atraso';

  @override
  String get membershipStatusEnding => 'A terminar';

  @override
  String get membershipStatusActive => 'Ativa';

  @override
  String get membershipCycleMonthly => 'Mensal';

  @override
  String get membershipCycleYearly => 'Anual';

  @override
  String get membershipBadgeYourPlan => 'O TEU PLANO';

  @override
  String get membershipBadgeMostPopular => 'O MAIS POPULAR';

  @override
  String get membershipPerMonth => 'por mês';

  @override
  String get membershipPerYear => 'por ano';

  @override
  String membershipSavePercent(int percent) {
    return 'Poupa $percent%';
  }

  @override
  String membershipQuotaLikesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gostos/dia',
      one: '1 gosto/dia',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens/dia',
      one: '1 mensagem/dia',
    );
    return '$_temp0';
  }

  @override
  String get membershipQuotaUnlimitedLikes => 'Gostos ilimitados';

  @override
  String get membershipQuotaUnlimitedMessages => 'Mensagens ilimitadas';

  @override
  String get membershipYourCurrentPlan => 'O teu plano atual';

  @override
  String get membershipSwitching => 'A mudar…';

  @override
  String get membershipOpeningSecureCheckout => 'A abrir o pagamento seguro…';

  @override
  String membershipSwitchToPlan(String plan) {
    return 'Mudar para $plan';
  }

  @override
  String get membershipSubscribeWithCard => 'Subscrever com cartão';

  @override
  String get membershipSettleBeforeSwitch =>
      'Regulariza o pagamento em falta do teu plano atual antes de mudares.';

  @override
  String get membershipPaymentChargeback => 'Estorno';

  @override
  String get membershipPaymentDisputed => 'Contestado';

  @override
  String get membershipPaymentRefunded => 'Reembolsado';

  @override
  String get membershipPaymentPartlyRefunded => 'Parcialmente reembolsado';

  @override
  String get membershipPaymentFailed => 'Falhado';

  @override
  String get membershipPaymentPaid => 'Pago';

  @override
  String get membershipPaymentPending => 'Pendente';

  @override
  String get membershipPaymentReasonFirstCharge => 'Primeira cobrança';

  @override
  String get membershipPaymentReasonRenewal => 'Renovação';

  @override
  String get membershipPaymentReasonPlanChange => 'Mudança de plano';

  @override
  String get membershipPaymentReasonCoins => 'Moedas';

  @override
  String get membershipPaymentReasonLocalActivation => 'Ativação local';

  @override
  String get membershipPaymentReasonCard => 'Pagamento com cartão';

  @override
  String get membershipPaymentReasonOther => 'Pagamento';

  @override
  String get paymentModeSandbox => 'Teste local · sem cobrança real';

  @override
  String get paymentModeStripeTest => 'Teste Stripe · sem cobrança real';

  @override
  String get paymentModeLive => 'Pagamentos reais';

  @override
  String get paymentModeUnavailable => 'Pagamentos indisponíveis';

  @override
  String get paymentAccountTitle => 'A tua conta de pagamento';

  @override
  String get paymentAccountSignedInMember => 'Membro com sessão iniciada';

  @override
  String get paymentAccountCardTitle => 'Cartão de crédito ou débito';

  @override
  String get paymentAccountCardUnavailableTitle =>
      'O pagamento com cartão não está disponível';

  @override
  String get paymentAccountCardBody =>
      'Introduz o cartão na página de pagamento alojada. A subscrição e o histórico de pagamentos pertencem a esta conta.';

  @override
  String get paymentAccountCardUnavailableBody =>
      'Podes continuar a usar a tua conta atual. Os novos pagamentos com cartão não estão ativados.';

  @override
  String paymentAccountTestCardHint(String cardNumber) {
    return 'Para testar, usa $cardNumber, uma data de validade futura e qualquer CVC de três dígitos. Usa apenas dados de teste.';
  }

  @override
  String get paymentAccountUnfinishedCardUpdate =>
      'Atualização do cartão por concluir';

  @override
  String paymentAccountUnfinishedCheckout(String plan) {
    return 'Pagamento por concluir: $plan';
  }

  @override
  String get paymentAccountPendingHint =>
      'Verifica o estado mais recente ou continua o mesmo pagamento.';

  @override
  String get paymentAccountCheckStatus => 'Verificar estado';

  @override
  String get paymentAccountResumeCheckout => 'Retomar o pagamento';

  @override
  String paymentCheckoutPayFor(String title) {
    return 'Pagar: $title';
  }

  @override
  String get paymentCheckoutClose => 'Fechar o pagamento';

  @override
  String get paymentCheckoutSecureNote =>
      'Os dados do cartão são introduzidos na página segura do prestador de pagamentos.';

  @override
  String paymentCheckoutCompleteInNewTab(String title) {
    return 'Conclui o pagamento ($title) no novo separador';
  }

  @override
  String get paymentCheckoutWaitingBody =>
      'Os dados do cartão são introduzidos na página segura do prestador de pagamentos. Volta aqui quando indicar que o pagamento está concluído.';

  @override
  String get paymentCheckoutCheckConfirmation => 'Verificar confirmação';

  @override
  String get paymentCheckoutBackToAccount => 'Voltar à conta';

  @override
  String get paymentWalletTitle => 'Carteira e pagamentos';

  @override
  String get paymentWalletTestNote =>
      'Pagamentos de teste · sem cobrança real. Usa apenas dados de cartão de teste.';

  @override
  String get paymentWalletPopularTopUps => 'Carregamentos populares';

  @override
  String get paymentWalletTopUpsIntro =>
      'Paga com cartão na página de pagamento segura. As moedas chegam à tua carteira assim que o pagamento for liquidado.';

  @override
  String get paymentWalletCardsDisabled =>
      'Os pagamentos com cartão ainda não estão ativados neste servidor.';

  @override
  String get paymentWalletNoPacks =>
      'De momento, não há pacotes de moedas à venda.';

  @override
  String get paymentWalletActivity => 'Atividade da carteira';

  @override
  String get paymentWalletNoPurchases => 'Ainda não há compras de moedas.';

  @override
  String get paymentWalletFooter =>
      'As moedas servem para presentes e boosts no Connect. As compras são definitivas depois de liquidadas; os dados do cartão ficam com o prestador de pagamentos.';

  @override
  String paymentCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moedas',
      one: '1 moeda',
    );
    return '$_temp0';
  }

  @override
  String paymentCoinsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moedas adicionadas à tua carteira.',
      one: '1 moeda adicionada à tua carteira.',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'moedas',
      one: 'moeda',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnitBonus(int count, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'moedas · +$bonus de bónus',
      one: 'moeda · +$bonus de bónus',
    );
    return '$_temp0';
  }

  @override
  String get paymentWalletCheckoutEnded =>
      'Esta sessão de pagamento terminou. Revê o teu histórico de pagamentos antes de tentares novamente.';

  @override
  String get paymentWalletBalanceLabel => 'Saldo da carteira Glow';

  @override
  String get paymentWalletSourceSupport => 'Carregamento do apoio ao cliente';

  @override
  String get paymentWalletSourcePromo => 'Promoção';

  @override
  String get paymentWalletSourcePurchase => 'Compra de moedas';

  @override
  String get paymentErrorSignInSubscriptions =>
      'Inicia sessão para gerir as subscrições.';

  @override
  String get paymentErrorSignInWallet =>
      'Inicia sessão para gerir a tua carteira.';

  @override
  String get paymentErrorLoadSubscription =>
      'Não foi possível carregar os detalhes da subscrição.';

  @override
  String get paymentErrorLoadWallet =>
      'Não foi possível carregar a tua carteira.';

  @override
  String get paymentErrorStartCheckoutNow =>
      'De momento, não é possível iniciar o pagamento.';

  @override
  String get paymentErrorStartCheckout =>
      'Não foi possível iniciar o pagamento.';

  @override
  String get paymentErrorConfirmPayment =>
      'Ainda não é possível confirmar o pagamento.';

  @override
  String get paymentErrorAutoRenewOn =>
      'Não foi possível voltar a ativar a renovação automática.';

  @override
  String get paymentErrorAutoRenewOff =>
      'Não foi possível desativar a renovação automática.';

  @override
  String get paymentErrorChangePlan => 'Não foi possível mudar de plano.';

  @override
  String get paymentErrorUpdateCard => 'Não foi possível atualizar o cartão.';

  @override
  String get paymentErrorSandboxFailed => 'A simulação de sandbox falhou.';

  @override
  String get paymentErrorUnreachable =>
      'Não é possível contactar o serviço local. Verifica se a API está em execução.';

  @override
  String membershipQuotaLikesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Hoje restam $remaining de $limit gostos',
      one: 'Hoje restam $remaining de 1 gosto',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Hoje restam $remaining de $limit mensagens',
      one: 'Hoje restam $remaining de 1 mensagem',
    );
    return '$_temp0';
  }

  @override
  String membershipLikeLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Já usaste os teus $limit gostos de hoje no $plan',
      one: 'Já usaste o teu gosto de hoje no $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipMessageLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Já usaste as tuas $limit mensagens de hoje no $plan',
      one: 'Já usaste a tua mensagem de hoje no $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaResetsAt(String time) {
    return 'Repõe às $time';
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
      'Um pouco mais perto, uma mensagem de cada vez.';

  @override
  String get matchesSubtitlePeople =>
      'Pessoas que escolheste. Possibilidades para construir a dois.';

  @override
  String get matchesSearchConversations => 'Pesquisar conversas';

  @override
  String get matchesSearchMatches => 'Pesquisar os teus matches';

  @override
  String get matchesFilterAllConversations => 'Todas as conversas';

  @override
  String matchesFilterUnread(int count) {
    return 'Por ler · $count';
  }

  @override
  String get matchesLoading => 'A carregar matches…';

  @override
  String get matchesLoadErrorTitle => 'Não foi possível carregar os matches';

  @override
  String get matchesRetry => 'Tentar de novo';

  @override
  String get matchesEmptyTitle => 'Ainda sem matches';

  @override
  String matchesTrustFilteredHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Os filtros de confiança ocultaram $count matches. Experimenta relaxá-los em Descobrir.',
      one:
          'Os filtros de confiança ocultaram 1 match. Experimenta relaxá-los em Descobrir.',
    );
    return '$_temp0';
  }

  @override
  String get matchesEmptyBody =>
      'Visita Hoje para descobrir alguém que gostarias de conhecer.';

  @override
  String get matchesNoConversationResults =>
      'Ainda não há conversas aqui. Experimenta outra pesquisa ou outro filtro.';

  @override
  String get matchesNoPeopleResults =>
      'Nenhum match encontrado. Experimenta outro nome.';

  @override
  String get matchesTabPeople => 'Os teus matches';

  @override
  String get matchesTabConversations => 'Conversas';

  @override
  String get matchesActionStartCall => 'Iniciar chamada';

  @override
  String get matchesActionStartActivity => 'Começar uma atividade';

  @override
  String get matchesActionPlanDate => 'Planear um encontro';

  @override
  String get matchesActionPlanDateSubtitle =>
      'Escolhe uma hora e o que queres partilhar';

  @override
  String matchesPlanSent(String name) {
    return 'Plano enviado a $name.';
  }

  @override
  String get matchesActionGraduate => 'Encontrámo-nos';

  @override
  String get matchesActionGraduateSubtitle =>
      'Saiam juntos do Connect; a conversa fica';

  @override
  String matchesGraduationAsked(String name) {
    return 'Pediste a $name para saírem juntos. Pode confirmar na vossa conversa.';
  }

  @override
  String get matchesActionNudge => 'Enviar um toque';

  @override
  String matchesNudgeSent(String name) {
    return 'Toque enviado a $name.';
  }

  @override
  String get matchesNudgeFailed => 'Não foi possível enviar o toque.';

  @override
  String get matchesActionClose => 'Fechar conversa';

  @override
  String get matchesActionCloseSubtitle => 'Ganha espaço, sem explicações.';

  @override
  String get matchesCloseDialogTitle => 'Fechar esta conversa?';

  @override
  String get matchesCloseDialogBody =>
      'Não faz mal se esta ligação não for para ti. Isto termina o match. Não precisas de enviar uma explicação. Denunciar continua a ser uma escolha à parte.';

  @override
  String get matchesCloseDialogKeep => 'Continuar a conversar';

  @override
  String get matchesActionReport => 'Denunciar';

  @override
  String get matchesReportSubmitted => 'Denúncia enviada. Obrigado.';

  @override
  String get matchesReportAppeal => 'Recorrer';

  @override
  String matchesAppealReason(String userId) {
    return 'Rever o resultado da moderação da denúncia sobre o utilizador $userId';
  }

  @override
  String get matchesBothChose => 'Ambos escolheram conhecer-se';

  @override
  String matchesOptionsTooltip(String name) {
    return 'Opções do match com $name';
  }

  @override
  String matchesChatUnread(int count) {
    return 'Chat · $count por ler';
  }

  @override
  String get matchesOpenChat => 'Abrir conversa';

  @override
  String get matchesFirstChapter => 'Primeiro Capítulo';

  @override
  String get matchesUnknownName => 'Desconhecido';

  @override
  String get matchesSayHi => 'Diz olá 👋';

  @override
  String get matchesFallbackName => 'O teu match';

  @override
  String get matchesFallbackMessage => 'Começa a conversa';

  @override
  String get matchesGiftPreview => 'Um pequeno presente na vossa conversa';

  @override
  String matchesConversationOptionsTooltip(String name) {
    return 'Opções da conversa com $name';
  }

  @override
  String get matchesTimeNow => 'Agora';

  @override
  String matchesTimeMinutesAgo(int minutes) {
    return 'há $minutes min';
  }

  @override
  String matchesTimeHoursAgo(int hours) {
    return 'há $hours h';
  }

  @override
  String get matchesTimeToday => 'Hoje';

  @override
  String get matchesTimeYesterday => 'Ontem';

  @override
  String get matchesNewMatchTitle => 'Novo match';

  @override
  String get matchesItsAMatch => 'É um match!';

  @override
  String matchesLikedEachOther(String name) {
    return 'Tu e $name gostaram um do outro';
  }

  @override
  String get matchesSendMessage => 'Enviar mensagem';

  @override
  String get matchesKeepSwiping => 'Continuar a deslizar';

  @override
  String get matchesErrorLoginRequired =>
      'Inicia sessão para veres os teus matches.';

  @override
  String get matchesErrorLoadFailed =>
      'Não foi possível carregar os matches. Tenta novamente.';

  @override
  String get matchesErrorUnmatchFailed => 'Não foi possível desfazer o match.';

  @override
  String get matchesErrorMarkReadFailed => 'Não foi possível marcar como lido.';

  @override
  String get matchesErrorSessionUnavailable =>
      'Sessão de utilizador indisponível.';

  @override
  String get matchesTrustBadgePromptCompleter => 'Prompts completos';

  @override
  String get matchesTrustBadgeRespectful => 'Comunicação respeitosa';

  @override
  String get matchesTrustBadgeConsistent => 'Perfil coerente';

  @override
  String get matchesTrustBadgeVerifiedActive => 'Verificado e ativo';

  @override
  String get matchesTrustErrorLoad =>
      'Não foi possível carregar os filtros de confiança. Tenta novamente.';

  @override
  String get matchesTrustErrorSave =>
      'Não foi possível guardar os filtros de confiança. Tenta novamente.';

  @override
  String get matchesGestureErrorLoad => 'Não foi possível carregar o histórico';

  @override
  String get matchesGestureErrorPending =>
      'Os gestos ficam disponíveis quando esta conversa pendente se tornar um match a sério.';

  @override
  String get matchesGestureErrorSend => 'Não foi possível enviar o gesto.';

  @override
  String get matchesGestureErrorUpdate =>
      'Não foi possível atualizar o estado do gesto.';

  @override
  String get matchesActivityTitle => 'Isto ou aquilo em 2 minutos';

  @override
  String get matchesActivityRestartTooltip => 'Começar uma nova sessão';

  @override
  String matchesActivityCompleteWith(String name) {
    return 'Completa isto com $name';
  }

  @override
  String get matchesActivityInstructions =>
      'Responde às 8 rondas antes de o tempo acabar.';

  @override
  String matchesActivityStatus(String status) {
    return 'Estado: $status';
  }

  @override
  String get matchesActivityStatusActive => 'ativa';

  @override
  String get matchesActivityStatusTimedOut => 'tempo esgotado';

  @override
  String get matchesActivityStatusPartialTimeout => 'parcialmente expirada';

  @override
  String get matchesActivityStatusCompleted => 'concluída';

  @override
  String get matchesActivitySubmit => 'Enviar respostas';

  @override
  String get matchesActivityTimeUpLoad => 'O tempo acabou — Carregar resumo';

  @override
  String get matchesActivityWaiting =>
      'Respostas enviadas. À espera que a outra pessoa termine.';

  @override
  String get matchesActivityRefreshSummary => 'Atualizar resumo';

  @override
  String matchesActivityTimeLeft(String time) {
    return 'Tempo restante $time';
  }

  @override
  String get matchesActivitySummaryTitle => 'Resumo da atividade';

  @override
  String matchesActivityParticipantsCompleted(int completed, int total) {
    return 'Participantes que terminaram: $completed/$total';
  }

  @override
  String get matchesActivitySummaryPending =>
      'O resumo vai aparecer assim que estiver disponível.';

  @override
  String get matchesActivityShareResult => 'Partilhar resultado na conversa';

  @override
  String matchesActivityShareMessage(String status, int completed, int total) {
    return 'Resultado de Isto ou aquilo (2 min): $status • $completed/$total concluído';
  }

  @override
  String matchesActivityShareMessageWithInsight(
    String status,
    int completed,
    int total,
    String insight,
  ) {
    return 'Resultado de Isto ou aquilo (2 min): $status • $completed/$total concluído • $insight';
  }

  @override
  String matchesActivityRound(int number) {
    return 'Ronda $number';
  }

  @override
  String get matchesActivityErrorStart =>
      'Não é possível começar a atividade agora. Tenta novamente.';

  @override
  String get matchesActivityErrorNotReady => 'A sessão ainda não está pronta.';

  @override
  String get matchesActivityErrorAnswerAll =>
      'Responde a todas as perguntas antes de enviar.';

  @override
  String get matchesActivityErrorTimeUp =>
      'O tempo acabou. A carregar o resumo…';

  @override
  String get matchesActivityErrorSubmit =>
      'Não foi possível enviar as respostas. Tenta novamente.';

  @override
  String get matchesActivityErrorSummary =>
      'Ainda não é possível obter o resumo. Tenta novamente.';

  @override
  String get matchesActivityQ1Prompt => 'Primeiro encontro ideal?';

  @override
  String get matchesActivityQ1OptionA => 'Passeio com café';

  @override
  String get matchesActivityQ1OptionB => 'Visita a uma livraria';

  @override
  String get matchesActivityQ2Prompt => 'Ambiente de fim de semana preferido?';

  @override
  String get matchesActivityQ2OptionA => 'Ficar em casa a recarregar energias';

  @override
  String get matchesActivityQ2OptionB => 'Explorar a cidade';

  @override
  String get matchesActivityQ3Prompt => 'Melhor sítio para conversar?';

  @override
  String get matchesActivityQ3OptionA => 'Passeio longo';

  @override
  String get matchesActivityQ3OptionB => 'Canto acolhedor de um café';

  @override
  String get matchesActivityQ4Prompt => 'Como planeias os encontros?';

  @override
  String get matchesActivityQ4OptionA => 'Espontaneamente';

  @override
  String get matchesActivityQ4OptionB => 'Com antecedência';

  @override
  String get matchesActivityQ5Prompt => 'O que importa mais agora?';

  @override
  String get matchesActivityQ5OptionA => 'Constância';

  @override
  String get matchesActivityQ5OptionB => 'Emoção';

  @override
  String get matchesActivityQ6Prompt => 'Como preferes lidar com conflitos?';

  @override
  String get matchesActivityQ6OptionA => 'Resolver no mesmo dia';

  @override
  String get matchesActivityQ6OptionB => 'Dar espaço e voltar ao assunto';

  @override
  String get matchesActivityQ7Prompt => 'Atividade para fazer a dois?';

  @override
  String get matchesActivityQ7OptionA => 'Cozinhar juntos';

  @override
  String get matchesActivityQ7OptionB => 'Treinar juntos';

  @override
  String get matchesActivityQ8Prompt => 'Que ritmo preferes?';

  @override
  String get matchesActivityQ8OptionA => 'Calmo e intencional';

  @override
  String get matchesActivityQ8OptionB => 'Rápido e energético';

  @override
  String get cityPilotSaveFailed =>
      'Não conseguimos confirmar essa alteração. Atualiza para verificar antes de tentares novamente.';

  @override
  String get cityPilotLeaveTitle => 'Sair do projeto-piloto da cidade?';

  @override
  String get cityPilotLeaveBody =>
      'As tuas reservas no projeto-piloto serão canceladas e o teu feedback sobre as experiências será removido. A tua atividade deixa de contar para os resultados atuais. Os teus matches e conversas mantêm-se. Não podes voltar a aderir a este projeto-piloto.';

  @override
  String get cityPilotStay => 'Ficar no projeto';

  @override
  String get cityPilotLeave => 'Sair do projeto';

  @override
  String get cityPilotLeftNotice =>
      'Saíste do projeto-piloto. Os teus matches ficam contigo.';

  @override
  String cityPilotJoinEventTitle(String title) {
    return 'Participar em $title?';
  }

  @override
  String cityPilotBookingTerms(
    String host,
    String safetyContact,
    String accessibility,
  ) {
    return 'Esta experiência é gratuita. O encontro é num local público: respeita os limites das outras pessoas e trata da tua deslocação. Podes sair a qualquer momento.\n\nAnfitrião: $host\nContacto de segurança: $safetyContact\n\nAcessibilidade: $accessibility\n\nEm caso de perigo imediato, contacta os serviços de emergência locais.';
  }

  @override
  String get cityPilotAcceptReserve => 'Aceitar e reservar lugar';

  @override
  String get cityPilotReservedNotice =>
      'O teu lugar está reservado. Podes cancelar aqui a qualquer momento.';

  @override
  String get cityPilotFeedbackTitle => 'Como foi a experiência?';

  @override
  String get cityPilotFeedbackIntro =>
      'Opcional. As respostas contribuem para os resultados agregados do projeto-piloto. Não são mostradas a outros membros nem ao anfitrião.';

  @override
  String get cityPilotDidYouAttend => 'Foste?';

  @override
  String get cityPilotAttendedYes => 'Sim, fui';

  @override
  String get cityPilotAttendedNo => 'Não consegui ir';

  @override
  String get cityPilotWorthwhileQuestion => 'Valeu a pena? (opcional)';

  @override
  String get cityPilotNotThisTime => 'Desta vez não';

  @override
  String get cityPilotSkip => 'Saltar';

  @override
  String get cityPilotShareFeedback => 'Enviar feedback';

  @override
  String get cityPilotFeedbackThanks =>
      'Obrigado. O teu feedback foi registado de forma privada.';

  @override
  String get cityPilotTimeTbc => 'Hora a confirmar';

  @override
  String get cityPilotTitle => 'O projeto-piloto na cidade';

  @override
  String get cityPilotRefreshTooltip => 'Atualizar projeto-piloto';

  @override
  String get cityPilotHeroTitle => 'Um pouco mais perto.\nMuito mais real.';

  @override
  String get cityPilotHeroBody =>
      'Uma cidade. Uma pequena comunidade. Mais hipóteses de uma conversa se tornar um plano.';

  @override
  String get cityPilotStep1Title => 'Começa com uma conversa';

  @override
  String get cityPilotStep1Body =>
      'Conhece pessoas ao teu ritmo através das apresentações que já tens.';

  @override
  String get cityPilotStep2Title => 'Abre espaço para um encontro a sério';

  @override
  String get cityPilotStep2Body =>
      'Façam um plano juntos. Partilha como correu só se quiseres.';

  @override
  String get cityPilotStep3Title => 'Experimentem algo juntos';

  @override
  String get cityPilotStep3Body =>
      'Pequenas experiências com anfitrião chegam depois da primeira avaliação do projeto-piloto.';

  @override
  String get cityPilotSaving => 'A guardar a preferência';

  @override
  String get cityPilotUnavailableTitle =>
      'O teu projeto-piloto não está disponível';

  @override
  String get cityPilotUnavailableBody =>
      'Verifica a tua ligação e atualiza para veres a tua participação e reservas mais recentes.';

  @override
  String get cityPilotComingSoonTitle => 'Em breve numa cidade perto de ti';

  @override
  String get cityPilotComingSoonBody =>
      'Ainda não há um projeto-piloto aberto para a cidade do teu perfil. Quando abrir um, podes escolher se queres participar. A tua experiência atual continua como sempre.';

  @override
  String cityPilotPanelTitleJoined(String city) {
    return '$city · Fazes parte';
  }

  @override
  String cityPilotPanelTitleOpen(String city) {
    return '$city · Projeto-piloto';
  }

  @override
  String cityPilotRecruitmentCloses(String date) {
    return 'Fim das inscrições: $date (hora local).';
  }

  @override
  String get cityPilotPaused =>
      'Novas participações e reservas estão em pausa. Continuas a poder sair ou cancelar.';

  @override
  String get cityPilotCompleted =>
      'Este projeto-piloto terminou. Obrigado por teres participado.';

  @override
  String get cityPilotMeasurement =>
      'Ao aderires, podemos contar conversas, planos aceites e respostas opcionais a «o encontro aconteceu?» nos novos matches em que ambas as pessoas aderiram a este projeto-piloto. Usamos janelas de 7 dias para conversas e de 28 dias para encontros. Não lemos o texto das mensagens nem as notas privadas de feedback para o projeto-piloto.';

  @override
  String get cityPilotPrivacy =>
      'A participação é privada. Não há lista pública de presenças nem pontuação de encontros. Sair exclui a tua atividade dos resultados atuais e cancela as reservas. Os resultados agregados já analisados não podem ser desfeitos.';

  @override
  String get cityPilotConsent =>
      'Aceito participar neste projeto-piloto e na medição dos seus resultados.';

  @override
  String get cityPilotJoinedNotice =>
      'Já estás dentro. Continua a conhecer pessoas ao teu ritmo.';

  @override
  String get cityPilotJoin => 'Aderir ao projeto-piloto';

  @override
  String get cityPilotWithdrawn =>
      'Saíste deste projeto-piloto. Os teus matches e conversas mantêm-se.';

  @override
  String get cityPilotNotAccepting =>
      'Este projeto-piloto não está a aceitar novos membros de momento.';

  @override
  String get cityPilotExperiencesHeading =>
      'Pequenos planos. Experiências partilhadas.';

  @override
  String get cityPilotNoExperiences =>
      'As experiências com anfitrião ainda não estão abertas. Vão aparecer aqui depois de uma avaliação de resultados e segurança.';

  @override
  String cityPilotEventDetails(
    String start,
    String end,
    String venue,
    String host,
  ) {
    return '$start → $end\nHora local · Grátis\n$venue\nAnfitrião: $host';
  }

  @override
  String cityPilotAccessibility(String details) {
    return 'Acessibilidade · $details';
  }

  @override
  String cityPilotSafetyContact(String contact) {
    return 'Contacto de segurança · $contact';
  }

  @override
  String get cityPilotEventCancelled =>
      'Esta experiência foi cancelada. Por favor, não te desloques ao local.';

  @override
  String get cityPilotPlaceReserved => 'O teu lugar está reservado.';

  @override
  String get cityPilotBookingCancelled => 'A tua reserva foi cancelada.';

  @override
  String get cityPilotCancelPlace => 'Cancelar o meu lugar';

  @override
  String get cityPilotReserveFree => 'Reservar um lugar grátis';

  @override
  String get cityPilotShareOptionalFeedback => 'Partilhar feedback opcional';

  @override
  String get cityPilotFeedbackReceived => 'Recebemos o teu feedback. Obrigado.';

  @override
  String get blogAudiencePrivate => 'Só eu';

  @override
  String get blogAudienceFriends => 'Amigos';

  @override
  String get blogAudienceCommunity => 'Comunidade Connect';

  @override
  String get blogInvitationNone => 'Sem convite';

  @override
  String get blogInvitationYourVersion => 'Como seria a tua versão?';

  @override
  String get blogInvitationTeachMe => 'O que me poderias ensinar sobre isto?';

  @override
  String get blogInvitationWhatNext => 'O que experimentarias a seguir?';

  @override
  String get blogRewardStoryPublishedTitle => 'Partilhar um capítulo';

  @override
  String get blogRewardStoryPublishedWho =>
      'Tu, na primeira vez que um capítulo é partilhado além de «Só eu»';

  @override
  String get blogRewardPhotoSharedTitle =>
      'Partilhar uma foto nos Temas de fotos';

  @override
  String get blogRewardPhotoSharedWho =>
      'Tu, por uma foto que partilhas nos Temas de fotos';

  @override
  String get blogRewardLikeReceivedTitle => 'Um gosto no teu capítulo ou foto';

  @override
  String get blogRewardLikeReceivedWho => 'Tu, por cada membro que gosta';

  @override
  String get blogRewardCommentReceivedTitle => 'Um comentário que aprovas';

  @override
  String get blogRewardCommentReceivedWho =>
      'Tu, quando aprovas o comentário de um leitor';

  @override
  String get blogRewardCommentApprovedTitle => 'O teu comentário é aprovado';

  @override
  String get blogRewardCommentApprovedWho =>
      'Tu, quando um autor aprova o teu comentário';

  @override
  String get blogRewardSubscriberGainedTitle => 'Um novo seguidor';

  @override
  String get blogRewardSubscriberGainedWho =>
      'Tu, por cada novo membro que segue os teus capítulos';

  @override
  String get blogRewardWallTierTitle => 'Chegar a mais murais';

  @override
  String get blogRewardWallTierWho =>
      'Tu, sempre que um capítulo atinge um novo nível de murais';

  @override
  String get blogRewardCoverOfWeekTitle => 'Capa da semana';

  @override
  String get blogRewardCoverOfWeekWho =>
      'Tu, quando o teu trabalho é escolhido como Capa da semana';

  @override
  String get blogScopeForYou => 'Para ti';

  @override
  String get blogScopeTopRated => 'Mais apreciados';

  @override
  String get blogScopeFollowing => 'A seguir';

  @override
  String get blogScopeMine => 'Meus';

  @override
  String get blogScopeCaptionMine =>
      'Os teus rascunhos e capítulos publicados. Escolhes o público de cada um.';

  @override
  String get blogScopeCaptionFriends =>
      'Capítulos partilhados pelos teus amigos no Connect.';

  @override
  String get blogScopeCaptionTop =>
      'Ordenados por gostos, comentários aprovados e leitores dos últimos 30 dias.';

  @override
  String get blogScopeCaptionFollowing =>
      'Os capítulos mais recentes dos autores que segues.';

  @override
  String get blogScopeCaptionCommunity =>
      'Para membros do Connect elegíveis e com sessão iniciada. Estes capítulos não são públicos na web.';

  @override
  String get blogTitle => 'Capítulos abertos';

  @override
  String get blogRewardsTitle => 'Como funcionam as recompensas';

  @override
  String get blogWritersTitle => 'Autores que segues';

  @override
  String get blogConnectionsTooltip => 'Respostas privadas, partilhas e avisos';

  @override
  String get blogSignInReadWrite =>
      'Inicia sessão para ler e escrever capítulos.';

  @override
  String get blogHeroTitle => 'Uma vida que vale\na pena conhecer.';

  @override
  String get blogHeroBody =>
      'A história por trás de uma foto. Uma pequena obsessão. Algo que ainda estás a aprender. Deixa o teu dia a dia falar por ti.';

  @override
  String get blogWriteChapter => 'Escrever um capítulo';

  @override
  String get blogPrivateResponses => 'Respostas privadas';

  @override
  String get blogSharedLinks => 'Ligações partilhadas';

  @override
  String get blogReviewNotices => 'Avisos de revisão';

  @override
  String get blogTopicAll => 'Todos';

  @override
  String get blogFeedLoadFailed => 'Não foi possível carregar os capítulos.';

  @override
  String get blogPreviousPage => 'Página anterior';

  @override
  String get blogMoreChapters => 'Mais capítulos';

  @override
  String get blogEmptyMineTitle => 'O teu próximo capítulo começa aqui.';

  @override
  String get blogEmptyMineBody =>
      'Começa por um momento sobre o qual adorarias que alguém te perguntasse. O teu primeiro rascunho é só para ti.';

  @override
  String get blogEmptyTopTitle =>
      'Quando os capítulos tocam as pessoas, sobem aqui.';

  @override
  String get blogEmptyTopFilteredBody =>
      'Ainda nada subiu neste tema. Experimenta «Todos» ou partilha um capítulo teu.';

  @override
  String get blogEmptyTopBody =>
      'Aqui vão aparecer os capítulos que os leitores adoraram nos últimos 30 dias.';

  @override
  String get blogEmptyFollowingFilteredTitle =>
      'Ainda nada de novo neste tema.';

  @override
  String get blogEmptyFollowingTitle =>
      'Os autores que segues vão aparecer aqui.';

  @override
  String get blogEmptyFollowingBody =>
      'Quando um capítulo te tocar, abre-o e toca em «Seguir os capítulos». Os novos capítulos vão reunir-se aqui para não perderes nada.';

  @override
  String get blogEmptyCommunityTitle =>
      'Por agora, está tudo um pouco calmo por aqui.';

  @override
  String get blogEmptyCommunityBody =>
      'Os capítulos aparecem aqui quando os membros decidem partilhá-los com este público.';

  @override
  String get blogFindWritersTopRated =>
      'Encontrar autores em «Mais apreciados»';

  @override
  String blogRankTooltip(int rank) {
    return 'Número $rank nos mais apreciados';
  }

  @override
  String get blogUntitled => 'Um capítulo sem título';

  @override
  String get blogDraftPlaceholder =>
      'Um rascunho privado à espera das tuas palavras.';

  @override
  String get blogReadEdit => 'Ler e editar →';

  @override
  String get blogReadChapter => 'Ler capítulo →';

  @override
  String get blogPhotoUnavailableRetry => 'Foto indisponível · Tentar de novo';

  @override
  String get blogTryAgain => 'Tentar de novo';

  @override
  String get blogDetailTitle => 'Um capítulo';

  @override
  String get blogSignInRead => 'Inicia sessão para ler capítulos.';

  @override
  String get blogDetailUnavailable =>
      'Este capítulo está indisponível ou o seu público mudou.';

  @override
  String get blogRespondPrivately => 'Responder em privado';

  @override
  String get blogCreatePublicPreview => 'Criar uma pré-visualização pública';

  @override
  String get blogRemovedByModerationNote =>
      'Removido pela moderação. Abre «Avisos de revisão» para ler a decisão ou pedir outra revisão.';

  @override
  String get blogEditChapter => 'Editar capítulo';

  @override
  String get blogDeleteChapter => 'Eliminar capítulo';

  @override
  String get blogDeleteChapterTitle => 'Eliminar este capítulo?';

  @override
  String get blogDeleteChapterMessage =>
      'Vai desaparecer para todos os públicos. Não é possível anular.';

  @override
  String get blogDeleteChapterFailed =>
      'Não foi possível confirmar a eliminação. Recarrega o capítulo antes de tentar de novo.';

  @override
  String get blogReportChapter => 'Denunciar capítulo';

  @override
  String get blogReportFailed => 'Não foi possível enviar a denúncia.';

  @override
  String get blogBlockThisMember => 'Bloquear este membro';

  @override
  String get blogBlockTitle => 'Bloquear este membro?';

  @override
  String get blogBlockMessageChapter =>
      'Deixam de ver os capítulos um do outro. Isto também bloqueia o contacto através do Connect.';

  @override
  String get blogBlockMember => 'Bloquear membro';

  @override
  String get blogBlockRetryFailed =>
      'Não foi possível bloquear este membro. Tenta outra vez.';

  @override
  String get blogCancel => 'Cancelar';

  @override
  String get blogEditorMissingFields =>
      'Adiciona um título e uma história antes de publicar.';

  @override
  String blogPublishConfirmTitle(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Publicar para «Só eu»?',
      'friends': 'Publicar para os amigos?',
      'community': 'Publicar na comunidade Connect?',
      'other': 'Publicar?',
    });
    return '$_temp0';
  }

  @override
  String get blogPublishFriendsBody =>
      'Os teus amigos no Connect vão poder ler o texto e ver as fotos deste capítulo. Podes mudar o público mais tarde.';

  @override
  String get blogPublishCommunityBody =>
      'Os membros do Connect elegíveis e com sessão iniciada vão poder ler este capítulo. Não vai aparecer na web pública. Podes mudar o público mais tarde.';

  @override
  String get blogPublishChapter => 'Publicar capítulo';

  @override
  String get blogSavedOnlyMe => 'Guardado. Só tu podes ler este capítulo.';

  @override
  String blogPublishedTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Publicado para «Só eu».',
      'friends': 'Publicado para os amigos.',
      'community': 'Publicado na comunidade Connect.',
      'other': 'Publicado.',
    });
    return '$_temp0';
  }

  @override
  String get blogSharedSnack =>
      'Partilhado. Os gostos e comentários dos leitores dão-te XP.';

  @override
  String get blogSeeMyLevel => 'Ver o meu nível';

  @override
  String get blogSaveUnconfirmed =>
      'Não conseguimos confirmar que foi guardado.';

  @override
  String blogEditsStillHere(String message) {
    return '$message As tuas alterações continuam aqui. Verifica a versão guardada antes de continuar.';
  }

  @override
  String blogSavedVersionTitle(String audience) {
    return 'Versão guardada · $audience';
  }

  @override
  String get blogSavedVersionNote =>
      'As tuas alterações atuais continuam no editor. Fecha este painel para as manter ou substitui-as por esta versão guardada.';

  @override
  String get blogKeepMyEdits =>
      'Manter as minhas alterações para a próxima vez que guardar';

  @override
  String get blogUseSavedVersion => 'Usar a versão guardada';

  @override
  String get blogSavedVersionLoadFailed =>
      'Não foi possível carregar a versão guardada. As tuas alterações continuam aqui.';

  @override
  String get blogDescribePhotoTitle => 'Descreve a tua foto';

  @override
  String get blogDescribePhotoBody =>
      'Uma breve descrição torna o teu capítulo acessível. Ao adicionar a foto, o texto fica guardado como rascunho «Só eu».';

  @override
  String get blogDescribePhotoLabel => 'O que está nesta foto?';

  @override
  String get blogAddToPrivateDraft => 'Adicionar ao rascunho privado';

  @override
  String get blogPhotoAdded => 'Foto adicionada ao teu rascunho privado.';

  @override
  String get blogPhotoAddFailed =>
      'Não foi possível adicionar a foto. Usa um JPEG ou PNG até 10 MB.';

  @override
  String blogCheckSavedBeforeRetrying(String message) {
    return '$message Verifica a versão guardada antes de tentar de novo.';
  }

  @override
  String get blogRemoveUnconfirmed =>
      'Não foi possível confirmar a remoção. Verifica a versão guardada.';

  @override
  String get blogSignInAsAuthor =>
      'Inicia sessão como autor para editar este capítulo.';

  @override
  String get blogLeaveEditorTitle => 'Sair sem guardar?';

  @override
  String get blogLeaveEditorMessage =>
      'As alterações não guardadas vão perder-se. O último capítulo guardado mantém-se.';

  @override
  String get blogLeaveEditor => 'Sair do editor';

  @override
  String get blogEditorPreviewTitle => 'Pré-visualização do capítulo';

  @override
  String get blogEditorTitle => 'O teu próximo capítulo';

  @override
  String get blogEditorHeadline => 'Um pouco mais de ti.';

  @override
  String get blogEditorIntro =>
      'Pequenas histórias são bem-vindas. Uma refeição que fizeste. Um lugar que te fez mudar de ideias. A foto com uma história por trás.';

  @override
  String get blogNotSavedDefault => 'Não guardado · «Só eu» por predefinição';

  @override
  String blogSavedFor(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Guardado para «Só eu»',
      'friends': 'Guardado para os amigos',
      'community': 'Guardado para a comunidade Connect',
      'other': 'Guardado',
    });
    return '$_temp0';
  }

  @override
  String get blogKeepWriting => 'Continuar a escrever';

  @override
  String get blogPreview => 'Pré-visualizar';

  @override
  String get blogCheckSavedVersion => 'Verificar a versão guardada';

  @override
  String blogPreviewNotSaved(String audience) {
    return 'Pré-visualização · $audience · Ainda não guardado';
  }

  @override
  String get blogStoryPlaceholder => 'A tua história vai aparecer aqui.';

  @override
  String get blogChapterTitleLabel => 'Título do capítulo';

  @override
  String get blogChapterTitleHint => 'O domingo em que aprendi a abrandar';

  @override
  String get blogStoryLabel => 'A tua história';

  @override
  String get blogStoryHint => 'Começa onde quiseres. Torna-a tua.';

  @override
  String get blogInvitationLabel => 'Terminar com um convite (opcional)';

  @override
  String get blogInvitationHelp =>
      'Deixa uma pergunta que ajude alguém a conhecer-te.';

  @override
  String get blogRemovePhoto => 'Remover foto';

  @override
  String get blogAddPhoto => 'Adicionar uma foto';

  @override
  String get blogPhotoRules =>
      'Até 6 fotos JPEG ou PNG, com 10 MB cada. As fotos precisam de aprovação. Guarda como «Só eu» antes de mudar as fotos de um capítulo publicado.';

  @override
  String get blogWhoFor => 'Para quem é este capítulo?';

  @override
  String get blogAudiencePrivateHelp =>
      'Só tu podes ler este capítulo. Amigos e matches não o veem.';

  @override
  String get blogAudienceFriendsHelp =>
      'Só os teus amigos no Connect o podem ler. Um match, por si só, não dá acesso.';

  @override
  String get blogAudienceCommunityHelp =>
      'Podem lê-lo os membros elegíveis com sessão iniciada. Completa o teu perfil com duas fotos de perfil aprovadas para publicar aqui. Não é uma partilha pública na web.';

  @override
  String get blogAllowFeaturing => 'Permitir destaque';

  @override
  String get blogAllowFeaturingHelp =>
      'Se os leitores adorarem, o teu capítulo pode chegar aos murais de outros membros: 50 gostos e 5 comentários chegam a 50 murais, 100 gostos e 10 comentários a 100. Podes desativar isto a qualquer momento.';

  @override
  String get blogSaveOnlyForMe => 'Guardar só para mim';

  @override
  String blogPublishTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Publicar para «Só eu»',
      'friends': 'Publicar para os amigos',
      'community': 'Publicar na comunidade Connect',
      'other': 'Publicar',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveAsOnlyMe => 'Guardar como «Só eu»';

  @override
  String get blogSaveNote =>
      'As tuas palavras ficam guardadas quando escolhes Guardar ou Publicar. A pré-visualização não publica nada.';

  @override
  String get blogTopicOptional => 'Tema (opcional)';

  @override
  String get blogTopicHelp =>
      'Ajuda os leitores interessados a encontrar o teu capítulo.';

  @override
  String get webDestBlog => 'Blog';

  @override
  String get webDestFirstChapter => 'Estúdio Primeiro capítulo';

  @override
  String get webDestDatingPreferences => 'Preferências de encontros';

  @override
  String get webDestEditProfile => 'Editar perfil';

  @override
  String get webDestProfilePhotos => 'Fotos de perfil';

  @override
  String get webDestLikedYou => 'Gostaram de ti';

  @override
  String get webDestNotifications => 'Notificações';

  @override
  String get webDestDailyPrompt => 'Pergunta do dia';

  @override
  String get webDestLevels => 'Níveis e progresso';

  @override
  String get webDestTrustBadges => 'Selos de confiança';

  @override
  String get webDestTrustFilters => 'Filtros de confiança';

  @override
  String get webDestIcebreakers => 'Quebra-gelos';

  @override
  String get webDestCircleChallenges => 'Desafios do círculo';

  @override
  String get webDestCoffeePolls => 'Sondagens de café';

  @override
  String get webDestGroups => 'Grupos';

  @override
  String get webDestRooms => 'Salas de conversa';

  @override
  String get webDestMatchNudges => 'Toques aos matches';

  @override
  String get webDestFriends => 'Amigos';

  @override
  String get webDestDatePlans => 'Planos de encontro';

  @override
  String get webDestCallHistory => 'Histórico de chamadas';

  @override
  String get webDestMembership => 'Subscrição';

  @override
  String get webDestVerification => 'Verificação';

  @override
  String get webDestPrivacySafety => 'Privacidade e segurança';

  @override
  String get webDestAccountData => 'Conta e dados';

  @override
  String get webDestBlockedMembers => 'Membros bloqueados';

  @override
  String get webDestEmergencyContacts => 'Contactos de emergência';

  @override
  String get webDestModerationAppeals => 'Recursos de moderação';

  @override
  String get webDestNotificationPreferences => 'Preferências de notificações';

  @override
  String get webDestHelpSupport => 'Ajuda e apoio';

  @override
  String get webNavExplore => 'Explorar';

  @override
  String get webNavMyProfile => 'O meu perfil';

  @override
  String get webNavAllFeatures => 'Todas as funcionalidades';

  @override
  String get webNavMoreForYou => 'Mais para ti';

  @override
  String get webNavPreferences => 'Preferências';

  @override
  String get webNavWebsite => 'Site do Connect';

  @override
  String get webNavSignOut => 'Terminar sessão';

  @override
  String get webPageNotFound => 'Esta página não foi encontrada.';

  @override
  String get webBackToDiscover => 'Voltar a Descobrir';

  @override
  String get webTagline => 'O teu ritmo. A tua escolha.';

  @override
  String webUnavailableTitle(String label) {
    return '$label ainda não está disponível.';
  }

  @override
  String get webUnavailableBody => 'Não faz parte desta versão do Connect.';

  @override
  String get webDirectoryTitle => 'Torna este espaço teu.';

  @override
  String get webDirectorySubtitle =>
      'O teu perfil, conversas, comunidade e controlos — tudo num só lugar.';

  @override
  String get webIcebreakerTitle => 'Ideias para iniciar conversa';

  @override
  String get webIcebreakerHeadline =>
      'Um pouco de inspiração para o teu próximo olá.';

  @override
  String get webIcebreakerBody =>
      'A gravação e reprodução de voz ainda não estão disponíveis. Podes usar estas ideias numa conversa elegível.';

  @override
  String get webIcebreakerOpenMatches => 'Abrir os meus matches';

  @override
  String get webMembershipHeadline => 'Um pouco mais de possibilidades.';

  @override
  String get webMembershipIntro =>
      'Explora os planos atuais. O pagamento no navegador ainda não está disponível. Nesta página não é possível comprar nem cobrar nada.';

  @override
  String webMembershipCurrent(String plan) {
    return 'A tua subscrição: $plan';
  }

  @override
  String webMembershipStatus(String status) {
    return 'Estado: $status';
  }

  @override
  String get webMembershipMonthly => 'Mensal';

  @override
  String get webMembershipYearly => 'Anual';

  @override
  String get webMembershipFree => 'Grátis';

  @override
  String webMembershipPrice(String price, String cycle) {
    String _temp0 = intl.Intl.selectLogic(cycle, {
      'yearly': 'ano',
      'other': 'mês',
    });
    return '$price / $_temp0';
  }

  @override
  String get webMembershipFootnote =>
      'Os preços do catálogo são uma pré-visualização. A subscrição nunca ultrapassa os limites de outra pessoa nem os requisitos para conversar.';

  @override
  String get blogLinkCopied => 'Ligação copiada. Partilha-a onde quiseres.';

  @override
  String get blogYourPublicLink => 'A tua ligação pública';

  @override
  String get blogShareUnconfirmed =>
      'Não foi possível confirmar a partilha. Verifica «Ligações partilhadas» antes de tentar de novo.';

  @override
  String get blogSignInAgain => 'Inicia sessão novamente para continuar.';

  @override
  String get blogSharedJournalPage => 'Uma página de diário partilhada';

  @override
  String get blogYourPublicPreview => 'A tua pré-visualização pública';

  @override
  String get blogShareJointHeadline =>
      'Uma história que ambos decidem partilhar.';

  @override
  String get blogShareSoloHeadline => 'Uma pequena janela para o teu mundo.';

  @override
  String get blogShareJointBody =>
      'Os dois autores têm de aprovar exatamente estas palavras para a ligação funcionar. Qualquer um a pode retirar.';

  @override
  String get blogShareSoloBody =>
      'Qualquer pessoa com a ligação pode ler o texto e ver as fotos selecionadas, sem conta. O capítulo completo fica no Connect.';

  @override
  String get blogShareIdentityNote =>
      'Não é adicionado nenhum perfil nem nome de conta. As tuas palavras e fotos podem ainda assim identificar pessoas ou lugares. Publica só o que tens autorização para partilhar.';

  @override
  String get blogExcerptLabel => 'Excerto exato do teu capítulo';

  @override
  String blogIncludePhoto(String description) {
    return 'Incluir: $description';
  }

  @override
  String get blogApproveCopy => 'Aprovo exatamente esta cópia pública';

  @override
  String get blogApproveCopyNote =>
      'Editar ou ocultar o capítulo original invalida a ligação. As cópias guardadas fora do Connect não podem ser recuperadas.';

  @override
  String get blogSaving => 'A guardar…';

  @override
  String get blogRequestOtherApproval => 'Pedir a aprovação do outro autor';

  @override
  String get blogCreatePublicLink => 'Criar ligação pública';

  @override
  String get blogJointApprovalRecorded =>
      'A tua aprovação ficou registada. A ligação fica indisponível até o outro autor aprovar.';

  @override
  String get blogPublicCopyReady => 'A tua cópia pública está pronta.';

  @override
  String get blogCopyPublicLink => 'Copiar ligação pública';

  @override
  String get blogManageSharedLinks => 'Gerir ligações partilhadas';

  @override
  String blogFollowerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seguidores',
      one: '1 seguidor',
    );
    return '$_temp0';
  }

  @override
  String get blogUnfollowFailed =>
      'Não conseguimos deixar de seguir agora. Tenta outra vez.';

  @override
  String get blogFollowFailed =>
      'Não conseguimos seguir este autor agora. Tenta outra vez.';

  @override
  String get blogFollowingButton => 'A seguir';

  @override
  String get blogFollowTheirChapters => 'Seguir os capítulos';

  @override
  String get blogRewardsIntro =>
      'Quando o que partilhas toca alguém, conta. Os gostos dos leitores, os comentários aprovados e os novos seguidores dão-te XP para o teu nível. As recompensas vêm do que os leitores fazem, nunca de toques, e cada uma é atribuída só uma vez.';

  @override
  String blogRewardDailyCap(int cap) {
    return 'Até $cap XP por dia';
  }

  @override
  String blogRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String get blogSignInWriters =>
      'Inicia sessão para ver os autores que segues.';

  @override
  String get blogWritersLoadFailed =>
      'Não foi possível carregar os autores que segues.';

  @override
  String get blogNoWriters => 'Ainda não há autores.';

  @override
  String get blogNoWritersBody =>
      'Quando um capítulo te tocar, toca em «Seguir os capítulos». Os novos capítulos vão reunir-se em «A seguir».';

  @override
  String blogLatest(String title) {
    return 'Mais recente: $title';
  }

  @override
  String get blogReactionFailed =>
      'A tua reação não foi enviada. Tenta outra vez.';

  @override
  String blogCannotLikeOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Não podes gostar da tua própria foto',
      'other': 'Não podes gostar do teu próprio capítulo',
    });
    return '$_temp0';
  }

  @override
  String blogYouReacted(String reaction) {
    return 'Reagiste: $reaction. Toca para anular';
  }

  @override
  String blogLikeThis(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Gostar desta foto',
      'other': 'Gostar deste capítulo',
    });
    return '$_temp0';
  }

  @override
  String blogCannotReactOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Não podes reagir à tua própria foto',
      'other': 'Não podes reagir ao teu próprio capítulo',
    });
    return '$_temp0';
  }

  @override
  String get blogReactTooltip =>
      'Reagir: Estou a ouvir-te, Eu também, Um abraço…';

  @override
  String blogCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comentários',
      one: '1 comentário',
    );
    return '$_temp0';
  }

  @override
  String blogWaitingForYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '· $count à tua espera',
      one: '· $count à tua espera',
    );
    return '$_temp0';
  }

  @override
  String get blogFeatured => 'Em destaque';

  @override
  String blogTierNeedsBoth(int likes, int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes gostos',
      one: '1 gosto',
    );
    String _temp1 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments comentários',
      one: '1 comentário',
    );
    String _temp2 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls murais',
      one: '1 mural',
    );
    return 'Mais $_temp0 e $_temp1 para chegar a $_temp2';
  }

  @override
  String blogTierNeedsLikes(int likes, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes gostos',
      one: '1 gosto',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls murais',
      one: '1 mural',
    );
    return 'Mais $_temp0 para chegar a $_temp1';
  }

  @override
  String blogTierNeedsComments(int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments comentários',
      one: '1 comentário',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls murais',
      one: '1 mural',
    );
    return 'Mais $_temp0 para chegar a $_temp1';
  }

  @override
  String blogTierAlmostThere(int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: 'Quase lá: a seguir $walls murais',
      one: 'Quase lá: a seguir 1 mural',
    );
    return '$_temp0';
  }

  @override
  String blogOnWalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Em $count murais',
      one: 'Em 1 mural',
    );
    return '$_temp0';
  }

  @override
  String blogProgressToward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Progresso até $count murais',
      one: 'Progresso até 1 mural',
    );
    return '$_temp0';
  }

  @override
  String get blogReachIdle =>
      'Os leitores podem levar este capítulo mais longe';

  @override
  String get blogReachLive =>
      'Membros que adoraram histórias como a tua estão a lê-lo agora.';

  @override
  String get blogFeaturedStories => 'Histórias em destaque';

  @override
  String get blogFeaturedCaption =>
      'Histórias que outros membros adoraram, entregues no teu mural.';

  @override
  String blogByAuthor(String name) {
    return 'por $name';
  }

  @override
  String get blogLikes => 'Gostos';

  @override
  String get blogComments => 'Comentários';

  @override
  String get blogCommentHint => 'O que te ficou?';

  @override
  String get blogCommentApproved =>
      'Aprovado. Agora quem pode ler este capítulo também o vê.';

  @override
  String get blogCommentSent => 'Enviado ao autor para aprovação';

  @override
  String get blogCommentSendFailed =>
      'O teu comentário não foi enviado. As tuas palavras continuam aqui, por isso podes tentar de novo.';

  @override
  String blogCommentDeclined(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Recusado. Não vai aparecer na tua foto.',
      'other': 'Recusado. Não vai aparecer no teu capítulo.',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveFailed => 'Não ficou guardado. Tenta outra vez.';

  @override
  String get blogDeleteCommentTitle => 'Eliminar este comentário?';

  @override
  String get blogDeleteCommentMessage =>
      'Vai ser removido para toda a gente. Não é possível anular.';

  @override
  String get blogDeleteComment => 'Eliminar comentário';

  @override
  String get blogCommentDeleted => 'Comentário eliminado.';

  @override
  String get blogCommentDeleteFailed =>
      'Não foi possível eliminar o comentário. Tenta outra vez.';

  @override
  String get blogCommentsAuthorNote =>
      'Os novos comentários aguardam a tua aprovação antes de mais alguém os ver.';

  @override
  String get blogCommentsReaderNote =>
      'O autor lê primeiro cada comentário e escolhe o que partilhar.';

  @override
  String get blogLeaveComment => 'Deixa um comentário';

  @override
  String get blogSendToAuthor => 'Enviar ao autor';

  @override
  String get blogCommentsLoadFailed =>
      'Não foi possível carregar os comentários.';

  @override
  String get blogWaitingApproval => 'À espera da tua aprovação';

  @override
  String get blogNoCommentsInvite =>
      'Ainda não há comentários. Diz algo simpático para começar a conversa.';

  @override
  String get blogNoCommentsShared => 'Ainda não há comentários partilhados.';

  @override
  String get blogCommentNotShared => 'O autor decidiu não partilhar este.';

  @override
  String get blogYou => 'Tu';

  @override
  String get blogCommentOptions => 'Opções do comentário';

  @override
  String get blogReportComment => 'Denunciar comentário';

  @override
  String get blogApprove => 'Aprovar';

  @override
  String get blogDecline => 'Recusar';

  @override
  String get blogSignInContinue => 'Inicia sessão para continuar.';

  @override
  String get blogPrivateResponseTitle => 'Uma resposta privada';

  @override
  String blogPrivateResponseHelp(String invitation) {
    return '$invitation\n\nSó o autor recebe esta resposta. Pode aceitar ou recusar uma troca opcional. Até cinco novas respostas por dia, e uma ao mesmo autor.';
  }

  @override
  String get blogSendPrivateResponse => 'Enviar resposta privada';

  @override
  String get blogTextSaveUnconfirmed =>
      'Não foi possível confirmar que foi guardado. As tuas palavras continuam aqui; tenta de novo ou recarrega a troca guardada.';

  @override
  String get blogLeaveUnsentTitle => 'Sair sem enviar?';

  @override
  String get blogLeaveUnsentMessage =>
      'As palavras não enviadas vão ser descartadas.';

  @override
  String get blogLeave => 'Sair';

  @override
  String get blogOwnWordsLabel => 'Nas tuas próprias palavras';

  @override
  String get blogSending => 'A enviar…';

  @override
  String get blogChangeUnconfirmed =>
      'Não foi possível confirmar a alteração. Atualiza para verificar.';

  @override
  String get blogConnectionsTitle => 'As tuas ligações de Capítulos';

  @override
  String get blogRefresh => 'Atualizar';

  @override
  String get blogConnectionsIntro =>
      'As boas histórias deixam espaço para mais alguém.';

  @override
  String get blogConnectionsLoadFailed =>
      'Não foi possível carregar as tuas ligações.';

  @override
  String get blogResponsesEmpty =>
      'As respostas aos teus capítulos e as que enviares vão aparecer aqui. Nada precisa de resposta imediata.';

  @override
  String get blogPublicationsEmpty =>
      'As tuas pré-visualizações públicas e ligações aprovadas em conjunto vão aparecer aqui.';

  @override
  String get blogNoticesEmpty => 'Não há avisos de revisão.';

  @override
  String get blogResponseRevealed => 'O vosso capítulo partilhado está pronto';

  @override
  String get blogResponseIncoming => 'Uma resposta para ti';

  @override
  String get blogResponseSent => 'Enviado · a escolha é dele, ao seu ritmo';

  @override
  String get blogResponseAccepted => 'Uma troca, ao vosso ritmo';

  @override
  String get blogResponseClosed => 'Esta troca está fechada';

  @override
  String get blogOpenExchange => 'Abrir troca privada';

  @override
  String get blogPublicationLive => 'Cópia pública ativa';

  @override
  String get blogPublicationRemoved => 'Removido pela moderação';

  @override
  String get blogPublicationNeedsBoth =>
      'Requer as duas aprovações e um capítulo original atual';

  @override
  String get blogPublicationSourceChanged =>
      'Original alterado · cria uma nova pré-visualização para voltar a partilhar';

  @override
  String get blogApprovePublicCopyTitle => 'Aprovar esta cópia pública?';

  @override
  String get blogApprovePublicCopyMessage =>
      'As palavras exatas acima vão ficar disponíveis para quem tiver a ligação. Ambos podem retirar a partilha. Não são adicionados nomes automaticamente, mas as palavras podem identificar-te.';

  @override
  String get blogApprovePublicCopyAction => 'Aprovar cópia pública';

  @override
  String get blogApproveExactPublicCopy => 'Aprovar exatamente a cópia pública';

  @override
  String get blogCopyLink => 'Copiar ligação';

  @override
  String get blogWithdrawLinkTitle => 'Retirar esta ligação?';

  @override
  String get blogWithdrawLinkMessage =>
      'A cópia pública vai ficar indisponível. As cópias já guardadas por outras pessoas não podem ser recuperadas.';

  @override
  String get blogWithdrawLink => 'Retirar ligação';

  @override
  String get blogYourAppeal => 'O teu recurso';

  @override
  String get blogRequestReview => 'Pedir outra revisão';

  @override
  String get blogRequestReviewHelp =>
      'Explica o que deve ser reconsiderado. O teu recurso vai em privado para a equipa de confiança. O conteúdo removido continua oculto durante a revisão.';

  @override
  String get blogSubmitAppeal => 'Enviar recurso';

  @override
  String get blogAppealDecision => 'Recorrer desta decisão';

  @override
  String get blogPrevious => 'Anterior';

  @override
  String get blogMore => 'Mais';

  @override
  String get blogExchangeChangeFailed =>
      'Não foi possível confirmar esta alteração. Atualiza e tenta de novo.';

  @override
  String get blogExchangeTitle => 'Uma troca de Capítulos privada';

  @override
  String get blogExchangeUnavailable => 'Esta troca já não está disponível.';

  @override
  String blogExchangeWith(String name) {
    return 'Com $name';
  }

  @override
  String get blogExchangeIntro =>
      'Uma resposta é um convite, nunca uma obrigação. Esta troca não cria um match nem desbloqueia a conversa.';

  @override
  String get blogAcceptExchange => 'Aceitar uma troca';

  @override
  String get blogDeclineKindly => 'Recusar com simpatia';

  @override
  String get blogResponseSentNote =>
      'A tua resposta foi enviada. Não há contagem decrescente nem necessidade de insistir.';

  @override
  String get blogExchangeClosedNote =>
      'Esta troca está fechada. Abre espaço para outra ligação ao teu ritmo.';

  @override
  String get blogOneStoryEach => 'Uma pequena história cada um.';

  @override
  String get blogOneStoryEachBody =>
      'Adiciona uma pequena continuação, uma memória ou a tua versão do momento. Os dois contributos aparecem juntos, só depois de ambos os enviarem.';

  @override
  String get blogYourSideTitle => 'A tua parte do capítulo';

  @override
  String get blogYourSideHelp =>
      'Partilha até 1000 caracteres. A outra pessoa só pode ler isto depois de também contribuir. Depois de enviado, o texto não pode ser editado; podes retirar a troca a qualquer momento.';

  @override
  String get blogSubmitContribution => 'Enviar o meu contributo';

  @override
  String get blogAddContribution => 'Adicionar o meu contributo';

  @override
  String get blogYourContribution => 'O teu contributo';

  @override
  String blogPartnerContribution(String name) {
    return 'Contributo de $name';
  }

  @override
  String get blogShapeDate => 'Planear juntos um encontro';

  @override
  String get blogInspiredNote => 'Inspirado na nossa troca de Capítulos.';

  @override
  String get blogTryStudio => 'Experimentar o Estúdio Primeiro Capítulo';

  @override
  String get blogDatePlanningUnavailable =>
      'O planeamento de encontros fica disponível se tiverem um match ativo e a conversa estiver desbloqueada.';

  @override
  String get blogProposeJournalPage => 'Propor uma página de diário partilhada';

  @override
  String get blogSourceUnavailable => 'O capítulo original está indisponível.';

  @override
  String get blogContributionSaved =>
      'O teu contributo ficou guardado em privado. A revelação acontece quando ambos estiverem prontos.';

  @override
  String get blogWithdrawExchangeTitle => 'Retirar esta troca?';

  @override
  String get blogWithdrawExchangeMessage =>
      'A resposta e os contributos deixam de estar disponíveis para ambos. As ligações públicas conjuntas também deixam de funcionar.';

  @override
  String get blogWithdrawExchange => 'Retirar troca';

  @override
  String get blogReportExchange => 'Denunciar troca';

  @override
  String get blogBlockMessageExchange =>
      'O contacto e o acesso aos capítulos um do outro vão terminar.';

  @override
  String get blogBlockFailed => 'Não foi possível bloquear este membro.';

  @override
  String get notificationsReadAll => 'Marcar tudo como lido';

  @override
  String get notificationsFallbackTitle => 'Notificação';

  @override
  String get notificationsLoadFailed =>
      'Não foi possível carregar as notificações.';

  @override
  String get notificationsPrefsUpdateFailed =>
      'Não foi possível atualizar as preferências de notificações.';

  @override
  String notificationsAgoMinutes(int count) {
    return 'há $count min';
  }

  @override
  String notificationsAgoHours(int count) {
    return 'há $count h';
  }

  @override
  String notificationsAgoDays(int count) {
    return 'há $count d';
  }

  @override
  String get wallsReactEyebrow => 'REAGIR';

  @override
  String wallsReactQuestion(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'O que sentes com esta foto?',
      'other': 'O que sentes com este capítulo?',
    });
    return '$_temp0';
  }

  @override
  String get wallsReactBody =>
      'A tua reação mostra que foram ouvidos. Cada reação conta como um gosto.';

  @override
  String get wallsReactRemove => 'Retirar a minha reação';

  @override
  String wallsReactionsSemantics(String list) {
    return 'Reações: $list';
  }

  @override
  String get wallsReactionLove => 'Adoro';

  @override
  String get wallsReactionHearYou => 'Estou a ouvir-te';

  @override
  String get wallsReactionMeToo => 'Eu também';

  @override
  String get wallsReactionWithYou => 'Estou contigo';

  @override
  String get wallsReactionHug => 'Envio-te um abraço';

  @override
  String get wallsReactionProud => 'Orgulho em ti';

  @override
  String get wallsSignInRequired => 'Inicia sessão para ver o teu mural.';

  @override
  String get celebrationCoverHeadline => 'A tua foto é a capa da semana';

  @override
  String celebrationReachHeadline(String kind, int reach) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'photo': 'A tua foto chegou a $reach murais',
      'other': 'O teu capítulo chegou a $reach murais',
    });
    return '$_temp0';
  }

  @override
  String get celebrationCoverMessage =>
      'Os membros adoraram. Esta semana todos a veem em Hoje.';

  @override
  String get celebrationReachMessage =>
      'Os membros adoraram. Agora está nos murais Hoje deles.';

  @override
  String celebrationQuotedTitle(String title) {
    return '«$title»';
  }

  @override
  String get celebrationBarrier => 'Celebração';

  @override
  String get celebrationLovely => 'Que bom';

  @override
  String get celebrationSeePhoto => 'Ver foto';

  @override
  String get celebrationSeeChapter => 'Ver capítulo';

  @override
  String rewardXpPill(int xp) {
    return '+$xp XP';
  }

  @override
  String get rewardClaimedTitle => 'Recompensa resgatada';

  @override
  String rewardNameDescription(String name, String description) {
    return '$name · $description';
  }

  @override
  String rewardPlusXpAnnouncement(int xp) {
    return 'mais $xp XP';
  }

  @override
  String rewardSourceXpLine(String source, int xp) {
    return '$source +$xp XP';
  }

  @override
  String rewardAndMore(int count) {
    return 'e mais $count';
  }

  @override
  String rewardBadgeLine(String badge) {
    return 'Selo: $badge';
  }

  @override
  String rewardLevelReached(int level) {
    return 'Nível $level alcançado';
  }

  @override
  String rewardBadgesEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selos conquistados',
      one: 'Selo conquistado',
    );
    return '$_temp0';
  }

  @override
  String get rewardYourRewardsToday => 'As tuas recompensas de hoje';

  @override
  String rewardNewRewards(int count) {
    return '$count novas recompensas';
  }

  @override
  String get rewardSourceStoryPublished => 'Capítulo publicado';

  @override
  String get rewardSourcePhotoShared => 'Foto partilhada';

  @override
  String get rewardSourceLikeReceived => 'Um membro gostou do teu trabalho';

  @override
  String get rewardSourceCommentReceived => 'Novo comentário no teu trabalho';

  @override
  String get rewardSourceCommentApproved => 'O teu comentário foi aprovado';

  @override
  String get rewardSourceSubscriberGained => 'Novo subscritor';

  @override
  String get rewardSourceWallTierReached => 'Nível de mural alcançado';

  @override
  String get rewardSourceCoverOfWeek => 'Capa da semana';

  @override
  String get rewardSourceDailyPromptSubmitted => 'Pergunta do dia respondida';

  @override
  String get rewardLineStoryPublished => 'O teu capítulo está no mundo.';

  @override
  String get rewardLinePhotoShared => 'A tua foto juntou-se ao tema.';

  @override
  String get rewardLineLikeReceived => 'Alguém adorou o que partilhaste.';

  @override
  String get rewardLineCommentReceived => 'Um leitor juntou-se à conversa.';

  @override
  String get rewardLineSubscriberGained =>
      'Alguém quer o teu próximo capítulo.';

  @override
  String get rewardLineWallTierReached =>
      'O teu trabalho chegou a mais murais.';

  @override
  String get rewardLineCoverOfWeek => 'Esta semana todos o veem em Hoje.';

  @override
  String get rewardLineOther => 'Conquistado por atividade significativa.';

  @override
  String get rewardNewBadgeFallback => 'Novo selo';

  @override
  String get blockedUnknownUser => 'Utilizador desconhecido';

  @override
  String get themeTaglineBluerose =>
      'Veludo da meia-noite, rosas safira e um rebordo de platina.';

  @override
  String get themeTaglineBluelotus =>
      'Água ao luar, pétalas safira e um coração dourado.';

  @override
  String discoverMessageLikeSent(String name) {
    return 'Love enviado a $name. Podem conversar assim que $name retribuir o like.';
  }

  @override
  String get notificationsDismissFailed =>
      'Não foi possível remover a notificação. Tenta de novo.';

  @override
  String get notificationsReadAllFailed =>
      'Não foi possível marcar tudo como lido. Tenta de novo.';

  @override
  String get blogReportSubmitted => 'Denúncia enviada. Obrigado.';

  @override
  String get settingsSectionAccount => 'Conta';

  @override
  String settingsSignedInAs(String username) {
    return 'Sessão iniciada como @$username';
  }

  @override
  String get settingsSignOut => 'Terminar sessão';

  @override
  String get settingsSignOutSubtitle =>
      'Termina a tua sessão neste dispositivo';

  @override
  String get settingsSignOutAllTitle =>
      'Terminar sessão em todos os dispositivos';

  @override
  String get settingsSignOutAllSubtitle =>
      'Termina todas as sessões, em cada telemóvel e navegador';

  @override
  String get settingsSignOutConfirmTitle => 'Terminar sessão?';

  @override
  String get settingsSignOutConfirmBody =>
      'Vais precisar do teu nome de utilizador e da tua palavra-passe para voltares a iniciar sessão neste dispositivo.';

  @override
  String get settingsSignOutAllConfirmTitle =>
      'Terminar sessão em todos os dispositivos?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'A tua sessão termina em todos os telemóveis, tablets e navegadores, incluindo este. Quem tiver sessão iniciada na tua conta noutro lado será desligado.';

  @override
  String get settingsSignOutAllConfirmAction =>
      'Terminar sessão em todo o lado';

  @override
  String get settingsSignOutAllFailed =>
      'Não foi possível terminar a sessão nos teus outros dispositivos. Verifica a ligação e tenta novamente.';

  @override
  String get supportPaymentHelpLink =>
      'Problema com um pagamento? Contacta o suporte';

  @override
  String get supportReportHelpLink =>
      'Precisas de mais ajuda? Contacta o suporte';

  @override
  String get supportSignedOutHelpLink => 'Outro problema? Contacta o suporte';

  @override
  String get supportGuestSubtitle =>
      'Não consegues iniciar sessão ou outra coisa não funciona? Conta-nos o que aconteceu e respondemos por e-mail.';

  @override
  String get supportGuestEmailLabel => 'O teu e-mail';

  @override
  String get supportGuestEmailHint => 'Respondemos para este endereço';

  @override
  String get supportGuestNameLabel => 'O teu nome (opcional)';

  @override
  String get supportGuestEmailInvalid =>
      'Introduz um endereço de e-mail válido para podermos responder.';

  @override
  String get supportGuestSentTitle => 'Pedido enviado';

  @override
  String supportGuestSentBody(String reference, String email) {
    return 'Obrigado. A tua referência é $reference. Respondemos para $email.';
  }

  @override
  String get supportGuestUnavailableBody =>
      'De momento não é possível enviar pedidos de suporte a partir da app. Para algo urgente, escreve para support@connect.example.';

  @override
  String get supportDraftRestored => 'Guardámos o teu pedido por enviar.';

  @override
  String get supportDraftDiscard => 'Descartar rascunho';

  @override
  String get discoverActionUndo => 'Desfazer';

  @override
  String get discoverActionLike => 'Gosto';

  @override
  String get discoverActionSuperLike => 'Super like';

  @override
  String get navQaVerifyShortcut => 'Verificar';

  @override
  String get chatMessageDeletedPlaceholder => 'Mensagem eliminada';

  @override
  String get chatGiftYouSentHeading => 'Enviaste um presente';

  @override
  String get commonMemberFallbackName => 'Um membro';

  @override
  String get giftNameRoseRedSingle => 'Uma rosa vermelha';

  @override
  String get giftNameRosePinkSoft => 'Rosa cor-de-rosa';

  @override
  String get giftNameRoseWhitePure => 'Rosa branca';

  @override
  String get giftNameRoseYellowFriendship => 'Rosa amarela';

  @override
  String get giftNameRoseLavenderCrush => 'Rosa lavanda';

  @override
  String get giftNameRoseBlueRare => 'Rosa azul';

  @override
  String get giftNameRoseBlackMystery => 'Rosa negra';

  @override
  String get giftNameRoseSparkle => 'Rosa cintilante';

  @override
  String get giftNameRoseHeartPetal => 'Rosa de pétalas em coração';

  @override
  String get giftNameRoseNeonGlow => 'Rosa néon';

  @override
  String get giftNameRoseRain => 'Chuva de rosas';

  @override
  String get giftNameRoseBurningFlame => 'Rosa em chamas';

  @override
  String get giftNameRoseGolden => 'Rosa dourada';

  @override
  String get giftNameRoseCrystal => 'Rosa de cristal';

  @override
  String get giftNameRoseBouquet12 => 'Ramo de rosas (12)';

  @override
  String get giftNameRoseBouquet24 => 'Ramo de rosas (24)';

  @override
  String get giftNameRoseSeasonalWeekly => 'Rosa sazonal de edição limitada';

  @override
  String get giftNameChocolateBox => 'Caixa de bombons';

  @override
  String get giftNameHeartBalloon => 'Balão de coração';

  @override
  String get giftNameTeddyBear => 'Ursinho de peluche';

  @override
  String get giftNameFlowerBouquet => 'Ramo de flores';

  @override
  String get giftNameJewelleryBox => 'Caixa de joias';

  @override
  String get giftNameChampagneToast => 'Brinde com champanhe';

  @override
  String get giftNameHeartExplosion => 'Explosão de corações';

  @override
  String get giftNameConfettiShower => 'Chuva de confettis';

  @override
  String get giftNameFireworksBurst => 'Fogo de artifício';

  @override
  String get giftNameStarShower => 'Chuva de estrelas';

  @override
  String get giftNameGoldenSparkle => 'Brilho dourado';

  @override
  String get giftNameRainbowWave => 'Onda arco-íris';

  @override
  String get giftNameCoffeeDateInvite => 'Convite para um café';

  @override
  String get giftNamePicnicInvite => 'Convite para um piquenique';

  @override
  String get giftNameMovieNightInvite => 'Convite para uma noite de cinema';

  @override
  String get giftNameSunsetWalkInvite =>
      'Convite para um passeio ao pôr do sol';

  @override
  String get giftNameDateNightCard => 'Cartão de noite a dois';

  @override
  String get giftNameValentineSurprise => 'Surpresa de São Valentim';

  @override
  String get giftNameDiamondRing => 'Anel de diamantes';

  @override
  String get giftNameLuxuryDate => 'Encontro de luxo';

  @override
  String get blogPublicationUnavailableTitle => 'Partilha indisponível';

  @override
  String get blogPublicationUnavailableExcerpt =>
      'A origem mudou ou o acesso foi retirado. Retira esta ligação.';

  @override
  String get blogNoticeKindPost => 'Publicação';

  @override
  String get blogNoticeKindResponse => 'Resposta';

  @override
  String get blogNoticeKindPublication => 'Cópia pública';

  @override
  String get blogNoticeKindThemeEntry => 'Foto temática';

  @override
  String get blogNoticeKindClub => 'Clube';

  @override
  String get blogNoticeKindClubPost => 'Publicação do clube';

  @override
  String get blogNoticeKindReview => 'Crítica';

  @override
  String get blogNoticeKindList => 'Lista';

  @override
  String get blogNoticeKindComment => 'Comentário';

  @override
  String get blogNoticeKindPhotoComment => 'Comentário de foto';

  @override
  String get blogNoticeKindChatMessage => 'Mensagem de chat';

  @override
  String get blogNoticeKindGroup => 'Grupo';

  @override
  String get blogNoticeKindOther => 'Conteúdo';

  @override
  String get blogNoticeStatusPending => 'Em análise';

  @override
  String get blogNoticeStatusDismissed => 'Sem medidas';

  @override
  String get blogNoticeStatusRemoved => 'Removido';

  @override
  String get blogNoticeStatusRestored => 'Reposto';

  @override
  String get engagementTrustMilestoneProfileDepth => 'Profundidade do perfil';

  @override
  String get engagementTrustMilestoneCommunication => 'Comunicação';

  @override
  String get engagementTrustMilestoneConsistency => 'Consistência';

  @override
  String get engagementTrustMilestonePromptCompletion =>
      'Perguntas respondidas';

  @override
  String get engagementTrustMilestoneActivitySignals => 'Sinais de atividade';

  @override
  String get engagementTrustMilestoneUnsafeSignals => 'Alertas de segurança';

  @override
  String get engagementTrustMilestoneReportPenalty =>
      'Penalização por denúncias';

  @override
  String get engagementTrustMilestoneVerification => 'Verificação coerente';

  @override
  String get engagementTrustMilestoneSafety => 'Segurança';

  @override
  String engagementTrustMilestoneLine(String label, String value) {
    return '$label: $value';
  }

  @override
  String get networkOfflineTryAgain =>
      'Não é possível ligar agora. Verifica a tua ligação à internet e tenta novamente.';

  @override
  String get apiErrorFeatureUnavailable =>
      'Esta funcionalidade não está disponível de momento.';

  @override
  String get apiErrorConversationUnavailable =>
      'Esta conversa já não está disponível.';

  @override
  String get apiErrorMemberUnavailable => 'Este membro não está disponível.';

  @override
  String get apiErrorChatLocked => 'Desbloqueia primeiro esta conversa.';

  @override
  String get apiErrorCopilotDailyLimit =>
      'Já usaste os rascunhos de hoje. Escreve esta mensagem tu.';

  @override
  String get apiErrorCopilotUnavailable =>
      'A ajuda para escrever não está disponível de momento.';

  @override
  String get apiErrorCopilotProfileUnavailable =>
      'O perfil não está disponível de momento.';

  @override
  String get apiErrorDatePlanAlreadyOpen =>
      'Já existe um plano de encontro aberto para este match.';

  @override
  String get apiErrorDatePlanMatchInactive =>
      'Os planos de encontro precisam de um match ativo.';

  @override
  String get apiErrorDatePlanNotOpen =>
      'Este plano de encontro já não está aberto.';

  @override
  String get apiErrorDatePlanCheckInTooEarly =>
      'Podes fazer check-in quando o plano começar.';

  @override
  String get apiErrorDatePlanDebriefTooEarly =>
      'O balanço abre quando o plano começar.';

  @override
  String get apiErrorSharedAvailabilityChanged =>
      'A disponibilidade partilhada mudou. Atualiza as horas sugeridas ou escolhe tu uma hora.';

  @override
  String get apiErrorGraduationAlreadyOpen =>
      'Já existe uma proposta de graduação aberta para este match.';

  @override
  String get apiErrorGraduationMatchInactive =>
      'A graduação precisa de um match ativo.';

  @override
  String get apiErrorGraduationNotOpen =>
      'Esta proposta de graduação já não está aberta.';

  @override
  String get apiErrorGraduationAlreadyConfirmed => 'Já se graduaram juntos.';

  @override
  String get apiErrorOutOfDate =>
      'Esta vista está desatualizada. Atualiza e tenta novamente.';

  @override
  String get apiErrorOutcomeUncertain =>
      'Não conseguimos confirmar. Atualiza para verificar antes de tentar novamente.';

  @override
  String get apiErrorInsufficientCoins =>
      'Não tens moedas suficientes para isto.';

  @override
  String get apiErrorChannelReadOnly =>
      'Este chat está só de leitura de momento.';

  @override
  String get apiErrorRoomFull =>
      'Esta sala está cheia de momento. Tenta novamente daqui a pouco.';

  @override
  String get apiErrorRoomRemoved =>
      'Um anfitrião removeu-te desta sala. Podes voltar a entrar quando esta sessão terminar.';

  @override
  String get apiErrorRoomNotJoined => 'Não estás nesta sala.';

  @override
  String get apiErrorDailyMessageLimit =>
      'Já usaste as mensagens de hoje. Tenta novamente depois da reposição ou melhora o teu plano.';

  @override
  String get apiErrorDailyLikeLimit =>
      'Já usaste os gostos de hoje. Tenta novamente depois da reposição ou melhora o teu plano.';

  @override
  String get apiErrorFriendRequired => 'Primeiro têm de ser amigos.';

  @override
  String get apiErrorVouchExists =>
      'Já escreveste uma recomendação para esta pessoa.';

  @override
  String get apiErrorIntroUnavailable =>
      'Esta apresentação já não está disponível.';

  @override
  String get apiErrorIntroAlreadyOpen =>
      'Já existe uma apresentação aberta entre estas duas pessoas.';

  @override
  String get apiErrorIntroNotOpen => 'Esta apresentação já não está aberta.';

  @override
  String get apiErrorTooManyTries =>
      'Demasiadas tentativas. Espera um momento e tenta novamente.';

  @override
  String get apiErrorQuestCooldown =>
      'Esta missão está em pausa. Tenta novamente daqui a pouco.';

  @override
  String get apiErrorQuestSelfReview =>
      'É o teu match que avalia a tua resposta à missão, não tu.';

  @override
  String get apiErrorQuestNotParticipant =>
      'Só as pessoas deste match podem participar na missão.';

  @override
  String get apiErrorPaymentsUnavailable =>
      'A compra de moedas não está disponível de momento.';

  @override
  String get apiErrorServiceBusy =>
      'O serviço está sobrecarregado de momento. Tenta novamente daqui a pouco.';

  @override
  String get apiErrorSignInAgain => 'Inicia sessão novamente para continuar.';

  @override
  String get friendsMemberFallback => 'Um membro';

  @override
  String get friendsActivityFallback => 'Atividade';

  @override
  String get membershipPlanFallback => 'Plano';

  @override
  String get membershipSubscriptionFallback => 'Subscrição';

  @override
  String engagementLevelRewardFallback(int level) {
    return 'Recompensa do nível $level';
  }

  @override
  String get engagementTrustBadgeUnknown => 'Distintivo desconhecido';

  @override
  String get firstChapterComfortDefaultLanguage => 'Português';

  @override
  String paymentWalletBalanceCoins(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString moedas',
      one: '1 moeda',
    );
    return '$_temp0';
  }

  @override
  String get languageIntroSignedOut =>
      'Escolhe o idioma do Connect. Aplica-se de imediato e, quando iniciares sessão, fica guardado na tua conta.';

  @override
  String languagePickerButtonSemantics(String language) {
    return 'Idioma: $language. Mudar de idioma';
  }

  @override
  String get authErrorUsernameTaken =>
      'Esse nome de utilizador já está a ser usado. Experimenta outro.';

  @override
  String get authErrorAccountSuspended =>
      'Esta conta está suspensa. Contacta o apoio se achares que é um erro.';

  @override
  String get authErrorAccountLocked =>
      'Demasiadas tentativas de início de sessão. Tenta novamente daqui a alguns minutos.';

  @override
  String get authErrorTooManyRequests =>
      'Demasiadas tentativas. Espera um momento e tenta novamente.';

  @override
  String get authErrorAccountTypeUnavailable =>
      'Este tipo de conta não está disponível de momento.';

  @override
  String get authErrorNetwork =>
      'Não é possível ligar agora. Verifica a tua ligação à internet e tenta novamente.';

  @override
  String get profileSetupReorderPhoto => 'Arrasta para reordenar esta foto';

  @override
  String get profileLanguageAssamese => 'Assamês';

  @override
  String get profileLanguageBengali => 'Bengali';

  @override
  String get profileLanguageBodo => 'Bodo';

  @override
  String get profileLanguageDogri => 'Dogri';

  @override
  String get profileLanguageEnglish => 'Inglês';

  @override
  String get profileLanguageGujarati => 'Guzerate';

  @override
  String get profileLanguageHindi => 'Hindi';

  @override
  String get profileLanguageKannada => 'Canarim';

  @override
  String get profileLanguageKashmiri => 'Caxemira';

  @override
  String get profileLanguageKonkani => 'Concani';

  @override
  String get profileLanguageMaithili => 'Maithili';

  @override
  String get profileLanguageMalayalam => 'Malaiala';

  @override
  String get profileLanguageManipuri => 'Manipuri';

  @override
  String get profileLanguageMarathi => 'Marata';

  @override
  String get profileLanguageNepali => 'Nepalês';

  @override
  String get profileLanguageOdia => 'Oriá';

  @override
  String get profileLanguagePunjabi => 'Panjabi';

  @override
  String get profileLanguageSanskrit => 'Sânscrito';

  @override
  String get profileLanguageSantali => 'Santali';

  @override
  String get profileLanguageSindhi => 'Sindi';

  @override
  String get profileLanguageTamil => 'Tâmil';

  @override
  String get profileLanguageTelugu => 'Télugo';

  @override
  String get profileLanguageUrdu => 'Urdu';

  @override
  String get profileCountryIndia => 'Índia';

  @override
  String get profileCountryUnitedKingdom => 'Reino Unido';

  @override
  String get profileCountryIreland => 'Irlanda';

  @override
  String get profileCountryGermany => 'Alemanha';

  @override
  String get profileCountryAustria => 'Áustria';

  @override
  String get profileMasterWorkoutSometimes => 'Às vezes';

  @override
  String get profileMasterWorkoutWeekly => 'Todas as semanas';

  @override
  String get profileMasterTravelRoadTrips => 'Viagens de carro';

  @override
  String get profileMasterTravelBackpacking => 'Viagens de mochila';

  @override
  String get profileMasterTravelLuxuryShort => 'Luxo';

  @override
  String get profileMasterTravelStaycations => 'Férias em casa';

  @override
  String get profileMasterPoliticsSimilarShort => 'Semelhantes';

  @override
  String get profileMasterPoliticsModerate => 'Moderadas';

  @override
  String get profileMasterPoliticsAny => 'Qualquer';

  @override
  String discoverOpenMemberProfile(String name) {
    return 'Abrir o perfil de $name';
  }

  @override
  String get chatCopilotDisclosureText =>
      'Diz isso por palavras tuas. Se o enviares tal como está, a outra pessoa verá que foi escrito com ajuda.';
}
