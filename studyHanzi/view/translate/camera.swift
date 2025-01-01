//
//  camera.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 9/12/24.
//
import SwiftUI
import Translation
import Vision



struct CameraView: View {
    @State private var recognizedTexts: [String] = []
    @State private var cameraConfiguration: TranslationSession.Configuration?
    @State private var isLoading = false
    @StateObject private var cameraModel = CameraModel()
    
    @Binding var isCameraActive: Bool
    @Binding var searchResults: [String]
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraModel.session) { texts in
                handleRecognizedTexts(texts)
            }
            .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                ProgressView("Đang xử lý...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            cameraModel.startSession()
            AppDelegate.shouldLockOrientation = true
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        }
        .onDisappear {
            cameraModel.stopSession()
            AppDelegate.shouldLockOrientation = false
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        }
        .translationTask(cameraConfiguration) { session in
            searchResults.removeAll()
            if recognizedTexts.count > 0 {
                Task { @MainActor in
                    isLoading = true
                    do {
                        for textOrigin in recognizedTexts {
                            if isChinese(textOrigin) {
                                searchResults.append(String(repeating: "-", count: 40))
                                searchResults.append(textOrigin)
                                let response = try await session.translate(textOrigin)
                                searchResults.append(response.targetText)
                            }
                        }
                    } catch {
                        searchResults.append("Lỗi dịch văn bản.")
                    }
                    isLoading = false
                    isCameraActive = false
                }
            }
        }
    }
    
    private func handleRecognizedTexts(_ texts: [String]) {
        recognizedTexts = texts
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
