import 'dart:async';

enum BarbershopEvent {
  barbershopCreated,
}

class BarbershopEventBus {
  BarbershopEventBus._();

  static final BarbershopEventBus _instance = BarbershopEventBus._();
  static BarbershopEventBus get instance => _instance;

  final StreamController<BarbershopEvent> _controller =
      StreamController<BarbershopEvent>.broadcast();

  Stream<BarbershopEvent> get stream => _controller.stream;

  void emit(BarbershopEvent event) => _controller.add(event);

  void dispose() => _controller.close();
}