// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navDiscover => 'Descubrir';

  @override
  String get navMatches => 'Matches';

  @override
  String get navEngage => 'Participar';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionProfile => 'Perfil';

  @override
  String get settingsEditProfileTitle => 'Editar perfil';

  @override
  String get settingsEditProfileSubtitle => 'Actualiza tu información';

  @override
  String get settingsPhotosTitle => 'Fotos';

  @override
  String get settingsPhotosSubtitle => 'Gestiona tus fotos';

  @override
  String get settingsSectionPreferences => 'Preferencias';

  @override
  String get settingsAppearanceTitle => 'Apariencia';

  @override
  String get settingsAppearanceSubtitle => 'Guardado en tu cuenta';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeMatchDevice => 'Como el dispositivo';

  @override
  String get settingsLooksTitle => 'Estilos';

  @override
  String get settingsLooksClassicDescription =>
      'Warm ivory and forest by day. Soft mint and deep forest by night.';

  @override
  String get settingsLooksClassicLabel => 'Today';

  @override
  String get settingsThemeSaveFailed =>
      'No se pudo guardar tu tema. Inténtalo de nuevo.';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Elige el idioma de la app';

  @override
  String get settingsDatingPreferencesTitle => 'Preferencias de citas';

  @override
  String get settingsDatingPreferencesSubtitle => 'Edad, ubicación, intereses';

  @override
  String get settingsAccountDataTitle => 'Cuenta y datos';

  @override
  String get settingsAccountDataSubtitle =>
      'Oculta, descarga o elimina tu cuenta';

  @override
  String get settingsNotificationsTitle => 'Notificaciones';

  @override
  String get settingsNotificationsSubtitle =>
      'Notificaciones push y por correo';

  @override
  String get settingsSectionEngagement => 'Participar';

  @override
  String get settingsTrustBadgesTitle => 'Insignias de confianza';

  @override
  String get settingsTrustBadgesSubtitle =>
      'Mira las insignias que has ganado y tu historial de confianza';

  @override
  String get settingsTrustFiltersTitle => 'Filtros de confianza';

  @override
  String get settingsTrustFiltersSubtitle =>
      'Controla los requisitos de confianza para descubrir';

  @override
  String get settingsConversationRoomsTitle => 'Salas de conversación';

  @override
  String get settingsConversationRoomsSubtitle =>
      'Explora, únete, sal y modera salas';

  @override
  String get settingsFriendsTitle => 'Amigos y contactos';

  @override
  String get settingsFriendsSubtitle => 'Crea y cuida tus amistades';

  @override
  String get settingsCallHistoryTitle => 'Historial de llamadas';

  @override
  String get settingsCallHistorySubtitle => 'Revisa tus llamadas anteriores';

  @override
  String get settingsMatchNudgesTitle => 'Toques a tus matches';

  @override
  String get settingsMatchNudgesSubtitle =>
      'Reactiva las conversaciones que se han quedado en silencio';

  @override
  String get settingsSubscriptionsTitle => 'Suscripciones';

  @override
  String get settingsSubscriptionsSubtitle =>
      'Planes, estado de acceso y pagos';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsPrivacySafetyTitle => 'Privacidad y seguridad';

  @override
  String get settingsPrivacySafetySubtitle =>
      'Gestiona tu configuración de privacidad';

  @override
  String get settingsGovernmentVerificationTitle => 'Verificación de identidad';

  @override
  String get settingsGovernmentVerificationSubtitle =>
      'Consulta el estado de tu verificación de identidad';

  @override
  String get settingsQaVerificationUploadTitle => 'Subida de verificación QA';

  @override
  String get settingsQaVerificationUploadSubtitle =>
      'Flujo de documento y selfie solo para automatización';

  @override
  String get settingsHelpSupportTitle => 'Ayuda y soporte';

  @override
  String get settingsHelpSupportSubtitle =>
      'Preguntas frecuentes y contacto con soporte';

  @override
  String get settingsAboutTitle => 'Acerca de';

  @override
  String get settingsAboutSubtitle => 'Detalles de la app y tecnología';

  @override
  String get settingsLogout => 'Cerrar sesión';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageIntro =>
      'Elige el idioma en el que se muestra Connect. Tu elección se guarda en tu cuenta y se aplica en todos los dispositivos en los que inicies sesión.';

  @override
  String get languageUseDevice => 'Usar el idioma del dispositivo';

  @override
  String get languageUseDeviceSubtitle =>
      'Sigue el ajuste de idioma de tu teléfono';

  @override
  String get languageSaveFailed =>
      'No se pudo guardar tu idioma. Inténtalo de nuevo.';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsInboxTitle => 'Bandeja de notificaciones';

  @override
  String get notificationsInboxCaughtUp => 'Estás al día';

  @override
  String notificationsInboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sin leer',
      one: '1 sin leer',
    );
    return '$_temp0';
  }

  @override
  String get notificationsInAppTitle => 'Notificaciones en la app';

  @override
  String get notificationsInAppSubtitle =>
      'Mostrar notificaciones mientras usas la app';

  @override
  String get notificationsPushTitle => 'Notificaciones push';

  @override
  String get notificationsPushSubtitle =>
      'Permitir la entrega cuando la app está en segundo plano';

  @override
  String get notificationsNewMatchesTitle => 'Nuevos matches';

  @override
  String get notificationsNewMatchesSubtitle =>
      'Recibe un aviso cuando hagas match';

  @override
  String get notificationsNewMessagesTitle => 'Mensajes nuevos';

  @override
  String get notificationsNewMessagesSubtitle =>
      'Recibe un aviso con los mensajes del chat';

  @override
  String get notificationsLikesTitle => 'Me gusta';

  @override
  String get notificationsLikesSubtitle =>
      'Recibe un aviso cuando alguien te dé me gusta';

  @override
  String get notificationsMatchNudgesTitle => 'Toques de tus matches';

  @override
  String get notificationsMatchNudgesSubtitle =>
      'Recibe un aviso cuando un match te dé un toque';

  @override
  String get notificationsIncomingCallsTitle => 'Llamadas entrantes';

  @override
  String get notificationsIncomingCallsSubtitle =>
      'Mostrar avisos de llamadas entrantes';

  @override
  String get notificationsSafetyTitle => 'Novedades de seguridad';

  @override
  String get notificationsSafetySubtitle =>
      'Recibe avisos importantes sobre tu estado de seguridad';

  @override
  String get notificationsFriendPlansTitle => 'Planes de cita de tus amigos';

  @override
  String get notificationsFriendPlansSubtitle =>
      'Entérate cuando un amigo planea una cita o avisa de que está bien';

  @override
  String get welcomeTagline => 'Hecho para la vida real.';

  @override
  String get welcomePhotoNote => 'La meta es verse en persona.';

  @override
  String get welcomeHeadlineLead => 'Una buena historia\nempieza con un ';

  @override
  String get welcomeHeadlineAccent => 'hola.';

  @override
  String get welcomeBody =>
      'Encuentra a alguien que sea tu tipo de persona. Lo demás viene solo.';

  @override
  String get welcomeCreateAccount => 'Crear cuenta';

  @override
  String get welcomeAlreadyMember => '¿Ya tienes cuenta? ';

  @override
  String get welcomeSignIn => 'Iniciar sesión';

  @override
  String get welcomeFooter => '18+  ·  A tu ritmo. Tú decides.';

  @override
  String get authBackTooltip => 'Volver al inicio';

  @override
  String get authHeadline => 'Qué bueno verte.';

  @override
  String get authSubtitle =>
      'Usa tu nombre de usuario y contraseña para continuar';

  @override
  String get authWelcomeBack => 'Hola de nuevo';

  @override
  String get authNextHello => 'Tu próximo hola te está esperando.';

  @override
  String get authUsernameHint => 'nombre de usuario';

  @override
  String get authPasswordHint => 'Contraseña';

  @override
  String get authShowPassword => 'Mostrar contraseña';

  @override
  String get authHidePassword => 'Ocultar contraseña';

  @override
  String get authCantSignIn => '¿No puedes iniciar sesión?';

  @override
  String get authSignIn => 'Iniciar sesión';

  @override
  String get authPrivacyNote =>
      'Tu contraseña solo se envía al iniciar sesión y nunca se guarda en la app.';

  @override
  String get authEnterUsername => 'Escribe tu nombre de usuario.';

  @override
  String get authEnterPassword => 'Escribe tu contraseña.';

  @override
  String get commonYes => 'Sí';

  @override
  String get commonNo => 'No';

  @override
  String get planVenueCoffee => 'Un café';

  @override
  String get planVenueMeal => 'Una comida';

  @override
  String get planVenueDrinks => 'Unas copas';

  @override
  String get planVenueWalk => 'Un paseo';

  @override
  String get planVenueActivity => 'Una actividad';

  @override
  String get planVenueEvent => 'Un evento';

  @override
  String get planVenueVideoCall => 'Videollamada';

  @override
  String get planVenueOther => 'Otra cosa';

  @override
  String planProposeTitle(String name) {
    return 'Planea una cita con $name';
  }

  @override
  String get planProposeSubtitle =>
      'Shape a first hello together. Contact sharing starts off.';

  @override
  String get planProposeButton => 'Proponer';

  @override
  String planHeadlineProposed(String name) {
    return '$name te ha propuesto una cita';
  }

  @override
  String planHeadlineWaiting(String name) {
    return 'Esperando a $name';
  }

  @override
  String get planHeadlineUpcoming => 'Cita confirmada';

  @override
  String get planHeadlineCheckin => '¿Cómo ha ido?';

  @override
  String get planHeadlineDebrief => '¿Qué tal fue?';

  @override
  String get planHeadlineDebriefComplete => 'Balance completado';

  @override
  String planHeadlineWaitingDebrief(String name) {
    return 'Esperando el balance de $name';
  }

  @override
  String get planHeadlineCheckedInSafe => 'Has avisado de que estás bien';

  @override
  String get planHeadlineFriendsAlerted => 'Your request for help is recorded';

  @override
  String get planHeadlineDefault => 'Plan';

  @override
  String get planStatusProposed => 'Propuesta';

  @override
  String get planStatusConfirmed => 'Confirmada';

  @override
  String get planDebriefButton => 'Balance de diez segundos';

  @override
  String get planDecline => 'Rechazar';

  @override
  String get planAccept => 'Aceptar';

  @override
  String get planFriendsKnowAccepted =>
      'Choose trusted contacts to share your updates.';

  @override
  String get planFriendsKnowProposed =>
      'Contact sharing is optional for each plan.';

  @override
  String get planCancel => 'Cancelar la cita';

  @override
  String get planNeedHelp => 'Necesito ayuda';

  @override
  String get planImSafe => 'Estoy bien';

  @override
  String get planCancelDialogTitle => '¿Cancelar esta cita?';

  @override
  String planCancelDialogBody(String name) {
    return '$name y todas las personas con las que la compartiste recibirán un aviso.';
  }

  @override
  String get planKeepIt => 'Mantenerla';

  @override
  String get planProposeIntro =>
      'This starts between you and your date. After proposing, choose trusted contacts if you want to share plan and check-in updates.';

  @override
  String get planSectionWhen => 'Cuándo';

  @override
  String get planSectionWhat => 'Qué';

  @override
  String get planSectionGroups => 'Trusted contacts';

  @override
  String planDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String get planPlaceLabel => 'Lugar (opcional)';

  @override
  String get planPlaceHint => 'Un lugar público es lo mejor';

  @override
  String get planAreaLabel => 'Zona o barrio';

  @override
  String get planNoteLabel => 'Nota para tu match (opcional)';

  @override
  String get planFutureTimeError => 'Elige una hora en el futuro.';

  @override
  String get planProposeFailed => 'No se pudo proponer esta cita.';

  @override
  String get planSendButton => 'Enviar el plan';

  @override
  String get planAcceptTitle => '¿Aceptar la cita?';

  @override
  String get planAcceptIntro =>
      'Accept this plan with your date. Choose trusted contacts afterwards if you want to share your updates.';

  @override
  String get planAcceptButton => 'Accept plan';

  @override
  String debriefTitle(String name) {
    return '¿Qué tal fue con $name?';
  }

  @override
  String get debriefIntro =>
      'Tus respuestas son privadas. Cuando ambos confirmáis que la cita ocurrió, cuenta para tu insignia Shows Up.';

  @override
  String get debriefHappened => '¿La cita ocurrió?';

  @override
  String get debriefMeetAgain => '¿Volverías a quedar?';

  @override
  String get debriefFeltSafe => '¿Te sentiste a salvo?';

  @override
  String get debriefNoteLabel => '¿Algo más que añadir? (opcional)';

  @override
  String get debriefMissingHappened => 'Dinos si la cita ocurrió.';

  @override
  String get debriefSaveFailed => 'No se pudo guardar tu balance.';

  @override
  String get debriefSave => 'Guardar balance';

  @override
  String get debriefUnsafeTitle => 'Sentimos que no te hayas sentido a salvo';

  @override
  String debriefUnsafeBody(String name) {
    return 'Tu respuesta queda registrada para nuestro equipo de seguridad. ¿Quieres denunciar también a $name?';
  }

  @override
  String get debriefNotNow => 'Ahora no';

  @override
  String get debriefReport => 'Denunciar';

  @override
  String get plansTitle => 'Citas';

  @override
  String get plansTabMine => 'Mías';

  @override
  String get plansTabFriends => 'Amigos';

  @override
  String get plansEmptyMineTitle => 'Aún no hay citas';

  @override
  String get plansEmptyMineBody =>
      'Propose a date from a conversation. You choose whether to share plan and check-in updates with trusted contacts.';

  @override
  String plansWith(String name) {
    return 'Con $name';
  }

  @override
  String get plansNextDecide => 'Esperando tu respuesta';

  @override
  String plansNextAwait(String name) {
    return 'Esperando a $name';
  }

  @override
  String get plansNextUpcoming => 'Confirmed. Your time together is planned.';

  @override
  String get plansNextCheckin => 'Check in after your date';

  @override
  String get plansNextDebrief => 'Cuéntanos qué tal fue';

  @override
  String get plansNextCancelled => 'Cancelada';

  @override
  String get plansNextDone => 'Hecho';

  @override
  String get plansEmptyFriendsTitle => 'Nada compartido todavía';

  @override
  String get plansEmptyFriendsBody =>
      'Plans appear here when friends explicitly choose to share with you.';

  @override
  String get plansViaGroup => 'Shared with you';

  @override
  String get plansViaFriend => 'Trusted contact';

  @override
  String plansFriendNeedsHelp(String name) {
    return '$name ha pedido ayuda. Ponte en contacto ahora.';
  }

  @override
  String plansFriendMissedCheckin(String name) {
    return '$name todavía no ha avisado.';
  }

  @override
  String plansFriendCheckedInSafe(String name, String via) {
    return '$name ha avisado de que está bien · $via';
  }

  @override
  String plansFriendStatusLine(String via, String status) {
    return '$via · $status';
  }

  @override
  String get plansStatusWordProposed => 'propuesta';

  @override
  String get plansStatusWordConfirmed => 'confirmada';

  @override
  String get plansStatusWordCancelled => 'cancelada';

  @override
  String get plansStatusWordHappened => 'realizada';

  @override
  String get chatEmptyDefault =>
      'Saluda. Los mensajes aparecen aquí para todas las personas de esta conversación.';

  @override
  String get chatNotSentRetry =>
      'No se ha enviado. Toca el mensaje para reintentarlo.';

  @override
  String get chatRetrySend => 'Volver a enviar';

  @override
  String get chatCopyText => 'Copiar texto';

  @override
  String get chatDeleteMine => 'Eliminar mi mensaje';

  @override
  String get chatRemoveMessage => 'Quitar mensaje';

  @override
  String get chatReportMessage => 'Denunciar mensaje';

  @override
  String get chatThisMember => 'Este miembro';

  @override
  String get chatMember => 'Miembro';

  @override
  String get chatCopied => 'Copiado.';

  @override
  String get chatDeleteFailed =>
      'No se ha podido eliminar. Inténtalo de nuevo.';

  @override
  String get chatSubtitleFriends => 'Amigos';

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String get chatReconnecting =>
      'Reconectando. Los mensajes nuevos pueden tardar un poco.';

  @override
  String get chatUnavailable =>
      'Esta conversación no está disponible. Puede que ya no formes parte de ella.';

  @override
  String get chatTryAgain => 'Reintentar';

  @override
  String get chatStatusNotSent => 'No enviado · mantén pulsado para reintentar';

  @override
  String get chatStatusSending => 'Enviando…';

  @override
  String get chatMessageRemoved => 'Mensaje eliminado';

  @override
  String chatSemanticsYouAt(String time) {
    return 'Tú a las $time';
  }

  @override
  String chatSemanticsMemberAt(String name, String time) {
    return '$name a las $time';
  }

  @override
  String chatAboutMember(String name) {
    return 'Sobre $name';
  }

  @override
  String get chatComposerHint => 'Escribe un mensaje';

  @override
  String get chatMutedComposerHint => 'Ahora mismo no puedes escribir';

  @override
  String get chatSend => 'Enviar';

  @override
  String chatRoomMutedUntil(String when) {
    return 'Estás silenciado en esta sala hasta las $when. Puedes seguir leyendo.';
  }

  @override
  String get chatRoomMuted =>
      'Estás silenciado en esta sala. Puedes seguir leyendo.';

  @override
  String chatReadOnlyUntil(String when) {
    return 'Puedes leer esta conversación, pero no escribir hasta las $when.';
  }

  @override
  String get chatReadOnly =>
      'Puedes leer esta conversación, pero ahora mismo no puedes escribir.';

  @override
  String get chatMuteTooltip => 'Silenciar notificaciones';

  @override
  String get chatMutedTooltip => 'Notificaciones silenciadas';

  @override
  String get chatMuteSheetTitle => 'Silenciar notificaciones';

  @override
  String get chatMuteSheetBody =>
      'Los mensajes seguirán llegando aquí, solo que sin notificaciones.';

  @override
  String get chatMuteOneHour => 'Durante 1 hora';

  @override
  String get chatMuteEightHours => 'Durante 8 horas';

  @override
  String get chatMuteOneWeek => 'Durante 1 semana';

  @override
  String get chatMuteForever => 'Hasta que las vuelva a activar';

  @override
  String get chatUnmute => 'Volver a activar las notificaciones';

  @override
  String chatMutedUntilLabel(String when) {
    return 'Silenciadas hasta las $when';
  }

  @override
  String get chatMutedIndefinitely =>
      'Silenciadas hasta que vuelvas a activar las notificaciones.';

  @override
  String get chatMuteDone => 'Notificaciones silenciadas.';

  @override
  String get chatUnmuteDone => 'Las notificaciones vuelven a estar activadas.';

  @override
  String get chatMuteFailed =>
      'No se han podido cambiar las notificaciones. Inténtalo de nuevo.';

  @override
  String get roomsClosedSnack => 'Esta sala ha cerrado.';

  @override
  String get roomsChatNotOpen => 'El chat de esta sala aún no está abierto.';

  @override
  String get roomsJoinFailed =>
      'No se ha podido entrar en esta sala. Inténtalo de nuevo.';

  @override
  String get roomsStartRoom => 'Abrir una sala';

  @override
  String get roomsEyebrow => 'CHAT EN VIVO';

  @override
  String get roomsTitle => 'Salas';

  @override
  String get roomsSubtitle =>
      'Únete a una conversación. Si conectas con alguien, añádelo como amigo.';

  @override
  String get roomsSectionRooms => 'SALAS';

  @override
  String get roomsSectionYours => 'TUS SALAS';

  @override
  String get roomsYoursCaption =>
      'Salas en las que estás. Toca para seguir la conversación.';

  @override
  String get roomsSectionLive => 'EN VIVO AHORA';

  @override
  String get roomsLiveTitle => 'Donde la gente está hablando';

  @override
  String get roomsSectionBrowse => 'EXPLORAR';

  @override
  String get roomsBrowseTitle => 'Encuentra tu sala';

  @override
  String get roomsBrowseCaption =>
      'Siempre abiertas. Elige un tema, saluda y descubre con quién conectas.';

  @override
  String get roomsNoFriendsHere =>
      'Ahora mismo ninguno de tus amigos está en una de estas salas.';

  @override
  String get roomsNoRoomsInTopic => 'Todavía no hay salas sobre este tema.';

  @override
  String get roomsSectionComingUp => 'PRÓXIMAMENTE';

  @override
  String get roomsComingUpCaption =>
      'Salas que organizan los miembros. Únete pronto para guardar tu sitio.';

  @override
  String get roomsCategoryAll => 'Todas';

  @override
  String get roomsCategoryTalk => 'Charlas';

  @override
  String get roomsCategoryInterests => 'Intereses';

  @override
  String get roomsCategoryActive => 'De paseo';

  @override
  String get roomsCategoryCity => 'Tu ciudad';

  @override
  String get roomsFriendsHereChip => 'Amigos aquí';

  @override
  String get roomsQuiet => 'Ahora está tranquilo. Sé el primero en saludar.';

  @override
  String roomsPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: '1 persona',
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
    return '$people charlando en $rooms';
  }

  @override
  String roomsHereNow(int count) {
    return '$count aquí ahora';
  }

  @override
  String roomsInTheRoom(int count) {
    return '$count en la sala';
  }

  @override
  String roomsFriendsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amigos aquí',
      one: '1 amigo aquí',
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
  String get roomsActionFull => 'Llena';

  @override
  String get roomsActionJoin => 'Unirse';

  @override
  String roomsStartsAt(String time) {
    return 'Empieza a las $time';
  }

  @override
  String roomsStartsOn(String day, String time) {
    return 'Empieza el $day a las $time';
  }

  @override
  String get roomsStartNameTooShort =>
      'Ponle a la sala un nombre de al menos 3 letras.';

  @override
  String get roomsStartIntro =>
      'Tú la organizas: puedes avisar, silenciar o expulsar a personas y cerrarla cuando termines. Una sala cada vez.';

  @override
  String get roomsStartNameLabel => 'Nombre de la sala';

  @override
  String get roomsStartNameHint => 'Intercambio de libros del domingo';

  @override
  String get roomsStartAboutLabel => '¿De qué va? (opcional)';

  @override
  String get roomsStartTopic => 'Tema';

  @override
  String get roomsStartHowLong => 'Duración';

  @override
  String get roomsLength30Min => '30 min';

  @override
  String get roomsLength1Hour => '1 hora';

  @override
  String get roomsLength2Hours => '2 horas';

  @override
  String get roomsStartNow => 'Empezar ya';

  @override
  String get roomsRoleHost => 'Anfitrión';

  @override
  String get roomsRoleModerator => 'Moderador';

  @override
  String get roomsRoomFallback => 'Sala';

  @override
  String roomsChatEmpty(String room) {
    return 'Ya estás dentro. Saluda: todo el mundo en $room ve lo que escribes aquí.';
  }

  @override
  String get roomsPeopleTooltip => 'Personas en esta sala';

  @override
  String roomsLeaveTitle(String room) {
    return '¿Salir de $room?';
  }

  @override
  String get roomsLeaveBody =>
      'Dejarás de ver los mensajes de esta sala. Puedes volver cuando quieras mientras esté abierta.';

  @override
  String get roomsLeaveAction => 'Salir de la sala';

  @override
  String get roomsLeaveFailed => 'No se ha podido salir. Inténtalo de nuevo.';

  @override
  String roomsCloseTitle(String room) {
    return '¿Cerrar $room?';
  }

  @override
  String get roomsCloseBody =>
      'El chat termina para todas las personas de la sala. No se puede deshacer.';

  @override
  String get roomsCloseAction => 'Cerrar la sala';

  @override
  String get roomsCloseFailed => 'No se ha podido cerrar. Inténtalo de nuevo.';

  @override
  String get roomsMenuTooltip => 'Opciones de la sala';

  @override
  String get roomsMenuPeople => 'Quién está aquí';

  @override
  String get roomsMenuModerate => 'Moderar';

  @override
  String roomsModerateTitle(String room) {
    return 'Moderar $room';
  }

  @override
  String get roomsModerateIntro =>
      'Toca a alguien para avisarle, silenciarle o expulsarle. Quien esté silenciado puede seguir leyendo; quien sea expulsado podrá volver cuando termine la sesión.';

  @override
  String get roomsPeopleIntro =>
      '¿Has conectado con alguien? Añádelo como amigo para seguir hablando después de la sala.';

  @override
  String get roomsMembersLoadFailed =>
      'No se ha podido cargar quién está aquí.';

  @override
  String get roomsStatusFriend => 'Amigo';

  @override
  String get roomsStatusHereNow => 'Aquí ahora';

  @override
  String get roomsStatusInRoom => 'En la sala';

  @override
  String get roomsStatusGone => 'Ya no está en la sala';

  @override
  String roomsStatusMutedUntil(String time) {
    return 'Silenciado hasta las $time';
  }

  @override
  String roomsYouSuffix(String name) {
    return '$name (tú)';
  }

  @override
  String roomsRemoveTitle(String name) {
    return '¿Expulsar a $name de la sala?';
  }

  @override
  String roomsRemoveBodyAlwaysOn(String name) {
    return '$name sale del chat ahora y podrá volver dentro de 24 horas.';
  }

  @override
  String roomsRemoveBodyHosted(String name) {
    return '$name sale del chat ahora y no podrá volver hasta que termine esta sala.';
  }

  @override
  String roomsWarnTitle(String name) {
    return '¿Avisar a $name?';
  }

  @override
  String roomsWarnBody(String name) {
    return '$name recibe un recordatorio privado para mantener la conversación amable y en el tema.';
  }

  @override
  String get roomsRemoveAction => 'Expulsar';

  @override
  String get roomsWarnAction => 'Enviar aviso';

  @override
  String roomsRemovedDone(String name) {
    return '$name ha sido expulsado de la sala.';
  }

  @override
  String roomsWarnedDone(String name) {
    return 'Aviso enviado a $name.';
  }

  @override
  String get roomsModerationFailed => 'No ha funcionado. Inténtalo otra vez.';

  @override
  String roomsBlockedDone(String name) {
    return 'Has bloqueado a $name. Aquí no veréis los mensajes del otro.';
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
  String get roomsRemoveFromRoom => 'Expulsar de la sala';

  @override
  String get roomsMute => 'Silenciar';

  @override
  String get roomsUnmute => 'Quitar silencio';

  @override
  String roomsMuteSheetTitle(String name) {
    return '¿Silenciar a $name?';
  }

  @override
  String roomsMuteSheetBody(String name) {
    return '$name puede seguir leyendo el chat, pero no escribir hasta que termine el silencio. Recibirá un aviso privado.';
  }

  @override
  String get roomsMuteTenMinutes => 'Durante 10 minutos';

  @override
  String get roomsMuteOneHour => 'Durante 1 hora';

  @override
  String get roomsMuteUntilEnd => 'Hasta que termine la sala';

  @override
  String get roomsMuteOneDay => 'Durante 24 horas';

  @override
  String roomsMutedDone(String name) {
    return '$name está silenciado.';
  }

  @override
  String roomsUnmutedDone(String name) {
    return '$name puede volver a escribir.';
  }
}
