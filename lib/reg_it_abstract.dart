library reg_it_abstract;

import 'package:flutter/foundation.dart';

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

  const SingletonRegistrar(this.instance, [this.beforeDispose]);
}

class InstanceFactoryRegistrar<T>
    with DisposeHandler<T>
    implements Registrar<T> {
  final T Function() _constructor;

  InstanceFactoryRegistrar(this._constructor, [this.beforeDispose]);

  @override
  T get instance => _constructor();

  @override
  final void Function(Registrar<T> registrar)? beforeDispose;
}

class LazySingletonRegistrar<T> with DisposeHandler<T> implements Registrar<T> {
  T? _instance;

  final T Function() _constructor;

  LazySingletonRegistrar(this._constructor, [this.beforeDispose]);

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

  @override
  T get instance {
    if (_weakReference?.target != null) return _weakReference!.target!;

    return (_weakReference = WeakReference(_instanceBuilder())).target!;
  }

  final T Function() _instanceBuilder;

  WeakReference<T>? _weakReference;

  WeakSingletonRegistrar(this._instanceBuilder, [this.beforeDispose]);
}

abstract interface class Registry {
  void put<T>(final Registrar<T> registrar);
  T get<T>();
  void drop<T>();
}
