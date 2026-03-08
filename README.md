# DailyToolbox

A collection of 12 useful everyday tools for iPhone, iPad and Mac (Catalyst), built entirely with **SwiftUI** and the **iOS 26 Liquid Glass** design system.

---

## Tools

| Category | Tool | Description |
|---|---|---|
| **Numbers** | Percentage | Base & rate calculator |
| | Currency | Live exchange rates |
| | Number Bases | Hex · Dec · Bin converter |
| | Interest Rate | Compound & simple interest |
| | Roman Numerals | Bi-directional Dec ↔ Roman |
| **Conversions** | Temperature | °C · °F · K |
| | Power | Watts & electricity cost |
| | Translation | dict.leo.org dictionary |
| **Tools** | Calendar | Date difference & countdown |
| | Horizon | Visibility range via GPS |
| | Benchmark | CPU/memory device speed |
| | About | App info & feedback |

---

## What's New in v2.0 (Alpha)

### Complete UIKit → SwiftUI Rewrite
Every screen has been rebuilt from the ground up using SwiftUI with the **iOS 26 Liquid Glass** design system (`GlassEffectContainer`, `.glassEffect()`, `.buttonStyle(.glass)`).

- **Animated splash screen** — SwiftUI `MeshGradient` launch experience replaces the old `LaunchScreen.storyboard`
- **Home grid** — adaptive `LazyVGrid` with glassmorphic tool cards, coloured icon badges and section headers
- **Pure SwiftUI app lifecycle** — `@main DailyToolboxApp`, no `SceneDelegate`, no storyboard navigation
- **Adaptive navigation** — `NavigationSplitView` on iPad/Mac, `NavigationStack` on iPhone
- **UIKit removed** from all non-UI files (`Global`, `DeviceInfo`, `MyExtensions`, `AboutView`, `MenuController`)
- **No more localization files** — all strings inlined in English; German `.lproj` files removed
- **Swift 6 strict concurrency** — zero warnings, zero errors

### Per-screen Design Highlights
Each tool has a unique `MeshGradient` colour palette:

| Screen | Palette |
|---|---|
| About | Deep blue / violet |
| Percentage | Teal / cyan |
| Currency | Indigo / purple |
| Temperature | Ember / rust |
| Number Bases | Midnight navy |
| Interest Rate | Emerald green |
| Horizon | Midnight ocean |
| Calendar | Deep purple |
| Power | Dark charcoal / amber |
| Roman Numerals | Crimson / burgundy |
| Benchmark | Deep-space navy |
| Home grid | Midnight aurora |

---

## Requirements

- **iOS / iPadOS 26+**
- **Xcode 26+**
- Swift 6

---

## Architecture

```
DailyToolboxApp   @main SwiftUI App entry point
ContentView       Root navigation (NavigationSplitView / NavigationStack)
MasterView        Home grid — ToolItem/ToolSection data model
*View.swift       One file per tool screen
AppDelegate       iCloud KV store + Mac Catalyst menu bar
MenuController    Mac Catalyst menu bar (macCatalyst only)
Global            App-wide string & URL constants
DeviceInfo        OS/device info via Foundation (no UIKit)
MyExtensions      Bundle, Date, Array, Locale helpers
```

---

## License

Apache License 2.0 — © 2020–2025 Marcus Deuß

