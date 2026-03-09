# DailyToolbox

A collection of **24 useful everyday tools** for iPhone, iPad and Mac (Catalyst), built entirely with **SwiftUI** and the **iOS 26 Liquid Glass** design system.

---

## Tools

| Category | Tool | Description |
|---|---|---|
| **Numbers** | Percentage | Base & rate calculator |
| | Currency Converter | Live exchange rates (persistent selection) |
| | Tip Splitter | Bill split & tip calculator |
| | Unit Converter | Length · Weight · Volume · Temperature |
| | Number Bases | Hex · Dec · Bin converter |
| | Interest Rate | Compound & simple interest |
| | Roman Numerals | Bi-directional Dec ↔ Roman |
| | BMI Calculator | Body Mass Index with health ranges |
| | Loan Calculator | Monthly payment & amortization |
| **Science** | Ohm's Law | Voltage · Current · Resistance · Power |
| | Color Picker & Converter | HEX · RGB · HSB · CMYK |
| | Area & Volume | Shapes: square, circle, cube, sphere … |
| **Tools** | QR Code Generator | URL · Text · WiFi · Contact · Email (persistent) |
| | Aspect Ratio | Scale & ratio calculator |
| | Randomizer | Coin flip · Dice · Custom range |
| | Fuel Cost | Trip cost from consumption & price |
| | German Holidays | Public & school holidays for all 16 states (persistent) |
| | Calendar | Date difference & countdown |
| | Translation | dict.leo.org dictionary |
| | Horizon | Visibility range via GPS |
| **Performance** | Benchmark | CPU/memory device speed |
| | Power Consumption | Watts & electricity cost |
| **App** | About | App info & feedback |

---

## What's New in v2.0

### Complete UIKit → SwiftUI Rewrite
Every screen has been rebuilt from the ground up using SwiftUI with the **iOS 26 Liquid Glass** design system (`GlassEffectContainer`, `.glassEffect()`, `.buttonStyle(.glass)`).

- **Animated splash screen** — SwiftUI `MeshGradient` launch experience
- **Home grid** — adaptive `LazyVGrid` with glassmorphic tool cards, coloured icon badges and section headers
- **Pure SwiftUI app lifecycle** — `@main DailyToolboxApp`, no `SceneDelegate`, no storyboard navigation
- **Adaptive navigation** — `NavigationSplitView` on iPad/Mac, `NavigationStack` on iPhone
- **Swift 6 strict concurrency** — zero warnings, zero errors
- **String Catalog localisation** — English, German, Italian, Spanish, Danish, French

### New Tools (v2.0beta2 → v2.0rc)

| Tool | Highlights |
|---|---|
| **Tip Splitter** | Per-person amount, custom tip %, rounding |
| **Unit Converter** | 6 categories, live conversion |
| **BMI Calculator** | Visual health-range bar |
| **Loan Calculator** | Monthly payment, total interest, amortisation table |
| **Fuel Cost** | Distance · consumption · price, km & miles |
| **Ohm's Law** | Solve for any of V, I, R, P |
| **Color Picker & Converter** | System color wheel + HEX/RGB/HSB/CMYK output |
| **Area & Volume** | 8 shapes, metric & imperial |
| **QR Code Generator** | 5 modes, share sheet, persistent inputs |
| **Aspect Ratio Calculator** | Constrained resize, ratio lock |
| **Randomizer** | Coin flip, 4 dice types, custom min/max |
| **German Holidays** | Live data from feiertage-api.de + ferien-api.de, all 16 Bundesländer, persistent state & year |

### Input Persistence
User inputs are remembered across app launches via `@AppStorage`:
- **QR Code** — active tab, all text fields, WiFi credentials, contact details
- **Currency Converter** — from/to currency selection, amount
- **German Holidays** — selected Bundesland, selected year

### Per-screen Design Highlights
Each tool has a unique `MeshGradient` colour palette:

| Screen | Palette |
|---|---|
| About | Deep blue / violet |
| Percentage | Teal / cyan |
| Currency Converter | Indigo / purple |
| Tip Splitter | Rose / pink |
| Unit Converter | Sky blue |
| Temperature | Ember / rust |
| Number Bases | Midnight navy |
| Interest Rate | Emerald green |
| BMI Calculator | Blue / teal |
| Loan Calculator | Deep indigo |
| Fuel Cost | Forest green |
| Ohm's Law | Electric blue |
| Color Picker | Prism / rainbow |
| Area & Volume | Stone / slate |
| QR Code | Neutral charcoal |
| Aspect Ratio | Deep violet |
| Randomizer | Midnight blue / gold |
| German Holidays | Dark navy / gold |
| Horizon | Midnight ocean |
| Calendar | Deep purple |
| Power Consumption | Dark charcoal / amber |
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
*View.swift       One file per tool screen (24 tools)
AppDelegate       iCloud KV store + Mac Catalyst menu bar
MenuController    Mac Catalyst menu bar (macCatalyst only)
Global            App-wide string & URL constants
DeviceInfo        OS/device info via Foundation (no UIKit)
MyExtensions      Bundle, Date, Array, Locale helpers
```

---

## License

Apache License 2.0 — © 2020–2026 Marcus Deuß

