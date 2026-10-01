import '../../core/widgets/connect_page.dart';

export '../../core/widgets/connect_page.dart';

/// The one ruler the Today screen is built on. Every gap and radius on the
/// page comes from here so sections line up with each other.
abstract final class TodayMetrics {
  static const double sectionGap = ConnectMetrics.sectionGap;
  static const double cardGap = ConnectMetrics.cardGap;
  static const double padding = ConnectMetrics.padding;
  static const double paddingLarge = ConnectMetrics.paddingLarge;
  static const double cardRadius = ConnectMetrics.cardRadius;

  /// Feature cards: the Blog card and the Cover of the Week.
  static const double featureRadius = ConnectMetrics.featureRadius;

  /// At or above this width Today lays the cover and the wall side by side.
  static const double wideBreakpoint = 900;
}

/// Today's section header and card are the app-wide ones in
/// `core/widgets/connect_page.dart`; these names remain for Today's code.
typedef TodaySectionHeader = ConnectSectionHeader;
typedef TodayPanel = ConnectPanel;
