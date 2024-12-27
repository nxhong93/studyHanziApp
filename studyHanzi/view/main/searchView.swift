//
//  searchView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 18/11/24.
//

import SwiftUI
import Translation
import NaturalLanguage
import FirebaseAuth
import AVFoundation
import Speech
import Vision



struct searchView: View {
    
    @ObservedObject private var viewModel = SearchViewModel()
    @FocusState private var isTextFieldFocused: Bool
    @Binding var isDarkMode: Bool
    @State private var selectedSearchType: SearchType = .online
    @State private var showingSearchMenu: Bool = false

    
    @State private var isRecording = false
    @State private var selectedLanguage: Language = .vietnamese
    @State private var audioEngine = AVAudioEngine()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var speechRecognizer: SFSpeechRecognizer?
    
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    
    @State private var isDrawingActive = false
    @State private var isCameraActive = false
    @State private var drawnText: String = ""
    @State private var detectedText: String = ""
    @State private var isCanvasVisible = true
    
    @State private var imageDetectedText: String = ""
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage? = nil

        
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            searchBar
            
            ZStack {
                
                VStack {
                    if !viewModel.searchSuggestions.isEmpty && selectedSearchType == .offline {
                        suggestionList
                    }
                    if viewModel.isLoading {
                        ProgressView("...")
                            .padding()
                    } else {
                        resultView
                    }
                    Spacer()
                }
                languageMenu
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .background(isDarkMode ? .black : .white)
        .translationTask(viewModel.configuration) { session in
            guard selectedSearchType == .online else { return }
            Task { @MainActor in
                do {
                    let response = try await session.translate(viewModel.searchText)
                    viewModel.searchResults = [viewModel.searchText, response.targetText]
                    viewModel.searchText = ""
                } catch let error as TranslationError {
                    viewModel.searchResults = ["Translation failed: \(error.localizedDescription)"]
                } catch {
                    viewModel.searchResults = ["An unknown error occurred."]
                }
                viewModel.isLoading = false
            }
        }
        .onAppear {
            requestAudioPermissions()
            setupSpeechRecognizer(for: selectedLanguage.localeIdentifier)
        }
        .onChange(of: selectedLanguage) {_, _ in
            setupSpeechRecognizer(for: selectedLanguage.localeIdentifier)
        }
        .sheet(isPresented: $isDrawingActive, onDismiss: {
            if !drawnText.isEmpty {
                viewModel.searchText += drawnText
            }
            drawnText = ""
            isDrawingActive = false
        }) {
            NavigationView {
                DrawingView(
                    selectedCharacter: $drawnText
                )
                
            }
            .background(isDarkMode ? .black : .white)
        }
        .sheet(isPresented: $isCameraActive) {
            CameraView(isCameraActive: $isCameraActive, searchResults: $viewModel.searchResults)
        }
    }
    
    
    
    private func fetchSearchSuggestions(for query: String) {
        guard !query.isEmpty else {
            viewModel.searchSuggestions.removeAll()
            return
        }

        let allSuggestions = CSVHelper.suggesWord(in: viewModel.dictionary, for: query)
        viewModel.searchSuggestions = allSuggestions.filter { $0 != query }
    }
    
    private var searchBar: some View {
        HStack {
            Menu {
                ForEach(SearchType.allCases, id: \.self) { type in
                    if type != .camera {
                        Button(action: {
                            selectedSearchType = type
                            viewModel.clearSearch()
                        }) {
                            HStack {
                                Image(systemName: type.icon)
                                    .font(.body)
                                    .foregroundColor(isDarkMode ? .white : .blue)
                                Text(type.rawValue.capitalized)
                                    .font(.body)
                                    .foregroundColor(isDarkMode ? .white : .primary)
                            }
                        }
                    } else {
                        Button(action: {
                            isCameraActive.toggle()
                            
                        }) {
                            HStack {
                                Image(systemName: type.icon)
                                    .font(.title2)
                                    .foregroundColor(isDarkMode ? .white : .blue)
                                Text(type.rawValue.capitalized)
                                    .font(.body)
                                    .foregroundColor(isDarkMode ? .white : .primary)
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundColor(isDarkMode ? .white : .blue)
            }
            .padding(.leading, 4)
            .environment(\.colorScheme, isDarkMode ? .dark : .light)
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 40)
                HStack {
                    Button(action: {
                        viewModel.performSearch(searchText: viewModel.searchText, selectedSearchType: selectedSearchType)
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(isDarkMode ? .white : .gray)
                            .padding(.leading, 16)
                    }
                    TextField("Search", text: $viewModel.searchText)
                        .foregroundColor(isDarkMode ? .white : .black)
                        .focused($isTextFieldFocused)
                        .onChange(of: viewModel.searchText) { oldText, newText in
                            if selectedSearchType == .offline {
                                fetchSearchSuggestions(for: newText)
                            } else {
                                viewModel.searchSuggestions.removeAll()
                            }
                        }
                        .onSubmit {
                            viewModel.performSearch(searchText: viewModel.searchText, selectedSearchType: selectedSearchType)
                            viewModel.searchSuggestions.removeAll()
                            isTextFieldFocused = false
                        }
                        .padding(.horizontal, 8)
                    
                    Button(action: toggleRecording) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle")
                            .font(.title2)
                            .foregroundColor(isDarkMode ? .white : .blue)
                            .accessibilityLabel(isRecording ? "Stop Recording" : "Start Recording")
                    }
                    .padding(.leading, 4)
                    
                    Button(action: {
                        isDrawingActive = true
                    }) {
                        Image(systemName: "pencil.circle")
                            .font(.title2)
                            .foregroundColor(isDarkMode ? .white : .blue)
                    }
                    .padding(.leading, 4)
                }
            }
            .padding(.trailing, 16)
        }
        .padding(.leading)
    }


    
    
    private var languageMenu: some View {
        Menu {
            ForEach(Language.allCases, id: \.self) { language in
                Button(action: {
                    selectedLanguage = language
                    setupSpeechRecognizer(for: language.localeIdentifier)
                }) {
                    Text(language.flag)
                }
            }
        } label: {
            Image(systemName: "globe")
                .font(.title2)
                .foregroundColor(isDarkMode ? .white : .blue)
        }
        .padding()
        .background(isDarkMode ? Color.black : Color.white)
        .cornerRadius(8)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }



    
    private var suggestionList: some View {
        List {
            ForEach(viewModel.searchSuggestions, id: \.self) { suggestion in
                Button(action: {
                    viewModel.searchText = suggestion
                    viewModel.searchSuggestions.removeAll()
                    viewModel.performSearch(searchText: suggestion, selectedSearchType: selectedSearchType)
                    viewModel.searchText = ""
                }) {
                    Text(suggestion)
                        .foregroundColor(isDarkMode ? .white : .black)
                }
            }
        }
        .listStyle(PlainListStyle())
        .frame(maxWidth: 200)
        .environment(\.colorScheme, isDarkMode ? .dark : .light)
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var resultView: some View {
        ScrollView {
            VStack(spacing: 2) {
                HStack {
                    Button(action: {
                        viewModel.backStroke()
                    }) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.title)
                            .foregroundColor(isDarkMode ? .white : .blue)
                            .padding()
                    }
                    .disabled(viewModel.resultManager?.canUndo == false)
                    
                    Spacer()
                    Button(action: {
                        print("Redo button pressed")
                        viewModel.redoStroke()
                    }) {
                        Image(systemName: "arrow.uturn.forward.circle.fill")
                            .font(.title)
                            .foregroundColor(isDarkMode ? .white : .blue)
                            .padding()
                    }
                    .disabled(viewModel.resultManager?.canRedo == false)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.horizontal)
                
                VStack(spacing: 2) {
                    ForEach(viewModel.searchResults, id: \.self) { result in
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(result.components(separatedBy: "\n"), id: \.self) { line in
                                HStack {
                                    Text(line)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundColor(isDarkMode ? .white : .black)
                                        .padding(.vertical, 2)
                                        .contextMenu {
                                            Button(action: {
                                                UIPasteboard.general.string = line
                                            }) {
                                                Label("Copy", systemImage: "doc.on.doc.fill")
                                            }
                                            ForEach(SearchType.allCases.filter { $0 != .camera }, id: \.self) { type in
                                                Button(action: {
                                                    selectedSearchType = type
                                                    viewModel.searchText = line
                                                    viewModel.performSearch(searchText: viewModel.searchText, selectedSearchType: selectedSearchType)
                                                }) {
                                                    HStack {
                                                        Image(systemName: type.icon)
                                                            .font(.body)
                                                        Text(type.rawValue.capitalized)
                                                            .font(.body)
                                                    }
                                                }
                                            }
                                        }
                                    
                                    if isChinese(line) {
                                        Button(action: {
                                            readText(line, in: "zh-CN")
                                        }) {
                                            Image(systemName: "speaker.wave.2.fill")
                                                .foregroundColor(isDarkMode ? .white : .blue)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                }
                                .cornerRadius(8)
                            }
                        }
                        .padding(.bottom, 2)
                    }
                }
                .padding(.horizontal)
            }
            .onTapGesture {
                isTextFieldFocused = false
            }
        }
    }


    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            viewModel.searchText = ""
            startRecording()
        }
    }
    
    private func setupSpeechRecognizer(for localeIdentifier: String) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }
    
    private func requestAudioPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                break
            case .denied, .restricted, .notDetermined:
                print("Speech recognition authorization denied.")
            @unknown default:
                break
            }
        }
        AVAudioApplication.requestRecordPermission { granted in
            if !granted {
                print("Microphone permission denied.")
            }
        }
    }
    
    private func startRecording() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            viewModel.searchResults = ["Speech recognizer is not available for \(selectedLanguage)"]
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                viewModel.searchText = result.bestTranscription.formattedString
            }
            if error != nil || result?.isFinal == true {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                isRecording = false
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio Engine couldn't start.")
        }
        
        isRecording = true
    }
    
    private func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
        viewModel.performSearch(searchText: viewModel.searchText, selectedSearchType: selectedSearchType)
    }
    
    private func readText(_ text: String, in language: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.5
        utterance.volume = 1
        speechSynthesizer.speak(utterance)
    }
}

#Preview {
    searchView(isDarkMode: .constant(true))
}
