import 'dart:async';
import 'dart:isolate';

import 'task.dart';
import 'isolate_messages.dart';
import 'helper.dart';

class Worker {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  StreamSubscription<dynamic>? _portSub;
  int _acollaborators = 0;
  int _summaryPriority = 0;
  final _results = <int, Completer<dynamic>>{};

  Future<void> initialize() async {
    final initCompleter = Completer<bool>();
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_anotherIsolate, _receivePort!.sendPort);

    _portSub = _receivePort!.listen((message) {
      if (message is ResultMessage) {
        _results[message.taskId]?.complete(message.result);
        _results.remove(message.taskId);
      } else if (message is ErrorMessage) {
        _results[message.taskId]?.completeError(
          message.error,
          message.stackTrace,
        );
        _results.remove(message.taskId);
      } else {
        _sendPort = message;
        initCompleter.complete(true);
      }
    });
    await initCompleter.future;
  }

  Future<OutT> work<ArgT, OutT>(Task<ArgT, OutT> task) {
    final completer = Completer<OutT>();
    _results[task.id] = completer;
    _summaryPriority += task.workPriority.index;
    _acollaborators += task.canCollaborationLoop.toInt();
    _sendPort?.send(WorkMessage(taskId: task.id, runnable: task.runnable));
    return completer.future.then((v) {
      _acollaborators -= task.canCollaborationLoop.toInt();
      _summaryPriority -= task.workPriority.index;
      return v;
    });
  }

  static void _anotherIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    receivePort.listen((message) async {
      final currentMessage = message as WorkMessage;
      final taskId = message.taskId;
      try {
        final function = currentMessage.runnable;
        final result = await function();
        sendPort.send(ResultMessage(taskId: taskId, result: result));
      } catch (error) {
        try {
          sendPort.send(ErrorMessage(error, taskId: taskId));
        } catch (error) {
          sendPort.send(ErrorMessage(
              'can`t send error with too big stackTrace, error is : ${error.toString()}',
              taskId: taskId));
        }
      }
    });
  }

  bool get hasCollaborations => _results.length > 1;
  bool get hasWork => _results.isNotEmpty;
  bool get canCollaboration => _acollaborators == 0;
  int get summaryPriority => _summaryPriority;

  Future<void> kill() async {
    final cancelableIsolate = _isolate;
    _isolate = null;
    await _portSub?.cancel();
    _sendPort = null;
    cancelableIsolate?.kill(priority: Isolate.immediate);
  }
}
