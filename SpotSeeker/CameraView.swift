//
//  CameraView.swift
//  SpotSeeker
//
//  Created by ByteDance on 7/5/25.
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?

    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraViewController = CameraViewController()
        cameraViewController.delegate = context.coordinator
        return cameraViewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func didCaptureImage(_ image: UIImage) {
            parent.capturedImage = image
        }
    }
}
