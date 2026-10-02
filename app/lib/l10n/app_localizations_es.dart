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
      'De día, marfil cálido y verde bosque. De noche, menta suave y bosque profundo.';

  @override
  String get settingsLooksClassicLabel => 'Hoy';

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
      'Dad forma juntos a un primer hola. Compartir con contactos empieza desactivado.';

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
  String get planHeadlineFriendsAlerted =>
      'Tu petición de ayuda está registrada';

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
      'Elige contactos de confianza para compartir tus novedades.';

  @override
  String get planFriendsKnowProposed =>
      'Compartir con contactos es opcional en cada plan.';

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
      'Esto queda entre tú y tu cita. Después de proponerlo, elige contactos de confianza si quieres compartir novedades del plan y del check-in.';

  @override
  String get planSectionWhen => 'Cuándo';

  @override
  String get planSectionWhat => 'Qué';

  @override
  String get planSectionGroups => 'Contactos de confianza';

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
      'Acepta este plan con tu cita. Después, elige contactos de confianza si quieres compartir tus novedades.';

  @override
  String get planAcceptButton => 'Aceptar plan';

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
      'Propón una cita desde una conversación. Tú eliges si compartes las novedades del plan y del check-in con contactos de confianza.';

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
  String get plansNextUpcoming =>
      'Confirmado. Vuestro tiempo juntos está planeado.';

  @override
  String get plansNextCheckin => 'Haz check-in después de tu cita';

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
      'Los planes aparecen aquí cuando tus amigos deciden compartirlos contigo.';

  @override
  String get plansViaGroup => 'Compartido contigo';

  @override
  String get plansViaFriend => 'Contacto de confianza';

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

  @override
  String get callsHistoryTitle => 'Historial de llamadas';

  @override
  String get callsHistoryEmpty => 'Aún no hay llamadas.';

  @override
  String callsHistoryMatch(String id) {
    return 'Match $id';
  }

  @override
  String get callsJoinLiveRoom => 'Entrar en la sala en directo';

  @override
  String get callsActiveSession => 'Llamada en curso';

  @override
  String callsEndedWithDuration(String duration) {
    return 'Finalizada · $duration';
  }

  @override
  String get callsSessionTitle => 'Llamada';

  @override
  String get callsStarting => 'Iniciando sesión segura…';

  @override
  String get callsSessionActive => 'Llamada activa';

  @override
  String get callsSessionUnavailable => 'Llamada no disponible';

  @override
  String get callsLiveRoomNote =>
      'La sala en directo se abre en una ventana segura del proveedor. Durante la llamada, usa allí los controles de micrófono, cámara y salida.';

  @override
  String get callsEnd => 'Colgar';

  @override
  String get callsErrorSignInHistory =>
      'Inicia sesión para ver el historial de llamadas.';

  @override
  String get callsErrorSignInStart =>
      'Inicia sesión antes de empezar una llamada.';

  @override
  String get callsErrorPermissions =>
      'Las llamadas necesitan permiso para la cámara y el micrófono.';

  @override
  String get callsErrorLoadHistory =>
      'No se pudo cargar el historial de llamadas.';

  @override
  String get callsErrorStart => 'No se pudo iniciar la llamada.';

  @override
  String get callsErrorEnd => 'No se pudo finalizar la llamada.';

  @override
  String get callsErrorNotConfigured =>
      'Las salas de llamada en directo no están configuradas en este entorno.';

  @override
  String get callsErrorOpenRoom =>
      'No se pudo abrir la sala de llamada en directo.';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonCopy => 'Copiar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get commonReset => 'Restablecer';

  @override
  String get commonOpen => 'Abrir';

  @override
  String get commonView => 'Ver';

  @override
  String get commonDismiss => 'Descartar';

  @override
  String get commonAny => 'Cualquiera';

  @override
  String get commonSomethingWentWrong => 'Algo salió mal';

  @override
  String get commonSomethingWentWrongTryAgain =>
      'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get commonTryAgainTitle => 'Intentar de nuevo';

  @override
  String get commonNothingHereYet => 'Aún no hay nada';

  @override
  String commonLoadingLabel(String label) {
    return '$label, cargando';
  }

  @override
  String commonDistanceKm(int distance) {
    return '$distance km';
  }

  @override
  String get navToday => 'Hoy';

  @override
  String get navOfflineBanner =>
      'Modo sin conexión: algunos datos pueden estar desactualizados.';

  @override
  String navWeakNetworkBanner(int mbps) {
    return 'Red débil detectada. Usa al menos $mbps Mbps para que la app funcione mejor.';
  }

  @override
  String get navIncomingCallTitle => 'Llamada entrante';

  @override
  String get navIncomingCallBody => 'Un match te está llamando.';

  @override
  String get navViewCallDetails => 'Ver detalles de la llamada';

  @override
  String get filterSheetTitle => 'Filtrar matches';

  @override
  String get filterAgeRange => 'Rango de edad';

  @override
  String get filterProfileLifestyle => 'Filtros de perfil y estilo de vida';

  @override
  String get filterCountry => 'País';

  @override
  String get filterState => 'Estado/región';

  @override
  String get filterCity => 'Ciudad';

  @override
  String get filterMotherTongue => 'Lengua materna';

  @override
  String get filterReligion => 'Religión';

  @override
  String get filterRelationshipStatus => 'Estado civil';

  @override
  String get filterSmoking => 'Tabaco';

  @override
  String get filterDrinking => 'Alcohol';

  @override
  String get filterPersonalityType => 'Tipo de personalidad';

  @override
  String get filterPartyLoverOnly => 'Solo fiesteros';

  @override
  String get filterHookupsOnly => 'Solo encuentros casuales';

  @override
  String get filterAdvancedBio => 'Filtros avanzados de biografía';

  @override
  String get filterAdvancedBioBody =>
      'Los libros, novelas, canciones, aficiones, ubicación y actividades se gestionan en Ajustes → Preferencias de citas.';

  @override
  String get filterOpenDatingPreferences => 'Abrir preferencias de citas';

  @override
  String get filterDistanceKm => 'Distancia (km)';

  @override
  String get filterVerifiedOnlyTitle => 'Solo verificados';

  @override
  String get filterVerifiedOnlyBody => 'Mostrar solo perfiles verificados';

  @override
  String get filterVerifiedOnlyChip => 'Solo verificados';

  @override
  String get filterPartyLoverChip => 'Fiestero';

  @override
  String get filterHookupChip => 'Solo casual';

  @override
  String get filterEnableTrust => 'Activar filtro por confianza';

  @override
  String filterMinimumTrustBadges(int count) {
    return 'Mínimo de insignias de confianza activas: $count';
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
      'true': ', solo verificados',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(trust, {
      'true': ', filtro de confianza activado',
      'other': ', filtro de confianza desactivado',
    });
    return 'Filtros guardados: $minAge-$maxAge años, $distance km$_temp0$_temp1';
  }

  @override
  String get optionNever => 'Nunca';

  @override
  String get optionOccasionally => 'Ocasionalmente';

  @override
  String get optionSocially => 'Socialmente';

  @override
  String get optionRegularly => 'Con frecuencia';

  @override
  String get optionSingle => 'Soltero/a';

  @override
  String get optionDivorced => 'Divorciado/a';

  @override
  String get optionWidowed => 'Viudo/a';

  @override
  String get optionSeparated => 'Separado/a';

  @override
  String get optionComplicated => 'Es complicado';

  @override
  String get optionIntrovert => 'Introvertido/a';

  @override
  String get optionAmbivert => 'Ambivertido/a';

  @override
  String get optionExtrovert => 'Extrovertido/a';

  @override
  String get optionHighSchool => 'Bachillerato';

  @override
  String get optionBachelors => 'Grado';

  @override
  String get optionMasters => 'Máster';

  @override
  String get optionPhd => 'Doctorado';

  @override
  String get optionOther => 'Otro';

  @override
  String get optionPreferNotToSay => 'Prefiero no decirlo';

  @override
  String get optionHindu => 'Hindú';

  @override
  String get optionMuslim => 'Musulmán/ana';

  @override
  String get optionChristian => 'Cristiano/a';

  @override
  String get optionSikh => 'Sij';

  @override
  String get optionBuddhist => 'Budista';

  @override
  String get optionJain => 'Jainista';

  @override
  String get optionJewish => 'Judío/a';

  @override
  String get optionSpiritual => 'Espiritual';

  @override
  String get optionAgnostic => 'Agnóstico/a';

  @override
  String get optionAtheist => 'Ateo/a';

  @override
  String get storiesNudgeTitle => 'Cuenta un poco más de tu historia';

  @override
  String get storiesNudgeBodyUnknown =>
      'Las historias cortas en tu perfil dan a los demás algo real de lo que hablar al saludarte.';

  @override
  String get storiesNudgeActionOpen => 'Abrir tus historias';

  @override
  String get storiesNudgeBodyEmpty =>
      'Añade una historia corta a tu perfil: una pequeña alegría, un fin de semana que merezca la pena contar. La gente las lee antes de saludar.';

  @override
  String get storiesNudgeActionFirst => 'Escribe tu primera historia';

  @override
  String get storiesNudgeCompleteTitle => 'Tu historia está completa';

  @override
  String get storiesNudgeCompleteBody =>
      'Las tres historias están en tu perfil. Renueva una cuando la vida te regale otra.';

  @override
  String get storiesNudgeActionEdit => 'Editar tus historias';

  @override
  String storiesNudgeSharedTitle(int count, int max) {
    return '$count de $max historias compartidas';
  }

  @override
  String get storiesNudgeBodyMore =>
      'Una historia más da a la gente otra forma de empezar una conversación.';

  @override
  String storiesNudgeBodyLatest(String prompt) {
    return 'La última: «$prompt». Una más da a la gente otra forma de empezar una conversación.';
  }

  @override
  String get storiesNudgeActionAdd => 'Añadir otra historia';

  @override
  String get storiesNudgeIdeas => 'Ideas para empezar';

  @override
  String storiesProgressSemantics(int count, int max) {
    return '$count de $max historias escritas';
  }

  @override
  String get storiesPromptLittleJoy =>
      'Algo pequeño para lo que siempre saco tiempo';

  @override
  String get storiesPromptWeekend =>
      'Un fin de semana que merece la pena contar';

  @override
  String get storiesPromptFirstHello => 'Un primer saludo que me encantaría';

  @override
  String get storiesPromptLearning =>
      'Algo que estoy aprendiendo, solo para mí';

  @override
  String get storiesPromptCare =>
      'Un pequeño gesto con el que demuestro que me importa';

  @override
  String get storiesScreenTitle => 'Un poco más de ti';

  @override
  String get storiesSignIn => 'Inicia sesión para editar tus historias.';

  @override
  String get storiesLoadFailed => 'No se han podido cargar tus historias.';

  @override
  String get storiesTryAgain => 'Reintentar';

  @override
  String get storiesIncomplete =>
      'Añade texto a cada historia y una descripción a cada foto, o elimina la historia sin terminar.';

  @override
  String get storiesPublished => 'Tus historias del perfil se han publicado.';

  @override
  String get storiesSavedPrivately =>
      'Guardado en privado. Tus historias están ocultas para otros miembros.';

  @override
  String get storiesSaveUnconfirmed =>
      'No pudimos confirmar el guardado. Tus cambios siguen aquí; recarga las historias guardadas para comprobarlo.';

  @override
  String get storiesHeadline => 'Deja que alguien conozca\nal tú de cada día.';

  @override
  String get storiesIntro =>
      'Un pequeño ritual, la historia detrás de una foto, un primer saludo que te gustaría. Comparte hasta tres momentos con tus propias palabras.';

  @override
  String get storiesOptionalNote =>
      'Opcional, sin puntuación ni obligación de completarlo. Evita datos de contacto o ubicaciones precisas que no quieras compartir.';

  @override
  String get storiesPublishSwitch => 'Mostrar estas historias en mi perfil';

  @override
  String get storiesPublishSwitchHint =>
      'Desactivado al principio. Visible para los miembros que cumplan los requisitos cuando tu perfil esté publicado y disponible. Puedes ocultarlas cuando quieras.';

  @override
  String get storiesBackToEditing => 'Volver a editar';

  @override
  String get storiesPreview => 'Vista previa de mis historias';

  @override
  String get storiesPreviewBanner => 'VISTA PREVIA · NO SE PUBLICA';

  @override
  String get storiesAdd => 'Añadir una historia';

  @override
  String get storiesReloadDiscard =>
      'Recargar historias guardadas · descartar cambios';

  @override
  String get storiesSaving => 'Guardando…';

  @override
  String get storiesPublishButton => 'Publicar historias';

  @override
  String get storiesSavePrivatelyButton => 'Guardar en privado';

  @override
  String get storiesPolicyNote =>
      'Las fotos proceden de tu galería de perfil aprobada. Las historias y fotos siguen sujetas a las denuncias de los miembros y a las políticas de seguridad.';

  @override
  String storiesMomentLabel(int number) {
    return 'MOMENTO $number';
  }

  @override
  String storiesRemoveTooltip(int number) {
    return 'Eliminar la historia $number';
  }

  @override
  String get storiesPromptLabel => 'Un punto de partida';

  @override
  String get storiesTextLabel => 'Con tus palabras';

  @override
  String get storiesTextHint => 'Un detalle real la hace tuya.';

  @override
  String get storiesTextRequired =>
      'Añade unas palabras o elimina esta historia.';

  @override
  String get storiesPhotoLabel => 'Una foto, si quieres';

  @override
  String get storiesWordsOnly => 'Solo texto';

  @override
  String storiesProfilePhoto(int number) {
    return 'Foto de perfil $number';
  }

  @override
  String get storiesPhotoDescriptionLabel => 'Describe esta foto';

  @override
  String get storiesPhotoDescriptionHelper =>
      'Ayuda a quienes usan lectores de pantalla.';

  @override
  String get storiesPhotoDescriptionRequired =>
      'Añade una breve descripción de la foto.';

  @override
  String get storiesPhotoSemantics => 'Foto de una historia del perfil';

  @override
  String get storiesSectionTitle => 'Un poco más de mí';

  @override
  String get storiesRetryLoad => 'Volver a cargar las historias';

  @override
  String get authErrorSessionExpired =>
      'Se ha cerrado tu sesión. Vuelve a iniciar sesión.';

  @override
  String get authErrorSignInFailed =>
      'No se pudo iniciar sesión. Inténtalo de nuevo.';

  @override
  String get authErrorCreateAccountFailed =>
      'No se pudo crear la cuenta. Inténtalo de nuevo.';

  @override
  String get authErrorCreateAccountGeneric => 'No se pudo crear la cuenta.';

  @override
  String get authErrorInvalidCredentials =>
      'Nombre de usuario o contraseña incorrectos.';

  @override
  String get authErrorUsernameFormat =>
      'El nombre de usuario debe tener entre 3 y 30 caracteres: letras, números, _ o .';

  @override
  String get authErrorPasswordFormat =>
      'La contraseña debe tener entre 8 y 72 bytes e incluir letras y números.';

  @override
  String get authWelcomeIntroducerLink => 'Solo vengo a presentar amigos';

  @override
  String get signupBackTooltip => 'Atrás';

  @override
  String get signupIntroducerTitle => 'Sé quien une a las personas.';

  @override
  String get signupIntroducerBody =>
      'Una cuenta solo para amistades. Sin perfil de citas, fotos ni swipes. Tu edad es privada; Connect es para adultos de 18 a 80 años.';

  @override
  String get signupTitle => 'Crea tu cuenta';

  @override
  String get signupSubtitle =>
      'Elige un nombre de usuario único y una contraseña segura';

  @override
  String get signupUsernameLabel => 'Nombre de usuario único';

  @override
  String get signupUsernameHint => 'tu_usuario';

  @override
  String get signupUsernameHelp =>
      'De 3 a 30 caracteres. Letras, números, guion bajo y punto.';

  @override
  String get signupPasswordLabel => 'Contraseña';

  @override
  String get signupPasswordHint => 'Al menos 8 caracteres';

  @override
  String get signupConfirmPasswordHint => 'Confirma la contraseña';

  @override
  String get signupNameLabel => 'Nombre completo';

  @override
  String get signupNameHint => 'Tu nombre';

  @override
  String get signupDobLabel => 'Fecha de nacimiento';

  @override
  String get signupDobPickerHelp => 'Selecciona tu fecha de nacimiento';

  @override
  String get signupDobPlaceholder => 'Seleccionar fecha';

  @override
  String get signupGenderLabel => 'Me identifico como';

  @override
  String get signupGenderMan => 'Hombre';

  @override
  String get signupGenderWoman => 'Mujer';

  @override
  String get signupGenderOther => 'Otro';

  @override
  String get signupCreateFriendAccount => 'Crear cuenta de amistad';

  @override
  String get signupAlreadyHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get signupErrorPasswordMismatch => 'Las contraseñas no coinciden.';

  @override
  String get signupErrorFullName => 'Escribe tu nombre completo.';

  @override
  String get signupErrorDobMissing => 'Selecciona tu fecha de nacimiento.';

  @override
  String get signupErrorUnderage => 'Debes tener al menos 18 años.';

  @override
  String get signupErrorAgeRange =>
      'Por ahora, Connect admite miembros de 18 a 80 años.';

  @override
  String get signupErrorGenderMissing => 'Elige cómo te identificas.';

  @override
  String get authRecoveryEnterUsername => 'Escribe tu nombre de usuario.';

  @override
  String get authRecoveryEnterCode => 'Escribe tu código de recuperación.';

  @override
  String get authRecoveryPasswordRule =>
      'Usa entre 8 y 72 caracteres con al menos una letra y un número.';

  @override
  String get authRecoveryResetDone =>
      'Tu contraseña se ha restablecido y se ha cerrado la sesión en todos los dispositivos. Inicia sesión con tu nueva contraseña.';

  @override
  String get authRecoveryAssistanceDone =>
      'Si este nombre de usuario pertenece a una cuenta de Connect, nuestro equipo de seguridad revisará la solicitud.';

  @override
  String get authRecoveryInvalidCode =>
      'Ese código de recuperación no es válido o ha caducado.';

  @override
  String get authRecoveryOffline =>
      'No se pudo conectar con Connect. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get authRecoverySendFailed =>
      'No se pudo enviar tu solicitud. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get authRecoveryBackToSignIn => 'Volver a iniciar sesión';

  @override
  String get authRecoveryHaveCode => 'Tengo mi código';

  @override
  String get authRecoveryLostCode => 'He perdido mi código';

  @override
  String get authRecoveryHaveCodeIntro =>
      'Usa el código de recuperación que guardaste al crear tu cuenta o uno emitido por nuestro equipo de seguridad.';

  @override
  String get authRecoveryLostCodeIntro =>
      'Dinos tu nombre de usuario. Confirmaremos tu identidad antes de emitir un código de recuperación. Nunca te pediremos la contraseña.';

  @override
  String get authRecoveryUsernameLabel => 'Nombre de usuario';

  @override
  String get authRecoveryCodeLabel => 'Código de recuperación';

  @override
  String get authRecoveryNewPasswordLabel => 'Nueva contraseña';

  @override
  String get authRecoveryMessageLabel =>
      'Cualquier dato que nos ayude (opcional)';

  @override
  String get authRecoveryMessageHint =>
      'Por ejemplo, cuándo iniciaste sesión por última vez';

  @override
  String get authRecoverySending => 'Enviando…';

  @override
  String get authRecoveryResetPassword => 'Restablecer contraseña';

  @override
  String get authRecoveryAskForHelp => 'Pedir ayuda';

  @override
  String get authTermsTitle => 'Términos y condiciones';

  @override
  String get authTermsSubtitle => 'Un repaso rápido antes de entrar en la app.';

  @override
  String get authTermsIntro =>
      'Revisa y acepta nuestros Términos y nuestra Política de privacidad para continuar.';

  @override
  String get authTermsCommunityTitle => 'Normas de la comunidad';

  @override
  String get authTermsPointRespect => 'Sé respetuoso y auténtico.';

  @override
  String get authTermsPointNoHarassment =>
      'Nada de acoso ni conductas fraudulentas.';

  @override
  String get authTermsPointPrivacy =>
      'Tú controlas tu configuración de privacidad y la visibilidad de tu perfil.';

  @override
  String get authTermsPointReports =>
      'Revisamos las denuncias para mantener la comunidad segura.';

  @override
  String get authTermsPointViolations =>
      'Las infracciones pueden conllevar la suspensión o la eliminación de la cuenta.';

  @override
  String get authTermsReviewLater =>
      'Puedes revisar los detalles completos de la política más tarde en Ajustes, pero debes aceptarla antes de usar la app.';

  @override
  String get authTermsAgreeCheckbox =>
      'Acepto los Términos y la Política de privacidad';

  @override
  String get authTermsAcceptButton => 'Aceptar y continuar';

  @override
  String get authTermsSaveFailed =>
      'No se pudo guardar tu aceptación. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String discoverSuperLikeSent(String name) {
    return 'Superlike enviado a $name';
  }

  @override
  String get discoverMatchPlaceholderMessage => 'Saluda';

  @override
  String discoverChatNeedsMatch(String name) {
    return 'Podrás chatear con $name cuando haya un match de verdad.';
  }

  @override
  String get discoverDailyLimitTitle => 'Ya usaste tus me gusta de hoy';

  @override
  String get discoverDailyLimitBody =>
      'Vuelve mañana o mejora tu plan para tener más me gusta cada día.';

  @override
  String discoverDailyLimitResetBody(String reset) {
    return '$reset. Mejora tu plan para tener más me gusta cada día.';
  }

  @override
  String get discoverSeePlans => 'Ver planes';

  @override
  String get discoverNotNow => 'Ahora no';

  @override
  String get discoverBackToToday => 'Volver a Hoy';

  @override
  String get discoverExploreTitle => 'Explorar';

  @override
  String get discoverSpotlightReviewed => '¡Destacados revisados!';

  @override
  String get discoverAllReviewed => '¡Todo revisado!';

  @override
  String get discoverCuratedForYou => 'Seleccionado para ti';

  @override
  String get discoverTitle => 'Descubre matches';

  @override
  String get discoverTagline => 'Un poco de curiosidad. Una conexión real.';

  @override
  String get discoverMessages => 'Mensajes';

  @override
  String get discoverFilters => 'Filtros';

  @override
  String get discoverYourDeck => 'Tu mazo';

  @override
  String get discoverStatReady => 'Listos';

  @override
  String get discoverStatLiked => 'Me gusta';

  @override
  String get discoverStatPassed => 'Descartados';

  @override
  String get discoverEdit => 'Editar';

  @override
  String get discoverShowingEveryone =>
      'Mostrando a todas las personas según tus preferencias.';

  @override
  String get discoverToday => 'Hoy';

  @override
  String get discoverTodaySubtitle => 'Cinco sugerencias, renovadas cada día.';

  @override
  String get discoverViewAll => 'Ver todo';

  @override
  String get discoverMatchOnYourTerms => 'Haz match a tu manera';

  @override
  String get discoverMatchOnYourTermsBody =>
      'El match surge del interés mutuo. Puedes bloquear o denunciar a cualquiera desde su perfil o la conversación.';

  @override
  String get discoverErrorEyebrow => 'Conexión en pausa';

  @override
  String get discoverErrorTitle => 'No se pudieron cargar los perfiles';

  @override
  String discoverTrustFilteredBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Los filtros de confianza ocultaron $count perfiles. Prueba a relajarlos o actualiza para rehacer tu mazo.',
      one:
          'Los filtros de confianza ocultaron $count perfil. Prueba a relajarlos o actualiza para rehacer tu mazo.',
    );
    return '$_temp0';
  }

  @override
  String get discoverDeckPreparingBody =>
      'Estamos preparando tu mazo. Actualiza para ver nuevos perfiles verificados cerca de ti.';

  @override
  String get discoverCheckBackSoon => 'Vuelve pronto';

  @override
  String get discoverNoSpotlightProfiles => 'No hay perfiles destacados';

  @override
  String get discoverNoProfiles => 'No hay perfiles';

  @override
  String get discoverRefresh => 'Actualizar';

  @override
  String get discoverPromisePrivate => 'Privado';

  @override
  String get discoverPremium => 'Premium';

  @override
  String discoverNotificationsUnread(int count) {
    return 'Notificaciones, $count sin leer';
  }

  @override
  String get discoverLatestUnreadNotifications =>
      'Últimas notificaciones sin leer';

  @override
  String get discoverNoUnreadNotifications => 'No hay notificaciones sin leer';

  @override
  String get discoverNotificationWhoReplied => 'Quién me respondió';

  @override
  String discoverNotificationRepliesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respuestas nuevas',
      one: '1 respuesta nueva',
    );
    return '$_temp0';
  }

  @override
  String get discoverNotificationWhoLiked => 'Quién me dio me gusta';

  @override
  String discoverNotificationLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count me gusta nuevos',
      one: '1 me gusta nuevo',
    );
    return '$_temp0';
  }

  @override
  String get discoverViewMore => 'Ver más';

  @override
  String get discoverFitsYourWeek => 'Encaja en tu semana';

  @override
  String discoverTodayPicks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sugerencias',
      one: '1 sugerencia',
    );
    return '$_temp0';
  }

  @override
  String get discoverPickedForYouToday => 'Elegido para ti hoy.';

  @override
  String get discoverErrorLoginToDiscover =>
      'Inicia sesión para descubrir perfiles.';

  @override
  String get discoverErrorLoadProfiles =>
      'No se pudieron cargar los perfiles. Inténtalo de nuevo.';

  @override
  String get discoverErrorSessionUnavailable =>
      'La sesión no está disponible. Vuelve a iniciar sesión.';

  @override
  String get discoverErrorLikeRetry =>
      'Ahora no se puede dar me gusta. Inténtalo de nuevo.';

  @override
  String get discoverErrorLike => 'Ahora no se puede dar me gusta.';

  @override
  String get discoverErrorPassRetry =>
      'Ahora no se puede descartar. Inténtalo de nuevo.';

  @override
  String get discoverErrorLoadLikedMe =>
      'No se pudo cargar quién te dio me gusta. Inténtalo de nuevo.';

  @override
  String get discoverErrorAnswerInFlight => 'Ya estamos enviando tu respuesta.';

  @override
  String get discoverErrorAnswer =>
      'No se pudo enviar tu respuesta. Inténtalo de nuevo.';

  @override
  String get firstChapterTopicPace => 'Ritmo de comunicación';

  @override
  String get firstChapterTopicDates => 'Comodidad en las citas';

  @override
  String get firstChapterTopicLanguage => 'Idiomas';

  @override
  String get firstChapterTopicFamily => 'Implicación de la familia';

  @override
  String get firstChapterInMyWords => 'Con mis palabras';

  @override
  String firstChapterComfortOriginal(String language) {
    return 'Original · $language';
  }

  @override
  String firstChapterComfortMemberTranslation(String language) {
    return 'Traducción del miembro · $language';
  }

  @override
  String get firstChapterComfortReloadSaved => 'Recargar la versión guardada';

  @override
  String get firstChapterComfortReloadCards => 'Recargar las tarjetas';

  @override
  String get firstChapterComfortHeadline => 'Tus palabras. Tus límites.';

  @override
  String get firstChapterComfortIntro =>
      'Contexto opcional para las personas con las que has hecho match. No se deduce nada de tus orígenes. Escribe en el idioma que sientas tuyo.';

  @override
  String get firstChapterComfortShareTitle =>
      'Compartir estas tarjetas con mis matches';

  @override
  String get firstChapterComfortShareSubtitle =>
      'Desactivado, todas las tarjetas son privadas.';

  @override
  String get firstChapterComfortRemoveFromDraft => 'Quitar del borrador';

  @override
  String get firstChapterComfortTopicLabel => 'Un poco de contexto sobre';

  @override
  String get firstChapterComfortOriginalLanguage => 'Idioma original';

  @override
  String get firstChapterComfortOwnWords => 'Con tus propias palabras';

  @override
  String get firstChapterComfortOwnWordsHint =>
      'Por ejemplo: me gustan las citas de día y tener algo de tiempo para sentirme cómodo.';

  @override
  String get firstChapterComfortTranslation => 'Tu traducción (opcional)';

  @override
  String get firstChapterComfortTranslationLanguage =>
      'Idioma de la traducción (si la añades)';

  @override
  String get firstChapterComfortTranslationNote =>
      'Las traducciones se marcan como aportadas por el miembro. Tus palabras originales siempre se conservan.';

  @override
  String get firstChapterComfortAddCard =>
      'Añadir / reemplazar esta tarjeta en el borrador';

  @override
  String get firstChapterComfortMissingFields =>
      'Añade tus palabras y el idioma. Una traducción también necesita su idioma.';

  @override
  String get firstChapterComfortUnaddedCard =>
      'Añade tu tarjeta al borrador antes de guardar.';

  @override
  String get firstChapterComfortSaveFailed =>
      'Tu borrador sigue aquí. Recarga para comprobar la última versión guardada antes de reintentarlo.';

  @override
  String get firstChapterSaving => 'Guardando…';

  @override
  String get firstChapterComfortSave => 'Guardar mis elecciones';

  @override
  String get firstChapterYourMatch => 'tu match';

  @override
  String get firstChapterSaveUnconfirmed =>
      'No pudimos confirmar el guardado. Actualiza para comprobarlo antes de reintentarlo.';

  @override
  String get firstChapterJointPreviewTitle =>
      'Una historia que aprobáis los dos';

  @override
  String get firstChapterSoloPreviewTitle =>
      'Vista previa de tu capítulo público';

  @override
  String firstChapterThenSurprise(String surprise) {
    return 'Luego… $surprise';
  }

  @override
  String get firstChapterJointPreviewBody =>
      'Tu aprobación es la mitad. El enlace solo funciona cuando tu pareja también aprueba exactamente esta tarjeta. Cualquiera de los dos puede revocarlo.';

  @override
  String get firstChapterSoloPreviewBody =>
      'Solo esta escena y el comienzo que elegiste son públicos. Sin nombres, fotos, chat privado, ubicación ni aportaciones de tu pareja. Puedes revocar el enlace.';

  @override
  String get firstChapterKeepPrivate => 'Mantener en privado';

  @override
  String get firstChapterApproveMyHalf => 'Aprobar mi mitad';

  @override
  String get firstChapterCreateShareLink => 'Crear enlace para compartir';

  @override
  String get firstChapterStudioTitle => 'Estudio Primer Capítulo';

  @override
  String get firstChapterRefresh => 'Actualizar capítulo';

  @override
  String get firstChapterHeroEyebrow => 'UNA PEQUEÑA AVENTURA. DOS AUTORES.';

  @override
  String get firstChapterHeroTitle => 'Lo que pasa\ndespués es vuestro.';

  @override
  String get firstChapterHeroSolo =>
      'Crea una escena. Pásasela a alguien. O crea un primer capítulo con alguien con quien hayas hecho match.';

  @override
  String firstChapterHeroPair(String name) {
    return 'Tú y $name. Un comienzo, un giro inesperado y una historia que podéis hacer realidad.';
  }

  @override
  String get firstChapterHeroPace =>
      'Opcional, a tu ritmo. Chatear siempre es una elección.';

  @override
  String get firstChapterLoadFailed => 'No se pudo cargar tu capítulo.';

  @override
  String get firstChapterTryAgain => 'Reintentar';

  @override
  String get firstChapterStepChooseScene => '01 / Elige tu escena';

  @override
  String get firstChapterStepWriteBeginning => '02 / Escribe el comienzo';

  @override
  String get firstChapterStartOurChapter => 'Empezar nuestro capítulo';

  @override
  String get firstChapterPassTheChapter => 'Pasar el capítulo';

  @override
  String get firstChapterYourFirstChapter => 'Vuestro primer capítulo';

  @override
  String get firstChapterItBeginsWith => 'EMPIEZA CON';

  @override
  String get firstChapterAndThen => 'Y LUEGO…';

  @override
  String firstChapterDateIdeaNote(String beginning, String surprise) {
    return '$beginning. Luego $surprise.';
  }

  @override
  String get firstChapterMakeDateIdea => 'Convertirlo en una idea de cita';

  @override
  String get firstChapterDateIdeaHint =>
      'Una sugerencia para dar forma juntos. No se reserva ni se acepta ninguna cita automáticamente.';

  @override
  String get firstChapterYourTurn => 'Te toca: añade una sorpresa.';

  @override
  String get firstChapterBeginningSaved =>
      'Tu comienzo está guardado. Tu match puede añadir una sorpresa cuando quiera. Podéis seguir chateando.';

  @override
  String get firstChapterClose => 'Cerrar este capítulo';

  @override
  String get firstChapterGiveBackTitle => 'Historias que inspiran';

  @override
  String get firstChapterGiveBackBody =>
      'Vuestra conexión puede inspirar un nuevo comienzo. Compartid solo esta idea de cita anónima, con la aprobación de los dos.';

  @override
  String get firstChapterPreviewAnonymous =>
      'Vista previa de nuestra historia anónima';

  @override
  String get firstChapterGreenLightTitle => 'Una luz verde privada';

  @override
  String get firstChapterInTheirWords => 'Con sus palabras';

  @override
  String get firstChapterMakeRoomTitle => 'Haz espacio para lo que te importa';

  @override
  String get firstChapterMakeRoomSubtitle =>
      'Tu ritmo, idiomas, citas y expectativas familiares. Tus palabras, compartidas solo cuando tú decidas.';

  @override
  String get firstChapterCreateWithConnection => 'Crear con una conexión';

  @override
  String get firstChapterCreateTogether => 'Crear juntos un primer capítulo';

  @override
  String get firstChapterMatchesAppearHere =>
      'Tus matches mutuos aparecen aquí. Ya puedes probar y compartir una escena tú solo.';

  @override
  String get firstChapterSharedChapters => 'Tus capítulos compartidos';

  @override
  String get firstChapterReloadShared => 'Recargar capítulos compartidos';

  @override
  String get firstChapterNothingPublic =>
      'Nada es público hasta que decidas compartirlo.';

  @override
  String get firstChapterGreenChat => 'Seguir chateando';

  @override
  String get firstChapterGreenCall => 'Probar una llamada';

  @override
  String get firstChapterGreenDate => 'Proponer una cita';

  @override
  String get firstChapterGreenLightIntro =>
      'Solo se revela una elección compartida. Nadie ve una petición sin respuesta. Las elecciones caducan a los siete días; bórralas para retirarlas.';

  @override
  String get firstChapterSavePrivately => 'Guardar en privado';

  @override
  String get firstChapterGreenLightNone =>
      'Cualquier siguiente paso compartido aparecerá aquí.';

  @override
  String firstChapterGreenLightMutual(String choices) {
    return 'Los dos os sentís cómodos con: $choices';
  }

  @override
  String get firstChapterGreenLightNote =>
      'Una luz verde es permiso para proponer. Una llamada o una cita siguen necesitando un acuerdo aparte.';

  @override
  String get firstChapterLinkRevoked => 'Enlace revocado';

  @override
  String get firstChapterPublicScene => 'Escena pública y anónima';

  @override
  String get firstChapterPrivateUntilBoth =>
      'Privado hasta que los dos lo aprueben';

  @override
  String get firstChapterLinkCopied =>
      'Enlace del capítulo copiado. Compártelo donde quieras.';

  @override
  String get firstChapterCopyLink => 'Copiar enlace';

  @override
  String get firstChapterApproveStory => 'Aprobar exactamente esta historia';

  @override
  String get firstChapterRevokeLink => 'Revocar enlace';

  @override
  String networkSlowResponse(int mbps) {
    return 'Red débil detectada. Usa al menos $mbps Mbps para que el chat, los regalos y los gestos vayan mejor.';
  }

  @override
  String get networkOffline =>
      'No hay una conexión estable. Vuelve a conectarte para seguir usando la app.';

  @override
  String networkWeak(int mbps) {
    return 'La red es débil. Usa al menos $mbps Mbps para una experiencia más fluida.';
  }

  @override
  String get networkCannotReachService =>
      'No se puede conectar con el servicio local. Comprueba que la API esté en marcha.';

  @override
  String get gateCheckingTerms => 'Comprobando las condiciones…';

  @override
  String get gateLoadingProfile => 'Cargando tu perfil…';

  @override
  String get gateConnectionIssue => 'Problema de conexión';

  @override
  String get safetyReportFailed => 'No se pudo denunciar al usuario';

  @override
  String get safetyBlockFailed => 'No se pudo bloquear al usuario';

  @override
  String get safetyUnblockFailed => 'No se pudo desbloquear al usuario';

  @override
  String get safetyNotAuthenticated => 'No has iniciado sesión';

  @override
  String get timeAgoJustNow => 'Ahora mismo';

  @override
  String timeAgoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count minutos',
      one: 'hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count horas',
      one: 'hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String timeAgoWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count semanas',
      one: 'hace 1 semana',
    );
    return '$_temp0';
  }

  @override
  String get themePreviewBarrier => 'Vista previa del tema';

  @override
  String get themeNowShowing => 'EN CARTELERA';

  @override
  String get themeTaglineRealLife =>
      'Marfil cálido, verde bosque y albaricoque.';

  @override
  String get themeTaglineRealLifeNight =>
      'Verde bosque, menta suave y luz de velas.';

  @override
  String get themeTaglineDaylight =>
      'Crema, tinta y un toque frambuesa, como la web.';

  @override
  String get themeTaglineEmber =>
      'Noche negro ciruela con brasas y brillo violeta.';

  @override
  String get themeTaglineForge => 'Rojo horno, azul acero, cromo pavonado.';

  @override
  String get themeTaglineNeongrid =>
      'Cristal negro, líneas de luz cian, pulso ámbar.';

  @override
  String get themeTaglineCrimsonalloy =>
      'Laca carmesí, oro fundido, granate de medianoche.';

  @override
  String get themeTaglineCircuit =>
      'Verde circuito, violeta señal, negro carbono.';

  @override
  String get themeTaglineDeepfield =>
      'Espacio profundo, azul plasma y un destello de oro estelar.';

  @override
  String get themeTaglineLove => 'Rubor, rosa y un poco de oro.';

  @override
  String get themeTaglineRose =>
      'Vino aterciopelado, rojo rosa y un poco de oro.';

  @override
  String get themeTaglinePetal =>
      'Papel rosado, pétalos a la deriva, un toque de salvia.';

  @override
  String get themeTaglineSnow =>
      'Nieve recién caída, cristal esmerilado y una cinta de aurora.';

  @override
  String get themeTaglineGothic =>
      'Tracería a la luz de la luna, granate, humo de vela y oro antiguo.';

  @override
  String get themeTaglineCalm =>
      'Poca estimulación, alto contraste. Fondo quieto, sin movimiento.';

  @override
  String get themeLooksTodayDescription =>
      'De día, marfil cálido y verde bosque. De noche, menta suave y bosque profundo.';

  @override
  String get settingsEyebrow => 'AJUSTES';

  @override
  String get settingsHeaderSubtitle => 'Tu estilo, tu privacidad y tu cuenta.';

  @override
  String get settingsThemeSection => 'Tema';

  @override
  String get settingsThemeSectionTitle => 'Hazlo tuyo';

  @override
  String get settingsThemeSectionCaption =>
      'Cada pantalla sigue el estilo que elijas.';

  @override
  String get settingsSectionYourStory => 'Tu historia';

  @override
  String get settingsDatingRhythmTitle => 'Tu ritmo de citas';

  @override
  String get settingsDatingRhythmSubtitle =>
      'Intención, ritmo, disponibilidad y privacidad de presentaciones';

  @override
  String get settingsProfileStoriesTitle => 'Tus historias de perfil';

  @override
  String get settingsProfileStoriesSubtitle =>
      'Pequeños momentos, tus palabras, fotos opcionales';

  @override
  String get settingsBlogTitle => 'Blog · Capítulos abiertos';

  @override
  String get settingsBlogSubtitle => 'Tu diario, tus fotos, tu público';

  @override
  String get settingsLookPreviewEyebrow => 'HOY';

  @override
  String get settingsLookPreviewHeadline => 'Algo real.';

  @override
  String get friendsEyebrow => 'AMIGOS';

  @override
  String get friendsTitle => 'Tu gente';

  @override
  String get friendsSubtitle =>
      'Los amigos pueden escribirse, hacer planes y crear grupos juntos. Las solicitudes necesitan un sí de ambas partes.';

  @override
  String get friendsBack => 'Atrás';

  @override
  String get friendsAddFriend => 'Añadir amigo';

  @override
  String get friendsCreateGroup => 'Crear un grupo';

  @override
  String get friendsSectionRequests => 'SOLICITUDES';

  @override
  String get friendsRequestsWaitingOnOthers => 'Esperando a otros';

  @override
  String get friendsRequestsWaitingOnYou => 'Esperan tu respuesta';

  @override
  String get friendsRequestsCaption =>
      'No se comparte nada hasta que los dos aceptéis.';

  @override
  String get friendsSectionChats => 'CHATS';

  @override
  String get friendsChatsTitle => 'Conversaciones';

  @override
  String get friendsSectionIntros => 'PRESENTACIONES';

  @override
  String get friendsIntrosTitle => 'Presentaciones para ti';

  @override
  String get friendsSectionVouches => 'AVALES';

  @override
  String get friendsVouchesPendingTitle => 'Avales pendientes de tu aprobación';

  @override
  String friendsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amigos',
      one: '1 amigo',
      zero: 'Aún no tienes amigos',
    );
    return '$_temp0';
  }

  @override
  String get friendsIntroduce => 'Presentar';

  @override
  String get friendsEmptyBody =>
      'Encuentra a gente que conoces por su nombre o nombre de usuario, o añade a alguien desde un match, una sala o un grupo.';

  @override
  String get friendsSectionOnProfile => 'EN TU PERFIL';

  @override
  String get friendsVouchesOnProfileTitle => 'Avales en tu perfil';

  @override
  String friendsQuoted(String text) {
    return '«$text»';
  }

  @override
  String friendsVouchedForYou(String name) {
    return '$name te ha avalado';
  }

  @override
  String get friendsHideFromProfile => 'Ocultar del perfil';

  @override
  String get friendsSectionMore => 'MÁS';

  @override
  String get friendsMoreTitle => 'Planes y presentaciones';

  @override
  String get friendsPlansLinkTitle => 'Planes de citas compartidos contigo';

  @override
  String get friendsPlansLinkSubtitle =>
      'Tus amigos te avisan cuando planean una cita y cuando dan señales después.';

  @override
  String get friendsInviteIntroducerTitle =>
      'Invita a un amigo que no está buscando pareja';

  @override
  String get friendsInviteIntroducerSubtitle =>
      'Elige quién puede presentarte. Revisa o retira el permiso cuando quieras.';

  @override
  String get friendsIntroTermsTitle => 'Presentaciones, a tu manera';

  @override
  String get friendsIntroTermsSubtitle =>
      'Elige si tus amigos pueden presentarte y qué muestra una vista previa.';

  @override
  String get friendsSectionActivity => 'ACTIVIDAD';

  @override
  String get friendsActivityTitle => 'Con tus amigos';

  @override
  String friendsVouchSentSnack(String name) {
    return 'Aval enviado. $name lo aprueba antes de que se muestre.';
  }

  @override
  String friendsRemoveTitle(String name) {
    return '¿Quitar a $name?';
  }

  @override
  String get friendsRemoveBody =>
      'Dejaréis de ser amigos y vuestro chat se cerrará. No se le avisa.';

  @override
  String get friendsRemoveFriend => 'Quitar amigo';

  @override
  String get friendsIntroMadeSnack =>
      'Presentación hecha. Tus dos amigos recibirán tu mensaje.';

  @override
  String get friendsAddSheetLabel => 'AÑADIR AMIGO';

  @override
  String get friendsAddSheetTitle => 'Encuentra a alguien que conozcas';

  @override
  String get friendsAddSheetCaption =>
      'Busca por nombre o @usuario. La otra persona decide si acepta.';

  @override
  String get friendsSearchHiddenNote =>
      'No apareces en la búsqueda de amigos, así que los demás no pueden encontrarte aquí. Cámbialo en Privacidad y seguridad.';

  @override
  String get friendsSearchLabel => 'Nombre o @usuario';

  @override
  String get friendsSearchHelper => 'Escribe al menos 3 letras';

  @override
  String get friendsSearchFailed =>
      'La búsqueda no está disponible ahora. Inténtalo de nuevo.';

  @override
  String friendsSearchNoResults(String query) {
    return 'No se encontró a nadie para «$query».';
  }

  @override
  String get friendsNewGroupLabel => 'NUEVO GRUPO';

  @override
  String get friendsNewGroupTitle => '¿Quién se apunta?';

  @override
  String get friendsNewGroupCaption =>
      'Elige a qué amigos invitar. Puedes añadir más después.';

  @override
  String get friendsChooseFriends => 'Elige amigos';

  @override
  String friendsCreateGroupWith(int count) {
    return 'Crear un grupo con $count';
  }

  @override
  String get friendsSourceMatch => 'De tus matches';

  @override
  String get friendsSourceProfile => 'Vio tu perfil';

  @override
  String get friendsSourceRoom => 'Os conocisteis en una sala';

  @override
  String get friendsSourceGroup => 'De un grupo';

  @override
  String get friendsSourceSearch => 'Te encontró por tu nombre';

  @override
  String get friendsWantsToBeFriends => 'Quiere ser tu amigo';

  @override
  String get friendsRequestSent => 'Solicitud enviada';

  @override
  String get friendsCancel => 'Cancelar';

  @override
  String get friendsDecline => 'Rechazar';

  @override
  String get friendsAccept => 'Aceptar';

  @override
  String friendsMessageTooltip(String name) {
    return 'Escribir a $name';
  }

  @override
  String friendsMessageTooltipUnread(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Escribir a $name, $count sin leer',
      one: 'Escribir a $name, 1 sin leer',
    );
    return '$_temp0';
  }

  @override
  String friendsMoreFor(String name) {
    return 'Más opciones para $name';
  }

  @override
  String get friendsMenuVouch => 'Avalar a esta persona';

  @override
  String get friendsMenuIntro => 'Presentar a un amigo';

  @override
  String friendsChatSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chat con $name, $count sin leer',
      zero: 'Chat con $name',
    );
    return '$_temp0';
  }

  @override
  String friendsChatSemanticsMuted(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chat con $name, $count sin leer, notificaciones silenciadas',
      zero: 'Chat con $name, notificaciones silenciadas',
    );
    return '$_temp0';
  }

  @override
  String friendsIntroHeadline(String introducer, String person) {
    return '$introducer cree que deberías conocer a $person';
  }

  @override
  String friendsIntroHeadlineSomeone(String introducer) {
    return '$introducer cree que deberías conocer a alguien';
  }

  @override
  String friendsNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String get friendsIntroNoThanks => 'No, gracias';

  @override
  String get friendsIntroImIn => 'Me apunto';

  @override
  String get friendsVouchKeepPrivate => 'Mantener en privado';

  @override
  String get friendsVouchShowOnProfile => 'Mostrar en mi perfil';

  @override
  String get memberProfileNoData => 'No se encontraron datos del perfil.';

  @override
  String get memberProfileSignInToView => 'Inicia sesión para ver tu perfil.';

  @override
  String get memberProfileLoadFailed =>
      'No se pudo cargar el perfil. Inténtalo de nuevo.';

  @override
  String get memberProfileConnectionsTitle => 'Tus conexiones';

  @override
  String get memberProfileConnectionsCaption =>
      'Personas a las que diste like, tus matches y tus conversaciones.';

  @override
  String get memberProfileStatLiked => 'Tus likes';

  @override
  String get memberProfileStatMatches => 'Matches';

  @override
  String get memberProfileStatMessages => 'Mensajes';

  @override
  String memberProfileOpenStat(String label) {
    return 'Abrir $label';
  }

  @override
  String get memberProfileNoticedTitle => 'Quién se ha fijado en ti';

  @override
  String get memberProfileNoticedCaption =>
      'Likes y visitas de miembros cerca de ti.';

  @override
  String get memberProfileWhoLikedMe => 'Quién me ha dado like';

  @override
  String memberProfileWhoLikedMeCount(int count) {
    return 'Quién me ha dado like ($count)';
  }

  @override
  String get memberProfileWhoLikedMeSubtitle =>
      'Miembros a los que les gustó tu perfil.';

  @override
  String get memberProfileWhoViewedTitle => 'Quién ha visto mi perfil';

  @override
  String get memberProfileWhoViewedSubtitle => 'Visitas recientes a tu perfil.';

  @override
  String get memberProfileWhoViewedTooltip => 'Quién ha visto mi perfil';

  @override
  String get memberProfileRefreshTooltip => 'Actualizar perfil';

  @override
  String get memberProfilePreferencesTitle => 'Tus preferencias';

  @override
  String get memberProfilePrefSeeking => 'Busco';

  @override
  String get memberProfilePrefDistance => 'Distancia';

  @override
  String memberProfileWithinKm(int km) {
    return 'A menos de $km km';
  }

  @override
  String get profileViewersTitle => 'Han visto mi perfil';

  @override
  String get profileViewersLoadFailed =>
      'No se pudieron cargar las visitas al perfil.';

  @override
  String get profileViewersEmpty => 'Nadie ha visto tu perfil todavía.';

  @override
  String get profileViewersViewedRecently => 'Visto recientemente';

  @override
  String profileViewersViewedAt(String time) {
    return 'Visto el $time';
  }

  @override
  String get profileMasterReligionParsi => 'Parsi';

  @override
  String get profileMasterReligionBahai => 'Bahaí';

  @override
  String get profileMasterReligionTribal => 'Tribal / Indígena';

  @override
  String get profileMasterWorkout1to2 => '1-2 veces por semana';

  @override
  String get profileMasterWorkout3to4 => '3-4 veces por semana';

  @override
  String get profileMasterWorkout5Plus => '5 o más veces por semana';

  @override
  String get profileMasterWorkoutDaily => 'A diario';

  @override
  String get profileMasterDietNoPreference => 'Sin preferencia';

  @override
  String get profileMasterDietVegetarian => 'Vegetariano';

  @override
  String get profileMasterDietEggetarian => 'Vegetariano con huevo';

  @override
  String get profileMasterDietNonVegetarian => 'No vegetariano';

  @override
  String get profileMasterDietVegan => 'Vegano';

  @override
  String get profileMasterDietJain => 'Dieta jainista';

  @override
  String get profileMasterDietTypeBalanced => 'Equilibrada';

  @override
  String get profileMasterDietTypeHighProtein => 'Alta en proteínas';

  @override
  String get profileMasterDietTypeLowCarb => 'Baja en carbohidratos';

  @override
  String get profileMasterDietTypeKeto => 'Keto';

  @override
  String get profileMasterDietTypeMediterranean => 'Mediterránea';

  @override
  String get profileMasterDietTypeIntermittentFasting => 'Ayuno intermitente';

  @override
  String get profileMasterSleepEarlyBird => 'Madrugador';

  @override
  String get profileMasterSleepNightOwl => 'Noctámbulo';

  @override
  String get profileMasterSleepFlexible => 'Flexible';

  @override
  String get profileMasterSleepShiftBased => 'Por turnos';

  @override
  String get profileMasterTravelHomebody => 'Casero';

  @override
  String get profileMasterTravelOccasional => 'Viajero ocasional';

  @override
  String get profileMasterTravelFrequent => 'Viajero frecuente';

  @override
  String get profileMasterTravelAdventure => 'Aventurero';

  @override
  String get profileMasterTravelLuxury => 'Viajes de lujo';

  @override
  String get profileMasterTravelBackpacker => 'Mochilero';

  @override
  String get profileMasterPoliticsSimilar => 'Solo opiniones similares';

  @override
  String get profileMasterPoliticsOpen => 'Abierto a diferencias';

  @override
  String get profileMasterPoliticsNotDiscuss => 'Prefiero no hablar de ello';

  @override
  String get profileMasterPoliticsNoStrong => 'Sin preferencia marcada';

  @override
  String get profileMasterIntentLongTerm => 'Relación duradera';

  @override
  String get profileMasterIntentMarriage => 'Matrimonio';

  @override
  String get profileMasterIntentNewFriends => 'Nuevos amigos';

  @override
  String get chatBackToConversations => 'Volver a las conversaciones';

  @override
  String get chatOfflineBanner =>
      'Estás sin conexión. Tu borrador se quedará aquí mientras vuelves a conectarte.';

  @override
  String get chatVoiceHello => 'Comparte un saludo de voz · lee y escucha';

  @override
  String get chatLoadFailedTitle => 'Volvamos a conectar.';

  @override
  String get chatLoadFailedBody =>
      'No se pudo cargar tu conversación. Inténtalo de nuevo.';

  @override
  String get chatConversationEnded => 'Esta conversación ha terminado.';

  @override
  String get chatUnlockStepRequired =>
      'Completa el paso de desbloqueo actual para seguir con esta conversación.';

  @override
  String get chatGiftTrayTitle => 'Un detallito para esa persona';

  @override
  String get chatCloseGifts => 'Cerrar regalos';

  @override
  String get chatAllGifts => 'Todos los regalos';

  @override
  String get chatNoGiftsInCollection =>
      'No hay regalos disponibles en esta colección.';

  @override
  String get chatAddCoins => 'Añadir monedas';

  @override
  String get chatFreeGiftDaily => 'Gratis · 1 al día';

  @override
  String chatCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monedas',
      one: '1 moneda',
    );
    return '$_temp0';
  }

  @override
  String get chatSendingGift => 'Enviando tu regalo…';

  @override
  String get chatOfflineGifts =>
      'Estás sin conexión. Puedes ver los regalos y enviarlos cuando vuelvas a conectarte.';

  @override
  String chatGiftConfirmTitle(String gift, String name) {
    return '¿Enviar $gift a $name?';
  }

  @override
  String chatGiftNoteQuote(String note) {
    return '«$note»';
  }

  @override
  String chatGiftBalanceAfter(int balance, int remaining) {
    return '·  $balance → quedarán $remaining';
  }

  @override
  String get chatGiftNoObligation =>
      'Un regalo es un gesto, nunca una obligación de responder o quedar.';

  @override
  String chatGiftSendFor(String price) {
    return 'Enviar por $price';
  }

  @override
  String get chatNotNow => 'Ahora no';

  @override
  String get chatDeleteMessageTitle => '¿Eliminar el mensaje?';

  @override
  String get chatDeleteMessageBody =>
      'Esto elimina el mensaje de los chats de ambos.';

  @override
  String get chatDeleteForEveryone => 'Eliminar para todos';

  @override
  String get chatMessageDeletedSnack => 'Mensaje eliminado.';

  @override
  String get chatUndo => 'Deshacer';

  @override
  String get chatDeleteUndone => 'Eliminación deshecha.';

  @override
  String chatGiftReceivedFrom(String name) {
    return 'Regalo de $name';
  }

  @override
  String get chatGiftReceiverIntro => 'Tú decides qué se queda en tu chat.';

  @override
  String get chatHideGift => 'Ocultar regalo';

  @override
  String get chatHideGiftSubtitle => 'Quitarlo solo de tu chat.';

  @override
  String get chatReportAndHide => 'Denunciar y ocultar';

  @override
  String get chatReportAndHideSubtitle =>
      'Enviarlo al equipo de seguridad y quitarlo ya.';

  @override
  String get chatGiftHidden => 'Regalo ocultado de tu chat.';

  @override
  String get chatReportGiftTitle => 'Denunciar este regalo';

  @override
  String get chatReportGiftIntro =>
      'Elige un motivo. El regalo se ocultará de inmediato.';

  @override
  String get chatReportReasonLabel => 'Motivo';

  @override
  String get chatReportReasonUnwanted => 'Regalo no deseado';

  @override
  String get chatReportReasonHarassment => 'Acoso';

  @override
  String get chatReportReasonSexual => 'Contenido sexual';

  @override
  String get chatReportReasonScam => 'Estafa o fraude';

  @override
  String get chatReportReasonOther => 'Otra cosa';

  @override
  String get chatReportDetailsLabel => 'Añadir detalles (opcional)';

  @override
  String get chatReportSubmit => 'Enviar denuncia y ocultar';

  @override
  String get chatGiftReported =>
      'Regalo denunciado y ocultado. Nuestro equipo de seguridad lo revisará.';

  @override
  String get chatQuickEmojis => 'Emojis rápidos';

  @override
  String chatWalletTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monedas',
      one: '1 moneda',
    );
    return 'Tu monedero · $_temp0';
  }

  @override
  String get chatDailyLimitReached =>
      'Has alcanzado el límite diario de mensajes';

  @override
  String get chatDailyLimitFallback =>
      'Vuelve a intentarlo mañana o mejora tu plan.';

  @override
  String chatDailyLimitReset(String reset) {
    return '$reset · mejora tu plan para tener más.';
  }

  @override
  String get chatSeePlans => 'Ver planes';

  @override
  String chatQuotaOnPlan(String quota, String plan) {
    return '$quota con $plan';
  }

  @override
  String get chatYourConversation => 'Vuestra conversación';

  @override
  String get chatVerifiedHumans => 'Personas verificadas';

  @override
  String get chatVerifiedHumansShowsUp =>
      'Personas verificadas · Acude a las citas';

  @override
  String discoverLikedBack(String name) {
    return 'Le diste me gusta a $name de vuelta';
  }

  @override
  String discoverPassedOn(String name) {
    return 'Descartaste a $name';
  }

  @override
  String get discoverLikedMeLoadFailedTitle =>
      'No se pudieron cargar tus me gusta';

  @override
  String get discoverLikedMeEmptyTitle => 'Aún no hay me gusta nuevos';

  @override
  String get discoverLikedMeEmptyBody =>
      'Cuando alguien te dé me gusta, aparecerá aquí. Devuélvele el me gusta y será un match.';

  @override
  String get discoverLikedMeIntro =>
      'Ya les gustas. Devuelve el me gusta para hacer match o descarta. Descartar es privado.';

  @override
  String get discoverLikedMeTitle => 'Les gustas';

  @override
  String discoverLikedMeTitleCount(int count) {
    return 'Les gustas · $count';
  }

  @override
  String get discoverPass => 'Descartar';

  @override
  String get discoverLikeBack => 'Devolver me gusta';

  @override
  String get discoverLikedJustNow => 'Te dio me gusta hace un momento';

  @override
  String discoverLikedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te dio me gusta hace $count minutos',
      one: 'Te dio me gusta hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te dio me gusta hace $count horas',
      one: 'Te dio me gusta hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te dio me gusta hace $count días',
      one: 'Te dio me gusta hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te dio me gusta hace $count semanas',
      one: 'Te dio me gusta hace 1 semana',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedOnDate(String date) {
    return 'Te dio me gusta el $date';
  }

  @override
  String discoverLikedProfilesTitle(int count) {
    return 'Perfiles que te gustan ($count)';
  }

  @override
  String get discoverNoLikedProfiles => 'Aún no te ha gustado ningún perfil';

  @override
  String get discoverLikedProfileFallback => 'Perfil que te gusta';

  @override
  String get discoverPassedProfilesTitle => 'Perfiles descartados';

  @override
  String get discoverNoPassedProfiles => 'Aún no hay perfiles descartados';

  @override
  String get discoverSavedForLater => 'Guardado para más tarde';

  @override
  String get discoverSpotlightFiltersTitle => 'Filtros de destacados';

  @override
  String get discoverVerifiedOnly => 'Solo verificados';

  @override
  String discoverAgeRange(int min, int max) {
    return 'Rango de edad: $min - $max';
  }

  @override
  String get discoverSpotlightTitle => 'Matches destacados';

  @override
  String get discoverSpotlightSubtitle => 'Conexiones premium seleccionadas';

  @override
  String discoverPassedCount(int count) {
    return 'Descartados ($count)';
  }

  @override
  String get discoverOpenChatsFromDiscover => 'Abre los chats desde Descubrir';

  @override
  String get discoverNoNewNotifications => 'No hay notificaciones nuevas';

  @override
  String get discoverNoSpotlightMatchFilters =>
      'Ningún perfil destacado coincide con los filtros';

  @override
  String get discoverAllSpotlightReviewed =>
      '¡Revisaste todos los perfiles destacados!';

  @override
  String get discoverSpotlightCheckBackLater =>
      'Vuelve más tarde para ver nuevos perfiles destacados';

  @override
  String get discoverReportSubmitted => 'Denuncia enviada.';

  @override
  String get discoverAppeal => 'Apelar';

  @override
  String discoverAppealPrefill(String userId) {
    return 'Revisar el resultado de moderación de la denuncia sobre el usuario $userId';
  }

  @override
  String get discoverProfileUnavailable =>
      'Este perfil no está disponible ahora mismo.';

  @override
  String get discoverGoBack => 'Volver';

  @override
  String get discoverPremiumView => 'Vista premium';

  @override
  String get todayLabel => 'HOY';

  @override
  String get todayRefreshTooltip => 'Actualizar Hoy';

  @override
  String get todayDiscoveryPreferences => 'Preferencias de descubrimiento';

  @override
  String get todayHeroTitle => 'Un pequeño hola.\nEspacio para algo real.';

  @override
  String get todayHeroSubtitle =>
      'Unas pocas presentaciones pensadas, a tu ritmo.';

  @override
  String get todaySectionPace => 'TU RITMO';

  @override
  String get todayPaceTitle => '¿Qué encaja en tu semana?';

  @override
  String get todayPaceBody =>
      'Tu ritmo, tu tipo de primera cita, disponibilidad opcional.';

  @override
  String get todaySetRhythm => 'Configura tu ritmo';

  @override
  String get todaySectionStory => 'TU HISTORIA';

  @override
  String get todaySectionIntroductions => 'PRESENTACIONES DE HOY';

  @override
  String get todayIntroductionsTitle => 'Algunas personas por conocer';

  @override
  String get todayIntroductionsCaption =>
      'Los intereses en común son un punto de partida. La química la descubres tú.';

  @override
  String get todayPausedTitle => 'Tómate el tiempo que necesites.';

  @override
  String get todayPausedBody =>
      'Las presentaciones están en pausa. Tus conversaciones siguen aquí.';

  @override
  String get todayManageRhythm => 'Gestiona tu ritmo';

  @override
  String get todayLoadingIntroductions => 'Cargando presentaciones';

  @override
  String get todayFailedTitle => 'Tus presentaciones tardan un momento.';

  @override
  String get todayFailedBody =>
      'No pudimos cargar la información más reciente. Vuelve a intentarlo.';

  @override
  String get todayTryAgain => 'Reintentar';

  @override
  String get todayEmptyTitle => 'Un pequeño respiro.';

  @override
  String get todayEmptyBody =>
      'Ahora mismo no hay presentaciones nuevas para tus preferencias. Puedes ajustar tu ritmo o explorar perfiles.';

  @override
  String get todayExploreProfiles => 'Explorar perfiles';

  @override
  String get todayAllIntroductions => 'Todas las presentaciones';

  @override
  String get todayBreatheTitle =>
      'Una buena conexión necesita espacio para respirar.';

  @override
  String get todayBreatheBody =>
      'Estas son las presentaciones de hoy. No hay cuenta atrás ni necesidad de decidir sobre todo el mundo.';

  @override
  String get todayExploreMore => 'Explorar más perfiles';

  @override
  String get todayCommonGround => 'ALGO EN COMÚN';

  @override
  String todayMeetName(String name) {
    return 'Conoce a $name';
  }

  @override
  String get todayFirstHelloCoffee =>
      'Un primer saludo podría ser un café juntos.';

  @override
  String get todayFirstHelloWalk =>
      'Un primer saludo podría ser un paseo de día.';

  @override
  String get todayFirstHelloMeal =>
      'Un primer saludo podría ser una comida tranquila.';

  @override
  String get todayFirstHelloVideoCall =>
      'Un primer saludo podría ser una videollamada.';

  @override
  String get todayFirstHelloEvent =>
      'Un primer saludo podría ser un evento que os guste a los dos.';

  @override
  String get todayFirstHelloDrinks =>
      'Un primer saludo podría ser tomar algo juntos.';

  @override
  String get todayFirstHelloOther =>
      'Un primer saludo podría ser algo que os guste a los dos.';

  @override
  String get todaySectionTalk => 'ALGO DE QUÉ HABLAR';

  @override
  String get todayTalkCaption =>
      'Historias, clubes e ideas que facilitan un primer saludo.';

  @override
  String get todayBlogTitle => 'Blog · Capítulos abiertos';

  @override
  String get todayBlogSubtitle =>
      'Lee las historias de otros miembros y escribe las tuyas.';

  @override
  String get todayBookClubsTitle => 'Clubes de lectura';

  @override
  String get todayBookClubsSubtitle =>
      'Un libro a la semana, comentado en grupo.';

  @override
  String get todayFilmClubsTitle => 'Cineclubs';

  @override
  String get todayFilmClubsSubtitle =>
      'Mira la película elegida y luego compartid opiniones.';

  @override
  String get todayPhotoThemesTitle => 'Temas de fotos';

  @override
  String get todayPhotoThemesSubtitle =>
      'Una foto por tema. Mira las de todos.';

  @override
  String get todayChapterStudioTitle => 'Estudio Primer capítulo';

  @override
  String get todayChapterStudioSubtitle => 'Empezad una historia juntos.';

  @override
  String get todayCoverFallbackLine => 'Una foto que encantó a los miembros';

  @override
  String todayCoverSemantics(String name) {
    return 'Abrir la portada de la semana de $name';
  }

  @override
  String get todayCoverTitle => 'PORTADA DE LA SEMANA';

  @override
  String todayCoverBy(String name) {
    return 'DE $name';
  }

  @override
  String get todayLikes => 'Me gusta';

  @override
  String get todayComments => 'Comentarios';

  @override
  String get todayThisWeek => 'Esta semana';

  @override
  String get todayWallLabel => 'DE LA COMUNIDAD';

  @override
  String get todayWallTitle => 'El muro de hoy';

  @override
  String get todayWallCaption =>
      'Historias y fotos que encantaron a los miembros: una nueva selección cada día';

  @override
  String get todayWallPrevious => 'Anterior';

  @override
  String get todayWallNext => 'Siguiente';

  @override
  String get todayWallChapter => 'CAPÍTULO';

  @override
  String get todayWallUntitled => 'Un capítulo sin título';

  @override
  String todayWallBy(String name) {
    return 'de $name';
  }

  @override
  String get todayWallEmpty =>
      'Tu muro se llenará a medida que los miembros compartan historias y fotos que les encantan';

  @override
  String get todayWallWrite => 'Escribir un capítulo';

  @override
  String get todayWallShare => 'Compartir una foto';

  @override
  String get profileSetupBackTooltip => 'Atrás';

  @override
  String profileSetupStepCounter(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get profileSetupLoadErrorTitle =>
      'No se pudieron cargar los datos del perfil.';

  @override
  String get profileSetupRetry => 'Reintentar';

  @override
  String get profileSetupEducationHighSchool => 'Bachillerato';

  @override
  String get profileSetupEducationBachelors => 'Grado';

  @override
  String get profileSetupEducationMasters => 'Máster';

  @override
  String get profileSetupEducationPhd => 'Doctorado';

  @override
  String get profileSetupEducationOther => 'Otro';

  @override
  String get profileSetupPreferNotToSay => 'Prefiero no decirlo';

  @override
  String profileSetupIncomeBelow(String amount) {
    return 'Menos de $amount';
  }

  @override
  String get profileSetupFrequencyNever => 'Nunca';

  @override
  String get profileSetupFrequencySocially => 'En ocasiones sociales';

  @override
  String get profileSetupFrequencyOccasionally => 'Ocasionalmente';

  @override
  String get profileSetupFrequencyRegularly => 'Con regularidad';

  @override
  String get profileSetupGenderMan => 'Hombre';

  @override
  String get profileSetupGenderWoman => 'Mujer';

  @override
  String get profileSetupGenderOther => 'Otro';

  @override
  String profileSetupBioTooShort(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'La biografía debe tener al menos $min caracteres.',
      one: 'La biografía debe tener al menos 1 carácter.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupSaveFailed =>
      'No se pudo guardar — inténtalo de nuevo.';

  @override
  String get profileSetupCouldNotSaveChanges =>
      'No se pudieron guardar tus cambios. Inténtalo de nuevo.';

  @override
  String get profileSetupAboutTitle => 'Haz que tu perfil brille';

  @override
  String get profileSetupAboutSubtitle =>
      'Estos datos ayudan a encontrar mejores matches.';

  @override
  String get profileSetupBioLabel => 'Biografía';

  @override
  String profileSetupBioHint(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Cuéntale a la gente sobre ti (mín. $min caracteres)',
      one: 'Cuéntale a la gente sobre ti (mín. 1 carácter)',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupHeightLabel => 'Altura (cm)';

  @override
  String get profileSetupHeightHint => 'Selecciona tu altura';

  @override
  String profileSetupHeightValue(int cm) {
    return '$cm cm';
  }

  @override
  String get profileSetupEducationLabel => 'Estudios';

  @override
  String get profileSetupEducationHint => 'Selecciona tus estudios';

  @override
  String get profileSetupProfessionLabel => 'Profesión';

  @override
  String get profileSetupProfessionHint => 'p. ej., ingeniera de software';

  @override
  String get profileSetupIncomeLabel => 'Ingresos (opcional)';

  @override
  String get profileSetupLifestyleTitle => 'Estilo de vida';

  @override
  String get profileSetupDrinkingLabel => 'Alcohol';

  @override
  String get profileSetupSmokingLabel => 'Tabaco';

  @override
  String get profileSetupSelectHint => 'Seleccionar';

  @override
  String get profileSetupReligionOptionalLabel => 'Religión (opcional)';

  @override
  String get profileSetupContinue => 'Continuar';

  @override
  String get profileSetupSaveAbout => 'Guardar «Sobre mí»';

  @override
  String get profileSetupPhotosSaved => 'Fotos guardadas.';

  @override
  String profileSetupPhotosMaxReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Solo puedes subir hasta $max fotos.',
      one: 'Solo puedes subir 1 foto.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupRemovePhotoTitle => '¿Quitar esta foto?';

  @override
  String get profileSetupRemovePhotoBody =>
      'Se quitará de tu perfil y se eliminará del almacenamiento.';

  @override
  String get profileSetupCancel => 'Cancelar';

  @override
  String get profileSetupRemove => 'Quitar';

  @override
  String profileSetupPhotosMinRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Sube al menos $min fotos para continuar.',
      one: 'Sube al menos 1 foto para continuar.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTitle => 'Añade tus fotos';

  @override
  String profileSetupPhotosSubtitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Añade al menos $min fotos para conseguir matches',
      one: 'Añade al menos 1 foto para conseguir matches',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupChooseSource => 'Elige el origen';

  @override
  String get profileSetupGallery => 'Galería';

  @override
  String get profileSetupCamera => 'Cámara';

  @override
  String get profileSetupPhotoRequirements =>
      'JPEG, PNG, WebP o HEIC · mínimo 300×300 · 10 MB cada una · 50 MB en total';

  @override
  String profileSetupPhotosTipEmpty(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Añade al menos $min fotos para mostrar distintas facetas de ti.',
      one: 'Añade al menos 1 foto para mostrar distintas facetas de ti.',
    );
    return '$_temp0';
  }

  @override
  String profileSetupPhotosTipMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Añade $count fotos más para desbloquear todos los matches.',
      one: 'Añade 1 foto más para desbloquear todos los matches.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTipDone =>
      '¡Genial! Puedes reordenar las fotos arrastrándolas.';

  @override
  String get profileSetupYourPhotosHeading =>
      'Tus fotos  •  arrastra para reordenar';

  @override
  String get profileSetupContinueToAbout => 'Continuar a «Sobre mí»';

  @override
  String get profileSetupSavePhotos => 'Guardar fotos';

  @override
  String get profileSetupPrimaryPhoto => 'Foto principal';

  @override
  String profileSetupPhotoNumber(int number) {
    return 'Foto $number';
  }

  @override
  String get profileSetupShownFirst => 'Se muestra primero en tu perfil';

  @override
  String get profileSetupDragHandleHint => 'Arrastra el control para reordenar';

  @override
  String get profileSetupAwaitingSafetyReview =>
      'Pendiente de revisión de seguridad';

  @override
  String get profileSetupSafetyCheckInProgress =>
      'Comprobación de seguridad en curso';

  @override
  String get profileSetupSetAsProfilePicture => 'Usar como foto de perfil';

  @override
  String get profileSetupProfilePictureSelected =>
      'Foto de perfil seleccionada';

  @override
  String get profileSetupRemovePhotoTooltip => 'Quitar foto';

  @override
  String get profileSetupPhotoTooLarge =>
      'Esta foto supera el límite de 10 MB.';

  @override
  String get profileSetupPhotoUnsupportedType =>
      'Usa una foto JPEG, PNG, WebP o HEIC.';

  @override
  String get profileSetupPhotoBadDimensions =>
      'Las dimensiones de la foto deben estar entre 300×300 y 4096×4096.';

  @override
  String get profileSetupPhotoQuotaReached =>
      'Has alcanzado tu límite de fotos de perfil.';

  @override
  String get profileSetupPhotoStorageFull =>
      'El almacenamiento de fotos está lleno temporalmente. Inténtalo más tarde.';

  @override
  String get profileSetupPhotoUpdateFailed =>
      'No se pudo actualizar la foto. Inténtalo de nuevo.';

  @override
  String profileSetupPhotoMaxAllowed(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Se permite un máximo de $max fotos.',
      one: 'Se permite como máximo 1 foto.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPreferencesLoadFailed =>
      'No se pudieron cargar las preferencias';

  @override
  String get profileSetupOfflineBanner =>
      'Modo sin conexión — algunos datos pueden estar desactualizados.';

  @override
  String get profileSetupYourPreferences => 'Tus preferencias';

  @override
  String get profileSetupEditPreferencesTitle => 'Editar preferencias';

  @override
  String get profileSetupFinishAndFindMatches => 'Terminar y buscar matches';

  @override
  String get profileSetupSavePreferences => 'Guardar preferencias';

  @override
  String get profileSetupSelectGenderPreference =>
      'Selecciona al menos un género.';

  @override
  String get profileSetupFinishFailed =>
      'No se pudo completar la configuración. Revisa tus fotos y preferencias e inténtalo de nuevo.';

  @override
  String get profileSetupPreferencesSaveFailed =>
      'Algunas preferencias no se pudieron guardar ahora mismo.';

  @override
  String get profileSetupPreferencesSaved => 'Preferencias guardadas.';

  @override
  String get profileSetupTabBasic => 'Básico';

  @override
  String get profileSetupTabAdvanced => 'Avanzado';

  @override
  String get profileSetupLookingFor => 'Busco';

  @override
  String get profileSetupSeekingMen => 'Hombres';

  @override
  String get profileSetupSeekingWomen => 'Mujeres';

  @override
  String get profileSetupSeekingOther => 'Otros';

  @override
  String profileSetupAgeRangeTitle(int min, int max) {
    return 'Rango de edad: $min – $max';
  }

  @override
  String profileSetupMaxDistanceTitle(int km) {
    return 'Distancia máx.: $km km';
  }

  @override
  String profileSetupDistanceValue(int km) {
    return '$km km';
  }

  @override
  String get profileSetupRelationshipIntent => 'Tipo de relación';

  @override
  String get profileSetupSeriousOnly => 'Solo relación seria';

  @override
  String get profileSetupSeriousOnlySubtitle =>
      'Mostrar solo a quienes buscan compromiso';

  @override
  String get profileSetupVerifiedOnly => 'Solo perfiles verificados';

  @override
  String get profileSetupVerifiedOnlySubtitle =>
      'Solo cuentas con identidad verificada';

  @override
  String get profileSetupHookupsOnly => 'Solo encuentros casuales';

  @override
  String get profileSetupHookupsOnlySubtitle =>
      'Mostrar solo perfiles casuales';

  @override
  String get profileSetupLocation => 'Ubicación';

  @override
  String get profileSetupCountry => 'País';

  @override
  String get profileSetupStateRegion => 'Estado / Región';

  @override
  String get profileSetupCity => 'Ciudad';

  @override
  String get profileSetupBackgroundCulture => 'Origen y cultura';

  @override
  String get profileSetupReligionPreference => 'Religión';

  @override
  String get profileSetupMotherTongue => 'Lengua materna';

  @override
  String get profileSetupLanguage => 'Idioma';

  @override
  String get profileSetupDietPreference => 'Preferencia alimentaria';

  @override
  String get profileSetupWorkoutFrequency => 'Frecuencia de ejercicio';

  @override
  String get profileSetupDietType => 'Tipo de dieta';

  @override
  String get profileSetupSleepSchedule => 'Horario de sueño';

  @override
  String get profileSetupTravelStyle => 'Estilo de viaje';

  @override
  String get profileSetupPoliticalComfortRange => 'Afinidad política';

  @override
  String get profileSetupInterestsPersonality => 'Intereses y personalidad';

  @override
  String get profileSetupInstagramHandle => 'Usuario de Instagram (sin @)';

  @override
  String get profileSetupIntentTags =>
      'Intenciones (largo plazo, matrimonio, casual…)';

  @override
  String get profileSetupHobbiesField => 'Aficiones (separadas por comas)';

  @override
  String get profileSetupFavouriteBooksField =>
      'Libros favoritos (separados por comas)';

  @override
  String get profileSetupFavouriteNovelsField =>
      'Novelas favoritas (separadas por comas)';

  @override
  String get profileSetupFavouriteSongsField =>
      'Canciones favoritas (separadas por comas)';

  @override
  String get profileSetupExtraCurricularField =>
      'Actividades extracurriculares (separadas por comas)';

  @override
  String get profileSetupAdditionalInformation => 'Información adicional';

  @override
  String get profileSetupPetPreference => 'Mascotas';

  @override
  String get profileSetupDealBreakers => 'Innegociables';

  @override
  String get profileSetupTagsField => 'Etiquetas (separadas por comas)';

  @override
  String get profileSetupNameRequired => 'El nombre es obligatorio.';

  @override
  String get profileSetupDobRequired =>
      'La fecha de nacimiento es obligatoria.';

  @override
  String profileSetupPhotosRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Se necesitan al menos $min fotos.',
      one: 'Se necesita al menos 1 foto.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupServerError => 'Error del servidor';

  @override
  String get profileSetupNetworkError => 'Error de red — inténtalo de nuevo.';

  @override
  String get profileSetupGenericError => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get profileSetupPreviewTitle => 'Vista previa de tu perfil';

  @override
  String get profileSetupPreviewSubtitle => 'Así es como te verán los demás.';

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
    return 'Tabaco: $value';
  }

  @override
  String get profileSetupCompleteProfile => 'Completar perfil';

  @override
  String profileSetupCompletionPercent(int percent) {
    return 'Perfil completado: $percent %';
  }

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileEditRefreshTooltip => 'Actualizar perfil';

  @override
  String get profileEditAboutYou => 'Sobre ti';

  @override
  String get profileEditEditAbout => 'Editar «Sobre mí»';

  @override
  String get profileEditName => 'Nombre';

  @override
  String get profileEditPhone => 'Teléfono';

  @override
  String get profileEditDateOfBirth => 'Fecha de nacimiento';

  @override
  String get profileEditGender => 'Género';

  @override
  String get profileEditHeight => 'Altura';

  @override
  String get profileEditIncomeRange => 'Rango de ingresos';

  @override
  String get profileEditLocationSocial => 'Ubicación y redes';

  @override
  String get profileEditEditPreferences => 'Editar preferencias';

  @override
  String get profileEditState => 'Estado / Región';

  @override
  String get profileEditInstagram => 'Instagram';

  @override
  String get profileEditDatingPreferences => 'Preferencias de citas';

  @override
  String get profileEditSeeking => 'Busco';

  @override
  String get profileEditAgeRange => 'Rango de edad';

  @override
  String profileEditAgeRangeValue(int min, int max) {
    return '$min–$max';
  }

  @override
  String get profileEditMaxDistance => 'Distancia máx.';

  @override
  String get profileEditEducationFilter => 'Filtro de estudios';

  @override
  String get profileEditSeriousOnly => 'Solo en serio';

  @override
  String get profileEditVerifiedOnly => 'Solo verificados';

  @override
  String get profileEditHookupOnly => 'Solo casual';

  @override
  String get profileEditYes => 'Sí';

  @override
  String get profileEditNo => 'No';

  @override
  String get profileEditIntent => 'Intención';

  @override
  String get profileEditLanguages => 'Idiomas';

  @override
  String get profileEditDealBreakers => 'Innegociables';

  @override
  String get profileEditReligion => 'Religión';

  @override
  String get profileEditPets => 'Mascotas';

  @override
  String get profileEditWorkout => 'Ejercicio';

  @override
  String get profileEditPoliticsComfort => 'Afinidad política';

  @override
  String get profileEditInterestsDetails => 'Intereses y detalles';

  @override
  String get profileEditHobbies => 'Aficiones';

  @override
  String get profileEditBooks => 'Libros';

  @override
  String get profileEditNovels => 'Novelas';

  @override
  String get profileEditSongs => 'Canciones';

  @override
  String get profileEditExtraCurriculars => 'Actividades extracurriculares';

  @override
  String get profileEditAdditionalInfo => 'Información adicional';

  @override
  String get profileEditNotSet => 'Sin especificar';

  @override
  String get profileEditLoadingTitle => 'Cargando tu perfil guardado';

  @override
  String get profileEditLoadingBody =>
      'Recuperando la información guardada al crear la cuenta.';

  @override
  String get profileEditYourProfile => 'Tu perfil';

  @override
  String profileEditPercentComplete(int percent) {
    return '$percent % completado';
  }

  @override
  String get profileEditPhotoGallery => 'Galería de fotos';

  @override
  String get profileEditManagePhotos => 'Gestionar fotos';

  @override
  String get profileEditNoPhotos => 'Aún no has subido fotos.';

  @override
  String get profileEditPrimaryBadge => 'Principal';

  @override
  String get engagementHubPromptLoading => 'Cargando la pregunta de hoy';

  @override
  String get engagementHubPromptIntro =>
      'Responde una pregunta al día y alarga tu racha.';

  @override
  String engagementHubPromptRepliedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas han respondido hoy',
      one: '1 persona ha respondido hoy',
    );
    return '$_temp0';
  }

  @override
  String engagementHubPromptStreakSummary(int days, int similar) {
    return 'Racha $days d · respuestas parecidas: $similar';
  }

  @override
  String get engagementHubBlogTitle => 'Blog · Open Chapters';

  @override
  String get engagementHubBlogSubtitle =>
      'Lee historias, comparte fotos y escribe la tuya.';

  @override
  String get engagementHubPhotoThemesTitle => 'Temas de fotos';

  @override
  String get engagementHubPhotoThemesSubtitle =>
      'Comparte una foto por tema y mira las de los demás.';

  @override
  String get engagementHubClubsTitle => 'Clubs de libros y cine';

  @override
  String get engagementHubClubsSubtitle =>
      'Sigue la elección de la semana, coméntala y puntúala.';

  @override
  String get engagementHubCityPilotTitle => 'El piloto en tu ciudad';

  @override
  String get engagementHubCityPilotSubtitle =>
      'Una comunidad pequeña. Conversaciones que se convierten en planes.';

  @override
  String get engagementDailyPromptTitle => 'Racha de preguntas diarias';

  @override
  String get engagementHubVoiceTitle => 'Rompehielos de voz guiados';

  @override
  String get engagementHubVoiceSubtitle =>
      'Una intro de voz guiada de 20-45 s por match y día';

  @override
  String get engagementCirclesTitle => 'Retos de círculos locales';

  @override
  String get engagementHubCirclesSubtitle =>
      'Únete a un círculo de tu ciudad y envía tu participación de esta semana';

  @override
  String get engagementHubCoffeeTitle => 'Encuesta de café en grupo';

  @override
  String get engagementHubCoffeeSubtitle =>
      'Crea, vota y cierra encuestas sencillas para quedar';

  @override
  String get engagementHubGroupsTitle => 'Grupos';

  @override
  String get engagementHubGroupsSubtitle =>
      'Comunidades de estilo de vida y grupos privados de amigos';

  @override
  String get engagementHubRoomsSubtitle =>
      'Salas de chat en directo: entra, habla y haz amigos';

  @override
  String get engagementHubFriendsTitle => 'Amigos y presentaciones';

  @override
  String get engagementHubFriendsSubtitle =>
      'Invita a alguien de confianza, aunque no esté buscando pareja';

  @override
  String get engagementLevelTitle => 'Nivel y XP';

  @override
  String get engagementHubLevelSubtitle =>
      'Sigue tu actividad significativa, las recompensas de nivel y los requisitos de confianza';

  @override
  String get engagementHubPaywallFree =>
      'El progreso básico sigue sin muro de pago.';

  @override
  String get engagementHubPolicyUpdating =>
      'Estamos actualizando la política de monetización.';

  @override
  String engagementHubPremiumAreas(String features) {
    return 'Áreas premium opcionales: $features';
  }

  @override
  String get engagementHubEyebrow => 'PARTICIPAR';

  @override
  String get engagementHubTitle => 'Haced algo juntos.';

  @override
  String get engagementHubSubtitle =>
      'Matches más sólidos con confianza y actividades compartidas.';

  @override
  String get engagementHubSectionCreate => 'CREA Y COMPARTE';

  @override
  String get engagementHubSectionCreateCaption =>
      'Historias, fotos y clubs que inician conversaciones de verdad.';

  @override
  String get engagementHubSectionMeet => 'CONOCE GENTE';

  @override
  String get engagementHubSectionMeetCaption =>
      'Grupos pequeños, preguntas y planes a tu ritmo.';

  @override
  String get engagementHubSectionProgress => 'CONFIANZA Y PROGRESO';

  @override
  String get engagementHubSectionProgressCaption =>
      'Tu nivel, tus insignias y quién puede encontrarte.';

  @override
  String get engagementVoiceAppBarTitle => 'Una voz, un poco más cerca';

  @override
  String get engagementVoiceHeadline => 'Que tu hola\nsuene a ti.';

  @override
  String get engagementVoiceIntro =>
      'Una presentación opcional de 20 a 45 segundos que solo se comparte en esta conversación. El texto también es siempre bienvenido.';

  @override
  String engagementVoiceYouAndName(String name) {
    return 'Tú y $name';
  }

  @override
  String get engagementVoiceYouAndYourMatch => 'Tú y tu match';

  @override
  String get engagementVoicePrivate => 'Solo visible en esta conversación';

  @override
  String get engagementVoiceConversationsLoadFailed =>
      'No se han podido cargar tus conversaciones.';

  @override
  String get engagementVoiceNoMatches =>
      'Cuando tengas un match, podrás compartir aquí una presentación de voz. Sin prisa.';

  @override
  String get engagementVoicePickConversation => '¿A quién quieres saludar?';

  @override
  String get engagementVoiceStartingPoint => 'Un pequeño punto de partida';

  @override
  String get engagementVoiceChoosePrompt => 'Elige una pregunta';

  @override
  String get engagementVoiceTranscriptLabel => 'Tus palabras, por escrito';

  @override
  String get engagementVoiceTranscriptHelper =>
      'Escribe lo que dices para que también se pueda leer. No es una transcripción automática.';

  @override
  String engagementVoiceStop(int seconds) {
    return 'Detener · $seconds s';
  }

  @override
  String get engagementVoiceRecord => 'Graba tu hola';

  @override
  String engagementVoiceRecordAgain(int seconds) {
    return 'Volver a grabar · $seconds s';
  }

  @override
  String get engagementVoiceRecordingReady =>
      'Grabación lista. Revisa tu texto antes de enviarlo.';

  @override
  String get engagementVoiceRecordingShort =>
      'Ha sido un poco corto. Graba entre 20 y 45 segundos.';

  @override
  String get engagementVoiceDiscard => 'Descartar grabación';

  @override
  String get engagementVoiceSubmitted =>
      'Presentación enviada. Las grabaciones aprobadas aparecen abajo.';

  @override
  String get engagementVoiceSending => 'Enviando…';

  @override
  String get engagementVoiceShare => 'Comparte tu hola';

  @override
  String get engagementVoiceCheckedNote =>
      'Las grabaciones se revisan antes de compartirse. No hay reproducción automática.';

  @override
  String get engagementVoiceYourIntros => 'Vuestras presentaciones de voz';

  @override
  String get engagementVoiceLatestNote =>
      'Las últimas 20 grabaciones aprobadas de esta conversación. Los textos siempre se pueden leer.';

  @override
  String get engagementVoiceIntrosLoadFailed =>
      'No se han podido cargar las presentaciones. Puede que la conversación ya no esté disponible.';

  @override
  String get engagementVoiceNothingYet =>
      'Aún no hay nada. Un simple hola es un buen comienzo.';

  @override
  String get engagementVoiceYourHello => 'Tu hola';

  @override
  String engagementVoiceHelloFromName(String name) {
    return 'Un hola de $name';
  }

  @override
  String get engagementVoiceHelloFromYourMatch => 'Un hola de tu match';

  @override
  String get engagementVoiceTranscriptHeading => 'TEXTO';

  @override
  String get engagementVoiceStopPlayback => 'Detener reproducción';

  @override
  String engagementVoiceListen(int seconds) {
    return 'Escuchar · $seconds s';
  }

  @override
  String get engagementVoiceReloadPrompts => 'Volver a cargar preguntas';

  @override
  String get engagementVoiceMicPermission =>
      'Permite el acceso al micrófono para grabar. Puedes leer los textos igualmente.';

  @override
  String get engagementVoiceStartFailed =>
      'No se ha podido empezar a grabar. Revisa el acceso al micrófono e inténtalo de nuevo.';

  @override
  String get engagementVoiceSaveFailed =>
      'No se ha podido guardar la grabación. Inténtalo de nuevo.';

  @override
  String get engagementVoicePromptsLoadFailed =>
      'Ahora mismo no se pueden cargar las preguntas de voz.';

  @override
  String get engagementSessionUnavailable => 'La sesión no está disponible.';

  @override
  String get engagementVoiceChooseConversation =>
      'Elige primero una conversación.';

  @override
  String get engagementVoiceSelectPrompt => 'Elige una pregunta de voz.';

  @override
  String get engagementVoiceEnterTranscript => 'Escribe el texto.';

  @override
  String get engagementVoiceSessionFailed =>
      'No se ha podido crear la sesión de rompehielos de voz.';

  @override
  String get engagementVoiceSendFailed =>
      'Ahora mismo no se puede enviar el rompehielos de voz.';

  @override
  String get engagementVoicePlaybackUserRequired =>
      'Se necesita un ID de usuario para registrar la reproducción.';

  @override
  String get engagementVoiceMarkPlaybackFailed =>
      'Ahora mismo no se puede registrar la reproducción.';

  @override
  String get engagementVoicePlayFailed =>
      'Ahora mismo no se puede reproducir esta grabación.';

  @override
  String get chatStarterSmile => '¿Qué te ha hecho sonreír hoy?';

  @override
  String get chatStarterSunday => 'Tu domingo ideal: cuéntame.';

  @override
  String get chatStarterCoffee => '¿Un café, un paseo o una pequeña aventura?';

  @override
  String get chatWelcomeTitle => 'Toda buena historia\nempieza con un hola.';

  @override
  String get chatWelcomePending =>
      'La conversación se abrirá cuando se confirme el match.';

  @override
  String get chatWelcomeBody => 'No hace falta la frase perfecta. Sé tú.';

  @override
  String get chatInspirationEyebrow => 'UN POCO DE INSPIRACIÓN';

  @override
  String get chatAllConversations => 'Todas las conversaciones';

  @override
  String get chatMakeConnectionEyebrow => 'CREA UNA CONEXIÓN';

  @override
  String get chatLessSmallTalk => 'Un poco menos de charla trivial.';

  @override
  String get chatLessSmallTalkBody =>
      'Pregunta por lo que le apasiona. Comparte algo que sea muy tuyo.';

  @override
  String get chatFindTheWords => 'Encontrar las palabras';

  @override
  String get chatSendJoy => 'Envía un poco de alegría';

  @override
  String get chatPaceTitle => 'Tu ritmo. Tu espacio.';

  @override
  String get chatPaceBody =>
      'Comparte solo lo que te resulte cómodo. Una buena conexión respeta tus límites.';

  @override
  String get chatWriteMessageHint => 'Escribe un mensaje…';

  @override
  String get chatConversationPaused => 'Conversación en pausa';

  @override
  String get chatSendingMessageTooltip => 'Enviando mensaje';

  @override
  String get chatSendMessageTooltip => 'Enviar mensaje';

  @override
  String get chatSendGiftTooltip => 'Enviar un regalo';

  @override
  String get chatAddEmojiTooltip => 'Añadir un emoji';

  @override
  String get chatDraftedWithHelp => 'Redactado con ayuda';

  @override
  String get chatHelpMeSayIt => 'Ayúdame a decirlo';

  @override
  String get chatEnterToSendHint =>
      'Intro para enviar · Mayús + Intro para nueva línea';

  @override
  String get chatToday => 'Hoy';

  @override
  String get chatYesterday => 'Ayer';

  @override
  String get chatGiftOptions => 'Opciones del regalo';

  @override
  String get chatStatusRead => 'Leído';

  @override
  String get chatStatusDelivered => 'Entregado';

  @override
  String get chatStatusSent => 'Enviado';

  @override
  String get chatGestureGiftHeading => 'Gesto + rosa de regalo';

  @override
  String get chatGiftForYouHeading => 'Un detallito para ti';

  @override
  String chatGiftTone(String tone) {
    return 'Tono: $tone';
  }

  @override
  String get chatFreeGift => 'Regalo gratis';

  @override
  String get chatCopilotKindOpener => 'Primer mensaje';

  @override
  String get chatCopilotKindReply => 'Respuesta';

  @override
  String get chatCopilotKindDateIdea => 'Idea de cita';

  @override
  String get chatCopilotToneWarm => 'Cálido';

  @override
  String get chatCopilotTonePlayful => 'Divertido';

  @override
  String get chatCopilotToneDirect => 'Directo';

  @override
  String chatCopilotIntro(String name) {
    return 'Un borrador con tu estilo, a partir del perfil de $name y vuestra conversación. Nunca se envía por ti, y si lo envías tal cual, verá que se escribió con ayuda.';
  }

  @override
  String chatCopilotDisclosure(String disclosure, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te quedan $count borradores hoy.',
      one: 'Te queda 1 borrador hoy.',
    );
    return '$disclosure $_temp0';
  }

  @override
  String get chatCopilotDraftIt => 'Redactarlo';

  @override
  String get chatCopilotTryAnother => 'Probar otro';

  @override
  String get chatCopilotUseAndEdit => 'Usar y editar';

  @override
  String get chatCopilotEmpty => 'El copiloto no ha devuelto nada.';

  @override
  String get chatCopilotUnavailable => 'El copiloto no está disponible.';

  @override
  String get chatErrorMatchEnded => 'Este match ha terminado.';

  @override
  String get chatErrorLoadMessages =>
      'No se pudieron cargar los mensajes. Inténtalo de nuevo.';

  @override
  String get chatErrorLockedQuest =>
      'El chat está bloqueado hasta que se apruebe el reto.';

  @override
  String get chatErrorSendFailed => 'No se pudo enviar el mensaje.';

  @override
  String get chatErrorDeleteFailed => 'No se pudo eliminar el mensaje.';

  @override
  String get chatErrorDeleteWindowExpired =>
      'El plazo para eliminar ha vencido (24 h).';

  @override
  String get chatErrorOnlyReceivedGifts =>
      'Solo se pueden gestionar los regalos recibidos.';

  @override
  String get chatErrorGiftGone => 'Este regalo ya no está disponible.';

  @override
  String get chatErrorGiftReportFailed =>
      'No se pudo denunciar este regalo. Inténtalo de nuevo.';

  @override
  String get chatErrorGiftHideFailed =>
      'No se pudo ocultar este regalo. Inténtalo de nuevo.';

  @override
  String get chatErrorGiftsUnavailable =>
      'Los regalos de rosas no están disponibles ahora mismo.';

  @override
  String chatErrorNotEnoughCoins(String gift) {
    return 'No tienes monedas suficientes para enviar $gift.';
  }

  @override
  String get chatErrorNotEnoughCoinsSelected =>
      'No tienes monedas suficientes para el regalo elegido.';

  @override
  String get chatErrorWalletFrozen =>
      'Tus monedas están retenidas mientras revisamos una compra reembolsada. Los regalos gratis siguen disponibles.';

  @override
  String get chatErrorGiftVelocity =>
      'Has enviado muchos regalos en poco tiempo. Inténtalo más tarde.';

  @override
  String get chatErrorFreeGiftUsed =>
      'Ya has enviado el regalo gratis de hoy. Habrá otro después de medianoche UTC.';

  @override
  String chatErrorGiftNotAvailable(String gift) {
    return '$gift no está disponible ahora mismo.';
  }

  @override
  String get chatErrorGiftNeedsActiveMatch =>
      'Solo puedes enviar regalos en un match activo.';

  @override
  String get chatErrorExclusiveGiftOnce =>
      'Este regalo exclusivo solo se puede enviar una vez hoy.';

  @override
  String get chatErrorGiftFailed => 'No se pudo enviar el regalo.';

  @override
  String get chatErrorSessionUnavailable => 'La sesión no está disponible.';

  @override
  String get chatErrorConversationUnavailable => 'Conversación no disponible.';

  @override
  String get verificationLandingTitle => 'Verifícate con confianza';

  @override
  String get verificationLandingBody =>
      'Sube un documento de identidad oficial legible y un selfie reciente. Los archivos se envían cifrados y se guardan en un área privada de pruebas.';

  @override
  String get verificationLandingDisclaimer =>
      'La revisión añade contexto a tu perfil. Nunca garantiza la identidad, las intenciones ni la seguridad de otra persona.';

  @override
  String get verificationViewVerifiedStatus => 'Ver estado verificado';

  @override
  String get verificationViewReviewStatus => 'Ver estado de la revisión';

  @override
  String get verificationStartButton => 'Iniciar verificación segura';

  @override
  String get verificationUploadIdTitle => 'Subir documento';

  @override
  String get verificationUploadIdInstruction =>
      'Haz o sube una foto nítida de tu documento de identidad oficial.';

  @override
  String get verificationGallery => 'Galería';

  @override
  String get verificationCamera => 'Cámara';

  @override
  String get verificationNext => 'Siguiente';

  @override
  String get verificationSelfieTitle => 'Selfie';

  @override
  String get verificationSelfieInstruction => 'Hazte un selfie nítido.';

  @override
  String get verificationUploadFailed =>
      'No pudimos subir tus pruebas. Revisa los archivos e inténtalo de nuevo.';

  @override
  String get verificationSubmit => 'Enviar';

  @override
  String get verificationStatusTitle => 'Estado de verificación';

  @override
  String get verificationRetry => 'Reintentar';

  @override
  String get verificationStatusVerified => 'Verificado';

  @override
  String get verificationStatusVerifiedMessage =>
      'Tu verificación se ha completado.';

  @override
  String get verificationStatusRejected => 'Rechazado';

  @override
  String get verificationStatusRejectedFallback => 'Inténtalo de nuevo.';

  @override
  String get verificationStatusPending => 'Pendiente';

  @override
  String get verificationStatusPendingMessage => 'Revisión en curso.';

  @override
  String get verificationStatusNotStarted => 'Sin iniciar';

  @override
  String get verificationStatusNotStartedMessage =>
      'Inicia la verificación desde Ajustes.';

  @override
  String get safetySosTitle => 'SOS de emergencia';

  @override
  String get safetySosDefaultMessage =>
      'Necesito ayuda inmediata. Por favor, comprobad que estoy bien.';

  @override
  String get safetySosHeadline => 'Activar una alerta de emergencia';

  @override
  String get safetySosIntro =>
      'Si estás en peligro inmediato, contacta primero con los servicios de emergencia locales. Esta alerta queda registrada para el equipo de seguridad.';

  @override
  String get safetySosLevelUrgent => 'Urgente';

  @override
  String get safetySosLevelCritical => 'Crítico';

  @override
  String get safetySosMessageLabel => 'Mensaje para el equipo de seguridad';

  @override
  String get safetySosActivating => 'Activando…';

  @override
  String get safetySosActivate => 'Activar SOS';

  @override
  String get safetySosLocationNote =>
      'La ubicación solo se solicita para esta alerta. Puedes continuar aunque deniegues el permiso.';

  @override
  String get safetySosHistoryTitle => 'Historial de alertas';

  @override
  String get safetySosHistoryEmpty => 'No hay alertas SOS registradas.';

  @override
  String safetySosHistoryHeading(String level, String status) {
    return '$level · $status';
  }

  @override
  String get safetySosAlertLevelLow => 'BAJO';

  @override
  String get safetySosAlertLevelMedium => 'MEDIO';

  @override
  String get safetySosAlertLevelHigh => 'ALTO';

  @override
  String get safetySosAlertLevelCritical => 'CRÍTICO';

  @override
  String get safetySosAlertStatusOpen => 'abierta';

  @override
  String get safetySosAlertStatusActive => 'activa';

  @override
  String get safetySosAlertStatusAcknowledged => 'recibida';

  @override
  String get safetySosAlertStatusResolved => 'resuelta';

  @override
  String safetySosHistoryMetaWithLocation(String date) {
    return '$date · con ubicación';
  }

  @override
  String safetySosHistoryMetaNoLocation(String date) {
    return '$date · sin ubicación';
  }

  @override
  String safetySosResolution(String note) {
    return 'Resolución: $note';
  }

  @override
  String get safetySosConfirmTitle => '¿Activar SOS ahora?';

  @override
  String get safetySosConfirmBody =>
      'Esto crea una alerta de emergencia para el equipo de seguridad e intenta adjuntar tu ubicación actual.';

  @override
  String get safetySosCancel => 'Cancelar';

  @override
  String get safetySosConfirmActivate => 'Activar';

  @override
  String get safetySosActivatedTitle => 'Alerta SOS activada';

  @override
  String get safetySosActivatedWithLocation =>
      'Se han registrado tu alerta y tu ubicación actual.';

  @override
  String get safetySosActivatedWithoutLocation =>
      'Tu alerta se ha registrado sin ubicación. El permiso de ubicación no estaba disponible o se denegó.';

  @override
  String get safetySosDone => 'Listo';

  @override
  String get safetySosSignInToView =>
      'Inicia sesión para ver el historial de SOS.';

  @override
  String get safetySosLoadFailed => 'No se pudo cargar el historial de SOS.';

  @override
  String get safetySosSignInToActivate =>
      'Inicia sesión antes de activar el SOS.';

  @override
  String get safetySosActivateFailed => 'No se pudo activar el SOS.';

  @override
  String get photoThemesTitle => 'Temas de fotos';

  @override
  String get photoThemesSignIn => 'Inicia sesión para ver los temas de fotos.';

  @override
  String get photoThemesHeroTitle => 'Muestra un poco de tu mundo';

  @override
  String get photoThemesHeroSubtitle =>
      'Elige un tema, comparte una foto y mira cómo han respondido los demás. Es una forma fácil de empezar una conversación.';

  @override
  String get photoThemesLoadFailed => 'No se pudieron cargar los temas';

  @override
  String get photoThemesCheckConnection => 'Comprueba tu conexión.';

  @override
  String get photoThemesLookAround => 'Puedes echar un vistazo';

  @override
  String get photoThemesEligibilityShareOwn =>
      'Completa tu perfil con dos fotos aprobadas para compartir las tuyas.';

  @override
  String get photoThemesNewPromptsTitle => 'Pronto habrá nuevos temas';

  @override
  String get photoThemesNewPromptsBody =>
      'Vuelve pronto para encontrar algo que compartir.';

  @override
  String photoThemesSharedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compartidas',
      one: '$count compartida',
    );
    return '$_temp0';
  }

  @override
  String get photoThemesYouShared => 'Has compartido ✓';

  @override
  String get photoThemesBeFirst => 'Sé el primero en compartir →';

  @override
  String get photoThemesSeeEveryone => 'Ver las fotos de todos →';

  @override
  String get photoThemesSharedSnack => 'Tu foto se ha compartido. ¡Genial!';

  @override
  String get photoThemesShareFailed =>
      'No se pudo compartir tu foto. Usa un JPEG o PNG de hasta 10 MB.';

  @override
  String get photoThemesEligibilityShare =>
      'Completa tu perfil con dos fotos aprobadas para compartir.';

  @override
  String get photoThemesAlreadyShared =>
      'Ya has compartido en este tema. Elimina tu foto para compartir otra.';

  @override
  String get photoThemesThemeFallback => 'Tema de fotos';

  @override
  String get photoThemesShareTooltip => 'Comparte una foto para este tema';

  @override
  String get photoThemesShareYourPhoto => 'Comparte tu foto';

  @override
  String get photoThemesNoPhotosYet => 'Todavía no hay fotos';

  @override
  String photoThemesBeFirstFor(String title) {
    return 'Sé el primero en compartir en «$title»';
  }

  @override
  String get photoThemesLoadingPrompt => 'Cargando el tema…';

  @override
  String get photoThemesPhotosLoadFailed => 'No se pudieron cargar las fotos';

  @override
  String get photoThemesEmptyMessage =>
      'Tu foto podría ser la que haga hablar a todos.';

  @override
  String get photoThemesMoreFailed =>
      'No se pudieron cargar más fotos. Recargar';

  @override
  String get photoThemesLoadMore => 'Cargar más';

  @override
  String get photoThemesPhotoUnavailable => 'Foto no disponible. Reintentar';

  @override
  String photoThemesOpenPhoto(String name) {
    return 'Abrir la foto de $name';
  }

  @override
  String get photoThemesYou => 'Tú';

  @override
  String get photoThemesWallHelp =>
      'Si a los miembros les encanta, tu foto puede llegar a sus muros de Today: 50 me gusta y 5 comentarios llegan a 50 muros; 100 me gusta y 10 comentarios, a 100. Puedes desactivarlo cuando quieras.';

  @override
  String get photoThemesRemoveTitle => '¿Quitar tu foto?';

  @override
  String get photoThemesRemoveMessage =>
      'Desaparecerá de este tema para todos. Después podrás compartir otra.';

  @override
  String get photoThemesRemoveAction => 'Quitar foto';

  @override
  String get photoThemesRemoveFailed => 'No se pudo quitar tu foto.';

  @override
  String get photoThemesReachOn =>
      'Ahora tu foto puede llegar a los muros de los miembros cuando les encante.';

  @override
  String get photoThemesReachOff => 'Tu foto ya no está en ningún muro.';

  @override
  String get photoThemesSharedByYou => 'Compartida por ti';

  @override
  String photoThemesSharedBy(String name) {
    return 'Compartida por $name';
  }

  @override
  String photoThemesPhotoDescription(String text) {
    return 'Descripción de la foto: $text';
  }

  @override
  String get photoThemesReachSwitch =>
      'Dejar que llegue a los muros de otros miembros';

  @override
  String get photoThemesReachIdle =>
      'Los miembros pueden llevar esta foto más lejos';

  @override
  String get photoThemesReachLive =>
      'Hay miembros viéndola ahora en sus muros de Today.';

  @override
  String get photoThemesRemoveMine => 'Quitar mi foto';

  @override
  String get photoThemesReport => 'Denunciar';

  @override
  String photoThemesBlock(String name) {
    return 'Bloquear a $name';
  }

  @override
  String get photoThemesCommentHint => '¿Qué te hace pensar?';

  @override
  String get photoThemesCommentApproved =>
      'Aprobado. Ahora lo ve todo el que puede ver esta foto.';

  @override
  String get photoThemesDetailsTitle => 'Cuéntanos';

  @override
  String get photoThemesCaption => 'Pie de foto';

  @override
  String get photoThemesCaptionHint => 'Tortitas y ningún sitio al que ir.';

  @override
  String get photoThemesDescribe => 'Describe la foto';

  @override
  String get photoThemesDescribeHelper =>
      'Ayuda a los miembros que usan un lector de pantalla.';

  @override
  String get photoThemesShare => 'Compartir';

  @override
  String get photoThemesWallTitle => 'Portadas en tu muro';

  @override
  String get photoThemesWallCaption =>
      'Fotos que les encantaron a otros miembros';

  @override
  String get photoThemesMasthead => 'TEMAS DE FOTOS';

  @override
  String photoThemesByline(String name) {
    return 'POR $name';
  }

  @override
  String get photoThemesLikes => 'Me gusta';

  @override
  String get photoThemesComments => 'Comentarios';

  @override
  String get photoThemesCancel => 'Cancelar';

  @override
  String get photoThemesTryAgain => 'Reintentar';

  @override
  String get photoThemesSaveFailed => 'No se ha guardado. Inténtalo de nuevo.';

  @override
  String get friendsChatEmpty =>
      'Saluda. Solo vosotros dos podéis ver esta conversación.';

  @override
  String get friendsChatOpenFailed =>
      'No se pudo abrir el chat. Inténtalo de nuevo.';

  @override
  String get friendsCancelRequestTitle => '¿Cancelar tu solicitud de amistad?';

  @override
  String friendsCancelRequestBody(String name) {
    return '$name ya no verá tu solicitud.';
  }

  @override
  String get friendsCancelRequestBodyUnnamed =>
      'Este miembro ya no verá tu solicitud.';

  @override
  String get friendsKeepIt => 'Mantenerla';

  @override
  String get friendsCancelRequest => 'Cancelar solicitud';

  @override
  String friendsNowFriends(String name) {
    return '$name y tú ya sois amigos.';
  }

  @override
  String get friendsNowFriendsUnnamed => 'Este miembro y tú ya sois amigos.';

  @override
  String friendsRequestSentTo(String name) {
    return 'Solicitud de amistad enviada a $name.';
  }

  @override
  String get friendsRequestSentToUnnamed =>
      'Solicitud de amistad enviada a este miembro.';

  @override
  String get friendsRequestCancelled => 'Solicitud cancelada.';

  @override
  String get friendsRequestFailed => 'No se pudo enviar la solicitud.';

  @override
  String get friendsAddCaption =>
      'Los amigos pueden escribirse y hacer planes juntos';

  @override
  String get friendsRequested => 'Solicitado';

  @override
  String friendsWaitingFor(String name) {
    return 'Esperando a $name. Toca para cancelar.';
  }

  @override
  String get friendsWaitingForUnnamed =>
      'Esperando a este miembro. Toca para cancelar.';

  @override
  String get friendsAcceptFriend => 'Aceptar amistad';

  @override
  String friendsAskedToBeFriends(String name) {
    return '$name quiere ser tu amigo';
  }

  @override
  String get friendsAskedToBeFriendsUnnamed =>
      'Este miembro quiere ser tu amigo';

  @override
  String get friendsMessage => 'Escribir';

  @override
  String get friendsYoureFriends => 'Sois amigos. Abre vuestro chat.';

  @override
  String friendsVouchTooShort(int min) {
    return 'Cuenta un poco más (al menos $min caracteres).';
  }

  @override
  String friendsVouchTitle(String name) {
    return 'Avalar a $name';
  }

  @override
  String get friendsVouchBody =>
      'Una o dos frases sobre por qué alguien tendría suerte de conocer a esta persona. Lo aprueba antes de que aparezca en su perfil, con tu nombre.';

  @override
  String get friendsVouchLabel => 'Tu aval';

  @override
  String get friendsVouchHint => 'Amable, divertido y siempre puntual.';

  @override
  String get friendsVouchSend => 'Enviar aval';

  @override
  String get friendsIntroChooseTwo => 'Elige a dos amigos distintos.';

  @override
  String get friendsIntroSheetTitle => 'Presentar a dos amigos';

  @override
  String get friendsIntroSheetBody =>
      'Ambos amigos tienen que permitir las presentaciones. Cada uno controla su vista previa y decide en privado. Comparte solo un motivo que tengas permiso para mencionar. Sus decisiones y si hay match quedan en privado.';

  @override
  String get friendsIntroNeedTwo =>
      'Necesitas al menos dos amigos aceptados para hacer una presentación.';

  @override
  String get friendsFirstFriend => 'Primer amigo';

  @override
  String get friendsSecondFriend => 'Segundo amigo';

  @override
  String get friendsIntroWhyLabel => 'Por qué deberían conocerse (opcional)';

  @override
  String get friendsIntroSubmit => 'Hacer la presentación';

  @override
  String get friendsLoadFailed =>
      'No se pudieron cargar tus amigos. Inténtalo de nuevo.';

  @override
  String get friendsAddFailed => 'No se pudo añadir al amigo.';

  @override
  String get friendsRemoveFailed => 'No se pudo quitar al amigo.';

  @override
  String get friendsRespondFailed =>
      'No se pudo responder a la solicitud de amistad.';

  @override
  String get friendsSocialLoadFailed =>
      'No se pudieron cargar los avales y las presentaciones.';

  @override
  String get friendsVouchSendFailed => 'No se pudo enviar este aval.';

  @override
  String get friendsVouchUpdateFailed => 'No se pudo actualizar este aval.';

  @override
  String get friendsVouchWithdrawFailed => 'No se pudo retirar este aval.';

  @override
  String get friendsIntroMakeFailed => 'No se pudo hacer esta presentación.';

  @override
  String get friendsIntroAnswerFailed =>
      'No se pudo responder a esta presentación.';

  @override
  String get groupsEyebrow => 'GRUPOS';

  @override
  String get groupsTitle => 'Encuentra a tu gente.';

  @override
  String get groupsSubtitle =>
      'Comunidades por estilo de vida a las que cualquiera puede unirse, y grupos privados solo para tus amigos.';

  @override
  String get groupsStartGroup => 'Crear un grupo';

  @override
  String get groupsInvitationsHeader => 'INVITACIONES';

  @override
  String get groupsInvitationsCaption => 'Tus amigos te invitan a unirte.';

  @override
  String get groupsAnswerFailed => 'No se pudo guardar tu respuesta.';

  @override
  String groupsWelcome(String name) {
    return '¡Ya eres parte de $name!';
  }

  @override
  String get groupsInvitationDeclined => 'Invitación rechazada.';

  @override
  String get groupsYourGroupsHeader => 'TUS GRUPOS';

  @override
  String get groupsYourGroupsFailed => 'No se pudieron cargar tus grupos';

  @override
  String get groupsErrorCheckConnection => 'Comprueba tu conexión.';

  @override
  String get groupsEmptyTitle => 'Aún no hay grupos';

  @override
  String get groupsEmptyBody =>
      'Únete a una comunidad de abajo o crea un grupo privado con tus amigos.';

  @override
  String get groupsDiscoverHeader => 'DESCUBRE POR ESTILO DE VIDA';

  @override
  String get groupsDiscoverCaption =>
      'Los grupos de comunidad están abiertos a todos.';

  @override
  String get groupsLifestylesFailed =>
      'No se pudieron cargar los estilos de vida';

  @override
  String get groupsCategoryAll => 'Todos';

  @override
  String get groupsDiscoverFailed => 'No se pudieron cargar los grupos';

  @override
  String get groupsDiscoverEmptyTitle => 'Nada nuevo a lo que unirse';

  @override
  String groupsDiscoverEmptyCategoryTitle(String category) {
    return 'Aún no hay grupos de $category';
  }

  @override
  String get groupsDiscoverEmptyBody =>
      'Da el primer paso: crea un grupo de comunidad e invita a tus amigos.';

  @override
  String get groupsStartOne => 'Crear uno';

  @override
  String get groupsJoinFailed => 'No has podido unirte ahora mismo.';

  @override
  String get groupsJoin => 'Unirse';

  @override
  String groupsJoinNamed(String name) {
    return 'Unirse a $name';
  }

  @override
  String groupsInvitedBy(String name, String kind, String members) {
    return '$name te ha invitado · $kind · $members';
  }

  @override
  String groupsInvitedByFriend(String kind, String members) {
    return 'Un amigo te ha invitado · $kind · $members';
  }

  @override
  String get groupsDecline => 'Rechazar';

  @override
  String groupsDeclineNamed(String name) {
    return 'Rechazar $name';
  }

  @override
  String groupsChatEmpty(String name) {
    return 'Saluda al grupo. Todos en $name pueden ver los mensajes aquí.';
  }

  @override
  String groupsInviteFriendsTo(String name) {
    return 'Invitar amigos a $name';
  }

  @override
  String get groupsSendInvitations => 'Enviar invitaciones';

  @override
  String get groupsInvitationsFailed =>
      'No se pudieron enviar las invitaciones.';

  @override
  String groupsInvitationSentTo(String name) {
    return 'Invitación enviada a $name.';
  }

  @override
  String groupsInvitationsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invitaciones enviadas.',
      one: '1 invitación enviada.',
    );
    return '$_temp0';
  }

  @override
  String groupsLeaveTitle(String name) {
    return '¿Salir de $name?';
  }

  @override
  String get groupsLeaveBodyAlone =>
      'Eres el único miembro, así que el grupo y su chat se eliminarán.';

  @override
  String get groupsLeaveBodyOwner =>
      'La propiedad pasará a tu moderador más antiguo o, si no hay, al miembro más antiguo. Perderás el acceso al chat.';

  @override
  String get groupsLeaveBodyCommunity =>
      'Perderás el acceso al chat del grupo. Puedes volver a unirte más adelante.';

  @override
  String get groupsLeaveBodyPrivate =>
      'Perderás el acceso al chat del grupo. Necesitarás una nueva invitación para volver.';

  @override
  String get groupsLeave => 'Salir';

  @override
  String get groupsLeaveFailed => 'No has podido salir ahora mismo.';

  @override
  String get groupsCoverUploadFailed =>
      'No se pudo subir tu foto de portada. Usa un JPEG o PNG de hasta 10 MB.';

  @override
  String get groupsRemoveCoverTitle => '¿Quitar la foto de portada?';

  @override
  String groupsRemoveCoverBody(String name) {
    return '$name volverá a mostrar su portada con emoji.';
  }

  @override
  String get groupsRemove => 'Quitar';

  @override
  String get groupsRemoveCoverFailed => 'No se pudo quitar la foto de portada.';

  @override
  String get groupsCoverRemoved => 'Foto de portada quitada.';

  @override
  String groupsDeleteTitle(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get groupsDeleteBody =>
      'El grupo, sus invitaciones y su chat se eliminarán para todos. No se puede deshacer.';

  @override
  String get groupsDeleteGroup => 'Eliminar grupo';

  @override
  String get groupsDeleteFailed => 'No se pudo eliminar el grupo.';

  @override
  String get groupsDetailEyebrow => 'GRUPO';

  @override
  String get groupsDetailTitleFallback => 'Grupo';

  @override
  String get groupsOwnerTools => 'Herramientas de propietario';

  @override
  String get groupsEditGroup => 'Editar grupo';

  @override
  String get groupsAddCoverPhoto => 'Añadir foto de portada';

  @override
  String get groupsChangeCoverPhoto => 'Cambiar foto de portada';

  @override
  String get groupsRemoveCoverPhoto => 'Quitar foto de portada';

  @override
  String get groupsMoreOptions => 'Más opciones';

  @override
  String get groupsReportGroup => 'Denunciar grupo';

  @override
  String get groupsUnavailableTitle => 'Este grupo no está disponible';

  @override
  String get groupsUnavailableBody =>
      'Puede que se haya eliminado o que ya no tengas acceso.';

  @override
  String get groupsOpenToAll => 'Abierto a todos';

  @override
  String get groupsPrivate => 'Privado';

  @override
  String get groupsYouRunIt => 'Lo gestionas tú';

  @override
  String get groupsYouModerate => 'Moderas tú';

  @override
  String get groupsCoverNotePending =>
      'Solo tú puedes ver esta foto hasta que se apruebe. Mientras tanto, los miembros ven la portada con emoji.';

  @override
  String get groupsCoverNoteRejected =>
      'Tu última foto de portada no se aprobó. Elige otra.';

  @override
  String get groupsCoverUnderReview => 'En revisión';

  @override
  String get groupsChangeCover => 'Cambiar portada';

  @override
  String get groupsRemoveCover => 'Quitar portada';

  @override
  String get groupsRemovedTitle => 'Este grupo se retiró tras una revisión';

  @override
  String get groupsRemovedBodyOwner =>
      'Mientras esté retirado, los miembros no pueden chatear, unirse ni invitar. Tus avisos de revisión explican la decisión y te permiten apelar.';

  @override
  String get groupsRemovedBodyMember =>
      'Mientras esté retirado, los miembros no pueden chatear, unirse ni invitar. Puedes salir del grupo cuando quieras.';

  @override
  String get groupsMembers => 'Miembros';

  @override
  String get groupsChatButton => 'Chat del grupo';

  @override
  String groupsChatButtonUnread(int count) {
    return 'Chat del grupo · $count sin leer';
  }

  @override
  String get groupsInviteFriends => 'Invitar amigos';

  @override
  String get groupsWhosHere => 'QUIÉN ESTÁ';

  @override
  String get groupsSeeAll => 'Ver todos';

  @override
  String get groupsYou => 'Tú';

  @override
  String groupsInvitedToJoin(String name) {
    return 'Te han invitado a unirte a $name.';
  }

  @override
  String get groupsJoinGroup => 'Unirse al grupo';

  @override
  String get groupsJoinHint => 'Los miembros ven quién está y chatean juntos.';

  @override
  String get groupsCantJoinTitle => 'No puedes unirte a este grupo';

  @override
  String get groupsCantJoinBody =>
      'Puede que esté lleno o que un moderador te haya expulsado.';

  @override
  String get groupsInvitationOnly => 'Solo con invitación';

  @override
  String get groupsInvitationOnlyBody =>
      'Un miembro puede invitarte a este grupo privado.';

  @override
  String get groupsMakeModerator => 'Hacer moderador';

  @override
  String get groupsMakeMember => 'Hacer miembro';

  @override
  String get groupsRemoveFromGroup => 'Expulsar del grupo';

  @override
  String groupsRemoveMemberTitle(String name) {
    return '¿Expulsar a $name?';
  }

  @override
  String get groupsRemoveMemberBodyCommunity =>
      'Saldrá del grupo y de su chat, y no podrá volver a unirse por su cuenta.';

  @override
  String get groupsRemoveMemberBodyPrivate => 'Saldrá del grupo y de su chat.';

  @override
  String get groupsChangeFailed => 'No se pudo guardar el cambio.';

  @override
  String get groupsMembersFailed => 'No se pudieron cargar los miembros';

  @override
  String get groupsPleaseTryAgain => 'Inténtalo de nuevo.';

  @override
  String groupsMemberYou(String name) {
    return '$name (tú)';
  }

  @override
  String get groupsRoleOwner => 'Propietario';

  @override
  String get groupsRoleModerator => 'Moderador';

  @override
  String get groupsRoleMember => 'Miembro';

  @override
  String groupsMemberOptions(String name) {
    return 'Opciones para $name';
  }

  @override
  String get groupsEditFailed => 'No se pudieron guardar tus cambios.';

  @override
  String get groupsSaving => 'Guardando…';

  @override
  String get groupsSaveChanges => 'Guardar cambios';

  @override
  String get groupsNameLabel => 'Nombre del grupo';

  @override
  String get groupsAboutLabel => '¿De qué trata?';

  @override
  String get groupsAboutOptionalLabel => '¿De qué trata? (opcional)';

  @override
  String get groupsCityLabel => 'Ciudad (opcional)';

  @override
  String get groupsCoverColorTheme => 'Tema';

  @override
  String get groupsCoverColorAccent => 'Acento';

  @override
  String get groupsCoverColorWarm => 'Cálido';

  @override
  String get groupsLifestyleLabel => 'Estilo de vida';

  @override
  String get groupsCreateCoverUploadFailed =>
      'Tu grupo está listo, pero no se pudo subir la foto de portada. Inténtalo de nuevo desde el grupo.';

  @override
  String get groupsCreatePickLifestyle =>
      'Elige un estilo de vida para tu grupo de comunidad.';

  @override
  String get groupsCreateNameTooShort =>
      'Ponle a tu grupo un nombre de al menos 3 letras.';

  @override
  String get groupsCreateFailed =>
      'No se pudo crear tu grupo. Inténtalo de nuevo.';

  @override
  String get groupsCreateEyebrow => 'NUEVO GRUPO';

  @override
  String get groupsCreateSubtitle =>
      'Reúne a gente en torno a lo que te encanta.';

  @override
  String get groupsCreateSubtitleFriends =>
      'Convierte a tus amigos en un grupo.';

  @override
  String get groupsCreateKindHeader => 'QUÉ TIPO';

  @override
  String get groupsKindCommunity => 'Grupo de comunidad';

  @override
  String get groupsKindPrivate => 'Grupo privado';

  @override
  String get groupsCreateCommunitySubtitle =>
      'Por estilo de vida. Cualquiera puede encontrarlo y unirse.';

  @override
  String get groupsCreatePrivateSubtitle =>
      'Solo amigos. Solo pueden unirse las personas que invites.';

  @override
  String get groupsCreateLifestyleHeader => 'ESTILO DE VIDA';

  @override
  String get groupsCreateLifestyleCaption =>
      'Donde la gente descubrirá tu grupo.';

  @override
  String get groupsCreateDetailsHeader => 'DETALLES';

  @override
  String get groupsCreateNameHintCommunity =>
      'Corredores al amanecer de Indiranagar';

  @override
  String get groupsCreateNameHintPrivate =>
      'La pandilla del brunch del domingo';

  @override
  String get groupsCreateCoverHeader => 'PORTADA';

  @override
  String groupsCoverEmojiSemantics(String emoji) {
    return 'Emoji de portada $emoji';
  }

  @override
  String get groupsCreateCoverPhotoOptional => 'Foto de portada (opcional)';

  @override
  String get groupsCreateCoverPhotoHint =>
      'Los miembros ven el emoji hasta que se apruebe tu foto.';

  @override
  String get groupsCreateAddCoverPhoto => 'Añadir una foto de portada';

  @override
  String get groupsCreateChangePhoto => 'Cambiar foto';

  @override
  String get groupsCreateRemovePhoto => 'Quitar foto';

  @override
  String get groupsCreateFriendsHeader => 'AMIGOS';

  @override
  String get groupsCreateFriendsCaptionEmpty =>
      'Invita a amigos ahora o más tarde desde el grupo.';

  @override
  String get groupsCreateFriendsCaption =>
      'Recibirán una invitación para unirse.';

  @override
  String get groupsFriendFallback => 'Amigo';

  @override
  String groupsRemoveInvitee(String name) {
    return 'Quitar a $name';
  }

  @override
  String get groupsChooseFriends => 'Elegir amigos';

  @override
  String get groupsChangeFriends => 'Cambiar amigos';

  @override
  String get groupsCreating => 'Creando…';

  @override
  String get groupsCreateGroup => 'Crear grupo';

  @override
  String get groupsCardRemoved => 'Retirado tras una revisión';

  @override
  String groupsCardSemanticsMuted(String name, String details) {
    return '$name, $details, notificaciones silenciadas';
  }

  @override
  String get groupsNotificationsMuted => 'Notificaciones silenciadas';

  @override
  String groupsUnreadMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes sin leer',
      one: '1 mensaje sin leer',
    );
    return '$_temp0';
  }

  @override
  String get groupsCoverSheetTitle => 'Foto de portada';

  @override
  String get groupsCoverSheetBody =>
      'Revisamos cada foto antes de que otros miembros puedan verla. Usa un JPEG o PNG de hasta 10 MB.';

  @override
  String get groupsCoverFromPhotos => 'Elegir de tus fotos';

  @override
  String get groupsCoverTakePhoto => 'Hacer una foto';

  @override
  String get groupsCoverTooLarge =>
      'Esa foto pesa más de 10 MB. Elige una más pequeña.';

  @override
  String get groupsCoverPreviewTitle => 'Vista previa de tu portada';

  @override
  String get groupsCoverPreviewBody =>
      'Las portadas se muestran como un banner ancho que conserva el centro de tu foto.';

  @override
  String get groupsCancel => 'Cancelar';

  @override
  String get groupsCoverUseThisPhoto => 'Usar esta foto';

  @override
  String get groupsCoverPreviewSemantics => 'Tu nueva foto de portada';

  @override
  String get groupsCoverChecking => 'Comprobando tu foto de portada…';

  @override
  String groupsCoverUploading(int percent) {
    return 'Subiendo foto de portada… $percent %';
  }

  @override
  String get groupsCoverUploadedReview =>
      'Tu portada está en revisión. Solo tú puedes verla hasta que se apruebe.';

  @override
  String get groupsCoverUpdated => 'Foto de portada actualizada.';

  @override
  String get groupsPickerSubtitle =>
      'Solo puedes invitar a personas de tu lista de amigos.';

  @override
  String get groupsDone => 'Listo';

  @override
  String get groupsSearchFriends => 'Buscar amigos';

  @override
  String get groupsFriendsFailed => 'No se pudieron cargar tus amigos';

  @override
  String get groupsNoFriendsTitle => 'Aún no tienes amigos';

  @override
  String get groupsNoFriendsBody =>
      'Añade amigos desde Matches, perfiles o salas y luego llévalos a un grupo.';

  @override
  String get groupsAlreadyMember => 'Ya está en este grupo';

  @override
  String get groupsInvitationSent => 'Invitación enviada';

  @override
  String get todayActivityCoffee => 'Un café';

  @override
  String get todayActivityWalk => 'Un paseo de día';

  @override
  String get todayActivityMeal => 'Una comida';

  @override
  String get todayActivityPlayful => 'Algo divertido';

  @override
  String get todayActivityEvent => 'Un evento';

  @override
  String get todayActivityVideoCall => 'Un hola por videollamada';

  @override
  String get todayActivityDrinks => 'Tomar algo';

  @override
  String get todayActivityOther => 'Otra cosa';

  @override
  String get todayBudgetFlexible => 'Decidámoslo juntos';

  @override
  String get todayBudgetFree => 'Que sea gratis';

  @override
  String get todayBudgetModest => 'Algo económico';

  @override
  String get todayBudgetTreat => 'Darnos un capricho';

  @override
  String get todayRhythmTitle => 'Tu ritmo de citas';

  @override
  String get todayRhythmLoadFailed =>
      'No se han podido cargar tus preferencias.';

  @override
  String get todayRhythmSaved => 'Tu ritmo de citas se ha guardado.';

  @override
  String get todayRhythmSaveFailed =>
      'No se ha podido guardar. Tus elecciones siguen aquí.';

  @override
  String get todayRhythmHeadline => 'Haz sitio a tu manera de tener citas.';

  @override
  String get todayRhythmIntro =>
      'Elige lo que encaje con tu vida. La disponibilidad y las presentaciones son opcionales, y puedes cambiar de opinión.';

  @override
  String get todayRhythmOpenTo => '¿Qué estás buscando?';

  @override
  String get todayRhythmIntentNone => 'Prefiero no decirlo';

  @override
  String get todayRhythmIntentRelationship => 'Una relación';

  @override
  String get todayRhythmIntentExploring => 'Buscando mi camino';

  @override
  String get todayRhythmIntentCasual => 'Algo casual';

  @override
  String get todayRhythmPaceSection => 'Tu ritmo de conversación';

  @override
  String get todayRhythmPaceNone => 'Sin preferencia';

  @override
  String get todayRhythmPaceSlow => 'Un poco más despacio';

  @override
  String get todayRhythmPaceSteady => 'Una conversación constante';

  @override
  String get todayRhythmPaceFrequent => 'Conversación frecuente';

  @override
  String get todayRhythmSlowWeek => 'Respuestas lentas esta semana';

  @override
  String get todayRhythmSlowWeekHint =>
      'Este estado se borra a los siete días.';

  @override
  String get todayRhythmSharePace => 'Compartir este estado con mis matches';

  @override
  String get todayRhythmSharePaceHint =>
      'Solo tus matches actuales pueden ver tu estado temporal.';

  @override
  String get todayRhythmFirstDate => 'Tu tipo de primera cita';

  @override
  String get todayRhythmChooseFive =>
      'Elige hasta cinco. Las preferencias compartidas ayudan a explicar tus presentaciones.';

  @override
  String get todayRhythmWeekSection => 'Un hueco en tu semana';

  @override
  String get todayRhythmShareAvailability => 'Usar mi disponibilidad general';

  @override
  String get todayRhythmShareAvailabilityHint =>
      'Solo se muestran las coincidencias reales. Tu agenda completa es privada. Al desactivarlo se borran los horarios guardados.';

  @override
  String get todayRhythmAvailabilityHint =>
      'Toca cualquier mañana, tarde o noche que te venga bien. Las horas usan la hora local de este dispositivo y caducan automáticamente.';

  @override
  String get todayRhythmMorning => 'Mañana';

  @override
  String get todayRhythmAfternoon => 'Tarde';

  @override
  String get todayRhythmEvening => 'Noche';

  @override
  String get todayRhythmIntrosSection => 'Presentaciones con tu permiso';

  @override
  String get todayRhythmFriendIntros =>
      'Permitir presentaciones de amigos aceptados';

  @override
  String get todayRhythmFriendIntrosHint =>
      'Ambas personas deben aceptar. Tu amigo no recibe avisos de match ni de rechazo. La vista previa incluye tu nombre y tu edad.';

  @override
  String get todayRhythmIntroPhoto => 'Incluir mis fotos de perfil';

  @override
  String get todayRhythmIntroPhotoHint =>
      'Solo la persona que recibe la presentación puede verlas.';

  @override
  String get todayRhythmIntroCity => 'Incluir mi ciudad';

  @override
  String get todayRhythmIntroCityHint =>
      'Tu ubicación exacta nunca se incluye.';

  @override
  String get todayRhythmReload => 'Recargar elecciones guardadas';

  @override
  String get todayRhythmSaving => 'Guardando…';

  @override
  String get todayRhythmSave => 'Guardar mi ritmo';

  @override
  String get todayRhythmBreakTitle => 'Tomarse un descanso siempre está bien.';

  @override
  String get todayRhythmBreakBody =>
      'Pausa las nuevas presentaciones cuando lo necesites. Tus conversaciones actuales siguen disponibles.';

  @override
  String get todayRhythmPauseFailed => 'No se ha podido actualizar tu pausa.';

  @override
  String get todayRhythmResume => 'Reanudar presentaciones';

  @override
  String get todayRhythmPause => 'Pausar presentaciones';

  @override
  String get datingConnectionSlowTitle => 'Responde con calma esta semana';

  @override
  String get datingConnectionSlowBody =>
      'Tu match se está tomando las cosas con más calma.';

  @override
  String get datingConnectionYourTurn => 'Te toca: añade una sorpresa';

  @override
  String get datingConnectionComplete => 'Vuestro primer capítulo está listo';

  @override
  String get datingConnectionWaiting => 'Vuestro capítulo ya tiene un comienzo';

  @override
  String get datingConnectionCreate => 'Cread vuestro primer capítulo';

  @override
  String get datingConnectionBody =>
      'Un comienzo, una sorpresa y una historia que construís juntos.';

  @override
  String get chemistryTitle => 'Un poco de química';

  @override
  String get chemistryIntro =>
      'Elige lo que vaya contigo. No hay respuestas correctas y esto nunca limita el acceso al chat.';

  @override
  String get chemistrySaveFailed =>
      'No se ha podido guardar tu elección. Vuelve a intentarlo.';

  @override
  String get chemistryRetry => 'Volver a cargar';

  @override
  String get chemistryRevealedTitle => 'Las dos respuestas, juntas';

  @override
  String get chemistryYouPicked => 'Tú elegiste';

  @override
  String get chemistryMatchPicked => 'Tu match eligió';

  @override
  String get chemistryRevealedBody =>
      'Un favorito en común o una bonita diferencia: tenéis algo de lo que hablar.';

  @override
  String get chemistryWaitingBody =>
      'Tu respuesta se ha guardado en privado. Las dos respuestas aparecerán aquí cuando ambos hayáis elegido.';

  @override
  String chemistryYourChoice(String choice) {
    return 'Tu elección: $choice';
  }

  @override
  String get chemistryAnotherMoment => 'Otro momento, cuando quieras';

  @override
  String get chemistryChooseMoment => 'Elige un momento';

  @override
  String get chemistryPromptSunday => 'Diseña un domingo';

  @override
  String get chemistryPromptAdventure => 'Elige una aventura';

  @override
  String get chemistryPromptFirstDate => 'Tu tipo de primera cita';

  @override
  String get chemistryQuestionSunday => 'Tu domingo ideal empieza con…';

  @override
  String get chemistryQuestionAdventure => 'Una pequeña aventura juntos…';

  @override
  String get chemistryQuestionFirstDate => 'Para un primer saludo, elegirías…';

  @override
  String get engagementLevelFrozen =>
      'Tu progreso está en pausa mientras se revisa la seguridad de tu cuenta.';

  @override
  String get engagementLevelTrustGate =>
      'Verifica tu perfil y mantén tu cuenta en buen estado para desbloquear los niveles que requieren confianza.';

  @override
  String get engagementLevelPathTitle => 'Camino de niveles';

  @override
  String get engagementLevelPathSubtitle =>
      'La XP viene de la actividad significativa. Las compras nunca suben tu nivel.';

  @override
  String get engagementLevelRewardsTitle => 'Recompensas';

  @override
  String get engagementLevelRewardsSubtitle =>
      'Las recompensas son estéticas, de comodidad o ventajas de visibilidad limitadas.';

  @override
  String get engagementLevelRecentTitle => 'XP reciente';

  @override
  String get engagementLevelRecentSubtitle =>
      'Tu registro de actividad es permanente y verificable.';

  @override
  String engagementLevelNumber(int level) {
    return 'Nivel $level';
  }

  @override
  String engagementLevelXp(String xp) {
    return '$xp XP';
  }

  @override
  String get engagementLevelHighest => 'Nivel máximo alcanzado';

  @override
  String engagementLevelProgress(int xp, String percent) {
    return '$xp XP en este nivel · $percent %';
  }

  @override
  String engagementLevelThreshold(int xp, String summary) {
    return '$xp XP · $summary';
  }

  @override
  String get engagementLevelTrustGated => 'Requiere confianza';

  @override
  String get engagementLevelClaimed => 'Reclamada';

  @override
  String get engagementLevelClaim => 'Reclamar';

  @override
  String get engagementLevelLocked => 'Bloqueada';

  @override
  String get engagementLevelStandardAward => 'Asignación estándar';

  @override
  String engagementLevelQualityWeighting(String multiplier) {
    return 'Ponderación de calidad ×$multiplier';
  }

  @override
  String get engagementLevelEmptyLedger =>
      'Completa actividades significativas para ganar tu primera XP.';

  @override
  String get engagementXpSourceProfileCompleted => 'Perfil completado';

  @override
  String get engagementXpSourceDailyPromptSubmitted =>
      'Pregunta diaria respondida';

  @override
  String get engagementXpSourceMiniActivityCompleted =>
      'Miniactividad completada';

  @override
  String get engagementXpSourceCircleChallengeSubmitted =>
      'Reto de círculo enviado';

  @override
  String get engagementXpSourceVoiceIcebreakerPlayed =>
      'Rompehielos de voz escuchado';

  @override
  String get engagementXpSourceStreak3 => 'Racha de 3 días';

  @override
  String get engagementXpSourceStreak7 => 'Racha de 7 días';

  @override
  String get engagementXpSourceStreak14 => 'Racha de 14 días';

  @override
  String get engagementXpSourceAdminAdjustment => 'Ajuste del equipo';

  @override
  String get engagementLevelSignIn =>
      'Inicia sesión para ver tu progreso de nivel.';

  @override
  String get engagementLevelLoadFailed =>
      'Ahora mismo no se puede cargar tu progreso.';

  @override
  String get engagementLevelClaimFailed =>
      'Ahora mismo no se puede reclamar esta recompensa.';

  @override
  String get engagementCoffeeTitle => 'Encuestas de café en grupo';

  @override
  String get engagementCoffeeCreateHeading =>
      'Crea una encuesta sencilla para tomar un café en grupo';

  @override
  String get engagementCoffeeCreateHint =>
      'Añade hasta 3 ID de participantes (separados por comas) y al menos una opción.';

  @override
  String get engagementCoffeeParticipantsLabel =>
      'ID de participantes (separados por comas)';

  @override
  String get engagementCoffeeDeadlineLabel => 'Fecha límite ISO (opcional)';

  @override
  String engagementCoffeeOptionNumber(int number) {
    return 'Opción $number';
  }

  @override
  String get engagementCoffeeCreate => 'Crear encuesta';

  @override
  String get engagementCoffeeActorLabel =>
      'ID de usuario alternativo para la acción (opcional)';

  @override
  String get engagementCoffeeEmpty => 'Aún no hay encuestas. Crea una arriba.';

  @override
  String engagementCoffeePollId(String id) {
    return 'Encuesta $id';
  }

  @override
  String engagementCoffeeStatus(String status) {
    return 'Estado: $status';
  }

  @override
  String get engagementCoffeeStatusOpen => 'abierta';

  @override
  String get engagementCoffeeStatusFinalized => 'cerrada';

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
  String get engagementCoffeeFinalize => 'Cerrar encuesta';

  @override
  String get engagementCoffeeDayLabel => 'Día';

  @override
  String get engagementCoffeeTimeLabel => 'Franja horaria';

  @override
  String get engagementCoffeeAreaLabel => 'Barrio';

  @override
  String get engagementCoffeeLoadFailed =>
      'Ahora mismo no se pueden cargar las encuestas de grupo.';

  @override
  String get engagementCoffeeCreateFailed =>
      'Ahora mismo no se puede crear la encuesta de grupo.';

  @override
  String get engagementCoffeeVoteUserRequired =>
      'Se necesita un ID de usuario para votar.';

  @override
  String get engagementCoffeeVoteFailed => 'Ahora mismo no se puede votar.';

  @override
  String get engagementCoffeeFinalizeUserRequired =>
      'Se necesita un ID de usuario para cerrarla.';

  @override
  String get engagementCoffeeFinalizeFailed =>
      'Ahora mismo no se puede cerrar la encuesta.';

  @override
  String get engagementDailyPromptUnavailable =>
      'Pregunta diaria no disponible';

  @override
  String get engagementDailyPromptPullToRefresh =>
      'Desliza hacia abajo para actualizar o inténtalo en un rato.';

  @override
  String get engagementDailyPromptDomainValues => 'VALORES';

  @override
  String get engagementDailyPromptDomainLifestyle => 'ESTILO DE VIDA';

  @override
  String get engagementDailyPromptDomainRelationshipStyle =>
      'ESTILO DE RELACIÓN';

  @override
  String get engagementDailyPromptSparkTitle => 'Chispa de compatibilidad';

  @override
  String engagementDailyPromptSparkSummary(int replied, int similar) {
    return 'Respuestas hoy: $replied · respuestas parecidas: $similar';
  }

  @override
  String get engagementDailyPromptYourAnswer => 'Tu respuesta';

  @override
  String get engagementDailyPromptHint =>
      'Escribe tu respuesta en menos de 60 segundos.';

  @override
  String engagementDailyPromptEditOpenUntil(String time) {
    return 'Puedes editarla hasta las $time';
  }

  @override
  String get engagementDailyPromptEditOpenSoon =>
      'Puedes editarla durante poco tiempo más';

  @override
  String get engagementDailyPromptEditClosed => 'Ya no puedes editarla hoy.';

  @override
  String get engagementDailyPromptEdited => 'Editada';

  @override
  String get engagementDailyPromptSubmit => 'Enviar respuesta diaria';

  @override
  String get engagementDailyPromptUpdate => 'Actualizar respuesta';

  @override
  String get engagementDailyPromptStreakProgress => 'Progreso de la racha';

  @override
  String engagementDailyPromptStatCurrent(String value) {
    return 'Actual: $value';
  }

  @override
  String engagementDailyPromptStatBest(String value) {
    return 'Mejor: $value';
  }

  @override
  String engagementDailyPromptStatNext(String value) {
    return 'Siguiente: $value';
  }

  @override
  String engagementDailyPromptDays(int days) {
    return '$days d';
  }

  @override
  String get engagementDailyPromptComplete => 'Completado';

  @override
  String engagementDailyPromptMilestone(int days) {
    return 'Hito desbloqueado: racha de $days días';
  }

  @override
  String get engagementDailyPromptLoadFailed =>
      'Ahora mismo no se puede cargar la pregunta diaria.';

  @override
  String get engagementDailyPromptNotLoaded =>
      'La pregunta diaria aún no se ha cargado.';

  @override
  String get engagementDailyPromptEnterAnswer =>
      'Escribe primero una respuesta.';

  @override
  String get engagementDailyPromptSubmitFailed =>
      'No se ha podido enviar la respuesta. Inténtalo de nuevo.';

  @override
  String get clubsKindBooks => 'Libros';

  @override
  String get clubsKindFilms => 'Películas';

  @override
  String get clubsFilterAll => 'Todos';

  @override
  String get clubsAudiencePrivate => 'Solo yo';

  @override
  String get clubsAudienceFriends => 'Amigos';

  @override
  String get clubsAudienceCommunity => 'Comunidad de Connect';

  @override
  String get clubsRoleOwner => 'Responsable';

  @override
  String get clubsRoleModerator => 'Moderador';

  @override
  String get clubsRoleMember => 'Miembro';

  @override
  String get clubsBadgeBookClub => 'Club de lectura';

  @override
  String get clubsBadgeFilmClub => 'Cineclub';

  @override
  String get clubsBadgeBookList => 'Lista de libros';

  @override
  String get clubsBadgeFilmList => 'Lista de películas';

  @override
  String get clubsBadgeBook => 'Libro';

  @override
  String get clubsBadgeFilm => 'Película';

  @override
  String get clubsClub => 'Club';

  @override
  String clubsStarsOutOfFive(String rating) {
    return '$rating de 5 estrellas';
  }

  @override
  String clubsStarCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrellas',
      one: '1 estrella',
    );
    return '$_temp0';
  }

  @override
  String get clubsNoRatingsYet => 'Aún sin valoraciones';

  @override
  String clubsRatingSummary(String average, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reseñas',
      one: '1 reseña',
    );
    return '$average · $_temp0';
  }

  @override
  String get clubsWeekThis => 'Esta semana';

  @override
  String get clubsWeekNext => 'La próxima semana';

  @override
  String get clubsWeekLast => 'La semana pasada';

  @override
  String clubsWeekOf(String date) {
    return 'Semana del $date';
  }

  @override
  String get clubsTitle => 'Clubs de lectura y cine';

  @override
  String get clubsMyLists => 'Mis listas';

  @override
  String get clubsStartClubTooltip => 'Crea un club de lectura o de cine';

  @override
  String get clubsStartClub => 'Crear un club';

  @override
  String get clubsSignInToSee => 'Inicia sesión para ver los clubs.';

  @override
  String get clubsHeroTitle => 'Léelo. Míralo. Coméntalo.';

  @override
  String get clubsHeroSubtitle =>
      'Únete a un club, sigue una elección por semana y comparte lo que te pareció. El buen gusto da para muy buenas conversaciones.';

  @override
  String get clubsScopeMine => 'Mis clubs';

  @override
  String get clubsScopeDiscover => 'Descubrir';

  @override
  String get clubsLoadErrorTitle => 'No se pudieron cargar los clubs';

  @override
  String get clubsCheckConnection => 'Comprueba tu conexión.';

  @override
  String get clubsLookAroundTitle => 'Puedes echar un vistazo';

  @override
  String get clubsLookAroundMessage =>
      'Completa tu perfil con dos fotos aprobadas para crear un club o unirte a uno.';

  @override
  String get clubsEmptyMineTitle => 'Tu primer club te espera';

  @override
  String get clubsEmptyMineMessage =>
      'Encuentra un club que lea o vea lo que te encanta, o crea el tuyo.';

  @override
  String get clubsEmptyDiscoverTitle => 'Aún no hay clubs aquí';

  @override
  String get clubsEmptyDiscoverMessage =>
      'Da el primer paso: crea un club y elige algo genial para esta semana.';

  @override
  String get clubsDiscoverClubs => 'Descubrir clubs';

  @override
  String clubsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String get clubsYouRunIt => 'Lo diriges tú';

  @override
  String get clubsYouModerate => 'Moderas tú';

  @override
  String get clubsJoined => 'Te uniste ✓';

  @override
  String get clubsNoPickThisWeek => 'Aún no hay elección esta semana';

  @override
  String get clubsNameTooShort =>
      'Ponle a tu club un nombre de al menos 3 letras.';

  @override
  String get clubsCreateFailed => 'No se pudo crear tu club.';

  @override
  String get clubsNameLabel => 'Nombre del club';

  @override
  String get clubsNameHint => 'Lecturas lentas de domingo';

  @override
  String get clubsDescriptionLabel => '¿De qué trata tu club? (opcional)';

  @override
  String get clubsCreating => 'Creando…';

  @override
  String get clubsCreateClub => 'Crear club';

  @override
  String clubsLeaveTitle(String name) {
    return '¿Salir de $name?';
  }

  @override
  String get clubsLeaveMessage =>
      'Puedes volver a unirte más tarde mientras el club siga abierto.';

  @override
  String get clubsLeaveClub => 'Salir del club';

  @override
  String clubsWelcome(String name) {
    return '¡Te damos la bienvenida a $name!';
  }

  @override
  String get clubsChangeNotSaved => 'No se pudo guardar ese cambio.';

  @override
  String get clubsOptionsTooltip => 'Opciones del club';

  @override
  String get clubsMembers => 'Miembros';

  @override
  String get clubsReportClub => 'Denunciar club';

  @override
  String get clubsDetailLoadErrorTitle => 'No se pudo cargar este club';

  @override
  String get clubsDetailLoadErrorMessage =>
      'Puede que haya cerrado. Inténtalo de nuevo.';

  @override
  String get clubsEarlierPicks => 'Elecciones anteriores';

  @override
  String clubsPickSubtitle(String week, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count publicaciones',
      one: '1 publicación',
    );
    return '$week · $_temp0';
  }

  @override
  String get clubsOpenDiscussion => 'Abrir la conversación';

  @override
  String get clubsJoinToSeeTitle => 'Únete para ver la conversación';

  @override
  String get clubsJoinToSeeMessage =>
      'Los miembros comentan juntos cada elección. Únete al club para seguir la conversación y aportar tu opinión.';

  @override
  String clubsYouRole(String role) {
    return 'Tú: $role';
  }

  @override
  String get clubsRemovedByModeration =>
      'Este club fue retirado por moderación.';

  @override
  String get clubsJoinClub => 'Unirse al club';

  @override
  String get clubsNoPickModerator =>
      'Aún no hay elección. Elige algo genial para todos.';

  @override
  String get clubsNoPickMember => 'Aún no hay elección. Vuelve pronto.';

  @override
  String clubsQuotedNote(String note) {
    return '«$note»';
  }

  @override
  String clubsPostsInDiscussion(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count publicaciones en la conversación',
      one: '1 publicación en la conversación',
    );
    return '$_temp0';
  }

  @override
  String get clubsSetThisWeeksPick => 'Elegir la de esta semana';

  @override
  String get clubsDiscussThisPick => 'Comentar esta elección';

  @override
  String get clubsPostNotSent => 'No se pudo enviar tu publicación.';

  @override
  String clubsDiscussionHeading(String title) {
    return 'Conversación · $title';
  }

  @override
  String get clubsDiscussionLoadError => 'No se pudo cargar la conversación';

  @override
  String get clubsStartConversationTitle => 'Empieza la conversación';

  @override
  String get clubsStartConversationMessage =>
      '¿Qué te ha parecido hasta ahora? Tu publicación podría ser la que ponga a todos a hablar.';

  @override
  String get clubsLoadMorePosts => 'Cargar más publicaciones';

  @override
  String get clubsComposerLabel => 'Participa en la conversación';

  @override
  String get clubsComposerHint => '¿Momento favorito? ¿La mayor sorpresa?';

  @override
  String get clubsContainsSpoilers => 'Contiene spoilers';

  @override
  String get clubsSpoilersSubtitle => 'Los demás tocan para verla.';

  @override
  String get clubsPosting => 'Publicando…';

  @override
  String get clubsPost => 'Publicar';

  @override
  String get clubsDeletePostTitle => '¿Eliminar tu publicación?';

  @override
  String get clubsDeletePostMessage =>
      'Se eliminará de la conversación para todos.';

  @override
  String get clubsActionFailed => 'No se pudo completar esa acción.';

  @override
  String get clubsHideFromMembers => 'Ocultar a los miembros';

  @override
  String get clubsShowToMembers => 'Mostrar a los miembros';

  @override
  String get clubsReport => 'Denunciar';

  @override
  String get clubsYou => 'Tú';

  @override
  String get clubsHidden => 'Oculta';

  @override
  String get clubsPostActions => 'Acciones de la publicación';

  @override
  String get clubsMakeModerator => 'Hacer moderador';

  @override
  String get clubsMakeMember => 'Hacer miembro';

  @override
  String get clubsRemoveFromClub => 'Quitar del club';

  @override
  String clubsRemoveMemberTitle(String name) {
    return '¿Quitar a $name?';
  }

  @override
  String get clubsRemoveMemberMessage =>
      'Saldrá del club y no podrá volver a unirse. Sus publicaciones anteriores se quedan en la conversación.';

  @override
  String get clubsRemove => 'Quitar';

  @override
  String get clubsMembersLoadError => 'No se pudieron cargar los miembros.';

  @override
  String clubsMemberYou(String name) {
    return '$name (tú)';
  }

  @override
  String clubsMemberActions(String name) {
    return 'Acciones para $name';
  }

  @override
  String get clubsChooseFilm => 'Elige una película';

  @override
  String get clubsChooseBook => 'Elige un libro';

  @override
  String get clubsChooseTitle => 'Elige un título';

  @override
  String get clubsChooseTitleFirst => 'Elige primero un título.';

  @override
  String get clubsPickNotSaved => 'No se pudo guardar la elección.';

  @override
  String get clubsSetWeeklyPick => 'Fijar la elección de la semana';

  @override
  String get clubsChange => 'Cambiar';

  @override
  String get clubsPickNoteLabel => 'Una nota para el club (opcional)';

  @override
  String get clubsPickNoteHint => '¿Por qué este? ¿Por dónde empezar?';

  @override
  String get clubsSaving => 'Guardando…';

  @override
  String get clubsSavePick => 'Guardar elección';

  @override
  String get clubsListNameRequired => 'Ponle un nombre a tu lista.';

  @override
  String get clubsListNotSaved => 'No se pudo guardar tu lista.';

  @override
  String get clubsEditList => 'Editar lista';

  @override
  String get clubsNewList => 'Nueva lista';

  @override
  String get clubsListNameLabel => 'Nombre de la lista';

  @override
  String get clubsListNameHint => 'Libros que me hicieron cambiar de opinión';

  @override
  String get clubsWhoCanSee => 'Quién puede verlo';

  @override
  String get clubsSave => 'Guardar';

  @override
  String get clubsCreateList => 'Crear lista';

  @override
  String get clubsYourNote => 'Tu nota';

  @override
  String get clubsNoteLabel => 'Por qué está en esta lista';

  @override
  String get clubsSaveNote => 'Guardar nota';

  @override
  String get clubsCreateNewListTooltip => 'Crear una lista nueva';

  @override
  String get clubsSignInToSeeLists => 'Inicia sesión para ver tus listas.';

  @override
  String get clubsShelfTitle => 'Tu estantería';

  @override
  String get clubsShelfSubtitle =>
      'Lleva la cuenta de lo que te encantó y de lo que viene. Comparte una lista o guárdala solo para ti.';

  @override
  String get clubsListsLoadErrorTitle => 'No se pudieron cargar tus listas';

  @override
  String get clubsFirstListTitle => 'Crea tu primera lista';

  @override
  String get clubsFirstListMessage =>
      'Películas favoritas, próximas lecturas, pelis para volver a ver: tú decides.';

  @override
  String clubsAddToNamed(String name) {
    return 'Añadir a $name';
  }

  @override
  String get clubsAddToThisListFailed => 'No se pudo añadir a esta lista.';

  @override
  String clubsDeleteListTitle(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get clubsDeleteListMessage =>
      'Se eliminarán la lista y sus notas. No se puede deshacer.';

  @override
  String get clubsDeleteList => 'Eliminar lista';

  @override
  String get clubsListDeleteFailed =>
      'No se pudo eliminar la lista. Recarga e inténtalo de nuevo.';

  @override
  String get clubsNoteNotSaved => 'No se pudo guardar tu nota.';

  @override
  String get clubsRemoveFailed => 'No se pudo quitar.';

  @override
  String get clubsListOptions => 'Opciones de la lista';

  @override
  String get clubsAddATitle => 'Añadir un título';

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
      'Aún no hay nada. Usa «Añadir un título» en el menú de la lista.';

  @override
  String clubsItemOptions(String title) {
    return 'Opciones para $title';
  }

  @override
  String get clubsAddNote => 'Añadir una nota';

  @override
  String get clubsEditNote => 'Editar nota';

  @override
  String get clubsRemoveFromList => 'Quitar de la lista';

  @override
  String get clubsTapStarError => 'Toca una estrella para valorar.';

  @override
  String get clubsReviewNotSaved => 'No se pudo guardar tu reseña.';

  @override
  String get clubsWriteReview => 'Escribir una reseña';

  @override
  String get clubsEditYourReview => 'Editar tu reseña';

  @override
  String get clubsTapStarToRate => 'Toca una estrella para valorar';

  @override
  String clubsRatingOutOfFive(int rating) {
    return '$rating de 5';
  }

  @override
  String get clubsReviewBodyLabel => '¿Qué te pareció? (opcional)';

  @override
  String get clubsSaveReview => 'Guardar reseña';

  @override
  String clubsAddedToList(String name) {
    return 'Añadido a $name.';
  }

  @override
  String get clubsAddToThatListFailed => 'No se pudo añadir a esa lista.';

  @override
  String get clubsAddToAList => 'Añadir a una lista';

  @override
  String get clubsListsLoadError => 'No se pudieron cargar tus listas.';

  @override
  String get clubsNoFilmLists =>
      'Aún no tienes listas de películas. Crea una para empezar tu colección.';

  @override
  String get clubsNoBookLists =>
      'Aún no tienes listas de libros. Crea una para empezar tu colección.';

  @override
  String get clubsTitleFallback => 'Título';

  @override
  String get clubsSignInToSeeReviews => 'Inicia sesión para ver las reseñas.';

  @override
  String get clubsTitleLoadError => 'No se pudo cargar este título';

  @override
  String get clubsReviews => 'Reseñas';

  @override
  String get clubsNoOtherReviewsTitle => 'Aún no hay otras reseñas';

  @override
  String get clubsNoOtherReviewsMessage =>
      'Cuando miembros que puedes ver compartan una reseña, aparecerá aquí.';

  @override
  String get clubsDeleteReviewTitle => '¿Eliminar tu reseña?';

  @override
  String get clubsDeleteReviewMessage =>
      'Tu valoración y tu texto se eliminarán para todos.';

  @override
  String get clubsDeleteReview => 'Eliminar reseña';

  @override
  String get clubsReviewDeleteFailed =>
      'No se pudo eliminar tu reseña. Recarga e inténtalo de nuevo.';

  @override
  String get clubsWhatDidYouThink => '¿Qué te pareció?';

  @override
  String get clubsReviewPrompt =>
      'Valóralo y di por qué. Tú eliges quién lo ve.';

  @override
  String get clubsYourReview => 'Tu reseña';

  @override
  String get clubsSpoilers => 'Spoilers';

  @override
  String get clubsEdit => 'Editar';

  @override
  String get clubsReportReview => 'Denunciar esta reseña';

  @override
  String get clubsEnterTitle => 'Escribe el título.';

  @override
  String get clubsYearRange => 'Escribe un año entre 1450 y 2100.';

  @override
  String get clubsTitleAddFailed => 'No se pudo añadir el título.';

  @override
  String get clubsSearchFilms => 'Buscar películas';

  @override
  String get clubsSearchBooks => 'Buscar libros';

  @override
  String get clubsTypeTwoLetters => 'Escribe al menos 2 letras';

  @override
  String get clubsSearchUnavailable => 'La búsqueda no está disponible.';

  @override
  String get clubsNoFilmsMatch => 'Ninguna película coincide. Añádela abajo.';

  @override
  String get clubsNoBooksMatch => 'Ningún libro coincide. Añádelo abajo.';

  @override
  String get clubsAddNewFilm => 'Añadir una película nueva';

  @override
  String get clubsAddNewBook => 'Añadir un libro nuevo';

  @override
  String get clubsTitleFieldLabel => 'Título';

  @override
  String get clubsDirector => 'Dirección';

  @override
  String get clubsAuthor => 'Autor';

  @override
  String get clubsYearOptional => 'Año (opcional)';

  @override
  String get clubsAdding => 'Añadiendo…';

  @override
  String get clubsAddAndChoose => 'Añadir y elegir';

  @override
  String get friendsIntroducerSaveFailed =>
      'No hemos podido guardarlo. Actualiza para ver los permisos más recientes antes de volver a intentarlo.';

  @override
  String friendsIntroducerRevokeTitle(String name) {
    return '¿Retirar el permiso a $name?';
  }

  @override
  String get friendsIntroducerRevokeBody =>
      'Las presentaciones nuevas y sin respuesta se detendrán. Un match mutuo que ya exista se queda entre las dos personas.';

  @override
  String get friendsIntroducerKeepPermission => 'Mantener el permiso';

  @override
  String get friendsIntroducerRemovePermission => 'Retirar permiso';

  @override
  String get friendsIntroducerPermissionRemoved => 'Permiso retirado.';

  @override
  String get friendsIntroducerMemberTitle => 'Tus celestinos';

  @override
  String get friendsIntroducerAppTitle => 'Connect · Amigos';

  @override
  String get friendsIntroducerRefresh => 'Actualizar permisos';

  @override
  String get friendsIntroducerAccount => 'Cuenta';

  @override
  String get friendsIntroducerAccountPrivacy => 'Cuenta y privacidad';

  @override
  String get friendsIntroducerSignOut => 'Cerrar sesión';

  @override
  String get friendsIntroducerMemberHeadline => 'Buenos amigos. Tú decides.';

  @override
  String get friendsIntroducerHeadline => 'Los conoces.\nVes la posibilidad.';

  @override
  String get friendsIntroducerMemberIntro =>
      'Invita a alguien de confianza a presentarte. Puede unirse sin perfil de citas. Tú decides quién tiene permiso y qué muestra una vista previa.';

  @override
  String get friendsIntroducerIntro =>
      'Un pequeño detalle puede empezar algo real. Junta a amigos que te han pedido ayuda.';

  @override
  String get friendsIntroducerMemberListTitle => 'Personas que eliges';

  @override
  String get friendsIntroducerListTitle => 'Tu círculo cercano';

  @override
  String get friendsIntroducerLoadFailed =>
      'No hemos podido cargar los permisos. No se ha cambiado nada.';

  @override
  String get friendsIntroducerMemberEmpty =>
      'Aún no tienes celestinos. Comparte una invitación con un amigo de confianza para empezar.';

  @override
  String get friendsIntroducerEmpty =>
      'Tu círculo empieza con un permiso. Pide a un amigo en Connect su código de invitación.';

  @override
  String get friendsIntroducerStatusPendingMember =>
      'Quiere tu permiso para presentarte.';

  @override
  String get friendsIntroducerStatusPending =>
      'Esperando la aprobación de tu amigo.';

  @override
  String get friendsIntroducerStatusPaused =>
      'Las presentaciones están en pausa.';

  @override
  String get friendsIntroducerStatusActive =>
      'Tiene permiso para sugerir presentaciones.';

  @override
  String friendsIntroducerPreview(String extras) {
    String _temp0 = intl.Intl.selectLogic(extras, {
      'photo':
          'Vista previa para una cita sugerida: nombre y edad opcional, foto.',
      'city':
          'Vista previa para una cita sugerida: nombre y edad opcional, ciudad.',
      'both':
          'Vista previa para una cita sugerida: nombre y edad opcional, foto, ciudad.',
      'other': 'Vista previa para una cita sugerida: nombre y edad opcional.',
    });
    return '$_temp0';
  }

  @override
  String get friendsIntroducerApproveNote =>
      'Aprobar también activa las presentaciones de amigos. Puedes pausar todas las presentaciones en Ritmo de citas.';

  @override
  String get friendsIntroducerAllow => 'Permitir presentaciones';

  @override
  String friendsIntroducerAllowed(String name) {
    return '$name ya tiene tu permiso.';
  }

  @override
  String get friendsIntroducerDecline => 'Rechazar solicitud';

  @override
  String get friendsIntroducerSentTitle => 'Enviadas con cariño';

  @override
  String get friendsIntroducerSentBody =>
      'Sus respuestas quedan entre ellos. Los dos tienen que decir que sí para que haya match.';

  @override
  String get friendsIntroducerReloadSent => 'Recargar presentaciones enviadas';

  @override
  String get friendsIntroducerSentSubtitle =>
      'Enviada · su decisión es privada';

  @override
  String get friendsIntroducerStepPreview => '1. Elige la vista previa';

  @override
  String get friendsIntroducerPreviewBody =>
      'Una cita sugerida ve tu nombre y tu edad si ya la muestras. Tu celestino solo ve tu nombre, nunca tu perfil ni tu actividad de citas.';

  @override
  String get friendsIntroducerIncludePhoto => 'Incluir mi foto de perfil';

  @override
  String get friendsIntroducerIncludeCity => 'Incluir mi ciudad';

  @override
  String get friendsIntroducerStepInvite => '2. Invita a un amigo de confianza';

  @override
  String get friendsIntroducerInviteBody =>
      'El código funciona una vez y caduca en 48 horas. Tu amigo se une con «Solo para presentar amigos» en la pantalla de bienvenida. Aprobarás su nombre aquí antes de que se comparta nada.';

  @override
  String get friendsIntroducerInviteReady =>
      'Invitación lista. Los códigos anteriores sin usar ya no funcionan.';

  @override
  String get friendsIntroducerCreateCode => 'Crear código de invitación';

  @override
  String get friendsIntroducerShareCode =>
      'Compártelo en privado con tu amigo. Para cambiar esta vista previa, cancela la invitación sin usar y crea un código nuevo.';

  @override
  String get friendsIntroducerCodeCopied => 'Código de invitación copiado';

  @override
  String get friendsIntroducerCopyCode => 'Copiar código';

  @override
  String get friendsIntroducerInvitesCancelled =>
      'Invitaciones sin usar canceladas.';

  @override
  String get friendsIntroducerCancelInvites => 'Cancelar invitaciones sin usar';

  @override
  String get friendsIntroducerManagePrefs =>
      'Gestionar todas las preferencias de presentaciones';

  @override
  String get friendsIntroducerRedeemTitle => '¿Te ha invitado un amigo?';

  @override
  String get friendsIntroducerRedeemBody =>
      'Pega su código de invitación privado. Confirmará tu nombre antes de que puedas presentarle a alguien.';

  @override
  String get friendsIntroducerCodeLabel => 'Código de invitación';

  @override
  String get friendsIntroducerCodeMissing =>
      'Escribe el código de invitación que te ha pasado tu amigo.';

  @override
  String get friendsIntroducerRequestSent =>
      'Solicitud enviada. Tu amigo ya puede aprobarte en «Tus celestinos».';

  @override
  String get friendsIntroducerAskPermission => 'Pedir permiso';

  @override
  String get friendsIntroducerNeedTwo =>
      'Cuando dos amigos te den permiso, podrás sugerir una presentación aquí.';

  @override
  String get friendsIntroducerComposerTitle => '¿Ves una posibilidad?';

  @override
  String get friendsIntroducerWhyLabel =>
      'Por qué pensaste en ellos (opcional)';

  @override
  String get friendsIntroducerWhyHelper =>
      'Los dos lo verán. No incluyas datos privados.';

  @override
  String get friendsIntroducerIntroSent =>
      'Presentación enviada. Cada uno puede decidir en privado.';

  @override
  String get friendsIntroducerSuggest => 'Sugerir una presentación';

  @override
  String get friendsIntroducerPrivacyNote =>
      'Primero, el permiso. Sin actividad de citas pública. Sin avisos de quién dijo sí o no.';

  @override
  String get planSharingLoadFailed =>
      'No se han podido cargar las opciones para compartir.';

  @override
  String get planSharingOffSnack =>
      'Compartir con tus contactos está desactivado.';

  @override
  String get planSharingSavedSnack =>
      'Los contactos que elegiste ya pueden ver este plan.';

  @override
  String get planSharingSaveFailed =>
      'No se ha podido guardar. Vuelve a cargar las opciones antes de intentarlo de nuevo.';

  @override
  String get planSharingTitle => 'Tu plan. Tu gente.';

  @override
  String get planSharingCloseTooltip => 'Cerrar opciones para compartir';

  @override
  String get planSharingIntro =>
      'Compartir con contactos empieza desactivado. Elige hasta 10 amigos de confianza para este plan. Tu cita elige sus propios contactos.';

  @override
  String get planSharingNoContacts =>
      'Todavía no hay amigos disponibles. Tu plan sigue disponible para ti y tu cita.';

  @override
  String get planSharingFriendFallback => 'Un amigo';

  @override
  String get planSharingPreviewNone =>
      'Vista previa · ningún contacto seleccionado';

  @override
  String planSharingPreviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vista previa · $count seleccionados',
      one: 'Vista previa · $count seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get planSharingPreviewOffBody =>
      'Tus amigos no recibirán novedades del plan ni de tus check-ins.';

  @override
  String get planSharingPreviewOnBody =>
      'Estos contactos pueden ver el nombre de tu cita, la hora y el lugar, el estado del plan y tus check-ins. Reciben el plan actual cuando guardas.';

  @override
  String get planSharingPrivacyNote =>
      'Los mensajes y tu opinión privada después de la cita siguen siendo privados. Si quitas a un contacto, deja de recibir novedades y pierde el acceso al plan en la app. Las novedades que ya llegaron a un dispositivo no se pueden recuperar.';

  @override
  String get planSharingReload => 'Volver a cargar las opciones';

  @override
  String get planSharingSaving => 'Guardando…';

  @override
  String get planSharingKeepOff => 'Seguir sin compartir con contactos';

  @override
  String get planSharingShareSelected => 'Compartir con los contactos elegidos';

  @override
  String get planSharingDeselectAll => 'Quitar a todos';

  @override
  String planBudgetLine(String budget) {
    return 'Presupuesto · $budget';
  }

  @override
  String planAtmosphereLine(String atmospheres) {
    return 'Ambiente · $atmospheres';
  }

  @override
  String get planAtmosphereQuiet => 'Conversación tranquila';

  @override
  String get planAtmosphereRelaxed => 'Relajado y sin prisas';

  @override
  String get planAtmosphereLively => 'Un sitio animado';

  @override
  String get planAtmosphereOutdoors => 'Al aire libre';

  @override
  String get planAtmosphereIndoors => 'En interior';

  @override
  String get planAccessStepFree => 'Acceso sin escalones';

  @override
  String get planAccessToilet => 'Baño accesible';

  @override
  String get planAccessSeating => 'Con asientos disponibles';

  @override
  String get planAccessLowNoise => 'Poco ruido de fondo';

  @override
  String get planAccessTransit => 'Cerca del transporte público';

  @override
  String get planAccessCaptions => 'Subtítulos en una cita por vídeo';

  @override
  String get planComfortHeading => 'Para que sea cómodo';

  @override
  String get planPreferencesDisclaimer =>
      'Preferencias compartidas para este plan. Confírmalas con el local o el servicio de vídeo.';

  @override
  String get planProposeErrorKept =>
      'No se ha podido enviar tu plan. Tus elecciones siguen aquí.';

  @override
  String get planChangedError =>
      'Este plan ha cambiado. Cierra esta ventana para revisar la conversación.';

  @override
  String get planProposeHeadline => 'Un plan que os haga ilusión a los dos.';

  @override
  String get planCounterHeadline => 'Dad forma juntos a este plan';

  @override
  String planProposeLead(String name) {
    return 'Una propuesta para ti y $name. No hay nada acordado hasta que la otra persona acepte esta versión.';
  }

  @override
  String get planFindTimeTitle => 'Encontrad un rato juntos';

  @override
  String get planFindTimeBody =>
      'Solo se muestran los horarios que coinciden si los dos compartís vuestra disponibilidad. Siempre puedes proponer una hora tú.';

  @override
  String get planSharedTimesFailed =>
      'No se han podido cargar los horarios en común. Puedes seguir eligiendo una hora a mano.';

  @override
  String get planSharedTimesEmpty =>
      'Ahora mismo no hay sugerencias de horarios en común. Eso no significa que ninguno de los dos esté ocupado.';

  @override
  String get planRefreshSharedTimes => 'Actualizar horarios en común';

  @override
  String get planSetAvailability => 'Indicar mi disponibilidad';

  @override
  String get planWhenTitle => '¿Cuándo te vendría bien?';

  @override
  String get planTimeSourceManual => 'Una hora que propones tú';

  @override
  String get planTimeSourceShared =>
      'Elegida de la disponibilidad en común · se vuelve a comprobar al enviar';

  @override
  String planLocalTimeNote(int minutes, String timeZone) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Hora local de tu dispositivo ($timeZone). Duración: $minutes minutos.',
      one:
          'Hora local de tu dispositivo ($timeZone). Duración: $minutes minuto.',
    );
    return '$_temp0';
  }

  @override
  String planDurationChip(int minutes) {
    return '$minutes min';
  }

  @override
  String get planEnjoyTitle => 'Algo que te apetezca';

  @override
  String get planAreaHint => 'Un barrio o un punto de encuentro público';

  @override
  String get planBudgetTitle => '¿Qué presupuesto te parece cómodo?';

  @override
  String get planBudgetBody =>
      'Un punto de partida para acordar juntos, no un presupuesto cerrado ni una promesa de quién paga.';

  @override
  String get planAtmosphereTitle => 'Elige el ambiente';

  @override
  String get planAtmosphereBody =>
      'Elige hasta tres ambientes que te gustarían. Opcional.';

  @override
  String get planComfortTitle => 'Que sea cómodo para los dos';

  @override
  String get planComfortBody =>
      'Preferencias de accesibilidad opcionales. Lo que elijas se comparte con tu match al enviar el plan. No se añade a tu perfil público ni a las novedades para tus contactos de confianza.';

  @override
  String get planComfortDisclaimer =>
      'No tienes que explicar ningún diagnóstico. Son peticiones para comprobar con el local o el servicio de vídeo, no instalaciones verificadas.';

  @override
  String get planNoteHint =>
      '¿El sábado por la tarde, en algún sitio más tranquilo?';

  @override
  String get planReviewBeforeSending =>
      'Antes de enviar, revisa la hora y tus elecciones. La otra persona puede aceptar, rechazar o proponer un cambio.';

  @override
  String get planReloadLatest => 'Cargar el último plan · descartar cambios';

  @override
  String get planSending => 'Enviando…';

  @override
  String get planSendSuggestion => 'Enviar tu propuesta';

  @override
  String get planSecondYesTitle => 'Compartir un segundo sí';

  @override
  String get planSecondYesBody =>
      'Muestra que quieres volver a quedar solo si tu match también dice que sí y acepta compartirlo. Tus demás respuestas siguen siendo privadas.';

  @override
  String get planSecondYesHeadline => 'Un segundo sí de los dos';

  @override
  String get planSecondYesCardBody =>
      'Los dos habéis compartido que os gustaría volver a quedar.';

  @override
  String get planAnotherHello => 'Planear otra cita';

  @override
  String get planSuggestChange => 'Proponer un cambio';

  @override
  String get planChooseUpdates => 'Elegir quién recibe tus novedades';

  @override
  String planQuotedNote(String note) {
    return '«$note»';
  }

  @override
  String get planStatusDeclined => 'Rechazado';

  @override
  String get planStatusExpired => 'Caducado';

  @override
  String get planStatusCompleted => 'Completado';

  @override
  String get planStatusDidNotHappen => 'No tuvo lugar';

  @override
  String get planStatusDisputed => 'En disputa';

  @override
  String get plansManageSharing => 'Gestionar con quién compartes';

  @override
  String get plansLoadFailed => 'No se han podido cargar los planes de cita.';

  @override
  String get plansFeedLoadFailed => 'No se han podido cargar los planes.';

  @override
  String get planAcceptFailed => 'No se ha podido aceptar este plan.';

  @override
  String get planDeclineFailed => 'No se ha podido rechazar este plan.';

  @override
  String get planCancelFailed => 'No se ha podido cancelar este plan.';

  @override
  String get planCheckinFailed => 'Ahora mismo no se puede hacer el check-in.';

  @override
  String get graduationFoundEachOther => 'Os habéis encontrado';

  @override
  String graduationHeadlineDecide(String name) {
    return '$name quiere dejar Connect contigo';
  }

  @override
  String graduationHeadlineWaiting(String name) {
    return 'Esperando a $name';
  }

  @override
  String get graduationBodyConfirmed =>
      'Los dos estáis ocultos en Descubrir. Este chat sigue abierto.';

  @override
  String get graduationBodyDecide =>
      'Confirma y los dos saldréis de Descubrir. Vuestro chat se queda.';

  @override
  String get graduationBodyWaiting =>
      'Has propuesto iros juntos. La otra persona puede confirmar o rechazar.';

  @override
  String get graduationCelebrate => 'Celebrarlo';

  @override
  String get graduationNotYet => 'Todavía no';

  @override
  String get graduationConfirm => 'Confirmar';

  @override
  String get graduationFriendsToldOnConfirm =>
      'Tus amigos se enterarán cuando la otra persona confirme.';

  @override
  String get graduationOnlyTwoOfYouForNow =>
      'Por ahora solo lo sabéis vosotros dos.';

  @override
  String get graduationWithdraw => 'Retirar';

  @override
  String graduationProposeTitle(String name) {
    return '¿Dejar Connect con $name?';
  }

  @override
  String graduationProposeBody(String name) {
    return 'Cuando $name confirme, los dos estaréis ocultos en Descubrir. Este chat sigue abierto y puedes volver a Descubrir cuando quieras desde Privacidad y seguridad.';
  }

  @override
  String get graduationNoteLabel => 'Una nota para tu match (opcional)';

  @override
  String get graduationNoteHint => 'Cuenta por qué es el momento';

  @override
  String get graduationTellFriends => 'Contárselo a mis amigos';

  @override
  String get graduationTellFriendsBody =>
      'Tus amigos aceptados sabrán que has encontrado a alguien, pero no a quién.';

  @override
  String get graduationAskThem => 'Preguntar';

  @override
  String get graduationTitle => 'Graduación';

  @override
  String graduationCelebrationBody(String name) {
    return 'Tú y $name dejáis Connect juntos. Los dos estáis ocultos en Descubrir y este chat sigue abierto todo el tiempo que queráis.';
  }

  @override
  String get graduationFriendsHaveBeenTold => 'Tus amigos ya lo saben.';

  @override
  String get graduationFriendsAreTold => 'Tus amigos se enteran.';

  @override
  String get graduationOnlyTwoOfYou => 'Solo lo sabéis vosotros dos.';

  @override
  String get graduationConfirmAndBack => 'Confirmar y volver';

  @override
  String get graduationBackToConnect => 'Volver a Connect';

  @override
  String get graduationLoadFailed => 'No se ha podido cargar la graduación.';

  @override
  String get graduationProposeFailed => 'No se ha podido proponer iros juntos.';

  @override
  String get graduationConfirmFailed => 'Ahora mismo no se puede confirmar.';

  @override
  String get graduationDeclineFailed => 'Ahora mismo no se puede rechazar.';

  @override
  String get graduationWithdrawFailed =>
      'No se ha podido retirar la propuesta.';

  @override
  String get graduationPauseLoadFailed =>
      'No se ha podido cargar tu estado en Descubrir.';

  @override
  String get graduationPauseFailed => 'No se ha podido pausar Descubrir.';

  @override
  String get graduationResumeFailed => 'No se ha podido reanudar Descubrir.';

  @override
  String get engagementCirclesEmptyTitle => 'No hay círculos disponibles';

  @override
  String get engagementCirclesPullToRefresh =>
      'Desliza hacia abajo para actualizar.';

  @override
  String get engagementCirclesJoined => 'Te has unido';

  @override
  String get engagementCirclesNotJoined => 'No te has unido';

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
  String get engagementCirclesJoin => 'Unirme al círculo';

  @override
  String get engagementCirclesResponseLabel => 'Tu respuesta al reto semanal';

  @override
  String get engagementCirclesSubmit => 'Enviar participación';

  @override
  String get engagementCirclesTopicFallback => 'Círculo';

  @override
  String get engagementCirclesLoadFailed =>
      'Ahora mismo no se pueden cargar los círculos.';

  @override
  String get engagementCirclesJoinFailed =>
      'Ahora mismo no puedes unirte al círculo.';

  @override
  String get engagementCirclesEnterResponse => 'Escribe tu respuesta al reto.';

  @override
  String get engagementCirclesSubmitFailed =>
      'Ahora mismo no se puede enviar tu participación.';

  @override
  String get engagementNudgesTitle => 'Toques a tus matches';

  @override
  String get engagementNudgesIntro =>
      'Envía un recordatorio amable para retomar una conversación que se ha quedado en silencio. El servidor aplica los límites diarios y las normas de seguridad.';

  @override
  String get engagementNudgesEmpty => 'No hay matches a los que dar un toque.';

  @override
  String get engagementNudgesSentInSession => 'Toque enviado en esta sesión';

  @override
  String get engagementNudgesReady => 'Listo para enviar';

  @override
  String engagementNudgesSentTo(String name) {
    return 'Toque enviado a $name.';
  }

  @override
  String get engagementNudgesAction => 'Dar un toque';

  @override
  String get engagementNudgesSendFailed => 'No se ha podido enviar este toque.';

  @override
  String get engagementTrustBadgesEarned => 'Insignias conseguidas';

  @override
  String get engagementTrustBadgesEmpty =>
      'Aún no tienes insignias. Completa actividades para desbloquear insignias de confianza.';

  @override
  String engagementTrustBadgesDetails(
    String code,
    String status,
    String awardedAt,
  ) {
    return 'Código: $code\nEstado: $status • Conseguida el $awardedAt';
  }

  @override
  String get engagementTrustBadgesHistory => 'Historial reciente';

  @override
  String get engagementTrustBadgesHistoryEmpty =>
      'Aún no hay historial de confianza.';

  @override
  String get engagementTrustBadgesMilestoneUnavailable =>
      'Estado del hito no disponible.';

  @override
  String get engagementTrustBadgesCurrentMilestone => 'Hito actual';

  @override
  String get engagementTrustBadgesLoadFailed =>
      'No se han podido cargar las insignias de confianza. Inténtalo de nuevo.';

  @override
  String get engagementTrustFiltersEnable => 'Activar filtros de confianza';

  @override
  String get engagementTrustFiltersEnableSubtitle =>
      'Ocultar perfiles que no cumplen tus requisitos de confianza';

  @override
  String engagementTrustFiltersMinimum(int count) {
    return 'Mínimo de insignias activas: $count';
  }

  @override
  String get engagementTrustFiltersRequired => 'Insignias obligatorias';

  @override
  String get engagementTrustFiltersSaved => 'Filtros de confianza guardados.';

  @override
  String get engagementTrustFiltersSave => 'Guardar filtros de confianza';

  @override
  String get engagementAppealStatusSubmitted => 'Enviada';

  @override
  String get engagementAppealStatusUnderReview => 'En revisión';

  @override
  String get engagementAppealStatusResolvedUpheld => 'Resuelta (se mantiene)';

  @override
  String get engagementAppealStatusResolvedReversed => 'Resuelta (revocada)';

  @override
  String get engagementRoomsLeaveFailed =>
      'No se ha podido salir de esta sala. Inténtalo de nuevo.';

  @override
  String get engagementRoomsPresenceFailed =>
      'Se ha perdido la conexión con la sala.';

  @override
  String get engagementRoomsMembersFailed =>
      'No se ha podido cargar quién está aquí. Inténtalo de nuevo.';

  @override
  String get engagementRoomsModerationFailed =>
      'No se ha podido completar. Inténtalo de nuevo.';

  @override
  String get engagementRoomsCreateFailed =>
      'No se ha podido abrir la sala. Inténtalo de nuevo.';

  @override
  String get engagementRoomsLoadFailed =>
      'Las salas no están disponibles ahora mismo. Desliza para reintentar.';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonRemove => 'Quitar';

  @override
  String get accountTitle => 'Cuenta y datos';

  @override
  String get accountLoadFailed => 'No se pudo cargar el estado de tu cuenta.';

  @override
  String accountDeletionIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Eliminación en $days días',
      one: 'Eliminación en 1 día',
    );
    return '$_temp0';
  }

  @override
  String get accountDeletionDue => 'La eliminación es inminente';

  @override
  String get accountDeletionCountdownBody =>
      'Tu perfil está oculto. Hasta entonces puedes iniciar sesión y cancelar; después, tus datos no se podrán recuperar.';

  @override
  String get accountKeepMyAccount => 'Conservar mi cuenta';

  @override
  String get accountNotDeletedSnack => 'Tu cuenta no se eliminará.';

  @override
  String get accountCancelFailed => 'No se pudo cancelar. Inténtalo de nuevo.';

  @override
  String get accountHiddenTitle => 'Tu perfil está oculto';

  @override
  String get accountTakeBreakTitle => 'Tómate un descanso';

  @override
  String get accountHiddenBody =>
      'Nadie puede verte ni hacer match contigo. Tus matches y mensajes se conservan y puedes volver cuando quieras.';

  @override
  String get accountTakeBreakBody =>
      'Oculta tu perfil de Descubrir sin perder nada. Sigues con la sesión iniciada y puedes volver cuando quieras.';

  @override
  String get accountUnhideProfile => 'Mostrar mi perfil';

  @override
  String get accountHideProfile => 'Ocultar mi perfil';

  @override
  String get accountVisibleAgainSnack => 'Tu perfil vuelve a ser visible.';

  @override
  String get accountNowHiddenSnack => 'Tu perfil ahora está oculto.';

  @override
  String get accountUpdateFailed =>
      'No se pudo actualizar. Inténtalo de nuevo.';

  @override
  String get accountDownloadTitle => 'Descargar tus datos';

  @override
  String get accountDownloadBody =>
      'Obtén una copia de tu perfil, preferencias, matches y los mensajes que enviaste. No se incluyen los mensajes escritos por otras personas.';

  @override
  String get accountPreparing => 'Preparando…';

  @override
  String get accountPrepareData => 'Preparar mis datos';

  @override
  String get accountPrepareFailed =>
      'No se pudieron preparar tus datos. Inténtalo de nuevo.';

  @override
  String get accountYourData => 'Tus datos';

  @override
  String get accountDeleteTitle => 'Eliminar mi cuenta';

  @override
  String get accountDeleteBody =>
      'Tu perfil se oculta de inmediato y todo se borra tras un periodo de gracia. Puedes cancelar durante ese tiempo iniciando sesión. Después no se podrá recuperar nada.';

  @override
  String get accountDeletionAlreadyScheduled => 'Eliminación ya programada';

  @override
  String get accountDeleteConfirmTitle => '¿Eliminar tu cuenta?';

  @override
  String get accountDeleteConfirmBody =>
      'Tu perfil, fotos, matches y mensajes se borrarán y no se podrán recuperar.\n\nSi solo quieres un descanso, ocultar tu perfil lo conserva todo y se puede deshacer.';

  @override
  String get accountHideInstead => 'Ocultar en su lugar';

  @override
  String get accountDeletionScheduledSnack =>
      'Eliminación programada. Puedes cancelarla hasta entonces.';

  @override
  String get privacyTitle => 'Privacidad y seguridad';

  @override
  String get privacyShowAge => 'Mostrar edad';

  @override
  String get privacyShowAgeSubtitle => 'Controla si tu edad es visible';

  @override
  String get privacyShowDistance => 'Mostrar distancia exacta';

  @override
  String get privacyShowDistanceSubtitle =>
      'Muestra la distancia precisa en tu perfil';

  @override
  String get privacyShowOnline => 'Mostrar estado en línea';

  @override
  String get privacyShowOnlineSubtitle =>
      'Permite que otros vean si estás en línea';

  @override
  String get privacyEmergencySos => 'SOS de emergencia';

  @override
  String get privacyEmergencySosSubtitle =>
      'Activa una alerta y revisa el historial';

  @override
  String get privacyEmergencyContacts => 'Contactos de emergencia';

  @override
  String get privacyEmergencyContactsSubtitle =>
      'Gestiona tus contactos de emergencia de confianza';

  @override
  String get privacyBlockedUsers => 'Usuarios bloqueados';

  @override
  String get privacyBlockedUsersSubtitle => 'Revisa y desbloquea usuarios';

  @override
  String get privacyModerationAppeals => 'Apelaciones de moderación';

  @override
  String get privacyModerationAppealsSubtitle =>
      'Envía una apelación y sigue su revisión';

  @override
  String get privacyFriendSearch =>
      'Dejar que me encuentren en la búsqueda de amigos';

  @override
  String get privacySettingLoadFailed =>
      'No se pudo cargar este ajuste. Vuelve a abrir esta página para reintentarlo.';

  @override
  String get privacyFriendSearchSubtitle =>
      'Los miembros pueden encontrarte por tu nombre o @usuario en Añadir amigo. Las personas con las que haces match o que conoces en salas y grupos aún pueden añadirte.';

  @override
  String get privacyChoiceSaveFailed => 'No se pudo guardar tu elección.';

  @override
  String get privacyShowcase => 'Mostrar mis escritos públicos en mi perfil';

  @override
  String get privacyShowcaseSubtitle =>
      'Los miembros pueden ver en tu perfil los capítulos que compartes con la comunidad y tus fotos del muro. Los capítulos privados o solo para amigos nunca aparecen.';

  @override
  String get privacyCrashReports => 'Compartir informes de errores';

  @override
  String get privacyCrashReportsSubtitle =>
      'Los informes anónimos de fallos y errores nos ayudan a solucionar problemas. No incluyen mensajes, fotos ni datos de la cuenta.';

  @override
  String get privacyGraduatedReason =>
      'Dejaste Connect con tu match. Tu tarjeta no se muestra a nadie.';

  @override
  String get privacyPausedReason =>
      'Tu tarjeta no se muestra a nadie hasta que reanudes.';

  @override
  String get privacyActiveReason =>
      'Se te muestra a otros miembros en Descubrir.';

  @override
  String get privacyDiscoveryPaused => 'Descubrir en pausa';

  @override
  String get privacyDiscoveryActive => 'Descubrir activo';

  @override
  String get privacyResume => 'Reanudar';

  @override
  String get privacyPause => 'Pausar';

  @override
  String get emergencyIntro =>
      'Añade hasta 3 contactos de confianza. Se usarán más adelante en los procesos de seguridad y las funciones SOS.';

  @override
  String get emergencyEmpty => 'Aún no has añadido contactos de emergencia.';

  @override
  String get emergencyMaxReached => 'Máximo de contactos alcanzado';

  @override
  String get emergencyAddContact => 'Añadir contacto';

  @override
  String get emergencyEditContact => 'Editar contacto';

  @override
  String get emergencyInvalidInput =>
      'Introduce un nombre y un número de teléfono válidos.';

  @override
  String get emergencyAdded => 'Contacto de emergencia añadido.';

  @override
  String get emergencyAddFailed =>
      'No se pudo añadir el contacto. Inténtalo de nuevo.';

  @override
  String get emergencyUpdated => 'Contacto de emergencia actualizado.';

  @override
  String get emergencyUpdateFailed =>
      'No se pudo actualizar el contacto. Inténtalo de nuevo.';

  @override
  String get emergencyRemoveTitle => 'Quitar contacto';

  @override
  String emergencyRemoveBody(String name) {
    return '¿Quitar a $name de tus contactos de emergencia?';
  }

  @override
  String get emergencyRemoved => 'Contacto de emergencia eliminado.';

  @override
  String get emergencyRemoveFailed =>
      'No se pudo quitar el contacto. Inténtalo de nuevo.';

  @override
  String get emergencyNameLabel => 'Nombre';

  @override
  String get emergencyPhoneLabel => 'Número de teléfono';

  @override
  String get appealsSubmitTitle => 'Enviar una apelación';

  @override
  String get appealsReasonLabel => 'Motivo';

  @override
  String get appealsReasonHint =>
      '¿Por qué debería revisarse esta decisión de moderación?';

  @override
  String get appealsReportIdLabel => 'ID de la denuncia (opcional)';

  @override
  String get appealsContextLabel => 'Contexto adicional (opcional)';

  @override
  String get appealsSubmit => 'Enviar apelación';

  @override
  String get appealsEmpty =>
      'Aún no has enviado apelaciones. Aquí aparecerán con su estado.';

  @override
  String appealsIdLine(String id) {
    return 'ID de apelación: $id';
  }

  @override
  String appealsSlaLine(String deadline) {
    return 'Plazo de revisión: $deadline';
  }

  @override
  String appealsReviewedBy(String reviewer) {
    return 'Revisado por: $reviewer';
  }

  @override
  String get appealsReasonRequired => 'El motivo es obligatorio.';

  @override
  String get appealsSubmitted => 'Apelación enviada correctamente.';

  @override
  String get appealsSubmitFailed =>
      'No se pudo enviar la apelación. Inténtalo de nuevo.';

  @override
  String get blockedEmpty => 'No has bloqueado a nadie.';

  @override
  String get blockedUnblock => 'Desbloquear';

  @override
  String get blockedUnblockTitle => 'Desbloquear usuario';

  @override
  String blockedUnblockBody(String name) {
    return '¿Desbloquear a $name?';
  }

  @override
  String blockedUnblockedSnack(String name) {
    return 'Has desbloqueado a $name.';
  }

  @override
  String get blockedUnblockFailed =>
      'No se pudo desbloquear. Inténtalo de nuevo.';

  @override
  String aboutVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get aboutDescription =>
      'App de citas basada en la confianza: perfiles auténticos, comunicación segura y relaciones serias.';

  @override
  String get aboutStack => 'Tecnología';

  @override
  String get aboutStackFlutter => 'Flutter (Android primero)';

  @override
  String get aboutStackGo => 'Servicios en Go + PostgreSQL nativo';

  @override
  String get aboutStackRiverpod => 'Gestión de estado con Riverpod';

  @override
  String get communitySpoiler => 'Spoiler: toca para ver';

  @override
  String get communityReportFailed => 'No se pudo enviar la denuncia.';

  @override
  String get communityReportSubmitted => 'Denuncia enviada. Gracias.';

  @override
  String communityBlockTitle(String name) {
    return '¿Bloquear a $name?';
  }

  @override
  String get communityBlockBody =>
      'Dejaréis de ver vuestras fotos, publicaciones de clubes, reseñas y listas. También se bloquea el contacto a través de Connect.';

  @override
  String get communityBlockAction => 'Bloquear miembro';

  @override
  String get communityBlockFailed =>
      'No se pudo bloquear a este miembro. Inténtalo de nuevo.';

  @override
  String get reportSheetTitle => 'Denunciar';

  @override
  String get reportReasonHarassment => 'Acoso';

  @override
  String get reportReasonInappropriate => 'Contenido inapropiado';

  @override
  String get reportReasonFraud => 'Fraude / estafa';

  @override
  String get reportReasonFake => 'Perfil falso';

  @override
  String get reportReasonLabel => 'Motivo';

  @override
  String get reportDescriptionLabel => 'Descripción (opcional)';

  @override
  String get reportDescriptionHint =>
      'Añade contexto para ayudar a revisar tu denuncia';

  @override
  String get reportSubmitFailed =>
      'No se pudo enviar la denuncia. Inténtalo de nuevo.';

  @override
  String get reportSubmit => 'Enviar denuncia';

  @override
  String get membershipTitle => 'Membresía';

  @override
  String get membershipChooseYourPlan => 'Elige tu plan';

  @override
  String get membershipCycleNoteMonthly =>
      'Pago con tarjeta. Se renueva automáticamente cada mes hasta que lo desactives.';

  @override
  String get membershipCycleNoteYearly =>
      'Pago con tarjeta. Se renueva automáticamente cada año hasta que lo desactives.';

  @override
  String get membershipNoPlansOnSale => 'Ahora mismo no hay planes a la venta.';

  @override
  String get membershipPaymentsTitle => 'Pagos';

  @override
  String get membershipNoCardPayments => 'Aún no hay pagos con tarjeta.';

  @override
  String get membershipFooterNote =>
      'Tu plan se renueva automáticamente al final de cada periodo de facturación. Puedes desactivar la renovación automática en cualquier momento; conservas tus ventajas hasta que termine el periodo. Los datos de la tarjeta los gestiona el proveedor de pagos y nunca se guardan en la app.';

  @override
  String membershipSwitchTitle(String plan) {
    return '¿Cambiar a $plan?';
  }

  @override
  String membershipSwitchUpgradeBodyMonthly(String price) {
    return 'Ahora se cobra en tu tarjeta la diferencia por lo que queda de este periodo y, a partir de la próxima renovación, $price al mes.';
  }

  @override
  String membershipSwitchUpgradeBodyYearly(String price) {
    return 'Ahora se cobra en tu tarjeta la diferencia por lo que queda de este periodo y, a partir de la próxima renovación, $price al año.';
  }

  @override
  String membershipSwitchDowngradeBodyMonthly(
    String currentPlan,
    String price,
  ) {
    return 'Tu plan cambia ahora. El tiempo no usado de $currentPlan se descuenta de tu próxima renovación y después pagas $price al mes.';
  }

  @override
  String membershipSwitchDowngradeBodyYearly(String currentPlan, String price) {
    return 'Tu plan cambia ahora. El tiempo no usado de $currentPlan se descuenta de tu próxima renovación y después pagas $price al año.';
  }

  @override
  String get membershipNotNow => 'Ahora no';

  @override
  String get membershipUpgrade => 'Mejorar plan';

  @override
  String get membershipSwitchPlan => 'Cambiar de plan';

  @override
  String membershipSwitchedSnack(String plan) {
    return 'Ya tienes $plan.';
  }

  @override
  String get membershipCardUpdated => 'Tu tarjeta se ha actualizado.';

  @override
  String get membershipCardUpdatePending =>
      'La actualización de la tarjeta aún no está confirmada. Comprueba su estado antes de volver a intentarlo.';

  @override
  String get membershipCardUpdateEnded =>
      'Esta sesión de actualización de tarjeta ha terminado. Actualiza para ver tu tarjeta actual.';

  @override
  String get membershipCheckoutTitleCard => 'tu tarjeta';

  @override
  String get membershipAutoRenewOffTitle =>
      '¿Desactivar la renovación automática?';

  @override
  String membershipAutoRenewOffBodyDate(String plan, String date) {
    return 'Tus ventajas de $plan siguen activas hasta el $date. Después pasas al plan gratuito y no se te vuelve a cobrar en la tarjeta.';
  }

  @override
  String membershipAutoRenewOffBodyPeriodEnd(String plan) {
    return 'Tus ventajas de $plan siguen activas hasta el final del periodo actual. Después pasas al plan gratuito y no se te vuelve a cobrar en la tarjeta.';
  }

  @override
  String get membershipKeepRenewing => 'Seguir renovando';

  @override
  String get membershipTurnOff => 'Desactivar';

  @override
  String get membershipAutoRenewBackOn =>
      'La renovación automática vuelve a estar activada.';

  @override
  String get membershipAutoRenewNowOff =>
      'La renovación automática está desactivada. Tus ventajas siguen hasta que termine el periodo.';

  @override
  String membershipSubscribeTitle(String plan) {
    return 'Suscribirse a $plan';
  }

  @override
  String membershipSubscribeBodyMonthly(String price) {
    return '$price al mes, cobrados en tu tarjeta y renovados automáticamente hasta que desactives la renovación automática. Introducirás tu tarjeta en la página segura del proveedor de pagos.';
  }

  @override
  String membershipSubscribeBodyYearly(String price) {
    return '$price al año, cobrados en tu tarjeta y renovados automáticamente hasta que desactives la renovación automática. Introducirás tu tarjeta en la página segura del proveedor de pagos.';
  }

  @override
  String membershipSubscribeBodyTestMonthly(String price) {
    return 'Solo pago de prueba: no se cobra nada real. $price al mes, simulados y renovados automáticamente hasta que desactives la renovación automática. Introducirás tu tarjeta en la página segura del proveedor de pagos.';
  }

  @override
  String membershipSubscribeBodyTestYearly(String price) {
    return 'Solo pago de prueba: no se cobra nada real. $price al año, simulados y renovados automáticamente hasta que desactives la renovación automática. Introducirás tu tarjeta en la página segura del proveedor de pagos.';
  }

  @override
  String get membershipContinueToCard => 'Ir a la tarjeta';

  @override
  String get paymentStillConfirming =>
      'El pago aún se está confirmando. Desliza hacia abajo para actualizar en un momento.';

  @override
  String get membershipCheckoutEnded =>
      'Esta sesión de pago ha terminado. Actualiza tu historial de pagos antes de volver a intentarlo.';

  @override
  String get membershipRecoverAccountUnavailable =>
      'No se pudo comprobar la cuenta de pago. Inténtalo de nuevo.';

  @override
  String get membershipRecoverCheckoutClosed =>
      'Cuenta de pago actualizada. Este pago ya no está abierto.';

  @override
  String get membershipRecoverConfirmed =>
      'Confirmado. Tu cuenta de pago está al día.';

  @override
  String get membershipRecoverPending =>
      'La confirmación sigue pendiente. Puedes volver a comprobarlo aquí.';

  @override
  String get membershipRecoverEnded =>
      'Esta sesión de pago ha terminado. Revisa tu historial de pagos antes de iniciar otra.';

  @override
  String membershipCelebrateTitle(String plan) {
    return 'Ya eres $plan';
  }

  @override
  String get membershipCelebrateBodyTest =>
      'Pago de prueba confirmado; no se ha cobrado dinero real. Tu plan de prueba se renueva automáticamente. Gestiona la renovación automática cuando quieras desde esta pantalla.';

  @override
  String get membershipCelebrateBody =>
      'Pago confirmado. Tu plan se renueva automáticamente. Gestiona la renovación automática cuando quieras desde esta pantalla.';

  @override
  String get membershipStartExploring => 'Empezar a explorar';

  @override
  String get membershipYourMembership => 'Tu membresía';

  @override
  String get membershipYourPlan => 'Tu plan';

  @override
  String get membershipFreePlanName => 'Gratis';

  @override
  String membershipPricePerMonthShort(String price) {
    return '$price/mes';
  }

  @override
  String membershipPricePerYearShort(String price) {
    return '$price/año';
  }

  @override
  String get membershipCardOnFile =>
      'Tarjeta guardada en el proveedor de pagos';

  @override
  String get membershipCardBrandFallback => 'Tarjeta';

  @override
  String get paymentOpening => 'Abriendo…';

  @override
  String get membershipUpdateCard => 'Cambiar tarjeta';

  @override
  String get membershipLastPaymentFailed =>
      'El último pago ha fallado. Volveremos a intentarlo con tu tarjeta; tus ventajas siguen activas unos días.';

  @override
  String membershipRenewsOn(String date) {
    return 'Se renueva el $date';
  }

  @override
  String get membershipRenewsSoon => 'Se renueva pronto';

  @override
  String membershipEndsOn(String date) {
    return 'Termina el $date · renovación automática desactivada';
  }

  @override
  String get membershipEndsSoon =>
      'Termina pronto · renovación automática desactivada';

  @override
  String get membershipAutoRenew => 'Renovación automática';

  @override
  String get membershipAutoRenewOnSubtitle =>
      'Se cobra automáticamente cada periodo.';

  @override
  String get membershipAutoRenewOffSubtitle =>
      'Desactivada. Las ventajas terminan con el periodo actual.';

  @override
  String get membershipFreeHeroBody =>
      'Desbloquea más me gusta, mensajes y destacados con un plan de abajo. Pago con tarjeta; cancela cuando quieras.';

  @override
  String get membershipStatusFree => 'Gratis';

  @override
  String get membershipStatusPaymentDue => 'Pago pendiente';

  @override
  String get membershipStatusEnding => 'Finaliza';

  @override
  String get membershipStatusActive => 'Activa';

  @override
  String get membershipCycleMonthly => 'Mensual';

  @override
  String get membershipCycleYearly => 'Anual';

  @override
  String get membershipBadgeYourPlan => 'TU PLAN';

  @override
  String get membershipBadgeMostPopular => 'EL MÁS POPULAR';

  @override
  String get membershipPerMonth => 'al mes';

  @override
  String get membershipPerYear => 'al año';

  @override
  String membershipSavePercent(int percent) {
    return 'Ahorra un $percent %';
  }

  @override
  String membershipQuotaLikesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count me gusta/día',
      one: '1 me gusta/día',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes/día',
      one: '1 mensaje/día',
    );
    return '$_temp0';
  }

  @override
  String get membershipQuotaUnlimitedLikes => 'Me gusta ilimitados';

  @override
  String get membershipQuotaUnlimitedMessages => 'Mensajes ilimitados';

  @override
  String get membershipYourCurrentPlan => 'Tu plan actual';

  @override
  String get membershipSwitching => 'Cambiando…';

  @override
  String get membershipOpeningSecureCheckout => 'Abriendo el pago seguro…';

  @override
  String membershipSwitchToPlan(String plan) {
    return 'Cambiar a $plan';
  }

  @override
  String get membershipSubscribeWithCard => 'Suscribirse con tarjeta';

  @override
  String get membershipSettleBeforeSwitch =>
      'Liquida el pago pendiente de tu plan actual antes de cambiar.';

  @override
  String get membershipPaymentChargeback => 'Contracargo';

  @override
  String get membershipPaymentDisputed => 'En disputa';

  @override
  String get membershipPaymentRefunded => 'Reembolsado';

  @override
  String get membershipPaymentPartlyRefunded => 'Reembolsado en parte';

  @override
  String get membershipPaymentFailed => 'Fallido';

  @override
  String get membershipPaymentPaid => 'Pagado';

  @override
  String get membershipPaymentPending => 'Pendiente';

  @override
  String get membershipPaymentReasonFirstCharge => 'Primer cobro';

  @override
  String get membershipPaymentReasonRenewal => 'Renovación';

  @override
  String get membershipPaymentReasonPlanChange => 'Cambio de plan';

  @override
  String get membershipPaymentReasonCoins => 'Monedas';

  @override
  String get membershipPaymentReasonLocalActivation => 'Activación local';

  @override
  String get membershipPaymentReasonCard => 'Pago con tarjeta';

  @override
  String get membershipPaymentReasonOther => 'Pago';

  @override
  String get paymentModeSandbox => 'Prueba local · sin cobro real';

  @override
  String get paymentModeStripeTest => 'Prueba de Stripe · sin cobro real';

  @override
  String get paymentModeLive => 'Pagos reales';

  @override
  String get paymentModeUnavailable => 'Pagos no disponibles';

  @override
  String get paymentAccountTitle => 'Tu cuenta de pago';

  @override
  String get paymentAccountSignedInMember => 'Miembro con sesión iniciada';

  @override
  String get paymentAccountCardTitle => 'Tarjeta de crédito o débito';

  @override
  String get paymentAccountCardUnavailableTitle =>
      'El pago con tarjeta no está disponible';

  @override
  String get paymentAccountCardBody =>
      'Introduce tu tarjeta en la página de pago alojada. La membresía y el historial de pagos pertenecen a esta cuenta.';

  @override
  String get paymentAccountCardUnavailableBody =>
      'Puedes seguir usando tu cuenta actual. Los nuevos pagos con tarjeta no están activados.';

  @override
  String paymentAccountTestCardHint(String cardNumber) {
    return 'Para probar, usa $cardNumber, una fecha de caducidad futura y cualquier CVC de tres dígitos. Usa solo datos de prueba.';
  }

  @override
  String get paymentAccountUnfinishedCardUpdate =>
      'Actualización de tarjeta sin terminar';

  @override
  String paymentAccountUnfinishedCheckout(String plan) {
    return 'Pago sin terminar: $plan';
  }

  @override
  String get paymentAccountPendingHint =>
      'Comprueba el último estado o continúa el mismo pago.';

  @override
  String get paymentAccountCheckStatus => 'Comprobar estado';

  @override
  String get paymentAccountResumeCheckout => 'Reanudar el pago';

  @override
  String paymentCheckoutPayFor(String title) {
    return 'Pagar: $title';
  }

  @override
  String get paymentCheckoutClose => 'Cerrar el pago';

  @override
  String get paymentCheckoutSecureNote =>
      'Los datos de la tarjeta se introducen en la página segura del proveedor de pagos.';

  @override
  String paymentCheckoutCompleteInNewTab(String title) {
    return 'Completa el pago ($title) en la nueva pestaña';
  }

  @override
  String get paymentCheckoutWaitingBody =>
      'Los datos de tu tarjeta se introducen en la página segura del proveedor de pagos. Vuelve aquí cuando indique que el pago se ha completado.';

  @override
  String get paymentCheckoutCheckConfirmation => 'Comprobar confirmación';

  @override
  String get paymentCheckoutBackToAccount => 'Volver a la cuenta';

  @override
  String get paymentWalletTitle => 'Monedero y pagos';

  @override
  String get paymentWalletTestNote =>
      'Pagos de prueba · sin cobro real. Usa solo datos de tarjeta de prueba.';

  @override
  String get paymentWalletPopularTopUps => 'Recargas populares';

  @override
  String get paymentWalletTopUpsIntro =>
      'Paga con tarjeta en la página de pago segura. Las monedas llegan a tu monedero en cuanto se liquida el pago.';

  @override
  String get paymentWalletCardsDisabled =>
      'Los pagos con tarjeta aún no están activados en este servidor.';

  @override
  String get paymentWalletNoPacks =>
      'Ahora mismo no hay paquetes de monedas a la venta.';

  @override
  String get paymentWalletActivity => 'Actividad del monedero';

  @override
  String get paymentWalletNoPurchases => 'Aún no hay compras de monedas.';

  @override
  String get paymentWalletFooter =>
      'Las monedas se usan para regalos e impulsos dentro de Connect. Las compras son definitivas una vez liquidadas; los datos de la tarjeta se quedan en el proveedor de pagos.';

  @override
  String paymentCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monedas',
      one: '1 moneda',
    );
    return '$_temp0';
  }

  @override
  String paymentCoinsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se han añadido $count monedas a tu monedero.',
      one: 'Se ha añadido 1 moneda a tu monedero.',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'monedas',
      one: 'moneda',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnitBonus(int count, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'monedas · +$bonus de regalo',
      one: 'moneda · +$bonus de regalo',
    );
    return '$_temp0';
  }

  @override
  String get paymentWalletCheckoutEnded =>
      'Esta sesión de pago ha terminado. Revisa tu historial de pagos antes de volver a intentarlo.';

  @override
  String get paymentWalletBalanceLabel => 'Saldo del monedero Glow';

  @override
  String get paymentWalletSourceSupport => 'Recarga del equipo de soporte';

  @override
  String get paymentWalletSourcePromo => 'Promoción';

  @override
  String get paymentWalletSourcePurchase => 'Compra de monedas';

  @override
  String get paymentErrorSignInSubscriptions =>
      'Inicia sesión para gestionar las suscripciones.';

  @override
  String get paymentErrorSignInWallet =>
      'Inicia sesión para gestionar tu monedero.';

  @override
  String get paymentErrorLoadSubscription =>
      'No se pudieron cargar los detalles de la suscripción.';

  @override
  String get paymentErrorLoadWallet => 'No se pudo cargar tu monedero.';

  @override
  String get paymentErrorStartCheckoutNow =>
      'Ahora mismo no se puede iniciar el pago.';

  @override
  String get paymentErrorStartCheckout => 'No se pudo iniciar el pago.';

  @override
  String get paymentErrorConfirmPayment => 'Aún no se puede confirmar el pago.';

  @override
  String get paymentErrorAutoRenewOn =>
      'No se pudo volver a activar la renovación automática.';

  @override
  String get paymentErrorAutoRenewOff =>
      'No se pudo desactivar la renovación automática.';

  @override
  String get paymentErrorChangePlan => 'No se pudo cambiar de plan.';

  @override
  String get paymentErrorUpdateCard => 'No se pudo actualizar la tarjeta.';

  @override
  String get paymentErrorSandboxFailed =>
      'La simulación de sandbox ha fallado.';

  @override
  String get paymentErrorUnreachable =>
      'No se puede conectar con el servicio local. Comprueba que la API esté en marcha.';

  @override
  String membershipQuotaLikesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Hoy quedan $remaining de $limit me gusta',
      one: 'Hoy quedan $remaining de 1 me gusta',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Hoy quedan $remaining de $limit mensajes',
      one: 'Hoy quedan $remaining de 1 mensaje',
    );
    return '$_temp0';
  }

  @override
  String membershipLikeLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Has usado tus $limit me gusta de hoy con $plan',
      one: 'Has usado tu me gusta de hoy con $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipMessageLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Has usado tus $limit mensajes de hoy con $plan',
      one: 'Has usado tu mensaje de hoy con $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaResetsAt(String time) {
    return 'Se restablece a las $time';
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
      'Un poco más cerca, mensaje a mensaje.';

  @override
  String get matchesSubtitlePeople =>
      'Personas que has elegido. Posibilidades para construir juntos.';

  @override
  String get matchesSearchConversations => 'Buscar conversaciones';

  @override
  String get matchesSearchMatches => 'Buscar entre tus matches';

  @override
  String get matchesFilterAllConversations => 'Todas las conversaciones';

  @override
  String matchesFilterUnread(int count) {
    return 'No leídos · $count';
  }

  @override
  String get matchesLoading => 'Cargando matches…';

  @override
  String get matchesLoadErrorTitle => 'No se pudieron cargar los matches';

  @override
  String get matchesRetry => 'Reintentar';

  @override
  String get matchesEmptyTitle => 'Aún no hay matches';

  @override
  String matchesTrustFilteredHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Los filtros de confianza ocultaron $count matches. Prueba a relajarlos desde Descubrir.',
      one:
          'Los filtros de confianza ocultaron 1 match. Prueba a relajarlos desde Descubrir.',
    );
    return '$_temp0';
  }

  @override
  String get matchesEmptyBody =>
      'Visita Hoy para descubrir a alguien a quien te gustaría conocer.';

  @override
  String get matchesNoConversationResults =>
      'Aún no hay conversaciones aquí. Prueba otra búsqueda u otro filtro.';

  @override
  String get matchesNoPeopleResults =>
      'No se encontraron matches. Prueba con otro nombre.';

  @override
  String get matchesTabPeople => 'Tus matches';

  @override
  String get matchesTabConversations => 'Conversaciones';

  @override
  String get matchesActionStartCall => 'Iniciar llamada';

  @override
  String get matchesActionStartActivity => 'Empezar una actividad';

  @override
  String get matchesActionPlanDate => 'Planear una cita';

  @override
  String get matchesActionPlanDateSubtitle =>
      'Elige un momento y lo que quieres compartir';

  @override
  String matchesPlanSent(String name) {
    return 'Plan enviado a $name.';
  }

  @override
  String get matchesActionGraduate => 'Nos hemos encontrado';

  @override
  String get matchesActionGraduateSubtitle =>
      'Dejad Connect juntos; vuestro chat se queda';

  @override
  String matchesGraduationAsked(String name) {
    return 'Le has pedido a $name salir juntos. Puede confirmarlo desde vuestro chat.';
  }

  @override
  String get matchesActionNudge => 'Enviar un toque';

  @override
  String matchesNudgeSent(String name) {
    return 'Toque enviado a $name.';
  }

  @override
  String get matchesNudgeFailed => 'No se pudo enviar el toque.';

  @override
  String get matchesActionClose => 'Cerrar conversación';

  @override
  String get matchesActionCloseSubtitle =>
      'Toma distancia, sin dar explicaciones.';

  @override
  String get matchesCloseDialogTitle => '¿Cerrar esta conversación?';

  @override
  String get matchesCloseDialogBody =>
      'No pasa nada si esta conexión no es para ti. Esto termina el match. No necesitas dar explicaciones. Denunciar sigue siendo una decisión aparte.';

  @override
  String get matchesCloseDialogKeep => 'Seguir hablando';

  @override
  String get matchesActionReport => 'Denunciar';

  @override
  String get matchesReportSubmitted => 'Denuncia enviada. Gracias.';

  @override
  String get matchesReportAppeal => 'Apelar';

  @override
  String matchesAppealReason(String userId) {
    return 'Revisar el resultado de moderación de la denuncia sobre el usuario $userId';
  }

  @override
  String get matchesBothChose => 'Los dos habéis elegido conectar';

  @override
  String matchesOptionsTooltip(String name) {
    return 'Opciones del match con $name';
  }

  @override
  String matchesChatUnread(int count) {
    return 'Chat · $count sin leer';
  }

  @override
  String get matchesOpenChat => 'Abrir chat';

  @override
  String get matchesFirstChapter => 'Primer Capítulo';

  @override
  String get matchesUnknownName => 'Desconocido';

  @override
  String get matchesSayHi => 'Saluda 👋';

  @override
  String get matchesFallbackName => 'Tu match';

  @override
  String get matchesFallbackMessage => 'Empieza la conversación';

  @override
  String get matchesGiftPreview => 'Un pequeño regalo en vuestra conversación';

  @override
  String matchesConversationOptionsTooltip(String name) {
    return 'Opciones de la conversación con $name';
  }

  @override
  String get matchesTimeNow => 'Ahora';

  @override
  String matchesTimeMinutesAgo(int minutes) {
    return 'hace $minutes min';
  }

  @override
  String matchesTimeHoursAgo(int hours) {
    return 'hace $hours h';
  }

  @override
  String get matchesTimeToday => 'Hoy';

  @override
  String get matchesTimeYesterday => 'Ayer';

  @override
  String get matchesNewMatchTitle => 'Nuevo match';

  @override
  String get matchesItsAMatch => '¡Es un match!';

  @override
  String matchesLikedEachOther(String name) {
    return 'Tú y $name os habéis gustado';
  }

  @override
  String get matchesSendMessage => 'Enviar mensaje';

  @override
  String get matchesKeepSwiping => 'Seguir deslizando';

  @override
  String get matchesErrorLoginRequired => 'Inicia sesión para ver tus matches.';

  @override
  String get matchesErrorLoadFailed =>
      'No se pudieron cargar los matches. Inténtalo de nuevo.';

  @override
  String get matchesErrorUnmatchFailed => 'No se pudo deshacer el match.';

  @override
  String get matchesErrorMarkReadFailed => 'No se pudo marcar como leído.';

  @override
  String get matchesErrorSessionUnavailable =>
      'La sesión de usuario no está disponible.';

  @override
  String get matchesTrustBadgePromptCompleter => 'Completa los prompts';

  @override
  String get matchesTrustBadgeRespectful => 'Comunicación respetuosa';

  @override
  String get matchesTrustBadgeConsistent => 'Perfil coherente';

  @override
  String get matchesTrustBadgeVerifiedActive => 'Verificado y activo';

  @override
  String get matchesTrustErrorLoad =>
      'No se pudieron cargar los filtros de confianza. Inténtalo de nuevo.';

  @override
  String get matchesTrustErrorSave =>
      'No se pudieron guardar los filtros de confianza. Inténtalo de nuevo.';

  @override
  String get matchesGestureErrorLoad => 'No se pudo cargar el historial';

  @override
  String get matchesGestureErrorPending =>
      'Los gestos se desbloquean cuando esta conversación pendiente se convierte en un match real.';

  @override
  String get matchesGestureErrorSend => 'No se pudo enviar el gesto.';

  @override
  String get matchesGestureErrorUpdate =>
      'No se pudo actualizar el estado del gesto.';

  @override
  String get matchesActivityTitle => 'Esto o aquello en 2 minutos';

  @override
  String get matchesActivityRestartTooltip => 'Empezar una nueva sesión';

  @override
  String matchesActivityCompleteWith(String name) {
    return 'Complétalo con $name';
  }

  @override
  String get matchesActivityInstructions =>
      'Responde las 8 rondas antes de que se acabe el tiempo.';

  @override
  String matchesActivityStatus(String status) {
    return 'Estado: $status';
  }

  @override
  String get matchesActivityStatusActive => 'activa';

  @override
  String get matchesActivityStatusTimedOut => 'tiempo agotado';

  @override
  String get matchesActivityStatusPartialTimeout =>
      'tiempo agotado parcialmente';

  @override
  String get matchesActivityStatusCompleted => 'completada';

  @override
  String get matchesActivitySubmit => 'Enviar respuestas';

  @override
  String get matchesActivityTimeUpLoad => 'Se acabó el tiempo — Cargar resumen';

  @override
  String get matchesActivityWaiting =>
      'Respuestas enviadas. Esperando a que la otra persona termine.';

  @override
  String get matchesActivityRefreshSummary => 'Actualizar resumen';

  @override
  String matchesActivityTimeLeft(String time) {
    return 'Tiempo restante $time';
  }

  @override
  String get matchesActivitySummaryTitle => 'Resumen de la actividad';

  @override
  String matchesActivityParticipantsCompleted(int completed, int total) {
    return 'Participantes que terminaron: $completed/$total';
  }

  @override
  String get matchesActivitySummaryPending =>
      'El resumen aparecerá en cuanto esté disponible.';

  @override
  String get matchesActivityShareResult => 'Compartir resultado en el chat';

  @override
  String matchesActivityShareMessage(String status, int completed, int total) {
    return 'Resultado de Esto o aquello (2 min): $status • $completed/$total completado';
  }

  @override
  String matchesActivityShareMessageWithInsight(
    String status,
    int completed,
    int total,
    String insight,
  ) {
    return 'Resultado de Esto o aquello (2 min): $status • $completed/$total completado • $insight';
  }

  @override
  String matchesActivityRound(int number) {
    return 'Ronda $number';
  }

  @override
  String get matchesActivityErrorStart =>
      'No se puede empezar la actividad ahora. Inténtalo de nuevo.';

  @override
  String get matchesActivityErrorNotReady => 'La sesión aún no está lista.';

  @override
  String get matchesActivityErrorAnswerAll =>
      'Responde todas las preguntas antes de enviar.';

  @override
  String get matchesActivityErrorTimeUp =>
      'Se acabó el tiempo. Cargando el resumen…';

  @override
  String get matchesActivityErrorSubmit =>
      'No se pudieron enviar tus respuestas. Inténtalo de nuevo.';

  @override
  String get matchesActivityErrorSummary =>
      'Aún no se puede obtener el resumen. Inténtalo de nuevo.';

  @override
  String get matchesActivityQ1Prompt => '¿Primera cita ideal?';

  @override
  String get matchesActivityQ1OptionA => 'Paseo con café';

  @override
  String get matchesActivityQ1OptionB => 'Curiosear en una librería';

  @override
  String get matchesActivityQ2Prompt => '¿Plan de fin de semana preferido?';

  @override
  String get matchesActivityQ2OptionA => 'Quedarse en casa y recargar pilas';

  @override
  String get matchesActivityQ2OptionB => 'Explorar la ciudad';

  @override
  String get matchesActivityQ3Prompt => '¿Mejor lugar para conversar?';

  @override
  String get matchesActivityQ3OptionA => 'Paseo largo';

  @override
  String get matchesActivityQ3OptionB => 'Rincón acogedor de una cafetería';

  @override
  String get matchesActivityQ4Prompt => '¿Cómo planeas las citas?';

  @override
  String get matchesActivityQ4OptionA => 'Espontáneamente';

  @override
  String get matchesActivityQ4OptionB => 'Con antelación';

  @override
  String get matchesActivityQ5Prompt => '¿Qué te importa más ahora mismo?';

  @override
  String get matchesActivityQ5OptionA => 'Constancia';

  @override
  String get matchesActivityQ5OptionB => 'Emoción';

  @override
  String get matchesActivityQ6Prompt =>
      '¿Cómo prefieres resolver los conflictos?';

  @override
  String get matchesActivityQ6OptionA => 'Resolverlo el mismo día';

  @override
  String get matchesActivityQ6OptionB => 'Tomar distancia y retomarlo';

  @override
  String get matchesActivityQ7Prompt => '¿Qué actividad compartirías?';

  @override
  String get matchesActivityQ7OptionA => 'Cocinar juntos';

  @override
  String get matchesActivityQ7OptionB => 'Entrenar juntos';

  @override
  String get matchesActivityQ8Prompt => '¿Qué ritmo prefieres?';

  @override
  String get matchesActivityQ8OptionA => 'Tranquilo y con intención';

  @override
  String get matchesActivityQ8OptionB => 'Rápido y con energía';

  @override
  String get cityPilotSaveFailed =>
      'No pudimos confirmar ese cambio. Actualiza para comprobarlo antes de volver a intentarlo.';

  @override
  String get cityPilotLeaveTitle => '¿Salir del piloto de tu ciudad?';

  @override
  String get cityPilotLeaveBody =>
      'Tus reservas del piloto se cancelarán y se eliminarán tus opiniones sobre las experiencias. Tu actividad dejará de contar en los resultados actuales. Tus matches y conversaciones se mantienen. No podrás volver a unirte a este piloto.';

  @override
  String get cityPilotStay => 'Seguir en el piloto';

  @override
  String get cityPilotLeave => 'Salir del piloto';

  @override
  String get cityPilotLeftNotice =>
      'Has salido del piloto. Tus matches se quedan contigo.';

  @override
  String cityPilotJoinEventTitle(String title) {
    return '¿Unirte a $title?';
  }

  @override
  String cityPilotBookingTerms(
    String host,
    String safetyContact,
    String accessibility,
  ) {
    return 'Esta experiencia es gratuita. El encuentro es en un lugar público: respeta los límites de los demás y organiza tu propio transporte. Puedes irte en cualquier momento.\n\nAnfitrión: $host\nContacto de seguridad: $safetyContact\n\nAccesibilidad: $accessibility\n\nEn caso de peligro inmediato, contacta con los servicios de emergencia locales.';
  }

  @override
  String get cityPilotAcceptReserve => 'Aceptar y reservar plaza';

  @override
  String get cityPilotReservedNotice =>
      'Tu plaza está reservada. Puedes cancelarla aquí en cualquier momento.';

  @override
  String get cityPilotFeedbackTitle => '¿Qué tal la experiencia?';

  @override
  String get cityPilotFeedbackIntro =>
      'Opcional. Las respuestas se suman a los resultados combinados del piloto. No se muestran a otros miembros ni al anfitrión.';

  @override
  String get cityPilotDidYouAttend => '¿Asististe?';

  @override
  String get cityPilotAttendedYes => 'Sí, fui';

  @override
  String get cityPilotAttendedNo => 'No pude ir';

  @override
  String get cityPilotWorthwhileQuestion => '¿Mereció la pena? (opcional)';

  @override
  String get cityPilotNotThisTime => 'Esta vez no';

  @override
  String get cityPilotSkip => 'Omitir';

  @override
  String get cityPilotShareFeedback => 'Enviar opinión';

  @override
  String get cityPilotFeedbackThanks =>
      'Gracias. Tu opinión se ha registrado de forma privada.';

  @override
  String get cityPilotTimeTbc => 'Hora por confirmar';

  @override
  String get cityPilotTitle => 'El piloto de tu ciudad';

  @override
  String get cityPilotRefreshTooltip => 'Actualizar el piloto';

  @override
  String get cityPilotHeroTitle => 'Un poco más cerca.\nMucho más real.';

  @override
  String get cityPilotHeroBody =>
      'Una ciudad. Una comunidad pequeña. Más oportunidades de que una conversación se convierta en un plan.';

  @override
  String get cityPilotStep1Title => 'Empieza con una conversación';

  @override
  String get cityPilotStep1Body =>
      'Conoce gente a tu ritmo a través de tus presentaciones actuales.';

  @override
  String get cityPilotStep2Title => 'Haz sitio para una cita real';

  @override
  String get cityPilotStep2Body =>
      'Preparad un plan juntos. Cuenta cómo fue solo si quieres.';

  @override
  String get cityPilotStep3Title => 'Probad algo juntos';

  @override
  String get cityPilotStep3Body =>
      'Las pequeñas experiencias con anfitrión llegarán tras la primera revisión del piloto.';

  @override
  String get cityPilotSaving => 'Guardando tu preferencia del piloto';

  @override
  String get cityPilotUnavailableTitle => 'Tu piloto no está disponible';

  @override
  String get cityPilotUnavailableBody =>
      'Comprueba tu conexión y actualiza para ver tu participación y reservas más recientes.';

  @override
  String get cityPilotComingSoonTitle => 'Pronto en una ciudad cerca de ti';

  @override
  String get cityPilotComingSoonBody =>
      'Todavía no hay un piloto abierto para la ciudad de tu perfil. Cuando se abra uno, podrás elegir si participas. Tu experiencia de citas actual sigue como siempre.';

  @override
  String cityPilotPanelTitleJoined(String city) {
    return '$city · Formas parte';
  }

  @override
  String cityPilotPanelTitleOpen(String city) {
    return '$city · Piloto en la ciudad';
  }

  @override
  String cityPilotRecruitmentCloses(String date) {
    return 'Cierre de inscripciones: $date (tu hora local).';
  }

  @override
  String get cityPilotPaused =>
      'Las nuevas inscripciones y reservas están en pausa. Aún puedes salir o cancelar.';

  @override
  String get cityPilotCompleted =>
      'Este piloto ha terminado. Gracias por formar parte.';

  @override
  String get cityPilotMeasurement =>
      'Al unirte, podemos contar conversaciones, planes aceptados y respuestas opcionales a «¿hubo cita?» en los nuevos matches en los que ambas personas se unieron a este piloto. Usamos ventanas de 7 días para conversaciones y de 28 días para citas. No leemos el texto de los mensajes ni las notas privadas de opinión para el piloto.';

  @override
  String get cityPilotPrivacy =>
      'Tu participación es privada. No hay lista pública de asistencia ni puntuación de citas. Si sales, tu actividad se excluye de los resultados actuales y se cancelan tus reservas. Los resultados combinados ya revisados no se pueden deshacer.';

  @override
  String get cityPilotConsent =>
      'Acepto participar en este piloto y en la medición de sus resultados.';

  @override
  String get cityPilotJoinedNotice =>
      'Ya estás dentro. Sigue conociendo gente a tu ritmo.';

  @override
  String get cityPilotJoin => 'Unirme al piloto';

  @override
  String get cityPilotWithdrawn =>
      'Has salido de este piloto. Tus matches y conversaciones no cambian.';

  @override
  String get cityPilotNotAccepting =>
      'Este piloto no admite nuevos miembros por ahora.';

  @override
  String get cityPilotExperiencesHeading =>
      'Planes pequeños. Experiencias compartidas.';

  @override
  String get cityPilotNoExperiences =>
      'Las experiencias con anfitrión aún no están abiertas. Aparecerán aquí tras una revisión de resultados y seguridad.';

  @override
  String cityPilotEventDetails(
    String start,
    String end,
    String venue,
    String host,
  ) {
    return '$start → $end\nTu hora local · Gratis\n$venue\nAnfitrión: $host';
  }

  @override
  String cityPilotAccessibility(String details) {
    return 'Accesibilidad · $details';
  }

  @override
  String cityPilotSafetyContact(String contact) {
    return 'Contacto de seguridad · $contact';
  }

  @override
  String get cityPilotEventCancelled =>
      'Esta experiencia se ha cancelado. Por favor, no vayas al lugar.';

  @override
  String get cityPilotPlaceReserved => 'Tu plaza está reservada.';

  @override
  String get cityPilotBookingCancelled => 'Tu reserva está cancelada.';

  @override
  String get cityPilotCancelPlace => 'Cancelar mi plaza';

  @override
  String get cityPilotReserveFree => 'Reservar una plaza gratis';

  @override
  String get cityPilotShareOptionalFeedback => 'Compartir opinión opcional';

  @override
  String get cityPilotFeedbackReceived => 'Hemos recibido tu opinión. Gracias.';

  @override
  String get blogAudiencePrivate => 'Solo yo';

  @override
  String get blogAudienceFriends => 'Amigos';

  @override
  String get blogAudienceCommunity => 'Comunidad Connect';

  @override
  String get blogInvitationNone => 'Sin invitación';

  @override
  String get blogInvitationYourVersion => '¿Cómo sería tu versión?';

  @override
  String get blogInvitationTeachMe => '¿Qué podrías enseñarme sobre esto?';

  @override
  String get blogInvitationWhatNext => '¿Qué probarías después?';

  @override
  String get blogRewardStoryPublishedTitle => 'Compartir un capítulo';

  @override
  String get blogRewardStoryPublishedWho =>
      'Tú, la primera vez que compartes un capítulo más allá de «Solo yo»';

  @override
  String get blogRewardPhotoSharedTitle =>
      'Compartir una foto en Temas de fotos';

  @override
  String get blogRewardPhotoSharedWho =>
      'Tú, por una foto que compartes en Temas de fotos';

  @override
  String get blogRewardLikeReceivedTitle => 'Un me gusta en tu capítulo o foto';

  @override
  String get blogRewardLikeReceivedWho =>
      'Tú, por cada miembro al que le gusta';

  @override
  String get blogRewardCommentReceivedTitle => 'Un comentario que apruebas';

  @override
  String get blogRewardCommentReceivedWho =>
      'Tú, cuando apruebas el comentario de un lector';

  @override
  String get blogRewardCommentApprovedTitle => 'Tu comentario es aprobado';

  @override
  String get blogRewardCommentApprovedWho =>
      'Tú, cuando un autor aprueba tu comentario';

  @override
  String get blogRewardSubscriberGainedTitle => 'Un nuevo seguidor';

  @override
  String get blogRewardSubscriberGainedWho =>
      'Tú, por cada nuevo miembro que sigue tus capítulos';

  @override
  String get blogRewardWallTierTitle => 'Llegar a más muros';

  @override
  String get blogRewardWallTierWho =>
      'Tú, cada vez que un capítulo alcanza un nuevo nivel de muros';

  @override
  String get blogRewardCoverOfWeekTitle => 'Portada de la semana';

  @override
  String get blogRewardCoverOfWeekWho =>
      'Tú, cuando tu trabajo es elegido Portada de la semana';

  @override
  String get blogScopeForYou => 'Para ti';

  @override
  String get blogScopeTopRated => 'Mejor valorados';

  @override
  String get blogScopeFollowing => 'Siguiendo';

  @override
  String get blogScopeMine => 'Míos';

  @override
  String get blogScopeCaptionMine =>
      'Tus borradores y capítulos publicados. Tú eliges el público de cada uno.';

  @override
  String get blogScopeCaptionFriends =>
      'Capítulos compartidos por tus amigos de Connect.';

  @override
  String get blogScopeCaptionTop =>
      'Ordenados por me gusta, comentarios aprobados y lectores de los últimos 30 días.';

  @override
  String get blogScopeCaptionFollowing =>
      'Los capítulos más recientes de los autores que sigues.';

  @override
  String get blogScopeCaptionCommunity =>
      'Para miembros de Connect que cumplen los requisitos y han iniciado sesión. Estos capítulos no son públicos en la web.';

  @override
  String get blogTitle => 'Capítulos abiertos';

  @override
  String get blogRewardsTitle => 'Cómo funcionan las recompensas';

  @override
  String get blogWritersTitle => 'Autores que sigues';

  @override
  String get blogConnectionsTooltip =>
      'Respuestas privadas, enlaces compartidos y avisos';

  @override
  String get blogSignInReadWrite =>
      'Inicia sesión para leer y escribir capítulos.';

  @override
  String get blogHeroTitle => 'Una vida que\nmerece conocerse.';

  @override
  String get blogHeroBody =>
      'La historia detrás de una foto. Una pequeña obsesión. Algo que aún estás aprendiendo. Deja que tu día a día hable por ti.';

  @override
  String get blogWriteChapter => 'Escribir un capítulo';

  @override
  String get blogPrivateResponses => 'Respuestas privadas';

  @override
  String get blogSharedLinks => 'Enlaces compartidos';

  @override
  String get blogReviewNotices => 'Avisos de revisión';

  @override
  String get blogTopicAll => 'Todos';

  @override
  String get blogFeedLoadFailed => 'No se pudieron cargar los capítulos.';

  @override
  String get blogPreviousPage => 'Página anterior';

  @override
  String get blogMoreChapters => 'Más capítulos';

  @override
  String get blogEmptyMineTitle => 'Tu próximo capítulo empieza aquí.';

  @override
  String get blogEmptyMineBody =>
      'Empieza por un momento sobre el que te encantaría que alguien te preguntara. Tu primer borrador es solo para ti.';

  @override
  String get blogEmptyTopTitle => 'Cuando los capítulos emocionan, suben aquí.';

  @override
  String get blogEmptyTopFilteredBody =>
      'Aún no ha subido nada en este tema. Prueba con «Todos» o comparte un capítulo propio.';

  @override
  String get blogEmptyTopBody =>
      'Aquí aparecerán los capítulos que más gustaron a los lectores en los últimos 30 días.';

  @override
  String get blogEmptyFollowingFilteredTitle =>
      'Todavía no hay nada nuevo en este tema.';

  @override
  String get blogEmptyFollowingTitle =>
      'Aquí aparecerán los autores que sigues.';

  @override
  String get blogEmptyFollowingBody =>
      'Cuando un capítulo te llegue, ábrelo y toca «Seguir sus capítulos». Sus nuevos capítulos se reunirán aquí para que no te pierdas nada.';

  @override
  String get blogEmptyCommunityTitle =>
      'Por ahora, esto está un poco tranquilo.';

  @override
  String get blogEmptyCommunityBody =>
      'Los capítulos aparecen aquí cuando los miembros deciden compartirlos con este público.';

  @override
  String get blogFindWritersTopRated =>
      'Encontrar autores en «Mejor valorados»';

  @override
  String blogRankTooltip(int rank) {
    return 'Número $rank en «Mejor valorados»';
  }

  @override
  String get blogUntitled => 'Un capítulo sin título';

  @override
  String get blogDraftPlaceholder =>
      'Un borrador privado esperando tus palabras.';

  @override
  String get blogReadEdit => 'Leer y editar →';

  @override
  String get blogReadChapter => 'Leer capítulo →';

  @override
  String get blogPhotoUnavailableRetry => 'Foto no disponible · Reintentar';

  @override
  String get blogTryAgain => 'Reintentar';

  @override
  String get blogDetailTitle => 'Un capítulo';

  @override
  String get blogSignInRead => 'Inicia sesión para leer capítulos.';

  @override
  String get blogDetailUnavailable =>
      'Este capítulo no está disponible o su público ha cambiado.';

  @override
  String get blogRespondPrivately => 'Responder en privado';

  @override
  String get blogCreatePublicPreview => 'Crear una vista previa pública';

  @override
  String get blogRemovedByModerationNote =>
      'Eliminado por moderación. Abre «Avisos de revisión» para leer la decisión o pedir otra revisión.';

  @override
  String get blogEditChapter => 'Editar capítulo';

  @override
  String get blogDeleteChapter => 'Eliminar capítulo';

  @override
  String get blogDeleteChapterTitle => '¿Eliminar este capítulo?';

  @override
  String get blogDeleteChapterMessage =>
      'Desaparecerá para todos los públicos. No se puede deshacer.';

  @override
  String get blogDeleteChapterFailed =>
      'No se pudo confirmar la eliminación. Recarga el capítulo antes de reintentarlo.';

  @override
  String get blogReportChapter => 'Denunciar capítulo';

  @override
  String get blogReportFailed => 'No se pudo enviar la denuncia.';

  @override
  String get blogBlockThisMember => 'Bloquear a este miembro';

  @override
  String get blogBlockTitle => '¿Bloquear a este miembro?';

  @override
  String get blogBlockMessageChapter =>
      'Ya no veréis los capítulos del otro. También se bloquea el contacto a través de Connect.';

  @override
  String get blogBlockMember => 'Bloquear miembro';

  @override
  String get blogBlockRetryFailed =>
      'No se pudo bloquear a este miembro. Inténtalo de nuevo.';

  @override
  String get blogCancel => 'Cancelar';

  @override
  String get blogEditorMissingFields =>
      'Añade un título y una historia antes de publicar.';

  @override
  String blogPublishConfirmTitle(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': '¿Publicar para «Solo yo»?',
      'friends': '¿Publicar para tus amigos?',
      'community': '¿Publicar en la comunidad Connect?',
      'other': '¿Publicar?',
    });
    return '$_temp0';
  }

  @override
  String get blogPublishFriendsBody =>
      'Tus amigos de Connect podrán leer el texto y ver las fotos de este capítulo. Puedes cambiar el público más adelante.';

  @override
  String get blogPublishCommunityBody =>
      'Los miembros de Connect que cumplan los requisitos y hayan iniciado sesión podrán leer este capítulo. No aparecerá en la web pública. Puedes cambiar el público más adelante.';

  @override
  String get blogPublishChapter => 'Publicar capítulo';

  @override
  String get blogSavedOnlyMe => 'Guardado. Solo tú puedes leer este capítulo.';

  @override
  String blogPublishedTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Publicado para «Solo yo».',
      'friends': 'Publicado para tus amigos.',
      'community': 'Publicado en la comunidad Connect.',
      'other': 'Publicado.',
    });
    return '$_temp0';
  }

  @override
  String get blogSharedSnack =>
      'Compartido. Los me gusta y comentarios de los lectores te dan XP.';

  @override
  String get blogSeeMyLevel => 'Ver mi nivel';

  @override
  String get blogSaveUnconfirmed => 'No pudimos confirmar el guardado.';

  @override
  String blogEditsStillHere(String message) {
    return '$message Tus cambios siguen aquí. Comprueba la versión guardada antes de continuar.';
  }

  @override
  String blogSavedVersionTitle(String audience) {
    return 'Versión guardada · $audience';
  }

  @override
  String get blogSavedVersionNote =>
      'Tus cambios actuales siguen en el editor. Cierra este panel para conservarlos o sustitúyelos por esta versión guardada.';

  @override
  String get blogKeepMyEdits =>
      'Conservar mis cambios para el próximo guardado';

  @override
  String get blogUseSavedVersion => 'Usar la versión guardada';

  @override
  String get blogSavedVersionLoadFailed =>
      'No se pudo cargar la versión guardada. Tus cambios siguen aquí.';

  @override
  String get blogDescribePhotoTitle => 'Describe tu foto';

  @override
  String get blogDescribePhotoBody =>
      'Una breve descripción hace tu capítulo accesible. Al añadir la foto, tus palabras se guardan como borrador «Solo yo».';

  @override
  String get blogDescribePhotoLabel => '¿Qué hay en esta foto?';

  @override
  String get blogAddToPrivateDraft => 'Añadir al borrador privado';

  @override
  String get blogPhotoAdded => 'Foto añadida a tu borrador privado.';

  @override
  String get blogPhotoAddFailed =>
      'No se pudo añadir la foto. Usa un JPEG o PNG de hasta 10 MB.';

  @override
  String blogCheckSavedBeforeRetrying(String message) {
    return '$message Comprueba la versión guardada antes de reintentarlo.';
  }

  @override
  String get blogRemoveUnconfirmed =>
      'No se pudo confirmar la eliminación. Comprueba la versión guardada.';

  @override
  String get blogSignInAsAuthor =>
      'Inicia sesión como autor para editar este capítulo.';

  @override
  String get blogLeaveEditorTitle => '¿Salir sin guardar?';

  @override
  String get blogLeaveEditorMessage =>
      'Perderás los cambios sin guardar. Tu último capítulo guardado se mantendrá.';

  @override
  String get blogLeaveEditor => 'Salir del editor';

  @override
  String get blogEditorPreviewTitle => 'Vista previa del capítulo';

  @override
  String get blogEditorTitle => 'Tu próximo capítulo';

  @override
  String get blogEditorHeadline => 'Un poco más de ti.';

  @override
  String get blogEditorIntro =>
      'Las historias pequeñas son bienvenidas. Una comida que preparaste. Un lugar que te hizo cambiar de opinión. La foto que esconde una historia.';

  @override
  String get blogNotSavedDefault => 'Sin guardar · «Solo yo» por defecto';

  @override
  String blogSavedFor(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Guardado para «Solo yo»',
      'friends': 'Guardado para tus amigos',
      'community': 'Guardado para la comunidad Connect',
      'other': 'Guardado',
    });
    return '$_temp0';
  }

  @override
  String get blogKeepWriting => 'Seguir escribiendo';

  @override
  String get blogPreview => 'Vista previa';

  @override
  String get blogCheckSavedVersion => 'Comprobar la versión guardada';

  @override
  String blogPreviewNotSaved(String audience) {
    return 'Vista previa · $audience · Aún sin guardar';
  }

  @override
  String get blogStoryPlaceholder => 'Tu historia aparecerá aquí.';

  @override
  String get blogChapterTitleLabel => 'Título del capítulo';

  @override
  String get blogChapterTitleHint =>
      'El domingo en que aprendí a ir más despacio';

  @override
  String get blogStoryLabel => 'Tu historia';

  @override
  String get blogStoryHint => 'Empieza por donde quieras. Hazla tuya.';

  @override
  String get blogInvitationLabel => 'Terminar con una invitación (opcional)';

  @override
  String get blogInvitationHelp =>
      'Deja una pregunta que ayude a alguien a conocerte.';

  @override
  String get blogRemovePhoto => 'Quitar foto';

  @override
  String get blogAddPhoto => 'Añadir una foto';

  @override
  String get blogPhotoRules =>
      'Hasta 6 fotos JPEG o PNG de 10 MB cada una. Las fotos necesitan aprobación. Guarda como «Solo yo» antes de cambiar las fotos de un capítulo publicado.';

  @override
  String get blogWhoFor => '¿Para quién es este capítulo?';

  @override
  String get blogAudiencePrivateHelp =>
      'Solo tú puedes leer este capítulo. Tus amigos y matches no lo ven.';

  @override
  String get blogAudienceFriendsHelp =>
      'Solo tus amigos de Connect pueden leerlo. Un match por sí solo no da acceso.';

  @override
  String get blogAudienceCommunityHelp =>
      'Pueden leerlo los miembros que cumplan los requisitos y hayan iniciado sesión. Completa tu perfil con dos fotos de perfil aprobadas para publicar aquí. No se comparte públicamente en la web.';

  @override
  String get blogAllowFeaturing => 'Permitir destacar';

  @override
  String get blogAllowFeaturingHelp =>
      'Si a los lectores les encanta, tu capítulo puede llegar a los muros de otros miembros: 50 me gusta y 5 comentarios llegan a 50 muros; 100 me gusta y 10 comentarios, a 100. Puedes desactivarlo cuando quieras.';

  @override
  String get blogSaveOnlyForMe => 'Guardar solo para mí';

  @override
  String blogPublishTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Publicar para «Solo yo»',
      'friends': 'Publicar para tus amigos',
      'community': 'Publicar en la comunidad Connect',
      'other': 'Publicar',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveAsOnlyMe => 'Guardar como «Solo yo»';

  @override
  String get blogSaveNote =>
      'Tus palabras se guardan cuando eliges Guardar o Publicar. La vista previa no publica nada.';

  @override
  String get blogTopicOptional => 'Tema (opcional)';

  @override
  String get blogTopicHelp =>
      'Ayuda a los lectores a quienes les interesa a encontrar tu capítulo.';

  @override
  String get webDestBlog => 'Blog';

  @override
  String get webDestFirstChapter => 'Estudio Primer capítulo';

  @override
  String get webDestDatingPreferences => 'Preferencias de citas';

  @override
  String get webDestEditProfile => 'Editar perfil';

  @override
  String get webDestProfilePhotos => 'Fotos de perfil';

  @override
  String get webDestLikedYou => 'Les gustas';

  @override
  String get webDestNotifications => 'Notificaciones';

  @override
  String get webDestDailyPrompt => 'Pregunta del día';

  @override
  String get webDestLevels => 'Niveles y progreso';

  @override
  String get webDestTrustBadges => 'Insignias de confianza';

  @override
  String get webDestTrustFilters => 'Filtros de confianza';

  @override
  String get webDestIcebreakers => 'Rompehielos';

  @override
  String get webDestCircleChallenges => 'Retos del círculo';

  @override
  String get webDestCoffeePolls => 'Encuestas de café';

  @override
  String get webDestGroups => 'Grupos';

  @override
  String get webDestRooms => 'Salas de conversación';

  @override
  String get webDestMatchNudges => 'Toques a matches';

  @override
  String get webDestFriends => 'Amigos';

  @override
  String get webDestDatePlans => 'Planes de cita';

  @override
  String get webDestCallHistory => 'Historial de llamadas';

  @override
  String get webDestMembership => 'Membresía';

  @override
  String get webDestVerification => 'Verificación';

  @override
  String get webDestPrivacySafety => 'Privacidad y seguridad';

  @override
  String get webDestAccountData => 'Cuenta y datos';

  @override
  String get webDestBlockedMembers => 'Miembros bloqueados';

  @override
  String get webDestEmergencyContacts => 'Contactos de emergencia';

  @override
  String get webDestModerationAppeals => 'Apelaciones de moderación';

  @override
  String get webDestNotificationPreferences => 'Preferencias de notificaciones';

  @override
  String get webDestHelpSupport => 'Ayuda y soporte';

  @override
  String get webNavExplore => 'Explorar';

  @override
  String get webNavMyProfile => 'Mi perfil';

  @override
  String get webNavAllFeatures => 'Todas las funciones';

  @override
  String get webNavMoreForYou => 'Más para ti';

  @override
  String get webNavPreferences => 'Preferencias';

  @override
  String get webNavWebsite => 'Web de Connect';

  @override
  String get webNavSignOut => 'Cerrar sesión';

  @override
  String get webPageNotFound => 'No se encontró esta página.';

  @override
  String get webBackToDiscover => 'Volver a Descubrir';

  @override
  String get webTagline => 'Tu ritmo. Tu elección.';

  @override
  String webUnavailableTitle(String label) {
    return '$label aún no está disponible.';
  }

  @override
  String get webUnavailableBody => 'No forma parte de esta versión de Connect.';

  @override
  String get webDirectoryTitle => 'Haz tuyo este espacio.';

  @override
  String get webDirectorySubtitle =>
      'Tu perfil, conversaciones, comunidad y controles, todo en un solo lugar.';

  @override
  String get webIcebreakerTitle => 'Ideas para iniciar conversaciones';

  @override
  String get webIcebreakerHeadline =>
      'Un poco de inspiración para tu próximo hola.';

  @override
  String get webIcebreakerBody =>
      'La grabación y reproducción de voz aún no están disponibles. Puedes usar estas ideas en una conversación habilitada.';

  @override
  String get webIcebreakerOpenMatches => 'Abrir mis matches';

  @override
  String get webMembershipHeadline => 'Un poco más de posibilidades.';

  @override
  String get webMembershipIntro =>
      'Explora los planes actuales. El pago en el navegador aún no está disponible. Desde esta página no se puede comprar ni cobrar nada.';

  @override
  String webMembershipCurrent(String plan) {
    return 'Tu membresía: $plan';
  }

  @override
  String webMembershipStatus(String status) {
    return 'Estado: $status';
  }

  @override
  String get webMembershipMonthly => 'Mensual';

  @override
  String get webMembershipYearly => 'Anual';

  @override
  String get webMembershipFree => 'Gratis';

  @override
  String webMembershipPrice(String price, String cycle) {
    String _temp0 = intl.Intl.selectLogic(cycle, {
      'yearly': 'año',
      'other': 'mes',
    });
    return '$price / $_temp0';
  }

  @override
  String get webMembershipFootnote =>
      'Los precios del catálogo son una vista previa. La membresía nunca pasa por encima de los límites de otra persona ni de los requisitos para conversar.';

  @override
  String get blogLinkCopied => 'Enlace copiado. Compártelo donde quieras.';

  @override
  String get blogYourPublicLink => 'Tu enlace público';

  @override
  String get blogShareUnconfirmed =>
      'No se pudo confirmar que se compartió. Revisa «Enlaces compartidos» antes de reintentarlo.';

  @override
  String get blogSignInAgain => 'Vuelve a iniciar sesión para continuar.';

  @override
  String get blogSharedJournalPage => 'Una página de diario compartida';

  @override
  String get blogYourPublicPreview => 'Tu vista previa pública';

  @override
  String get blogShareJointHeadline =>
      'Una historia que los dos decidís compartir.';

  @override
  String get blogShareSoloHeadline => 'Una pequeña ventana a tu mundo.';

  @override
  String get blogShareJointBody =>
      'Los dos autores deben aprobar exactamente estas palabras para que funcione el enlace. Cualquiera de los dos puede retirarlo.';

  @override
  String get blogShareSoloBody =>
      'Cualquiera con el enlace puede leer el texto y ver las fotos seleccionadas, sin cuenta. Tu capítulo completo se queda en Connect.';

  @override
  String get blogShareIdentityNote =>
      'No se añade ningún perfil ni nombre de cuenta. Aun así, tus palabras y fotos pueden identificar a personas o lugares. Publica solo lo que tengas permiso para compartir.';

  @override
  String get blogExcerptLabel => 'Fragmento exacto de tu capítulo';

  @override
  String blogIncludePhoto(String description) {
    return 'Incluir: $description';
  }

  @override
  String get blogApproveCopy => 'Apruebo exactamente esta copia pública';

  @override
  String get blogApproveCopyNote =>
      'Editar u ocultar el capítulo original invalida el enlace. Las copias guardadas fuera de Connect no se pueden recuperar.';

  @override
  String get blogSaving => 'Guardando…';

  @override
  String get blogRequestOtherApproval => 'Pedir la aprobación del otro autor';

  @override
  String get blogCreatePublicLink => 'Crear enlace público';

  @override
  String get blogJointApprovalRecorded =>
      'Tu aprobación ha quedado registrada. El enlace no estará disponible hasta que el otro autor lo apruebe.';

  @override
  String get blogPublicCopyReady => 'Tu copia pública está lista.';

  @override
  String get blogCopyPublicLink => 'Copiar enlace público';

  @override
  String get blogManageSharedLinks => 'Gestionar enlaces compartidos';

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
      'No hemos podido dejar de seguir ahora mismo. Inténtalo de nuevo.';

  @override
  String get blogFollowFailed =>
      'No hemos podido seguir a este autor ahora mismo. Inténtalo de nuevo.';

  @override
  String get blogFollowingButton => 'Siguiendo';

  @override
  String get blogFollowTheirChapters => 'Seguir sus capítulos';

  @override
  String get blogRewardsIntro =>
      'Cuando lo que compartes emociona a alguien, cuenta. Los me gusta, los comentarios aprobados y los nuevos seguidores te dan XP para tu nivel. Las recompensas vienen de lo que hacen los lectores, nunca de tocar sin más, y cada una se da solo una vez.';

  @override
  String blogRewardDailyCap(int cap) {
    return 'Hasta $cap XP al día';
  }

  @override
  String blogRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String get blogSignInWriters =>
      'Inicia sesión para ver los autores que sigues.';

  @override
  String get blogWritersLoadFailed =>
      'No se pudieron cargar los autores que sigues.';

  @override
  String get blogNoWriters => 'Todavía no hay autores.';

  @override
  String get blogNoWritersBody =>
      'Cuando un capítulo te llegue, toca «Seguir sus capítulos». Sus nuevos capítulos se reunirán en «Siguiendo».';

  @override
  String blogLatest(String title) {
    return 'Lo último: $title';
  }

  @override
  String get blogReactionFailed =>
      'Tu reacción no se ha enviado. Inténtalo de nuevo.';

  @override
  String blogCannotLikeOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'No puedes dar me gusta a tu propia foto',
      'other': 'No puedes dar me gusta a tu propio capítulo',
    });
    return '$_temp0';
  }

  @override
  String blogYouReacted(String reaction) {
    return 'Has reaccionado: $reaction. Toca para deshacerlo';
  }

  @override
  String blogLikeThis(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Me gusta esta foto',
      'other': 'Me gusta este capítulo',
    });
    return '$_temp0';
  }

  @override
  String blogCannotReactOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'No puedes reaccionar a tu propia foto',
      'other': 'No puedes reaccionar a tu propio capítulo',
    });
    return '$_temp0';
  }

  @override
  String get blogReactTooltip =>
      'Reaccionar: Te escucho, Yo también, Te mando un abrazo…';

  @override
  String blogCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comentarios',
      one: '1 comentario',
    );
    return '$_temp0';
  }

  @override
  String blogWaitingForYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '· $count te esperan',
      one: '· $count te espera',
    );
    return '$_temp0';
  }

  @override
  String get blogFeatured => 'Destacado';

  @override
  String blogTierNeedsBoth(int likes, int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes me gusta más',
      one: '1 me gusta más',
    );
    String _temp1 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments comentarios más',
      one: '1 comentario más',
    );
    String _temp2 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls muros',
      one: '1 muro',
    );
    return '$_temp0 y $_temp1 para llegar a $_temp2';
  }

  @override
  String blogTierNeedsLikes(int likes, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes me gusta más',
      one: '1 me gusta más',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls muros',
      one: '1 muro',
    );
    return '$_temp0 para llegar a $_temp1';
  }

  @override
  String blogTierNeedsComments(int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments comentarios más',
      one: '1 comentario más',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls muros',
      one: '1 muro',
    );
    return '$_temp0 para llegar a $_temp1';
  }

  @override
  String blogTierAlmostThere(int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: 'Casi lo tienes: lo siguiente son $walls muros',
      one: 'Casi lo tienes: lo siguiente es 1 muro',
    );
    return '$_temp0';
  }

  @override
  String blogOnWalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En $count muros',
      one: 'En 1 muro',
    );
    return '$_temp0';
  }

  @override
  String blogProgressToward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Progreso hacia $count muros',
      one: 'Progreso hacia 1 muro',
    );
    return '$_temp0';
  }

  @override
  String get blogReachIdle =>
      'Los lectores pueden llevar este capítulo más lejos';

  @override
  String get blogReachLive =>
      'Miembros a los que les encantaron historias como la tuya lo están leyendo ahora.';

  @override
  String get blogFeaturedStories => 'Historias destacadas';

  @override
  String get blogFeaturedCaption =>
      'Historias que les encantaron a otros miembros, en tu muro.';

  @override
  String blogByAuthor(String name) {
    return 'por $name';
  }

  @override
  String get blogLikes => 'Me gusta';

  @override
  String get blogComments => 'Comentarios';

  @override
  String get blogCommentHint => '¿Qué se te quedó?';

  @override
  String get blogCommentApproved =>
      'Aprobado. Ahora lo ve todo el que puede leer este capítulo.';

  @override
  String get blogCommentSent => 'Enviado al autor para su aprobación';

  @override
  String get blogCommentSendFailed =>
      'Tu comentario no se ha enviado. Tus palabras siguen aquí, así que puedes intentarlo de nuevo.';

  @override
  String blogCommentDeclined(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Rechazado. No aparecerá en tu foto.',
      'other': 'Rechazado. No aparecerá en tu capítulo.',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveFailed => 'No se ha guardado. Inténtalo de nuevo.';

  @override
  String get blogDeleteCommentTitle => '¿Eliminar este comentario?';

  @override
  String get blogDeleteCommentMessage =>
      'Se eliminará para todos. No se puede deshacer.';

  @override
  String get blogDeleteComment => 'Eliminar comentario';

  @override
  String get blogCommentDeleted => 'Comentario eliminado.';

  @override
  String get blogCommentDeleteFailed =>
      'No se pudo eliminar el comentario. Inténtalo de nuevo.';

  @override
  String get blogCommentsAuthorNote =>
      'Los comentarios nuevos esperan tu aprobación antes de que los vea nadie más.';

  @override
  String get blogCommentsReaderNote =>
      'El autor lee primero cada comentario y elige qué compartir.';

  @override
  String get blogLeaveComment => 'Deja un comentario';

  @override
  String get blogSendToAuthor => 'Enviar al autor';

  @override
  String get blogCommentsLoadFailed => 'No se pudieron cargar los comentarios.';

  @override
  String get blogWaitingApproval => 'Esperando tu aprobación';

  @override
  String get blogNoCommentsInvite =>
      'Todavía no hay comentarios. Di algo amable para empezar la conversación.';

  @override
  String get blogNoCommentsShared =>
      'Todavía no se ha compartido ningún comentario.';

  @override
  String get blogCommentNotShared => 'El autor decidió no compartir este.';

  @override
  String get blogYou => 'Tú';

  @override
  String get blogCommentOptions => 'Opciones del comentario';

  @override
  String get blogReportComment => 'Denunciar comentario';

  @override
  String get blogApprove => 'Aprobar';

  @override
  String get blogDecline => 'Rechazar';

  @override
  String get blogSignInContinue => 'Inicia sesión para continuar.';

  @override
  String get blogPrivateResponseTitle => 'Una respuesta privada';

  @override
  String blogPrivateResponseHelp(String invitation) {
    return '$invitation\n\nSolo el autor recibe esta respuesta. Puede aceptar o rechazar un intercambio opcional. Hasta cinco respuestas nuevas al día, y una al mismo autor.';
  }

  @override
  String get blogSendPrivateResponse => 'Enviar respuesta privada';

  @override
  String get blogTextSaveUnconfirmed =>
      'No se pudo confirmar el guardado. Tus palabras siguen aquí; vuelve a intentarlo o recarga el intercambio guardado.';

  @override
  String get blogLeaveUnsentTitle => '¿Salir sin enviar?';

  @override
  String get blogLeaveUnsentMessage =>
      'Se descartarán tus palabras sin enviar.';

  @override
  String get blogLeave => 'Salir';

  @override
  String get blogOwnWordsLabel => 'Con tus propias palabras';

  @override
  String get blogSending => 'Enviando…';

  @override
  String get blogChangeUnconfirmed =>
      'No se pudo confirmar el cambio. Actualiza para comprobarlo.';

  @override
  String get blogConnectionsTitle => 'Tus conexiones de Capítulos';

  @override
  String get blogRefresh => 'Actualizar';

  @override
  String get blogConnectionsIntro =>
      'Las buenas historias dejan espacio para alguien más.';

  @override
  String get blogConnectionsLoadFailed =>
      'No se pudieron cargar tus conexiones.';

  @override
  String get blogResponsesEmpty =>
      'Aquí aparecerán las respuestas a tus capítulos y las que envíes. Nada necesita una respuesta inmediata.';

  @override
  String get blogPublicationsEmpty =>
      'Aquí aparecerán tus vistas previas públicas y los enlaces aprobados en conjunto.';

  @override
  String get blogNoticesEmpty => 'No hay avisos de revisión.';

  @override
  String get blogResponseRevealed => 'Vuestro capítulo compartido está listo';

  @override
  String get blogResponseIncoming => 'Una respuesta para ti';

  @override
  String get blogResponseSent => 'Enviado · su decisión, a su ritmo';

  @override
  String get blogResponseAccepted => 'Un intercambio, a vuestro ritmo';

  @override
  String get blogResponseClosed => 'Este intercambio está cerrado';

  @override
  String get blogOpenExchange => 'Abrir intercambio privado';

  @override
  String get blogPublicationLive => 'Copia pública activa';

  @override
  String get blogPublicationRemoved => 'Eliminado por moderación';

  @override
  String get blogPublicationNeedsBoth =>
      'Necesita las dos aprobaciones y un capítulo original actualizado';

  @override
  String get blogPublicationSourceChanged =>
      'El original ha cambiado · crea una nueva vista previa para volver a compartir';

  @override
  String get blogApprovePublicCopyTitle => '¿Aprobar esta copia pública?';

  @override
  String get blogApprovePublicCopyMessage =>
      'Las palabras exactas de arriba estarán disponibles para cualquiera con el enlace. Cualquiera de los dos puede retirar lo compartido. No se añaden nombres automáticamente, pero las palabras podrían identificarte.';

  @override
  String get blogApprovePublicCopyAction => 'Aprobar copia pública';

  @override
  String get blogApproveExactPublicCopy =>
      'Aprobar exactamente la copia pública';

  @override
  String get blogCopyLink => 'Copiar enlace';

  @override
  String get blogWithdrawLinkTitle => '¿Retirar este enlace?';

  @override
  String get blogWithdrawLinkMessage =>
      'La copia pública dejará de estar disponible. Las copias que otra persona ya haya guardado no se pueden recuperar.';

  @override
  String get blogWithdrawLink => 'Retirar enlace';

  @override
  String get blogYourAppeal => 'Tu apelación';

  @override
  String get blogRequestReview => 'Pedir otra revisión';

  @override
  String get blogRequestReviewHelp =>
      'Explica qué debería reconsiderar quien revisa. Tu apelación llega de forma privada al equipo de confianza. El contenido eliminado sigue oculto durante la revisión.';

  @override
  String get blogSubmitAppeal => 'Enviar apelación';

  @override
  String get blogAppealDecision => 'Apelar esta decisión';

  @override
  String get blogPrevious => 'Anterior';

  @override
  String get blogMore => 'Más';

  @override
  String get blogExchangeChangeFailed =>
      'No se pudo confirmar este cambio. Actualiza y vuelve a intentarlo.';

  @override
  String get blogExchangeTitle => 'Un intercambio de Capítulos privado';

  @override
  String get blogExchangeUnavailable =>
      'Este intercambio ya no está disponible.';

  @override
  String blogExchangeWith(String name) {
    return 'Con $name';
  }

  @override
  String get blogExchangeIntro =>
      'Una respuesta es una invitación, nunca una obligación. Este intercambio no crea un match ni desbloquea el chat.';

  @override
  String get blogAcceptExchange => 'Aceptar un intercambio';

  @override
  String get blogDeclineKindly => 'Rechazar con amabilidad';

  @override
  String get blogResponseSentNote =>
      'Tu respuesta se ha enviado. No hay cuenta atrás ni necesidad de insistir.';

  @override
  String get blogExchangeClosedNote =>
      'Este intercambio está cerrado. Haz espacio para otra conexión a tu ritmo.';

  @override
  String get blogOneStoryEach => 'Una pequeña historia cada uno.';

  @override
  String get blogOneStoryEachBody =>
      'Añade una pequeña continuación, un recuerdo o tu versión del momento. Las dos aportaciones aparecen juntas, solo cuando ambos las envían.';

  @override
  String get blogYourSideTitle => 'Tu parte del capítulo';

  @override
  String get blogYourSideHelp =>
      'Comparte hasta 1000 caracteres. La otra persona no podrá leerlo hasta que también aporte lo suyo. Una vez enviado, el texto no se puede editar; puedes retirar el intercambio en cualquier momento.';

  @override
  String get blogSubmitContribution => 'Enviar mi aportación';

  @override
  String get blogAddContribution => 'Añadir mi aportación';

  @override
  String get blogYourContribution => 'Tu aportación';

  @override
  String blogPartnerContribution(String name) {
    return 'Aportación de $name';
  }

  @override
  String get blogShapeDate => 'Dar forma juntos a una cita';

  @override
  String get blogInspiredNote =>
      'Inspirado en nuestro intercambio de Capítulos.';

  @override
  String get blogTryStudio => 'Probar el Estudio Primer Capítulo';

  @override
  String get blogDatePlanningUnavailable =>
      'La planificación de citas estará disponible si tenéis un match activo y la conversación desbloqueada.';

  @override
  String get blogProposeJournalPage =>
      'Proponer una página de diario compartida';

  @override
  String get blogSourceUnavailable =>
      'El capítulo original no está disponible.';

  @override
  String get blogContributionSaved =>
      'Tu aportación se ha guardado en privado. Se revelará cuando los dos estéis listos.';

  @override
  String get blogWithdrawExchangeTitle => '¿Retirar este intercambio?';

  @override
  String get blogWithdrawExchangeMessage =>
      'La respuesta y las aportaciones dejarán de estar disponibles para los dos. Los enlaces públicos conjuntos también dejarán de funcionar.';

  @override
  String get blogWithdrawExchange => 'Retirar intercambio';

  @override
  String get blogReportExchange => 'Denunciar intercambio';

  @override
  String get blogBlockMessageExchange =>
      'Se cortarán el contacto y el acceso a los capítulos del otro.';

  @override
  String get blogBlockFailed => 'No se pudo bloquear a este miembro.';

  @override
  String get notificationsReadAll => 'Marcar todo como leído';

  @override
  String get notificationsFallbackTitle => 'Notificación';

  @override
  String get notificationsLoadFailed =>
      'No se pudieron cargar las notificaciones.';

  @override
  String get notificationsPrefsUpdateFailed =>
      'No se pudieron actualizar las preferencias de notificaciones.';

  @override
  String notificationsAgoMinutes(int count) {
    return 'hace $count min';
  }

  @override
  String notificationsAgoHours(int count) {
    return 'hace $count h';
  }

  @override
  String notificationsAgoDays(int count) {
    return 'hace $count d';
  }

  @override
  String get wallsReactEyebrow => 'REACCIONAR';

  @override
  String wallsReactQuestion(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': '¿Qué te hace sentir esta foto?',
      'other': '¿Qué te hace sentir este capítulo?',
    });
    return '$_temp0';
  }

  @override
  String get wallsReactBody =>
      'Tu reacción les dice que les has escuchado. Cada reacción cuenta como un me gusta.';

  @override
  String get wallsReactRemove => 'Retirar mi reacción';

  @override
  String wallsReactionsSemantics(String list) {
    return 'Reacciones: $list';
  }

  @override
  String get wallsReactionLove => 'Me encanta';

  @override
  String get wallsReactionHearYou => 'Te escucho';

  @override
  String get wallsReactionMeToo => 'Yo también';

  @override
  String get wallsReactionWithYou => 'Estoy contigo';

  @override
  String get wallsReactionHug => 'Te mando un abrazo';

  @override
  String get wallsReactionProud => 'Orgullo de ti';

  @override
  String get wallsSignInRequired => 'Inicia sesión para ver tu muro.';

  @override
  String get celebrationCoverHeadline => 'Tu foto es la portada de la semana';

  @override
  String celebrationReachHeadline(String kind, int reach) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'photo': 'Tu foto llegó a $reach muros',
      'other': 'Tu capítulo llegó a $reach muros',
    });
    return '$_temp0';
  }

  @override
  String get celebrationCoverMessage =>
      'A los miembros les encantó. Esta semana todos lo ven en Hoy.';

  @override
  String get celebrationReachMessage =>
      'A los miembros les encantó. Ahora está en sus muros de Hoy.';

  @override
  String celebrationQuotedTitle(String title) {
    return '«$title»';
  }

  @override
  String get celebrationBarrier => 'Celebración';

  @override
  String get celebrationLovely => 'Genial';

  @override
  String get celebrationSeePhoto => 'Ver foto';

  @override
  String get celebrationSeeChapter => 'Ver capítulo';

  @override
  String rewardXpPill(int xp) {
    return '+$xp XP';
  }

  @override
  String get rewardClaimedTitle => 'Recompensa obtenida';

  @override
  String rewardNameDescription(String name, String description) {
    return '$name · $description';
  }

  @override
  String rewardPlusXpAnnouncement(int xp) {
    return 'más $xp XP';
  }

  @override
  String rewardSourceXpLine(String source, int xp) {
    return '$source +$xp XP';
  }

  @override
  String rewardAndMore(int count) {
    return 'y $count más';
  }

  @override
  String rewardBadgeLine(String badge) {
    return 'Insignia: $badge';
  }

  @override
  String rewardLevelReached(int level) {
    return 'Nivel $level alcanzado';
  }

  @override
  String rewardBadgesEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count insignias conseguidas',
      one: 'Insignia conseguida',
    );
    return '$_temp0';
  }

  @override
  String get rewardYourRewardsToday => 'Tus recompensas de hoy';

  @override
  String rewardNewRewards(int count) {
    return '$count recompensas nuevas';
  }

  @override
  String get rewardSourceStoryPublished => 'Capítulo publicado';

  @override
  String get rewardSourcePhotoShared => 'Foto compartida';

  @override
  String get rewardSourceLikeReceived => 'A alguien le gustó tu trabajo';

  @override
  String get rewardSourceCommentReceived => 'Nuevo comentario en tu trabajo';

  @override
  String get rewardSourceCommentApproved => 'Tu comentario fue aprobado';

  @override
  String get rewardSourceSubscriberGained => 'Nuevo suscriptor';

  @override
  String get rewardSourceWallTierReached => 'Nivel de muro alcanzado';

  @override
  String get rewardSourceCoverOfWeek => 'Portada de la semana';

  @override
  String get rewardSourceDailyPromptSubmitted => 'Pregunta del día respondida';

  @override
  String get rewardLineStoryPublished => 'Tu capítulo ya está en el mundo.';

  @override
  String get rewardLinePhotoShared => 'Tu foto se unió al tema.';

  @override
  String get rewardLineLikeReceived =>
      'A alguien le encantó lo que compartiste.';

  @override
  String get rewardLineCommentReceived =>
      'Un lector se unió a la conversación.';

  @override
  String get rewardLineSubscriberGained =>
      'Alguien quiere tu próximo capítulo.';

  @override
  String get rewardLineWallTierReached => 'Tu trabajo llegó a más muros.';

  @override
  String get rewardLineCoverOfWeek => 'Esta semana todos lo ven en Hoy.';

  @override
  String get rewardLineOther => 'Conseguido por una actividad significativa.';

  @override
  String get rewardNewBadgeFallback => 'Nueva insignia';

  @override
  String get blockedUnknownUser => 'Usuario desconocido';

  @override
  String get themeTaglineBluerose =>
      'Terciopelo de medianoche, rosas zafiro y un borde de platino.';

  @override
  String get themeTaglineBluelotus =>
      'Agua a la luz de la luna, pétalos zafiro y un corazón dorado.';

  @override
  String discoverMessageLikeSent(String name) {
    return 'Love enviado a $name. Podréis chatear en cuanto $name te dé like también.';
  }

  @override
  String get notificationsDismissFailed =>
      'No se pudo quitar esa notificación. Inténtalo de nuevo.';

  @override
  String get notificationsReadAllFailed =>
      'No se pudieron marcar todas como leídas. Inténtalo de nuevo.';

  @override
  String get blogReportSubmitted => 'Denuncia enviada. Gracias.';

  @override
  String get settingsSectionAccount => 'Cuenta';

  @override
  String settingsSignedInAs(String username) {
    return 'Sesión iniciada como @$username';
  }

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsSignOutSubtitle => 'Cierra tu sesión en este dispositivo';

  @override
  String get settingsSignOutAllTitle =>
      'Cerrar sesión en todos los dispositivos';

  @override
  String get settingsSignOutAllSubtitle =>
      'Cierra todas tus sesiones, en cada móvil y navegador';

  @override
  String get settingsSignOutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get settingsSignOutConfirmBody =>
      'Necesitarás tu nombre de usuario y tu contraseña para volver a iniciar sesión en este dispositivo.';

  @override
  String get settingsSignOutAllConfirmTitle =>
      '¿Cerrar sesión en todos los dispositivos?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'Se cerrará tu sesión en todos los móviles, tabletas y navegadores, incluido este. Quien haya iniciado sesión con tu cuenta en otro lugar quedará desconectado.';

  @override
  String get settingsSignOutAllConfirmAction => 'Cerrar sesión en todas partes';

  @override
  String get settingsSignOutAllFailed =>
      'No se pudo cerrar la sesión en tus otros dispositivos. Comprueba tu conexión e inténtalo de nuevo.';
}
