import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/bank_summary.dart';
import '../../../../domain/usecases/get_banks.dart';

enum BanksStatus { loading, loaded, failed }

class BanksState extends Equatable {
  final BanksStatus status;
  final List<BankSummary> banks;

  const BanksState({this.status = BanksStatus.loading, this.banks = const []});

  @override
  List<Object?> get props => [status, banks];
}

class BanksCubit extends Cubit<BanksState> {
  BanksCubit(this._getBanks) : super(const BanksState());

  final GetBanks _getBanks;

  Future<void> load() async {
    emit(const BanksState());
    try {
      final banks = await _getBanks();
      if (isClosed) return;
      emit(BanksState(status: BanksStatus.loaded, banks: banks));
    } catch (_) {
      if (isClosed) return;
      emit(const BanksState(status: BanksStatus.failed));
    }
  }
}
