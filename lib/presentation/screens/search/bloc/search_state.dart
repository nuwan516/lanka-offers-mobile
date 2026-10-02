import 'package:equatable/equatable.dart';
import '../../../../domain/entities/bank_offer.dart';

abstract class SearchState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  final List<String> recentSearches;
  final List<String> popularSearches;

  SearchInitial({
    this.recentSearches = const [],
    this.popularSearches = const [],
  });

  @override
  List<Object?> get props => [recentSearches, popularSearches];
}

class SearchLoading extends SearchState {}

class SearchResultsLoaded extends SearchState {
  final List<BankOffer> results;
  final String query;

  SearchResultsLoaded({required this.results, required this.query});

  @override
  List<Object?> get props => [results, query];
}

class SearchError extends SearchState {
  final String message;
  SearchError({required this.message});
  @override
  List<Object?> get props => [message];
}
