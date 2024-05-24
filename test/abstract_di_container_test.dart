import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reg_it_abstract/reg_it_abstract.dart';

class TestRegistry implements Registry {
  final Map<Type, Registrar> _instanceMap = {};

  static final _instance = TestRegistry._();

  static TestRegistry get instance => _instance;

  @visibleForTesting
  Map<Type, Registrar> get instanceMap => _instanceMap;

  TestRegistry._();

  @override
  T get<T>() {
    try {
      final Registrar(:instance) = _instanceMap[T]!;
      return instance;
    } catch (e, st) {
      log('get error', error: e, stackTrace: st);
      throw Exception('An instance of the $T is not registered.');
    }
  }

  @override
  void put<T>(Registrar<T> registrar) {
    if (_instanceMap.containsKey(T)) {
      throw Exception('An instance of $T is already exists');
    }
    _instanceMap[T] = registrar;
  }

  @override
  void drop<T>() {
    final registrar = _instanceMap[T];
    if (registrar == null) {
      throw Exception('An instance of the $T haven\'t been registered yet.');
    }

    final result = registrar.dispose() as dynamic;
    if (result is Future) {
      throw Exception(
          'The dispose method must return a void result, not a Future!');
    }

    _instanceMap.remove(T);
  }
}

class SomeService {
  int temp;

  SomeService(this.temp);
}

class ServiceFactory extends SmartFactoryRegistrar<SomeService, int>
    implements Registrar<ServiceFactory> {
  ServiceFactory(super.builder);

  @override
  void dispose() {}

  @override
  ServiceFactory get instance => this;
}

void main() {
  group('DI put & get testing', () {
    final TestRegistry di = TestRegistry.instance;
    test('DI put singleton test', () {
      di.put(SingletonRegistrar(SomeService(0)));
      final mapLength = di.instanceMap.length;
      expect(mapLength, 1);
    });

    test('di double put exception test', () {
      try {
        di.put(SingletonRegistrar(SomeService(3)));

        expect(di.instanceMap.length, 1);
      } catch (e) {
        expect(di.instanceMap.length, 1);
      }
    });

    test('di get simple singleton testing', () {
      final intService = di.get<SomeService>();

      expect(intService.temp, 0);
    });

    test('some singleton testing', () {
      SomeService? intService = di.get<SomeService>();
      intService.temp = 5;
      intService = null;

      expect(di.get<SomeService>().temp, 5);
    });
  });

  group('Future factory testing', () {
    final TestRegistry di = TestRegistry.instance;
    test('Future registrar put tests', () {
      try {
        di.put(AsyncFactoryRegistrar(() async => SomeService(0)));
        expect(di.instanceMap.length, 2);
      } catch (e) {
        expect(di.instanceMap.length, 2);
      }
    });

    test('Future registrar getting a new instance', () async {
      final firstIntFactory = di.get<AsyncFactory<SomeService>>();
      final secondIntFactory = di.get<AsyncFactory<SomeService>>();

      expect(firstIntFactory == secondIntFactory, true);

      expect((await firstIntFactory()) != (await secondIntFactory()), true);

      final tempService = di.get<SomeService>();

      expect((await firstIntFactory()) != tempService, true);
    });
  });

  group('Factory registrars testing', () {
    final TestRegistry di = TestRegistry.instance;

    test('Factory put', () {
      di.put(SyncFactoryRegistrar(() => SomeService(0)));

      expect(di.instanceMap.length, 3);
    });

    test('Factory double put testing', () {
      try {
        di.put(SyncFactoryRegistrar(() => SomeService(0)));

        expect(di.instanceMap.length, 3);
      } catch (e) {
        expect(di.instanceMap.length, 3);
      }
    });

    test('get factory', () {
      final firstService = di.get<SyncFactory<SomeService>>()();
      final secondService = di.get<SyncFactory<SomeService>>()();

      expect(firstService != secondService, true);
    });
  });

  group('drop testing', () {
    final TestRegistry di = TestRegistry.instance;
    test('drop a non existing object', () {
      final currentObjectLength = di.instanceMap.length;
      try {
        di.drop<int>();

        expect(di.instanceMap.length, currentObjectLength);
      } catch (e) {
        expect(di.instanceMap.length, currentObjectLength);
      }
    });

    test('drop an existing singleton', () {
      final currentObjectLength = di.instanceMap.length;

      di.drop<SomeService>();
      expect(di.instanceMap.length, currentObjectLength - 1);
    });

    test('drop an existing factory', () {
      final currentObjectLength = di.instanceMap.length;

      di.drop<SyncFactory<SomeService>>();
      expect(di.instanceMap.length, currentObjectLength - 1);
    });
  });

  group('Smart factory', () {
    final TestRegistry di = TestRegistry.instance;
    test('put tests', () {
      final prevLength = di.instanceMap.length;

      di.put(ServiceFactory(
        (args) => SomeService(args),
      ));

      expect(di.instanceMap.length, prevLength + 1);
    });

    test('get tests', () {
      final serviceFactory = di.get<ServiceFactory>();
      final serviceInstance = serviceFactory(5);

      expect(serviceInstance.temp, 5);
    });
  });
}
