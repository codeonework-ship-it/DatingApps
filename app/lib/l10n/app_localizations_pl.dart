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
      'W dzień ciepła kość słoniowa i leśna zieleń. Nocą delikatna mięta i głęboki las.';

  @override
  String get settingsLooksClassicLabel => 'Dziś';

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
      'Zaplanujcie razem pierwsze spotkanie. Udostępnianie kontaktom jest na początku wyłączone.';

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
  String get planHeadlineFriendsAlerted =>
      'Twoja prośba o pomoc została zapisana';

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
      'Wybierz zaufane kontakty, którym udostępnisz swoje aktualizacje.';

  @override
  String get planFriendsKnowProposed =>
      'Udostępnianie kontaktom jest opcjonalne przy każdym planie.';

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
      'To zostaje między tobą a twoją randką. Po wysłaniu propozycji wybierz zaufane kontakty, jeśli chcesz udostępniać aktualizacje planu i check-inu.';

  @override
  String get planSectionWhen => 'Kiedy';

  @override
  String get planSectionWhat => 'Co';

  @override
  String get planSectionGroups => 'Zaufane kontakty';

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
      'Zaakceptuj ten plan ze swoją randką. Potem wybierz zaufane kontakty, jeśli chcesz udostępniać aktualizacje.';

  @override
  String get planAcceptButton => 'Zaakceptuj plan';

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
      'Zaproponuj randkę z poziomu rozmowy. Sam(a) decydujesz, czy udostępniać aktualizacje planu i check-inu zaufanym kontaktom.';

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
  String get plansNextUpcoming =>
      'Potwierdzone. Wasz wspólny czas jest zaplanowany.';

  @override
  String get plansNextCheckin => 'Zrób check-in po randce';

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
      'Plany pojawią się tutaj, gdy znajomi wyraźnie zdecydują się je tobie udostępnić.';

  @override
  String get plansViaGroup => 'Udostępnione tobie';

  @override
  String get plansViaFriend => 'Zaufany kontakt';

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

  @override
  String get callsHistoryTitle => 'Historia połączeń';

  @override
  String get callsHistoryEmpty => 'Nie ma jeszcze żadnych połączeń.';

  @override
  String callsHistoryMatch(String id) {
    return 'Para $id';
  }

  @override
  String get callsJoinLiveRoom => 'Dołącz do pokoju na żywo';

  @override
  String get callsActiveSession => 'Trwające połączenie';

  @override
  String callsEndedWithDuration(String duration) {
    return 'Zakończone · $duration';
  }

  @override
  String get callsSessionTitle => 'Połączenie';

  @override
  String get callsStarting => 'Uruchamianie bezpiecznej sesji…';

  @override
  String get callsSessionActive => 'Połączenie aktywne';

  @override
  String get callsSessionUnavailable => 'Połączenie niedostępne';

  @override
  String get callsLiveRoomNote =>
      'Pokój na żywo otworzy się w bezpiecznym oknie dostawcy. Podczas rozmowy używaj tam przycisków mikrofonu, kamery i wyjścia.';

  @override
  String get callsEnd => 'Zakończ';

  @override
  String get callsErrorSignInHistory =>
      'Zaloguj się, aby zobaczyć historię połączeń.';

  @override
  String get callsErrorSignInStart =>
      'Zaloguj się, zanim zaczniesz połączenie.';

  @override
  String get callsErrorPermissions =>
      'Do połączeń potrzebny jest dostęp do kamery i mikrofonu.';

  @override
  String get callsErrorLoadHistory =>
      'Nie udało się wczytać historii połączeń.';

  @override
  String get callsErrorStart => 'Nie udało się rozpocząć połączenia.';

  @override
  String get callsErrorEnd => 'Nie udało się zakończyć połączenia.';

  @override
  String get callsErrorNotConfigured =>
      'Pokoje połączeń na żywo nie są skonfigurowane w tym środowisku.';

  @override
  String get callsErrorOpenRoom => 'Nie udało się otworzyć pokoju połączenia.';

  @override
  String get commonRetry => 'Spróbuj ponownie';

  @override
  String get commonCancel => 'Anuluj';

  @override
  String get commonClose => 'Zamknij';

  @override
  String get commonCopy => 'Kopiuj';

  @override
  String get commonDelete => 'Usuń';

  @override
  String get commonBack => 'Wstecz';

  @override
  String get commonApply => 'Zastosuj';

  @override
  String get commonReset => 'Resetuj';

  @override
  String get commonOpen => 'Otwórz';

  @override
  String get commonView => 'Zobacz';

  @override
  String get commonDismiss => 'Odrzuć';

  @override
  String get commonAny => 'Dowolne';

  @override
  String get commonSomethingWentWrong => 'Coś poszło nie tak';

  @override
  String get commonSomethingWentWrongTryAgain =>
      'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get commonTryAgainTitle => 'Spróbuj ponownie';

  @override
  String get commonNothingHereYet => 'Na razie nic tu nie ma';

  @override
  String commonLoadingLabel(String label) {
    return '$label, ładowanie';
  }

  @override
  String commonDistanceKm(int distance) {
    return '$distance km';
  }

  @override
  String get navToday => 'Dziś';

  @override
  String get navOfflineBanner =>
      'Tryb offline: niektóre dane mogą być nieaktualne.';

  @override
  String navWeakNetworkBanner(int mbps) {
    return 'Wykryto słabą sieć. Użyj co najmniej $mbps Mb/s, by aplikacja działała płynniej.';
  }

  @override
  String get navIncomingCallTitle => 'Połączenie przychodzące';

  @override
  String get navIncomingCallBody => 'Dzwoni do ciebie twoje dopasowanie.';

  @override
  String get navViewCallDetails => 'Zobacz szczegóły połączenia';

  @override
  String get filterSheetTitle => 'Filtruj dopasowania';

  @override
  String get filterAgeRange => 'Przedział wieku';

  @override
  String get filterProfileLifestyle => 'Filtry profilu i stylu życia';

  @override
  String get filterCountry => 'Kraj';

  @override
  String get filterState => 'Stan/region';

  @override
  String get filterCity => 'Miasto';

  @override
  String get filterMotherTongue => 'Język ojczysty';

  @override
  String get filterReligion => 'Religia';

  @override
  String get filterRelationshipStatus => 'Status związku';

  @override
  String get filterSmoking => 'Palenie';

  @override
  String get filterDrinking => 'Alkohol';

  @override
  String get filterPersonalityType => 'Typ osobowości';

  @override
  String get filterPartyLoverOnly => 'Tylko imprezowicze';

  @override
  String get filterHookupsOnly => 'Tylko przygody';

  @override
  String get filterAdvancedBio => 'Zaawansowane filtry opisu';

  @override
  String get filterAdvancedBioBody =>
      'Książki, powieści, piosenki, hobby, lokalizację i inne tagi ustawisz w Ustawienia → Preferencje randkowe.';

  @override
  String get filterOpenDatingPreferences => 'Otwórz preferencje randkowe';

  @override
  String get filterDistanceKm => 'Odległość (km)';

  @override
  String get filterVerifiedOnlyTitle => 'Tylko zweryfikowani';

  @override
  String get filterVerifiedOnlyBody => 'Pokazuj tylko zweryfikowane profile';

  @override
  String get filterVerifiedOnlyChip => 'Tylko zweryfikowani';

  @override
  String get filterPartyLoverChip => 'Imprezowicz';

  @override
  String get filterHookupChip => 'Tylko przygody';

  @override
  String get filterEnableTrust => 'Włącz filtrowanie według zaufania';

  @override
  String filterMinimumTrustBadges(int count) {
    return 'Minimalna liczba aktywnych odznak zaufania: $count';
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
      'true': ', tylko zweryfikowani',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(trust, {
      'true': ', filtr zaufania włączony',
      'other': ', filtr zaufania wyłączony',
    });
    return 'Filtry zapisane: $minAge–$maxAge lat, $distance km$_temp0$_temp1';
  }

  @override
  String get optionNever => 'Nigdy';

  @override
  String get optionOccasionally => 'Okazjonalnie';

  @override
  String get optionSocially => 'Towarzysko';

  @override
  String get optionRegularly => 'Regularnie';

  @override
  String get optionSingle => 'Singiel/ka';

  @override
  String get optionDivorced => 'Rozwiedziony/a';

  @override
  String get optionWidowed => 'Wdowiec/wdowa';

  @override
  String get optionSeparated => 'W separacji';

  @override
  String get optionComplicated => 'To skomplikowane';

  @override
  String get optionIntrovert => 'Introwertyk';

  @override
  String get optionAmbivert => 'Ambiwertyk';

  @override
  String get optionExtrovert => 'Ekstrawertyk';

  @override
  String get optionHighSchool => 'Szkoła średnia';

  @override
  String get optionBachelors => 'Licencjat';

  @override
  String get optionMasters => 'Magister';

  @override
  String get optionPhd => 'Doktorat';

  @override
  String get optionOther => 'Inne';

  @override
  String get optionPreferNotToSay => 'Wolę nie mówić';

  @override
  String get optionHindu => 'Hinduizm';

  @override
  String get optionMuslim => 'Islam';

  @override
  String get optionChristian => 'Chrześcijaństwo';

  @override
  String get optionSikh => 'Sikhizm';

  @override
  String get optionBuddhist => 'Buddyzm';

  @override
  String get optionJain => 'Dżinizm';

  @override
  String get optionJewish => 'Judaizm';

  @override
  String get optionSpiritual => 'Duchowość';

  @override
  String get optionAgnostic => 'Agnostycyzm';

  @override
  String get optionAtheist => 'Ateizm';

  @override
  String get storiesNudgeTitle => 'Opowiedz trochę więcej o sobie';

  @override
  String get storiesNudgeBodyUnknown =>
      'Krótkie historie w profilu dają innym prawdziwy powód, żeby się przywitać.';

  @override
  String get storiesNudgeActionOpen => 'Otwórz swoje historie';

  @override
  String get storiesNudgeBodyEmpty =>
      'Dodaj do profilu krótką historię: małą radość, weekend, którym warto się podzielić. Ludzie czytają je, zanim się przywitają.';

  @override
  String get storiesNudgeActionFirst => 'Napisz swoją pierwszą historię';

  @override
  String get storiesNudgeCompleteTitle => 'Twoja historia jest kompletna';

  @override
  String get storiesNudgeCompleteBody =>
      'Wszystkie trzy historie są w twoim profilu. Odśwież którąś, gdy życie podsunie ci nową.';

  @override
  String get storiesNudgeActionEdit => 'Edytuj swoje historie';

  @override
  String storiesNudgeSharedTitle(int count, int max) {
    return 'Udostępnione historie: $count z $max';
  }

  @override
  String get storiesNudgeBodyMore =>
      'Kolejna historia to kolejny sposób na rozpoczęcie rozmowy.';

  @override
  String storiesNudgeBodyLatest(String prompt) {
    return 'Ostatnia: „$prompt”. Kolejna to następny sposób na rozpoczęcie rozmowy.';
  }

  @override
  String get storiesNudgeActionAdd => 'Dodaj kolejną historię';

  @override
  String get storiesNudgeIdeas => 'Pomysły na początek';

  @override
  String storiesProgressSemantics(int count, int max) {
    return 'Napisane historie: $count z $max';
  }

  @override
  String get storiesPromptLittleJoy =>
      'Drobiazg, na który zawsze znajduję czas';

  @override
  String get storiesPromptWeekend => 'Weekend, którym warto się podzielić';

  @override
  String get storiesPromptFirstHello =>
      'Pierwsze „cześć”, które bardzo by mi się spodobało';

  @override
  String get storiesPromptLearning => 'Coś, czego się uczę, tylko dla siebie';

  @override
  String get storiesPromptCare => 'Drobny sposób, w jaki okazuję troskę';

  @override
  String get storiesScreenTitle => 'Trochę więcej ciebie';

  @override
  String get storiesSignIn => 'Zaloguj się, aby edytować swoje historie.';

  @override
  String get storiesLoadFailed => 'Nie udało się wczytać twoich historii.';

  @override
  String get storiesTryAgain => 'Spróbuj ponownie';

  @override
  String get storiesIncomplete =>
      'Dodaj tekst do każdej historii i opis do każdego zdjęcia albo usuń niedokończoną historię.';

  @override
  String get storiesPublished =>
      'Historie w twoim profilu zostały opublikowane.';

  @override
  String get storiesSavedPrivately =>
      'Zapisano prywatnie. Twoje historie są ukryte przed innymi członkami.';

  @override
  String get storiesSaveUnconfirmed =>
      'Nie udało się potwierdzić zapisu. Twoje zmiany wciąż tu są; wczytaj ponownie zapisane historie, aby sprawdzić.';

  @override
  String get storiesHeadline => 'Pozwól komuś poznać\nciebie na co dzień.';

  @override
  String get storiesIntro =>
      'Mały rytuał, historia stojąca za zdjęciem, pierwsze „cześć”, które by ci się spodobało. Podziel się maksymalnie trzema chwilami własnymi słowami.';

  @override
  String get storiesOptionalNote =>
      'Opcjonalnie, bez punktów i obowiązku uzupełniania. Unikaj danych kontaktowych i dokładnych lokalizacji, których nie chcesz udostępniać.';

  @override
  String get storiesPublishSwitch => 'Pokazuj te historie w moim profilu';

  @override
  String get storiesPublishSwitchHint =>
      'Domyślnie wyłączone. Widoczne dla uprawnionych członków, gdy twój profil jest opublikowany i dostępny. Możesz je ukryć w każdej chwili.';

  @override
  String get storiesBackToEditing => 'Wróć do edycji';

  @override
  String get storiesPreview => 'Podgląd moich historii';

  @override
  String get storiesPreviewBanner => 'PODGLĄD · NIE ZOSTANIE OPUBLIKOWANY';

  @override
  String get storiesAdd => 'Dodaj historię';

  @override
  String get storiesReloadDiscard =>
      'Wczytaj zapisane historie · odrzuć zmiany';

  @override
  String get storiesSaving => 'Zapisywanie…';

  @override
  String get storiesPublishButton => 'Opublikuj historie';

  @override
  String get storiesSavePrivatelyButton => 'Zapisz prywatnie';

  @override
  String get storiesPolicyNote =>
      'Zdjęcia pochodzą z zatwierdzonej galerii twojego profilu. Historie i zdjęcia nadal podlegają zgłoszeniom członków i zasadom bezpieczeństwa.';

  @override
  String storiesMomentLabel(int number) {
    return 'CHWILA $number';
  }

  @override
  String storiesRemoveTooltip(int number) {
    return 'Usuń historię $number';
  }

  @override
  String get storiesPromptLabel => 'Punkt wyjścia';

  @override
  String get storiesTextLabel => 'Własnymi słowami';

  @override
  String get storiesTextHint => 'Prawdziwy szczegół sprawia, że jest twoja.';

  @override
  String get storiesTextRequired => 'Dodaj kilka słów albo usuń tę historię.';

  @override
  String get storiesPhotoLabel => 'Zdjęcie, jeśli chcesz';

  @override
  String get storiesWordsOnly => 'Tylko tekst';

  @override
  String storiesProfilePhoto(int number) {
    return 'Zdjęcie profilowe $number';
  }

  @override
  String get storiesPhotoDescriptionLabel => 'Opisz to zdjęcie';

  @override
  String get storiesPhotoDescriptionHelper =>
      'Pomaga osobom korzystającym z czytników ekranu.';

  @override
  String get storiesPhotoDescriptionRequired => 'Dodaj krótki opis zdjęcia.';

  @override
  String get storiesPhotoSemantics => 'Zdjęcie do historii z profilu';

  @override
  String get storiesSectionTitle => 'Trochę więcej mnie';

  @override
  String get storiesRetryLoad => 'Spróbuj ponownie wczytać historie';

  @override
  String get authErrorSessionExpired => 'Wylogowano Cię. Zaloguj się ponownie.';

  @override
  String get authErrorSignInFailed =>
      'Nie udało się zalogować. Spróbuj ponownie.';

  @override
  String get authErrorCreateAccountFailed =>
      'Nie udało się utworzyć konta. Spróbuj ponownie.';

  @override
  String get authErrorCreateAccountGeneric => 'Nie udało się utworzyć konta.';

  @override
  String get authErrorInvalidCredentials =>
      'Nieprawidłowa nazwa użytkownika lub hasło.';

  @override
  String get authErrorUsernameFormat =>
      'Nazwa użytkownika musi mieć 3–30 znaków: litery, cyfry, _ lub .';

  @override
  String get authErrorPasswordFormat =>
      'Hasło musi mieć 8–72 bajty i zawierać litery oraz cyfry.';

  @override
  String get authWelcomeIntroducerLink =>
      'Jestem tu tylko, by przedstawiać znajomych';

  @override
  String get signupBackTooltip => 'Wstecz';

  @override
  String get signupIntroducerTitle => 'Bądź przyjacielem, który łączy ludzi.';

  @override
  String get signupIntroducerBody =>
      'Konto tylko dla znajomych. Bez profilu randkowego, zdjęć i przesuwania. Twój wiek pozostaje prywatny; Connect jest dla dorosłych w wieku 18–80 lat.';

  @override
  String get signupTitle => 'Utwórz konto';

  @override
  String get signupSubtitle =>
      'Wybierz unikalną nazwę użytkownika i bezpieczne hasło';

  @override
  String get signupUsernameLabel => 'Unikalna nazwa użytkownika';

  @override
  String get signupUsernameHint => 'twoja_nazwa';

  @override
  String get signupUsernameHelp =>
      '3–30 znaków. Litery, cyfry, podkreślnik i kropka.';

  @override
  String get signupPasswordLabel => 'Hasło';

  @override
  String get signupPasswordHint => 'Co najmniej 8 znaków';

  @override
  String get signupConfirmPasswordHint => 'Potwierdź hasło';

  @override
  String get signupNameLabel => 'Imię i nazwisko';

  @override
  String get signupNameHint => 'Twoje imię';

  @override
  String get signupDobLabel => 'Data urodzenia';

  @override
  String get signupDobPickerHelp => 'Wybierz datę urodzenia';

  @override
  String get signupDobPlaceholder => 'Wybierz datę';

  @override
  String get signupGenderLabel => 'Identyfikuję się jako';

  @override
  String get signupGenderMan => 'Mężczyzna';

  @override
  String get signupGenderWoman => 'Kobieta';

  @override
  String get signupGenderOther => 'Inna';

  @override
  String get signupCreateFriendAccount => 'Utwórz konto znajomego';

  @override
  String get signupAlreadyHaveAccount => 'Masz już konto?';

  @override
  String get signupErrorPasswordMismatch => 'Hasła nie są takie same.';

  @override
  String get signupErrorFullName => 'Podaj imię i nazwisko.';

  @override
  String get signupErrorDobMissing => 'Wybierz datę urodzenia.';

  @override
  String get signupErrorUnderage => 'Musisz mieć ukończone 18 lat.';

  @override
  String get signupErrorAgeRange =>
      'Connect jest obecnie dostępny dla osób w wieku 18–80 lat.';

  @override
  String get signupErrorGenderMissing => 'Wybierz, jak się identyfikujesz.';

  @override
  String get authRecoveryEnterUsername => 'Podaj nazwę użytkownika.';

  @override
  String get authRecoveryEnterCode => 'Podaj kod odzyskiwania.';

  @override
  String get authRecoveryPasswordRule =>
      'Użyj 8–72 znaków, w tym co najmniej jednej litery i jednej cyfry.';

  @override
  String get authRecoveryResetDone =>
      'Hasło zostało zresetowane, a wszystkie urządzenia wylogowane. Zaloguj się nowym hasłem.';

  @override
  String get authRecoveryAssistanceDone =>
      'Jeśli ta nazwa użytkownika należy do konta Connect, nasz zespół bezpieczeństwa rozpatrzy prośbę.';

  @override
  String get authRecoveryInvalidCode =>
      'Ten kod odzyskiwania jest nieprawidłowy lub wygasł.';

  @override
  String get authRecoveryOffline =>
      'Nie można połączyć się z Connect. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get authRecoverySendFailed =>
      'Nie udało się wysłać prośby. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get authRecoveryBackToSignIn => 'Wróć do logowania';

  @override
  String get authRecoveryHaveCode => 'Mam kod';

  @override
  String get authRecoveryLostCode => 'Nie mam kodu';

  @override
  String get authRecoveryHaveCodeIntro =>
      'Użyj kodu odzyskiwania zapisanego przy zakładaniu konta lub kodu wydanego przez nasz zespół bezpieczeństwa.';

  @override
  String get authRecoveryLostCodeIntro =>
      'Podaj nazwę użytkownika. Potwierdzimy Twoją tożsamość, zanim wydamy kod odzyskiwania. Nigdy nie prosimy o hasło.';

  @override
  String get authRecoveryUsernameLabel => 'Nazwa użytkownika';

  @override
  String get authRecoveryCodeLabel => 'Kod odzyskiwania';

  @override
  String get authRecoveryNewPasswordLabel => 'Nowe hasło';

  @override
  String get authRecoveryMessageLabel => 'Coś, co nam pomoże (opcjonalnie)';

  @override
  String get authRecoveryMessageHint =>
      'Na przykład kiedy ostatnio udało Ci się zalogować';

  @override
  String get authRecoverySending => 'Wysyłanie…';

  @override
  String get authRecoveryResetPassword => 'Zresetuj hasło';

  @override
  String get authRecoveryAskForHelp => 'Poproś o pomoc';

  @override
  String get authTermsTitle => 'Regulamin';

  @override
  String get authTermsSubtitle =>
      'Krótki przegląd, zanim zaczniesz korzystać z aplikacji.';

  @override
  String get authTermsIntro =>
      'Zapoznaj się z Regulaminem i Polityką prywatności i zaakceptuj je, aby kontynuować.';

  @override
  String get authTermsCommunityTitle => 'Zasady społeczności';

  @override
  String get authTermsPointRespect => 'Bądź uprzejmy i autentyczny.';

  @override
  String get authTermsPointNoHarassment => 'Żadnego nękania ani oszustw.';

  @override
  String get authTermsPointPrivacy =>
      'Ty decydujesz o ustawieniach prywatności i widoczności profilu.';

  @override
  String get authTermsPointReports =>
      'Zgłoszenia są weryfikowane, aby społeczność była bezpieczna.';

  @override
  String get authTermsPointViolations =>
      'Naruszenia mogą skutkować zawieszeniem lub usunięciem konta.';

  @override
  String get authTermsReviewLater =>
      'Pełną treść zasad możesz później przejrzeć w ustawieniach, ale musisz je zaakceptować przed korzystaniem z aplikacji.';

  @override
  String get authTermsAgreeCheckbox =>
      'Akceptuję Regulamin i Politykę prywatności';

  @override
  String get authTermsAcceptButton => 'Akceptuję i kontynuuję';

  @override
  String get authTermsSaveFailed =>
      'Nie udało się zapisać zgody. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String discoverSuperLikeSent(String name) {
    return 'Super like wysłany: $name';
  }

  @override
  String get discoverMatchPlaceholderMessage => 'Przywitaj się';

  @override
  String discoverChatNeedsMatch(String name) {
    return 'Czat z osobą $name będzie dostępny po prawdziwym dopasowaniu.';
  }

  @override
  String get discoverDailyLimitTitle => 'Wykorzystałeś dzisiejsze polubienia';

  @override
  String get discoverDailyLimitBody =>
      'Wróć jutro albo przejdź na wyższy plan, by mieć więcej polubień każdego dnia.';

  @override
  String discoverDailyLimitResetBody(String reset) {
    return '$reset. Przejdź na wyższy plan, by mieć więcej polubień każdego dnia.';
  }

  @override
  String get discoverSeePlans => 'Zobacz plany';

  @override
  String get discoverNotNow => 'Nie teraz';

  @override
  String get discoverBackToToday => 'Wróć do Dzisiaj';

  @override
  String get discoverExploreTitle => 'Przeglądaj';

  @override
  String get discoverSpotlightReviewed => 'Wyróżnienia przejrzane!';

  @override
  String get discoverAllReviewed => 'Wszystko przejrzane!';

  @override
  String get discoverCuratedForYou => 'Wybrane dla ciebie';

  @override
  String get discoverTitle => 'Odkrywaj dopasowania';

  @override
  String get discoverTagline => 'Odrobina ciekawości. Prawdziwa więź.';

  @override
  String get discoverMessages => 'Wiadomości';

  @override
  String get discoverFilters => 'Filtry';

  @override
  String get discoverYourDeck => 'Twoja talia';

  @override
  String get discoverStatReady => 'Gotowe';

  @override
  String get discoverStatLiked => 'Polubione';

  @override
  String get discoverStatPassed => 'Pominięte';

  @override
  String get discoverEdit => 'Edytuj';

  @override
  String get discoverShowingEveryone =>
      'Pokazujemy wszystkich zgodnych z twoimi preferencjami.';

  @override
  String get discoverToday => 'Dzisiaj';

  @override
  String get discoverTodaySubtitle =>
      'Pięć propozycji, odświeżanych codziennie.';

  @override
  String get discoverViewAll => 'Zobacz wszystkie';

  @override
  String get discoverMatchOnYourTerms => 'Dopasowania na twoich zasadach';

  @override
  String get discoverMatchOnYourTermsBody =>
      'Dopasowanie powstaje przy wzajemnym zainteresowaniu. Możesz zablokować lub zgłosić każdego z poziomu profilu lub rozmowy.';

  @override
  String get discoverErrorEyebrow => 'Połączenie wstrzymane';

  @override
  String get discoverErrorTitle => 'Nie udało się wczytać profili';

  @override
  String discoverTrustFilteredBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Filtry zaufania ukryły $count profilu. Złagodź je lub odśwież, aby odbudować talię.',
      many:
          'Filtry zaufania ukryły $count profili. Złagodź je lub odśwież, aby odbudować talię.',
      few:
          'Filtry zaufania ukryły $count profile. Złagodź je lub odśwież, aby odbudować talię.',
      one:
          'Filtry zaufania ukryły $count profil. Złagodź je lub odśwież, aby odbudować talię.',
    );
    return '$_temp0';
  }

  @override
  String get discoverDeckPreparingBody =>
      'Przygotowujemy twoją talię. Odśwież, aby sprawdzić nowe zweryfikowane profile w pobliżu.';

  @override
  String get discoverCheckBackSoon => 'Zajrzyj wkrótce';

  @override
  String get discoverNoSpotlightProfiles => 'Brak wyróżnionych profili';

  @override
  String get discoverNoProfiles => 'Brak profili';

  @override
  String get discoverRefresh => 'Odśwież';

  @override
  String get discoverPromisePrivate => 'Prywatnie';

  @override
  String get discoverPremium => 'Premium';

  @override
  String discoverNotificationsUnread(int count) {
    return 'Powiadomienia, nieprzeczytane: $count';
  }

  @override
  String get discoverLatestUnreadNotifications =>
      'Najnowsze nieprzeczytane powiadomienia';

  @override
  String get discoverNoUnreadNotifications =>
      'Brak nieprzeczytanych powiadomień';

  @override
  String get discoverNotificationWhoReplied => 'Kto mi odpowiedział';

  @override
  String discoverNotificationRepliesCount(int count) {
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
  String get discoverNotificationWhoLiked => 'Kto mnie polubił';

  @override
  String discoverNotificationLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nowego polubienia',
      many: '$count nowych polubień',
      few: '$count nowe polubienia',
      one: '1 nowe polubienie',
    );
    return '$_temp0';
  }

  @override
  String get discoverViewMore => 'Zobacz więcej';

  @override
  String get discoverFitsYourWeek => 'Pasuje do twojego tygodnia';

  @override
  String discoverTodayPicks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count propozycji',
      many: '$count propozycji',
      few: '$count propozycje',
      one: '1 propozycja',
    );
    return '$_temp0';
  }

  @override
  String get discoverPickedForYouToday => 'Wybrane dla ciebie na dziś.';

  @override
  String get discoverErrorLoginToDiscover =>
      'Zaloguj się, aby odkrywać profile.';

  @override
  String get discoverErrorLoadProfiles =>
      'Nie udało się wczytać profili. Spróbuj ponownie.';

  @override
  String get discoverErrorSessionUnavailable =>
      'Sesja niedostępna. Zaloguj się ponownie.';

  @override
  String get discoverErrorLikeRetry =>
      'Nie można teraz polubić. Spróbuj ponownie.';

  @override
  String get discoverErrorLike => 'Nie można teraz polubić.';

  @override
  String get discoverErrorPassRetry =>
      'Nie można teraz pominąć. Spróbuj ponownie.';

  @override
  String get discoverErrorLoadLikedMe =>
      'Nie udało się wczytać, kto cię polubił. Spróbuj ponownie.';

  @override
  String get discoverErrorAnswerInFlight =>
      'Twoja odpowiedź jest już wysyłana.';

  @override
  String get discoverErrorAnswer =>
      'Nie udało się wysłać odpowiedzi. Spróbuj ponownie.';

  @override
  String get firstChapterTopicPace => 'Tempo komunikacji';

  @override
  String get firstChapterTopicDates => 'Komfort na randkach';

  @override
  String get firstChapterTopicLanguage => 'Języki';

  @override
  String get firstChapterTopicFamily => 'Udział rodziny';

  @override
  String get firstChapterInMyWords => 'Moimi słowami';

  @override
  String firstChapterComfortOriginal(String language) {
    return 'Oryginał · $language';
  }

  @override
  String firstChapterComfortMemberTranslation(String language) {
    return 'Tłumaczenie od użytkownika · $language';
  }

  @override
  String get firstChapterComfortReloadSaved => 'Wczytaj zapisaną wersję';

  @override
  String get firstChapterComfortReloadCards => 'Wczytaj karty ponownie';

  @override
  String get firstChapterComfortHeadline => 'Twoje słowa. Twoje granice.';

  @override
  String get firstChapterComfortIntro =>
      'Opcjonalny kontekst dla osób, z którymi masz dopasowanie. Niczego nie wnioskujemy z Twojego pochodzenia. Pisz w języku, który jest Ci bliski.';

  @override
  String get firstChapterComfortShareTitle =>
      'Udostępnij te karty moim dopasowaniom';

  @override
  String get firstChapterComfortShareSubtitle =>
      'Wyłączone – każda karta pozostaje prywatna.';

  @override
  String get firstChapterComfortRemoveFromDraft => 'Usuń z wersji roboczej';

  @override
  String get firstChapterComfortTopicLabel => 'Trochę kontekstu na temat';

  @override
  String get firstChapterComfortOriginalLanguage => 'Język oryginału';

  @override
  String get firstChapterComfortOwnWords => 'Własnymi słowami';

  @override
  String get firstChapterComfortOwnWordsHint =>
      'Na przykład: lubię randki w ciągu dnia i chwilę czasu, żeby się oswoić.';

  @override
  String get firstChapterComfortTranslation =>
      'Twoje tłumaczenie (opcjonalnie)';

  @override
  String get firstChapterComfortTranslationLanguage =>
      'Język tłumaczenia (jeśli dodano)';

  @override
  String get firstChapterComfortTranslationNote =>
      'Tłumaczenia są oznaczane jako dodane przez użytkownika. Twoje oryginalne słowa zawsze zostają zachowane.';

  @override
  String get firstChapterComfortAddCard =>
      'Dodaj / zastąp tę kartę w wersji roboczej';

  @override
  String get firstChapterComfortMissingFields =>
      'Dodaj swoje słowa i język. Tłumaczenie też wymaga podania języka.';

  @override
  String get firstChapterComfortUnaddedCard =>
      'Przed zapisaniem dodaj napisaną kartę do wersji roboczej.';

  @override
  String get firstChapterComfortSaveFailed =>
      'Twoja wersja robocza wciąż tu jest. Odśwież, aby sprawdzić ostatnio zapisaną wersję, zanim spróbujesz ponownie.';

  @override
  String get firstChapterSaving => 'Zapisywanie…';

  @override
  String get firstChapterComfortSave => 'Zapisz moje wybory';

  @override
  String get firstChapterYourMatch => 'Twoje dopasowanie';

  @override
  String get firstChapterSaveUnconfirmed =>
      'Nie udało się potwierdzić zapisu. Odśwież, aby to sprawdzić, zanim spróbujesz ponownie.';

  @override
  String get firstChapterJointPreviewTitle =>
      'Historia, którą oboje zatwierdzacie';

  @override
  String get firstChapterSoloPreviewTitle =>
      'Podgląd Twojego publicznego rozdziału';

  @override
  String firstChapterThenSurprise(String surprise) {
    return 'Potem… $surprise';
  }

  @override
  String get firstChapterJointPreviewBody =>
      'Twoja zgoda to połowa. Link zadziała dopiero, gdy druga osoba też zatwierdzi dokładnie tę kartę. Każde z was może go cofnąć.';

  @override
  String get firstChapterSoloPreviewBody =>
      'Publiczne są tylko ta scena i wybrany przez Ciebie początek. Żadnych imion, zdjęć, prywatnego czatu, lokalizacji ani wkładu drugiej osoby. Możesz cofnąć link.';

  @override
  String get firstChapterKeepPrivate => 'Zachowaj prywatnie';

  @override
  String get firstChapterApproveMyHalf => 'Zatwierdź moją połowę';

  @override
  String get firstChapterCreateShareLink => 'Utwórz link do udostępnienia';

  @override
  String get firstChapterStudioTitle => 'Studio Pierwszego Rozdziału';

  @override
  String get firstChapterRefresh => 'Odśwież rozdział';

  @override
  String get firstChapterHeroEyebrow => 'MAŁA PRZYGODA. DWOJE AUTORÓW.';

  @override
  String get firstChapterHeroTitle => 'To, co będzie dalej,\nnależy do was.';

  @override
  String get firstChapterHeroSolo =>
      'Stwórz scenę. Przekaż ją znajomym. Albo napisz pierwszy rozdział z kimś, z kim masz dopasowanie.';

  @override
  String firstChapterHeroPair(String name) {
    return 'Ty i $name. Jeden początek, jeden nieoczekiwany zwrot i historia, którą możecie urzeczywistnić.';
  }

  @override
  String get firstChapterHeroPace =>
      'Opcjonalnie, w Twoim tempie. Czat to zawsze wybór.';

  @override
  String get firstChapterLoadFailed => 'Nie udało się wczytać rozdziału.';

  @override
  String get firstChapterTryAgain => 'Spróbuj ponownie';

  @override
  String get firstChapterStepChooseScene => '01 / Wybierz scenę';

  @override
  String get firstChapterStepWriteBeginning => '02 / Napisz początek';

  @override
  String get firstChapterStartOurChapter => 'Zacznij nasz rozdział';

  @override
  String get firstChapterPassTheChapter => 'Przekaż rozdział';

  @override
  String get firstChapterYourFirstChapter => 'Wasz pierwszy rozdział';

  @override
  String get firstChapterItBeginsWith => 'ZACZYNA SIĘ OD';

  @override
  String get firstChapterAndThen => 'A POTEM…';

  @override
  String firstChapterDateIdeaNote(String beginning, String surprise) {
    return '$beginning. Potem $surprise.';
  }

  @override
  String get firstChapterMakeDateIdea => 'Zrób z tego pomysł na randkę';

  @override
  String get firstChapterDateIdeaHint =>
      'Propozycja do wspólnego dopracowania. Żadna randka nie jest automatycznie rezerwowana ani akceptowana.';

  @override
  String get firstChapterYourTurn => 'Twoja kolej: dodaj niespodziankę.';

  @override
  String get firstChapterBeginningSaved =>
      'Twój początek jest zapisany. Twoje dopasowanie może dodać niespodziankę, kiedy zechce. Możecie dalej rozmawiać.';

  @override
  String get firstChapterClose => 'Zamknij ten rozdział';

  @override
  String get firstChapterGiveBackTitle => 'Historie, które inspirują';

  @override
  String get firstChapterGiveBackBody =>
      'Wasza relacja może zainspirować nowy początek. Udostępnijcie tylko ten anonimowy pomysł na randkę – za zgodą was obojga.';

  @override
  String get firstChapterPreviewAnonymous =>
      'Podgląd naszej anonimowej historii';

  @override
  String get firstChapterGreenLightTitle => 'Prywatne zielone światło';

  @override
  String get firstChapterInTheirWords => 'Ich słowami';

  @override
  String get firstChapterMakeRoomTitle =>
      'Zrób miejsce na to, co dla Ciebie ważne';

  @override
  String get firstChapterMakeRoomSubtitle =>
      'Twoje tempo, języki, randki i oczekiwania rodziny. Twoje słowa, udostępniane tylko wtedy, gdy zechcesz.';

  @override
  String get firstChapterCreateWithConnection => 'Twórz z kimś bliskim';

  @override
  String get firstChapterCreateTogether => 'Stwórzcie razem pierwszy rozdział';

  @override
  String get firstChapterMatchesAppearHere =>
      'Tu pojawią się Twoje wzajemne dopasowania. Już teraz możesz wypróbować i udostępnić scenę w pojedynkę.';

  @override
  String get firstChapterSharedChapters => 'Twoje udostępnione rozdziały';

  @override
  String get firstChapterReloadShared =>
      'Wczytaj udostępnione rozdziały ponownie';

  @override
  String get firstChapterNothingPublic =>
      'Nic nie jest publiczne, dopóki nie zdecydujesz się udostępnić.';

  @override
  String get firstChapterGreenChat => 'Dalej rozmawiać';

  @override
  String get firstChapterGreenCall => 'Spróbować rozmowy';

  @override
  String get firstChapterGreenDate => 'Zaproponować randkę';

  @override
  String get firstChapterGreenLightIntro =>
      'Ujawniany jest tylko wspólny wybór. Nikt nie widzi prośby bez odpowiedzi. Wybory wygasają po siedmiu dniach; wyczyść je, aby je wycofać.';

  @override
  String get firstChapterSavePrivately => 'Zapisz prywatnie';

  @override
  String get firstChapterGreenLightNone =>
      'Tu pojawi się każdy wspólny kolejny krok.';

  @override
  String firstChapterGreenLightMutual(String choices) {
    return 'Oboje czujecie się komfortowo z: $choices';
  }

  @override
  String get firstChapterGreenLightNote =>
      'Zielone światło to zgoda na zaproponowanie. Rozmowa lub randka nadal wymagają osobnej zgody.';

  @override
  String get firstChapterLinkRevoked => 'Link cofnięty';

  @override
  String get firstChapterPublicScene => 'Publiczna, anonimowa scena';

  @override
  String get firstChapterPrivateUntilBoth =>
      'Prywatne, dopóki oboje nie zatwierdzicie';

  @override
  String get firstChapterLinkCopied =>
      'Link do rozdziału skopiowany. Udostępnij go, gdzie chcesz.';

  @override
  String get firstChapterCopyLink => 'Kopiuj link';

  @override
  String get firstChapterApproveStory => 'Zatwierdź dokładnie tę historię';

  @override
  String get firstChapterRevokeLink => 'Cofnij link';

  @override
  String networkSlowResponse(int mbps) {
    return 'Wykryto słabą sieć. Użyj co najmniej $mbps Mb/s, by czat, prezenty i gesty działały płynniej.';
  }

  @override
  String get networkOffline =>
      'Brak stabilnego połączenia. Połącz się ponownie, aby dalej korzystać z aplikacji.';

  @override
  String networkWeak(int mbps) {
    return 'Sieć jest słaba. Użyj co najmniej $mbps Mb/s, by wszystko działało płynniej.';
  }

  @override
  String get networkCannotReachService =>
      'Nie można połączyć się z usługą lokalną. Sprawdź, czy API działa.';

  @override
  String get gateCheckingTerms => 'Sprawdzanie warunków…';

  @override
  String get gateLoadingProfile => 'Ładowanie twojego profilu…';

  @override
  String get gateConnectionIssue => 'Problem z połączeniem';

  @override
  String get safetyReportFailed => 'Nie udało się zgłosić użytkownika';

  @override
  String get safetyBlockFailed => 'Nie udało się zablokować użytkownika';

  @override
  String get safetyUnblockFailed => 'Nie udało się odblokować użytkownika';

  @override
  String get safetyNotAuthenticated => 'Nie zalogowano';

  @override
  String get timeAgoJustNow => 'Przed chwilą';

  @override
  String timeAgoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minut temu',
      few: '$count minuty temu',
      one: '1 minutę temu',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count godzin temu',
      few: '$count godziny temu',
      one: '1 godzinę temu',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dni temu',
      one: '1 dzień temu',
    );
    return '$_temp0';
  }

  @override
  String timeAgoWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tygodni temu',
      few: '$count tygodnie temu',
      one: '1 tydzień temu',
    );
    return '$_temp0';
  }

  @override
  String get themePreviewBarrier => 'Podgląd motywu';

  @override
  String get themeNowShowing => 'NA EKRANIE';

  @override
  String get themeTaglineRealLife =>
      'Ciepła kość słoniowa, leśna zieleń i morela.';

  @override
  String get themeTaglineRealLifeNight =>
      'Leśna zieleń, delikatna mięta i blask świec.';

  @override
  String get themeTaglineDaylight =>
      'Krem, atrament i malinowy akcent, jak na stronie.';

  @override
  String get themeTaglineEmber =>
      'Śliwkowo-czarna noc z żarem i fioletową poświatą.';

  @override
  String get themeTaglineForge =>
      'Piecowa czerwień, stalowy błękit, grafitowy chrom.';

  @override
  String get themeTaglineNeongrid =>
      'Czarne szkło, cyjanowe linie światła, bursztynowy puls.';

  @override
  String get themeTaglineCrimsonalloy =>
      'Karmazynowy lakier, płynne złoto, bordo o północy.';

  @override
  String get themeTaglineCircuit =>
      'Zieleń obwodów, sygnałowy fiolet, węglowa czerń.';

  @override
  String get themeTaglineDeepfield =>
      'Głęboki kosmos, plazmowy błękit i błysk gwiezdnego złota.';

  @override
  String get themeTaglineLove => 'Róż pudrowy, róża i odrobina złota.';

  @override
  String get themeTaglineRose =>
      'Aksamitne wino, różana czerwień i odrobina złota.';

  @override
  String get themeTaglinePetal =>
      'Różowy papier, unoszące się płatki, nuta szałwii.';

  @override
  String get themeTaglineSnow => 'Świeży śnieg, matowe szkło i wstęga zorzy.';

  @override
  String get themeTaglineGothic =>
      'Maswerk w świetle księżyca, granat, dym świec i antyczne złoto.';

  @override
  String get themeTaglineCalm =>
      'Mało bodźców, wysoki kontrast. Nieruchome tło, bez animacji.';

  @override
  String get themeLooksTodayDescription =>
      'W dzień ciepła kość słoniowa i leśna zieleń. Nocą delikatna mięta i głęboki las.';

  @override
  String get settingsEyebrow => 'USTAWIENIA';

  @override
  String get settingsHeaderSubtitle =>
      'Twój wygląd, twoja prywatność i twoje konto.';

  @override
  String get settingsThemeSection => 'Motyw';

  @override
  String get settingsThemeSectionTitle => 'Dopasuj do siebie';

  @override
  String get settingsThemeSectionCaption =>
      'Każdy ekran podąża za wybranym wyglądem.';

  @override
  String get settingsSectionYourStory => 'Twoja historia';

  @override
  String get settingsDatingRhythmTitle => 'Twój rytm randkowania';

  @override
  String get settingsDatingRhythmSubtitle =>
      'Intencje, tempo, dostępność i prywatność poznawania';

  @override
  String get settingsProfileStoriesTitle => 'Historie twojego profilu';

  @override
  String get settingsProfileStoriesSubtitle =>
      'Małe chwile, twoje słowa, opcjonalne zdjęcia';

  @override
  String get settingsBlogTitle => 'Blog · Otwarte rozdziały';

  @override
  String get settingsBlogSubtitle =>
      'Twój dziennik, twoje zdjęcia, twój wybór odbiorców';

  @override
  String get settingsLookPreviewEyebrow => 'DZIŚ';

  @override
  String get settingsLookPreviewHeadline => 'Coś prawdziwego.';

  @override
  String get friendsEyebrow => 'ZNAJOMI';

  @override
  String get friendsTitle => 'Twoi ludzie';

  @override
  String get friendsSubtitle =>
      'Znajomi mogą do siebie pisać, planować i razem tworzyć grupy. Zaproszenie wymaga zgody obu stron.';

  @override
  String get friendsBack => 'Wstecz';

  @override
  String get friendsAddFriend => 'Dodaj znajomego';

  @override
  String get friendsCreateGroup => 'Utwórz grupę';

  @override
  String get friendsSectionRequests => 'ZAPROSZENIA';

  @override
  String get friendsRequestsWaitingOnOthers => 'Czekasz na innych';

  @override
  String get friendsRequestsWaitingOnYou => 'Czekają na ciebie';

  @override
  String get friendsRequestsCaption =>
      'Nic nie jest udostępniane, dopóki oboje się nie zgodzicie.';

  @override
  String get friendsSectionChats => 'CZATY';

  @override
  String get friendsChatsTitle => 'Rozmowy';

  @override
  String get friendsSectionIntros => 'ZAPOZNANIA';

  @override
  String get friendsIntrosTitle => 'Zapoznania dla ciebie';

  @override
  String get friendsSectionVouches => 'POLECENIA';

  @override
  String get friendsVouchesPendingTitle => 'Polecenia czekające na twoją zgodę';

  @override
  String friendsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count znajomego',
      many: '$count znajomych',
      few: '$count znajomych',
      one: '1 znajomy',
      zero: 'Nie masz jeszcze znajomych',
    );
    return '$_temp0';
  }

  @override
  String get friendsIntroduce => 'Zapoznaj';

  @override
  String get friendsEmptyBody =>
      'Znajdź znajomych po imieniu lub nazwie użytkownika albo dodaj kogoś z dopasowania, pokoju lub grupy.';

  @override
  String get friendsSectionOnProfile => 'NA TWOIM PROFILU';

  @override
  String get friendsVouchesOnProfileTitle => 'Polecenia na twoim profilu';

  @override
  String friendsQuoted(String text) {
    return '„$text”';
  }

  @override
  String friendsVouchedForYou(String name) {
    return '$name poleca cię';
  }

  @override
  String get friendsHideFromProfile => 'Ukryj na profilu';

  @override
  String get friendsSectionMore => 'WIĘCEJ';

  @override
  String get friendsMoreTitle => 'Plany i zapoznania';

  @override
  String get friendsPlansLinkTitle => 'Plany randek udostępnione tobie';

  @override
  String get friendsPlansLinkSubtitle =>
      'Znajomi dają ci znać, kiedy planują randkę i kiedy odezwą się po niej.';

  @override
  String get friendsInviteIntroducerTitle =>
      'Zaproś znajomego, który nie szuka randek';

  @override
  String get friendsInviteIntroducerSubtitle =>
      'Wybierz, kto może cię z kimś zapoznać. Zgodę możesz w każdej chwili sprawdzić lub cofnąć.';

  @override
  String get friendsIntroTermsTitle => 'Zapoznania na twoich zasadach';

  @override
  String get friendsIntroTermsSubtitle =>
      'Zdecyduj, czy znajomi mogą cię z kimś zapoznać i co pokazuje podgląd.';

  @override
  String get friendsSectionActivity => 'AKTYWNOŚĆ';

  @override
  String get friendsActivityTitle => 'Z twoimi znajomymi';

  @override
  String friendsVouchSentSnack(String name) {
    return 'Polecenie wysłane. $name zatwierdzi je, zanim się pojawi.';
  }

  @override
  String friendsRemoveTitle(String name) {
    return 'Usunąć $name?';
  }

  @override
  String get friendsRemoveBody =>
      'Przestaniecie być znajomymi, a wasz czat zostanie zamknięty. Ta osoba nie dostanie powiadomienia.';

  @override
  String get friendsRemoveFriend => 'Usuń ze znajomych';

  @override
  String get friendsIntroMadeSnack =>
      'Zapoznanie wysłane. Oboje znajomi dostaną od ciebie wiadomość.';

  @override
  String get friendsAddSheetLabel => 'DODAJ ZNAJOMEGO';

  @override
  String get friendsAddSheetTitle => 'Znajdź kogoś, kogo znasz';

  @override
  String get friendsAddSheetCaption =>
      'Szukaj po imieniu lub @nazwie użytkownika. Ta osoba zdecyduje, czy zaakceptować.';

  @override
  String get friendsSearchHiddenNote =>
      'Nie pojawiasz się w wyszukiwaniu znajomych, więc inni nie znajdą cię tutaj. Zmienisz to w sekcji Prywatność i bezpieczeństwo.';

  @override
  String get friendsSearchLabel => 'Imię lub @nazwa użytkownika';

  @override
  String get friendsSearchHelper => 'Wpisz co najmniej 3 litery';

  @override
  String get friendsSearchFailed =>
      'Wyszukiwanie jest teraz niedostępne. Spróbuj ponownie.';

  @override
  String friendsSearchNoResults(String query) {
    return 'Nie znaleziono nikogo dla „$query”.';
  }

  @override
  String get friendsNewGroupLabel => 'NOWA GRUPA';

  @override
  String get friendsNewGroupTitle => 'Kto wchodzi?';

  @override
  String get friendsNewGroupCaption =>
      'Wybierz znajomych do zaproszenia. Później możesz dodać kolejnych.';

  @override
  String get friendsChooseFriends => 'Wybierz znajomych';

  @override
  String friendsCreateGroupWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Utwórz grupę z $count osoby',
      many: 'Utwórz grupę z $count osobami',
      few: 'Utwórz grupę z $count osobami',
      one: 'Utwórz grupę z $count osobą',
    );
    return '$_temp0';
  }

  @override
  String get friendsSourceMatch => 'Z twoich dopasowań';

  @override
  String get friendsSourceProfile => 'Widział(a) twój profil';

  @override
  String get friendsSourceRoom => 'Poznani w pokoju';

  @override
  String get friendsSourceGroup => 'Z grupy';

  @override
  String get friendsSourceSearch => 'Znalazł(a) cię po imieniu';

  @override
  String get friendsWantsToBeFriends => 'Chce się zaprzyjaźnić';

  @override
  String get friendsRequestSent => 'Zaproszenie wysłane';

  @override
  String get friendsCancel => 'Anuluj';

  @override
  String get friendsDecline => 'Odrzuć';

  @override
  String get friendsAccept => 'Akceptuj';

  @override
  String friendsMessageTooltip(String name) {
    return 'Napisz do $name';
  }

  @override
  String friendsMessageTooltipUnread(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Napisz do $name, $count nieprzeczytanej',
      many: 'Napisz do $name, $count nieprzeczytanych',
      few: 'Napisz do $name, $count nieprzeczytane',
      one: 'Napisz do $name, $count nieprzeczytana',
    );
    return '$_temp0';
  }

  @override
  String friendsMoreFor(String name) {
    return 'Więcej dla $name';
  }

  @override
  String get friendsMenuVouch => 'Poleć tę osobę';

  @override
  String get friendsMenuIntro => 'Zapoznaj ze znajomym';

  @override
  String friendsChatSemantics(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Czat z $name, $count nieprzeczytanej',
      many: 'Czat z $name, $count nieprzeczytanych',
      few: 'Czat z $name, $count nieprzeczytane',
      one: 'Czat z $name, $count nieprzeczytana',
      zero: 'Czat z $name',
    );
    return '$_temp0';
  }

  @override
  String friendsChatSemanticsMuted(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Czat z $name, $count nieprzeczytanej, powiadomienia wyciszone',
      many: 'Czat z $name, $count nieprzeczytanych, powiadomienia wyciszone',
      few: 'Czat z $name, $count nieprzeczytane, powiadomienia wyciszone',
      one: 'Czat z $name, $count nieprzeczytana, powiadomienia wyciszone',
      zero: 'Czat z $name, powiadomienia wyciszone',
    );
    return '$_temp0';
  }

  @override
  String friendsIntroHeadline(String introducer, String person) {
    return '$introducer uważa, że warto, żebyś poznał(a): $person';
  }

  @override
  String friendsIntroHeadlineSomeone(String introducer) {
    return '$introducer uważa, że warto, żebyś kogoś poznał(a)';
  }

  @override
  String friendsNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String get friendsIntroNoThanks => 'Nie, dziękuję';

  @override
  String get friendsIntroImIn => 'Wchodzę w to';

  @override
  String get friendsVouchKeepPrivate => 'Zachowaj dla siebie';

  @override
  String get friendsVouchShowOnProfile => 'Pokaż na moim profilu';

  @override
  String get memberProfileNoData => 'Nie znaleziono danych profilu.';

  @override
  String get memberProfileSignInToView =>
      'Zaloguj się, aby zobaczyć swój profil.';

  @override
  String get memberProfileLoadFailed =>
      'Nie udało się wczytać profilu. Spróbuj ponownie.';

  @override
  String get memberProfileConnectionsTitle => 'Twoje kontakty';

  @override
  String get memberProfileConnectionsCaption =>
      'Polubione osoby, dopasowania i rozmowy.';

  @override
  String get memberProfileStatLiked => 'Polubione';

  @override
  String get memberProfileStatMatches => 'Dopasowania';

  @override
  String get memberProfileStatMessages => 'Wiadomości';

  @override
  String memberProfileOpenStat(String label) {
    return 'Otwórz: $label';
  }

  @override
  String get memberProfileNoticedTitle => 'Kto cię zauważył';

  @override
  String get memberProfileNoticedCaption =>
      'Polubienia i wyświetlenia od osób w pobliżu.';

  @override
  String get memberProfileWhoLikedMe => 'Kto mnie polubił';

  @override
  String memberProfileWhoLikedMeCount(int count) {
    return 'Kto mnie polubił ($count)';
  }

  @override
  String get memberProfileWhoLikedMeSubtitle =>
      'Osoby, którym spodobał się twój profil.';

  @override
  String get memberProfileWhoViewedTitle => 'Kto oglądał mój profil';

  @override
  String get memberProfileWhoViewedSubtitle =>
      'Ostatnie odwiedziny twojego profilu.';

  @override
  String get memberProfileWhoViewedTooltip => 'Kto oglądał mój profil';

  @override
  String get memberProfileRefreshTooltip => 'Odśwież profil';

  @override
  String get memberProfilePreferencesTitle => 'Twoje preferencje';

  @override
  String get memberProfilePrefSeeking => 'Szukam';

  @override
  String get memberProfilePrefDistance => 'Odległość';

  @override
  String memberProfileWithinKm(int km) {
    return 'W promieniu $km km';
  }

  @override
  String get profileViewersTitle => 'Oglądali mój profil';

  @override
  String get profileViewersLoadFailed =>
      'Nie udało się wczytać odwiedzin profilu.';

  @override
  String get profileViewersEmpty => 'Nikt jeszcze nie oglądał twojego profilu.';

  @override
  String get profileViewersViewedRecently => 'Wyświetlono niedawno';

  @override
  String profileViewersViewedAt(String time) {
    return 'Wyświetlono $time';
  }

  @override
  String get profileMasterReligionParsi => 'Parsizm';

  @override
  String get profileMasterReligionBahai => 'Bahaizm';

  @override
  String get profileMasterReligionTribal => 'Wierzenia plemienne / rdzenne';

  @override
  String get profileMasterWorkout1to2 => '1-2 razy w tygodniu';

  @override
  String get profileMasterWorkout3to4 => '3-4 razy w tygodniu';

  @override
  String get profileMasterWorkout5Plus => '5+ razy w tygodniu';

  @override
  String get profileMasterWorkoutDaily => 'Codziennie';

  @override
  String get profileMasterDietNoPreference => 'Bez preferencji';

  @override
  String get profileMasterDietVegetarian => 'Wegetarianizm';

  @override
  String get profileMasterDietEggetarian => 'Wegetarianizm z jajkami';

  @override
  String get profileMasterDietNonVegetarian => 'Dieta mięsna';

  @override
  String get profileMasterDietVegan => 'Weganizm';

  @override
  String get profileMasterDietJain => 'Dieta dżinijska';

  @override
  String get profileMasterDietTypeBalanced => 'Zbilansowana';

  @override
  String get profileMasterDietTypeHighProtein => 'Wysokobiałkowa';

  @override
  String get profileMasterDietTypeLowCarb => 'Niskowęglowodanowa';

  @override
  String get profileMasterDietTypeKeto => 'Keto';

  @override
  String get profileMasterDietTypeMediterranean => 'Śródziemnomorska';

  @override
  String get profileMasterDietTypeIntermittentFasting => 'Post przerywany';

  @override
  String get profileMasterSleepEarlyBird => 'Ranny ptaszek';

  @override
  String get profileMasterSleepNightOwl => 'Nocny marek';

  @override
  String get profileMasterSleepFlexible => 'Elastycznie';

  @override
  String get profileMasterSleepShiftBased => 'Zmianowo';

  @override
  String get profileMasterTravelHomebody => 'Domator';

  @override
  String get profileMasterTravelOccasional => 'Podróżuję od czasu do czasu';

  @override
  String get profileMasterTravelFrequent => 'Często podróżuję';

  @override
  String get profileMasterTravelAdventure => 'Poszukiwacz przygód';

  @override
  String get profileMasterTravelLuxury => 'Luksusowe podróże';

  @override
  String get profileMasterTravelBackpacker => 'Backpacker';

  @override
  String get profileMasterPoliticsSimilar => 'Tylko podobne poglądy';

  @override
  String get profileMasterPoliticsOpen => 'Otwartość na różnice';

  @override
  String get profileMasterPoliticsNotDiscuss => 'Wolę o tym nie rozmawiać';

  @override
  String get profileMasterPoliticsNoStrong => 'Bez wyraźnych preferencji';

  @override
  String get profileMasterIntentLongTerm => 'Stały związek';

  @override
  String get profileMasterIntentMarriage => 'Małżeństwo';

  @override
  String get profileMasterIntentNewFriends => 'Nowi znajomi';

  @override
  String get chatBackToConversations => 'Wróć do rozmów';

  @override
  String get chatOfflineBanner =>
      'Jesteś offline. Twoja wersja robocza zostanie tutaj, aż połączenie wróci.';

  @override
  String get chatVoiceHello => 'Wyślij głosowe powitanie · czytaj i słuchaj';

  @override
  String get chatLoadFailedTitle => 'Połączmy się ponownie.';

  @override
  String get chatLoadFailedBody =>
      'Nie udało się wczytać rozmowy. Spróbuj ponownie.';

  @override
  String get chatConversationEnded => 'Ta rozmowa została zakończona.';

  @override
  String get chatUnlockStepRequired =>
      'Ukończ bieżący krok odblokowania, aby kontynuować rozmowę.';

  @override
  String get chatGiftTrayTitle => 'Drobny upominek';

  @override
  String get chatCloseGifts => 'Zamknij prezenty';

  @override
  String get chatAllGifts => 'Wszystkie prezenty';

  @override
  String get chatNoGiftsInCollection => 'Brak prezentów w tej kolekcji.';

  @override
  String get chatAddCoins => 'Dodaj monety';

  @override
  String get chatFreeGiftDaily => 'Za darmo · 1 dziennie';

  @override
  String chatCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monety',
      many: '$count monet',
      few: '$count monety',
      one: '1 moneta',
    );
    return '$_temp0';
  }

  @override
  String get chatSendingGift => 'Wysyłanie prezentu…';

  @override
  String get chatOfflineGifts =>
      'Jesteś offline. Możesz przeglądać prezenty i wysłać je po odzyskaniu połączenia.';

  @override
  String chatGiftConfirmTitle(String gift, String name) {
    return 'Wysłać $gift do $name?';
  }

  @override
  String chatGiftNoteQuote(String note) {
    return '„$note”';
  }

  @override
  String chatGiftBalanceAfter(int balance, int remaining) {
    return '·  $balance → zostanie $remaining';
  }

  @override
  String get chatGiftNoObligation =>
      'Prezent to gest, a nie zobowiązanie do odpowiedzi czy spotkania.';

  @override
  String chatGiftSendFor(String price) {
    return 'Wyślij za $price';
  }

  @override
  String get chatNotNow => 'Nie teraz';

  @override
  String get chatDeleteMessageTitle => 'Usunąć wiadomość?';

  @override
  String get chatDeleteMessageBody => 'Wiadomość zniknie z czatu u was obojga.';

  @override
  String get chatDeleteForEveryone => 'Usuń dla wszystkich';

  @override
  String get chatMessageDeletedSnack => 'Wiadomość usunięta.';

  @override
  String get chatUndo => 'Cofnij';

  @override
  String get chatDeleteUndone => 'Usuwanie cofnięte.';

  @override
  String chatGiftReceivedFrom(String name) {
    return 'Prezent od $name';
  }

  @override
  String get chatGiftReceiverIntro =>
      'To ty decydujesz, co zostaje na twoim czacie.';

  @override
  String get chatHideGift => 'Ukryj prezent';

  @override
  String get chatHideGiftSubtitle => 'Usuń tylko ze swojego czatu.';

  @override
  String get chatReportAndHide => 'Zgłoś i ukryj';

  @override
  String get chatReportAndHideSubtitle =>
      'Wyślij do zespołu bezpieczeństwa i usuń od razu.';

  @override
  String get chatGiftHidden => 'Prezent ukryty na twoim czacie.';

  @override
  String get chatReportGiftTitle => 'Zgłoś ten prezent';

  @override
  String get chatReportGiftIntro =>
      'Wybierz powód. Prezent zostanie od razu ukryty.';

  @override
  String get chatReportReasonLabel => 'Powód';

  @override
  String get chatReportReasonUnwanted => 'Niechciany prezent';

  @override
  String get chatReportReasonHarassment => 'Nękanie';

  @override
  String get chatReportReasonSexual => 'Treści seksualne';

  @override
  String get chatReportReasonScam => 'Oszustwo';

  @override
  String get chatReportReasonOther => 'Coś innego';

  @override
  String get chatReportDetailsLabel => 'Dodaj szczegóły (opcjonalnie)';

  @override
  String get chatReportSubmit => 'Wyślij zgłoszenie i ukryj';

  @override
  String get chatGiftReported =>
      'Prezent zgłoszony i ukryty. Nasz zespół bezpieczeństwa go sprawdzi.';

  @override
  String get chatQuickEmojis => 'Szybkie emoji';

  @override
  String chatWalletTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monety',
      many: '$count monet',
      few: '$count monety',
      one: '1 moneta',
    );
    return 'Twój portfel · $_temp0';
  }

  @override
  String get chatDailyLimitReached => 'Osiągnięto dzienny limit wiadomości';

  @override
  String get chatDailyLimitFallback =>
      'Spróbuj jutro albo zmień plan na wyższy.';

  @override
  String chatDailyLimitReset(String reset) {
    return '$reset · zmień plan, by mieć więcej.';
  }

  @override
  String get chatSeePlans => 'Zobacz plany';

  @override
  String chatQuotaOnPlan(String quota, String plan) {
    return '$quota w planie $plan';
  }

  @override
  String get chatYourConversation => 'Wasza rozmowa';

  @override
  String get chatVerifiedHumans => 'Zweryfikowane osoby';

  @override
  String get chatVerifiedHumansShowsUp =>
      'Zweryfikowane osoby · Przychodzi na randki';

  @override
  String discoverLikedBack(String name) {
    return 'Odwzajemniono polubienie: $name';
  }

  @override
  String discoverPassedOn(String name) {
    return 'Pominięto: $name';
  }

  @override
  String get discoverLikedMeLoadFailedTitle => 'Nie udało się wczytać polubień';

  @override
  String get discoverLikedMeEmptyTitle => 'Brak nowych polubień';

  @override
  String get discoverLikedMeEmptyBody =>
      'Gdy ktoś cię polubi, pojawi się tutaj. Odwzajemnij polubienie i macie dopasowanie.';

  @override
  String get discoverLikedMeIntro =>
      'Te osoby już cię lubią. Odwzajemnij, by mieć dopasowanie, albo pomiń. Pominięcie jest prywatne.';

  @override
  String get discoverLikedMeTitle => 'Polubili cię';

  @override
  String discoverLikedMeTitleCount(int count) {
    return 'Polubili cię · $count';
  }

  @override
  String get discoverPass => 'Pomiń';

  @override
  String get discoverLikeBack => 'Odwzajemnij';

  @override
  String get discoverLikedJustNow => 'Polubił(a) cię przed chwilą';

  @override
  String discoverLikedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Polubił(a) cię $count minuty temu',
      many: 'Polubił(a) cię $count minut temu',
      few: 'Polubił(a) cię $count minuty temu',
      one: 'Polubił(a) cię 1 minutę temu',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Polubił(a) cię $count godziny temu',
      many: 'Polubił(a) cię $count godzin temu',
      few: 'Polubił(a) cię $count godziny temu',
      one: 'Polubił(a) cię 1 godzinę temu',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Polubił(a) cię $count dnia temu',
      many: 'Polubił(a) cię $count dni temu',
      few: 'Polubił(a) cię $count dni temu',
      one: 'Polubił(a) cię 1 dzień temu',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Polubił(a) cię $count tygodnia temu',
      many: 'Polubił(a) cię $count tygodni temu',
      few: 'Polubił(a) cię $count tygodnie temu',
      one: 'Polubił(a) cię 1 tydzień temu',
    );
    return '$_temp0';
  }

  @override
  String discoverLikedOnDate(String date) {
    return 'Polubił(a) cię $date';
  }

  @override
  String discoverLikedProfilesTitle(int count) {
    return 'Polubione profile ($count)';
  }

  @override
  String get discoverNoLikedProfiles => 'Brak polubionych profili';

  @override
  String get discoverLikedProfileFallback => 'Polubiony profil';

  @override
  String get discoverPassedProfilesTitle => 'Pominięte profile';

  @override
  String get discoverNoPassedProfiles => 'Brak pominiętych profili';

  @override
  String get discoverSavedForLater => 'Zapisane na później';

  @override
  String get discoverSpotlightFiltersTitle => 'Filtry wyróżnień';

  @override
  String get discoverVerifiedOnly => 'Tylko zweryfikowani';

  @override
  String discoverAgeRange(int min, int max) {
    return 'Przedział wieku: $min–$max';
  }

  @override
  String get discoverSpotlightTitle => 'Wyróżnione dopasowania';

  @override
  String get discoverSpotlightSubtitle => 'Wybrane znajomości premium';

  @override
  String discoverPassedCount(int count) {
    return 'Pominięte ($count)';
  }

  @override
  String get discoverOpenChatsFromDiscover =>
      'Otwieraj czaty z sekcji Odkrywaj';

  @override
  String get discoverNoNewNotifications => 'Brak nowych powiadomień';

  @override
  String get discoverNoSpotlightMatchFilters =>
      'Żaden wyróżniony profil nie pasuje do filtrów';

  @override
  String get discoverAllSpotlightReviewed =>
      'Wszystkie wyróżnione profile przejrzane!';

  @override
  String get discoverSpotlightCheckBackLater =>
      'Zajrzyj później po nowe wyróżnione profile';

  @override
  String get discoverReportSubmitted => 'Zgłoszenie wysłane.';

  @override
  String get discoverAppeal => 'Odwołaj się';

  @override
  String discoverAppealPrefill(String userId) {
    return 'Ponowna ocena decyzji moderacji w sprawie zgłoszenia użytkownika $userId';
  }

  @override
  String get discoverProfileUnavailable => 'Ten profil jest teraz niedostępny.';

  @override
  String get discoverGoBack => 'Wróć';

  @override
  String get discoverPremiumView => 'Widok premium';

  @override
  String get todayLabel => 'DZIŚ';

  @override
  String get todayRefreshTooltip => 'Odśwież Dziś';

  @override
  String get todayDiscoveryPreferences => 'Preferencje odkrywania';

  @override
  String get todayHeroTitle => 'Małe „cześć”.\nMiejsce na coś prawdziwego.';

  @override
  String get todayHeroSubtitle => 'Kilka przemyślanych poznań, w twoim tempie.';

  @override
  String get todaySectionPace => 'TWOJE TEMPO';

  @override
  String get todayPaceTitle => 'Co pasuje do twojego tygodnia?';

  @override
  String get todayPaceBody =>
      'Twoje tempo, twój rodzaj pierwszej randki, dostępność opcjonalnie.';

  @override
  String get todaySetRhythm => 'Ustaw swój rytm';

  @override
  String get todaySectionStory => 'TWOJA HISTORIA';

  @override
  String get todaySectionIntroductions => 'DZISIEJSZE PROPOZYCJE';

  @override
  String get todayIntroductionsTitle => 'Kilka osób do poznania';

  @override
  String get todayIntroductionsCaption =>
      'Wspólne zainteresowania to dopiero początek. Chemię odkryjesz sam.';

  @override
  String get todayPausedTitle => 'Daj sobie tyle czasu, ile potrzebujesz.';

  @override
  String get todayPausedBody =>
      'Propozycje są wstrzymane. Twoje rozmowy wciąż tu są.';

  @override
  String get todayManageRhythm => 'Zarządzaj swoim rytmem';

  @override
  String get todayLoadingIntroductions => 'Wczytywanie propozycji';

  @override
  String get todayFailedTitle => 'Twoje propozycje potrzebują chwili.';

  @override
  String get todayFailedBody =>
      'Nie udało się wczytać najnowszych informacji. Spróbuj ponownie.';

  @override
  String get todayTryAgain => 'Spróbuj ponownie';

  @override
  String get todayEmptyTitle => 'Chwila oddechu.';

  @override
  String get todayEmptyBody =>
      'Obecnie nie ma nowych propozycji dla twoich preferencji. Możesz zmienić swój rytm albo przeglądać profile.';

  @override
  String get todayExploreProfiles => 'Przeglądaj profile';

  @override
  String get todayAllIntroductions => 'Wszystkie propozycje';

  @override
  String get todayBreatheTitle => 'Dobra relacja potrzebuje przestrzeni.';

  @override
  String get todayBreatheBody =>
      'To dzisiejsze propozycje. Nie ma odliczania i nie musisz decydować o każdej osobie.';

  @override
  String get todayExploreMore => 'Przeglądaj więcej profili';

  @override
  String get todayCommonGround => 'TROCHĘ WSPÓLNEGO';

  @override
  String todayMeetName(String name) {
    return 'Poznaj: $name';
  }

  @override
  String get todayFirstHelloCoffee =>
      'Na pierwsze spotkanie świetna będzie wspólna kawa.';

  @override
  String get todayFirstHelloWalk =>
      'Na pierwsze spotkanie świetny będzie spacer za dnia.';

  @override
  String get todayFirstHelloMeal =>
      'Na pierwsze spotkanie świetny będzie spokojny posiłek.';

  @override
  String get todayFirstHelloVideoCall =>
      'Na pierwsze spotkanie świetna będzie rozmowa wideo.';

  @override
  String get todayFirstHelloEvent =>
      'Na pierwsze spotkanie świetne będzie wydarzenie, które lubicie oboje.';

  @override
  String get todayFirstHelloDrinks =>
      'Na pierwsze spotkanie świetny będzie wspólny drink.';

  @override
  String get todayFirstHelloOther =>
      'Na pierwsze spotkanie świetne będzie coś, co lubicie oboje.';

  @override
  String get todaySectionTalk => 'COŚ DO POGADANIA';

  @override
  String get todayTalkCaption =>
      'Historie, kluby i podpowiedzi, które ułatwiają pierwsze „cześć”.';

  @override
  String get todayBlogTitle => 'Blog · Otwarte rozdziały';

  @override
  String get todayBlogSubtitle =>
      'Czytaj historie innych członków i pisz własne.';

  @override
  String get todayBookClubsTitle => 'Kluby książki';

  @override
  String get todayBookClubsSubtitle =>
      'Jedna książka tygodniowo, omawiana wspólnie.';

  @override
  String get todayFilmClubsTitle => 'Kluby filmowe';

  @override
  String get todayFilmClubsSubtitle =>
      'Obejrzyj wybrany film, a potem wymieńcie się wrażeniami.';

  @override
  String get todayPhotoThemesTitle => 'Tematy zdjęć';

  @override
  String get todayPhotoThemesSubtitle =>
      'Jedno zdjęcie na temat. Zobacz zdjęcia wszystkich.';

  @override
  String get todayChapterStudioTitle => 'Studio Pierwszy rozdział';

  @override
  String get todayChapterStudioSubtitle => 'Zacznijcie wspólną historię.';

  @override
  String get todayCoverFallbackLine => 'Zdjęcie, które pokochali członkowie';

  @override
  String todayCoverSemantics(String name) {
    return 'Otwórz okładkę tygodnia, autor: $name';
  }

  @override
  String get todayCoverTitle => 'OKŁADKA TYGODNIA';

  @override
  String todayCoverBy(String name) {
    return 'AUTOR: $name';
  }

  @override
  String get todayLikes => 'Polubienia';

  @override
  String get todayComments => 'Komentarze';

  @override
  String get todayThisWeek => 'W tym tygodniu';

  @override
  String get todayWallLabel => 'OD SPOŁECZNOŚCI';

  @override
  String get todayWallTitle => 'Dzisiejsza ściana';

  @override
  String get todayWallCaption =>
      'Historie i zdjęcia, które pokochali członkowie — codziennie nowy wybór';

  @override
  String get todayWallPrevious => 'Poprzedni';

  @override
  String get todayWallNext => 'Następny';

  @override
  String get todayWallChapter => 'ROZDZIAŁ';

  @override
  String get todayWallUntitled => 'Rozdział bez tytułu';

  @override
  String todayWallBy(String name) {
    return 'autor: $name';
  }

  @override
  String get todayWallEmpty =>
      'Twoja ściana zapełni się, gdy członkowie będą dzielić się ulubionymi historiami i zdjęciami';

  @override
  String get todayWallWrite => 'Napisz rozdział';

  @override
  String get todayWallShare => 'Udostępnij zdjęcie';

  @override
  String get profileSetupBackTooltip => 'Wstecz';

  @override
  String profileSetupStepCounter(int current, int total) {
    return 'Krok $current z $total';
  }

  @override
  String get profileSetupLoadErrorTitle =>
      'Nie udało się wczytać danych profilu.';

  @override
  String get profileSetupRetry => 'Spróbuj ponownie';

  @override
  String get profileSetupEducationHighSchool => 'Szkoła średnia';

  @override
  String get profileSetupEducationBachelors => 'Licencjat';

  @override
  String get profileSetupEducationMasters => 'Magisterium';

  @override
  String get profileSetupEducationPhd => 'Doktorat';

  @override
  String get profileSetupEducationOther => 'Inne';

  @override
  String get profileSetupPreferNotToSay => 'Wolę nie podawać';

  @override
  String profileSetupIncomeBelow(String amount) {
    return 'Poniżej $amount';
  }

  @override
  String get profileSetupFrequencyNever => 'Nigdy';

  @override
  String get profileSetupFrequencySocially => 'Towarzysko';

  @override
  String get profileSetupFrequencyOccasionally => 'Okazjonalnie';

  @override
  String get profileSetupFrequencyRegularly => 'Regularnie';

  @override
  String get profileSetupGenderMan => 'Mężczyzna';

  @override
  String get profileSetupGenderWoman => 'Kobieta';

  @override
  String get profileSetupGenderOther => 'Inna';

  @override
  String profileSetupBioTooShort(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Opis musi mieć co najmniej $min znaku.',
      many: 'Opis musi mieć co najmniej $min znaków.',
      few: 'Opis musi mieć co najmniej $min znaki.',
      one: 'Opis musi mieć co najmniej $min znak.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupSaveFailed =>
      'Nie udało się zapisać — spróbuj ponownie.';

  @override
  String get profileSetupCouldNotSaveChanges =>
      'Nie udało się zapisać zmian. Spróbuj ponownie.';

  @override
  String get profileSetupAboutTitle => 'Niech twój profil zabłyśnie';

  @override
  String get profileSetupAboutSubtitle =>
      'Te informacje pomagają znaleźć lepsze dopasowania.';

  @override
  String get profileSetupBioLabel => 'O mnie';

  @override
  String profileSetupBioHint(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Opowiedz coś o sobie (min. $min znaku)',
      many: 'Opowiedz coś o sobie (min. $min znaków)',
      few: 'Opowiedz coś o sobie (min. $min znaki)',
      one: 'Opowiedz coś o sobie (min. $min znak)',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupHeightLabel => 'Wzrost (cm)';

  @override
  String get profileSetupHeightHint => 'Wybierz wzrost';

  @override
  String profileSetupHeightValue(int cm) {
    return '$cm cm';
  }

  @override
  String get profileSetupEducationLabel => 'Wykształcenie';

  @override
  String get profileSetupEducationHint => 'Wybierz wykształcenie';

  @override
  String get profileSetupProfessionLabel => 'Zawód';

  @override
  String get profileSetupProfessionHint => 'np. inżynier oprogramowania';

  @override
  String get profileSetupIncomeLabel => 'Dochód (opcjonalnie)';

  @override
  String get profileSetupLifestyleTitle => 'Styl życia';

  @override
  String get profileSetupDrinkingLabel => 'Alkohol';

  @override
  String get profileSetupSmokingLabel => 'Palenie';

  @override
  String get profileSetupSelectHint => 'Wybierz';

  @override
  String get profileSetupReligionOptionalLabel => 'Religia (opcjonalnie)';

  @override
  String get profileSetupContinue => 'Dalej';

  @override
  String get profileSetupSaveAbout => 'Zapisz „O mnie”';

  @override
  String get profileSetupPhotosSaved => 'Zdjęcia zapisane.';

  @override
  String profileSetupPhotosMaxReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Możesz przesłać maksymalnie $max zdjęcia.',
      many: 'Możesz przesłać maksymalnie $max zdjęć.',
      few: 'Możesz przesłać maksymalnie $max zdjęcia.',
      one: 'Możesz przesłać tylko $max zdjęcie.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupRemovePhotoTitle => 'Usunąć to zdjęcie?';

  @override
  String get profileSetupRemovePhotoBody =>
      'Zostanie usunięte z profilu i z pamięci.';

  @override
  String get profileSetupCancel => 'Anuluj';

  @override
  String get profileSetupRemove => 'Usuń';

  @override
  String profileSetupPhotosMinRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Prześlij co najmniej $min zdjęcia, aby kontynuować.',
      many: 'Prześlij co najmniej $min zdjęć, aby kontynuować.',
      few: 'Prześlij co najmniej $min zdjęcia, aby kontynuować.',
      one: 'Prześlij co najmniej $min zdjęcie, aby kontynuować.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTitle => 'Dodaj swoje zdjęcia';

  @override
  String profileSetupPhotosSubtitle(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Dodaj co najmniej $min zdjęcia, aby dostawać dopasowania',
      many: 'Dodaj co najmniej $min zdjęć, aby dostawać dopasowania',
      few: 'Dodaj co najmniej $min zdjęcia, aby dostawać dopasowania',
      one: 'Dodaj co najmniej $min zdjęcie, aby dostawać dopasowania',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupChooseSource => 'Wybierz źródło';

  @override
  String get profileSetupGallery => 'Galeria';

  @override
  String get profileSetupCamera => 'Aparat';

  @override
  String get profileSetupPhotoRequirements =>
      'JPEG, PNG, WebP lub HEIC · min. 300×300 · 10 MB na zdjęcie · łącznie 50 MB';

  @override
  String profileSetupPhotosTipEmpty(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Dodaj co najmniej $min zdjęcia, aby pokazać różne strony siebie.',
      many: 'Dodaj co najmniej $min zdjęć, aby pokazać różne strony siebie.',
      few: 'Dodaj co najmniej $min zdjęcia, aby pokazać różne strony siebie.',
      one: 'Dodaj co najmniej $min zdjęcie, aby pokazać różne strony siebie.',
    );
    return '$_temp0';
  }

  @override
  String profileSetupPhotosTipMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Dodaj jeszcze $count zdjęcia, aby odblokować pełne dopasowywanie.',
      many: 'Dodaj jeszcze $count zdjęć, aby odblokować pełne dopasowywanie.',
      few: 'Dodaj jeszcze $count zdjęcia, aby odblokować pełne dopasowywanie.',
      one: 'Dodaj jeszcze $count zdjęcie, aby odblokować pełne dopasowywanie.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPhotosTipDone =>
      'Świetnie! Możesz zmieniać kolejność zdjęć, przeciągając je.';

  @override
  String get profileSetupYourPhotosHeading =>
      'Twoje zdjęcia  •  przeciągnij, aby zmienić kolejność';

  @override
  String get profileSetupContinueToAbout => 'Przejdź do „O mnie”';

  @override
  String get profileSetupSavePhotos => 'Zapisz zdjęcia';

  @override
  String get profileSetupPrimaryPhoto => 'Zdjęcie główne';

  @override
  String profileSetupPhotoNumber(int number) {
    return 'Zdjęcie $number';
  }

  @override
  String get profileSetupShownFirst => 'Wyświetlane jako pierwsze w profilu';

  @override
  String get profileSetupDragHandleHint =>
      'Przeciągnij uchwyt, aby zmienić kolejność';

  @override
  String get profileSetupAwaitingSafetyReview =>
      'Czeka na weryfikację bezpieczeństwa';

  @override
  String get profileSetupSafetyCheckInProgress =>
      'Trwa sprawdzanie bezpieczeństwa';

  @override
  String get profileSetupSetAsProfilePicture => 'Ustaw jako zdjęcie profilowe';

  @override
  String get profileSetupProfilePictureSelected => 'Wybrano zdjęcie profilowe';

  @override
  String get profileSetupRemovePhotoTooltip => 'Usuń zdjęcie';

  @override
  String get profileSetupPhotoTooLarge => 'To zdjęcie przekracza limit 10 MB.';

  @override
  String get profileSetupPhotoUnsupportedType =>
      'Użyj zdjęcia w formacie JPEG, PNG, WebP lub HEIC.';

  @override
  String get profileSetupPhotoBadDimensions =>
      'Wymiary zdjęcia muszą mieścić się między 300×300 a 4096×4096.';

  @override
  String get profileSetupPhotoQuotaReached =>
      'Osiągnięto limit zdjęć profilowych.';

  @override
  String get profileSetupPhotoStorageFull =>
      'Miejsce na zdjęcia jest chwilowo pełne. Spróbuj później.';

  @override
  String get profileSetupPhotoUpdateFailed =>
      'Nie udało się zaktualizować zdjęcia. Spróbuj ponownie.';

  @override
  String profileSetupPhotoMaxAllowed(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Dozwolone są maksymalnie $max zdjęcia.',
      many: 'Dozwolonych jest maksymalnie $max zdjęć.',
      few: 'Dozwolone są maksymalnie $max zdjęcia.',
      one: 'Dozwolone jest maksymalnie $max zdjęcie.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupPreferencesLoadFailed =>
      'Nie udało się wczytać preferencji';

  @override
  String get profileSetupOfflineBanner =>
      'Tryb offline — część danych może być nieaktualna.';

  @override
  String get profileSetupYourPreferences => 'Twoje preferencje';

  @override
  String get profileSetupEditPreferencesTitle => 'Edytuj preferencje';

  @override
  String get profileSetupFinishAndFindMatches => 'Zakończ i znajdź dopasowania';

  @override
  String get profileSetupSavePreferences => 'Zapisz preferencje';

  @override
  String get profileSetupSelectGenderPreference =>
      'Wybierz co najmniej jedną płeć.';

  @override
  String get profileSetupFinishFailed =>
      'Nie udało się dokończyć konfiguracji. Sprawdź zdjęcia i preferencje, a potem spróbuj ponownie.';

  @override
  String get profileSetupPreferencesSaveFailed =>
      'Nie udało się teraz zapisać części preferencji.';

  @override
  String get profileSetupPreferencesSaved => 'Preferencje zapisane.';

  @override
  String get profileSetupTabBasic => 'Podstawowe';

  @override
  String get profileSetupTabAdvanced => 'Zaawansowane';

  @override
  String get profileSetupLookingFor => 'Szukam';

  @override
  String get profileSetupSeekingMen => 'Mężczyzn';

  @override
  String get profileSetupSeekingWomen => 'Kobiet';

  @override
  String get profileSetupSeekingOther => 'Inne osoby';

  @override
  String profileSetupAgeRangeTitle(int min, int max) {
    return 'Przedział wieku: $min – $max';
  }

  @override
  String profileSetupMaxDistanceTitle(int km) {
    return 'Maks. odległość: $km km';
  }

  @override
  String profileSetupDistanceValue(int km) {
    return '$km km';
  }

  @override
  String get profileSetupRelationshipIntent => 'Cel związku';

  @override
  String get profileSetupSeriousOnly => 'Tylko poważny związek';

  @override
  String get profileSetupSeriousOnlySubtitle =>
      'Pokazuj tylko osoby szukające stałego związku';

  @override
  String get profileSetupVerifiedOnly => 'Tylko zweryfikowane profile';

  @override
  String get profileSetupVerifiedOnlySubtitle =>
      'Tylko konta ze zweryfikowanym dokumentem';

  @override
  String get profileSetupHookupsOnly => 'Tylko przygody';

  @override
  String get profileSetupHookupsOnlySubtitle =>
      'Pokazuj tylko profile nastawione na przygody';

  @override
  String get profileSetupLocation => 'Lokalizacja';

  @override
  String get profileSetupCountry => 'Kraj';

  @override
  String get profileSetupStateRegion => 'Stan / Region';

  @override
  String get profileSetupCity => 'Miasto';

  @override
  String get profileSetupBackgroundCulture => 'Pochodzenie i kultura';

  @override
  String get profileSetupReligionPreference => 'Religia';

  @override
  String get profileSetupMotherTongue => 'Język ojczysty';

  @override
  String get profileSetupLanguage => 'Język';

  @override
  String get profileSetupDietPreference => 'Preferencje żywieniowe';

  @override
  String get profileSetupWorkoutFrequency => 'Częstotliwość treningów';

  @override
  String get profileSetupDietType => 'Rodzaj diety';

  @override
  String get profileSetupSleepSchedule => 'Rytm snu';

  @override
  String get profileSetupTravelStyle => 'Styl podróżowania';

  @override
  String get profileSetupPoliticalComfortRange => 'Poglądy polityczne partnera';

  @override
  String get profileSetupInterestsPersonality => 'Zainteresowania i osobowość';

  @override
  String get profileSetupInstagramHandle => 'Nazwa na Instagramie (bez @)';

  @override
  String get profileSetupIntentTags =>
      'Intencje (na dłużej, małżeństwo, luźno…)';

  @override
  String get profileSetupHobbiesField => 'Hobby (oddzielone przecinkami)';

  @override
  String get profileSetupFavouriteBooksField =>
      'Ulubione książki (oddzielone przecinkami)';

  @override
  String get profileSetupFavouriteNovelsField =>
      'Ulubione powieści (oddzielone przecinkami)';

  @override
  String get profileSetupFavouriteSongsField =>
      'Ulubione piosenki (oddzielone przecinkami)';

  @override
  String get profileSetupExtraCurricularField =>
      'Zajęcia dodatkowe (oddzielone przecinkami)';

  @override
  String get profileSetupAdditionalInformation => 'Dodatkowe informacje';

  @override
  String get profileSetupPetPreference => 'Zwierzęta';

  @override
  String get profileSetupDealBreakers => 'Nie do przyjęcia';

  @override
  String get profileSetupTagsField => 'Tagi (oddzielone przecinkami)';

  @override
  String get profileSetupNameRequired => 'Imię jest wymagane.';

  @override
  String get profileSetupDobRequired => 'Data urodzenia jest wymagana.';

  @override
  String profileSetupPhotosRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Wymagane są co najmniej $min zdjęcia.',
      many: 'Wymaganych jest co najmniej $min zdjęć.',
      few: 'Wymagane są co najmniej $min zdjęcia.',
      one: 'Wymagane jest co najmniej $min zdjęcie.',
    );
    return '$_temp0';
  }

  @override
  String get profileSetupServerError => 'Błąd serwera';

  @override
  String get profileSetupNetworkError => 'Błąd sieci — spróbuj ponownie.';

  @override
  String get profileSetupGenericError =>
      'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get profileSetupPreviewTitle => 'Podgląd profilu';

  @override
  String get profileSetupPreviewSubtitle => 'Tak zobaczą cię inni.';

  @override
  String profileSetupNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String profileSetupDrinksChip(String value) {
    return 'Alkohol: $value';
  }

  @override
  String profileSetupSmokesChip(String value) {
    return 'Palenie: $value';
  }

  @override
  String get profileSetupCompleteProfile => 'Zakończ profil';

  @override
  String profileSetupCompletionPercent(int percent) {
    return 'Profil uzupełniony w $percent%';
  }

  @override
  String get profileEditTitle => 'Edytuj profil';

  @override
  String get profileEditRefreshTooltip => 'Odśwież profil';

  @override
  String get profileEditAboutYou => 'O tobie';

  @override
  String get profileEditEditAbout => 'Edytuj „O mnie”';

  @override
  String get profileEditName => 'Imię';

  @override
  String get profileEditPhone => 'Telefon';

  @override
  String get profileEditDateOfBirth => 'Data urodzenia';

  @override
  String get profileEditGender => 'Płeć';

  @override
  String get profileEditHeight => 'Wzrost';

  @override
  String get profileEditIncomeRange => 'Przedział dochodów';

  @override
  String get profileEditLocationSocial => 'Lokalizacja i social media';

  @override
  String get profileEditEditPreferences => 'Edytuj preferencje';

  @override
  String get profileEditState => 'Region';

  @override
  String get profileEditInstagram => 'Instagram';

  @override
  String get profileEditDatingPreferences => 'Preferencje randkowe';

  @override
  String get profileEditSeeking => 'Szukam';

  @override
  String get profileEditAgeRange => 'Przedział wieku';

  @override
  String profileEditAgeRangeValue(int min, int max) {
    return '$min–$max';
  }

  @override
  String get profileEditMaxDistance => 'Maks. odległość';

  @override
  String get profileEditEducationFilter => 'Filtr wykształcenia';

  @override
  String get profileEditSeriousOnly => 'Tylko na poważnie';

  @override
  String get profileEditVerifiedOnly => 'Tylko zweryfikowani';

  @override
  String get profileEditHookupOnly => 'Tylko przygody';

  @override
  String get profileEditYes => 'Tak';

  @override
  String get profileEditNo => 'Nie';

  @override
  String get profileEditIntent => 'Intencja';

  @override
  String get profileEditLanguages => 'Języki';

  @override
  String get profileEditDealBreakers => 'Nie do przyjęcia';

  @override
  String get profileEditReligion => 'Religia';

  @override
  String get profileEditPets => 'Zwierzęta';

  @override
  String get profileEditWorkout => 'Trening';

  @override
  String get profileEditPoliticsComfort => 'Polityka';

  @override
  String get profileEditInterestsDetails => 'Zainteresowania i szczegóły';

  @override
  String get profileEditHobbies => 'Hobby';

  @override
  String get profileEditBooks => 'Książki';

  @override
  String get profileEditNovels => 'Powieści';

  @override
  String get profileEditSongs => 'Piosenki';

  @override
  String get profileEditExtraCurriculars => 'Zajęcia dodatkowe';

  @override
  String get profileEditAdditionalInfo => 'Dodatkowe informacje';

  @override
  String get profileEditNotSet => 'Nie podano';

  @override
  String get profileEditLoadingTitle => 'Wczytywanie zapisanego profilu';

  @override
  String get profileEditLoadingBody =>
      'Wczytujemy dane zapisane podczas zakładania konta.';

  @override
  String get profileEditYourProfile => 'Twój profil';

  @override
  String profileEditPercentComplete(int percent) {
    return 'Uzupełniono w $percent%';
  }

  @override
  String get profileEditPhotoGallery => 'Galeria zdjęć';

  @override
  String get profileEditManagePhotos => 'Zarządzaj zdjęciami';

  @override
  String get profileEditNoPhotos => 'Nie przesłano jeszcze zdjęć.';

  @override
  String get profileEditPrimaryBadge => 'Główne';

  @override
  String get engagementHubPromptLoading => 'Wczytywanie dzisiejszego pytania';

  @override
  String get engagementHubPromptIntro =>
      'Odpowiadaj codziennie na jedno pytanie i buduj swoją serię.';

  @override
  String engagementHubPromptRepliedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count osoby odpowiedziały dzisiaj',
      many: '$count osób odpowiedziało dzisiaj',
      few: '$count osoby odpowiedziały dzisiaj',
      one: '$count osoba odpowiedziała dzisiaj',
    );
    return '$_temp0';
  }

  @override
  String engagementHubPromptStreakSummary(int days, int similar) {
    return 'Seria $days dni · podobne odpowiedzi: $similar';
  }

  @override
  String get engagementHubBlogTitle => 'Blog · Open Chapters';

  @override
  String get engagementHubBlogSubtitle =>
      'Czytaj historie, dziel się zdjęciami i pisz własne.';

  @override
  String get engagementHubPhotoThemesTitle => 'Tematy zdjęć';

  @override
  String get engagementHubPhotoThemesSubtitle =>
      'Dodaj jedno zdjęcie na temat i zobacz zdjęcia innych.';

  @override
  String get engagementHubClubsTitle => 'Kluby książkowe i filmowe';

  @override
  String get engagementHubClubsSubtitle =>
      'Śledź wybór tygodnia, rozmawiaj o nim i oceniaj.';

  @override
  String get engagementHubCityPilotTitle => 'Pilotaż w mieście';

  @override
  String get engagementHubCityPilotSubtitle =>
      'Mała społeczność. Rozmowy, które zmieniają się w plany.';

  @override
  String get engagementDailyPromptTitle => 'Seria pytań dnia';

  @override
  String get engagementHubVoiceTitle =>
      'Głosowe przełamywacze lodów z podpowiedzią';

  @override
  String get engagementHubVoiceSubtitle =>
      'Jedno głosowe intro (20–45 s) na parę dziennie';

  @override
  String get engagementCirclesTitle => 'Wyzwania lokalnych kręgów';

  @override
  String get engagementHubCirclesSubtitle =>
      'Dołącz do kręgu w swoim mieście i wyślij odpowiedź na ten tydzień';

  @override
  String get engagementHubCoffeeTitle => 'Ankieta na wspólną kawę';

  @override
  String get engagementHubCoffeeSubtitle =>
      'Twórz proste ankiety o spotkaniach, głosuj i zamykaj je';

  @override
  String get engagementHubGroupsTitle => 'Grupy';

  @override
  String get engagementHubGroupsSubtitle =>
      'Społeczności lifestyle’owe i prywatne grupy znajomych';

  @override
  String get engagementHubRoomsSubtitle =>
      'Czaty na żywo: wpadnij, porozmawiaj, poznaj znajomych';

  @override
  String get engagementHubFriendsTitle => 'Znajomi i przedstawienia';

  @override
  String get engagementHubFriendsSubtitle =>
      'Zaproś zaufaną osobę, nawet jeśli nie randkuje';

  @override
  String get engagementLevelTitle => 'Poziom i XP';

  @override
  String get engagementHubLevelSubtitle =>
      'Śledź wartościową aktywność, nagrody za poziomy i progi zaufania';

  @override
  String get engagementHubPaywallFree =>
      'Podstawowy postęp pozostaje bez paywalla.';

  @override
  String get engagementHubPolicyUpdating =>
      'Zasady monetyzacji są aktualizowane.';

  @override
  String engagementHubPremiumAreas(String features) {
    return 'Opcjonalne obszary premium: $features';
  }

  @override
  String get engagementHubEyebrow => 'AKTYWNOŚCI';

  @override
  String get engagementHubTitle => 'Twórzcie coś razem.';

  @override
  String get engagementHubSubtitle =>
      'Silniejsze dopasowania dzięki zaufaniu i wspólnym aktywnościom.';

  @override
  String get engagementHubSectionCreate => 'TWÓRZ I UDOSTĘPNIAJ';

  @override
  String get engagementHubSectionCreateCaption =>
      'Historie, zdjęcia i kluby, od których zaczynają się prawdziwe rozmowy.';

  @override
  String get engagementHubSectionMeet => 'POZNAWAJ LUDZI';

  @override
  String get engagementHubSectionMeetCaption =>
      'Małe grupy, pytania i plany w twoim tempie.';

  @override
  String get engagementHubSectionProgress => 'ZAUFANIE I POSTĘPY';

  @override
  String get engagementHubSectionProgressCaption =>
      'Twój poziom, twoje odznaki i kto może cię znaleźć.';

  @override
  String get engagementVoiceAppBarTitle => 'Głos, trochę bliżej';

  @override
  String get engagementVoiceHeadline => 'Niech twoje „cześć”\nbrzmi jak ty.';

  @override
  String get engagementVoiceIntro =>
      'Opcjonalne przedstawienie się w 20–45 sekund, widoczne tylko w tej rozmowie. Tekst też jest zawsze mile widziany.';

  @override
  String engagementVoiceYouAndName(String name) {
    return 'Ty i $name';
  }

  @override
  String get engagementVoiceYouAndYourMatch => 'Ty i twoje dopasowanie';

  @override
  String get engagementVoicePrivate => 'Widoczne tylko w tej rozmowie';

  @override
  String get engagementVoiceConversationsLoadFailed =>
      'Nie udało się wczytać twoich rozmów.';

  @override
  String get engagementVoiceNoMatches =>
      'Gdy będziesz mieć dopasowanie, możesz tu udostępnić głosowe przedstawienie. Bez pośpiechu.';

  @override
  String get engagementVoicePickConversation => 'Z kim chcesz się przywitać?';

  @override
  String get engagementVoiceStartingPoint => 'Mały punkt wyjścia';

  @override
  String get engagementVoiceChoosePrompt => 'Wybierz pytanie';

  @override
  String get engagementVoiceTranscriptLabel => 'Twoje słowa na piśmie';

  @override
  String get engagementVoiceTranscriptHelper =>
      'Zapisz to, co mówisz, żeby można było też to przeczytać. To nie jest automatyczna transkrypcja.';

  @override
  String engagementVoiceStop(int seconds) {
    return 'Zatrzymaj · $seconds s';
  }

  @override
  String get engagementVoiceRecord => 'Nagraj swoje „cześć”';

  @override
  String engagementVoiceRecordAgain(int seconds) {
    return 'Nagraj ponownie · $seconds s';
  }

  @override
  String get engagementVoiceRecordingReady =>
      'Nagranie gotowe. Sprawdź tekst przed wysłaniem.';

  @override
  String get engagementVoiceRecordingShort =>
      'Trochę za krótko. Nagraj 20–45 sekund.';

  @override
  String get engagementVoiceDiscard => 'Odrzuć nagranie';

  @override
  String get engagementVoiceSubmitted =>
      'Przedstawienie wysłane. Zatwierdzone nagrania pojawią się poniżej.';

  @override
  String get engagementVoiceSending => 'Wysyłanie…';

  @override
  String get engagementVoiceShare => 'Wyślij swoje „cześć”';

  @override
  String get engagementVoiceCheckedNote =>
      'Nagrania są sprawdzane przed udostępnieniem. Nie ma autoodtwarzania.';

  @override
  String get engagementVoiceYourIntros => 'Wasze głosowe przedstawienia';

  @override
  String get engagementVoiceLatestNote =>
      'Ostatnie 20 zatwierdzonych nagrań w tej rozmowie. Tekst zawsze można przeczytać.';

  @override
  String get engagementVoiceIntrosLoadFailed =>
      'Nie udało się wczytać przedstawień. Ta rozmowa może być już niedostępna.';

  @override
  String get engagementVoiceNothingYet =>
      'Jeszcze nic tu nie ma. Zwykłe „cześć” to dobry początek.';

  @override
  String get engagementVoiceYourHello => 'Twoje „cześć”';

  @override
  String engagementVoiceHelloFromName(String name) {
    return '„Cześć” od $name';
  }

  @override
  String get engagementVoiceHelloFromYourMatch =>
      '„Cześć” od twojego dopasowania';

  @override
  String get engagementVoiceTranscriptHeading => 'TEKST';

  @override
  String get engagementVoiceStopPlayback => 'Zatrzymaj odtwarzanie';

  @override
  String engagementVoiceListen(int seconds) {
    return 'Posłuchaj · $seconds s';
  }

  @override
  String get engagementVoiceReloadPrompts => 'Wczytaj pytania ponownie';

  @override
  String get engagementVoiceMicPermission =>
      'Zezwól na dostęp do mikrofonu, aby nagrywać. Teksty możesz czytać i bez tego.';

  @override
  String get engagementVoiceStartFailed =>
      'Nie udało się rozpocząć nagrywania. Sprawdź dostęp do mikrofonu i spróbuj ponownie.';

  @override
  String get engagementVoiceSaveFailed =>
      'Nie udało się zapisać nagrania. Spróbuj ponownie.';

  @override
  String get engagementVoicePromptsLoadFailed =>
      'Nie można teraz wczytać pytań głosowych.';

  @override
  String get engagementSessionUnavailable => 'Sesja jest niedostępna.';

  @override
  String get engagementVoiceChooseConversation => 'Najpierw wybierz rozmowę.';

  @override
  String get engagementVoiceSelectPrompt => 'Wybierz pytanie głosowe.';

  @override
  String get engagementVoiceEnterTranscript => 'Wpisz tekst.';

  @override
  String get engagementVoiceSessionFailed =>
      'Nie udało się utworzyć sesji głosowego przełamywacza lodów.';

  @override
  String get engagementVoiceSendFailed =>
      'Nie można teraz wysłać głosowego przełamywacza lodów.';

  @override
  String get engagementVoicePlaybackUserRequired =>
      'Do oznaczenia odtworzenia potrzebny jest identyfikator użytkownika.';

  @override
  String get engagementVoiceMarkPlaybackFailed =>
      'Nie można teraz oznaczyć odtworzenia.';

  @override
  String get engagementVoicePlayFailed =>
      'Nie można teraz odtworzyć tego nagrania.';

  @override
  String get chatStarterSmile => 'Co dziś wywołało twój uśmiech?';

  @override
  String get chatStarterSunday => 'Twoja idealna niedziela: opowiadaj.';

  @override
  String get chatStarterCoffee => 'Kawa, spacer czy mała przygoda?';

  @override
  String get chatWelcomeTitle =>
      'Każda dobra historia\nzaczyna się od „cześć”.';

  @override
  String get chatWelcomePending =>
      'Rozmowa otworzy się, gdy para zostanie potwierdzona.';

  @override
  String get chatWelcomeBody =>
      'Nie potrzeba idealnego pierwszego zdania. Po prostu bądź sobą.';

  @override
  String get chatInspirationEyebrow => 'TROCHĘ INSPIRACJI';

  @override
  String get chatAllConversations => 'Wszystkie rozmowy';

  @override
  String get chatMakeConnectionEyebrow => 'NAWIĄŻ KONTAKT';

  @override
  String get chatLessSmallTalk => 'Trochę mniej small talku.';

  @override
  String get chatLessSmallTalkBody =>
      'Zapytaj o to, co tę osobę naprawdę cieszy. Podziel się czymś, co do ciebie pasuje.';

  @override
  String get chatFindTheWords => 'Znajdź słowa';

  @override
  String get chatSendJoy => 'Wyślij trochę radości';

  @override
  String get chatPaceTitle => 'Twoje tempo. Twoja przestrzeń.';

  @override
  String get chatPaceBody =>
      'Dziel się tylko tym, z czym czujesz się dobrze. Dobra relacja szanuje twoje granice.';

  @override
  String get chatWriteMessageHint => 'Napisz wiadomość…';

  @override
  String get chatConversationPaused => 'Rozmowa wstrzymana';

  @override
  String get chatSendingMessageTooltip => 'Wysyłanie wiadomości';

  @override
  String get chatSendMessageTooltip => 'Wyślij wiadomość';

  @override
  String get chatSendGiftTooltip => 'Wyślij prezent';

  @override
  String get chatAddEmojiTooltip => 'Dodaj emoji';

  @override
  String get chatDraftedWithHelp => 'Napisane z pomocą';

  @override
  String get chatHelpMeSayIt => 'Pomóż mi to ująć';

  @override
  String get chatEnterToSendHint =>
      'Enter, aby wysłać · Shift + Enter, aby przejść do nowej linii';

  @override
  String get chatToday => 'Dzisiaj';

  @override
  String get chatYesterday => 'Wczoraj';

  @override
  String get chatGiftOptions => 'Opcje prezentu';

  @override
  String get chatStatusRead => 'Przeczytano';

  @override
  String get chatStatusDelivered => 'Dostarczono';

  @override
  String get chatStatusSent => 'Wysłano';

  @override
  String get chatGestureGiftHeading => 'Gest + róża w prezencie';

  @override
  String get chatGiftForYouHeading => 'Mały upominek dla ciebie';

  @override
  String chatGiftTone(String tone) {
    return 'Ton: $tone';
  }

  @override
  String get chatFreeGift => 'Darmowy prezent';

  @override
  String get chatCopilotKindOpener => 'Na początek';

  @override
  String get chatCopilotKindReply => 'Odpowiedź';

  @override
  String get chatCopilotKindDateIdea => 'Pomysł na randkę';

  @override
  String get chatCopilotToneWarm => 'Ciepły';

  @override
  String get chatCopilotTonePlayful => 'Zabawny';

  @override
  String get chatCopilotToneDirect => 'Bezpośredni';

  @override
  String chatCopilotIntro(String name) {
    return 'Wersja robocza w twoim stylu, na podstawie profilu $name i waszej rozmowy. Nigdy nie wysyłamy jej za ciebie, a jeśli wyślesz ją bez zmian, druga osoba zobaczy, że powstała z pomocą.';
  }

  @override
  String chatCopilotDisclosure(String disclosure, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Na dziś zostało $count wersji roboczej.',
      many: 'Na dziś zostało $count wersji roboczych.',
      few: 'Na dziś zostały $count wersje robocze.',
      one: 'Na dziś została 1 wersja robocza.',
    );
    return '$disclosure $_temp0';
  }

  @override
  String get chatCopilotDraftIt => 'Napisz wersję roboczą';

  @override
  String get chatCopilotTryAnother => 'Inna wersja';

  @override
  String get chatCopilotUseAndEdit => 'Użyj i edytuj';

  @override
  String get chatCopilotEmpty => 'Asystent nic nie zwrócił.';

  @override
  String get chatCopilotUnavailable => 'Asystent jest niedostępny.';

  @override
  String get chatErrorMatchEnded => 'Ta para została zakończona.';

  @override
  String get chatErrorLoadMessages =>
      'Nie udało się wczytać wiadomości. Spróbuj ponownie.';

  @override
  String get chatErrorLockedQuest =>
      'Czat jest zablokowany do czasu zatwierdzenia zadania.';

  @override
  String get chatErrorSendFailed => 'Nie udało się wysłać wiadomości.';

  @override
  String get chatErrorDeleteFailed => 'Nie udało się usunąć wiadomości.';

  @override
  String get chatErrorDeleteWindowExpired => 'Minął czas na usunięcie (24 h).';

  @override
  String get chatErrorOnlyReceivedGifts =>
      'Zarządzać można tylko otrzymanymi prezentami.';

  @override
  String get chatErrorGiftGone => 'Ten prezent nie jest już dostępny.';

  @override
  String get chatErrorGiftReportFailed =>
      'Nie udało się zgłosić prezentu. Spróbuj ponownie.';

  @override
  String get chatErrorGiftHideFailed =>
      'Nie udało się ukryć prezentu. Spróbuj ponownie.';

  @override
  String get chatErrorGiftsUnavailable => 'Prezenty-róże są teraz niedostępne.';

  @override
  String chatErrorNotEnoughCoins(String gift) {
    return 'Za mało monet, by wysłać $gift.';
  }

  @override
  String get chatErrorNotEnoughCoinsSelected =>
      'Za mało monet na wybrany prezent.';

  @override
  String get chatErrorWalletFrozen =>
      'Twoje monety są wstrzymane, dopóki sprawdzamy zwrócony zakup. Darmowe prezenty są nadal dostępne.';

  @override
  String get chatErrorGiftVelocity =>
      'Wysłano dużo prezentów w krótkim czasie. Spróbuj później.';

  @override
  String get chatErrorFreeGiftUsed =>
      'Dzisiejszy darmowy prezent został już wysłany. Nowy będzie dostępny po północy UTC.';

  @override
  String chatErrorGiftNotAvailable(String gift) {
    return '$gift jest teraz niedostępny.';
  }

  @override
  String get chatErrorGiftNeedsActiveMatch =>
      'Prezenty można wysyłać tylko w aktywnej parze.';

  @override
  String get chatErrorExclusiveGiftOnce =>
      'Ten ekskluzywny prezent można dziś wysłać tylko raz.';

  @override
  String get chatErrorGiftFailed => 'Nie udało się wysłać prezentu.';

  @override
  String get chatErrorSessionUnavailable =>
      'Sesja użytkownika jest niedostępna.';

  @override
  String get chatErrorConversationUnavailable => 'Rozmowa jest niedostępna.';

  @override
  String get verificationLandingTitle => 'Zweryfikuj się bez obaw';

  @override
  String get verificationLandingBody =>
      'Prześlij wyraźne zdjęcie urzędowego dokumentu tożsamości i aktualne selfie. Pliki są przesyłane w postaci zaszyfrowanej i przechowywane w prywatnym obszarze dowodów.';

  @override
  String get verificationLandingDisclaimer =>
      'Weryfikacja dodaje kontekst do Twojego profilu. Nigdy nie gwarantuje tożsamości, intencji ani bezpieczeństwa innej osoby.';

  @override
  String get verificationViewVerifiedStatus => 'Zobacz status weryfikacji';

  @override
  String get verificationViewReviewStatus => 'Zobacz status sprawdzania';

  @override
  String get verificationStartButton => 'Rozpocznij bezpieczną weryfikację';

  @override
  String get verificationUploadIdTitle => 'Prześlij dokument';

  @override
  String get verificationUploadIdInstruction =>
      'Zrób lub prześlij wyraźne zdjęcie urzędowego dokumentu tożsamości.';

  @override
  String get verificationGallery => 'Galeria';

  @override
  String get verificationCamera => 'Aparat';

  @override
  String get verificationNext => 'Dalej';

  @override
  String get verificationSelfieTitle => 'Selfie';

  @override
  String get verificationSelfieInstruction => 'Zrób wyraźne selfie.';

  @override
  String get verificationUploadFailed =>
      'Nie udało się przesłać plików. Sprawdź je i spróbuj ponownie.';

  @override
  String get verificationSubmit => 'Wyślij';

  @override
  String get verificationStatusTitle => 'Status weryfikacji';

  @override
  String get verificationRetry => 'Ponów';

  @override
  String get verificationStatusVerified => 'Zweryfikowano';

  @override
  String get verificationStatusVerifiedMessage =>
      'Weryfikacja została zakończona.';

  @override
  String get verificationStatusRejected => 'Odrzucono';

  @override
  String get verificationStatusRejectedFallback => 'Spróbuj ponownie.';

  @override
  String get verificationStatusPending => 'Oczekuje';

  @override
  String get verificationStatusPendingMessage => 'Trwa sprawdzanie.';

  @override
  String get verificationStatusNotStarted => 'Nie rozpoczęto';

  @override
  String get verificationStatusNotStartedMessage =>
      'Rozpocznij weryfikację w Ustawieniach.';

  @override
  String get safetySosTitle => 'SOS alarmowy';

  @override
  String get safetySosDefaultMessage =>
      'Potrzebuję natychmiastowej pomocy. Proszę, sprawdźcie, czy wszystko u mnie w porządku.';

  @override
  String get safetySosHeadline => 'Uruchom alarm';

  @override
  String get safetySosIntro =>
      'Jeśli grozi Ci bezpośrednie niebezpieczeństwo, najpierw skontaktuj się z lokalnymi służbami ratunkowymi. Ten alarm zostanie zapisany dla zespołu bezpieczeństwa.';

  @override
  String get safetySosLevelUrgent => 'Pilne';

  @override
  String get safetySosLevelCritical => 'Krytyczne';

  @override
  String get safetySosMessageLabel => 'Wiadomość dla zespołu bezpieczeństwa';

  @override
  String get safetySosActivating => 'Uruchamianie…';

  @override
  String get safetySosActivate => 'Uruchom SOS';

  @override
  String get safetySosLocationNote =>
      'Lokalizacja jest pobierana tylko na potrzeby tego alarmu. Możesz kontynuować bez zgody.';

  @override
  String get safetySosHistoryTitle => 'Historia alarmów';

  @override
  String get safetySosHistoryEmpty => 'Brak zapisanych alarmów SOS.';

  @override
  String safetySosHistoryHeading(String level, String status) {
    return '$level · $status';
  }

  @override
  String get safetySosAlertLevelLow => 'NISKI';

  @override
  String get safetySosAlertLevelMedium => 'ŚREDNI';

  @override
  String get safetySosAlertLevelHigh => 'WYSOKI';

  @override
  String get safetySosAlertLevelCritical => 'KRYTYCZNY';

  @override
  String get safetySosAlertStatusOpen => 'otwarty';

  @override
  String get safetySosAlertStatusActive => 'aktywny';

  @override
  String get safetySosAlertStatusAcknowledged => 'przyjęty';

  @override
  String get safetySosAlertStatusResolved => 'rozwiązany';

  @override
  String safetySosHistoryMetaWithLocation(String date) {
    return '$date · z lokalizacją';
  }

  @override
  String safetySosHistoryMetaNoLocation(String date) {
    return '$date · bez lokalizacji';
  }

  @override
  String safetySosResolution(String note) {
    return 'Rozwiązanie: $note';
  }

  @override
  String get safetySosConfirmTitle => 'Uruchomić SOS teraz?';

  @override
  String get safetySosConfirmBody =>
      'Utworzy to alarm dla zespołu bezpieczeństwa i spróbuje dołączyć Twoją bieżącą lokalizację.';

  @override
  String get safetySosCancel => 'Anuluj';

  @override
  String get safetySosConfirmActivate => 'Uruchom';

  @override
  String get safetySosActivatedTitle => 'Alarm SOS uruchomiony';

  @override
  String get safetySosActivatedWithLocation =>
      'Zapisano Twój alarm i bieżącą lokalizację.';

  @override
  String get safetySosActivatedWithoutLocation =>
      'Alarm zapisano bez lokalizacji. Uprawnienie do lokalizacji było niedostępne lub odrzucone.';

  @override
  String get safetySosDone => 'Gotowe';

  @override
  String get safetySosSignInToView => 'Zaloguj się, aby zobaczyć historię SOS.';

  @override
  String get safetySosLoadFailed => 'Nie udało się wczytać historii SOS.';

  @override
  String get safetySosSignInToActivate =>
      'Zaloguj się przed uruchomieniem SOS.';

  @override
  String get safetySosActivateFailed => 'Nie udało się uruchomić SOS.';

  @override
  String get photoThemesTitle => 'Tematy zdjęć';

  @override
  String get photoThemesSignIn => 'Zaloguj się, aby zobaczyć tematy zdjęć.';

  @override
  String get photoThemesHeroTitle => 'Pokaż kawałek swojego świata';

  @override
  String get photoThemesHeroSubtitle =>
      'Wybierz temat, udostępnij jedno zdjęcie i zobacz, jak odpowiedzieli inni. To łatwy sposób, by zacząć rozmowę.';

  @override
  String get photoThemesLoadFailed => 'Nie udało się wczytać tematów';

  @override
  String get photoThemesCheckConnection => 'Sprawdź połączenie.';

  @override
  String get photoThemesLookAround => 'Możesz się rozejrzeć';

  @override
  String get photoThemesEligibilityShareOwn =>
      'Uzupełnij profil o dwa zatwierdzone zdjęcia, aby udostępniać własne.';

  @override
  String get photoThemesNewPromptsTitle => 'Nowe tematy są w drodze';

  @override
  String get photoThemesNewPromptsBody =>
      'Zajrzyj wkrótce – pojawi się coś do udostępnienia.';

  @override
  String photoThemesSharedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zdjęcia',
      many: '$count zdjęć',
      few: '$count zdjęcia',
      one: '$count zdjęcie',
    );
    return '$_temp0';
  }

  @override
  String get photoThemesYouShared => 'Udostępniono ✓';

  @override
  String get photoThemesBeFirst => 'Udostępnij jako pierwszy →';

  @override
  String get photoThemesSeeEveryone => 'Zobacz zdjęcia wszystkich →';

  @override
  String get photoThemesSharedSnack => 'Zdjęcie udostępnione. Super!';

  @override
  String get photoThemesShareFailed =>
      'Nie udało się udostępnić zdjęcia. Użyj pliku JPEG lub PNG do 10 MB.';

  @override
  String get photoThemesEligibilityShare =>
      'Uzupełnij profil o dwa zatwierdzone zdjęcia, aby udostępniać.';

  @override
  String get photoThemesAlreadyShared =>
      'Już udostępniono zdjęcie w tym temacie. Usuń je, aby dodać nowe.';

  @override
  String get photoThemesThemeFallback => 'Temat zdjęć';

  @override
  String get photoThemesShareTooltip => 'Udostępnij zdjęcie w tym temacie';

  @override
  String get photoThemesShareYourPhoto => 'Udostępnij zdjęcie';

  @override
  String get photoThemesNoPhotosYet => 'Brak zdjęć';

  @override
  String photoThemesBeFirstFor(String title) {
    return 'Udostępnij jako pierwszy w temacie „$title”';
  }

  @override
  String get photoThemesLoadingPrompt => 'Wczytywanie tematu…';

  @override
  String get photoThemesPhotosLoadFailed => 'Nie udało się wczytać zdjęć';

  @override
  String get photoThemesEmptyMessage =>
      'To Twoje zdjęcie może sprawić, że wszyscy zaczną rozmawiać.';

  @override
  String get photoThemesMoreFailed =>
      'Nie udało się wczytać więcej zdjęć. Odśwież';

  @override
  String get photoThemesLoadMore => 'Wczytaj więcej';

  @override
  String get photoThemesPhotoUnavailable =>
      'Zdjęcie niedostępne. Spróbuj ponownie';

  @override
  String photoThemesOpenPhoto(String name) {
    return 'Otwórz zdjęcie: $name';
  }

  @override
  String get photoThemesYou => 'Ty';

  @override
  String get photoThemesWallHelp =>
      'Jeśli zdjęcie spodoba się innym, może trafić na ich tablice Today: 50 polubień i 5 komentarzy to 50 tablic, 100 polubień i 10 komentarzy to 100. Możesz to w każdej chwili wyłączyć.';

  @override
  String get photoThemesRemoveTitle => 'Usunąć zdjęcie?';

  @override
  String get photoThemesRemoveMessage =>
      'Zniknie z tego tematu dla wszystkich. Potem możesz udostępnić nowe.';

  @override
  String get photoThemesRemoveAction => 'Usuń zdjęcie';

  @override
  String get photoThemesRemoveFailed => 'Nie udało się usunąć zdjęcia.';

  @override
  String get photoThemesReachOn =>
      'Teraz zdjęcie może trafiać na tablice innych, gdy im się spodoba.';

  @override
  String get photoThemesReachOff => 'Zdjęcie zniknęło ze wszystkich tablic.';

  @override
  String get photoThemesSharedByYou => 'Udostępnione przez Ciebie';

  @override
  String photoThemesSharedBy(String name) {
    return 'Udostępnione przez: $name';
  }

  @override
  String photoThemesPhotoDescription(String text) {
    return 'Opis zdjęcia: $text';
  }

  @override
  String get photoThemesReachSwitch => 'Pozwól trafiać na tablice innych';

  @override
  String get photoThemesReachIdle =>
      'Inni mogą sprawić, że to zdjęcie zajdzie dalej';

  @override
  String get photoThemesReachLive =>
      'Inni widzą je teraz na swoich tablicach Today.';

  @override
  String get photoThemesRemoveMine => 'Usuń moje zdjęcie';

  @override
  String get photoThemesReport => 'Zgłoś';

  @override
  String photoThemesBlock(String name) {
    return 'Zablokuj: $name';
  }

  @override
  String get photoThemesCommentHint => 'Z czym Ci się kojarzy?';

  @override
  String get photoThemesCommentApproved =>
      'Zatwierdzono. Teraz widzi go każdy, kto widzi to zdjęcie.';

  @override
  String get photoThemesDetailsTitle => 'Opowiedz o nim';

  @override
  String get photoThemesCaption => 'Podpis';

  @override
  String get photoThemesCaptionHint =>
      'Naleśniki, a potem nigdzie się nie spieszyć.';

  @override
  String get photoThemesDescribe => 'Opisz zdjęcie';

  @override
  String get photoThemesDescribeHelper =>
      'Pomaga osobom korzystającym z czytnika ekranu.';

  @override
  String get photoThemesShare => 'Udostępnij';

  @override
  String get photoThemesWallTitle => 'Okładki na Twojej tablicy';

  @override
  String get photoThemesWallCaption => 'Zdjęcia, które pokochali inni';

  @override
  String get photoThemesMasthead => 'TEMATY ZDJĘĆ';

  @override
  String photoThemesByline(String name) {
    return 'AUTOR: $name';
  }

  @override
  String get photoThemesLikes => 'Polubienia';

  @override
  String get photoThemesComments => 'Komentarze';

  @override
  String get photoThemesCancel => 'Anuluj';

  @override
  String get photoThemesTryAgain => 'Spróbuj ponownie';

  @override
  String get photoThemesSaveFailed =>
      'Nie udało się zapisać. Spróbuj ponownie.';

  @override
  String get friendsChatEmpty =>
      'Przywitaj się. Tylko wy dwoje widzicie tę rozmowę.';

  @override
  String get friendsChatOpenFailed =>
      'Nie udało się otworzyć czatu. Spróbuj ponownie.';

  @override
  String get friendsCancelRequestTitle => 'Anulować zaproszenie do znajomych?';

  @override
  String friendsCancelRequestBody(String name) {
    return '$name nie zobaczy już twojego zaproszenia.';
  }

  @override
  String get friendsCancelRequestBodyUnnamed =>
      'Ta osoba nie zobaczy już twojego zaproszenia.';

  @override
  String get friendsKeepIt => 'Zostaw';

  @override
  String get friendsCancelRequest => 'Anuluj zaproszenie';

  @override
  String friendsNowFriends(String name) {
    return 'Ty i $name jesteście teraz znajomymi.';
  }

  @override
  String get friendsNowFriendsUnnamed =>
      'Ty i ta osoba jesteście teraz znajomymi.';

  @override
  String friendsRequestSentTo(String name) {
    return 'Zaproszenie do znajomych wysłane: $name.';
  }

  @override
  String get friendsRequestSentToUnnamed =>
      'Zaproszenie do znajomych wysłane do tej osoby.';

  @override
  String get friendsRequestCancelled => 'Zaproszenie anulowane.';

  @override
  String get friendsRequestFailed => 'Nie udało się wysłać zaproszenia.';

  @override
  String get friendsAddCaption =>
      'Znajomi mogą do siebie pisać i razem coś planować';

  @override
  String get friendsRequested => 'Wysłano';

  @override
  String friendsWaitingFor(String name) {
    return 'Czekasz na: $name. Dotknij, aby anulować.';
  }

  @override
  String get friendsWaitingForUnnamed =>
      'Czekasz na tę osobę. Dotknij, aby anulować.';

  @override
  String get friendsAcceptFriend => 'Akceptuj znajomość';

  @override
  String friendsAskedToBeFriends(String name) {
    return '$name chce się zaprzyjaźnić';
  }

  @override
  String get friendsAskedToBeFriendsUnnamed => 'Ta osoba chce się zaprzyjaźnić';

  @override
  String get friendsMessage => 'Napisz';

  @override
  String get friendsYoureFriends => 'Jesteście znajomymi. Otwórz wasz czat.';

  @override
  String friendsVouchTooShort(int min) {
    return 'Napisz trochę więcej (co najmniej $min znaków).';
  }

  @override
  String friendsVouchTitle(String name) {
    return 'Poleć: $name';
  }

  @override
  String get friendsVouchBody =>
      'Zdanie lub dwa o tym, dlaczego warto poznać tę osobę. Zatwierdzi je, zanim pojawi się na jej profilu z twoim imieniem.';

  @override
  String get friendsVouchLabel => 'Twoje polecenie';

  @override
  String get friendsVouchHint => 'Miły, zabawny i zawsze punktualny.';

  @override
  String get friendsVouchSend => 'Wyślij polecenie';

  @override
  String get friendsIntroChooseTwo => 'Wybierz dwie różne osoby.';

  @override
  String get friendsIntroSheetTitle => 'Zapoznaj dwoje znajomych';

  @override
  String get friendsIntroSheetBody =>
      'Oboje znajomi muszą zezwolić na zapoznania. Każde kontroluje swój podgląd i decyduje prywatnie. Podaj tylko powód, o którym możesz wspomnieć. Ich decyzje i to, czy dojdzie do dopasowania, pozostają prywatne.';

  @override
  String get friendsIntroNeedTwo =>
      'Potrzebujesz co najmniej dwojga znajomych, aby kogoś zapoznać.';

  @override
  String get friendsFirstFriend => 'Pierwsza osoba';

  @override
  String get friendsSecondFriend => 'Druga osoba';

  @override
  String get friendsIntroWhyLabel =>
      'Dlaczego powinni się poznać (opcjonalnie)';

  @override
  String get friendsIntroSubmit => 'Zapoznaj ich';

  @override
  String get friendsLoadFailed =>
      'Nie udało się wczytać znajomych. Spróbuj ponownie.';

  @override
  String get friendsAddFailed => 'Nie udało się dodać znajomego.';

  @override
  String get friendsRemoveFailed => 'Nie udało się usunąć znajomego.';

  @override
  String get friendsRespondFailed =>
      'Nie udało się odpowiedzieć na zaproszenie do znajomych.';

  @override
  String get friendsSocialLoadFailed =>
      'Nie udało się wczytać poleceń i zapoznań.';

  @override
  String get friendsVouchSendFailed => 'Nie udało się wysłać tego polecenia.';

  @override
  String get friendsVouchUpdateFailed =>
      'Nie udało się zaktualizować tego polecenia.';

  @override
  String get friendsVouchWithdrawFailed =>
      'Nie udało się wycofać tego polecenia.';

  @override
  String get friendsIntroMakeFailed => 'Nie udało się wysłać tego zapoznania.';

  @override
  String get friendsIntroAnswerFailed =>
      'Nie udało się odpowiedzieć na to zapoznanie.';

  @override
  String get groupsEyebrow => 'GRUPY';

  @override
  String get groupsTitle => 'Znajdź swoich ludzi.';

  @override
  String get groupsSubtitle =>
      'Społeczności według stylu życia, do których każdy może dołączyć, i prywatne grupy tylko dla twoich znajomych.';

  @override
  String get groupsStartGroup => 'Załóż grupę';

  @override
  String get groupsInvitationsHeader => 'ZAPROSZENIA';

  @override
  String get groupsInvitationsCaption => 'Znajomi zapraszają cię do grupy.';

  @override
  String get groupsAnswerFailed => 'Nie udało się zapisać twojej odpowiedzi.';

  @override
  String groupsWelcome(String name) {
    return 'Witaj w grupie $name!';
  }

  @override
  String get groupsInvitationDeclined => 'Zaproszenie odrzucone.';

  @override
  String get groupsYourGroupsHeader => 'TWOJE GRUPY';

  @override
  String get groupsYourGroupsFailed => 'Nie udało się wczytać twoich grup';

  @override
  String get groupsErrorCheckConnection => 'Sprawdź połączenie z internetem.';

  @override
  String get groupsEmptyTitle => 'Nie masz jeszcze grup';

  @override
  String get groupsEmptyBody =>
      'Dołącz do społeczności poniżej albo załóż prywatną grupę ze znajomymi.';

  @override
  String get groupsDiscoverHeader => 'ODKRYWAJ WEDŁUG STYLU ŻYCIA';

  @override
  String get groupsDiscoverCaption =>
      'Grupy społeczności są otwarte dla wszystkich.';

  @override
  String get groupsLifestylesFailed => 'Nie udało się wczytać stylów życia';

  @override
  String get groupsCategoryAll => 'Wszystkie';

  @override
  String get groupsDiscoverFailed => 'Nie udało się wczytać grup';

  @override
  String get groupsDiscoverEmptyTitle => 'Brak nowych grup do dołączenia';

  @override
  String groupsDiscoverEmptyCategoryTitle(String category) {
    return 'Brak jeszcze grup w kategorii $category';
  }

  @override
  String get groupsDiscoverEmptyBody =>
      'Zrób pierwszy krok: załóż grupę społeczności i zaproś znajomych.';

  @override
  String get groupsStartOne => 'Załóż grupę';

  @override
  String get groupsJoinFailed => 'Nie udało się teraz dołączyć.';

  @override
  String get groupsJoin => 'Dołącz';

  @override
  String groupsJoinNamed(String name) {
    return 'Dołącz do $name';
  }

  @override
  String groupsInvitedBy(String name, String kind, String members) {
    return '$name zaprasza cię · $kind · $members';
  }

  @override
  String groupsInvitedByFriend(String kind, String members) {
    return 'Znajomy zaprasza cię · $kind · $members';
  }

  @override
  String get groupsDecline => 'Odrzuć';

  @override
  String groupsDeclineNamed(String name) {
    return 'Odrzuć $name';
  }

  @override
  String groupsChatEmpty(String name) {
    return 'Przywitaj się z grupą. Wszyscy w $name widzą tu wiadomości.';
  }

  @override
  String groupsInviteFriendsTo(String name) {
    return 'Zaproś znajomych do $name';
  }

  @override
  String get groupsSendInvitations => 'Wyślij zaproszenia';

  @override
  String get groupsInvitationsFailed => 'Nie udało się wysłać zaproszeń.';

  @override
  String groupsInvitationSentTo(String name) {
    return 'Wysłano zaproszenie: $name.';
  }

  @override
  String groupsInvitationsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wysłano $count zaproszenia.',
      many: 'Wysłano $count zaproszeń.',
      few: 'Wysłano $count zaproszenia.',
      one: 'Wysłano $count zaproszenie.',
    );
    return '$_temp0';
  }

  @override
  String groupsLeaveTitle(String name) {
    return 'Opuścić grupę $name?';
  }

  @override
  String get groupsLeaveBodyAlone =>
      'Jesteś jedyną osobą w grupie, więc grupa i jej czat zostaną usunięte.';

  @override
  String get groupsLeaveBodyOwner =>
      'Własność grupy przejdzie na moderatora z najdłuższym stażem, a jeśli go nie ma – na członka z najdłuższym stażem. Stracisz dostęp do czatu.';

  @override
  String get groupsLeaveBodyCommunity =>
      'Stracisz dostęp do czatu grupy. Możesz później dołączyć ponownie.';

  @override
  String get groupsLeaveBodyPrivate =>
      'Stracisz dostęp do czatu grupy. Aby wrócić, potrzebujesz nowego zaproszenia.';

  @override
  String get groupsLeave => 'Opuść';

  @override
  String get groupsLeaveFailed => 'Nie udało się teraz opuścić grupy.';

  @override
  String get groupsCoverUploadFailed =>
      'Nie udało się przesłać zdjęcia okładki. Użyj pliku JPEG lub PNG do 10 MB.';

  @override
  String get groupsRemoveCoverTitle => 'Usunąć zdjęcie okładki?';

  @override
  String groupsRemoveCoverBody(String name) {
    return 'Grupa $name znów będzie mieć okładkę z emoji.';
  }

  @override
  String get groupsRemove => 'Usuń';

  @override
  String get groupsRemoveCoverFailed => 'Nie udało się usunąć zdjęcia okładki.';

  @override
  String get groupsCoverRemoved => 'Usunięto zdjęcie okładki.';

  @override
  String groupsDeleteTitle(String name) {
    return 'Usunąć grupę $name?';
  }

  @override
  String get groupsDeleteBody =>
      'Grupa, jej zaproszenia i czat zostaną usunięte dla wszystkich. Tej operacji nie można cofnąć.';

  @override
  String get groupsDeleteGroup => 'Usuń grupę';

  @override
  String get groupsDeleteFailed => 'Nie udało się usunąć grupy.';

  @override
  String get groupsDetailEyebrow => 'GRUPA';

  @override
  String get groupsDetailTitleFallback => 'Grupa';

  @override
  String get groupsOwnerTools => 'Narzędzia właściciela';

  @override
  String get groupsEditGroup => 'Edytuj grupę';

  @override
  String get groupsAddCoverPhoto => 'Dodaj zdjęcie okładki';

  @override
  String get groupsChangeCoverPhoto => 'Zmień zdjęcie okładki';

  @override
  String get groupsRemoveCoverPhoto => 'Usuń zdjęcie okładki';

  @override
  String get groupsMoreOptions => 'Więcej opcji';

  @override
  String get groupsReportGroup => 'Zgłoś grupę';

  @override
  String get groupsUnavailableTitle => 'Ta grupa jest niedostępna';

  @override
  String get groupsUnavailableBody =>
      'Mogła zostać usunięta albo nie masz już do niej dostępu.';

  @override
  String get groupsOpenToAll => 'Otwarta dla wszystkich';

  @override
  String get groupsPrivate => 'Prywatna';

  @override
  String get groupsYouRunIt => 'Prowadzisz ją';

  @override
  String get groupsYouModerate => 'Moderujesz';

  @override
  String get groupsCoverNotePending =>
      'Dopóki zdjęcie nie zostanie zatwierdzone, widzisz je tylko ty. W tym czasie członkowie widzą okładkę z emoji.';

  @override
  String get groupsCoverNoteRejected =>
      'Twoje ostatnie zdjęcie okładki nie zostało zatwierdzone. Wybierz inne.';

  @override
  String get groupsCoverUnderReview => 'W trakcie weryfikacji';

  @override
  String get groupsChangeCover => 'Zmień okładkę';

  @override
  String get groupsRemoveCover => 'Usuń okładkę';

  @override
  String get groupsRemovedTitle => 'Ta grupa została usunięta po weryfikacji';

  @override
  String get groupsRemovedBodyOwner =>
      'Dopóki grupa jest usunięta, członkowie nie mogą czatować, dołączać ani zapraszać. Powiadomienia o weryfikacji wyjaśniają decyzję i pozwalają się odwołać.';

  @override
  String get groupsRemovedBodyMember =>
      'Dopóki grupa jest usunięta, członkowie nie mogą czatować, dołączać ani zapraszać. Możesz opuścić grupę w dowolnym momencie.';

  @override
  String get groupsMembers => 'Członkowie';

  @override
  String get groupsChatButton => 'Czat grupy';

  @override
  String groupsChatButtonUnread(int count) {
    return 'Czat grupy · nowe: $count';
  }

  @override
  String get groupsInviteFriends => 'Zaproś znajomych';

  @override
  String get groupsWhosHere => 'KTO TU JEST';

  @override
  String get groupsSeeAll => 'Zobacz wszystkich';

  @override
  String get groupsYou => 'Ty';

  @override
  String groupsInvitedToJoin(String name) {
    return 'Masz zaproszenie do grupy $name.';
  }

  @override
  String get groupsJoinGroup => 'Dołącz do grupy';

  @override
  String get groupsJoinHint =>
      'Członkowie widzą, kto tu jest, i czatują razem.';

  @override
  String get groupsCantJoinTitle => 'Nie możesz dołączyć do tej grupy';

  @override
  String get groupsCantJoinBody => 'Może jest pełna albo moderator cię usunął.';

  @override
  String get groupsInvitationOnly => 'Tylko na zaproszenie';

  @override
  String get groupsInvitationOnlyBody =>
      'Członek grupy może zaprosić cię do tej prywatnej grupy.';

  @override
  String get groupsMakeModerator => 'Ustaw jako moderatora';

  @override
  String get groupsMakeMember => 'Ustaw jako członka';

  @override
  String get groupsRemoveFromGroup => 'Usuń z grupy';

  @override
  String groupsRemoveMemberTitle(String name) {
    return 'Usunąć użytkownika $name?';
  }

  @override
  String get groupsRemoveMemberBodyCommunity =>
      'Ta osoba opuści grupę i jej czat i nie będzie mogła sama dołączyć ponownie.';

  @override
  String get groupsRemoveMemberBodyPrivate =>
      'Ta osoba opuści grupę i jej czat.';

  @override
  String get groupsChangeFailed => 'Nie udało się zapisać zmiany.';

  @override
  String get groupsMembersFailed => 'Nie udało się wczytać członków';

  @override
  String get groupsPleaseTryAgain => 'Spróbuj ponownie.';

  @override
  String groupsMemberYou(String name) {
    return '$name (ty)';
  }

  @override
  String get groupsRoleOwner => 'Właściciel';

  @override
  String get groupsRoleModerator => 'Moderator';

  @override
  String get groupsRoleMember => 'Członek';

  @override
  String groupsMemberOptions(String name) {
    return 'Opcje: $name';
  }

  @override
  String get groupsEditFailed => 'Nie udało się zapisać zmian.';

  @override
  String get groupsSaving => 'Zapisywanie…';

  @override
  String get groupsSaveChanges => 'Zapisz zmiany';

  @override
  String get groupsNameLabel => 'Nazwa grupy';

  @override
  String get groupsAboutLabel => 'O czym jest ta grupa?';

  @override
  String get groupsAboutOptionalLabel => 'O czym jest ta grupa? (opcjonalnie)';

  @override
  String get groupsCityLabel => 'Miasto (opcjonalnie)';

  @override
  String get groupsCoverColorTheme => 'Motyw';

  @override
  String get groupsCoverColorAccent => 'Akcent';

  @override
  String get groupsCoverColorWarm => 'Ciepły';

  @override
  String get groupsLifestyleLabel => 'Styl życia';

  @override
  String get groupsCreateCoverUploadFailed =>
      'Twoja grupa jest gotowa, ale nie udało się przesłać zdjęcia okładki. Spróbuj ponownie w grupie.';

  @override
  String get groupsCreatePickLifestyle =>
      'Wybierz styl życia dla swojej grupy społeczności.';

  @override
  String get groupsCreateNameTooShort =>
      'Nazwa grupy musi mieć co najmniej 3 litery.';

  @override
  String get groupsCreateFailed =>
      'Nie udało się utworzyć grupy. Spróbuj ponownie.';

  @override
  String get groupsCreateEyebrow => 'NOWA GRUPA';

  @override
  String get groupsCreateSubtitle => 'Połącz ludzi wokół tego, co kochasz.';

  @override
  String get groupsCreateSubtitleFriends => 'Zrób grupę ze swoich znajomych.';

  @override
  String get groupsCreateKindHeader => 'JAKI RODZAJ';

  @override
  String get groupsKindCommunity => 'Grupa społeczności';

  @override
  String get groupsKindPrivate => 'Grupa prywatna';

  @override
  String get groupsCreateCommunitySubtitle =>
      'Według stylu życia. Każdy może ją znaleźć i dołączyć.';

  @override
  String get groupsCreatePrivateSubtitle =>
      'Tylko znajomi. Dołączyć mogą tylko osoby, które zaprosisz.';

  @override
  String get groupsCreateLifestyleHeader => 'STYL ŻYCIA';

  @override
  String get groupsCreateLifestyleCaption => 'Tu ludzie odkryją twoją grupę.';

  @override
  String get groupsCreateDetailsHeader => 'SZCZEGÓŁY';

  @override
  String get groupsCreateNameHintCommunity => 'Poranni biegacze z Indiranagaru';

  @override
  String get groupsCreateNameHintPrivate => 'Ekipa od niedzielnego brunchu';

  @override
  String get groupsCreateCoverHeader => 'OKŁADKA';

  @override
  String groupsCoverEmojiSemantics(String emoji) {
    return 'Emoji okładki $emoji';
  }

  @override
  String get groupsCreateCoverPhotoOptional => 'Zdjęcie okładki (opcjonalnie)';

  @override
  String get groupsCreateCoverPhotoHint =>
      'Członkowie widzą emoji, dopóki twoje zdjęcie nie zostanie zatwierdzone.';

  @override
  String get groupsCreateAddCoverPhoto => 'Dodaj zdjęcie okładki';

  @override
  String get groupsCreateChangePhoto => 'Zmień zdjęcie';

  @override
  String get groupsCreateRemovePhoto => 'Usuń zdjęcie';

  @override
  String get groupsCreateFriendsHeader => 'ZNAJOMI';

  @override
  String get groupsCreateFriendsCaptionEmpty =>
      'Zaproś znajomych teraz albo później z poziomu grupy.';

  @override
  String get groupsCreateFriendsCaption => 'Dostaną zaproszenie do grupy.';

  @override
  String get groupsFriendFallback => 'Znajomy';

  @override
  String groupsRemoveInvitee(String name) {
    return 'Usuń: $name';
  }

  @override
  String get groupsChooseFriends => 'Wybierz znajomych';

  @override
  String get groupsChangeFriends => 'Zmień znajomych';

  @override
  String get groupsCreating => 'Tworzenie…';

  @override
  String get groupsCreateGroup => 'Utwórz grupę';

  @override
  String get groupsCardRemoved => 'Usunięta po weryfikacji';

  @override
  String groupsCardSemanticsMuted(String name, String details) {
    return '$name, $details, powiadomienia wyciszone';
  }

  @override
  String get groupsNotificationsMuted => 'Powiadomienia wyciszone';

  @override
  String groupsUnreadMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieprzeczytanej wiadomości',
      many: '$count nieprzeczytanych wiadomości',
      few: '$count nieprzeczytane wiadomości',
      one: '$count nieprzeczytana wiadomość',
    );
    return '$_temp0';
  }

  @override
  String get groupsCoverSheetTitle => 'Zdjęcie okładki';

  @override
  String get groupsCoverSheetBody =>
      'Każde zdjęcie jest sprawdzane, zanim zobaczą je inni członkowie. Użyj pliku JPEG lub PNG do 10 MB.';

  @override
  String get groupsCoverFromPhotos => 'Wybierz ze zdjęć';

  @override
  String get groupsCoverTakePhoto => 'Zrób zdjęcie';

  @override
  String get groupsCoverTooLarge =>
      'To zdjęcie ma ponad 10 MB. Wybierz mniejsze.';

  @override
  String get groupsCoverPreviewTitle => 'Podgląd okładki';

  @override
  String get groupsCoverPreviewBody =>
      'Okładki wyświetlają się jako szeroki baner ze środkiem twojego zdjęcia.';

  @override
  String get groupsCancel => 'Anuluj';

  @override
  String get groupsCoverUseThisPhoto => 'Użyj tego zdjęcia';

  @override
  String get groupsCoverPreviewSemantics => 'Twoje nowe zdjęcie okładki';

  @override
  String get groupsCoverChecking => 'Sprawdzanie zdjęcia okładki…';

  @override
  String groupsCoverUploading(int percent) {
    return 'Przesyłanie zdjęcia okładki… $percent%';
  }

  @override
  String get groupsCoverUploadedReview =>
      'Twoja okładka jest weryfikowana. Dopóki nie zostanie zatwierdzona, widzisz ją tylko ty.';

  @override
  String get groupsCoverUpdated => 'Zaktualizowano zdjęcie okładki.';

  @override
  String get groupsPickerSubtitle =>
      'Możesz zapraszać tylko osoby z listy znajomych.';

  @override
  String get groupsDone => 'Gotowe';

  @override
  String get groupsSearchFriends => 'Szukaj znajomych';

  @override
  String get groupsFriendsFailed => 'Nie udało się wczytać znajomych';

  @override
  String get groupsNoFriendsTitle => 'Nie masz jeszcze znajomych';

  @override
  String get groupsNoFriendsBody =>
      'Dodawaj znajomych z Dopasowań, profili lub pokoi, a potem zaproś ich do grupy.';

  @override
  String get groupsAlreadyMember => 'Już jest w tej grupie';

  @override
  String get groupsInvitationSent => 'Zaproszenie wysłane';

  @override
  String get todayActivityCoffee => 'Kawa';

  @override
  String get todayActivityWalk => 'Spacer za dnia';

  @override
  String get todayActivityMeal => 'Posiłek';

  @override
  String get todayActivityPlayful => 'Coś zabawnego';

  @override
  String get todayActivityEvent => 'Wydarzenie';

  @override
  String get todayActivityVideoCall => '„Cześć” przez wideo';

  @override
  String get todayActivityDrinks => 'Drinki';

  @override
  String get todayActivityOther => 'Coś innego';

  @override
  String get todayBudgetFlexible => 'Zdecydujmy razem';

  @override
  String get todayBudgetFree => 'Za darmo';

  @override
  String get todayBudgetModest => 'Skromnie';

  @override
  String get todayBudgetTreat => 'Mała przyjemność';

  @override
  String get todayRhythmTitle => 'Twój rytm randkowania';

  @override
  String get todayRhythmLoadFailed =>
      'Nie udało się wczytać twoich preferencji.';

  @override
  String get todayRhythmSaved => 'Twój rytm randkowania został zapisany.';

  @override
  String get todayRhythmSaveFailed =>
      'Nie udało się zapisać. Twoje wybory wciąż tu są.';

  @override
  String get todayRhythmHeadline => 'Zrób miejsce na swój sposób randkowania.';

  @override
  String get todayRhythmIntro =>
      'Wybierz to, co pasuje do twojego życia. Dostępność i propozycje są opcjonalne i zawsze możesz zmienić zdanie.';

  @override
  String get todayRhythmOpenTo => 'Na co jesteś otwarty/a?';

  @override
  String get todayRhythmIntentNone => 'Wolę nie mówić';

  @override
  String get todayRhythmIntentRelationship => 'Związek';

  @override
  String get todayRhythmIntentExploring => 'Szukam swojej drogi';

  @override
  String get todayRhythmIntentCasual => 'Coś na luzie';

  @override
  String get todayRhythmPaceSection => 'Twoje tempo rozmowy';

  @override
  String get todayRhythmPaceNone => 'Bez preferencji';

  @override
  String get todayRhythmPaceSlow => 'Trochę wolniej';

  @override
  String get todayRhythmPaceSteady => 'Regularna rozmowa';

  @override
  String get todayRhythmPaceFrequent => 'Częsta rozmowa';

  @override
  String get todayRhythmSlowWeek => 'Wolne odpowiedzi w tym tygodniu';

  @override
  String get todayRhythmSlowWeekHint => 'Ten status zniknie po siedmiu dniach.';

  @override
  String get todayRhythmSharePace => 'Udostępniaj ten status moim dopasowaniom';

  @override
  String get todayRhythmSharePaceHint =>
      'Tylko obecne dopasowania widzą twój tymczasowy status.';

  @override
  String get todayRhythmFirstDate => 'Twój rodzaj pierwszej randki';

  @override
  String get todayRhythmChooseFive =>
      'Wybierz maksymalnie pięć. Wspólne preferencje pomagają wyjaśnić twoje propozycje.';

  @override
  String get todayRhythmWeekSection => 'Trochę miejsca w twoim tygodniu';

  @override
  String get todayRhythmShareAvailability =>
      'Uwzględniaj moją ogólną dostępność';

  @override
  String get todayRhythmShareAvailabilityHint =>
      'Pokazywane są tylko rzeczywiste pokrywające się terminy. Twój pełny grafik jest prywatny. Wyłączenie usuwa zapisane przedziały czasu.';

  @override
  String get todayRhythmAvailabilityHint =>
      'Dotknij dowolnego poranka, popołudnia lub wieczoru, który ci pasuje. Godziny są według czasu lokalnego tego urządzenia i wygasają automatycznie.';

  @override
  String get todayRhythmMorning => 'Rano';

  @override
  String get todayRhythmAfternoon => 'Popołudnie';

  @override
  String get todayRhythmEvening => 'Wieczór';

  @override
  String get todayRhythmIntrosSection => 'Propozycje za twoją zgodą';

  @override
  String get todayRhythmFriendIntros =>
      'Zezwalaj na propozycje od zaakceptowanych znajomych';

  @override
  String get todayRhythmFriendIntrosHint =>
      'Obie osoby muszą się zgodzić. Twój znajomy nie dostaje informacji o dopasowaniu ani odmowie. Podgląd zawiera twoje imię i wiek.';

  @override
  String get todayRhythmIntroPhoto => 'Dołącz moje zdjęcia profilowe';

  @override
  String get todayRhythmIntroPhotoHint =>
      'Widzi je tylko osoba, która otrzymuje propozycję.';

  @override
  String get todayRhythmIntroCity => 'Dołącz moje miasto';

  @override
  String get todayRhythmIntroCityHint =>
      'Twoja dokładna lokalizacja nigdy nie jest udostępniana.';

  @override
  String get todayRhythmReload => 'Wczytaj zapisane wybory';

  @override
  String get todayRhythmSaving => 'Zapisywanie…';

  @override
  String get todayRhythmSave => 'Zapisz mój rytm';

  @override
  String get todayRhythmBreakTitle => 'Przerwa jest zawsze w porządku.';

  @override
  String get todayRhythmBreakBody =>
      'Wstrzymuj nowe propozycje, kiedy tylko potrzebujesz. Twoje obecne rozmowy pozostaną dostępne.';

  @override
  String get todayRhythmPauseFailed => 'Nie udało się zaktualizować przerwy.';

  @override
  String get todayRhythmResume => 'Wznów propozycje';

  @override
  String get todayRhythmPause => 'Wstrzymaj propozycje';

  @override
  String get datingConnectionSlowTitle => 'W tym tygodniu odpowiada wolniej';

  @override
  String get datingConnectionSlowBody =>
      'Twoje dopasowanie robi miejsce na wolniejsze tempo.';

  @override
  String get datingConnectionYourTurn => 'Twoja kolej: dodaj niespodziankę';

  @override
  String get datingConnectionComplete => 'Wasz pierwszy rozdział jest gotowy';

  @override
  String get datingConnectionWaiting => 'Wasz rozdział ma już początek';

  @override
  String get datingConnectionCreate => 'Stwórzcie pierwszy rozdział';

  @override
  String get datingConnectionBody =>
      'Początek, niespodzianka i historia, którą tworzycie razem.';

  @override
  String get chemistryTitle => 'Trochę chemii';

  @override
  String get chemistryIntro =>
      'Wybierz coś, co do ciebie pasuje. Nie ma dobrych odpowiedzi i nigdy nie wpływa to na dostęp do czatu.';

  @override
  String get chemistrySaveFailed =>
      'Nie udało się zapisać twojego wyboru. Spróbuj ponownie.';

  @override
  String get chemistryRetry => 'Spróbuj wczytać ponownie';

  @override
  String get chemistryRevealedTitle => 'Obie odpowiedzi razem';

  @override
  String get chemistryYouPicked => 'Twój wybór';

  @override
  String get chemistryMatchPicked => 'Wybór twojego dopasowania';

  @override
  String get chemistryRevealedBody =>
      'Wspólny faworyt albo miła różnica — macie o czym rozmawiać.';

  @override
  String get chemistryWaitingBody =>
      'Twoja odpowiedź jest zapisana prywatnie. Obie odpowiedzi pojawią się tutaj, gdy oboje dokonacie wyboru.';

  @override
  String chemistryYourChoice(String choice) {
    return 'Twój wybór: $choice';
  }

  @override
  String get chemistryAnotherMoment => 'Kolejna chwila, kiedy zechcesz';

  @override
  String get chemistryChooseMoment => 'Wybierz chwilę';

  @override
  String get chemistryPromptSunday => 'Zaplanuj niedzielę';

  @override
  String get chemistryPromptAdventure => 'Wybierz przygodę';

  @override
  String get chemistryPromptFirstDate => 'Twój rodzaj pierwszej randki';

  @override
  String get chemistryQuestionSunday =>
      'Twoja idealna niedziela zaczyna się od…';

  @override
  String get chemistryQuestionAdventure => 'Mała wspólna przygoda…';

  @override
  String get chemistryQuestionFirstDate =>
      'Na pierwsze spotkanie wybrałbyś/wybrałabyś…';

  @override
  String get engagementLevelFrozen =>
      'Postęp jest wstrzymany na czas kontroli bezpieczeństwa konta.';

  @override
  String get engagementLevelTrustGate =>
      'Zweryfikuj profil i dbaj o dobry stan konta, aby odblokować poziomy wymagające zaufania.';

  @override
  String get engagementLevelPathTitle => 'Ścieżka poziomów';

  @override
  String get engagementLevelPathSubtitle =>
      'XP zdobywasz za wartościową aktywność. Zakupy nigdy nie podnoszą poziomu.';

  @override
  String get engagementLevelRewardsTitle => 'Nagrody';

  @override
  String get engagementLevelRewardsSubtitle =>
      'Nagrody są kosmetyczne, ułatwiające albo dają ograniczony wzrost widoczności.';

  @override
  String get engagementLevelRecentTitle => 'Ostatnie XP';

  @override
  String get engagementLevelRecentSubtitle =>
      'Rejestr twojej aktywności jest trwały i możliwy do sprawdzenia.';

  @override
  String engagementLevelNumber(int level) {
    return 'Poziom $level';
  }

  @override
  String engagementLevelXp(String xp) {
    return '$xp XP';
  }

  @override
  String get engagementLevelHighest => 'Osiągnięto najwyższy poziom';

  @override
  String engagementLevelProgress(int xp, String percent) {
    return '$xp XP na tym poziomie · $percent%';
  }

  @override
  String engagementLevelThreshold(int xp, String summary) {
    return '$xp XP · $summary';
  }

  @override
  String get engagementLevelTrustGated => 'Wymaga zaufania';

  @override
  String get engagementLevelClaimed => 'Odebrano';

  @override
  String get engagementLevelClaim => 'Odbierz';

  @override
  String get engagementLevelLocked => 'Zablokowane';

  @override
  String get engagementLevelStandardAward => 'Standardowe przyznanie';

  @override
  String engagementLevelQualityWeighting(String multiplier) {
    return 'Waga jakości ×$multiplier';
  }

  @override
  String get engagementLevelEmptyLedger =>
      'Wykonuj wartościowe aktywności, aby zdobyć pierwsze XP.';

  @override
  String get engagementXpSourceProfileCompleted => 'Profil uzupełniony';

  @override
  String get engagementXpSourceDailyPromptSubmitted =>
      'Odpowiedź na pytanie dnia';

  @override
  String get engagementXpSourceMiniActivityCompleted =>
      'Miniaktywność ukończona';

  @override
  String get engagementXpSourceCircleChallengeSubmitted =>
      'Wyzwanie kręgu wysłane';

  @override
  String get engagementXpSourceVoiceIcebreakerPlayed =>
      'Głosowy przełamywacz lodów odsłuchany';

  @override
  String get engagementXpSourceStreak3 => 'Seria 3 dni';

  @override
  String get engagementXpSourceStreak7 => 'Seria 7 dni';

  @override
  String get engagementXpSourceStreak14 => 'Seria 14 dni';

  @override
  String get engagementXpSourceAdminAdjustment => 'Korekta administratora';

  @override
  String get engagementLevelSignIn =>
      'Zaloguj się, aby zobaczyć postęp poziomu.';

  @override
  String get engagementLevelLoadFailed =>
      'Nie można teraz wczytać twoich postępów.';

  @override
  String get engagementLevelClaimFailed =>
      'Nie można teraz odebrać tej nagrody.';

  @override
  String get engagementCoffeeTitle => 'Ankiety na wspólną kawę';

  @override
  String get engagementCoffeeCreateHeading =>
      'Utwórz prostą ankietę na wspólną kawę';

  @override
  String get engagementCoffeeCreateHint =>
      'Dodaj maksymalnie 3 identyfikatory uczestników (oddzielone przecinkami) i co najmniej jedną opcję.';

  @override
  String get engagementCoffeeParticipantsLabel =>
      'Identyfikatory uczestników (oddzielone przecinkami)';

  @override
  String get engagementCoffeeDeadlineLabel =>
      'Termin w formacie ISO (opcjonalnie)';

  @override
  String engagementCoffeeOptionNumber(int number) {
    return 'Opcja $number';
  }

  @override
  String get engagementCoffeeCreate => 'Utwórz ankietę';

  @override
  String get engagementCoffeeActorLabel =>
      'Inny identyfikator użytkownika dla akcji (opcjonalnie)';

  @override
  String get engagementCoffeeEmpty =>
      'Nie ma jeszcze ankiet. Utwórz pierwszą powyżej.';

  @override
  String engagementCoffeePollId(String id) {
    return 'Ankieta $id';
  }

  @override
  String engagementCoffeeStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get engagementCoffeeStatusOpen => 'otwarta';

  @override
  String get engagementCoffeeStatusFinalized => 'zamknięta';

  @override
  String engagementCoffeeParticipants(String ids) {
    return 'Uczestnicy: $ids';
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
      other: '$day · $time · $area ($count głosu)',
      many: '$day · $time · $area ($count głosów)',
      few: '$day · $time · $area ($count głosy)',
      one: '$day · $time · $area ($count głos)',
    );
    return '$_temp0';
  }

  @override
  String get engagementCoffeeVote => 'Głosuj';

  @override
  String get engagementCoffeeFinalize => 'Zamknij ankietę';

  @override
  String get engagementCoffeeDayLabel => 'Dzień';

  @override
  String get engagementCoffeeTimeLabel => 'Przedział czasu';

  @override
  String get engagementCoffeeAreaLabel => 'Okolica';

  @override
  String get engagementCoffeeLoadFailed =>
      'Nie można teraz wczytać ankiet grupowych.';

  @override
  String get engagementCoffeeCreateFailed =>
      'Nie można teraz utworzyć ankiety grupowej.';

  @override
  String get engagementCoffeeVoteUserRequired =>
      'Do głosowania potrzebny jest identyfikator użytkownika.';

  @override
  String get engagementCoffeeVoteFailed => 'Nie można teraz zagłosować.';

  @override
  String get engagementCoffeeFinalizeUserRequired =>
      'Do zamknięcia potrzebny jest identyfikator użytkownika.';

  @override
  String get engagementCoffeeFinalizeFailed =>
      'Nie można teraz zamknąć ankiety.';

  @override
  String get engagementDailyPromptUnavailable =>
      'Pytanie dnia jest niedostępne';

  @override
  String get engagementDailyPromptPullToRefresh =>
      'Przeciągnij w dół, aby odświeżyć, albo spróbuj za chwilę.';

  @override
  String get engagementDailyPromptDomainValues => 'WARTOŚCI';

  @override
  String get engagementDailyPromptDomainLifestyle => 'STYL ŻYCIA';

  @override
  String get engagementDailyPromptDomainRelationshipStyle => 'STYL ZWIĄZKU';

  @override
  String get engagementDailyPromptSparkTitle => 'Iskra dopasowania';

  @override
  String engagementDailyPromptSparkSummary(int replied, int similar) {
    return 'Odpowiedzi dzisiaj: $replied · podobne odpowiedzi: $similar';
  }

  @override
  String get engagementDailyPromptYourAnswer => 'Twoja odpowiedź';

  @override
  String get engagementDailyPromptHint =>
      'Napisz odpowiedź w mniej niż 60 sekund.';

  @override
  String engagementDailyPromptEditOpenUntil(String time) {
    return 'Edycja możliwa do $time';
  }

  @override
  String get engagementDailyPromptEditOpenSoon =>
      'Edycja możliwa jeszcze przez chwilę';

  @override
  String get engagementDailyPromptEditClosed =>
      'Na dziś edycja jest już zamknięta.';

  @override
  String get engagementDailyPromptEdited => 'Edytowano';

  @override
  String get engagementDailyPromptSubmit => 'Wyślij odpowiedź dnia';

  @override
  String get engagementDailyPromptUpdate => 'Zaktualizuj odpowiedź';

  @override
  String get engagementDailyPromptStreakProgress => 'Postęp serii';

  @override
  String engagementDailyPromptStatCurrent(String value) {
    return 'Obecna: $value';
  }

  @override
  String engagementDailyPromptStatBest(String value) {
    return 'Rekord: $value';
  }

  @override
  String engagementDailyPromptStatNext(String value) {
    return 'Następny cel: $value';
  }

  @override
  String engagementDailyPromptDays(int days) {
    return '$days dni';
  }

  @override
  String get engagementDailyPromptComplete => 'Ukończono';

  @override
  String engagementDailyPromptMilestone(int days) {
    return 'Kamień milowy odblokowany: seria $days dni';
  }

  @override
  String get engagementDailyPromptLoadFailed =>
      'Nie można teraz wczytać pytania dnia.';

  @override
  String get engagementDailyPromptNotLoaded =>
      'Pytanie dnia nie zostało jeszcze wczytane.';

  @override
  String get engagementDailyPromptEnterAnswer => 'Najpierw wpisz odpowiedź.';

  @override
  String get engagementDailyPromptSubmitFailed =>
      'Nie udało się wysłać odpowiedzi. Spróbuj ponownie.';

  @override
  String get clubsKindBooks => 'Książki';

  @override
  String get clubsKindFilms => 'Filmy';

  @override
  String get clubsFilterAll => 'Wszystkie';

  @override
  String get clubsAudiencePrivate => 'Tylko ja';

  @override
  String get clubsAudienceFriends => 'Znajomi';

  @override
  String get clubsAudienceCommunity => 'Społeczność Connect';

  @override
  String get clubsRoleOwner => 'Właściciel';

  @override
  String get clubsRoleModerator => 'Moderator';

  @override
  String get clubsRoleMember => 'Członek';

  @override
  String get clubsBadgeBookClub => 'Klub książki';

  @override
  String get clubsBadgeFilmClub => 'Klub filmowy';

  @override
  String get clubsBadgeBookList => 'Lista książek';

  @override
  String get clubsBadgeFilmList => 'Lista filmów';

  @override
  String get clubsBadgeBook => 'Książka';

  @override
  String get clubsBadgeFilm => 'Film';

  @override
  String get clubsClub => 'Klub';

  @override
  String clubsStarsOutOfFive(String rating) {
    return '$rating na 5 gwiazdek';
  }

  @override
  String clubsStarCount(int count) {
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
  String get clubsNoRatingsYet => 'Brak ocen';

  @override
  String clubsRatingSummary(String average, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recenzji',
      many: '$count recenzji',
      few: '$count recenzje',
      one: '1 recenzja',
    );
    return '$average · $_temp0';
  }

  @override
  String get clubsWeekThis => 'Ten tydzień';

  @override
  String get clubsWeekNext => 'Przyszły tydzień';

  @override
  String get clubsWeekLast => 'Zeszły tydzień';

  @override
  String clubsWeekOf(String date) {
    return 'Tydzień od $date';
  }

  @override
  String get clubsTitle => 'Kluby książki i filmu';

  @override
  String get clubsMyLists => 'Moje listy';

  @override
  String get clubsStartClubTooltip => 'Załóż klub książki lub filmowy';

  @override
  String get clubsStartClub => 'Załóż klub';

  @override
  String get clubsSignInToSee => 'Zaloguj się, aby zobaczyć kluby.';

  @override
  String get clubsHeroTitle => 'Czytaj. Oglądaj. Rozmawiaj.';

  @override
  String get clubsHeroSubtitle =>
      'Dołącz do klubu, śledź jeden wybór tygodnia i podziel się wrażeniami. Dobry gust to świetny początek rozmowy.';

  @override
  String get clubsScopeMine => 'Moje kluby';

  @override
  String get clubsScopeDiscover => 'Odkrywaj';

  @override
  String get clubsLoadErrorTitle => 'Nie udało się wczytać klubów';

  @override
  String get clubsCheckConnection => 'Sprawdź połączenie.';

  @override
  String get clubsLookAroundTitle => 'Możesz się rozejrzeć';

  @override
  String get clubsLookAroundMessage =>
      'Uzupełnij profil o dwa zatwierdzone zdjęcia, aby założyć klub lub do niego dołączyć.';

  @override
  String get clubsEmptyMineTitle => 'Twój pierwszy klub czeka';

  @override
  String get clubsEmptyMineMessage =>
      'Znajdź klub, który czyta lub ogląda to, co kochasz, albo załóż własny.';

  @override
  String get clubsEmptyDiscoverTitle => 'Nie ma tu jeszcze klubów';

  @override
  String get clubsEmptyDiscoverMessage =>
      'Zrób pierwszy krok: załóż klub i wybierz coś świetnego na ten tydzień.';

  @override
  String get clubsDiscoverClubs => 'Odkryj kluby';

  @override
  String clubsMemberCount(int count) {
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
  String get clubsYouRunIt => 'Prowadzisz go';

  @override
  String get clubsYouModerate => 'Moderujesz';

  @override
  String get clubsJoined => 'Dołączono ✓';

  @override
  String get clubsNoPickThisWeek => 'Brak wyboru w tym tygodniu';

  @override
  String get clubsNameTooShort =>
      'Nadaj klubowi nazwę o długości co najmniej 3 liter.';

  @override
  String get clubsCreateFailed => 'Nie udało się utworzyć klubu.';

  @override
  String get clubsNameLabel => 'Nazwa klubu';

  @override
  String get clubsNameHint => 'Niedzielne czytanie bez pośpiechu';

  @override
  String get clubsDescriptionLabel => 'O czym jest twój klub? (opcjonalnie)';

  @override
  String get clubsCreating => 'Tworzenie…';

  @override
  String get clubsCreateClub => 'Utwórz klub';

  @override
  String clubsLeaveTitle(String name) {
    return 'Opuścić klub $name?';
  }

  @override
  String get clubsLeaveMessage =>
      'Możesz wrócić później, dopóki klub jest otwarty.';

  @override
  String get clubsLeaveClub => 'Opuść klub';

  @override
  String clubsWelcome(String name) {
    return 'Witaj w klubie $name!';
  }

  @override
  String get clubsChangeNotSaved => 'Nie udało się zapisać tej zmiany.';

  @override
  String get clubsOptionsTooltip => 'Opcje klubu';

  @override
  String get clubsMembers => 'Członkowie';

  @override
  String get clubsReportClub => 'Zgłoś klub';

  @override
  String get clubsDetailLoadErrorTitle => 'Nie udało się wczytać klubu';

  @override
  String get clubsDetailLoadErrorMessage =>
      'Mógł zostać zamknięty. Spróbuj ponownie.';

  @override
  String get clubsEarlierPicks => 'Wcześniejsze wybory';

  @override
  String clubsPickSubtitle(String week, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wpisu',
      many: '$count wpisów',
      few: '$count wpisy',
      one: '1 wpis',
    );
    return '$week · $_temp0';
  }

  @override
  String get clubsOpenDiscussion => 'Otwórz dyskusję';

  @override
  String get clubsJoinToSeeTitle => 'Dołącz, aby zobaczyć dyskusję';

  @override
  String get clubsJoinToSeeMessage =>
      'Członkowie wspólnie rozmawiają o każdym wyborze. Dołącz do klubu, aby czytać i dzielić się przemyśleniami.';

  @override
  String clubsYouRole(String role) {
    return 'Ty: $role';
  }

  @override
  String get clubsRemovedByModeration =>
      'Ten klub został usunięty przez moderację.';

  @override
  String get clubsJoinClub => 'Dołącz do klubu';

  @override
  String get clubsNoPickModerator =>
      'Jeszcze nic nie wybrano. Wybierz coś świetnego dla wszystkich.';

  @override
  String get clubsNoPickMember => 'Jeszcze nic nie wybrano. Zajrzyj wkrótce.';

  @override
  String clubsQuotedNote(String note) {
    return '„$note”';
  }

  @override
  String clubsPostsInDiscussion(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wpisu w dyskusji',
      many: '$count wpisów w dyskusji',
      few: '$count wpisy w dyskusji',
      one: '1 wpis w dyskusji',
    );
    return '$_temp0';
  }

  @override
  String get clubsSetThisWeeksPick => 'Ustal wybór tego tygodnia';

  @override
  String get clubsDiscussThisPick => 'Omów ten wybór';

  @override
  String get clubsPostNotSent => 'Nie udało się wysłać wpisu.';

  @override
  String clubsDiscussionHeading(String title) {
    return 'Dyskusja · $title';
  }

  @override
  String get clubsDiscussionLoadError => 'Nie udało się wczytać dyskusji';

  @override
  String get clubsStartConversationTitle => 'Rozpocznij rozmowę';

  @override
  String get clubsStartConversationMessage =>
      'Co myślisz na razie? Twój wpis może rozkręcić rozmowę.';

  @override
  String get clubsLoadMorePosts => 'Wczytaj więcej wpisów';

  @override
  String get clubsComposerLabel => 'Dodaj coś do dyskusji';

  @override
  String get clubsComposerHint => 'Ulubiony moment? Największe zaskoczenie?';

  @override
  String get clubsContainsSpoilers => 'Zawiera spoilery';

  @override
  String get clubsSpoilersSubtitle => 'Inni dotkną, aby go odsłonić.';

  @override
  String get clubsPosting => 'Publikowanie…';

  @override
  String get clubsPost => 'Opublikuj';

  @override
  String get clubsDeletePostTitle => 'Usunąć twój wpis?';

  @override
  String get clubsDeletePostMessage =>
      'Zostanie usunięty z dyskusji dla wszystkich.';

  @override
  String get clubsActionFailed => 'Nie udało się wykonać tej czynności.';

  @override
  String get clubsHideFromMembers => 'Ukryj przed członkami';

  @override
  String get clubsShowToMembers => 'Pokaż członkom';

  @override
  String get clubsReport => 'Zgłoś';

  @override
  String get clubsYou => 'Ty';

  @override
  String get clubsHidden => 'Ukryty';

  @override
  String get clubsPostActions => 'Akcje wpisu';

  @override
  String get clubsMakeModerator => 'Ustaw jako moderatora';

  @override
  String get clubsMakeMember => 'Ustaw jako członka';

  @override
  String get clubsRemoveFromClub => 'Usuń z klubu';

  @override
  String clubsRemoveMemberTitle(String name) {
    return 'Usunąć użytkownika $name?';
  }

  @override
  String get clubsRemoveMemberMessage =>
      'Ta osoba opuści klub i nie będzie mogła wrócić. Jej wcześniejsze wpisy zostaną w dyskusji.';

  @override
  String get clubsRemove => 'Usuń';

  @override
  String get clubsMembersLoadError => 'Nie udało się wczytać członków.';

  @override
  String clubsMemberYou(String name) {
    return '$name (ty)';
  }

  @override
  String clubsMemberActions(String name) {
    return 'Akcje: $name';
  }

  @override
  String get clubsChooseFilm => 'Wybierz film';

  @override
  String get clubsChooseBook => 'Wybierz książkę';

  @override
  String get clubsChooseTitle => 'Wybierz tytuł';

  @override
  String get clubsChooseTitleFirst => 'Najpierw wybierz tytuł.';

  @override
  String get clubsPickNotSaved => 'Nie udało się zapisać wyboru.';

  @override
  String get clubsSetWeeklyPick => 'Ustal wybór tygodnia';

  @override
  String get clubsChange => 'Zmień';

  @override
  String get clubsPickNoteLabel => 'Notatka dla klubu (opcjonalnie)';

  @override
  String get clubsPickNoteHint => 'Dlaczego to? Od czego zacząć?';

  @override
  String get clubsSaving => 'Zapisywanie…';

  @override
  String get clubsSavePick => 'Zapisz wybór';

  @override
  String get clubsListNameRequired => 'Nadaj liście nazwę.';

  @override
  String get clubsListNotSaved => 'Nie udało się zapisać listy.';

  @override
  String get clubsEditList => 'Edytuj listę';

  @override
  String get clubsNewList => 'Nowa lista';

  @override
  String get clubsListNameLabel => 'Nazwa listy';

  @override
  String get clubsListNameHint => 'Książki, które zmieniły moje zdanie';

  @override
  String get clubsWhoCanSee => 'Kto może to zobaczyć';

  @override
  String get clubsSave => 'Zapisz';

  @override
  String get clubsCreateList => 'Utwórz listę';

  @override
  String get clubsYourNote => 'Twoja notatka';

  @override
  String get clubsNoteLabel => 'Dlaczego jest na tej liście';

  @override
  String get clubsSaveNote => 'Zapisz notatkę';

  @override
  String get clubsCreateNewListTooltip => 'Utwórz nową listę';

  @override
  String get clubsSignInToSeeLists => 'Zaloguj się, aby zobaczyć swoje listy.';

  @override
  String get clubsShelfTitle => 'Twoja półka';

  @override
  String get clubsShelfSubtitle =>
      'Zapisuj, co cię zachwyciło i co czeka w kolejce. Udostępnij listę albo zachowaj ją dla siebie.';

  @override
  String get clubsListsLoadErrorTitle => 'Nie udało się wczytać twoich list';

  @override
  String get clubsFirstListTitle => 'Utwórz swoją pierwszą listę';

  @override
  String get clubsFirstListMessage =>
      'Ulubione filmy, książki do przeczytania, filmy do ponownego obejrzenia: ty decydujesz.';

  @override
  String clubsAddToNamed(String name) {
    return 'Dodaj do listy $name';
  }

  @override
  String get clubsAddToThisListFailed => 'Nie udało się dodać do tej listy.';

  @override
  String clubsDeleteListTitle(String name) {
    return 'Usunąć listę $name?';
  }

  @override
  String get clubsDeleteListMessage =>
      'Lista i jej notatki zostaną usunięte. Tego nie można cofnąć.';

  @override
  String get clubsDeleteList => 'Usuń listę';

  @override
  String get clubsListDeleteFailed =>
      'Nie udało się usunąć listy. Odśwież i spróbuj ponownie.';

  @override
  String get clubsNoteNotSaved => 'Nie udało się zapisać notatki.';

  @override
  String get clubsRemoveFailed => 'Nie udało się usunąć.';

  @override
  String get clubsListOptions => 'Opcje listy';

  @override
  String get clubsAddATitle => 'Dodaj tytuł';

  @override
  String clubsTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tytułu',
      many: '$count tytułów',
      few: '$count tytuły',
      one: '1 tytuł',
    );
    return '$_temp0';
  }

  @override
  String get clubsListEmpty =>
      'Nic tu jeszcze nie ma. Użyj opcji „Dodaj tytuł” w menu listy.';

  @override
  String clubsItemOptions(String title) {
    return 'Opcje: $title';
  }

  @override
  String get clubsAddNote => 'Dodaj notatkę';

  @override
  String get clubsEditNote => 'Edytuj notatkę';

  @override
  String get clubsRemoveFromList => 'Usuń z listy';

  @override
  String get clubsTapStarError => 'Dotknij gwiazdki, aby ocenić.';

  @override
  String get clubsReviewNotSaved => 'Nie udało się zapisać recenzji.';

  @override
  String get clubsWriteReview => 'Napisz recenzję';

  @override
  String get clubsEditYourReview => 'Edytuj swoją recenzję';

  @override
  String get clubsTapStarToRate => 'Dotknij gwiazdki, aby ocenić';

  @override
  String clubsRatingOutOfFive(int rating) {
    return '$rating na 5';
  }

  @override
  String get clubsReviewBodyLabel => 'Co o tym myślisz? (opcjonalnie)';

  @override
  String get clubsSaveReview => 'Zapisz recenzję';

  @override
  String clubsAddedToList(String name) {
    return 'Dodano do listy $name.';
  }

  @override
  String get clubsAddToThatListFailed => 'Nie udało się dodać do tej listy.';

  @override
  String get clubsAddToAList => 'Dodaj do listy';

  @override
  String get clubsListsLoadError => 'Nie udało się wczytać twoich list.';

  @override
  String get clubsNoFilmLists =>
      'Nie masz jeszcze list filmów. Utwórz jedną, aby zacząć kolekcję.';

  @override
  String get clubsNoBookLists =>
      'Nie masz jeszcze list książek. Utwórz jedną, aby zacząć kolekcję.';

  @override
  String get clubsTitleFallback => 'Tytuł';

  @override
  String get clubsSignInToSeeReviews => 'Zaloguj się, aby zobaczyć recenzje.';

  @override
  String get clubsTitleLoadError => 'Nie udało się wczytać tytułu';

  @override
  String get clubsReviews => 'Recenzje';

  @override
  String get clubsNoOtherReviewsTitle => 'Brak innych recenzji';

  @override
  String get clubsNoOtherReviewsMessage =>
      'Gdy widoczni dla ciebie członkowie udostępnią recenzję, pojawi się tutaj.';

  @override
  String get clubsDeleteReviewTitle => 'Usunąć twoją recenzję?';

  @override
  String get clubsDeleteReviewMessage =>
      'Twoja ocena i tekst zostaną usunięte dla wszystkich.';

  @override
  String get clubsDeleteReview => 'Usuń recenzję';

  @override
  String get clubsReviewDeleteFailed =>
      'Nie udało się usunąć recenzji. Odśwież i spróbuj ponownie.';

  @override
  String get clubsWhatDidYouThink => 'Jak ci się podobało?';

  @override
  String get clubsReviewPrompt =>
      'Oceń i napisz dlaczego. Ty decydujesz, kto to zobaczy.';

  @override
  String get clubsYourReview => 'Twoja recenzja';

  @override
  String get clubsSpoilers => 'Spoilery';

  @override
  String get clubsEdit => 'Edytuj';

  @override
  String get clubsReportReview => 'Zgłoś tę recenzję';

  @override
  String get clubsEnterTitle => 'Wpisz tytuł.';

  @override
  String get clubsYearRange => 'Wpisz rok od 1450 do 2100.';

  @override
  String get clubsTitleAddFailed => 'Nie udało się dodać tytułu.';

  @override
  String get clubsSearchFilms => 'Szukaj filmów';

  @override
  String get clubsSearchBooks => 'Szukaj książek';

  @override
  String get clubsTypeTwoLetters => 'Wpisz co najmniej 2 litery';

  @override
  String get clubsSearchUnavailable => 'Wyszukiwanie jest niedostępne.';

  @override
  String get clubsNoFilmsMatch => 'Brak pasujących filmów. Dodaj go poniżej.';

  @override
  String get clubsNoBooksMatch => 'Brak pasujących książek. Dodaj ją poniżej.';

  @override
  String get clubsAddNewFilm => 'Dodaj nowy film';

  @override
  String get clubsAddNewBook => 'Dodaj nową książkę';

  @override
  String get clubsTitleFieldLabel => 'Tytuł';

  @override
  String get clubsDirector => 'Reżyseria';

  @override
  String get clubsAuthor => 'Autor';

  @override
  String get clubsYearOptional => 'Rok (opcjonalnie)';

  @override
  String get clubsAdding => 'Dodawanie…';

  @override
  String get clubsAddAndChoose => 'Dodaj i wybierz';

  @override
  String get friendsIntroducerSaveFailed =>
      'Nie udało się tego zapisać. Odśwież, aby sprawdzić aktualne zgody, zanim spróbujesz ponownie.';

  @override
  String friendsIntroducerRevokeTitle(String name) {
    return 'Cofnąć zgodę dla $name?';
  }

  @override
  String get friendsIntroducerRevokeBody =>
      'Nowe i nieodpowiedziane zapoznania zostaną wstrzymane. Istniejące wzajemne dopasowanie pozostaje między tymi dwiema osobami.';

  @override
  String get friendsIntroducerKeepPermission => 'Zachowaj zgodę';

  @override
  String get friendsIntroducerRemovePermission => 'Cofnij zgodę';

  @override
  String get friendsIntroducerPermissionRemoved => 'Zgoda cofnięta.';

  @override
  String get friendsIntroducerMemberTitle => 'Twoi swaci';

  @override
  String get friendsIntroducerAppTitle => 'Connect · Znajomi';

  @override
  String get friendsIntroducerRefresh => 'Odśwież zgody';

  @override
  String get friendsIntroducerAccount => 'Konto';

  @override
  String get friendsIntroducerAccountPrivacy => 'Konto i prywatność';

  @override
  String get friendsIntroducerSignOut => 'Wyloguj się';

  @override
  String get friendsIntroducerMemberHeadline =>
      'Dobrzy znajomi. Ty decydujesz.';

  @override
  String get friendsIntroducerHeadline =>
      'Znasz ich.\nWidzisz, co może z tego wyjść.';

  @override
  String get friendsIntroducerMemberIntro =>
      'Zaproś zaufaną osobę, żeby mogła cię z kimś zapoznać. Może dołączyć bez profilu randkowego. Ty decydujesz, kto dostaje zgodę i co pokazuje podgląd.';

  @override
  String get friendsIntroducerIntro =>
      'Odrobina troski może zapoczątkować coś prawdziwego. Połącz znajomych, którzy poprosili cię o pomoc.';

  @override
  String get friendsIntroducerMemberListTitle => 'Osoby, które wybierasz';

  @override
  String get friendsIntroducerListTitle => 'Twój mały krąg';

  @override
  String get friendsIntroducerLoadFailed =>
      'Nie udało się wczytać zgód. Nic nie zostało zmienione.';

  @override
  String get friendsIntroducerMemberEmpty =>
      'Nie masz jeszcze swatów. Wyślij zaproszenie jednej zaufanej osobie, aby zacząć.';

  @override
  String get friendsIntroducerEmpty =>
      'Twój krąg zaczyna się od zgody. Poproś znajomego z Connect o kod zaproszenia.';

  @override
  String get friendsIntroducerStatusPendingMember =>
      'Prosi o zgodę na zapoznawanie cię z innymi.';

  @override
  String get friendsIntroducerStatusPending =>
      'Czeka na zgodę twojego znajomego.';

  @override
  String get friendsIntroducerStatusPaused => 'Zapoznania są wstrzymane.';

  @override
  String get friendsIntroducerStatusActive =>
      'Ma zgodę na proponowanie zapoznań.';

  @override
  String friendsIntroducerPreview(String extras) {
    String _temp0 = intl.Intl.selectLogic(extras, {
      'photo':
          'Podgląd dla proponowanej randki: imię i opcjonalnie wiek, zdjęcie.',
      'city':
          'Podgląd dla proponowanej randki: imię i opcjonalnie wiek, miasto.',
      'both':
          'Podgląd dla proponowanej randki: imię i opcjonalnie wiek, zdjęcie, miasto.',
      'other': 'Podgląd dla proponowanej randki: imię i opcjonalnie wiek.',
    });
    return '$_temp0';
  }

  @override
  String get friendsIntroducerApproveNote =>
      'Zatwierdzenie włącza też zapoznania przez znajomych. Wszystkie zapoznania możesz wstrzymać w sekcji Rytm randek.';

  @override
  String get friendsIntroducerAllow => 'Zezwól na zapoznania';

  @override
  String friendsIntroducerAllowed(String name) {
    return '$name ma teraz twoją zgodę.';
  }

  @override
  String get friendsIntroducerDecline => 'Odrzuć prośbę';

  @override
  String get friendsIntroducerSentTitle => 'Wysłane z troską';

  @override
  String get friendsIntroducerSentBody =>
      'Ich odpowiedzi zostają między nimi. Oboje muszą się zgodzić, zanim powstanie dopasowanie.';

  @override
  String get friendsIntroducerReloadSent =>
      'Wczytaj ponownie wysłane zapoznania';

  @override
  String get friendsIntroducerSentSubtitle =>
      'Wysłane · ich decyzja jest prywatna';

  @override
  String get friendsIntroducerStepPreview => '1. Wybierz podgląd';

  @override
  String get friendsIntroducerPreviewBody =>
      'Proponowana osoba zobaczy twoje imię i wiek, jeśli już go pokazujesz. Twój swat widzi tylko twoje imię, nigdy profil ani aktywność randkową.';

  @override
  String get friendsIntroducerIncludePhoto => 'Dołącz moje zdjęcie profilowe';

  @override
  String get friendsIntroducerIncludeCity => 'Dołącz moje miasto';

  @override
  String get friendsIntroducerStepInvite => '2. Zaproś jedną zaufaną osobę';

  @override
  String get friendsIntroducerInviteBody =>
      'Kod działa raz i wygasa po 48 godzinach. Twój znajomy dołącza przez „Tylko zapoznaję znajomych” na ekranie powitalnym. Zanim cokolwiek zostanie udostępnione, zatwierdzisz tu jego imię.';

  @override
  String get friendsIntroducerInviteReady =>
      'Zaproszenie gotowe. Wcześniejsze niewykorzystane kody już nie działają.';

  @override
  String get friendsIntroducerCreateCode => 'Utwórz kod zaproszenia';

  @override
  String get friendsIntroducerShareCode =>
      'Przekaż go znajomemu prywatnie. Aby zmienić podgląd, anuluj niewykorzystane zaproszenie i utwórz nowy kod.';

  @override
  String get friendsIntroducerCodeCopied => 'Skopiowano kod zaproszenia';

  @override
  String get friendsIntroducerCopyCode => 'Kopiuj kod';

  @override
  String get friendsIntroducerInvitesCancelled =>
      'Anulowano niewykorzystane zaproszenia.';

  @override
  String get friendsIntroducerCancelInvites =>
      'Anuluj niewykorzystane zaproszenia';

  @override
  String get friendsIntroducerManagePrefs =>
      'Zarządzaj wszystkimi ustawieniami zapoznań';

  @override
  String get friendsIntroducerRedeemTitle => 'Znajomy cię zaprosił?';

  @override
  String get friendsIntroducerRedeemBody =>
      'Wklej prywatny kod zaproszenia. Znajomy potwierdzi twoje imię, zanim będziesz mógł go z kimś zapoznać.';

  @override
  String get friendsIntroducerCodeLabel => 'Kod zaproszenia';

  @override
  String get friendsIntroducerCodeMissing =>
      'Wpisz kod zaproszenia od znajomego.';

  @override
  String get friendsIntroducerRequestSent =>
      'Prośba wysłana. Znajomy może cię teraz zatwierdzić w sekcji „Twoi swaci”.';

  @override
  String get friendsIntroducerAskPermission => 'Poproś o zgodę';

  @override
  String get friendsIntroducerNeedTwo =>
      'Gdy dwoje znajomych wyrazi zgodę, możesz tu zaproponować zapoznanie.';

  @override
  String get friendsIntroducerComposerTitle => 'Widzisz szansę?';

  @override
  String get friendsIntroducerWhyLabel =>
      'Dlaczego o nich pomyślałeś(-aś) (opcjonalnie)';

  @override
  String get friendsIntroducerWhyHelper =>
      'Zobaczą to oboje. Pomiń prywatne szczegóły.';

  @override
  String get friendsIntroducerIntroSent =>
      'Zapoznanie wysłane. Każde z nich może zdecydować prywatnie.';

  @override
  String get friendsIntroducerSuggest => 'Zaproponuj zapoznanie';

  @override
  String get friendsIntroducerPrivacyNote =>
      'Najpierw zgoda. Żadnej publicznej aktywności randkowej. Żadnych informacji o tym, kto powiedział tak, a kto nie.';

  @override
  String get planSharingLoadFailed =>
      'Nie udało się wczytać opcji udostępniania.';

  @override
  String get planSharingOffSnack => 'Udostępnianie kontaktom jest wyłączone.';

  @override
  String get planSharingSavedSnack => 'Wybrane kontakty widzą teraz ten plan.';

  @override
  String get planSharingSaveFailed =>
      'Nie udało się zapisać. Wczytaj wybór ponownie, zanim spróbujesz jeszcze raz.';

  @override
  String get planSharingTitle => 'Twój plan. Twoi ludzie.';

  @override
  String get planSharingCloseTooltip => 'Zamknij udostępnianie';

  @override
  String get planSharingIntro =>
      'Udostępnianie kontaktom jest domyślnie wyłączone. Wybierz do 10 zaufanych znajomych dla tego planu. Druga osoba wybiera własne kontakty.';

  @override
  String get planSharingNoContacts =>
      'Nie masz jeszcze znajomych, których można wybrać. Plan nadal jest dostępny dla ciebie i drugiej osoby.';

  @override
  String get planSharingFriendFallback => 'Znajomy';

  @override
  String get planSharingPreviewNone => 'Podgląd · nie wybrano kontaktów';

  @override
  String planSharingPreviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Podgląd · wybrano $count kontaktu',
      many: 'Podgląd · wybrano $count kontaktów',
      few: 'Podgląd · wybrano $count kontakty',
      one: 'Podgląd · wybrano $count kontakt',
    );
    return '$_temp0';
  }

  @override
  String get planSharingPreviewOffBody =>
      'Znajomi nie dostaną od ciebie żadnych informacji o planie ani o meldunkach.';

  @override
  String get planSharingPreviewOnBody =>
      'Te kontakty zobaczą imię drugiej osoby, czas i miejsce, status planu oraz twoje meldunki. Aktualny plan dostaną po zapisaniu.';

  @override
  String get planSharingPrivacyNote =>
      'Wiadomości i prywatna opinia po randce pozostają prywatne. Usunięcie kontaktu wstrzymuje kolejne informacje i odbiera mu dostęp do planu w aplikacji. Informacji, które już dotarły na urządzenie, nie da się wycofać.';

  @override
  String get planSharingReload => 'Wczytaj opcje udostępniania ponownie';

  @override
  String get planSharingSaving => 'Zapisywanie…';

  @override
  String get planSharingKeepOff => 'Pozostaw udostępnianie wyłączone';

  @override
  String get planSharingShareSelected => 'Udostępnij wybranym kontaktom';

  @override
  String get planSharingDeselectAll => 'Odznacz wszystkich';

  @override
  String planBudgetLine(String budget) {
    return 'Budżet · $budget';
  }

  @override
  String planAtmosphereLine(String atmospheres) {
    return 'Atmosfera · $atmospheres';
  }

  @override
  String get planAtmosphereQuiet => 'Spokojna rozmowa';

  @override
  String get planAtmosphereRelaxed => 'Na luzie i bez pośpiechu';

  @override
  String get planAtmosphereLively => 'Gwarne miejsce';

  @override
  String get planAtmosphereOutdoors => 'Na zewnątrz';

  @override
  String get planAtmosphereIndoors => 'W środku';

  @override
  String get planAccessStepFree => 'Wejście bez schodów';

  @override
  String get planAccessToilet =>
      'Toaleta dostępna dla osób z niepełnosprawnościami';

  @override
  String get planAccessSeating => 'Dostępne miejsca siedzące';

  @override
  String get planAccessLowNoise => 'Mało hałasu w tle';

  @override
  String get planAccessTransit => 'Blisko komunikacji miejskiej';

  @override
  String get planAccessCaptions => 'Napisy podczas randki wideo';

  @override
  String get planComfortHeading => 'Żeby było wygodnie';

  @override
  String get planPreferencesDisclaimer =>
      'Preferencje udostępnione dla tego planu. Potwierdź szczegóły z miejscem lub usługą wideo.';

  @override
  String get planProposeErrorKept =>
      'Nie udało się wysłać planu. Twoje wybory zostały zachowane.';

  @override
  String get planChangedError =>
      'Ten plan się zmienił. Zamknij to okno, aby wrócić do rozmowy.';

  @override
  String get planProposeHeadline => 'Plan, na który oboje czekacie.';

  @override
  String get planCounterHeadline => 'Dopracujcie ten plan razem';

  @override
  String planProposeLead(String name) {
    return 'Propozycja dla ciebie i $name. Nic nie jest ustalone, dopóki druga osoba nie zaakceptuje tej wersji.';
  }

  @override
  String get planFindTimeTitle => 'Znajdźcie chwilę dla siebie';

  @override
  String get planFindTimeBody =>
      'Wspólne terminy widać tylko wtedy, gdy oboje udostępniacie swoją dostępność. Zawsze możesz zaproponować własny termin.';

  @override
  String get planSharedTimesFailed =>
      'Nie udało się wczytać wspólnych terminów. Nadal możesz wybrać termin ręcznie.';

  @override
  String get planSharedTimesEmpty =>
      'Na razie brak propozycji wspólnych terminów. To nie znaczy, że któreś z was jest niedostępne.';

  @override
  String get planRefreshSharedTimes => 'Odśwież wspólne terminy';

  @override
  String get planSetAvailability => 'Ustaw moją dostępność';

  @override
  String get planWhenTitle => 'Kiedy będzie ci pasować?';

  @override
  String get planTimeSourceManual => 'Termin, który proponujesz';

  @override
  String get planTimeSourceShared =>
      'Wybrano ze wspólnej dostępności · sprawdzimy ponownie przy wysyłaniu';

  @override
  String planLocalTimeNote(int minutes, String timeZone) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Czas lokalny urządzenia ($timeZone). Czas trwania: $minutes minuty.',
      many:
          'Czas lokalny urządzenia ($timeZone). Czas trwania: $minutes minut.',
      few:
          'Czas lokalny urządzenia ($timeZone). Czas trwania: $minutes minuty.',
      one:
          'Czas lokalny urządzenia ($timeZone). Czas trwania: $minutes minuta.',
    );
    return '$_temp0';
  }

  @override
  String planDurationChip(int minutes) {
    return '$minutes min';
  }

  @override
  String get planEnjoyTitle => 'Coś, co sprawi ci przyjemność';

  @override
  String get planAreaHint => 'Dzielnica lub publiczne miejsce spotkań';

  @override
  String get planBudgetTitle => 'Jaki budżet będzie dla ciebie wygodny?';

  @override
  String get planBudgetBody =>
      'Punkt wyjścia do wspólnych ustaleń, a nie wycena ani obietnica, kto płaci.';

  @override
  String get planAtmosphereTitle => 'Wybierz atmosferę';

  @override
  String get planAtmosphereBody =>
      'Wybierz maksymalnie trzy klimaty, które ci odpowiadają. Opcjonalnie.';

  @override
  String get planComfortTitle => 'Niech będzie wygodnie dla was obojga';

  @override
  String get planComfortBody =>
      'Opcjonalne preferencje dotyczące dostępności. Wybrane opcje zobaczy twoje dopasowanie po wysłaniu planu. Nie trafiają do publicznego profilu ani do informacji dla zaufanych kontaktów.';

  @override
  String get planComfortDisclaimer =>
      'Nie musisz tłumaczyć żadnej diagnozy. To prośby do sprawdzenia z miejscem lub usługą wideo, a nie zweryfikowane udogodnienia.';

  @override
  String get planNoteHint =>
      'Sobotnie popołudnie, gdzieś, gdzie jest spokojniej?';

  @override
  String get planReviewBeforeSending =>
      'Przed wysłaniem sprawdź termin i wybory powyżej. Druga osoba może zaakceptować, odrzucić lub zaproponować zmianę.';

  @override
  String get planReloadLatest => 'Wczytaj najnowszy plan · odrzuć zmiany';

  @override
  String get planSending => 'Wysyłanie…';

  @override
  String get planSendSuggestion => 'Wyślij swoją propozycję';

  @override
  String get planSecondYesTitle => 'Podziel się drugim „tak”';

  @override
  String get planSecondYesBody =>
      'Pokaż, że chcesz spotkać się ponownie – tylko jeśli twoje dopasowanie też powie „tak” i zgodzi się to udostępnić. Pozostałe odpowiedzi zostają prywatne.';

  @override
  String get planSecondYesHeadline => 'Drugie „tak” od was obojga';

  @override
  String get planSecondYesCardBody =>
      'Oboje daliście znać, że chcecie spotkać się ponownie.';

  @override
  String get planAnotherHello => 'Zaplanuj kolejne spotkanie';

  @override
  String get planSuggestChange => 'Zaproponuj zmianę';

  @override
  String get planChooseUpdates => 'Wybierz, kto dostaje twoje informacje';

  @override
  String planQuotedNote(String note) {
    return '„$note”';
  }

  @override
  String get planStatusDeclined => 'Odrzucony';

  @override
  String get planStatusExpired => 'Wygasł';

  @override
  String get planStatusCompleted => 'Zakończony';

  @override
  String get planStatusDidNotHappen => 'Nie odbył się';

  @override
  String get planStatusDisputed => 'Sporny';

  @override
  String get plansManageSharing => 'Zarządzaj udostępnianiem kontaktom';

  @override
  String get plansLoadFailed => 'Nie udało się wczytać planów randek.';

  @override
  String get plansFeedLoadFailed => 'Nie udało się wczytać planów.';

  @override
  String get planAcceptFailed => 'Nie udało się zaakceptować tego planu.';

  @override
  String get planDeclineFailed => 'Nie udało się odrzucić tego planu.';

  @override
  String get planCancelFailed => 'Nie udało się odwołać tego planu.';

  @override
  String get planCheckinFailed => 'Nie można się teraz zameldować.';

  @override
  String get graduationFoundEachOther => 'Odnaleźliście się';

  @override
  String graduationHeadlineDecide(String name) {
    return '$name chce razem z tobą opuścić Connect';
  }

  @override
  String graduationHeadlineWaiting(String name) {
    return 'Czekamy, aż $name odpowie';
  }

  @override
  String get graduationBodyConfirmed =>
      'Oboje jesteście ukryci w odkrywaniu. Ten czat pozostaje otwarty.';

  @override
  String get graduationBodyDecide =>
      'Potwierdź, a oboje znikniecie z odkrywania. Wasz czat zostaje.';

  @override
  String get graduationBodyWaiting =>
      'Wysłano prośbę o wspólne odejście. Druga osoba może potwierdzić lub odrzucić.';

  @override
  String get graduationCelebrate => 'Świętuj';

  @override
  String get graduationNotYet => 'Jeszcze nie';

  @override
  String get graduationConfirm => 'Potwierdź';

  @override
  String get graduationFriendsToldOnConfirm =>
      'Znajomi dowiedzą się, gdy druga osoba potwierdzi.';

  @override
  String get graduationOnlyTwoOfYouForNow =>
      'Na razie wiecie o tym tylko wy dwoje.';

  @override
  String get graduationWithdraw => 'Wycofaj';

  @override
  String graduationProposeTitle(String name) {
    return 'Ty i $name opuszczacie Connect?';
  }

  @override
  String graduationProposeBody(String name) {
    return 'Gdy $name potwierdzi, oboje będziecie ukryci w odkrywaniu. Ten czat pozostanie otwarty, a do odkrywania możesz wrócić w każdej chwili w sekcji Prywatność i bezpieczeństwo.';
  }

  @override
  String get graduationNoteLabel => 'Wiadomość dla drugiej osoby (opcjonalnie)';

  @override
  String get graduationNoteHint => 'Napisz, dlaczego to dobry moment';

  @override
  String get graduationTellFriends => 'Powiedz moim znajomym';

  @override
  String get graduationTellFriendsBody =>
      'Znajomi dowiedzą się, że ktoś pojawił się w twoim życiu, ale nie kto.';

  @override
  String get graduationAskThem => 'Zapytaj';

  @override
  String get graduationTitle => 'Wspólne odejście';

  @override
  String graduationCelebrationBody(String name) {
    return 'Ty i $name razem opuszczacie Connect. Oboje jesteście ukryci w odkrywaniu, a ten czat pozostanie otwarty, jak długo chcecie.';
  }

  @override
  String get graduationFriendsHaveBeenTold => 'Znajomi już wiedzą.';

  @override
  String get graduationFriendsAreTold => 'Znajomi zostaną powiadomieni.';

  @override
  String get graduationOnlyTwoOfYou => 'Wiecie o tym tylko wy dwoje.';

  @override
  String get graduationConfirmAndBack => 'Potwierdź i wróć';

  @override
  String get graduationBackToConnect => 'Wróć do Connect';

  @override
  String get graduationLoadFailed =>
      'Nie udało się wczytać wspólnego odejścia.';

  @override
  String get graduationProposeFailed =>
      'Nie udało się zaproponować wspólnego odejścia.';

  @override
  String get graduationConfirmFailed => 'Nie można teraz potwierdzić.';

  @override
  String get graduationDeclineFailed => 'Nie można teraz odrzucić.';

  @override
  String get graduationWithdrawFailed => 'Nie udało się wycofać propozycji.';

  @override
  String get graduationPauseLoadFailed =>
      'Nie udało się wczytać stanu odkrywania.';

  @override
  String get graduationPauseFailed => 'Nie udało się wstrzymać odkrywania.';

  @override
  String get graduationResumeFailed => 'Nie udało się wznowić odkrywania.';

  @override
  String get engagementCirclesEmptyTitle => 'Brak dostępnych kręgów';

  @override
  String get engagementCirclesPullToRefresh =>
      'Przeciągnij w dół, aby odświeżyć.';

  @override
  String get engagementCirclesJoined => 'Dołączono';

  @override
  String get engagementCirclesNotJoined => 'Nie dołączono';

  @override
  String engagementCirclesParticipants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uczestnika w tym tygodniu',
      many: '$count uczestników w tym tygodniu',
      few: '$count uczestnicy w tym tygodniu',
      one: '$count uczestnik w tym tygodniu',
    );
    return '$_temp0';
  }

  @override
  String get engagementCirclesJoin => 'Dołącz do kręgu';

  @override
  String get engagementCirclesResponseLabel => 'Odpowiedź na wyzwanie tygodnia';

  @override
  String get engagementCirclesSubmit => 'Wyślij odpowiedź';

  @override
  String get engagementCirclesTopicFallback => 'Krąg';

  @override
  String get engagementCirclesLoadFailed => 'Nie można teraz wczytać kręgów.';

  @override
  String get engagementCirclesJoinFailed =>
      'Nie można teraz dołączyć do kręgu.';

  @override
  String get engagementCirclesEnterResponse => 'Wpisz odpowiedź na wyzwanie.';

  @override
  String get engagementCirclesSubmitFailed =>
      'Nie można teraz wysłać odpowiedzi.';

  @override
  String get engagementNudgesTitle => 'Zaczepki';

  @override
  String get engagementNudgesIntro =>
      'Wyślij delikatne przypomnienie, aby ożywić ucichłą rozmowę. Dzienne limity i zasady bezpieczeństwa egzekwuje serwer.';

  @override
  String get engagementNudgesEmpty => 'Brak dopasowań do zaczepienia.';

  @override
  String get engagementNudgesSentInSession => 'Zaczepka wysłana w tej sesji';

  @override
  String get engagementNudgesReady => 'Gotowe do wysłania';

  @override
  String engagementNudgesSentTo(String name) {
    return 'Wysłano zaczepkę do: $name.';
  }

  @override
  String get engagementNudgesAction => 'Zaczep';

  @override
  String get engagementNudgesSendFailed => 'Nie udało się wysłać tej zaczepki.';

  @override
  String get engagementTrustBadgesEarned => 'Zdobyte odznaki';

  @override
  String get engagementTrustBadgesEmpty =>
      'Nie masz jeszcze odznak. Wykonuj aktywności, aby odblokować odznaki zaufania.';

  @override
  String engagementTrustBadgesDetails(
    String code,
    String status,
    String awardedAt,
  ) {
    return 'Kod: $code\nStatus: $status • Przyznano $awardedAt';
  }

  @override
  String get engagementTrustBadgesHistory => 'Ostatnia historia';

  @override
  String get engagementTrustBadgesHistoryEmpty =>
      'Nie ma jeszcze historii zaufania.';

  @override
  String get engagementTrustBadgesMilestoneUnavailable =>
      'Status kamienia milowego jest niedostępny.';

  @override
  String get engagementTrustBadgesCurrentMilestone => 'Obecny kamień milowy';

  @override
  String get engagementTrustBadgesLoadFailed =>
      'Nie udało się wczytać odznak zaufania. Spróbuj ponownie.';

  @override
  String get engagementTrustFiltersEnable => 'Włącz filtry zaufania';

  @override
  String get engagementTrustFiltersEnableSubtitle =>
      'Ukrywaj profile, które nie spełniają twoich wymagań zaufania';

  @override
  String engagementTrustFiltersMinimum(int count) {
    return 'Minimalna liczba aktywnych odznak: $count';
  }

  @override
  String get engagementTrustFiltersRequired => 'Wymagane odznaki';

  @override
  String get engagementTrustFiltersSaved => 'Zapisano filtry zaufania.';

  @override
  String get engagementTrustFiltersSave => 'Zapisz filtry zaufania';

  @override
  String get engagementAppealStatusSubmitted => 'Wysłano';

  @override
  String get engagementAppealStatusUnderReview => 'W trakcie rozpatrywania';

  @override
  String get engagementAppealStatusResolvedUpheld => 'Rozpatrzono (utrzymano)';

  @override
  String get engagementAppealStatusResolvedReversed => 'Rozpatrzono (uchylono)';

  @override
  String get engagementRoomsLeaveFailed =>
      'Nie udało się opuścić pokoju. Spróbuj ponownie.';

  @override
  String get engagementRoomsPresenceFailed => 'Utracono połączenie z pokojem.';

  @override
  String get engagementRoomsMembersFailed =>
      'Nie udało się wczytać, kto tu jest. Spróbuj ponownie.';

  @override
  String get engagementRoomsModerationFailed =>
      'Nie udało się. Spróbuj ponownie.';

  @override
  String get engagementRoomsCreateFailed =>
      'Nie udało się uruchomić pokoju. Spróbuj ponownie.';

  @override
  String get engagementRoomsLoadFailed =>
      'Pokoje są teraz niedostępne. Przeciągnij, aby spróbować ponownie.';

  @override
  String get commonSave => 'Zapisz';

  @override
  String get commonRemove => 'Usuń';

  @override
  String get accountTitle => 'Konto i dane';

  @override
  String get accountLoadFailed => 'Nie udało się wczytać stanu konta.';

  @override
  String accountDeletionIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Usunięcie za $days dni',
      one: 'Usunięcie za 1 dzień',
    );
    return '$_temp0';
  }

  @override
  String get accountDeletionDue => 'Usunięcie nastąpi wkrótce';

  @override
  String get accountDeletionCountdownBody =>
      'Twój profil jest ukryty. Do tego czasu możesz się zalogować i anulować — potem danych nie da się odzyskać.';

  @override
  String get accountKeepMyAccount => 'Zachowaj moje konto';

  @override
  String get accountNotDeletedSnack => 'Twoje konto nie zostanie usunięte.';

  @override
  String get accountCancelFailed => 'Nie udało się anulować. Spróbuj ponownie.';

  @override
  String get accountHiddenTitle => 'Twój profil jest ukryty';

  @override
  String get accountTakeBreakTitle => 'Zrób sobie przerwę';

  @override
  String get accountHiddenBody =>
      'Nikt cię nie widzi ani nie może się z tobą dopasować. Twoje dopasowania i wiadomości zostają, a wrócić możesz w każdej chwili.';

  @override
  String get accountTakeBreakBody =>
      'Ukryj profil w Odkrywaniu, niczego nie tracąc. Pozostajesz zalogowany i możesz wrócić w każdej chwili.';

  @override
  String get accountUnhideProfile => 'Pokaż mój profil';

  @override
  String get accountHideProfile => 'Ukryj mój profil';

  @override
  String get accountVisibleAgainSnack => 'Twój profil jest znowu widoczny.';

  @override
  String get accountNowHiddenSnack => 'Twój profil jest teraz ukryty.';

  @override
  String get accountUpdateFailed =>
      'Nie udało się zaktualizować. Spróbuj ponownie.';

  @override
  String get accountDownloadTitle => 'Pobierz swoje dane';

  @override
  String get accountDownloadBody =>
      'Otrzymaj kopię profilu, preferencji, dopasowań i wysłanych przez siebie wiadomości. Wiadomości napisane przez innych nie są dołączone.';

  @override
  String get accountPreparing => 'Przygotowywanie…';

  @override
  String get accountPrepareData => 'Przygotuj moje dane';

  @override
  String get accountPrepareFailed =>
      'Nie udało się przygotować danych. Spróbuj ponownie.';

  @override
  String get accountYourData => 'Twoje dane';

  @override
  String get accountDeleteTitle => 'Usuń moje konto';

  @override
  String get accountDeleteBody =>
      'Twój profil zostanie od razu ukryty, a po okresie karencji wszystko zostanie usunięte. W tym czasie możesz anulować, logując się. Potem nic nie da się odzyskać.';

  @override
  String get accountDeletionAlreadyScheduled => 'Usunięcie już zaplanowane';

  @override
  String get accountDeleteConfirmTitle => 'Usunąć konto?';

  @override
  String get accountDeleteConfirmBody =>
      'Twój profil, zdjęcia, dopasowania i wiadomości zostaną usunięte bez możliwości odzyskania.\n\nJeśli chcesz tylko przerwy, ukrycie profilu zachowuje wszystko i można je cofnąć.';

  @override
  String get accountHideInstead => 'Zamiast tego ukryj';

  @override
  String get accountDeletionScheduledSnack =>
      'Usunięcie zaplanowane. Do tego czasu możesz je anulować.';

  @override
  String get privacyTitle => 'Prywatność i bezpieczeństwo';

  @override
  String get privacyShowAge => 'Pokazuj wiek';

  @override
  String get privacyShowAgeSubtitle => 'Zdecyduj, czy twój wiek jest widoczny';

  @override
  String get privacyShowDistance => 'Pokazuj dokładną odległość';

  @override
  String get privacyShowDistanceSubtitle =>
      'Pokazuj dokładną odległość w profilu';

  @override
  String get privacyShowOnline => 'Pokazuj status online';

  @override
  String get privacyShowOnlineSubtitle =>
      'Pozwól innym widzieć, czy jesteś online';

  @override
  String get privacyEmergencySos => 'SOS alarmowy';

  @override
  String get privacyEmergencySosSubtitle =>
      'Włącz alarm i przejrzyj historię alarmów';

  @override
  String get privacyEmergencyContacts => 'Kontakty alarmowe';

  @override
  String get privacyEmergencyContactsSubtitle =>
      'Zarządzaj zaufanymi kontaktami alarmowymi';

  @override
  String get privacyBlockedUsers => 'Zablokowani użytkownicy';

  @override
  String get privacyBlockedUsersSubtitle =>
      'Przeglądaj i odblokowuj użytkowników';

  @override
  String get privacyModerationAppeals => 'Odwołania od moderacji';

  @override
  String get privacyModerationAppealsSubtitle =>
      'Złóż odwołanie i śledź jego status';

  @override
  String get privacyFriendSearch =>
      'Pozwól znaleźć mnie w wyszukiwaniu znajomych';

  @override
  String get privacySettingLoadFailed =>
      'Nie udało się wczytać tego ustawienia. Otwórz stronę ponownie, aby spróbować jeszcze raz.';

  @override
  String get privacyFriendSearchSubtitle =>
      'Członkowie mogą znaleźć cię po imieniu lub @nazwie w Dodaj znajomego. Osoby, z którymi masz dopasowanie lub które spotykasz w pokojach i grupach, nadal mogą cię dodać.';

  @override
  String get privacyChoiceSaveFailed => 'Nie udało się zapisać twojego wyboru.';

  @override
  String get privacyShowcase => 'Pokazuj moje publiczne teksty w profilu';

  @override
  String get privacyShowcaseSubtitle =>
      'Członkowie widzą w twoim profilu rozdziały udostępnione społeczności i twoje zdjęcia na ścianie. Rozdziały prywatne i tylko dla znajomych nigdy się nie pojawiają.';

  @override
  String get privacyCrashReports => 'Udostępniaj raporty o awariach';

  @override
  String get privacyCrashReportsSubtitle =>
      'Anonimowe raporty o awariach i błędach pomagają nam naprawiać problemy. Nie zawierają wiadomości, zdjęć ani danych konta.';

  @override
  String get privacyGraduatedReason =>
      'Opuściłeś Connect ze swoim dopasowaniem. Twoja karta nie jest nikomu pokazywana.';

  @override
  String get privacyPausedReason =>
      'Twoja karta nie jest nikomu pokazywana, dopóki nie wznowisz.';

  @override
  String get privacyActiveReason =>
      'Jesteś pokazywany innym członkom w Odkrywaniu.';

  @override
  String get privacyDiscoveryPaused => 'Odkrywanie wstrzymane';

  @override
  String get privacyDiscoveryActive => 'Odkrywanie aktywne';

  @override
  String get privacyResume => 'Wznów';

  @override
  String get privacyPause => 'Wstrzymaj';

  @override
  String get emergencyIntro =>
      'Dodaj maksymalnie 3 zaufane kontakty. Będą później używane w procedurach bezpieczeństwa i funkcjach SOS.';

  @override
  String get emergencyEmpty => 'Nie dodano jeszcze kontaktów alarmowych.';

  @override
  String get emergencyMaxReached => 'Dodano maksymalną liczbę kontaktów';

  @override
  String get emergencyAddContact => 'Dodaj kontakt';

  @override
  String get emergencyEditContact => 'Edytuj kontakt';

  @override
  String get emergencyInvalidInput => 'Podaj prawidłowe imię i numer telefonu.';

  @override
  String get emergencyAdded => 'Dodano kontakt alarmowy.';

  @override
  String get emergencyAddFailed =>
      'Nie udało się dodać kontaktu. Spróbuj ponownie.';

  @override
  String get emergencyUpdated => 'Zaktualizowano kontakt alarmowy.';

  @override
  String get emergencyUpdateFailed =>
      'Nie udało się zaktualizować kontaktu. Spróbuj ponownie.';

  @override
  String get emergencyRemoveTitle => 'Usuń kontakt';

  @override
  String emergencyRemoveBody(String name) {
    return 'Usunąć $name z kontaktów alarmowych?';
  }

  @override
  String get emergencyRemoved => 'Usunięto kontakt alarmowy.';

  @override
  String get emergencyRemoveFailed =>
      'Nie udało się usunąć kontaktu. Spróbuj ponownie.';

  @override
  String get emergencyNameLabel => 'Imię';

  @override
  String get emergencyPhoneLabel => 'Numer telefonu';

  @override
  String get appealsSubmitTitle => 'Złóż odwołanie';

  @override
  String get appealsReasonLabel => 'Powód';

  @override
  String get appealsReasonHint =>
      'Dlaczego ta decyzja moderacji powinna zostać ponownie rozpatrzona?';

  @override
  String get appealsReportIdLabel => 'ID zgłoszenia (opcjonalnie)';

  @override
  String get appealsContextLabel => 'Dodatkowy kontekst (opcjonalnie)';

  @override
  String get appealsSubmit => 'Wyślij odwołanie';

  @override
  String get appealsEmpty =>
      'Nie złożono jeszcze odwołań. Twoje odwołania pojawią się tutaj wraz ze statusem.';

  @override
  String appealsIdLine(String id) {
    return 'ID odwołania: $id';
  }

  @override
  String appealsSlaLine(String deadline) {
    return 'Termin rozpatrzenia: $deadline';
  }

  @override
  String appealsReviewedBy(String reviewer) {
    return 'Rozpatrzone przez: $reviewer';
  }

  @override
  String get appealsReasonRequired => 'Podaj powód.';

  @override
  String get appealsSubmitted => 'Odwołanie zostało wysłane.';

  @override
  String get appealsSubmitFailed =>
      'Nie udało się wysłać odwołania. Spróbuj ponownie.';

  @override
  String get blockedEmpty => 'Nikogo nie zablokowałeś.';

  @override
  String get blockedUnblock => 'Odblokuj';

  @override
  String get blockedUnblockTitle => 'Odblokuj użytkownika';

  @override
  String blockedUnblockBody(String name) {
    return 'Odblokować $name?';
  }

  @override
  String blockedUnblockedSnack(String name) {
    return 'Odblokowano: $name.';
  }

  @override
  String get blockedUnblockFailed =>
      'Nie udało się odblokować. Spróbuj ponownie.';

  @override
  String aboutVersion(String version) {
    return 'Wersja $version';
  }

  @override
  String get aboutDescription =>
      'Aplikacja randkowa oparta na zaufaniu: prawdziwe profile, bezpieczna komunikacja i poważne związki.';

  @override
  String get aboutStack => 'Technologie';

  @override
  String get aboutStackFlutter => 'Flutter (najpierw Android)';

  @override
  String get aboutStackGo => 'Usługi w Go + natywny PostgreSQL';

  @override
  String get aboutStackRiverpod => 'Zarządzanie stanem przez Riverpod';

  @override
  String get communitySpoiler => 'Spoiler — dotknij, aby odsłonić';

  @override
  String get communityReportFailed => 'Nie udało się wysłać zgłoszenia.';

  @override
  String get communityReportSubmitted => 'Zgłoszenie wysłane. Dziękujemy.';

  @override
  String communityBlockTitle(String name) {
    return 'Zablokować $name?';
  }

  @override
  String get communityBlockBody =>
      'Przestaniecie widzieć swoje zdjęcia, posty w klubach, recenzje i listy. To blokuje też kontakt przez Connect.';

  @override
  String get communityBlockAction => 'Zablokuj członka';

  @override
  String get communityBlockFailed =>
      'Nie udało się zablokować tego członka. Spróbuj ponownie.';

  @override
  String get reportSheetTitle => 'Zgłoś';

  @override
  String get reportReasonHarassment => 'Nękanie';

  @override
  String get reportReasonInappropriate => 'Nieodpowiednie treści';

  @override
  String get reportReasonFraud => 'Oszustwo';

  @override
  String get reportReasonFake => 'Fałszywy profil';

  @override
  String get reportReasonLabel => 'Powód';

  @override
  String get reportDescriptionLabel => 'Opis (opcjonalnie)';

  @override
  String get reportDescriptionHint =>
      'Dodaj kontekst, aby ułatwić rozpatrzenie zgłoszenia';

  @override
  String get reportSubmitFailed =>
      'Nie udało się wysłać zgłoszenia. Spróbuj ponownie.';

  @override
  String get reportSubmit => 'Wyślij zgłoszenie';

  @override
  String get membershipTitle => 'Członkostwo';

  @override
  String get membershipChooseYourPlan => 'Wybierz swój plan';

  @override
  String get membershipCycleNoteMonthly =>
      'Płatność kartą. Odnawia się automatycznie co miesiąc, dopóki tego nie wyłączysz.';

  @override
  String get membershipCycleNoteYearly =>
      'Płatność kartą. Odnawia się automatycznie co rok, dopóki tego nie wyłączysz.';

  @override
  String get membershipNoPlansOnSale => 'Obecnie nie ma dostępnych planów.';

  @override
  String get membershipPaymentsTitle => 'Płatności';

  @override
  String get membershipNoCardPayments => 'Brak płatności kartą.';

  @override
  String get membershipFooterNote =>
      'Twój plan odnawia się automatycznie na koniec każdego okresu rozliczeniowego. Automatyczne odnawianie możesz wyłączyć w dowolnym momencie; korzyści zachowasz do końca okresu. Dane karty obsługuje dostawca płatności i nigdy nie są przechowywane w aplikacji.';

  @override
  String membershipSwitchTitle(String plan) {
    return 'Przejść na $plan?';
  }

  @override
  String membershipSwitchUpgradeBodyMonthly(String price) {
    return 'Teraz z karty zostanie pobrana różnica za resztę tego okresu, a od następnego odnowienia $price miesięcznie.';
  }

  @override
  String membershipSwitchUpgradeBodyYearly(String price) {
    return 'Teraz z karty zostanie pobrana różnica za resztę tego okresu, a od następnego odnowienia $price rocznie.';
  }

  @override
  String membershipSwitchDowngradeBodyMonthly(
    String currentPlan,
    String price,
  ) {
    return 'Plan zmieni się od razu. Niewykorzystany czas planu $currentPlan zostanie zaliczony na poczet następnego odnowienia, potem zapłacisz $price miesięcznie.';
  }

  @override
  String membershipSwitchDowngradeBodyYearly(String currentPlan, String price) {
    return 'Plan zmieni się od razu. Niewykorzystany czas planu $currentPlan zostanie zaliczony na poczet następnego odnowienia, potem zapłacisz $price rocznie.';
  }

  @override
  String get membershipNotNow => 'Nie teraz';

  @override
  String get membershipUpgrade => 'Ulepsz plan';

  @override
  String get membershipSwitchPlan => 'Zmień plan';

  @override
  String membershipSwitchedSnack(String plan) {
    return 'Masz teraz plan $plan.';
  }

  @override
  String get membershipCardUpdated => 'Twoja karta została zaktualizowana.';

  @override
  String get membershipCardUpdatePending =>
      'Aktualizacja karty nie została jeszcze potwierdzona. Sprawdź jej status, zanim spróbujesz ponownie.';

  @override
  String get membershipCardUpdateEnded =>
      'Sesja aktualizacji karty wygasła. Odśwież, aby zobaczyć aktualną kartę.';

  @override
  String get membershipCheckoutTitleCard => 'twoja karta';

  @override
  String get membershipAutoRenewOffTitle => 'Wyłączyć automatyczne odnawianie?';

  @override
  String membershipAutoRenewOffBodyDate(String plan, String date) {
    return 'Korzyści planu $plan pozostaną aktywne do $date. Potem przejdziesz na plan darmowy, a karta nie zostanie już obciążona.';
  }

  @override
  String membershipAutoRenewOffBodyPeriodEnd(String plan) {
    return 'Korzyści planu $plan pozostaną aktywne do końca bieżącego okresu. Potem przejdziesz na plan darmowy, a karta nie zostanie już obciążona.';
  }

  @override
  String get membershipKeepRenewing => 'Odnawiaj dalej';

  @override
  String get membershipTurnOff => 'Wyłącz';

  @override
  String get membershipAutoRenewBackOn =>
      'Automatyczne odnawianie jest znowu włączone.';

  @override
  String get membershipAutoRenewNowOff =>
      'Automatyczne odnawianie jest wyłączone. Korzyści zachowasz do końca okresu.';

  @override
  String membershipSubscribeTitle(String plan) {
    return 'Subskrybuj $plan';
  }

  @override
  String membershipSubscribeBodyMonthly(String price) {
    return '$price miesięcznie, pobierane z karty i odnawiane automatycznie, dopóki nie wyłączysz automatycznego odnawiania. Dane karty wpiszesz na bezpiecznej stronie dostawcy płatności.';
  }

  @override
  String membershipSubscribeBodyYearly(String price) {
    return '$price rocznie, pobierane z karty i odnawiane automatycznie, dopóki nie wyłączysz automatycznego odnawiania. Dane karty wpiszesz na bezpiecznej stronie dostawcy płatności.';
  }

  @override
  String membershipSubscribeBodyTestMonthly(String price) {
    return 'Tylko płatność testowa — bez prawdziwego obciążenia. $price miesięcznie, symulowane i odnawiane automatycznie, dopóki nie wyłączysz automatycznego odnawiania. Dane karty wpiszesz na bezpiecznej stronie dostawcy płatności.';
  }

  @override
  String membershipSubscribeBodyTestYearly(String price) {
    return 'Tylko płatność testowa — bez prawdziwego obciążenia. $price rocznie, symulowane i odnawiane automatycznie, dopóki nie wyłączysz automatycznego odnawiania. Dane karty wpiszesz na bezpiecznej stronie dostawcy płatności.';
  }

  @override
  String get membershipContinueToCard => 'Przejdź do karty';

  @override
  String get paymentStillConfirming =>
      'Płatność jest jeszcze potwierdzana. Za chwilę przeciągnij w dół, aby odświeżyć.';

  @override
  String get membershipCheckoutEnded =>
      'Sesja płatności wygasła. Odśwież historię płatności, zanim spróbujesz ponownie.';

  @override
  String get membershipRecoverAccountUnavailable =>
      'Nie udało się sprawdzić konta płatności. Spróbuj ponownie.';

  @override
  String get membershipRecoverCheckoutClosed =>
      'Konto płatności odświeżone. Ta płatność nie jest już otwarta.';

  @override
  String get membershipRecoverConfirmed =>
      'Potwierdzono. Twoje konto płatności jest aktualne.';

  @override
  String get membershipRecoverPending =>
      'Potwierdzenie wciąż oczekuje. Możesz sprawdzić ponownie tutaj.';

  @override
  String get membershipRecoverEnded =>
      'Sesja płatności wygasła. Sprawdź historię płatności, zanim rozpoczniesz kolejną.';

  @override
  String membershipCelebrateTitle(String plan) {
    return 'Masz teraz $plan';
  }

  @override
  String get membershipCelebrateBodyTest =>
      'Płatność testowa potwierdzona; nie pobrano prawdziwych pieniędzy. Twój plan testowy odnawia się automatycznie. Automatycznym odnawianiem możesz zarządzać w każdej chwili na tym ekranie.';

  @override
  String get membershipCelebrateBody =>
      'Płatność potwierdzona. Twój plan odnawia się automatycznie. Automatycznym odnawianiem możesz zarządzać w każdej chwili na tym ekranie.';

  @override
  String get membershipStartExploring => 'Zacznij odkrywać';

  @override
  String get membershipYourMembership => 'Twoje członkostwo';

  @override
  String get membershipYourPlan => 'Twój plan';

  @override
  String get membershipFreePlanName => 'Darmowy';

  @override
  String membershipPricePerMonthShort(String price) {
    return '$price/mies.';
  }

  @override
  String membershipPricePerYearShort(String price) {
    return '$price/rok';
  }

  @override
  String get membershipCardOnFile => 'Karta zapisana u dostawcy płatności';

  @override
  String get membershipCardBrandFallback => 'Karta';

  @override
  String get paymentOpening => 'Otwieranie…';

  @override
  String get membershipUpdateCard => 'Zmień kartę';

  @override
  String get membershipLastPaymentFailed =>
      'Ostatnia płatność się nie powiodła. Spróbujemy ponownie obciążyć kartę; korzyści pozostaną aktywne jeszcze przez kilka dni.';

  @override
  String membershipRenewsOn(String date) {
    return 'Odnowienie $date';
  }

  @override
  String get membershipRenewsSoon => 'Wkrótce odnowienie';

  @override
  String membershipEndsOn(String date) {
    return 'Kończy się $date · automatyczne odnawianie wyłączone';
  }

  @override
  String get membershipEndsSoon =>
      'Wkrótce się kończy · automatyczne odnawianie wyłączone';

  @override
  String get membershipAutoRenew => 'Automatyczne odnawianie';

  @override
  String get membershipAutoRenewOnSubtitle =>
      'Pobierane automatycznie w każdym okresie.';

  @override
  String get membershipAutoRenewOffSubtitle =>
      'Wyłączone. Korzyści wygasną z końcem bieżącego okresu.';

  @override
  String get membershipFreeHeroBody =>
      'Odblokuj więcej polubień, wiadomości i wyróżnień dzięki planowi poniżej. Płatność kartą, anulujesz w dowolnym momencie.';

  @override
  String get membershipStatusFree => 'Darmowy';

  @override
  String get membershipStatusPaymentDue => 'Płatność zaległa';

  @override
  String get membershipStatusEnding => 'Wygasa';

  @override
  String get membershipStatusActive => 'Aktywna';

  @override
  String get membershipCycleMonthly => 'Miesięcznie';

  @override
  String get membershipCycleYearly => 'Rocznie';

  @override
  String get membershipBadgeYourPlan => 'TWÓJ PLAN';

  @override
  String get membershipBadgeMostPopular => 'NAJPOPULARNIEJSZY';

  @override
  String get membershipPerMonth => 'miesięcznie';

  @override
  String get membershipPerYear => 'rocznie';

  @override
  String membershipSavePercent(int percent) {
    return 'Oszczędzasz $percent%';
  }

  @override
  String membershipQuotaLikesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count polubienia/dzień',
      many: '$count polubień/dzień',
      few: '$count polubienia/dzień',
      one: '1 polubienie/dzień',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wiadomości/dzień',
      many: '$count wiadomości/dzień',
      few: '$count wiadomości/dzień',
      one: '1 wiadomość/dzień',
    );
    return '$_temp0';
  }

  @override
  String get membershipQuotaUnlimitedLikes => 'Nielimitowane polubienia';

  @override
  String get membershipQuotaUnlimitedMessages => 'Nielimitowane wiadomości';

  @override
  String get membershipYourCurrentPlan => 'Twój obecny plan';

  @override
  String get membershipSwitching => 'Zmiana planu…';

  @override
  String get membershipOpeningSecureCheckout =>
      'Otwieranie bezpiecznej płatności…';

  @override
  String membershipSwitchToPlan(String plan) {
    return 'Przejdź na $plan';
  }

  @override
  String get membershipSubscribeWithCard => 'Subskrybuj kartą';

  @override
  String get membershipSettleBeforeSwitch =>
      'Przed zmianą planu ureguluj zaległą płatność za obecny plan.';

  @override
  String get membershipPaymentChargeback => 'Obciążenie zwrotne';

  @override
  String get membershipPaymentDisputed => 'Sporna';

  @override
  String get membershipPaymentRefunded => 'Zwrócona';

  @override
  String get membershipPaymentPartlyRefunded => 'Częściowo zwrócona';

  @override
  String get membershipPaymentFailed => 'Nieudana';

  @override
  String get membershipPaymentPaid => 'Opłacona';

  @override
  String get membershipPaymentPending => 'Oczekuje';

  @override
  String get membershipPaymentReasonFirstCharge => 'Pierwsza płatność';

  @override
  String get membershipPaymentReasonRenewal => 'Odnowienie';

  @override
  String get membershipPaymentReasonPlanChange => 'Zmiana planu';

  @override
  String get membershipPaymentReasonCoins => 'Monety';

  @override
  String get membershipPaymentReasonLocalActivation => 'Aktywacja lokalna';

  @override
  String get membershipPaymentReasonCard => 'Płatność kartą';

  @override
  String get membershipPaymentReasonOther => 'Płatność';

  @override
  String get paymentModeSandbox => 'Test lokalny · bez prawdziwego obciążenia';

  @override
  String get paymentModeStripeTest =>
      'Test Stripe · bez prawdziwego obciążenia';

  @override
  String get paymentModeLive => 'Prawdziwe płatności';

  @override
  String get paymentModeUnavailable => 'Płatności niedostępne';

  @override
  String get paymentAccountTitle => 'Twoje konto płatności';

  @override
  String get paymentAccountSignedInMember => 'Zalogowany członek';

  @override
  String get paymentAccountCardTitle => 'Karta kredytowa lub debetowa';

  @override
  String get paymentAccountCardUnavailableTitle =>
      'Płatność kartą jest niedostępna';

  @override
  String get paymentAccountCardBody =>
      'Wpisz dane karty na hostowanej stronie płatności. Członkostwo i historia płatności należą do tego konta.';

  @override
  String get paymentAccountCardUnavailableBody =>
      'Możesz dalej korzystać z obecnego konta. Nowe płatności kartą nie są włączone.';

  @override
  String paymentAccountTestCardHint(String cardNumber) {
    return 'Do testów użyj $cardNumber, przyszłej daty ważności i dowolnego trzycyfrowego kodu CVC. Używaj tylko danych testowych.';
  }

  @override
  String get paymentAccountUnfinishedCardUpdate =>
      'Niedokończona aktualizacja karty';

  @override
  String paymentAccountUnfinishedCheckout(String plan) {
    return 'Niedokończona płatność: $plan';
  }

  @override
  String get paymentAccountPendingHint =>
      'Sprawdź najnowszy status lub kontynuuj tę samą płatność.';

  @override
  String get paymentAccountCheckStatus => 'Sprawdź status';

  @override
  String get paymentAccountResumeCheckout => 'Wznów płatność';

  @override
  String paymentCheckoutPayFor(String title) {
    return 'Płatność: $title';
  }

  @override
  String get paymentCheckoutClose => 'Zamknij płatność';

  @override
  String get paymentCheckoutSecureNote =>
      'Dane karty wpisuje się na bezpiecznej stronie dostawcy płatności.';

  @override
  String paymentCheckoutCompleteInNewTab(String title) {
    return 'Dokończ płatność ($title) w nowej karcie';
  }

  @override
  String get paymentCheckoutWaitingBody =>
      'Dane karty wpisujesz na bezpiecznej stronie dostawcy płatności. Wróć tutaj, gdy pojawi się informacja, że płatność została zakończona.';

  @override
  String get paymentCheckoutCheckConfirmation => 'Sprawdź potwierdzenie';

  @override
  String get paymentCheckoutBackToAccount => 'Wróć do konta';

  @override
  String get paymentWalletTitle => 'Portfel i płatności';

  @override
  String get paymentWalletTestNote =>
      'Płatności testowe · bez prawdziwego obciążenia. Używaj tylko testowych danych karty.';

  @override
  String get paymentWalletPopularTopUps => 'Popularne doładowania';

  @override
  String get paymentWalletTopUpsIntro =>
      'Zapłać kartą na bezpiecznej stronie płatności. Monety trafią do portfela, gdy tylko płatność zostanie rozliczona.';

  @override
  String get paymentWalletCardsDisabled =>
      'Płatności kartą nie są jeszcze włączone na tym serwerze.';

  @override
  String get paymentWalletNoPacks =>
      'Obecnie nie ma dostępnych pakietów monet.';

  @override
  String get paymentWalletActivity => 'Aktywność portfela';

  @override
  String get paymentWalletNoPurchases => 'Brak zakupów monet.';

  @override
  String get paymentWalletFooter =>
      'Monety służą do prezentów i wyróżnień w Connect. Zakupy są ostateczne po rozliczeniu; dane karty pozostają u dostawcy płatności.';

  @override
  String paymentCoinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monety',
      many: '$count monet',
      few: '$count monety',
      one: '1 moneta',
    );
    return '$_temp0';
  }

  @override
  String paymentCoinsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dodano $count monety do portfela.',
      many: 'Dodano $count monet do portfela.',
      few: 'Dodano $count monety do portfela.',
      one: 'Dodano 1 monetę do portfela.',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'monety',
      many: 'monet',
      few: 'monety',
      one: 'moneta',
    );
    return '$_temp0';
  }

  @override
  String paymentPackCoinsUnitBonus(int count, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'monety · +$bonus gratis',
      many: 'monet · +$bonus gratis',
      few: 'monety · +$bonus gratis',
      one: 'moneta · +$bonus gratis',
    );
    return '$_temp0';
  }

  @override
  String get paymentWalletCheckoutEnded =>
      'Sesja płatności wygasła. Sprawdź historię płatności, zanim spróbujesz ponownie.';

  @override
  String get paymentWalletBalanceLabel => 'Saldo portfela Glow';

  @override
  String get paymentWalletSourceSupport => 'Doładowanie od wsparcia';

  @override
  String get paymentWalletSourcePromo => 'Promocja';

  @override
  String get paymentWalletSourcePurchase => 'Zakup monet';

  @override
  String get paymentErrorSignInSubscriptions =>
      'Zaloguj się, aby zarządzać subskrypcjami.';

  @override
  String get paymentErrorSignInWallet =>
      'Zaloguj się, aby zarządzać portfelem.';

  @override
  String get paymentErrorLoadSubscription =>
      'Nie udało się wczytać szczegółów subskrypcji.';

  @override
  String get paymentErrorLoadWallet => 'Nie udało się wczytać portfela.';

  @override
  String get paymentErrorStartCheckoutNow =>
      'Nie można teraz rozpocząć płatności.';

  @override
  String get paymentErrorStartCheckout => 'Nie udało się rozpocząć płatności.';

  @override
  String get paymentErrorConfirmPayment =>
      'Nie można jeszcze potwierdzić płatności.';

  @override
  String get paymentErrorAutoRenewOn =>
      'Nie udało się ponownie włączyć automatycznego odnawiania.';

  @override
  String get paymentErrorAutoRenewOff =>
      'Nie udało się wyłączyć automatycznego odnawiania.';

  @override
  String get paymentErrorChangePlan => 'Nie udało się zmienić planu.';

  @override
  String get paymentErrorUpdateCard => 'Nie udało się zaktualizować karty.';

  @override
  String get paymentErrorSandboxFailed =>
      'Symulacja w piaskownicy nie powiodła się.';

  @override
  String get paymentErrorUnreachable =>
      'Nie można połączyć się z usługą lokalną. Sprawdź, czy API działa.';

  @override
  String membershipQuotaLikesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Dziś zostało $remaining z $limit polubienia',
      many: 'Dziś zostało $remaining z $limit polubień',
      few: 'Dziś zostało $remaining z $limit polubień',
      one: 'Dziś zostało $remaining z 1 polubienia',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaMessagesLeftToday(int remaining, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Dziś zostało $remaining z $limit wiadomości',
      many: 'Dziś zostało $remaining z $limit wiadomości',
      few: 'Dziś zostało $remaining z $limit wiadomości',
      one: 'Dziś zostało $remaining z 1 wiadomości',
    );
    return '$_temp0';
  }

  @override
  String membershipLikeLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Dzisiejszy limit wykorzystany: $limit polubienia w planie $plan',
      many: 'Dzisiejszy limit wykorzystany: $limit polubień w planie $plan',
      few: 'Dzisiejszy limit wykorzystany: $limit polubienia w planie $plan',
      one: 'Dzisiejszy limit wykorzystany: 1 polubienie w planie $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipMessageLimitHeadline(int limit, String plan) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: 'Dzisiejszy limit wykorzystany: $limit wiadomości w planie $plan',
      many: 'Dzisiejszy limit wykorzystany: $limit wiadomości w planie $plan',
      few: 'Dzisiejszy limit wykorzystany: $limit wiadomości w planie $plan',
      one: 'Dzisiejszy limit wykorzystany: 1 wiadomość w planie $plan',
    );
    return '$_temp0';
  }

  @override
  String membershipQuotaResetsAt(String time) {
    return 'Odnowi się o $time';
  }

  @override
  String matchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dopasowania',
      many: '$count dopasowań',
      few: '$count dopasowania',
      one: '$count dopasowanie',
    );
    return '$_temp0';
  }

  @override
  String get matchesSubtitleConversations =>
      'Trochę bliżej, wiadomość po wiadomości.';

  @override
  String get matchesSubtitlePeople =>
      'Osoby, które wybierasz. Możliwości, które tworzycie razem.';

  @override
  String get matchesSearchConversations => 'Szukaj rozmów';

  @override
  String get matchesSearchMatches => 'Szukaj w swoich dopasowaniach';

  @override
  String get matchesFilterAllConversations => 'Wszystkie rozmowy';

  @override
  String matchesFilterUnread(int count) {
    return 'Nieprzeczytane · $count';
  }

  @override
  String get matchesLoading => 'Wczytywanie dopasowań…';

  @override
  String get matchesLoadErrorTitle => 'Nie udało się wczytać dopasowań';

  @override
  String get matchesRetry => 'Ponów';

  @override
  String get matchesEmptyTitle => 'Jeszcze nie masz dopasowań';

  @override
  String matchesTrustFilteredHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Filtry zaufania ukryły $count dopasowania. Spróbuj je złagodzić w sekcji Odkrywaj.',
      many:
          'Filtry zaufania ukryły $count dopasowań. Spróbuj je złagodzić w sekcji Odkrywaj.',
      few:
          'Filtry zaufania ukryły $count dopasowania. Spróbuj je złagodzić w sekcji Odkrywaj.',
      one:
          'Filtry zaufania ukryły $count dopasowanie. Spróbuj je złagodzić w sekcji Odkrywaj.',
    );
    return '$_temp0';
  }

  @override
  String get matchesEmptyBody =>
      'Zajrzyj do sekcji Dzisiaj, aby odkryć kogoś, kogo chcesz poznać.';

  @override
  String get matchesNoConversationResults =>
      'Nie ma tu jeszcze rozmów. Spróbuj innego wyszukiwania lub filtra.';

  @override
  String get matchesNoPeopleResults =>
      'Nie znaleziono dopasowań. Spróbuj innego imienia.';

  @override
  String get matchesTabPeople => 'Twoje dopasowania';

  @override
  String get matchesTabConversations => 'Rozmowy';

  @override
  String get matchesActionStartCall => 'Rozpocznij połączenie';

  @override
  String get matchesActionStartActivity => 'Rozpocznij aktywność';

  @override
  String get matchesActionPlanDate => 'Zaplanuj randkę';

  @override
  String get matchesActionPlanDateSubtitle =>
      'Wybierz termin i to, czym chcesz się podzielić';

  @override
  String matchesPlanSent(String name) {
    return 'Plan wysłany do: $name.';
  }

  @override
  String get matchesActionGraduate => 'Znaleźliśmy się';

  @override
  String get matchesActionGraduateSubtitle =>
      'Opuśćcie Connect razem; czat zostaje';

  @override
  String matchesGraduationAsked(String name) {
    return 'Wysłano prośbę o wspólne odejście: $name. Potwierdzenie jest możliwe w waszym czacie.';
  }

  @override
  String get matchesActionNudge => 'Wyślij szturchnięcie';

  @override
  String matchesNudgeSent(String name) {
    return 'Szturchnięcie wysłane do: $name.';
  }

  @override
  String get matchesNudgeFailed => 'Nie udało się wysłać szturchnięcia.';

  @override
  String get matchesActionClose => 'Zamknij rozmowę';

  @override
  String get matchesActionCloseSubtitle =>
      'Zrób sobie przestrzeń, bez tłumaczenia się.';

  @override
  String get matchesCloseDialogTitle => 'Zamknąć tę rozmowę?';

  @override
  String get matchesCloseDialogBody =>
      'To w porządku, jeśli ta znajomość nie jest dla Ciebie. To zakończy dopasowanie. Nie musisz niczego wyjaśniać. Zgłoszenie pozostaje osobną decyzją.';

  @override
  String get matchesCloseDialogKeep => 'Rozmawiaj dalej';

  @override
  String get matchesActionReport => 'Zgłoś';

  @override
  String get matchesReportSubmitted => 'Zgłoszenie wysłane. Dziękujemy.';

  @override
  String get matchesReportAppeal => 'Odwołaj się';

  @override
  String matchesAppealReason(String userId) {
    return 'Sprawdź wynik moderacji zgłoszenia dotyczącego użytkownika $userId';
  }

  @override
  String get matchesBothChose => 'Oboje zdecydowaliście się poznać';

  @override
  String matchesOptionsTooltip(String name) {
    return 'Opcje dopasowania: $name';
  }

  @override
  String matchesChatUnread(int count) {
    return 'Czat · nieprzeczytane: $count';
  }

  @override
  String get matchesOpenChat => 'Otwórz czat';

  @override
  String get matchesFirstChapter => 'Pierwszy Rozdział';

  @override
  String get matchesUnknownName => 'Nieznany';

  @override
  String get matchesSayHi => 'Przywitaj się 👋';

  @override
  String get matchesFallbackName => 'Twoje dopasowanie';

  @override
  String get matchesFallbackMessage => 'Rozpocznij rozmowę';

  @override
  String get matchesGiftPreview => 'Mały prezent w waszej rozmowie';

  @override
  String matchesConversationOptionsTooltip(String name) {
    return 'Opcje rozmowy: $name';
  }

  @override
  String get matchesTimeNow => 'Teraz';

  @override
  String matchesTimeMinutesAgo(int minutes) {
    return '$minutes min temu';
  }

  @override
  String matchesTimeHoursAgo(int hours) {
    return '$hours godz. temu';
  }

  @override
  String get matchesTimeToday => 'Dzisiaj';

  @override
  String get matchesTimeYesterday => 'Wczoraj';

  @override
  String get matchesNewMatchTitle => 'Nowe dopasowanie';

  @override
  String get matchesItsAMatch => 'Jest dopasowanie!';

  @override
  String matchesLikedEachOther(String name) {
    return 'Ty i $name polubiliście się nawzajem';
  }

  @override
  String get matchesSendMessage => 'Wyślij wiadomość';

  @override
  String get matchesKeepSwiping => 'Przeglądaj dalej';

  @override
  String get matchesErrorLoginRequired =>
      'Zaloguj się, aby zobaczyć dopasowania.';

  @override
  String get matchesErrorLoadFailed =>
      'Nie udało się wczytać dopasowań. Spróbuj ponownie.';

  @override
  String get matchesErrorUnmatchFailed => 'Nie udało się usunąć dopasowania.';

  @override
  String get matchesErrorMarkReadFailed =>
      'Nie udało się oznaczyć jako przeczytane.';

  @override
  String get matchesErrorSessionUnavailable =>
      'Sesja użytkownika jest niedostępna.';

  @override
  String get matchesTrustBadgePromptCompleter => 'Uzupełnia pytania';

  @override
  String get matchesTrustBadgeRespectful => 'Kulturalna komunikacja';

  @override
  String get matchesTrustBadgeConsistent => 'Spójny profil';

  @override
  String get matchesTrustBadgeVerifiedActive => 'Zweryfikowany i aktywny';

  @override
  String get matchesTrustErrorLoad =>
      'Nie udało się wczytać filtrów zaufania. Spróbuj ponownie.';

  @override
  String get matchesTrustErrorSave =>
      'Nie udało się zapisać filtrów zaufania. Spróbuj ponownie.';

  @override
  String get matchesGestureErrorLoad => 'Nie udało się wczytać historii';

  @override
  String get matchesGestureErrorPending =>
      'Gesty odblokują się, gdy ta oczekująca rozmowa stanie się prawdziwym dopasowaniem.';

  @override
  String get matchesGestureErrorSend => 'Nie udało się wysłać gestu.';

  @override
  String get matchesGestureErrorUpdate =>
      'Nie udało się zaktualizować statusu gestu.';

  @override
  String get matchesActivityTitle => 'To czy tamto w 2 minuty';

  @override
  String get matchesActivityRestartTooltip => 'Rozpocznij nową sesję';

  @override
  String matchesActivityCompleteWith(String name) {
    return 'Zagrajcie razem: Ty i $name';
  }

  @override
  String get matchesActivityInstructions =>
      'Odpowiedz na wszystkie 8 rund, zanim skończy się czas.';

  @override
  String matchesActivityStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get matchesActivityStatusActive => 'aktywna';

  @override
  String get matchesActivityStatusTimedOut => 'czas minął';

  @override
  String get matchesActivityStatusPartialTimeout => 'częściowo wygasła';

  @override
  String get matchesActivityStatusCompleted => 'ukończona';

  @override
  String get matchesActivitySubmit => 'Wyślij odpowiedzi';

  @override
  String get matchesActivityTimeUpLoad => 'Czas minął — wczytaj podsumowanie';

  @override
  String get matchesActivityWaiting =>
      'Odpowiedzi wysłane. Czekamy, aż druga osoba skończy.';

  @override
  String get matchesActivityRefreshSummary => 'Odśwież podsumowanie';

  @override
  String matchesActivityTimeLeft(String time) {
    return 'Pozostało $time';
  }

  @override
  String get matchesActivitySummaryTitle => 'Podsumowanie aktywności';

  @override
  String matchesActivityParticipantsCompleted(int completed, int total) {
    return 'Ukończyło: $completed/$total';
  }

  @override
  String get matchesActivitySummaryPending =>
      'Podsumowanie pojawi się, gdy będzie dostępne.';

  @override
  String get matchesActivityShareResult => 'Udostępnij wynik w czacie';

  @override
  String matchesActivityShareMessage(String status, int completed, int total) {
    return 'Wynik To czy tamto (2 min): $status • ukończyło $completed/$total';
  }

  @override
  String matchesActivityShareMessageWithInsight(
    String status,
    int completed,
    int total,
    String insight,
  ) {
    return 'Wynik To czy tamto (2 min): $status • ukończyło $completed/$total • $insight';
  }

  @override
  String matchesActivityRound(int number) {
    return 'Runda $number';
  }

  @override
  String get matchesActivityErrorStart =>
      'Nie można teraz rozpocząć aktywności. Spróbuj ponownie.';

  @override
  String get matchesActivityErrorNotReady => 'Sesja nie jest jeszcze gotowa.';

  @override
  String get matchesActivityErrorAnswerAll =>
      'Odpowiedz na wszystkie pytania przed wysłaniem.';

  @override
  String get matchesActivityErrorTimeUp =>
      'Czas minął. Wczytywanie podsumowania…';

  @override
  String get matchesActivityErrorSubmit =>
      'Nie udało się wysłać odpowiedzi. Spróbuj ponownie.';

  @override
  String get matchesActivityErrorSummary =>
      'Nie można jeszcze pobrać podsumowania. Spróbuj ponownie.';

  @override
  String get matchesActivityQ1Prompt => 'Idealne pierwsze spotkanie?';

  @override
  String get matchesActivityQ1OptionA => 'Spacer z kawą';

  @override
  String get matchesActivityQ1OptionB => 'Wizyta w księgarni';

  @override
  String get matchesActivityQ2Prompt => 'Ulubiony nastrój na weekend?';

  @override
  String get matchesActivityQ2OptionA => 'Zostać w domu i odpocząć';

  @override
  String get matchesActivityQ2OptionB => 'Zwiedzać miasto';

  @override
  String get matchesActivityQ3Prompt => 'Najlepsze miejsce na rozmowę?';

  @override
  String get matchesActivityQ3OptionA => 'Długi spacer';

  @override
  String get matchesActivityQ3OptionB => 'Przytulny kącik w kawiarni';

  @override
  String get matchesActivityQ4Prompt => 'Jak planujesz randki?';

  @override
  String get matchesActivityQ4OptionA => 'Spontanicznie';

  @override
  String get matchesActivityQ4OptionB => 'Z wyprzedzeniem';

  @override
  String get matchesActivityQ5Prompt => 'Co jest teraz ważniejsze?';

  @override
  String get matchesActivityQ5OptionA => 'Stabilność';

  @override
  String get matchesActivityQ5OptionB => 'Ekscytacja';

  @override
  String get matchesActivityQ6Prompt => 'Jak wolisz rozwiązywać konflikty?';

  @override
  String get matchesActivityQ6OptionA => 'Wyjaśnić tego samego dnia';

  @override
  String get matchesActivityQ6OptionB => 'Odpocząć i wrócić do tematu';

  @override
  String get matchesActivityQ7Prompt => 'Wspólna aktywność?';

  @override
  String get matchesActivityQ7OptionA => 'Wspólne gotowanie';

  @override
  String get matchesActivityQ7OptionB => 'Wspólny trening';

  @override
  String get matchesActivityQ8Prompt => 'Jakie tempo wolisz?';

  @override
  String get matchesActivityQ8OptionA => 'Spokojnie i świadomie';

  @override
  String get matchesActivityQ8OptionB => 'Szybko i energicznie';

  @override
  String get cityPilotSaveFailed =>
      'Nie udało się potwierdzić tej zmiany. Odśwież, aby sprawdzić, zanim spróbujesz ponownie.';

  @override
  String get cityPilotLeaveTitle => 'Opuścić pilotaż miejski?';

  @override
  String get cityPilotLeaveBody =>
      'Twoje rezerwacje w pilotażu zostaną anulowane, a opinie o wydarzeniach usunięte. Twoja aktywność przestanie wpływać na bieżące wyniki. Dopasowania i rozmowy zostają. Nie możesz ponownie dołączyć do tego pilotażu.';

  @override
  String get cityPilotStay => 'Zostań w pilotażu';

  @override
  String get cityPilotLeave => 'Opuść pilotaż';

  @override
  String get cityPilotLeftNotice =>
      'Udział w pilotażu zakończony. Twoje dopasowania zostają z Tobą.';

  @override
  String cityPilotJoinEventTitle(String title) {
    return 'Dołączyć do: $title?';
  }

  @override
  String cityPilotBookingTerms(
    String host,
    String safetyContact,
    String accessibility,
  ) {
    return 'To wydarzenie jest bezpłatne. Spotkanie odbywa się w miejscu publicznym: szanuj granice innych i zorganizuj własny dojazd. Możesz wyjść w dowolnym momencie.\n\nGospodarz: $host\nKontakt ds. bezpieczeństwa: $safetyContact\n\nDostępność: $accessibility\n\nW razie bezpośredniego zagrożenia skontaktuj się z lokalnymi służbami ratunkowymi.';
  }

  @override
  String get cityPilotAcceptReserve => 'Akceptuj i zarezerwuj miejsce';

  @override
  String get cityPilotReservedNotice =>
      'Twoje miejsce jest zarezerwowane. Możesz je tu anulować w dowolnym momencie.';

  @override
  String get cityPilotFeedbackTitle => 'Jak było?';

  @override
  String get cityPilotFeedbackIntro =>
      'Opcjonalne. Odpowiedzi trafiają do zbiorczych wyników pilotażu. Nie widzą ich inni członkowie ani gospodarz.';

  @override
  String get cityPilotDidYouAttend => 'Udało się przyjść?';

  @override
  String get cityPilotAttendedYes => 'Tak, udało się';

  @override
  String get cityPilotAttendedNo => 'Nie udało się';

  @override
  String get cityPilotWorthwhileQuestion => 'Czy było warto? (opcjonalnie)';

  @override
  String get cityPilotNotThisTime => 'Tym razem nie';

  @override
  String get cityPilotSkip => 'Pomiń';

  @override
  String get cityPilotShareFeedback => 'Wyślij opinię';

  @override
  String get cityPilotFeedbackThanks =>
      'Dziękujemy. Twoja opinia została zapisana prywatnie.';

  @override
  String get cityPilotTimeTbc => 'Godzina do potwierdzenia';

  @override
  String get cityPilotTitle => 'Pilotaż miejski';

  @override
  String get cityPilotRefreshTooltip => 'Odśwież pilotaż';

  @override
  String get cityPilotHeroTitle => 'Trochę bliżej.\nZnacznie prawdziwiej.';

  @override
  String get cityPilotHeroBody =>
      'Jedno miasto. Mała społeczność. Więcej szans, że rozmowa zamieni się w plan.';

  @override
  String get cityPilotStep1Title => 'Zacznij od rozmowy';

  @override
  String get cityPilotStep1Body =>
      'Poznawaj ludzi we własnym tempie dzięki dotychczasowym przedstawieniom.';

  @override
  String get cityPilotStep2Title => 'Zrób miejsce na prawdziwą randkę';

  @override
  String get cityPilotStep2Body =>
      'Stwórzcie razem plan. Opowiedz, jak poszło, tylko jeśli chcesz.';

  @override
  String get cityPilotStep3Title => 'Spróbujcie czegoś razem';

  @override
  String get cityPilotStep3Body =>
      'Małe wydarzenia z gospodarzem pojawią się po pierwszym przeglądzie pilotażu.';

  @override
  String get cityPilotSaving => 'Zapisywanie ustawienia pilotażu';

  @override
  String get cityPilotUnavailableTitle => 'Pilotaż jest niedostępny';

  @override
  String get cityPilotUnavailableBody =>
      'Sprawdź połączenie i odśwież, aby zobaczyć aktualny udział i rezerwacje.';

  @override
  String get cityPilotComingSoonTitle => 'Wkrótce w mieście niedaleko Ciebie';

  @override
  String get cityPilotComingSoonBody =>
      'Dla miasta z Twojego profilu nie ma jeszcze otwartego pilotażu. Gdy się pojawi, zdecydujesz, czy chcesz wziąć udział. Twoje obecne randkowanie toczy się jak zwykle.';

  @override
  String cityPilotPanelTitleJoined(String city) {
    return '$city · Bierzesz udział';
  }

  @override
  String cityPilotPanelTitleOpen(String city) {
    return '$city · Pilotaż miejski';
  }

  @override
  String cityPilotRecruitmentCloses(String date) {
    return 'Koniec rekrutacji: $date (Twój czas lokalny).';
  }

  @override
  String get cityPilotPaused =>
      'Nowe zgłoszenia i rezerwacje są wstrzymane. Nadal możesz zrezygnować lub anulować.';

  @override
  String get cityPilotCompleted =>
      'Ten pilotaż dobiegł końca. Dziękujemy za udział.';

  @override
  String get cityPilotMeasurement =>
      'Dołączając, pozwalasz nam liczyć rozmowy, zaakceptowane plany i opcjonalne odpowiedzi na pytanie „Czy randka się odbyła?” dla nowych dopasowań, w których obie osoby dołączyły do tego pilotażu. Stosujemy okna 7 dni dla rozmów i 28 dni dla randek. Na potrzeby pilotażu nie czytamy treści wiadomości ani prywatnych notatek z opinii.';

  @override
  String get cityPilotPrivacy =>
      'Udział pozostaje prywatny. Nie ma publicznej listy obecności ani wyniku randkowego. Rezygnacja wyklucza Twoją aktywność z bieżących wyników i anuluje rezerwacje. Wcześniej przejrzanych zbiorczych wyników nie da się cofnąć.';

  @override
  String get cityPilotConsent =>
      'Zgadzam się na udział w tym pilotażu i pomiar jego wyników.';

  @override
  String get cityPilotJoinedNotice =>
      'Wchodzisz w to. Poznawaj dalej ludzi we własnym tempie.';

  @override
  String get cityPilotJoin => 'Dołącz do pilotażu';

  @override
  String get cityPilotWithdrawn =>
      'Nie bierzesz już udziału w tym pilotażu. Dopasowania i rozmowy pozostają bez zmian.';

  @override
  String get cityPilotNotAccepting =>
      'Ten pilotaż nie przyjmuje teraz nowych uczestników.';

  @override
  String get cityPilotExperiencesHeading => 'Małe plany. Wspólne przeżycia.';

  @override
  String get cityPilotNoExperiences =>
      'Wydarzenia z gospodarzem nie są jeszcze otwarte. Pojawią się tutaj po przeglądzie wyników i bezpieczeństwa.';

  @override
  String cityPilotEventDetails(
    String start,
    String end,
    String venue,
    String host,
  ) {
    return '$start → $end\nTwój czas lokalny · Bezpłatne\n$venue\nGospodarz: $host';
  }

  @override
  String cityPilotAccessibility(String details) {
    return 'Dostępność · $details';
  }

  @override
  String cityPilotSafetyContact(String contact) {
    return 'Kontakt ds. bezpieczeństwa · $contact';
  }

  @override
  String get cityPilotEventCancelled =>
      'To wydarzenie zostało odwołane. Nie przyjeżdżaj na miejsce.';

  @override
  String get cityPilotPlaceReserved => 'Twoje miejsce jest zarezerwowane.';

  @override
  String get cityPilotBookingCancelled => 'Twoja rezerwacja została anulowana.';

  @override
  String get cityPilotCancelPlace => 'Anuluj moje miejsce';

  @override
  String get cityPilotReserveFree => 'Zarezerwuj bezpłatne miejsce';

  @override
  String get cityPilotShareOptionalFeedback => 'Podziel się opcjonalną opinią';

  @override
  String get cityPilotFeedbackReceived =>
      'Otrzymaliśmy Twoją opinię. Dziękujemy.';

  @override
  String get blogAudiencePrivate => 'Tylko ja';

  @override
  String get blogAudienceFriends => 'Znajomi';

  @override
  String get blogAudienceCommunity => 'Społeczność Connect';

  @override
  String get blogInvitationNone => 'Bez zaproszenia';

  @override
  String get blogInvitationYourVersion => 'Jak wyglądałaby Twoja wersja?';

  @override
  String get blogInvitationTeachMe => 'Czego możesz mnie o tym nauczyć?';

  @override
  String get blogInvitationWhatNext => 'Co chcesz wypróbować jako następne?';

  @override
  String get blogRewardStoryPublishedTitle => 'Udostępnienie rozdziału';

  @override
  String get blogRewardStoryPublishedWho =>
      'Ty – gdy po raz pierwszy udostępnisz rozdział szerzej niż „Tylko ja”';

  @override
  String get blogRewardPhotoSharedTitle =>
      'Udostępnienie zdjęcia w Tematach zdjęć';

  @override
  String get blogRewardPhotoSharedWho =>
      'Ty – za zdjęcie udostępnione w Tematach zdjęć';

  @override
  String get blogRewardLikeReceivedTitle =>
      'Polubienie Twojego rozdziału lub zdjęcia';

  @override
  String get blogRewardLikeReceivedWho => 'Ty – za każdą osobę, która polubi';

  @override
  String get blogRewardCommentReceivedTitle =>
      'Zatwierdzony przez Ciebie komentarz';

  @override
  String get blogRewardCommentReceivedWho =>
      'Ty – gdy zatwierdzisz komentarz czytelnika';

  @override
  String get blogRewardCommentApprovedTitle =>
      'Twój komentarz został zatwierdzony';

  @override
  String get blogRewardCommentApprovedWho =>
      'Ty – gdy autor zatwierdzi Twój komentarz';

  @override
  String get blogRewardSubscriberGainedTitle => 'Nowy obserwujący';

  @override
  String get blogRewardSubscriberGainedWho =>
      'Ty – za każdą nową osobę obserwującą Twoje rozdziały';

  @override
  String get blogRewardWallTierTitle => 'Więcej tablic';

  @override
  String get blogRewardWallTierWho =>
      'Ty – za każdym razem, gdy rozdział osiągnie nowy próg tablic';

  @override
  String get blogRewardCoverOfWeekTitle => 'Okładka tygodnia';

  @override
  String get blogRewardCoverOfWeekWho =>
      'Ty – gdy Twoja praca zostanie wybrana Okładką tygodnia';

  @override
  String get blogScopeForYou => 'Dla Ciebie';

  @override
  String get blogScopeTopRated => 'Najlepiej oceniane';

  @override
  String get blogScopeFollowing => 'Obserwowani';

  @override
  String get blogScopeMine => 'Moje';

  @override
  String get blogScopeCaptionMine =>
      'Twoje wersje robocze i opublikowane rozdziały. Dla każdego sam wybierasz odbiorców.';

  @override
  String get blogScopeCaptionFriends =>
      'Rozdziały udostępnione przez Twoich znajomych w Connect.';

  @override
  String get blogScopeCaptionTop =>
      'Ranking według polubień, zatwierdzonych komentarzy i czytelników z ostatnich 30 dni.';

  @override
  String get blogScopeCaptionFollowing =>
      'Najnowsze rozdziały autorów, których obserwujesz.';

  @override
  String get blogScopeCaptionCommunity =>
      'Dla zalogowanych, uprawnionych członków Connect. Te rozdziały nie są publiczne w sieci.';

  @override
  String get blogTitle => 'Otwarte rozdziały';

  @override
  String get blogRewardsTitle => 'Jak działają nagrody';

  @override
  String get blogWritersTitle => 'Obserwowani autorzy';

  @override
  String get blogConnectionsTooltip =>
      'Prywatne odpowiedzi, udostępnienia i powiadomienia';

  @override
  String get blogSignInReadWrite =>
      'Zaloguj się, aby czytać i pisać rozdziały.';

  @override
  String get blogHeroTitle => 'Życie, które warto\npoznać.';

  @override
  String get blogHeroBody =>
      'Historia kryjąca się za zdjęciem. Mała obsesja. Coś, czego wciąż się uczysz. Niech Twoja codzienność mówi za Ciebie.';

  @override
  String get blogWriteChapter => 'Napisz rozdział';

  @override
  String get blogPrivateResponses => 'Prywatne odpowiedzi';

  @override
  String get blogSharedLinks => 'Udostępnione linki';

  @override
  String get blogReviewNotices => 'Powiadomienia o weryfikacji';

  @override
  String get blogTopicAll => 'Wszystkie';

  @override
  String get blogFeedLoadFailed => 'Nie udało się wczytać rozdziałów.';

  @override
  String get blogPreviousPage => 'Poprzednia strona';

  @override
  String get blogMoreChapters => 'Więcej rozdziałów';

  @override
  String get blogEmptyMineTitle => 'Twój następny rozdział zaczyna się tutaj.';

  @override
  String get blogEmptyMineBody =>
      'Zacznij od chwili, o którą warto Cię zapytać. Twoja pierwsza wersja robocza jest tylko dla Ciebie.';

  @override
  String get blogEmptyTopTitle =>
      'Gdy rozdziały poruszają ludzi, trafiają tutaj.';

  @override
  String get blogEmptyTopFilteredBody =>
      'W tym temacie nic jeszcze nie awansowało. Wybierz „Wszystkie” albo udostępnij własny rozdział.';

  @override
  String get blogEmptyTopBody =>
      'Tu pojawią się rozdziały, które czytelnicy pokochali w ciągu ostatnich 30 dni.';

  @override
  String get blogEmptyFollowingFilteredTitle =>
      'W tym temacie nie ma jeszcze nic nowego.';

  @override
  String get blogEmptyFollowingTitle => 'Tu pojawią się obserwowani autorzy.';

  @override
  String get blogEmptyFollowingBody =>
      'Gdy rozdział Cię poruszy, otwórz go i stuknij „Obserwuj rozdziały”. Nowe rozdziały będą się tu zbierać, więc niczego nie przegapisz.';

  @override
  String get blogEmptyCommunityTitle => 'Na razie jest tu trochę cicho.';

  @override
  String get blogEmptyCommunityBody =>
      'Rozdziały pojawią się tu, gdy członkowie udostępnią je tym odbiorcom.';

  @override
  String get blogFindWritersTopRated =>
      'Znajdź autorów w „Najlepiej ocenianych”';

  @override
  String blogRankTooltip(int rank) {
    return 'Miejsce $rank w „Najlepiej ocenianych”';
  }

  @override
  String get blogUntitled => 'Rozdział bez tytułu';

  @override
  String get blogDraftPlaceholder =>
      'Prywatna wersja robocza czeka na Twoje słowa.';

  @override
  String get blogReadEdit => 'Czytaj i edytuj →';

  @override
  String get blogReadChapter => 'Czytaj rozdział →';

  @override
  String get blogPhotoUnavailableRetry => 'Zdjęcie niedostępne · Ponów';

  @override
  String get blogTryAgain => 'Spróbuj ponownie';

  @override
  String get blogDetailTitle => 'Rozdział';

  @override
  String get blogSignInRead => 'Zaloguj się, aby czytać rozdziały.';

  @override
  String get blogDetailUnavailable =>
      'Ten rozdział jest niedostępny lub zmienili się jego odbiorcy.';

  @override
  String get blogRespondPrivately => 'Odpowiedz prywatnie';

  @override
  String get blogCreatePublicPreview => 'Utwórz publiczny podgląd';

  @override
  String get blogRemovedByModerationNote =>
      'Usunięte przez moderację. Otwórz „Powiadomienia o weryfikacji”, aby przeczytać decyzję lub poprosić o ponowną weryfikację.';

  @override
  String get blogEditChapter => 'Edytuj rozdział';

  @override
  String get blogDeleteChapter => 'Usuń rozdział';

  @override
  String get blogDeleteChapterTitle => 'Usunąć ten rozdział?';

  @override
  String get blogDeleteChapterMessage =>
      'Zniknie dla wszystkich odbiorców. Tego nie można cofnąć.';

  @override
  String get blogDeleteChapterFailed =>
      'Nie udało się potwierdzić usunięcia. Odśwież rozdział, zanim spróbujesz ponownie.';

  @override
  String get blogReportChapter => 'Zgłoś rozdział';

  @override
  String get blogReportFailed => 'Nie udało się wysłać zgłoszenia.';

  @override
  String get blogBlockThisMember => 'Zablokuj tę osobę';

  @override
  String get blogBlockTitle => 'Zablokować tę osobę?';

  @override
  String get blogBlockMessageChapter =>
      'Nie będziecie już widzieć swoich rozdziałów. To także blokuje kontakt przez Connect.';

  @override
  String get blogBlockMember => 'Zablokuj';

  @override
  String get blogBlockRetryFailed =>
      'Nie udało się zablokować tej osoby. Spróbuj ponownie.';

  @override
  String get blogCancel => 'Anuluj';

  @override
  String get blogEditorMissingFields =>
      'Przed publikacją dodaj tytuł i historię.';

  @override
  String blogPublishConfirmTitle(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Opublikować jako „Tylko ja”?',
      'friends': 'Opublikować dla znajomych?',
      'community': 'Opublikować w społeczności Connect?',
      'other': 'Opublikować?',
    });
    return '$_temp0';
  }

  @override
  String get blogPublishFriendsBody =>
      'Twoi znajomi w Connect będą mogli przeczytać tekst i zobaczyć zdjęcia z tego rozdziału. Odbiorców możesz później zmienić.';

  @override
  String get blogPublishCommunityBody =>
      'Ten rozdział przeczytają zalogowani, uprawnieni członkowie Connect. Nie pojawi się w publicznej sieci. Odbiorców możesz później zmienić.';

  @override
  String get blogPublishChapter => 'Opublikuj rozdział';

  @override
  String get blogSavedOnlyMe =>
      'Zapisano. Tylko Ty możesz przeczytać ten rozdział.';

  @override
  String blogPublishedTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Opublikowano jako „Tylko ja”.',
      'friends': 'Opublikowano dla znajomych.',
      'community': 'Opublikowano w społeczności Connect.',
      'other': 'Opublikowano.',
    });
    return '$_temp0';
  }

  @override
  String get blogSharedSnack =>
      'Udostępniono. Polubienia i komentarze czytelników dają Ci XP.';

  @override
  String get blogSeeMyLevel => 'Zobacz mój poziom';

  @override
  String get blogSaveUnconfirmed => 'Nie udało się potwierdzić zapisu.';

  @override
  String blogEditsStillHere(String message) {
    return '$message Twoje zmiany wciąż tu są. Sprawdź zapisaną wersję, zanim przejdziesz dalej.';
  }

  @override
  String blogSavedVersionTitle(String audience) {
    return 'Zapisana wersja · $audience';
  }

  @override
  String get blogSavedVersionNote =>
      'Bieżące zmiany pozostają w edytorze. Zamknij ten panel, aby je zachować, lub zastąp je zapisaną wersją.';

  @override
  String get blogKeepMyEdits => 'Zachowaj moje zmiany do następnego zapisu';

  @override
  String get blogUseSavedVersion => 'Użyj zapisanej wersji';

  @override
  String get blogSavedVersionLoadFailed =>
      'Nie udało się wczytać zapisanej wersji. Twoje zmiany pozostają tutaj.';

  @override
  String get blogDescribePhotoTitle => 'Opisz zdjęcie';

  @override
  String get blogDescribePhotoBody =>
      'Krótki opis sprawia, że rozdział jest dostępny. Dodanie zdjęcia zapisze tekst jako wersję roboczą „Tylko ja”.';

  @override
  String get blogDescribePhotoLabel => 'Co jest na tym zdjęciu?';

  @override
  String get blogAddToPrivateDraft => 'Dodaj do prywatnej wersji roboczej';

  @override
  String get blogPhotoAdded => 'Zdjęcie dodano do prywatnej wersji roboczej.';

  @override
  String get blogPhotoAddFailed =>
      'Nie udało się dodać zdjęcia. Użyj pliku JPEG lub PNG do 10 MB.';

  @override
  String blogCheckSavedBeforeRetrying(String message) {
    return '$message Sprawdź zapisaną wersję, zanim spróbujesz ponownie.';
  }

  @override
  String get blogRemoveUnconfirmed =>
      'Nie udało się potwierdzić usunięcia. Sprawdź zapisaną wersję.';

  @override
  String get blogSignInAsAuthor =>
      'Zaloguj się jako autor, aby edytować ten rozdział.';

  @override
  String get blogLeaveEditorTitle => 'Wyjść bez zapisywania?';

  @override
  String get blogLeaveEditorMessage =>
      'Niezapisane zmiany zostaną utracone. Ostatnio zapisany rozdział pozostanie.';

  @override
  String get blogLeaveEditor => 'Wyjdź z edytora';

  @override
  String get blogEditorPreviewTitle => 'Podgląd rozdziału';

  @override
  String get blogEditorTitle => 'Twój następny rozdział';

  @override
  String get blogEditorHeadline => 'Trochę więcej Ciebie.';

  @override
  String get blogEditorIntro =>
      'Małe historie są mile widziane. Posiłek przygotowany własnoręcznie. Miejsce, które zmieniło Twoje zdanie. Zdjęcie, za którym kryje się historia.';

  @override
  String get blogNotSavedDefault => 'Nie zapisano · Domyślnie „Tylko ja”';

  @override
  String blogSavedFor(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Zapisano jako „Tylko ja”',
      'friends': 'Zapisano dla znajomych',
      'community': 'Zapisano dla społeczności Connect',
      'other': 'Zapisano',
    });
    return '$_temp0';
  }

  @override
  String get blogKeepWriting => 'Pisz dalej';

  @override
  String get blogPreview => 'Podgląd';

  @override
  String get blogCheckSavedVersion => 'Sprawdź zapisaną wersję';

  @override
  String blogPreviewNotSaved(String audience) {
    return 'Podgląd · $audience · Jeszcze nie zapisano';
  }

  @override
  String get blogStoryPlaceholder => 'Tu pojawi się Twoja historia.';

  @override
  String get blogChapterTitleLabel => 'Tytuł rozdziału';

  @override
  String get blogChapterTitleHint => 'Niedziela, w którą nauczyłem się zwolnić';

  @override
  String get blogStoryLabel => 'Twoja historia';

  @override
  String get blogStoryHint => 'Zacznij od czegokolwiek. Niech będzie Twoja.';

  @override
  String get blogInvitationLabel => 'Zakończ zaproszeniem (opcjonalnie)';

  @override
  String get blogInvitationHelp =>
      'Zostaw pytanie, które pomoże komuś Cię poznać.';

  @override
  String get blogRemovePhoto => 'Usuń zdjęcie';

  @override
  String get blogAddPhoto => 'Dodaj zdjęcie';

  @override
  String get blogPhotoRules =>
      'Do 6 zdjęć JPEG lub PNG, po 10 MB każde. Zdjęcia wymagają zatwierdzenia. Przed zmianą zdjęć w opublikowanym rozdziale zapisz go jako „Tylko ja”.';

  @override
  String get blogWhoFor => 'Dla kogo jest ten rozdział?';

  @override
  String get blogAudiencePrivateHelp =>
      'Tylko Ty możesz przeczytać ten rozdział. Znajomi i dopasowania go nie widzą.';

  @override
  String get blogAudienceFriendsHelp =>
      'Mogą go czytać tylko Twoi znajomi w Connect. Samo dopasowanie nie daje dostępu.';

  @override
  String get blogAudienceCommunityHelp =>
      'Mogą go czytać zalogowani, uprawnieni członkowie. Aby tu publikować, uzupełnij profil o dwa zatwierdzone zdjęcia profilowe. To nie jest publiczne udostępnianie w sieci.';

  @override
  String get blogAllowFeaturing => 'Zezwól na wyróżnienie';

  @override
  String get blogAllowFeaturingHelp =>
      'Jeśli rozdział spodoba się czytelnikom, może trafić na tablice innych: 50 polubień i 5 komentarzy to 50 tablic, 100 polubień i 10 komentarzy to 100. Możesz to w każdej chwili wyłączyć.';

  @override
  String get blogSaveOnlyForMe => 'Zapisz tylko dla mnie';

  @override
  String blogPublishTo(String audience) {
    String _temp0 = intl.Intl.selectLogic(audience, {
      'private': 'Opublikuj jako „Tylko ja”',
      'friends': 'Opublikuj dla znajomych',
      'community': 'Opublikuj w społeczności Connect',
      'other': 'Opublikuj',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveAsOnlyMe => 'Zapisz jako „Tylko ja”';

  @override
  String get blogSaveNote =>
      'Twoje słowa zapisują się, gdy wybierzesz Zapisz lub Opublikuj. Podgląd niczego nie publikuje.';

  @override
  String get blogTopicOptional => 'Temat (opcjonalnie)';

  @override
  String get blogTopicHelp =>
      'Pomóż zainteresowanym czytelnikom znaleźć Twój rozdział.';

  @override
  String get webDestBlog => 'Blog';

  @override
  String get webDestFirstChapter => 'Studio Pierwszy rozdział';

  @override
  String get webDestDatingPreferences => 'Preferencje randkowe';

  @override
  String get webDestEditProfile => 'Edytuj profil';

  @override
  String get webDestProfilePhotos => 'Zdjęcia profilowe';

  @override
  String get webDestLikedYou => 'Polubili cię';

  @override
  String get webDestNotifications => 'Powiadomienia';

  @override
  String get webDestDailyPrompt => 'Pytanie dnia';

  @override
  String get webDestLevels => 'Poziomy i postępy';

  @override
  String get webDestTrustBadges => 'Odznaki zaufania';

  @override
  String get webDestTrustFilters => 'Filtry zaufania';

  @override
  String get webDestIcebreakers => 'Przełamywacze lodów';

  @override
  String get webDestCircleChallenges => 'Wyzwania kręgu';

  @override
  String get webDestCoffeePolls => 'Kawowe ankiety';

  @override
  String get webDestGroups => 'Grupy';

  @override
  String get webDestRooms => 'Pokoje rozmów';

  @override
  String get webDestMatchNudges => 'Szturchnięcia dopasowań';

  @override
  String get webDestFriends => 'Znajomi';

  @override
  String get webDestDatePlans => 'Plany randek';

  @override
  String get webDestCallHistory => 'Historia połączeń';

  @override
  String get webDestMembership => 'Członkostwo';

  @override
  String get webDestVerification => 'Weryfikacja';

  @override
  String get webDestPrivacySafety => 'Prywatność i bezpieczeństwo';

  @override
  String get webDestAccountData => 'Konto i dane';

  @override
  String get webDestBlockedMembers => 'Zablokowani członkowie';

  @override
  String get webDestEmergencyContacts => 'Kontakty alarmowe';

  @override
  String get webDestModerationAppeals => 'Odwołania od moderacji';

  @override
  String get webDestNotificationPreferences => 'Ustawienia powiadomień';

  @override
  String get webDestHelpSupport => 'Pomoc i wsparcie';

  @override
  String get webNavExplore => 'Odkrywaj';

  @override
  String get webNavMyProfile => 'Mój profil';

  @override
  String get webNavAllFeatures => 'Wszystkie funkcje';

  @override
  String get webNavMoreForYou => 'Więcej dla ciebie';

  @override
  String get webNavPreferences => 'Preferencje';

  @override
  String get webNavWebsite => 'Strona Connect';

  @override
  String get webNavSignOut => 'Wyloguj się';

  @override
  String get webPageNotFound => 'Nie znaleziono tej strony.';

  @override
  String get webBackToDiscover => 'Wróć do Odkrywania';

  @override
  String get webTagline => 'Twoje tempo. Twój wybór.';

  @override
  String webUnavailableTitle(String label) {
    return '$label nie jest jeszcze dostępne.';
  }

  @override
  String get webUnavailableBody => 'Nie jest częścią tej wersji Connect.';

  @override
  String get webDirectoryTitle => 'Urządź tę przestrzeń po swojemu.';

  @override
  String get webDirectorySubtitle =>
      'Twój profil, rozmowy, społeczność i ustawienia — wszystko w jednym miejscu.';

  @override
  String get webIcebreakerTitle => 'Pomysły na rozmowę';

  @override
  String get webIcebreakerHeadline => 'Trochę inspiracji na kolejne „cześć”.';

  @override
  String get webIcebreakerBody =>
      'Nagrywanie i odtwarzanie głosu nie są jeszcze dostępne. Możesz użyć tych podpowiedzi w dozwolonej rozmowie.';

  @override
  String get webIcebreakerOpenMatches => 'Otwórz moje dopasowania';

  @override
  String get webMembershipHeadline => 'Trochę więcej możliwości.';

  @override
  String get webMembershipIntro =>
      'Poznaj aktualne plany. Płatność w przeglądarce nie jest jeszcze dostępna. Na tej stronie nie można niczego kupić ani obciążyć.';

  @override
  String webMembershipCurrent(String plan) {
    return 'Twoje członkostwo: $plan';
  }

  @override
  String webMembershipStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get webMembershipMonthly => 'Miesięcznie';

  @override
  String get webMembershipYearly => 'Rocznie';

  @override
  String get webMembershipFree => 'Za darmo';

  @override
  String webMembershipPrice(String price, String cycle) {
    String _temp0 = intl.Intl.selectLogic(cycle, {
      'yearly': 'rok',
      'other': 'miesiąc',
    });
    return '$price / $_temp0';
  }

  @override
  String get webMembershipFootnote =>
      'Ceny w katalogu to podgląd. Członkostwo nigdy nie omija granic innej osoby ani zasad dostępu do rozmowy.';

  @override
  String get blogLinkCopied => 'Link skopiowany. Udostępnij go, gdzie chcesz.';

  @override
  String get blogYourPublicLink => 'Twój publiczny link';

  @override
  String get blogShareUnconfirmed =>
      'Nie udało się potwierdzić udostępnienia. Sprawdź „Udostępnione linki”, zanim spróbujesz ponownie.';

  @override
  String get blogSignInAgain => 'Zaloguj się ponownie, aby kontynuować.';

  @override
  String get blogSharedJournalPage => 'Wspólna strona dziennika';

  @override
  String get blogYourPublicPreview => 'Twój publiczny podgląd';

  @override
  String get blogShareJointHeadline =>
      'Historia, którą oboje chcecie się podzielić.';

  @override
  String get blogShareSoloHeadline => 'Małe okno na Twój świat.';

  @override
  String get blogShareJointBody =>
      'Oboje autorzy muszą zatwierdzić dokładnie te słowa, zanim link zadziała. Każde z was może go wycofać.';

  @override
  String get blogShareSoloBody =>
      'Każdy, kto ma link, może bez konta przeczytać wybrane słowa i zobaczyć zdjęcia. Cały rozdział zostaje w Connect.';

  @override
  String get blogShareIdentityNote =>
      'Nie dodajemy profilu ani nazwy konta. Twoje słowa i zdjęcia mogą jednak pozwolić rozpoznać osoby lub miejsca. Publikuj tylko to, co możesz udostępnić.';

  @override
  String get blogExcerptLabel => 'Dokładny fragment rozdziału';

  @override
  String blogIncludePhoto(String description) {
    return 'Dołącz: $description';
  }

  @override
  String get blogApproveCopy => 'Zatwierdzam dokładnie tę publiczną kopię';

  @override
  String get blogApproveCopyNote =>
      'Edycja lub ukrycie rozdziału źródłowego unieważnia link. Kopii zapisanych poza Connect nie da się wycofać.';

  @override
  String get blogSaving => 'Zapisywanie…';

  @override
  String get blogRequestOtherApproval => 'Poproś drugiego autora o zgodę';

  @override
  String get blogCreatePublicLink => 'Utwórz publiczny link';

  @override
  String get blogJointApprovalRecorded =>
      'Twoja zgoda została zapisana. Link pozostanie niedostępny, dopóki drugi autor jej nie wyrazi.';

  @override
  String get blogPublicCopyReady => 'Twoja publiczna kopia jest gotowa.';

  @override
  String get blogCopyPublicLink => 'Kopiuj publiczny link';

  @override
  String get blogManageSharedLinks => 'Zarządzaj udostępnionymi linkami';

  @override
  String blogFollowerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obserwującego',
      many: '$count obserwujących',
      few: '$count obserwujących',
      one: '1 obserwujący',
    );
    return '$_temp0';
  }

  @override
  String get blogUnfollowFailed =>
      'Nie udało się teraz przestać obserwować. Spróbuj ponownie.';

  @override
  String get blogFollowFailed =>
      'Nie udało się teraz zaobserwować tego autora. Spróbuj ponownie.';

  @override
  String get blogFollowingButton => 'Obserwujesz';

  @override
  String get blogFollowTheirChapters => 'Obserwuj rozdziały';

  @override
  String get blogRewardsIntro =>
      'Gdy to, czym się dzielisz, kogoś poruszy, to się liczy. Polubienia czytelników, zatwierdzone komentarze i nowi obserwujący dają Ci XP do poziomu. Nagrody wynikają z działań czytelników, nigdy z samego stukania, i każdą dostajesz tylko raz.';

  @override
  String blogRewardDailyCap(int cap) {
    return 'Do $cap XP dziennie';
  }

  @override
  String blogRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String get blogSignInWriters =>
      'Zaloguj się, aby zobaczyć obserwowanych autorów.';

  @override
  String get blogWritersLoadFailed =>
      'Nie udało się wczytać obserwowanych autorów.';

  @override
  String get blogNoWriters => 'Brak autorów.';

  @override
  String get blogNoWritersBody =>
      'Gdy rozdział Cię poruszy, stuknij w nim „Obserwuj rozdziały”. Nowe rozdziały będą się zbierać w „Obserwowanych”.';

  @override
  String blogLatest(String title) {
    return 'Najnowszy: $title';
  }

  @override
  String get blogReactionFailed =>
      'Reakcja nie została wysłana. Spróbuj ponownie.';

  @override
  String blogCannotLikeOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Nie możesz polubić własnego zdjęcia',
      'other': 'Nie możesz polubić własnego rozdziału',
    });
    return '$_temp0';
  }

  @override
  String blogYouReacted(String reaction) {
    return 'Twoja reakcja: $reaction. Stuknij, aby cofnąć';
  }

  @override
  String blogLikeThis(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Polub to zdjęcie',
      'other': 'Polub ten rozdział',
    });
    return '$_temp0';
  }

  @override
  String blogCannotReactOwn(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Nie możesz zareagować na własne zdjęcie',
      'other': 'Nie możesz zareagować na własny rozdział',
    });
    return '$_temp0';
  }

  @override
  String get blogReactTooltip => 'Reaguj: Słyszę Cię, Ja też, Przytulam…';

  @override
  String blogCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count komentarza',
      many: '$count komentarzy',
      few: '$count komentarze',
      one: '1 komentarz',
    );
    return '$_temp0';
  }

  @override
  String blogWaitingForYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '· $count czeka na Ciebie',
      many: '· $count czeka na Ciebie',
      few: '· $count czekają na Ciebie',
      one: '· $count czeka na Ciebie',
    );
    return '$_temp0';
  }

  @override
  String get blogFeatured => 'Wyróżnione';

  @override
  String blogTierNeedsBoth(int likes, int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes polubienia',
      many: '$likes polubień',
      few: '$likes polubienia',
      one: '1 polubienie',
    );
    String _temp1 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments komentarza',
      many: '$comments komentarzy',
      few: '$comments komentarze',
      one: '1 komentarz',
    );
    String _temp2 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls tablicy',
      many: '$walls tablic',
      few: '$walls tablic',
      one: '1 tablicy',
    );
    return 'Jeszcze $_temp0 i $_temp1, by dotrzeć do $_temp2';
  }

  @override
  String blogTierNeedsLikes(int likes, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      likes,
      locale: localeName,
      other: '$likes polubienia',
      many: '$likes polubień',
      few: '$likes polubienia',
      one: '1 polubienie',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls tablicy',
      many: '$walls tablic',
      few: '$walls tablic',
      one: '1 tablicy',
    );
    return 'Jeszcze $_temp0, by dotrzeć do $_temp1';
  }

  @override
  String blogTierNeedsComments(int comments, int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      comments,
      locale: localeName,
      other: '$comments komentarza',
      many: '$comments komentarzy',
      few: '$comments komentarze',
      one: '1 komentarz',
    );
    String _temp1 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: '$walls tablicy',
      many: '$walls tablic',
      few: '$walls tablic',
      one: '1 tablicy',
    );
    return 'Jeszcze $_temp0, by dotrzeć do $_temp1';
  }

  @override
  String blogTierAlmostThere(int walls) {
    String _temp0 = intl.Intl.pluralLogic(
      walls,
      locale: localeName,
      other: 'Już prawie: następnie $walls tablicy',
      many: 'Już prawie: następnie $walls tablic',
      few: 'Już prawie: następnie $walls tablice',
      one: 'Już prawie: następnie 1 tablica',
    );
    return '$_temp0';
  }

  @override
  String blogOnWalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Na $count tablicy',
      many: 'Na $count tablicach',
      few: 'Na $count tablicach',
      one: 'Na 1 tablicy',
    );
    return '$_temp0';
  }

  @override
  String blogProgressToward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Postęp do $count tablicy',
      many: 'Postęp do $count tablic',
      few: 'Postęp do $count tablic',
      one: 'Postęp do 1 tablicy',
    );
    return '$_temp0';
  }

  @override
  String get blogReachIdle =>
      'Czytelnicy mogą sprawić, że ten rozdział zajdzie dalej';

  @override
  String get blogReachLive =>
      'Czytają go teraz osoby, które pokochały podobne historie.';

  @override
  String get blogFeaturedStories => 'Wyróżnione historie';

  @override
  String get blogFeaturedCaption =>
      'Historie, które pokochali inni, dostarczone na Twoją tablicę.';

  @override
  String blogByAuthor(String name) {
    return 'autor: $name';
  }

  @override
  String get blogLikes => 'Polubienia';

  @override
  String get blogComments => 'Komentarze';

  @override
  String get blogCommentHint => 'Co zostało z Tobą?';

  @override
  String get blogCommentApproved =>
      'Zatwierdzono. Teraz widzi go każdy, kto może czytać ten rozdział.';

  @override
  String get blogCommentSent => 'Wysłano do autora do zatwierdzenia';

  @override
  String get blogCommentSendFailed =>
      'Komentarz nie został wysłany. Twoje słowa wciąż tu są, możesz spróbować ponownie.';

  @override
  String blogCommentDeclined(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Odrzucono. Nie pojawi się przy Twoim zdjęciu.',
      'other': 'Odrzucono. Nie pojawi się przy Twoim rozdziale.',
    });
    return '$_temp0';
  }

  @override
  String get blogSaveFailed => 'Nie udało się zapisać. Spróbuj ponownie.';

  @override
  String get blogDeleteCommentTitle => 'Usunąć ten komentarz?';

  @override
  String get blogDeleteCommentMessage =>
      'Zostanie usunięty dla wszystkich. Tego nie można cofnąć.';

  @override
  String get blogDeleteComment => 'Usuń komentarz';

  @override
  String get blogCommentDeleted => 'Komentarz usunięty.';

  @override
  String get blogCommentDeleteFailed =>
      'Nie udało się usunąć komentarza. Spróbuj ponownie.';

  @override
  String get blogCommentsAuthorNote =>
      'Nowe komentarze czekają na Twoje zatwierdzenie, zanim zobaczą je inni.';

  @override
  String get blogCommentsReaderNote =>
      'Autor najpierw czyta każdy komentarz i wybiera, co udostępnić.';

  @override
  String get blogLeaveComment => 'Zostaw komentarz';

  @override
  String get blogSendToAuthor => 'Wyślij do autora';

  @override
  String get blogCommentsLoadFailed => 'Nie udało się wczytać komentarzy.';

  @override
  String get blogWaitingApproval => 'Czekają na Twoje zatwierdzenie';

  @override
  String get blogNoCommentsInvite =>
      'Brak komentarzy. Napisz coś miłego, aby zacząć rozmowę.';

  @override
  String get blogNoCommentsShared => 'Nie udostępniono jeszcze komentarzy.';

  @override
  String get blogCommentNotShared =>
      'Autor postanowił nie udostępniać tego komentarza.';

  @override
  String get blogYou => 'Ty';

  @override
  String get blogCommentOptions => 'Opcje komentarza';

  @override
  String get blogReportComment => 'Zgłoś komentarz';

  @override
  String get blogApprove => 'Zatwierdź';

  @override
  String get blogDecline => 'Odrzuć';

  @override
  String get blogSignInContinue => 'Zaloguj się, aby kontynuować.';

  @override
  String get blogPrivateResponseTitle => 'Prywatna odpowiedź';

  @override
  String blogPrivateResponseHelp(String invitation) {
    return '$invitation\n\nTę odpowiedź otrzyma tylko autor. Może przyjąć lub odrzucić opcjonalną wymianę. Do pięciu nowych odpowiedzi dziennie i jedna do tego samego autora.';
  }

  @override
  String get blogSendPrivateResponse => 'Wyślij prywatną odpowiedź';

  @override
  String get blogTextSaveUnconfirmed =>
      'Nie udało się potwierdzić zapisu. Twoje słowa wciąż tu są; spróbuj ponownie lub odśwież zapisaną wymianę.';

  @override
  String get blogLeaveUnsentTitle => 'Wyjść bez wysyłania?';

  @override
  String get blogLeaveUnsentMessage => 'Niewysłany tekst zostanie odrzucony.';

  @override
  String get blogLeave => 'Wyjdź';

  @override
  String get blogOwnWordsLabel => 'Własnymi słowami';

  @override
  String get blogSending => 'Wysyłanie…';

  @override
  String get blogChangeUnconfirmed =>
      'Nie udało się potwierdzić zmiany. Odśwież, aby sprawdzić.';

  @override
  String get blogConnectionsTitle => 'Twoje powiązania z rozdziałów';

  @override
  String get blogRefresh => 'Odśwież';

  @override
  String get blogConnectionsIntro =>
      'Dobre historie zostawiają miejsce dla kogoś jeszcze.';

  @override
  String get blogConnectionsLoadFailed =>
      'Nie udało się wczytać Twoich powiązań.';

  @override
  String get blogResponsesEmpty =>
      'Tu pojawią się odpowiedzi na Twoje rozdziały i te, które wyślesz. Nic nie wymaga natychmiastowej odpowiedzi.';

  @override
  String get blogPublicationsEmpty =>
      'Tu pojawią się Twoje publiczne podglądy i wspólnie zatwierdzone linki.';

  @override
  String get blogNoticesEmpty => 'Brak powiadomień o weryfikacji.';

  @override
  String get blogResponseRevealed => 'Wasz wspólny rozdział jest gotowy';

  @override
  String get blogResponseIncoming => 'Odpowiedź dla Ciebie';

  @override
  String get blogResponseSent => 'Wysłano · ich wybór, ich tempo';

  @override
  String get blogResponseAccepted => 'Wymiana w waszym tempie';

  @override
  String get blogResponseClosed => 'Ta wymiana jest zamknięta';

  @override
  String get blogOpenExchange => 'Otwórz prywatną wymianę';

  @override
  String get blogPublicationLive => 'Publiczna kopia aktywna';

  @override
  String get blogPublicationRemoved => 'Usunięte przez moderację';

  @override
  String get blogPublicationNeedsBoth =>
      'Wymaga obu zgód i aktualnego rozdziału źródłowego';

  @override
  String get blogPublicationSourceChanged =>
      'Źródło zmienione · utwórz nowy podgląd, aby udostępnić ponownie';

  @override
  String get blogApprovePublicCopyTitle => 'Zatwierdzić tę publiczną kopię?';

  @override
  String get blogApprovePublicCopyMessage =>
      'Dokładnie te słowa będą dostępne dla każdego, kto ma link. Każde z was może wycofać udostępnienie. Imiona nie są dodawane automatycznie, ale słowa mogą pozwolić Cię rozpoznać.';

  @override
  String get blogApprovePublicCopyAction => 'Zatwierdź publiczną kopię';

  @override
  String get blogApproveExactPublicCopy => 'Zatwierdź dokładną publiczną kopię';

  @override
  String get blogCopyLink => 'Kopiuj link';

  @override
  String get blogWithdrawLinkTitle => 'Wycofać ten link?';

  @override
  String get blogWithdrawLinkMessage =>
      'Publiczna kopia stanie się niedostępna. Kopii zapisanych już przez inne osoby nie da się wycofać.';

  @override
  String get blogWithdrawLink => 'Wycofaj link';

  @override
  String get blogYourAppeal => 'Twoje odwołanie';

  @override
  String get blogRequestReview => 'Poproś o ponowną weryfikację';

  @override
  String get blogRequestReviewHelp =>
      'Wyjaśnij, co należy ponownie rozważyć. Odwołanie trafi prywatnie do zespołu ds. zaufania. Usunięta treść pozostaje ukryta podczas weryfikacji.';

  @override
  String get blogSubmitAppeal => 'Wyślij odwołanie';

  @override
  String get blogAppealDecision => 'Odwołaj się od tej decyzji';

  @override
  String get blogPrevious => 'Poprzednie';

  @override
  String get blogMore => 'Więcej';

  @override
  String get blogExchangeChangeFailed =>
      'Nie udało się potwierdzić tej zmiany. Odśwież i spróbuj ponownie.';

  @override
  String get blogExchangeTitle => 'Prywatna wymiana rozdziałów';

  @override
  String get blogExchangeUnavailable => 'Ta wymiana nie jest już dostępna.';

  @override
  String blogExchangeWith(String name) {
    return 'Z: $name';
  }

  @override
  String get blogExchangeIntro =>
      'Odpowiedź to zaproszenie, nigdy obowiązek. Ta wymiana nie tworzy dopasowania ani nie odblokowuje czatu.';

  @override
  String get blogAcceptExchange => 'Przyjmij wymianę';

  @override
  String get blogDeclineKindly => 'Grzecznie odmów';

  @override
  String get blogResponseSentNote =>
      'Twoja odpowiedź została wysłana. Nie ma odliczania ani potrzeby przypominania się.';

  @override
  String get blogExchangeClosedNote =>
      'Ta wymiana jest zamknięta. W swoim tempie zrób miejsce na nową znajomość.';

  @override
  String get blogOneStoryEach => 'Każde po jednej małej historii.';

  @override
  String get blogOneStoryEachBody =>
      'Dodaj krótką kontynuację, wspomnienie lub swoją wersję tej chwili. Oba wpisy pojawią się razem, dopiero gdy obie osoby je wyślą.';

  @override
  String get blogYourSideTitle => 'Twoja część rozdziału';

  @override
  String get blogYourSideHelp =>
      'Do 1000 znaków. Druga osoba nie przeczyta tego, dopóki sama czegoś nie doda. Po wysłaniu tekstu nie można edytować; wymianę możesz wycofać w dowolnym momencie.';

  @override
  String get blogSubmitContribution => 'Wyślij mój wpis';

  @override
  String get blogAddContribution => 'Dodaj mój wpis';

  @override
  String get blogYourContribution => 'Twój wpis';

  @override
  String blogPartnerContribution(String name) {
    return 'Wpis: $name';
  }

  @override
  String get blogShapeDate => 'Zaplanujcie razem randkę';

  @override
  String get blogInspiredNote => 'Zainspirowane naszą wymianą rozdziałów.';

  @override
  String get blogTryStudio => 'Wypróbuj Studio Pierwszego Rozdziału';

  @override
  String get blogDatePlanningUnavailable =>
      'Planowanie randki będzie dostępne, gdy będziecie mieć aktywne dopasowanie i odblokowaną rozmowę.';

  @override
  String get blogProposeJournalPage => 'Zaproponuj wspólną stronę dziennika';

  @override
  String get blogSourceUnavailable => 'Rozdział źródłowy jest niedostępny.';

  @override
  String get blogContributionSaved =>
      'Twój wpis został zapisany prywatnie. Odsłonięcie nastąpi, gdy oboje będziecie gotowi.';

  @override
  String get blogWithdrawExchangeTitle => 'Wycofać tę wymianę?';

  @override
  String get blogWithdrawExchangeMessage =>
      'Odpowiedź i wpisy przestaną być dostępne dla was obojga. Wspólne publiczne linki również przestaną działać.';

  @override
  String get blogWithdrawExchange => 'Wycofaj wymianę';

  @override
  String get blogReportExchange => 'Zgłoś wymianę';

  @override
  String get blogBlockMessageExchange =>
      'Kontakt i dostęp do waszych rozdziałów zostaną zablokowane.';

  @override
  String get blogBlockFailed => 'Nie udało się zablokować tej osoby.';

  @override
  String get notificationsReadAll => 'Oznacz wszystkie';

  @override
  String get notificationsFallbackTitle => 'Powiadomienie';

  @override
  String get notificationsLoadFailed => 'Nie udało się wczytać powiadomień.';

  @override
  String get notificationsPrefsUpdateFailed =>
      'Nie udało się zaktualizować ustawień powiadomień.';

  @override
  String notificationsAgoMinutes(int count) {
    return '$count min temu';
  }

  @override
  String notificationsAgoHours(int count) {
    return '$count godz. temu';
  }

  @override
  String notificationsAgoDays(int count) {
    return '$count dni temu';
  }

  @override
  String get wallsReactEyebrow => 'REAKCJA';

  @override
  String wallsReactQuestion(String noun) {
    String _temp0 = intl.Intl.selectLogic(noun, {
      'photo': 'Jakie uczucia budzi w tobie to zdjęcie?',
      'other': 'Jakie uczucia budzi w tobie ten rozdział?',
    });
    return '$_temp0';
  }

  @override
  String get wallsReactBody =>
      'Twoja reakcja pokazuje, że zostali wysłuchani. Każda reakcja liczy się jako polubienie.';

  @override
  String get wallsReactRemove => 'Cofnij moją reakcję';

  @override
  String wallsReactionsSemantics(String list) {
    return 'Reakcje: $list';
  }

  @override
  String get wallsReactionLove => 'Uwielbiam';

  @override
  String get wallsReactionHearYou => 'Słyszę cię';

  @override
  String get wallsReactionMeToo => 'Ja też';

  @override
  String get wallsReactionWithYou => 'Jestem z tobą';

  @override
  String get wallsReactionHug => 'Przesyłam uścisk';

  @override
  String get wallsReactionProud => 'Dumny z ciebie';

  @override
  String get wallsSignInRequired => 'Zaloguj się, aby zobaczyć swoją ścianę.';

  @override
  String get celebrationCoverHeadline => 'Twoje zdjęcie jest okładką tygodnia';

  @override
  String celebrationReachHeadline(String kind, int reach) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'photo': 'Twoje zdjęcie trafiło na ściany: $reach',
      'other': 'Twój rozdział trafił na ściany: $reach',
    });
    return '$_temp0';
  }

  @override
  String get celebrationCoverMessage =>
      'Członkowie to pokochali. W tym tygodniu wszyscy widzą to w Dziś.';

  @override
  String get celebrationReachMessage =>
      'Członkowie to pokochali. Teraz jest na ich ścianach Dziś.';

  @override
  String celebrationQuotedTitle(String title) {
    return '„$title”';
  }

  @override
  String get celebrationBarrier => 'Świętowanie';

  @override
  String get celebrationLovely => 'Cudownie';

  @override
  String get celebrationSeePhoto => 'Zobacz zdjęcie';

  @override
  String get celebrationSeeChapter => 'Zobacz rozdział';

  @override
  String rewardXpPill(int xp) {
    return '+$xp XP';
  }

  @override
  String get rewardClaimedTitle => 'Nagroda odebrana';

  @override
  String rewardNameDescription(String name, String description) {
    return '$name · $description';
  }

  @override
  String rewardPlusXpAnnouncement(int xp) {
    return 'plus $xp XP';
  }

  @override
  String rewardSourceXpLine(String source, int xp) {
    return '$source +$xp XP';
  }

  @override
  String rewardAndMore(int count) {
    return 'i jeszcze $count';
  }

  @override
  String rewardBadgeLine(String badge) {
    return 'Odznaka: $badge';
  }

  @override
  String rewardLevelReached(int level) {
    return 'Osiągnięto poziom $level';
  }

  @override
  String rewardBadgesEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zdobyto $count odznak',
      few: 'Zdobyto $count odznaki',
      one: 'Zdobyto odznakę',
    );
    return '$_temp0';
  }

  @override
  String get rewardYourRewardsToday => 'Twoje dzisiejsze nagrody';

  @override
  String rewardNewRewards(int count) {
    return 'Nowe nagrody: $count';
  }

  @override
  String get rewardSourceStoryPublished => 'Rozdział opublikowany';

  @override
  String get rewardSourcePhotoShared => 'Zdjęcie udostępnione';

  @override
  String get rewardSourceLikeReceived => 'Komuś spodobała się twoja praca';

  @override
  String get rewardSourceCommentReceived => 'Nowy komentarz do twojej pracy';

  @override
  String get rewardSourceCommentApproved =>
      'Twój komentarz został zatwierdzony';

  @override
  String get rewardSourceSubscriberGained => 'Nowy subskrybent';

  @override
  String get rewardSourceWallTierReached => 'Osiągnięto poziom ściany';

  @override
  String get rewardSourceCoverOfWeek => 'Okładka tygodnia';

  @override
  String get rewardSourceDailyPromptSubmitted =>
      'Odpowiedziano na pytanie dnia';

  @override
  String get rewardLineStoryPublished => 'Twój rozdział trafił w świat.';

  @override
  String get rewardLinePhotoShared => 'Twoje zdjęcie dołączyło do motywu.';

  @override
  String get rewardLineLikeReceived =>
      'Ktoś pokochał to, czym się podzieliłeś.';

  @override
  String get rewardLineCommentReceived => 'Czytelnik dołączył do rozmowy.';

  @override
  String get rewardLineSubscriberGained =>
      'Ktoś czeka na twój kolejny rozdział.';

  @override
  String get rewardLineWallTierReached =>
      'Twoja praca trafiła na więcej ścian.';

  @override
  String get rewardLineCoverOfWeek => 'W tym tygodniu wszyscy widzą to w Dziś.';

  @override
  String get rewardLineOther => 'Zdobyte za wartościową aktywność.';

  @override
  String get rewardNewBadgeFallback => 'Nowa odznaka';

  @override
  String get blockedUnknownUser => 'Nieznany użytkownik';

  @override
  String get themeTaglineBluerose =>
      'Północny aksamit, szafirowe róże i platynowa krawędź.';

  @override
  String get themeTaglineBluelotus =>
      'Woda w blasku księżyca, szafirowe płatki i złote serce.';

  @override
  String discoverMessageLikeSent(String name) {
    return 'Wysłano love do: $name. Porozmawiacie, gdy $name odwzajemni polubienie.';
  }

  @override
  String get notificationsDismissFailed =>
      'Nie udało się usunąć powiadomienia. Spróbuj ponownie.';

  @override
  String get notificationsReadAllFailed =>
      'Nie udało się oznaczyć wszystkich jako przeczytane. Spróbuj ponownie.';

  @override
  String get blogReportSubmitted => 'Zgłoszenie wysłane. Dziękujemy.';

  @override
  String get settingsSectionAccount => 'Konto';

  @override
  String settingsSignedInAs(String username) {
    return 'Zalogowano jako @$username';
  }

  @override
  String get settingsSignOut => 'Wyloguj się';

  @override
  String get settingsSignOutSubtitle => 'Zakończ sesję na tym urządzeniu';

  @override
  String get settingsSignOutAllTitle => 'Wyloguj się ze wszystkich urządzeń';

  @override
  String get settingsSignOutAllSubtitle =>
      'Zakończ wszystkie sesje na każdym telefonie i w każdej przeglądarce';

  @override
  String get settingsSignOutConfirmTitle => 'Wylogować się?';

  @override
  String get settingsSignOutConfirmBody =>
      'Aby ponownie zalogować się na tym urządzeniu, potrzebujesz nazwy użytkownika i hasła.';

  @override
  String get settingsSignOutAllConfirmTitle =>
      'Wylogować się ze wszystkich urządzeń?';

  @override
  String get settingsSignOutAllConfirmBody =>
      'Twoja sesja zakończy się na każdym telefonie, tablecie i w każdej przeglądarce, także na tym urządzeniu. Każdy, kto jest zalogowany na Twoje konto gdzie indziej, zostanie wylogowany.';

  @override
  String get settingsSignOutAllConfirmAction => 'Wyloguj się wszędzie';

  @override
  String get settingsSignOutAllFailed =>
      'Nie udało się wylogować innych urządzeń. Sprawdź połączenie i spróbuj ponownie.';
}
