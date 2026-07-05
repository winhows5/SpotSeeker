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
    var currentPosition: AVCaptureDevice.Position = .back
    var isFlashDisabled: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera(position: currentPosition)
    }

    func setupCamera(position: AVCaptureDevice.Position = .back) {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            print("Unable to access camera!")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
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

    func setCameraPosition(_ position: AVCaptureDevice.Position) {
        guard position != currentPosition else { return }
        currentPosition = position
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else { return }
        do {
            let newInput = try AVCaptureDeviceInput(device: device)
            captureSession.beginConfiguration()
            for input in captureSession.inputs { captureSession.removeInput(input) }
            if captureSession.canAddInput(newInput) { captureSession.addInput(newInput) }
            captureSession.commitConfiguration()
        } catch {
            print("Failed to switch camera: \(error)")
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
        if !isFlashDisabled && photoOutput.supportedFlashModes.contains(.auto) {
            settings.flashMode = .auto
        } else {
            settings.flashMode = .off
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
            return
        }
        delegate?.didCaptureImage(image)
    }
}
