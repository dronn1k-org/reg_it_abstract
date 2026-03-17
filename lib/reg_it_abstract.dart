library reg_it_abstract;

import 'dart:async';

import 'package:meta/meta.dart';

/// A small set of abstractions to build a Dependency Injection (DI) container.
///
/// This library intentionally contains only *contracts* and a few small,
/// reusable registrar implementations. It does **not** provide a concrete
/// container implementation — you can implement your own `Registry` using any
/// storage and lifecycle rules you need.
///
/// The central idea:
/// - A `Registry` stores `Registrar<T>` by `Type`.
/// - A `Registrar<T>` knows how to *provide* an instance (`instance`) and how to
///   participate in cleanup (`dispose`).
///
/// See the package tests for a minimal `Registry` implementation example.
abstract interface class Registrar<T> {
  /// Returns an instance of `T`.
  ///
  /// The semantics depend on the registrar implementation:
  /// - `SingletonRegistrar`: always returns the same pre-built object.
  /// - `InstanceFactoryRegistrar`: creates a new instance per access.
  /// - `LazySingletonRegistrar`: builds once on first access, then caches.
  /// - `WeakSingletonRegistrar`: caches via a weak reference (may be rebuilt).
  T get instance;

  /// Releases resources associated with this registrar.
  ///
  /// A `Registry` typically calls this when dropping/unregistering a type.
  /// Implementations in this library are synchronous; if you need async disposal
  /// logic, do it in `beforeDispose` and schedule work explicitly.
  void dispose();
}

/// Adds a lightweight "hook" to run logic right before disposal.
///
/// This mixin is used by the default registrar implementations in this file.
/// A `Registry` calls `dispose()` on a registrar, and the registrar calls
/// `beforeDispose` (if provided).
///
/// Example:
///
/// ```dart
/// final registrar = SingletonRegistrar(
///   SomeService(),
///   beforeDispose: (r) {
///     // r.instance is available here.
///   },
/// );
/// ```
mixin DisposeHandler<T> implements Registrar<T> {
  /// A callback invoked when `dispose()` is called.
  ///
  /// The current registrar is passed as the argument, allowing you to access
  /// `instance` in a type-safe way.
  @protected
  abstract final void Function(Registrar<T> registrar)? beforeDispose;

  @override
  @mustCallSuper
  void dispose() => beforeDispose?.call(this);
}

/// A registrar that always returns the same already-created instance.
///
/// This is the simplest registrar and is typically used for long-lived
/// dependencies (configuration, clients, services).
///
/// Example:
///
/// ```dart
/// registry.put(SingletonRegistrar(SomeService(0)));
/// final service = registry.get<SomeService>();
/// ```
class SingletonRegistrar<T> with DisposeHandler<T> implements Registrar<T> {
  @override
  final T instance;

  @override
  final void Function(Registrar<T> registrar)? beforeDispose;

  /// Creates a registrar wrapping an already-built [instance].
  ///
  /// Use [beforeDispose] to clean up the instance when the registrar is dropped
  /// from a registry.
  const SingletonRegistrar(this.instance, {this.beforeDispose});
}

/// A registrar that builds a new instance on every access.
///
/// Useful for non-shared, short-lived objects.
///
/// Example:
///
/// ```dart
/// registry.put(InstanceFactoryRegistrar(() => SomeService(1)));
/// final a = registry.get<SomeService>();
/// final b = registry.get<SomeService>();
/// assert(!identical(a, b));
/// ```
class InstanceFactoryRegistrar<T>
    with DisposeHandler<T>
    implements Registrar<T> {
  final T Function() _constructor;

  /// Creates a registrar that uses [_constructor] to build instances.
  InstanceFactoryRegistrar(this._constructor, {this.beforeDispose});

  @override
  T get instance => _constructor();

  @override
  final void Function(Registrar<T> registrar)? beforeDispose;
}

/// A registrar for async factories.
///
/// It is functionally identical to `InstanceFactoryRegistrar<FutureOr<T>>`,
/// but provides a clearer intent when registering asynchronous constructors:
/// `() async => T`.
///
/// Typical usage:
///
/// ```dart
/// registry.put(AsyncFactoryRegistrar(() async => SomeService(1)));
/// final service = await registry.get<Future<SomeService>>();
/// ```
///
/// Note: the type you register/retrieve depends on your `Registry`
/// implementation strategy (see package tests for one approach).
class AsyncFactoryRegistrar<T> extends InstanceFactoryRegistrar<FutureOr<T>> {
  /// Creates an async factory registrar.
  AsyncFactoryRegistrar(super.constructor, {super.beforeDispose});
}

/// A registrar that builds the instance once on first access and then caches it.
///
/// This is useful when construction is expensive and you want lazy init without
/// having to pre-build the instance.
class LazySingletonRegistrar<T> with DisposeHandler<T> implements Registrar<T> {
  T? _instance;

  final T Function() _constructor;

  /// Creates a lazy singleton registrar that runs [_constructor] once.
  LazySingletonRegistrar(this._constructor, {this.beforeDispose});

  @override
  T get instance => _instance ??= _constructor();

  @override
  final void Function(Registrar<T> registrar)? beforeDispose;
}

/// A registrar that caches the instance using a weak reference.
///
/// If the instance is garbage-collected, the next access will rebuild it using
/// the provided builder. This can be useful for memory-sensitive caches.
///
/// Important notes:
/// - Only works for non-primitive objects. For `bool`, `num`, and `String`, the
///   value is returned without weak-caching (a weak reference would not provide
///   useful semantics).
/// - Do not rely on weak caching for deterministic lifetime; GC behavior is
///   runtime-dependent.
class WeakSingletonRegistrar<T extends Object>
    with DisposeHandler<T>
    implements Registrar<T> {
  @override
  final void Function(Registrar<T> registrar)? beforeDispose;

  final T Function() _instanceBuilder;

  /// Creates a weak singleton registrar.
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
  }
}

/// A minimal contract for a type-based registry (DI container).
///
/// A typical implementation stores `Registrar`s in a `Map<Type, Registrar>`,
/// keyed by the generic type `T`.
abstract interface class Registry {
  /// Registers [registrar] for the type `T`.
  void put<T>(final Registrar<T> registrar);

  /// Retrieves an instance of `T`.
  ///
  /// The returned value typically comes from `registrar.instance` stored for
  /// `T`. Implementations may throw if `T` is not registered.
  T get<T>();

  /// Unregisters `T` and disposes its registrar.
  void drop<T>();
}
