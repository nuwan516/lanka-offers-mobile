import 'package:flutter/foundation.dart';

/// The Explore tab's sections.
enum ExploreSegment { browse, nearby, banks }

/// A request to switch to the Explore tab, optionally on a given section and
/// with a bank pre-selected. Screens publish it; the main navigation consumes
/// it, so the screens need no reference to each other.
class ExploreRequest {
  final ExploreSegment segment;
  final String? bankCode;
  final String? category;
  final String? scope;

  const ExploreRequest({
    this.segment = ExploreSegment.browse,
    this.bankCode,
    this.category,
    this.scope,
  });
}

class TabNavigation {
  TabNavigation._();

  /// Set to ask the shell to show Explore; the shell clears it once handled.
  static final ValueNotifier<ExploreRequest?> exploreRequest =
      ValueNotifier<ExploreRequest?>(null);

  static void openExplore(ExploreRequest request) {
    exploreRequest.value = request;
  }
}
