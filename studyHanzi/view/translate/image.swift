//
//  image.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 5/12/24.
//

import SwiftUI
import UIKit
import Vision
import AVFoundation
import PhotosUI



class CameraModel: ObservableObject {
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "CameraSessionQueue")
    
    func startSession() {
        sessionQueue.async {
            self.setupSession()
            self.session.startRunning()
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            self.session.stopRunning()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureHandler { image in
            completion(image)
        })
    }
    
    private func setupSession() {
        session.beginConfiguration()
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            return
        }
        session.addInput(videoInput)
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
    }
}

class PhotoCaptureHandler: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage) -> Void
    
    init(completion: @escaping (UIImage) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData) {
            completion(image)
        }
    }
}




struct CameraPreview: UIViewControllerRepresentable {
    let session: AVCaptureSession
    var onRecognizeText: ([String]) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraViewController = CameraViewController()
        cameraViewController.session = session
        cameraViewController.onRecognizeText = onRecognizeText
        return cameraViewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    class CameraViewController: UIViewController {
        var session: AVCaptureSession?
        var onRecognizeText: (([String]) -> Void)?
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private var currentZoomFactor: CGFloat = 1.0

        override func viewDidLoad() {
            super.viewDidLoad()

            setupCameraPreview()
            setupControls()
            addPinchToZoomGesture()
        }

        private func setupCameraPreview() {
            guard let session = session else { return }
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.bounds
            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
            }
        }

        private func setupControls() {
            let choosePhotoButton = UIButton(type: .custom)
            choosePhotoButton.setImage(UIImage(systemName: "photo"), for: .normal)
            choosePhotoButton.tintColor = .white
            choosePhotoButton.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
            choosePhotoButton.layer.cornerRadius = 25
            choosePhotoButton.addTarget(self, action: #selector(choosePhotoTapped), for: .touchUpInside)
            choosePhotoButton.frame = CGRect(x: 20, y: view.bounds.height - 160, width: 50, height: 50)
            view.addSubview(choosePhotoButton)

            let captureButton = UIButton(type: .custom)
            captureButton.setImage(UIImage(systemName: "camera"), for: .normal)
            captureButton.tintColor = .white
            captureButton.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
            captureButton.frame = CGRect(x: view.bounds.midX - 27, y: view.bounds.height - 163, width: 50, height: 50)
            captureButton.layer.cornerRadius = 25
            captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
            view.addSubview(captureButton)
        }
        
        private func addPinchToZoomGesture() {
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchToZoom(_:)))
            view.addGestureRecognizer(pinchGesture)
        }
        
        @objc private func handlePinchToZoom(_ gesture: UIPinchGestureRecognizer) {
            guard let device = AVCaptureDevice.default(for: .video) else { return }
            if gesture.state == .changed {
                let maxZoomFactor = min(device.activeFormat.videoMaxZoomFactor, 5.0)
                let scale = max(1.0, min(currentZoomFactor * gesture.scale, maxZoomFactor))
                do {
                    try device.lockForConfiguration()
                    device.videoZoomFactor = scale
                    device.unlockForConfiguration()
                } catch {
                    print("Error adjusting zoom: \(error)")
                }
            }
            if gesture.state == .ended {
                currentZoomFactor = device.videoZoomFactor
            }
        }

        @objc private func choosePhotoTapped() {
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 1
            configuration.filter = .images
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        }

        @objc private func capturePhoto() {
            let settings = AVCapturePhotoSettings()
            guard let session = session,
                  let output = session.outputs.compactMap({ $0 as? AVCapturePhotoOutput }).first else { return }

            output.capturePhoto(with: settings, delegate: self)
        }

        private func processImage(_ image: UIImage) {
            guard let cgImage = image.cgImage else { return }
            let request = VNRecognizeTextRequest { (request, error) in
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                let recognizedTexts = observations.compactMap { $0.topCandidates(1).first?.string }
                DispatchQueue.main.async {
                    self.onRecognizeText?(recognizedTexts)
                }
            }
            request.recognitionLanguages = ["zh-Hans", "zh-Hant"]
            request.usesLanguageCorrection = true

            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try requestHandler.perform([request])
                } catch {
                    print("Error performing text recognition: \(error)")
                }
            }
        }
    }
}

extension CameraPreview.CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        processImage(image)
    }
}

extension CameraPreview.CameraViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard let result = results.first else { return }
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
            if let image = object as? UIImage {
                self?.processImage(image)
            }
        }
    }
}




