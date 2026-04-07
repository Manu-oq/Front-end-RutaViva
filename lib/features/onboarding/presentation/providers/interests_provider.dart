import 'package:flutter_riverpod/flutter_riverpod.dart';

class InterestsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void toggleInterest(String interest) {
    if (state.contains(interest)) {
      state = state.where((item) => item != interest).toList();
    } else {
      state = [...state, interest];
    }
  }
}

final interestsProvider =
    NotifierProvider<InterestsNotifier, List<String>>(InterestsNotifier.new);