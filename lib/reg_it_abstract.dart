library reg_it_abstract;

abstract interface class Registrar<T> {
  T get instance;

  void dispose();
}

abstract class SyncFactory<T> implements Registrar<SyncFactory<T>> {
  T call();
}

abstract class AsyncFactory<T> implements Registrar<AsyncFactory<T>> {
  Future<T> call();
}

class SingletonRegistrar<T> implements Registrar<T> {
  @override
  final T instance;

  const SingletonRegistrar(this.instance);

  @override
  void dispose() {}
}

class SyncFactoryRegistrar<T> implements SyncFactory<T> {
  final T Function() _constructor;

  const SyncFactoryRegistrar(this._constructor);

  @override
  SyncFactory<T> get instance => this;

  @override
  T call() => _constructor();

  @override
  void dispose() {}
}

class AsyncFactoryRegistrar<T> implements AsyncFactory<T> {
  final Future<T> Function() _constructor;

  AsyncFactoryRegistrar(this._constructor);

  @override
  Future<T> call() => _constructor();

  @override
  AsyncFactory<T> get instance => this;

  @override
  void dispose() {}
}

class LazySingletonRegistrar<T> implements Registrar<T> {
  T? _instance;

  final T Function() _constructor;

  LazySingletonRegistrar(this._constructor);

  @override
  T get instance => _instance ??= _constructor();

  @override
  void dispose() {}
}

abstract interface class Registry {
  void put<T>(final Registrar<T> registrar);
  T get<T>();
  void drop<T>();
}

abstract class SmartFactory<T, A> implements Registrar<SmartFactory<T, A>> {
  abstract final T Function(A args) builder;

  T call(A args);
}

class SmartFactoryRegistrar<T, A> {
  final T Function(A args) builder;

  SmartFactoryRegistrar(this.builder);

  T call(A args) => builder(args);
}
