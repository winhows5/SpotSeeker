//
//  ContentView.swift
//  SpotSeeker
//
//  Created by Wenhao.Wang on 7/5/25.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var capturedImage: UIImage?
    @State private var overlayImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var isCameraPresented = false

    var body: some View {
        VStack {
            if let capturedImage = capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Button("Take Another Photo") {
                    self.capturedImage = nil
                }
                .padding()
            } else {
                ZStack {
                    CameraView(capturedImage: $capturedImage)
                        .edgesIgnoringSafeArea(.all)

                    if let overlayImage = overlayImage {
                        Image(uiImage: overlayImage)
                            .resizable()
                            .scaledToFit()
                            .opacity(0.5) // Adjust transparency here
                    }
                }
            }

            HStack {
                Button("Select Overlay") {
                    isImagePickerPresented = true
                }
                .padding()
                .sheet(isPresented: $isImagePickerPresented) {
                    PhotoPicker(selectedImage: $overlayImage)
                }
            }
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


