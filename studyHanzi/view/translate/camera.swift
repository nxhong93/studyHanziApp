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
    @Binding var isDarkMode: Bool

    @State private var useLlmVision: Bool = false

    var body: some View {
        ZStack {
            CameraPreview(session: cameraModel.session, isDarkMode: isDarkMode, cameraModel: cameraModel, isLoading: { isLoading in
                self.isLoading = isLoading
            }, onRecognizeText: { result in
                isLoading = result.loading
                self.handleRecognizedTexts(result.texts)
            })
            .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                ProgressView("Đang xử lý...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        useLlmVision.toggle()
                    }) {
                        Text(useLlmVision ? "LLM" : "OCR")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isDarkMode ? .black : .white)
                            .padding(10)
                            .background(isDarkMode ? .white.opacity(0.3) : .black.opacity(0.3))
                            .cornerRadius(25)
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }

                Spacer()
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
        .onChange(of: useLlmVision) { _, newValue in
            cameraModel.useLlmVision = newValue
        }
        .translationTask(cameraConfiguration) { session in
            searchResults.removeAll()
            if !useLlmVision {
                if recognizedTexts.count > 0 {
                    Task { @MainActor in
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
    }

    private func handleRecognizedTexts(_ texts: [String]) {
        if !useLlmVision {
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
        } else {
            searchResults = texts
            isCameraActive = false
        }
    }
}

