# simple_login_app

A new Flutter project.

## Included library
[flutter_usb_printer](https://pub.dev/packages/flutter_usb_printer)

## Testing
Download latest APK build from [Release](https://github.com/itsmehoaq/flutter_login_app/releases/latest)

## App usage instruction
- To show printer page, user needs to be logged in
  - Login credentials: `admin` / `admin`
- Once logged in, go to Print screen and connect to USB printer
- Type any sample text in the input box
- Once done, press Print to confirm and print the text input

## Development

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

