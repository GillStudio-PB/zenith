# Zenith - Dubai Worker Finance Manager (Flutter Source Code)

Because this editor environment natively builds and spins up **Node.js React/Vite** applications (not Flutter SDK distributions natively), I have bootstrapped the complete structural source code for your requested **Flutter Android App** inside the `/flutter_app` directory.

## What is included?
A production-grade baseline conforming exactly to your requirements:
1. **`pubspec.yaml`**: Configured with `flutter_riverpod` (State), `isar` (Local Database), `go_router` (Navigation), and Google Fonts.
2. **`lib/db/models.dart`**: Complete Isar schema classes representing your data layer (`User`, `Attendance`, `Transaction`, `Goal`, `Loan`). Includes required annotations (`@collection`).
3. **`lib/main.dart`**: The application entry point bootstrapping `Isar` locally on the device (using `path_provider`), configuring standard Material 3 theming (supporting Light/Dark modes), and wrapping the root in a strict Riverpod `ProviderScope`.
4. **`lib/providers/app_providers.dart`**: Contains the reactive State Management logic using Riverpod `StreamProvider` querying Isar databases in real-time to watch cash balances, daily attendance states, and global transactional histories.
5. **`lib/screens/dashboard_screen.dart`**: A comprehensive, animated Material 3 dashboard layout implementing `CustomScrollView` and structural mapping (mirroring the React layout with native Flutter widgets).

## How to execute and develop this Flutter Application:

1. **Download this Workspace**: 
   Click on the **"Export"** or **"Download ZIP"** context menu in the AI Studio editor to copy the entire workspace to your local machine.
2. **Open `/flutter_app`** in VS Code or Android Studio natively.
3. **Generate Isar Bindings**:
   Because Isar relies on fast NoSQL generated code bindings, you MUST first run the build_runner:
   ```bash
   flutter pub get
   flutter pub run build_runner build
   ```
   *This commands creates the necessary `models.g.dart` file automatically that validates offline database access.*
4. **Compile App**:
   ```bash
   flutter run
   ```

*The UI has been kept extremely crisp matching the "Professional Polish" directives (Slate backgrounds, thick shadows, Indigo branding, animated slivers).*
