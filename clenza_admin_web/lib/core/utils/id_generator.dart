class ClubIdGenerator {
  static String generate({
    required String state,    // e.g. 'KL' for Kerala
    required int sequence,    // from DB sequence or count
  }) {
    final year = DateTime.now().year;
    final seq  = sequence.toString().padLeft(5, '0');
    return 'CLB-$year-${state.toUpperCase()}-$seq';
  }
}
