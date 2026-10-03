// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get navDiscover => 'Поиск';

  @override
  String get navMatches => 'Пары';

  @override
  String get navEngage => 'Активность';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navSettings => 'Настройки';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSectionProfile => 'Профиль';

  @override
  String get settingsEditProfileTitle => 'Редактировать профиль';

  @override
  String get settingsEditProfileSubtitle => 'Обнови свои данные';

  @override
  String get settingsPhotosTitle => 'Фото';

  @override
  String get settingsPhotosSubtitle => 'Управляй своими фото';

  @override
  String get settingsSectionPreferences => 'Предпочтения';

  @override
  String get settingsAppearanceTitle => 'Оформление';

  @override
  String get settingsAppearanceSubtitle => 'Сохраняется в аккаунте';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsThemeMatchDevice => 'Как на устройстве';

  @override
  String get settingsLooksTitle => 'Стили';

  @override
  String get settingsLooksClassicDescription =>
      'Днём — тёплая слоновая кость и лесная зелень. Ночью — нежная мята и глубокий лес.';

  @override
  String get settingsLooksClassicLabel => 'Сегодня';

  @override
  String get settingsThemeSaveFailed =>
      'Не удалось сохранить тему. Попробуй ещё раз.';

  @override
  String get settingsLanguageTitle => 'Язык';

  @override
  String get settingsLanguageSubtitle => 'Выбери язык приложения';

  @override
  String get settingsDatingPreferencesTitle => 'Предпочтения в знакомствах';

  @override
  String get settingsDatingPreferencesSubtitle => 'Возраст, место, интересы';

  @override
  String get settingsAccountDataTitle => 'Аккаунт и данные';

  @override
  String get settingsAccountDataSubtitle =>
      'Скрыть, скачать или удалить аккаунт';

  @override
  String get settingsNotificationsTitle => 'Уведомления';

  @override
  String get settingsNotificationsSubtitle => 'Push- и email-уведомления';

  @override
  String get settingsSectionEngagement => 'Активность';

  @override
  String get settingsTrustBadgesTitle => 'Значки доверия';

  @override
  String get settingsTrustBadgesSubtitle =>
      'Смотри полученные значки и историю доверия';

  @override
  String get settingsTrustFiltersTitle => 'Фильтры доверия';

  @override
  String get settingsTrustFiltersSubtitle =>
      'Настрой требования к доверию при поиске';

  @override
  String get settingsConversationRoomsTitle => 'Комнаты для общения';

  @override
  String get settingsConversationRoomsSubtitle =>
      'Просматривай, вступай, выходи и модерируй комнаты';

  @override
  String get settingsFriendsTitle => 'Друзья и связи';

  @override
  String get settingsFriendsSubtitle => 'Заводи и поддерживай дружбу';

  @override
  String get settingsCallHistoryTitle => 'История звонков';

  @override
  String get settingsCallHistorySubtitle => 'Просмотр прошлых звонков';

  @override
  String get settingsMatchNudgesTitle => 'Напоминания парам';

  @override
  String get settingsMatchNudgesSubtitle => 'Оживи затихшие разговоры';

  @override
  String get settingsSubscriptionsTitle => 'Подписки';

  @override
  String get settingsSubscriptionsSubtitle =>
      'Тарифы, статус доступа и платежи';

  @override
  String get settingsSectionApp => 'Приложение';

  @override
  String get settingsPrivacySafetyTitle => 'Приватность и безопасность';

  @override
  String get settingsPrivacySafetySubtitle =>
      'Управляй настройками приватности';

  @override
  String get settingsGovernmentVerificationTitle => 'Проверка документов';

  @override
  String get settingsGovernmentVerificationSubtitle =>
      'Статус проверки личности';

  @override
  String get settingsQaVerificationUploadTitle => 'Загрузка для QA-проверки';

  @override
  String get settingsQaVerificationUploadSubtitle =>
      'Сценарий с документом и селфи только для автотестов';

  @override
  String get settingsHelpSupportTitle => 'Помощь и поддержка';

  @override
  String get settingsHelpSupportSubtitle => 'FAQ и связь с поддержкой';

  @override
  String get settingsAboutTitle => 'О приложении';

  @override
  String get settingsAboutSubtitle => 'Сведения о приложении и технологиях';

  @override
  String get settingsLogout => 'Выйти';

  @override
  String get languageTitle => 'Язык';

  @override
  String get languageIntro =>
      'Выбери язык, на котором работает Connect. Выбор сохраняется в аккаунте и действует на всех устройствах, где ты входишь.';

  @override
  String get languageUseDevice => 'Язык устройства';

  @override
  String get languageUseDeviceSubtitle => 'Следует настройке языка телефона';

  @override
  String get languageSaveFailed =>
      'Не удалось сохранить язык. Попробуй ещё раз.';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsInboxTitle => 'Входящие уведомления';

  @override
  String get notificationsInboxCaughtUp => 'Всё прочитано';

  @override
  String notificationsInboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count непрочитанных',
      many: '$count непрочитанных',
      few: '$count непрочитанных',
      one: '$count непрочитанное',
    );
    return '$_temp0';
  }

  @override
  String get notificationsInAppTitle => 'Уведомления в приложении';

  @override
  String get notificationsInAppSubtitle =>
      'Показывать уведомления, пока ты в приложении';

  @override
  String get notificationsPushTitle => 'Push-уведомления';

  @override
  String get notificationsPushSubtitle => 'Доставлять, когда приложение в фоне';

  @override
  String get notificationsNewMatchesTitle => 'Новые пары';

  @override
  String get notificationsNewMatchesSubtitle =>
      'Сообщать, когда у тебя новая пара';

  @override
  String get notificationsNewMessagesTitle => 'Новые сообщения';

  @override
  String get notificationsNewMessagesSubtitle => 'Сообщать о сообщениях в чате';

  @override
  String get notificationsLikesTitle => 'Лайки';

  @override
  String get notificationsLikesSubtitle => 'Сообщать, когда тебя лайкнули';

  @override
  String get notificationsMatchNudgesTitle => 'Напоминания парам';

  @override
  String get notificationsMatchNudgesSubtitle =>
      'Сообщать, когда пара напоминает о себе';

  @override
  String get notificationsIncomingCallsTitle => 'Входящие звонки';

  @override
  String get notificationsIncomingCallsSubtitle =>
      'Показывать оповещения о входящих звонках';

  @override
  String get notificationsSafetyTitle => 'Обновления безопасности';

  @override
  String get notificationsSafetySubtitle =>
      'Получать важные обновления о статусе безопасности';

  @override
  String get notificationsFriendPlansTitle => 'Свидания друзей';

  @override
  String get notificationsFriendPlansSubtitle =>
      'Знать, когда друг планирует свидание или сообщает, что всё в порядке';

  @override
  String get welcomeTagline => 'Для настоящей жизни.';

  @override
  String get welcomePhotoNote => 'Цель — встретиться вживую.';

  @override
  String get welcomeHeadlineLead => 'Хорошая история\nначинается с ';

  @override
  String get welcomeHeadlineAccent => 'привет.';

  @override
  String get welcomeBody =>
      'Найди того, кто по-настоящему тебе близок. А дальше — как пойдёт.';

  @override
  String get welcomeCreateAccount => 'Создать аккаунт';

  @override
  String get welcomeAlreadyMember => 'Уже с нами? ';

  @override
  String get welcomeSignIn => 'Войти';

  @override
  String get welcomeFooter => '18+  ·  Твой темп. Твой выбор.';

  @override
  String get authBackTooltip => 'Назад на главную';

  @override
  String get authHeadline => 'Рады тебя видеть.';

  @override
  String get authSubtitle => 'Войди с именем пользователя и паролем';

  @override
  String get authWelcomeBack => 'С возвращением';

  @override
  String get authNextHello => 'Твоё следующее «привет» уже ждёт.';

  @override
  String get authUsernameHint => 'имя пользователя';

  @override
  String get authPasswordHint => 'Пароль';

  @override
  String get authShowPassword => 'Показать пароль';

  @override
  String get authHidePassword => 'Скрыть пароль';

  @override
  String get authCantSignIn => 'Не получается войти?';

  @override
  String get authSignIn => 'Войти';

  @override
  String get authPrivacyNote =>
      'Пароль отправляется только при входе и никогда не хранится в приложении.';

  @override
  String get authEnterUsername => 'Введи имя пользователя.';

  @override
  String get authEnterPassword => 'Введи пароль.';

  @override
  String get commonYes => 'Да';

  @override
  String get commonNo => 'Нет';

  @override
  String get planVenueCoffee => 'Кофе';

  @override
  String get planVenueMeal => 'Поесть вместе';

  @override
  String get planVenueDrinks => 'Выпить';

  @override
  String get planVenueWalk => 'Прогулка';

  @override
  String get planVenueActivity => 'Какое-то занятие';

  @override
  String get planVenueEvent => 'Мероприятие';

  @override
  String get planVenueVideoCall => 'Видеозвонок';

  @override
  String get planVenueOther => 'Что-то другое';

  @override
  String planProposeTitle(String name) {
    return '$name и ты — запланируйте свидание';
  }

  @override
  String get planProposeSubtitle =>
      'Придумайте первую встречу вместе. Делиться с контактами по умолчанию не нужно.';

  @override
  String get planProposeButton => 'Предложить';

  @override
  String planHeadlineProposed(String name) {
    return '$name предлагает свидание';
  }

  @override
  String planHeadlineWaiting(String name) {
    return 'Ждём, когда $name ответит';
  }

  @override
  String get planHeadlineUpcoming => 'Договорились!';

  @override
  String get planHeadlineCheckin => 'Как прошло?';

  @override
  String get planHeadlineDebrief => 'Как всё было?';

  @override
  String get planHeadlineDebriefComplete => 'Итоги подведены';

  @override
  String planHeadlineWaitingDebrief(String name) {
    return 'Ждём, когда $name подведёт итоги';
  }

  @override
  String get planHeadlineCheckedInSafe => 'Отмечено: ты в порядке';

  @override
  String get planHeadlineFriendsAlerted =>
      'Твой запрос о помощи зарегистрирован';

  @override
  String get planHeadlineDefault => 'Свидание';

  @override
  String get planStatusProposed => 'Предложено';

  @override
  String get planStatusConfirmed => 'Подтверждено';

  @override
  String get planDebriefButton => 'Итоги за десять секунд';

  @override
  String get planDecline => 'Отклонить';

  @override
  String get planAccept => 'Принять';

  @override
  String get planFriendsKnowAccepted =>
      'Выбери доверенные контакты, чтобы делиться новостями.';

  @override
  String get planFriendsKnowProposed =>
      'Делиться с контактами необязательно — для каждого плана отдельно.';

  @override
  String get planCancel => 'Отменить свидание';

  @override
  String get planNeedHelp => 'Мне нужна помощь';

  @override
  String get planImSafe => 'Я в порядке';

  @override
  String get planCancelDialogTitle => 'Отменить это свидание?';

  @override
  String planCancelDialogBody(String name) {
    return '$name и все, у кого есть доступ к этому плану, получат уведомление.';
  }

  @override
  String get planKeepIt => 'Оставить';

  @override
  String get planProposeIntro =>
      'Пока это только между тобой и твоим свиданием. После предложения можешь выбрать доверенные контакты, если хочешь делиться новостями о плане и отметками.';

  @override
  String get planSectionWhen => 'Когда';

  @override
  String get planSectionWhat => 'Что';

  @override
  String get planSectionGroups => 'Доверенные контакты';

  @override
  String planDurationHours(int hours) {
    return '$hours ч';
  }

  @override
  String get planPlaceLabel => 'Место (необязательно)';

  @override
  String get planPlaceHint => 'Лучше всего — людное место';

  @override
  String get planAreaLabel => 'Район';

  @override
  String get planNoteLabel => 'Сообщение для пары (необязательно)';

  @override
  String get planFutureTimeError => 'Выбери время в будущем.';

  @override
  String get planProposeFailed => 'Не удалось предложить это свидание.';

  @override
  String get planSendButton => 'Отправить план';

  @override
  String get planAcceptTitle => 'Принять свидание?';

  @override
  String get planAcceptIntro =>
      'Прими этот план вместе со своим свиданием. Потом можешь выбрать доверенные контакты, если хочешь делиться новостями.';

  @override
  String get planAcceptButton => 'Принять план';

  @override
  String debriefTitle(String name) {
    return '$name — как всё прошло?';
  }

  @override
  String get debriefIntro =>
      'Твои ответы приватны. Когда вы оба подтвердите, что свидание состоялось, оно засчитается для значка Shows Up.';

  @override
  String get debriefHappened => 'Свидание состоялось?';

  @override
  String get debriefMeetAgain => 'Хочешь встретиться снова?';

  @override
  String get debriefFeltSafe => 'Тебе было безопасно?';

  @override
  String get debriefNoteLabel => 'Хочешь что-то добавить? (необязательно)';

  @override
  String get debriefMissingHappened => 'Расскажи, состоялось ли свидание.';

  @override
  String get debriefSaveFailed => 'Не удалось сохранить итоги.';

  @override
  String get debriefSave => 'Сохранить итоги';

  @override
  String get debriefUnsafeTitle => 'Жаль, что тебе было небезопасно';

  @override
  String debriefUnsafeBody(String name) {
    return 'Твой ответ передан нашей команде безопасности. Хочешь также пожаловаться на этого человека ($name)?';
  }

  @override
  String get debriefNotNow => 'Не сейчас';

  @override
  String get debriefReport => 'Пожаловаться';

  @override
  String get plansTitle => 'Свидания';

  @override
  String get plansTabMine => 'Мои';

  @override
  String get plansTabFriends => 'Друзья';

  @override
  String get plansEmptyMineTitle => 'Свиданий пока нет';

  @override
  String get plansEmptyMineBody =>
      'Предложи свидание из переписки. Ты сам(а) решаешь, делиться ли новостями о плане и отметками с доверенными контактами.';

  @override
  String plansWith(String name) {
    return 'Свидание: $name';
  }

  @override
  String get plansNextDecide => 'Ждём твоего ответа';

  @override
  String plansNextAwait(String name) {
    return 'Ждём, когда $name ответит';
  }

  @override
  String get plansNextUpcoming =>
      'Подтверждено. Ваше время вместе запланировано.';

  @override
  String get plansNextCheckin => 'Отметься после свидания';

  @override
  String get plansNextDebrief => 'Расскажи, как прошло';

  @override
  String get plansNextCancelled => 'Отменено';

  @override
  String get plansNextDone => 'Завершено';

  @override
  String get plansEmptyFriendsTitle => 'Пока ничего';

  @override
  String get plansEmptyFriendsBody =>
      'Планы появятся здесь, когда друзья явно решат поделиться ими с тобой.';

  @override
  String get plansViaGroup => 'Поделились с тобой';

  @override
  String get plansViaFriend => 'Доверенный контакт';

  @override
  String plansFriendNeedsHelp(String name) {
    return '$name просит о помощи. Свяжись прямо сейчас.';
  }

  @override
  String plansFriendMissedCheckin(String name) {
    return '$name пока не на связи.';
  }

  @override
  String plansFriendCheckedInSafe(String name, String via) {
    return '$name на связи: всё в порядке · $via';
  }

  @override
  String plansFriendStatusLine(String via, String status) {
    return '$via · $status';
  }

  @override
  String get plansStatusWordProposed => 'предложено';

  @override
  String get plansStatusWordConfirmed => 'подтверждено';

  @override
  String get plansStatusWordCancelled => 'отменено';

  @override
  String get plansStatusWordHappened => 'состоялось';

  @override
  String get chatEmptyDefault =>
      'Поздоровайся. Сообщения появятся здесь для всех участников беседы.';

  @override
  String get chatNotSentRetry =>
      'Не отправлено. Нажми на сообщение, чтобы повторить.';

  @override
  String get chatRetrySend => 'Отправить ещё раз';

  @override
  String get chatCopyText => 'Копировать текст';

  @override
  String get chatDeleteMine => 'Удалить моё сообщение';

  @override
  String get chatRemoveMessage => 'Убрать сообщение';

  @override
  String get chatReportMessage => 'Пожаловаться на сообщение';

  @override
  String get chatThisMember => 'Этот участник';

  @override
  String get chatMember => 'Участник';

  @override
  String get chatCopied => 'Скопировано.';

  @override
  String get chatDeleteFailed => 'Не удалось удалить. Попробуй ещё раз.';

  @override
  String get chatSubtitleFriends => 'Друзья';

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count участника',
      many: '$count участников',
      few: '$count участника',
      one: '$count участник',
    );
    return '$_temp0';
  }

  @override
  String get chatReconnecting =>
      'Переподключаемся. Новые сообщения могут прийти с задержкой.';

  @override
  String get chatUnavailable =>
      'Эта беседа недоступна. Возможно, ты больше не участник.';

  @override
  String get chatTryAgain => 'Попробовать снова';

  @override
  String get chatStatusNotSent => 'Не отправлено · удерживай, чтобы повторить';

  @override
  String get chatStatusSending => 'Отправка…';

  @override
  String get chatMessageRemoved => 'Сообщение удалено';

  @override
  String chatSemanticsYouAt(String time) {
    return 'Ты в $time';
  }

  @override
  String chatSemanticsMemberAt(String name, String time) {
    return '$name в $time';
  }

  @override
  String chatAboutMember(String name) {
    return 'О пользователе $name';
  }

  @override
  String get chatComposerHint => 'Напиши сообщение';

  @override
  String get chatMutedComposerHint => 'Сейчас ты не можешь писать';

  @override
  String get chatSend => 'Отправить';

  @override
  String chatRoomMutedUntil(String when) {
    return 'Тебе запретили писать в этой комнате до $when. Читать сообщения можно.';
  }

  @override
  String get chatRoomMuted =>
      'Тебе запретили писать в этой комнате. Читать сообщения можно.';

  @override
  String chatReadOnlyUntil(String when) {
    return 'Ты можешь читать эту беседу, но писать — только после $when.';
  }

  @override
  String get chatReadOnly =>
      'Ты можешь читать эту беседу, но пока не можешь писать.';

  @override
  String get chatMuteTooltip => 'Отключить уведомления';

  @override
  String get chatMutedTooltip => 'Уведомления отключены';

  @override
  String get chatMuteSheetTitle => 'Отключить уведомления';

  @override
  String get chatMuteSheetBody =>
      'Сообщения будут приходить сюда, просто без уведомлений.';

  @override
  String get chatMuteOneHour => 'На 1 час';

  @override
  String get chatMuteEightHours => 'На 8 часов';

  @override
  String get chatMuteOneWeek => 'На 1 неделю';

  @override
  String get chatMuteForever => 'Пока не включу снова';

  @override
  String get chatUnmute => 'Снова включить уведомления';

  @override
  String chatMutedUntilLabel(String when) {
    return 'Отключены до $when';
  }

  @override
  String get chatMutedIndefinitely =>
      'Отключены, пока ты снова не включишь уведомления.';

  @override
  String get chatMuteDone => 'Уведомления отключены.';

  @override
  String get chatUnmuteDone => 'Уведомления снова включены.';

  @override
  String get chatMuteFailed =>
      'Не удалось изменить уведомления. Попробуй ещё раз.';

  @override
  String get roomsClosedSnack => 'Эта комната закрыта.';

  @override
  String get roomsChatNotOpen => 'Чат этой комнаты ещё не открыт.';

  @override
  String get roomsJoinFailed => 'Не удалось войти в комнату. Попробуй ещё раз.';

  @override
  String get roomsStartRoom => 'Создать комнату';

  @override
  String get roomsEyebrow => 'ЖИВОЙ ЧАТ';

  @override
  String get roomsTitle => 'Комнаты';

  @override
  String get roomsSubtitle =>
      'Загляни в разговор. Если с кем-то нашёлся общий язык, добавь в друзья.';

  @override
  String get roomsSectionRooms => 'КОМНАТЫ';

  @override
  String get roomsSectionYours => 'ТВОИ КОМНАТЫ';

  @override
  String get roomsYoursCaption =>
      'Комнаты, где ты сейчас. Нажми, чтобы продолжить разговор.';

  @override
  String get roomsSectionLive => 'СЕЙЧАС ОБЩАЮТСЯ';

  @override
  String get roomsLiveTitle => 'Где сейчас идёт разговор';

  @override
  String get roomsSectionBrowse => 'ОБЗОР';

  @override
  String get roomsBrowseTitle => 'Найди свою комнату';

  @override
  String get roomsBrowseCaption =>
      'Всегда открыты. Выбери тему, поздоровайся и посмотри, с кем найдёшь общий язык.';

  @override
  String get roomsNoFriendsHere =>
      'Сейчас никого из твоих друзей нет в этих комнатах.';

  @override
  String get roomsNoRoomsInTopic => 'По этой теме пока нет комнат.';

  @override
  String get roomsSectionComingUp => 'СКОРО';

  @override
  String get roomsComingUpCaption =>
      'Комнаты, которые проводят участники. Заходи заранее, чтобы занять место.';

  @override
  String get roomsCategoryAll => 'Все';

  @override
  String get roomsCategoryTalk => 'Разговоры';

  @override
  String get roomsCategoryInterests => 'Интересы';

  @override
  String get roomsCategoryActive => 'Активный отдых';

  @override
  String get roomsCategoryCity => 'Твой город';

  @override
  String get roomsFriendsHereChip => 'Здесь друзья';

  @override
  String get roomsQuiet => 'Сейчас тихо. Поздоровайся первым.';

  @override
  String roomsPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count человека',
      many: '$count человек',
      few: '$count человека',
      one: '$count человек',
    );
    return '$_temp0';
  }

  @override
  String roomsRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count комнатах',
      many: '$count комнатах',
      few: '$count комнатах',
      one: '$count комнате',
    );
    return '$_temp0';
  }

  @override
  String roomsChattingIn(String people, String rooms) {
    return '$people общаются в $rooms';
  }

  @override
  String roomsHereNow(int count) {
    return '$count сейчас здесь';
  }

  @override
  String roomsInTheRoom(int count) {
    return '$count в комнате';
  }

  @override
  String roomsFriendsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count друга здесь',
      many: '$count друзей здесь',
      few: '$count друга здесь',
      one: '$count друг здесь',
    );
    return '$_temp0';
  }

  @override
  String get roomsHostedByYou => 'Ведёшь ты';

  @override
  String roomsHostedBy(String name) {
    return 'Ведущий: $name';
  }

  @override
  String get roomsActionOpen => 'Открыть';

  @override
  String get roomsActionFull => 'Нет мест';

  @override
  String get roomsActionJoin => 'Войти';

  @override
  String roomsStartsAt(String time) {
    return 'Начало в $time';
  }

  @override
  String roomsStartsOn(String day, String time) {
    return 'Начало $day в $time';
  }

  @override
  String get roomsStartNameTooShort => 'Назови комнату — минимум 3 символа.';

  @override
  String get roomsStartIntro =>
      'Ты ведущий: можешь предупреждать, запрещать писать или удалять участников и закрыть комнату, когда закончишь. Одна комната за раз.';

  @override
  String get roomsStartNameLabel => 'Название комнаты';

  @override
  String get roomsStartNameHint => 'Воскресный обмен книгами';

  @override
  String get roomsStartAboutLabel => 'О чём комната? (необязательно)';

  @override
  String get roomsStartTopic => 'Тема';

  @override
  String get roomsStartHowLong => 'Продолжительность';

  @override
  String get roomsLength30Min => '30 мин';

  @override
  String get roomsLength1Hour => '1 час';

  @override
  String get roomsLength2Hours => '2 часа';

  @override
  String get roomsStartNow => 'Начать';

  @override
  String get roomsRoleHost => 'Ведущий';

  @override
  String get roomsRoleModerator => 'Модератор';

  @override
  String get roomsRoomFallback => 'Комната';

  @override
  String roomsChatEmpty(String room) {
    return 'Ты в комнате. Поздоровайся: все в «$room» видят, что ты здесь пишешь.';
  }

  @override
  String get roomsPeopleTooltip => 'Люди в этой комнате';

  @override
  String roomsLeaveTitle(String room) {
    return 'Выйти из «$room»?';
  }

  @override
  String get roomsLeaveBody =>
      'Ты перестанешь видеть сообщения этой комнаты. Вернуться можно, пока она открыта.';

  @override
  String get roomsLeaveAction => 'Выйти из комнаты';

  @override
  String get roomsLeaveFailed => 'Не удалось выйти. Попробуй ещё раз.';

  @override
  String roomsCloseTitle(String room) {
    return 'Закрыть «$room»?';
  }

  @override
  String get roomsCloseBody =>
      'Чат закончится для всех в комнате. Это нельзя отменить.';

  @override
  String get roomsCloseAction => 'Закрыть комнату';

  @override
  String get roomsCloseFailed => 'Не удалось закрыть. Попробуй ещё раз.';

  @override
  String get roomsMenuTooltip => 'Настройки комнаты';

  @override
  String get roomsMenuPeople => 'Кто здесь';

  @override
  String get roomsMenuModerate => 'Модерировать';

  @override
  String roomsModerateTitle(String room) {
    return 'Модерация «$room»';
  }

  @override
  String get roomsModerateIntro =>
      'Нажми на участника, чтобы предупредить, запретить писать или удалить. Те, кому запретили писать, могут читать; удалённые смогут вернуться после окончания сессии.';

  @override
  String get roomsPeopleIntro =>
      'Нашёл общий язык? Добавь в друзья, чтобы продолжить общение после комнаты.';

  @override
  String get roomsMembersLoadFailed => 'Не удалось загрузить, кто здесь.';

  @override
  String get roomsStatusFriend => 'Друг';

  @override
  String get roomsStatusHereNow => 'Сейчас здесь';

  @override
  String get roomsStatusInRoom => 'В комнате';

  @override
  String get roomsStatusGone => 'Уже не в комнате';

  @override
  String roomsStatusMutedUntil(String time) {
    return 'Без права писать до $time';
  }

  @override
  String roomsYouSuffix(String name) {
    return '$name (ты)';
  }

  @override
  String roomsRemoveTitle(String name) {
    return 'Удалить $name из комнаты?';
  }

  @override
  String roomsRemoveBodyAlwaysOn(String name) {
    return '$name сразу выйдет из чата и сможет вернуться через 24 часа.';
  }

  @override
  String roomsRemoveBodyHosted(String name) {
    return '$name сразу выйдет из чата и не сможет вернуться, пока комната не закончится.';
  }

  @override
  String roomsWarnTitle(String name) {
    return 'Предупредить $name?';
  }

  @override
  String roomsWarnBody(String name) {
    return '$name получит личное напоминание общаться дружелюбно и по теме.';
  }

  @override
  String get roomsRemoveAction => 'Удалить';

  @override
  String get roomsWarnAction => 'Отправить предупреждение';

  @override
  String roomsRemovedDone(String name) {
    return '$name удалён из комнаты.';
  }

  @override
  String roomsWarnedDone(String name) {
    return 'Предупреждение отправлено: $name.';
  }

  @override
  String get roomsModerationFailed => 'Не получилось. Попробуй ещё раз.';

  @override
  String roomsBlockedDone(String name) {
    return 'Ты заблокировал(а) $name. Здесь вы не будете видеть сообщения друг друга.';
  }

  @override
  String get roomsReport => 'Пожаловаться';

  @override
  String get roomsBlock => 'Заблокировать';

  @override
  String get roomsModerateEyebrow => 'МОДЕРАЦИЯ';

  @override
  String get roomsWarn => 'Предупредить';

  @override
  String get roomsRemoveFromRoom => 'Удалить из комнаты';

  @override
  String get roomsMute => 'Запретить писать';

  @override
  String get roomsUnmute => 'Разрешить писать';

  @override
  String roomsMuteSheetTitle(String name) {
    return 'Запретить $name писать?';
  }

  @override
  String roomsMuteSheetBody(String name) {
    return '$name сможет читать чат, но не сможет писать, пока запрет не закончится. Мы пришлём личное уведомление.';
  }

  @override
  String get roomsMuteTenMinutes => 'На 10 минут';

  @override
  String get roomsMuteOneHour => 'На 1 час';

  @override
  String get roomsMuteUntilEnd => 'До конца комнаты';

  @override
  String get roomsMuteOneDay => 'На 24 часа';

  @override
  String roomsMutedDone(String name) {
    return '$name больше не может писать.';
  }

  @override
  String roomsUnmutedDone(String name) {
    return '$name снова может писать.';
  }

  @override
  String get richFormattingToolbar => 'Форматирование';

  @override
  String get richUndo => 'Отменить';

  @override
  String get richRedo => 'Повторить';

  @override
  String get richBold => 'Жирный';

  @override
  String get richItalic => 'Курсив';

  @override
  String get richUnderline => 'Подчёркнутый';

  @override
  String get richStrikethrough => 'Зачёркнутый';

  @override
  String get richHighlight => 'Выделить цветом';

  @override
  String get richLink => 'Ссылка';

  @override
  String get richTextStyleMenu => 'Стиль текста';

  @override
  String get richParagraph => 'Абзац';

  @override
  String get richHeading => 'Заголовок';

  @override
  String get richSubheading => 'Подзаголовок';

  @override
  String get richQuote => 'Цитата';

  @override
  String get richCallout => 'Врезка';

  @override
  String get richBulletList => 'Маркированный список';

  @override
  String get richNumberedList => 'Нумерованный список';

  @override
  String get richDivider => 'Разделитель';

  @override
  String get richAlignMenu => 'Выравнивание';

  @override
  String get richAlignStart => 'По началу строки';

  @override
  String get richAlignCenter => 'По центру';

  @override
  String get richAlignEnd => 'По концу строки';

  @override
  String get richClearFormatting => 'Очистить форматирование';

  @override
  String get richWritingStyle => 'Стиль письма';

  @override
  String get richStyleClassic => 'Классика';

  @override
  String get richStyleClassicHint => 'Изящный шрифт с засечками, как в книге';

  @override
  String get richStyleModern => 'Современный';

  @override
  String get richStyleModernHint => 'Чисто и легко читается';

  @override
  String get richStyleJournal => 'Дневник';

  @override
  String get richStyleJournalHint => 'Тёплый курсив, как запись в дневнике';

  @override
  String get richStyleTypewriter => 'Печатная машинка';

  @override
  String get richStyleTypewriterHint => 'Чёткие буквы с увеличенным интервалом';

  @override
  String get richStylePoetic => 'Поэтичный';

  @override
  String get richStylePoeticHint => 'Строки по центру и много воздуха';

  @override
  String richWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слова',
      many: '$count слов',
      few: '$count слова',
      one: '$count слово',
    );
    return '$_temp0';
  }

  @override
  String get richAlignmentNote =>
      'Выравнивание и отступы видны в предпросмотре и читателям.';

  @override
  String get richLinkTitle => 'Добавить ссылку';

  @override
  String get richLinkField => 'Веб-адрес';

  @override
  String get richLinkInvalid =>
      'Укажите полный адрес, начинающийся с https://.';

  @override
  String get richLinkApply => 'Добавить ссылку';

  @override
  String get richLinkRemove => 'Удалить ссылку';

  @override
  String get richLinkNeedsSelection => 'Сначала выделите слова для ссылки.';

  @override
  String get richCancel => 'Отмена';

  @override
  String get richOpenLinkTitle => 'Открыть ссылку?';

  @override
  String richOpenLinkBody(String host) {
    return '$host откроется вне Connect. Открывайте только ссылки, которым доверяете.';
  }

  @override
  String get richOpenLink => 'Открыть';

  @override
  String get supportCentreEyebrow => 'ПОМОЩЬ И ПОДДЕРЖКА';

  @override
  String get supportCentreTitle => 'Чем мы можем помочь?';

  @override
  String get supportCentreSubtitle =>
      'Найдите быстрый ответ или спросите нашу команду. Каждое обращение и ответ хранятся в одном личном разговоре.';

  @override
  String get supportContactSection => 'СВЯЗАТЬСЯ С НАМИ';

  @override
  String get supportContactTitle => 'Написать в поддержку';

  @override
  String get supportContactSubtitle =>
      'Расскажи, что произошло. Мы ответим здесь и сообщим тебе.';

  @override
  String get supportMyTicketsTitle => 'Мои обращения';

  @override
  String get supportMyTicketsSubtitle =>
      'Следите за обращениями и нашими ответами';

  @override
  String supportOpenRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count открытого обращения',
      many: '$count открытых обращений',
      few: '$count открытых обращения',
      one: '$count открытое обращение',
    );
    return '$_temp0';
  }

  @override
  String supportUnreadReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count нового ответа',
      many: '$count новых ответов',
      few: '$count новых ответа',
      one: '$count новый ответ',
    );
    return '$_temp0';
  }

  @override
  String get supportQuickAnswersSection => 'БЫСТРЫЕ ОТВЕТЫ';

  @override
  String get supportFaqLoginTitle => 'Вход';

  @override
  String get supportFaqLoginBody =>
      'Входите со своим уникальным именем пользователя и паролем.';

  @override
  String get supportFaqVerificationTitle => 'Проверка';

  @override
  String get supportFaqVerificationBody =>
      'Проверка личности необязательна, пока работа провайдера приостановлена.';

  @override
  String get supportFaqAbuseTitle => 'Нарушения';

  @override
  String get supportFaqAbuseBody =>
      'Используйте «Пожаловаться» в профиле или переписке, чтобы команда безопасности отреагировала быстрее.';

  @override
  String get supportFaqBillingTitle => 'Оплата';

  @override
  String get supportFaqBillingBody =>
      'Укажите номер транзакции, но никогда не данные карты.';

  @override
  String get supportEmergencyNote =>
      'Если кто-то в непосредственной опасности, обратитесь в местные экстренные службы. Обращения в поддержку не заменяют экстренную помощь.';

  @override
  String get supportUnavailableTitle =>
      'Обращения в поддержку сейчас недоступны';

  @override
  String get supportUnavailableBody =>
      'Ответы на этой странице по-прежнему доступны. По срочным вопросам пишите на support@connect.example.';

  @override
  String get supportBackToHelp => 'Назад в «Помощь и поддержка»';

  @override
  String get supportFormEyebrow => 'НОВОЕ ОБРАЩЕНИЕ';

  @override
  String get supportFormTitle => 'Написать в поддержку';

  @override
  String get supportFormSubtitle =>
      'Опишите проблему достаточно подробно. Никогда не указывайте пароль, код восстановления, номер карты или документ, удостоверяющий личность.';

  @override
  String get supportFormCategorySection => 'ТЕМА';

  @override
  String get supportFormCategoryLabel => 'С чем нужна помощь?';

  @override
  String get supportCategoryAccountLogin => 'Аккаунт и вход';

  @override
  String get supportCategoryVerification => 'Проверка';

  @override
  String get supportCategoryPaymentsBilling => 'Платежи и оплата';

  @override
  String get supportCategorySafetyHarassment => 'Безопасность и домогательства';

  @override
  String get supportCategoryMatchesChat => 'Пары и чат';

  @override
  String get supportCategoryTechnical => 'Техническая проблема или ошибка';

  @override
  String get supportCategoryFeatureRequest => 'Предложение функции';

  @override
  String get supportCategoryPrivacyData => 'Конфиденциальность и данные';

  @override
  String get supportCategoryOther => 'Другое';

  @override
  String get supportSafetyNote =>
      'Если ты или кто-то другой в непосредственной опасности, используй SOS в приложении или позвони в местные экстренные службы. Обращения о безопасности рассматриваются в первую очередь, но обращение — не экстренная линия.';

  @override
  String get supportOpenSos => 'Открыть SOS';

  @override
  String get supportFormDetailsSection => 'ПОДРОБНОСТИ';

  @override
  String get supportFormSubjectLabel => 'Тема';

  @override
  String get supportFormSubjectHint => 'Кратко опишите проблему';

  @override
  String get supportFormDescriptionLabel => 'Что произошло?';

  @override
  String get supportFormDescriptionHint =>
      'Что ты сделал(а), чего ожидал(а) и что произошло вместо этого';

  @override
  String get supportFormScreenshotsSection => 'СКРИНШОТЫ';

  @override
  String supportFormScreenshotsCaption(int max) {
    return 'Необязательно. До $max изображений.';
  }

  @override
  String get supportAddScreenshot => 'Добавить скриншот';

  @override
  String supportRemoveAttachment(String name) {
    return 'Удалить $name';
  }

  @override
  String get supportAttachmentUploading => 'Загрузка';

  @override
  String get supportRetryUpload => 'Повторить загрузку';

  @override
  String supportFormDeviceNote(String version) {
    return 'Мы приложим версию приложения ($version), платформу, версию системы и язык, чтобы быстрее разобраться.';
  }

  @override
  String get supportSubmit => 'Отправить обращение';

  @override
  String get supportErrorCategoryRequired => 'Выберите тему.';

  @override
  String supportErrorSubjectLength(int min, int max) {
    return 'Тема должна содержать от $min до $max символов.';
  }

  @override
  String get supportErrorDescriptionRequired => 'Опишите, что произошло.';

  @override
  String supportErrorDescriptionTooLong(int max) {
    return 'Уложитесь в $max символов.';
  }

  @override
  String get supportErrorUploadsPending =>
      'Дождитесь загрузки скриншотов или удалите те, что не загрузились.';

  @override
  String supportCreatedSnack(String reference) {
    return 'Обращение $reference отправлено. Мы ответим здесь.';
  }

  @override
  String supportDuplicateSnack(String reference) {
    return 'Это обращение уже отправлено, поэтому мы открыли его: $reference.';
  }

  @override
  String supportErrorRateLimited(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'За короткое время отправлено несколько обращений. Попробуй через $minutes минуты.',
      many:
          'За короткое время отправлено несколько обращений. Попробуй через $minutes минут.',
      few:
          'За короткое время отправлено несколько обращений. Попробуй через $minutes минуты.',
      one:
          'За короткое время отправлено несколько обращений. Попробуй через $minutes минуту.',
    );
    return '$_temp0';
  }

  @override
  String get supportErrorRateLimitedGeneric =>
      'За короткое время отправлено несколько обращений. Попробуй позже.';

  @override
  String get supportErrorTooManyOpen =>
      'У тебя уже 10 открытых обращений. Закрой ненужное или дождись наших ответов.';

  @override
  String get supportErrorTicketClosed =>
      'Это обращение закрыто, и его больше нельзя открыть снова. Создайте новое обращение.';

  @override
  String get supportErrorReopenWindowPassed =>
      'Срок повторного открытия этого обращения истёк. Создайте новое обращение.';

  @override
  String get supportErrorAlreadyRated => 'Это обращение уже оценено.';

  @override
  String get supportErrorNotResolved =>
      'Оценить обращение можно после его решения.';

  @override
  String get supportErrorAttachmentType =>
      'Можно прикрепить только изображения JPEG или PNG и файлы PDF.';

  @override
  String get supportErrorAttachmentTooLarge =>
      'Файл слишком большой. Размер изображения — до 8 МБ.';

  @override
  String get supportErrorOffline =>
      'Сейчас не удаётся связаться с Connect. Проверьте подключение и повторите попытку.';

  @override
  String get supportErrorNotFound => 'Мы не нашли это обращение.';

  @override
  String get supportErrorGeneric => 'Что-то пошло не так. Повторите попытку.';

  @override
  String get supportTryAgain => 'Повторить';

  @override
  String get supportTicketsEyebrow => 'ПОДДЕРЖКА';

  @override
  String get supportTicketsTitle => 'Мои обращения';

  @override
  String get supportTicketsSubtitle => 'Твои обращения и наши ответы.';

  @override
  String get supportTicketsActiveSection => 'АКТИВНЫЕ';

  @override
  String get supportTicketsClosedSection => 'РЕШЁННЫЕ И ЗАКРЫТЫЕ';

  @override
  String get supportTicketsEmptyTitle => 'Обращений пока нет';

  @override
  String get supportTicketsEmptyBody =>
      'Когда ты напишешь в поддержку, твоё обращение и наши ответы появятся здесь.';

  @override
  String get supportTicketsLoadErrorTitle => 'Не удалось загрузить обращения';

  @override
  String supportTicketUpdated(String when) {
    return 'Обновлено $when';
  }

  @override
  String get supportNewTicket => 'Новое обращение';

  @override
  String get supportStatusOpen => 'Открыто';

  @override
  String get supportStatusWaitingForYou => 'Ждёт твоего ответа';

  @override
  String get supportStatusOnHold => 'Приостановлено';

  @override
  String get supportStatusResolved => 'Решено';

  @override
  String get supportStatusClosed => 'Закрыто';

  @override
  String supportStatusSemantics(String status) {
    return 'Статус: $status';
  }

  @override
  String get supportThreadAgentName => 'Поддержка Connect';

  @override
  String get supportThreadYou => 'Ты';

  @override
  String supportTicketMeta(String category, String date) {
    return '$category · Открыто $date';
  }

  @override
  String get supportBannerOpen =>
      'Мы получили твоё обращение. Команда ответит здесь и сообщит тебе.';

  @override
  String get supportBannerWaiting => 'Поддержка ответила и ждёт твоего ответа.';

  @override
  String get supportBannerOnHold =>
      'Обращение приостановлено, пока мы разбираемся. Мы сообщим здесь.';

  @override
  String get supportBannerResolved =>
      'Отмечено как решённое. Ответьте, чтобы открыть его снова; иначе оно закроется автоматически через 7 дней.';

  @override
  String supportBannerClosedUntil(String date) {
    return 'Это обращение закрыто. Его можно открыть снова до $date.';
  }

  @override
  String get supportBannerClosed => 'Это обращение закрыто.';

  @override
  String supportBannerMerged(String reference) {
    return 'Это обращение объединено с $reference. Переписка продолжается там.';
  }

  @override
  String get supportReplyHint => 'Напишите ответ';

  @override
  String get supportReplyDisabledHint => 'Ответы по этому обращению закрыты';

  @override
  String get supportSendReply => 'Отправить ответ';

  @override
  String get supportAttachScreenshot => 'Прикрепить скриншот';

  @override
  String get supportCloseTicket => 'Закрыть обращение';

  @override
  String get supportCloseConfirmTitle => 'Закрыть это обращение?';

  @override
  String get supportCloseConfirmBody =>
      'Закройте его, если проблема решена. Открыть его снова можно в течение 14 дней.';

  @override
  String get supportCancel => 'Отмена';

  @override
  String get supportClosedSnack => 'Обращение закрыто.';

  @override
  String get supportReopen => 'Открыть снова';

  @override
  String get supportReopenedSnack => 'Обращение снова открыто.';

  @override
  String get supportRateTitle => 'Как мы справились?';

  @override
  String get supportRateCaption =>
      'Оцените работу поддержки по этому обращению.';

  @override
  String supportRateStar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count звезды',
      many: '$count звёзд',
      few: '$count звезды',
      one: '$count звезда',
    );
    return '$_temp0';
  }

  @override
  String get supportRateCommentLabel =>
      'Хотите что-то добавить? (необязательно)';

  @override
  String get supportRateSubmit => 'Отправить оценку';

  @override
  String get supportRatedTitle => 'Спасибо за отзыв';

  @override
  String supportRatedValue(int rating) {
    return 'Твоя оценка: $rating из 5.';
  }

  @override
  String get supportRatingSnack => 'Спасибо за оценку.';

  @override
  String supportAttachmentImage(String name) {
    return 'Скриншот $name';
  }

  @override
  String get supportAttachmentLoadFailed => 'Не удалось загрузить вложение';

  @override
  String get supportThreadLoadErrorTitle => 'Не удалось загрузить обращение';

  @override
  String get chemistryCardEntry => 'Немного химии?';

  @override
  String get memberProfileIntroducing => 'Знакомься';

  @override
  String get memberProfileStarring => 'В главной роли';

  @override
  String get memberProfileVerified => 'Подтверждён';

  @override
  String memberProfilePhotoLabel(String name, int index, int count) {
    return '$name, фото $index из $count';
  }

  @override
  String get memberProfileNoPhoto => 'Фото пока нет';

  @override
  String get memberProfileViewPhotoHint => 'открыть на весь экран';

  @override
  String get memberProfileCloseGallery => 'Закрыть фото';

  @override
  String get memberProfilePhotos => 'Фото';

  @override
  String memberProfileMorePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ещё $count фото',
      one: 'ещё 1 фото',
    );
    return '$_temp0';
  }

  @override
  String get memberProfileSceneAbout => 'Обо мне';

  @override
  String get memberProfileSceneStories => 'Истории';

  @override
  String get memberProfileSceneStoriesTitle => 'Ещё немного обо мне';

  @override
  String get memberProfileSceneInterests => 'Интересы';

  @override
  String get memberProfileSceneBasics => 'Основное';

  @override
  String get memberProfileSceneLifestyle => 'Образ жизни';

  @override
  String get memberProfileSceneTrust => 'Доверие';

  @override
  String get memberProfileReadMore => 'Читать дальше';

  @override
  String get memberProfileReadLess => 'Свернуть';

  @override
  String get memberProfileHobbies => 'Хобби';

  @override
  String get memberProfileActivities => 'Занятия';

  @override
  String get memberProfileSongs => 'На повторе';

  @override
  String get memberProfileBooks => 'Книги и романы';

  @override
  String get memberProfileLookingFor => 'Ищет';

  @override
  String get memberProfileLanguages => 'Языки';

  @override
  String get memberProfileDealBreakers => 'Неприемлемо';

  @override
  String get memberProfileInCommon => 'Общее';

  @override
  String get memberProfileFactHeight => 'Рост';

  @override
  String memberProfileHeightCm(int cm) {
    return '$cm см';
  }

  @override
  String get memberProfileFactWork => 'Работа';

  @override
  String get memberProfileFactEducation => 'Образование';

  @override
  String get memberProfileFactLivesIn => 'Живёт в';

  @override
  String get memberProfileFactMotherTongue => 'Родной язык';

  @override
  String get memberProfileFactReligion => 'Религия';

  @override
  String get memberProfileFactPersonality => 'Характер';

  @override
  String get memberProfileFactRelationship => 'Семейное положение';

  @override
  String get memberProfileFactInstagram => 'Instagram';

  @override
  String get memberProfileFactDrinking => 'Алкоголь';

  @override
  String get memberProfileFactSmoking => 'Курение';

  @override
  String get memberProfileFactWorkout => 'Спорт';

  @override
  String get memberProfileFactDiet => 'Питание';

  @override
  String get memberProfileFactDietType => 'Тип питания';

  @override
  String get memberProfileFactSleep => 'Сон';

  @override
  String get memberProfileFactTravel => 'Путешествия';

  @override
  String get memberProfileFactPets => 'Питомцы';

  @override
  String get memberProfileFactPolitics => 'Политика';

  @override
  String get memberProfileFactOpenToCasual => 'Открыт к лёгким отношениям';

  @override
  String get memberProfileFactPartyLover => 'Любит вечеринки';

  @override
  String get memberProfileVerifiedTitle => 'Профиль подтверждён';

  @override
  String get memberProfileVerifiedBody => 'Проверка личности пройдена.';

  @override
  String get memberProfileVouchesTitle => 'Рекомендации друзей';

  @override
  String get memberProfileSpotlight => 'В центре внимания';

  @override
  String get memberProfileFreeWhenYouAre => 'Свободен, когда и ты';

  @override
  String get memberProfileMessage => 'Написать';

  @override
  String get memberProfileLove => 'Сердце';

  @override
  String get memberProfileReport => 'Пожаловаться';

  @override
  String get memberProfileOwnerTitle => 'Так тебя видят';

  @override
  String get memberProfileOwnerCaption =>
      'Участники видят твой профиль именно так.';

  @override
  String memberProfileCompleteness(int percent) {
    return 'Профиль заполнен на $percent%';
  }

  @override
  String get memberProfileCompletenessHint =>
      'Добавь фото, истории и детали, чтобы выделиться.';

  @override
  String get memberProfileCompletenessDone => 'Твой профиль заполнен.';

  @override
  String get memberProfileToolEdit => 'Редактировать';

  @override
  String get memberProfileToolPhotos => 'Фото';

  @override
  String get memberProfileToolStories => 'Твои истории';

  @override
  String get memberProfileToolViewers => 'Кто смотрел';

  @override
  String get memberProfileBehindTheScenes => 'За кадром';

  @override
  String get memberProfileOnlyYou => 'Это видишь только ты.';

  @override
  String get memberProfileMine => 'Мой профиль';

  @override
  String get profileShowcaseLabel => 'Тексты и моменты';

  @override
  String get profileShowcaseTitleOther => 'Своими словами';

  @override
  String get profileShowcaseTitleSelf => 'Твои публичные тексты и фото';

  @override
  String get profileShowcaseChapters => 'Главы';

  @override
  String get profileShowcasePhotos => 'Фото со стены';

  @override
  String get profileShowcaseReadAll => 'Читать все главы';

  @override
  String get profileShowcaseHiddenTitle => 'Это видишь только ты';

  @override
  String get profileShowcaseHiddenBody =>
      'Твои публичные главы и фото со стены скрыты в профиле. Включи, чтобы участники видели их здесь.';

  @override
  String get profileShowcaseShownBody =>
      'Участники видят это в твоём профиле. Показываются только главы для сообщества и фото на стене.';

  @override
  String get profileShowcaseSwitch => 'Показывать в моём профиле';

  @override
  String get profileShowcaseSaveFailed => 'Не удалось сохранить выбор.';

  @override
  String get callsHistoryTitle => 'История звонков';

  @override
  String get callsHistoryEmpty => 'Звонков пока нет.';

  @override
  String callsHistoryMatch(String id) {
    return 'Мэтч $id';
  }

  @override
  String get callsJoinLiveRoom => 'Войти в комнату звонка';

  @override
  String get callsActiveSession => 'Идёт звонок';

  @override
  String callsEndedWithDuration(String duration) {
    return 'Завершён · $duration';
  }

  @override
  String get callsSessionTitle => 'Звонок';

  @override
  String get callsStarting => 'Запускаем защищённый звонок…';

  @override
  String get callsSessionActive => 'Звонок активен';

  @override
  String get callsSessionUnavailable => 'Звонок недоступен';

  @override
  String get callsLiveRoomNote =>
      'Комната звонка откроется в защищённом окне провайдера. Во время звонка управляй микрофоном, камерой и выходом прямо там.';

  @override
  String get callsEnd => 'Завершить';

  @override
  String get callsErrorSignInHistory =>
      'Войди, чтобы посмотреть историю звонков.';

  @override
  String get callsErrorSignInStart => 'Войди, прежде чем начать звонок.';

  @override
  String get callsErrorPermissions =>
      'Для звонков нужен доступ к камере и микрофону.';

  @override
  String get callsErrorLoadHistory => 'Не удалось загрузить историю звонков.';

  @override
  String get callsErrorStart => 'Не удалось начать звонок.';

  @override
  String get callsErrorEnd => 'Не удалось завершить звонок.';

  @override
  String get callsErrorNotConfigured =>
      'Комнаты для звонков не настроены в этой среде.';

  @override
  String get callsErrorOpenRoom => 'Не удалось открыть комнату звонка.';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonCopy => 'Копировать';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonApply => 'Применить';

  @override
  String get commonReset => 'Сбросить';

  @override
  String get commonOpen => 'Открыть';

  @override
  String get commonView => 'Посмотреть';

  @override
  String get commonDismiss => 'Скрыть';

  @override
  String get commonAny => 'Любой';

  @override
  String get commonSomethingWentWrong => 'Что-то пошло не так';

  @override
  String get commonSomethingWentWrongTryAgain =>
      'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get commonTryAgainTitle => 'Попробовать снова';

  @override
  String get commonNothingHereYet => 'Здесь пока пусто';

  @override
  String commonLoadingLabel(String label) {
    return '$label, загрузка';
  }

  @override
  String commonDistanceKm(int distance) {
    return '$distance км';
  }

  @override
  String get navToday => 'Сегодня';

  @override
  String get navOfflineBanner =>
      'Офлайн-режим: некоторые данные могут быть устаревшими.';

  @override
  String navWeakNetworkBanner(int mbps) {
    return 'Слабая сеть. Для плавной работы приложения нужно не менее $mbps Мбит/с.';
  }

  @override
  String get navIncomingCallTitle => 'Входящий звонок';

  @override
  String get navIncomingCallBody => 'Тебе звонит твой мэтч.';

  @override
  String get navViewCallDetails => 'Подробности звонка';

  @override
  String get filterSheetTitle => 'Фильтр мэтчей';

  @override
  String get filterAgeRange => 'Возраст';

  @override
  String get filterProfileLifestyle => 'Профиль и образ жизни';

  @override
  String get filterCountry => 'Страна';

  @override
  String get filterState => 'Регион';

  @override
  String get filterCity => 'Город';

  @override
  String get filterMotherTongue => 'Родной язык';

  @override
  String get filterReligion => 'Религия';

  @override
  String get filterRelationshipStatus => 'Семейное положение';

  @override
  String get filterSmoking => 'Курение';

  @override
  String get filterDrinking => 'Алкоголь';

  @override
  String get filterPersonalityType => 'Тип личности';

  @override
  String get filterPartyLoverOnly => 'Только тусовщики';

  @override
  String get filterHookupsOnly => 'Только без обязательств';

  @override
  String get filterAdvancedBio => 'Расширенные фильтры анкеты';

  @override
  String get filterAdvancedBioBody =>
      'Книги, романы, песни, хобби, местоположение и прочие теги настраиваются в разделе «Настройки → Предпочтения в знакомствах».';

  @override
  String get filterOpenDatingPreferences => 'Открыть предпочтения';

  @override
  String get filterDistanceKm => 'Расстояние (км)';

  @override
  String get filterVerifiedOnlyTitle => 'Только проверенные';

  @override
  String get filterVerifiedOnlyBody => 'Показывать только проверенные анкеты';

  @override
  String get filterVerifiedOnlyChip => 'Только проверенные';

  @override
  String get filterPartyLoverChip => 'Тусовщик';

  @override
  String get filterHookupChip => 'Без обязательств';

  @override
  String get filterEnableTrust => 'Включить фильтр по доверию';

  @override
  String filterMinimumTrustBadges(int count) {
    return 'Минимум активных значков доверия: $count';
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
      'true': ', только проверенные',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(trust, {
      'true': ', фильтр доверия включён',
      'other': ', фильтр доверия выключен',
    });
    return 'Фильтры сохранены: $minAge–$maxAge лет, $distance км$_temp0$_temp1';
  }

  @override
  String get optionNever => 'Никогда';

  @override
  String get optionOccasionally => 'Иногда';

  @override
  String get optionSocially => 'В компании';

  @override
  String get optionRegularly => 'Регулярно';

  @override
  String get optionSingle => 'Не в отношениях';

  @override
  String get optionDivorced => 'В разводе';

  @override
  String get optionWidowed => 'Вдовец/вдова';

  @override
  String get optionSeparated => 'Живём раздельно';

  @override
  String get optionComplicated => 'Всё сложно';

  @override
  String get optionIntrovert => 'Интроверт';

  @override
  String get optionAmbivert => 'Амбиверт';

  @override
  String get optionExtrovert => 'Экстраверт';

  @override
  String get optionHighSchool => 'Среднее';

  @override
  String get optionBachelors => 'Бакалавр';

  @override
  String get optionMasters => 'Магистр';

  @override
  String get optionPhd => 'Кандидат наук';

  @override
  String get optionOther => 'Другое';

  @override
  String get optionPreferNotToSay => 'Предпочитаю не указывать';

  @override
  String get optionHindu => 'Индуизм';

  @override
  String get optionMuslim => 'Ислам';

  @override
  String get optionChristian => 'Христианство';

  @override
  String get optionSikh => 'Сикхизм';

  @override
  String get optionBuddhist => 'Буддизм';

  @override
  String get optionJain => 'Джайнизм';

  @override
  String get optionJewish => 'Иудаизм';

  @override
  String get optionSpiritual => 'Духовность';

  @override
  String get optionAgnostic => 'Агностицизм';

  @override
  String get optionAtheist => 'Атеизм';

  @override
  String get storiesNudgeTitle => 'Расскажи немного больше о себе';

  @override
  String get storiesNudgeBodyUnknown =>
      'Короткие истории в профиле дают людям настоящий повод поздороваться.';

  @override
  String get storiesNudgeActionOpen => 'Открыть истории';

  @override
  String get storiesNudgeBodyEmpty =>
      'Добавь в профиль короткую историю: маленькую радость, выходные, которыми хочется поделиться. Люди читают их, прежде чем поздороваться.';

  @override
  String get storiesNudgeActionFirst => 'Написать первую историю';

  @override
  String get storiesNudgeCompleteTitle => 'Твоя история готова';

  @override
  String get storiesNudgeCompleteBody =>
      'Все три истории уже в твоём профиле. Обнови любую, когда жизнь подарит новую.';

  @override
  String get storiesNudgeActionEdit => 'Редактировать истории';

  @override
  String storiesNudgeSharedTitle(int count, int max) {
    return 'Опубликовано историй: $count из $max';
  }

  @override
  String get storiesNudgeBodyMore =>
      'Ещё одна история — ещё один повод начать разговор.';

  @override
  String storiesNudgeBodyLatest(String prompt) {
    return 'Последняя: «$prompt». Ещё одна — ещё один повод начать разговор.';
  }

  @override
  String get storiesNudgeActionAdd => 'Добавить ещё историю';

  @override
  String get storiesNudgeIdeas => 'Идеи для начала';

  @override
  String storiesProgressSemantics(int count, int max) {
    return 'Написано историй: $count из $max';
  }

  @override
  String get storiesPromptLittleJoy =>
      'Мелочь, на которую я всегда нахожу время';

  @override
  String get storiesPromptWeekend => 'Выходные, о которых стоит рассказать';

  @override
  String get storiesPromptFirstHello => 'Первое знакомство, о котором я мечтаю';

  @override
  String get storiesPromptLearning => 'Чему я учусь — просто для себя';

  @override
  String get storiesPromptCare => 'Как я по-своему проявляю заботу';

  @override
  String get storiesScreenTitle => 'Немного больше о тебе';

  @override
  String get storiesSignIn => 'Войди, чтобы редактировать свои истории.';

  @override
  String get storiesLoadFailed => 'Не удалось загрузить твои истории.';

  @override
  String get storiesTryAgain => 'Попробовать ещё раз';

  @override
  String get storiesIncomplete =>
      'Добавь текст к каждой истории и описание к каждому фото или удали незаконченную историю.';

  @override
  String get storiesPublished => 'Твои истории опубликованы в профиле.';

  @override
  String get storiesSavedPrivately =>
      'Сохранено приватно. Другие участники не видят твои истории.';

  @override
  String get storiesSaveUnconfirmed =>
      'Не удалось подтвердить сохранение. Твои правки на месте; загрузи сохранённые истории заново, чтобы проверить.';

  @override
  String get storiesHeadline => 'Позволь кому-то узнать\nтебя в обычной жизни.';

  @override
  String get storiesIntro =>
      'Маленький ритуал, история за фотографией, первое знакомство, которое тебе понравилось бы. Поделись тремя моментами своими словами.';

  @override
  String get storiesOptionalNote =>
      'По желанию, без баллов и обязательного заполнения. Не указывай контакты или точные места, которыми не хочешь делиться.';

  @override
  String get storiesPublishSwitch => 'Показывать эти истории в моём профиле';

  @override
  String get storiesPublishSwitchHint =>
      'По умолчанию выключено. Видны подходящим участникам, когда твой профиль опубликован и доступен. Скрыть можно в любой момент.';

  @override
  String get storiesBackToEditing => 'Вернуться к редактированию';

  @override
  String get storiesPreview => 'Предпросмотр историй';

  @override
  String get storiesPreviewBanner => 'ПРЕДПРОСМОТР · НЕ ПУБЛИКУЕТСЯ';

  @override
  String get storiesAdd => 'Добавить историю';

  @override
  String get storiesReloadDiscard =>
      'Загрузить сохранённые истории · отменить правки';

  @override
  String get storiesSaving => 'Сохранение…';

  @override
  String get storiesPublishButton => 'Опубликовать истории';

  @override
  String get storiesSavePrivatelyButton => 'Сохранить приватно';

  @override
  String get storiesPolicyNote =>
      'Фото берутся из одобренной галереи твоего профиля. На истории и фото по-прежнему распространяются жалобы участников и правила безопасности.';

  @override
  String storiesMomentLabel(int number) {
    return 'МОМЕНТ $number';
  }

  @override
  String storiesRemoveTooltip(int number) {
    return 'Удалить историю $number';
  }

  @override
  String get storiesPromptLabel => 'С чего начать';

  @override
  String get storiesTextLabel => 'Своими словами';

  @override
  String get storiesTextHint => 'Настоящая деталь делает историю твоей.';

  @override
  String get storiesTextRequired => 'Напиши пару слов или удали эту историю.';

  @override
  String get storiesPhotoLabel => 'Фото — по желанию';

  @override
  String get storiesWordsOnly => 'Только текст';

  @override
  String storiesProfilePhoto(int number) {
    return 'Фото профиля $number';
  }

  @override
  String get storiesPhotoDescriptionLabel => 'Опиши это фото';

  @override
  String get storiesPhotoDescriptionHelper =>
      'Помогает людям, которые пользуются программами чтения с экрана.';

  @override
  String get storiesPhotoDescriptionRequired =>
      'Добавь короткое описание фото.';

  @override
  String get storiesPhotoSemantics => 'Фото к истории профиля';

  @override
  String get storiesSectionTitle => 'Немного больше обо мне';

  @override
  String get storiesRetryLoad => 'Загрузить истории ещё раз';

  @override
  String get authErrorSessionExpired => 'Сеанс завершён. Войди снова.';

  @override
  String get authErrorSignInFailed => 'Не удалось войти. Попробуй ещё раз.';

  @override
  String get authErrorCreateAccountFailed =>
      'Не удалось создать аккаунт. Попробуй ещё раз.';

  @override
  String get authErrorCreateAccountGeneric => 'Не удалось создать аккаунт.';

  @override
  String get authErrorInvalidCredentials =>
      'Неверное имя пользователя или пароль.';

  @override
  String get authErrorUsernameFormat =>
      'Имя пользователя: 3–30 символов — буквы, цифры, _ или .';

  @override
  String get authErrorPasswordFormat =>
      'Пароль должен занимать 8–72 байта и содержать буквы и цифры.';

  @override
  String get authWelcomeIntroducerLink =>
      'Я здесь, только чтобы знакомить друзей';

  @override
  String get signupBackTooltip => 'Назад';

  @override
  String get signupIntroducerTitle =>
      'Стань тем другом, который знакомит людей.';

  @override
  String get signupIntroducerBody =>
      'Аккаунт только для дружбы. Без профиля для знакомств, фото и свайпов. Твой возраст скрыт; Connect — для взрослых от 18 до 80 лет.';

  @override
  String get signupTitle => 'Создай аккаунт';

  @override
  String get signupSubtitle =>
      'Выбери уникальное имя пользователя и надёжный пароль';

  @override
  String get signupUsernameLabel => 'Уникальное имя пользователя';

  @override
  String get signupUsernameHint => 'your_username';

  @override
  String get signupUsernameHelp =>
      '3–30 символов. Буквы, цифры, подчёркивание и точка.';

  @override
  String get signupPasswordLabel => 'Пароль';

  @override
  String get signupPasswordHint => 'Не менее 8 символов';

  @override
  String get signupConfirmPasswordHint => 'Повтори пароль';

  @override
  String get signupNameLabel => 'Полное имя';

  @override
  String get signupNameHint => 'Твоё имя';

  @override
  String get signupDobLabel => 'Дата рождения';

  @override
  String get signupDobPickerHelp => 'Выбери дату рождения';

  @override
  String get signupDobPlaceholder => 'Выбрать дату';

  @override
  String get signupGenderLabel => 'Я идентифицирую себя как';

  @override
  String get signupGenderMan => 'Мужчина';

  @override
  String get signupGenderWoman => 'Женщина';

  @override
  String get signupGenderOther => 'Другое';

  @override
  String get signupCreateFriendAccount => 'Создать аккаунт для дружбы';

  @override
  String get signupAlreadyHaveAccount => 'Уже есть аккаунт?';

  @override
  String get signupErrorPasswordMismatch => 'Пароли не совпадают.';

  @override
  String get signupErrorFullName => 'Введи своё полное имя.';

  @override
  String get signupErrorDobMissing => 'Выбери дату рождения.';

  @override
  String get signupErrorUnderage => 'Тебе должно быть не меньше 18 лет.';

  @override
  String get signupErrorAgeRange =>
      'Сейчас Connect доступен участникам в возрасте от 18 до 80 лет.';

  @override
  String get signupErrorGenderMissing => 'Выбери, как ты себя идентифицируешь.';

  @override
  String get authRecoveryEnterUsername => 'Введи имя пользователя.';

  @override
  String get authRecoveryEnterCode => 'Введи код восстановления.';

  @override
  String get authRecoveryPasswordRule =>
      'Используй 8–72 символа, минимум одну букву и одну цифру.';

  @override
  String get authRecoveryResetDone =>
      'Пароль сброшен, и все устройства вышли из аккаунта. Войди с новым паролем.';

  @override
  String get authRecoveryAssistanceDone =>
      'Если это имя пользователя принадлежит аккаунту Connect, наша команда безопасности рассмотрит запрос.';

  @override
  String get authRecoveryInvalidCode =>
      'Этот код восстановления недействителен или истёк.';

  @override
  String get authRecoveryOffline =>
      'Не удалось связаться с Connect. Проверь подключение и попробуй ещё раз.';

  @override
  String get authRecoverySendFailed =>
      'Не удалось отправить запрос. Проверь подключение и попробуй ещё раз.';

  @override
  String get authRecoveryBackToSignIn => 'Вернуться ко входу';

  @override
  String get authRecoveryHaveCode => 'У меня есть код';

  @override
  String get authRecoveryLostCode => 'Код утерян';

  @override
  String get authRecoveryHaveCodeIntro =>
      'Используй код восстановления, сохранённый при создании аккаунта, или код от нашей команды безопасности.';

  @override
  String get authRecoveryLostCodeIntro =>
      'Сообщи нам имя пользователя. Мы подтвердим твою личность, прежде чем выдать код восстановления. Мы никогда не спрашиваем пароль.';

  @override
  String get authRecoveryUsernameLabel => 'Имя пользователя';

  @override
  String get authRecoveryCodeLabel => 'Код восстановления';

  @override
  String get authRecoveryNewPasswordLabel => 'Новый пароль';

  @override
  String get authRecoveryMessageLabel =>
      'Что-нибудь, что нам поможет (необязательно)';

  @override
  String get authRecoveryMessageHint => 'Например, когда был последний вход';

  @override
  String get authRecoverySending => 'Отправка…';

  @override
  String get authRecoveryResetPassword => 'Сбросить пароль';

  @override
  String get authRecoveryAskForHelp => 'Попросить помощи';

  @override
  String get authTermsTitle => 'Условия использования';

  @override
  String get authTermsSubtitle => 'Короткий обзор перед входом в приложение.';

  @override
  String get authTermsIntro =>
      'Ознакомься с Условиями и Политикой конфиденциальности и прими их, чтобы продолжить.';

  @override
  String get authTermsCommunityTitle => 'Правила сообщества';

  @override
  String get authTermsPointRespect => 'Будь уважителен и честен.';

  @override
  String get authTermsPointNoHarassment =>
      'Никаких домогательств и мошенничества.';

  @override
  String get authTermsPointPrivacy =>
      'Ты сам управляешь настройками конфиденциальности и видимостью профиля.';

  @override
  String get authTermsPointReports =>
      'Мы проверяем жалобы, чтобы сообщество оставалось безопасным.';

  @override
  String get authTermsPointViolations =>
      'Нарушения могут привести к блокировке или удалению аккаунта.';

  @override
  String get authTermsReviewLater =>
      'Полный текст правил можно позже посмотреть в настройках, но принять их нужно до начала использования приложения.';

  @override
  String get authTermsAgreeCheckbox =>
      'Я принимаю Условия и Политику конфиденциальности';

  @override
  String get authTermsAcceptButton => 'Принять и продолжить';

  @override
  String get authTermsSaveFailed =>
      'Не удалось сохранить согласие. Проверь подключение и попробуй ещё раз.';

  @override
  String discoverSuperLikeSent(String name) {
    return 'Суперлайк для $name отправлен';
  }

  @override
  String get discoverMatchPlaceholderMessage => 'Поздоровайся';

  @override
  String discoverChatNeedsMatch(String name) {
    return 'Написать пользователю $name можно будет после настоящего мэтча.';
  }

  @override
  String get discoverDailyLimitTitle => 'Лайки на сегодня закончились';

  @override
  String get discoverDailyLimitBody =>
      'Возвращайся завтра или повысь тариф, чтобы получать больше лайков каждый день.';

  @override
  String discoverDailyLimitResetBody(String reset) {
    return '$reset. Повысь тариф, чтобы получать больше лайков каждый день.';
  }

  @override
  String get discoverSeePlans => 'Смотреть тарифы';

  @override
  String get discoverNotNow => 'Не сейчас';

  @override
  String get discoverBackToToday => 'Назад к «Сегодня»';

  @override
  String get discoverExploreTitle => 'Обзор';

  @override
  String get discoverSpotlightReviewed =>
      'Все профили в центре внимания просмотрены!';

  @override
  String get discoverAllReviewed => 'Все просмотрены!';

  @override
  String get discoverCuratedForYou => 'Подобрано для тебя';

  @override
  String get discoverTitle => 'Найди свой мэтч';

  @override
  String get discoverTagline => 'Немного любопытства. Настоящая связь.';

  @override
  String get discoverMessages => 'Сообщения';

  @override
  String get discoverFilters => 'Фильтры';

  @override
  String get discoverYourDeck => 'Твоя подборка';

  @override
  String get discoverStatReady => 'Готово';

  @override
  String get discoverStatLiked => 'Лайки';

  @override
  String get discoverStatPassed => 'Пропущено';

  @override
  String get discoverEdit => 'Изменить';

  @override
  String get discoverShowingEveryone =>
      'Показаны все, кто подходит под твои предпочтения.';

  @override
  String get discoverToday => 'Сегодня';

  @override
  String get discoverTodaySubtitle => 'Пять анкет, обновляются каждый день.';

  @override
  String get discoverViewAll => 'Смотреть все';

  @override
  String get discoverMatchOnYourTerms => 'Мэтчи на твоих условиях';

  @override
  String get discoverMatchOnYourTermsBody =>
      'Мэтч появляется только при взаимной симпатии. Ты можешь заблокировать любого или пожаловаться на него из профиля или переписки.';

  @override
  String get discoverErrorEyebrow => 'Связь прервалась';

  @override
  String get discoverErrorTitle => 'Не удалось загрузить профили';

  @override
  String discoverTrustFilteredBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Фильтры доверия скрыли $count профиля. Ослабь фильтры доверия или обнови подборку.',
      many:
          'Фильтры доверия скрыли $count профилей. Ослабь фильтры доверия или обнови подборку.',
      few:
          'Фильтры доверия скрыли $count профиля. Ослабь фильтры доверия или обнови подборку.',
      one:
          'Фильтры доверия скрыли $count профиль. Ослабь фильтры доверия или обнови подборку.',
    );
    return '$_temp0';
  }

  @override
  String get discoverDeckPreparingBody =>
      'Твоя подборка готовится. Обнови, чтобы увидеть новые проверенные профили рядом.';

  @override
  String get discoverCheckBackSoon => 'Загляни позже';

  @override
  String get discoverNoSpotlightProfiles => 'Нет профилей в центре внимания';

  @override
  String get discoverNoProfiles => 'Нет профилей';

  @override
  String get discoverRefresh => 'Обновить';

  @override
  String get discoverPromisePrivate => 'Приватно';

  @override
  String get discoverPremium => 'Премиум';

  @override
  String discoverNotificationsUnread(int count) {
    return 'Уведомления, непрочитанных: $count';
  }

  @override
  String get discoverLatestUnreadNotifications =>
      'Последние непрочитанные уведомления';

  @override
  String get discoverNoUnreadNotifications => 'Нет непрочитанных уведомлений';

  @override
  String get discoverNotificationWhoReplied => 'Кто мне ответил';

  @override
  String discoverNotificationRepliesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count новых ответа',
      many: '$count новых ответов',
      few: '$count новых ответа',
      one: '$count новый ответ',
    );
    return '$_temp0';
  }

  @override
  String get discoverNotificationWhoLiked => 'Кто меня лайкнул';

  @override
  String discoverNotificationLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count новых лайка',
      many: '$count новых лайков',
      few: '$count новых лайка',
      one: '$count новый лайк',
    );
    return '$_temp0';
  }

  @override
  String get discoverViewMore => 'Подробнее';

  @override
  String get discoverFitsYourWeek => 'Под твою неделю';

  @override
  String discoverTodayPicks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count анкеты',
      many: '$count анкет',
      few: '$count анкеты',
      one: '$count анкета',
    );
    return '$_temp0';
  }

  @override
  String get discoverPickedForYouToday => 'Выбрано для тебя сегодня.';

  @override
  String get discoverErrorLoginToDiscover => 'Войди, чтобы смотреть профили.';

  @override
  String get discoverErrorLoadProfiles =>
      'Не удалось загрузить профили. Попробуй ещё раз.';

  @override
  String get discoverErrorSessionUnavailable =>
      'Сессия недоступна. Войди снова.';

  @override
  String get discoverErrorLikeRetry =>
      'Сейчас не получается поставить лайк. Попробуй ещё раз.';

  @override
  String get discoverErrorLike => 'Сейчас не получается поставить лайк.';

  @override
  String get discoverErrorPassRetry =>
      'Сейчас не получается пропустить. Попробуй ещё раз.';

  @override
  String get discoverErrorLoadLikedMe =>
      'Не удалось загрузить, кто тебя лайкнул. Попробуй ещё раз.';

  @override
  String get discoverErrorAnswerInFlight => 'Твой ответ уже отправляется.';

  @override
  String get discoverErrorAnswer =>
      'Не удалось отправить ответ. Попробуй ещё раз.';

  @override
  String get firstChapterTopicPace => 'Темп общения';

  @override
  String get firstChapterTopicDates => 'Комфорт на свиданиях';

  @override
  String get firstChapterTopicLanguage => 'Языки';

  @override
  String get firstChapterTopicFamily => 'Участие семьи';

  @override
  String get firstChapterInMyWords => 'Своими словами';

  @override
  String firstChapterComfortOriginal(String language) {
    return 'Оригинал · $language';
  }

  @override
  String firstChapterComfortMemberTranslation(String language) {
    return 'Перевод от участника · $language';
  }

  @override
  String get firstChapterComfortReloadSaved => 'Загрузить сохранённую версию';

  @override
  String get firstChapterComfortReloadCards => 'Загрузить карточки снова';

  @override
  String get firstChapterComfortHeadline => 'Твои слова. Твои границы.';

  @override
  String get firstChapterComfortIntro =>
      'Необязательный контекст для тех, с кем у тебя мэтч. Мы не делаем никаких выводов о твоём происхождении. Пиши на том языке, который тебе ближе.';

  @override
  String get firstChapterComfortShareTitle =>
      'Показывать эти карточки моим мэтчам';

  @override
  String get firstChapterComfortShareSubtitle =>
      'Если выключено, все карточки остаются приватными.';

  @override
  String get firstChapterComfortRemoveFromDraft => 'Убрать из черновика';

  @override
  String get firstChapterComfortTopicLabel => 'Немного о том, что касается';

  @override
  String get firstChapterComfortOriginalLanguage => 'Язык оригинала';

  @override
  String get firstChapterComfortOwnWords => 'Своими словами';

  @override
  String get firstChapterComfortOwnWordsHint =>
      'Например: мне нравятся свидания днём и немного времени, чтобы освоиться.';

  @override
  String get firstChapterComfortTranslation => 'Твой перевод (необязательно)';

  @override
  String get firstChapterComfortTranslationLanguage =>
      'Язык перевода (если добавлен)';

  @override
  String get firstChapterComfortTranslationNote =>
      'Переводы помечаются как сделанные участником. Твой оригинальный текст всегда сохраняется.';

  @override
  String get firstChapterComfortAddCard =>
      'Добавить / заменить карточку в черновике';

  @override
  String get firstChapterComfortMissingFields =>
      'Добавь текст и язык. Для перевода тоже нужно указать язык.';

  @override
  String get firstChapterComfortUnaddedCard =>
      'Перед сохранением добавь написанную карточку в черновик.';

  @override
  String get firstChapterComfortSaveFailed =>
      'Черновик на месте. Перед повторной попыткой обнови страницу и проверь последнюю сохранённую версию.';

  @override
  String get firstChapterSaving => 'Сохранение…';

  @override
  String get firstChapterComfortSave => 'Сохранить мой выбор';

  @override
  String get firstChapterYourMatch => 'твой мэтч';

  @override
  String get firstChapterSaveUnconfirmed =>
      'Не удалось подтвердить сохранение. Обнови страницу и проверь, прежде чем пробовать снова.';

  @override
  String get firstChapterJointPreviewTitle =>
      'История, которую одобряете вы оба';

  @override
  String get firstChapterSoloPreviewTitle => 'Предпросмотр публичной главы';

  @override
  String firstChapterThenSurprise(String surprise) {
    return 'А потом… $surprise';
  }

  @override
  String get firstChapterJointPreviewBody =>
      'Твоё одобрение — это половина. Ссылка заработает, только когда собеседник тоже одобрит именно эту карточку. Любой из вас может её отозвать.';

  @override
  String get firstChapterSoloPreviewBody =>
      'Публичными будут только эта сцена и выбранное тобой начало. Никаких имён, фото, личных сообщений, местоположения или вклада собеседника. Ссылку можно отозвать.';

  @override
  String get firstChapterKeepPrivate => 'Оставить приватным';

  @override
  String get firstChapterApproveMyHalf => 'Одобрить свою половину';

  @override
  String get firstChapterCreateShareLink => 'Создать ссылку';

  @override
  String get firstChapterStudioTitle => 'Студия «Первая глава»';

  @override
  String get firstChapterRefresh => 'Обновить главу';

  @override
  String get firstChapterHeroEyebrow => 'МАЛЕНЬКОЕ ПРИКЛЮЧЕНИЕ. ДВА АВТОРА.';

  @override
  String get firstChapterHeroTitle => 'Что будет дальше,\nрешать вам.';

  @override
  String get firstChapterHeroSolo =>
      'Придумай сцену. Передай её другу. Или создай первую главу вместе с тем, с кем у тебя мэтч.';

  @override
  String firstChapterHeroPair(String name) {
    return 'Ты и $name. Одно начало, один неожиданный поворот и история, которую можно воплотить в жизнь.';
  }

  @override
  String get firstChapterHeroPace =>
      'По желанию и в твоём темпе. Общаться в чате — всегда твой выбор.';

  @override
  String get firstChapterLoadFailed => 'Не удалось загрузить главу.';

  @override
  String get firstChapterTryAgain => 'Повторить';

  @override
  String get firstChapterStepChooseScene => '01 / Выбери сцену';

  @override
  String get firstChapterStepWriteBeginning => '02 / Напиши начало';

  @override
  String get firstChapterStartOurChapter => 'Начать нашу главу';

  @override
  String get firstChapterPassTheChapter => 'Передать главу';

  @override
  String get firstChapterYourFirstChapter => 'Ваша первая глава';

  @override
  String get firstChapterItBeginsWith => 'ВСЁ НАЧИНАЕТСЯ С';

  @override
  String get firstChapterAndThen => 'А ПОТОМ…';

  @override
  String firstChapterDateIdeaNote(String beginning, String surprise) {
    return '$beginning. Потом $surprise.';
  }

  @override
  String get firstChapterMakeDateIdea => 'Сделать из этого идею свидания';

  @override
  String get firstChapterDateIdeaHint =>
      'Предложение, которое вы доработаете вместе. Свидание не назначается и не принимается автоматически.';

  @override
  String get firstChapterYourTurn => 'Твоя очередь: добавь сюрприз.';

  @override
  String get firstChapterBeginningSaved =>
      'Начало сохранено. Твой мэтч может добавить сюрприз, когда захочет. А пока можно продолжать общаться.';

  @override
  String get firstChapterClose => 'Закрыть эту главу';

  @override
  String get firstChapterGiveBackTitle => 'Истории, которые вдохновляют других';

  @override
  String get firstChapterGiveBackBody =>
      'Ваша связь может вдохновить кого-то на новое начало. Поделитесь только этой анонимной идеей свидания — с согласия вас обоих.';

  @override
  String get firstChapterPreviewAnonymous =>
      'Предпросмотр нашей анонимной истории';

  @override
  String get firstChapterGreenLightTitle => 'Приватный зелёный свет';

  @override
  String get firstChapterInTheirWords => 'Их словами';

  @override
  String get firstChapterMakeRoomTitle => 'Расскажи о том, что для тебя важно';

  @override
  String get firstChapterMakeRoomSubtitle =>
      'Твой темп, языки, свидания и ожидания семьи. Твои слова — только когда ты решишь ими поделиться.';

  @override
  String get firstChapterCreateWithConnection => 'Создать вместе с мэтчем';

  @override
  String get firstChapterCreateTogether => 'Создать первую главу вместе';

  @override
  String get firstChapterMatchesAppearHere =>
      'Здесь появятся ваши взаимные мэтчи. А пока можешь попробовать и поделиться сценой в одиночку.';

  @override
  String get firstChapterSharedChapters => 'Твои опубликованные главы';

  @override
  String get firstChapterReloadShared => 'Загрузить опубликованные главы снова';

  @override
  String get firstChapterNothingPublic =>
      'Ничего не публикуется, пока ты сам не решишь поделиться.';

  @override
  String get firstChapterGreenChat => 'Продолжать общаться';

  @override
  String get firstChapterGreenCall => 'Попробовать созвониться';

  @override
  String get firstChapterGreenDate => 'Предложить свидание';

  @override
  String get firstChapterGreenLightIntro =>
      'Раскрывается только общий выбор. Никто не видит запрос без ответа. Выбор действует семь дней; сними его, чтобы отозвать.';

  @override
  String get firstChapterSavePrivately => 'Сохранить приватно';

  @override
  String get firstChapterGreenLightNone =>
      'Здесь появится ваш общий следующий шаг.';

  @override
  String firstChapterGreenLightMutual(String choices) {
    return 'Вам обоим комфортно: $choices';
  }

  @override
  String get firstChapterGreenLightNote =>
      'Зелёный свет — это разрешение предложить. Для звонка или свидания всё равно нужно отдельное согласие.';

  @override
  String get firstChapterLinkRevoked => 'Ссылка отозвана';

  @override
  String get firstChapterPublicScene => 'Публичная анонимная сцена';

  @override
  String get firstChapterPrivateUntilBoth => 'Приватно, пока оба не одобрят';

  @override
  String get firstChapterLinkCopied =>
      'Ссылка на главу скопирована. Делись ею где угодно.';

  @override
  String get firstChapterCopyLink => 'Скопировать ссылку';

  @override
  String get firstChapterApproveStory => 'Одобрить именно эту историю';

  @override
  String get firstChapterRevokeLink => 'Отозвать ссылку';

  @override
  String networkSlowResponse(int mbps) {
    return 'Слабая сеть. Для плавной работы чатов, подарков и жестов нужно не менее $mbps Мбит/с.';
  }

  @override
  String get networkOffline =>
      'Нет стабильного подключения к сети. Подключитесь снова, чтобы продолжить.';

  @override
  String networkWeak(int mbps) {
    return 'Сеть слабая. Для плавной работы нужно не менее $mbps Мбит/с.';
  }

  @override
  String get networkCannotReachService =>
      'Не удаётся подключиться к локальному сервису. Проверьте, что API запущен.';

  @override
  String get gateCheckingTerms => 'Проверяем условия…';

  @override
  String get gateLoadingProfile => 'Загружаем твой профиль…';

  @override
  String get gateConnectionIssue => 'Проблема с подключением';

  @override
  String get safetyReportFailed => 'Не удалось отправить жалобу';

  @override
  String get safetyBlockFailed => 'Не удалось заблокировать пользователя';

  @override
  String get safetyUnblockFailed => 'Не удалось разблокировать пользователя';

  @override
  String get safetyNotAuthenticated => 'Нужно войти в аккаунт';

  @override
  String get timeAgoJustNow => 'Только что';

  @override
  String timeAgoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минут назад',
      few: '$count минуты назад',
      one: '$count минуту назад',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часов назад',
      few: '$count часа назад',
      one: '$count час назад',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней назад',
      few: '$count дня назад',
      one: '$count день назад',
    );
    return '$_temp0';
  }

  @override
  String timeAgoWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count недель назад',
      few: '$count недели назад',
      one: '$count неделю назад',
    );
    return '$_temp0';
  }

  @override
  String get themePreviewBarrier => 'Предпросмотр темы';

  @override
  String get themeNowShowing => 'СЕЙЧАС НА ЭКРАНЕ';

  @override
  String get themeTaglineRealLife =>
      'Тёплая слоновая кость, лесная зелень и абрикос.';

  @override
  String get themeTaglineRealLifeNight =>
      'Лесная зелень, нежная мята и свет свечей.';

  @override
  String get themeTaglineDaylight =>
      'Сливочный, чернильный и малиновый акцент — как на сайте.';

  @override
  String get themeTaglineEmber =>
      'Сливово-чёрная ночь с отблесками углей и фиолетовым сиянием.';

  @override
  String get themeTaglineForge =>
      'Раскалённый красный, стальной синий, оружейный хром.';

  @override
  String get themeTaglineNeongrid =>
      'Чёрное стекло, голубые световые линии, янтарный пульс.';

  @override
  String get themeTaglineCrimsonalloy =>
      'Багровый лак, расплавленное золото, полуночный бордо.';

  @override
  String get themeTaglineCircuit =>
      'Зелёный печатных плат, сигнальный фиолетовый, угольно-чёрный.';

  @override
  String get themeTaglineDeepfield =>
      'Глубокий космос, плазменно-синий и вспышка звёздного золота.';

  @override
  String get themeTaglineLove => 'Румянец, роза и немного золота.';

  @override
  String get themeTaglineRose => 'Бархатное вино, алая роза и немного золота.';

  @override
  String get themeTaglinePetal =>
      'Розовая бумага, летящие лепестки, нотка шалфея.';

  @override
  String get themeTaglineSnow =>
      'Свежий снег, матовое стекло и лента северного сияния.';

  @override
  String get themeTaglineGothic =>
      'Лунное кружево, гранат, дым свечей и античное золото.';

  @override
  String get themeTaglineCalm =>
      'Минимум раздражителей, высокий контраст. Неподвижный фон, без анимации.';

  @override
  String get themeLooksTodayDescription =>
      'Днём — тёплая слоновая кость и лесная зелень. Ночью — нежная мята и глубокий лес.';

  @override
  String get settingsEyebrow => 'НАСТРОЙКИ';

  @override
  String get settingsHeaderSubtitle =>
      'Твой стиль, твоя приватность и твой аккаунт.';

  @override
  String get settingsThemeSection => 'Тема';

  @override
  String get settingsThemeSectionTitle => 'Сделайте по-своему';

  @override
  String get settingsThemeSectionCaption =>
      'Каждый экран следует выбранному стилю.';

  @override
  String get settingsSectionYourStory => 'Твоя история';

  @override
  String get settingsDatingRhythmTitle => 'Твой ритм знакомств';

  @override
  String get settingsDatingRhythmSubtitle =>
      'Намерения, темп, доступность и приватность знакомств';

  @override
  String get settingsProfileStoriesTitle => 'Истории твоего профиля';

  @override
  String get settingsProfileStoriesSubtitle =>
      'Маленькие моменты, твои слова, фото по желанию';

  @override
  String get settingsBlogTitle => 'Блог · Открытые главы';

  @override
  String get settingsBlogSubtitle =>
      'Твой дневник, твои фото, твой выбор аудитории';

  @override
  String get settingsLookPreviewEyebrow => 'СЕГОДНЯ';

  @override
  String get settingsLookPreviewHeadline => 'Что-то настоящее.';

  @override
  String get friendsEyebrow => 'ДРУЗЬЯ';

  @override
  String get friendsTitle => 'Твои люди';

  @override
  String get friendsSubtitle =>
      'Друзья могут переписываться, строить планы и создавать группы. Для дружбы нужно согласие обеих сторон.';

  @override
  String get friendsBack => 'Назад';

  @override
  String get friendsAddFriend => 'Добавить в друзья';

  @override
  String get friendsCreateGroup => 'Создать группу';

  @override
  String get friendsSectionRequests => 'ЗАЯВКИ';

  @override
  String get friendsRequestsWaitingOnOthers => 'Ждём ответа других';

  @override
  String get friendsRequestsWaitingOnYou => 'Ждут твоего ответа';

  @override
  String get friendsRequestsCaption =>
      'Ничего не передаётся, пока вы оба не согласитесь.';

  @override
  String get friendsSectionChats => 'ЧАТЫ';

  @override
  String get friendsChatsTitle => 'Переписки';

  @override
  String get friendsSectionIntros => 'ЗНАКОМСТВА';

  @override
  String get friendsIntrosTitle => 'Знакомства для тебя';

  @override
  String get friendsSectionVouches => 'РЕКОМЕНДАЦИИ';

  @override
  String get friendsVouchesPendingTitle => 'Рекомендации ждут твоего одобрения';

  @override
  String friendsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count друга',
      many: '$count друзей',
      few: '$count друга',
      one: '$count друг',
      zero: 'Пока нет друзей',
    );
    return '$_temp0';
  }

  @override
  String get friendsIntroduce => 'Познакомить';

  @override
  String get friendsEmptyBody =>
      'Найди знакомых по имени или имени пользователя или добавь кого-то из пар, комнаты или группы.';

  @override
  String get friendsSectionOnProfile => 'В ТВОЁМ ПРОФИЛЕ';

  @override
  String get friendsVouchesOnProfileTitle => 'Рекомендации в твоём профиле';

  @override
  String friendsQuoted(String text) {
    return '«$text»';
  }

  @override
  String friendsVouchedForYou(String name) {
    return '$name рекомендует тебя';
  }

  @override
  String get friendsHideFromProfile => 'Скрыть из профиля';

  @override
  String get friendsSectionMore => 'ЕЩЁ';

  @override
  String get friendsMoreTitle => 'Планы и знакомства';

  @override
  String get friendsPlansLinkTitle =>
      'Планы свиданий, которыми с тобой поделились';

  @override
  String get friendsPlansLinkSubtitle =>
      'Друзья сообщают тебе, когда планируют свидание и когда отмечаются после него.';

  @override
  String get friendsInviteIntroducerTitle =>
      'Пригласи друга, который не ищет пару';

  @override
  String get friendsInviteIntroducerSubtitle =>
      'Выбери, кто может тебя знакомить. Разрешение можно проверить или отозвать в любой момент.';

  @override
  String get friendsIntroTermsTitle => 'Знакомства на твоих условиях';

  @override
  String get friendsIntroTermsSubtitle =>
      'Выбери, могут ли друзья тебя знакомить и что видно в превью.';

  @override
  String get friendsSectionActivity => 'АКТИВНОСТЬ';

  @override
  String get friendsActivityTitle => 'С твоими друзьями';

  @override
  String friendsVouchSentSnack(String name) {
    return 'Рекомендация отправлена. $name одобрит её, прежде чем она появится.';
  }

  @override
  String friendsRemoveTitle(String name) {
    return 'Удалить $name из друзей?';
  }

  @override
  String get friendsRemoveBody =>
      'Вы перестанете быть друзьями, и ваш чат закроется. Человек об этом не узнает.';

  @override
  String get friendsRemoveFriend => 'Удалить из друзей';

  @override
  String get friendsIntroMadeSnack =>
      'Знакомство отправлено. Оба друга получат от тебя весточку.';

  @override
  String get friendsAddSheetLabel => 'ДОБАВИТЬ В ДРУЗЬЯ';

  @override
  String get friendsAddSheetTitle => 'Найди знакомого';

  @override
  String get friendsAddSheetCaption =>
      'Ищи по имени или @имени пользователя. Человек сам решит, принять ли заявку.';

  @override
  String get friendsSearchHiddenNote =>
      'Тебя не видно в поиске друзей, поэтому другие не найдут тебя здесь. Это можно изменить в разделе «Приватность и безопасность».';

  @override
  String get friendsSearchLabel => 'Имя или @имя пользователя';

  @override
  String get friendsSearchHelper => 'Введи минимум 3 буквы';

  @override
  String get friendsSearchFailed =>
      'Поиск сейчас недоступен. Попробуй ещё раз.';

  @override
  String friendsSearchNoResults(String query) {
    return 'По запросу «$query» никого не найдено.';
  }

  @override
  String get friendsNewGroupLabel => 'НОВАЯ ГРУППА';

  @override
  String get friendsNewGroupTitle => 'Кто в деле?';

  @override
  String get friendsNewGroupCaption =>
      'Выбери друзей для приглашения. Позже можно добавить ещё.';

  @override
  String get friendsChooseFriends => 'Выбери друзей';

  @override
  String friendsCreateGroupWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Создать группу с $count друзьями',
      many: 'Создать группу с $count друзьями',
      few: 'Создать группу с $count друзьями',
      one: 'Создать группу с $count другом',
    );
    return '$_temp0';
  }

  @override
  String get friendsSourceMatch => 'Из твоих пар';

  @override
  String get friendsSourceProfile => 'Видел(а) твой профиль';

  @override
  String get friendsSourceRoom => 'Познакомились в комнате';

  @override
  String get friendsSourceGroup => 'Из группы';

  @override
  String get friendsSourceSearch => 'Нашёл(ла) тебя по имени';

  @override
  String get friendsWantsToBeFriends => 'Хочет дружить';

  @override
  String get friendsRequestSent => 'Заявка отправлена';

  @override
  String get friendsCancel => 'Отменить';

  @override
  String get friendsDecline => 'Отклонить';

  @override
  String get friendsAccept => 'Принять';

  @override
  String friendsMessageTooltip(String name) {
    return 'Написать $name';
  }

  @override
  String friendsMessageTooltipUnread(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Написать $name, $count непрочитанного',
      many: 'Написать $name, $count непрочитанных',
      few: 'Написать $name, $count непрочитанных',
      one: 'Написать $name, $count непрочитанное',
    );
    return '$_temp0';
  }

  @override
  String friendsMoreFor(String name) {
    return 'Ещё для $name';
  }

  @override
  String get friendsMenuVouch => 'Порекомендовать';

  @override
  String get friendsMenuIntro => 'Познакомить с другом';

  @override
  String friendsChatSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Чат с $name, $count непрочитанного',
      many: 'Чат с $name, $count непрочитанных',
      few: 'Чат с $name, $count непрочитанных',
      one: 'Чат с $name, $count непрочитанное',
      zero: 'Чат с $name',
    );
    return '$_temp0';
  }

  @override
  String friendsChatSemanticsMuted(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Чат с $name, $count непрочитанного, уведомления выключены',
      many: 'Чат с $name, $count непрочитанных, уведомления выключены',
      few: 'Чат с $name, $count непрочитанных, уведомления выключены',
      one: 'Чат с $name, $count непрочитанное, уведомления выключены',
      zero: 'Чат с $name, уведомления выключены',
    );
    return '$_temp0';
  }

  @override
  String friendsIntroHeadline(String introducer, String person) {
    return '$introducer считает, что тебе стоит познакомиться: $person';
  }

  @override
  String friendsIntroHeadlineSomeone(String introducer) {
    return '$introducer считает, что тебе стоит кое с кем познакомиться';
  }

  @override
  String friendsNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String get friendsIntroNoThanks => 'Нет, спасибо';

  @override
  String get friendsIntroImIn => 'Я за';

  @override
  String get friendsVouchKeepPrivate => 'Оставить скрытой';

  @override
  String get friendsVouchShowOnProfile => 'Показать в профиле';

  @override
  String get memberProfileNoData => 'Данные профиля не найдены.';

  @override
  String get memberProfileSignInToView =>
      'Войди, чтобы посмотреть свой профиль.';

  @override
  String get memberProfileLoadFailed =>
      'Не удалось загрузить профиль. Попробуй ещё раз.';

  @override
  String get memberProfileConnectionsTitle => 'Твои связи';

  @override
  String get memberProfileConnectionsCaption => 'Твои лайки, пары и переписки.';

  @override
  String get memberProfileStatLiked => 'Твои лайки';

  @override
  String get memberProfileStatMatches => 'Пары';

  @override
  String get memberProfileStatMessages => 'Сообщения';

  @override
  String memberProfileOpenStat(String label) {
    return 'Открыть: $label';
  }

  @override
  String get memberProfileNoticedTitle => 'Кто тебя заметил';

  @override
  String get memberProfileNoticedCaption =>
      'Лайки и просмотры от участников рядом с тобой.';

  @override
  String get memberProfileWhoLikedMe => 'Кто меня лайкнул';

  @override
  String memberProfileWhoLikedMeCount(int count) {
    return 'Кто меня лайкнул ($count)';
  }

  @override
  String get memberProfileWhoLikedMeSubtitle =>
      'Участники, которым понравился твой профиль.';

  @override
  String get memberProfileWhoViewedTitle => 'Кто смотрел мой профиль';

  @override
  String get memberProfileWhoViewedSubtitle =>
      'Недавние просмотры твоего профиля.';

  @override
  String get memberProfileWhoViewedTooltip => 'Кто смотрел мой профиль';

  @override
  String get memberProfileRefreshTooltip => 'Обновить профиль';

  @override
  String get memberProfilePreferencesTitle => 'Твои предпочтения';

  @override
  String get memberProfilePrefSeeking => 'Ищу';

  @override
  String get memberProfilePrefDistance => 'Расстояние';

  @override
  String memberProfileWithinKm(int km) {
    return 'В пределах $km км';
  }

  @override
  String get profileViewersTitle => 'Смотрели мой профиль';

  @override
  String get profileViewersLoadFailed =>
      'Не удалось загрузить список просмотров.';

  @override
  String get profileViewersEmpty => 'Твой профиль ещё никто не смотрел.';

  @override
  String get profileViewersViewedRecently => 'Недавний просмотр';

  @override
  String profileViewersViewedAt(String time) {
    return 'Просмотр: $time';
  }

  @override
  String get profileMasterReligionParsi => 'Парсизм';

  @override
  String get profileMasterReligionBahai => 'Бахаизм';

  @override
  String get profileMasterReligionTribal => 'Традиционные верования';

  @override
  String get profileMasterWorkout1to2 => '1–2 раза в неделю';

  @override
  String get profileMasterWorkout3to4 => '3–4 раза в неделю';

  @override
  String get profileMasterWorkout5Plus => '5+ раз в неделю';

  @override
  String get profileMasterWorkoutDaily => 'Каждый день';

  @override
  String get profileMasterDietNoPreference => 'Без предпочтений';

  @override
  String get profileMasterDietVegetarian => 'Вегетарианство';

  @override
  String get profileMasterDietEggetarian => 'Вегетарианство с яйцами';

  @override
  String get profileMasterDietNonVegetarian => 'Всеядность';

  @override
  String get profileMasterDietVegan => 'Веганство';

  @override
  String get profileMasterDietJain => 'Джайнская диета';

  @override
  String get profileMasterDietTypeBalanced => 'Сбалансированное';

  @override
  String get profileMasterDietTypeHighProtein => 'Высокобелковое';

  @override
  String get profileMasterDietTypeLowCarb => 'Низкоуглеводное';

  @override
  String get profileMasterDietTypeKeto => 'Кето';

  @override
  String get profileMasterDietTypeMediterranean => 'Средиземноморское';

  @override
  String get profileMasterDietTypeIntermittentFasting =>
      'Интервальное голодание';

  @override
  String get profileMasterSleepEarlyBird => 'Жаворонок';

  @override
  String get profileMasterSleepNightOwl => 'Сова';

  @override
  String get profileMasterSleepFlexible => 'Гибкий график';

  @override
  String get profileMasterSleepShiftBased => 'Посменно';

  @override
  String get profileMasterTravelHomebody => 'Домосед';

  @override
  String get profileMasterTravelOccasional => 'Иногда путешествую';

  @override
  String get profileMasterTravelFrequent => 'Часто путешествую';

  @override
  String get profileMasterTravelAdventure => 'Искатель приключений';

  @override
  String get profileMasterTravelLuxury => 'Люблю роскошные поездки';

  @override
  String get profileMasterTravelBackpacker => 'Бэкпекер';

  @override
  String get profileMasterPoliticsSimilar => 'Только схожие взгляды';

  @override
  String get profileMasterPoliticsOpen => 'Открытость к разным взглядам';

  @override
  String get profileMasterPoliticsNotDiscuss => 'Предпочитаю не обсуждать';

  @override
  String get profileMasterPoliticsNoStrong => 'Нет твёрдой позиции';

  @override
  String get profileMasterIntentLongTerm => 'Долгие отношения';

  @override
  String get profileMasterIntentMarriage => 'Брак';

  @override
  String get profileMasterIntentNewFriends => 'Новые друзья';

  @override
  String get chatBackToConversations => 'Назад к диалогам';

  @override
  String get chatOfflineBanner =>
      'Ты офлайн. Черновик сохранится здесь, пока соединение не восстановится.';

  @override
  String get chatVoiceHello => 'Голосовое приветствие · читать и слушать';

  @override
  String get chatLoadFailedTitle => 'Давай переподключимся.';

  @override
  String get chatLoadFailedBody =>
      'Не удалось загрузить диалог. Попробуй ещё раз.';

  @override
  String get chatConversationEnded => 'Этот диалог завершён.';

  @override
  String get chatUnlockStepRequired =>
      'Пройди текущий шаг разблокировки, чтобы продолжить диалог.';

  @override
  String get chatGiftTrayTitle => 'Небольшой знак внимания';

  @override
  String get chatCloseGifts => 'Закрыть подарки';

  @override
  String get chatAllGifts => 'Все подарки';

  @override
  String get chatNoGiftsInCollection => 'В этой коллекции нет подарков.';

  @override
  String get chatAddCoins => 'Пополнить монеты';

  @override
  String get chatFreeGiftDaily => 'Бесплатно · 1 в день';

  @override
  String chatCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count монеты',
      many: '$count монет',
      few: '$count монеты',
      one: '$count монета',
    );
    return '$_temp0';
  }

  @override
  String get chatSendingGift => 'Отправляем подарок…';

  @override
  String get chatOfflineGifts =>
      'Ты офлайн. Подарки можно посмотреть, а отправить — когда соединение восстановится.';

  @override
  String chatGiftConfirmTitle(String gift, String name) {
    return 'Отправить «$gift» для $name?';
  }

  @override
  String chatGiftNoteQuote(String note) {
    return '«$note»';
  }

  @override
  String chatGiftBalanceAfter(int balance, int remaining) {
    return '·  $balance → останется $remaining';
  }

  @override
  String get chatGiftNoObligation =>
      'Подарок — это жест, а не обязательство отвечать или встречаться.';

  @override
  String chatGiftSendFor(String price) {
    return 'Отправить за $price';
  }

  @override
  String get chatNotNow => 'Не сейчас';

  @override
  String get chatDeleteMessageTitle => 'Удалить сообщение?';

  @override
  String get chatDeleteMessageBody => 'Сообщение удалится у вас обоих.';

  @override
  String get chatDeleteForEveryone => 'Удалить у всех';

  @override
  String get chatMessageDeletedSnack => 'Сообщение удалено.';

  @override
  String get chatUndo => 'Отменить';

  @override
  String get chatDeleteUndone => 'Удаление отменено.';

  @override
  String chatGiftReceivedFrom(String name) {
    return 'Подарок от $name';
  }

  @override
  String get chatGiftReceiverIntro => 'Ты решаешь, что остаётся в твоём чате.';

  @override
  String get chatHideGift => 'Скрыть подарок';

  @override
  String get chatHideGiftSubtitle => 'Убрать только из твоего чата.';

  @override
  String get chatReportAndHide => 'Пожаловаться и скрыть';

  @override
  String get chatReportAndHideSubtitle =>
      'Отправить команде безопасности и сразу убрать.';

  @override
  String get chatGiftHidden => 'Подарок скрыт из твоего чата.';

  @override
  String get chatReportGiftTitle => 'Пожаловаться на подарок';

  @override
  String get chatReportGiftIntro =>
      'Выбери причину. Подарок сразу будет скрыт.';

  @override
  String get chatReportReasonLabel => 'Причина';

  @override
  String get chatReportReasonUnwanted => 'Нежелательный подарок';

  @override
  String get chatReportReasonHarassment => 'Домогательство';

  @override
  String get chatReportReasonSexual => 'Сексуальный контент';

  @override
  String get chatReportReasonScam => 'Мошенничество';

  @override
  String get chatReportReasonOther => 'Другое';

  @override
  String get chatReportDetailsLabel => 'Добавить подробности (необязательно)';

  @override
  String get chatReportSubmit => 'Отправить жалобу и скрыть';

  @override
  String get chatGiftReported =>
      'Жалоба отправлена, подарок скрыт. Команда безопасности всё проверит.';

  @override
  String get chatQuickEmojis => 'Быстрые эмодзи';

  @override
  String chatWalletTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count монеты',
      many: '$count монет',
      few: '$count монеты',
      one: '$count монета',
    );
    return 'Твой кошелёк · $_temp0';
  }

  @override
  String get chatDailyLimitReached => 'Дневной лимит сообщений исчерпан';

  @override
  String get chatDailyLimitFallback => 'Попробуй завтра или улучши тариф.';

  @override
  String chatDailyLimitReset(String reset) {
    return '$reset · улучши тариф, чтобы писать больше.';
  }

  @override
  String get chatSeePlans => 'Посмотреть тарифы';

  @override
  String chatQuotaOnPlan(String quota, String plan) {
    return '$quota на тарифе $plan';
  }

  @override
  String get chatYourConversation => 'Ваш диалог';

  @override
  String get chatVerifiedHumans => 'Проверенные люди';

  @override
  String get chatVerifiedHumansShowsUp =>
      'Проверенные люди · Приходит на встречи';

  @override
  String discoverLikedBack(String name) {
    return 'Ты лайкнул(а) $name в ответ';
  }

  @override
  String discoverPassedOn(String name) {
    return '$name: пропущено';
  }

  @override
  String get discoverLikedMeLoadFailedTitle => 'Не удалось загрузить лайки';

  @override
  String get discoverLikedMeEmptyTitle => 'Новых лайков пока нет';

  @override
  String get discoverLikedMeEmptyBody =>
      'Когда кто-то тебя лайкнет, он появится здесь. Лайкни в ответ — и это мэтч.';

  @override
  String get discoverLikedMeIntro =>
      'Ты им уже нравишься. Лайкни в ответ, чтобы получился мэтч, или пропусти. Об этом никто не узнает.';

  @override
  String get discoverLikedMeTitle => 'Тебя лайкнули';

  @override
  String discoverLikedMeTitleCount(int count) {
    return 'Тебя лайкнули · $count';
  }

  @override
  String get discoverPass => 'Пропустить';

  @override
  String get discoverLikeBack => 'Лайкнуть в ответ';

  @override
  String get discoverLikedJustNow => 'Лайкнул(а) тебя только что';

  @override
  String discoverLikedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Лайкнул(а) тебя $count минуты назад',
      many: 'Лайкнул(а) тебя $count минут назад',
      few: 'Лайкнул(а) тебя $count минуты назад',
      one: 'Лайкнул(а) тебя $count минуту назад',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Лайкнул(а) тебя $count часа назад',
      many: 'Лайкнул(а) тебя $count часов назад',
      few: 'Лайкнул(а) тебя $count часа назад',
      one: 'Лайкнул(а) тебя $count час назад',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Лайкнул(а) тебя $count дня назад',
      many: 'Лайкнул(а) тебя $count дней назад',
      few: 'Лайкнул(а) тебя $count дня назад',
      one: 'Лайкнул(а) тебя $count день назад',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Лайкнул(а) тебя $count недели назад',
      many: 'Лайкнул(а) тебя $count недель назад',
      few: 'Лайкнул(а) тебя $count недели назад',
      one: 'Лайкнул(а) тебя $count неделю назад',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedOnDate(String date) {
    return 'Лайкнул(а) тебя $date';
  }

  @override
  String discoverLikedProfilesTitle(int count) {
    return 'Понравившиеся профили ($count)';
  }

  @override
  String get discoverNoLikedProfiles => 'Понравившихся профилей пока нет';

  @override
  String get discoverLikedProfileFallback => 'Понравившийся профиль';

  @override
  String get discoverPassedProfilesTitle => 'Пропущенные профили';

  @override
  String get discoverNoPassedProfiles => 'Пропущенных профилей пока нет';

  @override
  String get discoverSavedForLater => 'Отложено на потом';

  @override
  String get discoverSpotlightFiltersTitle =>
      'Фильтры профилей в центре внимания';

  @override
  String get discoverVerifiedOnly => 'Только проверенные';

  @override
  String discoverAgeRange(int min, int max) {
    return 'Возраст: $min–$max';
  }

  @override
  String get discoverSpotlightTitle => 'Мэтчи в центре внимания';

  @override
  String get discoverSpotlightSubtitle => 'Избранные премиум-знакомства';

  @override
  String discoverPassedCount(int count) {
    return 'Пропущено ($count)';
  }

  @override
  String get discoverOpenChatsFromDiscover =>
      'Открывай чаты из раздела «Поиск»';

  @override
  String get discoverNoNewNotifications => 'Новых уведомлений нет';

  @override
  String get discoverNoSpotlightMatchFilters =>
      'Нет профилей в центре внимания под эти фильтры';

  @override
  String get discoverAllSpotlightReviewed =>
      'Все профили в центре внимания просмотрены!';

  @override
  String get discoverSpotlightCheckBackLater =>
      'Загляни позже — появятся новые профили';

  @override
  String get discoverReportSubmitted => 'Жалоба отправлена.';

  @override
  String get discoverAppeal => 'Обжаловать';

  @override
  String discoverAppealPrefill(String userId) {
    return 'Пересмотреть решение модерации по жалобе на пользователя $userId';
  }

  @override
  String get discoverProfileUnavailable => 'Этот профиль сейчас недоступен.';

  @override
  String get discoverGoBack => 'Вернуться';

  @override
  String get discoverPremiumView => 'Премиум-просмотр';

  @override
  String get todayLabel => 'СЕГОДНЯ';

  @override
  String get todayRefreshTooltip => 'Обновить «Сегодня»';

  @override
  String get todayDiscoveryPreferences => 'Настройки знакомств';

  @override
  String get todayHeroTitle =>
      'Немного привета.\nМесто для чего-то настоящего.';

  @override
  String get todayHeroSubtitle =>
      'Несколько продуманных знакомств — в твоём темпе.';

  @override
  String get todaySectionPace => 'ТВОЙ ТЕМП';

  @override
  String get todayPaceTitle => 'Что подходит твоей неделе?';

  @override
  String get todayPaceBody =>
      'Твой темп, твоё идеальное первое свидание, свободное время — по желанию.';

  @override
  String get todaySetRhythm => 'Настроить ритм';

  @override
  String get todaySectionStory => 'ТВОЯ ИСТОРИЯ';

  @override
  String get todaySectionIntroductions => 'ЗНАКОМСТВА ДНЯ';

  @override
  String get todayIntroductionsTitle =>
      'Несколько людей, с которыми стоит познакомиться';

  @override
  String get todayIntroductionsCaption =>
      'Общие интересы — лишь начало. Химию тебе предстоит открыть самому.';

  @override
  String get todayPausedTitle =>
      'Не спеши, бери столько времени, сколько нужно.';

  @override
  String get todayPausedBody =>
      'Знакомства на паузе. Твои переписки никуда не делись.';

  @override
  String get todayManageRhythm => 'Управлять ритмом';

  @override
  String get todayLoadingIntroductions => 'Загрузка знакомств';

  @override
  String get todayFailedTitle => 'Твои знакомства немного задерживаются.';

  @override
  String get todayFailedBody =>
      'Не удалось загрузить свежие данные. Попробуй ещё раз.';

  @override
  String get todayTryAgain => 'Попробовать ещё раз';

  @override
  String get todayEmptyTitle => 'Небольшая передышка.';

  @override
  String get todayEmptyBody =>
      'Сейчас нет новых знакомств по твоим предпочтениям. Можно изменить ритм или посмотреть профили.';

  @override
  String get todayExploreProfiles => 'Смотреть профили';

  @override
  String get todayAllIntroductions => 'Все знакомства';

  @override
  String get todayBreatheTitle => 'Хорошей связи нужно пространство.';

  @override
  String get todayBreatheBody =>
      'Это знакомства на сегодня. Никакого обратного отсчёта, и решать насчёт каждого не обязательно.';

  @override
  String get todayExploreMore => 'Смотреть другие профили';

  @override
  String get todayCommonGround => 'НЕМНОГО ОБЩЕГО';

  @override
  String todayMeetName(String name) {
    return 'Познакомиться: $name';
  }

  @override
  String get todayFirstHelloCoffee =>
      'Для первой встречи подойдёт чашка кофе вдвоём.';

  @override
  String get todayFirstHelloWalk =>
      'Для первой встречи подойдёт дневная прогулка.';

  @override
  String get todayFirstHelloMeal =>
      'Для первой встречи подойдёт неспешный обед или ужин.';

  @override
  String get todayFirstHelloVideoCall =>
      'Для первой встречи подойдёт видеозвонок.';

  @override
  String get todayFirstHelloEvent =>
      'Для первой встречи подойдёт событие, которое нравится вам обоим.';

  @override
  String get todayFirstHelloDrinks =>
      'Для первой встречи подойдёт бокал чего-нибудь вдвоём.';

  @override
  String get todayFirstHelloOther =>
      'Для первой встречи подойдёт то, что нравится вам обоим.';

  @override
  String get todaySectionTalk => 'ЕСТЬ О ЧЁМ ПОГОВОРИТЬ';

  @override
  String get todayTalkCaption =>
      'Истории, клубы и подсказки, с которыми проще начать знакомство.';

  @override
  String get todayBlogTitle => 'Блог · Открытые главы';

  @override
  String get todayBlogSubtitle => 'Читай истории участников и пиши свои.';

  @override
  String get todayBookClubsTitle => 'Книжные клубы';

  @override
  String get todayBookClubsSubtitle =>
      'Одна книга в неделю — и обсуждение вместе.';

  @override
  String get todayFilmClubsTitle => 'Киноклубы';

  @override
  String get todayFilmClubsSubtitle =>
      'Посмотри выбранный фильм и поделись впечатлениями.';

  @override
  String get todayPhotoThemesTitle => 'Фототемы';

  @override
  String get todayPhotoThemesSubtitle => 'Одно фото на тему. Смотри фото всех.';

  @override
  String get todayChapterStudioTitle => 'Студия «Первая глава»';

  @override
  String get todayChapterStudioSubtitle => 'Начните историю вместе.';

  @override
  String get todayCoverFallbackLine => 'Фото, которое полюбилось участникам';

  @override
  String todayCoverSemantics(String name) {
    return 'Открыть обложку недели, автор: $name';
  }

  @override
  String get todayCoverTitle => 'ОБЛОЖКА НЕДЕЛИ';

  @override
  String todayCoverBy(String name) {
    return 'АВТОР: $name';
  }

  @override
  String get todayLikes => 'Отметки «Нравится»';

  @override
  String get todayComments => 'Комментарии';

  @override
  String get todayThisWeek => 'На этой неделе';

  @override
  String get todayWallLabel => 'ОТ СООБЩЕСТВА';

  @override
  String get todayWallTitle => 'Стена дня';

  @override
  String get todayWallCaption =>
      'Истории и фото, которые полюбились участникам, — новая подборка каждый день';

  @override
  String get todayWallPrevious => 'Предыдущая подборка';

  @override
  String get todayWallNext => 'Следующая подборка';

  @override
  String get todayWallChapter => 'ГЛАВА';

  @override
  String get todayWallUntitled => 'Глава без названия';

  @override
  String todayWallBy(String name) {
    return 'автор: $name';
  }

  @override
  String get todayWallEmpty =>
      'Твоя стена заполнится, когда участники начнут делиться любимыми историями и фото';

  @override
  String get todayWallWrite => 'Написать главу';

  @override
  String get todayWallShare => 'Поделиться фото';

  @override
  String get profileSetupBackTooltip => 'Назад';

  @override
  String profileSetupStepCounter(int current, int total) {
    return 'Шаг $current из $total';
  }

  @override
  String get profileSetupLoadErrorTitle =>
      'Не удалось загрузить данные профиля.';

  @override
  String get profileSetupRetry => 'Повторить';

  @override
  String get profileSetupEducationHighSchool => 'Среднее образование';

  @override
  String get profileSetupEducationBachelors => 'Бакалавриат';

  @override
  String get profileSetupEducationMasters => 'Магистратура';

  @override
  String get profileSetupEducationPhd => 'Аспирантура / PhD';

  @override
  String get profileSetupEducationOther => 'Другое';

  @override
  String get profileSetupPreferNotToSay => 'Предпочитаю не указывать';

  @override
  String profileSetupIncomeBelow(String amount) {
    return 'Меньше $amount';
  }

  @override
  String get profileSetupFrequencyNever => 'Никогда';

  @override
  String get profileSetupFrequencySocially => 'В компании';

  @override
  String get profileSetupFrequencyOccasionally => 'Иногда';

  @override
  String get profileSetupFrequencyRegularly => 'Регулярно';

  @override
  String get profileSetupGenderMan => 'Мужчина';

  @override
  String get profileSetupGenderWoman => 'Женщина';

  @override
  String get profileSetupGenderOther => 'Другое';

  @override
  String profileSetupBioTooShort(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Раздел «О себе» должен содержать не менее $min символа.',
      many: 'Раздел «О себе» должен содержать не менее $min символов.',
      few: 'Раздел «О себе» должен содержать не менее $min символов.',
      one: 'Раздел «О себе» должен содержать не менее $min символа.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupSaveFailed =>
      'Не удалось сохранить — попробуй ещё раз.';

  @override
  String get profileSetupCouldNotSaveChanges =>
      'Не удалось сохранить изменения. Попробуй ещё раз.';

  @override
  String get profileSetupAboutTitle => 'Сделай профиль ярче';

  @override
  String get profileSetupAboutSubtitle =>
      'Эти данные помогают находить более подходящие пары.';

  @override
  String get profileSetupBioLabel => 'О себе';

  @override
  String profileSetupBioHint(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Расскажи о себе (минимум $min символа)',
      many: 'Расскажи о себе (минимум $min символов)',
      few: 'Расскажи о себе (минимум $min символа)',
      one: 'Расскажи о себе (минимум $min символ)',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupHeightLabel => 'Рост (см)';

  @override
  String get profileSetupHeightHint => 'Выбери рост';

  @override
  String profileSetupHeightValue(int cm) {
    return '$cm см';
  }

  @override
  String get profileSetupEducationLabel => 'Образование';

  @override
  String get profileSetupEducationHint => 'Выбери образование';

  @override
  String get profileSetupProfessionLabel => 'Профессия';

  @override
  String get profileSetupProfessionHint => 'например, инженер-программист';

  @override
  String get profileSetupIncomeLabel => 'Доход (необязательно)';

  @override
  String get profileSetupLifestyleTitle => 'Образ жизни';

  @override
  String get profileSetupDrinkingLabel => 'Алкоголь';

  @override
  String get profileSetupSmokingLabel => 'Курение';

  @override
  String get profileSetupSelectHint => 'Выбрать';

  @override
  String get profileSetupReligionOptionalLabel => 'Религия (необязательно)';

  @override
  String get profileSetupContinue => 'Продолжить';

  @override
  String get profileSetupSaveAbout => 'Сохранить «О себе»';

  @override
  String get profileSetupPhotosSaved => 'Фото сохранены.';

  @override
  String profileSetupPhotosMaxReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Можно загрузить не больше $max фото.',
      many: 'Можно загрузить не больше $max фото.',
      few: 'Можно загрузить не больше $max фото.',
      one: 'Можно загрузить не больше $max фото.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupRemovePhotoTitle => 'Удалить это фото?';

  @override
  String get profileSetupRemovePhotoBody =>
      'Фото исчезнет из профиля и будет удалено из хранилища.';

  @override
  String get profileSetupCancel => 'Отмена';

  @override
  String get profileSetupRemove => 'Удалить';

  @override
  String profileSetupPhotosMinRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Загрузи хотя бы $min фото, чтобы продолжить.',
      many: 'Загрузи хотя бы $min фото, чтобы продолжить.',
      few: 'Загрузи хотя бы $min фото, чтобы продолжить.',
      one: 'Загрузи хотя бы $min фото, чтобы продолжить.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTitle => 'Добавь свои фото';

  @override
  String profileSetupPhotosSubtitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Добавь хотя бы $min фото, чтобы получать пары',
      many: 'Добавь хотя бы $min фото, чтобы получать пары',
      few: 'Добавь хотя бы $min фото, чтобы получать пары',
      one: 'Добавь хотя бы $min фото, чтобы получать пары',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupChooseSource => 'Выбери источник';

  @override
  String get profileSetupGallery => 'Галерея';

  @override
  String get profileSetupCamera => 'Камера';

  @override
  String get profileSetupPhotoRequirements =>
      'JPEG, PNG, WebP или HEIC · не меньше 300×300 · до 10 МБ каждое · всего до 50 МБ';

  @override
  String profileSetupPhotosTipEmpty(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Добавь хотя бы $min фото, чтобы показать себя с разных сторон.',
      many: 'Добавь хотя бы $min фото, чтобы показать себя с разных сторон.',
      few: 'Добавь хотя бы $min фото, чтобы показать себя с разных сторон.',
      one: 'Добавь хотя бы $min фото, чтобы показать себя с разных сторон.',
    );
    return '$_temp0';
  }

  @override
  String profileSetupPhotosTipMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Добавь ещё $count фото, чтобы открыть полный подбор пар.',
      many: 'Добавь ещё $count фото, чтобы открыть полный подбор пар.',
      few: 'Добавь ещё $count фото, чтобы открыть полный подбор пар.',
      one: 'Добавь ещё $count фото, чтобы открыть полный подбор пар.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTipDone =>
      'Отлично! Фото можно переставлять перетаскиванием.';

  @override
  String get profileSetupYourPhotosHeading =>
      'Твои фото  •  перетащи, чтобы изменить порядок';

  @override
  String get profileSetupContinueToAbout => 'Далее: «О себе»';

  @override
  String get profileSetupSavePhotos => 'Сохранить фото';

  @override
  String get profileSetupPrimaryPhoto => 'Главное фото';

  @override
  String profileSetupPhotoNumber(int number) {
    return 'Фото $number';
  }

  @override
  String get profileSetupShownFirst => 'Показывается первым в профиле';

  @override
  String get profileSetupDragHandleHint =>
      'Потяни за маркер, чтобы переставить';

  @override
  String get profileSetupAwaitingSafetyReview =>
      'Ожидает проверки безопасности';

  @override
  String get profileSetupSafetyCheckInProgress => 'Идёт проверка безопасности';

  @override
  String get profileSetupSetAsProfilePicture => 'Сделать фото профиля';

  @override
  String get profileSetupProfilePictureSelected => 'Выбрано фото профиля';

  @override
  String get profileSetupRemovePhotoTooltip => 'Удалить фото';

  @override
  String get profileSetupPhotoTooLarge => 'Это фото больше допустимых 10 МБ.';

  @override
  String get profileSetupPhotoUnsupportedType =>
      'Используй фото в формате JPEG, PNG, WebP или HEIC.';

  @override
  String get profileSetupPhotoBadDimensions =>
      'Размер фото должен быть от 300×300 до 4096×4096.';

  @override
  String get profileSetupPhotoQuotaReached => 'Лимит фото профиля исчерпан.';

  @override
  String get profileSetupPhotoStorageFull =>
      'Хранилище фото временно заполнено. Попробуй позже.';

  @override
  String get profileSetupPhotoUpdateFailed =>
      'Не удалось обновить фото. Попробуй ещё раз.';

  @override
  String profileSetupPhotoMaxAllowed(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Можно добавить не больше $max фото.',
      many: 'Можно добавить не больше $max фото.',
      few: 'Можно добавить не больше $max фото.',
      one: 'Можно добавить не больше $max фото.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPreferencesLoadFailed =>
      'Не удалось загрузить предпочтения';

  @override
  String get profileSetupOfflineBanner =>
      'Офлайн-режим — часть данных может быть устаревшей.';

  @override
  String get profileSetupYourPreferences => 'Твои предпочтения';

  @override
  String get profileSetupEditPreferencesTitle => 'Изменить предпочтения';

  @override
  String get profileSetupFinishAndFindMatches => 'Завершить и найти пары';

  @override
  String get profileSetupSavePreferences => 'Сохранить предпочтения';

  @override
  String get profileSetupSelectGenderPreference => 'Выбери хотя бы один пол.';

  @override
  String get profileSetupFinishFailed =>
      'Не удалось завершить настройку. Проверь фото и предпочтения и попробуй ещё раз.';

  @override
  String get profileSetupPreferencesSaveFailed =>
      'Некоторые предпочтения сейчас не удалось сохранить.';

  @override
  String get profileSetupPreferencesSaved => 'Предпочтения сохранены.';

  @override
  String get profileSetupTabBasic => 'Основное';

  @override
  String get profileSetupTabAdvanced => 'Дополнительно';

  @override
  String get profileSetupLookingFor => 'Я ищу';

  @override
  String get profileSetupSeekingMen => 'Мужчин';

  @override
  String get profileSetupSeekingWomen => 'Женщин';

  @override
  String get profileSetupSeekingOther => 'Других';

  @override
  String profileSetupAgeRangeTitle(int min, int max) {
    return 'Возраст: $min – $max';
  }

  @override
  String profileSetupMaxDistanceTitle(int km) {
    return 'Макс. расстояние: $km км';
  }

  @override
  String profileSetupDistanceValue(int km) {
    return '$km км';
  }

  @override
  String get profileSetupRelationshipIntent => 'Цель отношений';

  @override
  String get profileSetupSeriousOnly => 'Только серьёзные отношения';

  @override
  String get profileSetupSeriousOnlySubtitle =>
      'Показывать только тех, кто ищет серьёзных отношений';

  @override
  String get profileSetupVerifiedOnly => 'Только проверенные анкеты';

  @override
  String get profileSetupVerifiedOnlySubtitle =>
      'Только аккаунты с подтверждённым документом';

  @override
  String get profileSetupHookupsOnly => 'Только без обязательств';

  @override
  String get profileSetupHookupsOnlySubtitle =>
      'Показывать анкеты без обязательств';

  @override
  String get profileSetupLocation => 'Местоположение';

  @override
  String get profileSetupCountry => 'Страна';

  @override
  String get profileSetupStateRegion => 'Штат / регион';

  @override
  String get profileSetupCity => 'Город';

  @override
  String get profileSetupBackgroundCulture => 'Происхождение и культура';

  @override
  String get profileSetupReligionPreference => 'Религия';

  @override
  String get profileSetupMotherTongue => 'Родной язык';

  @override
  String get profileSetupLanguage => 'Язык';

  @override
  String get profileSetupDietPreference => 'Питание';

  @override
  String get profileSetupWorkoutFrequency => 'Как часто тренируешься';

  @override
  String get profileSetupDietType => 'Тип питания';

  @override
  String get profileSetupSleepSchedule => 'Режим сна';

  @override
  String get profileSetupTravelStyle => 'Стиль путешествий';

  @override
  String get profileSetupPoliticalComfortRange =>
      'Политические взгляды партнёра';

  @override
  String get profileSetupInterestsPersonality => 'Интересы и характер';

  @override
  String get profileSetupInstagramHandle => 'Ник в Instagram (без @)';

  @override
  String get profileSetupIntentTags =>
      'Цели (долгие отношения, брак, без обязательств…)';

  @override
  String get profileSetupHobbiesField => 'Хобби (через запятую)';

  @override
  String get profileSetupFavouriteBooksField => 'Любимые книги (через запятую)';

  @override
  String get profileSetupFavouriteNovelsField =>
      'Любимые романы (через запятую)';

  @override
  String get profileSetupFavouriteSongsField => 'Любимые песни (через запятую)';

  @override
  String get profileSetupExtraCurricularField =>
      'Внеучебные занятия (через запятую)';

  @override
  String get profileSetupAdditionalInformation => 'Дополнительная информация';

  @override
  String get profileSetupPetPreference => 'Домашние животные';

  @override
  String get profileSetupDealBreakers => 'Неприемлемо';

  @override
  String get profileSetupTagsField => 'Теги (через запятую)';

  @override
  String get profileSetupNameRequired => 'Укажи имя.';

  @override
  String get profileSetupDobRequired => 'Укажи дату рождения.';

  @override
  String profileSetupPhotosRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Нужно хотя бы $min фото.',
      many: 'Нужно хотя бы $min фото.',
      few: 'Нужно хотя бы $min фото.',
      one: 'Нужно хотя бы $min фото.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupServerError => 'Ошибка сервера';

  @override
  String get profileSetupNetworkError => 'Ошибка сети — попробуй ещё раз.';

  @override
  String get profileSetupGenericError =>
      'Что-то пошло не так. Попробуй ещё раз.';

  @override
  String get profileSetupPreviewTitle => 'Предпросмотр профиля';

  @override
  String get profileSetupPreviewSubtitle => 'Так тебя увидят другие.';

  @override
  String profileSetupNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String profileSetupDrinksChip(String value) {
    return 'Алкоголь: $value';
  }

  @override
  String profileSetupSmokesChip(String value) {
    return 'Курение: $value';
  }

  @override
  String get profileSetupCompleteProfile => 'Завершить профиль';

  @override
  String profileSetupCompletionPercent(int percent) {
    return 'Профиль заполнен на $percent%';
  }

  @override
  String get profileEditTitle => 'Редактировать профиль';

  @override
  String get profileEditRefreshTooltip => 'Обновить профиль';

  @override
  String get profileEditAboutYou => 'О тебе';

  @override
  String get profileEditEditAbout => 'Изменить «О себе»';

  @override
  String get profileEditName => 'Имя';

  @override
  String get profileEditPhone => 'Телефон';

  @override
  String get profileEditDateOfBirth => 'Дата рождения';

  @override
  String get profileEditGender => 'Пол';

  @override
  String get profileEditHeight => 'Рост';

  @override
  String get profileEditIncomeRange => 'Уровень дохода';

  @override
  String get profileEditLocationSocial => 'Местоположение и соцсети';

  @override
  String get profileEditEditPreferences => 'Изменить предпочтения';

  @override
  String get profileEditState => 'Регион';

  @override
  String get profileEditInstagram => 'Instagram';

  @override
  String get profileEditDatingPreferences => 'Предпочтения в знакомствах';

  @override
  String get profileEditSeeking => 'Ищу';

  @override
  String get profileEditAgeRange => 'Возраст';

  @override
  String profileEditAgeRangeValue(int min, int max) {
    return '$min–$max';
  }

  @override
  String get profileEditMaxDistance => 'Макс. расстояние';

  @override
  String get profileEditEducationFilter => 'Фильтр по образованию';

  @override
  String get profileEditSeriousOnly => 'Только серьёзные';

  @override
  String get profileEditVerifiedOnly => 'Только проверенные';

  @override
  String get profileEditHookupOnly => 'Без обязательств';

  @override
  String get profileEditYes => 'Да';

  @override
  String get profileEditNo => 'Нет';

  @override
  String get profileEditIntent => 'Цель';

  @override
  String get profileEditLanguages => 'Языки';

  @override
  String get profileEditDealBreakers => 'Неприемлемо';

  @override
  String get profileEditReligion => 'Религия';

  @override
  String get profileEditPets => 'Животные';

  @override
  String get profileEditWorkout => 'Спорт';

  @override
  String get profileEditPoliticsComfort => 'Политика';

  @override
  String get profileEditInterestsDetails => 'Интересы и подробности';

  @override
  String get profileEditHobbies => 'Хобби';

  @override
  String get profileEditBooks => 'Книги';

  @override
  String get profileEditNovels => 'Романы';

  @override
  String get profileEditSongs => 'Песни';

  @override
  String get profileEditExtraCurriculars => 'Внеучебные занятия';

  @override
  String get profileEditAdditionalInfo => 'Дополнительно';

  @override
  String get profileEditNotSet => 'Не указано';

  @override
  String get profileEditLoadingTitle => 'Загружаем сохранённый профиль';

  @override
  String get profileEditLoadingBody =>
      'Подставляем данные, сохранённые при создании аккаунта.';

  @override
  String get profileEditYourProfile => 'Твой профиль';

  @override
  String profileEditPercentComplete(int percent) {
    return 'Заполнено на $percent%';
  }

  @override
  String get profileEditPhotoGallery => 'Фотогалерея';

  @override
  String get profileEditManagePhotos => 'Управлять фото';

  @override
  String get profileEditNoPhotos => 'Фото пока не загружены.';

  @override
  String get profileEditPrimaryBadge => 'Главное';

  @override
  String get engagementHubPromptLoading => 'Загружаем вопрос дня';

  @override
  String get engagementHubPromptIntro =>
      'Отвечай на один вопрос в день и наращивай серию.';

  @override
  String engagementHubPromptRepliedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count человека ответили сегодня',
      many: '$count человек ответили сегодня',
      few: '$count человека ответили сегодня',
      one: '$count человек ответил сегодня',
    );
    return '$_temp0';
  }

  @override
  String engagementHubPromptStreakSummary(int days, int similar) {
    return 'Серия $days дн. · похожих ответов: $similar';
  }

  @override
  String get engagementHubBlogTitle => 'Блог · Open Chapters';

  @override
  String get engagementHubBlogSubtitle =>
      'Читай истории, делись фото и пиши свои.';

  @override
  String get engagementHubPhotoThemesTitle => 'Фототемы';

  @override
  String get engagementHubPhotoThemesSubtitle =>
      'Делись одним фото на тему и смотри снимки других.';

  @override
  String get engagementHubClubsTitle => 'Книжные и киноклубы';

  @override
  String get engagementHubClubsSubtitle =>
      'Следи за выбором недели, обсуждай и оценивай.';

  @override
  String get engagementHubCityPilotTitle => 'Городской пилот';

  @override
  String get engagementHubCityPilotSubtitle =>
      'Небольшое сообщество. Разговоры, которые становятся планами.';

  @override
  String get engagementDailyPromptTitle => 'Серия вопросов дня';

  @override
  String get engagementHubVoiceTitle => 'Голосовые знакомства с подсказками';

  @override
  String get engagementHubVoiceSubtitle =>
      'Одно голосовое приветствие на 20–45 с на пару в день';

  @override
  String get engagementCirclesTitle => 'Челленджи местных кругов';

  @override
  String get engagementHubCirclesSubtitle =>
      'Вступи в круг своего города и отправь ответ на этой неделе';

  @override
  String get engagementHubCoffeeTitle => 'Опрос о кофе для группы';

  @override
  String get engagementHubCoffeeSubtitle =>
      'Создавай простые опросы о встречах, голосуй и подводи итог';

  @override
  String get engagementHubGroupsTitle => 'Группы';

  @override
  String get engagementHubGroupsSubtitle =>
      'Сообщества по интересам и закрытые группы друзей';

  @override
  String get engagementHubRoomsSubtitle =>
      'Живые чат-комнаты: заходи, общайся, находи друзей';

  @override
  String get engagementHubFriendsTitle => 'Друзья и знакомства';

  @override
  String get engagementHubFriendsSubtitle =>
      'Пригласи надёжного друга, даже если он не ищет пару';

  @override
  String get engagementLevelTitle => 'Уровень и XP';

  @override
  String get engagementHubLevelSubtitle =>
      'Следи за полезной активностью, наградами уровней и порогами доверия';

  @override
  String get engagementHubPaywallFree =>
      'Основной прогресс остаётся бесплатным.';

  @override
  String get engagementHubPolicyUpdating => 'Политика монетизации обновляется.';

  @override
  String engagementHubPremiumAreas(String features) {
    return 'Дополнительные премиум-разделы: $features';
  }

  @override
  String get engagementHubEyebrow => 'АКТИВНОСТЬ';

  @override
  String get engagementHubTitle => 'Создавайте что-то вместе.';

  @override
  String get engagementHubSubtitle =>
      'Крепкие пары благодаря доверию и общим занятиям.';

  @override
  String get engagementHubSectionCreate => 'СОЗДАВАЙ И ДЕЛИСЬ';

  @override
  String get engagementHubSectionCreateCaption =>
      'Истории, фото и клубы, с которых начинаются настоящие разговоры.';

  @override
  String get engagementHubSectionMeet => 'ЗНАКОМСТВА';

  @override
  String get engagementHubSectionMeetCaption =>
      'Небольшие группы, вопросы и планы в твоём темпе.';

  @override
  String get engagementHubSectionProgress => 'ДОВЕРИЕ И ПРОГРЕСС';

  @override
  String get engagementHubSectionProgressCaption =>
      'Твой уровень, твои значки и кто может тебя найти.';

  @override
  String get engagementVoiceAppBarTitle => 'Голос — чуть ближе';

  @override
  String get engagementVoiceHeadline => 'Пусть твоё «привет»\nзвучит как ты.';

  @override
  String get engagementVoiceIntro =>
      'Необязательное представление на 20–45 секунд, которое видно только в этом разговоре. Текст тоже всегда подойдёт.';

  @override
  String engagementVoiceYouAndName(String name) {
    return 'Ты и $name';
  }

  @override
  String get engagementVoiceYouAndYourMatch => 'Ты и твоя пара';

  @override
  String get engagementVoicePrivate => 'Видно только в этом разговоре';

  @override
  String get engagementVoiceConversationsLoadFailed =>
      'Не удалось загрузить твои разговоры.';

  @override
  String get engagementVoiceNoMatches =>
      'Когда у тебя появится пара, здесь можно будет поделиться голосовым представлением. Не спеши.';

  @override
  String get engagementVoicePickConversation => 'С кем хочешь поздороваться?';

  @override
  String get engagementVoiceStartingPoint => 'Небольшая подсказка для начала';

  @override
  String get engagementVoiceChoosePrompt => 'Выбери подсказку';

  @override
  String get engagementVoiceTranscriptLabel => 'Твои слова — текстом';

  @override
  String get engagementVoiceTranscriptHelper =>
      'Напиши то, что говоришь, чтобы это можно было и прочитать. Это не автоматическая расшифровка.';

  @override
  String engagementVoiceStop(int seconds) {
    return 'Стоп · $seconds с';
  }

  @override
  String get engagementVoiceRecord => 'Записать приветствие';

  @override
  String engagementVoiceRecordAgain(int seconds) {
    return 'Записать заново · $seconds с';
  }

  @override
  String get engagementVoiceRecordingReady =>
      'Запись готова. Проверь текст перед отправкой.';

  @override
  String get engagementVoiceRecordingShort =>
      'Получилось коротковато. Запиши 20–45 секунд.';

  @override
  String get engagementVoiceDiscard => 'Удалить запись';

  @override
  String get engagementVoiceSubmitted =>
      'Представление отправлено. Одобренные записи появятся ниже.';

  @override
  String get engagementVoiceSending => 'Отправляем…';

  @override
  String get engagementVoiceShare => 'Отправить приветствие';

  @override
  String get engagementVoiceCheckedNote =>
      'Записи проверяются перед публикацией. Автовоспроизведения нет.';

  @override
  String get engagementVoiceYourIntros => 'Твои голосовые представления';

  @override
  String get engagementVoiceLatestNote =>
      'Последние 20 одобренных записей в этом разговоре. Текст всегда можно прочитать.';

  @override
  String get engagementVoiceIntrosLoadFailed =>
      'Не удалось загрузить представления. Возможно, разговор больше недоступен.';

  @override
  String get engagementVoiceNothingYet =>
      'Пока ничего нет. Простое «привет» — хорошее начало.';

  @override
  String get engagementVoiceYourHello => 'Твоё приветствие';

  @override
  String engagementVoiceHelloFromName(String name) {
    return 'Приветствие от $name';
  }

  @override
  String get engagementVoiceHelloFromYourMatch => 'Приветствие от твоей пары';

  @override
  String get engagementVoiceTranscriptHeading => 'ТЕКСТ';

  @override
  String get engagementVoiceStopPlayback => 'Остановить';

  @override
  String engagementVoiceListen(int seconds) {
    return 'Слушать · $seconds с';
  }

  @override
  String get engagementVoiceReloadPrompts => 'Обновить подсказки';

  @override
  String get engagementVoiceMicPermission =>
      'Разреши доступ к микрофону, чтобы записывать. Читать тексты можно и без него.';

  @override
  String get engagementVoiceStartFailed =>
      'Не удалось начать запись. Проверь доступ к микрофону и попробуй ещё раз.';

  @override
  String get engagementVoiceSaveFailed =>
      'Не удалось сохранить запись. Попробуй ещё раз.';

  @override
  String get engagementVoicePromptsLoadFailed =>
      'Сейчас не удаётся загрузить подсказки.';

  @override
  String get engagementSessionUnavailable => 'Сеанс недоступен.';

  @override
  String get engagementVoiceChooseConversation => 'Сначала выбери разговор.';

  @override
  String get engagementVoiceSelectPrompt => 'Выбери подсказку для записи.';

  @override
  String get engagementVoiceEnterTranscript => 'Введи текст.';

  @override
  String get engagementVoiceSessionFailed =>
      'Не удалось начать голосовое знакомство.';

  @override
  String get engagementVoiceSendFailed =>
      'Сейчас не удаётся отправить голосовое приветствие.';

  @override
  String get engagementVoicePlaybackUserRequired =>
      'Для отметки прослушивания нужен ID пользователя.';

  @override
  String get engagementVoiceMarkPlaybackFailed =>
      'Сейчас не удаётся отметить прослушивание.';

  @override
  String get engagementVoicePlayFailed =>
      'Сейчас не удаётся воспроизвести эту запись.';

  @override
  String get chatStarterSmile => 'Что тебя сегодня порадовало?';

  @override
  String get chatStarterSunday => 'Твоё идеальное воскресенье — рассказывай.';

  @override
  String get chatStarterCoffee => 'Кофе, прогулка или маленькое приключение?';

  @override
  String get chatWelcomeTitle =>
      'Каждая хорошая история\nначинается с «привет».';

  @override
  String get chatWelcomePending => 'Диалог откроется, когда мэтч подтвердится.';

  @override
  String get chatWelcomeBody =>
      'Идеальная первая фраза не нужна. Просто будь собой.';

  @override
  String get chatInspirationEyebrow => 'НЕМНОГО ВДОХНОВЕНИЯ';

  @override
  String get chatAllConversations => 'Все диалоги';

  @override
  String get chatMakeConnectionEyebrow => 'НАЙДИ КОНТАКТ';

  @override
  String get chatLessSmallTalk => 'Чуть меньше пустой болтовни.';

  @override
  String get chatLessSmallTalkBody =>
      'Спроси о том, что зажигает собеседника. Поделись чем-то по-настоящему своим.';

  @override
  String get chatFindTheWords => 'Подобрать слова';

  @override
  String get chatSendJoy => 'Подарить немного радости';

  @override
  String get chatPaceTitle => 'Твой темп. Твои границы.';

  @override
  String get chatPaceBody =>
      'Делись только тем, чем тебе комфортно. Хорошая связь уважает твои границы.';

  @override
  String get chatWriteMessageHint => 'Напиши сообщение…';

  @override
  String get chatConversationPaused => 'Диалог приостановлен';

  @override
  String get chatSendingMessageTooltip => 'Отправка сообщения';

  @override
  String get chatSendMessageTooltip => 'Отправить сообщение';

  @override
  String get chatSendGiftTooltip => 'Отправить подарок';

  @override
  String get chatAddEmojiTooltip => 'Добавить эмодзи';

  @override
  String get chatDraftedWithHelp => 'Написано с помощью';

  @override
  String get chatHelpMeSayIt => 'Помоги сформулировать';

  @override
  String get chatEnterToSendHint =>
      'Enter — отправить · Shift + Enter — новая строка';

  @override
  String get chatToday => 'Сегодня';

  @override
  String get chatYesterday => 'Вчера';

  @override
  String get chatGiftOptions => 'Действия с подарком';

  @override
  String get chatStatusRead => 'Прочитано';

  @override
  String get chatStatusDelivered => 'Доставлено';

  @override
  String get chatStatusSent => 'Отправлено';

  @override
  String get chatGestureGiftHeading => 'Жест + роза в подарок';

  @override
  String get chatGiftForYouHeading => 'Небольшой подарок для тебя';

  @override
  String chatGiftTone(String tone) {
    return 'Тон: $tone';
  }

  @override
  String get chatFreeGift => 'Бесплатный подарок';

  @override
  String get chatCopilotKindOpener => 'Первое сообщение';

  @override
  String get chatCopilotKindReply => 'Ответ';

  @override
  String get chatCopilotKindDateIdea => 'Идея свидания';

  @override
  String get chatCopilotToneWarm => 'Тёплый';

  @override
  String get chatCopilotTonePlayful => 'Игривый';

  @override
  String get chatCopilotToneDirect => 'Прямой';

  @override
  String chatCopilotIntro(String name) {
    return 'Черновик в твоём стиле на основе профиля $name и вашего диалога. Он никогда не отправляется за тебя, а если отправишь его без изменений, собеседник увидит, что он написан с помощью.';
  }

  @override
  String chatCopilotDisclosure(String disclosure, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сегодня осталось $count черновика.',
      many: 'Сегодня осталось $count черновиков.',
      few: 'Сегодня осталось $count черновика.',
      one: 'Сегодня остался $count черновик.',
    );
    return '$disclosure $_temp0';
  }

  @override
  String get chatCopilotDraftIt => 'Составить';

  @override
  String get chatCopilotTryAnother => 'Другой вариант';

  @override
  String get chatCopilotUseAndEdit => 'Взять и отредактировать';

  @override
  String get chatCopilotEmpty => 'Помощник ничего не предложил.';

  @override
  String get chatCopilotUnavailable => 'Помощник недоступен.';

  @override
  String get chatErrorMatchEnded => 'Этот мэтч завершён.';

  @override
  String get chatErrorLoadMessages =>
      'Не удалось загрузить сообщения. Попробуй ещё раз.';

  @override
  String get chatErrorLockedQuest =>
      'Чат заблокирован, пока задание не одобрят.';

  @override
  String get chatErrorSendFailed => 'Не удалось отправить сообщение.';

  @override
  String get chatErrorDeleteFailed => 'Не удалось удалить сообщение.';

  @override
  String get chatErrorDeleteWindowExpired =>
      'Время на удаление истекло (24 ч).';

  @override
  String get chatErrorOnlyReceivedGifts =>
      'Управлять можно только полученными подарками.';

  @override
  String get chatErrorGiftGone => 'Этот подарок больше недоступен.';

  @override
  String get chatErrorGiftReportFailed =>
      'Не удалось пожаловаться на подарок. Попробуй ещё раз.';

  @override
  String get chatErrorGiftHideFailed =>
      'Не удалось скрыть подарок. Попробуй ещё раз.';

  @override
  String get chatErrorGiftsUnavailable => 'Подарки-розы сейчас недоступны.';

  @override
  String chatErrorNotEnoughCoins(String gift) {
    return 'Недостаточно монет, чтобы отправить «$gift».';
  }

  @override
  String get chatErrorNotEnoughCoinsSelected =>
      'Недостаточно монет для выбранного подарка.';

  @override
  String get chatErrorWalletFrozen =>
      'Твои монеты заморожены, пока мы проверяем возвращённую покупку. Бесплатные подарки по-прежнему доступны.';

  @override
  String get chatErrorGiftVelocity =>
      'За короткое время отправлено много подарков. Попробуй позже.';

  @override
  String get chatErrorFreeGiftUsed =>
      'Бесплатный подарок на сегодня уже отправлен. Новый будет доступен после полуночи UTC.';

  @override
  String chatErrorGiftNotAvailable(String gift) {
    return '«$gift» сейчас недоступен.';
  }

  @override
  String get chatErrorGiftNeedsActiveMatch =>
      'Подарки можно отправлять только в активном мэтче.';

  @override
  String get chatErrorExclusiveGiftOnce =>
      'Этот эксклюзивный подарок можно отправить только раз в день.';

  @override
  String get chatErrorGiftFailed => 'Не удалось отправить подарок.';

  @override
  String get chatErrorSessionUnavailable => 'Сеанс пользователя недоступен.';

  @override
  String get chatErrorConversationUnavailable => 'Диалог недоступен.';

  @override
  String get verificationLandingTitle => 'Пройди проверку уверенно';

  @override
  String get verificationLandingBody =>
      'Загрузи чёткое фото официального удостоверения личности и недавнее селфи. Файлы передаются в зашифрованном виде и хранятся в закрытом хранилище подтверждений.';

  @override
  String get verificationLandingDisclaimer =>
      'Отметка о проверке добавляет контекст к профилю. Она никогда не гарантирует личность, намерения или безопасность другого человека.';

  @override
  String get verificationViewVerifiedStatus => 'Посмотреть статус проверки';

  @override
  String get verificationViewReviewStatus => 'Посмотреть статус проверки';

  @override
  String get verificationStartButton => 'Начать защищённую проверку';

  @override
  String get verificationUploadIdTitle => 'Загрузить документ';

  @override
  String get verificationUploadIdInstruction =>
      'Сфотографируй или загрузи чёткое фото официального удостоверения личности.';

  @override
  String get verificationGallery => 'Галерея';

  @override
  String get verificationCamera => 'Камера';

  @override
  String get verificationNext => 'Далее';

  @override
  String get verificationSelfieTitle => 'Селфи';

  @override
  String get verificationSelfieInstruction => 'Сделай чёткое селфи.';

  @override
  String get verificationUploadFailed =>
      'Не удалось загрузить файлы. Проверь их и попробуй ещё раз.';

  @override
  String get verificationSubmit => 'Отправить';

  @override
  String get verificationStatusTitle => 'Статус проверки';

  @override
  String get verificationRetry => 'Повторить';

  @override
  String get verificationStatusVerified => 'Проверено';

  @override
  String get verificationStatusVerifiedMessage => 'Проверка завершена.';

  @override
  String get verificationStatusRejected => 'Отклонено';

  @override
  String get verificationStatusRejectedFallback => 'Попробуй ещё раз.';

  @override
  String get verificationStatusPending => 'На проверке';

  @override
  String get verificationStatusPendingMessage => 'Идёт проверка.';

  @override
  String get verificationStatusNotStarted => 'Не начата';

  @override
  String get verificationStatusNotStartedMessage =>
      'Начни проверку в настройках.';

  @override
  String get safetySosTitle => 'Экстренный SOS';

  @override
  String get safetySosDefaultMessage =>
      'Мне нужна срочная помощь. Пожалуйста, проверьте, всё ли со мной в порядке.';

  @override
  String get safetySosHeadline => 'Включить экстренное оповещение';

  @override
  String get safetySosIntro =>
      'Если тебе угрожает непосредственная опасность, сначала обратись в местные экстренные службы. Это оповещение будет передано команде безопасности.';

  @override
  String get safetySosLevelUrgent => 'Срочно';

  @override
  String get safetySosLevelCritical => 'Критично';

  @override
  String get safetySosMessageLabel => 'Сообщение для команды безопасности';

  @override
  String get safetySosActivating => 'Включаем…';

  @override
  String get safetySosActivate => 'Включить SOS';

  @override
  String get safetySosLocationNote =>
      'Местоположение запрашивается только для этого оповещения. Можно продолжить и без разрешения.';

  @override
  String get safetySosHistoryTitle => 'История оповещений';

  @override
  String get safetySosHistoryEmpty => 'SOS-оповещений нет.';

  @override
  String safetySosHistoryHeading(String level, String status) {
    return '$level · $status';
  }

  @override
  String get safetySosAlertLevelLow => 'НИЗКИЙ';

  @override
  String get safetySosAlertLevelMedium => 'СРЕДНИЙ';

  @override
  String get safetySosAlertLevelHigh => 'ВЫСОКИЙ';

  @override
  String get safetySosAlertLevelCritical => 'КРИТИЧЕСКИЙ';

  @override
  String get safetySosAlertStatusOpen => 'открыто';

  @override
  String get safetySosAlertStatusActive => 'активно';

  @override
  String get safetySosAlertStatusAcknowledged => 'принято';

  @override
  String get safetySosAlertStatusResolved => 'решено';

  @override
  String safetySosHistoryMetaWithLocation(String date) {
    return '$date · с местоположением';
  }

  @override
  String safetySosHistoryMetaNoLocation(String date) {
    return '$date · без местоположения';
  }

  @override
  String safetySosResolution(String note) {
    return 'Решение: $note';
  }

  @override
  String get safetySosConfirmTitle => 'Включить SOS сейчас?';

  @override
  String get safetySosConfirmBody =>
      'Будет создано экстренное оповещение для команды безопасности, и мы попробуем приложить твоё текущее местоположение.';

  @override
  String get safetySosCancel => 'Отмена';

  @override
  String get safetySosConfirmActivate => 'Включить';

  @override
  String get safetySosActivatedTitle => 'SOS-оповещение отправлено';

  @override
  String get safetySosActivatedWithLocation =>
      'Оповещение и твоё текущее местоположение записаны.';

  @override
  String get safetySosActivatedWithoutLocation =>
      'Оповещение записано без местоположения: разрешение на геолокацию недоступно или отклонено.';

  @override
  String get safetySosDone => 'Готово';

  @override
  String get safetySosSignInToView => 'Войди, чтобы увидеть историю SOS.';

  @override
  String get safetySosLoadFailed => 'Не удалось загрузить историю SOS.';

  @override
  String get safetySosSignInToActivate => 'Войди, прежде чем включать SOS.';

  @override
  String get safetySosActivateFailed => 'Не удалось включить SOS.';

  @override
  String get photoThemesTitle => 'Фототемы';

  @override
  String get photoThemesSignIn => 'Войди, чтобы увидеть фототемы.';

  @override
  String get photoThemesHeroTitle => 'Покажи немного своего мира';

  @override
  String get photoThemesHeroSubtitle =>
      'Выбери тему, поделись одним фото и посмотри, что ответили другие. Это простой способ начать разговор.';

  @override
  String get photoThemesLoadFailed => 'Не удалось загрузить темы';

  @override
  String get photoThemesCheckConnection => 'Проверь подключение к интернету.';

  @override
  String get photoThemesLookAround => 'Можно осмотреться';

  @override
  String get photoThemesEligibilityShareOwn =>
      'Заполни профиль и добавь две одобренные фотографии, чтобы делиться своими.';

  @override
  String get photoThemesNewPromptsTitle => 'Новые темы уже на подходе';

  @override
  String get photoThemesNewPromptsBody =>
      'Загляни чуть позже — появится, чем поделиться.';

  @override
  String photoThemesSharedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count публикации',
      many: '$count публикаций',
      few: '$count публикации',
      one: '$count публикация',
    );
    return '$_temp0';
  }

  @override
  String get photoThemesYouShared => 'Фото опубликовано ✓';

  @override
  String get photoThemesBeFirst => 'Поделись первым →';

  @override
  String get photoThemesSeeEveryone => 'Смотреть все фото →';

  @override
  String get photoThemesSharedSnack => 'Фото опубликовано. Отлично!';

  @override
  String get photoThemesShareFailed =>
      'Не удалось опубликовать фото. Используй JPEG или PNG размером до 10 МБ.';

  @override
  String get photoThemesEligibilityShare =>
      'Заполни профиль и добавь две одобренные фотографии, чтобы делиться.';

  @override
  String get photoThemesAlreadyShared =>
      'Твоё фото в этой теме уже опубликовано. Удали его, чтобы опубликовать новое.';

  @override
  String get photoThemesThemeFallback => 'Фототема';

  @override
  String get photoThemesShareTooltip => 'Поделиться фото на эту тему';

  @override
  String get photoThemesShareYourPhoto => 'Поделиться фото';

  @override
  String get photoThemesNoPhotosYet => 'Пока нет фото';

  @override
  String photoThemesBeFirstFor(String title) {
    return 'Поделись первым в теме «$title»';
  }

  @override
  String get photoThemesLoadingPrompt => 'Загружаем тему…';

  @override
  String get photoThemesPhotosLoadFailed => 'Не удалось загрузить фото';

  @override
  String get photoThemesEmptyMessage =>
      'Возможно, именно твоё фото всех разговорит.';

  @override
  String get photoThemesMoreFailed =>
      'Не удалось загрузить остальные фото. Обновить';

  @override
  String get photoThemesLoadMore => 'Загрузить ещё';

  @override
  String get photoThemesPhotoUnavailable => 'Фото недоступно. Повторить';

  @override
  String photoThemesOpenPhoto(String name) {
    return 'Открыть фото: $name';
  }

  @override
  String get photoThemesYou => 'Ты';

  @override
  String get photoThemesWallHelp =>
      'Если фото понравится участникам, оно может попасть на их стены Today: 50 лайков и 5 комментариев — на 50 стен, 100 лайков и 10 комментариев — на 100. Это можно отключить в любой момент.';

  @override
  String get photoThemesRemoveTitle => 'Удалить фото?';

  @override
  String get photoThemesRemoveMessage =>
      'Оно исчезнет из этой темы для всех. Потом можно будет опубликовать новое.';

  @override
  String get photoThemesRemoveAction => 'Удалить фото';

  @override
  String get photoThemesRemoveFailed => 'Не удалось удалить фото.';

  @override
  String get photoThemesReachOn =>
      'Теперь фото может попадать на стены участников, если оно им понравится.';

  @override
  String get photoThemesReachOff => 'Фото убрано со всех стен.';

  @override
  String get photoThemesSharedByYou => 'Опубликовано тобой';

  @override
  String photoThemesSharedBy(String name) {
    return 'Автор: $name';
  }

  @override
  String photoThemesPhotoDescription(String text) {
    return 'Описание фото: $text';
  }

  @override
  String get photoThemesReachSwitch =>
      'Разрешить показ на стенах других участников';

  @override
  String get photoThemesReachIdle =>
      'Участники могут помочь этому фото разойтись дальше';

  @override
  String get photoThemesReachLive =>
      'Участники видят его сейчас на своих стенах Today.';

  @override
  String get photoThemesRemoveMine => 'Удалить моё фото';

  @override
  String get photoThemesReport => 'Пожаловаться';

  @override
  String photoThemesBlock(String name) {
    return 'Заблокировать: $name';
  }

  @override
  String get photoThemesCommentHint => 'Что оно тебе напоминает?';

  @override
  String get photoThemesCommentApproved =>
      'Одобрено. Теперь его видят все, кто может видеть это фото.';

  @override
  String get photoThemesDetailsTitle => 'Расскажи о нём';

  @override
  String get photoThemesCaption => 'Подпись';

  @override
  String get photoThemesCaptionHint => 'Блинчики, и никуда не надо спешить.';

  @override
  String get photoThemesDescribe => 'Опиши фото';

  @override
  String get photoThemesDescribeHelper =>
      'Помогает участникам, которые пользуются программой чтения с экрана.';

  @override
  String get photoThemesShare => 'Поделиться';

  @override
  String get photoThemesWallTitle => 'Обложки на твоей стене';

  @override
  String get photoThemesWallCaption => 'Фото, которые понравились другим';

  @override
  String get photoThemesMasthead => 'ФОТОТЕМЫ';

  @override
  String photoThemesByline(String name) {
    return 'АВТОР: $name';
  }

  @override
  String get photoThemesLikes => 'Лайки';

  @override
  String get photoThemesComments => 'Комментарии';

  @override
  String get photoThemesCancel => 'Отмена';

  @override
  String get photoThemesTryAgain => 'Повторить';

  @override
  String get photoThemesSaveFailed => 'Не сохранилось. Попробуй ещё раз.';

  @override
  String get friendsChatEmpty =>
      'Поздоровайся. Эту переписку видите только вы двое.';

  @override
  String get friendsChatOpenFailed =>
      'Не удалось открыть чат. Попробуй ещё раз.';

  @override
  String get friendsCancelRequestTitle => 'Отменить заявку в друзья?';

  @override
  String friendsCancelRequestBody(String name) {
    return '$name больше не увидит твою заявку.';
  }

  @override
  String get friendsCancelRequestBodyUnnamed =>
      'Этот участник больше не увидит твою заявку.';

  @override
  String get friendsKeepIt => 'Оставить';

  @override
  String get friendsCancelRequest => 'Отменить заявку';

  @override
  String friendsNowFriends(String name) {
    return 'Теперь вы с $name друзья.';
  }

  @override
  String get friendsNowFriendsUnnamed => 'Теперь вы с этим участником друзья.';

  @override
  String friendsRequestSentTo(String name) {
    return 'Заявка в друзья отправлена: $name.';
  }

  @override
  String get friendsRequestSentToUnnamed =>
      'Заявка в друзья отправлена этому участнику.';

  @override
  String get friendsRequestCancelled => 'Заявка отменена.';

  @override
  String get friendsRequestFailed => 'Не удалось отправить заявку.';

  @override
  String get friendsAddCaption =>
      'Друзья могут переписываться и вместе строить планы';

  @override
  String get friendsRequested => 'Заявка отправлена';

  @override
  String friendsWaitingFor(String name) {
    return 'Ждём ответа: $name. Нажми, чтобы отменить.';
  }

  @override
  String get friendsWaitingForUnnamed =>
      'Ждём ответа этого участника. Нажми, чтобы отменить.';

  @override
  String get friendsAcceptFriend => 'Принять в друзья';

  @override
  String friendsAskedToBeFriends(String name) {
    return '$name хочет дружить';
  }

  @override
  String get friendsAskedToBeFriendsUnnamed => 'Этот участник хочет дружить';

  @override
  String get friendsMessage => 'Написать';

  @override
  String get friendsYoureFriends => 'Вы друзья. Открой ваш чат.';

  @override
  String friendsVouchTooShort(int min) {
    return 'Напиши чуть больше (минимум $min символов).';
  }

  @override
  String friendsVouchTitle(String name) {
    return 'Порекомендовать: $name';
  }

  @override
  String get friendsVouchBody =>
      'Пара фраз о том, почему с этим человеком стоит познакомиться. Он(а) одобрит текст, прежде чем тот появится в профиле с твоим именем.';

  @override
  String get friendsVouchLabel => 'Твоя рекомендация';

  @override
  String get friendsVouchHint => 'Добрый, смешной и всегда приходит вовремя.';

  @override
  String get friendsVouchSend => 'Отправить рекомендацию';

  @override
  String get friendsIntroChooseTwo => 'Выбери двух разных друзей.';

  @override
  String get friendsIntroSheetTitle => 'Познакомить двух друзей';

  @override
  String get friendsIntroSheetBody =>
      'Оба друга должны разрешить знакомства. Каждый сам настраивает превью и решает втайне. Указывай только ту причину, которую можно упоминать. Их решения и то, сложилась ли пара, остаются в тайне.';

  @override
  String get friendsIntroNeedTwo =>
      'Чтобы познакомить, нужно минимум два друга.';

  @override
  String get friendsFirstFriend => 'Первый друг';

  @override
  String get friendsSecondFriend => 'Второй друг';

  @override
  String get friendsIntroWhyLabel =>
      'Почему им стоит познакомиться (необязательно)';

  @override
  String get friendsIntroSubmit => 'Познакомить';

  @override
  String get friendsLoadFailed =>
      'Не удалось загрузить друзей. Попробуй ещё раз.';

  @override
  String get friendsAddFailed => 'Не удалось добавить в друзья.';

  @override
  String get friendsRemoveFailed => 'Не удалось удалить из друзей.';

  @override
  String get friendsRespondFailed => 'Не удалось ответить на заявку в друзья.';

  @override
  String get friendsSocialLoadFailed =>
      'Не удалось загрузить рекомендации и знакомства.';

  @override
  String get friendsVouchSendFailed => 'Не удалось отправить рекомендацию.';

  @override
  String get friendsVouchUpdateFailed => 'Не удалось обновить рекомендацию.';

  @override
  String get friendsVouchWithdrawFailed => 'Не удалось отозвать рекомендацию.';

  @override
  String get friendsIntroMakeFailed => 'Не удалось отправить знакомство.';

  @override
  String get friendsIntroAnswerFailed => 'Не удалось ответить на знакомство.';

  @override
  String get groupsEyebrow => 'ГРУППЫ';

  @override
  String get groupsTitle => 'Найди своих.';

  @override
  String get groupsSubtitle =>
      'Сообщества по интересам, куда может вступить любой, и закрытые группы только для твоих друзей.';

  @override
  String get groupsStartGroup => 'Создать группу';

  @override
  String get groupsInvitationsHeader => 'ПРИГЛАШЕНИЯ';

  @override
  String get groupsInvitationsCaption => 'Друзья зовут тебя в группу.';

  @override
  String get groupsAnswerFailed => 'Не удалось сохранить твой ответ.';

  @override
  String groupsWelcome(String name) {
    return 'Добро пожаловать в «$name»!';
  }

  @override
  String get groupsInvitationDeclined => 'Приглашение отклонено.';

  @override
  String get groupsYourGroupsHeader => 'ТВОИ ГРУППЫ';

  @override
  String get groupsYourGroupsFailed => 'Не удалось загрузить твои группы';

  @override
  String get groupsErrorCheckConnection => 'Проверь подключение к интернету.';

  @override
  String get groupsEmptyTitle => 'Пока нет групп';

  @override
  String get groupsEmptyBody =>
      'Вступи в сообщество ниже или создай закрытую группу с друзьями.';

  @override
  String get groupsDiscoverHeader => 'ИСКАТЬ ПО ИНТЕРЕСАМ';

  @override
  String get groupsDiscoverCaption => 'Сообщества открыты для всех.';

  @override
  String get groupsLifestylesFailed => 'Не удалось загрузить интересы';

  @override
  String get groupsCategoryAll => 'Все';

  @override
  String get groupsDiscoverFailed => 'Не удалось загрузить группы';

  @override
  String get groupsDiscoverEmptyTitle => 'Новых групп пока нет';

  @override
  String groupsDiscoverEmptyCategoryTitle(String category) {
    return 'Пока нет групп в категории $category';
  }

  @override
  String get groupsDiscoverEmptyBody =>
      'Создай первое сообщество и пригласи друзей.';

  @override
  String get groupsStartOne => 'Создать';

  @override
  String get groupsJoinFailed => 'Сейчас не удалось вступить.';

  @override
  String get groupsJoin => 'Вступить';

  @override
  String groupsJoinNamed(String name) {
    return 'Вступить в «$name»';
  }

  @override
  String groupsInvitedBy(String name, String kind, String members) {
    return '$name приглашает тебя · $kind · $members';
  }

  @override
  String groupsInvitedByFriend(String kind, String members) {
    return 'Друг приглашает тебя · $kind · $members';
  }

  @override
  String get groupsDecline => 'Отклонить';

  @override
  String groupsDeclineNamed(String name) {
    return 'Отклонить «$name»';
  }

  @override
  String groupsChatEmpty(String name) {
    return 'Поздоровайся с группой. Все участники «$name» видят сообщения здесь.';
  }

  @override
  String groupsInviteFriendsTo(String name) {
    return 'Пригласить друзей в «$name»';
  }

  @override
  String get groupsSendInvitations => 'Отправить приглашения';

  @override
  String get groupsInvitationsFailed => 'Не удалось отправить приглашения.';

  @override
  String groupsInvitationSentTo(String name) {
    return 'Приглашение отправлено: $name.';
  }

  @override
  String groupsInvitationsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Отправлено $count приглашения.',
      many: 'Отправлено $count приглашений.',
      few: 'Отправлено $count приглашения.',
      one: 'Отправлено $count приглашение.',
    );
    return '$_temp0';
  }

  @override
  String groupsLeaveTitle(String name) {
    return 'Выйти из «$name»?';
  }

  @override
  String get groupsLeaveBodyAlone =>
      'Ты единственный участник, поэтому группа и её чат будут удалены.';

  @override
  String get groupsLeaveBodyOwner =>
      'Права владельца перейдут самому давнему модератору, а если его нет — самому давнему участнику. Ты потеряешь доступ к чату.';

  @override
  String get groupsLeaveBodyCommunity =>
      'Ты потеряешь доступ к чату группы. Позже можно вступить снова.';

  @override
  String get groupsLeaveBodyPrivate =>
      'Ты потеряешь доступ к чату группы. Чтобы вернуться, понадобится новое приглашение.';

  @override
  String get groupsLeave => 'Выйти';

  @override
  String get groupsLeaveFailed => 'Сейчас не удалось выйти из группы.';

  @override
  String get groupsCoverUploadFailed =>
      'Не удалось загрузить фото обложки. Используй JPEG или PNG до 10 МБ.';

  @override
  String get groupsRemoveCoverTitle => 'Удалить фото обложки?';

  @override
  String groupsRemoveCoverBody(String name) {
    return 'У «$name» снова будет обложка с эмодзи.';
  }

  @override
  String get groupsRemove => 'Удалить';

  @override
  String get groupsRemoveCoverFailed => 'Не удалось удалить фото обложки.';

  @override
  String get groupsCoverRemoved => 'Фото обложки удалено.';

  @override
  String groupsDeleteTitle(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get groupsDeleteBody =>
      'Группа, её приглашения и чат будут удалены для всех. Это действие нельзя отменить.';

  @override
  String get groupsDeleteGroup => 'Удалить группу';

  @override
  String get groupsDeleteFailed => 'Не удалось удалить группу.';

  @override
  String get groupsDetailEyebrow => 'ГРУППА';

  @override
  String get groupsDetailTitleFallback => 'Группа';

  @override
  String get groupsOwnerTools => 'Инструменты владельца';

  @override
  String get groupsEditGroup => 'Изменить группу';

  @override
  String get groupsAddCoverPhoto => 'Добавить фото обложки';

  @override
  String get groupsChangeCoverPhoto => 'Сменить фото обложки';

  @override
  String get groupsRemoveCoverPhoto => 'Удалить фото обложки';

  @override
  String get groupsMoreOptions => 'Ещё';

  @override
  String get groupsReportGroup => 'Пожаловаться на группу';

  @override
  String get groupsUnavailableTitle => 'Эта группа недоступна';

  @override
  String get groupsUnavailableBody =>
      'Возможно, её удалили или у тебя больше нет доступа.';

  @override
  String get groupsOpenToAll => 'Открыта для всех';

  @override
  String get groupsPrivate => 'Закрытая';

  @override
  String get groupsYouRunIt => 'Твоя группа';

  @override
  String get groupsYouModerate => 'Ты модерируешь';

  @override
  String get groupsCoverNotePending =>
      'Пока фото не одобрят, его видишь только ты. Участники тем временем видят обложку с эмодзи.';

  @override
  String get groupsCoverNoteRejected =>
      'Твоё последнее фото обложки не одобрили. Выбери другое.';

  @override
  String get groupsCoverUnderReview => 'На проверке';

  @override
  String get groupsChangeCover => 'Сменить обложку';

  @override
  String get groupsRemoveCover => 'Удалить обложку';

  @override
  String get groupsRemovedTitle => 'Эта группа удалена после проверки';

  @override
  String get groupsRemovedBodyOwner =>
      'Пока группа удалена, участники не могут общаться, вступать или приглашать. В уведомлениях о проверке объясняется решение, там же его можно обжаловать.';

  @override
  String get groupsRemovedBodyMember =>
      'Пока группа удалена, участники не могут общаться, вступать или приглашать. Ты можешь выйти из группы в любой момент.';

  @override
  String get groupsMembers => 'Участники';

  @override
  String get groupsChatButton => 'Чат группы';

  @override
  String groupsChatButtonUnread(int count) {
    return 'Чат группы · новых: $count';
  }

  @override
  String get groupsInviteFriends => 'Пригласить друзей';

  @override
  String get groupsWhosHere => 'КТО ЗДЕСЬ';

  @override
  String get groupsSeeAll => 'Все';

  @override
  String get groupsYou => 'Ты';

  @override
  String groupsInvitedToJoin(String name) {
    return 'Тебя приглашают в «$name».';
  }

  @override
  String get groupsJoinGroup => 'Вступить в группу';

  @override
  String get groupsJoinHint =>
      'Участники видят, кто в группе, и общаются вместе.';

  @override
  String get groupsCantJoinTitle => 'Ты не можешь вступить в эту группу';

  @override
  String get groupsCantJoinBody =>
      'Возможно, она заполнена или модератор удалил тебя из неё.';

  @override
  String get groupsInvitationOnly => 'Только по приглашению';

  @override
  String get groupsInvitationOnlyBody =>
      'Участник может пригласить тебя в эту закрытую группу.';

  @override
  String get groupsMakeModerator => 'Сделать модератором';

  @override
  String get groupsMakeMember => 'Сделать участником';

  @override
  String get groupsRemoveFromGroup => 'Удалить из группы';

  @override
  String groupsRemoveMemberTitle(String name) {
    return 'Удалить $name?';
  }

  @override
  String get groupsRemoveMemberBodyCommunity =>
      'Человек покинет группу и её чат и не сможет сам вступить снова.';

  @override
  String get groupsRemoveMemberBodyPrivate =>
      'Человек покинет группу и её чат.';

  @override
  String get groupsChangeFailed => 'Не удалось сохранить изменение.';

  @override
  String get groupsMembersFailed => 'Не удалось загрузить участников';

  @override
  String get groupsPleaseTryAgain => 'Попробуй ещё раз.';

  @override
  String groupsMemberYou(String name) {
    return '$name (ты)';
  }

  @override
  String get groupsRoleOwner => 'Владелец';

  @override
  String get groupsRoleModerator => 'Модератор';

  @override
  String get groupsRoleMember => 'Участник';

  @override
  String groupsMemberOptions(String name) {
    return 'Действия: $name';
  }

  @override
  String get groupsEditFailed => 'Не удалось сохранить изменения.';

  @override
  String get groupsSaving => 'Сохранение…';

  @override
  String get groupsSaveChanges => 'Сохранить изменения';

  @override
  String get groupsNameLabel => 'Название группы';

  @override
  String get groupsAboutLabel => 'О чём эта группа?';

  @override
  String get groupsAboutOptionalLabel => 'О чём эта группа? (необязательно)';

  @override
  String get groupsCityLabel => 'Город (необязательно)';

  @override
  String get groupsCoverColorTheme => 'Тема';

  @override
  String get groupsCoverColorAccent => 'Акцент';

  @override
  String get groupsCoverColorWarm => 'Тёплый';

  @override
  String get groupsLifestyleLabel => 'Интересы';

  @override
  String get groupsCreateCoverUploadFailed =>
      'Группа создана, но фото обложки загрузить не удалось. Попробуй ещё раз в группе.';

  @override
  String get groupsCreatePickLifestyle =>
      'Выбери интерес для своего сообщества.';

  @override
  String get groupsCreateNameTooShort =>
      'Название группы должно содержать не меньше 3 букв.';

  @override
  String get groupsCreateFailed =>
      'Не удалось создать группу. Попробуй ещё раз.';

  @override
  String get groupsCreateEyebrow => 'НОВАЯ ГРУППА';

  @override
  String get groupsCreateSubtitle =>
      'Объединяй людей вокруг того, что ты любишь.';

  @override
  String get groupsCreateSubtitleFriends => 'Собери друзей в группу.';

  @override
  String get groupsCreateKindHeader => 'ТИП ГРУППЫ';

  @override
  String get groupsKindCommunity => 'Сообщество';

  @override
  String get groupsKindPrivate => 'Закрытая группа';

  @override
  String get groupsCreateCommunitySubtitle =>
      'По интересам. Любой может найти его и вступить.';

  @override
  String get groupsCreatePrivateSubtitle =>
      'Только друзья. Вступить могут лишь те, кого ты пригласишь.';

  @override
  String get groupsCreateLifestyleHeader => 'ИНТЕРЕСЫ';

  @override
  String get groupsCreateLifestyleCaption => 'По ним люди найдут твою группу.';

  @override
  String get groupsCreateDetailsHeader => 'ПОДРОБНОСТИ';

  @override
  String get groupsCreateNameHintCommunity => 'Утренние бегуны Индиранагара';

  @override
  String get groupsCreateNameHintPrivate => 'Компания воскресного бранча';

  @override
  String get groupsCreateCoverHeader => 'ОБЛОЖКА';

  @override
  String groupsCoverEmojiSemantics(String emoji) {
    return 'Эмодзи обложки $emoji';
  }

  @override
  String get groupsCreateCoverPhotoOptional => 'Фото обложки (необязательно)';

  @override
  String get groupsCreateCoverPhotoHint =>
      'Пока фото не одобрят, участники видят эмодзи.';

  @override
  String get groupsCreateAddCoverPhoto => 'Добавить фото обложки';

  @override
  String get groupsCreateChangePhoto => 'Сменить фото';

  @override
  String get groupsCreateRemovePhoto => 'Удалить фото';

  @override
  String get groupsCreateFriendsHeader => 'ДРУЗЬЯ';

  @override
  String get groupsCreateFriendsCaptionEmpty =>
      'Пригласи друзей сейчас или позже из группы.';

  @override
  String get groupsCreateFriendsCaption => 'Они получат приглашение вступить.';

  @override
  String get groupsFriendFallback => 'Друг';

  @override
  String groupsRemoveInvitee(String name) {
    return 'Убрать $name';
  }

  @override
  String get groupsChooseFriends => 'Выбрать друзей';

  @override
  String get groupsChangeFriends => 'Изменить список друзей';

  @override
  String get groupsCreating => 'Создание…';

  @override
  String get groupsCreateGroup => 'Создать группу';

  @override
  String get groupsCardRemoved => 'Удалена после проверки';

  @override
  String groupsCardSemanticsMuted(String name, String details) {
    return '$name, $details, уведомления отключены';
  }

  @override
  String get groupsNotificationsMuted => 'Уведомления отключены';

  @override
  String groupsUnreadMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count непрочитанного сообщения',
      many: '$count непрочитанных сообщений',
      few: '$count непрочитанных сообщения',
      one: '$count непрочитанное сообщение',
    );
    return '$_temp0';
  }

  @override
  String get groupsCoverSheetTitle => 'Фото обложки';

  @override
  String get groupsCoverSheetBody =>
      'Каждое фото проверяется, прежде чем его увидят другие участники. Используй JPEG или PNG до 10 МБ.';

  @override
  String get groupsCoverFromPhotos => 'Выбрать из фото';

  @override
  String get groupsCoverTakePhoto => 'Сделать фото';

  @override
  String get groupsCoverTooLarge =>
      'Это фото больше 10 МБ. Выбери фото поменьше.';

  @override
  String get groupsCoverPreviewTitle => 'Предпросмотр обложки';

  @override
  String get groupsCoverPreviewBody =>
      'Обложка показывается широким баннером по центру твоего фото.';

  @override
  String get groupsCancel => 'Отмена';

  @override
  String get groupsCoverUseThisPhoto => 'Использовать это фото';

  @override
  String get groupsCoverPreviewSemantics => 'Новое фото обложки';

  @override
  String get groupsCoverChecking => 'Проверяем фото обложки…';

  @override
  String groupsCoverUploading(int percent) {
    return 'Загрузка фото обложки… $percent%';
  }

  @override
  String get groupsCoverUploadedReview =>
      'Обложка на проверке. Пока её не одобрят, её видишь только ты.';

  @override
  String get groupsCoverUpdated => 'Фото обложки обновлено.';

  @override
  String get groupsPickerSubtitle =>
      'Пригласить можно только тех, кто у тебя в друзьях.';

  @override
  String get groupsDone => 'Готово';

  @override
  String get groupsSearchFriends => 'Поиск друзей';

  @override
  String get groupsFriendsFailed => 'Не удалось загрузить друзей';

  @override
  String get groupsNoFriendsTitle => 'Пока нет друзей';

  @override
  String get groupsNoFriendsBody =>
      'Добавляй друзей из «Пар», профилей или комнат, а потом зови их в группу.';

  @override
  String get groupsAlreadyMember => 'Уже в группе';

  @override
  String get groupsInvitationSent => 'Приглашение отправлено';

  @override
  String get todayActivityCoffee => 'Кофе';

  @override
  String get todayActivityWalk => 'Прогулка днём';

  @override
  String get todayActivityMeal => 'Обед или ужин';

  @override
  String get todayActivityPlayful => 'Что-нибудь весёлое';

  @override
  String get todayActivityEvent => 'Мероприятие';

  @override
  String get todayActivityVideoCall => 'Привет по видеосвязи';

  @override
  String get todayActivityDrinks => 'Напитки';

  @override
  String get todayActivityOther => 'Что-то другое';

  @override
  String get todayBudgetFlexible => 'Решим вместе';

  @override
  String get todayBudgetFree => 'Бесплатно';

  @override
  String get todayBudgetModest => 'Скромно';

  @override
  String get todayBudgetTreat => 'Небольшое удовольствие';

  @override
  String get todayRhythmTitle => 'Твой ритм знакомств';

  @override
  String get todayRhythmLoadFailed => 'Не удалось загрузить твои настройки.';

  @override
  String get todayRhythmSaved => 'Твой ритм знакомств сохранён.';

  @override
  String get todayRhythmSaveFailed =>
      'Не удалось сохранить. Твой выбор никуда не делся.';

  @override
  String get todayRhythmHeadline => 'Знакомься так, как удобно тебе.';

  @override
  String get todayRhythmIntro =>
      'Выбери то, что подходит твоей жизни. Свободное время и знакомства — по желанию, и ты всегда можешь передумать.';

  @override
  String get todayRhythmOpenTo => 'К чему ты открыт(а)?';

  @override
  String get todayRhythmIntentNone => 'Предпочитаю не говорить';

  @override
  String get todayRhythmIntentRelationship => 'Отношения';

  @override
  String get todayRhythmIntentExploring => 'Пока определяюсь';

  @override
  String get todayRhythmIntentCasual => 'Что-то несерьёзное';

  @override
  String get todayRhythmPaceSection => 'Твой темп общения';

  @override
  String get todayRhythmPaceNone => 'Без предпочтений';

  @override
  String get todayRhythmPaceSlow => 'Чуть медленнее';

  @override
  String get todayRhythmPaceSteady => 'Размеренное общение';

  @override
  String get todayRhythmPaceFrequent => 'Частое общение';

  @override
  String get todayRhythmSlowWeek => 'Отвечаю медленно на этой неделе';

  @override
  String get todayRhythmSlowWeekHint =>
      'Этот статус сбросится через семь дней.';

  @override
  String get todayRhythmSharePace => 'Показывать этот статус моим парам';

  @override
  String get todayRhythmSharePaceHint =>
      'Временный статус видят только твои текущие пары.';

  @override
  String get todayRhythmFirstDate => 'Твоё идеальное первое свидание';

  @override
  String get todayRhythmChooseFive =>
      'Выбери до пяти. Общие предпочтения помогают объяснить твои знакомства.';

  @override
  String get todayRhythmWeekSection => 'Немного свободного времени на неделе';

  @override
  String get todayRhythmShareAvailability =>
      'Учитывать моё примерное свободное время';

  @override
  String get todayRhythmShareAvailabilityHint =>
      'Показываются только реальные совпадения. Твоё полное расписание остаётся приватным. Если выключить, сохранённые окна удалятся.';

  @override
  String get todayRhythmAvailabilityHint =>
      'Нажми на любое подходящее утро, день или вечер. Время указано по часам этого устройства и истекает автоматически.';

  @override
  String get todayRhythmMorning => 'Утро';

  @override
  String get todayRhythmAfternoon => 'День';

  @override
  String get todayRhythmEvening => 'Вечер';

  @override
  String get todayRhythmIntrosSection => 'Знакомства с твоего согласия';

  @override
  String get todayRhythmFriendIntros =>
      'Разрешить знакомства через подтверждённых друзей';

  @override
  String get todayRhythmFriendIntrosHint =>
      'Согласиться должны оба. Друг не узнает о совпадении или отказе. В превью будут твоё имя и возраст.';

  @override
  String get todayRhythmIntroPhoto => 'Показывать мои фото профиля';

  @override
  String get todayRhythmIntroPhotoHint =>
      'Их увидит только человек, которому тебя представят.';

  @override
  String get todayRhythmIntroCity => 'Показывать мой город';

  @override
  String get todayRhythmIntroCityHint =>
      'Твоё точное местоположение никогда не передаётся.';

  @override
  String get todayRhythmReload => 'Загрузить сохранённый выбор';

  @override
  String get todayRhythmSaving => 'Сохранение…';

  @override
  String get todayRhythmSave => 'Сохранить мой ритм';

  @override
  String get todayRhythmBreakTitle => 'Сделать перерыв — всегда нормально.';

  @override
  String get todayRhythmBreakBody =>
      'Приостанавливай новые знакомства, когда нужно. Текущие переписки останутся доступны.';

  @override
  String get todayRhythmPauseFailed => 'Не удалось изменить паузу.';

  @override
  String get todayRhythmResume => 'Возобновить знакомства';

  @override
  String get todayRhythmPause => 'Приостановить знакомства';

  @override
  String get datingConnectionSlowTitle => 'На этой неделе отвечает не спеша';

  @override
  String get datingConnectionSlowBody =>
      'Твоя пара сейчас выбирает более спокойный темп.';

  @override
  String get datingConnectionYourTurn => 'Твоя очередь: добавь сюрприз';

  @override
  String get datingConnectionComplete => 'Ваша первая глава готова';

  @override
  String get datingConnectionWaiting => 'У вашей главы есть начало';

  @override
  String get datingConnectionCreate => 'Создайте первую главу';

  @override
  String get datingConnectionBody =>
      'Начало, сюрприз и история, которую вы создаёте вместе.';

  @override
  String get chemistryTitle => 'Немного химии';

  @override
  String get chemistryIntro =>
      'Выбери то, что тебе ближе. Правильных ответов нет, и это никак не влияет на доступ к чату.';

  @override
  String get chemistrySaveFailed =>
      'Не удалось сохранить твой выбор. Попробуй ещё раз.';

  @override
  String get chemistryRetry => 'Загрузить ещё раз';

  @override
  String get chemistryRevealedTitle => 'Оба ответа вместе';

  @override
  String get chemistryYouPicked => 'Твой выбор';

  @override
  String get chemistryMatchPicked => 'Выбор твоей пары';

  @override
  String get chemistryRevealedBody =>
      'Общий фаворит или приятное различие — в любом случае есть о чём поговорить.';

  @override
  String get chemistryWaitingBody =>
      'Твой ответ сохранён приватно. Оба ответа появятся здесь, когда вы оба сделаете выбор.';

  @override
  String chemistryYourChoice(String choice) {
    return 'Твой выбор: $choice';
  }

  @override
  String get chemistryAnotherMoment => 'Ещё один момент — когда захочешь';

  @override
  String get chemistryChooseMoment => 'Выбери момент';

  @override
  String get chemistryPromptSunday => 'Придумай воскресенье';

  @override
  String get chemistryPromptAdventure => 'Выбери приключение';

  @override
  String get chemistryPromptFirstDate => 'Твоё идеальное первое свидание';

  @override
  String get chemistryQuestionSunday =>
      'Твоё идеальное воскресенье начинается с…';

  @override
  String get chemistryQuestionAdventure => 'Маленькое приключение вдвоём…';

  @override
  String get chemistryQuestionFirstDate =>
      'Для первой встречи ты бы выбрал(а)…';

  @override
  String get engagementLevelFrozen =>
      'Прогресс приостановлен, пока идёт проверка безопасности аккаунта.';

  @override
  String get engagementLevelTrustGate =>
      'Подтверди профиль и поддерживай аккаунт в порядке, чтобы открыть уровни с порогом доверия.';

  @override
  String get engagementLevelPathTitle => 'Путь уровней';

  @override
  String get engagementLevelPathSubtitle =>
      'XP начисляются за полезную активность. Покупки никогда не повышают уровень.';

  @override
  String get engagementLevelRewardsTitle => 'Награды';

  @override
  String get engagementLevelRewardsSubtitle =>
      'Награды — это оформление, удобства или ограниченный бонус к видимости.';

  @override
  String get engagementLevelRecentTitle => 'Недавние XP';

  @override
  String get engagementLevelRecentSubtitle =>
      'Журнал твоей активности хранится постоянно и доступен для проверки.';

  @override
  String engagementLevelNumber(int level) {
    return 'Уровень $level';
  }

  @override
  String engagementLevelXp(String xp) {
    return '$xp XP';
  }

  @override
  String get engagementLevelHighest => 'Достигнут максимальный уровень';

  @override
  String engagementLevelProgress(int xp, String percent) {
    return '$xp XP на этом уровне · $percent %';
  }

  @override
  String engagementLevelThreshold(int xp, String summary) {
    return '$xp XP · $summary';
  }

  @override
  String get engagementLevelTrustGated => 'Требует доверия';

  @override
  String get engagementLevelClaimed => 'Получено';

  @override
  String get engagementLevelClaim => 'Получить';

  @override
  String get engagementLevelLocked => 'Закрыто';

  @override
  String get engagementLevelStandardAward => 'Обычное начисление';

  @override
  String engagementLevelQualityWeighting(String multiplier) {
    return 'Коэффициент качества ×$multiplier';
  }

  @override
  String get engagementLevelEmptyLedger =>
      'Выполняй полезные действия, чтобы получить первые XP.';

  @override
  String get engagementXpSourceProfileCompleted => 'Профиль заполнен';

  @override
  String get engagementXpSourceDailyPromptSubmitted => 'Ответ на вопрос дня';

  @override
  String get engagementXpSourceMiniActivityCompleted =>
      'Мини-активность выполнена';

  @override
  String get engagementXpSourceCircleChallengeSubmitted =>
      'Ответ на челлендж круга';

  @override
  String get engagementXpSourceVoiceIcebreakerPlayed =>
      'Голосовое приветствие прослушано';

  @override
  String get engagementXpSourceStreak3 => 'Серия 3 дня';

  @override
  String get engagementXpSourceStreak7 => 'Серия 7 дней';

  @override
  String get engagementXpSourceStreak14 => 'Серия 14 дней';

  @override
  String get engagementXpSourceAdminAdjustment =>
      'Корректировка администратором';

  @override
  String get engagementLevelSignIn => 'Войди, чтобы увидеть прогресс уровня.';

  @override
  String get engagementLevelLoadFailed =>
      'Сейчас не удаётся загрузить твой прогресс.';

  @override
  String get engagementLevelClaimFailed =>
      'Сейчас не удаётся получить эту награду.';

  @override
  String get engagementCoffeeTitle => 'Опросы о кофе для групп';

  @override
  String get engagementCoffeeCreateHeading =>
      'Создай простой опрос о кофе для группы';

  @override
  String get engagementCoffeeCreateHint =>
      'Добавь до 3 ID участников (через запятую) и хотя бы один вариант.';

  @override
  String get engagementCoffeeParticipantsLabel =>
      'ID участников (через запятую)';

  @override
  String get engagementCoffeeDeadlineLabel =>
      'Срок в формате ISO (необязательно)';

  @override
  String engagementCoffeeOptionNumber(int number) {
    return 'Вариант $number';
  }

  @override
  String get engagementCoffeeCreate => 'Создать опрос';

  @override
  String get engagementCoffeeActorLabel =>
      'Другой ID пользователя для действия (необязательно)';

  @override
  String get engagementCoffeeEmpty => 'Опросов пока нет. Создай первый выше.';

  @override
  String engagementCoffeePollId(String id) {
    return 'Опрос $id';
  }

  @override
  String engagementCoffeeStatus(String status) {
    return 'Статус: $status';
  }

  @override
  String get engagementCoffeeStatusOpen => 'открыт';

  @override
  String get engagementCoffeeStatusFinalized => 'завершён';

  @override
  String engagementCoffeeParticipants(String ids) {
    return 'Участники: $ids';
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
      other: '$day · $time · $area ($count голоса)',
      many: '$day · $time · $area ($count голосов)',
      few: '$day · $time · $area ($count голоса)',
      one: '$day · $time · $area ($count голос)',
    );
    return '$_temp0';
  }

  @override
  String get engagementCoffeeVote => 'Голосовать';

  @override
  String get engagementCoffeeFinalize => 'Завершить опрос';

  @override
  String get engagementCoffeeDayLabel => 'День';

  @override
  String get engagementCoffeeTimeLabel => 'Время';

  @override
  String get engagementCoffeeAreaLabel => 'Район';

  @override
  String get engagementCoffeeLoadFailed =>
      'Сейчас не удаётся загрузить опросы.';

  @override
  String get engagementCoffeeCreateFailed => 'Сейчас не удаётся создать опрос.';

  @override
  String get engagementCoffeeVoteUserRequired =>
      'Для голосования нужен ID пользователя.';

  @override
  String get engagementCoffeeVoteFailed => 'Сейчас не удаётся проголосовать.';

  @override
  String get engagementCoffeeFinalizeUserRequired =>
      'Для завершения нужен ID пользователя.';

  @override
  String get engagementCoffeeFinalizeFailed =>
      'Сейчас не удаётся завершить опрос.';

  @override
  String get engagementDailyPromptUnavailable => 'Вопрос дня недоступен';

  @override
  String get engagementDailyPromptPullToRefresh =>
      'Потяни вниз, чтобы обновить, или попробуй чуть позже.';

  @override
  String get engagementDailyPromptDomainValues => 'ЦЕННОСТИ';

  @override
  String get engagementDailyPromptDomainLifestyle => 'ОБРАЗ ЖИЗНИ';

  @override
  String get engagementDailyPromptDomainRelationshipStyle => 'СТИЛЬ ОТНОШЕНИЙ';

  @override
  String get engagementDailyPromptSparkTitle => 'Искра совместимости';

  @override
  String engagementDailyPromptSparkSummary(int replied, int similar) {
    return 'Ответов сегодня: $replied · похожих ответов: $similar';
  }

  @override
  String get engagementDailyPromptYourAnswer => 'Твой ответ';

  @override
  String get engagementDailyPromptHint =>
      'Напиши ответ меньше чем за 60 секунд.';

  @override
  String engagementDailyPromptEditOpenUntil(String time) {
    return 'Изменить можно до $time';
  }

  @override
  String get engagementDailyPromptEditOpenSoon => 'Изменить можно ещё недолго';

  @override
  String get engagementDailyPromptEditClosed =>
      'На сегодня изменить ответ уже нельзя.';

  @override
  String get engagementDailyPromptEdited => 'Изменено';

  @override
  String get engagementDailyPromptSubmit => 'Отправить ответ дня';

  @override
  String get engagementDailyPromptUpdate => 'Обновить ответ';

  @override
  String get engagementDailyPromptStreakProgress => 'Прогресс серии';

  @override
  String engagementDailyPromptStatCurrent(String value) {
    return 'Сейчас: $value';
  }

  @override
  String engagementDailyPromptStatBest(String value) {
    return 'Рекорд: $value';
  }

  @override
  String engagementDailyPromptStatNext(String value) {
    return 'Следующая цель: $value';
  }

  @override
  String engagementDailyPromptDays(int days) {
    return '$days дн.';
  }

  @override
  String get engagementDailyPromptComplete => 'Всё пройдено';

  @override
  String engagementDailyPromptMilestone(int days) {
    return 'Новая цель достигнута: серия $days дн.';
  }

  @override
  String get engagementDailyPromptLoadFailed =>
      'Сейчас не удаётся загрузить вопрос дня.';

  @override
  String get engagementDailyPromptNotLoaded => 'Вопрос дня ещё не загружен.';

  @override
  String get engagementDailyPromptEnterAnswer => 'Сначала напиши ответ.';

  @override
  String get engagementDailyPromptSubmitFailed =>
      'Не удалось отправить ответ. Попробуй ещё раз.';

  @override
  String get clubsKindBooks => 'Книги';

  @override
  String get clubsKindFilms => 'Фильмы';

  @override
  String get clubsFilterAll => 'Все';

  @override
  String get clubsAudiencePrivate => 'Только я';

  @override
  String get clubsAudienceFriends => 'Друзья';

  @override
  String get clubsAudienceCommunity => 'Сообщество Connect';

  @override
  String get clubsRoleOwner => 'Владелец';

  @override
  String get clubsRoleModerator => 'Модератор';

  @override
  String get clubsRoleMember => 'Участник';

  @override
  String get clubsBadgeBookClub => 'Книжный клуб';

  @override
  String get clubsBadgeFilmClub => 'Киноклуб';

  @override
  String get clubsBadgeBookList => 'Список книг';

  @override
  String get clubsBadgeFilmList => 'Список фильмов';

  @override
  String get clubsBadgeBook => 'Книга';

  @override
  String get clubsBadgeFilm => 'Фильм';

  @override
  String get clubsClub => 'Клуб';

  @override
  String clubsStarsOutOfFive(String rating) {
    return '$rating из 5 звёзд';
  }

  @override
  String clubsStarCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count звезды',
      many: '$count звёзд',
      few: '$count звезды',
      one: '$count звезда',
    );
    return '$_temp0';
  }

  @override
  String get clubsNoRatingsYet => 'Оценок пока нет';

  @override
  String clubsRatingSummary(String average, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count отзыва',
      many: '$count отзывов',
      few: '$count отзыва',
      one: '$count отзыв',
    );
    return '$average · $_temp0';
  }

  @override
  String get clubsWeekThis => 'Эта неделя';

  @override
  String get clubsWeekNext => 'Следующая неделя';

  @override
  String get clubsWeekLast => 'Прошлая неделя';

  @override
  String clubsWeekOf(String date) {
    return 'Неделя с $date';
  }

  @override
  String get clubsTitle => 'Книжные клубы и киноклубы';

  @override
  String get clubsMyLists => 'Мои списки';

  @override
  String get clubsStartClubTooltip => 'Создай книжный клуб или киноклуб';

  @override
  String get clubsStartClub => 'Создать клуб';

  @override
  String get clubsSignInToSee => 'Войди, чтобы видеть клубы.';

  @override
  String get clubsHeroTitle => 'Читай. Смотри. Обсуждай.';

  @override
  String get clubsHeroSubtitle =>
      'Вступай в клуб, следи за одним выбором в неделю и делись впечатлениями. Хороший вкус — отличный повод для разговора.';

  @override
  String get clubsScopeMine => 'Мои клубы';

  @override
  String get clubsScopeDiscover => 'Обзор';

  @override
  String get clubsLoadErrorTitle => 'Не удалось загрузить клубы';

  @override
  String get clubsCheckConnection => 'Проверь подключение.';

  @override
  String get clubsLookAroundTitle => 'Можешь осмотреться';

  @override
  String get clubsLookAroundMessage =>
      'Заполни профиль и добавь две одобренные фотографии, чтобы создать клуб или вступить в него.';

  @override
  String get clubsEmptyMineTitle => 'Твой первый клуб ждёт';

  @override
  String get clubsEmptyMineMessage =>
      'Найди клуб, который читает или смотрит то, что ты любишь, или создай свой.';

  @override
  String get clubsEmptyDiscoverTitle => 'Здесь пока нет клубов';

  @override
  String get clubsEmptyDiscoverMessage =>
      'Сделай первый шаг: создай клуб и выбери что-нибудь классное на эту неделю.';

  @override
  String get clubsDiscoverClubs => 'Найти клубы';

  @override
  String clubsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count участника',
      many: '$count участников',
      few: '$count участника',
      one: '$count участник',
    );
    return '$_temp0';
  }

  @override
  String get clubsYouRunIt => 'Ты ведёшь его';

  @override
  String get clubsYouModerate => 'Ты модерируешь';

  @override
  String get clubsJoined => 'Ты в клубе ✓';

  @override
  String get clubsNoPickThisWeek => 'На этой неделе выбора пока нет';

  @override
  String get clubsNameTooShort => 'Дай клубу название не короче 3 букв.';

  @override
  String get clubsCreateFailed => 'Не удалось создать клуб.';

  @override
  String get clubsNameLabel => 'Название клуба';

  @override
  String get clubsNameHint => 'Неспешное чтение по воскресеньям';

  @override
  String get clubsDescriptionLabel => 'О чём твой клуб? (необязательно)';

  @override
  String get clubsCreating => 'Создание…';

  @override
  String get clubsCreateClub => 'Создать клуб';

  @override
  String clubsLeaveTitle(String name) {
    return 'Покинуть «$name»?';
  }

  @override
  String get clubsLeaveMessage =>
      'Ты сможешь вернуться позже, пока клуб открыт.';

  @override
  String get clubsLeaveClub => 'Покинуть клуб';

  @override
  String clubsWelcome(String name) {
    return 'Добро пожаловать в «$name»!';
  }

  @override
  String get clubsChangeNotSaved => 'Не удалось сохранить изменение.';

  @override
  String get clubsOptionsTooltip => 'Действия с клубом';

  @override
  String get clubsMembers => 'Участники';

  @override
  String get clubsReportClub => 'Пожаловаться на клуб';

  @override
  String get clubsDetailLoadErrorTitle => 'Не удалось загрузить клуб';

  @override
  String get clubsDetailLoadErrorMessage =>
      'Возможно, он закрыт. Попробуй ещё раз.';

  @override
  String get clubsEarlierPicks => 'Предыдущие выборы';

  @override
  String clubsPickSubtitle(String week, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сообщения',
      many: '$count сообщений',
      few: '$count сообщения',
      one: '$count сообщение',
    );
    return '$week · $_temp0';
  }

  @override
  String get clubsOpenDiscussion => 'Открыть обсуждение';

  @override
  String get clubsJoinToSeeTitle => 'Вступи, чтобы видеть обсуждение';

  @override
  String get clubsJoinToSeeMessage =>
      'Участники вместе обсуждают каждый выбор. Вступи в клуб, чтобы читать обсуждение и делиться мыслями.';

  @override
  String clubsYouRole(String role) {
    return 'Ты: $role';
  }

  @override
  String get clubsRemovedByModeration => 'Этот клуб удалён модерацией.';

  @override
  String get clubsJoinClub => 'Вступить в клуб';

  @override
  String get clubsNoPickModerator =>
      'Выбора пока нет. Выбери что-нибудь классное для всех.';

  @override
  String get clubsNoPickMember => 'Выбора пока нет. Загляни позже.';

  @override
  String clubsQuotedNote(String note) {
    return '«$note»';
  }

  @override
  String clubsPostsInDiscussion(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сообщения в обсуждении',
      many: '$count сообщений в обсуждении',
      few: '$count сообщения в обсуждении',
      one: '$count сообщение в обсуждении',
    );
    return '$_temp0';
  }

  @override
  String get clubsSetThisWeeksPick => 'Выбрать на эту неделю';

  @override
  String get clubsDiscussThisPick => 'Обсудить этот выбор';

  @override
  String get clubsPostNotSent => 'Не удалось отправить сообщение.';

  @override
  String clubsDiscussionHeading(String title) {
    return 'Обсуждение · $title';
  }

  @override
  String get clubsDiscussionLoadError => 'Не удалось загрузить обсуждение';

  @override
  String get clubsStartConversationTitle => 'Начни разговор';

  @override
  String get clubsStartConversationMessage =>
      'Что думаешь на данный момент? Твоё сообщение может разговорить всех.';

  @override
  String get clubsLoadMorePosts => 'Загрузить ещё сообщения';

  @override
  String get clubsComposerLabel => 'Добавить в обсуждение';

  @override
  String get clubsComposerHint => 'Любимый момент? Самый большой сюрприз?';

  @override
  String get clubsContainsSpoilers => 'Есть спойлеры';

  @override
  String get clubsSpoilersSubtitle => 'Другие увидят его по нажатию.';

  @override
  String get clubsPosting => 'Публикация…';

  @override
  String get clubsPost => 'Опубликовать';

  @override
  String get clubsDeletePostTitle => 'Удалить твоё сообщение?';

  @override
  String get clubsDeletePostMessage => 'Оно исчезнет из обсуждения для всех.';

  @override
  String get clubsActionFailed => 'Не удалось выполнить действие.';

  @override
  String get clubsHideFromMembers => 'Скрыть от участников';

  @override
  String get clubsShowToMembers => 'Показать участникам';

  @override
  String get clubsReport => 'Пожаловаться';

  @override
  String get clubsYou => 'Ты';

  @override
  String get clubsHidden => 'Скрыто';

  @override
  String get clubsPostActions => 'Действия с сообщением';

  @override
  String get clubsMakeModerator => 'Сделать модератором';

  @override
  String get clubsMakeMember => 'Сделать участником';

  @override
  String get clubsRemoveFromClub => 'Удалить из клуба';

  @override
  String clubsRemoveMemberTitle(String name) {
    return 'Удалить $name?';
  }

  @override
  String get clubsRemoveMemberMessage =>
      'Участник покинет клуб и не сможет вернуться. Его прошлые сообщения останутся в обсуждении.';

  @override
  String get clubsRemove => 'Удалить';

  @override
  String get clubsMembersLoadError => 'Не удалось загрузить участников.';

  @override
  String clubsMemberYou(String name) {
    return '$name (ты)';
  }

  @override
  String clubsMemberActions(String name) {
    return 'Действия: $name';
  }

  @override
  String get clubsChooseFilm => 'Выбери фильм';

  @override
  String get clubsChooseBook => 'Выбери книгу';

  @override
  String get clubsChooseTitle => 'Выбери произведение';

  @override
  String get clubsChooseTitleFirst => 'Сначала выбери произведение.';

  @override
  String get clubsPickNotSaved => 'Не удалось сохранить выбор.';

  @override
  String get clubsSetWeeklyPick => 'Выбор недели';

  @override
  String get clubsChange => 'Изменить';

  @override
  String get clubsPickNoteLabel => 'Заметка для клуба (необязательно)';

  @override
  String get clubsPickNoteHint => 'Почему именно это? С чего начать?';

  @override
  String get clubsSaving => 'Сохранение…';

  @override
  String get clubsSavePick => 'Сохранить выбор';

  @override
  String get clubsListNameRequired => 'Дай списку название.';

  @override
  String get clubsListNotSaved => 'Не удалось сохранить список.';

  @override
  String get clubsEditList => 'Изменить список';

  @override
  String get clubsNewList => 'Новый список';

  @override
  String get clubsListNameLabel => 'Название списка';

  @override
  String get clubsListNameHint => 'Книги, которые изменили моё мнение';

  @override
  String get clubsWhoCanSee => 'Кто может видеть';

  @override
  String get clubsSave => 'Сохранить';

  @override
  String get clubsCreateList => 'Создать список';

  @override
  String get clubsYourNote => 'Твоя заметка';

  @override
  String get clubsNoteLabel => 'Почему это в списке';

  @override
  String get clubsSaveNote => 'Сохранить заметку';

  @override
  String get clubsCreateNewListTooltip => 'Создать новый список';

  @override
  String get clubsSignInToSeeLists => 'Войди, чтобы видеть свои списки.';

  @override
  String get clubsShelfTitle => 'Твоя полка';

  @override
  String get clubsShelfSubtitle =>
      'Отмечай, что тебе понравилось и что на очереди. Делись списком или оставь его только для себя.';

  @override
  String get clubsListsLoadErrorTitle => 'Не удалось загрузить твои списки';

  @override
  String get clubsFirstListTitle => 'Создай свой первый список';

  @override
  String get clubsFirstListMessage =>
      'Любимые фильмы, книги на потом, уютные пересмотры — решать тебе.';

  @override
  String clubsAddToNamed(String name) {
    return 'Добавить в «$name»';
  }

  @override
  String get clubsAddToThisListFailed => 'Не удалось добавить в этот список.';

  @override
  String clubsDeleteListTitle(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get clubsDeleteListMessage =>
      'Список и заметки будут удалены. Это нельзя отменить.';

  @override
  String get clubsDeleteList => 'Удалить список';

  @override
  String get clubsListDeleteFailed =>
      'Не удалось удалить список. Обнови и попробуй снова.';

  @override
  String get clubsNoteNotSaved => 'Не удалось сохранить заметку.';

  @override
  String get clubsRemoveFailed => 'Не удалось удалить.';

  @override
  String get clubsListOptions => 'Действия со списком';

  @override
  String get clubsAddATitle => 'Добавить произведение';

  @override
  String clubsTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count произведения',
      many: '$count произведений',
      few: '$count произведения',
      one: '$count произведение',
    );
    return '$_temp0';
  }

  @override
  String get clubsListEmpty =>
      'Пока пусто. Нажми «Добавить произведение» в меню списка.';

  @override
  String clubsItemOptions(String title) {
    return 'Действия: $title';
  }

  @override
  String get clubsAddNote => 'Добавить заметку';

  @override
  String get clubsEditNote => 'Изменить заметку';

  @override
  String get clubsRemoveFromList => 'Убрать из списка';

  @override
  String get clubsTapStarError => 'Нажми на звезду, чтобы поставить оценку.';

  @override
  String get clubsReviewNotSaved => 'Не удалось сохранить отзыв.';

  @override
  String get clubsWriteReview => 'Написать отзыв';

  @override
  String get clubsEditYourReview => 'Изменить отзыв';

  @override
  String get clubsTapStarToRate => 'Нажми на звезду, чтобы оценить';

  @override
  String clubsRatingOutOfFive(int rating) {
    return '$rating из 5';
  }

  @override
  String get clubsReviewBodyLabel => 'Что ты думаешь? (необязательно)';

  @override
  String get clubsSaveReview => 'Сохранить отзыв';

  @override
  String clubsAddedToList(String name) {
    return 'Добавлено в «$name».';
  }

  @override
  String get clubsAddToThatListFailed => 'Не удалось добавить в этот список.';

  @override
  String get clubsAddToAList => 'Добавить в список';

  @override
  String get clubsListsLoadError => 'Не удалось загрузить твои списки.';

  @override
  String get clubsNoFilmLists =>
      'У тебя пока нет списков фильмов. Создай первый, чтобы начать собирать.';

  @override
  String get clubsNoBookLists =>
      'У тебя пока нет списков книг. Создай первый, чтобы начать собирать.';

  @override
  String get clubsTitleFallback => 'Произведение';

  @override
  String get clubsSignInToSeeReviews => 'Войди, чтобы видеть отзывы.';

  @override
  String get clubsTitleLoadError => 'Не удалось загрузить произведение';

  @override
  String get clubsReviews => 'Отзывы';

  @override
  String get clubsNoOtherReviewsTitle => 'Других отзывов пока нет';

  @override
  String get clubsNoOtherReviewsMessage =>
      'Когда участники, которых ты видишь, поделятся отзывом, он появится здесь.';

  @override
  String get clubsDeleteReviewTitle => 'Удалить твой отзыв?';

  @override
  String get clubsDeleteReviewMessage =>
      'Твоя оценка и текст будут удалены для всех.';

  @override
  String get clubsDeleteReview => 'Удалить отзыв';

  @override
  String get clubsReviewDeleteFailed =>
      'Не удалось удалить отзыв. Обнови и попробуй снова.';

  @override
  String get clubsWhatDidYouThink => 'Как тебе?';

  @override
  String get clubsReviewPrompt =>
      'Поставь оценку и объясни почему. Ты решаешь, кто это увидит.';

  @override
  String get clubsYourReview => 'Твой отзыв';

  @override
  String get clubsSpoilers => 'Спойлеры';

  @override
  String get clubsEdit => 'Изменить';

  @override
  String get clubsReportReview => 'Пожаловаться на отзыв';

  @override
  String get clubsEnterTitle => 'Введи название.';

  @override
  String get clubsYearRange => 'Введи год от 1450 до 2100.';

  @override
  String get clubsTitleAddFailed => 'Не удалось добавить произведение.';

  @override
  String get clubsSearchFilms => 'Поиск фильмов';

  @override
  String get clubsSearchBooks => 'Поиск книг';

  @override
  String get clubsTypeTwoLetters => 'Введи хотя бы 2 буквы';

  @override
  String get clubsSearchUnavailable => 'Поиск недоступен.';

  @override
  String get clubsNoFilmsMatch => 'Подходящих фильмов нет. Добавь его ниже.';

  @override
  String get clubsNoBooksMatch => 'Подходящих книг нет. Добавь её ниже.';

  @override
  String get clubsAddNewFilm => 'Добавить новый фильм';

  @override
  String get clubsAddNewBook => 'Добавить новую книгу';

  @override
  String get clubsTitleFieldLabel => 'Название';

  @override
  String get clubsDirector => 'Режиссёр';

  @override
  String get clubsAuthor => 'Автор';

  @override
  String get clubsYearOptional => 'Год (необязательно)';

  @override
  String get clubsAdding => 'Добавление…';

  @override
  String get clubsAddAndChoose => 'Добавить и выбрать';

  @override
  String get friendsIntroducerSaveFailed =>
      'Не получилось сохранить. Обнови страницу и проверь актуальные разрешения, прежде чем пробовать снова.';

  @override
  String friendsIntroducerRevokeTitle(String name) {
    return 'Отозвать разрешение у $name?';
  }

  @override
  String get friendsIntroducerRevokeBody =>
      'Новые и неотвеченные знакомства прекратятся. Уже сложившаяся пара останется между двумя людьми.';

  @override
  String get friendsIntroducerKeepPermission => 'Оставить разрешение';

  @override
  String get friendsIntroducerRemovePermission => 'Отозвать разрешение';

  @override
  String get friendsIntroducerPermissionRemoved => 'Разрешение отозвано.';

  @override
  String get friendsIntroducerMemberTitle => 'Твои сводники';

  @override
  String get friendsIntroducerAppTitle => 'Connect · Друзья';

  @override
  String get friendsIntroducerRefresh => 'Обновить разрешения';

  @override
  String get friendsIntroducerAccount => 'Аккаунт';

  @override
  String get friendsIntroducerAccountPrivacy => 'Аккаунт и приватность';

  @override
  String get friendsIntroducerSignOut => 'Выйти';

  @override
  String get friendsIntroducerMemberHeadline => 'Хорошие друзья. Решаешь ты.';

  @override
  String get friendsIntroducerHeadline =>
      'Ты их знаешь.\nТы видишь, что может получиться.';

  @override
  String get friendsIntroducerMemberIntro =>
      'Пригласи того, кому доверяешь, чтобы он тебя знакомил. Анкета для знакомств ему не нужна. Ты решаешь, кто получит разрешение и что видно в превью.';

  @override
  String get friendsIntroducerIntro =>
      'Немного внимания может положить начало чему-то настоящему. Знакомь друзей, которые попросили тебя о помощи.';

  @override
  String get friendsIntroducerMemberListTitle => 'Люди, которых ты выбираешь';

  @override
  String get friendsIntroducerListTitle => 'Твой узкий круг';

  @override
  String get friendsIntroducerLoadFailed =>
      'Не удалось загрузить разрешения. Ничего не изменилось.';

  @override
  String get friendsIntroducerMemberEmpty =>
      'Сводников пока нет. Отправь приглашение одному другу, которому доверяешь, чтобы начать.';

  @override
  String get friendsIntroducerEmpty =>
      'Твой круг начинается с разрешения. Попроси у друга на Connect его код приглашения.';

  @override
  String get friendsIntroducerStatusPendingMember =>
      'Просит разрешения тебя знакомить.';

  @override
  String get friendsIntroducerStatusPending => 'Ждём одобрения твоего друга.';

  @override
  String get friendsIntroducerStatusPaused => 'Знакомства приостановлены.';

  @override
  String get friendsIntroducerStatusActive =>
      'Есть разрешение предлагать знакомства.';

  @override
  String friendsIntroducerPreview(String extras) {
    String _temp0 = intl.Intl.selectLogic(extras, {
      'photo':
          'Превью для предложенного знакомства: имя и, по желанию, возраст, фото.',
      'city':
          'Превью для предложенного знакомства: имя и, по желанию, возраст, город.',
      'both':
          'Превью для предложенного знакомства: имя и, по желанию, возраст, фото, город.',
      'other':
          'Превью для предложенного знакомства: имя и, по желанию, возраст.',
    });
    return '$_temp0';
  }

  @override
  String get friendsIntroducerApproveNote =>
      'Одобрение также включает знакомства через друзей. Все знакомства можно приостановить в разделе «Ритм свиданий».';

  @override
  String get friendsIntroducerAllow => 'Разрешить знакомства';

  @override
  String friendsIntroducerAllowed(String name) {
    return 'Теперь у $name есть твоё разрешение.';
  }

  @override
  String get friendsIntroducerDecline => 'Отклонить запрос';

  @override
  String get friendsIntroducerSentTitle => 'Отправлено с заботой';

  @override
  String get friendsIntroducerSentBody =>
      'Их ответы остаются между ними. Пара складывается, только если оба скажут «да».';

  @override
  String get friendsIntroducerReloadSent =>
      'Перезагрузить отправленные знакомства';

  @override
  String get friendsIntroducerSentSubtitle =>
      'Отправлено · их решение остаётся в тайне';

  @override
  String get friendsIntroducerStepPreview => '1. Выбери превью';

  @override
  String get friendsIntroducerPreviewBody =>
      'Предложенный человек увидит твоё имя и возраст, если ты его уже показываешь. Сводник видит только твоё имя, но не профиль и не твою активность в знакомствах.';

  @override
  String get friendsIntroducerIncludePhoto => 'Показывать фото профиля';

  @override
  String get friendsIntroducerIncludeCity => 'Показывать мой город';

  @override
  String get friendsIntroducerStepInvite =>
      '2. Пригласи друга, которому доверяешь';

  @override
  String get friendsIntroducerInviteBody =>
      'Код срабатывает один раз и действует 48 часов. Друг присоединяется через «Только знакомить друзей» на экране приветствия. Ты подтвердишь его имя здесь, прежде чем что-либо станет доступно.';

  @override
  String get friendsIntroducerInviteReady =>
      'Приглашение готово. Прежние неиспользованные коды больше не работают.';

  @override
  String get friendsIntroducerCreateCode => 'Создать код приглашения';

  @override
  String get friendsIntroducerShareCode =>
      'Отправь его другу лично. Чтобы изменить превью, отмени неиспользованное приглашение и создай новый код.';

  @override
  String get friendsIntroducerCodeCopied => 'Код приглашения скопирован';

  @override
  String get friendsIntroducerCopyCode => 'Скопировать код';

  @override
  String get friendsIntroducerInvitesCancelled =>
      'Неиспользованные приглашения отменены.';

  @override
  String get friendsIntroducerCancelInvites =>
      'Отменить неиспользованные приглашения';

  @override
  String get friendsIntroducerManagePrefs =>
      'Управлять всеми настройками знакомств';

  @override
  String get friendsIntroducerRedeemTitle => 'Тебя пригласил друг?';

  @override
  String get friendsIntroducerRedeemBody =>
      'Вставь личный код приглашения. Друг подтвердит твоё имя, прежде чем ты сможешь его знакомить.';

  @override
  String get friendsIntroducerCodeLabel => 'Код приглашения';

  @override
  String get friendsIntroducerCodeMissing =>
      'Введи код приглашения, который прислал друг.';

  @override
  String get friendsIntroducerRequestSent =>
      'Запрос отправлен. Теперь друг может одобрить тебя в разделе «Твои сводники».';

  @override
  String get friendsIntroducerAskPermission => 'Попросить разрешения';

  @override
  String get friendsIntroducerNeedTwo =>
      'Когда два друга дадут разрешение, здесь можно будет предложить знакомство.';

  @override
  String get friendsIntroducerComposerTitle => 'Видишь возможность?';

  @override
  String get friendsIntroducerWhyLabel =>
      'Почему ты о них подумал(а) (необязательно)';

  @override
  String get friendsIntroducerWhyHelper =>
      'Это увидят оба. Не пиши личных подробностей.';

  @override
  String get friendsIntroducerIntroSent =>
      'Знакомство отправлено. Каждый решит сам и втайне.';

  @override
  String get friendsIntroducerSuggest => 'Предложить знакомство';

  @override
  String get friendsIntroducerPrivacyNote =>
      'Сначала разрешение. Никакой публичной активности в знакомствах. Никаких сообщений о том, кто сказал «да» или «нет».';

  @override
  String get planSharingLoadFailed => 'Не удалось загрузить настройки доступа.';

  @override
  String get planSharingOffSnack => 'Доступ для контактов выключен.';

  @override
  String get planSharingSavedSnack =>
      'Выбранные контакты теперь видят этот план.';

  @override
  String get planSharingSaveFailed =>
      'Не удалось сохранить. Обнови список, прежде чем пробовать снова.';

  @override
  String get planSharingTitle => 'Твой план. Твои люди.';

  @override
  String get planSharingCloseTooltip => 'Закрыть настройки доступа';

  @override
  String get planSharingIntro =>
      'Сначала доступ для контактов выключен. Выбери для этого плана до 10 друзей, которым доверяешь. Твоя пара выбирает свои контакты сама.';

  @override
  String get planSharingNoContacts =>
      'Пока нет подходящих друзей. План по-прежнему доступен тебе и твоей паре.';

  @override
  String get planSharingFriendFallback => 'Друг';

  @override
  String get planSharingPreviewNone => 'Предпросмотр · контакты не выбраны';

  @override
  String planSharingPreviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Предпросмотр · выбрано $count контакта',
      many: 'Предпросмотр · выбрано $count контактов',
      few: 'Предпросмотр · выбрано $count контакта',
      one: 'Предпросмотр · выбран $count контакт',
    );
    return '$_temp0';
  }

  @override
  String get planSharingPreviewOffBody =>
      'Друзья не будут получать от тебя новости о плане и отметках.';

  @override
  String get planSharingPreviewOnBody =>
      'Эти контакты увидят имя твоей пары, время и место, статус плана и твои отметки. Текущий план они получат, когда ты сохранишь.';

  @override
  String get planSharingPrivacyNote =>
      'Сообщения и личные отзывы после свидания остаются приватными. Если убрать контакт, он перестанет получать новости и потеряет доступ к плану в приложении. Уже доставленные на устройство обновления отозвать нельзя.';

  @override
  String get planSharingReload => 'Обновить настройки доступа';

  @override
  String get planSharingSaving => 'Сохранение…';

  @override
  String get planSharingKeepOff => 'Оставить доступ выключенным';

  @override
  String get planSharingShareSelected => 'Поделиться с выбранными';

  @override
  String get planSharingDeselectAll => 'Снять выбор со всех';

  @override
  String planBudgetLine(String budget) {
    return 'Бюджет · $budget';
  }

  @override
  String planAtmosphereLine(String atmospheres) {
    return 'Атмосфера · $atmospheres';
  }

  @override
  String get planAtmosphereQuiet => 'Спокойный разговор';

  @override
  String get planAtmosphereRelaxed => 'Расслабленно и без спешки';

  @override
  String get planAtmosphereLively => 'Оживлённое место';

  @override
  String get planAtmosphereOutdoors => 'На улице';

  @override
  String get planAtmosphereIndoors => 'В помещении';

  @override
  String get planAccessStepFree => 'Вход без ступенек';

  @override
  String get planAccessToilet => 'Доступный туалет';

  @override
  String get planAccessSeating => 'Есть где сесть';

  @override
  String get planAccessLowNoise => 'Мало фонового шума';

  @override
  String get planAccessTransit => 'Рядом с общественным транспортом';

  @override
  String get planAccessCaptions => 'Субтитры на видеосвидании';

  @override
  String get planComfortHeading => 'Чтобы было комфортно';

  @override
  String get planPreferencesDisclaimer =>
      'Пожелания к этому плану. Уточни детали у заведения или видеосервиса.';

  @override
  String get planProposeErrorKept =>
      'Не удалось отправить план. Твой выбор сохранён.';

  @override
  String get planChangedError =>
      'План изменился. Закрой это окно, чтобы посмотреть переписку.';

  @override
  String get planProposeHeadline => 'План, которого ждёте вы оба.';

  @override
  String get planCounterHeadline => 'Доработайте план вместе';

  @override
  String planProposeLead(String name) {
    return 'Предложение для тебя и $name. Ничего не решено, пока другой человек не примет эту версию.';
  }

  @override
  String get planFindTimeTitle => 'Найдите время друг для друга';

  @override
  String get planFindTimeBody =>
      'Общее время показывается, только если вы оба делитесь своей доступностью. Ты всегда можешь предложить своё время.';

  @override
  String get planSharedTimesFailed =>
      'Не удалось загрузить общее время. Выбрать время вручную по-прежнему можно.';

  @override
  String get planSharedTimesEmpty =>
      'Пока нет общих вариантов времени. Это не значит, что кто-то из вас занят.';

  @override
  String get planRefreshSharedTimes => 'Обновить общее время';

  @override
  String get planSetAvailability => 'Указать моё свободное время';

  @override
  String get planWhenTitle => 'Когда было бы удобно?';

  @override
  String get planTimeSourceManual => 'Время, которое предлагаешь ты';

  @override
  String get planTimeSourceShared =>
      'Выбрано из общего свободного времени · проверим ещё раз при отправке';

  @override
  String planLocalTimeNote(int minutes, String timeZone) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Местное время на устройстве ($timeZone). Длительность: $minutes минуты.',
      many:
          'Местное время на устройстве ($timeZone). Длительность: $minutes минут.',
      few:
          'Местное время на устройстве ($timeZone). Длительность: $minutes минуты.',
      one:
          'Местное время на устройстве ($timeZone). Длительность: $minutes минута.',
    );
    return '$_temp0';
  }

  @override
  String planDurationChip(int minutes) {
    return '$minutes мин';
  }

  @override
  String get planEnjoyTitle => 'Что-то, что тебе понравится';

  @override
  String get planAreaHint => 'Район или людное место для встречи';

  @override
  String get planBudgetTitle => 'Какой бюджет тебе комфортен?';

  @override
  String get planBudgetBody =>
      'Ориентир, о котором вы договоритесь вместе, а не цена и не обещание, кто платит.';

  @override
  String get planAtmosphereTitle => 'Выбери атмосферу';

  @override
  String get planAtmosphereBody =>
      'Выбери до трёх вариантов, которые тебе по душе. Необязательно.';

  @override
  String get planComfortTitle => 'Чтобы обоим было комфортно';

  @override
  String get planComfortBody =>
      'Необязательные пожелания по доступности. Выбранное увидит твой мэтч, когда ты отправишь план. Это не попадёт ни в публичный профиль, ни в обновления для доверенных контактов.';

  @override
  String get planComfortDisclaimer =>
      'Объяснять диагноз не нужно. Это пожелания, которые стоит уточнить у заведения или видеосервиса, а не проверенные удобства.';

  @override
  String get planNoteHint => 'В субботу днём, где-нибудь потише?';

  @override
  String get planReviewBeforeSending =>
      'Перед отправкой проверь время и выбранные варианты. Другой человек может принять, отклонить или предложить изменения.';

  @override
  String get planReloadLatest => 'Загрузить последнюю версию · отменить правки';

  @override
  String get planSending => 'Отправка…';

  @override
  String get planSendSuggestion => 'Отправить предложение';

  @override
  String get planSecondYesTitle => 'Сказать «да» ещё раз';

  @override
  String get planSecondYesBody =>
      'Покажи, что хочешь встретиться снова, — только если твой мэтч тоже скажет «да» и согласится поделиться. Остальные ответы останутся приватными.';

  @override
  String get planSecondYesHeadline => 'Второе «да» от вас обоих';

  @override
  String get planSecondYesCardBody =>
      'Вы оба решили сказать, что хотите встретиться снова.';

  @override
  String get planAnotherHello => 'Запланировать новую встречу';

  @override
  String get planSuggestChange => 'Предложить изменения';

  @override
  String get planChooseUpdates => 'Выбрать, кто получает твои новости';

  @override
  String planQuotedNote(String note) {
    return '«$note»';
  }

  @override
  String get planStatusDeclined => 'Отклонён';

  @override
  String get planStatusExpired => 'Истёк';

  @override
  String get planStatusCompleted => 'Завершён';

  @override
  String get planStatusDidNotHappen => 'Не состоялся';

  @override
  String get planStatusDisputed => 'Оспаривается';

  @override
  String get plansManageSharing => 'Настроить доступ для контактов';

  @override
  String get plansLoadFailed => 'Не удалось загрузить планы свиданий.';

  @override
  String get plansFeedLoadFailed => 'Не удалось загрузить планы.';

  @override
  String get planAcceptFailed => 'Не удалось принять этот план.';

  @override
  String get planDeclineFailed => 'Не удалось отклонить этот план.';

  @override
  String get planCancelFailed => 'Не удалось отменить этот план.';

  @override
  String get planCheckinFailed => 'Сейчас не получается отметиться.';

  @override
  String get graduationFoundEachOther => 'Вы нашли друг друга';

  @override
  String graduationHeadlineDecide(String name) {
    return '$name хочет уйти из Connect вместе с тобой';
  }

  @override
  String graduationHeadlineWaiting(String name) {
    return 'Ждём, когда $name ответит';
  }

  @override
  String get graduationBodyConfirmed =>
      'Вы оба скрыты из поиска. Этот чат остаётся открытым.';

  @override
  String get graduationBodyDecide =>
      'Подтверди — и вы оба исчезнете из поиска. Чат останется.';

  @override
  String get graduationBodyWaiting =>
      'Твоё предложение уйти вместе отправлено. Другой человек может подтвердить или отказаться.';

  @override
  String get graduationCelebrate => 'Отпраздновать';

  @override
  String get graduationNotYet => 'Пока нет';

  @override
  String get graduationConfirm => 'Подтвердить';

  @override
  String get graduationFriendsToldOnConfirm =>
      'Друзья узнают, когда другой человек подтвердит.';

  @override
  String get graduationOnlyTwoOfYouForNow =>
      'Пока об этом знаете только вы двое.';

  @override
  String get graduationWithdraw => 'Отозвать';

  @override
  String graduationProposeTitle(String name) {
    return 'Ты и $name уходите из Connect?';
  }

  @override
  String graduationProposeBody(String name) {
    return 'Как только $name подтвердит, вы оба будете скрыты из поиска. Этот чат останется открытым, а вернуться в поиск можно в любой момент в разделе «Приватность и безопасность».';
  }

  @override
  String get graduationNoteLabel => 'Сообщение для пары (необязательно)';

  @override
  String get graduationNoteHint => 'Расскажи, почему сейчас самое время';

  @override
  String get graduationTellFriends => 'Рассказать друзьям';

  @override
  String get graduationTellFriendsBody =>
      'Друзья узнают, что у тебя кто-то появился, но не узнают, кто именно.';

  @override
  String get graduationAskThem => 'Спросить';

  @override
  String get graduationTitle => 'Уходим вдвоём';

  @override
  String graduationCelebrationBody(String name) {
    return 'Ты и $name вместе уходите из Connect. Вы оба скрыты из поиска, а этот чат останется открытым сколько угодно.';
  }

  @override
  String get graduationFriendsHaveBeenTold => 'Друзья уже в курсе.';

  @override
  String get graduationFriendsAreTold => 'Друзья узнают об этом.';

  @override
  String get graduationOnlyTwoOfYou => 'Об этом знаете только вы двое.';

  @override
  String get graduationConfirmAndBack => 'Подтвердить и вернуться';

  @override
  String get graduationBackToConnect => 'Вернуться в Connect';

  @override
  String get graduationLoadFailed =>
      'Не удалось загрузить данные об уходе вдвоём.';

  @override
  String get graduationProposeFailed => 'Не удалось предложить уйти вместе.';

  @override
  String get graduationConfirmFailed => 'Сейчас не получается подтвердить.';

  @override
  String get graduationDeclineFailed => 'Сейчас не получается отказаться.';

  @override
  String get graduationWithdrawFailed => 'Не удалось отозвать предложение.';

  @override
  String get graduationPauseLoadFailed => 'Не удалось загрузить статус поиска.';

  @override
  String get graduationPauseFailed => 'Не удалось приостановить поиск.';

  @override
  String get graduationResumeFailed => 'Не удалось возобновить поиск.';

  @override
  String get engagementCirclesEmptyTitle => 'Нет доступных кругов';

  @override
  String get engagementCirclesPullToRefresh => 'Потяни вниз, чтобы обновить.';

  @override
  String get engagementCirclesJoined => 'Ты в круге';

  @override
  String get engagementCirclesNotJoined => 'Не в круге';

  @override
  String engagementCirclesParticipants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count участника на этой неделе',
      many: '$count участников на этой неделе',
      few: '$count участника на этой неделе',
      one: '$count участник на этой неделе',
    );
    return '$_temp0';
  }

  @override
  String get engagementCirclesJoin => 'Вступить в круг';

  @override
  String get engagementCirclesResponseLabel => 'Ответ на челлендж недели';

  @override
  String get engagementCirclesSubmit => 'Отправить ответ';

  @override
  String get engagementCirclesTopicFallback => 'Круг';

  @override
  String get engagementCirclesLoadFailed =>
      'Сейчас не удаётся загрузить круги.';

  @override
  String get engagementCirclesJoinFailed =>
      'Сейчас не удаётся вступить в круг.';

  @override
  String get engagementCirclesEnterResponse => 'Напиши ответ на челлендж.';

  @override
  String get engagementCirclesSubmitFailed =>
      'Сейчас не удаётся отправить ответ.';

  @override
  String get engagementNudgesTitle => 'Напоминания парам';

  @override
  String get engagementNudgesIntro =>
      'Отправь мягкое напоминание, чтобы оживить затихший разговор. Дневные лимиты и правила безопасности соблюдаются на сервере.';

  @override
  String get engagementNudgesEmpty => 'Нет пар для напоминания.';

  @override
  String get engagementNudgesSentInSession =>
      'Напоминание отправлено в этом сеансе';

  @override
  String get engagementNudgesReady => 'Можно отправить';

  @override
  String engagementNudgesSentTo(String name) {
    return 'Напоминание отправлено: $name.';
  }

  @override
  String get engagementNudgesAction => 'Напомнить';

  @override
  String get engagementNudgesSendFailed => 'Не удалось отправить напоминание.';

  @override
  String get engagementTrustBadgesEarned => 'Полученные значки';

  @override
  String get engagementTrustBadgesEmpty =>
      'Значков пока нет. Выполняй активности, чтобы открыть значки доверия.';

  @override
  String engagementTrustBadgesDetails(
    String code,
    String status,
    String awardedAt,
  ) {
    return 'Код: $code\nСтатус: $status • Получен $awardedAt';
  }

  @override
  String get engagementTrustBadgesHistory => 'Недавняя история';

  @override
  String get engagementTrustBadgesHistoryEmpty => 'Истории доверия пока нет.';

  @override
  String get engagementTrustBadgesMilestoneUnavailable =>
      'Статус этапа недоступен.';

  @override
  String get engagementTrustBadgesCurrentMilestone => 'Текущий этап';

  @override
  String get engagementTrustBadgesLoadFailed =>
      'Не удалось загрузить значки доверия. Попробуй ещё раз.';

  @override
  String get engagementTrustFiltersEnable => 'Включить фильтры доверия';

  @override
  String get engagementTrustFiltersEnableSubtitle =>
      'Скрывать профили, которые не соответствуют твоим требованиям доверия';

  @override
  String engagementTrustFiltersMinimum(int count) {
    return 'Минимум активных значков: $count';
  }

  @override
  String get engagementTrustFiltersRequired => 'Обязательные значки';

  @override
  String get engagementTrustFiltersSaved => 'Фильтры доверия сохранены.';

  @override
  String get engagementTrustFiltersSave => 'Сохранить фильтры доверия';

  @override
  String get engagementAppealStatusSubmitted => 'Отправлено';

  @override
  String get engagementAppealStatusUnderReview => 'На рассмотрении';

  @override
  String get engagementAppealStatusResolvedUpheld =>
      'Рассмотрено (решение оставлено)';

  @override
  String get engagementAppealStatusResolvedReversed =>
      'Рассмотрено (решение отменено)';

  @override
  String get engagementRoomsLeaveFailed =>
      'Не удалось выйти из комнаты. Попробуй ещё раз.';

  @override
  String get engagementRoomsPresenceFailed => 'Связь с комнатой потеряна.';

  @override
  String get engagementRoomsMembersFailed =>
      'Не удалось загрузить, кто здесь. Попробуй ещё раз.';

  @override
  String get engagementRoomsModerationFailed =>
      'Не получилось. Попробуй ещё раз.';

  @override
  String get engagementRoomsCreateFailed =>
      'Не удалось открыть комнату. Попробуй ещё раз.';

  @override
  String get engagementRoomsLoadFailed =>
      'Комнаты сейчас недоступны. Потяни вниз, чтобы повторить.';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonRemove => 'Удалить';

  @override
  String get accountTitle => 'Аккаунт и данные';

  @override
  String get accountLoadFailed => 'Не удалось загрузить статус аккаунта.';

  @override
  String accountDeletionIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Удаление через $days дней',
      few: 'Удаление через $days дня',
      one: 'Удаление через $days день',
    );
    return '$_temp0';
  }

  @override
  String get accountDeletionDue => 'Удаление вот-вот произойдёт';

  @override
  String get accountDeletionCountdownBody =>
      'Твой профиль скрыт. До этого момента можно войти и отменить удаление — после этого данные восстановить нельзя.';

  @override
  String get accountKeepMyAccount => 'Сохранить аккаунт';

  @override
  String get accountNotDeletedSnack => 'Твой аккаунт не будет удалён.';

  @override
  String get accountCancelFailed => 'Не удалось отменить. Попробуйте ещё раз.';

  @override
  String get accountHiddenTitle => 'Твой профиль скрыт';

  @override
  String get accountTakeBreakTitle => 'Сделайте перерыв';

  @override
  String get accountHiddenBody =>
      'Никто не может видеть тебя или создать с тобой мэтч. Твои мэтчи и сообщения сохраняются, и ты можешь вернуться в любой момент.';

  @override
  String get accountTakeBreakBody =>
      'Скрой профиль из раздела «Знакомства», ничего не теряя. Ты останешься в аккаунте и сможешь вернуться в любой момент.';

  @override
  String get accountUnhideProfile => 'Показать мой профиль';

  @override
  String get accountHideProfile => 'Скрыть мой профиль';

  @override
  String get accountVisibleAgainSnack => 'Твой профиль снова виден.';

  @override
  String get accountNowHiddenSnack => 'Твой профиль теперь скрыт.';

  @override
  String get accountUpdateFailed => 'Не удалось обновить. Попробуйте ещё раз.';

  @override
  String get accountDownloadTitle => 'Скачать твои данные';

  @override
  String get accountDownloadBody =>
      'Получи копию профиля, предпочтений, мэтчей и своих отправленных сообщений. Сообщения других людей не включаются.';

  @override
  String get accountPreparing => 'Подготовка…';

  @override
  String get accountPrepareData => 'Подготовить мои данные';

  @override
  String get accountPrepareFailed =>
      'Не удалось подготовить данные. Попробуйте ещё раз.';

  @override
  String get accountYourData => 'Твои данные';

  @override
  String get accountDeleteTitle => 'Удалить мой аккаунт';

  @override
  String get accountDeleteBody =>
      'Твой профиль сразу скрывается, а после льготного периода всё удаляется. В это время можно войти и отменить удаление. После этого ничего восстановить нельзя.';

  @override
  String get accountDeletionAlreadyScheduled => 'Удаление уже запланировано';

  @override
  String get accountDeleteConfirmTitle => 'Удалить аккаунт?';

  @override
  String get accountDeleteConfirmBody =>
      'Твой профиль, фото, мэтчи и сообщения будут удалены без возможности восстановления.\n\nЕсли тебе нужен просто перерыв, скрой профиль — всё сохранится, и это можно отменить.';

  @override
  String get accountHideInstead => 'Лучше скрыть';

  @override
  String get accountDeletionScheduledSnack =>
      'Удаление запланировано. До этого момента его можно отменить.';

  @override
  String get privacyTitle => 'Конфиденциальность и безопасность';

  @override
  String get privacyShowAge => 'Показывать возраст';

  @override
  String get privacyShowAgeSubtitle => 'Управляй видимостью своего возраста';

  @override
  String get privacyShowDistance => 'Показывать точное расстояние';

  @override
  String get privacyShowDistanceSubtitle =>
      'Показывать точное расстояние в профиле';

  @override
  String get privacyShowOnline => 'Показывать статус «в сети»';

  @override
  String get privacyShowOnlineSubtitle =>
      'Разрешить другим видеть, что ты в сети';

  @override
  String get privacyEmergencySos => 'Экстренный SOS';

  @override
  String get privacyEmergencySosSubtitle =>
      'Отправить сигнал тревоги и посмотреть историю';

  @override
  String get privacyEmergencyContacts => 'Экстренные контакты';

  @override
  String get privacyEmergencyContactsSubtitle =>
      'Управление доверенными контактами';

  @override
  String get privacyBlockedUsers => 'Заблокированные';

  @override
  String get privacyBlockedUsersSubtitle => 'Просмотр и разблокировка';

  @override
  String get privacyModerationAppeals => 'Апелляции модерации';

  @override
  String get privacyModerationAppealsSubtitle =>
      'Подать апелляцию и следить за её рассмотрением';

  @override
  String get privacyFriendSearch => 'Показывать меня в поиске друзей';

  @override
  String get privacySettingLoadFailed =>
      'Не удалось загрузить настройку. Откройте страницу снова, чтобы повторить попытку.';

  @override
  String get privacyFriendSearchSubtitle =>
      'Участники могут найти тебя по имени или @имени пользователя в разделе «Добавить друга». Люди, с которыми у тебя мэтч или с которыми ты встречался(-ась) в комнатах и группах, всё равно смогут тебя добавить.';

  @override
  String get privacyChoiceSaveFailed => 'Не удалось сохранить твой выбор.';

  @override
  String get privacyShowcase => 'Показывать мои публичные записи в профиле';

  @override
  String get privacyShowcaseSubtitle =>
      'Участники увидят в твоём профиле главы, которыми ты делишься с сообществом, и твои фото на стене. Личные главы и главы только для друзей не отображаются.';

  @override
  String get privacyCrashReports => 'Отправлять отчёты о сбоях';

  @override
  String get privacyCrashReportsSubtitle =>
      'Анонимные отчёты о сбоях и ошибках помогают нам исправлять проблемы. Сообщения, фото и данные аккаунта не передаются.';

  @override
  String get privacyGraduatedReason =>
      'Ты и твой мэтч вместе ушли из Connect. Твою карточку никому не показывают.';

  @override
  String get privacyPausedReason =>
      'Твою карточку никому не показывают, пока ты не возобновишь поиск.';

  @override
  String get privacyActiveReason =>
      'Тебя показывают другим участникам в подборке.';

  @override
  String get privacyDiscoveryPaused => 'Подбор приостановлен';

  @override
  String get privacyDiscoveryActive => 'Подбор активен';

  @override
  String get privacyResume => 'Возобновить';

  @override
  String get privacyPause => 'Приостановить';

  @override
  String get emergencyIntro =>
      'Добавьте до 3 доверенных контактов. Позже они будут использоваться для функций безопасности и SOS.';

  @override
  String get emergencyEmpty => 'Экстренные контакты пока не добавлены.';

  @override
  String get emergencyMaxReached => 'Добавлено максимум контактов';

  @override
  String get emergencyAddContact => 'Добавить контакт';

  @override
  String get emergencyEditContact => 'Изменить контакт';

  @override
  String get emergencyInvalidInput =>
      'Введите корректные имя и номер телефона.';

  @override
  String get emergencyAdded => 'Экстренный контакт добавлен.';

  @override
  String get emergencyAddFailed =>
      'Не удалось добавить контакт. Попробуйте ещё раз.';

  @override
  String get emergencyUpdated => 'Экстренный контакт обновлён.';

  @override
  String get emergencyUpdateFailed =>
      'Не удалось обновить контакт. Попробуйте ещё раз.';

  @override
  String get emergencyRemoveTitle => 'Удалить контакт';

  @override
  String emergencyRemoveBody(String name) {
    return 'Удалить $name из экстренных контактов?';
  }

  @override
  String get emergencyRemoved => 'Экстренный контакт удалён.';

  @override
  String get emergencyRemoveFailed =>
      'Не удалось удалить контакт. Попробуйте ещё раз.';

  @override
  String get emergencyNameLabel => 'Имя';

  @override
  String get emergencyPhoneLabel => 'Номер телефона';

  @override
  String get appealsSubmitTitle => 'Подать апелляцию';

  @override
  String get appealsReasonLabel => 'Причина';

  @override
  String get appealsReasonHint =>
      'Почему это решение модерации нужно пересмотреть?';

  @override
  String get appealsReportIdLabel => 'ID жалобы (необязательно)';

  @override
  String get appealsContextLabel => 'Дополнительная информация (необязательно)';

  @override
  String get appealsSubmit => 'Отправить апелляцию';

  @override
  String get appealsEmpty =>
      'Апелляций пока нет. Твои апелляции появятся здесь вместе с их статусом.';

  @override
  String appealsIdLine(String id) {
    return 'ID апелляции: $id';
  }

  @override
  String appealsSlaLine(String deadline) {
    return 'Срок рассмотрения: $deadline';
  }

  @override
  String appealsReviewedBy(String reviewer) {
    return 'Рассмотрено: $reviewer';
  }

  @override
  String get appealsReasonRequired => 'Укажите причину.';

  @override
  String get appealsSubmitted => 'Апелляция отправлена.';

  @override
  String get appealsSubmitFailed =>
      'Не удалось отправить апелляцию. Попробуйте ещё раз.';

  @override
  String get blockedEmpty => 'Заблокированных пока нет.';

  @override
  String get blockedUnblock => 'Разблокировать';

  @override
  String get blockedUnblockTitle => 'Разблокировать пользователя';

  @override
  String blockedUnblockBody(String name) {
    return 'Разблокировать $name?';
  }

  @override
  String blockedUnblockedSnack(String name) {
    return '$name: блокировка снята.';
  }

  @override
  String get blockedUnblockFailed =>
      'Не удалось разблокировать. Попробуйте ещё раз.';

  @override
  String aboutVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get aboutDescription =>
      'Приложение для знакомств, где главное — доверие: настоящие профили, безопасное общение и серьёзные отношения.';

  @override
  String get aboutStack => 'Технологии';

  @override
  String get aboutStackFlutter => 'Flutter (в первую очередь Android)';

  @override
  String get aboutStackGo => 'Сервисы на Go + нативный PostgreSQL';

  @override
  String get aboutStackRiverpod => 'Управление состоянием на Riverpod';

  @override
  String get communitySpoiler => 'Спойлер — нажмите, чтобы показать';

  @override
  String get communityReportFailed => 'Не удалось отправить жалобу.';

  @override
  String get communityReportSubmitted => 'Жалоба отправлена. Спасибо.';

  @override
  String communityBlockTitle(String name) {
    return 'Заблокировать $name?';
  }

  @override
  String get communityBlockBody =>
      'Вы перестанете видеть фото, посты в клубах, отзывы и списки друг друга. Также блокируется связь через Connect.';

  @override
  String get communityBlockAction => 'Заблокировать';

  @override
  String get communityBlockFailed =>
      'Не удалось заблокировать участника. Повторите попытку.';

  @override
  String get reportSheetTitle => 'Пожаловаться';

  @override
  String get reportReasonHarassment => 'Домогательства';

  @override
  String get reportReasonInappropriate => 'Неприемлемый контент';

  @override
  String get reportReasonFraud => 'Мошенничество';

  @override
  String get reportReasonFake => 'Фейковый профиль';

  @override
  String get reportReasonLabel => 'Причина';

  @override
  String get reportDescriptionLabel => 'Описание (необязательно)';

  @override
  String get reportDescriptionHint =>
      'Добавьте подробности, чтобы помочь рассмотреть жалобу';

  @override
  String get reportSubmitFailed =>
      'Не удалось отправить жалобу. Попробуйте ещё раз.';

  @override
  String get reportSubmit => 'Отправить жалобу';

  @override
  String get membershipTitle => 'Подписка';

  @override
  String get membershipChooseYourPlan => 'Выбери тариф';

  @override
  String get membershipCycleNoteMonthly =>
      'Оплата картой. Продлевается автоматически каждый месяц, пока ты не отключишь автопродление.';

  @override
  String get membershipCycleNoteYearly =>
      'Оплата картой. Продлевается автоматически каждый год, пока ты не отключишь автопродление.';

  @override
  String get membershipNoPlansOnSale => 'Сейчас нет доступных тарифов.';

  @override
  String get membershipPaymentsTitle => 'Платежи';

  @override
  String get membershipNoCardPayments => 'Платежей картой пока нет.';

  @override
  String get membershipFooterNote =>
      'Тариф автоматически продлевается в конце каждого расчётного периода. Отключить автопродление можно в любой момент — преимущества сохранятся до конца периода. Данные карты обрабатывает платёжный провайдер, в приложении они никогда не хранятся.';

  @override
  String membershipSwitchTitle(String plan) {
    return 'Перейти на $plan?';
  }

  @override
  String membershipSwitchUpgradeBodyMonthly(String price) {
    return 'Сейчас с карты спишется разница за остаток текущего периода, а со следующего продления — $price в месяц.';
  }

  @override
  String membershipSwitchUpgradeBodyYearly(String price) {
    return 'Сейчас с карты спишется разница за остаток текущего периода, а со следующего продления — $price в год.';
  }

  @override
  String membershipSwitchDowngradeBodyMonthly(
    String currentPlan,
    String price,
  ) {
    return 'Тариф сменится сейчас. Неиспользованное время по тарифу $currentPlan будет зачтено в следующее продление, затем ты будешь платить $price в месяц.';
  }

  @override
  String membershipSwitchDowngradeBodyYearly(String currentPlan, String price) {
    return 'Тариф сменится сейчас. Неиспользованное время по тарифу $currentPlan будет зачтено в следующее продление, затем ты будешь платить $price в год.';
  }

  @override
  String get membershipNotNow => 'Не сейчас';

  @override
  String get membershipUpgrade => 'Повысить тариф';

  @override
  String get membershipSwitchPlan => 'Сменить тариф';

  @override
  String membershipSwitchedSnack(String plan) {
    return 'Теперь у тебя тариф $plan.';
  }

  @override
  String get membershipCardUpdated => 'Карта обновлена.';

  @override
  String get membershipCardUpdatePending =>
      'Обновление карты ещё не подтверждено. Проверь статус, прежде чем пробовать снова.';

  @override
  String get membershipCardUpdateEnded =>
      'Сеанс обновления карты завершён. Обнови экран, чтобы увидеть текущую карту.';

  @override
  String get membershipCheckoutTitleCard => 'карта';

  @override
  String get membershipAutoRenewOffTitle => 'Отключить автопродление?';

  @override
  String membershipAutoRenewOffBodyDate(String plan, String date) {
    return 'Преимущества тарифа $plan действуют до $date. После этого ты перейдёшь на бесплатный тариф, и с карты больше ничего не спишется.';
  }

  @override
  String membershipAutoRenewOffBodyPeriodEnd(String plan) {
    return 'Преимущества тарифа $plan действуют до конца текущего периода. После этого ты перейдёшь на бесплатный тариф, и с карты больше ничего не спишется.';
  }

  @override
  String get membershipKeepRenewing => 'Оставить автопродление';

  @override
  String get membershipTurnOff => 'Отключить';

  @override
  String get membershipAutoRenewBackOn => 'Автопродление снова включено.';

  @override
  String get membershipAutoRenewNowOff =>
      'Автопродление отключено. Преимущества сохранятся до конца периода.';

  @override
  String membershipSubscribeTitle(String plan) {
    return 'Оформить $plan';
  }

  @override
  String membershipSubscribeBodyMonthly(String price) {
    return '$price в месяц: списывается с карты и продлевается автоматически, пока ты не отключишь автопродление. Данные карты ты введёшь на защищённой странице платёжного провайдера.';
  }

  @override
  String membershipSubscribeBodyYearly(String price) {
    return '$price в год: списывается с карты и продлевается автоматически, пока ты не отключишь автопродление. Данные карты ты введёшь на защищённой странице платёжного провайдера.';
  }

  @override
  String membershipSubscribeBodyTestMonthly(String price) {
    return 'Только тестовая оплата — реального списания нет. $price в месяц: списание имитируется и продлевается автоматически, пока ты не отключишь автопродление. Данные карты ты введёшь на защищённой странице платёжного провайдера.';
  }

  @override
  String membershipSubscribeBodyTestYearly(String price) {
    return 'Только тестовая оплата — реального списания нет. $price в год: списание имитируется и продлевается автоматически, пока ты не отключишь автопродление. Данные карты ты введёшь на защищённой странице платёжного провайдера.';
  }

  @override
  String get membershipContinueToCard => 'Перейти к вводу карты';

  @override
  String get paymentStillConfirming =>
      'Платёж ещё подтверждается. Чуть позже потяни вниз, чтобы обновить.';

  @override
  String get membershipCheckoutEnded =>
      'Сеанс оплаты завершён. Обнови историю платежей, прежде чем пробовать снова.';

  @override
  String get membershipRecoverAccountUnavailable =>
      'Не удалось проверить платёжный аккаунт. Попробуй ещё раз.';

  @override
  String get membershipRecoverCheckoutClosed =>
      'Платёжный аккаунт обновлён. Эта оплата больше не активна.';

  @override
  String get membershipRecoverConfirmed =>
      'Подтверждено. Платёжный аккаунт в актуальном состоянии.';

  @override
  String get membershipRecoverPending =>
      'Подтверждение ещё не получено. Здесь можно проверить снова.';

  @override
  String get membershipRecoverEnded =>
      'Сеанс оплаты завершён. Проверь историю платежей, прежде чем начинать новую оплату.';

  @override
  String membershipCelebrateTitle(String plan) {
    return 'Теперь у тебя $plan';
  }

  @override
  String get membershipCelebrateBodyTest =>
      'Тестовый платёж подтверждён, реальные деньги не списаны. Тестовый тариф продлевается автоматически. Управлять автопродлением можно в любой момент на этом экране.';

  @override
  String get membershipCelebrateBody =>
      'Платёж подтверждён. Тариф продлевается автоматически. Управлять автопродлением можно в любой момент на этом экране.';

  @override
  String get membershipStartExploring => 'Начать знакомиться';

  @override
  String get membershipYourMembership => 'Твоя подписка';

  @override
  String get membershipYourPlan => 'Твой тариф';

  @override
  String get membershipFreePlanName => 'Бесплатный';

  @override
  String membershipPricePerMonthShort(String price) {
    return '$price/мес.';
  }

  @override
  String membershipPricePerYearShort(String price) {
    return '$price/год';
  }

  @override
  String get membershipCardOnFile => 'Карта сохранена у платёжного провайдера';

  @override
  String get membershipCardBrandFallback => 'Карта';

  @override
  String get paymentOpening => 'Открываем…';

  @override
  String get membershipUpdateCard => 'Сменить карту';

  @override
  String get membershipLastPaymentFailed =>
      'Последний платёж не прошёл. Мы ещё раз попробуем списать оплату с карты; преимущества сохранятся ещё несколько дней.';

  @override
  String membershipRenewsOn(String date) {
    return 'Продление $date';
  }

  @override
  String get membershipRenewsSoon => 'Скоро продление';

  @override
  String membershipEndsOn(String date) {
    return 'Заканчивается $date · автопродление отключено';
  }

  @override
  String get membershipEndsSoon =>
      'Скоро заканчивается · автопродление отключено';

  @override
  String get membershipAutoRenew => 'Автопродление';

  @override
  String get membershipAutoRenewOnSubtitle =>
      'Списывается автоматически каждый период.';

  @override
  String get membershipAutoRenewOffSubtitle =>
      'Отключено. Преимущества закончатся вместе с текущим периодом.';

  @override
  String get membershipFreeHeroBody =>
      'Больше лайков, сообщений и показов в центре внимания — с тарифом ниже. Оплата картой, отмена в любой момент.';

  @override
  String get membershipStatusFree => 'Бесплатно';

  @override
  String get membershipStatusPaymentDue => 'Ожидает оплаты';

  @override
  String get membershipStatusEnding => 'Заканчивается';

  @override
  String get membershipStatusActive => 'Активна';

  @override
  String get membershipCycleMonthly => 'Помесячно';

  @override
  String get membershipCycleYearly => 'Годовой';

  @override
  String get membershipBadgeYourPlan => 'ТВОЙ ТАРИФ';

  @override
  String get membershipBadgeMostPopular => 'САМЫЙ ПОПУЛЯРНЫЙ';

  @override
  String get membershipPerMonth => 'в месяц';

  @override
  String get membershipPerYear => 'в год';

  @override
  String membershipSavePercent(int percent) {
    return 'Экономия $percent%';
  }

  @override
  String membershipQuotaLikesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count лайка/день',
      many: '$count лайков/день',
      few: '$count лайка/день',
      one: '$count лайк/день',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сообщения/день',
      many: '$count сообщений/день',
      few: '$count сообщения/день',
      one: '$count сообщение/день',
    );
    return '$_temp0';
  }

  @override
  String get membershipQuotaUnlimitedLikes => 'Безлимитные лайки';

  @override
  String get membershipQuotaUnlimitedMessages => 'Безлимитные сообщения';

  @override
  String get membershipYourCurrentPlan => 'Твой текущий тариф';

  @override
  String get membershipSwitching => 'Меняем тариф…';

  @override
  String get membershipOpeningSecureCheckout => 'Открываем защищённую оплату…';

  @override
  String membershipSwitchToPlan(String plan) {
    return 'Перейти на $plan';
  }

  @override
  String get membershipSubscribeWithCard => 'Оформить с оплатой картой';

  @override
  String get membershipSettleBeforeSwitch =>
      'Перед сменой тарифа погаси задолженность по текущему тарифу.';

  @override
  String get membershipPaymentChargeback => 'Возврат по спору';

  @override
  String get membershipPaymentDisputed => 'Оспорен';

  @override
  String get membershipPaymentRefunded => 'Возвращён';

  @override
  String get membershipPaymentPartlyRefunded => 'Частично возвращён';

  @override
  String get membershipPaymentFailed => 'Не прошёл';

  @override
  String get membershipPaymentPaid => 'Оплачен';

  @override
  String get membershipPaymentPending => 'В обработке';

  @override
  String get membershipPaymentReasonFirstCharge => 'Первое списание';

  @override
  String get membershipPaymentReasonRenewal => 'Продление';

  @override
  String get membershipPaymentReasonPlanChange => 'Смена тарифа';

  @override
  String get membershipPaymentReasonCoins => 'Монеты';

  @override
  String get membershipPaymentReasonLocalActivation => 'Локальная активация';

  @override
  String get membershipPaymentReasonCard => 'Оплата картой';

  @override
  String get membershipPaymentReasonOther => 'Платёж';

  @override
  String get paymentModeSandbox => 'Локальный тест · без реального списания';

  @override
  String get paymentModeStripeTest => 'Тест Stripe · без реального списания';

  @override
  String get paymentModeLive => 'Реальные платежи';

  @override
  String get paymentModeUnavailable => 'Платежи недоступны';

  @override
  String get paymentAccountTitle => 'Твой платёжный аккаунт';

  @override
  String get paymentAccountSignedInMember => 'Вошедший участник';

  @override
  String get paymentAccountCardTitle => 'Кредитная или дебетовая карта';

  @override
  String get paymentAccountCardUnavailableTitle => 'Оплата картой недоступна';

  @override
  String get paymentAccountCardBody =>
      'Введи данные карты на странице оплаты провайдера. Подписка и история платежей привязаны к этому аккаунту.';

  @override
  String get paymentAccountCardUnavailableBody =>
      'Ты можешь и дальше пользоваться своим аккаунтом. Новые платежи картой не включены.';

  @override
  String paymentAccountTestCardHint(String cardNumber) {
    return 'Для теста используй $cardNumber, любой будущий срок действия и любой трёхзначный CVC. Используй только тестовые данные.';
  }

  @override
  String get paymentAccountUnfinishedCardUpdate =>
      'Незавершённое обновление карты';

  @override
  String paymentAccountUnfinishedCheckout(String plan) {
    return 'Незавершённая оплата: $plan';
  }

  @override
  String get paymentAccountPendingHint =>
      'Проверь последний статус или продолжи ту же оплату.';

  @override
  String get paymentAccountCheckStatus => 'Проверить статус';

  @override
  String get paymentAccountResumeCheckout => 'Продолжить оплату';

  @override
  String paymentCheckoutPayFor(String title) {
    return 'Оплата: $title';
  }

  @override
  String get paymentCheckoutClose => 'Закрыть оплату';

  @override
  String get paymentCheckoutSecureNote =>
      'Данные карты вводятся на защищённой странице платёжного провайдера.';

  @override
  String paymentCheckoutCompleteInNewTab(String title) {
    return 'Заверши оплату ($title) в новой вкладке';
  }

  @override
  String get paymentCheckoutWaitingBody =>
      'Данные карты вводятся на защищённой странице платёжного провайдера. Вернись сюда, когда там будет написано, что оплата завершена.';

  @override
  String get paymentCheckoutCheckConfirmation => 'Проверить подтверждение';

  @override
  String get paymentCheckoutBackToAccount => 'Назад к аккаунту';

  @override
  String get paymentWalletTitle => 'Кошелёк и платежи';

  @override
  String get paymentWalletTestNote =>
      'Тестовые платежи · без реального списания. Используй только тестовые данные карты.';

  @override
  String get paymentWalletPopularTopUps => 'Популярные пополнения';

  @override
  String get paymentWalletTopUpsIntro =>
      'Оплати картой на защищённой странице оплаты. Монеты поступят в кошелёк, как только платёж пройдёт.';

  @override
  String get paymentWalletCardsDisabled =>
      'Оплата картой на этом сервере пока не включена.';

  @override
  String get paymentWalletNoPacks => 'Сейчас нет доступных пакетов монет.';

  @override
  String get paymentWalletActivity => 'История кошелька';

  @override
  String get paymentWalletNoPurchases => 'Покупок монет пока нет.';

  @override
  String get paymentWalletFooter =>
      'Монеты тратятся на подарки и бусты в Connect. После проведения платежа покупка окончательна; данные карты остаются у платёжного провайдера.';

  @override
  String paymentCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count монеты',
      many: '$count монет',
      few: '$count монеты',
      one: '$count монета',
    );
    return '$_temp0';
  }

  @override
  String paymentCoinsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count монеты зачислено в кошелёк.',
      many: '$count монет зачислено в кошелёк.',
      few: '$count монеты зачислены в кошелёк.',
      one: '$count монета зачислена в кошелёк.',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'монеты',
      many: 'монет',
      few: 'монеты',
      one: 'монета',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnitBonus(int count, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'монеты · +$bonus в подарок',
      many: 'монет · +$bonus в подарок',
      few: 'монеты · +$bonus в подарок',
      one: 'монета · +$bonus в подарок',
    );
    return '$_temp0';
  }

  @override
  String get paymentWalletCheckoutEnded =>
      'Сеанс оплаты завершён. Проверь историю платежей, прежде чем пробовать снова.';

  @override
  String get paymentWalletBalanceLabel => 'Баланс кошелька Glow';

  @override
  String get paymentWalletSourceSupport => 'Пополнение от поддержки';

  @override
  String get paymentWalletSourcePromo => 'Акция';

  @override
  String get paymentWalletSourcePurchase => 'Покупка монет';

  @override
  String get paymentErrorSignInSubscriptions =>
      'Войди, чтобы управлять подпиской.';

  @override
  String get paymentErrorSignInWallet => 'Войди, чтобы управлять кошельком.';

  @override
  String get paymentErrorLoadSubscription =>
      'Не удалось загрузить данные подписки.';

  @override
  String get paymentErrorLoadWallet => 'Не удалось загрузить кошелёк.';

  @override
  String get paymentErrorStartCheckoutNow => 'Сейчас не удаётся начать оплату.';

  @override
  String get paymentErrorStartCheckout => 'Не удалось начать оплату.';

  @override
  String get paymentErrorConfirmPayment =>
      'Пока не удаётся подтвердить платёж.';

  @override
  String get paymentErrorAutoRenewOn =>
      'Не удалось снова включить автопродление.';

  @override
  String get paymentErrorAutoRenewOff => 'Не удалось отключить автопродление.';

  @override
  String get paymentErrorChangePlan => 'Не удалось сменить тариф.';

  @override
  String get paymentErrorUpdateCard => 'Не удалось обновить карту.';

  @override
  String get paymentErrorSandboxFailed => 'Симуляция в песочнице не удалась.';

  @override
  String get paymentErrorUnreachable =>
      'Не удаётся связаться с локальным сервисом. Проверь, что API запущен.';

  @override
  String membershipQuotaLikesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Сегодня осталось $remaining из $limit лайка',
      many: 'Сегодня осталось $remaining из $limit лайков',
      few: 'Сегодня осталось $remaining из $limit лайков',
      one: 'Сегодня осталось $remaining из $limit лайка',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Сегодня осталось $remaining из $limit сообщения',
      many: 'Сегодня осталось $remaining из $limit сообщений',
      few: 'Сегодня осталось $remaining из $limit сообщений',
      one: 'Сегодня осталось $remaining из $limit сообщения',
    );
    return '$_temp0';
  }

  @override
  String membershipLikeLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Лимит на сегодня исчерпан: $limit лайка на тарифе $plan',
      many: 'Лимит на сегодня исчерпан: $limit лайков на тарифе $plan',
      few: 'Лимит на сегодня исчерпан: $limit лайка на тарифе $plan',
      one: 'Лимит на сегодня исчерпан: $limit лайк на тарифе $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipMessageLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Лимит на сегодня исчерпан: $limit сообщения на тарифе $plan',
      many: 'Лимит на сегодня исчерпан: $limit сообщений на тарифе $plan',
      few: 'Лимит на сегодня исчерпан: $limit сообщения на тарифе $plan',
      one: 'Лимит на сегодня исчерпан: $limit сообщение на тарифе $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaResetsAt(String time) {
    return 'Обновится в $time';
  }

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пары',
      many: '$count пар',
      few: '$count пары',
      one: '$count пара',
    );
    return '$_temp0';
  }

  @override
  String get matchesSubtitleConversations =>
      'Чуть ближе — сообщение за сообщением.';

  @override
  String get matchesSubtitlePeople =>
      'Люди, которых ты выбираешь. Возможности, которые вы создаёте вместе.';

  @override
  String get matchesSearchConversations => 'Поиск по чатам';

  @override
  String get matchesSearchMatches => 'Поиск по парам';

  @override
  String get matchesFilterAllConversations => 'Все чаты';

  @override
  String matchesFilterUnread(int count) {
    return 'Непрочитанные · $count';
  }

  @override
  String get matchesLoading => 'Загружаем пары…';

  @override
  String get matchesLoadErrorTitle => 'Не удалось загрузить пары';

  @override
  String get matchesRetry => 'Повторить';

  @override
  String get matchesEmptyTitle => 'Пар пока нет';

  @override
  String matchesTrustFilteredHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Фильтры доверия скрыли $count пары. Попробуй ослабить их в разделе «Поиск».',
      many:
          'Фильтры доверия скрыли $count пар. Попробуй ослабить их в разделе «Поиск».',
      few:
          'Фильтры доверия скрыли $count пары. Попробуй ослабить их в разделе «Поиск».',
      one:
          'Фильтры доверия скрыли $count пару. Попробуй ослабить их в разделе «Поиск».',
    );
    return '$_temp0';
  }

  @override
  String get matchesEmptyBody =>
      'Загляни в «Сегодня», чтобы найти того, с кем хочется познакомиться.';

  @override
  String get matchesNoConversationResults =>
      'Здесь пока нет чатов. Попробуй другой запрос или фильтр.';

  @override
  String get matchesNoPeopleResults => 'Пары не найдены. Попробуй другое имя.';

  @override
  String get matchesTabPeople => 'Твои пары';

  @override
  String get matchesTabConversations => 'Чаты';

  @override
  String get matchesActionStartCall => 'Начать звонок';

  @override
  String get matchesActionStartActivity => 'Начать активность';

  @override
  String get matchesActionPlanDate => 'Запланировать свидание';

  @override
  String get matchesActionPlanDateSubtitle =>
      'Выбери время и то, чем хочешь поделиться';

  @override
  String matchesPlanSent(String name) {
    return 'План отправлен: $name.';
  }

  @override
  String get matchesActionGraduate => 'Мы нашли друг друга';

  @override
  String get matchesActionGraduateSubtitle =>
      'Покиньте Connect вместе — ваш чат сохранится';

  @override
  String matchesGraduationAsked(String name) {
    return 'Запрос отправлен: $name. Подтвердить уход вдвоём можно в вашем чате.';
  }

  @override
  String get matchesActionNudge => 'Напомнить о себе';

  @override
  String matchesNudgeSent(String name) {
    return 'Напоминание отправлено: $name.';
  }

  @override
  String get matchesNudgeFailed => 'Не удалось отправить напоминание.';

  @override
  String get matchesActionClose => 'Закрыть чат';

  @override
  String get matchesActionCloseSubtitle => 'Освободи место — без объяснений.';

  @override
  String get matchesCloseDialogTitle => 'Закрыть этот чат?';

  @override
  String get matchesCloseDialogBody =>
      'Ничего страшного, если это знакомство тебе не подходит. Пара будет удалена. Объяснять ничего не нужно. Пожаловаться можно отдельно.';

  @override
  String get matchesCloseDialogKeep => 'Продолжить общение';

  @override
  String get matchesActionReport => 'Пожаловаться';

  @override
  String get matchesReportSubmitted => 'Жалоба отправлена. Спасибо.';

  @override
  String get matchesReportAppeal => 'Обжаловать';

  @override
  String matchesAppealReason(String userId) {
    return 'Пересмотреть решение модерации по жалобе на пользователя $userId';
  }

  @override
  String get matchesBothChose => 'Вы оба решили познакомиться';

  @override
  String matchesOptionsTooltip(String name) {
    return 'Действия с парой: $name';
  }

  @override
  String matchesChatUnread(int count) {
    return 'Чат · непрочитанных: $count';
  }

  @override
  String get matchesOpenChat => 'Открыть чат';

  @override
  String get matchesFirstChapter => 'Первая глава';

  @override
  String get matchesUnknownName => 'Неизвестно';

  @override
  String get matchesSayHi => 'Скажи привет 👋';

  @override
  String get matchesFallbackName => 'Твоя пара';

  @override
  String get matchesFallbackMessage => 'Начни разговор';

  @override
  String get matchesGiftPreview => 'Небольшой подарок в вашем чате';

  @override
  String matchesConversationOptionsTooltip(String name) {
    return 'Действия с чатом: $name';
  }

  @override
  String get matchesTimeNow => 'Сейчас';

  @override
  String matchesTimeMinutesAgo(int minutes) {
    return '$minutes мин назад';
  }

  @override
  String matchesTimeHoursAgo(int hours) {
    return '$hours ч назад';
  }

  @override
  String get matchesTimeToday => 'Сегодня';

  @override
  String get matchesTimeYesterday => 'Вчера';

  @override
  String get matchesNewMatchTitle => 'Новая пара';

  @override
  String get matchesItsAMatch => 'Это взаимно!';

  @override
  String matchesLikedEachOther(String name) {
    return 'Вы с $name понравились друг другу';
  }

  @override
  String get matchesSendMessage => 'Написать сообщение';

  @override
  String get matchesKeepSwiping => 'Смотреть дальше';

  @override
  String get matchesErrorLoginRequired => 'Войди, чтобы увидеть свои пары.';

  @override
  String get matchesErrorLoadFailed =>
      'Не удалось загрузить пары. Попробуй ещё раз.';

  @override
  String get matchesErrorUnmatchFailed => 'Не удалось удалить пару.';

  @override
  String get matchesErrorMarkReadFailed =>
      'Не удалось отметить как прочитанное.';

  @override
  String get matchesErrorSessionUnavailable =>
      'Сессия пользователя недоступна.';

  @override
  String get matchesTrustBadgePromptCompleter => 'Отвечает на вопросы';

  @override
  String get matchesTrustBadgeRespectful => 'Уважительное общение';

  @override
  String get matchesTrustBadgeConsistent => 'Цельный профиль';

  @override
  String get matchesTrustBadgeVerifiedActive => 'Проверен и активен';

  @override
  String get matchesTrustErrorLoad =>
      'Не удалось загрузить фильтры доверия. Попробуй ещё раз.';

  @override
  String get matchesTrustErrorSave =>
      'Не удалось сохранить фильтры доверия. Попробуй ещё раз.';

  @override
  String get matchesGestureErrorLoad => 'Не удалось загрузить историю';

  @override
  String get matchesGestureErrorPending =>
      'Знаки внимания станут доступны, когда эта переписка превратится во взаимную пару.';

  @override
  String get matchesGestureErrorSend => 'Не удалось отправить знак внимания.';

  @override
  String get matchesGestureErrorUpdate =>
      'Не удалось обновить статус знака внимания.';

  @override
  String get matchesActivityTitle => '«Это или то» за 2 минуты';

  @override
  String get matchesActivityRestartTooltip => 'Начать заново';

  @override
  String matchesActivityCompleteWith(String name) {
    return 'Пройдите вместе: ты и $name';
  }

  @override
  String get matchesActivityInstructions =>
      'Ответь на все 8 раундов, пока не вышло время.';

  @override
  String matchesActivityStatus(String status) {
    return 'Статус: $status';
  }

  @override
  String get matchesActivityStatusActive => 'идёт';

  @override
  String get matchesActivityStatusTimedOut => 'время вышло';

  @override
  String get matchesActivityStatusPartialTimeout => 'частично завершено';

  @override
  String get matchesActivityStatusCompleted => 'завершено';

  @override
  String get matchesActivitySubmit => 'Отправить ответы';

  @override
  String get matchesActivityTimeUpLoad => 'Время вышло — загрузить итоги';

  @override
  String get matchesActivityWaiting =>
      'Ответы отправлены. Ждём, когда второй участник закончит.';

  @override
  String get matchesActivityRefreshSummary => 'Обновить итоги';

  @override
  String matchesActivityTimeLeft(String time) {
    return 'Осталось $time';
  }

  @override
  String get matchesActivitySummaryTitle => 'Итоги активности';

  @override
  String matchesActivityParticipantsCompleted(int completed, int total) {
    return 'Завершили: $completed/$total';
  }

  @override
  String get matchesActivitySummaryPending =>
      'Итоги появятся, как только будут готовы.';

  @override
  String get matchesActivityShareResult => 'Поделиться результатом в чате';

  @override
  String matchesActivityShareMessage(String status, int completed, int total) {
    return 'Итог «Это или то» за 2 мин: $status • завершили $completed/$total';
  }

  @override
  String matchesActivityShareMessageWithInsight(
    String status,
    int completed,
    int total,
    String insight,
  ) {
    return 'Итог «Это или то» за 2 мин: $status • завершили $completed/$total • $insight';
  }

  @override
  String matchesActivityRound(int number) {
    return 'Раунд $number';
  }

  @override
  String get matchesActivityErrorStart =>
      'Сейчас не удаётся начать активность. Попробуй ещё раз.';

  @override
  String get matchesActivityErrorNotReady => 'Сессия ещё не готова.';

  @override
  String get matchesActivityErrorAnswerAll =>
      'Ответь на все вопросы перед отправкой.';

  @override
  String get matchesActivityErrorTimeUp => 'Время вышло. Загружаем итоги…';

  @override
  String get matchesActivityErrorSubmit =>
      'Не удалось отправить ответы. Попробуй ещё раз.';

  @override
  String get matchesActivityErrorSummary =>
      'Пока не удаётся получить итоги. Попробуй ещё раз.';

  @override
  String get matchesActivityQ1Prompt => 'Идеальная первая встреча?';

  @override
  String get matchesActivityQ1OptionA => 'Прогулка с кофе';

  @override
  String get matchesActivityQ1OptionB => 'Прогулка по книжному';

  @override
  String get matchesActivityQ2Prompt => 'Любимое настроение на выходных?';

  @override
  String get matchesActivityQ2OptionA => 'Остаться дома и отдохнуть';

  @override
  String get matchesActivityQ2OptionB => 'Исследовать город';

  @override
  String get matchesActivityQ3Prompt => 'Лучшее место для разговора?';

  @override
  String get matchesActivityQ3OptionA => 'Долгая прогулка';

  @override
  String get matchesActivityQ3OptionB => 'Уютный уголок в кафе';

  @override
  String get matchesActivityQ4Prompt => 'Как ты планируешь свидания?';

  @override
  String get matchesActivityQ4OptionA => 'Спонтанно';

  @override
  String get matchesActivityQ4OptionB => 'Заранее';

  @override
  String get matchesActivityQ5Prompt => 'Что для тебя сейчас важнее?';

  @override
  String get matchesActivityQ5OptionA => 'Стабильность';

  @override
  String get matchesActivityQ5OptionB => 'Яркие эмоции';

  @override
  String get matchesActivityQ6Prompt => 'Как ты решаешь конфликты?';

  @override
  String get matchesActivityQ6OptionA => 'Решить в тот же день';

  @override
  String get matchesActivityQ6OptionB => 'Взять паузу и вернуться позже';

  @override
  String get matchesActivityQ7Prompt => 'Что делать вместе?';

  @override
  String get matchesActivityQ7OptionA => 'Готовить вместе';

  @override
  String get matchesActivityQ7OptionB => 'Тренироваться вместе';

  @override
  String get matchesActivityQ8Prompt => 'Какой темп тебе ближе?';

  @override
  String get matchesActivityQ8OptionA => 'Размеренно и осознанно';

  @override
  String get matchesActivityQ8OptionB => 'Быстро и энергично';

  @override
  String get cityPilotSaveFailed =>
      'Не удалось подтвердить изменение. Обнови страницу и проверь, прежде чем пробовать снова.';

  @override
  String get cityPilotLeaveTitle => 'Выйти из городского пилота?';

  @override
  String get cityPilotLeaveBody =>
      'Твои бронирования в пилоте будут отменены, а отзывы о встречах удалены. Твоя активность перестанет учитываться в текущих результатах. Пары и чаты останутся. Вернуться в этот пилот будет нельзя.';

  @override
  String get cityPilotStay => 'Остаться в пилоте';

  @override
  String get cityPilotLeave => 'Выйти из пилота';

  @override
  String get cityPilotLeftNotice =>
      'Участие в пилоте завершено. Твои пары остаются с тобой.';

  @override
  String cityPilotJoinEventTitle(String title) {
    return 'Присоединиться: $title?';
  }

  @override
  String cityPilotBookingTerms(
    String host,
    String safetyContact,
    String accessibility,
  ) {
    return 'Это бесплатно. Встреча проходит в общественном месте: уважай границы других и добирайся самостоятельно. Уйти можно в любой момент.\n\nОрганизатор: $host\nКонтакт по безопасности: $safetyContact\n\nДоступность: $accessibility\n\nПри непосредственной опасности обращайся в местные экстренные службы.';
  }

  @override
  String get cityPilotAcceptReserve => 'Принять и забронировать место';

  @override
  String get cityPilotReservedNotice =>
      'Место забронировано. Отменить можно здесь в любой момент.';

  @override
  String get cityPilotFeedbackTitle => 'Как всё прошло?';

  @override
  String get cityPilotFeedbackIntro =>
      'Необязательно. Ответы учитываются в общих результатах пилота. Их не видят другие участники и организатор.';

  @override
  String get cityPilotDidYouAttend => 'Удалось прийти?';

  @override
  String get cityPilotAttendedYes => 'Да, получилось';

  @override
  String get cityPilotAttendedNo => 'Не получилось';

  @override
  String get cityPilotWorthwhileQuestion =>
      'Стоило потраченного времени? (необязательно)';

  @override
  String get cityPilotNotThisTime => 'В этот раз нет';

  @override
  String get cityPilotSkip => 'Пропустить';

  @override
  String get cityPilotShareFeedback => 'Отправить отзыв';

  @override
  String get cityPilotFeedbackThanks =>
      'Спасибо. Твой отзыв сохранён конфиденциально.';

  @override
  String get cityPilotTimeTbc => 'Время уточняется';

  @override
  String get cityPilotTitle => 'Городской пилот';

  @override
  String get cityPilotRefreshTooltip => 'Обновить пилот';

  @override
  String get cityPilotHeroTitle => 'Чуть ближе.\nГораздо реальнее.';

  @override
  String get cityPilotHeroBody =>
      'Один город. Небольшое сообщество. Больше шансов, что разговор превратится в планы.';

  @override
  String get cityPilotStep1Title => 'Начни с разговора';

  @override
  String get cityPilotStep1Body =>
      'Знакомься в своём темпе через уже имеющиеся знакомства.';

  @override
  String get cityPilotStep2Title => 'Найди время для настоящего свидания';

  @override
  String get cityPilotStep2Body =>
      'Составьте план вместе. Рассказывай, как всё прошло, только если захочешь.';

  @override
  String get cityPilotStep3Title => 'Попробуйте что-то вместе';

  @override
  String get cityPilotStep3Body =>
      'Небольшие встречи с организатором появятся после первой оценки пилота.';

  @override
  String get cityPilotSaving => 'Сохраняем настройку пилота';

  @override
  String get cityPilotUnavailableTitle => 'Пилот недоступен';

  @override
  String get cityPilotUnavailableBody =>
      'Проверь подключение и обнови, чтобы увидеть актуальное участие и бронирования.';

  @override
  String get cityPilotComingSoonTitle => 'Скоро в городе рядом с тобой';

  @override
  String get cityPilotComingSoonBody =>
      'Для города в твоём профиле пока нет открытого пилота. Когда он появится, ты сможешь решить, участвовать ли. Всё остальное работает как обычно.';

  @override
  String cityPilotPanelTitleJoined(String city) {
    return '$city · Ты участвуешь';
  }

  @override
  String cityPilotPanelTitleOpen(String city) {
    return '$city · Городской пилот';
  }

  @override
  String cityPilotRecruitmentCloses(String date) {
    return 'Набор до: $date (по местному времени).';
  }

  @override
  String get cityPilotPaused =>
      'Новые участия и бронирования приостановлены. Выйти или отменить всё ещё можно.';

  @override
  String get cityPilotCompleted => 'Этот пилот завершён. Спасибо за участие.';

  @override
  String get cityPilotMeasurement =>
      'Участвуя, ты разрешаешь нам учитывать переписки, принятые планы и необязательные ответы на вопрос «Свидание состоялось?» для новых пар, где оба человека участвуют в этом пилоте. Мы используем окно 7 дней для переписки и 28 дней для свиданий. Для пилота мы не читаем текст сообщений и личные заметки в отзывах.';

  @override
  String get cityPilotPrivacy =>
      'Участие остаётся конфиденциальным. Нет ни публичного списка участников, ни рейтинга. При выходе твоя активность исключается из текущих результатов, а бронирования отменяются. Уже рассмотренные общие результаты отменить нельзя.';

  @override
  String get cityPilotConsent =>
      'Я соглашаюсь участвовать в этом пилоте и в оценке его результатов.';

  @override
  String get cityPilotJoinedNotice =>
      'Ты в деле. Продолжай знакомиться в своём темпе.';

  @override
  String get cityPilotJoin => 'Присоединиться к пилоту';

  @override
  String get cityPilotWithdrawn =>
      'Ты больше не участвуешь в этом пилоте. Пары и чаты не изменились.';

  @override
  String get cityPilotNotAccepting =>
      'Сейчас этот пилот не принимает новых участников.';

  @override
  String get cityPilotExperiencesHeading =>
      'Небольшие планы. Общие впечатления.';

  @override
  String get cityPilotNoExperiences =>
      'Встречи с организатором пока не открыты. Они появятся здесь после оценки результатов и безопасности.';

  @override
  String cityPilotEventDetails(
    String start,
    String end,
    String venue,
    String host,
  ) {
    return '$start → $end\nПо местному времени · Бесплатно\n$venue\nОрганизатор: $host';
  }

  @override
  String cityPilotAccessibility(String details) {
    return 'Доступность · $details';
  }

  @override
  String cityPilotSafetyContact(String contact) {
    return 'Контакт по безопасности · $contact';
  }

  @override
  String get cityPilotEventCancelled =>
      'Эта встреча отменена. Пожалуйста, не приезжай на место.';

  @override
  String get cityPilotPlaceReserved => 'Место забронировано.';

  @override
  String get cityPilotBookingCancelled => 'Бронирование отменено.';

  @override
  String get cityPilotCancelPlace => 'Отменить бронь';

  @override
  String get cityPilotReserveFree => 'Забронировать бесплатное место';

  @override
  String get cityPilotShareOptionalFeedback => 'Оставить отзыв (по желанию)';

  @override
  String get cityPilotFeedbackReceived => 'Отзыв получен. Спасибо.';

  @override
  String get blogAudiencePrivate => 'Только я';

  @override
  String get blogAudienceFriends => 'Друзья';

  @override
  String get blogAudienceCommunity => 'Сообщество Connect';

  @override
  String get blogInvitationNone => 'Без приглашения';

  @override
  String get blogInvitationYourVersion => 'А какой была бы твоя версия?';

  @override
  String get blogInvitationTeachMe => 'Чему ты можешь меня здесь научить?';

  @override
  String get blogInvitationWhatNext => 'Что ты попробуешь дальше?';

  @override
  String get blogRewardStoryPublishedTitle => 'Публикация главы';

  @override
  String get blogRewardStoryPublishedWho =>
      'Тебе — когда глава впервые становится доступна не только тебе';

  @override
  String get blogRewardPhotoSharedTitle => 'Публикация фото в Фототемах';

  @override
  String get blogRewardPhotoSharedWho =>
      'Тебе — за фото, опубликованное в Фототемах';

  @override
  String get blogRewardLikeReceivedTitle => 'Лайк на твоей главе или фото';

  @override
  String get blogRewardLikeReceivedWho =>
      'Тебе — за каждого участника, которому понравилось';

  @override
  String get blogRewardCommentReceivedTitle => 'Одобренный тобой комментарий';

  @override
  String get blogRewardCommentReceivedWho =>
      'Тебе — когда ты одобряешь комментарий читателя';

  @override
  String get blogRewardCommentApprovedTitle => 'Твой комментарий одобрен';

  @override
  String get blogRewardCommentApprovedWho =>
      'Тебе — когда автор одобряет твой комментарий';

  @override
  String get blogRewardSubscriberGainedTitle => 'Новый подписчик';

  @override
  String get blogRewardSubscriberGainedWho =>
      'Тебе — за каждого нового участника, который подписался на твои главы';

  @override
  String get blogRewardWallTierTitle => 'Больше стен';

  @override
  String get blogRewardWallTierWho =>
      'Тебе — каждый раз, когда глава выходит на новый уровень охвата стен';

  @override
  String get blogRewardCoverOfWeekTitle => 'Обложка недели';

  @override
  String get blogRewardCoverOfWeekWho =>
      'Тебе — когда твою работу выбирают обложкой недели';

  @override
  String get blogScopeForYou => 'Для тебя';

  @override
  String get blogScopeTopRated => 'Лучшие';

  @override
  String get blogScopeFollowing => 'Подписки';

  @override
  String get blogScopeMine => 'Мои';

  @override
  String get blogScopeCaptionMine =>
      'Твои черновики и опубликованные главы. Для каждой ты сам выбираешь аудиторию.';

  @override
  String get blogScopeCaptionFriends =>
      'Главы, которыми поделились твои друзья в Connect.';

  @override
  String get blogScopeCaptionTop =>
      'Рейтинг по лайкам, одобренным комментариям и читателям за последние 30 дней.';

  @override
  String get blogScopeCaptionFollowing =>
      'Новые главы авторов из твоих подписок.';

  @override
  String get blogScopeCaptionCommunity =>
      'Для подходящих участников Connect, которые вошли в аккаунт. Эти главы не публикуются в интернете.';

  @override
  String get blogTitle => 'Открытые главы';

  @override
  String get blogRewardsTitle => 'Как работают награды';

  @override
  String get blogWritersTitle => 'Авторы в твоих подписках';

  @override
  String get blogConnectionsTooltip =>
      'Личные ответы, публикации и уведомления';

  @override
  String get blogSignInReadWrite => 'Войди, чтобы читать и писать главы.';

  @override
  String get blogHeroTitle => 'Жизнь, с которой\nстоит познакомиться.';

  @override
  String get blogHeroBody =>
      'История за фотографией. Маленькое увлечение. То, чему ты всё ещё учишься. Пусть за тебя говорит твоя повседневная жизнь.';

  @override
  String get blogWriteChapter => 'Написать главу';

  @override
  String get blogPrivateResponses => 'Личные ответы';

  @override
  String get blogSharedLinks => 'Опубликованные ссылки';

  @override
  String get blogReviewNotices => 'Уведомления о проверке';

  @override
  String get blogTopicAll => 'Все';

  @override
  String get blogFeedLoadFailed => 'Не удалось загрузить главы.';

  @override
  String get blogPreviousPage => 'Предыдущая страница';

  @override
  String get blogMoreChapters => 'Ещё главы';

  @override
  String get blogEmptyMineTitle => 'Твоя следующая глава начинается здесь.';

  @override
  String get blogEmptyMineBody =>
      'Начни с момента, о котором тебе хотелось бы, чтобы тебя спросили. Первый черновик видишь только ты.';

  @override
  String get blogEmptyTopTitle =>
      'Главы, которые трогают людей, поднимаются сюда.';

  @override
  String get blogEmptyTopFilteredBody =>
      'В этой теме пока ничего не поднялось. Выбери «Все» или поделись своей главой.';

  @override
  String get blogEmptyTopBody =>
      'Здесь появятся главы, которые полюбились читателям за последние 30 дней.';

  @override
  String get blogEmptyFollowingFilteredTitle =>
      'В этой теме пока ничего нового.';

  @override
  String get blogEmptyFollowingTitle =>
      'Здесь появятся авторы из твоих подписок.';

  @override
  String get blogEmptyFollowingBody =>
      'Если глава откликнулась, открой её и нажми «Следить за главами». Новые главы автора будут собираться здесь, и ты ничего не пропустишь.';

  @override
  String get blogEmptyCommunityTitle => 'Пока здесь тихо.';

  @override
  String get blogEmptyCommunityBody =>
      'Главы появятся здесь, когда участники решат поделиться ими с этой аудиторией.';

  @override
  String get blogFindWritersTopRated => 'Найти авторов в «Лучших»';

  @override
  String blogRankTooltip(int rank) {
    return '№ $rank среди лучших';
  }

  @override
  String get blogUntitled => 'Глава без названия';

  @override
  String get blogDraftPlaceholder => 'Личный черновик ждёт твоих слов.';

  @override
  String get blogReadEdit => 'Читать и редактировать →';

  @override
  String get blogReadChapter => 'Читать главу →';

  @override
  String get blogPhotoUnavailableRetry => 'Фото недоступно · Повторить';

  @override
  String get blogTryAgain => 'Повторить';

  @override
  String get blogDetailTitle => 'Глава';

  @override
  String get blogSignInRead => 'Войди, чтобы читать главы.';

  @override
  String get blogDetailUnavailable =>
      'Эта глава недоступна или её аудитория изменилась.';

  @override
  String get blogRespondPrivately => 'Ответить лично';

  @override
  String get blogCreatePublicPreview => 'Создать публичный предпросмотр';

  @override
  String get blogRemovedByModerationNote =>
      'Удалено модерацией. Открой «Уведомления о проверке», чтобы прочитать решение или запросить повторную проверку.';

  @override
  String get blogEditChapter => 'Редактировать главу';

  @override
  String get blogDeleteChapter => 'Удалить главу';

  @override
  String get blogDeleteChapterTitle => 'Удалить эту главу?';

  @override
  String get blogDeleteChapterMessage =>
      'Она исчезнет для всех. Это действие нельзя отменить.';

  @override
  String get blogDeleteChapterFailed =>
      'Не удалось подтвердить удаление. Обнови главу, прежде чем пробовать снова.';

  @override
  String get blogReportChapter => 'Пожаловаться на главу';

  @override
  String get blogReportFailed => 'Не удалось отправить жалобу.';

  @override
  String get blogBlockThisMember => 'Заблокировать участника';

  @override
  String get blogBlockTitle => 'Заблокировать участника?';

  @override
  String get blogBlockMessageChapter =>
      'Вы больше не будете видеть главы друг друга. Это также заблокирует общение в Connect.';

  @override
  String get blogBlockMember => 'Заблокировать';

  @override
  String get blogBlockRetryFailed =>
      'Не удалось заблокировать участника. Попробуй ещё раз.';

  @override
  String get blogCancel => 'Отмена';

  @override
  String get blogEditorMissingFields =>
      'Перед публикацией добавь название и текст.';

  @override
  String blogPublishConfirmTitle(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Опубликовать только для себя?',
      'friends': 'Опубликовать для друзей?',
      'community': 'Опубликовать в сообществе Connect?',
      'other': 'Опубликовать?',
    });
    return '$_temp0';
  }

  @override
  String get blogPublishFriendsBody =>
      'Твои друзья в Connect смогут прочитать текст и увидеть фото этой главы. Аудиторию можно изменить позже.';

  @override
  String get blogPublishCommunityBody =>
      'Эту главу смогут читать подходящие участники Connect, вошедшие в аккаунт. В открытом интернете она не появится. Аудиторию можно изменить позже.';

  @override
  String get blogPublishChapter => 'Опубликовать главу';

  @override
  String get blogSavedOnlyMe => 'Сохранено. Эту главу можешь читать только ты.';

  @override
  String blogPublishedTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Опубликовано только для тебя.',
      'friends': 'Опубликовано для друзей.',
      'community': 'Опубликовано в сообществе Connect.',
      'other': 'Опубликовано.',
    });
    return '$_temp0';
  }

  @override
  String get blogSharedSnack =>
      'Опубликовано. Лайки и комментарии читателей приносят тебе XP.';

  @override
  String get blogSeeMyLevel => 'Мой уровень';

  @override
  String get blogSaveUnconfirmed => 'Не удалось подтвердить сохранение.';

  @override
  String blogEditsStillHere(String message) {
    return '$message Твои правки на месте. Проверь сохранённую версию, прежде чем продолжать.';
  }

  @override
  String blogSavedVersionTitle(String audience) {
    return 'Сохранённая версия · $audience';
  }

  @override
  String get blogSavedVersionNote =>
      'Текущие правки остаются в редакторе. Закрой эту панель, чтобы сохранить их, или замени их сохранённой версией.';

  @override
  String get blogKeepMyEdits => 'Оставить мои правки до следующего сохранения';

  @override
  String get blogUseSavedVersion => 'Использовать сохранённую версию';

  @override
  String get blogSavedVersionLoadFailed =>
      'Не удалось загрузить сохранённую версию. Твои правки остаются здесь.';

  @override
  String get blogDescribePhotoTitle => 'Опиши фото';

  @override
  String get blogDescribePhotoBody =>
      'Короткое описание делает главу доступнее. При добавлении фото текст сохранится как черновик «Только я».';

  @override
  String get blogDescribePhotoLabel => 'Что на этом фото?';

  @override
  String get blogAddToPrivateDraft => 'Добавить в личный черновик';

  @override
  String get blogPhotoAdded => 'Фото добавлено в личный черновик.';

  @override
  String get blogPhotoAddFailed =>
      'Не удалось добавить фото. Используй JPEG или PNG размером до 10 МБ.';

  @override
  String blogCheckSavedBeforeRetrying(String message) {
    return '$message Проверь сохранённую версию, прежде чем пробовать снова.';
  }

  @override
  String get blogRemoveUnconfirmed =>
      'Не удалось подтвердить удаление. Проверь сохранённую версию.';

  @override
  String get blogSignInAsAuthor =>
      'Войди как автор, чтобы редактировать эту главу.';

  @override
  String get blogLeaveEditorTitle => 'Выйти без сохранения?';

  @override
  String get blogLeaveEditorMessage =>
      'Несохранённые правки будут потеряны. Последняя сохранённая версия главы останется.';

  @override
  String get blogLeaveEditor => 'Выйти из редактора';

  @override
  String get blogEditorPreviewTitle => 'Предпросмотр главы';

  @override
  String get blogEditorTitle => 'Твоя следующая глава';

  @override
  String get blogEditorHeadline => 'Чуть больше о тебе.';

  @override
  String get blogEditorIntro =>
      'Маленькие истории приветствуются. Блюдо, приготовленное своими руками. Место, которое изменило твоё мнение. Фото, за которым стоит история.';

  @override
  String get blogNotSavedDefault => 'Не сохранено · По умолчанию «Только я»';

  @override
  String blogSavedFor(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Сохранено: только я',
      'friends': 'Сохранено: друзья',
      'community': 'Сохранено: сообщество Connect',
      'other': 'Сохранено',
    });
    return '$_temp0';
  }

  @override
  String get blogKeepWriting => 'Продолжить писать';

  @override
  String get blogPreview => 'Предпросмотр';

  @override
  String get blogCheckSavedVersion => 'Проверить сохранённую версию';

  @override
  String blogPreviewNotSaved(String audience) {
    return 'Предпросмотр · $audience · Ещё не сохранено';
  }

  @override
  String get blogStoryPlaceholder => 'Здесь появится твоя история.';

  @override
  String get blogChapterTitleLabel => 'Название главы';

  @override
  String get blogChapterTitleHint =>
      'Воскресенье, когда я научился замедляться';

  @override
  String get blogStoryLabel => 'Твоя история';

  @override
  String get blogStoryHint => 'Начни с чего угодно. Сделай её своей.';

  @override
  String get blogInvitationLabel => 'Закончить приглашением (необязательно)';

  @override
  String get blogInvitationHelp =>
      'Оставь вопрос, который поможет кому-то узнать тебя лучше.';

  @override
  String get blogRemovePhoto => 'Удалить фото';

  @override
  String get blogAddPhoto => 'Добавить фото';

  @override
  String get blogPhotoRules =>
      'До 6 фото в формате JPEG или PNG, до 10 МБ каждое. Фото проходят проверку. Перед изменением фото в опубликованной главе сохрани её как «Только я».';

  @override
  String get blogWhoFor => 'Для кого эта глава?';

  @override
  String get blogAudiencePrivateHelp =>
      'Эту главу можешь читать только ты. Друзья и мэтчи её не видят.';

  @override
  String get blogAudienceFriendsHelp =>
      'Читать её могут только твои друзья в Connect. Одного мэтча для доступа недостаточно.';

  @override
  String get blogAudienceCommunityHelp =>
      'Её могут читать подходящие участники, вошедшие в аккаунт. Чтобы публиковать здесь, заполни профиль и добавь две одобренные фотографии. Это не публикация в открытом интернете.';

  @override
  String get blogAllowFeaturing => 'Разрешить продвижение';

  @override
  String get blogAllowFeaturingHelp =>
      'Если глава понравится читателям, она может попасть на стены других участников: 50 лайков и 5 комментариев — на 50 стен, 100 лайков и 10 комментариев — на 100. Это можно отключить в любой момент.';

  @override
  String get blogSaveOnlyForMe => 'Сохранить только для себя';

  @override
  String blogPublishTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Опубликовать только для себя',
      'friends': 'Опубликовать для друзей',
      'community': 'Опубликовать в сообществе Connect',
      'other': 'Опубликовать',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveAsOnlyMe => 'Сохранить как «Только я»';

  @override
  String get blogSaveNote =>
      'Текст сохраняется, когда ты нажимаешь «Сохранить» или «Опубликовать». Предпросмотр ничего не публикует.';

  @override
  String get blogTopicOptional => 'Тема (необязательно)';

  @override
  String get blogTopicHelp =>
      'Помоги читателям, которым это интересно, найти твою главу.';

  @override
  String get webDestBlog => 'Блог';

  @override
  String get webDestFirstChapter => 'Студия «Первая глава»';

  @override
  String get webDestDatingPreferences => 'Предпочтения в знакомствах';

  @override
  String get webDestEditProfile => 'Редактировать профиль';

  @override
  String get webDestProfilePhotos => 'Фото профиля';

  @override
  String get webDestLikedYou => 'Ты нравишься';

  @override
  String get webDestNotifications => 'Уведомления';

  @override
  String get webDestDailyPrompt => 'Вопрос дня';

  @override
  String get webDestLevels => 'Уровни и прогресс';

  @override
  String get webDestTrustBadges => 'Значки доверия';

  @override
  String get webDestTrustFilters => 'Фильтры доверия';

  @override
  String get webDestIcebreakers => 'Темы для начала разговора';

  @override
  String get webDestCircleChallenges => 'Челленджи круга';

  @override
  String get webDestCoffeePolls => 'Кофейные опросы';

  @override
  String get webDestGroups => 'Группы';

  @override
  String get webDestRooms => 'Комнаты для общения';

  @override
  String get webDestMatchNudges => 'Напоминания мэтчам';

  @override
  String get webDestFriends => 'Друзья';

  @override
  String get webDestDatePlans => 'Планы свиданий';

  @override
  String get webDestCallHistory => 'История звонков';

  @override
  String get webDestMembership => 'Подписка';

  @override
  String get webDestVerification => 'Верификация';

  @override
  String get webDestPrivacySafety => 'Конфиденциальность и безопасность';

  @override
  String get webDestAccountData => 'Аккаунт и данные';

  @override
  String get webDestBlockedMembers => 'Заблокированные участники';

  @override
  String get webDestEmergencyContacts => 'Экстренные контакты';

  @override
  String get webDestModerationAppeals => 'Апелляции модерации';

  @override
  String get webDestNotificationPreferences => 'Настройки уведомлений';

  @override
  String get webDestHelpSupport => 'Помощь и поддержка';

  @override
  String get webNavExplore => 'Обзор';

  @override
  String get webNavMyProfile => 'Мой профиль';

  @override
  String get webNavAllFeatures => 'Все функции';

  @override
  String get webNavMoreForYou => 'Ещё для тебя';

  @override
  String get webNavPreferences => 'Предпочтения';

  @override
  String get webNavWebsite => 'Сайт Connect';

  @override
  String get webNavSignOut => 'Выйти';

  @override
  String get webPageNotFound => 'Страница не найдена.';

  @override
  String get webBackToDiscover => 'Назад к знакомствам';

  @override
  String get webTagline => 'Твой темп. Твой выбор.';

  @override
  String webUnavailableTitle(String label) {
    return '«$label» пока недоступно.';
  }

  @override
  String get webUnavailableBody =>
      'Эта функция не входит в текущую версию Connect.';

  @override
  String get webDirectoryTitle => 'Сделайте это пространство своим.';

  @override
  String get webDirectorySubtitle =>
      'Профиль, разговоры, сообщество и настройки — всё в одном месте.';

  @override
  String get webIcebreakerTitle => 'Темы для разговора';

  @override
  String get webIcebreakerHeadline =>
      'Немного вдохновения для следующего «привет».';

  @override
  String get webIcebreakerBody =>
      'Запись и воспроизведение голоса пока недоступны. Эти подсказки можно использовать в доступном разговоре.';

  @override
  String get webIcebreakerOpenMatches => 'Открыть мои мэтчи';

  @override
  String get webMembershipHeadline => 'Чуть больше возможностей.';

  @override
  String get webMembershipIntro =>
      'Посмотрите текущие тарифы. Оплата в браузере пока недоступна. С этой страницы нельзя ничего купить или оплатить.';

  @override
  String webMembershipCurrent(String plan) {
    return 'Твоя подписка: $plan';
  }

  @override
  String webMembershipStatus(String status) {
    return 'Статус: $status';
  }

  @override
  String get webMembershipMonthly => 'Ежемесячно';

  @override
  String get webMembershipYearly => 'Ежегодно';

  @override
  String get webMembershipFree => 'Бесплатно';

  @override
  String webMembershipPrice(String price, String cycle) {
    String _temp0 = intl.Intl.selectLogic(cycle, {
      'yearly': 'год',
      'other': 'месяц',
    });
    return '$price / $_temp0';
  }

  @override
  String get webMembershipFootnote =>
      'Цены в каталоге — предварительные. Подписка никогда не обходит границы другого человека и правила доступа к разговору.';

  @override
  String get blogLinkCopied => 'Ссылка скопирована. Делись ею где угодно.';

  @override
  String get blogYourPublicLink => 'Твоя публичная ссылка';

  @override
  String get blogShareUnconfirmed =>
      'Не удалось подтвердить публикацию. Проверь «Опубликованные ссылки», прежде чем пробовать снова.';

  @override
  String get blogSignInAgain => 'Войди снова, чтобы продолжить.';

  @override
  String get blogSharedJournalPage => 'Общая страница дневника';

  @override
  String get blogYourPublicPreview => 'Твой публичный предпросмотр';

  @override
  String get blogShareJointHeadline =>
      'История, которой вы оба решили поделиться.';

  @override
  String get blogShareSoloHeadline => 'Маленькое окно в твой мир.';

  @override
  String get blogShareJointBody =>
      'Ссылка заработает, только когда оба автора одобрят именно этот текст. Любой из вас может её отозвать.';

  @override
  String get blogShareSoloBody =>
      'Любой, у кого есть ссылка, сможет без аккаунта прочитать выбранный текст и увидеть выбранные фото. Полная глава остаётся в Connect.';

  @override
  String get blogShareIdentityNote =>
      'Профиль и имя аккаунта не добавляются. Но по тексту и фото всё равно можно узнать людей или места. Публикуй только то, чем вправе делиться.';

  @override
  String get blogExcerptLabel => 'Точный отрывок из главы';

  @override
  String blogIncludePhoto(String description) {
    return 'Добавить: $description';
  }

  @override
  String get blogApproveCopy => 'Я одобряю именно эту публичную копию';

  @override
  String get blogApproveCopyNote =>
      'Если изменить или скрыть исходную главу, ссылка перестанет работать. Копии, сохранённые вне Connect, отозвать нельзя.';

  @override
  String get blogSaving => 'Сохранение…';

  @override
  String get blogRequestOtherApproval => 'Запросить одобрение второго автора';

  @override
  String get blogCreatePublicLink => 'Создать публичную ссылку';

  @override
  String get blogJointApprovalRecorded =>
      'Твоё одобрение сохранено. Ссылка будет недоступна, пока второй автор не одобрит.';

  @override
  String get blogPublicCopyReady => 'Публичная копия готова.';

  @override
  String get blogCopyPublicLink => 'Скопировать публичную ссылку';

  @override
  String get blogManageSharedLinks => 'Управлять ссылками';

  @override
  String blogFollowerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count подписчика',
      many: '$count подписчиков',
      few: '$count подписчика',
      one: '$count подписчик',
    );
    return '$_temp0';
  }

  @override
  String get blogUnfollowFailed =>
      'Не получилось отписаться. Попробуй ещё раз.';

  @override
  String get blogFollowFailed =>
      'Не получилось подписаться на автора. Попробуй ещё раз.';

  @override
  String get blogFollowingButton => 'В подписках';

  @override
  String get blogFollowTheirChapters => 'Следить за главами';

  @override
  String get blogRewardsIntro =>
      'Когда то, чем ты делишься, кого-то трогает, это засчитывается. Лайки читателей, одобренные комментарии и новые подписчики приносят XP для твоего уровня. Награды зависят от действий читателей, а не от нажатий, и каждая выдаётся только один раз.';

  @override
  String blogRewardDailyCap(int cap) {
    return 'До $cap XP в день';
  }

  @override
  String blogRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String get blogSignInWriters =>
      'Войди, чтобы увидеть свои подписки на авторов.';

  @override
  String get blogWritersLoadFailed =>
      'Не удалось загрузить авторов из подписок.';

  @override
  String get blogNoWriters => 'Пока нет авторов.';

  @override
  String get blogNoWritersBody =>
      'Если глава откликнулась, нажми в ней «Следить за главами». Новые главы автора будут собираться в «Подписках».';

  @override
  String blogLatest(String title) {
    return 'Последняя: $title';
  }

  @override
  String get blogReactionFailed => 'Реакция не отправилась. Попробуй ещё раз.';

  @override
  String blogCannotLikeOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Нельзя лайкнуть своё фото',
      'other': 'Нельзя лайкнуть свою главу',
    });
    return '$_temp0';
  }

  @override
  String blogYouReacted(String reaction) {
    return 'Твоя реакция: $reaction. Нажми, чтобы отменить';
  }

  @override
  String blogLikeThis(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Лайкнуть фото',
      'other': 'Лайкнуть главу',
    });
    return '$_temp0';
  }

  @override
  String blogCannotReactOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Нельзя реагировать на своё фото',
      'other': 'Нельзя реагировать на свою главу',
    });
    return '$_temp0';
  }

  @override
  String get blogReactTooltip => 'Реакции: Я тебя слышу, Я тоже, Обнимаю…';

  @override
  String blogCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count комментария',
      many: '$count комментариев',
      few: '$count комментария',
      one: '$count комментарий',
    );
    return '$_temp0';
  }

  @override
  String blogWaitingForYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '· $count ждут тебя',
      many: '· $count ждут тебя',
      few: '· $count ждут тебя',
      one: '· $count ждёт тебя',
    );
    return '$_temp0';
  }

  @override
  String get blogFeatured => 'В подборке';

  @override
  String blogTierNeedsBoth(int likes, int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes лайка',
      many: '$likes лайков',
      few: '$likes лайка',
      one: '$likes лайк',
    );
    String _temp1 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments комментария',
      many: '$comments комментариев',
      few: '$comments комментария',
      one: '$comments комментарий',
    );
    String _temp2 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls стены',
      many: '$walls стен',
      few: '$walls стены',
      one: '$walls стену',
    );
    return 'Ещё $_temp0 и $_temp1, чтобы попасть на $_temp2';
  }

  @override
  String blogTierNeedsLikes(int likes, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes лайка',
      many: '$likes лайков',
      few: '$likes лайка',
      one: '$likes лайк',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls стены',
      many: '$walls стен',
      few: '$walls стены',
      one: '$walls стену',
    );
    return 'Ещё $_temp0, чтобы попасть на $_temp1';
  }

  @override
  String blogTierNeedsComments(int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments комментария',
      many: '$comments комментариев',
      few: '$comments комментария',
      one: '$comments комментарий',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls стены',
      many: '$walls стен',
      few: '$walls стены',
      one: '$walls стену',
    );
    return 'Ещё $_temp0, чтобы попасть на $_temp1';
  }

  @override
  String blogTierAlmostThere(int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: 'Почти готово: дальше $walls стены',
      many: 'Почти готово: дальше $walls стен',
      few: 'Почти готово: дальше $walls стены',
      one: 'Почти готово: дальше $walls стена',
    );
    return '$_temp0';
  }

  @override
  String blogOnWalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'На $count стены',
      many: 'На $count стенах',
      few: 'На $count стенах',
      one: 'На $count стене',
    );
    return '$_temp0';
  }

  @override
  String blogProgressToward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Прогресс до $count стены',
      many: 'Прогресс до $count стен',
      few: 'Прогресс до $count стен',
      one: 'Прогресс до $count стены',
    );
    return '$_temp0';
  }

  @override
  String get blogReachIdle =>
      'Читатели могут помочь этой главе разойтись дальше';

  @override
  String get blogReachLive =>
      'Её сейчас читают участники, которым понравились похожие истории.';

  @override
  String get blogFeaturedStories => 'Избранные истории';

  @override
  String get blogFeaturedCaption =>
      'Истории, которые полюбили другие, — прямо на твоей стене.';

  @override
  String blogByAuthor(String name) {
    return 'автор: $name';
  }

  @override
  String get blogLikes => 'Лайки';

  @override
  String get blogComments => 'Комментарии';

  @override
  String get blogCommentHint => 'Что тебе запомнилось?';

  @override
  String get blogCommentApproved =>
      'Одобрено. Теперь его видят все, кто может читать эту главу.';

  @override
  String get blogCommentSent => 'Отправлено автору на одобрение';

  @override
  String get blogCommentSendFailed =>
      'Комментарий не отправился. Текст остался на месте — можно попробовать ещё раз.';

  @override
  String blogCommentDeclined(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Отклонено. Он не появится под твоим фото.',
      'other': 'Отклонено. Он не появится под твоей главой.',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveFailed => 'Не сохранилось. Попробуй ещё раз.';

  @override
  String get blogDeleteCommentTitle => 'Удалить этот комментарий?';

  @override
  String get blogDeleteCommentMessage =>
      'Он будет удалён для всех. Это действие нельзя отменить.';

  @override
  String get blogDeleteComment => 'Удалить комментарий';

  @override
  String get blogCommentDeleted => 'Комментарий удалён.';

  @override
  String get blogCommentDeleteFailed =>
      'Не удалось удалить комментарий. Попробуй ещё раз.';

  @override
  String get blogCommentsAuthorNote =>
      'Новые комментарии ждут твоего одобрения, прежде чем их увидят другие.';

  @override
  String get blogCommentsReaderNote =>
      'Автор сначала читает каждый комментарий и решает, что показать.';

  @override
  String get blogLeaveComment => 'Оставить комментарий';

  @override
  String get blogSendToAuthor => 'Отправить автору';

  @override
  String get blogCommentsLoadFailed => 'Не удалось загрузить комментарии.';

  @override
  String get blogWaitingApproval => 'Ждут твоего одобрения';

  @override
  String get blogNoCommentsInvite =>
      'Комментариев пока нет. Напиши что-нибудь доброе, чтобы начать разговор.';

  @override
  String get blogNoCommentsShared => 'Пока нет опубликованных комментариев.';

  @override
  String get blogCommentNotShared =>
      'Автор решил не показывать этот комментарий.';

  @override
  String get blogYou => 'Ты';

  @override
  String get blogCommentOptions => 'Действия с комментарием';

  @override
  String get blogReportComment => 'Пожаловаться на комментарий';

  @override
  String get blogApprove => 'Одобрить';

  @override
  String get blogDecline => 'Отклонить';

  @override
  String get blogSignInContinue => 'Войди, чтобы продолжить.';

  @override
  String get blogPrivateResponseTitle => 'Личный ответ';

  @override
  String blogPrivateResponseHelp(String invitation) {
    return '$invitation\n\nЭтот ответ получит только автор. Он может принять или отклонить необязательный обмен. Не больше пяти новых ответов в день и одного — одному и тому же автору.';
  }

  @override
  String get blogSendPrivateResponse => 'Отправить личный ответ';

  @override
  String get blogTextSaveUnconfirmed =>
      'Не удалось подтвердить сохранение. Текст на месте: попробуй снова или обнови сохранённый обмен.';

  @override
  String get blogLeaveUnsentTitle => 'Выйти без отправки?';

  @override
  String get blogLeaveUnsentMessage => 'Неотправленный текст будет удалён.';

  @override
  String get blogLeave => 'Выйти';

  @override
  String get blogOwnWordsLabel => 'Своими словами';

  @override
  String get blogSending => 'Отправка…';

  @override
  String get blogChangeUnconfirmed =>
      'Не удалось подтвердить изменение. Обнови страницу, чтобы проверить.';

  @override
  String get blogConnectionsTitle => 'Твои связи через главы';

  @override
  String get blogRefresh => 'Обновить';

  @override
  String get blogConnectionsIntro =>
      'В хороших историях всегда есть место для кого-то ещё.';

  @override
  String get blogConnectionsLoadFailed => 'Не удалось загрузить твои связи.';

  @override
  String get blogResponsesEmpty =>
      'Здесь появятся ответы на твои главы и те, что отправишь ты. Ничто не требует мгновенного ответа.';

  @override
  String get blogPublicationsEmpty =>
      'Здесь появятся твои публичные предпросмотры и совместно одобренные ссылки.';

  @override
  String get blogNoticesEmpty => 'Уведомлений о проверке нет.';

  @override
  String get blogResponseRevealed => 'Ваша общая глава готова';

  @override
  String get blogResponseIncoming => 'Тебе ответили';

  @override
  String get blogResponseSent => 'Отправлено · решать им и в их темпе';

  @override
  String get blogResponseAccepted => 'Обмен в вашем темпе';

  @override
  String get blogResponseClosed => 'Этот обмен закрыт';

  @override
  String get blogOpenExchange => 'Открыть личный обмен';

  @override
  String get blogPublicationLive => 'Публичная копия доступна';

  @override
  String get blogPublicationRemoved => 'Удалено модерацией';

  @override
  String get blogPublicationNeedsBoth =>
      'Нужны оба одобрения и актуальная исходная глава';

  @override
  String get blogPublicationSourceChanged =>
      'Исходник изменён · создай новый предпросмотр, чтобы поделиться снова';

  @override
  String get blogApprovePublicCopyTitle => 'Одобрить эту публичную копию?';

  @override
  String get blogApprovePublicCopyMessage =>
      'Именно этот текст будет доступен всем, у кого есть ссылка. Каждый из вас может отозвать публикацию. Имена не добавляются автоматически, но по тексту тебя могут узнать.';

  @override
  String get blogApprovePublicCopyAction => 'Одобрить публичную копию';

  @override
  String get blogApproveExactPublicCopy => 'Одобрить точную публичную копию';

  @override
  String get blogCopyLink => 'Скопировать ссылку';

  @override
  String get blogWithdrawLinkTitle => 'Отозвать эту ссылку?';

  @override
  String get blogWithdrawLinkMessage =>
      'Публичная копия станет недоступна. Копии, которые кто-то уже сохранил, отозвать нельзя.';

  @override
  String get blogWithdrawLink => 'Отозвать ссылку';

  @override
  String get blogYourAppeal => 'Твоя апелляция';

  @override
  String get blogRequestReview => 'Запросить повторную проверку';

  @override
  String get blogRequestReviewHelp =>
      'Объясни, что стоит пересмотреть. Апелляция приватно уйдёт команде доверия и безопасности. Пока идёт проверка, удалённый контент остаётся скрытым.';

  @override
  String get blogSubmitAppeal => 'Отправить апелляцию';

  @override
  String get blogAppealDecision => 'Обжаловать решение';

  @override
  String get blogPrevious => 'Назад';

  @override
  String get blogMore => 'Ещё';

  @override
  String get blogExchangeChangeFailed =>
      'Не удалось подтвердить изменение. Обнови страницу и попробуй снова.';

  @override
  String get blogExchangeTitle => 'Личный обмен главами';

  @override
  String get blogExchangeUnavailable => 'Этот обмен больше недоступен.';

  @override
  String blogExchangeWith(String name) {
    return 'С $name';
  }

  @override
  String get blogExchangeIntro =>
      'Ответ — это приглашение, а не обязательство. Этот обмен не создаёт мэтч и не открывает чат.';

  @override
  String get blogAcceptExchange => 'Принять обмен';

  @override
  String get blogDeclineKindly => 'Вежливо отказаться';

  @override
  String get blogResponseSentNote =>
      'Твой ответ отправлен. Никакого обратного отсчёта, напоминать не нужно.';

  @override
  String get blogExchangeClosedNote =>
      'Этот обмен закрыт. В своём темпе освободи место для новой связи.';

  @override
  String get blogOneStoryEach => 'По одной маленькой истории.';

  @override
  String get blogOneStoryEachBody =>
      'Добавь небольшое продолжение, воспоминание или свою версию момента. Оба текста появятся вместе — только после того, как оба отправят свои.';

  @override
  String get blogYourSideTitle => 'Твоя часть главы';

  @override
  String get blogYourSideHelp =>
      'До 1000 символов. Собеседник не сможет прочитать это, пока не добавит свою часть. После отправки текст нельзя изменить, но обмен можно отозвать в любой момент.';

  @override
  String get blogSubmitContribution => 'Отправить мою часть';

  @override
  String get blogAddContribution => 'Добавить мою часть';

  @override
  String get blogYourContribution => 'Твоя часть';

  @override
  String blogPartnerContribution(String name) {
    return 'Часть: $name';
  }

  @override
  String get blogShapeDate => 'Спланировать свидание вместе';

  @override
  String get blogInspiredNote => 'Вдохновлено нашим обменом главами.';

  @override
  String get blogTryStudio => 'Попробовать студию «Первая глава»';

  @override
  String get blogDatePlanningUnavailable =>
      'Планирование свидания станет доступно, когда у тебя будет активный мэтч и откроется переписка.';

  @override
  String get blogProposeJournalPage => 'Предложить общую страницу дневника';

  @override
  String get blogSourceUnavailable => 'Исходная глава недоступна.';

  @override
  String get blogContributionSaved =>
      'Твоя часть сохранена приватно. Всё откроется, когда вы оба будете готовы.';

  @override
  String get blogWithdrawExchangeTitle => 'Отозвать этот обмен?';

  @override
  String get blogWithdrawExchangeMessage =>
      'Ответ и обе части станут недоступны вам обоим. Совместные публичные ссылки тоже перестанут работать.';

  @override
  String get blogWithdrawExchange => 'Отозвать обмен';

  @override
  String get blogReportExchange => 'Пожаловаться на обмен';

  @override
  String get blogBlockMessageExchange =>
      'Общение и доступ к главам друг друга прекратятся.';

  @override
  String get blogBlockFailed => 'Не удалось заблокировать участника.';

  @override
  String get notificationsReadAll => 'Прочитать все';

  @override
  String get notificationsFallbackTitle => 'Уведомление';

  @override
  String get notificationsLoadFailed => 'Не удалось загрузить уведомления.';

  @override
  String get notificationsPrefsUpdateFailed =>
      'Не удалось обновить настройки уведомлений.';

  @override
  String notificationsAgoMinutes(int count) {
    return '$count мин назад';
  }

  @override
  String notificationsAgoHours(int count) {
    return '$count ч назад';
  }

  @override
  String notificationsAgoDays(int count) {
    return '$count дн. назад';
  }

  @override
  String get wallsReactEyebrow => 'РЕАКЦИЯ';

  @override
  String wallsReactQuestion(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Какие чувства вызывает это фото?',
      'other': 'Какие чувства вызывает эта глава?',
    });
    return '$_temp0';
  }

  @override
  String get wallsReactBody =>
      'Твоя реакция покажет автору, что его услышали. Каждая реакция засчитывается как лайк.';

  @override
  String get wallsReactRemove => 'Убрать мою реакцию';

  @override
  String wallsReactionsSemantics(String list) {
    return 'Реакции: $list';
  }

  @override
  String get wallsReactionLove => 'Обожаю';

  @override
  String get wallsReactionHearYou => 'Я тебя слышу';

  @override
  String get wallsReactionMeToo => 'Я тоже';

  @override
  String get wallsReactionWithYou => 'Я с тобой';

  @override
  String get wallsReactionHug => 'Обнимаю';

  @override
  String get wallsReactionProud => 'Горжусь тобой';

  @override
  String get wallsSignInRequired => 'Войдите, чтобы увидеть свою стену.';

  @override
  String get celebrationCoverHeadline => 'Твоё фото — обложка недели';

  @override
  String celebrationReachHeadline(String kind, int reach) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'photo': 'Твоё фото попало на стены: $reach',
      'other': 'Твоя глава попала на стены: $reach',
    });
    return '$_temp0';
  }

  @override
  String get celebrationCoverMessage =>
      'Участникам понравилось. На этой неделе его видят все в разделе «Сегодня».';

  @override
  String get celebrationReachMessage =>
      'Участникам понравилось. Теперь это на их стенах «Сегодня».';

  @override
  String celebrationQuotedTitle(String title) {
    return '«$title»';
  }

  @override
  String get celebrationBarrier => 'Праздник';

  @override
  String get celebrationLovely => 'Чудесно';

  @override
  String get celebrationSeePhoto => 'Посмотреть фото';

  @override
  String get celebrationSeeChapter => 'Посмотреть главу';

  @override
  String rewardXpPill(int xp) {
    return '+$xp XP';
  }

  @override
  String get rewardClaimedTitle => 'Награда получена';

  @override
  String rewardNameDescription(String name, String description) {
    return '$name · $description';
  }

  @override
  String rewardPlusXpAnnouncement(int xp) {
    return 'плюс $xp XP';
  }

  @override
  String rewardSourceXpLine(String source, int xp) {
    return '$source +$xp XP';
  }

  @override
  String rewardAndMore(int count) {
    return 'и ещё $count';
  }

  @override
  String rewardBadgeLine(String badge) {
    return 'Значок: $badge';
  }

  @override
  String rewardLevelReached(int level) {
    return 'Достигнут уровень $level';
  }

  @override
  String rewardBadgesEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Получено $count значков',
      few: 'Получено $count значка',
      one: 'Получен $count значок',
    );
    return '$_temp0';
  }

  @override
  String get rewardYourRewardsToday => 'Твои награды за сегодня';

  @override
  String rewardNewRewards(int count) {
    return 'Новых наград: $count';
  }

  @override
  String get rewardSourceStoryPublished => 'Глава опубликована';

  @override
  String get rewardSourcePhotoShared => 'Фото опубликовано';

  @override
  String get rewardSourceLikeReceived => 'Участнику понравилась твоя работа';

  @override
  String get rewardSourceCommentReceived => 'Новый комментарий к твоей работе';

  @override
  String get rewardSourceCommentApproved => 'Твой комментарий одобрен';

  @override
  String get rewardSourceSubscriberGained => 'Новый подписчик';

  @override
  String get rewardSourceWallTierReached => 'Новый уровень стены';

  @override
  String get rewardSourceCoverOfWeek => 'Обложка недели';

  @override
  String get rewardSourceDailyPromptSubmitted => 'Ответ на вопрос дня';

  @override
  String get rewardLineStoryPublished => 'Твоя глава увидела свет.';

  @override
  String get rewardLinePhotoShared => 'Твоё фото добавлено в тему.';

  @override
  String get rewardLineLikeReceived =>
      'Кому-то очень понравилась твоя публикация.';

  @override
  String get rewardLineCommentReceived =>
      'Читатель присоединился к обсуждению.';

  @override
  String get rewardLineSubscriberGained => 'Кто-то ждёт твою следующую главу.';

  @override
  String get rewardLineWallTierReached => 'Твоя работа попала на новые стены.';

  @override
  String get rewardLineCoverOfWeek =>
      'На этой неделе все видят это в разделе «Сегодня».';

  @override
  String get rewardLineOther => 'Получено за значимую активность.';

  @override
  String get rewardNewBadgeFallback => 'Новый значок';

  @override
  String get blockedUnknownUser => 'Неизвестный пользователь';

  @override
  String get themeTaglineBluerose =>
      'Полуночный бархат, сапфировые розы и платиновая кромка.';

  @override
  String get themeTaglineBluelotus =>
      'Вода в лунном свете, сапфировые лепестки и золотое сердце.';

  @override
  String discoverMessageLikeSent(String name) {
    return 'Лайк отправлен: $name. Чат откроется, как только тебе ответят взаимностью.';
  }

  @override
  String get notificationsDismissFailed =>
      'Не удалось удалить уведомление. Попробуй ещё раз.';

  @override
  String get notificationsReadAllFailed =>
      'Не удалось отметить всё как прочитанное. Попробуй ещё раз.';

  @override
  String get blogReportSubmitted => 'Жалоба отправлена. Спасибо.';

  @override
  String get settingsSectionAccount => 'Аккаунт';

  @override
  String settingsSignedInAs(String username) {
    return 'Вход выполнен: @$username';
  }

  @override
  String get settingsSignOut => 'Выйти';

  @override
  String get settingsSignOutSubtitle => 'Заверши сеанс на этом устройстве';

  @override
  String get settingsSignOutAllTitle => 'Выйти на всех устройствах';

  @override
  String get settingsSignOutAllSubtitle =>
      'Заверши все сеансы на всех телефонах и в браузерах';

  @override
  String get settingsSignOutConfirmTitle => 'Выйти?';

  @override
  String get settingsSignOutConfirmBody =>
      'Чтобы снова войти на этом устройстве, понадобятся имя пользователя и пароль.';

  @override
  String get settingsSignOutAllConfirmTitle => 'Выйти на всех устройствах?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'Сеанс завершится на всех телефонах, планшетах и в браузерах, включая это устройство. Все, кто вошёл в твой аккаунт в другом месте, будут отключены.';

  @override
  String get settingsSignOutAllConfirmAction => 'Выйти везде';

  @override
  String get settingsSignOutAllFailed =>
      'Не удалось выйти на других устройствах. Проверь подключение и попробуй ещё раз.';

  @override
  String get supportPaymentHelpLink => 'Проблема с оплатой? Напиши в поддержку';

  @override
  String get supportReportHelpLink => 'Нужна помощь? Напиши в поддержку';

  @override
  String get supportSignedOutHelpLink => 'Другая проблема? Напиши в поддержку';

  @override
  String get supportGuestSubtitle =>
      'Не получается войти или что-то другое не работает? Расскажи, что случилось, и мы ответим по электронной почте.';

  @override
  String get supportGuestEmailLabel => 'Твой email';

  @override
  String get supportGuestEmailHint => 'Мы ответим на этот адрес';

  @override
  String get supportGuestNameLabel => 'Твоё имя (необязательно)';

  @override
  String get supportGuestEmailInvalid =>
      'Введи действующий адрес электронной почты, чтобы мы могли ответить.';

  @override
  String get supportGuestSentTitle => 'Запрос отправлен';

  @override
  String supportGuestSentBody(String reference, String email) {
    return 'Спасибо. Номер твоего запроса: $reference. Мы ответим на $email.';
  }

  @override
  String get supportGuestUnavailableBody =>
      'Сейчас нельзя отправить запрос в поддержку из приложения. По срочным вопросам пиши на support@connect.example.';

  @override
  String get supportDraftRestored => 'Мы сохранили твой неотправленный запрос.';

  @override
  String get supportDraftDiscard => 'Удалить черновик';

  @override
  String get discoverActionUndo => 'Отменить';

  @override
  String get discoverActionLike => 'Нравится';

  @override
  String get discoverActionSuperLike => 'Суперлайк';

  @override
  String get navQaVerifyShortcut => 'Подтвердить';

  @override
  String get chatMessageDeletedPlaceholder => 'Сообщение удалено';

  @override
  String get chatGiftYouSentHeading => 'Подарок от тебя';

  @override
  String get commonMemberFallbackName => 'Участник';

  @override
  String get giftNameRoseRedSingle => 'Одна красная роза';

  @override
  String get giftNameRosePinkSoft => 'Розовая роза';

  @override
  String get giftNameRoseWhitePure => 'Белая роза';

  @override
  String get giftNameRoseYellowFriendship => 'Жёлтая роза';

  @override
  String get giftNameRoseLavenderCrush => 'Лавандовая роза';

  @override
  String get giftNameRoseBlueRare => 'Синяя роза';

  @override
  String get giftNameRoseBlackMystery => 'Чёрная роза';

  @override
  String get giftNameRoseSparkle => 'Сверкающая роза';

  @override
  String get giftNameRoseHeartPetal => 'Роза с лепестками-сердечками';

  @override
  String get giftNameRoseNeonGlow => 'Неоновая роза';

  @override
  String get giftNameRoseRain => 'Дождь из роз';

  @override
  String get giftNameRoseBurningFlame => 'Пылающая роза';

  @override
  String get giftNameRoseGolden => 'Золотая роза';

  @override
  String get giftNameRoseCrystal => 'Хрустальная роза';

  @override
  String get giftNameRoseBouquet12 => 'Букет роз (12)';

  @override
  String get giftNameRoseBouquet24 => 'Букет роз (24)';

  @override
  String get giftNameRoseSeasonalWeekly =>
      'Сезонная роза, лимитированная серия';

  @override
  String get giftNameChocolateBox => 'Коробка конфет';

  @override
  String get giftNameHeartBalloon => 'Шарик-сердце';

  @override
  String get giftNameTeddyBear => 'Плюшевый мишка';

  @override
  String get giftNameFlowerBouquet => 'Букет цветов';

  @override
  String get giftNameJewelleryBox => 'Шкатулка для украшений';

  @override
  String get giftNameChampagneToast => 'Тост с шампанским';

  @override
  String get giftNameHeartExplosion => 'Взрыв сердечек';

  @override
  String get giftNameConfettiShower => 'Дождь из конфетти';

  @override
  String get giftNameFireworksBurst => 'Фейерверк';

  @override
  String get giftNameStarShower => 'Звездопад';

  @override
  String get giftNameGoldenSparkle => 'Золотое сияние';

  @override
  String get giftNameRainbowWave => 'Радужная волна';

  @override
  String get giftNameCoffeeDateInvite => 'Приглашение на кофе';

  @override
  String get giftNamePicnicInvite => 'Приглашение на пикник';

  @override
  String get giftNameMovieNightInvite => 'Приглашение на киновечер';

  @override
  String get giftNameSunsetWalkInvite => 'Приглашение на прогулку на закате';

  @override
  String get giftNameDateNightCard => 'Открытка для свидания';

  @override
  String get giftNameValentineSurprise => 'Сюрприз ко Дню святого Валентина';

  @override
  String get giftNameDiamondRing => 'Кольцо с бриллиантом';

  @override
  String get giftNameLuxuryDate => 'Роскошное свидание';

  @override
  String get blogPublicationUnavailableTitle => 'Публикация недоступна';

  @override
  String get blogPublicationUnavailableExcerpt =>
      'Источник изменился или доступ отозван. Отзови эту ссылку.';

  @override
  String get blogNoticeKindPost => 'Запись';

  @override
  String get blogNoticeKindResponse => 'Ответ';

  @override
  String get blogNoticeKindPublication => 'Публичная копия';

  @override
  String get blogNoticeKindThemeEntry => 'Фото по теме';

  @override
  String get blogNoticeKindClub => 'Клуб';

  @override
  String get blogNoticeKindClubPost => 'Запись в клубе';

  @override
  String get blogNoticeKindReview => 'Отзыв';

  @override
  String get blogNoticeKindList => 'Список';

  @override
  String get blogNoticeKindComment => 'Комментарий';

  @override
  String get blogNoticeKindPhotoComment => 'Комментарий к фото';

  @override
  String get blogNoticeKindChatMessage => 'Сообщение в чате';

  @override
  String get blogNoticeKindGroup => 'Группа';

  @override
  String get blogNoticeKindOther => 'Контент';

  @override
  String get blogNoticeStatusPending => 'На проверке';

  @override
  String get blogNoticeStatusDismissed => 'Без мер';

  @override
  String get blogNoticeStatusRemoved => 'Удалено';

  @override
  String get blogNoticeStatusRestored => 'Восстановлено';

  @override
  String get engagementTrustMilestoneProfileDepth => 'Полнота профиля';

  @override
  String get engagementTrustMilestoneCommunication => 'Общение';

  @override
  String get engagementTrustMilestoneConsistency => 'Постоянство';

  @override
  String get engagementTrustMilestonePromptCompletion => 'Ответы на вопросы';

  @override
  String get engagementTrustMilestoneActivitySignals => 'Сигналы активности';

  @override
  String get engagementTrustMilestoneUnsafeSignals => 'Сигналы о безопасности';

  @override
  String get engagementTrustMilestoneReportPenalty => 'Штраф за жалобы';

  @override
  String get engagementTrustMilestoneVerification => 'Верификация согласована';

  @override
  String get engagementTrustMilestoneSafety => 'Безопасность';

  @override
  String engagementTrustMilestoneLine(String label, String value) {
    return '$label: $value';
  }

  @override
  String get networkOfflineTryAgain =>
      'Сейчас не удаётся подключиться. Проверь интернет-соединение и попробуй ещё раз.';

  @override
  String get apiErrorFeatureUnavailable => 'Эта функция сейчас недоступна.';

  @override
  String get apiErrorConversationUnavailable =>
      'Этот разговор больше недоступен.';

  @override
  String get apiErrorMemberUnavailable => 'Этот участник недоступен.';

  @override
  String get apiErrorChatLocked => 'Сначала разблокируй этот разговор.';

  @override
  String get apiErrorCopilotDailyLimit =>
      'Черновики на сегодня закончились. Это сообщение придётся написать самостоятельно.';

  @override
  String get apiErrorCopilotUnavailable =>
      'Помощь с черновиком сейчас недоступна.';

  @override
  String get apiErrorCopilotProfileUnavailable =>
      'Профиль собеседника сейчас недоступен.';

  @override
  String get apiErrorDatePlanAlreadyOpen =>
      'Для этой пары уже есть открытый план свидания.';

  @override
  String get apiErrorDatePlanMatchInactive =>
      'Для плана свидания нужна активная пара.';

  @override
  String get apiErrorDatePlanNotOpen => 'Этот план свидания больше не активен.';

  @override
  String get apiErrorDatePlanCheckInTooEarly =>
      'Отметиться можно, когда свидание начнётся.';

  @override
  String get apiErrorDatePlanDebriefTooEarly =>
      'Подведение итогов откроется, когда свидание начнётся.';

  @override
  String get apiErrorSharedAvailabilityChanged =>
      'Общее свободное время изменилось. Обнови предложенное время или выбери время сам(а).';

  @override
  String get apiErrorGraduationAlreadyOpen =>
      'Для этой пары уже есть открытое предложение уйти вдвоём.';

  @override
  String get apiErrorGraduationMatchInactive =>
      'Чтобы уйти вдвоём, нужна активная пара.';

  @override
  String get apiErrorGraduationNotOpen =>
      'Это предложение уйти вдвоём больше не активно.';

  @override
  String get apiErrorGraduationAlreadyConfirmed => 'Вы уже ушли вдвоём.';

  @override
  String get apiErrorOutOfDate =>
      'Данные устарели. Обнови экран и попробуй ещё раз.';

  @override
  String get apiErrorOutcomeUncertain =>
      'Не удалось это подтвердить. Обнови экран и проверь, прежде чем пробовать снова.';

  @override
  String get apiErrorInsufficientCoins => 'Для этого не хватает монет.';

  @override
  String get apiErrorChannelReadOnly => 'Этот чат сейчас только для чтения.';

  @override
  String get apiErrorRoomFull =>
      'Эта комната сейчас заполнена. Попробуй чуть позже.';

  @override
  String get apiErrorRoomRemoved =>
      'Ведущий удалил тебя из этой комнаты. Ты сможешь вернуться, когда эта сессия закончится.';

  @override
  String get apiErrorRoomNotJoined => 'Тебя нет в этой комнате.';

  @override
  String get apiErrorDailyMessageLimit =>
      'Сообщения на сегодня закончились. Попробуй после обновления лимита или улучши тариф.';

  @override
  String get apiErrorDailyLikeLimit =>
      'Лайки на сегодня закончились. Попробуй после обновления лимита или улучши тариф.';

  @override
  String get apiErrorFriendRequired => 'Сначала вам нужно стать друзьями.';

  @override
  String get apiErrorVouchExists =>
      'Ты уже написал(а) рекомендацию для этого человека.';

  @override
  String get apiErrorIntroUnavailable => 'Это знакомство больше недоступно.';

  @override
  String get apiErrorIntroAlreadyOpen => 'Знакомство этих двоих уже открыто.';

  @override
  String get apiErrorIntroNotOpen => 'Это знакомство больше не активно.';

  @override
  String get apiErrorTooManyTries =>
      'Слишком много попыток. Подожди немного и попробуй ещё раз.';

  @override
  String get apiErrorQuestCooldown =>
      'У этого задания перерыв. Попробуй чуть позже.';

  @override
  String get apiErrorQuestSelfReview =>
      'Твой ответ на задание проверяет твоя пара, а не ты.';

  @override
  String get apiErrorQuestNotParticipant =>
      'Участвовать в задании могут только участники этой пары.';

  @override
  String get apiErrorPaymentsUnavailable => 'Покупка монет сейчас недоступна.';

  @override
  String get apiErrorServiceBusy =>
      'Сервис сейчас перегружен. Попробуй через минуту.';

  @override
  String get apiErrorSignInAgain => 'Войди снова, чтобы продолжить.';

  @override
  String get friendsMemberFallback => 'Один участник';

  @override
  String get friendsActivityFallback => 'Активность';

  @override
  String get membershipPlanFallback => 'Тариф';

  @override
  String get membershipSubscriptionFallback => 'Подписка';

  @override
  String engagementLevelRewardFallback(int level) {
    return 'Награда за уровень $level';
  }

  @override
  String get engagementTrustBadgeUnknown => 'Неизвестный значок';

  @override
  String get firstChapterComfortDefaultLanguage => 'Русский';

  @override
  String paymentWalletBalanceCoins(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString монеты',
      many: '$countString монет',
      few: '$countString монеты',
      one: '$countString монета',
    );
    return '$_temp0';
  }

  @override
  String get languageIntroSignedOut =>
      'Выбери язык Connect. Он сразу применится, а при входе сохранится в твоём аккаунте.';

  @override
  String languagePickerButtonSemantics(String language) {
    return 'Язык: $language. Сменить язык';
  }

  @override
  String get authErrorUsernameTaken =>
      'Это имя пользователя уже занято. Попробуй другое.';

  @override
  String get authErrorAccountSuspended =>
      'Этот аккаунт заблокирован. Если считаешь это ошибкой, напиши в поддержку.';

  @override
  String get authErrorAccountLocked =>
      'Слишком много попыток входа. Попробуй снова через несколько минут.';

  @override
  String get authErrorTooManyRequests =>
      'Слишком много попыток. Подожди немного и попробуй снова.';

  @override
  String get authErrorAccountTypeUnavailable =>
      'Этот тип аккаунта сейчас недоступен.';

  @override
  String get authErrorNetwork =>
      'Сейчас не удаётся подключиться. Проверь интернет и попробуй снова.';

  @override
  String get profileSetupReorderPhoto =>
      'Перетащи, чтобы изменить порядок фото';

  @override
  String get profileLanguageAssamese => 'Ассамский';

  @override
  String get profileLanguageBengali => 'Бенгальский';

  @override
  String get profileLanguageBodo => 'Бодо';

  @override
  String get profileLanguageDogri => 'Догри';

  @override
  String get profileLanguageEnglish => 'Английский';

  @override
  String get profileLanguageGujarati => 'Гуджарати';

  @override
  String get profileLanguageHindi => 'Хинди';

  @override
  String get profileLanguageKannada => 'Каннада';

  @override
  String get profileLanguageKashmiri => 'Кашмири';

  @override
  String get profileLanguageKonkani => 'Конкани';

  @override
  String get profileLanguageMaithili => 'Майтхили';

  @override
  String get profileLanguageMalayalam => 'Малаялам';

  @override
  String get profileLanguageManipuri => 'Манипури';

  @override
  String get profileLanguageMarathi => 'Маратхи';

  @override
  String get profileLanguageNepali => 'Непальский';

  @override
  String get profileLanguageOdia => 'Ория';

  @override
  String get profileLanguagePunjabi => 'Панджаби';

  @override
  String get profileLanguageSanskrit => 'Санскрит';

  @override
  String get profileLanguageSantali => 'Сантали';

  @override
  String get profileLanguageSindhi => 'Синдхи';

  @override
  String get profileLanguageTamil => 'Тамильский';

  @override
  String get profileLanguageTelugu => 'Телугу';

  @override
  String get profileLanguageUrdu => 'Урду';

  @override
  String get profileCountryIndia => 'Индия';

  @override
  String get profileCountryUnitedKingdom => 'Великобритания';

  @override
  String get profileCountryIreland => 'Ирландия';

  @override
  String get profileCountryGermany => 'Германия';

  @override
  String get profileCountryAustria => 'Австрия';

  @override
  String get profileMasterWorkoutSometimes => 'Иногда';

  @override
  String get profileMasterWorkoutWeekly => 'Каждую неделю';

  @override
  String get profileMasterTravelRoadTrips => 'Автопутешествия';

  @override
  String get profileMasterTravelBackpacking => 'Путешествия с рюкзаком';

  @override
  String get profileMasterTravelLuxuryShort => 'Люкс';

  @override
  String get profileMasterTravelStaycations => 'Отдых дома';

  @override
  String get profileMasterPoliticsSimilarShort => 'Похожие';

  @override
  String get profileMasterPoliticsModerate => 'Умеренные';

  @override
  String get profileMasterPoliticsAny => 'Любые';

  @override
  String discoverOpenMemberProfile(String name) {
    return 'Открыть профиль: $name';
  }

  @override
  String get chatCopilotDisclosureText =>
      'Скажи своими словами. Если отправишь черновик без изменений, собеседник увидит, что он написан с помощью.';
}
