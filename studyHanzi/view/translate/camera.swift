//
//  camera.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 9/12/24.
//
import SwiftUI
import Translation



struct CameraView: View {
    @State private var selectedImage: UIImage?
    @State private var recognizedTexts: [String] = []
    @State private var showImagePicker = true
    @State private var useCamera = true
    @State private var cameraConfiguration: TranslationSession.Configuration?
    @State private var isLoading = false
    
    @Binding var isCameraActive: Bool
    @Binding var searchResults: [String]
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Button(action: {
                    useCamera = true
                    showImagePicker = true
                }) {
                    Image(systemName: "camera")
                        .padding()
                        .background(Color.blue.opacity(0.7))
                        .clipShape(Circle())
                        .foregroundColor(.white)
                }
                .padding()
                
                Button(action: {
                    useCamera = false
                    showImagePicker = true
                }) {
                    Image(systemName: "photo.badge.plus")
                        .padding()
                        .background(Color.green.opacity(0.7))
                        .clipShape(Circle())
                        .foregroundColor(.white)
                }
            }
            
            if isLoading {
                ProgressView("...")
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: useCamera ? .camera : .photoLibrary) { image in
                selectedImage = image
                processImage(image)
            }
        }
        .translationTask(cameraConfiguration) { session in
            searchResults.removeAll()
            if recognizedTexts.count>0 {
                Task { @MainActor in
                    isLoading = true
                    do {
                        for index in 0..<recognizedTexts.count {
                            let textOrigin = recognizedTexts[index]
                            if isChinese(textOrigin) {
                                searchResults.append(String(repeating: "-", count: 40))
                                searchResults.append(textOrigin)
                                let response = try await session.translate(textOrigin)
                                searchResults.append(response.targetText)
                            }
                        }
                    } catch {
                        searchResults.append("")
                    }
                    isLoading = false
                    isCameraActive = false
                }
            }
        }
    }
    
    private func processImage(_ image: UIImage) {
        
        TextRecognizer.recognizeTextWithRects(in: image) { textRects in
            for textRect in textRects {
                print(textRect)
                recognizedTexts.append(textRect.text)
            }
            let newConfig = TranslationSession.Configuration(
                source: .init(identifier: "zh-Hans"),
                target: .init(identifier: "vi")
            )
            
            if cameraConfiguration == nil || cameraConfiguration != newConfig {
                cameraConfiguration = newConfig
            } else {
                cameraConfiguration?.invalidate()
            }
        }
    }
}
