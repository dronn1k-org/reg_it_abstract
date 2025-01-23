library reg_it_abstract;

import 'dart:async';

import 'package:meta/meta.dart';

abstract interface class Registrar<T> {
  T get instance;

  void dispose();
}

mixin DisposeHandler<T> implements Registrar<T> {
  @protected
  abstract final void Function(Registrar<T> registrar)? beforeDispose;

  @override
  @mustCallSuper
  void dispose() => beforeDispose?.call(this);
}

class SingletonRegistrar<T> with DisposeHandler<T> implements Registrar<T> {
  @override
  final T instance;

  @override
  final void Function(Registrar<T> registrar)? beforeDispose;

  const SingletonRegistrar(this.instance, {this.beforeDispose});
}

class InstanceFactoryRegistrar<T>
    with DisposeHandler<T>
    implements Registrar<T> {
  final T Function() _constructor;

  InstanceFactoryRegistrar(this._constructor, {this.beforeDispose});

  @override
  T get instance => _constructor();

  @override
  final void Function(Registrar<T> registrar)? beforeDispose;
}

class AsyncFactoryRegistrar<T> extends InstanceFactoryRegistrar<FutureOr<T>> {
  AsyncFactoryRegistrar(super.constructor, {super.beforeDispose});
}

class LazySingletonRegistrar<T> with DisposeHandler<T> implements Registrar<T> {
  T? _instance;

  final T Function() _constructor;

  LazySingletonRegistrar(this._constructor, {this.beforeDispose});

  @override
  T get instance => _instance ??= _constructor();

  @override
  final void Function(Registrar<T> registrar)? beforeDispose;
}

class WeakSingletonRegistrar<T extends Object>
    with DisposeHandler<T>
    implements Registrar<T> {
  @override
  final void Function(Registrar<T> registrar)? beforeDispose;

  final T Function() _instanceBuilder;

  WeakSingletonRegistrar(this._instanceBuilder, {this.beforeDispose});

  WeakReference<T>? _weakReference;

  @override
  T get instance {
    final weakInstance = _weakReference?.target;
    if (weakInstance != null) return weakInstance;

    final instance = _instanceBuilder();

    if (instance is bool || instance is num || instance is String) {
      return instance;
    }

    _weakReference = WeakReference(instance);

    return instance;

    // mb it's also works
    // return (_weakReference = WeakReference(instance)).target!;
  }
}

abstract interface class Registry {
  void put<T>(final Registrar<T> registrar);
  T get<T>();
  void drop<T>();
}
