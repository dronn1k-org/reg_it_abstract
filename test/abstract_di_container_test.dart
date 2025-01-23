import 'dart:async';
import 'dart:developer';

import 'package:meta/meta.dart';
import 'package:reg_it_abstract/reg_it_abstract.dart';
import 'package:test/test.dart';

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
      return asyncGet();
    }
  }

  T asyncGet<T extends Future>() {
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

void main() {
  group('DI put & get testing', () {
    final TestRegistry di = TestRegistry.instance;
    setUp(() {
      di.instanceMap.clear();
    });
    test('DI put singleton test', () {
      di.put(SingletonRegistrar(SomeService(0)));
      final mapLength = di.instanceMap.length;
      expect(mapLength, 1);
    });

    test('di double put exception test', () {
      di.put(SingletonRegistrar(SomeService(3)));
      expect(di.instanceMap.length, 1);

      expect(() => di.put(SingletonRegistrar(SomeService(0))),
          throwsA(isA<Exception>()));

      expect(di.instanceMap.length, 1);
      expect(di.get<SomeService>().temp, 3);
    });

    test('di get simple singleton testing', () {
      di.put(SingletonRegistrar(SomeService(3)));
      expect(di.instanceMap.length, 1);

      final intService = di.get<SomeService>();

      expect(intService.temp, 3);
      expect(di.instanceMap.length, 1);
    });

    test('factory creating is right', () {
      di.put(InstanceFactoryRegistrar(() => SomeService(1)));
      expect(di.instanceMap.length, 1);

      final SomeService firstInstance = di.get();
      final SomeService secondInstance = di.get();

      expect(firstInstance == secondInstance, false);
    });
    test('async factory creating is right', () async {
      di.put(AsyncFactoryRegistrar(() async => SomeService(1)));
      expect(di.instanceMap.length, 1);

      final SomeService firstInstance = await di.get();
      final SomeService secondInstance = await di.get();

      expect(firstInstance == secondInstance, false);
    });
  });

  group('drop testing', () {
    final TestRegistry di = TestRegistry.instance;
    test('drop a non existing object', () {
      expect(() => di.drop<int>(), throwsA(isA<Exception>()));
    });

    test('drop an existing singleton', () {
      di.put(InstanceFactoryRegistrar(() => SomeService(1)));
      final currentObjectLength = di.instanceMap.length;

      di.drop<SomeService>();
      expect(di.instanceMap.length, currentObjectLength - 1);
    });
  });
}
