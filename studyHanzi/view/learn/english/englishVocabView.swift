//
//  englishVocabView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 16/1/25.
//
import SwiftUI



struct englishVocabView: View {
    @State var level: String
    @Binding var isDarkMode: Bool
    @State private var flashcards: [Flashcard] = []
    @State private var currentIndex = 0
    @State private var isLoading = true
    @State private var showAnswer = false
    @State private var showLearnedCardsOnly = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if isLoading {
                        ProgressView("Loading flashcards...")
                    } else if flashcards.isEmpty {
                        Text("No flashcards found.")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        flashcardView(
                            text: getDisplayedText(),
                            isDarkMode: isDarkMode,
                            showAnswer: showAnswer,
                            toggleShowAnswer: toggleShowAnswer,
                            markCardAsLearned: markCardAsLearned,
                            isLearned: flashcards[currentIndex].isLearned,
                            showLearnedCardsOnly: showLearnedCardsOnly,
                            toggleLearnedState: toggleLearnedState,
                            showNextCard: showNextCard,
                            showPreviousCard: showPreviousCard
                        )
                    }
                }
            }
            .onAppear(perform: loadFlashcards)
            .navigationTitle(
                flashcards.isEmpty ? "No Cards Available" : "\(flashcards[currentIndex].id) (\(currentIndex + 1)/\(flashcards.count))"
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func loadFlashcards() {
        var books: [String]

        switch level {
        case "book1":
            books = ["englishVocab1"]
        case "book2":
            books = ["englishVocab2"]
        case "book3":
            books = ["englishVocab3"]
        case "book4":
            books = ["englishVocab4"]
        case "book5":
            books = ["englishVocab5"]
        case "book6":
            books = ["englishVocab6"]
        case "all level":
            books = ["englishVocab1", "englishVocab2", "englishVocab3", "englishVocab4", "englishVocab5", "englishVocab6"]
        default:
            print("Invalid level: \(level)")
            flashcards = []
            isLoading = false
            return
        }
        
        var allFlashcards: [Flashcard] = []
        let group = DispatchGroup()

        for book in books {
            group.enter()
            AnkiFileManager.shared.loadFlashcards(from: book, level: level) { cards in
                allFlashcards.append(contentsOf: cards)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if showLearnedCardsOnly {
                flashcards = allFlashcards.filter { $0.isLearned }.shuffled()
            } else {
                flashcards = allFlashcards.filter { !$0.isLearned }.shuffled()
            }
            self.currentIndex = 0
            self.isLoading = false
        }
    }

    private func getDisplayedText() -> String {
        let text = showAnswer ? flashcards[currentIndex].back : flashcards[currentIndex].front
        return text
    }

    private func showNextCard() {
        if currentIndex < flashcards.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = 0
        }
        showAnswer = false
    }

    private func showPreviousCard() {
        if currentIndex > 0 {
            currentIndex -= 1
        } else {
            currentIndex = flashcards.count - 1
        }
        showAnswer = false
    }
    
    private func toggleShowAnswer() {
        showAnswer.toggle()
    }

    private func toggleLearnedState() {
        showLearnedCardsOnly.toggle()
        loadFlashcards()
    }

    private func markCardAsLearned() {
        flashcards[currentIndex].isLearned.toggle()
        AnkiFileManager.shared.updateLearnedStatus(for: flashcards[currentIndex], to: flashcards[currentIndex].isLearned)
    }
}

