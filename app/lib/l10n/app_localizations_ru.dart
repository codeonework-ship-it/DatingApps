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
      'Warm ivory and forest by day. Soft mint and deep forest by night.';

  @override
  String get settingsLooksClassicLabel => 'Today';

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
      'Shape a first hello together. Contact sharing starts off.';

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
  String get planHeadlineFriendsAlerted => 'Your request for help is recorded';

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
      'Choose trusted contacts to share your updates.';

  @override
  String get planFriendsKnowProposed =>
      'Contact sharing is optional for each plan.';

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
      'This starts between you and your date. After proposing, choose trusted contacts if you want to share plan and check-in updates.';

  @override
  String get planSectionWhen => 'Когда';

  @override
  String get planSectionWhat => 'Что';

  @override
  String get planSectionGroups => 'Trusted contacts';

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
      'Accept this plan with your date. Choose trusted contacts afterwards if you want to share your updates.';

  @override
  String get planAcceptButton => 'Accept plan';

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
      'Propose a date from a conversation. You choose whether to share plan and check-in updates with trusted contacts.';

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
  String get plansNextUpcoming => 'Confirmed. Your time together is planned.';

  @override
  String get plansNextCheckin => 'Check in after your date';

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
      'Plans appear here when friends explicitly choose to share with you.';

  @override
  String get plansViaGroup => 'Shared with you';

  @override
  String get plansViaFriend => 'Trusted contact';

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
}
