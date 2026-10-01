import 'package:equatable/equatable.dart';

/// One body-weight measurement. Pure domain object — no Flutter.
class WeightEntry extends Equatable {
  const WeightEntry({required this.date, required this.weightKg});

  final DateTime date;
  final double weightKg;

  @override
  List<Object?> get props => [date, weightKg];
}
