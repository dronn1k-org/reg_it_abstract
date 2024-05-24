`reg it abstract` is a library for implementing Dependency Injection (DI) container abstractions in Dart. It provides a flexible and powerful way to manage dependencies in your applications.

## Installation

Add `reg_it_abstract` to your `pubspec.yaml` file:

```yaml
dependencies:
  reg_it_abstract:
    git:
      url: https://github.com/your_username/reg_it_abstract.git
      ref: main
```

Then run:

```sh
flutter pub get
```

## Usage

### Core Abstractions & default implementations

```dart
import 'package:reg_it_abstract/reg_it_abstract.dart';

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
```

### Usage Examples

#### Registering and Retrieving a Singleton

```dart
void main() {
  final registry = RegistryImpl();

  final singletonRegistrar = SingletonRegistrar<String>('Singleton Instance');
  registry.put<String>(singletonRegistrar);

  final instance = registry.get<String>();
  print(instance); // Output: Singleton Instance
}
```

#### Using a Factory to Create Objects

```dart
void main() {
  final registry = RegistryImpl();

  final factoryRegistrar = SyncFactoryRegistrar<String>(() => 'New Instance');
  registry.put<SyncFactory<String>>(factoryRegistrar);

  final instance = registry.get<SyncFactory<String>>().call();
  print(instance); // Output: New Instance
}
```

#### Asynchronous Factory

```dart
void main() async {
  final registry = RegistryImpl();

  final asyncFactoryRegistrar = AsyncFactoryRegistrar<String>(() async => 'Async Instance');
  registry.put<AsyncFactory<String>>(asyncFactoryRegistrar);

  final instance = await registry.get<AsyncFactory<String>>().call();
  print(instance); // Output: Async Instance
}
```

#### Lazy Singleton

```dart
void main() {
  final registry = RegistryImpl();

  final lazySingletonRegistrar = LazySingletonRegistrar<String>(() => 'Lazy Singleton Instance');
  registry.put<String>(lazySingletonRegistrar);

  final instance = registry.get<String>();
  print(instance); // Output: Lazy Singleton Instance
}
```

#### Smart Factory

```dart
void main() {
  final registry = RegistryImpl();

  final smartFactoryRegistrar = SmartFactoryRegistrar<int, String>((args) => args.length);
  registry.put<SmartFactory<int, String>>(smartFactoryRegistrar);

  final length = registry.get<SmartFactory<int, String>>().call('Test');
  print(length); // Output: 4
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.