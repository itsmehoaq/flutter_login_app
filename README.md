# simple_login_app

A new Flutter project.

## Included library
[flutter_usb_printer](https://pub.dev/packages/flutter_usb_printer)

## Getting Started

Install dependencies
```
flutter pub get
```

Modify `flutter_usb_printer` JVM target to `1.8`
> This step is necessary, because by default the project looks for JVM version 21 top compile, but this library needs JVM version 1.8
- Go to `~/.pub-cache/hosted/pub.dev/flutter_usb_printer-0.1.0+1/android/`
- Modify the `build.gradle` file as follow:
  ```
  android {
  // existing configs below
  // ...
  // add kotlinOptions to specify jvmTarget
  kotlinOptions {
        jvmTarget = "1.8"
    }
  }
