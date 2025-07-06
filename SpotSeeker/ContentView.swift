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
    @State private var takePicture = false
    @State private var showingSaveAlert = false
    @State private var saveMessage = ""

    var body: some View {
        VStack {
            if let capturedImage = capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
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
            } else {
                ZStack {
                    CameraView(capturedImage: $capturedImage, takePicture: $takePicture)
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

                Button("Capture") {
                    self.takePicture = true
                }
                .padding()

                .sheet(isPresented: $isImagePickerPresented) {
                    PhotoPicker(selectedImage: $overlayImage)
                }
            }
        }
        .alert(isPresented: $showingSaveAlert) {
            Alert(title: Text("Save Status"), message: Text(saveMessage), dismissButton: .default(Text("OK")))
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


