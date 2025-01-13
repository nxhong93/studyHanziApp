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
    @Published var useLlmVision: Bool = false
    
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


struct CameraPreviewResult {
    let loading: Bool
    let texts: [String]
}

struct CameraPreview: UIViewControllerRepresentable {
    let session: AVCaptureSession
    let isDarkMode: Bool
    @ObservedObject var cameraModel: CameraModel
    var isLoading: (Bool) -> Void
    var onRecognizeText: (CameraPreviewResult) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraViewController = CameraViewController(session: session, onRecognizeText: { result in
            self.onRecognizeText(result)
        }, isDarkMode: isDarkMode, cameraModel: cameraModel, isLoading: isLoading)
        return cameraViewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    var session: AVCaptureSession?
    var onRecognizeText: ((CameraPreviewResult) -> Void)?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentZoomFactor: CGFloat = 1.0
    var isDarkMode: Bool = false
    var cameraModel: CameraModel?
    var isLoading: (Bool) -> Void
    
    private var cloudService: openRouterService?
    private var groqService: cloudgroqService?

    init(session: AVCaptureSession?, onRecognizeText: @escaping (CameraPreviewResult) -> Void, isDarkMode: Bool, cameraModel: CameraModel?, isLoading: @escaping (Bool) -> Void) {
        self.session = session
        self.onRecognizeText = onRecognizeText
        self.isDarkMode = isDarkMode
        self.cameraModel = cameraModel
        self.isLoading = isLoading
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        cloudService = openRouterService()
        groqService = cloudgroqService()
        setupCameraPreview()
        setupControls()
        addPinchToZoomGesture()
        
        view.backgroundColor = isDarkMode ? .black : .white
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
        choosePhotoButton.backgroundColor = isDarkMode ? UIColor(white: 0.0, alpha: 0.6) : UIColor(white: 1.0, alpha: 0.6)
        choosePhotoButton.layer.cornerRadius = 25
        choosePhotoButton.addTarget(self, action: #selector(choosePhotoTapped), for: .touchUpInside)
        choosePhotoButton.frame = CGRect(x: 20, y: view.bounds.height - 160, width: 50, height: 50)
        view.addSubview(choosePhotoButton)

        let captureButton = UIButton(type: .custom)
        captureButton.setImage(UIImage(systemName: "camera"), for: .normal)
        captureButton.tintColor = .white
        captureButton.backgroundColor = isDarkMode ? UIColor(white: 0.0, alpha: 0.6) : UIColor(white: 1.0, alpha: 0.6)
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
        guard let session = session,
              let output = session.outputs.compactMap({ $0 as? AVCapturePhotoOutput }).first else { return }
        
        isLoading(true)
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    private func processImage(_ image: UIImage) {
        guard let cameraModel = cameraModel else { return }
        if cameraModel.useLlmVision {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
            let base64String = imageData.base64EncodedString()
            isLoading(false)
            
            var accumulatedText = ""
            cloudService?.translateImageWithLLMVision(
                imageBase: base64String,
                onPartialResult: { partialResult in
                    DispatchQueue.main.async {
                        accumulatedText += partialResult
                        self.onRecognizeText?(CameraPreviewResult(loading: false, texts: [accumulatedText]))
                    }
                },
                onComplete: { result in
                    DispatchQueue.main.async {
                        self.isLoading(false)
                        switch result {
                        case .success:
                            print("Stream completed")
                        case .failure(let error):
                            print("Error: \(error.localizedDescription)")
                            self.callGroqAPI(with: image)
                        }
                    }
                }
            )
        } else {
            guard let cgImage = image.cgImage else { return }
            let request = VNRecognizeTextRequest { (request, error) in
                if let error = error {
                    DispatchQueue.main.async {
                        print("Text recognition error: \(error.localizedDescription)")
                        self.onRecognizeText?(CameraPreviewResult(loading: false, texts: ["Error recognizing text: \(error.localizedDescription)"]))
                    }
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                let recognizedTexts = observations.compactMap { $0.topCandidates(1).first?.string }
                DispatchQueue.main.async {
                    self.onRecognizeText?(CameraPreviewResult(loading: true, texts: recognizedTexts))
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
    private func callGroqAPI(with image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let base64String = imageData.base64EncodedString()

        isLoading(true)
        var accumulatedText = ""
        groqService?.translateImageWithLLMVision(
            imageBase: base64String,
            onPartialResult: { partialResult in
                DispatchQueue.main.async {
                    accumulatedText += partialResult
                    self.onRecognizeText?(CameraPreviewResult(loading: false, texts: [accumulatedText]))
                }
            },
            onComplete: { result in
                DispatchQueue.main.async {
                    self.isLoading(false)
                    switch result {
                    case .success:
                        print("Stream completed")
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                        self.onRecognizeText?(CameraPreviewResult(loading: false, texts: ["Error recognizing text: \(error.localizedDescription)"]))
                    }
                }
            }
        )
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        processImage(image)
        session?.stopRunning()
    }
}

extension CameraViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard let result = results.first else { return }
        isLoading(true)

        result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
            if let error = error {
                print("Lỗi chọn ảnh: \(error.localizedDescription)")
                self.isLoading(false)
                return
            }
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self.processImage(image)
                }
            } else {
                self.isLoading(false)
            }
        }
    }
}

