# Track 1 - Member A (Flutter UI + camera flow)

## Run
    flutter create --project-name tryon_member_a .   # generates android/ ios/ (keeps lib + pubspec)
    flutter pub get && flutter run

## Platform permissions
iOS  ios/Runner/Info.plist: NSCameraUsageDescription, NSPhotoLibraryUsageDescription,
     NSPhotoLibraryAddUsageDescription
Android: android/app/build.gradle -> minSdkVersion 21+ (gal needs 21+). Camera works via image_picker.
HTTPS/ngrok from the guide only matters if you later target Flutter Web.

## Plug-in points (search for TODO)
- TODO(B) lib/services/try_on_service.dart  -> real processTryOn + ImageResult; swap in main.dart
- TODO(C) lib/services/catalog_repository.dart -> real catalog JSON; swap in main.dart
- TODO(C) lib/state/try_on_state.dart -> shared TryOnState (keep field names)
- TODO(B) lib/utils/image_normalizer.dart -> agree size/aspect with B
