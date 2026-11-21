import 'dart:async';

/// A stream that emits `load()` once on listen and again after every event
/// of [changes].
///
/// Built on a [StreamController] instead of `async*` on purpose: cancelling
/// an `async*` generator that is waiting on another stream does not finish
/// until that stream emits, so `subscription.cancel()` (and `Bloc.close()`)
/// would hang. Here cancelling is immediate.
Stream<T> reloadingStream<T>({
  required Future<T> Function() load,
  required Stream<void> changes,
}) {
  late final StreamController<T> controller;
  StreamSubscription<void>? subscription;
  Future<void> chain = Future<void>.value();

  void emitLoaded() {
    // One load after another, so results never arrive out of order.
    chain = chain.then((_) async {
      if (controller.isClosed) return;
      try {
        controller.add(await load());
      } catch (error, stack) {
        if (!controller.isClosed) controller.addError(error, stack);
      }
    });
  }

  controller = StreamController<T>(
    onListen: () {
      subscription = changes.listen((_) => emitLoaded());
      emitLoaded();
    },
    onCancel: () => subscription?.cancel(),
  );
  return controller.stream;
}
