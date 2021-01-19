import 'runnable.dart';

class WorkMessage {
  final int taskId;
  final Runnable runnable;

  WorkMessage({
    required this.runnable,
    required this.taskId,
  });
}

class ResultMessage {
  final int taskId;
  final Object result;

  ResultMessage({required this.result, required this.taskId});
}

class ErrorMessage {
  final int taskId;
  final Object error;
  final StackTrace? stackTrace;

  ErrorMessage(this.error, {this.stackTrace, required this.taskId});
}
