# Architecture: feature-driven layers

Magnit Go follows the same feature-driven, layered design as the team's web reference
(Next.js, point-of-sale checkout), adapted to a single SwiftUI app. Folders under
`MagnitGo/` are split by **what the code is for**, not by file type.

## The rule

A layer may only use the layers **below** it.

```
App  ──►  Processes  ──►  Features  ──►  Entities  ──►  Providers  ──►  Shared
                     (each arrow = "may use")
```

The app is one Swift module, so the compiler does not enforce this. `scripts/check-layers.sh`
does: it fails if a layer names a type or action from a layer above it. Run it before
committing.

## The layers

| Layer | Question it answers | Here |
|---|---|---|
| `App/` | How is it wired into screens? | `MagnitGoApp`, `RootView`, and every screen under `App/Pages` |
| `Processes/` | Which actions make one workflow? | `Checkout`: record the receipt, spend and earn points, start a new basket |
| `Features/` | What can the shopper *do*? One action each | `ScanProduct` (read a code, say what it is), `AddToBasket` (confirm and add) |
| `Entities/` | What are the business nouns, their data and their own UI? | `Product`, `Basket`, `Receipt`, `Loyalty`, `Session` |
| `Providers/` | What infrastructure does it run on? | `Services/Scanner` (camera), `Lib/Feedback` (beep, haptics) |
| `Shared/` | What is generic, with no shop knowledge? | `UI/Theme`, icons, buttons, steps, page dots, QR drawing |

### Shared

Could be copied into an unrelated app unchanged: colours, fonts, button styles, `Icon`,
`IconButton`, `Steps`, `SectionLabel`, `PageDots`, `QR`. Knows nothing about products or
the session.

### Providers

Wrappers around the outside world. `CameraScanner` owns the `AVCaptureSession` and reports
codes; `Sounds` and `Haptics` wrap the system. Swapping the camera library means editing one
folder.

### Entities

Each noun has its model, its basic changes, and the UI that shows it:

```
Entities/
  Product/   Product, Nutrition, ProductFacts, ScannedItem, MarkingCode, Catalog, ProductPhoto
  Basket/    BasketLine, RemovedLine, BasketQR, Basket+Edit (+/−/remove/undo),
             EditableLine, PaperStepper, UndoBar
  Receipt/   Receipt, Paper, ReceiptRow, ReceiptLine, PaidReceipt
  Loyalty/   Tier, TierBar
  Session/   AppState (the shopper's session store), Lang, PayMethod, LanguageSwitch
```

`AppState` is the one `@Observable` store, injected with `.environment`. It holds the
stored state and the changes that touch saved settings (language, phone, store, welcome).
Other layers add their actions to it as extensions, each in its own folder, so a
capability lives in one place.

Entity UI is presentational plus the entity's own basic changes: `PaperStepper` may call
`increment`/`decrement`, but never a feature or a process.

### Features

One shopper action each, as an extension on `AppState` with one entry point and a plain
result:

- `ScanProduct`: `check(code) -> ScanCheck` (`.found`, `.unknown`, `.needsMark`, `.duplicateMark`).
  Adds nothing.
- `AddToBasket`: `add(item, qty) -> BasketLine`. Weighed goods and marked drinks are always one.

This is the Swift form of the reference's feature contract: one function to call, one result
to render, no UI inside.

### Processes

A workflow across several entities or features. `Checkout.completePurchase(method:)` records
the receipt, updates points and lifetime spend, remembers the payment method and starts a new
basket.

### App

Screens and wiring only. A page calls features and processes and renders entity UI:

```swift
switch app.check(code) {              // feature
case .found(let item): pending = item // the product window asks before adding
...
}
let line = app.add(item, qty: qty)    // feature, on "Add to basket"
```

```
App/
  MagnitGoApp.swift, RootView.swift
  Pages/
    Welcome/   WelcomeView
    SignIn/    OnboardingView
    Home/      HomeScreen (MainView), StoreSheet, ProfileSheet
    Product/   ProductScreen: scanned (asks to add) / in basket (edits) / browsing (scan to add)
    Shopping/  ShoppingFlow + Route, ScannerScreen, BasketSheet, PayScreens
```

## What is different from the web reference

- **No client/server segments.** Everything runs on the phone.
- **No barrels.** Swift has no per-file imports inside a module; the layer check replaces them.
- **One store instead of per-service providers.** The session is small enough for one
  `@Observable` object; features extend it rather than wrapping it in hooks.

## How to add things

- **A new shopper action** (e.g. "repeat last basket"): add `Features/RepeatBasket/RepeatBasket.swift`
  with one `extension AppState` function. Call it from a page.
- **A workflow across actions**: add it under `Processes/<Flow>/`.
- **A new noun** (e.g. a promotion): `Entities/Promotion/` with its model and its own view.
- **New infrastructure** (e.g. a payment SDK): `Providers/Services/<Name>/`. Anything above
  may use it; keep the calls that combine it with basket or session changes in a feature
  or process.
- **A new screen**: `App/Pages/<Area>/`.

Then run `scripts/check-layers.sh`.
