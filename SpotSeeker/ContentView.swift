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

enum NavRoute: Hashable { case imageSeries }

struct ContentView: View {
    @State private var capturedImage: UIImage?
    @State private var overlayImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var takePicture = false
    @State private var showingSaveAlert = false
    @State private var saveMessage = ""
    @State private var selectedTemplateId: Int? = nil
    @State private var templates: [TemplateItem] = TemplateItem.loadAvailableTemplates()
    @State private var useFrontCamera = false
    @State private var isFlashDisabled = true
    @State private var showImageSeriesGrid = false

    var body: some View {
        NavigationStack {
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
                                        RasterOverlayView(assetName: item.assetName)
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
                        // Clears the captured photo to retake
                        Button("Take Another Photo") {
                            self.capturedImage = nil
                        }
                        .padding()

                        // Saves the captured photo to Photos library
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
                    CameraView(capturedImage: $capturedImage, takePicture: $takePicture, useFrontCamera: $useFrontCamera, isFlashDisabled: $isFlashDisabled)
                        .edgesIgnoringSafeArea(.all)

                    if let overlayImage = overlayImage {
                        Image(uiImage: overlayImage)
                            .resizable()
                            .scaledToFit()
                            .opacity(0.5)
                    } else if let selectedId = selectedTemplateId, let item = templates.first(where: { $0.id == selectedId }) {
                        RasterOverlayView(assetName: item.assetName)
                            .opacity(0.5)
                    }

                    // Top controls: close (left) and flash toggle (center)
                    VStack {
                        HStack {
                            NavigationLink(destination: FeedsView()) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                            }
                            .simultaneousGesture(TapGesture().onEnded { print("[UI] Search pressed") })
                            Spacer()
                            // Toggles camera flash disabled/enabled
                            Button {
                                isFlashDisabled.toggle()
                            } label: {
                                Image(systemName: isFlashDisabled ? "bolt.slash" : "bolt")
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            NavigationLink(destination: ProfileView()) {
                                Image(systemName: "gearshape")
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                            }
                            .simultaneousGesture(TapGesture().onEnded { print("[UI] Profile pressed") })
                        }
                        .padding(.top, 60)
                        .padding(.horizontal, 12)
                        Spacer()
                    }
                    .zIndex(2)

                    // Bottom overlay with icon-only buttons and templates strip
                    VStack {
                        Spacer()

                        ZStack {
                            // Full-width strip behind the centered shutter
                            TemplateStrip(items: templates, selectedId: selectedTemplateId) { item in
                                selectedTemplateId = item.id
                                overlayImage = nil
                            }
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
                            .offset(y: -80)

                            // Centered shutter always on top
                            // Shutter: captures photo when tapped
                            ShutterButton(action: { self.takePicture = true }, assetName: selectedTemplateId.flatMap { id in templates.first(where: { $0.id == id })?.assetName })
                        }
                        .padding(.horizontal, 16)

                        HStack {
                            // Opens ImageSeries full-screen overlay
                            NavigationLink(destination: ImageSeriesView()) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "square.grid.2x2")
                                        .foregroundColor(.white)
                                }
                            }

                            Spacer()

                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 44)
                                Text(selectedTemplateId.flatMap { id in templates.first(where: { $0.id == id })?.assetName } ?? "Select Template")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(.horizontal, 16)
                            }
                            .frame(maxWidth: .infinity)

                            Spacer()

                            // Switches between front and back camera
                            Button {
                                useFrontCamera.toggle()
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .foregroundColor(.white)
                                }
                            }
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
    }
    .alert(isPresented: $showingSaveAlert) {
        Alert(title: Text("Save Status"), message: Text(saveMessage), dismissButton: .default(Text("OK")))
    }
    .onAppear {
        ensureTemplatesPersistedToAppSupport()
        templates = TemplateItem.loadAvailableTemplates()
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

        // Copy or update raster template assets into Application Support
        let exts = ["jpg","jpeg","png","heic"]
        var bundleURLs: [URL] = []
        for ext in exts {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "ImageSeries/DemoSeries") {
                bundleURLs.append(contentsOf: urls)
            }
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                bundleURLs.append(contentsOf: urls)
            }
        }
        for rawURL in bundleURLs {
            let base = rawURL.deletingPathExtension().lastPathComponent
            let targetURL = templatesDir.appendingPathComponent("\(base).\(rawURL.pathExtension)")
            do {
                let bundleData = try Data(contentsOf: rawURL)
                if fm.fileExists(atPath: targetURL.path) {
                    if let existingData = try? Data(contentsOf: targetURL), existingData == bundleData {
                    } else {
                        try bundleData.write(to: targetURL, options: .atomic)
                        print("[TemplatePersist] Updated \(base) from bundle at \(targetURL.path)")
                    }
                } else {
                    try bundleData.write(to: targetURL, options: .atomic)
                    print("[TemplatePersist] Stored \(base) from bundle at \(targetURL.path)")
                }
            } catch {
                print("[TemplatePersist] Failed to persist \(base) from bundle: \(error)")
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

struct ShutterButton: View {
    let action: () -> Void
    let assetName: String?

    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                if let name = assetName {
                    RasterTemplateView(assetName: name)
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.9), lineWidth: 6)
                                .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 4)
                        )
                        .allowsHitTesting(false)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.9), lineWidth: 6)
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 4)
                }
            }
        }
        .accessibilityLabel("Shutter")
    }
}
