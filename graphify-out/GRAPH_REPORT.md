# Graph Report - sodocu  (2026-09-01)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 596 nodes · 694 edges · 30 communities (15 shown, 9 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 23 edges (avg confidence: 0.85)
- Token cost: 884 input · 273 output

## Graph Freshness
- Built from commit: `1514f807`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Game Statistics Logic
- UI Animation and Layout
- Windows Platform Integration
- About Page UI
- Date and Time Formatting
- State Management and Controllers
- iOS and macOS App Delegate
- Linux Platform Integration
- Custom UI Components
- Windows C++ Utilities
- Web App Manifest
- Project Configuration and Assets
- Windows Plugin Registration
- Android Activity
- Linux Build Configuration
- Web Icons and HTML
- Windows Build Configuration
- iOS Launch Screen
- iOS App Icons
- iOS Launch Images 2x
- iOS Launch Images 3x
- macOS App Icons
- Nullable String Type
- Web Large Icons

## God Nodes (most connected - your core abstractions)
1. `_` - 46 edges
2. `Win32Window` - 24 edges
3. `MessageHandler` - 12 edges
4. `FlutterWindow` - 10 edges
5. `Create` - 10 edges
6. `WndProc` - 10 edges
7. `MessageHandler` - 9 edges
8. `WindowClassRegistrar` - 7 edges
9. `_MyApplication` - 7 edges
10. `OnCreate` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Android App Icon` --semantically_similar_to--> `Sudoku Logo`  [EXTRACTED] [semantically similar]
  android/app/src/main/res/mipmap-hdpi/ic_launcher.png → assets/images/logo.png
- `iOS App Icon` --semantically_similar_to--> `Sudoku Logo`  [EXTRACTED] [semantically similar]
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png → assets/images/logo.png
- `Launch Screen Assets README` --references--> `iOS Launch Image`  [INFERRED]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md → ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.h → windows/flutter/generated_plugin_registrant.cc
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Application Branding** — assets_images_logo, android_app_icon, ios_app_icon [EXTRACTED 1.00]
- **Linux Build System** — linux_cmakelists, linux_flutter_cmakelists, linux_runner_cmakelists [EXTRACTED 1.00]
- **Windows Build System** — windows_cmakelists, windows_flutter_cmakelists, windows_runner_cmakelists [EXTRACTED 1.00]
- **Cross-Platform Branding Assets** — ios_runner_assets_xcassets_appicon_appiconset_icon_app_83_5x83_5_2x_png, macos_runner_assets_xcassets_appicon_appiconset_app_icon_1024_png, web_favicon_png, web_icons_icon_512_png [INFERRED 0.70]
- **Flutter Project Configuration** — pubspec, analysis_options, devtools_options [INFERRED 0.90]

## Communities (30 total, 9 thin omitted)

### Community 0 - "Game Statistics Logic"
Cohesion: 0.01
Nodes (184): bool get, dart:async, dart:convert, Difficulty get, _afterNumberPlaced, allowedNumbers, _asInt, averageCompletedSeconds (+176 more)

### Community 1 - "UI Animation and Layout"
Cohesion: 0.03
Nodes (72): Animation, AnimationController, dart:math, FontWeight, int?, int? _selectedRow,, announcement, backgroundColor (+64 more)

### Community 2 - "Windows Platform Integration"
Cohesion: 0.06
Nodes (55): RECT, unique_ptr, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM (+47 more)

### Community 3 - "About Page UI"
Cohesion: 0.05
Nodes (44): Color, ColorScheme, CustomPainter, IconData, AboutPage, _appName, _appVersion, build (+36 more)

### Community 4 - "Date and Time Formatting"
Cohesion: 0.05
Nodes (44): int get, _, bl, d, _d2g, _d2j, day, _div (+36 more)

### Community 5 - "State Management and Controllers"
Cohesion: 0.05
Nodes (36): AnimatedContainer, Bindings, GetxController, home_controller.dart, dependencies, HomeBindings, HomeController, _bestInMode (+28 more)

### Community 6 - "iOS and macOS App Delegate"
Cohesion: 0.06
Nodes (26): Any, Cocoa, Flutter, FlutterAppDelegate, FlutterMacOS, FlutterPluginRegistry, FlutterViewController, Foundation (+18 more)

### Community 7 - "Linux Platform Integration"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 8 - "Custom UI Components"
Cohesion: 0.18
Nodes (16): _ContactTile, _ContactTileState, _FeatureTile, _FeatureTileState, _AnimatedBoardNumber, _AnimatedBoardNumberState, _AnimatedCellContainer, _AnimatedCellContainerState (+8 more)

### Community 9 - "Windows C++ Utilities"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 10 - "Web App Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 11 - "Project Configuration and Assets"
Cohesion: 0.22
Nodes (7): Android App Icon, Sudoku Logo, Build Android APK Workflow, iOS App Icon, package:flutter_lints, GetX, Window Manager

### Community 14 - "Linux Build Configuration"
Cohesion: 1.00
Nodes (3): Linux CMakeLists, Linux Flutter CMakeLists, Linux Runner CMakeLists

### Community 15 - "Web Icons and HTML"
Cohesion: 0.67
Nodes (3): Web Favicon, Web Icon (192), Web Index HTML

### Community 16 - "Windows Build Configuration"
Cohesion: 1.00
Nodes (3): Windows CMakeLists, Windows Flutter CMakeLists, Windows Runner CMakeLists

## Knowledge Gaps
- **358 isolated node(s):** `_afterNumberPlaced`, `allowedNumbers`, `_asInt`, `averageCompletedSeconds`, `bestStreak` (+353 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 443 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `Date and Time Formatting` to `State Management and Controllers`?**
  _High betweenness centrality (0.091) - this node is a cross-community bridge._
- **Why does `HomeController` connect `State Management and Controllers` to `Game Statistics Logic`, `UI Animation and Layout`?**
  _High betweenness centrality (0.030) - this node is a cross-community bridge._
- **Why does `FlutterWindow` connect `Windows Platform Integration` to `iOS and macOS App Delegate`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `MessageHandler` (e.g. with `Destroy` and `GetClientArea`) actually correct?**
  _`MessageHandler` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `Create` (e.g. with `Destroy` and `UpdateTheme`) actually correct?**
  _`Create` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `_afterNumberPlaced`, `allowedNumbers`, `_asInt` to the rest of the system?**
  _358 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Game Statistics Logic` be split into smaller, more focused modules?**
  _Cohesion score 0.010810810810810811 - nodes in this community are weakly interconnected._