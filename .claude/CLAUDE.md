# WolfCapture

## What This Is
iOS app that photographs appliance data tags and extracts model/serial numbers using OCR. Built in Swift with Apple's Vision framework. On-device processing, no API keys or internet required.

## Architecture
- Single file app — all UI and logic in `ContentView.swift`
- SwiftUI for UI, UIKit interop for camera/sharing
- Vision framework (`VNRecognizeTextRequest`) for on-device OCR
- No external dependencies

## Cannot Build on Debian
This is a Swift/iOS project requiring Xcode on macOS. Edit code here, commit/push, then pull on macOS to build and test in Xcode.

Camera features require a physical iPhone (simulator has no camera).

## How the OCR Parsing Works

Two-pass extraction in `extractModelAndSerial()`:
1. **Label scan** — looks for keywords (`model`, `mod`, `m/n`, `type` / `serial`, `s/n`, `sn`, `ser`) and grabs the alphanumeric code on the same or next line
2. **Heuristic fallback** — regex patterns: model = mixed letters+digits 4-18 chars, serial = 6-24 chars with 2+ digits
3. **Raw fallback** — shows all OCR text for manual copy

## Key File
- `ContentView.swift` — entire app: UI, OCR, parsing, ImagePicker, ShareSheet

## Gotchas
- `usesLanguageCorrection = true` can mangle alphanumeric model numbers — try `false` in `extractText()` if OCR looks wrong
- Heuristic fallback may grab barcode/EAN numbers on busy labels
- No state persistence — text clears when app closes, copy before navigating away
- No `.xcodeproj` in repo — source code only, create project in Xcode
