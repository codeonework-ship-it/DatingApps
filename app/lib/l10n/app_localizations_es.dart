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

  @override
  String get richFormattingToolbar => 'Formato';

  @override
  String get richUndo => 'Deshacer';

  @override
  String get richRedo => 'Rehacer';

  @override
  String get richBold => 'Negrita';

  @override
  String get richItalic => 'Cursiva';

  @override
  String get richUnderline => 'Subrayado';

  @override
  String get richStrikethrough => 'Tachado';

  @override
  String get richHighlight => 'Resaltar';

  @override
  String get richLink => 'Enlace';

  @override
  String get richTextStyleMenu => 'Estilo de texto';

  @override
  String get richParagraph => 'Párrafo';

  @override
  String get richHeading => 'Título';

  @override
  String get richSubheading => 'Subtítulo';

  @override
  String get richQuote => 'Cita';

  @override
  String get richCallout => 'Nota destacada';

  @override
  String get richBulletList => 'Lista con viñetas';

  @override
  String get richNumberedList => 'Lista numerada';

  @override
  String get richDivider => 'Separador';

  @override
  String get richAlignMenu => 'Alineación';

  @override
  String get richAlignStart => 'Alinear al inicio';

  @override
  String get richAlignCenter => 'Centrar';

  @override
  String get richAlignEnd => 'Alinear al final';

  @override
  String get richClearFormatting => 'Borrar formato';

  @override
  String get richWritingStyle => 'Estilo de escritura';

  @override
  String get richStyleClassic => 'Clásico';

  @override
  String get richStyleClassicHint => 'Serif elegante, como una página impresa';

  @override
  String get richStyleModern => 'Moderno';

  @override
  String get richStyleModernHint => 'Limpio y fácil de leer';

  @override
  String get richStyleJournal => 'Diario';

  @override
  String get richStyleJournalHint =>
      'Cursiva cálida, como una entrada de diario';

  @override
  String get richStyleTypewriter => 'Máquina de escribir';

  @override
  String get richStyleTypewriterHint => 'Letras cuadradas con más espacio';

  @override
  String get richStylePoetic => 'Poético';

  @override
  String get richStylePoeticHint => 'Líneas centradas y con aire';

  @override
  String richWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palabras',
      one: '1 palabra',
    );
    return '$_temp0';
  }

  @override
  String get richAlignmentNote =>
      'La alineación y el espaciado se ven en la vista previa y para quien lee.';

  @override
  String get richLinkTitle => 'Añadir un enlace';

  @override
  String get richLinkField => 'Dirección web';

  @override
  String get richLinkInvalid => 'Usa una dirección https:// completa.';

  @override
  String get richLinkApply => 'Añadir enlace';

  @override
  String get richLinkRemove => 'Quitar enlace';

  @override
  String get richLinkNeedsSelection =>
      'Primero selecciona las palabras que quieres enlazar.';

  @override
  String get richCancel => 'Cancelar';

  @override
  String get richOpenLinkTitle => '¿Abrir este enlace?';

  @override
  String richOpenLinkBody(String host) {
    return '$host se abrirá fuera de Connect. Abre solo enlaces de confianza.';
  }

  @override
  String get richOpenLink => 'Abrir enlace';

  @override
  String get supportCentreEyebrow => 'AYUDA Y SOPORTE';

  @override
  String get supportCentreTitle => '¿Cómo podemos ayudarte?';

  @override
  String get supportCentreSubtitle =>
      'Encuentra una respuesta rápida o pregunta a nuestro equipo. Cada solicitud y respuesta queda en una conversación privada.';

  @override
  String get supportContactSection => 'CONTÁCTANOS';

  @override
  String get supportContactTitle => 'Contactar con soporte';

  @override
  String get supportContactSubtitle =>
      'Cuéntanos qué pasó. Te respondemos aquí y te avisamos.';

  @override
  String get supportMyTicketsTitle => 'Mis solicitudes';

  @override
  String get supportMyTicketsSubtitle =>
      'Sigue tus solicitudes y nuestras respuestas';

  @override
  String supportOpenRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count solicitudes abiertas',
      one: '1 solicitud abierta',
    );
    return '$_temp0';
  }

  @override
  String supportUnreadReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respuestas nuevas',
      one: '1 respuesta nueva',
    );
    return '$_temp0';
  }

  @override
  String get supportQuickAnswersSection => 'RESPUESTAS RÁPIDAS';

  @override
  String get supportFaqLoginTitle => 'Inicio de sesión';

  @override
  String get supportFaqLoginBody =>
      'Inicia sesión con tu nombre de usuario único y tu contraseña.';

  @override
  String get supportFaqVerificationTitle => 'Verificación';

  @override
  String get supportFaqVerificationBody =>
      'La verificación de identidad es opcional mientras el proveedor esté en pausa.';

  @override
  String get supportFaqAbuseTitle => 'Abuso';

  @override
  String get supportFaqAbuseBody =>
      'Usa Denunciar en un perfil o conversación para una revisión de seguridad más rápida.';

  @override
  String get supportFaqBillingTitle => 'Facturación';

  @override
  String get supportFaqBillingBody =>
      'Incluye la referencia de la transacción, nunca los datos de tu tarjeta.';

  @override
  String get supportEmergencyNote =>
      'Si alguien está en peligro inmediato, contacta con los servicios de emergencia locales. Las solicitudes de soporte no sustituyen la ayuda de emergencia.';

  @override
  String get supportUnavailableTitle =>
      'Las solicitudes de soporte no están disponibles ahora mismo';

  @override
  String get supportUnavailableBody =>
      'Las respuestas de esta página siguen disponibles. Para algo urgente, escribe a support@connect.example.';

  @override
  String get supportBackToHelp => 'Volver a Ayuda y soporte';

  @override
  String get supportFormEyebrow => 'NUEVA SOLICITUD';

  @override
  String get supportFormTitle => 'Contactar con soporte';

  @override
  String get supportFormSubtitle =>
      'Danos suficientes detalles para actuar. Nunca incluyas una contraseña, código de recuperación, número de tarjeta ni documento de identidad.';

  @override
  String get supportFormCategorySection => 'TEMA';

  @override
  String get supportFormCategoryLabel => '¿Con qué necesitas ayuda?';

  @override
  String get supportCategoryAccountLogin => 'Cuenta e inicio de sesión';

  @override
  String get supportCategoryVerification => 'Verificación';

  @override
  String get supportCategoryPaymentsBilling => 'Pagos y facturación';

  @override
  String get supportCategorySafetyHarassment => 'Seguridad y acoso';

  @override
  String get supportCategoryMatchesChat => 'Matches y chat';

  @override
  String get supportCategoryTechnical => 'Problema técnico o error';

  @override
  String get supportCategoryFeatureRequest => 'Sugerencia de función';

  @override
  String get supportCategoryPrivacyData => 'Privacidad y datos';

  @override
  String get supportCategoryOther => 'Otro';

  @override
  String get supportSafetyNote =>
      'Si tú u otra persona estáis en peligro inmediato, usa SOS en la app o llama a los servicios de emergencia locales. Las solicitudes de seguridad tienen prioridad, pero una solicitud no es una línea de emergencia.';

  @override
  String get supportOpenSos => 'Abrir SOS';

  @override
  String get supportFormDetailsSection => 'DETALLES';

  @override
  String get supportFormSubjectLabel => 'Asunto';

  @override
  String get supportFormSubjectHint => 'Describe brevemente el problema';

  @override
  String get supportFormDescriptionLabel => '¿Qué pasó?';

  @override
  String get supportFormDescriptionHint =>
      'Qué hiciste, qué esperabas y qué ocurrió en su lugar';

  @override
  String get supportFormScreenshotsSection => 'CAPTURAS DE PANTALLA';

  @override
  String supportFormScreenshotsCaption(int max) {
    return 'Opcional. Hasta $max imágenes.';
  }

  @override
  String get supportAddScreenshot => 'Añadir captura';

  @override
  String supportRemoveAttachment(String name) {
    return 'Quitar $name';
  }

  @override
  String get supportAttachmentUploading => 'Subiendo';

  @override
  String get supportRetryUpload => 'Reintentar subida';

  @override
  String supportFormDeviceNote(String version) {
    return 'Incluiremos la versión de la app ($version), la plataforma, la versión del sistema y el idioma para ayudarnos a resolverlo.';
  }

  @override
  String get supportSubmit => 'Enviar solicitud';

  @override
  String get supportErrorCategoryRequired => 'Elige un tema.';

  @override
  String supportErrorSubjectLength(int min, int max) {
    return 'El asunto debe tener entre $min y $max caracteres.';
  }

  @override
  String get supportErrorDescriptionRequired => 'Describe qué pasó.';

  @override
  String supportErrorDescriptionTooLong(int max) {
    return 'Usa menos de $max caracteres.';
  }

  @override
  String get supportErrorUploadsPending =>
      'Espera a que terminen de subirse las capturas o quita las que fallaron.';

  @override
  String supportCreatedSnack(String reference) {
    return 'Solicitud $reference enviada. Te responderemos aquí.';
  }

  @override
  String supportDuplicateSnack(String reference) {
    return 'Ya enviaste esta solicitud, así que la abrimos: $reference.';
  }

  @override
  String supportErrorRateLimited(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Has enviado varias solicitudes en poco tiempo. Inténtalo de nuevo en $minutes minutos.',
      one:
          'Has enviado varias solicitudes en poco tiempo. Inténtalo de nuevo en 1 minuto.',
    );
    return '$_temp0';
  }

  @override
  String get supportErrorRateLimitedGeneric =>
      'Has enviado varias solicitudes en poco tiempo. Inténtalo de nuevo más tarde.';

  @override
  String get supportErrorTooManyOpen =>
      'Ya tienes 10 solicitudes abiertas. Cierra alguna que ya no necesites o espera nuestras respuestas.';

  @override
  String get supportErrorTicketClosed =>
      'Esta solicitud está cerrada y ya no se puede reabrir. Inicia una nueva solicitud.';

  @override
  String get supportErrorReopenWindowPassed =>
      'Ha pasado el plazo para reabrir esta solicitud. Inicia una nueva solicitud.';

  @override
  String get supportErrorAlreadyRated => 'Ya has valorado esta solicitud.';

  @override
  String get supportErrorNotResolved =>
      'Podrás valorar la solicitud cuando esté resuelta.';

  @override
  String get supportErrorAttachmentType =>
      'Solo se pueden adjuntar imágenes JPEG o PNG y archivos PDF.';

  @override
  String get supportErrorAttachmentTooLarge =>
      'El archivo es demasiado grande. Las imágenes pueden ocupar hasta 8 MB.';

  @override
  String get supportErrorOffline =>
      'No podemos conectar con Connect ahora mismo. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get supportErrorNotFound => 'No hemos encontrado esta solicitud.';

  @override
  String get supportErrorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get supportTryAgain => 'Reintentar';

  @override
  String get supportTicketsEyebrow => 'SOPORTE';

  @override
  String get supportTicketsTitle => 'Mis solicitudes';

  @override
  String get supportTicketsSubtitle => 'Tus solicitudes y nuestras respuestas.';

  @override
  String get supportTicketsActiveSection => 'ACTIVAS';

  @override
  String get supportTicketsClosedSection => 'RESUELTAS Y CERRADAS';

  @override
  String get supportTicketsEmptyTitle => 'Aún no hay solicitudes';

  @override
  String get supportTicketsEmptyBody =>
      'Cuando contactes con soporte, tu solicitud y nuestras respuestas aparecerán aquí.';

  @override
  String get supportTicketsLoadErrorTitle =>
      'No se pudieron cargar tus solicitudes';

  @override
  String supportTicketUpdated(String when) {
    return 'Actualizada $when';
  }

  @override
  String get supportNewTicket => 'Nueva solicitud';

  @override
  String get supportStatusOpen => 'Abierta';

  @override
  String get supportStatusWaitingForYou => 'Esperando tu respuesta';

  @override
  String get supportStatusOnHold => 'En pausa';

  @override
  String get supportStatusResolved => 'Resuelta';

  @override
  String get supportStatusClosed => 'Cerrada';

  @override
  String supportStatusSemantics(String status) {
    return 'Estado: $status';
  }

  @override
  String get supportThreadAgentName => 'Soporte de Connect';

  @override
  String get supportThreadYou => 'Tú';

  @override
  String supportTicketMeta(String category, String date) {
    return '$category · Abierta el $date';
  }

  @override
  String get supportBannerOpen =>
      'Tenemos tu solicitud. Nuestro equipo te responderá aquí y te avisará.';

  @override
  String get supportBannerWaiting =>
      'Soporte ha respondido y espera tu respuesta.';

  @override
  String get supportBannerOnHold =>
      'Tu solicitud está en pausa mientras la revisamos. Te informaremos aquí.';

  @override
  String get supportBannerResolved =>
      'Marcada como resuelta. Responde para reabrirla; si no, se cerrará automáticamente en 7 días.';

  @override
  String supportBannerClosedUntil(String date) {
    return 'Esta solicitud está cerrada. Puedes reabrirla hasta el $date.';
  }

  @override
  String get supportBannerClosed => 'Esta solicitud está cerrada.';

  @override
  String supportBannerMerged(String reference) {
    return 'Esta solicitud se ha unido a $reference. La conversación continúa allí.';
  }

  @override
  String get supportReplyHint => 'Escribe una respuesta';

  @override
  String get supportReplyDisabledHint =>
      'Ya no se puede responder a esta solicitud';

  @override
  String get supportSendReply => 'Enviar respuesta';

  @override
  String get supportAttachScreenshot => 'Adjuntar captura';

  @override
  String get supportCloseTicket => 'Cerrar solicitud';

  @override
  String get supportCloseConfirmTitle => '¿Cerrar esta solicitud?';

  @override
  String get supportCloseConfirmBody =>
      'Ciérrala si tu problema está resuelto. Podrás reabrirla durante 14 días.';

  @override
  String get supportCancel => 'Cancelar';

  @override
  String get supportClosedSnack => 'Solicitud cerrada.';

  @override
  String get supportReopen => 'Reabrir solicitud';

  @override
  String get supportReopenedSnack => 'Solicitud reabierta.';

  @override
  String get supportRateTitle => '¿Qué tal lo hicimos?';

  @override
  String get supportRateCaption => 'Valora tu experiencia con esta solicitud.';

  @override
  String supportRateStar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrellas',
      one: '1 estrella',
    );
    return '$_temp0';
  }

  @override
  String get supportRateCommentLabel => '¿Algo que añadir? (opcional)';

  @override
  String get supportRateSubmit => 'Enviar valoración';

  @override
  String get supportRatedTitle => 'Gracias por tu opinión';

  @override
  String supportRatedValue(int rating) {
    return 'Le diste $rating de 5.';
  }

  @override
  String get supportRatingSnack => 'Gracias por valorar tu experiencia.';

  @override
  String supportAttachmentImage(String name) {
    return 'Captura $name';
  }

  @override
  String get supportAttachmentLoadFailed => 'No se pudo cargar el adjunto';

  @override
  String get supportThreadLoadErrorTitle => 'No se pudo cargar esta solicitud';

  @override
  String get chemistryCardEntry => '¿Un poco de química?';

  @override
  String get memberProfileIntroducing => 'Te presentamos';

  @override
  String get memberProfileStarring => 'Protagonista';

  @override
  String get memberProfileVerified => 'Verificado';

  @override
  String memberProfilePhotoLabel(String name, int index, int count) {
    return '$name, foto $index de $count';
  }

  @override
  String get memberProfileNoPhoto => 'Aún no hay foto';

  @override
  String get memberProfileViewPhotoHint => 'ver en pantalla completa';

  @override
  String get memberProfileCloseGallery => 'Cerrar fotos';

  @override
  String get memberProfilePhotos => 'Fotos';

  @override
  String memberProfileMorePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos más',
      one: '1 foto más',
    );
    return '$_temp0';
  }

  @override
  String get memberProfileSceneAbout => 'Sobre mí';

  @override
  String get memberProfileSceneStories => 'Historias';

  @override
  String get memberProfileSceneStoriesTitle => 'Un poco más de mí';

  @override
  String get memberProfileSceneInterests => 'Intereses';

  @override
  String get memberProfileSceneBasics => 'Lo básico';

  @override
  String get memberProfileSceneLifestyle => 'Estilo de vida';

  @override
  String get memberProfileSceneTrust => 'Confianza';

  @override
  String get memberProfileReadMore => 'Leer más';

  @override
  String get memberProfileReadLess => 'Leer menos';

  @override
  String get memberProfileHobbies => 'Aficiones';

  @override
  String get memberProfileActivities => 'Actividades';

  @override
  String get memberProfileSongs => 'En bucle';

  @override
  String get memberProfileBooks => 'Libros y novelas';

  @override
  String get memberProfileLookingFor => 'Busca';

  @override
  String get memberProfileLanguages => 'Idiomas';

  @override
  String get memberProfileDealBreakers => 'Innegociables';

  @override
  String get memberProfileInCommon => 'En común';

  @override
  String get memberProfileFactHeight => 'Altura';

  @override
  String memberProfileHeightCm(int cm) {
    return '$cm cm';
  }

  @override
  String get memberProfileFactWork => 'Trabajo';

  @override
  String get memberProfileFactEducation => 'Estudios';

  @override
  String get memberProfileFactLivesIn => 'Vive en';

  @override
  String get memberProfileFactMotherTongue => 'Lengua materna';

  @override
  String get memberProfileFactReligion => 'Religión';

  @override
  String get memberProfileFactPersonality => 'Personalidad';

  @override
  String get memberProfileFactRelationship => 'Situación sentimental';

  @override
  String get memberProfileFactInstagram => 'Instagram';

  @override
  String get memberProfileFactDrinking => 'Alcohol';

  @override
  String get memberProfileFactSmoking => 'Tabaco';

  @override
  String get memberProfileFactWorkout => 'Ejercicio';

  @override
  String get memberProfileFactDiet => 'Dieta';

  @override
  String get memberProfileFactDietType => 'Tipo de dieta';

  @override
  String get memberProfileFactSleep => 'Sueño';

  @override
  String get memberProfileFactTravel => 'Viajes';

  @override
  String get memberProfileFactPets => 'Mascotas';

  @override
  String get memberProfileFactPolitics => 'Política';

  @override
  String get memberProfileFactOpenToCasual => 'Abierto a algo casual';

  @override
  String get memberProfileFactPartyLover => 'Le gustan las fiestas';

  @override
  String get memberProfileVerifiedTitle => 'Perfil verificado';

  @override
  String get memberProfileVerifiedBody =>
      'Verificación de identidad completada.';

  @override
  String get memberProfileVouchesTitle => 'Avalado por amigos';

  @override
  String get memberProfileSpotlight => 'Destacado';

  @override
  String get memberProfileFreeWhenYouAre => 'Libre cuando tú lo estás';

  @override
  String get memberProfileMessage => 'Mensaje';

  @override
  String get memberProfileLove => 'Me encanta';

  @override
  String get memberProfileReport => 'Denunciar';

  @override
  String get memberProfileOwnerTitle => 'Así te ven';

  @override
  String get memberProfileOwnerCaption =>
      'Los miembros ven tu perfil exactamente así.';

  @override
  String memberProfileCompleteness(int percent) {
    return 'Perfil completo al $percent %';
  }

  @override
  String get memberProfileCompletenessHint =>
      'Añade fotos, historias y detalles para destacar.';

  @override
  String get memberProfileCompletenessDone => 'Tu perfil está completo.';

  @override
  String get memberProfileToolEdit => 'Editar perfil';

  @override
  String get memberProfileToolPhotos => 'Editar fotos';

  @override
  String get memberProfileToolStories => 'Tus historias';

  @override
  String get memberProfileToolViewers => 'Quién te ha visto';

  @override
  String get memberProfileBehindTheScenes => 'Entre bastidores';

  @override
  String get memberProfileOnlyYou => 'Solo tú puedes verlo.';

  @override
  String get memberProfileMine => 'Mi perfil';

  @override
  String get profileShowcaseLabel => 'Escritos y momentos';

  @override
  String get profileShowcaseTitleOther => 'En sus propias palabras';

  @override
  String get profileShowcaseTitleSelf => 'Tus escritos y fotos públicos';

  @override
  String get profileShowcaseChapters => 'Capítulos';

  @override
  String get profileShowcasePhotos => 'Fotos del muro';

  @override
  String get profileShowcaseReadAll => 'Leer todos sus capítulos';

  @override
  String get profileShowcaseHiddenTitle => 'Solo tú puedes ver esto';

  @override
  String get profileShowcaseHiddenBody =>
      'Tus capítulos públicos y fotos del muro están ocultos en tu perfil. Actívalo para que los miembros los vean aquí.';

  @override
  String get profileShowcaseShownBody =>
      'Los miembros pueden verlos en tu perfil. Solo aparecen los capítulos compartidos con la comunidad y las fotos del muro.';

  @override
  String get profileShowcaseSwitch => 'Mostrar en mi perfil';

  @override
  String get profileShowcaseSaveFailed => 'No se pudo guardar tu elección.';
}
