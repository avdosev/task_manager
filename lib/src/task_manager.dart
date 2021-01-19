import 'dart:async';
import 'dart:collection';
import 'dart:html';

import 'id_generator.dart';
import 'task.dart';
import 'work_priority.dart';
import 'worker.dart';
import 'runnable.dart';
import 'helper.dart';

class TaskManager {
  final _queue = WorkPriority.values
      .asMap()
      .map((key, value) => MapEntry(value, Queue<Task>()));
  final _pool = <Worker>[];
  final _idGen = IdGenerator();

  static Future<TaskManager> initialized({required int countIsolates}) async {
    final manager = TaskManager();
    if (countIsolates <= 0) {
      throw ArgumentError.value(
          countIsolates, 'countIsolates', 'must be most 0');
    }

    for (var i = 0; i < countIsolates; i++) {
      manager._pool.add(Worker());
    }

    await manager.initialize();

    return manager;
  }

  Future<void> initialize() async {
    await Future.wait(_pool.map((iw) => iw.initialize()));
  }

  Future<OutT> execute<ArgT, OutT>(
      {required ArgT arg,
      required Fun<ArgT, OutT> fun,
      WorkPriority priority = WorkPriority.regular,
      bool collaborate = false}) {
    final taskId = _idGen.genId();
    final task = Task(taskId,
        runnable: Runnable(
          arg: arg,
          fun: fun,
        ),
        canCollaborationLoop: collaborate,
        workPriority: priority);
    if (collaborate && _collaborationReady()) {
      _schedule(task);
    } else {
      _addToQueue(task);
      _scheduleNext();
    }
    return task.resultCompleter.future;
  }

  bool _collaborationReady() =>
      _pool.any((worker) => !worker.hasWork || worker.canCollaboration);

  void _addToQueue(Task task) => _queue[task.workPriority]!.add(task);

  void _schedule(Task task) async {
    // worker with minimum summaryPriority
    final worker = _pool.reduce((worker1, worker2) =>
        worker1.summaryPriority > worker2.summaryPriority ? worker2 : worker1);

    await worker.work(task).then((result) {
      task.resultCompleter.complete(result);
    }).catchError((error) {
      task.resultCompleter.completeError(error);
    });
    _scheduleNext();
  }

  void _scheduleNext() async {
    final availableWorker = _pool.firstWhereOrNull((worker) => !worker.hasWork);
    if (availableWorker != null && queueIsNotEmpty()) {
      final task = _removeFirstTask()!;
      await availableWorker.work(task).then((result) {
        task.resultCompleter.complete(result);
      }).catchError((error) {
        task.resultCompleter.completeError(error);
      });
      _scheduleNext();
    }
  }

  bool queueIsNotEmpty() => WorkPriority.values
      .map((priority) => _queue[priority]!.isNotEmpty)
      .any((e) => e);

  Task? _removeFirstTask() {
    // from high to low
    for (var priority in WorkPriority.values.reversed) {
      final taskList = _queue[priority]!;
      if (taskList.isNotEmpty) {
        return taskList.removeFirst();
      }
    }
  }
}
