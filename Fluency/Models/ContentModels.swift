import Foundation

// MARK: - Content Models (decoded from bundled JSON, not persisted in SwiftData)
// These are read-only value types loaded from Resources/Content/

struct SpanishCourse: Codable {
    let course: CourseContent
}

struct CourseContent: Codable {
    let id: String
    let name: String
    let sourceLanguage: String
    let targetLanguage: String
    let difficulty: String
    let units: [UnitContent]
}

struct UnitContent: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: String
    let order: Int
    let lessons: [LessonRef]
}

struct LessonRef: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let order: Int
    let type: String
    let xpReward: Int
}

// MARK: - Lesson Detail (individual lesson JSON files)

struct LessonContent: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let unit: String
    let order: Int
    let xpReward: Int
    let newWords: [WordEntry]
    let exercises: [ExerciseContent]

    /// Estimated minutes based on word count (≈1 min per 2 words, min 4)
    var estimatedMinutes: Int { max(4, newWords.count / 2 + exercises.count / 4) }
}

struct WordEntry: Codable, Identifiable {
    let word: String
    let translation: String
    let phonetic: String?
    let partOfSpeech: String?
    let difficulty: Int
    let audio: String?

    var id: String { word }
}

struct ExerciseContent: Codable, Identifiable {
    let id: String
    let type: String            // "multiple_choice", "word_bank", "fill_blank", "matching", "listening", "speaking"
    let question: String
    let correctAnswer: String
    let options: [String]?
    let pairs: [[String]]?      // for matching exercises [[spanish, english], ...]
    let audioFile: String?
    let hint: String?
    let difficulty: Int?

    var exerciseType: ExerciseType {
        ExerciseType(rawValue: type) ?? .multipleChoice
    }
}

enum ExerciseType: String, Codable, CaseIterable {
    case multipleChoice = "multiple_choice"
    case wordBank = "word_bank"
    case fillBlank = "fill_blank"
    case matching = "matching"
    case listening = "listening"
    case speaking = "speaking"
    case translation = "translation"

    var displayName: String {
        switch self {
        case .multipleChoice: return "Multiple Choice"
        case .wordBank: return "Word Bank"
        case .fillBlank: return "Fill in the Blank"
        case .matching: return "Matching Pairs"
        case .listening: return "Listening"
        case .speaking: return "Speaking"
        case .translation: return "Translation"
        }
    }

    var instruction: String {
        switch self {
        case .multipleChoice: return "Select the correct answer"
        case .wordBank: return "Arrange the words"
        case .fillBlank: return "Fill in the blank"
        case .matching: return "Match the pairs"
        case .listening: return "Type what you hear"
        case .speaking: return "Say the phrase"
        case .translation: return "Write the translation"
        }
    }
}

// MARK: - Vocabulary Bank

struct VocabularyBank: Codable {
    let language: String
    let entries: [VocabEntry]
}

struct VocabEntry: Codable, Identifiable {
    let word: String
    let translation: String
    let category: String
    let difficulty: Int
    let audio: String?
    let examples: [String]?

    var id: String { word }
}
