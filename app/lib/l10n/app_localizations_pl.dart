// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get navDiscover => 'Odkrywaj';

  @override
  String get navMatches => 'Dopasowania';

  @override
  String get navEngage => 'Aktywności';

  @override
  String get navProfile => 'Profil';

  @override
  String get navSettings => 'Ustawienia';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsEditProfileTitle => 'Edytuj profil';

  @override
  String get settingsEditProfileSubtitle => 'Zaktualizuj swoje dane';

  @override
  String get settingsPhotosTitle => 'Zdjęcia';

  @override
  String get settingsPhotosSubtitle => 'Zarządzaj zdjęciami';

  @override
  String get settingsSectionPreferences => 'Preferencje';

  @override
  String get settingsAppearanceTitle => 'Wygląd';

  @override
  String get settingsAppearanceSubtitle => 'Zapisane na Twoim koncie';

  @override
  String get settingsThemeLight => 'Jasny';

  @override
  String get settingsThemeDark => 'Ciemny';

  @override
  String get settingsThemeMatchDevice => 'Jak w urządzeniu';

  @override
  String get settingsLooksTitle => 'Style';

  @override
  String get settingsLooksClassicDescription =>
      'Warm ivory and forest by day. Soft mint and deep forest by night.';

  @override
  String get settingsLooksClassicLabel => 'Today';

  @override
  String get settingsThemeSaveFailed =>
      'Nie udało się zapisać motywu. Spróbuj ponownie.';

  @override
  String get settingsLanguageTitle => 'Język';

  @override
  String get settingsLanguageSubtitle => 'Wybierz język aplikacji';

  @override
  String get settingsDatingPreferencesTitle => 'Preferencje randkowe';

  @override
  String get settingsDatingPreferencesSubtitle =>
      'Wiek, lokalizacja, zainteresowania';

  @override
  String get settingsAccountDataTitle => 'Konto i dane';

  @override
  String get settingsAccountDataSubtitle =>
      'Ukryj, pobierz lub usuń swoje konto';

  @override
  String get settingsNotificationsTitle => 'Powiadomienia';

  @override
  String get settingsNotificationsSubtitle => 'Powiadomienia push i e-mail';

  @override
  String get settingsSectionEngagement => 'Aktywności';

  @override
  String get settingsTrustBadgesTitle => 'Odznaki zaufania';

  @override
  String get settingsTrustBadgesSubtitle =>
      'Zobacz zdobyte odznaki i historię zaufania';

  @override
  String get settingsTrustFiltersTitle => 'Filtry zaufania';

  @override
  String get settingsTrustFiltersSubtitle =>
      'Ustal wymagania zaufania przy odkrywaniu';

  @override
  String get settingsConversationRoomsTitle => 'Pokoje rozmów';

  @override
  String get settingsConversationRoomsSubtitle =>
      'Przeglądaj pokoje, dołączaj, opuszczaj je i moderuj';

  @override
  String get settingsFriendsTitle => 'Znajomi i kontakty';

  @override
  String get settingsFriendsSubtitle => 'Buduj i pielęgnuj znajomości';

  @override
  String get settingsCallHistoryTitle => 'Historia połączeń';

  @override
  String get settingsCallHistorySubtitle => 'Przejrzyj wcześniejsze połączenia';

  @override
  String get settingsMatchNudgesTitle => 'Zaczepki';

  @override
  String get settingsMatchNudgesSubtitle => 'Ożyw rozmowy, które ucichły';

  @override
  String get settingsSubscriptionsTitle => 'Subskrypcje';

  @override
  String get settingsSubscriptionsSubtitle =>
      'Plany, status dostępu i płatności';

  @override
  String get settingsSectionApp => 'Aplikacja';

  @override
  String get settingsPrivacySafetyTitle => 'Prywatność i bezpieczeństwo';

  @override
  String get settingsPrivacySafetySubtitle =>
      'Zarządzaj ustawieniami prywatności';

  @override
  String get settingsGovernmentVerificationTitle => 'Weryfikacja tożsamości';

  @override
  String get settingsGovernmentVerificationSubtitle =>
      'Sprawdź status weryfikacji tożsamości';

  @override
  String get settingsQaVerificationUploadTitle => 'Przesyłanie weryfikacji QA';

  @override
  String get settingsQaVerificationUploadSubtitle =>
      'Ścieżka dokumentu i selfie tylko do automatyzacji';

  @override
  String get settingsHelpSupportTitle => 'Pomoc i wsparcie';

  @override
  String get settingsHelpSupportSubtitle => 'FAQ i kontakt ze wsparciem';

  @override
  String get settingsAboutTitle => 'O aplikacji';

  @override
  String get settingsAboutSubtitle => 'Szczegóły aplikacji i technologia';

  @override
  String get settingsLogout => 'Wyloguj się';

  @override
  String get languageTitle => 'Język';

  @override
  String get languageIntro =>
      'Wybierz język, w którym ma działać Connect. Twój wybór jest zapisywany na koncie i obowiązuje na każdym urządzeniu, na którym się logujesz.';

  @override
  String get languageUseDevice => 'Użyj języka urządzenia';

  @override
  String get languageUseDeviceSubtitle =>
      'Zgodnie z ustawieniem języka w telefonie';

  @override
  String get languageSaveFailed =>
      'Nie udało się zapisać języka. Spróbuj ponownie.';

  @override
  String get notificationsTitle => 'Powiadomienia';

  @override
  String get notificationsInboxTitle => 'Skrzynka powiadomień';

  @override
  String get notificationsInboxCaughtUp => 'Wszystko przeczytane';

  @override
  String notificationsInboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieprzeczytanego',
      many: '$count nieprzeczytanych',
      few: '$count nieprzeczytane',
      one: '1 nieprzeczytane',
    );
    return '$_temp0';
  }

  @override
  String get notificationsInAppTitle => 'Powiadomienia w aplikacji';

  @override
  String get notificationsInAppSubtitle =>
      'Pokazuj powiadomienia podczas korzystania z aplikacji';

  @override
  String get notificationsPushTitle => 'Powiadomienia push';

  @override
  String get notificationsPushSubtitle =>
      'Zezwól na dostarczanie, gdy aplikacja działa w tle';

  @override
  String get notificationsNewMatchesTitle => 'Nowe dopasowania';

  @override
  String get notificationsNewMatchesSubtitle =>
      'Dostań powiadomienie, gdy pojawi się dopasowanie';

  @override
  String get notificationsNewMessagesTitle => 'Nowe wiadomości';

  @override
  String get notificationsNewMessagesSubtitle =>
      'Dostań powiadomienie o wiadomościach na czacie';

  @override
  String get notificationsLikesTitle => 'Polubienia';

  @override
  String get notificationsLikesSubtitle =>
      'Dostań powiadomienie, gdy ktoś Cię polubi';

  @override
  String get notificationsMatchNudgesTitle => 'Zaczepki';

  @override
  String get notificationsMatchNudgesSubtitle =>
      'Dostań powiadomienie, gdy dopasowanie Cię zaczepi';

  @override
  String get notificationsIncomingCallsTitle => 'Połączenia przychodzące';

  @override
  String get notificationsIncomingCallsSubtitle =>
      'Pokazuj alerty o połączeniach przychodzących';

  @override
  String get notificationsSafetyTitle => 'Aktualizacje bezpieczeństwa';

  @override
  String get notificationsSafetySubtitle =>
      'Otrzymuj ważne informacje o statusie bezpieczeństwa';

  @override
  String get notificationsFriendPlansTitle => 'Randki znajomych';

  @override
  String get notificationsFriendPlansSubtitle =>
      'Wiedz, kiedy znajomy planuje randkę lub daje znać, że wszystko w porządku';

  @override
  String get welcomeTagline => 'Stworzone dla prawdziwego życia.';

  @override
  String get welcomePhotoNote => 'Celem jest spotkanie na żywo.';

  @override
  String get welcomeHeadlineLead => 'Dobra historia\nzaczyna się od ';

  @override
  String get welcomeHeadlineAccent => 'cześć.';

  @override
  String get welcomeBody =>
      'Znajdź kogoś, kto naprawdę do Ciebie pasuje. Reszta przyjdzie sama.';

  @override
  String get welcomeCreateAccount => 'Załóż konto';

  @override
  String get welcomeAlreadyMember => 'Masz już konto? ';

  @override
  String get welcomeSignIn => 'Zaloguj się';

  @override
  String get welcomeFooter => '18+  ·  Twoje tempo. Twój wybór.';

  @override
  String get authBackTooltip => 'Wróć na ekran powitalny';

  @override
  String get authHeadline => 'Dobrze Cię widzieć.';

  @override
  String get authSubtitle => 'Podaj nazwę użytkownika i hasło, aby kontynuować';

  @override
  String get authWelcomeBack => 'Witaj z powrotem';

  @override
  String get authNextHello => 'Twoje kolejne cześć już czeka.';

  @override
  String get authUsernameHint => 'nazwa użytkownika';

  @override
  String get authPasswordHint => 'Hasło';

  @override
  String get authShowPassword => 'Pokaż hasło';

  @override
  String get authHidePassword => 'Ukryj hasło';

  @override
  String get authCantSignIn => 'Nie możesz się zalogować?';

  @override
  String get authSignIn => 'Zaloguj się';

  @override
  String get authPrivacyNote =>
      'Hasło jest wysyłane tylko przy logowaniu i nigdy nie jest zapisywane w aplikacji.';

  @override
  String get authEnterUsername => 'Podaj nazwę użytkownika.';

  @override
  String get authEnterPassword => 'Podaj hasło.';

  @override
  String get commonYes => 'Tak';

  @override
  String get commonNo => 'Nie';

  @override
  String get planVenueCoffee => 'Kawa';

  @override
  String get planVenueMeal => 'Wspólny posiłek';

  @override
  String get planVenueDrinks => 'Drinki';

  @override
  String get planVenueWalk => 'Spacer';

  @override
  String get planVenueActivity => 'Jakaś aktywność';

  @override
  String get planVenueEvent => 'Wydarzenie';

  @override
  String get planVenueVideoCall => 'Rozmowa wideo';

  @override
  String get planVenueOther => 'Coś innego';

  @override
  String planProposeTitle(String name) {
    return '$name i Ty: zaplanujcie randkę';
  }

  @override
  String get planProposeSubtitle =>
      'Shape a first hello together. Contact sharing starts off.';

  @override
  String get planProposeButton => 'Zaproponuj';

  @override
  String planHeadlineProposed(String name) {
    return '$name proponuje randkę';
  }

  @override
  String planHeadlineWaiting(String name) {
    return 'Czekamy, aż $name odpowie';
  }

  @override
  String get planHeadlineUpcoming => 'Randka potwierdzona';

  @override
  String get planHeadlineCheckin => 'Jak poszło?';

  @override
  String get planHeadlineDebrief => 'Jak było?';

  @override
  String get planHeadlineDebriefComplete => 'Podsumowanie gotowe';

  @override
  String planHeadlineWaitingDebrief(String name) {
    return 'Czekamy, aż $name doda podsumowanie';
  }

  @override
  String get planHeadlineCheckedInSafe => 'Potwierdzono: wszystko w porządku';

  @override
  String get planHeadlineFriendsAlerted => 'Your request for help is recorded';

  @override
  String get planHeadlineDefault => 'Randka';

  @override
  String get planStatusProposed => 'Zaproponowana';

  @override
  String get planStatusConfirmed => 'Potwierdzona';

  @override
  String get planDebriefButton => 'Dziesięciosekundowe podsumowanie';

  @override
  String get planDecline => 'Odrzuć';

  @override
  String get planAccept => 'Akceptuj';

  @override
  String get planFriendsKnowAccepted =>
      'Choose trusted contacts to share your updates.';

  @override
  String get planFriendsKnowProposed =>
      'Contact sharing is optional for each plan.';

  @override
  String get planCancel => 'Odwołaj randkę';

  @override
  String get planNeedHelp => 'Potrzebuję pomocy';

  @override
  String get planImSafe => 'Wszystko OK';

  @override
  String get planCancelDialogTitle => 'Odwołać tę randkę?';

  @override
  String planCancelDialogBody(String name) {
    return '$name i wszyscy, którym to udostępniasz, dostaną wiadomość.';
  }

  @override
  String get planKeepIt => 'Zostaw';

  @override
  String get planProposeIntro =>
      'This starts between you and your date. After proposing, choose trusted contacts if you want to share plan and check-in updates.';

  @override
  String get planSectionWhen => 'Kiedy';

  @override
  String get planSectionWhat => 'Co';

  @override
  String get planSectionGroups => 'Trusted contacts';

  @override
  String planDurationHours(int hours) {
    return '$hours godz.';
  }

  @override
  String get planPlaceLabel => 'Miejsce (opcjonalnie)';

  @override
  String get planPlaceHint => 'Najlepiej miejsce publiczne';

  @override
  String get planAreaLabel => 'Okolica lub dzielnica';

  @override
  String get planNoteLabel => 'Wiadomość dla drugiej osoby (opcjonalnie)';

  @override
  String get planFutureTimeError => 'Wybierz termin w przyszłości.';

  @override
  String get planProposeFailed => 'Nie udało się zaproponować tej randki.';

  @override
  String get planSendButton => 'Wyślij propozycję';

  @override
  String get planAcceptTitle => 'Zaakceptować randkę?';

  @override
  String get planAcceptIntro =>
      'Accept this plan with your date. Choose trusted contacts afterwards if you want to share your updates.';

  @override
  String get planAcceptButton => 'Accept plan';

  @override
  String debriefTitle(String name) {
    return '$name – jak było?';
  }

  @override
  String get debriefIntro =>
      'Twoje odpowiedzi są prywatne. Gdy oboje potwierdzicie, że randka się odbyła, liczy się do Twojej odznaki Shows Up.';

  @override
  String get debriefHappened => 'Czy randka się odbyła?';

  @override
  String get debriefMeetAgain => 'Chcesz się spotkać ponownie?';

  @override
  String get debriefFeltSafe => 'Czy czułeś(-aś) się bezpiecznie?';

  @override
  String get debriefNoteLabel => 'Chcesz coś dodać? (opcjonalnie)';

  @override
  String get debriefMissingHappened => 'Powiedz nam, czy randka się odbyła.';

  @override
  String get debriefSaveFailed => 'Nie udało się zapisać podsumowania.';

  @override
  String get debriefSave => 'Zapisz podsumowanie';

  @override
  String get debriefUnsafeTitle => 'Przykro nam, że nie było bezpiecznie';

  @override
  String debriefUnsafeBody(String name) {
    return 'Twoja odpowiedź trafi do naszego zespołu ds. bezpieczeństwa. Chcesz też zgłosić tę osobę ($name)?';
  }

  @override
  String get debriefNotNow => 'Nie teraz';

  @override
  String get debriefReport => 'Zgłoś';

  @override
  String get plansTitle => 'Randki';

  @override
  String get plansTabMine => 'Moje';

  @override
  String get plansTabFriends => 'Znajomi';

  @override
  String get plansEmptyMineTitle => 'Jeszcze nie ma randek';

  @override
  String get plansEmptyMineBody =>
      'Propose a date from a conversation. You choose whether to share plan and check-in updates with trusted contacts.';

  @override
  String plansWith(String name) {
    return 'Randka: $name';
  }

  @override
  String get plansNextDecide => 'Czekamy na Twoją odpowiedź';

  @override
  String plansNextAwait(String name) {
    return 'Czekamy, aż $name odpowie';
  }

  @override
  String get plansNextUpcoming => 'Confirmed. Your time together is planned.';

  @override
  String get plansNextCheckin => 'Check in after your date';

  @override
  String get plansNextDebrief => 'Opowiedz nam, jak było';

  @override
  String get plansNextCancelled => 'Odwołana';

  @override
  String get plansNextDone => 'Zakończona';

  @override
  String get plansEmptyFriendsTitle => 'Jeszcze nic nie udostępniono';

  @override
  String get plansEmptyFriendsBody =>
      'Plans appear here when friends explicitly choose to share with you.';

  @override
  String get plansViaGroup => 'Shared with you';

  @override
  String get plansViaFriend => 'Trusted contact';

  @override
  String plansFriendNeedsHelp(String name) {
    return '$name prosi o pomoc. Odezwij się teraz.';
  }

  @override
  String plansFriendMissedCheckin(String name) {
    return '$name – wciąż brak potwierdzenia.';
  }

  @override
  String plansFriendCheckedInSafe(String name, String via) {
    return '$name daje znać: wszystko OK · $via';
  }

  @override
  String plansFriendStatusLine(String via, String status) {
    return '$via · $status';
  }

  @override
  String get plansStatusWordProposed => 'zaproponowana';

  @override
  String get plansStatusWordConfirmed => 'potwierdzona';

  @override
  String get plansStatusWordCancelled => 'odwołana';

  @override
  String get plansStatusWordHappened => 'odbyła się';

  @override
  String get chatEmptyDefault =>
      'Przywitaj się. Wiadomości pojawią się tutaj dla wszystkich w tej rozmowie.';

  @override
  String get chatNotSentRetry =>
      'Nie wysłano. Dotknij wiadomości, aby spróbować ponownie.';

  @override
  String get chatRetrySend => 'Wyślij ponownie';

  @override
  String get chatCopyText => 'Kopiuj tekst';

  @override
  String get chatDeleteMine => 'Usuń moją wiadomość';

  @override
  String get chatRemoveMessage => 'Usuń wiadomość';

  @override
  String get chatReportMessage => 'Zgłoś wiadomość';

  @override
  String get chatThisMember => 'Ten użytkownik';

  @override
  String get chatMember => 'Użytkownik';

  @override
  String get chatCopied => 'Skopiowano.';

  @override
  String get chatDeleteFailed => 'Nie udało się usunąć. Spróbuj ponownie.';

  @override
  String get chatSubtitleFriends => 'Znajomi';

  @override
  String chatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count osoby',
      many: '$count osób',
      few: '$count osoby',
      one: '1 osoba',
    );
    return '$_temp0';
  }

  @override
  String get chatReconnecting =>
      'Łączenie ponownie. Nowe wiadomości mogą chwilę poczekać.';

  @override
  String get chatUnavailable =>
      'Ta rozmowa jest niedostępna. Możliwe, że nie należysz już do niej.';

  @override
  String get chatTryAgain => 'Spróbuj ponownie';

  @override
  String get chatStatusNotSent => 'Nie wysłano · przytrzymaj, aby ponowić';

  @override
  String get chatStatusSending => 'Wysyłanie…';

  @override
  String get chatMessageRemoved => 'Wiadomość usunięta';

  @override
  String chatSemanticsYouAt(String time) {
    return 'Ty o $time';
  }

  @override
  String chatSemanticsMemberAt(String name, String time) {
    return '$name o $time';
  }

  @override
  String chatAboutMember(String name) {
    return 'O $name';
  }

  @override
  String get chatComposerHint => 'Napisz wiadomość';

  @override
  String get chatMutedComposerHint => 'Teraz nie możesz pisać';

  @override
  String get chatSend => 'Wyślij';

  @override
  String chatRoomMutedUntil(String when) {
    return 'Masz wyciszenie w tym pokoju do $when. Nadal możesz czytać.';
  }

  @override
  String get chatRoomMuted =>
      'Masz wyciszenie w tym pokoju. Nadal możesz czytać.';

  @override
  String chatReadOnlyUntil(String when) {
    return 'Możesz czytać tę rozmowę, ale nie możesz pisać do $when.';
  }

  @override
  String get chatReadOnly =>
      'Możesz czytać tę rozmowę, ale teraz nie możesz pisać.';

  @override
  String get chatMuteTooltip => 'Wycisz powiadomienia';

  @override
  String get chatMutedTooltip => 'Powiadomienia wyciszone';

  @override
  String get chatMuteSheetTitle => 'Wycisz powiadomienia';

  @override
  String get chatMuteSheetBody =>
      'Wiadomości nadal będą tu trafiać, tylko bez powiadomień.';

  @override
  String get chatMuteOneHour => 'Na 1 godzinę';

  @override
  String get chatMuteEightHours => 'Na 8 godzin';

  @override
  String get chatMuteOneWeek => 'Na 1 tydzień';

  @override
  String get chatMuteForever => 'Dopóki ich nie włączę';

  @override
  String get chatUnmute => 'Włącz powiadomienia ponownie';

  @override
  String chatMutedUntilLabel(String when) {
    return 'Wyciszone do $when';
  }

  @override
  String get chatMutedIndefinitely =>
      'Wyciszone, dopóki nie włączysz powiadomień ponownie.';

  @override
  String get chatMuteDone => 'Powiadomienia wyciszone.';

  @override
  String get chatUnmuteDone => 'Powiadomienia są znowu włączone.';

  @override
  String get chatMuteFailed =>
      'Nie udało się zmienić powiadomień. Spróbuj ponownie.';

  @override
  String get roomsClosedSnack => 'Ten pokój jest zamknięty.';

  @override
  String get roomsChatNotOpen => 'Czat tego pokoju nie jest jeszcze otwarty.';

  @override
  String get roomsJoinFailed =>
      'Nie udało się dołączyć do pokoju. Spróbuj ponownie.';

  @override
  String get roomsStartRoom => 'Załóż pokój';

  @override
  String get roomsEyebrow => 'CZAT NA ŻYWO';

  @override
  String get roomsTitle => 'Pokoje';

  @override
  String get roomsSubtitle =>
      'Wpadnij do rozmowy. Jeśli z kimś złapiesz kontakt, dodaj tę osobę do znajomych.';

  @override
  String get roomsSectionRooms => 'POKOJE';

  @override
  String get roomsSectionYours => 'TWOJE POKOJE';

  @override
  String get roomsYoursCaption =>
      'Pokoje, w których jesteś. Dotknij, aby wrócić do rozmowy.';

  @override
  String get roomsSectionLive => 'TERAZ NA ŻYWO';

  @override
  String get roomsLiveTitle => 'Tu właśnie się rozmawia';

  @override
  String get roomsSectionBrowse => 'PRZEGLĄDAJ';

  @override
  String get roomsBrowseTitle => 'Znajdź swój pokój';

  @override
  String get roomsBrowseCaption =>
      'Zawsze otwarte. Wybierz temat, przywitaj się i zobacz, z kim złapiesz kontakt.';

  @override
  String get roomsNoFriendsHere =>
      'Żadnego z twoich znajomych nie ma teraz w tych pokojach.';

  @override
  String get roomsNoRoomsInTopic => 'W tym temacie nie ma jeszcze pokoi.';

  @override
  String get roomsSectionComingUp => 'WKRÓTCE';

  @override
  String get roomsComingUpCaption =>
      'Pokoje prowadzone przez użytkowników. Dołącz wcześniej, aby zająć miejsce.';

  @override
  String get roomsCategoryAll => 'Wszystkie';

  @override
  String get roomsCategoryTalk => 'Rozmowy';

  @override
  String get roomsCategoryInterests => 'Zainteresowania';

  @override
  String get roomsCategoryActive => 'W plenerze';

  @override
  String get roomsCategoryCity => 'Twoje miasto';

  @override
  String get roomsFriendsHereChip => 'Znajomi tutaj';

  @override
  String get roomsQuiet => 'Na razie cicho. Przywitaj się jako pierwszy.';

  @override
  String roomsPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count osoby',
      many: '$count osób',
      few: '$count osoby',
      one: '1 osoba',
    );
    return '$_temp0';
  }

  @override
  String roomsRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pokojach',
      many: '$count pokojach',
      few: '$count pokojach',
      one: '1 pokoju',
    );
    return '$_temp0';
  }

  @override
  String roomsChattingIn(String people, String rooms) {
    return '$people rozmawia w $rooms';
  }

  @override
  String roomsHereNow(int count) {
    return '$count teraz tutaj';
  }

  @override
  String roomsInTheRoom(int count) {
    return '$count w pokoju';
  }

  @override
  String roomsFriendsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count znajomego tutaj',
      many: '$count znajomych tutaj',
      few: '$count znajomych tutaj',
      one: '1 znajomy tutaj',
    );
    return '$_temp0';
  }

  @override
  String get roomsHostedByYou => 'Prowadzisz ty';

  @override
  String roomsHostedBy(String name) {
    return 'Prowadzi: $name';
  }

  @override
  String get roomsActionOpen => 'Otwórz';

  @override
  String get roomsActionFull => 'Pełny';

  @override
  String get roomsActionJoin => 'Dołącz';

  @override
  String roomsStartsAt(String time) {
    return 'Start o $time';
  }

  @override
  String roomsStartsOn(String day, String time) {
    return 'Start $day o $time';
  }

  @override
  String get roomsStartNameTooShort =>
      'Nadaj pokojowi nazwę z co najmniej 3 znaków.';

  @override
  String get roomsStartIntro =>
      'To ty prowadzisz: możesz ostrzegać, wyciszać lub usuwać osoby i zamknąć pokój, gdy skończysz. Jeden pokój naraz.';

  @override
  String get roomsStartNameLabel => 'Nazwa pokoju';

  @override
  String get roomsStartNameHint => 'Niedzielna wymiana książek';

  @override
  String get roomsStartAboutLabel => 'O czym jest? (opcjonalnie)';

  @override
  String get roomsStartTopic => 'Temat';

  @override
  String get roomsStartHowLong => 'Jak długo';

  @override
  String get roomsLength30Min => '30 min';

  @override
  String get roomsLength1Hour => '1 godzina';

  @override
  String get roomsLength2Hours => '2 godziny';

  @override
  String get roomsStartNow => 'Zacznij teraz';

  @override
  String get roomsRoleHost => 'Gospodarz';

  @override
  String get roomsRoleModerator => 'Moderator';

  @override
  String get roomsRoomFallback => 'Pokój';

  @override
  String roomsChatEmpty(String room) {
    return 'Jesteś w środku. Przywitaj się: wszyscy w pokoju $room widzą, co tu piszesz.';
  }

  @override
  String get roomsPeopleTooltip => 'Osoby w tym pokoju';

  @override
  String roomsLeaveTitle(String room) {
    return 'Opuścić pokój $room?';
  }

  @override
  String get roomsLeaveBody =>
      'Przestaniesz widzieć wiadomości z tego pokoju. Możesz wrócić, dopóki jest otwarty.';

  @override
  String get roomsLeaveAction => 'Opuść pokój';

  @override
  String get roomsLeaveFailed => 'Nie udało się wyjść. Spróbuj ponownie.';

  @override
  String roomsCloseTitle(String room) {
    return 'Zamknąć pokój $room?';
  }

  @override
  String get roomsCloseBody =>
      'Czat zakończy się dla wszystkich w pokoju. Tego nie można cofnąć.';

  @override
  String get roomsCloseAction => 'Zamknij pokój';

  @override
  String get roomsCloseFailed => 'Nie udało się zamknąć. Spróbuj ponownie.';

  @override
  String get roomsMenuTooltip => 'Opcje pokoju';

  @override
  String get roomsMenuPeople => 'Kto tu jest';

  @override
  String get roomsMenuModerate => 'Moderuj';

  @override
  String roomsModerateTitle(String room) {
    return 'Moderuj pokój $room';
  }

  @override
  String get roomsModerateIntro =>
      'Dotknij osoby, aby ją ostrzec, wyciszyć lub usunąć. Wyciszeni nadal mogą czytać; usunięci mogą wrócić po zakończeniu sesji.';

  @override
  String get roomsPeopleIntro =>
      'Złapałeś z kimś kontakt? Dodaj tę osobę do znajomych, aby rozmawiać dalej po wyjściu z pokoju.';

  @override
  String get roomsMembersLoadFailed => 'Nie udało się wczytać, kto tu jest.';

  @override
  String get roomsStatusFriend => 'Znajomy';

  @override
  String get roomsStatusHereNow => 'Teraz tutaj';

  @override
  String get roomsStatusInRoom => 'W pokoju';

  @override
  String get roomsStatusGone => 'Nie ma już w pokoju';

  @override
  String roomsStatusMutedUntil(String time) {
    return 'Wyciszony do $time';
  }

  @override
  String roomsYouSuffix(String name) {
    return '$name (ty)';
  }

  @override
  String roomsRemoveTitle(String name) {
    return 'Usunąć $name z pokoju?';
  }

  @override
  String roomsRemoveBodyAlwaysOn(String name) {
    return '$name od razu opuści czat i będzie mógł wrócić po 24 godzinach.';
  }

  @override
  String roomsRemoveBodyHosted(String name) {
    return '$name od razu opuści czat i nie wróci, dopóki ten pokój się nie zakończy.';
  }

  @override
  String roomsWarnTitle(String name) {
    return 'Ostrzec $name?';
  }

  @override
  String roomsWarnBody(String name) {
    return '$name dostanie prywatne przypomnienie, by rozmawiać życzliwie i na temat.';
  }

  @override
  String get roomsRemoveAction => 'Usuń';

  @override
  String get roomsWarnAction => 'Wyślij ostrzeżenie';

  @override
  String roomsRemovedDone(String name) {
    return '$name został usunięty z pokoju.';
  }

  @override
  String roomsWarnedDone(String name) {
    return 'Wysłano ostrzeżenie do $name.';
  }

  @override
  String get roomsModerationFailed => 'Nie udało się. Spróbuj ponownie.';

  @override
  String roomsBlockedDone(String name) {
    return 'Zablokowano $name. Nie będziecie tu widzieć swoich wiadomości.';
  }

  @override
  String get roomsReport => 'Zgłoś';

  @override
  String get roomsBlock => 'Zablokuj';

  @override
  String get roomsModerateEyebrow => 'MODERUJ';

  @override
  String get roomsWarn => 'Ostrzeż';

  @override
  String get roomsRemoveFromRoom => 'Usuń z pokoju';

  @override
  String get roomsMute => 'Wycisz';

  @override
  String get roomsUnmute => 'Cofnij wyciszenie';

  @override
  String roomsMuteSheetTitle(String name) {
    return 'Wyciszyć $name?';
  }

  @override
  String roomsMuteSheetBody(String name) {
    return '$name nadal może czytać czat, ale nie może pisać, dopóki wyciszenie nie minie. Dostanie prywatną wiadomość.';
  }

  @override
  String get roomsMuteTenMinutes => 'Na 10 minut';

  @override
  String get roomsMuteOneHour => 'Na 1 godzinę';

  @override
  String get roomsMuteUntilEnd => 'Do końca pokoju';

  @override
  String get roomsMuteOneDay => 'Na 24 godziny';

  @override
  String roomsMutedDone(String name) {
    return '$name jest wyciszony.';
  }

  @override
  String roomsUnmutedDone(String name) {
    return '$name znowu może pisać.';
  }

  @override
  String get richFormattingToolbar => 'Formatowanie';

  @override
  String get richUndo => 'Cofnij';

  @override
  String get richRedo => 'Ponów';

  @override
  String get richBold => 'Pogrubienie';

  @override
  String get richItalic => 'Kursywa';

  @override
  String get richUnderline => 'Podkreślenie';

  @override
  String get richStrikethrough => 'Przekreślenie';

  @override
  String get richHighlight => 'Wyróżnienie';

  @override
  String get richLink => 'Link';

  @override
  String get richTextStyleMenu => 'Styl tekstu';

  @override
  String get richParagraph => 'Akapit';

  @override
  String get richHeading => 'Nagłówek';

  @override
  String get richSubheading => 'Podtytuł';

  @override
  String get richQuote => 'Cytat';

  @override
  String get richCallout => 'Ramka';

  @override
  String get richBulletList => 'Lista punktowana';

  @override
  String get richNumberedList => 'Lista numerowana';

  @override
  String get richDivider => 'Separator';

  @override
  String get richAlignMenu => 'Wyrównanie';

  @override
  String get richAlignStart => 'Wyrównaj do początku';

  @override
  String get richAlignCenter => 'Wyśrodkuj';

  @override
  String get richAlignEnd => 'Wyrównaj do końca';

  @override
  String get richClearFormatting => 'Wyczyść formatowanie';

  @override
  String get richWritingStyle => 'Styl pisania';

  @override
  String get richStyleClassic => 'Klasyczny';

  @override
  String get richStyleClassicHint =>
      'Elegancki szeryf jak na drukowanej stronie';

  @override
  String get richStyleModern => 'Nowoczesny';

  @override
  String get richStyleModernHint => 'Czysty i łatwy w czytaniu';

  @override
  String get richStyleJournal => 'Dziennik';

  @override
  String get richStyleJournalHint => 'Ciepła kursywa jak wpis w pamiętniku';

  @override
  String get richStyleTypewriter => 'Maszyna do pisania';

  @override
  String get richStyleTypewriterHint =>
      'Kanciaste litery z większymi odstępami';

  @override
  String get richStylePoetic => 'Poetycki';

  @override
  String get richStylePoeticHint => 'Wyśrodkowane wersy z oddechem';

  @override
  String richWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count słowa',
      many: '$count słów',
      few: '$count słowa',
      one: '$count słowo',
    );
    return '$_temp0';
  }

  @override
  String get richAlignmentNote =>
      'Wyrównanie i odstępy widać w podglądzie i u czytelników.';

  @override
  String get richLinkTitle => 'Dodaj link';

  @override
  String get richLinkField => 'Adres strony';

  @override
  String get richLinkInvalid => 'Podaj pełny adres https://.';

  @override
  String get richLinkApply => 'Dodaj link';

  @override
  String get richLinkRemove => 'Usuń link';

  @override
  String get richLinkNeedsSelection =>
      'Najpierw zaznacz słowa, które chcesz połączyć z linkiem.';

  @override
  String get richCancel => 'Anuluj';

  @override
  String get richOpenLinkTitle => 'Otworzyć ten link?';

  @override
  String richOpenLinkBody(String host) {
    return '$host otworzy się poza Connect. Otwieraj tylko zaufane linki.';
  }

  @override
  String get richOpenLink => 'Otwórz link';

  @override
  String get supportCentreEyebrow => 'POMOC I WSPARCIE';

  @override
  String get supportCentreTitle => 'Jak możemy pomóc?';

  @override
  String get supportCentreSubtitle =>
      'Znajdź szybką odpowiedź lub zapytaj nasz zespół. Każde zgłoszenie i odpowiedź zostają w jednej prywatnej rozmowie.';

  @override
  String get supportContactSection => 'KONTAKT';

  @override
  String get supportContactTitle => 'Skontaktuj się z pomocą';

  @override
  String get supportContactSubtitle =>
      'Opisz, co się stało. Odpowiemy tutaj i damy Ci znać.';

  @override
  String get supportMyTicketsTitle => 'Moje zgłoszenia';

  @override
  String get supportMyTicketsSubtitle =>
      'Śledź swoje zgłoszenia i nasze odpowiedzi';

  @override
  String supportOpenRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count otwartego zgłoszenia',
      many: '$count otwartych zgłoszeń',
      few: '$count otwarte zgłoszenia',
      one: '1 otwarte zgłoszenie',
    );
    return '$_temp0';
  }

  @override
  String supportUnreadReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nowej odpowiedzi',
      many: '$count nowych odpowiedzi',
      few: '$count nowe odpowiedzi',
      one: '1 nowa odpowiedź',
    );
    return '$_temp0';
  }

  @override
  String get supportQuickAnswersSection => 'SZYBKIE ODPOWIEDZI';

  @override
  String get supportFaqLoginTitle => 'Logowanie';

  @override
  String get supportFaqLoginBody =>
      'Zaloguj się, używając swojej unikalnej nazwy użytkownika i hasła.';

  @override
  String get supportFaqVerificationTitle => 'Weryfikacja';

  @override
  String get supportFaqVerificationBody =>
      'Weryfikacja tożsamości jest opcjonalna, dopóki dostawca jest wstrzymany.';

  @override
  String get supportFaqAbuseTitle => 'Nadużycia';

  @override
  String get supportFaqAbuseBody =>
      'Użyj opcji Zgłoś w profilu lub rozmowie, aby szybciej trafić do zespołu bezpieczeństwa.';

  @override
  String get supportFaqBillingTitle => 'Płatności';

  @override
  String get supportFaqBillingBody =>
      'Podaj numer transakcji, nigdy danych swojej karty.';

  @override
  String get supportEmergencyNote =>
      'Jeśli ktoś jest w bezpośrednim niebezpieczeństwie, skontaktuj się z lokalnymi służbami ratunkowymi. Zgłoszenia do pomocy nie zastępują pomocy w nagłych wypadkach.';

  @override
  String get supportUnavailableTitle =>
      'Zgłoszenia do pomocy są teraz niedostępne';

  @override
  String get supportUnavailableBody =>
      'Odpowiedzi na tej stronie nadal działają. W pilnych sprawach napisz na support@connect.example.';

  @override
  String get supportBackToHelp => 'Wróć do Pomocy i wsparcia';

  @override
  String get supportFormEyebrow => 'NOWE ZGŁOSZENIE';

  @override
  String get supportFormTitle => 'Skontaktuj się z pomocą';

  @override
  String get supportFormSubtitle =>
      'Podaj wystarczająco szczegółów, abyśmy mogli działać. Nigdy nie podawaj hasła, kodu odzyskiwania, numeru karty ani dokumentu tożsamości.';

  @override
  String get supportFormCategorySection => 'TEMAT';

  @override
  String get supportFormCategoryLabel => 'W czym potrzebujesz pomocy?';

  @override
  String get supportCategoryAccountLogin => 'Konto i logowanie';

  @override
  String get supportCategoryVerification => 'Weryfikacja';

  @override
  String get supportCategoryPaymentsBilling => 'Płatności i rozliczenia';

  @override
  String get supportCategorySafetyHarassment => 'Bezpieczeństwo i nękanie';

  @override
  String get supportCategoryMatchesChat => 'Dopasowania i czat';

  @override
  String get supportCategoryTechnical => 'Problem techniczny lub błąd';

  @override
  String get supportCategoryFeatureRequest => 'Propozycja funkcji';

  @override
  String get supportCategoryPrivacyData => 'Prywatność i dane';

  @override
  String get supportCategoryOther => 'Inne';

  @override
  String get supportSafetyNote =>
      'Jeśli Ty lub ktoś inny jesteście w bezpośrednim niebezpieczeństwie, użyj SOS w aplikacji lub zadzwoń do lokalnych służb ratunkowych. Zgłoszenia dotyczące bezpieczeństwa mają priorytet, ale zgłoszenie nie jest linią alarmową.';

  @override
  String get supportOpenSos => 'Otwórz SOS';

  @override
  String get supportFormDetailsSection => 'SZCZEGÓŁY';

  @override
  String get supportFormSubjectLabel => 'Temat';

  @override
  String get supportFormSubjectHint => 'Krótko opisz problem';

  @override
  String get supportFormDescriptionLabel => 'Co się stało?';

  @override
  String get supportFormDescriptionHint =>
      'Co zrobiłeś, czego oczekiwałeś i co się stało zamiast tego';

  @override
  String get supportFormScreenshotsSection => 'ZRZUTY EKRANU';

  @override
  String supportFormScreenshotsCaption(int max) {
    return 'Opcjonalnie. Maksymalnie $max obrazów.';
  }

  @override
  String get supportAddScreenshot => 'Dodaj zrzut ekranu';

  @override
  String supportRemoveAttachment(String name) {
    return 'Usuń $name';
  }

  @override
  String get supportAttachmentUploading => 'Przesyłanie';

  @override
  String get supportRetryUpload => 'Ponów przesyłanie';

  @override
  String supportFormDeviceNote(String version) {
    return 'Dołączymy wersję aplikacji ($version), platformę, wersję systemu i język, aby łatwiej rozwiązać problem.';
  }

  @override
  String get supportSubmit => 'Wyślij zgłoszenie';

  @override
  String get supportErrorCategoryRequired => 'Wybierz temat.';

  @override
  String supportErrorSubjectLength(int min, int max) {
    return 'Temat musi mieć od $min do $max znaków.';
  }

  @override
  String get supportErrorDescriptionRequired => 'Opisz, co się stało.';

  @override
  String supportErrorDescriptionTooLong(int max) {
    return 'Zmieść się w $max znakach.';
  }

  @override
  String get supportErrorUploadsPending =>
      'Poczekaj, aż zrzuty ekranu zostaną przesłane, lub usuń te, których nie udało się przesłać.';

  @override
  String supportCreatedSnack(String reference) {
    return 'Zgłoszenie $reference wysłane. Odpowiemy tutaj.';
  }

  @override
  String supportDuplicateSnack(String reference) {
    return 'To zgłoszenie zostało już wysłane, więc je otworzyliśmy: $reference.';
  }

  @override
  String supportErrorRateLimited(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Wysłano kilka zgłoszeń w krótkim czasie. Spróbuj ponownie za $minutes minuty.',
      many:
          'Wysłano kilka zgłoszeń w krótkim czasie. Spróbuj ponownie za $minutes minut.',
      few:
          'Wysłano kilka zgłoszeń w krótkim czasie. Spróbuj ponownie za $minutes minuty.',
      one:
          'Wysłano kilka zgłoszeń w krótkim czasie. Spróbuj ponownie za 1 minutę.',
    );
    return '$_temp0';
  }

  @override
  String get supportErrorRateLimitedGeneric =>
      'Wysłano kilka zgłoszeń w krótkim czasie. Spróbuj ponownie później.';

  @override
  String get supportErrorTooManyOpen =>
      'Masz już 10 otwartych zgłoszeń. Zamknij jedno, którego już nie potrzebujesz, lub poczekaj na nasze odpowiedzi.';

  @override
  String get supportErrorTicketClosed =>
      'To zgłoszenie jest zamknięte i nie można go już ponownie otworzyć. Utwórz nowe zgłoszenie.';

  @override
  String get supportErrorReopenWindowPassed =>
      'Minął czas na ponowne otwarcie tego zgłoszenia. Utwórz nowe zgłoszenie.';

  @override
  String get supportErrorAlreadyRated => 'To zgłoszenie zostało już ocenione.';

  @override
  String get supportErrorNotResolved =>
      'Zgłoszenie możesz ocenić po jego rozwiązaniu.';

  @override
  String get supportErrorAttachmentType =>
      'Można załączać tylko obrazy JPEG lub PNG oraz pliki PDF.';

  @override
  String get supportErrorAttachmentTooLarge =>
      'Ten plik jest za duży. Obrazy mogą mieć maksymalnie 8 MB.';

  @override
  String get supportErrorOffline =>
      'Nie można teraz połączyć się z Connect. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get supportErrorNotFound => 'Nie znaleźliśmy tego zgłoszenia.';

  @override
  String get supportErrorGeneric => 'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get supportTryAgain => 'Spróbuj ponownie';

  @override
  String get supportTicketsEyebrow => 'POMOC';

  @override
  String get supportTicketsTitle => 'Moje zgłoszenia';

  @override
  String get supportTicketsSubtitle => 'Twoje zgłoszenia i nasze odpowiedzi.';

  @override
  String get supportTicketsActiveSection => 'AKTYWNE';

  @override
  String get supportTicketsClosedSection => 'ROZWIĄZANE I ZAMKNIĘTE';

  @override
  String get supportTicketsEmptyTitle => 'Brak zgłoszeń';

  @override
  String get supportTicketsEmptyBody =>
      'Gdy skontaktujesz się z pomocą, Twoje zgłoszenie i nasze odpowiedzi pojawią się tutaj.';

  @override
  String get supportTicketsLoadErrorTitle => 'Nie udało się wczytać zgłoszeń';

  @override
  String supportTicketUpdated(String when) {
    return 'Zaktualizowano $when';
  }

  @override
  String get supportNewTicket => 'Nowe zgłoszenie';

  @override
  String get supportStatusOpen => 'Otwarte';

  @override
  String get supportStatusWaitingForYou => 'Czeka na Ciebie';

  @override
  String get supportStatusOnHold => 'Wstrzymane';

  @override
  String get supportStatusResolved => 'Rozwiązane';

  @override
  String get supportStatusClosed => 'Zamknięte';

  @override
  String supportStatusSemantics(String status) {
    return 'Status: $status';
  }

  @override
  String get supportThreadAgentName => 'Pomoc Connect';

  @override
  String get supportThreadYou => 'Ty';

  @override
  String supportTicketMeta(String category, String date) {
    return '$category · Otwarte $date';
  }

  @override
  String get supportBannerOpen =>
      'Mamy Twoje zgłoszenie. Nasz zespół odpowie tutaj i da Ci znać.';

  @override
  String get supportBannerWaiting =>
      'Pomoc odpowiedziała i czeka na Twoją odpowiedź.';

  @override
  String get supportBannerOnHold =>
      'Twoje zgłoszenie jest wstrzymane, dopóki je sprawdzamy. Poinformujemy Cię tutaj.';

  @override
  String get supportBannerResolved =>
      'Oznaczono jako rozwiązane. Odpowiedz, aby je ponownie otworzyć; w przeciwnym razie zamknie się automatycznie po 7 dniach.';

  @override
  String supportBannerClosedUntil(String date) {
    return 'To zgłoszenie jest zamknięte. Możesz je ponownie otworzyć do $date.';
  }

  @override
  String get supportBannerClosed => 'To zgłoszenie jest zamknięte.';

  @override
  String supportBannerMerged(String reference) {
    return 'To zgłoszenie połączono z $reference. Rozmowa toczy się dalej tam.';
  }

  @override
  String get supportReplyHint => 'Napisz odpowiedź';

  @override
  String get supportReplyDisabledHint =>
      'Odpowiedzi w tym zgłoszeniu są zamknięte';

  @override
  String get supportSendReply => 'Wyślij odpowiedź';

  @override
  String get supportAttachScreenshot => 'Załącz zrzut ekranu';

  @override
  String get supportCloseTicket => 'Zamknij zgłoszenie';

  @override
  String get supportCloseConfirmTitle => 'Zamknąć to zgłoszenie?';

  @override
  String get supportCloseConfirmBody =>
      'Zamknij je, jeśli problem został rozwiązany. Możesz je ponownie otworzyć przez 14 dni.';

  @override
  String get supportCancel => 'Anuluj';

  @override
  String get supportClosedSnack => 'Zgłoszenie zamknięte.';

  @override
  String get supportReopen => 'Otwórz ponownie';

  @override
  String get supportReopenedSnack => 'Zgłoszenie ponownie otwarte.';

  @override
  String get supportRateTitle => 'Jak nam poszło?';

  @override
  String get supportRateCaption =>
      'Oceń swoje doświadczenie z tym zgłoszeniem.';

  @override
  String supportRateStar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gwiazdki',
      many: '$count gwiazdek',
      few: '$count gwiazdki',
      one: '1 gwiazdka',
    );
    return '$_temp0';
  }

  @override
  String get supportRateCommentLabel => 'Chcesz coś dodać? (opcjonalnie)';

  @override
  String get supportRateSubmit => 'Wyślij ocenę';

  @override
  String get supportRatedTitle => 'Dziękujemy za opinię';

  @override
  String supportRatedValue(int rating) {
    return 'Twoja ocena: $rating na 5.';
  }

  @override
  String get supportRatingSnack => 'Dziękujemy za ocenę.';

  @override
  String supportAttachmentImage(String name) {
    return 'Zrzut ekranu $name';
  }

  @override
  String get supportAttachmentLoadFailed => 'Nie udało się wczytać załącznika';

  @override
  String get supportThreadLoadErrorTitle =>
      'Nie udało się wczytać tego zgłoszenia';

  @override
  String get chemistryCardEntry => 'Trochę chemii?';

  @override
  String get memberProfileIntroducing => 'Poznaj';

  @override
  String get memberProfileStarring => 'W roli głównej';

  @override
  String get memberProfileVerified => 'Zweryfikowano';

  @override
  String memberProfilePhotoLabel(String name, int index, int count) {
    return '$name, zdjęcie $index z $count';
  }

  @override
  String get memberProfileNoPhoto => 'Brak zdjęcia';

  @override
  String get memberProfileViewPhotoHint => 'wyświetlić na pełnym ekranie';

  @override
  String get memberProfileCloseGallery => 'Zamknij zdjęcia';

  @override
  String get memberProfilePhotos => 'Zdjęcia';

  @override
  String memberProfileMorePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jeszcze $count zdjęcia',
      many: 'jeszcze $count zdjęć',
      few: 'jeszcze $count zdjęcia',
      one: 'jeszcze 1 zdjęcie',
    );
    return '$_temp0';
  }

  @override
  String get memberProfileSceneAbout => 'O mnie';

  @override
  String get memberProfileSceneStories => 'Historie';

  @override
  String get memberProfileSceneStoriesTitle => 'Trochę więcej o mnie';

  @override
  String get memberProfileSceneInterests => 'Zainteresowania';

  @override
  String get memberProfileSceneBasics => 'Podstawy';

  @override
  String get memberProfileSceneLifestyle => 'Styl życia';

  @override
  String get memberProfileSceneTrust => 'Zaufanie';

  @override
  String get memberProfileReadMore => 'Czytaj więcej';

  @override
  String get memberProfileReadLess => 'Zwiń';

  @override
  String get memberProfileHobbies => 'Hobby';

  @override
  String get memberProfileActivities => 'Aktywności';

  @override
  String get memberProfileSongs => 'Na okrągło';

  @override
  String get memberProfileBooks => 'Książki i powieści';

  @override
  String get memberProfileLookingFor => 'Szuka';

  @override
  String get memberProfileLanguages => 'Języki';

  @override
  String get memberProfileDealBreakers => 'Nie do przyjęcia';

  @override
  String get memberProfileInCommon => 'Wspólne';

  @override
  String get memberProfileFactHeight => 'Wzrost';

  @override
  String memberProfileHeightCm(int cm) {
    return '$cm cm';
  }

  @override
  String get memberProfileFactWork => 'Praca';

  @override
  String get memberProfileFactEducation => 'Wykształcenie';

  @override
  String get memberProfileFactLivesIn => 'Mieszka w';

  @override
  String get memberProfileFactMotherTongue => 'Język ojczysty';

  @override
  String get memberProfileFactReligion => 'Religia';

  @override
  String get memberProfileFactPersonality => 'Osobowość';

  @override
  String get memberProfileFactRelationship => 'Status związku';

  @override
  String get memberProfileFactInstagram => 'Instagram';

  @override
  String get memberProfileFactDrinking => 'Alkohol';

  @override
  String get memberProfileFactSmoking => 'Palenie';

  @override
  String get memberProfileFactWorkout => 'Trening';

  @override
  String get memberProfileFactDiet => 'Dieta';

  @override
  String get memberProfileFactDietType => 'Rodzaj diety';

  @override
  String get memberProfileFactSleep => 'Sen';

  @override
  String get memberProfileFactTravel => 'Podróże';

  @override
  String get memberProfileFactPets => 'Zwierzęta';

  @override
  String get memberProfileFactPolitics => 'Polityka';

  @override
  String get memberProfileFactOpenToCasual => 'Otwarty na luźną relację';

  @override
  String get memberProfileFactPartyLover => 'Lubi imprezy';

  @override
  String get memberProfileVerifiedTitle => 'Zweryfikowany profil';

  @override
  String get memberProfileVerifiedBody => 'Weryfikacja tożsamości zakończona.';

  @override
  String get memberProfileVouchesTitle => 'Polecany przez znajomych';

  @override
  String get memberProfileSpotlight => 'Wyróżnienie';

  @override
  String get memberProfileFreeWhenYouAre => 'Wolny, kiedy ty';

  @override
  String get memberProfileMessage => 'Wiadomość';

  @override
  String get memberProfileLove => 'Serce';

  @override
  String get memberProfileReport => 'Zgłoś';

  @override
  String get memberProfileOwnerTitle => 'Tak cię widzą';

  @override
  String get memberProfileOwnerCaption =>
      'Inni członkowie widzą twój profil dokładnie tak.';

  @override
  String memberProfileCompleteness(int percent) {
    return 'Profil uzupełniony w $percent%';
  }

  @override
  String get memberProfileCompletenessHint =>
      'Dodaj zdjęcia, historie i szczegóły, aby się wyróżnić.';

  @override
  String get memberProfileCompletenessDone => 'Twój profil jest kompletny.';

  @override
  String get memberProfileToolEdit => 'Edytuj profil';

  @override
  String get memberProfileToolPhotos => 'Edytuj zdjęcia';

  @override
  String get memberProfileToolStories => 'Twoje historie';

  @override
  String get memberProfileToolViewers => 'Kto cię oglądał';

  @override
  String get memberProfileBehindTheScenes => 'Za kulisami';

  @override
  String get memberProfileOnlyYou => 'Tylko ty to widzisz.';

  @override
  String get memberProfileMine => 'Mój profil';

  @override
  String get profileShowcaseLabel => 'Teksty i chwile';

  @override
  String get profileShowcaseTitleOther => 'Własnymi słowami';

  @override
  String get profileShowcaseTitleSelf => 'Twoje publiczne teksty i zdjęcia';

  @override
  String get profileShowcaseChapters => 'Rozdziały';

  @override
  String get profileShowcasePhotos => 'Zdjęcia ze ściany';

  @override
  String get profileShowcaseReadAll => 'Przeczytaj wszystkie rozdziały';

  @override
  String get profileShowcaseHiddenTitle => 'Tylko ty to widzisz';

  @override
  String get profileShowcaseHiddenBody =>
      'Twoje publiczne rozdziały i zdjęcia ze ściany są ukryte w profilu. Włącz tę opcję, aby członkowie mogli je tu zobaczyć.';

  @override
  String get profileShowcaseShownBody =>
      'Członkowie widzą je w twoim profilu. Pojawiają się tylko rozdziały udostępnione społeczności i zdjęcia na ścianie.';

  @override
  String get profileShowcaseSwitch => 'Pokaż w moim profilu';

  @override
  String get profileShowcaseSaveFailed =>
      'Nie udało się zapisać twojego wyboru.';
}
