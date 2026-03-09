import Foundation
import SwiftData
import AVFoundation
import Speech

enum SessionState {
    case idle
    case active
    case showingFeedback(correct: Bool)
    case complete(score: Double, xpEarned: Int)
    case failed // 0 hearts
}

enum AnswerState {
    case waiting
    case correct
    case incorrect
}

@MainActor
final class LessonSession: ObservableObject {
    // MARK: - Published State
    @Published var sessionState: SessionState = .idle
    @Published var currentExerciseIndex: Int = 0
    @Published var userAnswer: String = ""
    @Published var answerState: AnswerState = .waiting
    @Published var hearts: Int = 5
    @Published var progressFraction: Double = 0
    @Published var showHint: Bool = false
    @Published var isListening: Bool = false
    @Published var recognizedSpeech: String = ""

    // MARK: - Content
    private(set) var lesson: LessonContent?
    private(set) var exercises: [ExerciseContent] = []
    private var exerciseStartTime: Date = Date()

    // MARK: - Result tracking
    private var correctCount: Int = 0
    private var exerciseResults: [(id: String, correct: Bool, timeSpent: TimeInterval)] = []

    // MARK: - Dependencies
    private var modelContext: ModelContext
    private var user: User
    private var srService = SpacedRepetitionService.shared
    private var audioPlayer: AVAudioPlayer?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let audioEngine = AVAudioEngine()

    // MARK: - Init

    init(modelContext: ModelContext, user: User) {
        self.modelContext = modelContext
        self.user = user
        self.hearts = min(user.hearts, 5)
    }

    /// Placeholder init — call configure(context:) before starting
    static func placeholder(user: User) -> LessonSession {
        // Create a temporary in-memory container for the placeholder
        let schema = Schema([User.self, UserProgress.self, LessonResult.self, SRCard.self, UserAchievement.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        return LessonSession(modelContext: ModelContext(container), user: user)
    }

    /// Re-inject the real environment context before the session starts
    func configure(context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Start Session

    func start(lesson: LessonContent) {
        self.lesson = lesson
        self.exercises = ContentLoader.shared.generateExercises(for: lesson)
        self.currentExerciseIndex = 0
        self.hearts = user.hearts
        self.correctCount = 0
        self.exerciseResults = []
        self.progressFraction = 0
        self.sessionState = .active
        self.exerciseStartTime = Date()
    }

    var currentExercise: ExerciseContent? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    // MARK: - Answer Submission

    func submitAnswer(_ answer: String) {
        guard let exercise = currentExercise,
              case .active = sessionState else { return }

        let timeSpent = Date().timeIntervalSince(exerciseStartTime)
        let isCorrect = checkAnswer(answer, exercise: exercise)

        answerState = isCorrect ? .correct : .incorrect
        sessionState = .showingFeedback(correct: isCorrect)

        exerciseResults.append((id: exercise.id, correct: isCorrect, timeSpent: timeSpent))

        if isCorrect {
            correctCount += 1
            updateSR(exercise: exercise, correct: true, timeSpent: timeSpent)
        } else {
            hearts -= 1
            updateSR(exercise: exercise, correct: false, timeSpent: timeSpent)
        }

        progressFraction = Double(currentExerciseIndex + 1) / Double(exercises.count)

        // Auto-advance after feedback
        if hearts <= 0 {
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await finishSession(failed: true)
            }
        } else {
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await advance()
            }
        }
    }

    @MainActor
    private func advance() {
        let nextIndex = currentExerciseIndex + 1
        if nextIndex >= exercises.count {
            Task { await finishSession(failed: false) }
        } else {
            currentExerciseIndex = nextIndex
            answerState = .waiting
            userAnswer = ""
            showHint = false
            sessionState = .active
            exerciseStartTime = Date()
        }
    }

    @MainActor
    private func finishSession(failed: Bool) {
        guard let lesson = lesson else { return }

        let totalQuestions = exercises.count
        let score = totalQuestions > 0 ? Double(correctCount) / Double(totalQuestions) : 0
        let xp = failed ? 0 : calculateXP(score: score, baseXP: lesson.xpReward)

        // Persist result
        let result = LessonResult(userId: user.id, lessonId: lesson.id, languageCode: user.selectedLanguageCode)
        result.completedAt = Date()
        result.score = score
        result.correctAnswers = correctCount
        result.totalQuestions = totalQuestions
        result.xpEarned = xp
        result.heartsLost = user.hearts - hearts
        result.timeSpent = exerciseResults.reduce(0) { $0 + $1.timeSpent }
        modelContext.insert(result)
        result.user = user

        // Update user
        user.totalXP += xp
        user.hearts = max(0, hearts)

        // Mark progress
        if !failed && score >= 0.8 {
            updateProgress(lessonId: lesson.id, score: score, xp: xp)
        }

        // SR cards for new words
        for word in lesson.newWords {
            _ = srService.upsertCard(for: word, lessonId: lesson.id, user: user, context: modelContext)
        }

        // Update streak
        updateStreak()

        try? modelContext.save()

        if failed {
            sessionState = .failed
        } else {
            sessionState = .complete(score: score, xpEarned: xp)
        }
    }

    // MARK: - Answer Checking

    private func checkAnswer(_ answer: String, exercise: ExerciseContent) -> Bool {
        let a = answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correct = exercise.correctAnswer.lowercased()

        switch exercise.exerciseType {
        case .multipleChoice, .matching:
            return a == correct
        case .wordBank:
            // Compare comma-separated lists ignoring order? No — order matters for sentences
            return a == correct
        case .fillBlank, .translation:
            return levenshtein(a, correct) <= 2
        case .listening, .speaking:
            return levenshtein(a, correct) <= 3
        }
    }

    // MARK: - SR Update

    private func updateSR(exercise: ExerciseContent, correct: Bool, timeSpent: TimeInterval) {
        guard let word = lesson?.newWords.first(where: {
            exercise.correctAnswer.contains($0.word) || exercise.correctAnswer.contains($0.translation)
        }) else { return }

        if let card = user.srCards.first(where: { $0.word == word.word }) {
            let quality = srService.quality(isCorrect: correct, timeSpent: timeSpent)
            srService.update(card: card, quality: quality)
        }
    }

    // MARK: - Progress Update

    private func updateProgress(lessonId: String, score: Double, xp: Int) {
        let existing = user.progress.first { $0.lessonId == lessonId }

        if let p = existing {
            p.attempts += 1
            p.bestScore = max(p.bestScore, score)
            p.xpEarned += xp
            if !p.isCompleted {
                p.isCompleted = true
                p.completedAt = Date()
            }
        } else {
            let p = UserProgress(
                userId: user.id,
                languageCode: user.selectedLanguageCode,
                unitId: lesson?.unit ?? "",
                lessonId: lessonId
            )
            p.isCompleted = true
            p.completedAt = Date()
            p.bestScore = score
            p.xpEarned = xp
            p.attempts = 1
            modelContext.insert(p)
            p.user = user
        }
    }

    // MARK: - Streak

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActive = calendar.startOfDay(for: user.lastActiveDate)
        let daysDiff = calendar.dateComponents([.day], from: lastActive, to: today).day ?? 0

        if daysDiff == 0 {
            // Already active today — no change
        } else if daysDiff == 1 {
            user.currentStreak += 1
            user.longestStreak = max(user.longestStreak, user.currentStreak)
        } else {
            user.currentStreak = 1 // reset
        }

        user.lastActiveDate = Date()
    }

    // MARK: - XP Calculation

    private func calculateXP(score: Double, baseXP: Int) -> Int {
        let bonus = Int(score * 10)
        return baseXP + bonus
    }

    // MARK: - Hints

    func requestHint() {
        showHint = true
    }

    // MARK: - Audio

    func playAudio(file: String) {
        guard let url = Bundle.main.url(forResource: file, withExtension: nil, subdirectory: "Content/Spanish/Audio") else {
            // TTS fallback
            speakWord(currentExercise?.question ?? "")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            speakWord(currentExercise?.question ?? "")
        }
    }

    private func speakWord(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = 0.4
        AVSpeechSynthesizer().speak(utterance)
    }

    // MARK: - Levenshtein Distance

    private func levenshtein(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1), b = Array(s2)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var matrix = (0...b.count).map { [$0] }
        for i in 1...a.count { matrix.append([i] + Array(repeating: 0, count: b.count)) }
        for i in 1...a.count {
            for j in 1...b.count {
                let cost = a[i-1] == b[j-1] ? 0 : 1
                matrix[i][j] = Swift.min(matrix[i-1][j]+1, matrix[i][j-1]+1, matrix[i-1][j-1]+cost)
            }
        }
        return matrix[a.count][b.count]
    }
}
