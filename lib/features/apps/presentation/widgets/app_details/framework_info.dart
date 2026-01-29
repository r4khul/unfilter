library;

class FrameworkInfo {
  final String name;
  final String description;
  final String? docsUrl;

  const FrameworkInfo({
    required this.name,
    required this.description,
    this.docsUrl,
  });
}

class FrameworkInfoData {
  static const _frameworkInfoMap = {
    'Flutter': FrameworkInfo(
      name: 'Flutter',
      description:
          'Flutter is Google\'s UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase. Known for its fast performance, expressive UIs, and hot reload feature.',
      docsUrl: 'https://flutter.dev',
    ),
    'React Native': FrameworkInfo(
      name: 'React Native',
      description:
          'React Native is a popular JavaScript framework for writing real, natively rendering mobile applications for iOS and Android. It\'s based on React and allows developers to use JavaScript and React to build mobile apps.',
      docsUrl: 'https://reactnative.dev',
    ),
    'Jetpack': FrameworkInfo(
      name: 'Jetpack Compose',
      description:
          'Jetpack Compose is Android\'s modern toolkit for building native UI. It simplifies and accelerates UI development with less code, powerful tools, and intuitive Kotlin APIs.',
      docsUrl: 'https://developer.android.com/jetpack/compose',
    ),
    'Native': FrameworkInfo(
      name: 'Native Android',
      description:
          'Native Android development using traditional XML layouts and Java/Kotlin. This approach provides maximum control and performance, directly leveraging Android SDK APIs.',
      docsUrl: 'https://developer.android.com/develop',
    ),
    'Kotlin': FrameworkInfo(
      name: 'Kotlin',
      description:
          'Kotlin is a modern programming language that makes Android development faster and more enjoyable. It\'s concise, safe, interoperable with Java, and tool-friendly, officially supported by Google for Android development.',
      docsUrl: 'https://kotlinlang.org',
    ),
    'Java': FrameworkInfo(
      name: 'Java',
      description:
          'Java is a powerful, object-oriented programming language that has been the foundation of Android development. It offers robust performance, extensive libraries, and cross-platform capabilities.',
      docsUrl: 'https://developer.android.com/guide',
    ),
    'Cordova': FrameworkInfo(
      name: 'Apache Cordova',
      description:
          'Apache Cordova is a mobile application development framework that enables developers to use standard web technologies like HTML5, CSS3, and JavaScript for cross-platform development.',
      docsUrl: 'https://cordova.apache.org',
    ),
    'Ionic': FrameworkInfo(
      name: 'Ionic Framework',
      description:
          'Ionic is an open-source UI toolkit for building high-quality mobile and desktop apps using web technologies (HTML, CSS, and JavaScript) with integrations for popular frameworks.',
      docsUrl: 'https://ionicframework.com',
    ),
    'Xamarin': FrameworkInfo(
      name: 'Xamarin',
      description:
          'Xamarin is an open-source platform for building modern and performant applications for iOS, Android, and Windows with .NET. It allows developers to share code across platforms.',
      docsUrl: 'https://dotnet.microsoft.com/apps/xamarin',
    ),
    'Unity': FrameworkInfo(
      name: 'Unity',
      description:
          'Unity is a cross-platform game engine developed by Unity Technologies. It\'s primarily used for developing video games and simulations for computers, consoles, and mobile devices.',
      docsUrl: 'https://unity.com',
    ),
    'Cocos2d': FrameworkInfo(
      name: 'Cocos2d-x',
      description:
          'Cocos2d-x is an open-source game framework for building 2D games, interactive books, demos, and other graphical applications. It\'s written in C++ and supports multiple platforms.',
      docsUrl: 'https://www.cocos.com/en/cocos2d-x',
    ),
    'Kotlin Multiplatform': FrameworkInfo(
      name: 'Kotlin Multiplatform',
      description:
          'Kotlin Multiplatform allows you to share code between different platforms while retaining the benefits of native programming. It\'s designed to share business logic across iOS, Android, and more.',
      docsUrl: 'https://kotlinlang.org/docs/multiplatform.html',
    ),
    'NativeScript': FrameworkInfo(
      name: 'NativeScript',
      description:
          'NativeScript is an open-source framework for building truly native mobile apps with JavaScript, TypeScript, or Angular. It provides direct access to native APIs and platform capabilities.',
      docsUrl: 'https://nativescript.org',
    ),
    'Qt': FrameworkInfo(
      name: 'Qt Framework',
      description:
          'Qt is a cross-platform application framework used for developing applications with native-like performance. It\'s widely used for embedded systems, desktop, and mobile applications.',
      docsUrl: 'https://www.qt.io',
    ),
    'Capacitor': FrameworkInfo(
      name: 'Capacitor',
      description:
          'Capacitor is a cross-platform native runtime that makes it easy to build web-native apps for iOS, Android, and the Web using JavaScript, HTML, and CSS.',
      docsUrl: 'https://capacitorjs.com',
    ),
    'Godot': FrameworkInfo(
      name: 'Godot Engine',
      description:
          'Godot provides a huge set of common tools, so you can just focus on making your game without reinventing the wheel. It exports to multiple platforms including Android.',
      docsUrl: 'https://godotengine.org',
    ),
  };

  static FrameworkInfo getInfo(String stack) {
    return _frameworkInfoMap[stack] ??
        FrameworkInfo(
          name: stack,
          description:
              'This app is built using $stack. It represents a framework or technology stack used for mobile application development.',
          docsUrl: 'https://developer.android.com',
        );
  }
}
