import 'package:test/test.dart';

import 'package:task_manager/task_manager.dart';

int fib(int n) => n <= 1 ? 1 : fib(n - 1) + fib(n - 2);

void main() async {
  final taskManager = TaskManager();
  await taskManager.initialize();
  test('sync execute', () async {
    final res = await taskManager.execute(fun: fib, arg: 8);
    expect(res, 34);
  });

  test('fib', () {
    expect(34, fib(8));
  });
}
