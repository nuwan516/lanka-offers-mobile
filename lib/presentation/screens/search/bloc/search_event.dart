import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;

  SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class PerformSearch extends SearchEvent {
  final String query;

  PerformSearch(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearch extends SearchEvent {}

class LoadRecentSearches extends SearchEvent {}

class LoadPopularSearches extends SearchEvent {}
