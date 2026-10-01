/// Member's self-reported training level.
///
/// Used at registration and on the profile screen to tailor recommendations.
enum FitnessLevel { beginner, intermediate, advanced }

/// Human-readable labels for [FitnessLevel].
extension FitnessLevelLabel on FitnessLevel {
  String get label => switch (this) {
    FitnessLevel.beginner => 'Beginner',
    FitnessLevel.intermediate => 'Intermediate',
    FitnessLevel.advanced => 'Advanced',
  };

  /// Parses the string form stored by the data layer. Unknown values fall
  /// back to [FitnessLevel.beginner] rather than throwing.
  static FitnessLevel fromString(String? value) => switch (value) {
    'intermediate' => FitnessLevel.intermediate,
    'advanced' => FitnessLevel.advanced,
    _ => FitnessLevel.beginner,
  };
}
