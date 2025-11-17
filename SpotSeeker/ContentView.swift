//
//  ContentView.swift
//  SpotSeeker
//
//  Created by Wenhao.Wang on 7/5/25.
//

import SwiftUI
import PhotosUI
import WebKit
import UIKit
import Foundation

struct ContentView: View {
    @State private var capturedImage: UIImage?
    @State private var overlayImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var takePicture = false
    @State private var showingSaveAlert = false
    @State private var saveMessage = ""
    @State private var selectedTemplateId: Int? = nil
    @State private var templates: [TemplateItem] = TemplateItem.demoAssets

    var body: some View {
        VStack {
            if let capturedImage = capturedImage {
                VStack(spacing: 8) {
                    GeometryReader { proxy in
                        VStack {
                            Spacer()
                            VStack(spacing: 8) {
                                // Top: original overlay (photo overlay preferred, else template SVG)
                                ZStack {
                                    if let overlayImage = overlayImage {
                                        Image(uiImage: overlayImage)
                                            .resizable()
                                            .scaledToFit()
                                            .opacity(0.5)
                                    } else if let selectedId = selectedTemplateId, let item = templates.first(where: { $0.id == selectedId }) {
                                        SVGOverlayView(assetName: item.assetName)
                                            .opacity(0.5)
                                    }
                                }
                                .frame(height: proxy.size.height * 0.4)
                                .frame(maxWidth: .infinity, alignment: .center)

                                // Bottom: captured photo
                                Image(uiImage: capturedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: proxy.size.height * 0.4)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    HStack {
                        Button("Take Another Photo") {
                            self.capturedImage = nil
                        }
                        .padding()

                        Button("Save Photo") {
                            let imageSaver = ImageSaver()
                            imageSaver.save(image: capturedImage) { result in
                                switch result {
                                case .success:
                                    self.saveMessage = "Photo saved!"
                                case .failure(let error):
                                    self.saveMessage = "Error saving: \(error.localizedDescription)"
                                }
                                self.showingSaveAlert = true
                            }
                        }
                        .padding()
                    }
                }
            } else {
                ZStack {
                    CameraView(capturedImage: $capturedImage, takePicture: $takePicture)
                        .edgesIgnoringSafeArea(.all)

                    if let overlayImage = overlayImage {
                        Image(uiImage: overlayImage)
                            .resizable()
                            .scaledToFit()
                            .opacity(0.5)
                    } else if let selectedId = selectedTemplateId, let item = templates.first(where: { $0.id == selectedId }) {
                        SVGOverlayView(assetName: item.assetName)
                            .opacity(0.5)
                    }

                    // Bottom overlay with icon-only buttons and templates strip
                    VStack {
                        Spacer()

                        HStack(alignment: .center, spacing: 16) {
                            // Left: overlay picker icon button (no text)
                            Button {
                                isImagePickerPresented = true
                            } label: {
                                Image(systemName: "photo")
                                    .font(.system(size: 22, weight: .regular))
                                    .foregroundColor(.white)
                                    .padding(12)
                            }

                            Spacer()

                            // Center: circular shutter button (empty circle)
                            ShutterButton {
                                self.takePicture = true
                            }

                            Spacer()

                            // Right: templates strip at the same height as shutter
                            TemplateStrip(items: templates, selectedId: selectedTemplateId) { item in
                                selectedTemplateId = item.id
                                overlayImage = nil
                            }
                            .frame(height: 60)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
                .sheet(isPresented: $isImagePickerPresented) {
                    PhotoPicker(selectedImage: $overlayImage)
                }
            }
        }
        .alert(isPresented: $showingSaveAlert) {
            Alert(title: Text("Save Status"), message: Text(saveMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            ensureTemplatesPersistedToAppSupport()
        }
    }

    // Persist bundled template assets into the app's internal storage (Library/Application Support)
    // This avoids exposing them directly to the user via Files while keeping them available for runtime use.
    private func ensureTemplatesPersistedToAppSupport() {
        let fm = FileManager.default
        guard let appSupportURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let templatesDir = appSupportURL.appendingPathComponent("ImageSeries/DemoSeries", isDirectory: true)

        // Create directory if needed
        do {
            try fm.createDirectory(at: templatesDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("[TemplatePersist] Failed to create DemoSeries directory: \(error)")
            return
        }

        // Copy each asset into Application Support if it doesn't exist yet
        for item in TemplateItem.demoAssets {
            let targetURL = templatesDir.appendingPathComponent("\(item.assetName).svg")
            if fm.fileExists(atPath: targetURL.path) {
                continue
            }
            // Prefer raw SVG from bundle under ImageSeries/DemoSeries
            if let rawURL = Bundle.main.url(forResource: item.assetName, withExtension: "svg", subdirectory: "ImageSeries/DemoSeries") {
                do {
                    let data = try Data(contentsOf: rawURL)
                    try data.write(to: targetURL, options: .atomic)
                    print("[TemplatePersist] Stored \(item.assetName) from bundle at \(targetURL.path)")
                } catch {
                    print("[TemplatePersist] Failed to persist \(item.assetName) from bundle: \(error)")
                }
            } else if let dataAsset = NSDataAsset(name: item.assetName) {
                // Fallback to asset catalog (Data asset) if raw bundle file is not present
                do {
                    try dataAsset.data.write(to: targetURL, options: .atomic)
                    print("[TemplatePersist] Stored \(item.assetName) from asset catalog at \(targetURL.path)")
                } catch {
                    print("[TemplatePersist] Failed to persist \(item.assetName) from asset catalog: \(error)")
                }
            } else {
                print("[TemplatePersist] Missing bundled resource for \(item.assetName)")
            }
        }
    }
}

class ImageSaver: NSObject {
    private var completionHandler: ((Result<Void, Error>) -> Void)?

    func save(image: UIImage, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        self.completionHandler = completionHandler
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }

    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            completionHandler?(.failure(error))
        } else {
            completionHandler?(.success(()))
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    self.parent.selectedImage = image as? UIImage
                }
            }
        }
    }
}

// Templates data and strip UI
struct TemplateItem: Identifiable {
    let id: Int
    let name: String
    let assetName: String

    static let demoAssets: [TemplateItem] = [
        TemplateItem(id: 0, name: "camera", assetName: "camera"),
        TemplateItem(id: 1, name: "photo", assetName: "photo"),
        TemplateItem(id: 2, name: "person", assetName: "person"),
        TemplateItem(id: 3, name: "heart", assetName: "heart"),
        TemplateItem(id: 4, name: "star", assetName: "star"),
        TemplateItem(id: 5, name: "bolt", assetName: "bolt"),
        TemplateItem(id: 6, name: "bell", assetName: "bell"),
        TemplateItem(id: 7, name: "leaf", assetName: "leaf"),
    ]
}

struct SVGOverlayView: UIViewRepresentable {
    let assetName: String

    private func html(for svgString: String) -> String {
        return """
<!DOCTYPE html><html><head><meta name=\"viewport\" content=\"initial-scale=1, maximum-scale=1\"><style>
html, body { margin:0; padding:0; background: transparent; }
.container { display:flex; align-items:center; justify-content:center; height:100vh; width:100vw; }
svg { width: 80vw; height: auto; }
</style></head><body>
<div class=\"container\">\(svgString)</div>
</body></html>
"""
    }

    private func persistedSVGString(for assetName: String) -> String? {
        let fm = FileManager.default
        guard let appSupportURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let svgURL = appSupportURL.appendingPathComponent("ImageSeries/DemoSeries/\(assetName).svg")
        guard let data = try? Data(contentsOf: svgURL) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func bundledSVGString(for assetName: String) -> String? {
        if let rawURL = Bundle.main.url(forResource: assetName, withExtension: "svg", subdirectory: "ImageSeries/DemoSeries"),
           let data = try? Data(contentsOf: rawURL),
           let s = String(data: data, encoding: .utf8) {
            return s
        }
        if let dataAsset = NSDataAsset(name: assetName), let s = String(data: dataAsset.data, encoding: .utf8) {
            return s
        }
        return nil
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isUserInteractionEnabled = false
        let svgString: String?
        if let persisted = persistedSVGString(for: assetName) {
            svgString = persisted
        } else {
            svgString = bundledSVGString(for: assetName)
        }
        if let s = svgString {
            webView.loadHTMLString(html(for: s), baseURL: nil)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let svgString: String?
        if let persisted = persistedSVGString(for: assetName) {
            svgString = persisted
        } else {
            svgString = bundledSVGString(for: assetName)
        }
        if let s = svgString {
            uiView.loadHTMLString(html(for: s), baseURL: nil)
        }
    }
}

struct SVGTemplateView: UIViewRepresentable {
    let assetName: String

    private func html(for svgString: String) -> String {
        return """
<!DOCTYPE html><html><head><meta name=\"viewport\" content=\"initial-scale=1, maximum-scale=1\"><style>
html, body { margin:0; padding:0; background: transparent; }
svg { width: 52px; height: 52px; }
</style></head><body>
\(svgString)
</body></html>
"""
    }

    private func persistedSVGString(for assetName: String) -> String? {
        let fm = FileManager.default
        guard let appSupportURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let svgURL = appSupportURL.appendingPathComponent("ImageSeries/DemoSeries/\(assetName).svg")
        guard let data = try? Data(contentsOf: svgURL) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func bundledSVGString(for assetName: String) -> String? {
        if let rawURL = Bundle.main.url(forResource: assetName, withExtension: "svg", subdirectory: "ImageSeries/DemoSeries"),
           let data = try? Data(contentsOf: rawURL),
           let s = String(data: data, encoding: .utf8) {
            return s
        }
        if let dataAsset = NSDataAsset(name: assetName), let s = String(data: dataAsset.data, encoding: .utf8) {
            return s
        }
        return nil
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isUserInteractionEnabled = false
        let svgString: String?
        if let persisted = persistedSVGString(for: assetName) {
            svgString = persisted
        } else {
            svgString = bundledSVGString(for: assetName)
        }
        if let s = svgString {
            webView.loadHTMLString(html(for: s), baseURL: nil)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let svgString: String?
        if let persisted = persistedSVGString(for: assetName) {
            svgString = persisted
        } else {
            svgString = bundledSVGString(for: assetName)
        }
        if let s = svgString {
            uiView.loadHTMLString(html(for: s), baseURL: nil)
        }
    }
}

struct TemplateStrip: View {
    let items: [TemplateItem]
    let selectedId: Int?
    let onSelect: (TemplateItem) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(items) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(selectedId == item.id ? 0.15 : 0.08))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.9), lineWidth: selectedId == item.id ? 3 : 1)
                                )

                            SVGTemplateView(assetName: item.assetName)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ShutterButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                // Outer ring only (empty circle)
                Circle()
                    .stroke(Color.white.opacity(0.9), lineWidth: 6)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 4)
            }
        }
        .accessibilityLabel("Shutter")
    }
}


