// Flutter Riverpod: How to Register a Listener during App Startup
// https://codewithandrea.com/articles/riverpod-initialize-listener-app-startup/

// for firebase integration with windows:
// https://iteo.medium.com/flutter-for-desktop-using-firebase-on-windows-9e3135b9ebd

// Singletons in Flutter: How to Avoid Them and What to do Instead
// https://codewithandrea.com/articles/flutter-singletons/

// Flutter Riverpod Tip: Use AsyncValue rather than FutureBuilder or StreamBuilder:
// https://codewithandrea.com/articles/flutter-use-async-value-not-future-stream-builder/

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_examples/firebase_options.dart';

Future<void> registerListenerOnStartupMainMethod() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // 1. Create a ProviderContainer
  final container = ProviderContainer();
  // 2. Use it to read the provider
  container.read(firebaseAuthServiceProvider);
  // 3. Pass the container to an UncontrolledProviderScope and run the app
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseAuthService = ref.watch(firebaseAuthServiceProvider);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              Text(
                'Firebase Auth Listener Example! User is ${firebaseAuthService?.email}',
              ),
              ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: 'temp@gmail.com',
                    password: '123456',
                  );
                },
                child: Text('Login'),
              ),
              ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                },
                child: Text('signout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final onFirebaseAuthProvider = StreamProvider.autoDispose((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class FirebaseAuthService extends StateNotifier<User?> {
  FirebaseAuthService(this.ref) : super(null) {
    _init();
  }

  // this variable is used to access any provider of project.
  final Ref ref;

  void _init() {
    // 3. listen to the StreamProvider
    // for more about [AsyncValue]:
    // https://codewithandrea.com/articles/flutter-use-async-value-not-future-stream-builder/
    ref.listen<AsyncValue<User?>>(onFirebaseAuthProvider, (previus, next) {
      // 4. Implement the event handling code
      final linkData = next.value;
      state = linkData;
      if (linkData != null) {
        debugPrint(linkData.email);
      }
    });
  }
}

// 1. Create a provider for the service
final firebaseAuthServiceProvider =
    StateNotifierProvider<FirebaseAuthService, User?>((ref) {
      return FirebaseAuthService(ref);
    });
