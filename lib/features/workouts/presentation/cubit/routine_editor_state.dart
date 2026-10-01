import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

/// One row in the routine editor: the chosen exercise plus its
/// prescription. [exercise] is kept so the editor can show names,
/// thumbnails and the right unit (reps vs seconds) without a lookup.
class RoutineItem extends Equatable {
  const RoutineItem({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  factory RoutineItem.fromExercise(Exercise exercise) => RoutineItem(
    exercise: exercise,
    sets: exercise.defaultSets,
    reps: exercise.defaultReps,
    restSeconds: exercise.defaultRestSeconds,
  );

  final Exercise exercise;
  final int sets;
  final int reps;
  final int restSeconds;

  RoutineItem copyWith({int? sets, int? reps, int? restSeconds}) => RoutineItem(
    exercise: exercise,
    sets: sets ?? this.sets,
    reps: reps ?? this.reps,
    restSeconds: restSeconds ?? this.restSeconds,
  );

  @override
  List<Object?> get props => <Object?>[exercise, sets, reps, restSeconds];
}

enum RoutineEditorStatus { loading, editing, saving, saved, error }

class RoutineEditorState extends Equatable {
  const RoutineEditorState({
    this.status = RoutineEditorStatus.loading,
    this.id,
    this.name = '',
    this.notes = '',
    this.items = const <RoutineItem>[],
    this.errorMessage,
    this.savedId,
  });

  final RoutineEditorStatus status;

  /// Null while creating; set when editing an existing routine.
  final String? id;
  final String name;
  final String notes;
  final List<RoutineItem> items;
  final String? errorMessage;

  /// Set once saved so the screen can navigate to the routine.
  final String? savedId;

  bool get isEditing => id != null;
  bool get canSave => name.trim().isNotEmpty && items.isNotEmpty;

  RoutineEditorState copyWith({
    RoutineEditorStatus? status,
    String? id,
    String? name,
    String? notes,
    List<RoutineItem>? items,
    String? errorMessage,
    String? savedId,
  }) {
    return RoutineEditorState(
      status: status ?? this.status,
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      errorMessage: errorMessage,
      savedId: savedId ?? this.savedId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    id,
    name,
    notes,
    items,
    errorMessage,
    savedId,
  ];
}
