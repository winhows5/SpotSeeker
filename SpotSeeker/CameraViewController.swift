//
//  CameraViewController.swift
//  SpotSeeker
//
//  Created by ByteDance on 7/5/25.
//

import UIKit
import AVFoundation

protocol CameraViewControllerDelegate: AnyObject {
    func didCaptureImage(_ image: UIImage)
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    weak var delegate: CameraViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("Unable to access back camera!")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            photoOutput = AVCapturePhotoOutput()

            if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(photoOutput)
                setupLivePreview()
            }
        } catch {
            print("Error setting up camera input: \(error)")
            return
        }
    }

    func setupLivePreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.previewLayer.frame = self.view.bounds
            }
        }
    }

    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
            return
        }
        delegate?.didCaptureImage(image)
    }
}
