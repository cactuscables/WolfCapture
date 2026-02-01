import SwiftUI
import Vision
import UIKit

struct ContentView: View {
    @State private var recognizedText: String = "Take a photo to extract text"
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showShareSheet = false
    @State private var image: UIImage?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Editable plain text box
                TextEditor(text: $recognizedText)
                    .padding()
                    .frame(maxHeight: 320)
                    .border(Color.gray.opacity(0.4), width: 1)

                HStack(spacing: 12) {
                    Button { showCamera = true } label: {
                        Label("Camera", systemImage: "camera")
                    }
                    .buttonStyle(.borderedProminent)

                    Button { showPhotoLibrary = true } label: {
                        Label("Photos", systemImage: "photo")
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    UIPasteboard.general.string = recognizedText
                } label: {
                    Label("Copy Text", systemImage: "doc.on.doc")
                }

                Button { showShareSheet = true } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            .padding()
            .navigationTitle("Photo to Text")

            // Camera
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { selected in
                    self.image = selected
                    self.extractText(from: selected)
                }
            }

            // Photo Library
            .sheet(isPresented: $showPhotoLibrary) {
                ImagePicker(sourceType: .photoLibrary) { selected in
                    self.image = selected
                    self.extractText(from: selected)
                }
            }

            // Share sheet
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [recognizedText])
            }
        }
    }

    // MARK: - OCR + Filtering
    private func extractText(from image: UIImage) {
        guard let cgImage = image.cgImage else {
            self.recognizedText = "Could not read image."
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.recognizedText = "OCR error: \(error.localizedDescription)"
                }
                return
            }

            guard let results = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async { self.recognizedText = "No text found." }
                return
            }

            let lines = results.compactMap { $0.topCandidates(1).first?.string }
            let allText = lines.joined(separator: "\n")

            // Try to extract model/serial; fallback to all text if none found.
            let parsed = Self.extractModelAndSerial(from: lines)
            DispatchQueue.main.async {
                if parsed.model != nil || parsed.serial != nil {
                    self.recognizedText =
                        "Model: \(parsed.model ?? "_unknown_")\nSerial: \(parsed.serial ?? "_unknown_")"
                } else {
                    self.recognizedText = allText
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do { try handler.perform([request]) }
            catch {
                DispatchQueue.main.async {
                    self.recognizedText = "OCR failed: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Parsing helpers
    private static func extractModelAndSerial(from lines: [String]) -> (model: String?, serial: String?) {
        var model: String? = nil
        var serial: String? = nil

        func firstCode(in s: String, min: Int, max: Int = 24) -> String? {
            // Alphanumeric code with dashes/slashes, uppercased
            let pattern = #"(?i)\b([A-Z0-9][A-Z0-9\-\/]{\#(min-1),\#(max-1)})\b"#
            guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
            let ns = NSRange(s.startIndex..., in: s)
            if let m = re.firstMatch(in: s, options: [], range: ns),
               let r = Range(m.range(at: 1), in: s) {
                return String(s[r]).uppercased()
            }
            return nil
        }

        // Normalize lines
        let trimmed = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for i in trimmed.indices {
            let raw = trimmed[i]
            let lower = raw.lowercased()

            // --- MODEL ---
            if model == nil, containsAny(lower, ["model", "mod", "m/n", "type"]) {
                model = firstCode(in: raw, min: 4)
                if model == nil, i < trimmed.count - 1 {
                    model = firstCode(in: trimmed[i + 1], min: 4)
                }
            }

            // --- SERIAL ---
            if serial == nil, containsAny(lower, ["serial", "s/n", "sn", "ser"]) {
                serial = firstCode(in: raw, min: 6)
                if serial == nil, i < trimmed.count - 1 {
                    serial = firstCode(in: trimmed[i + 1], min: 6)
                }
            }

            if model != nil && serial != nil { break }
        }

        // Heuristic fallback: scan the whole blob if labels weren't found
        if model == nil || serial == nil {
            let all = trimmed.joined(separator: "\n")

            if model == nil {
                // Mix of letters+digits, 4-18 chars, allows - or /
                let pat = #"(?i)\b(?=[A-Z0-9\-\/]{4,18}\b)(?=.*\d)(?=.*[A-Z])[A-Z0-9\-\/]+\b"#
                if let re = try? NSRegularExpression(pattern: pat) {
                    let ns = NSRange(all.startIndex..., in: all)
                    if let m = re.firstMatch(in: all, options: [], range: ns),
                       let r = Range(m.range, in: all) {
                        model = String(all[r]).uppercased()
                    }
                }
            }

            if serial == nil {
                // 6-24 chars, must include at least two digits
                let pat = #"(?i)\b(?=[A-Z0-9\-]{6,24}\b)(?=(?:.*\d){2,})[A-Z0-9\-]+\b"#
                if let re = try? NSRegularExpression(pattern: pat) {
                    let ns = NSRange(all.startIndex..., in: all)
                    if let m = re.firstMatch(in: all, options: [], range: ns),
                       let r = Range(m.range, in: all) {
                        serial = String(all[r]).uppercased()
                    }
                }
            }
        }

        return (model, serial)
    }

    private static func containsAny(_ text: String, _ needles: [String]) -> Bool {
        for n in needles where text.contains(n) { return true }
        return false
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var completion: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (UIImage) -> Void
        init(completion: @escaping (UIImage) -> Void) { self.completion = completion }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage { completion(image) }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
