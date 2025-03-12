# simple_login_app

A new Flutter project.

## Getting Started

Install dependencies
```
flutter pub get
```

Modify `flutter_usb_printer` JVM target to `1.8`
- Go to `~/android/flutter_usb_printer/build.gradle`
- Add the following to the file:
  ```
  android {
  // ... existing configs here
  // add kotlinOptions to specify jvmTarget
  kotlinOptions {
        jvmTarget = "1.8"
    }
  }
