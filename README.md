# simple_login_app

A new Flutter project.

## Included library
[flutter_usb_printer](https://pub.dev/packages/flutter_usb_printer)

## Testing
Download latest APK build from [Release](https://github.com/itsmehoaq/flutter_login_app/releases/latest)

## Workflow & Usage instruction
- To show printer page, user needs to be logged in
  - Login credentials are currently not needed, for testing use the Skip button
- Once logged in, go to Receipt screen
- On first app start, Printer connection must be done manually (the kiosk printer is already selected). Press **Connect** button on top of the screen
- If success, app shows notification of connected to printer
- Fill information about bill in the input boxes below
- Press **Checkout** button to continue
- On QR screen, press either buttons to confirm payment
  - Currently QR screen not showing an usable QR code. Both buttons on this screen are for demo purposes
- Upon success payment, press Print button to print receipt and return to receipt screen

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

