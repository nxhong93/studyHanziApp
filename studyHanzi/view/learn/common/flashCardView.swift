//
//  flashCardView.swift
//  studyHanzi
//
//  Created by nguyen xuan hong on 21/1/25.
//

import SwiftUI
import CoreMotion



class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var lastShakeTime: Date = Date()
    @Published var isShaking: Bool = false
    private var lastAcceleration: CMAcceleration?

    func startShakeDetection(toggleShowAnswer: @escaping () -> Void) {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                guard let acceleration = data?.acceleration else { return }
                
                let shakeThreshold: Double = 1.8
                let stopThreshold: Double = 0.2
                let now = Date()

                let totalForce = abs(acceleration.x) + abs(acceleration.y) + abs(acceleration.z)

                if let last = self.lastAcceleration {
                    let deltaX = abs(acceleration.x - last.x)
                    let deltaY = abs(acceleration.y - last.y)
                    let deltaZ = abs(acceleration.z - last.z)
                    let change = deltaX + deltaY + deltaZ

                    if change > shakeThreshold, !self.isShaking, now.timeIntervalSince(self.lastShakeTime) > 1.0 {
                        self.isShaking = true
                        self.lastShakeTime = now
                        toggleShowAnswer()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.isShaking = false
                        }
                    }
                }

                if totalForce < stopThreshold {
                    self.isShaking = false
                }

                self.lastAcceleration = acceleration
            }
        }
    }

    func stopShakeDetection() {
        motionManager.stopAccelerometerUpdates()
    }
}

struct flashcardView: View {
    var text: String
    var isDarkMode: Bool
    var showAnswer: Bool
    var toggleShowAnswer: () -> Void
    var markCardAsLearned: () -> Void
    var isLearned: Bool
    var showLearnedCardsOnly: Bool
    var toggleLearnedState: () -> Void
    var showNextCard: () -> Void
    var showPreviousCard: () -> Void

    @StateObject private var motion = MotionManager()

    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    VStack {
                        Text(text)
                            .font(.title)
                            .foregroundColor(isDarkMode ? .white : .black)
                            .padding()
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 600)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDarkMode ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
                )
                .padding()
            }

            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        withAnimation {
                            markCardAsLearned()
                        }
                    }) {
                        Image(systemName: isLearned ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(10)
                    }
                    Spacer()
                    Button(action: toggleLearnedState) {
                        Image(systemName: showLearnedCardsOnly ? "checkmark.circle.fill" : "circle.dotted")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.yellow.opacity(0.5))
                            .padding(10)
                    }
                    Spacer()
                    Button(action: {
                        withAnimation {
                            toggleShowAnswer()
                        }
                    }) {
                        Image(systemName: showAnswer ? "eye.fill" : "eye.slash.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(10)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width < -threshold {
                        withAnimation { showNextCard() }
                    } else if value.translation.width > threshold {
                        withAnimation { showPreviousCard() }
                    }
                }
        )
        .onAppear {
            motion.startShakeDetection(toggleShowAnswer: toggleShowAnswer)
        }
        .onDisappear {
            motion.stopShakeDetection()
        }
    }
}
