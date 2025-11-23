import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class ScoreNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void increment(int value) => state += value;
  void decrement(int value) => state -= value;
  void set(int newValue) => state = newValue;
}
//   Regular Scoring Providers
final assemblyTrayNotifierProvider = NotifierProvider<ScoreNotifier, int>(
  ScoreNotifier.new,
);
final ovenColumnNotifierProvider = NotifierProvider<ScoreNotifier, int>(
  ScoreNotifier.new,
);
final deliveryHatchNotifierProvider = NotifierProvider<ScoreNotifier, int>(
  ScoreNotifier.new,
);

//  Match Info Providers 
final teamNumberProvider = StateProvider<String>((ref) => '');
final matchNumberProvider = StateProvider<String>((ref) => '');
final scoutNameProvider = StateProvider<String>((ref) => '');

//   Endgame Providers   
final pizza5ftProvider = StateProvider<int>((ref) => 0);
final pizza10ftProvider = StateProvider<int>((ref) => 0);
final pizza15ftProvider = StateProvider<int>((ref) => 0);
final pizza20ftProvider = StateProvider<int>((ref) => 0);

//   Penalty Providers   
final motorBurnPenaltyProvider = StateProvider<int>((ref) => 0);
final elevatorMalfunctionPenaltyProvider = StateProvider<int>((ref) => 0);
final mechanismDetachedPenaltyProvider = StateProvider<int>((ref) => 0);
final humanPlayerPenaltyProvider = StateProvider<int>((ref) => 0);
final robotOutsidePenaltyProvider = StateProvider<int>((ref) => 0);