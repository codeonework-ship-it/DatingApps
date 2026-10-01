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
}
