import Foundation

/// Loads bundled JSON content from Resources/Content/
/// All lessons are offline-first — no network required
final class ContentLoader {
    static let shared = ContentLoader()
    private init() {}

    // MARK: - Course

    func loadSpanishCourse() -> CourseContent? {
        guard let url = Bundle.main.url(forResource: "spanish-course", withExtension: "json", subdirectory: "Content/Spanish"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(SpanishCourse.self, from: data)
        else {
            print("ContentLoader: Failed to load spanish-course.json")
            return nil
        }
        return decoded.course
    }

    // MARK: - Lessons

    func loadLesson(id: String) -> LessonContent? {
        guard let url = Bundle.main.url(forResource: id, withExtension: "json", subdirectory: "Content/Spanish/Lessons"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(LessonContent.self, from: data)
        else {
            print("ContentLoader: Failed to load lesson \(id).json")
            return nil
        }
        return decoded
    }

    func loadAllLessons() -> [LessonContent] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "Content/Spanish/Lessons") else {
            return []
        }
        return urls.compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(LessonContent.self, from: data)
        }
    }

    // MARK: - Vocabulary

    func loadVocabularyBank() -> VocabularyBank? {
        guard let url = Bundle.main.url(forResource: "vocabulary-bank", withExtension: "json", subdirectory: "Content/Spanish"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(VocabularyBank.self, from: data)
        else {
            print("ContentLoader: Failed to load vocabulary-bank.json")
            return nil
        }
        return decoded
    }

    // MARK: - Generate exercises for a lesson (from word list if no explicit exercises)

    func generateExercises(for lesson: LessonContent) -> [ExerciseContent] {
        // If lesson has explicit exercises, use those
        if !lesson.exercises.isEmpty {
            return lesson.exercises
        }

        // Auto-generate from newWords
        var exercises: [ExerciseContent] = []
        let words = lesson.newWords

        for (i, word) in words.enumerated() {
            let otherWords = words.filter { $0.word != word.word }
            let wrongOptions = Array(otherWords.shuffled().prefix(3).map { $0.translation })

            // Multiple choice: ES → EN
            let mcOptions = ([word.translation] + wrongOptions).shuffled()
            exercises.append(ExerciseContent(
                id: "mc-\(i)-\(word.word)",
                type: "multiple_choice",
                question: "What does \"\(word.word)\" mean?",
                correctAnswer: word.translation,
                options: mcOptions,
                pairs: nil,
                audioFile: word.audio,
                hint: word.phonetic,
                difficulty: word.difficulty
            ))

            // Fill in the blank: EN → ES
            if words.count > 1 {
                exercises.append(ExerciseContent(
                    id: "fill-\(i)-\(word.word)",
                    type: "fill_blank",
                    question: "Write the Spanish word for \"\(word.translation)\"",
                    correctAnswer: word.word,
                    options: nil,
                    pairs: nil,
                    audioFile: word.audio,
                    hint: word.phonetic,
                    difficulty: word.difficulty
                ))
            }
        }

        // Add a word bank exercise using all words if 3+
        if words.count >= 3 {
            let sample = Array(words.shuffled().prefix(5))
            let shuffledWords = sample.map { $0.word }.shuffled()
            exercises.append(ExerciseContent(
                id: "wb-\(lesson.id)",
                type: "word_bank",
                question: "Match: \(sample.map { "\($0.translation) = ?" }.joined(separator: ", "))",
                correctAnswer: sample.map { $0.word }.joined(separator: ","),
                options: shuffledWords,
                pairs: nil,
                audioFile: nil,
                hint: nil,
                difficulty: 2
            ))
        }

        return exercises.shuffled()
    }
}
