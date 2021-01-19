import 'dart:async';

import 'runnable.dart';
import 'work_priority.dart';

class Task<ArgT, OutT> {
  final Runnable<ArgT, OutT> runnable;
  final resultCompleter = Completer<OutT>();
  final int id;
  final WorkPriority workPriority;
  final bool canCollaborationLoop;

  Task(this.id,
      {required this.runnable,
      required this.workPriority,
      required this.canCollaborationLoop});

  int comparePriority(Task other) =>
      workPriority.index - other.workPriority.index;
}
