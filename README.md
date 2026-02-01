# Wolf Capture

An iOS app that extracts model and serial numbers from appliance tags using OCR.

## The Problem

Field service technicians photograph dozens of appliance tags daily to capture model and serial numbers for work orders. This leads to:
- Hundreds of work photos cluttering the camera roll
- Manual transcription of numbers (error-prone)
- Time wasted switching between camera and work order apps

## The Solution

Wolf Capture uses Apple's Vision framework to:
1. Capture or select a photo of an appliance tag
2. Extract all text using OCR
3. Intelligently identify model and serial numbers using pattern matching
4. Present the extracted data ready to copy with one tap

## Features

- **Camera & Photo Library** - Capture new photos or select existing ones
- **Smart Parsing** - Looks for keywords like "Model", "Serial", "S/N" and extracts adjacent codes
- **Fallback Heuristics** - If no labels found, uses pattern matching to identify likely model/serial numbers
- **One-Tap Copy** - Instantly copy extracted text to clipboard for pasting into work orders
- **Share Sheet** - Standard iOS sharing for other workflows

## Technical Details

- Built with SwiftUI
- Uses Vision framework (`VNRecognizeTextRequest`) for OCR
- Regex-based pattern matching for intelligent text extraction
- UIKit interop for camera access and sharing

## Usage

1. Tap **Camera** to photograph an appliance tag, or **Photos** to select an existing image
2. The app automatically extracts and displays the model/serial numbers
3. Tap **Copy Text** to copy to clipboard
4. Paste into your work order system

## Author

Built by Dustin Williams to solve a real workflow problem in appliance service.
